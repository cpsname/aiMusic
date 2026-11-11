#!/usr/bin/env bash
# ascpub shots 专用候选池:排除 dashscope(qwen-image-2.0-pro)与 volcengine(seedream-5.0)两家。
# 顺位:Nano Banana Pro → gpt_image_2(runway)→ Nano Banana 2(flash 兜底);失败按序切换。
# gpt-image-2(subscribe_gateway)不收参考图,带 --ref-image 时必定出池,故不列入。
# Go flag 取后值,追加在 "$@" 之后即覆盖默认池。用法:NB_GENERATOR_COMMAND=<本脚本> ascpub shots ...
exec /Users/lintion/Developer/MagicContent/genaistudio/scripts/nb-image-gen.sh "$@" \
  --model-version-bids 1f847346-482e-4b76-aa7a-703da2668f13,019e72ea-5198-77b3-8715-d6114ee1df99,eb0b17fc-9a34-431e-bc97-7724d7e59878
