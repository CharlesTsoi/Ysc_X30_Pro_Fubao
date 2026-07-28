bash ~/jy_cog/rosbag_recorder/scripts/start_record.sh
bash ~/jy_cog/rosbag_recorder/scripts/stop_record.sh
rosnod kill /livox_lidar_publisher2
rosnod kill/yesense_imu_node
rosbag play ~/jy_cog/system/record/bags/mapping/test
