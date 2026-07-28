#!/bin/bash
# =============================================
# 设置户外地图软链接脚本
# 用法: ./set_outdoor_map.sh [地图文件夹名]
# =============================================

set -e  # 遇到错误立即退出

# 默认地图（可通过参数覆盖）
DEFAULT_MAP="0629-garden-20260629-165424"

TARGET_DIR="$HOME/jy_cog/system"
MAP_NAME="${1:-$DEFAULT_MAP}"          # 支持传参，不传则用默认
LINK_PATH="$TARGET_DIR/map"
SOURCE_PATH="$TARGET_DIR/maps/$MAP_NAME"

# 检查目标目录是否存在
if [ ! -d "$TARGET_DIR" ]; then
    echo "❌ 错误: 目录不存在 -> $TARGET_DIR"
    exit 1
fi

cd "$TARGET_DIR"

# 删除已存在的 map（不管是文件夹还是软链接）
if [ -e "$LINK_PATH" ] || [ -L "$LINK_PATH" ]; then
    echo "🗑️  删除旧的 map 链接/文件夹..."
    rm -rf "$LINK_PATH"
fi

# 检查源地图文件夹是否存在
if [ ! -d "$SOURCE_PATH" ]; then
    echo "❌ 错误: 地图文件夹不存在 -> $SOURCE_PATH"
    echo "   请确认 maps/ 目录下有该文件夹"
    ls -l maps/ 2>/dev/null || echo "   maps/ 目录为空或不存在"
    exit 1
fi

# 创建软链接
echo "🔗 创建软链接: map -> maps/$MAP_NAME"
ln -s "maps/$MAP_NAME" map

echo "✅ 成功！当前地图已切换为：$MAP_NAME"
echo "   链接路径: $LINK_PATH"
ls -ld map
