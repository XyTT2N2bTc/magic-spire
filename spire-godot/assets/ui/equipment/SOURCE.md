# 素材来源

2026-09-10补接网页项目仓库 `mahou-shoujo-escape` 的 `public/assets/focus-equipment/focus-c-silicone-urethral-rod.png`，原样复制，按稳定family映射到对应系列的各品质。经用户确认，其余特殊部位装备没有现成图时只保留名称，不新画、不以无关素材替代。图鉴与实装装备均读取 `EquipmentImages.path`，运行时不依赖该项目。

素材来自网页项目仓库 `mahou-shoujo-escape` 的 `public/assets/restraints/icons/` 与 `public/assets/restraints/concepts/fine-belt/`（该仓库与本仓同级，是独立项目）。运行时只读取本项目副本，不依赖该项目目录。材质及模板映射见 `data/equipment_images.gd`；尚无对应旧图的装备显示真实名称。

2026-09-10检查确认：`special-armbinder`、`special-legbinder-full`、`special-legbinder-partial`已有透明通道，套体优先复用这些成品；普通绳／细绳／皮带／细皮带／胶带／扎带的30张源图仍是实色底。使用 `tools/prepare_equipment_icons.py` 在本地清理这30张图的底色及环内空隙，保留主体高光，输出透明128×128 PNG。只编辑本项目副本，不改旧项目；未调用图像生成服务。其余人物装备示意图保持原文件。


2026-09-10用户更正：单手套／单腿套改用上个项目正式映射的structure-armbinder.png和structure-legbinder.png，文件与旧项目副本SHA-256一致。此要求覆盖此前优先使用special-armbinder／special-legbinder像素成品的选择。共用映射同步装备栏及图鉴；无需重新裁剪、生成或复制素材。
