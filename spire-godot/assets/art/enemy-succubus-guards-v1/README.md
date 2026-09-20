# 魅魔警卫原版战斗立绘 v1

两张源图由用户于2026-09-09提供，角色设定为成年女性。2026-09-19按用户要求恢复为魅魔警卫战斗立绘；透明PNG直接取回项目v0.15中已经验收的原版资源，没有重新生成、重绘或修改像素。当前监狱狱警继续使用`../enemy-guards-v1/`，不与本目录共用运行时映射。

| 变体ID | 用户源图 | 透明PNG | 尺寸 | 正式PNG SHA256 |
| --- | --- | --- | --- | --- |
| `guard_purple` | `C:/Users/16563/Downloads/00001-3573096630.png` | `succubus-purple-v1.png` | 1178×2261 | `B26789330D06D718CF2C3706263F0858E3EE721AC392DB60BC3B6CEB45E38148` |
| `guard_brown` | `C:/Users/16563/Downloads/00002-3252140892.png` | `succubus-brown-v1.png` | 830×2223 | `598562AE70145A1A2C882796F9626AA5D0321163E2A9E2861A43A610A217D1D2` |

原版处理记录：紫发图使用`tools/extract_portrait.py --white-floor 242 --clear-border --background-seed 1050,1300`；棕发图使用背景种子`900,750`与`950,1300`，并固定裁框`367,32,1197,2255`，用于清除右臂／腰侧、尾巴内封闭白底以及左上角孤立杂色点。白色服装和高光保持不透明。

运行时仍由`data/enemies.gd`的`guard.visual_pool`生成`guard_purple`／`guard_brown`稳定ID，每只魅魔警卫独立有放回抽取并将结果保存到敌人状态。`ui/arena.gd`仅在敌人类型为`guard`时把这些ID映射到本目录；监狱NPC的相同视觉ID继续由`GUARD_PORTRAITS`映射到狱警资源，因此随机、存档和监狱分工均不改变。

源图SHA256：

- `00001-3573096630.png`：`9101731316D21F3E9BFA3BD640A56E4FBF7804A4701F7DAD4A3D85F2BB0EFB89`
- `00002-3252140892.png`：`A51909210BD665387D1FB8E430CEED80FF7298C693E5A6FA35E97D8AFEBD5BEE`
