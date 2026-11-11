#!/usr/bin/env bash
#
# devkit.sh — shared library for the terminal Flutter dev toolkit (dev.sh / logcat.sh,
# and future ioslog.sh / a dispatcher). Source it; do not execute:
#     SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
#     . "$SCRIPT_DIR/lib/devkit.sh"
#
# Conventions
#   - Functions are namespaced dk_*, variables DK_*.
#   - ALL user-facing UI goes to stderr; a function's "return value" is its stdout.
#   - Library is set -u safe and keeps no global side effects beyond DK_* it documents.
#   - Portable: macOS (BSD) + Linux (util-linux); only bash + perl are hard deps.
#     Device/emulator JSON parsing uses python3 when present, else perl JSON::PP
#     (a perl core module) — with a graceful degrade to -d/-s when both are absent.
#
[ -n "${DK_SOURCED:-}" ] && return 0
DK_SOURCED=1

# ----------------------------------------------------------------------------
# UI (stderr). Colors honor NO_COLOR and only paint an interactive stderr.
# ----------------------------------------------------------------------------
if [ -z "${NO_COLOR:-}" ] && [ -t 2 ]; then
  DK_CYAN=$'\033[1;36m'; DK_DIM=$'\033[90m'; DK_RED=$'\033[1;31m'
  DK_YEL=$'\033[1;33m';  DK_GRN=$'\033[1;32m'; DK_RST=$'\033[0m'
else
  DK_CYAN='';            DK_DIM='';           DK_RED=''
  DK_YEL='';             DK_GRN='';           DK_RST=''
fi
dk_say()  { printf '%s%s%s\n' "$DK_CYAN" "$*" "$DK_RST" >&2; }
dk_dim()  { printf '%s%s%s\n' "$DK_DIM"  "$*" "$DK_RST" >&2; }
dk_ok()   { printf '%s✓ %s%s\n' "$DK_GRN" "$*" "$DK_RST" >&2; }
dk_warn() { printf '%s⚠ %s%s\n' "$DK_YEL" "$*" "$DK_RST" >&2; }
dk_err()  { printf '%s✗ %s%s\n' "$DK_RED" "$*" "$DK_RST" >&2; }

# ----------------------------------------------------------------------------
# Environment / prerequisites
# ----------------------------------------------------------------------------
dk_require() {  # dk_require <cmd> [hint]; errors (non-zero) if missing
  command -v "$1" >/dev/null 2>&1 && return 0
  dk_err "未找到 $1${2:+(${2})}"
  return 1
}

# Option-argument guard for parse loops. `shift 2` with a missing argument does
# NOT shift on bash (POSIX: out-of-range is an error) -> silent infinite loop.
# Call as: dk_need_arg "$1" $#  — exits 2 with a clear message when $2 is absent.
dk_need_arg() {  # dk_need_arg <opt> <caller_argc>
  [ "$2" -ge 2 ] && return 0
  dk_err "选项 $1 缺少参数(-h 查看用法)"
  exit 2
}

# True only when we may prompt the user (a real tty, and not forced non-interactive).
dk_is_interactive() { [ -z "${DK_YES:-}" ] && [ -r /dev/tty ] && [ -t 2 ]; }

# ----------------------------------------------------------------------------
# Flutter project root: walk upward from each start dir for pubspec.yaml.
# ----------------------------------------------------------------------------
dk_find_root() {  # dk_find_root <start_dir>...; echoes the first project root found
  local start d
  for start in "$@"; do
    d="$start"
    while [ -n "$d" ] && [ "$d" != "/" ]; do
      [ -f "$d/pubspec.yaml" ] && { printf '%s\n' "$d"; return 0; }
      d="$(dirname "$d")"
    done
  done
  return 1
}

# Resolve the flutter launcher, honoring fvm when the project pins it.
dk_flutter_bin() {  # dk_flutter_bin <root>; echoes "fvm flutter" or "flutter"
  if { [ -f "$1/.fvmrc" ] || [ -d "$1/.fvm" ]; } && command -v fvm >/dev/null 2>&1; then
    printf 'fvm flutter\n'
  else
    printf 'flutter\n'
  fi
}

# ----------------------------------------------------------------------------
# Logs: <root>/logs with a self-contained .gitignore (never touches host root).
# ----------------------------------------------------------------------------
dk_init_logs() {  # dk_init_logs <root>; sets DK_LOGS_DIR; reaps crash-orphaned run logs
  DK_LOGS_DIR="$1/logs"
  mkdir -p "$DK_LOGS_DIR"
  [ -f "$DK_LOGS_DIR/.gitignore" ] || printf '*\n!.gitignore\n' > "$DK_LOGS_DIR/.gitignore"
  dk_reap_orphans
}

# ----------------------------------------------------------------------------
# Ephemeral run logs: a run log lives only for the duration of its run; the
# owning process removes it on exit/signal (wired in dev.sh). These helpers add
# crash-safety (SIGKILL / power loss leave no trap) + concurrency-safety.
#
# Per-run lock: logs/.run_<pid>.lock whose CONTENT is the run log's basename.
# Reaping removes a run log only when its owner pid is dead — never a live
# concurrent run's log.
# ----------------------------------------------------------------------------
dk_lock_run() {  # dk_lock_run <run_log_path>; sets DK_RUN_LOCK
  DK_RUN_LOCK="$DK_LOGS_DIR/.run_$$.lock"
  basename "$1" > "$DK_RUN_LOCK" 2>/dev/null || true
}

dk_reap_orphans() {  # remove run logs whose owning pid is gone (crash / kill -9 safety)
  local lock pid logname
  for lock in "$DK_LOGS_DIR"/.run_*.lock; do
    [ -e "$lock" ] || continue                 # no matches -> literal glob, skip
    pid="${lock##*/.run_}"; pid="${pid%.lock}"
    # Owner still alive (a concurrent run) -> leave its log untouched.
    [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null && continue
    logname="$(cat "$lock" 2>/dev/null)"
    [ -n "$logname" ] && rm -f "$DK_LOGS_DIR/$logname"
    rm -f "$lock"
  done
}

dk_discard_log() {  # dk_discard_log <run_log_path> <latest_symlink>; idempotent
  local run="$1" latest="$DK_LOGS_DIR/$2"
  rm -f "$run"
  # Drop latest.log only if it still points at THIS run log (concurrency-safe).
  if [ -L "$latest" ] && [ "$(readlink "$latest" 2>/dev/null)" = "$(basename "$run")" ]; then
    rm -f "$latest"
  fi
  [ -n "${DK_RUN_LOCK:-}" ] && rm -f "$DK_RUN_LOCK"
}

# dk_should_keep <mode> <exit_code> <signaled> -> rc 0 = keep the log.
#   mode: 1/yes/true/always = always keep; on-error = keep only on a non-signal
#   non-zero exit; anything else (default) = discard. Signals (Ctrl-C/TERM/HUP)
#   are user-initiated stops -> discarded unless mode forces always-keep.
dk_should_keep() {
  case "$1" in
    1|yes|true|always) return 0 ;;
    on-error|onerror)  { [ "${3:-0}" = 0 ] && [ "${2:-0}" -ne 0 ]; } && return 0; return 1 ;;
    *)                 return 1 ;;
  esac
}

dk_rotate() {  # dk_rotate <prefix> <keep>; keep N newest logs/<prefix>_*.log
  # shellcheck disable=SC2012  # 需要按 mtime 排序;日志名由本工具生成,无空白/换行
  ls -1t "$DK_LOGS_DIR/$1"_*.log 2>/dev/null | tail -n +"$(( $2 + 1 ))" \
    | while IFS= read -r f; do rm -f "$f"; done
}

dk_new_log() {  # dk_new_log <prefix> <latest_symlink>; echoes the new log path
  local stamp; stamp="$(date +%Y%m%d_%H%M%S)"
  ln -sfn "$1_${stamp}.log" "$DK_LOGS_DIR/$2"
  printf '%s\n' "$DK_LOGS_DIR/$1_${stamp}.log"
}

# ----------------------------------------------------------------------------
# Prefs: per-project, machine-local key=value store under logs/ (auto-ignored).
# ----------------------------------------------------------------------------
dk_pref_get() {  # dk_pref_get <key>; echoes value (empty + non-zero if unset)
  local f="$DK_LOGS_DIR/.devkit-prefs" v
  [ -f "$f" ] || return 1
  v="$(grep -E "^$1=" "$f" 2>/dev/null | tail -1)" || return 1
  [ -n "$v" ] && printf '%s\n' "${v#*=}"
}
dk_pref_set() {  # dk_pref_set <key> <value>
  local f="$DK_LOGS_DIR/.devkit-prefs" tmp="$DK_LOGS_DIR/.devkit-prefs.$$"
  { [ -f "$f" ] && grep -vE "^$1=" "$f"; printf '%s=%s\n' "$1" "$2"; } > "$tmp" 2>/dev/null \
    && mv "$tmp" "$f"
}

# ----------------------------------------------------------------------------
# Generic interactive menu. Renders to stderr, reads /dev/tty.
# Echoes (stdout): chosen 1-based index, or a matched action letter, or default
# index on Enter. Return: 0 ok, 1 invalid (caller may loop), 130 quit.
# ----------------------------------------------------------------------------
dk_menu() {  # dk_menu <title> <default_idx> <action_letters> -- <item>...
  local title="$1" def="$2" actions="$3"; shift 3
  [ "${1:-}" = "--" ] && shift
  local items=("$@") n=$# i
  dk_say "$title"
  for i in "${!items[@]}"; do
    local mk=""; [ "$((i+1))" = "$def" ] && mk="  ${DK_DIM}← 默认${DK_RST}"
    printf '  %s%2d)%s %s%b\n' "$DK_CYAN" "$((i+1))" "$DK_RST" "${items[$i]}" "$mk" >&2
  done
  # actions are space-separated "key" or "key:label" tokens (label shown in the hint).
  local hint="Enter=$def" tok key lbl
  for tok in $actions; do
    key="${tok%%:*}"; lbl="${tok#*:}"; [ "$lbl" = "$tok" ] && lbl="…"
    hint="$hint  ${key}=${lbl}"
  done
  printf '  %s── %s  q=退出%s\n› ' "$DK_DIM" "$hint" "$DK_RST" >&2
  local c; IFS= read -r c < /dev/tty || { printf '\n' >&2; return 130; }
  case "$c" in
    "")        printf '%s\n' "$def"; return 0 ;;
    q|Q)       return 130 ;;
    *[!0-9]*)  for tok in $actions; do [ "$c" = "${tok%%:*}" ] && { printf '%s\n' "${tok%%:*}"; return 0; }; done
               dk_warn "无效输入:${c}"; return 1 ;;
    *)         { [ "$c" -ge 1 ] && [ "$c" -le "$n" ]; } && { printf '%s\n' "$c"; return 0; }
               dk_warn "超出范围:${c}"; return 1 ;;
  esac
}

# ----------------------------------------------------------------------------
# Device enumeration / picker (flutter, all platforms).
# ----------------------------------------------------------------------------
# _dk_json_tsv <devices|emulators>: stdin = flutter --machine JSON array -> TSV.
# Parser: python3 if present, else perl JSON::PP (perl is a hard dep of the kit).
# rc 0 ok, 1 parse error, 2 no JSON parser available.
_dk_json_tsv() {
  local mode="$1"
  if command -v python3 >/dev/null 2>&1; then
    python3 -c '
import sys, json
mode = sys.argv[1]
try:
    xs = json.load(sys.stdin)
except Exception:
    sys.exit(1)
for x in xs:
    if mode == "devices":
        print("\t".join([
            str(x.get("id", "")),
            str(x.get("name", "")),
            str(x.get("targetPlatform", "")),
            "simulator" if x.get("emulator") else "device",
        ]))
    else:
        print("\t".join([str(x.get("id", "")), str(x.get("name", ""))]))
' "$mode"
  elif perl -MJSON::PP -e1 2>/dev/null; then
    DK_JSON_MODE="$mode" perl -MJSON::PP -e '
      local $/; my $xs = eval { decode_json(<STDIN>) };
      exit 1 unless ref $xs eq q{ARRAY};
      for my $x (@$xs) {
        if ($ENV{DK_JSON_MODE} eq q{devices}) {
          print join(qq{\t}, $x->{id} // q{}, $x->{name} // q{},
                     $x->{targetPlatform} // q{},
                     ($x->{emulator} ? q{simulator} : q{device})), qq{\n};
        } else {
          print join(qq{\t}, $x->{id} // q{}, $x->{name} // q{}), qq{\n};
        }
      }'
  else
    return 2
  fi
}

# dk_list_devices <flutter_cmd> -> TSV lines "id<TAB>name<TAB>platform<TAB>kind"
# rc 0 ok, 1 no devices / flutter error, 2 no JSON parser available.
dk_list_devices() {
  local fcmd="$1" json out rc
  json="$($fcmd devices --machine 2>/dev/null)" || return 1
  [ -n "$json" ] || return 1
  out="$(printf '%s' "$json" | _dk_json_tsv devices)"; rc=$?
  [ "$rc" -eq 0 ] || return "$rc"
  printf '%s\n' "$out"
}

# dk_pick_flutter_device <flutter_cmd> <preselect_id> -> echoes chosen id (stdout).
# Non-interactive: echoes preselect (may be empty => flutter default). 1 device: auto.
# Returns 130 if the user quits.
dk_pick_flutter_device() {
  local fcmd="$1" preselect="${2:-}"
  if ! dk_is_interactive; then printf '%s\n' "$preselect"; return 0; fi

  local devices rc ids names plats kinds
  while :; do
    devices="$(dk_list_devices "$fcmd")"; rc=$?
    if [ "$rc" -eq 2 ]; then
      dk_warn "设备选择需要 python3 或 perl(JSON::PP);请用 -d <id> 指定。"
      printf '%s\n' "$preselect"; return 0
    fi
    ids=(); names=(); plats=(); kinds=()
    if [ "$rc" -eq 0 ]; then
      while IFS=$'\t' read -r id name plat kind; do
        [ -n "$id" ] || continue
        ids+=("$id"); names+=("$name"); plats+=("$plat"); kinds+=("$kind")
      done <<EOF
$devices
EOF
    fi
    local n=${#ids[@]}

    if [ "$n" -eq 0 ]; then
      dk_warn "未检测到设备。"
      if _dk_offer_emulator "$fcmd"; then continue; fi
      printf '%s\n' "$preselect"; return 0
    fi
    if [ "$n" -eq 1 ]; then
      dk_ok "自动选中设备:${names[0]} (${plats[0]})"
      printf '%s\n' "${ids[0]}"; return 0
    fi

    local def=1 i labels=()
    for i in "${!ids[@]}"; do
      [ "${ids[$i]}" = "$preselect" ] && def=$((i+1))
      labels+=("$(printf '%-26s %s· %s%s' "${names[$i]}" "$DK_DIM" "${plats[$i]} · ${kinds[$i]}" "$DK_RST")")
    done

    local sel
    sel="$(dk_menu "选择运行设备(${n}):" "$def" "r:刷新 e:启动模拟器" -- "${labels[@]}")"; rc=$?
    [ "$rc" -eq 130 ] && { dk_dim "已取消。"; return 130; }
    [ "$rc" -ne 0 ] && continue
    case "$sel" in
      r) continue ;;
      e) _dk_offer_emulator "$fcmd"; continue ;;
      *) printf '%s\n' "${ids[$((sel-1))]}"; return 0 ;;
    esac
  done
}

# Offer to boot an emulator; returns 0 if one was launched (caller re-enumerates).
_dk_offer_emulator() {
  local fcmd="$1" emus ids names sel rc
  emus="$($fcmd emulators --machine 2>/dev/null | _dk_json_tsv emulators 2>/dev/null)"; rc=$?
  [ "$rc" -eq 2 ] && { dk_warn "列出模拟器需要 python3 或 perl(JSON::PP)。"; return 1; }
  [ -n "$emus" ] || { dk_warn "无可用模拟器(flutter emulators 为空)。"; return 1; }
  ids=(); names=()
  while IFS=$'\t' read -r id name; do [ -n "$id" ] && { ids+=("$id"); names+=("$name"); }; done <<EOF
$emus
EOF
  sel="$(dk_menu "启动模拟器:" 1 "" -- "${names[@]}")"; rc=$?
  [ "$rc" -eq 0 ] || return 1
  dk_dim "启动 ${names[$((sel-1))]} …(启动需要几秒,稍后按 r 刷新)"
  # nohup + disown:选择器随后被 q 退出/收到 HUP 时,模拟器启动不被连带杀掉。
  local -a fargs; read -r -a fargs <<< "$fcmd"   # "fvm flutter" 需按词拆开
  nohup "${fargs[@]}" emulators --launch "${ids[$((sel-1))]}" >/dev/null 2>&1 &
  disown 2>/dev/null || true
  return 0
}

# ----------------------------------------------------------------------------
# Entrypoint (-t) resolution.
# ----------------------------------------------------------------------------
# _dk_find_entrypoints <root> -> candidate entrypoint paths (relative to root).
# Prefers the lib/main*.dart convention; falls back to any lib/**/*.dart with a
# top-level main(.
_dk_find_entrypoints() {
  local root="$1" conv
  conv="$(cd "$root" 2>/dev/null && ls -1 lib/main*.dart 2>/dev/null)"
  if [ -n "$conv" ]; then printf '%s\n' "$conv"; return 0; fi
  (cd "$root" 2>/dev/null && grep -rlE '^[[:space:]]*(void[[:space:]]+|Future(<void>)?[[:space:]]+)?main[[:space:]]*\(' lib --include='*.dart' 2>/dev/null)
}

# dk_resolve_target <root> <explicit> <preselect> -> echoes a target path relative
# to root, or nothing to use flutter's default (lib/main.dart). Order:
# explicit -t  >  remembered (still exists)  >  lib/main.dart  >  detect (1 auto / N pick).
# Returns 130 if the user quits the picker.
dk_resolve_target() {
  local root="$1" explicit="${2:-}" preselect="${3:-}"
  if [ -n "$explicit" ]; then printf '%s\n' "$explicit"; return 0; fi
  if [ -n "$preselect" ] && [ -f "$root/$preselect" ]; then printf '%s\n' "$preselect"; return 0; fi
  [ -f "$root/lib/main.dart" ] && return 0          # flutter default — no -t needed
  local cands; cands="$(_dk_find_entrypoints "$root")"
  local arr=()
  while IFS= read -r f; do [ -n "$f" ] && arr+=("$f"); done <<EOF
$cands
EOF
  local n=${#arr[@]}
  [ "$n" -eq 0 ] && return 0                         # let flutter report a clear error
  if [ "$n" -eq 1 ]; then dk_ok "入口: ${arr[0]}"; printf '%s\n' "${arr[0]}"; return 0; fi
  if dk_is_interactive; then
    local def=1 i
    for i in "${!arr[@]}"; do [ "${arr[$i]}" = "$preselect" ] && def=$((i+1)); done
    local sel; sel="$(dk_menu "选择入口(${n}):" "$def" "" -- "${arr[@]}")"; local rc=$?
    [ "$rc" -eq 130 ] && return 130
    [ "$rc" -ne 0 ] && { printf '%s\n' "${arr[0]}"; return 0; }
    printf '%s\n' "${arr[$((sel-1))]}"; return 0
  fi
  dk_warn "多入口但非交互,默认用 ${arr[0]}(用 -t 指定)。"
  printf '%s\n' "${arr[0]}"; return 0
}

# ----------------------------------------------------------------------------
# Cross-platform PTY runner. Allocates a real pty so the child (flutter run)
# stays interactive; writes the raw stream to stdout for a downstream colorizer.
# ----------------------------------------------------------------------------
dk_run_pty() {  # dk_run_pty <cmd> [args...]
  case "$(uname -s)" in
    Darwin)
      dk_require script || return 127
      script -q /dev/null "$@"
      ;;
    Linux)
      dk_require script || return 127
      local cmd="" a
      for a in "$@"; do cmd+=" $(printf '%q' "$a")"; done
      script -q -e -c "${cmd# }" /dev/null
      ;;
    *)
      dk_warn "未知系统($(uname -s)):无 PTY,r/R/q 交互可能失效(仍着色+落盘)。"
      "$@"
      ;;
  esac
}

# ----------------------------------------------------------------------------
# Colorizer (perl). Reads stdin; LOGFILE/NO_COLOR/FORCE_COLOR via env.
# mode=flutter: collapse \r and \b progress, prepend HH:MM:SS, color by keyword.
# mode=logcat:  keep device timestamps, color by -v time level letter.
# Disk is always plain text (no ANSI); screen colors only when appropriate.
# ----------------------------------------------------------------------------
dk_colorize() {  # dk_colorize <flutter|logcat>
  DK_MODE="$1" perl -e '
use POSIX qw(strftime);
use Encode ();
$| = 1;
my $mode = $ENV{DK_MODE} || q{flutter};
my $lf;
if (defined $ENV{LOGFILE} && length $ENV{LOGFILE}) {
  open($lf, q{>>}, $ENV{LOGFILE}) or warn qq{log open failed: $!\n};
  if ($lf) { my $o = select($lf); $| = 1; select($o); }
}
my $force = defined $ENV{FORCE_COLOR} && length $ENV{FORCE_COLOR};
my $nocol = defined $ENV{NO_COLOR}    && length $ENV{NO_COLOR};
my $color = !$nocol && ($force || -t STDOUT);
my ($R,$Y,$G,$Z) = (qq{\e[1;31m}, qq{\e[1;33m}, qq{\e[90m}, qq{\e[0m});
# A tty stdout is in raw mode during flutter run (the script PTY disables ONLCR),
# so the screen needs explicit CR; a pipe/file keeps plain \n. Disk is always \n.
my $nl = (-t STDOUT) ? qq{\r\n} : qq{\n};
while (my $l = <STDIN>) {
  chomp $l;
  $l =~ s/\r$//;                       # CRLF tail from the PTY
  if ($mode eq q{flutter}) {
    $l =~ s/.*\r//s;                   # \r overwrite -> keep final frame
    # Backspace overwrite must collapse at the CHARACTER level: a \b erases one
    # glyph, which may be multibyte (flutter spinners are braille). Byte-level
    # collapse would split UTF-8 and corrupt it, so decode -> collapse -> encode.
    my $d = Encode::decode(q{UTF-8}, $l, Encode::FB_DEFAULT);
    1 while $d =~ s/[^\x{08}]\x{08}//g;
    $d =~ s/^\x{08}+//;
    $l = Encode::encode(q{UTF-8}, $d);
    $l =~ s/\xe2[\xa0-\xa3][\x80-\xbf]//g;   # strip leftover braille spinner glyphs
  }
  $l =~ s{\e\[[0-9;?]*[ -\/]*[\@-~]}{}g;          # ANSI / CSI
  $l =~ s{\e[\@-Z\\-_]}{}g;                         # other escapes
  $l =~ s/[\x00-\x08\x0b-\x0d\x0e-\x1f\x7f]//g;     # control chars (keep \t)
  next if $l eq q{};
  my $c = q{};
  if ($mode eq q{logcat}) {
    if ($l =~ m{^\d\d-\d\d \d\d:\d\d:\d\d\.\d+\s+([A-Z])/}) {
      my $p = $1;
      if    ($p eq q{E} || $p eq q{F} || $p eq q{A}) { $c = $R; }
      elsif ($p eq q{W})                             { $c = $Y; }
      elsif ($p eq q{D} || $p eq q{V})               { $c = $G; }
    }
    print {$lf} qq{$l\n} if $lf;
    print(($color && length $c) ? qq{$c$l$Z$nl} : qq{$l$nl});
  } else {
    if ($l =~ /another exception was thrown|Reloaded \d|Restarted application|Performing hot (?:reload|restart)|Syncing files to device|Flutter run key commands/i) {
      $c = $G;
    } elsif ($l =~ /\xe2\x9d\x8c|\xf0\x9f\x9b\x91|\xf0\x9f\x92\xa5|EXCEPTION CAUGHT BY|Unhandled|\b(?:error|exception|failure|fatal)\b|\bfailed\b|^\s*#\d+\s|(?:\xe2\x95\x90){3,}/i) {
      $c = $R;
    } elsif ($l =~ /\xe2\x9a\xa0|\bwarn(?:ing)?\b|\bdeprecated\b/i) {
      $c = $Y;
    }
    my $ts = strftime(q{%H:%M:%S}, localtime);
    print {$lf} qq{$ts  $l\n} if $lf;
    if ($color) { print qq{$G$ts$Z  } . (length $c ? qq{$c$l$Z} : $l) . $nl; }
    else        { print qq{$ts  $l$nl}; }
  }
}
'
}

# ----------------------------------------------------------------------------
# Log management subcommands (shared by dev.sh; reusable by a dispatcher).
# ----------------------------------------------------------------------------
dk_logs_list() {  # dk_logs_list [glob_prefix]
  local pat="${1:-}"
  ls -1t "$DK_LOGS_DIR/${pat}"*.log 2>/dev/null || dk_dim "(暂无日志)"
}
dk_logs_tail() {  # dk_logs_tail <latest_symlink>
  local f="$DK_LOGS_DIR/$1"
  [ -e "$f" ] || { dk_err "没有最近日志:$f"; return 1; }
  dk_dim "tail -f $f  (Ctrl-C 退出)"; tail -f "$f"
}
dk_logs_open() {  # dk_logs_open <latest_symlink>; $EDITOR wins (as documented)
  local f="$DK_LOGS_DIR/$1"
  [ -e "$f" ] || { dk_err "没有最近日志:$f"; return 1; }
  local ed="${EDITOR:-}"
  if   [ -n "$ed" ];                     then "$ed" "$f"
  elif command -v code >/dev/null 2>&1;  then code "$f"
  elif command -v open >/dev/null 2>&1;  then open "$f"
  else dk_err "未找到编辑器(设置 \$EDITOR 或安装 code)。"; return 1; fi
}
dk_logs_grep() {  # dk_logs_grep <pattern> [glob_prefix]
  local pat="$1" pre="${2:-}"
  [ -n "$pat" ] || { dk_err "用法:--grep <pattern>"; return 1; }
  grep -rniE --color=auto "$pat" "$DK_LOGS_DIR/${pre}"*.log 2>/dev/null \
    || dk_dim "(无匹配:$pat)"
}
dk_logs_clean() {  # dk_logs_clean [glob_prefix]
  local pre="${1:-}" cnt
  # shellcheck disable=SC2012  # 仅统计数量;日志名由本工具生成,无空白/换行
  cnt="$(ls -1 "$DK_LOGS_DIR/${pre}"*.log 2>/dev/null | wc -l | tr -d ' ')"
  rm -f "$DK_LOGS_DIR/${pre}"*.log
  dk_ok "已清理 ${cnt} 份日志(保留 logs/.gitignore)。"
}
