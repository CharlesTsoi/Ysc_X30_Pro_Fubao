# Indoor vs Outdoor 建图参数对比

> 基于 `jueying_pgo` 的 `indoor.yaml` / `outdoor.yaml` 及 occupancy 相关配置的分析结论。

---

## 1. 结论摘要

Indoor / Outdoor 差异主要体现在 **Pose Graph Optimization（PGO）** 的关键帧密度与回环检测策略上，用于适配室内结构化场景与室外大尺度场景。

- **Indoor**：关键帧更密，关闭 Scan Context，回环验证更严 → 优先保证局部精度、抑制错误回环
- **Outdoor**：关键帧更疏，开启 Scan Context（大半径），回环验证更松 → 优先保证大尺度全局一致性、控制计算量

配置通过 `mapping_pgo.launch` 的 `scene` 参数加载：

```bash
roslaunch jueying_pgo mapping_pgo.launch scene:=indoor  ...
roslaunch jueying_pgo mapping_pgo.launch scene:=outdoor ...
```

实际文件路径：
```
/home/ysc/jy_cog/system/conf/slam/jueying_pgo/$(scene).yaml
```

---

## 2. 参数对比

| 参数 | Indoor | Outdoor | 含义 |
|------|--------|---------|------|
| **关键帧** | | | |
| `keyframe_meter_gap` | **0.5 m** | **1.0 m** | 平移关键帧间隔 |
| `keyframe_deg_gap` | **20°** | **45°** | 旋转关键帧间隔 |
| `add_imu_orientation_factor` | true | true | 使用 IMU 朝向因子 |
| **回环总开关** | | | |
| `enable_loop_detect` | true | true | |
| **Scan Context** | | | |
| `enable_sc_detect` | **false** | **true** | 是否启用 SC |
| `sc_dist_thres` | 0.5 | **0.25** | SC 距离阈值（越小越严） |
| `sc_max_radius` | **5.0 m** | **80.0 m** | SC 描述子半径 |
| `sc_downsample_size` | 0.1 | 0.2 | SC 点云下采样 |
| **Radius Search** | | | |
| `enable_rs_detect` | true | true | 几何半径搜索回环 |
| `rs_gap_frac` | **0.005** | **0.02** | 相对间隔 |
| `rs_gap_const` | **1.0** | **5** | 常量间隔 |
| **回环验证** | | | |
| `loop_score_th` | **0.2** | **0.3** | 匹配分数阈值 |
| `loop_match_downsample_size` | 0.1 | 0.2 | 匹配下采样 |
| `loop_valid_trans_th` | **2.0 m** | **10.0 m** | 最大允许平移误差 |
| `loop_valid_rot_th` | 30.0° | 30.0° | 最大允许旋转误差 |
| **可视化** | | | |
| `enable_map_vis` | false | false | |
| `mapviz_filter_size` | 0.4 | 0.4 | |

---

## 3. 设计意图

### Indoor
- 关键帧密（0.5 m / 20°）：走廊、房间、家具等局部结构需要更高位姿密度
- 关闭 SC：室内重复结构多，全局描述子易产生错误回环，主要依赖 Radius Search
- 验证严（trans ≤ 2 m，score ≤ 0.2）：宁可少闭环，也不引入错误约束

### Outdoor
- 关键帧疏（1.0 m / 45°）：长距离路径下降低后端计算量
- 开启 SC 且半径大（80 m）：利用建筑、道路等全局特征做大尺度回环
- 验证松（trans ≤ 10 m，score ≤ 0.3）：室外漂移更大，需允许更大误差的候选进入优化
- RS 间隔更大：避免长直路上产生过多冗余候选

---

## 4. 与 .pgm 的关系

Indoor/Outdoor 配置作用于 **PGO 与回环**，影响轨迹精度。

`.pgm` 由 `occupancy_mapping` 独立生成，高度过滤参数在另一套配置中：

| 雷达 | 配置 | min_z | max_z |
|------|------|-------|-------|
| Livox | `livox.yaml` | -0.15 | 0.25 |
| RSLidar | `rslidar.yaml` | -0.15 | 1.5 |

PGO 优化后的位姿通过 `/Odometry` 或 TF 提供给 occupancy 节点，从而影响最终 `.pgm` 的几何精度。

另有 `pcd2map` 离线路径（从 `.pcd` 切片）：

```yaml
pcd2map:
  minh: 0.1
  maxh: 1.0
  leaf_size: 0.1
```

---

## 5. 相关文件

| 文件 | 作用 |
|------|------|
| `indoor.yaml` / `outdoor.yaml` | PGO + 回环参数 |
| `mapping_pgo.launch` | 按 scene 加载配置并启动 PGO |
| `livox.yaml` / `rslidar.yaml` | occupancy 高度过滤与投影参数 |
| `pcd2map` 相关 | 从 PCD 离线生成占用图 |

---

**更新时间**：2026-07-29  
**依据**：`indoor.yaml`、`outdoor.yaml`、`mapping_pgo.launch`、`livox.yaml`、`rslidar.yaml`、`pcd2map` 配置。
