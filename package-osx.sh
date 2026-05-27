#!/bin/bash

# 接收传递的参数
Arch="$1"        # 架构: macos-x64 或 macos-arm64
OutputPath="$2"  # 编译输出的文件路径
Version="$3"     # 版本号

echo "开始打包 $Arch 版本..."

# 1. 下载自带核心的压缩包
FileName="v2rayN-${Arch}.zip"
echo "正在下载核心组件: $FileName"
wget -nv -O $FileName "https://github.com/2dust/v2rayN-core-bin/raw/refs/heads/master/$FileName"
7z x $FileName -y

# 2. 将核心组件复制到输出目录与程序放在一起
cp -rf v2rayN-${Arch}/* "$OutputPath"

# 3. 创建 macOS 的 .app 包结构
PackagePath="v2rayN-Package-${Arch}"
mkdir -p "$PackagePath/v2rayN.app/Contents/Resources"
cp -rf "$OutputPath/"* "$PackagePath/v2rayN.app/Contents/MacOS/"

# 4. 修复可执行文件名 (将 v2rayN.Desktop 重命名为 v2rayN 保持与 PList 一致)
if [ -f "$PackagePath/v2rayN.app/Contents/MacOS/v2rayN.Desktop" ]; then
    mv "$PackagePath/v2rayN.app/Contents/MacOS/v2rayN.Desktop" "$PackagePath/v2rayN.app/Contents/MacOS/v2rayN"
fi

# 5. 配置图标和权限
cp -f "$PackagePath/v2rayN.app/Contents/MacOS/v2rayN.icns" "$PackagePath/v2rayN.app/Contents/Resources/AppIcon.icns"
echo "When this file exists, app will not store configs under this folder" > "$PackagePath/v2rayN.app/Contents/MacOS/NotStoreConfigHere.txt"
chmod +x "$PackagePath/v2rayN.app/Contents/MacOS/v2rayN"

# 6. 生成 Info.plist 配置文件
cat >"$PackagePath/v2rayN.app/Contents/Info.plist" <<-EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>English</string>
  <key>CFBundleDisplayName</key>
  <string>v2rayN</string>
  <key>CFBundleExecutable</key>
  <string>v2rayN</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
  <key>CFBundleIconName</key>
  <string>AppIcon</string>
  <key>CFBundleIdentifier</key>
  <string>2dust.v2rayN</string>
  <key>CFBundleName</key>
  <string>v2rayN</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>${Version}</string>
  <key>CSResourcesFileMapped</key>
  <true/>
  <key>NSHighResolutionCapable</key>
  <true/>
  <key>LSMinimumSystemVersion</key>
  <string>12.7</string>
</dict>
</plist>
EOF

# 7. 使用 create-dmg 生成苹果磁盘映像 DMG
echo "正在生成 DMG 安装包..."
create-dmg \
    --volname "v2rayN Installer" \
    --window-size 700 420 \
    --icon-size 100 \
    --icon "v2rayN.app" 160 185 \
    --hide-extension "v2rayN.app" \
    --app-drop-link 500 185 \
    "v2rayN-${Arch}.dmg" \
    "$PackagePath/v2rayN.app"

echo "打包完成: v2rayN-${Arch}.dmg"
