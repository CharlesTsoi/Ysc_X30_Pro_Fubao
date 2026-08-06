#!/bin/bash

# ====================== 启动 GNSS ======================
cd ~/jy_cog/gnss/
source ~/jy_cog/gnss/gnss_driver_ws/devel/setup.bash

sudo chmod 777 /dev/ttyACM0
sudo chmod 777 /dev/ttyACM1
sudo chmod 777 /dev/ttyACM2
sudo chmod 777 /dev/ttyACM3
sudo chmod 777 /dev/ttyACM4

echo "正在启动 ublox_driver ..."
roslaunch ublox_driver ublox_driver.launch &
LAUNCH_PID=$!

# ====================== 等待 10 秒 ======================
echo "等待 10 秒让 GNSS 驱动完全启动..."
sleep 10

# ====================== 开始录包 ======================
echo "开始录包..."
rosbag record /ublox_driver/ephem \
        /ublox_driver/glo_ephem \
        /ublox_driver/gnssephemarray \
        /ublox_driver/iono_params \
        /ublox_driver/range_meas \
        /ublox_driver/receiver_lla \
        /ublox_driver/receiver_pvt \
        /ublox_driver/time_pulse_info \
        /livox/lidar \
        /livox/imu_192_168_2_202 \
        /livox/imu_192_168_2_203 \
        /livox/imu_192_168_2_204 \
        /livox/imu_192_168_2_205 \
        /imu/data

# 录包结束后（Ctrl+C），顺手把 launch 也关掉
kill $LAUNCH_PID 2>/dev/null
