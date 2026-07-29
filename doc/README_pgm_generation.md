# 占用栅格地图（.pgm）生成机制说明

> 本文档基于现有脚本与 `mapping_server_node` 二进制分析整理，用于与开发工程师对接 `.pgm` 生成细节。

---

## 1. 结论摘要

**`.pgm` 的生成方式是：**

> **点云 → 高度过滤（min_z / max_z）→ 投影/转换成 2D 激光扫描（GeneralLaserScan）→ 在线更新 OccupancyMap2D → 节点自行写出 `.pgm` + `.yaml`**

- **不是**先生成大量独立 2D 切片再拼接。
- **不是**从 OctoMap 3D 地图切片得到。
- **主要不是**通过外部 `map_server map_saver` 保存（虽然系统中有备用脚本）。

核心节点为：`mapping_server_node`（属于 `occupancy_mapping` 包）。

---

## 2. 调用链路（脚本层）

建图入口脚本：`mapping.sh`

关键逻辑：

1. 创建新地图目录（`system/maps/<map_name>-<timestamp>`），并软链接为 `default`。
2. 当 `slam_function=fast` 时，后台启动：
   ```bash
   bash occupancy_mapping.sh online jueying $directory &
   ```
3. 同时启动点云建图（`pointcloud_mapping.sh`，主要产出 `.pcd`）。

`occupancy_mapping.sh` 最终执行：

```bash
roslaunch occupancy_mapping mapping_occupancy.launch \
    map_save_path:=${map_save_path} \
    map_save_name:=${map_save_name}
```

即真正生成 `.pgm` 的节点由 `occupancy_mapping` 包的 launch 文件启动。

---

## 3. 核心节点分析（mapping_server_node）

### 3.1 基本信息

| 项目 | 内容 |
|------|------|
| 二进制 | `mapping_server_node` |
| 包名 | `occupancy_mapping` |
| 源码路径（二进制中残留） | `/home/hxw/codeup/dev/slam/src/tool/occupancy_mapping/src/mapping_server.cc` |
| 相关类 | `OccupancyServerRealTime`、`OccupancyServerFromFile`、`OccupancyMap2D` |

> 注意：源码路径是开发机（hxw）上的路径，当前部署环境中可能只有二进制，无源码。

### 3.2 处理流程（从二进制字符串/符号还原）

1. **输入**
   - 点云：`/occupancy_mapping_2D/pointcloud_topic`（支持 `sensor_msgs/PointCloud2` 或 Livox `CustomMsg`）
   - 位姿：`/occupancy_mapping_2D/odom_topic` 或 TF
   - 高度过滤参数：`min_z`、`max_z`

2. **点云 → 2D 扫描转换**
   - 关键函数：`getScan(...)`
   - 将点云转换为 `GeneralLaserScan`（模拟传统 2D 激光雷达扫描）
   - 只保留 `min_z ≤ z ≤ max_z` 范围内的点（高度过滤，实现 3D→2D 投影）

3. **占用栅格更新**
   - 关键函数：`processScan(...)` → `OccupancyMap2D::updateGrid(...)`
   - 使用 log-odds 更新（参数：`log_occ`、`log_free`）
   - 在线累积多帧，持续扩展地图

4. **保存**
   - 建图结束时输出：
     ```
     -----Finish mapping, start saving occupancy grid map-----
     Writing map occupancy data to xxx.pgm
     # CREATOR: occupancy_mapping %.3f m/pix
     Save occupancy map Done
     ```
   - 节点**自行写入** `.pgm` 和 `.yaml`（不是调用外部 map_saver）
   - 保存路径与文件名由参数控制：
     - `/occupancy_mapping_2D/map_save_path`
     - `/occupancy_mapping_2D/map_save_name`

### 3.3 写入的 YAML 内容（标准 ROS 地图格式）

```yaml
image: <map_save_name>.pgm
resolution: <value>
origin: [x, y, 0.00]
negate: 0
occupied_thresh: 0.65
free_thresh: 0.196
```

---

## 4. 关键参数列表（从二进制提取）

| 参数名 | 作用 |
|--------|------|
| `/occupancy_mapping_2D/map_save_path` | 地图保存目录 |
| `/occupancy_mapping_2D/map_save_name` | 地图文件名前缀 |
| `/occupancy_mapping_2D/resolution` | 栅格分辨率（m/cell） |
| `/occupancy_mapping_2D/min_z` | 高度过滤下限 |
| `/occupancy_mapping_2D/max_z` | 高度过滤上限 |
| `/occupancy_mapping_2D/log_occ` | 占用对数概率 |
| `/occupancy_mapping_2D/log_free` | 空闲对数概率 |
| `/occupancy_mapping_2D/pointcloud_topic` | 输入点云话题 |
| `/occupancy_mapping_2D/odom_topic` | 输入里程计话题 |
| `/occupancy_mapping_2D/pub_map_topic` | 发布地图话题 |
| `/occupancy_mapping_2D/use_topic` | 是否使用在线话题模式 |
| `/occupancy_mapping_2D/max_range` / `min_range` | 距离过滤 |
| `/occupancy_mapping_2D/max_radius` | 半径限制 |
| `/occupancy_mapping_2D/lidar_type` | 雷达类型 |
| `/occupancy_mapping_2D/fill_with_white` | 未知区域填充策略 |

---

## 5. 系统中其他相关文件的作用

| 文件/节点 | 作用 | 是否参与主 `.pgm` 生成 |
|-----------|------|------------------------|
| `mapping_server_node` | **主生成节点**，点云投影 + 占用栅格更新 + 直接写 pgm | ✅ 是 |
| `occupancy_mapping.sh` | 启动上述节点，并传入 map_save_path/name | ✅ 是 |
| `map_saver` / `save_map.sh` | 标准 ROS 工具，从 `/projected_map` 话题保存 | 备用 |
| `pub_occ_map.sh` | 调用服务 `/occupancy_mapping_node/publish_occupancy_map` 触发发布 | 辅助 |
| `octomap_*` 系列节点 | 3D 八叉树地图（.bt/.ot） | ❌ 否 |
| `crop_map` | 对已生成的 pgm/yaml 做边界裁剪 | 后处理 |

---


**文档生成时间**：2026-07-29  
**分析依据**：`mapping.sh`、`occupancy_mapping.sh`、`mapping_server_node` 二进制字符串与符号、相关辅助脚本。
