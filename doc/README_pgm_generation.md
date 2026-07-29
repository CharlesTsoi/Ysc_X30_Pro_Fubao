# 占用栅格地图（.pgm）生成机制说明

> 基于脚本、`mapping_server_node` 二进制及 `livox.yaml` / `rslidar.yaml` 等配置文件的分析结论。

---

## 1. 结论

**`.pgm` 生成方式：**

> **点云 → 高度过滤（min_z / max_z）→ 投影/转换成 2D 激光扫描（GeneralLaserScan）→ 在线更新 OccupancyMap2D → 节点自行写出 `.pgm` + `.yaml`**

- 不是先生成大量独立 2D 切片再拼接
- 不是从 OctoMap 3D 地图切片得到
- 主要不是通过外部 `map_server map_saver` 保存（系统中有备用脚本，但非主路径）

核心节点：`mapping_server_node`（`occupancy_mapping` 包）

---

## 2. 调用链路

入口：`mapping.sh`

1. 创建地图目录 `system/maps/<map_name>-<timestamp>`，软链接为 `default`
2. `slam_function=fast` 时后台启动：
   ```bash
   bash occupancy_mapping.sh online jueying $directory &
   ```
3. 同时启动 `pointcloud_mapping.sh`（产出 `.pcd`）

`occupancy_mapping.sh` 最终执行：

```bash
roslaunch occupancy_mapping mapping_occupancy.launch \
    map_save_path:=${map_save_path} \
    map_save_name:=${map_save_name}
```

---

## 3. 处理流程（mapping_server_node）

| 步骤 | 内容 |
|------|------|
| 输入 | 点云（`/lidar_points`）+ 位姿（`/Odometry` 或 TF） |
| 高度过滤 | 只保留 `min_z ≤ z ≤ max_z` 的点（相对传感器中心） |
| 投影 | `getScan()` 将点云转为 `GeneralLaserScan`（模拟 2D 激光） |
| 更新 | `processScan()` → `OccupancyMap2D::updateGrid()`，log-odds 更新 |
| 保存 | 节点直接写 `.pgm` + `.yaml`（日志含 `CREATOR: occupancy_mapping`） |

保存时的 YAML 标准格式：

```yaml
image: <map_save_name>.pgm
resolution: <value>
origin: [x, y, 0.00]
negate: 0
occupied_thresh: 0.65
free_thresh: 0.196
```

---

## 4. 关键配置参数

### 4.1 公共参数（livox.yaml / rslidar.yaml）

| 参数 | 值 | 说明 |
|------|-----|------|
| `pub_map_topic` | `projected_map` | 占用图发布话题 |
| `angle_increment` | 0.006 rad | 角度间隔 |
| `min_range` / `max_range` | 0.5 / 200 m | 有效距离 |
| `log_free` / `log_occ` | -0.01 / 0.1 | 空闲 / 占用更新值 |
| `resolution` | 0.1 m | 栅格分辨率 |
| `max_radius` | 20 m | 只更新此半径内栅格 |
| `fill_with_white` | true | 超出半径的射线填白色 |
| `use_nan` | false | 不使用 nan 点 |
| `lidar_type` | 0 | 0=PointCloud2，1=Livox CustomMsg |
| `pointcloud_topic` | `/lidar_points` | |
| `odom_topic` | `/Odometry` | |
| `use_tf_transforms` | true | 优先用 TF |
| `map_frame` / `body_frame` / `sensor_frame` | `map` / `base_link` / `lidar_link` | |

### 4.2 高度过滤（雷达差异）

| 雷达 | 配置文件 | min_z | max_z | 说明 |
|------|----------|-------|-------|------|
| Livox | `livox.yaml` | -0.15 | **0.25** | 仅取传感器附近薄层 |
| RSLidar | `rslidar.yaml` | -0.15 | **1.5** | 允许更高障碍进入投影 |

> `min_z` / `max_z` 相对于**传感器中心**，非地面。

### 4.3 离线模式

```yaml
use_file_num: 1
data_file_1: ".../details/frames/"
pose_file: ".../details/poses.txt"   # 每行 12 个数（齐次矩阵前三行）
```

---

## 5. 相关文件角色

| 文件/节点 | 作用 | 主路径？ |
|-----------|------|----------|
| `mapping_server_node` | 点云投影 + 占用更新 + 写 pgm | ✅ |
| `occupancy_mapping.sh` | 启动节点并传保存路径 | ✅ |
| `livox.yaml` / `rslidar.yaml` | 完整投影与更新参数 | ✅ |
| `map_saver` / `save_map.sh` | 从 `/projected_map` 话题保存 | 备用 |
| `pub_occ_map.sh` | 触发地图发布服务 | 辅助 |
| `pcd2map`（minh/maxh） | 从已有 `.pcd` 离线切片 | 另一路径 |
| `octomap_*` | 3D 八叉树（.bt/.ot） | ❌ |
| `crop_map` | 对已有 pgm/yaml 裁剪 | 后处理 |

---

## 6. 二进制中的关键证据

- 源码残留路径：`.../occupancy_mapping/src/mapping_server.cc`
- 类：`OccupancyServerRealTime`、`OccupancyServerFromFile`、`OccupancyMap2D`
- 保存日志：
  ```
  -----Finish mapping, start saving occupancy grid map-----
  Writing map occupancy data to xxx.pgm
  # CREATOR: occupancy_mapping %.3f m/pix
  Save occupancy map Done
  ```
- 参数命名空间：`/occupancy_mapping_2D/...`

---

**更新时间**：2026-07-29  
**依据**：`mapping.sh`、`occupancy_mapping.sh`、`mapping_server_node` 二进制、`livox.yaml`、`rslidar.yaml`、`pcd2map` 及相关脚本。
