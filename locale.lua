local locale = {
  ["enUS"] = {
    BRAINWASHER_NPC = "Goblin Brainwashing Device",

    SHOW_ORIGINAL_STR = "Show original brainwasher dialogue.",
    RESET_TALENTS_STR_SHORT = "Reset Talents",
    RESET_TALENTS_STR = "Reset your current talent points?\n\nThis costs gold and causes a 10 minute brainwasher use debuff.",
    CURRENT_TALENTS_STR = "Current talents: ",
    ACTIVE_STR = "|cff00ff00ACTIVE|r",
    ENABLE_TALENT_LAYOUT_STR = "Do you want to enable these talents?",
    ENABLE_TALENT_LAYOUT_FMT = "|cffff5500LOAD|r TALENTS\n\nSpec Slot %d:\nSpec name: %s\nSpec talents: %s\n\nCurrent talents: %s\nActivate spec talents? (causes brainwasher debuff)",
    ENABLE_TALENT_LAYOUT_TS_FMT = "|cffff5500LOAD|r TALENTS (Talentsaver)\n\nSpec Slot %d:\nSpec name: %s\nSpec talents: %s\n\nCurrent talents: %s\n\n|cffff0000TalentSaver uses Reset Talents and COSTS GOLD.|r",

    EDIT_TALENT_SLOT_STR = "Change talent spec icon:\n\nEnter an icon path or spell or talent name.",

    SAVE_TALENT_LAYOUT_STR = "Do you want to save these talents?",
    SAVE_TALENT_LAYOUT_FMT = "|cff00ff55SAVE|r TALENTS\n\nSpec Slot %d:\nSpec name: %s\nSpec talents: %s\n\nCurrent talents: %s\nReplace spec talents with current talents?",

    ACTIVATE_STR = "Activate",

    BUY_TALENT_SLOT_STR = "Buy Slot",
    SPEC_STR = "Spec",

    NOT_AVAIALBLE_STR = "\n\n\n\nBrainwasher not available on this character.",
    
    DEBUFF_FND = "^Scrambled brain detected",
    DEBUFF_FMT = "Brainwasher Debuff: %dm %ds",
    BUY_TALENT_SLOT_FMT = "Do you want to buy a talent slot for %d gold?",
    
    SAVE_TALENTS_FND = "Save (%d+)(..) Specialization",
    ACTIVATE_TALENTS_FND = "Activate (%d+)(..) Specialization",
    BUY_TALENT_SLOT_FND = "Buy (%d+)(..) Specialization tab for (%d+) gold",
    RESET_TALENTS_FND = "Reset my talents",

    TALENTSAVER_TOGGLE_STR = "Talentsaver",
    TALENTSAVER_TOOLTIP_STR = "Reset + Talentsaver is used instead of the NPC activate.\nThis will cost Talent Reset gold!",
    TALENTSAVER_TOOLTIP_DISABLED_STR = "Requires nampower v2.35.0+.",
    TALENTSAVER_BUSY_STR = "Talentsaver is still loading a spec.",
  },

  ["zhCN"] = {
    BRAINWASHER_NPC = "地精洗脑装置",

    SHOW_ORIGINAL_STR = "显示原始洗脑装置对话框。",
    RESET_TALENTS_STR_SHORT = "重置天赋",
    RESET_TALENTS_STR = "是否重置当前的天赋点数？\n\n这将消耗金币,并产生一个10分钟的洗脑装置负面状态。",
    CURRENT_TALENTS_STR = "当前天赋: ",
    ACTIVE_STR = "|cff00ff00已激活|r",
    ENABLE_TALENT_LAYOUT_STR = "你想启用这些天赋吗?",
    ENABLE_TALENT_LAYOUT_FMT = "|cffff5500读取|r天赋\n\n天赋槽位 %d:\n预设名称: %s\n预设天赋: %s\n\n当前天赋: %s\n是否激活该预设天赋? (将产生洗脑装置负面状态)",
    ENABLE_TALENT_LAYOUT_TS_FMT = "|cffff5500读取|r天赋 (天赋保存)\n\n天赋槽位 %d:\n预设名称: %s\n预设天赋: %s\n\n当前天赋: %s\n\n|cffff0000这将重置你的天赋并花费金币。|r",

    EDIT_TALENT_SLOT_STR = "更改天赋预设图标：\n\n请输入图标路径、技能名称或天赋名称。",

    SAVE_TALENT_LAYOUT_STR = "你想保存这些天赋吗?",
    SAVE_TALENT_LAYOUT_FMT = "|cff00ff55保存|r天赋\n\n天赋槽位 %d:\n预设名称: %s\n预设天赋: %s\n\n当前天赋: %s\n是否用当前天赋替换预设天赋?",

    ACTIVATE_STR = "激活",

    BUY_TALENT_SLOT_STR = "购买一个槽位",
    SPEC_STR = "预设",

    NOT_AVAIALBLE_STR = "\n\n\n\n该角色无法使用洗脑装置。",
    
    DEBUFF_FND = "检测到大脑混乱！在你胡思乱想的时候,不允许改变天赋。",
    DEBUFF_FMT = "洗脑装置负面状态: %dm %ds",
    BUY_TALENT_SLOT_FMT = "你想花%d金币购买一个天赋槽位吗?",
    
    ACTIVATE_TALENTS_FND = "启用第(%d+)(.)",
    SAVE_TALENTS_FND = "保存第(%d+)(.)",
    BUY_TALENT_SLOT_FND = "用(%d+)金币购买第(%d+)个天赋标签。",
    RESET_TALENTS_FND = "重置我的天赋。",

    TALENTSAVER_TOGGLE_STR = "天赋保存",
    TALENTSAVER_TOOLTIP_STR = "使用重置+天赋保存代替NPC激活。\n这将花费重置金币。",
    TALENTSAVER_TOOLTIP_DISABLED_STR = "需要nampower v2.35.0+。",
    TALENTSAVER_BUSY_STR = "天赋保存仍在加载天赋中。",
  },
}

BrainSaver = BrainSaver or {}
BrainSaver.L = locale[GetLocale()] or locale["enUS"]