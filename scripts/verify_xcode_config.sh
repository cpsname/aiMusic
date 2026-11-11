#!/usr/bin/env bash
#
# verify_xcode_config.sh — Xcode 侧的 dart-define 闸门(供 Runner target 的
# 「Verify Build Config」build phase 调用,也可经 `make verify-xcode-config` 手动跑)
#
# 为什么需要它:Makefile 里的 GUARD/GUARD_SHIP 只在你用 make 时才生效,而 Xcode 的
# Run / Archive 按钮完全绕开它们。Xcode 不认识 --dart-define-from-file,它只读
# Flutter 生成的 xcconfig 里的 DART_DEFINES,而那个文件的内容由**最后一次** flutter
# 命令写入:
#   · 上一次是 `make run`  → Archive 出来的是 dev 配置的 release 包;
#   · 上一次是裸 `flutter run` / `flutter build` → 这些键被整段抹掉,打出来的包没有
#     BASE_URL / 分发码 / 签名密钥,上架后每个用户的 /v1/* 都被签名中间件拒
#     (40110 / 40114 / 40304),App 完全不可用。
# 所以校验必须挂在构建链本身上,而不是只挂在 make 上。
#
# 可移植 + 配置无关:key 清单由调用方传入(项目相关的清单写在根 Makefile 的
# REQUIRED_KEYS 里),本脚本可原样复制进任何 Flutter 项目。
#
# 用法:
#   verify_xcode_config.sh <xcconfig> [--require KEY]... [--config-dir DIR] [--require-prod]
#
#   <xcconfig>         ios/Flutter/Generated.xcconfig 或
#                      macos/Flutter/ephemeral/Flutter-Generated.xcconfig
#   --require KEY      该 key 必须出现在 DART_DEFINES 且值非空(可重复)
#   --config-dir DIR   config/ 目录(默认 config);存在 <DIR>/<ENV>.json 时额外用
#                      check_config.sh --verify-xcconfig 做逐 key 比对,抓「xcconfig
#                      比 config 文件旧」的情况
#   --require-prod     要求 ENV=prod(Xcode 传入 CONFIGURATION=Release 时自动开启)
#   --expect KEY=VALUE / --match KEY=REGEX / --forbid-host H
#                      透传给 check_config.sh,作用于 xcconfig 里**实际要打包**的 dart-define
#                      (语义见 check_config.sh -h)。仅 ENV=prod 或要求 prod 的
#                      构建执行这组规则;开发调试允许自定义身份和后端地址。
#
# 退出码:0 通过 · 1 校验失败 · 2 用法/环境错误
#
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Xcode 把以 "error:" 开头的行渲染成构建错误;命令行下也照样醒目。
fail() {
  echo "error: $1" >&2
  shift
  for line in "$@"; do echo "note: $line" >&2; done
  exit 1
}

XCCONFIG="${1:-}"
case "$XCCONFIG" in
  -h|--help) awk 'NR>1{ if(/^#/) print; else exit }' "$0"; exit 0 ;;
esac
[ -n "$XCCONFIG" ] || { echo "✗ 用法:verify_xcode_config.sh <xcconfig> [选项…](-h 查看)" >&2; exit 2; }
shift

REQUIRE=(); RULES=(); CONFIG_DIR="config"; REQUIRE_PROD=0
[ "${CONFIGURATION:-}" = "Release" ] && REQUIRE_PROD=1
while [ $# -gt 0 ]; do
  case "$1" in
    --require)      [ $# -ge 2 ] || { echo "✗ --require 缺少参数" >&2; exit 2; }; REQUIRE+=("$2"); shift 2 ;;
    --config-dir)   [ $# -ge 2 ] || { echo "✗ --config-dir 缺少参数" >&2; exit 2; }; CONFIG_DIR="$2"; shift 2 ;;
    --require-prod) REQUIRE_PROD=1; shift ;;
    --expect|--match|--forbid-host)
                    [ $# -ge 2 ] || { echo "✗ $1 缺少参数" >&2; exit 2; }; RULES+=("$1" "$2"); shift 2 ;;
    *)              echo "✗ 未知选项:$1(-h 查看用法)" >&2; exit 2 ;;
  esac
done

HINT_CLI="CLI:用 \`make run\` / \`make ipa\`,它们会注入 --dart-define-from-file。"
HINT_XCODE="Xcode:Archive 前先跑 \`make xcconfig\`(prod)或 \`make ios\`(dev)。"

[ -f "$XCCONFIG" ] || fail \
  "$XCCONFIG 不存在 —— 这次构建没有经过 flutter 工具链。" "$HINT_XCODE"

DEFINES_LINE="$(grep '^DART_DEFINES=' "$XCCONFIG" | head -1 | cut -d= -f2-)"
# `printf '%s\n'` (not '%s'): without the trailing newline the final entry has
# no line terminator and `read` drops it — silently losing the last dart-define.
[ -n "$DEFINES_LINE" ] && DECODED="$(
  printf '%s\n' "$DEFINES_LINE" | tr ',' '\n' | while IFS= read -r item; do
    [ -n "$item" ] && printf '%s\n' "$(printf '%s' "$item" | base64 --decode 2>/dev/null)"
  done
)" || DECODED=""

value_of() { printf '%s\n' "$DECODED" | grep "^$1=" | head -1 | cut -d= -f2-; }

MISSING=""
# 数组可能为空:bash 3.2 + set -u 下直接展开会报 unbound,先判长度。
if [ "${#REQUIRE[@]}" -gt 0 ]; then
  for key in "${REQUIRE[@]}"; do
    [ -z "$(value_of "$key")" ] && MISSING="$MISSING $key"
  done
fi
[ -n "$MISSING" ] && fail \
  "构建配置缺失:${MISSING# } —— 这个包无法通过后端签名校验(40110 / 40114 / 40304)。" \
  "$HINT_CLI" "$HINT_XCODE"

ENV_VALUE="$(value_of ENV)"
[ "$REQUIRE_PROD" = "1" ] && [ "$ENV_VALUE" != "prod" ] && fail \
  "Release 构建携带的是 ENV=${ENV_VALUE:-<empty>} 的配置,不是 prod。" \
  "xcconfig 保留的是上一次 flutter 命令(多半是 \`make run\`)写入的配置。" \
  "Archive 前先跑 \`make xcconfig\`;或直接用 \`make ipa\` 出包。"

# 生产身份 / 地址规则作用于实际要打包的值。Debug 的 dev/staging/mock 可自定义;
# 把生产 KEY=VALUE 写成临时 JSON,复用 check_config.sh 的同一套判据。
if [ "${#RULES[@]}" -gt 0 ] && { [ "$ENV_VALUE" = "prod" ] || [ "$REQUIRE_PROD" = "1" ]; }; then
  RULES_JSON="$(mktemp)"
  trap 'rm -f "$RULES_JSON"' EXIT
  printf '%s\n' "$DECODED" | perl -MJSON::PP -e '
    my %h;
    while (my $l = <STDIN>) { chomp $l; my ($k, $v) = split /=/, $l, 2; $h{$k} = $v // q{} if defined $k && length $k }
    print JSON::PP->new->canonical->encode(\%h);' > "$RULES_JSON"
  bash "$SCRIPT_DIR/check_config.sh" "$RULES_JSON" "${RULES[@]}" >/dev/null \
    || fail "xcconfig 里将打包的配置违反身份 / 地址规则(见上)—— 多半是 config/${ENV_VALUE}.json 填错了后端或分发。" \
            "Songlet 只与产品域上的 BFF 通信;平台域没有 /v1/attest、/v1/templates 等端点,只会 404。" "$HINT_XCODE"
fi

# xcconfig 可能只是「旧」——键齐全但值已与 config 文件不一致。已有的
# check_config.sh --verify-xcconfig 正是干这个的,直接复用。
CONFIG_FILE="$CONFIG_DIR/${ENV_VALUE}.json"
if [ -n "$ENV_VALUE" ] && [ -f "$CONFIG_FILE" ]; then
  bash "$SCRIPT_DIR/check_config.sh" "$CONFIG_FILE" --verify-xcconfig "$XCCONFIG" \
    || fail "xcconfig 与 $CONFIG_FILE 不一致(见上)—— 重跑 \`make ios\` / \`make xcconfig\`。"
fi

echo "✓ xcode build config: ENV=$ENV_VALUE distribution=$(value_of DISTRIBUTION_CODE) baseUrl=$(value_of BASE_URL)"
