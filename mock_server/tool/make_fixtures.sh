#!/usr/bin/env bash
# Synthesizes the mock server's audio fixtures with ffmpeg (no samples, no
# licensed material): a gentle I-V-vi-IV progression (C G Am F) as a swelling
# pad + a plucked arpeggio + a soft bass, with a light echo and fades.
#
#   assets/clip_30s.mp3   exactly 30 s   44.1 kHz stereo 96 kbps
#   assets/song_120s.mp3  120 s          44.1 kHz stereo 96 kbps
#   assets/song_120s.wav  120 s          44.1 kHz stereo 16-bit PCM
#
# Usage: mock_server/tool/make_fixtures.sh   (from anywhere)
set -euo pipefail

FFMPEG="${FFMPEG:-$(command -v ffmpeg || echo /opt/homebrew/bin/ffmpeg)}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/assets"
mkdir -p "$OUT"

# One sample of the tune for channel gains ($1 pad, $2 arp, $3 bass).
# st(0) chord index (2 s per chord, 8 s loop); st(1..3) chord tones;
# st(5) arpeggio note (4 per second); every envelope reaches 0 at its segment
# boundary, so frequency switches never click.
voice() {
  local pad="$1" arp="$2" bass="$3"
  printf '%s' "st(0,floor(mod(t,8)/2));"\
"st(1,if(eq(ld(0),0),261.63,if(eq(ld(0),1),196.00,if(eq(ld(0),2),220.00,174.61))));"\
"st(2,if(eq(ld(0),0),329.63,if(eq(ld(0),1),246.94,if(eq(ld(0),2),261.63,220.00))));"\
"st(3,if(eq(ld(0),0),392.00,if(eq(ld(0),1),293.66,if(eq(ld(0),2),329.63,261.63))));"\
"st(4,mod(floor(t*4),4));"\
"st(5,2*if(eq(ld(4),0),ld(1),if(eq(ld(4),1),ld(2),if(eq(ld(4),2),ld(3),ld(2)))));"\
"st(6,mod(t,0.25));"\
"st(7,pow(1-ld(6)/0.25,2)*min(1,ld(6)*400));"\
"st(8,sin(PI*mod(t,2)/2));"\
"st(9,mod(t,0.5));"\
"${pad}*ld(8)*(sin(2*PI*ld(1)*t)+sin(2*PI*ld(2)*t)+sin(2*PI*ld(3)*t))"\
"+${arp}*ld(7)*sin(2*PI*ld(5)*t)"\
"+${bass}*pow(1-ld(9)/0.5,1.5)*min(1,ld(9)*400)*sin(PI*ld(1)*t)"
}

LEFT="$(voice 0.10 0.20 0.16)"
RIGHT="$(voice 0.12 0.14 0.16)"

render() { # $1 duration (s), $2 output wav
  local dur="$1" out="$2" fade_out_start
  fade_out_start=$(( dur - 3 ))
  "$FFMPEG" -hide_banner -loglevel error -y \
    -f lavfi -i "aevalsrc='${LEFT}|${RIGHT}':s=44100:d=${dur}" \
    -af "aecho=0.8:0.6:180:0.22,afade=t=in:st=0:d=1.5,afade=t=out:st=${fade_out_start}:d=3,volume=2.4,atrim=0:${dur}" \
    -ar 44100 -ac 2 -c:a pcm_s16le "$out"
}

to_mp3() { # $1 wav in, $2 duration, $3 mp3 out
  "$FFMPEG" -hide_banner -loglevel error -y -i "$1" -t "$2" \
    -c:a libmp3lame -b:a 96k -ar 44100 -ac 2 -write_xing 1 "$3"
}

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

render 30 "$TMP/clip.wav"
to_mp3 "$TMP/clip.wav" 30 "$OUT/clip_30s.mp3"

render 120 "$OUT/song_120s.wav"
to_mp3 "$OUT/song_120s.wav" 120 "$OUT/song_120s.mp3"

ls -l "$OUT"
