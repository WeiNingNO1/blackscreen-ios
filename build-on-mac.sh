#!/usr/bin/env bash
# 任意一台 macOS 上跑这一条就能出未签名 ipa：
#   bash build-on-mac.sh
set -euo pipefail

cd "$(dirname "$0")"

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "[1/4] 安装 XcodeGen"
  brew install xcodegen
else
  echo "[1/4] XcodeGen 已就绪"
fi

echo "[2/4] 生成 Xcode 工程"
xcodegen generate

echo "[3/4] 编译（关闭签名）"
xcodebuild \
  -project BlackScreen.xcodeproj \
  -scheme BlackScreen \
  -configuration Release \
  -sdk iphoneos \
  -derivedDataPath build \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  build

echo "[4/4] 打包 ipa"
APP="build/Build/Products/Release-iphoneos/BlackScreen.app"
rm -rf Payload BlackScreen.ipa
mkdir -p Payload
cp -R "$APP" Payload/
/usr/bin/ditto -c -k --sequesterRsrc --keepParent Payload BlackScreen.ipa

ls -lh BlackScreen.ipa
echo
echo "完成：$(pwd)/BlackScreen.ipa"
echo "下一步：用你的证书签（zsign / Sideloadly / 轻松签），bundle id 记得对上描述文件。"
