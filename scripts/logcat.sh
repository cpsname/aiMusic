#!/usr/bin/env bash
#
# logcat.sh — 终端版「Logcat 面板」(替代 Android Studio 的 Logcat,仅 Android)
#
# 可移植:把整个 scripts/ 目录(含 lib/)丢进任意 Flutter 项目即可用;项目根
# 向上查找 pubspec.yaml 自动定位,applicationId 自动从 build.gradle(.kts) 读取。
#
# 产品化能力:
#   · 默认只看当前 app 进程(按 applicationId 取 pid,logcat --pid 过滤)
#   · 进程被杀/重启后自动重新附加新 pid(对齐 Android Studio Logcat;Ctrl-C 退出)
#   · 多设备时弹选择器(adb devices),单设备自动选中,记住上次设备
#   · 按级别着色(E/F/A 红 · W 黄 · I 默认 · D/V 灰),纯文本落盘 logs/logcat_*.log
#   · 自带日志子命令:--tail/--open/--grep/--list/--clean
#
# 用法:
#   ./scripts/logcat.sh                 # 选设备 → 只看本 app 进程
#   ./scripts/logcat.sh -a              # 全系统(放开 pid 过滤)
#   ./scripts/logcat.sh -s <serial>     # 指定设备(adb devices 查看)
#   ./scripts/logcat.sh -c              # 先清空 logcat 缓冲
#   ./scripts/logcat.sh '*:E'           # 追加任意 logcat 过滤表达式(原样透传)
#   ./scripts/logcat.sh --tail|--open|--grep <pat>|--list|--clean   # 日志管理
#
# 说明:dev.sh 覆盖 Dart/Flutter 层(对应 IDE 的 Run);本脚本覆盖 Android 系统层
#       (对应 Logcat)。iOS 无 logcat —— 系统日志走 Console.app 或 idevicesyslog。
#
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/devkit.sh
. "$SCRIPT_DIR/lib/devkit.sh" || { echo "✗ 缺少 lib/devkit.sh(请连同 scripts/lib 一起复制)" >&2; exit 1; }

# ---- 参数解析 ----
ALL=0; CLEAR=0; SERIAL="${ANDROID_SERIAL:-}"; LOGCMD=""; LOGARG=""
PASS=()
while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help)   awk 'NR>1{ if(/^#/) print; else exit }' "$0"; exit 0 ;;
    -a|--all)    ALL=1; shift ;;
    -c|--clear)  CLEAR=1; shift ;;
    -s|--serial) dk_need_arg "$1" $#; SERIAL="$2"; shift 2 ;;
    --serial=*)  SERIAL="${1#*=}"; shift ;;
    -y|--yes)    DK_YES=1; export DK_YES; shift ;;
    --tail)      LOGCMD="tail"; shift ;;
    --open)      LOGCMD="open"; shift ;;
    --list)      LOGCMD="list"; shift ;;
    --clean)     LOGCMD="clean"; shift ;;
    --grep)      dk_need_arg "$1" $#; LOGCMD="grep"; LOGARG="$2"; shift 2 ;;
    --grep=*)    LOGCMD="grep"; LOGARG="${1#*=}"; shift ;;
    *)           PASS+=("$1"); shift ;;
  esac
done

ROOT="$(dk_find_root "$PWD" "$SCRIPT_DIR")" || { dk_err "未找到 Flutter 项目(缺 pubspec.yaml)。"; exit 1; }
dk_init_logs "$ROOT"

# ---- 日志子命令 ----
case "$LOGCMD" in
  tail)  dk_logs_tail logcat-latest.log; exit $? ;;
  open)  dk_logs_open logcat-latest.log; exit $? ;;
  list)  dk_logs_list logcat; exit 0 ;;
  grep)  dk_logs_grep "$LOGARG" logcat; exit $? ;;
  clean) dk_logs_clean logcat; exit 0 ;;
esac

# ---- 定位 adb ----
ADB="$(command -v adb 2>/dev/null || true)"
if [ -z "$ADB" ]; then
  for c in "${ANDROID_HOME:-}/platform-tools/adb" "${ANDROID_SDK_ROOT:-}/platform-tools/adb" \
           "$HOME/Library/Android/sdk/platform-tools/adb" "$HOME/Android/Sdk/platform-tools/adb"; do
    [ -n "$c" ] && [ -x "$c" ] && { ADB="$c"; break; }
  done
fi
[ -z "$ADB" ] && { dk_err "未找到 adb。请安装 Android SDK,或设置 ANDROID_HOME / ANDROID_SDK_ROOT。"; exit 127; }

# ---- 设备:-s > 上次(在线) > 单个自动 > 多个选择器 ----
DEVLINES="$("$ADB" devices -l | awk 'NR>1 && $2=="device"{print}')"
if [ -z "$DEVLINES" ]; then
  dk_err "未检测到已连接的 Android 设备/模拟器。"
  UNAUTH="$("$ADB" devices | awk 'NR>1 && ($2=="unauthorized" || $2=="offline"){printf "%s(%s) ", $1, $2}')"
  [ -n "$UNAUTH" ] && dk_warn "存在未就绪设备:${UNAUTH}—— unauthorized 需在设备上允许 USB 调试。"
  dk_dim "  · 启动模拟器或连真机开 USB 调试;自检:adb devices"
  dk_dim "  · iOS 无 logcat —— 用 Console.app 或 idevicesyslog"
  exit 1
fi
if [ -z "$SERIAL" ]; then
  pref="$(dk_pref_get serial 2>/dev/null || true)"
  if [ -n "$pref" ] && printf '%s\n' "$DEVLINES" | awk '{print $1}' | grep -qx "$pref"; then
    SERIAL="$pref"
  fi
fi
if [ -z "$SERIAL" ]; then
  serials=(); labels=()
  while read -r line; do
    [ -n "$line" ] || continue
    s="$(printf '%s' "$line" | awk '{print $1}')"
    model="$(printf '%s' "$line" | grep -oE 'model:[^ ]+' | cut -d: -f2)"
    serials+=("$s"); labels+=("$(printf '%-22s %s%s%s' "$s" "$DK_DIM" "${model:-}" "$DK_RST")")
  done <<EOF
$DEVLINES
EOF
  if [ "${#serials[@]}" -eq 1 ]; then
    SERIAL="${serials[0]}"
  elif dk_is_interactive; then
    sel="$(dk_menu "选择 Android 设备(${#serials[@]}):" 1 "" -- "${labels[@]}")"; rc=$?
    [ "$rc" -eq 130 ] && exit 0
    [ "$rc" -ne 0 ] && exit 1
    SERIAL="${serials[$((sel-1))]}"
  else
    SERIAL="${serials[0]}"; dk_warn "多设备但非交互,默认用 ${SERIAL}(用 -s 指定)。"
  fi
fi
dk_pref_set serial "$SERIAL"
SOPT="-s $SERIAL"

# ---- applicationId ----
GRADLE="$ROOT/android/app/build.gradle.kts"; [ -f "$GRADLE" ] || GRADLE="$ROOT/android/app/build.gradle"
APP_ID="$(grep -E '^[[:space:]]*applicationId' "$GRADLE" 2>/dev/null | grep -oE '"[^"]+"' | head -1 | tr -d '"')"

# ---- 日志文件 + 轮转 ----
CAT_LOG="$(dk_new_log logcat logcat-latest.log)"
dk_rotate logcat 20
export LOGFILE="$CAT_LOG"

# ---- pid 过滤(进程重启自动重新附加)----
# shellcheck disable=SC2086  # $SOPT 形如 "-s <serial>",需要分词
lc_pidof() { "$ADB" $SOPT shell pidof "$APP_ID" 2>/dev/null | tr -d '\r' | awk '{print $1}'; }
# shellcheck disable=SC2086
lc_device_online() { "$ADB" $SOPT get-state >/dev/null 2>&1; }

lc_wait_pid() {  # lc_wait_pid <max_tries>(0=无限) [quiet];回显 pid;rc1 超时,rc2 设备离线
  local max="$1" quiet="${2:-}" i=0 pid
  while :; do
    pid="$(lc_pidof)"
    [ -n "$pid" ] && { printf '%s\n' "$pid"; return 0; }
    lc_device_online || return 2
    i=$((i+1))
    [ "$i" -eq 1 ] && [ -z "$quiet" ] && dk_dim "等待 ${APP_ID} 启动中…(在设备打开 app,或另开终端跑 ./scripts/dev.sh)"
    [ "$max" -gt 0 ] && [ "$i" -ge "$max" ] && return 1
    sleep 1
  done
}

# 跟随一个 pid 的 logcat;进程退出/重启则定位新 pid 自动重新附加(对齐 Android
# Studio Logcat)。stdout 进着色管道,提示走 stderr;设备断开时干净退出。
lc_follow() {
  local pid="$1" lcpid cur
  while :; do
    # shellcheck disable=SC2086
    "$ADB" $SOPT logcat -v time --pid="$pid" "${PASS[@]+"${PASS[@]}"}" &
    lcpid=$!; cur=""
    while :; do
      sleep 2
      kill -0 "$lcpid" 2>/dev/null || break        # logcat 自身退出(设备断开等)
      cur="$(lc_pidof)"
      [ "$cur" = "$pid" ] || break                 # 进程退出,或已换新 pid
    done
    kill "$lcpid" 2>/dev/null; wait "$lcpid" 2>/dev/null
    lc_device_online || { dk_err "设备 ${SERIAL} 已断开。"; return 1; }
    if [ -n "$cur" ] && [ "$cur" != "$pid" ]; then
      pid="$cur"                                   # 快速重启,直接换 pid
    else
      dk_warn "${APP_ID} 进程已退出,等待重启后自动重新附加…(Ctrl-C 退出)"
      pid="$(lc_wait_pid 0 quiet)" || { dk_err "设备 ${SERIAL} 已断开。"; return 1; }
    fi
    dk_ok "已重新附加 ${APP_ID} (pid=${pid})"
  done
}

PID=""
if [ "$ALL" -eq 0 ]; then
  if [ -z "$APP_ID" ]; then
    dk_warn "未能从 ${GRADLE} 解析 applicationId,改为全量(可用 -a 显式全量)。"
  else
    dk_dim "目标包名: ${APP_ID}  设备: ${SERIAL}"
    PID="$(lc_wait_pid 30)"; rc=$?
    if [ "$rc" -eq 2 ]; then dk_err "设备 ${SERIAL} 已断开。"; exit 1
    elif [ -z "$PID" ]; then dk_warn "等待超时,未发现 ${APP_ID},改为全量。"
    else dk_ok "已定位 pid=${PID},仅看该进程(重启自动重新附加)"; fi
  fi
fi

# shellcheck disable=SC2086
[ "$CLEAR" -eq 1 ] && { "$ADB" $SOPT logcat -c 2>/dev/null || true; }

cleanup() { printf '\n%s▸ 本次 logcat 已保存:%s%s\n' "$DK_DIM" "$CAT_LOG" "$DK_RST" >&2; }
trap cleanup EXIT

MODE="全系统"; [ -n "$PID" ] && MODE="进程 ${APP_ID} (pid=${PID},重启自动重附加)"
dk_say "▶ adb logcat"
dk_dim "  ${MODE}  设备: ${SERIAL}"
dk_dim "  日志: ${CAT_LOG}  (软链 logs/logcat-latest.log) · Ctrl-C 退出"

# adb logcat -v time 自带设备时间戳与级别;dk_colorize 着色(屏幕)+落盘(纯文本)
if [ -n "$PID" ]; then
  lc_follow "$PID" | dk_colorize logcat
else
  # shellcheck disable=SC2086
  "$ADB" $SOPT logcat -v time "${PASS[@]+"${PASS[@]}"}" | dk_colorize logcat
fi
