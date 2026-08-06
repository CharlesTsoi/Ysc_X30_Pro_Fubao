#!/bin/bash
# =============================================
# 云深处X30 pro ROS1 初始定位脚本__户外花园
# =============================================

echo "=== 开始一站式初始化 ==="

X="11.437593"
Y="-3.8767476"
YAW="-1.6030536"


TOPIC="/initialpose"

echo " 正在发布初始位姿..."
echo "   X = $X"
echo "   Y = $Y"
echo "   Yaw = $YAW rad"

# 计算四元数（使用 awk 更可靠）
QZ=$(awk "BEGIN {print sin($YAW/2)}")
QW=$(awk "BEGIN {print cos($YAW/2)}")

echo "   qz ≈ $QZ"
echo "   qw ≈ $QW"

# 使用 here-string + printf 构造消息，更稳定
rostopic pub -1 $TOPIC geometry_msgs/PoseWithCovarianceStamped "
header:
  frame_id: 'map'
pose:
  pose:
    position:
      x: $X
      y: $Y
      z: 0.0
    orientation:
      x: 0.0
      y: 0.0
      z: $QZ
      w: $QW
  covariance: [0.25, 0.0, 0.0, 0.0, 0.0, 0.0, 
               0.0, 0.25, 0.0, 0.0, 0.0, 0.0, 
               0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 
               0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 
               0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 
               0.0, 0.0, 0.0, 0.0, 0.0685, 0.0]" 

echo " 初始位姿发布完成！"

