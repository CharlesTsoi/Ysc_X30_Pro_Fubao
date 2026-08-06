#!/bin/bash
# =============================================
# 云深处X30 Pro 一键室内/户外 地图+位姿切换脚本
# 用法: ./demo_switch_map_set_pose.sh
# =============================================

set -e

echo "=== 云深处X30 Pro 一键切换脚本 ==="
echo "请选择要切换的地图模式："
echo "  1) Indoor 室内 (~/Desktop/indoor/)"
echo "  2) Outdoor 户外 (~/Desktop/ourdoor_demo/)"
echo -n "请输入 1 或 2: "
read -r choice

case $choice in
    1)
        echo "🔄 正在切换到 **室内** 模式..."
        MAP_DIR="$HOME/Ysc_X30_Pro_Fubao/scripts"
        MAP_SCRIPT="$MAP_DIR/set_indoor_map.sh"
        POSE_SCRIPT="$MAP_DIR/set_initial_2Dpose_indoor.sh"
        ;;
    2)
        echo "🔄 正在切换到 **户外** 模式..."
        MAP_DIR="$HOME/Ysc_X30_Pro_Fubao/scripts"
        MAP_SCRIPT="$MAP_DIR/set_outdoor_map.sh"
        POSE_SCRIPT="$MAP_DIR/set_initial_2Dpose_outdoor.sh"
        ;;
    *)
        echo "❌ 无效输入！请只输入 1 或 2"
        exit 1
        ;;
esac

# 检查脚本是否存在
for script in "$MAP_SCRIPT" "$POSE_SCRIPT"; do
    if [ ! -f "$script" ]; then
        echo "❌ 找不到脚本: $script"
        exit 1
    fi
done

# 1. 设置地图软链接
echo "📍 步骤1: 设置地图软链接..."
bash "$MAP_SCRIPT"

# 2. 重启导航节点
echo "🔄 步骤2: 重启导航 (kill_nav → start_nav)..."
KILL_SCRIPT="$HOME/jy_cog/system/scripts/kill_nav.sh"
START_SCRIPT="$HOME/jy_cog/system/scripts/start_nav.sh"

if [ ! -f "$KILL_SCRIPT" ] || [ ! -f "$START_SCRIPT" ]; then
    echo "⚠️  警告: 未找到 kill_nav.sh 或 start_nav.sh，跳过重启导航"
else
    echo "   → kill_nav.sh ..."
    bash "$KILL_SCRIPT" || true

    echo "   → start_nav.sh （等待30秒让节点稳定启动）..."
    bash "$START_SCRIPT" &
    START_PID=$!
    echo "   start_nav PID: $START_PID"

    echo "⏳ 等待 30 秒..."
    sleep 30
fi

# 3. 发布初始位姿
echo "📍 步骤3: 发布初始2D位姿..."
bash "$POSE_SCRIPT"

echo ""
echo "✅ **一键切换完成！** 当前模式: $( [ "$choice" = "1" ] && echo "室内" || echo "户外" )"
echo "   请打开 RViz 检查定位是否正确。"
echo "   如需手动观察 start_nav 日志，可把 sleep 30 注释掉改成手动 Ctrl+C。"
