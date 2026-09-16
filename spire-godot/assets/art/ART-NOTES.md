# 本批美术提示词与来源

## 2026-09-15 单手套拘束具差分

本批只使用用户提供的两张1536×2304同姿势PNG进行本地像素差分和白底抠图，没有调用生成工具，也没有修改原文件。单手套源图为`C:/Users/16563/Downloads/00105-3376505697.png`（SHA256 `075487EA317622794B8B956B8E7BC16F5BE26007A47B4952B027532CFDDCACD2`）；红绳参照图为`C:/Users/16563/Downloads/00077-1312644243.png`（`23E76BA8FA2E76B3F55B39B2010936C66A25F4CACC9369CC4A6AE2AAE5E1DEA5`）。

`tools/build_equipment_single_glove_layer.py`在原图坐标(450,420,1050,1230)内提取变化，实际非透明差分边界为(477,446,1030,1213)，输出检查用`equipment-overlay-single-glove-v1.png`。由于新套体会移除原图拳头和红绳，运行时使用差分生成的透明替换底图，而不在旧像素上直接覆盖；普通／平板锁底图及大腿根有拘束／无拘束切片均生成对应版本。完整路径、哈希、坐标和映射见`equipment-single-glove-layer.json`。

运行时只读取只读投影`composite_portrait_layers`：存在主体仍有效的真实`kind == "glove"`复合拘束具时，短型、长型和两种肩带共用单手套差分；套体解除后恢复原红绳分段立绘。左侧装备肖像与战斗受限站姿同步，平板锁可组合；自由站姿、坐姿、躺姿和固定立绘设置不变。该显示映射不参与装备生成、等级、覆盖、容量、耐久、锁、候选、事务或随机结算。

## 2026-09-13 自由站姿平板锁与加固带差分

本批只使用用户提供的三张1536×2304对齐PNG进行本地像素差分和白底抠图，不调用生成工具，不修改源文件。无平板锁源图为`C:/Users/16563/Downloads/hand0legs0.png`（SHA256 `2C28A89B08E7BEE0F4761445A615CCDF34FDA43427C0C7C7CC33D5A1785AA41B`）；平板锁源图为`C:/Users/16563/Downloads/QQ图片202609131041226.png`（`B176781AADDA42CFE15E2F90432E1EDC55E1072748BC9857D61C5F095BA82442`）；带加固带源图为`C:/Users/16563/Downloads/QQ图片20260913104126.png`（`BF5EA5A1FBDB8E80321DF085726B1479D687B0760C9E1A45D6A13449795EF544`）。

`tools/build_free_flat_lock_layers.py`先从图2相对图1的差异提取138×284的`hero-overlay-flat-lock-free-v1.png`，源坐标(774,894)；再从图3相对图2的差异提取390×180的`hero-overlay-flat-lock-reinforcement-free-v1.png`，源坐标(634,956)。差异遮罩只在已确认区域保留连通变化，轻微扩展并羽化后乘以目标图的本地抠图alpha。复现参数、源哈希和坐标保存于`hero-stand-special-layers.json`。

运行时只在站姿且双臂／双腿拘束等级均为0时使用本差分：存在真实平板锁显示锁体层，存在其真实加固带再显示加固带层；未佩戴平板锁继续直接使用原`hero-stand-cutout-v2.png`。受限站姿仍沿原装备栏组合器，坐姿、躺姿和固定立绘设置不变。

## 2026-09-09 拘束等级战斗立绘

本批按用户要求仅使用本地抠图，不调用生成工具，也不重绘人物。两张源图均保持原文件不变：

| 姿态 | 用户源文件 | 原始尺寸 | 正式透明PNG | 裁剪范围 / 输出尺寸 |
| --- | --- | --- | --- | --- |
| 坐 | `C:/Users/16563/Downloads/00016-707839426.png` | 1920×1920 | `hero-restrained-sit-v1.png` | (108,247,1886,1779) / 1778×1532 |
| 躺 | `C:/Users/16563/Downloads/00014-3134264137.png` | 2112×1728 | `hero-restrained-lie-v1.png` | (0,511,2112,1379) / 2112×868 |

两图复用`tools/extract_bedded_portrait.py`的固定种子GrabCut，只以原图RGB计算alpha。坐姿使用背景种子700,1740／1000,1720／1400,1700，并以`--clear-neutral-shadow`清除臀部轮廓下方与最低前景相连的低色度投影；该步骤不会清除封闭在人物内部的浅色皮肤或衣物。卧姿的白色床面与灰色投影由主人物连通区域排除。两张图都已在深蓝底检查透明边缘和完整肢体。

运行时以只读投影`has_restraint_level`为唯一切换事实：双臂或双腿任一整数拘束等级大于0时，坐／躺姿读取上述资源；站姿直接复用`equipment_portrait.gd`组合器，因此战场和左侧装备栏同步显示同一底图与真实覆盖层。单独的眼／口装备不产生肢体拘束等级，不会借此切换整套战斗姿态。

## 2026-09-14：魅魔警卫与监狱狱警双立绘

用户提供 `00014-3038311190.png` 与 `1212122.png`，分别作为紫发狱警和棕发资深狱警，并同步替换魅魔警卫战斗立绘池的两张角色图。使用项目现有本地脚本移除边缘连通白底，没有调用生成式图像工具；透明成品、裁框、哈希和运行时约定见 `enemy-guards-v1/README.md`。战斗仍按每只魅魔警卫独立有放回抽取并保存变体；监狱例行巡视固定使用紫发图，收押、出狱前额外巡视和正常出狱对白固定使用棕发图，不消耗战斗美术随机域。

## 2026-09-07 装备栏五档差分与口/眼覆盖

来源均为用户提供的1536×2304 PNG，位于`C:/Users/16563/Downloads/`：

| 用途 | 源文件 | 正式资源 |
| --- | --- | --- |
| 图1 / 腿0级 | `00068-4048214563 (1).png` | `equipment-bound-legs0-v1.png` |
| 图2 / 腿1级 | `handsanylegs1 (2).png` | `equipment-bound-legs1-v1.png` |
| 图3 / 腿2级 | `00071-1333714550.png` | `equipment-bound-legs2-v1.png` |
| 图4 / 腿3级 | `00073-1839265440.png` | `equipment-bound-legs3-v1.png` |
| 图5 / 腿4级 | `00075-1504326030 (1).png` | `equipment-bound-legs4-v1.png` |
| 图6 / 嘴部 | `00076-3734441362.png` | `equipment-overlay-mouth-v1.png` |
| 图7 / 眼部 | `00077-1312644243.png` | `equipment-overlay-eyes-v1.png` |

处理只使用原图像素进行本地去背景、裁剪、差异遮罩与显示对齐，没有生成或重绘。`tools/build_equipment_variants.py <源目录>`复用extract_portrait，统一源图裁剪(390,90,1130,2304)，五张正式图均740×2214；额外白底种子677,480用于封闭发丝/手臂间空隙。图6/7整图中间结果仅保存在build，不加入运行时。

嘴部从图6相对图5的差异提取，源区域(655,374,950,479)，输出295×105；眼部从图7相对图6提取，源区域(590,238,990,374)，输出400×136。差异遮罩小幅扩展并羽化，乘以原图抠图alpha，保留原脸部/发丝像素，仅覆盖对应变化，眼部贴片不携带嘴部装备。两层共享五张差分坐标；自由图使用原图眼部锚点(823,383)，相对差分眼部(895,329)缩放0.907、旋转-0.1035弧度，扣除原自由图裁剪偏移。

图1同时是用户指定的“手臂无等级但腿部受限”临时图。图片是区域等级示意，不等于逐件装备外观清单。战场站/坐/躺资源保持独立。

## 2026-09-06 战场三姿态原图替换

本批只做用户提供图片的本地背景移除、透明裁剪及摆放，不生成或重绘人物。三个源文件保持原样：

| 姿态 | 用户源文件 | 原始尺寸 | 正式透明PNG | 裁剪范围 / 输出尺寸 |
| --- | --- | --- | --- | --- |
| 站 | `C:/Users/16563/Downloads/hand0legs0.png` | 1536×2304 | `hero-stand-cutout-v2.png` | (349,60,1138,2268) / 789×2208 |
| 坐 | `C:/Users/16563/Downloads/00066-1380771150.png` | 1920×1920 | `hero-sit-cutout-v2.png` | (64,101,1375,1906) / 1311×1805 |
| 躺 | `C:/Users/16563/Downloads/00067-362755172.png` | 2240×1664 | `hero-lie-cutout-v2.png` | (29,11,2167,1497) / 2138×1486 |

站/坐使用`tools/extract_portrait.py`，保留衣物内部白色与人物不透明原像素。站姿白底种子为668,432 / 813,467 / 966,785 / 572,848；坐姿为444,540 / 367,932，白底下限239，并清理已确认全是背景的源图边缘孤立像素（`--clear-border`）。

躺姿使用`tools/extract_bedded_portrait.py`，以原图颜色作为GrabCut前后景种子，保留主连通人物并恢复封闭衣料高光；三处人工确认的床单空隙为600,1250 / 840,1380 / 1357,740，最后只在这些种子对应的小型中性颜色连通域清理床单。依赖Pillow/numpy/OpenCV，所需版本记录在`tools/cutout-requirements.txt`；本机`build/cutout-deps`是可重建缓存，需要重建时可运行`python -m pip install --target build/cutout-deps -r tools/cutout-requirements.txt`，并给脚本传`--opencv-path build/cutout-deps`。这些依赖不进入游戏运行时。此算法只决定原图像素的alpha，不添加人物内容。

三张图均已在深色背景与正式站/坐/躺窗口检查。战场与头像现在直接使用alpha和线性采样；旧绿底像素图保留为历史资源，不再被人物运行时代码引用。左侧装备栏仍用此前单独确认的立绘。

以下为此前素材记录，历史“正式/当前”指各批次当时版本。

## 2026-09-06 装备区人物本地抠图

用户原图：`C:/Users/16563/Downloads/00081-1922854840.png`，1536×2304。正式透明资源：`equipment-portrait-cutout-v1.png`，621×2098；裁剪范围为原图(463,164)至(1084,2262)，保留14像素边距。该资源直接处理原图，没有生成式重绘，原文件不修改。

`tools/extract_portrait.py`以Pillow/numpy识别边缘连通的近白背景，再清理经人工查看确认的三个封闭背景区域，原图种子坐标为(644,622)、(816,524)、(743,879)。只处理背景与相邻边缘的透明度/白底混色，人物内部白色衣料不作全局色键删除。输出695837个透明像素、保留21940个不透明近白像素；已在深色背景检查头发、手臂间隙与衣料。需要复现时向脚本传入原图、输出路径及三个`--background-seed x,y`参数。

装备栏使用真实alpha与等比完整缩放，战场继续使用原三姿态像素图。立绘不随装备改变，不冒充穿戴差分。

## 2026-09-06 界面与敌人美术升级

正式资源：`assets/art/enemies-atlas-v2.png`，1536×1024；使用内置 image_gen 生成及编辑。六个区域依次为浮游绳索、皮带、锁、眼罩、封口符板和穿完整制服的成年女性警卫。区域坐标由 `ui/pixel_art.gd` 统一登记，所有敌人共用 `ui/arena.gd`；卡牌插图复用图集。没有新增敌人机制。

生成器未产出真实透明通道：最初是暗底，第二稿是烘焙棋盘底，均未采用。最终采用纯绿底源图，当时通过 chroma_key 画材运行时透明合成（历史方案；2026-09-11确认已无运行时调用，删除其闲置接口与着色器，源PNG保留）；源PNG原样复制，没有手工绘改。最终生成原文件为 `G:/CodexData/generated_images/01a070f2-5b3a-7980-82c2-3816e7a504a1/exec-a3942014-f81b-4b17-9f59-0fe5b3594d89.png`。用户批准的人物图集保持原样。

初次生成提示词：
Use case: stylized-concept. Asset type: one production sprite atlas for a side-view anime pixel-art fantasy roguelike. Create a 1536 by 1024 transparent PNG sprite sheet, exactly THREE COLUMNS and TWO ROWS of equal 512x512 cells, no gridlines, no labels, no text. Each cell contains one complete isolated game enemy centered with generous transparent margins; nothing crosses cell borders. Consistent polished 32-bit JRPG pixel-art, crisp visible pixel clusters, dark navy outlines, 5-tone shaded materials, antique gold highlights, pale cyan magic. TOP LEFT: a floating living coil of thick pale hemp rope, asymmetrical S-shaped dynamic knot, loose ends, tiny cyan runic glints. TOP MIDDLE: a floating curled dark brown leather belt with a large ornate bronze rectangular buckle, supple curling strap and punched holes, elegant serpentine silhouette. TOP RIGHT: a floating imposing antique padlock, dark iron body, gold keyhole, arched brass shackle, a couple of cyan rune motes. BOTTOM LEFT: a floating opaque violet cloth eye mask, silver rim, long trailing ribbons curving upward, its oval mask clearly different from the belt. BOTTOM MIDDLE: a floating dark blue enchanted sealing plate, compact curved oval central plate with a bright cyan seal rune, small leather fastening straps flowing behind, no person and no anatomy. BOTTOM RIGHT: one adult woman palace guard age 30, full body 3/4 SIDE VIEW FACING LEFT in a confident grounded combat stance, mature face, long dark plum hair ponytail, peaked navy cap with bronze insignia, fully clothed high-collared tailored navy uniform jacket, fitted trousers, tall boots, gold shoulder trim, utility belt with a coil of rope and a ring of keys, one hand holding a short baton downward. Character realistic anime adult proportions about 6.5 heads tall, not chibi, no cleavage, no fetish styling. Guard sprite should fit entirely in its own cell and occupy 88% of cell height. Other objects occupy 65-75% of their cells. Truly transparent background and spaces between sprites; no scenic backgrounds, no drop shadows, no glow clouds, no gradient vignette, no typography, no watermark. High quality finished game sprites not flat icons.

最终编辑提示词：
Production sprite-sheet edit. Keep the exact six sprites, positions, proportions, pixel details and colors in this image. Replace EVERY white and grey checkerboard background square and ALL empty space between and inside the sprites with one perfectly flat chroma-key color RGB(0,255,0), hex #00FF00. This is a green-screen sprite atlas. Absolutely no checkerboard, no gradient, no texture, no shadows or lighting on the background. All background pixels must be pure bright green including openings inside rope and belt and padlock loop, between limbs and loose ribbons. Preserve dark navy sprite edges and crisp cyan magic marks. Keep layout dimensions unchanged. Do not add/remove/repose any sprites.

UI边框、地图图标、卡牌面、配色与伤害数字由Godot绘制；统一样式在 `ui/visual_theme.gd`，伤害表现只消费提交前后可见生命变化，不改规则与资源。

使用内置 image_gen 工具生成；2026-09-06。
用户最新选择：暂用本轮上传的三姿态像素图，不继续重画。已将附件原样收纳为正式人物图集，替换此前的严格侧视稿。

## 正式人物素材
`assets/art/hero-poses-selected-v1.png`，源为用户上传的 `codex-clipboard-154312eb-6ae2-4400-b7f8-0356593d60f6.png`（1774×887）。站姿保留用户选择的三分之四视角，坐/躺保留同图姿态；不再将该版本描述为严格正侧视。前置生成参考为网页项目仓库 `mahou-shoujo-escape` 的 `public/assets/character/source-pose-sheets-v1/hero-standing-three-view-v1.png`，仅参考画风与人物外形，不读取或复用旧规则代码。

初次像素姿态提示词：
Use case: stylized-concept. NEW original pixel-art character pose sheet. The attached reference is ONLY the intended identity, costume, and PIXEL ART drawing style. Closely match its beautiful detailed anime pixel sprite aesthetic: pink-haired green-eyed adult magical heroine, age 26, large white ribbon with pink edges, partial high ponytail, layered pink dress with white ruffle hems and small gold heart brooch, white gloves, white boots with pink accents. Keep the recognizable original heroine design. Clear clustered pixel shading, delicate pixel outlines, carefully placed hair highlights, vibrant yet soft pinks, sprite proportions similar to the reference (about 5.5 heads tall, unmistakably an adult fantasy heroine), NOT smooth vector art, NOT painterly illustration, NOT a portrait. Make a single WIDE landscape sprite sheet divided into three equal invisible columns with at least 50 pixels clear space between figures. Column LEFT: full-body standing, 3/4 view facing right, arms comfortably at sides, hands visible and free. Column CENTER: same character seated on invisible floor facing right, torso upright, hands relaxed beside hips, bent knees and boots extending right, dress worn normally covering upper thighs. Column RIGHT: same character resting lying on her back on invisible floor, head on left and feet on right within that column, hands resting on abdomen, both legs extended, dress worn normally. All three poses must fit completely inside their own column; no overlap between columns; keep costume, face and hair identical. Use readable crisp pixel sprites at a consistent pixel density. Background must be perfectly flat chroma green #00FF00 everywhere outside the sprites, for Godot real-time cutout; no shadows, no floor, no gradient, no checkerboard, no text, no labels, no frames, no watermarks. Nonsexual neutral combat/resting poses, fully clothed, no restraints. Only these three sprites.

先前侧视草稿提示词（当前停用，文件保留为`hero-side-poses-v1.png`）：
Use case: precise-object-edit. Revise this three-pose pink-haired magical heroine pixel-art sheet for a TRUE SIDE-SCROLLING 2D BATTLE GAME. Preserve the same adult character age 26, beautiful detailed anime pixel rendering, pink ponytail, green eyes, big white-and-pink bow, layered pink dress, long white gloves and white/pink boots. Change the camera to STRICT ORTHOGRAPHIC SIDE VIEW AT BODY HEIGHT: absolutely NO top-down view, NO three-quarter/front view, NO foreshortening. LEFT sprite: standing neutral READY pose facing exactly screen RIGHT in complete side profile, one visible profile eye and one nose silhouette, both hands relaxed and free, aligned with body; character head, torso, hips, knees, and boots all shown from the side. MIDDLE sprite: seated facing exactly screen RIGHT, same strict side camera, upright torso and relaxed bent knees, boots point right; hands resting beside hips, skirt normally covers upper thighs. RIGHT sprite: lying on her back with head LEFT and boots RIGHT, shown strictly from her body's SIDE as in a side-scroller resting animation, no overhead view; face profile looks upward naturally, hands on abdomen, legs straight. Each figure fully isolated with generous separation, one figure per zone, no overlap, same character design and pixel scale across poses. Three sprites placed left-to-right in a single wide sprite sheet. Keep entire background perfectly uniform chroma green #00FF00 for game-engine compositing, no shadows, no gradient, no checkerboard, no stage, no panels, no words, no watermark. Fully clothed, nonsexual poses, no restraints. Emphasize exact side profile silhouettes and crisp beautiful pixel clustering.

生成源文件带绿色底，游戏通过统一画材做实时透明合成；源PNG原样保存，未手工重画或后处理。原图集的三个姿态区域分别读取，按正式姿态切换。这里只表现基础姿态，并非装备差分图。

## 正式背景素材
`assets/art/moonlit-gallery-v1.png`。
Use case: stylized-concept. Production game asset: one empty illustrated 16:9 widescreen battle background for an original Japanese anime magical-heroine card battler. A beautiful moonlit tower interior, a broad lateral stone arcade, elegant pointed arches, slender carved columns, tall violet stained-glass windows high behind the scene, a few warm brass sconces, deep indigo night visible through an arch, subtle floating silver dust. Fine hand-drawn anime linework with clean gentle cel-painted shading and layered atmospheric depth, polished Japanese RPG background art. Cool dusty lavender and blue-gray stone, muted antique gold details, restrained soft rose reflections that will harmonize with a pink-haired green-eyed heroine in a pink-white magical dress. The central play area must be uncluttered: no figures, no enemies, no cages, no large props. A wide level stone floor spans the image, floor-wall boundary around 58% of height, camera mostly side-on at a slightly elevated battle-game angle; smooth perspective without an extreme vanishing point. Keep the lower quarter dark and quiet because cards will overlay it; leave the upper area readable for intent panels. Light falls softly from upper right, faint warm fill from left. Elegant and enchanting with a hint of mystery, not horror. No pixel art, no photorealism, no gritty texture noise, no UI, no text, no lettering, no watermark. Wide 1536x1024 or 16:9 composition suitable for a Godot background.

## 未采用草稿
银发人物、平滑赛璐璐粉发人物与严格侧视像素稿均未接入当前运行时。当前采用用户重新上传并指定的三姿态像素稿。

## 2026-09-07：腿部按实际部位整段替换

用户最后确认：裁下绳子及周围整段腿部，保留皮肤、袜子及受压轮廓，不仅提取红绳。源图是`C:/Users/16563/Downloads/00077-1312644243.png`，1536×2304；无拘束腿段来自用户原图1。七处分别为大腿根、大腿中部、膝上、膝下、小腿中间、脚踝、脚掌，脚趾暂无差分。

`tools/build_equipment_leg_layers.py`生成每处有拘束/无拘束两张v3 PNG与挖空对应腿段的`equipment-body-sliced-v3.png`；上下切边12像素过渡，中央完整保留源图腿段。无拘束七段可逐像素还原原底图，脚部外形不会被旧底图重叠覆盖。坐标、裁框、图片路径和显示映射统一记录在`equipment-leg-layers.json`。全部为本地裁切合成，无生成式重绘，原文件不变。

普通大腿控制前三段，小腿控制膝下和中段；独立外带只控制真实固定点。自由图、原图1的分段底图、嘴/眼图层保持原接口。旧legs1—4不再用于运行时；本次中间的v2纯绳贴片已清理；图像不决定或改变装备规则。

## 2026-09-07：地图独立素材正式接入

map-icons-v1 与 map-parts-v2 均为本任务内置 image_gen 生成，逐图原始提示词和来源记录保存在各目录。ui/route_map.gd 直接使用独立PNG，纸面只在绘制时以0.78调暗，未生成或修改原图。入口、当前位置、可前往及完成标记均按正式投影显示；侧边建筑不拦截输入。纸面按视口等比裁取，不使用未验证的无缝平铺。此前 map-assembly-v1 仍为历史静态示意，不参与游戏。

route窗口88项通过。实际截图与日志见docs/verification.md本批记录。

## 2026-09-07：商店代码绘景

ui/shop_scenery.gd 和 ui/shop_glyph.gd 使用 Godot 原生几何绘制棚檐、灯笼、商人、柜台、货架和商品符号；无外部图片、无生成式绘图。卡牌插图复用项目既有 pixel_art 图集。只参考摊位陈列这一界面组织方式，不复制其他游戏的商人或美术。灯光与商人轻微起伏只按显示时间变化，不使用游戏随机域。

## 2026-09-09：魅魔的三局赌牌立绘

用户指定原图 C:/Users/16563/Downloads/00013-3999890640.png 复制为 event-fortune-teller-v1.png（1536×2304）。源图与项目文件 SHA256 一致，未重绘、裁切或去背景。事件只读投影公开稳定 id，ui/event_screen.gd 按 succubus_three_games 选择图片，所有阶段及结果页沿用；其他事件保留占位。左侧300×450画框内等比完整显示，图片不接收鼠标输入。

## 2026-09-10：废弃储物室与漂浮皮带群插图

用户确认接入本对话内置 imagegen 生成的两张最终预览；复制原 PNG，源文件保留，SHA256 校验一致。共用 `ui/event_screen.gd::ARTWORK`，正式事件与练习均按稳定事件 ID 加载，沿原画框完整等比显示、线性采样且不接收鼠标输入。

- `event-abandoned-storeroom-v1.png`：来源 `G:/CodexData/generated_images/01a07aed-ccd8-70b2-bc98-da783f6cdbe3/exec-59f91b5d-ac5c-4b0f-9cac-28501fc015ee.png`；采用第二版日系二次元绘制，前景为药剂、卷轴与工具。
- `event-floating-belt-cluster-v1.png`：来源 `G:/CodexData/generated_images/01a07aed-ccd8-70b2-bc98-da783f6cdbe3/exec-a4d3480c-13b5-4652-b6a4-3e26d05b88ac.png`；采用减少到约七条皮带后的版本，保留粉色附魔纹路与高塔回廊。

原三局赌牌插图保留；本批没有重新生成、裁切、拉伸或修改事件规则与正文。

## 2026-09-10：迷宫测绘队插图

用户提供 `C:/Users/16563/Downloads/00084-4094280623.png`，原样复制为 `event-maze-survey-team-v1.png`。源图与项目文件 SHA256 均为 `BA3494EAEE489196447608F8F49D6413229A76C3559DCB42B8EEE2C6A3DDC23F`；未重绘、裁切或拉伸。`ui/event_screen.gd` 按 `maze_survey_team` 加载，正式事件与练习共用，沿原画框完整等比显示。

## 2026-09-10：偷渡商人的魔药箱插图

用户提供 `C:/Users/16563/Downloads/00085-558123539.png` 并指定接入偷渡商人的魔药箱，原样复制为 `event-smuggled-mana-potions-v1.png`，源图保留，SHA256校验一致。`ui/event_screen.gd::ARTWORK` 按 `smuggled_mana_potions` 加载；正式事件与练习共用，沿现有画框完整等比显示、线性采样且不拦截鼠标。

## 2026-09-10：魅纹师的空房插图

用户提供 `C:/Users/16563/Downloads/00086-4247279898.png` 并指定接入魅纹师的空房，原样复制为 `event-enchanters-empty-studio-v1.png`，源图保留，SHA256校验一致。`ui/event_screen.gd::ARTWORK` 按 `enchanters_empty_studio` 加载；正式事件与练习共用，沿现有画框完整等比显示、线性采样且不拦截鼠标。

## 2026-09-10：女药师的试饮摊插图

用户提供 `C:/Users/16563/Downloads/00087-1686288904.png`，原样复制为 `event-alchemist-tasting-stall-v1.png`，源图保留，SHA256校验一致。`ui/event_screen.gd::ARTWORK` 按 `alchemist_tasting_stall` 加载；正式事件与练习共用，沿现有画框完整等比显示、线性采样且不拦截鼠标。

## 2026-09-10：缚疗修女插图

用户提供 `C:/Users/16563/Downloads/00088-549235516.png`，原样复制为 `event-binding-cleric-v1.png`，源图保留，SHA256校验一致。`ui/event_screen.gd::ARTWORK` 按 `binding_cleric` 加载；正式事件与练习共用，沿现有画框完整等比显示、线性采样且不拦截鼠标。

## 2026-09-10：拘束具堆里的微光插图

用户提供 `C:/Users/16563/Downloads/00089-3699988499.png`，原样复制为 `event-bound-adventurer-relic-v1.png`，源图保留，SHA256校验一致。`ui/event_screen.gd::ARTWORK` 按 `bound_adventurer_relic` 加载；正式事件与练习共用，沿现有画框完整等比显示、线性采样且不拦截鼠标。

## 2026-09-10：缚梦客房插图

用户提供 `C:/Users/16563/Downloads/00090-3863653336.png`，原样复制为 `event-bound-dream-guest-room-v1.png`，源图保留，SHA256校验一致。`ui/event_screen.gd::ARTWORK` 按 `bound_dream_guest_room` 加载；正式事件与练习共用，沿现有画框完整等比显示、线性采样且不拦截鼠标。

## 2026-09-10：神秘女人的雕像插图

用户提供 `C:/Users/16563/Downloads/00091-1968829285.png`，原样复制为 `event-mysterious-woman-statue-v1.png`，源图保留，SHA256校验一致。`ui/event_screen.gd::ARTWORK` 按 `mysterious_woman_statue` 加载；正式事件与练习共用，沿现有画框完整等比显示、线性采样且不拦截鼠标。

## 2026-09-10：魅魔的魔力典当铺插图

用户提供 `C:/Users/16563/Downloads/00093-2888790767.png`，原样复制为 `event-succubus-magic-pawnshop-v1.png`，源图保留，SHA256校验一致。`ui/event_screen.gd::ARTWORK` 按 `succubus_magic_pawnshop` 加载；正式事件与练习共用，沿现有画框完整等比显示、线性采样且不拦截鼠标。


## 2026-09-10：翘腿无视正式卡牌立绘

用户原图`C:/Users/16563/Downloads/00094-2394729949.png`（1536×2304）通过`tools/prepare_crossed_legs_art.py`本地抠图，复用色彩播种GrabCut并按已核对区域保留饮料、玻璃杯与吸管；定向清除座面阴影和手臂／躯干／大腿之间的背景孔洞。原图保持不变，没有生成或重绘。输出`card-crossed-legs-formal-v1.png`为1536×2138透明RGBA，原图裁框(0,64,1536,2202)，不拉伸、不裁去人物。

正式图登记到DisplaySettings.FORMAL_ART.cards.crossed_legs，原SVG继续作为测试版。透明区直接显示CardFace原有双面暗色背景，不烘焙另一份背景，也不改牌面效果。

源图SHA-256：`1eb9ca45fbb08cadbb4d74117602b6fe478248f41ccc4884fc5022fc980cc4b2`。输出SHA-256：`e029664d70119e811aa5e71a304ec3c05a0ba08ef3f1c295011ac4e2ea4f4aca`。

## 2026-09-11：商店自身魔力付款演出

用户提供的图2—5原样复制到 `assets/art/`，未裁切、重绘或拉伸；Godot以完整等比方式显示。现有常驻店主图 `assets/characters/shopkeeper.png` 按用户要求保持不变，图1不重复接入。四张演出图只表现已经成功提交的自身魔力付款，不参与付款资格、上半身束缚等级或随机结算。

- `00012-659780370.png` → `shop-payment-self-v1.png`，SHA256 `B05EE7A57A71F208E592DE59D3DE56841AF00306722FE314D34EBE5A0C60CB39`。
- `00006-2887118337.png` → `shop-payment-sleeve-v1.png`，SHA256 `0136966BEEDF7A0DCE2DE017EC42BCB03C2F032074222D68992B0DDF6A416BC6`。
- `00007-4136421944.png` → `shop-payment-hand-v1.png`，SHA256 `73F008719326CE976AF65BD57171BF279DD714C4499ECAC4A6BEF1E53AE81CDD`。
- `00010-2041060406.png` → `shop-payment-foot-v1.png`，SHA256 `738BFC24E23103EEDF98B67A5357B532462CE839B60399FEC8E7D4E0925D8127`。

## 2026-09-13：平板锁、加固带与马眼棒拘束立绘差分

用户提供四张1536×2304对齐原图，由`tools/build_equipment_special_layers.py`在本地进行白底抠图与像素差分，没有调用生成式绘图。图1与图2形成平板锁替换；图3相对图2扣除已经处理的平板锁后形成加固带透明层；图4与图3形成马眼棒透明层。源图保持不变，完整路径、配对关系与SHA-256记录在`equipment-special-layers.json`。

平板锁会移除原底图对应区域，因此输出同尺寸`equipment-body-flat-lock-v1.png`，并为会覆盖其下缘的大腿根分段输出有拘束／无拘束两个对应版本。加固带与马眼棒分别输出`equipment-overlay-flat-lock-reinforcement-v1.png`、`equipment-overlay-urethral-rod-v1.png`。构建脚本在暗色背景上重组大腿分段并检查可见接缝。

这些差分只应用于拘束站姿：左侧身体与拘束具立绘，以及战斗中复用同一拘束站姿的角色立绘。自由立绘、“扶她出去”固定立绘、坐姿与躺姿均不显示。普通平板锁显示锁体；真实加固带存在时叠加加固带；只有存在任意平板锁，且该锁内置导尿管或同时佩戴独立马眼棒时，才叠加依附锁体绘制的马眼棒差分。单独佩戴马眼棒时不显示该差分。显示只读取`equipment_portrait_layers`投影，不参与装备规则、容量、耐久、锁、高潮或随机结算。

## 2026-09-15：小魔女站／坐／躺立绘

用户明确提供并授权以下本地原图作为小魔女三姿势素材；仅使用`tools/extract_portrait.py`在本地去除白底，没有生成、重绘、变形或改色。

- 站姿源`C:/Users/16563/Downloads/00000-3192334327.png`，1536×2304，SHA-256 `913D0560A27695BECB67BAAFAEB35A9C342122669B32EA1B8203691ADC52B1C0`。外部白底种子`(1200,1800)`，前景连通种子`(750,1050)`，输出`witch-stand-cutout-v1.png`为1536×2295，SHA-256 `48645E61E95C76F1ED52E73ED15917CCA9FE8441A16A47E13109DFC80F2214FD`。
- 坐姿源`C:/Users/16563/Downloads/00002-1650663794.png`，1856×2112，SHA-256 `DD2A2214CB44319E8759044949988CD0038D87537E2148F87A9A167591D50CEB`。外部白底之外，只清除用户指出的帽内`(592,323)`与脚／斗篷之间`(1231,1699)`两个封闭白底区域；没有使用会误伤大腿的`(1168,1670)`区域。裁框`(15,63,1848,2070)`，输出`witch-sit-cutout-v1.png`为1833×2007，SHA-256 `79000FA19A3B978A536DCE726EC048D8DAE0D403072A6BB9EBF16AABD4ABF2BE`。
- 躺姿源`C:/Users/16563/Downloads/00003-3976721801.png`，2112×1856，SHA-256 `96ED0524705CB2FFAB48E8A6508504842B2E0BE4D2F4F4740AEE01EEDAB74652`。封闭白底种子`(1726,1110)`用于清除用户指出的双腿间白底，裁框`(20,221,2112,1777)`，输出`witch-lie-cutout-v1.png`为2092×1556，SHA-256 `BCB18D7046AA0562953CAB31288C2A22564FAD6879B0D03AEEDF70D30DD5D045`。
- 左侧身体栏从站姿源按`(460,0,1380,2304)`裁成920×2304的`witch-sidebar-cutout-v1.png`，SHA-256 `2A39CA5647C8370507B60B49243C63ECA6BE700FA745659DA6CCC66E4DC78725`。相对首版裁框向右取景320像素，使人物身体在现有178×454画框内向左移动并居中，保持同一宽高比。

战场根据只读View中的`character_id`和真实姿势选择三张图；身体栏使用独立窄裁图。小魔女暂无拘束差分，因此拘束状态不叠加角色1的嘴、眼、腿、平板锁或复合拘束图层。该显示映射不改变装备、姿势、资源、卡牌、随机或存档。
