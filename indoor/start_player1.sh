#!/bin/bash
# 使用方法：
#   ./start_player.sh [日期标识] [导航模式]
#   日期标识：如 0709、0710 等（默认 0709）
#   导航模式：1=最近点导航（默认），2=零点导航
#
# 示例：
#   ./start_player.sh 0709          # 使用0709的地图，默认模式2
#   ./start_player.sh 0709 2        # 使用0709的地图，模式2
#   ./start_player.sh 0710 1        # 使用0710的地图，模式1

# 参数处理
DATE_ID=${1:-0709}
MODE=${2:-2}

# 1. 构造最新的json文件路径
LATEST_JSON=~/jy_cog/system/data/8d65b957_${DATE_ID}.json

echo "使用地图文件: $LATEST_JSON"
echo "导航模式: $MODE"

# 2. 检查文件是否存在
if [ ! -f "$LATEST_JSON" ]; then
    echo "错误：地图文件不存在: $LATEST_JSON"
    exit 1
fi

# 3. 替换配置文件里的路径
sed -i "s|^points_path.*|points_path = \"$LATEST_JSON\"|" ~/jy_cog/system/conf/player/config.toml

# 4. 启动导航，自动输入导航模式
cd ~/jy_cog/player/scripts
echo "$MODE" | bash player.sh
