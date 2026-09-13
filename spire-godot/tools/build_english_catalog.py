"""Build the transitional English display catalog with an offline CTranslate2 model.

The runtime never includes the model. It loads only the generated JSON. This
script does not edit gameplay sources and resumes from a cache under build/.
"""
from hashlib import sha256
from pathlib import Path
import json
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / "build"
DEPS = BUILD / "translation-lite"
MODEL = BUILD / "argos-model/translate-zh_en-1_9"
CACHE = BUILD / "english-translation-cache-v4.json"
OUTPUT = ROOT / "assets/localization/legacy-en_US.json"
sys.path.insert(0, str(DEPS))

try:
    import ctranslate2
    import sentencepiece as spm
except ImportError:
    ctranslate2 = None
    spm = None

CJK = re.compile(r"[\u3400-\u9fff]")
FORMAT = re.compile(r"%(?:[-+ 0#]*)(?:\d+|\*)?(?:\.(?:\d+|\*))?[diouxXfFeEgGaAcsp]")
NAMED = re.compile(r"(?<!\{)\{(?:[A-Za-z_][A-Za-z0-9_.]*|\d+)\}(?!\})")
TAG = re.compile(r"\[(?:/?[A-Za-z][^\]\n]*|[^\]\n]*=[^\]\n]*)\]")
_SUFFIXES = "alpha beta gamma delta epsilon zeta eta theta iota kappa lambda mu nu xi omicron pi rho sigma tau upsilon phi chi psi omega".split()
WORDS = ["Placeholder" + suffix for suffix in _SUFFIXES]
WORDS += ["Placeholder" + first + second for first in _SUFFIXES for second in _SUFFIXES]

# Longest first. Protect only terms whose meaning must remain stable. Protecting
# ordinary nouns and verbs breaks Chinese sentence structure for small models.
GLOSSARY = {
    "紧缚尖塔": "Bound Spire", "魔法少女": "Magical Girl", "魔瓶魔力": "Flask Mana",
    "临时魔力": "Temporary Mana", "施法成功率": "Cast Success Rate", "魔法伤害": "Spell Damage",
    "挣扎伤害": "Struggle Damage", "滑脱伤害": "Slip Damage", "固定伤害": "Fixed Damage",
    "抽牌堆": "Draw Pile", "弃牌堆": "Discard Pile", "消耗区": "Exhaust Pile",
    "火球术": "Fireball", "术式解锁": "Spell Unlock", "魔术手": "Mage Hand",
    "拘束之拥": "Restraint's Embrace", "身轻如燕": "Featherlight",
    "般若汤": "Hannya Brew", "淫纹": "Lewd Mark", "正义飞踢": "Justice Kick",
    "软化扣环": "Softened Buckle", "贞操锁": "Chastity Lock", "平板锁": "Plate Lock",
    "拘束具": "Restraint", "蓄力": "Charge", "闪避": "Evasion", "力量": "Strength",
    "灵巧": "Dexterity", "快感": "Arousal", "魔力": "Mana", "能量": "Energy",
    "耐久": "Durability", "紧度": "Tightness", "挣扎": "Struggle", "滑脱": "Slip",
    "伤害": "Damage", "施法": "Cast", "卡组": "Deck", "手牌": "Hand", "卡牌": "Card",
    "普通": "Common", "罕见": "Uncommon", "稀有": "Rare",
}

MANUAL = {
    "每佩戴%d件拘束具，本回合获得1点力量，不足%d件不计。": "For every {p0} restraints worn, gain 1 Strength this turn. Fewer than {p1} do not count.",
    "每佩戴%d件拘束具，恢复1点魔力。": "For every {p0} restraints worn, restore 1 Mana.",
    "每佩戴%d件拘束具，本回合获得1点力量，不足%d件不计。\n当前：本回合力量＋%s。": "For every {p0} restraints worn, gain 1 Strength this turn. Fewer than {p1} do not count.\nCurrent: +{p2} Strength this turn.",
    "每佩戴%d件拘束具，恢复1点魔力。\n当前：恢复%s魔力。": "For every {p0} restraints worn, restore 1 Mana.\nCurrent: restore {p1} Mana.",
    '限制项圈': 'Restriction Collar',
    '无耐久': 'No durability',
    '先开锁，双臂自由后取下': 'Unlock first, then remove with both arms free.',
    '限制项圈没有耐久，须先开锁，再在双臂自由时取下；品相完美版 henshin 可直接解除。': 'The Restriction Collar has no durability. Unlock it, then remove it with both arms free. Perfect henshin can remove it directly.',
    '限制项圈不能通过耐久变化松解。': 'The Restriction Collar cannot be loosened by changing durability.',
    '已经佩戴限制项圈。': 'A Restriction Collar is already equipped.',
    '不能重复佩戴限制项圈。': 'Only one Restriction Collar can be equipped.',
    '佩戴限制项圈时不能使用 henshin；品相完美版不受影响。': 'The Restriction Collar prevents henshin. Perfect henshin is unaffected.',
    '先用开锁术或开锁工具打开限制项圈的锁。': 'Unlock the Restriction Collar with an unlocking spell or tool first.',
    '双臂需要完全自由才能取下限制项圈。': 'Both arms must be fully free to remove the Restriction Collar.',
    '取下限制项圈': 'Remove Restriction Collar',
    '取下已开锁的限制项圈，花费1能量。': 'Remove the unlocked Restriction Collar for 1 Energy.',
    '取下了已开锁的限制项圈。': 'Removed the unlocked Restriction Collar.',
    '打开限制项圈的锁；双臂自由后可取下。': 'Unlock the Restriction Collar. It can then be removed with both arms free.',
    '位置：颈部\n无耐久 · 不计入拘束具件数\n佩戴时不能使用普通 henshin。\n': 'Location: Neck\nNo durability; excluded from restraint counts.\nPrevents normal henshin while equipped.\n',
    '已开锁 · 双臂自由后可取下': 'Unlocked; removable with both arms free',
    '3级及以上入狱时固定佩戴，不计入件数。\n佩戴时无法使用普通 henshin。\n': 'Automatically equipped on imprisonment at security level 3 or higher; excluded from restraint counts.\nPrevents normal henshin while equipped.\n',
    '拘束具保底%d件，不足时补齐并额外增加%d件、全部至少2档；已达保底则不补装，全部收紧1档，最多3档。另加%d件2档特殊装备，空位不足不替换。': 'Minimum {p0} restraints. Below the minimum, fill to it and add {p1} more, all at least tier 2. At or above it, add none and tighten each by 1 tier, capped at 3. Add {p2} tier-2 special items to free slots only; existing items are not replaced.',
    '五级进入高安全监室。': 'Level 5 leads to the high-security ending.',
    '原有拘束具收紧1档，最多3档。': 'Existing restraints tighten by 1 tier, capped at 3.',
    '普通与复合拘束具收紧至至少2档。': 'Ordinary and composite restraints tighten to at least tier 2.',
    '即将转入高安全监室。': 'Transfer to the high-security cell follows.',
    '执行收押。警戒度升至%d，没收%d件道具；追加%d件拘束具、%d条链接和%d件特殊装备。': ' completes the arrest. Security rises to {p0}. Confiscated {p1} items; added {p2} restraints, {p3} links and {p4} special items.',
    '佩戴限制项圈。': 'Restriction Collar equipped.',
    '3级起固定佩戴限制项圈，不占件数。': 'At level 3 or higher, a Restriction Collar is equipped separately and does not count toward the minimum.',
    '携带卡组与遗物继续游玩仍累计；新开游戏归零': 'Retained when continuing with your deck and relics; reset only in a new game',
    '新的塔路已展开。第%s阶段：怪物基础生命×%s，可解除的装备已解除，魔力已补满；快感降低%s，姿势变为站立。': 'A new tower awaits. Stage {p0}: base enemy HP x{p1}. Eligible equipment was removed and Mana refilled; Arousal decreased by {p2}, and you are standing.',
    '保留卡组、遗物、成长与监狱警戒度，开启全新塔路。怪物基础生命×%s；解除可解除的装备并补满魔力，快感降低%s（最低0），姿势变为站立。': 'Start a new tower while keeping your deck, relics, growth and prison security. Base enemy HP x{p0}; remove eligible equipment, refill Mana, reduce Arousal by {p1} (minimum 0), and stand up.',
    '没收%d件道具，清除临时增益。追加%d件拘束具、%d条链接、%d件特殊装备。': 'Confiscated {p0} items and cleared temporary buffs. Added {p1} restraints, {p2} links and {p3} special items.',
    '限制项圈不计入件数；开锁后须双臂自由才能取下，品相完美版 henshin 可直接解除。': 'The Restriction Collar is excluded from restraint counts. Unlock it and free both arms to remove it; Perfect henshin can remove it directly.',
    '警戒度达到5，移入高安全监室。原装备结构与链接保留，普通与复合装备补齐至高级三档，可上锁处全部上锁；限制项圈继续保留。本次逃脱结束，可以检查最终装备或重新开始。': 'Security reaches level 5. Transfer to the high-security cell preserves existing structures and links, fills ordinary and composite restraints to advanced tier 3, and locks every lockable piece. The Restriction Collar remains equipped. This escape attempt has ended; inspect your equipment or start a new game.',
    '高安全监室：共%d件普通装备、组件与链接，全部高级三档（%s/%s耐久），可上锁处全部上锁。另佩戴无耐久的限制项圈。本局已经结束，可在左侧逐件检查。': 'High-security cell: {p0} ordinary pieces, components and links, all advanced tier 3 ({p1}/{p2} durability), with every lockable piece locked. A durability-free Restriction Collar is equipped separately. This run has ended; inspect individual pieces on the left.',
    '高安全监室的限制项圈必须上锁。': 'The Restriction Collar must be locked in the high-security cell.',
    '%d级：保底%d件，额外%d件，特殊装备%d件。': 'Level {p0}: minimum {p1} restraints, {p2} extra restraints, {p3} special items.',
    '警戒度与入狱': 'Security and Imprisonment',
    '每次入狱，警戒度＋1；携带卡组和遗物继续游玩也会保留，只有新开游戏归零。\n': 'Each imprisonment raises Security by 1. Continuing with your deck and relics preserves it; only a new game resets it.\n',
    '\n普通和复合拘束具按整件计数。不足保底时补齐并额外增加，全部至少2档；已达保底则不补装，全部收紧1档，最多3档。特殊装备以2档添加，空位不足不替换。\n3级起固定佩戴限制项圈，不占件数；须先开锁，再在双臂自由时取下。佩戴时禁止普通 henshin，品相完美版可以使用并直接解除项圈。\n检查补装的等级与紧度：\n': '\nCount each ordinary restraint or active composite root once. Below the minimum, fill to it and add the extra amount; all pieces become at least tier 2. At or above the minimum, add none and tighten each by 1 tier, capped at 3. Add tier-2 special equipment only to available slots, without replacement.\nFrom level 3, a separate Restriction Collar is equipped and excluded from the count. Unlock it, then remove it with both arms free. It blocks normal henshin, but Perfect henshin can remove it directly.\nInspection replacement grades and tiers:\n',
    '\n3级起可出现复合装备，每套占1个名额。5级进入高安全监室。': '\nComposite restraints become available from level 3; each whole set counts once. Level 5 leads to the high-security cell.',
    # Follow-up pass: high-frequency UI, rule and narrative strings that the
    # compact model translated literally or with the wrong gameplay meaning.
    "柔软硅胶": "Soft silicone",
    "弱怪": "Lesser Enemy",
    "成功：获得一件随机遗物。": "Success: Gain a random relic.",
    "【离开】放弃继续尝试": "[Leave] Give Up",
    "你放弃继续尝试，带着已经缠到身上的拘束具离开了回廊。": "You stop trying and leave the corridor with the restraints already wrapped around you.",
    "自由": "Free",
    "硅胶与塑料": "Silicone and plastic",
    "捕缚": "Capture",
    "获得「": "Gain “",
    "领取「": "Claim “",
    "获得": "Gain",
    "精英": "Elite",
    "强怪练习": "Strong Enemy Practice",
    "诅咒眼罩封闭了眼部装备操作。": "The cursed blindfold prevents interaction with eye equipment.",
    "需要先到牢门前。": "Move in front of the cell door first.",
    "绳索": "Rope",
    "链接绳": "Link Rope",
    "已跳过": "Skipped",
    "诅咒": "Curse",
    "事件": "Event",
    "加固拘束具": "Reinforce Restraint",
    "上锁": "Lock",
    "加固": "Reinforce",
    "跳过": "Skip",
    "遗物": "Relic",
    "已解除。": "Removed.",
    "药剂": "Potion",
    "卷轴": "Scroll",
    "牢门": "Cell Door",
    "肩部": "Shoulders",
    "牢房": "Cell",
    "左手": "Left Hand",
    "右手": "Right Hand",
    "与": "and",
    "遗物宝箱": "Relic Chest",
    "地图画线损坏。": "Map path data is corrupted.",
    "皮带": "Belt",
    "%d层": "{p0} layer(s)",
    "受限": "Restricted",
    "升级时领取效果；当前等级详见出牌预览。": "Apply the upgrade effect; see the card preview for the current level.",
    "挣扎{base}。": "Struggle {p0}.",
    "牌": "card(s)",
    "开锁": "Unlock",
    "生命：%s\n": "HP: {p0}\n",
    "组合练习": "Combination Practice",
    "完成付款": "Complete Payment",
    "魅魔用手榨取了第一瓶精液": "The succubus milks out the first flask of semen by hand.",
    "你起身离开了牌桌。": "You rise and leave the card table.",
    "魅魔看见平板锁把肉棒压得一点也硬不起来，先是愣了愣，随即笑着从身后搂住你。双手揉压乳房、夹弄乳头，尾巴贴着小穴与阴蒂反复磨蹭；快感骤然冲上来，精液随高潮从锁具下流了出来": "The succubus notices the plate lock keeping your cock completely soft. She pauses in surprise, then smiles and wraps her arms around you from behind. She kneads your breasts and pinches your nipples while her tail rubs repeatedly against your pussy and clit. Arousal surges through you, and as you climax, semen leaks out beneath the lock.",
    "她没有停手，尾巴继续压着刚高潮过的阴蒂来回磨动，两根手指插进湿透的小穴连续勾弄，另一只手仍捏着乳头。第二次高潮很快压了上来，更多精液又从平板锁下断断续续流出": "She does not stop. Her tail keeps grinding over your still-sensitive clit while two fingers curl repeatedly inside your soaked pussy and her other hand continues pinching your nipple. A second climax quickly overwhelms you, and more semen trickles out from beneath the plate lock.",
    "切割": "Cut",
    "腿部": "Legs",
    "自由 · ": "Free · ",
    "打出「": "Play “",
    "强怪": "Strong Enemy",
    "一": "One",
    "二": "Two",
    "三": "Three",
    "所选卡牌已经不在卡组中。": "The selected card is no longer in your deck.",
    "，随后离场": ", then leaves",
    "执行收押": "Take Into Custody",
    "捕缚进度＋10": "Capture +10",
    "停顿": "Pause",
    "塔底入口": "Spire Entrance",
    "佩戴": "Equip",
    "施加了": "Applied ",
    "休息回合不足。": "Not enough rest turns.",
    "继续": "Continue",
    "取出": "Withdraw",
    "当前姿势下，": "In your current posture, ",
    "牢门已经打开。": "The cell door is already open.",
    "用": "Use ",
    "领取": "Claim",
    "前往": "Travel",
    "工具": "Tools",
    "道具": "Items",
    "监狱": "Prison",
    "塔路": "Spire Route",
    "手部": "Hands",
    "进入监狱": "Enter Prison",
    "诅咒平板锁": "Cursed Plate Lock",
    "支付%s魔力。": "Pay {p0} Mana.",
    "所选拘束具": "Selected Restraint",
    "装上": "Equip",
    "已经解除。": "Already removed.",
    "战斗遗物领取记录损坏。": "Battle relic claim data is corrupted.",
    "该敌人存活期间": "While this enemy is alive",
    "脚趾": "Toes",
    "%d张": "{p0} card(s)",
    "状态牌": "Status Card",
    "剩余%d回合": "{p0} turn(s) remaining",
    "战后整备": "Post-Battle Recovery",
    "下一次卡牌滑脱伤害×2。": "Next card Slip Damage ×2.",
    "滑脱{base}。": "Slip {p0}.",
    "挣扎{base}×{hits}。顺延。": "Struggle {p0} × {p1}. Delayed.",
    "状态": "Status",
    "魔力，不超过上限。": " Mana, up to the maximum.",
    "套体": "Sleeve",
    "般若汤赠牌": "Hannya Brew Card",
    "初级": "Basic",
    "中级": "Intermediate",
    "高级": "Advanced",
    "魔力商店": "Mana Shop",
    "战斗": "Battle",
    "金属与硅胶": "Metal and silicone",
    "夹在乳头上的无线震动夹。": "Wireless vibrating clamps worn on the nipples.",
    "环绕乳头持续震动。": "Vibrates continuously around the nipples.",
    "套在柱身上的震动环。": "A vibrating ring worn around the shaft.",
    "固定在冠沟位置的震动环。": "A vibrating ring fixed around the coronal ridge.",
    "你顶着新添拘束具的限制，终于勾住皮包的搭扣，将遗物抽了出来。她身上的拘束具仍原封不动。": "Working around the restraints newly added to your body, you finally hook the satchel clasp and pull out the relic. The restraints on her remain exactly as they were.",
    "魅魔低头看见平板锁把肉棒压得一点也硬不起来，明显怔了一下。“咦？连这里也锁住了呀？”她很快笑着从身后贴住你，揉压乳房、夹弄乳头，又用尾巴贴着小穴与阴蒂反复磨蹭，直到高潮将精液从锁具下流出": "The succubus looks down and pauses when she sees the plate lock keeping your cock completely soft. “Oh? They locked you up here too?” She soon presses against you from behind with a grin, kneading your breasts and pinching your nipples while her tail rubs over your pussy and clit, until you climax and semen leaks out beneath the lock.",
    "魅魔看着从锁具下流出的精液，笑着又敲了敲锁面。\n“姐姐连那根杂鱼肉棒都没碰哦？”\n“只是揉揉奶子、玩一下小穴，你就自己射出来了❤”\n\n她翻开牌面，啧了一声，把两枚心形筹码丢到桌上。\n“算你赢。筹码拿好啦。”": "The succubus watches the semen trickle out beneath the lock and taps its face with a teasing smile.\n“I didn't even touch that pathetic little cock, you know?”\n“All I did was fondle your tits and play with your pussy, and you came all by yourself❤”\n\nShe turns over the cards, clicks her tongue, and tosses two heart-shaped chips onto the table.\n“Fine, you win. Take your chips.”",
    "魅魔屈指敲了敲平板锁，低头看着锁具下面还在滴落的精液。\n“真的又射了呀？下面锁得这么严，奶子和小穴一碰却能连着射两次……”\n“你的杂鱼肉棒还真是不争气❤”\n\n她这才看向牌面。\n“这把也输了。都给你戴好，继续往上爬吧。”": "The succubus taps the plate lock with one finger and looks down at the semen still dripping beneath it.\n“You really came again? You're locked up so tightly down there, yet touching your tits and pussy made you come twice in a row…”\n“That pathetic little cock of yours really is hopeless❤”\n\nOnly then does she look at the cards.\n“I lost this hand too. I'll put everything on you, then you can keep climbing.”",
    "医用硅胶": "Medical silicone",
    "置于小穴内的无线跳蛋。": "A wireless egg vibrator placed inside the vagina.",
    "置于后庭内的无线跳蛋。": "A wireless egg vibrator placed inside the anus.",
    "由外部固定件压在小穴上的按摩棒。": "A vibrating wand held against the vagina by an external fixture.",
    "同时经过双穴区域，但只刺激小穴。": "Crosses both intimate areas but stimulates only the vagina.",
    " · %s魔力": " · {p0} Mana",
    "行动已失效，请重新选择。": "This action is no longer valid. Choose again.",
    "获得一件随机遗物。": "Gain a random relic.",
    "选择": "Select",
    "移除「{name}」": "Remove “{p0}”",
    "魅魔揉捏乳房与乳头，又用尾巴刺激小穴和阴蒂；锁下肉棒疯狂顶着锁板却无法勃起，精液随第一次高潮从平板锁下流出": "The succubus kneads your breasts and nipples while her tail stimulates your pussy and clit. Beneath the lock, your cock strains helplessly against the plate without becoming erect, and semen leaks out as your first climax hits.",
    "魅魔用乳沟榨取了第二瓶精液": "The succubus milks out the second flask of semen between her breasts.",
    "魅魔继续揉弄乳头，并用手指勾弄小穴；锁下肉棒再次徒劳顶动，更多精液随第二次高潮从平板锁下流出": "The succubus keeps teasing your nipples and curls her fingers inside your pussy. Your cock pushes helplessly against the lock again, and more semen leaks out beneath the plate lock with your second climax.",
    "就此离开": "Leave",
    "用1枚筹码换一张普通牌": "Trade 1 chip for a Common card",
    "的捕缚": "'s Capture",
    "消耗。": "Exhaust.",
    "固有。": "Innate.",
    "需要选择另一张当前手牌来消耗。": "Select another card in your hand to Exhaust.",
    "需要%s无拘束。": "Requires {p0} to be unrestrained.",
    "上身": "Upper Body",
    "超级顺延": "Full Follow-Through",
    "顺延": "Follow-Through",
    "的锁。": "'s lock.",
    "继续 · ": "Continue · ",
    "的": "'s ",
    "抽%d张%s": "Draw {p0} {p1}",
    "手指或脚趾任一部位自由即可使用。": "Requires either free fingers or free toes.",
    "show_pressure_sources 必须为布尔值。": "show_pressure_sources must be a boolean.",
    "show_pressure_sources 需要至少一个带 source 的快感效果。": "show_pressure_sources requires at least one Arousal effect with a source.",
    "同一个暂存 key 只能建立一次。": "The same temporary key can be created only once.",
    "选择一张牌": "Select a Card",
    "施加拘束具": "Apply Restraint",
    "施加复合拘束具": "Apply Composite Restraint",
    "展开六缚阵": "Deploy Sixfold Binding",
    "六重束装": "Sixfold Binding",
    "戏弄封缚": "Teasing Bind",
    "调教升温": "Heat Up",
    "复合束装": "Composite Binding",
    "六缚齐收": "Complete Sixfold Bind",
    "执行逮捕": "Make Arrest",
    "准备捕缚": "Prepare Capture",
    "发呆": "Idle",
    "甩缚": "Lashing Bind",
    "没有可以加固的拘束具，这次动作落空。": "There is no restraint to reinforce, so the action has no effect.",
    "本次没有指定要安装的装备。": "No equipment was selected for installation.",
    "装备品质或紧度档位不合法。": "The equipment quality or Tightness tier is invalid.",
    "本次不能替换刚安装的装备或附属件。": "Equipment or attachments installed during this action cannot be replaced.",
    "装备材质版本不合法。": "The equipment material version is invalid.",
    "该装备不能安装在这个位置。": "This equipment cannot be installed in that position.",
    "最外层没有满足本次容量、强度比较和完整覆盖要求的替换方案。": "No outermost replacement satisfies the capacity, strength, and full-coverage requirements.",
    "进入": "Enter",
    "你先行动": "You act first.",
    "敌人先行动": "The enemy acts first.",
    "单手套与拘束衣不能重复或互相覆盖。": "A single glove and a straitjacket cannot overlap or cover each other.",
    "所需位置已满。": "The required positions are full.",
    "翻卷收紧": "Wrap and Tighten",
    "准备捕缚。": "Prepare Capture.",
    "，紧度%d档。": ", Tightness tier {p0}.",
    "投降": "Surrender",
    "随身道具栏已满，无法拾取这件道具。": "Your inventory is full, so you cannot pick up this item.",
    "选择「": "Select “",
    "结束回合": "End Turn",
    "眼罩使站起额外消耗1能量。": "The blindfold makes standing up cost 1 additional Energy.",
    "打断": "Interrupt",
    "；可用部位：": "; available body parts: ",
    "安装到": "Install on ",
    "行动未提交：": "Action not submitted: ",
    "：本次施法必定成功。": ": This cast is guaranteed to succeed.",
    "，剩余耐久": ", remaining Durability ",
    "，收入道具栏。": ", added to your inventory.",
    "请先使用或放下超出容量的随身道具。": "Use or drop the items exceeding your inventory capacity first.",
    "当前房间还有未完成的事项，不能离开。": "You cannot leave while something in this room remains unresolved.",
    "无法继续这份存档：": "Unable to continue this save: ",
    "%s · 可使用%d次": "{p0} · {p1} use(s)",
    " · 领取后收入道具栏": " · Added to inventory when claimed",
    "选择一张卡牌": "Select a Card",
    "加入你的卡组": "Add to your deck",
    "已获得「": "Already gained “",
    "战 斗 奖 励": "Battle Rewards",
    "继续  ›": "Continue  ›",
    "位置：": "Position: ",
    "锁已打开": "Lock Open",
    "触手固定": "Tentacle Bind",
    "足部": "Feet",
    "需要先靠到工具所在墙边。": "Move beside the wall-mounted tool first.",
    "存入": "Deposit",
    "滑精": "Leaking Climax",
    "本回合深呼吸次数不正确。": "The Deep Breath count for this turn is invalid.",
    "普通或复合": "Standard or Composite",
    "高安全监室": "High-Security Cell",
    "需要先到通风口前。": "Move in front of the vent first.",
    "闪避抵消了%d件。": "Evasion prevented {p0} item(s).",
    "床边": "Bedside",
    "靠墙": "Against the Wall",
    "已经在这里。": "You are already here.",
    "引敌缚咒": "Binding Lure",
    "已经拥有这件遗物。": "You already own this relic.",
    "持有%d件。": "Holding {p0} item(s).",
    "战斗结束": "Battle Over",
    "恢复%s魔力。": "Restore {p0} Mana.",
    "魔力耳坠": "Mana Earrings",
    "事件道具奖励记录不完整。": "Event item reward data is incomplete.",
    "解除了": "Removed ",
    "恢复%s魔力，当前魔力%s/%s。": "Restore {p0} Mana. Current Mana: {p1}/{p2}.",
    "贴身魔瓶获得%s魔力，当前储量%s。": "The flask gains {p0} Mana. Current reserve: {p1}.",
    "诅咒眼罩无法解除。": "The cursed blindfold cannot be removed.",
    "已经松到%d档。": "Already loosened to tier {p0}.",
    "事件仍有尚未归还的装备。": "The event still has equipment that has not been returned.",
    "事件战斗记录不完整。": "Event battle data is incomplete.",
    "魔力恢复至%s/%s。": "Mana restored to {p0}/{p1}.",
    "事件道具奖励混入了战斗奖励记录。": "Event item rewards were mixed into the battle reward data.",
    "事件阶段不合法。": "The event stage is invalid.",
    "进入商店": "Enter Shop",
    "店主": "Shopkeeper",
    "存档小数损坏。": "A decimal value in the save is corrupted.",
    "存档数值损坏。": "A numeric value in the save is corrupted.",
    "尚无存档。": "No save data found.",
    "存档位置不存在。": "The save location does not exist.",
    "左肩": "Left Shoulder",
    "右肩": "Right Shoulder",
    "绳": "Rope",
    "房间敌人组合不符合生成要求。": "The room's enemy group does not meet the generation requirements.",
    "房间缺少指定种类的敌人。": "The room is missing the required enemy type.",
    "房间敌人池损坏。": "The room enemy pool is corrupted.",
    "敌人行动历史损坏。": "Enemy action history is corrupted.",
    "事件暂存装备记录损坏。": "Event equipment storage data is corrupted.",
    "本玩家回合结束后解除": "Removed at the end of this player turn",
    "%d件": "{p0} item(s)",
    "手部辅助": "Hand Assistance",
    "环境": "Environment",
    "狱警巡视": "Guard Patrol",
    "连接式固缚耐久不正确。": "Connected restraint Durability is invalid.",
    "手指": "Fingers",
    "汇流": "Confluence",
    "每佩戴{bound_worn_divisor}件拘束具，本回合获得1点力量，不足{bound_worn_divisor}件不计。{bound_worn_preview}": "For every {p0} restraints worn, gain 1 Strength this turn; fewer than {p1} grant nothing.{p2}",
    "每佩戴{free_worn_divisor}件拘束具，恢复1点魔力。{free_worn_preview}": "For every {p0} restraints worn, restore 1 Mana.{p1}",
    "按打出时的当前佩戴件数计算；复合拘束具整件计1件。力量可通过重复使用叠加，回合结束消失。": "Count restraints when this card is played; a composite restraint counts as one item. Strength gained from repeated uses stacks and expires at the end of the turn.",
    "\n当前：恢复%s魔力。": "\nCurrent: Restore {p0} Mana.",
    "\n当前：本回合力量＋%s。": "\nCurrent: Strength +{p0} this turn.",
    "拘束": "Bound",
    "转换": "Conversion",
    "再利用": "Reuse",
    "共鸣": "Resonance",
    "熟练而已": "Practiced",
    "汲取力量": "Siphon Strength",
    "命运同担": "Shared Fate",
    "借力打力": "Leverage",
    "运气": "Breath Control",
    "紧缚爱好": "Binding Enthusiast",
    "灌注": "Infusion",
    "专心致志": "Concentration",
    "魔力回路": "Mana Circuit",
    "蓄势待发": "Ready to Strike",
    "翘腿无视": "Crossed Legs",
    "魔路检索": "Mana Search",
    "强欲之壶": "Pot of Greed",
    "连续挣": "Repeated Strain",
    "余势复演": "Echo Cast",
    "余火": "Embers",
    "猛火下山": "Wildfire Descent",
    "猪神之皇焚": "Boar Emperor Blaze",
    "灵活变通": "Adaptability",
    "死灰复燃": "Rekindle",
    "火动力学": "Fire Dynamics",
    "炫火": "Flame Flourish",
    "控火": "Fire Control",
    "开信刀play": "Letter Opener Play",
    "欲能转换": "Arousal Conversion",
    "魔力转换": "Mana Conversion",
    "魔力涌流": "Mana Surge",
    "火焰精通": "Fire Mastery",
    "找准松处": "Find the Weak Spot",
    "扯开缺口": "Tear It Open",
    "接连挣动": "Chain Struggle",
    "逐层抽离": "Peel Away",
    "双重解锁": "Double Unlock",
    "慌乱": "Panic",
    "敏感": "Sensitive",
    "玩弄": "Tease",
    "玩弄+": "Tease+",
    "绷紧再挣": "Brace and Strain",
    "一点点抽出": "Inch Free",
    "魔力松缚": "Mana Slip",
    "将快感与魔力均设为两者总和的一半。": "Set both Arousal and Mana to half their combined total.",
    "{mana_cost}每使用火球术：抽牌1。": "{p0}Whenever you use Fireball: Draw 1 card.",
    "可叠加。失败火球也触发；群攻每层触发一次。": "Stackable. Failed Fireballs also trigger it; area attacks trigger once per stack.",
    "火球现在可以对拘束具使用,但是伤害减半": "Fireball can now target restraints, but deals half damage.",
    "每回合火球次数＋1。": "+1 Fireball use each turn.",
    "自由面次数可叠加，拘束面不叠加。敌人与拘束具共用次数。": "Extra uses from the Free face stack; the Bound face does not. Enemies and restraints share the same use limit.",
    "删牌服务 · %s魔力": "Card Removal · {p0} Mana",
    "火球无视身体限制；不获得手势加成。": "Fireball ignores body restrictions and gains no gesture bonus.",
    "火球伤害×2。": "Fireball Damage ×2.",
    "同面不叠加；费用与快感施法概率不变。": "The same face does not stack. Cost and Arousal-based cast chance remain unchanged.",
    '保留全部手牌': 'Retain all cards in hand',
    '全部保留不能同时指定选牌数量。': 'Retain all cannot also specify a selection count.',
    '本回合结束时，保留的手牌不会丢弃。': 'Retained cards are not discarded at the end of this turn.',
    '带着一个%s点生命的玩偶登场。': 'enters with a puppet with {p0} HP.',
    '生命：%s\n开场：自带10生命玩偶。首回合赋予玩偶嘲讽与受伤反击。\n行动：玩偶生命上限＋5并回满→准备中级2档复合拘束具→准备中级3档特殊装备，循环。两类装备各保留1件，同类新准备替换旧准备。\n牵线保护：玩偶生命最低为1，溢出伤害全额转给玩偶师。击败玩偶师，玩偶同时消失。': 'HP: {p0}\nStarts with a 10-HP puppet. Turn 1: Grant the puppet Taunt and a reaction that applies a restraint when damaged.\nThen repeat: Raise puppet max HP by 5 and fully heal it; prepare a medium tier-2 composite restraint; prepare medium tier-3 special equipment. Each equipment category holds one prepared item; a new preparation replaces the old one.\nThe puppet cannot fall below 1 HP and transfers excess damage to its puppeteer. Multi-hit attacks trigger the reaction per hit. Area attacks ignore Taunt. Defeating the puppeteer dismisses the puppet; rewards are granted once.',
    "预备咏唱": "Prepared Chant",
    "本回合施法成功率固定为100%。": "Cast success rate is fixed at 100% this turn.",
    "{mana_cost}本回合施法成功率固定为100%。": "{p0}Cast success rate is fixed at 100% this turn.",
    "：施法成功率固定为100%。": ": Cast success rate is fixed at 100%.",
    "问题与建议": "Issues and Suggestions",
    "每使用火球术：抽牌1。": "Whenever you use Fireball, draw 1 card.",
    "火球术施法成功率＋30%。": "Fireball cast success rate +30%.",
    "唯一": "Unique",
    "回廊": "Corridor", "开": "On", "关": "Off", "扶她出去": "Futa Off",
    "次": " time(s)", "层": " stack(s)", "已经降到最低": "Already at minimum",
    "用力": "Strain", "用力！": "Strain!", "顾涌": "Wriggle", "顾涌！": "Wriggle!", "术式解锁": "Spell Unlock",
    "蓄力": "Charge", "闪避": "Evasion", "力量": "Strength", "灵巧": "Dexterity",
    "快感": "Arousal", "魔力": "Mana", "能量": "Energy", "耐久": "Durability",
    "紧度": "Tightness", "挣扎": "Struggle", "滑脱": "Slip", "伤害": "Damage",
    "拘束具": "Restraint", "施法": "Cast", "卡组": "Deck", "手牌": "Hand", "卡牌": "Card",
    "普通": "Common", "罕见": "Uncommon", "稀有": "Rare", "成功": "Success", "失败": "Failure",
    "回合开始": "Start of Turn", "回合结束": "End of Turn",
    "魔力撑隙": "Mana Expansion", "汲取": "Siphon", "激发魔力": "Mana Surge",
    "拘束之拥": "Restraint's Embrace", "魔术手": "Mage Hand", "身轻如燕": "Featherlight",
    "需要双腿活动": "Requires free leg movement", "解除": "Remove",
    "打出时播放": "Play on use: ", "版雨爱": "Rain Love Remix", "品相完美": "Pristine",
    "般若汤": "Hannya Brew", "其二": "Part Two", "受": "Affected", "需要": "Requires",
    "扶她出去 · ": "Futa Off · ", "贞操锁池": "Chastity Lock Pool",
    "贞操锁池 · %s（%d%%）": "Chastity Lock Pool · {p0} ({p1}%)",
    "开启贞操锁池后可选": "Available after enabling the Chastity Lock Pool",
    "仅新局生效 · 勾选后不出现第4项开局选项": "New games only · Hides the fourth starting choice",
    "月灯杂货铺": "Moonlight General Store", "拘束具堆里的微光": "A Glimmer in the Restraint Pile",
    "全量蓄力": "Full Charge", "普通蓄力": "Normal Charge", "切换为全量蓄力": "Switch to Full Charge",
    "切换为普通蓄力": "Switch to Normal Charge", "敌人正在蓄力": "Enemy is charging",
    "敌人正在蓄力。": "The enemy is charging.", "本回合正在高潮": "Climaxing this turn",
    "获得%d层蓄力": "Gain {p0} Charge", "获得%d层蓄力。": "Gain {p0} Charge.",
    "火球术 · 自解": "Fireball · Self-Release", "贴身刺激与高潮练习": "Intimate Stimulation & Climax Practice",
    "每耗魔20：蓄力1。": "For every 20 Mana spent: Gain 1 Charge.",
    "继续 · 高潮后缓一缓": "Continue · Recover after climax",
    "高潮 · 先缓过这一回合": "Climax · Recover for this turn",
    "高潮练习": "Climax Practice", "下次火球术：复放1。": "Next Fireball: Replay once.",
    "下一次触发使用全部蓄力。": "The next trigger consumes all Charge.",
    "本回合火球术次数已用完。": "No Fireball uses remain this turn.",
    "高潮打断了剩余卡牌效果。": "Climax interrupted the remaining card effects.",
    "入口回廊": "Entrance Corridor", "中央回廊": "Central Corridor", "左侧回廊": "Left Corridor", "右侧回廊": "Right Corridor",
    "偏左回廊": "Left-Center Corridor", "偏右回廊": "Right-Center Corridor",
    "最左回廊": "Far-Left Corridor", "最右回廊": "Far-Right Corridor",
    "身体与拘束具": "Body & Restraints", "颈肩": "Neck & Shoulders", "大臂": "Upper Arms",
    "小臂": "Forearms", "双穴": "Vagina & Anus", "眼部": "Eyes", "口部": "Mouth",
    "乳头": "Nipples", "肉棒": "Penis", "大腿": "Thighs", "小腿": "Calves", "脚踝": "Ankles",
    "脚掌": "Feet", "施法：": "Casting: ", "无": "None", "技能": "Skill", "魔法": "Spell",
    "能力": "Power", "基础": "Basic", "保留": "Retain", "保留。": "Retain.", " · 保留": " · Retain",
    "第%d层": "Floor {p0}", "第0层": "Floor 0", "第%d回合": "Turn {p0}", "非战斗": "Out of Combat",
    "回合 —": "Turn —", "教程书": "Tutorial",
    "距墙%d格": "{p0} tiles from wall", "离墙%d格": "{p0} tiles from wall", "警戒度%d级": "Alert {p0}",
    "道具 %d / %d": "Items {p0}/{p1}", "能力区 · %d": "Powers · {p0}",
    "近身短打": "Close Strike", "近身短打 · 连击": "Close Strike · Combo", "肘击": "Elbow Strike",
    "强力肘击": "Heavy Elbow", "深呼吸": "Deep Breath", "并腿飞踢": "Flying Kick",
    "并拢飞踢": "Flying Kick", "坐姿踢击": "Seated Kick", "站着踢": "Standing Kick", "横扫": "Sweep",
    "当前快感已经降到最低": "Arousal is already at its minimum", "当前快感已经降到最低。": "Arousal is already at its minimum.",
    "魔力药剂": "Mana Potion", "活力药剂": "Energy Potion", "蓄势药剂": "Charge Potion",
    "应变卷轴": "Tactical Scroll", "节魔卷轴": "Mana-Saving Scroll", "定咒卷轴": "Surecast Scroll",
    "便携开锁针": "Lockpick Set", "润滑油": "Lubricant", "冰心诀": "Heart of Ice",
    "断缚护腕": "Sunder Bracers", "小刻印": "Minor Sigil", "拘束解除": "Remove Restraints",
    "删牌服务 · 本店一次": "Card Removal · Once per Visit",
    "删牌服务 · 已使用": "Card Removal · Used", "整理道具": "Manage Items", "继续旅程 →": "Continue Journey →",
    "自身魔力 ": "Personal Mana ", "魔瓶魔力 ": "Flask Mana ",
    "漂浮绳索": "Floating Rope", "漂浮胶带": "Floating Tape", "漂浮皮带": "Floating Belt",
    "漂浮皮带群": "Floating Belt Cluster", "【迎战】打散皮带群": "[Fight] Break Up the Belt Cluster",
    "【硬闯】把挡路的皮带打散": "[Fight] Break Through the Belt Cluster",
    "与3只初级漂浮皮带战斗；胜利后获得稀有遗物「软化扣环」。": "Fight three lesser Floating Belts; victory grants the rare relic “Softened Buckle.”",
    "【接受灌注】走进皮带群中": "[Accept Infusion] Enter the Belt Cluster",
    "恢复25魔力；获得诅咒「淫纹」。": "Restore 25 Mana; gain the curse “Lewd Mark.”",
    "走廊前方传来一阵密集的金属轻响。\n\n十几条漂浮皮带挤在一起，宽大的带身盘成一圈圈，几乎封死了整条路。皮带扣不断开合，像是在等什么东西主动靠近。\n\n其中几条皮带内侧浮动着粉色的魔力，甜腻的气息隔着一段距离都能感觉到。": "A rapid metallic clatter echoes from the corridor ahead.\n\nMore than a dozen floating belts crowd together, their broad straps coiling into rings that nearly block the passage. Their buckles snap open and shut as if waiting for something to come closer.\n\nPink mana shimmers along the inner faces of several belts, carrying a cloyingly sweet scent even at a distance.",
    "可以迎战三只初级漂浮皮带并取得稀有遗物「软化扣环」，或接受魔力灌注，恢复25魔力并获得诅咒「淫纹」。": "Fight three lesser Floating Belts to claim the rare relic “Softened Buckle,” or accept a mana infusion to restore 25 Mana and gain the curse “Lewd Mark.”",
    "“欢迎光临呀，zako♡”\n\n“本店不收金币，只收含着魔力的精液。实在不想当场射，用魔瓶里的存货也行。”\n\n“喜欢什么就自己挑吧，付不起可别盯着看太久哦♡”": "“Welcome, zako♡”\n\n“We don't take coins here—only semen infused with mana. If you really don't want to cum on the spot, you can use what's stored in your flask.”\n\n“Pick anything you like. Just don't stare too long if you can't afford it♡”",
    "“用魔瓶付？真没劲。”\n\n“人家还以为能看看你当场射出来的样子呢。”\n\n“商品拿去啦。下次记得用肉棒亲自结账♡”": "“Paying with the flask? Boring.”\n\n“I thought I'd get to watch you cum right here.”\n\n“Fine, take it. Next time, remember to pay with your cock in person♡”",
    "henshin（品相完美!）": "Henshin (Pristine!)", "般若汤-其一": "Hannya Brew · Part One",
    "般若汤-其二": "Hannya Brew · Part Two", "般若汤-其三": "Hannya Brew · Part Three",
    "般若汤-其四": "Hannya Brew · Part Four", "好汤喝够饮饮饮饮": "Drink Your Fill",
}


def protect(text, argument_start=0):
    matches = []
    spans = []
    for regex, kind in ((FORMAT, "argument"), (NAMED, "argument"), (TAG, "literal")):
        for hit in regex.finditer(text):
            if not any(hit.start() < end and hit.end() > start for start, end, *_ in spans):
                spans.append((hit.start(), hit.end(), kind, hit.group()))
    spans.sort()
    if len(spans) > len(WORDS):
        raise ValueError(f"too many protected segments: {text[:80]}")
    output = []
    position = 0
    argument = argument_start
    for index, (start, end, kind, raw) in enumerate(spans):
        output.append(text[position:start])
        token = WORDS[index]
        output.append(token)
        replacement = "{p%d}" % argument if kind == "argument" else raw
        if kind == "argument":
            argument += 1
        matches.append((token, replacement))
        position = end
    output.append(text[position:])
    return "".join(output), matches


def apply_glossary(text, protected):
    for chinese, english in sorted(GLOSSARY.items(), key=lambda pair: len(pair[0]), reverse=True):
        while chinese in text:
            if len(protected) >= len(WORDS):
                raise ValueError(f"too many protected terms: {text[:80]}")
            token = WORDS[len(protected)]
            text = text.replace(chinese, " " + token + " ", 1)
            protected.append((token, " " + english + " "))
    return text, protected


def clean(text, protected):
    text = text.replace("▁", " ").strip()
    for token, value in sorted(protected, key=lambda pair: len(pair[0]), reverse=True):
        pattern = re.compile(re.escape(token), re.I)
        text, count = pattern.subn(lambda _: value, text)
        if count != 1:
            # The small model occasionally inserts a space inside a marker.
            suffix = token.removeprefix("Placeholder")
            fuzzy = re.compile(r"Place\s*hold(?:er)?\s*" + re.escape(suffix), re.I)
            text, count = fuzzy.subn(lambda _: value, text)
        if count != 1:
            raise ValueError(f"lost protected token {token}: {text}")
    punctuation = {"，": ", ", "。": ".", "；": "; ", "：": ": ", "、": ", ",
                   "（": "(", "）": ")", "“": '“', "”": '”', "「": '“', "」": '”',
                   "／": "/", "～": "–"}
    for source, target in punctuation.items():
        text = text.replace(source, target)
    text = re.sub(r"[ \t]+", " ", text)
    text = re.sub(r" +([,.;:!?%)])", r"\1", text)
    text = re.sub(r"([“(]) +", r"\1", text)
    text = re.sub(r"(\{p\d+\}|\d+) stack Charge", r"\1 Charge", text)
    text = re.sub(r"\bThis Turn\b", "this turn", text)
    text = re.sub(r"\brounds\b", "turns", text, flags=re.I)
    text = re.sub(r"\bround\b", "turn", text, flags=re.I)
    text = re.sub(r"\bmagic powers?\b", "Mana", text, flags=re.I)
    text = re.sub(r"\bpleasure\b", "Arousal", text, flags=re.I)
    text = re.sub(r"\bsmart\b", "Dexterity", text, flags=re.I)
    return text.strip()


def translate_fragments(text, protected, processor, translator):
    """Rare safety path when the model drops a format marker."""
    tokens = [token for token, _ in protected]
    pieces = re.split("(" + "|".join(map(re.escape, tokens)) + ")", text)
    translatable = [piece for piece in pieces if piece and piece not in tokens]
    encoded = [processor.encode(piece, out_type=str) for piece in translatable]
    results = translator.translate_batch(encoded, beam_size=4, max_decoding_length=512) if encoded else []
    translated = iter(processor.decode(result.hypotheses[0]) for result in results)
    return "".join(piece if piece in tokens else (next(translated) if piece else "") for piece in pieces)


def translate_segments(text, processor, translator):
    pieces = [piece for piece in re.split(r"(?<=[。！？；\n])", text) if piece]
    split = []
    for piece in pieces:
        split.extend(part for part in re.split(r"(?<=，)", piece) if part)
    encoded = [processor.encode(piece, out_type=str) for piece in split]
    results = translator.translate_batch(encoded, beam_size=4, max_decoding_length=512)
    return "".join(processor.decode(result.hypotheses[0]) for result in results)


def translate_original_segments(original, processor, translator):
    parts = [part for part in re.split(r"(?<=[。！？；\n])", original) if part]
    prepared = []
    metadata = []
    argument = 0
    for part in parts:
        marked, protected = protect(part, argument)
        argument += sum(1 for _, value in protected if value.startswith("{p"))
        marked, protected = apply_glossary(marked, protected)
        prepared.append(marked)
        metadata.append(protected)
    encoded = [processor.encode(text, out_type=str) for text in prepared]
    results = translator.translate_batch(encoded, beam_size=4, max_decoding_length=512)
    output = []
    for marked, protected, result in zip(prepared, metadata, results):
        translated = processor.decode(result.hypotheses[0])
        try:
            output.append(clean(translated, protected))
        except ValueError:
            output.append(clean(translate_fragments(marked, protected, processor, translator), protected))
    return " ".join(output)


def main():
    inventory = json.loads((BUILD / "localization/inventory.json").read_text(encoding="utf-8"))
    sources = sorted({entry["text"] for entry in inventory["entries"]} | set(MANUAL), key=lambda text: (len(text), text))
    cache = json.loads(CACHE.read_text(encoding="utf-8")) if CACHE.exists() else {}
    pending = [text for text in sources if text not in cache and text not in MANUAL]
    processor = None
    translator = None
    if pending:
        if ctranslate2 is None or spm is None:
            raise SystemExit(
                "Missing offline translation dependencies in build/translation-lite; "
                f"{len(pending)} uncached source string(s) still require translation"
            )
        processor = spm.SentencePieceProcessor(model_file=str(MODEL / "sentencepiece.model"))
        translator = ctranslate2.Translator(str(MODEL / "model"), device="cpu")
    batch_size = 48
    for offset in range(0, len(pending), batch_size):
        originals = pending[offset:offset + batch_size]
        prepared = []
        metadata = []
        for original in originals:
            marked, protected = protect(original)
            marked, protected = apply_glossary(marked, protected)
            prepared.append(marked)
            metadata.append(protected)
        encoded = [processor.encode(text, out_type=str) for text in prepared]
        results = translator.translate_batch(encoded, beam_size=4, max_decoding_length=512)
        for original, prepared_text, protected, result in zip(originals, prepared, metadata, results):
            translated = processor.decode(result.hypotheses[0])
            try:
                cache[original] = clean(translated, protected)
            except ValueError:
                translated = translate_segments(prepared_text, processor, translator)
                try:
                    cache[original] = clean(translated, protected)
                except ValueError:
                    cache[original] = translate_original_segments(original, processor, translator)
            if CJK.search(cache[original]):
                raise ValueError(f"untranslated Chinese remains: {original} -> {cache[original]}")
        CACHE.write_text(json.dumps(cache, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        print(f"translated {min(offset + batch_size, len(pending))}/{len(pending)}", flush=True)
    messages = []
    for source in sources:
        digest = sha256(source.encode("utf-8")).hexdigest()[:24]
        text = MANUAL[source] if source in MANUAL else cache[source]
        messages.append({"id": "legacy.h" + digest, "source": source, "text": text})
    document = {"schema_version": 1, "locale": "en_US", "messages": messages}
    OUTPUT.write_text(json.dumps(document, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"output": str(OUTPUT), "messages": len(messages)}, ensure_ascii=False))


if __name__ == "__main__":
    main()
