#!/bin/bash
# Argosbx 包装脚本：每次拉取上游 yonggekkk/argosbx 最新原版，
# 将 Shadowsocks-2022 加密方式改为 2022-blake3-chacha20-poly1305 后执行。
# 用法与原版完全相同，例如：
#   arpt="" sspt="" bash <(curl -Ls https://raw.githubusercontent.com/Williams3993/New-repository/main/argosbx.sh)
#   agsbx list / rep / res / upx / ups / upa / del

UP='https://raw.githubusercontent.com/yonggekkk/argosbx/main/argosbx.sh'
ME='https://raw.githubusercontent.com/Williams3993/New-repository/main/argosbx.sh'
METHOD='2022-blake3-chacha20-poly1305'

TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT

# 1. 下载上游原版
(command -v curl >/dev/null 2>&1 && curl -Ls "$UP" -o "$TMP") || \
(command -v wget >/dev/null 2>&1 && wget -qO "$TMP" "$UP")
[ -s "$TMP" ] || { echo "下载上游 argosbx.sh 失败，已中止"; exit 1; }

# 2. 打补丁
#   - 加密方式：服务端 sb.json + 分享链接 + sing-box/clash 订阅
#   - 密钥长度：chacha20-poly1305 需要 32 字节（原版 aes-128 为 16 字节）
#   - 快捷命令 agsbx 与 sh.txt 记录的命令改指向本包装脚本，避免被原版覆盖
sed -i \
  -e "s/2022-blake3-aes-128-gcm/$METHOD/g" \
  -e 's/generate rand 16 --base64/generate rand 32 --base64/' \
  -e "s#^url='$UP'#url='$ME'#" \
  -e "s#^agsbxurl=\"$UP\"#agsbxurl=\"$ME\"#" \
  "$TMP"

# 3. 校验补丁是否全部生效（上游改版导致匹配不上时中止，不装半成品）
if grep -q '2022-blake3-aes-128-gcm' "$TMP" \
   || ! grep -q 'generate rand 32 --base64' "$TMP" \
   || ! grep -q "^url='$ME'" "$TMP" \
   || ! grep -q "^agsbxurl=\"$ME\"" "$TMP"; then
  echo "上游脚本结构已变化，补丁未能完全生效，已中止。请检查包装脚本。"
  exit 1
fi

# 4. 旧 16 字节密钥处理：仅在 安装/rep 时删除，list 等命令不动
k="$HOME/agsbx/sskey"
if [ -s "$k" ] && { [ "$1" = "rep" ] || [ ! -e "$HOME/agsbx/sb.json" ]; }; then
  if [ "$(base64 -d "$k" 2>/dev/null | wc -c)" -ne 32 ]; then
    rm -f "$k"
    echo "已删除旧的 SS 密钥（非 32 字节），将重新生成"
  fi
fi

# 5. 执行（协议变量通过环境变量原样传入）
bash "$TMP" "$@"
