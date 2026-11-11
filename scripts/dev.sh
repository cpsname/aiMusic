#!/usr/bin/env bash
#
# dev.sh — 终端版「Run 控制台」(替代 IDE 的 Run 按钮 / Dart·Flutter 层日志)
#
# 可移植:把整个 scripts/ 目录(dev.sh + logcat.sh + lib/)丢进任意 Flutter
# 项目即可用;项目根目录向上查找 pubspec.yaml 自动定位,无任何项目硬编码。
#
# 产品化能力:
#   · 不带 -d 时弹出设备选择器(flutter devices),单设备自动选中,可启动模拟器
#   · 入口自动定位:有 lib/main.dart 直接用;否则探测,多入口时选择(-t 指定可记住)
#   · 记住上次的设备/模式/入口,下次默认复用
#   · 按日志级别着色(仅屏幕)、每行加 HH:MM:SS、纯文本落盘 logs/run_*.log(+latest.log)
#     run 日志「用完即清」:正常/错误/中断/Ctrl-C/被 kill 退出都删除(崩溃残留下次启动回收);
#     --keep-log 或 DEV_KEEP_LOG=1 永久保留,DEV_KEEP_LOG=on-error 仅崩溃保留
#   · 保留 r/R/q 交互(用 script 分配 PTY;macOS BSD 与 Linux util-linux 都支持)
#   · 自带日志子命令:--tail/--open/--grep/--list/--clean
#
# 用法:
#   ./scripts/dev.sh                         # 选设备 → 跑(复用上次/单设备自动)
#   ./scripts/dev.sh -d <deviceId>           # 指定设备(跳过选择器,可脚本化)
#   ./scripts/dev.sh -p | -r                 # profile / release 模式
#   ./scripts/dev.sh -t lib/main_dev.dart    # 指定入口(否则自动定位;选择会被记住)
#   ./scripts/dev.sh --flavor dev            # 其余参数透传给 flutter run
#   ./scripts/dev.sh --dart-define-from-file=config/dev.json   # 配置(透传给 flutter)
#   ./scripts/dev.sh -y                       # 非交互(用上次/默认,适合 CI)
#   ./scripts/dev.sh --tail | --open | --grep <pat> | --list | --clean   # 日志管理
#   ./scripts/dev.sh --keep-log               # 保留本次日志(默认退出即清);DEV_KEEP_LOG=on-error 仅崩溃保留
#   NO_COLOR=1 ./scripts/dev.sh               # 关闭着色
#
# 交互键(原样透传给 flutter):r 热重载 · R 热重启 · q 退出 · h 帮助
#
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/devkit.sh
. "$SCRIPT_DIR/lib/devkit.sh" || { echo "✗ 缺少 lib/devkit.sh(请连同 scripts/lib 一起复制)" >&2; exit 1; }

# ---- 参数解析 ----
DEVICE=""; MODE=""; TARGET=""; LOGCMD=""; LOGARG=""; DK_KEEP=""
PASS=()
while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help)    awk 'NR>1{ if(/^#/) print; else exit }' "$0"; exit 0 ;;
    -d|--device)  dk_need_arg "$1" $#; DEVICE="$2"; shift 2 ;;
    --device=*)   DEVICE="${1#*=}"; shift ;;
    -t|--target)  dk_need_arg "$1" $#; TARGET="$2"; shift 2 ;;
    --target=*)   TARGET="${1#*=}"; shift ;;
    --mode)       dk_need_arg "$1" $#; MODE="$2"; shift 2 ;;
    --mode=*)     MODE="${1#*=}"; shift ;;
    -p|--profile) MODE=profile; shift ;;
    -r|--release) MODE=release; shift ;;
    -y|--yes)     DK_YES=1; export DK_YES; shift ;;
    --tail)       LOGCMD="tail"; shift ;;
    --open)       LOGCMD="open"; shift ;;
    --list)       LOGCMD="list"; shift ;;
    --clean)      LOGCMD="clean"; shift ;;
    --grep)       dk_need_arg "$1" $#; LOGCMD="grep"; LOGARG="$2"; shift 2 ;;
    --grep=*)     LOGCMD="grep"; LOGARG="${1#*=}"; shift ;;
    --keep-log)   DK_KEEP=1; shift ;;
    *)            PASS+=("$1"); shift ;;
  esac
done

ROOT="$(dk_find_root "$PWD" "$SCRIPT_DIR")" || { dk_err "未找到 Flutter 项目(缺 pubspec.yaml)。"; exit 1; }
FLUTTER="$(dk_flutter_bin "$ROOT")"
dk_init_logs "$ROOT"

# ---- 日志子命令(不跑 flutter,直接处理后退出)----
case "$LOGCMD" in
  tail)  dk_logs_tail latest.log; exit $? ;;
  open)  dk_logs_open latest.log; exit $? ;;
  list)  dk_logs_list run; exit 0 ;;
  grep)  dk_logs_grep "$LOGARG" run; exit $? ;;
  clean) dk_logs_clean run; exit 0 ;;
esac

dk_require "${FLUTTER%% *}" "请安装并加入 PATH" || exit 127
dk_require perl || exit 127

# ---- 设备:-d > 上次 > 选择器 ----
if [ -z "$DEVICE" ]; then
  preselect="$(dk_pref_get device 2>/dev/null || true)"
  DEVICE="$(dk_pick_flutter_device "$FLUTTER" "$preselect")"; rc=$?
  [ "$rc" -eq 130 ] && exit 0
fi

# ---- 入口(-t):显式 > 上次 > lib/main.dart > 探测/选择 ----
TARGET="$(dk_resolve_target "$ROOT" "$TARGET" "$(dk_pref_get target 2>/dev/null || true)")"; rc=$?
[ "$rc" -eq 130 ] && exit 0

# ---- 模式:flag > 上次 > debug ----
[ -z "$MODE" ] && MODE="$(dk_pref_get mode 2>/dev/null || true)"
[ -z "$MODE" ] && MODE=debug
case "$MODE" in debug|profile|release) ;; *) dk_warn "未知模式 ${MODE} → 改用 debug"; MODE=debug ;; esac

# ---- 记忆本次选择 ----
[ -n "$DEVICE" ]   && dk_pref_set device "$DEVICE"
[ -n "$TARGET" ]   && dk_pref_set target "$TARGET"
dk_pref_set mode "$MODE"

# ---- 组装命令 ----
read -r -a RUN <<< "$FLUTTER"       # "fvm flutter" 需按词拆开
RUN+=(--no-color run)
[ -n "$DEVICE" ]        && RUN+=(-d "$DEVICE")
[ -n "$TARGET" ]        && RUN+=(-t "$TARGET")
[ "$MODE" = profile ]   && RUN+=(--profile)
[ "$MODE" = release ]   && RUN+=(--release)
RUN+=("${PASS[@]+"${PASS[@]}"}")

# ---- 日志文件(用完即清:任何终止都删本次 run 日志)----
RUN_LOG="$(dk_new_log run latest.log)"
export LOGFILE="$RUN_LOG"
dk_lock_run "$RUN_LOG"
# keep 策略:--keep-log / DEV_KEEP_LOG=1|always 永久保留;=on-error 仅崩溃保留;默认即清。
DK_KEEP="${DK_KEEP:-${DEV_KEEP_LOG:-0}}"
[ "$DK_KEEP" != 0 ] && dk_rotate run 20   # 仅保留模式才轮转累积(默认即清,无需轮转)

_dev_cleaned=""
cleanup() {  # cleanup [exit_code] [signaled]
  [ -n "$_dev_cleaned" ] && return; _dev_cleaned=1
  wait 2>/dev/null || true                 # 让管道(perl 写入方)收尾,再删
  if dk_should_keep "$DK_KEEP" "${1:-0}" "${2:-0}"; then
    printf '\n%s▸ 本次日志已保留:%s%s\n' "$DK_DIM" "$RUN_LOG" "$DK_RST" >&2
    [ -n "${DK_RUN_LOCK:-}" ] && rm -f "$DK_RUN_LOCK"
  else
    dk_discard_log "$RUN_LOG" latest.log
  fi
}
# 信号即用户主动停止 → 清理后重抛默认动作(退出码 130 等),不吞信号。
on_signal() { cleanup 130 1; trap - "$1"; kill -"$1" "$$"; }
trap 'cleanup "$?" 0' EXIT
trap 'on_signal INT'  INT
trap 'on_signal TERM' TERM
trap 'on_signal HUP'  HUP

dk_say "▶ flutter run"
dk_dim "  项目: ${ROOT}"
dk_dim "  设备: ${DEVICE:-<flutter 默认>}    模式: ${MODE}    入口: ${TARGET:-lib/main.dart}"
dk_dim "  日志: ${RUN_LOG}  (运行期 logs/latest.log;退出即清,--keep-log 保留)"
dk_dim "  交互: r 热重载 · R 热重启 · q 退出"

cd "$ROOT" || exit 1
# script 分配 PTY 保留交互;flutter --no-color 不产色码;dk_colorize 着色(屏幕)+落盘(纯文本)
dk_run_pty "${RUN[@]}" | dk_colorize flutter
