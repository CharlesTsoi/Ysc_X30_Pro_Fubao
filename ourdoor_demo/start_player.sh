#!/bin/bash

# 导航模式：1=最近点导航（默认），2=零点导航
# 平时直接运行 ./start.sh 就是默认1
# 想选2的话运行 ./start.sh 2
MODE=$2:-2}

# 1. 找到最新的json文件
#LATEST_JSON=$(ls -t ~/jy_cog/system/data/*.json | head -n 1)
LATEST_JSON=~/jy_cog/system/data/8d65b957_0714.json
echo "使用地图文件: $LATEST_JSON"

# 2. 替换配置文件里的路径
sed -i "s|^points_path.*|points_path = \"$LATEST_JSON\"|" ~/jy_cog/system/conf/player/config.toml

# 3. 启动导航，自动输入导航模式
cd ~/jy_cog/player/scripts
echo "$MODE" | bash player.sh

