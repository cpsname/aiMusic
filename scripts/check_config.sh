#!/usr/bin/env bash
#
# check_config.sh — dart-define 配置文件校验器(供根 Makefile 的 GUARD 调用,也可手动跑)
#
# 可移植 + 配置无关:纯 bash + perl(JSON::PP / MIME::Base64,均为 perl 核心模块,
# macOS/Linux 自带)。校验哪些 key、执行哪种环境策略全部由参数传入 —— 项目相关的
# key 清单写在根 Makefile 里,本脚本可原样复制进任何 Flutter 项目。
#
# 用法:
#   check_config.sh <config.json> [--require KEY]... [--expect-env NAME]
#                   [--https] [--no-localhost] [--no-placeholder]
#   check_config.sh <config.json> --verify-xcconfig <Generated.xcconfig>
#
#   --require KEY        该 key 必须存在且值非空(可重复)
#   --expect-env NAME    config 的 ENV 字段必须等于 NAME(防拿错环境文件)
#   --https              BASE_URL 必须以 https:// 开头(store 构建)
#   --no-localhost       BASE_URL 不得指向 localhost/127.0.0.1/10.0.2.2 等本机地址
#   --no-placeholder     值不得以 REPLACE 开头(dev.example.json 占位符未填)
#   --expect KEY=VALUE   KEY 的值必须严格等于 VALUE(可重复)
#   --match KEY=REGEX    KEY 的值必须匹配 Perl 正则 REGEX(可重复;自行写 ^…$ 锚定)
#   --forbid-host H      BASE_URL 的主机不得为 H(可重复)。H 为 host 时任意端口都拒,
#                        为 host:port 时只拒该端口 —— 用来挡「后端地址填成了别的服务」
#   --verify-xcconfig F  解码 F 中的 DART_DEFINES(逗号分隔 base64 KEY=VALUE),
#                        逐 key 与 config 比对并打印将打包的 ENV / BASE_URL ——
#                        防止 Xcode Archive 把上一次 `make run` 的 dev 配置打进包里
#
# 退出码:0 通过 · 1 校验失败 · 2 用法/环境错误
#
set -uo pipefail

err() { printf '✗ %s\n' "$*" >&2; }

CONFIG="${1:-}"
case "$CONFIG" in
  -h|--help) awk 'NR>1{ if(/^#/) print; else exit }' "$0"; exit 0 ;;
esac
[ -n "$CONFIG" ] || { err "用法:check_config.sh <config.json> [选项…](-h 查看)"; exit 2; }
shift
[ -f "$CONFIG" ] || { err "配置文件不存在:$CONFIG"; exit 2; }

REQUIRE=(); EXPECT=(); MATCH=(); FORBID_HOST=(); EXPECT_ENV=""; HTTPS=0; NO_LOCALHOST=0; NO_PLACEHOLDER=0; XCCONFIG=""
need_arg() { [ "$2" -ge 2 ] || { err "选项 $1 缺少参数"; exit 2; }; }
while [ $# -gt 0 ]; do
  case "$1" in
    --require)         need_arg "$1" $#; REQUIRE+=("$2"); shift 2 ;;
    --expect)          need_arg "$1" $#; case "$2" in *=*) ;; *) err "--expect 需要 KEY=VALUE:$2"; exit 2 ;; esac; EXPECT+=("$2"); shift 2 ;;
    --match)           need_arg "$1" $#; case "$2" in *=*) ;; *) err "--match 需要 KEY=REGEX:$2"; exit 2 ;; esac; MATCH+=("$2"); shift 2 ;;
    --forbid-host)     need_arg "$1" $#; FORBID_HOST+=("$2"); shift 2 ;;
    --expect-env)      need_arg "$1" $#; EXPECT_ENV="$2"; shift 2 ;;
    --https)           HTTPS=1; shift ;;
    --no-localhost)    NO_LOCALHOST=1; shift ;;
    --no-placeholder)  NO_PLACEHOLDER=1; shift ;;
    --verify-xcconfig) need_arg "$1" $#; XCCONFIG="$2"; shift 2 ;;
    *)                 err "未知选项:$1(-h 查看用法)"; exit 2 ;;
  esac
done

command -v perl >/dev/null 2>&1 || { err "需要 perl(macOS/Linux 自带)"; exit 2; }
perl -MJSON::PP -MMIME::Base64 -e1 2>/dev/null \
  || { err "perl 缺少核心模块 JSON::PP / MIME::Base64"; exit 2; }

export CC_REQUIRE="${REQUIRE[*]+${REQUIRE[*]}}"
# 值里可能有空格 / 正则元字符:用 ASCII 单元分隔符(\x1f)拼接,perl 侧按它拆,不按空格拆。
join_us() { local IFS=$'\x1f'; printf '%s' "$*"; }
CC_EXPECT="$(join_us ${EXPECT[@]+"${EXPECT[@]}"})"
CC_MATCH="$(join_us ${MATCH[@]+"${MATCH[@]}"})"
CC_FORBID_HOST="$(join_us ${FORBID_HOST[@]+"${FORBID_HOST[@]}"})"
export CC_EXPECT CC_MATCH CC_FORBID_HOST
export CC_EXPECT_ENV="$EXPECT_ENV" CC_HTTPS="$HTTPS" CC_NO_LOCALHOST="$NO_LOCALHOST"
export CC_NO_PLACEHOLDER="$NO_PLACEHOLDER" CC_XCCONFIG="$XCCONFIG"

perl -e '
use strict; use warnings;
use JSON::PP; use MIME::Base64 qw(decode_base64);

my $path = shift @ARGV;
open my $fh, "<", $path or do { print STDERR qq{✗ 无法读取 $path: $!\n}; exit 2 };
my $raw = do { local $/; <$fh> }; close $fh;
my $cfg = eval { JSON::PP->new->decode($raw) };
if (!defined $cfg || ref $cfg ne q{HASH}) {
  print STDERR qq{✗ $path 不是合法的 JSON 对象\n}; exit 1;
}

my @fail;
# 敏感 key 的值绝不进消息/日志(构建日志常被上传 CI),只显示长度。
my $mask = sub {
  my ($k, $v) = @_;
  return $v unless $k =~ /secret|token|passw|private|credential/i;
  return length($v) ? qq{<redacted len=} . length($v) . q{>} : q{};
};
my @req = grep { length } split / /, ($ENV{CC_REQUIRE} // q{});
for my $k (@req) {
  my $v = $cfg->{$k};
  if (!defined $v || !length qq{$v}) { push @fail, qq{缺少或为空:$k}; next }
  push @fail, qq{$k 仍是占位符(值以 REPLACE 开头)—— 请填入真实值}
    if $ENV{CC_NO_PLACEHOLDER} && qq{$v} =~ /^REPLACE/;
}
if (length($ENV{CC_EXPECT_ENV} // q{})) {
  my $e = $cfg->{ENV} // q{};
  push @fail, qq{ENV="$e" 与目标环境 "$ENV{CC_EXPECT_ENV}" 不一致(拿错配置文件?)}
    unless $e eq $ENV{CC_EXPECT_ENV};
}
my $base = $cfg->{BASE_URL} // q{};
push @fail, qq{BASE_URL 必须是 https://(当前:$base)}
  if $ENV{CC_HTTPS} && $base !~ m{^https://};
push @fail, qq{BASE_URL 指向本机地址,store 构建禁止(当前:$base)}
  if $ENV{CC_NO_LOCALHOST}
  && $base =~ m{^https?://(?:localhost|127\.0\.0\.1|0\.0\.0\.0|10\.0\.2\.2|\[::1\])(?::|/|$)}i;

for my $pair (grep { length } split /\x1f/, ($ENV{CC_EXPECT} // q{})) {
  my ($k, $want) = split /=/, $pair, 2;
  my $v = $cfg->{$k}; $v = defined $v ? qq{$v} : q{};
  push @fail, sprintf(qq{%s="%s" 必须是 "%s"}, $k, $mask->($k, $v), $want) unless $v eq $want;
}
for my $pair (grep { length } split /\x1f/, ($ENV{CC_MATCH} // q{})) {
  my ($k, $re) = split /=/, $pair, 2;
  my $v = $cfg->{$k}; $v = defined $v ? qq{$v} : q{};
  my $ok = eval { $v =~ /$re/ };
  if ($@) { print STDERR qq{✗ --match $k 的正则非法:$re\n}; exit 2 }
  push @fail, sprintf(qq{%s="%s" 不匹配 /%s/}, $k, $mask->($k, $v), $re) unless $ok;
}
if (my @forbid = grep { length } split /\x1f/, ($ENV{CC_FORBID_HOST} // q{})) {
  my ($host, $port) = $base =~ m{^https?://(\[[^\]]+\]|[^/:?#]+)(?::(\d+))?}i;
  if (defined $host) {
    $host = lc $host;
    my $authority = defined $port ? qq{$host:$port} : $host;
    for my $f (map { lc } @forbid) {
      my $hit = $f =~ /:\d+$/ ? $authority eq $f : $host eq $f;
      push @fail, qq{BASE_URL 指向禁用的主机 $f(当前:$base)—— 后端地址填成了别的服务?} if $hit;
    }
  }
}

# ---- xcconfig 反解比对(Xcode Archive 防呆)----
if (length($ENV{CC_XCCONFIG} // q{})) {
  my $xp = $ENV{CC_XCCONFIG};
  if (open my $xf, "<", $xp) {
    my $xc = do { local $/; <$xf> }; close $xf;
    if ($xc =~ /^DART_DEFINES=(.*)$/m) {
      my %def;
      for my $b64 (split /,/, $1) {
        my $kv = decode_base64($b64);
        $def{$1} = $2 if $kv =~ /^([^=]+)=(.*)$/s;
      }
      for my $k (sort keys %$cfg) {
        my $want = $cfg->{$k}; $want = defined $want ? qq{$want} : q{};
        my $got  = $def{$k};
        if (!defined $got) {
          push @fail, qq{xcconfig 缺少 dart-define:$k(重跑对应的 make xcconfig)};
        } elsif ($got ne $want) {
          push @fail, sprintf(qq{xcconfig 的 %s="%s" ≠ 配置 "%s"(xcconfig 已过期 —— 重跑 make xcconfig)},
                              $k, $mask->($k, $got), $mask->($k, $want));
        }
      }
      printf qq{▸ 将打包的 dart-define:ENV=%s  BASE_URL=%s\n},
             $def{ENV} // q{?}, $def{BASE_URL} // q{?}
        unless @fail;
    } else {
      push @fail, qq{$xp 没有 DART_DEFINES 行(先跑对应的 --config-only 构建)};
    }
  } else {
    push @fail, qq{无法读取 $xp: $!(先跑对应的 --config-only 构建)};
  }
}

if (@fail) {
  print STDERR qq{✗ 配置校验失败:$path\n};
  print STDERR qq{  · $_\n} for @fail;
  exit 1;
}
print qq{✓ 配置校验通过:$path} . (@req ? q{(} . scalar(@req) . q{ keys)} : q{}) . qq{\n};
' -- "$CONFIG"
