local _G = _G or getfenv(0)

local addon_name = "BrainSaver"
local dialog_alpha = 0.35
local talentButtons = {}

if not BrainSaverDB then
    BrainSaverDB = {}
end
if not BrainSaverDB.spec then
    BrainSaverDB.spec = {}
end

--------------------------------------------------
-- Main Frame Setup
--------------------------------------------------
local mainFrame = CreateFrame("Frame", addon_name.."Frame", UIParent)
mainFrame:SetWidth(350)
mainFrame:SetHeight(350)
mainFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
mainFrame:EnableMouse(true)
mainFrame:SetMovable(true)
mainFrame:RegisterForDrag("LeftButton")
mainFrame:SetScript("OnDragStart", function () mainFrame:StartMoving() end)
mainFrame:SetScript("OnDragStop", function () mainFrame:StopMovingOrSizing() end )
mainFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 }
})
-- mainFrame:SetBackdropColor(0, 0, 0, 1)
-- For testing you can call mainFrame:Show() manually,
-- but now event handling will control its visibility.
mainFrame:Hide()

mainFrame.iconCheckTexture = mainFrame:CreateTexture()

-- Allow the frame to be closed with Escape.
tinsert(UISpecialFrames, addon_name.."Frame")

mainFrame.gossip_slots = {}
mainFrame.gossip_slots.save = {}
mainFrame.gossip_slots.load = {}
mainFrame.gossip_slots.buy = {}
mainFrame.gossip_slots.reset = nil
mainFrame.currentButton = 1


--------------------------------------------------
-- Title and Talent Summary
--------------------------------------------------
mainFrame.titleText = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
mainFrame.titleText:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 15, -15)
mainFrame.titleText:SetText(GetAddOnMetadata(addon_name, "title") .. " " .. GetAddOnMetadata(addon_name, "version"))

mainFrame.talentSummaryText = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
mainFrame.talentSummaryText:SetPoint("TOP", mainFrame, "TOP", 0, -50)
mainFrame.talentSummaryText:SetText("12/31/9")  -- Update this with real talent info as needed

-- Standard close button.
mainFrame.closeButton = CreateFrame("Button", nil, mainFrame, "UIPanelCloseButton")
mainFrame.closeButton:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -5, -5)
mainFrame.closeButton:SetScript("OnClick", function()
  HideUIPanel(GossipFrame) -- use the specific closing function
end)

local function ColorSpecSummary(t1,t2,t3)
  local largest  = math.max(t1, t2, t3)
  local smallest = math.min(t1, t2, t3)

  -- Function to return the color code based on ranking
  local function getColor(value)
      if value == largest then
          return "|cff00ff00"  -- Green
      elseif value == smallest then
          return "|cff0077ff"  -- Blue
      else
          return "|cffffff00"  -- Yellow
      end
  end

  -- Build the output string with each number colored according to its ranking.
  return string.format("%s%d|r | %s%d|r | %s%d|r",
      getColor(t1), t1,
      getColor(t2), t2,
      getColor(t3), t3)
end

local function TalentCounts()
  local _,_,t1 = GetTalentTabInfo(1)
  local _,_,t2 = GetTalentTabInfo(2)
  local _,_,t3 = GetTalentTabInfo(3)
  return t1,t2,t3
end

function FetchTalents()
  local talents = {}
  for tab=1,3 do
    local _,_,tcount = GetTalentTabInfo(tab)
    for talent=1,100 do
      local name,icon,row,col,count,max = GetTalentInfo(tab,talent)
      if not name then break end
      talents[tab] = talents[tab] or {}
      talents[tab][talent] = {
        name = name,
        icon = icon,
        row = row,
        col = col,
        count = count,
        max = max,
      }
    end
  end
  return talents
end

function IsSameSpec(t1, t2)
  for i, tab in ipairs(t1) do
    for j, talent in ipairs(tab) do
      if not (t2[i] and t2[i][j] and talent.count == t2[i][j].count) then
        return false
      end
    end
  end
  return true
end

----------------------------------------------------------------
-- Searches the spellbook for a spell matching the given name.
-- Returns the texture path if found, or nil otherwise.
----------------------------------------------------------------
local function SearchSpellbookForIcon(spellName)
  if type(spellName) ~= "string" then
    print("Erreur: 'spellName' est nil ou invalide dans SearchSpellbookForIcon")
    return nil
  end

  local lowerSpellName = string.lower(spellName)
  local index = 1
  local foundTexture = nil

  while true do
    local name, rank = GetSpellName(index, BOOKTYPE_SPELL)
    if not name then break end

    if string.lower(name) == lowerSpellName then
      foundTexture = GetSpellTexture(index, BOOKTYPE_SPELL)
      break
    end

    index = index + 1
  end

  return foundTexture
end


----------------------------------------------------------------
-- Searches the talent list for a talent matching the given name.
-- Returns the talent’s texture if found, or nil otherwise.
----------------------------------------------------------------
local function SearchTalentsForIcon(talentName)
  if type(talentName) ~= "string" then
    print("Erreur: 'talentName' est nil ou invalide dans SearchTalentsForIcon")
    return nil
  end

  local lowerTalentName = string.lower(talentName)

  for tab = 1, 3 do
    for talent = 1, 100 do
      local name, texture = GetTalentInfo(tab, talent)
      if not name then break end

      if string.lower(name) == lowerTalentName then
        return texture
      end
    end
  end

  return nil
end


function FindTexture(source)
  local icon = "Interface\\Icons\\INV_Misc_QuestionMark"

  if type(source) ~= "string" or source == "" then
    print("FindTexture: 'source' invalide ou nil:", source)
    return icon
  end

  local spell_icon = SearchSpellbookForIcon(source)
  local talent_icon = SearchTalentsForIcon(source)

  if spell_icon then
    icon = spell_icon
  elseif talent_icon then
    icon = talent_icon
  else
    -- Vérifie si source est une texture valide
    mainFrame.iconCheckTexture:SetTexture(source)
    if mainFrame.iconCheckTexture:GetTexture() then
      icon = source
    end
    mainFrame.iconCheckTexture:SetTexture(nil)
  end

  return icon
end




--------------------------------------------------
-- Reset Talents Button (Anchored below the grid)
--------------------------------------------------
mainFrame.resetButton = CreateFrame("Button", "ResetTalentButton", mainFrame, "UIPanelButtonTemplate")
mainFrame.resetButton:SetWidth(120)
mainFrame.resetButton:SetHeight(30)
-- Anchor the reset button below the grid.
mainFrame.resetButton:SetPoint("BOTTOM", mainFrame, "BOTTOM", 0, 20)
mainFrame.resetButton:SetText("Reset Talents")
mainFrame.resetButton:SetScript("OnClick", function()
    StaticPopup_Show("RESET_TALENTS")
end)

--------------------------------------------------
-- Show Brainwasher Dialogue button
--------------------------------------------------
mainFrame.washerButton = CreateFrame("Button", "WasherDialogueButton", mainFrame, "UIPanelButtonTemplate")
mainFrame.washerButton:SetWidth(60)
mainFrame.washerButton:SetHeight(20)
-- Anchor the reset button below the grid.
mainFrame.washerButton:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -15, 15)
mainFrame.washerButton:SetText("Washer")
mainFrame.washerButton:SetScript("OnClick", function()
  GossipFrame:SetAlpha(1)
end)
mainFrame.washerButton:SetScript("OnEnter", function()
  GameTooltip:SetOwner(this, "ANCHOR_LEFT")
  GameTooltip:SetText("Show original brainwasher dialogue.", 1, 1, 0)  -- Tooltip title
  GameTooltip:Show()
end)
mainFrame.washerButton:SetScript("OnLeave", function()
  GameTooltip:Hide()
end)

local function CreateLegacyIconSelector()
    local f = CreateFrame("Frame", "BrainSaverIconSelector", UIParent)
    f:SetWidth(340)
    f:SetHeight(320)
    f:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    f:SetPoint("CENTER", UIParent, "CENTER")
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function() f:StartMoving() end)
    f:SetScript("OnDragStop", function() f:StopMovingOrSizing() end)
    f:Hide()

    local title = f:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    title:SetText("Choose an Icon")
    title:SetPoint("TOP", 0, -16)

    -- ScrollFrame
    local scrollFrame = CreateFrame("ScrollFrame", "BrainSaverIconSelectorScrollFrame", f, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -40)
    scrollFrame:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -30, 10)

    -- Content frame where icons will be placed
    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetWidth(300)
    -- Hauteur totale calculée après création des boutons, on met large pour le scroll horizontal désactivé
    scrollFrame:SetScrollChild(content)

    local ICON_LIST = {
    -- Général / Capacités diverses
    "INV_Misc_QuestionMark",
    "Ability_Ambush",
    "Ability_BackStab",
    "Ability_CheapShot",
    "Ability_CriticalStrike",
    "Ability_Defend",
    "Ability_DualWield",
    "Ability_EyeOfTheOwl",
    --"Ability_FeignDeath",
    "Ability_GhoulFrenzy",
    "Ability_Gouge",
    "Ability_Hibernation",
    "Ability_Hunter_RunningShot",
    "Ability_Kick",
    "Ability_Marksmanship",
    "Ability_MeleeDamage",
    "Ability_Racial_BloodRage",
    "Ability_Throw",
    "Ability_ThunderBolt",
    "Ability_Tracking",
    "Ability_Whirlwind",

    -- Guerrier
    "Ability_Warrior_Charge",
    "Ability_Warrior_Cleave",
    "Ability_Warrior_DefensiveStance",
    "Ability_Warrior_Disarm",
    "Ability_Warrior_InnerRage",
    "Ability_Warrior_PunishingBlow",
    "Ability_Warrior_Revenge",
    "Ability_Warrior_Riposte",
    "Ability_Warrior_SavageBlow",
    "Ability_Warrior_ShieldBash",
    "Ability_Warrior_ShieldWall",
    "Ability_Warrior_Sunder",
    --"Ability_Warrior_Taunt",
    "Ability_Warrior_RallyingCry",
    "Ability_Warrior_WarCry",

    -- Paladin
    "Spell_Holy_HolyBolt",
    "Spell_Holy_SealOfMight",
    "Spell_Holy_SealOfRighteousness",
    "Spell_Holy_SealOfSalvation",
    --"Spell_Holy_SealOfLight",
    "Spell_Holy_SealOfWisdom",
    "Spell_Holy_AuraOfLight",
    "Spell_Holy_BlessingOfProtection",
    --"Spell_Holy_BlessingOfSacrifice",
    --"Spell_Holy_BlessingOfMight",
    --"Spell_Holy_BlessingOfKings",
    "Spell_Holy_Excorcism_02",
    --"Ability_Paladin_HolyAvenger",

    -- Chasseur
    "Ability_Hunter_AspectOfTheMonkey",
    --"Ability_Hunter_AspectOfTheHawk",
    --"Ability_Hunter_AspectOfTheCheetah",
    --"Ability_Hunter_AspectOfThePack",
    --"Ability_Hunter_ExplosiveTrap",
    --"Ability_Hunter_FrostTrap",
    "Ability_Hunter_Pet_Bear",
    "Ability_Hunter_Pet_Cat",
    "Ability_Hunter_Pet_Crab",
    "Ability_Hunter_Pet_Crocolisk",
    "Ability_Hunter_Pet_Gorilla",
    "Ability_Hunter_Pet_Hyena",
    "Ability_Hunter_Pet_Owl",
    "Ability_Hunter_Pet_Raptor",
    "Ability_Hunter_Pet_Scorpid",
    "Ability_Hunter_Pet_Spider",
    "Ability_Hunter_Pet_TallStrider",
    "Ability_Hunter_Pet_Turtle",
    "Ability_Hunter_Pet_WindSerpent",
    "Ability_Hunter_Pet_Wolf",
    "Ability_Hunter_SniperShot",
    "Ability_Hunter_SteadyShot",

    -- Voleur
    "Ability_Rogue_Eviscerate",
    "Ability_Rogue_KidneyShot",
    "Ability_Rogue_SliceDice",
    --"Ability_Rogue_SinisterStrike",
    "Ability_Rogue_FeignDeath",
    "Ability_Rogue_Garrote",
    "Ability_Rogue_Rupture",
    --"Ability_Rogue_DualWield",
    "Ability_Rogue_Disguise",
    "Ability_Rogue_Trip",

    -- Prêtre
    "Spell_Holy_FlashHeal",
    "Spell_Holy_GreaterHeal",
    "Spell_Holy_Heal",
    "Spell_Holy_HolyBolt",
    "Spell_Holy_PowerWordShield",
    "Spell_Holy_Renew",
    --"Spell_Holy_Serendipity",
    --"Spell_Holy_Shield",
    "Spell_Holy_PrayerOfHealing",
    --"Spell_Holy_Penance",
    "Spell_Holy_MindSooth",
    "Spell_Holy_MindVision",
    "Spell_Holy_DispelMagic",

    -- Chaman
    "Spell_Nature_HealingWaveLesser",
    --"Spell_Nature_HealingWave",
    "Spell_Nature_Lightning",
    "Spell_Nature_LightningBolt",
    "Spell_Nature_LightningShield",
    "Spell_Nature_MagicImmunity",
    "Spell_Nature_StoneClawTotem",
    "Spell_Nature_StoneSkinTotem",
    "Spell_Nature_Strength",
    "Spell_Nature_ThunderClap",
    "Spell_Nature_Windfury",
    "Spell_Nature_WispHeal",
    "Spell_Nature_EarthBind",
    "Spell_Nature_Earthquake",

    -- Mage
    "Spell_Frost_FrostBolt02",
    "Spell_Frost_FrostBolt",
    "Spell_Frost_IceStorm",
    "Spell_Frost_FrostNova",
    "Spell_Frost_FrostArmor",
    "Spell_Frost_ChainsOfIce",
    --"Spell_Frost_Blizzard",
    --"Spell_Frost_ColdSnap",
    "Spell_Frost_FrostWard",
    --"Spell_Frost_ManaShield",
    --"Spell_Frost_Polymorph",
    --"Spell_Frost_Frostfire",

    -- Démoniste
    "Spell_Shadow_Curse",
    --"Spell_Shadow_Corruption",
    "Spell_Shadow_DeathCoil",
    "Spell_Shadow_EnslaveDemon",
    --"Spell_Shadow_Fear",
    "Spell_Shadow_ImpPhaseShift",
    "Spell_Shadow_LifeDrain",
    "Spell_Shadow_Metamorphosis",
    "Spell_Shadow_RainOfFire",
    "Spell_Shadow_SiphonMana",
    "Spell_Shadow_SummonFelHunter",
    "Spell_Shadow_SummonSuccubus",
    "Spell_Shadow_SummonVoidWalker",
    "Spell_Shadow_SummonInfernal",

    -- Druide
    "Ability_Druid_AquaticForm",
    "Ability_Druid_Bash",
    --"Ability_Druid_BearForm",
    "Ability_Druid_CatForm",
    --"Ability_Druid_HealingTouch",
    "Ability_Druid_Maul",
    --"Ability_Druid_Rejuvenation",
    --"Ability_Druid_Regrowth",
    "Ability_Druid_Swipe",
    --"Ability_Druid_Thorns",
    "Ability_Druid_TravelForm",
    "Ability_Mount_WhiteTiger",
    "Ability_Mount_JungleTiger",

    -- Armes
    "INV_Weapon_ShortBlade_01",
    "INV_Weapon_ShortBlade_02",
    "INV_Weapon_ShortBlade_03",
    "INV_Weapon_ShortBlade_04",
    "INV_Weapon_ShortBlade_05",
    "INV_Weapon_Rifle_01",
    "INV_Weapon_Rifle_02",
    "INV_Weapon_Rifle_03",
    "INV_Weapon_Bow_01",
    "INV_Weapon_Bow_02",
    "INV_Weapon_Bow_03",
    "INV_Weapon_Bow_04",
    "INV_Weapon_Bow_05",
    "INV_Weapon_Crossbow_01",
    "INV_Weapon_Crossbow_02",
    "INV_Weapon_Crossbow_03",
    "INV_Weapon_Crossbow_04",
    "INV_Weapon_Crossbow_05",
    "INV_Weapon_Halberd_02",
    "INV_Weapon_Halberd_03",
    "INV_Weapon_Halberd_04",
    "INV_Weapon_Halberd_05",

    -- Armures
    "INV_Chest_Chain_05",
    "INV_Chest_Chain_06",
    "INV_Chest_Leather_07",
    "INV_Chest_Leather_08",
    "INV_Chest_Cloth_01",
    "INV_Chest_Cloth_02",
    "INV_Chest_Cloth_03",
    "INV_Chest_Plate03",
    "INV_Chest_Plate04",
    "INV_Chest_Plate05",
    "INV_Chest_Plate06",
    "INV_Boots_01",
    "INV_Boots_02",
    "INV_Boots_03",
    "INV_Boots_04",
    "INV_Boots_05",
    "INV_Belt_01",
    "INV_Belt_02",
    "INV_Belt_03",
    "INV_Belt_04",
    "INV_Belt_05",

    -- Casques
    "INV_Helmet_01",
    "INV_Helmet_02",
    "INV_Helmet_03",
    "INV_Helmet_04",
    "INV_Helmet_05",
    "INV_Helmet_06",
    "INV_Helmet_07",
    "INV_Helmet_08",
    "INV_Helmet_09",
    "INV_Helmet_10",

    -- Divers / Consommables / Montures / Têtes de monstres
    "INV_Misc_Book_01",
    "INV_Misc_Book_02",
    "INV_Misc_Book_03",
    "INV_Misc_Book_04",
    "INV_Misc_Book_05",
    "INV_Misc_Book_06",
    "INV_Misc_Book_07",
    "INV_Misc_Book_08",
    "INV_Misc_Book_09",
    "INV_Misc_EngGizmos_01",
    "INV_Misc_EngGizmos_02",
    "INV_Misc_EngGizmos_03",
    "INV_Misc_EngGizmos_04",
    "INV_Misc_Food_01",
    "INV_Misc_Food_02",
    "INV_Misc_Food_03",
    "INV_Misc_Food_04",
    "INV_Misc_Food_05",
    "INV_Misc_Gem_Emerald_01",
    "INV_Misc_Gem_Ruby_01",
    "INV_Misc_Gem_Sapphire_01",
    "INV_Misc_Herb_01",
    "INV_Misc_Herb_02",
    "INV_Misc_Herb_03",
    "INV_Misc_Orb_01",
    "INV_Misc_Orb_02",
    "INV_Misc_Pelt_Bear_01",
    "INV_Misc_Pelt_Wolf_01",
    "INV_Misc_Rune_01",
    "INV_Misc_Rune_02",
    "INV_Misc_StoneTablet_01",
    "INV_Misc_StoneTablet_02",
    "INV_Misc_StoneTablet_03",
    "INV_Misc_StoneTablet_04",
    "INV_Misc_StoneTablet_05",
    "INV_Misc_Head_Orc_01",
    "INV_Misc_Head_Orc_02",
    "INV_Misc_Head_Tauren_01",
    "INV_Misc_Head_Tauren_02",
    "INV_Misc_Head_Troll_01",
    "INV_Misc_Head_Troll_02",
    "INV_Misc_Head_Human_01",
    "INV_Misc_Head_Human_02",
    "INV_Misc_Head_Dwarf_01",
    "INV_Misc_Head_Dwarf_02",

    -- Potions & Consommables
    "INV_Potion_01",
    "INV_Potion_02",
    "INV_Potion_03",
    "INV_Potion_04",
    "INV_Potion_05",
    "INV_Potion_06",
    "INV_Potion_07",
    "INV_Potion_08",
    "INV_Potion_09",
    "INV_Potion_10",
    "INV_Potion_11",
    "INV_Potion_12",

    -- Montures
    "Ability_Mount_RidingHorse",
    "Ability_Mount_Dreadsteed",
    "Ability_Mount_BlackDireWolf",
    "Ability_Mount_WhiteTiger",
    "Ability_Mount_JungleTiger",
    "Ability_Mount_MountainRam",
    }





    local function mod(a, b)
        return a - math.floor(a / b) * b
    end

    local selectedCallback = nil
    f.iconButtons = {}  -- 👈 Important : stockage ici

    local buttonsPerRow = 7
    local spacing = 40
    local offsetX, offsetY = 0, 0

    local iconCount = table.getn(ICON_LIST)

    for i = 1, iconCount do
        local thisIconName = ICON_LIST[i]
        local button = CreateFrame("Button", nil, content)
        button:SetWidth(36)
        button:SetHeight(36)

        local row = math.floor((i - 1) / buttonsPerRow)
        local col = mod(i - 1, buttonsPerRow)

        button:SetPoint("TOPLEFT", content, "TOPLEFT", offsetX + col * spacing, offsetY - row * spacing)

        local tex = button:CreateTexture(nil, "ARTWORK")
        tex:SetAllPoints()
        tex:SetTexture("Interface\\Icons\\" .. thisIconName)
        button.texture = tex
        button.iconName = thisIconName

        local highlight = button:CreateTexture(nil, "OVERLAY")
        highlight:SetAllPoints()
        highlight:SetTexture("Interface\\Buttons\\UI-Quickslot2") -- compatible 1.12
        highlight:SetVertexColor(1, 1, 0, 0.5) -- jaune pâle transparent
        highlight:Hide()
        button.highlight = highlight

        button:SetScript("OnClick", function()
            if selectedCallback then
                selectedCallback("Interface\\Icons\\" .. thisIconName)
            end
            f:Hide()
        end)

        table.insert(f.iconButtons, button) -- 👈 Ajouter dans la liste
    end

    local totalRows = math.ceil(iconCount / buttonsPerRow)
    content:SetHeight(totalRows * spacing)

    function f:ShowSelector(callback, currentIcon)
        selectedCallback = callback
        self:Show()

        for _, btn in ipairs(self.iconButtons) do
            if ("Interface\\Icons\\" .. btn.iconName) == currentIcon then
                btn.highlight:Show()
            else
                btn.highlight:Hide()
            end
        end
    end

    return f
end

-- Initialisation unique
local BrainSaver_IconSelector = BrainSaver_IconSelector or CreateLegacyIconSelector()

--------------------------------------------------
-- Static Popup Dialogs
--------------------------------------------------

StaticPopupDialogs["BUY_TALENT_SLOT"] = {
    text = "Do you want to buy a talent slot for %d gold?",
    button1 = "Yes",
    button2 = "No",
    OnShow = function()
      mainFrame:SetAlpha(dialog_alpha)
    end,
    OnAccept = function()
      -- local button = this.data
      local button
      local buy_button
      local slot
      for s,btn in mainFrame.gossip_slots.buy do
        -- Send the appropriate gossip option:
        btn.button:Click() -- this will close the dialogue for us
        break
      end
    end,
    OnHide = function ()
      mainFrame:SetAlpha(1)
    end,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,
    preferredIndex = 3,
}

StaticPopupDialogs["ENABLE_TALENT_LAYOUT"] = {
    text = "Do you want to enable these talents?",
    button1 = "Activate",
    button2 = "Cancel",
    showAlert = 1,
    OnShow = function()
      mainFrame:SetAlpha(dialog_alpha)
      this:SetBackdropColor(1,1,1,1)

      local button = talentButtons[mainFrame.currentButton]
      local spec = BrainSaverDB.spec[button.index]
      local t1,t2,t3 = TalentCounts()
      _G[this:GetName().."Text"]:SetText(
        format("|cffff5500LOAD|r TALENTS\n\nSpec Slot %d:\nSpec name: %s\nSpec talents: %s\n\nCurrent talents: %s\nActivate spec talents? (causes brainwasher debuff)",
        -- format("Enable these talents from slot %d?\n\n%s\n\n%s",
                button.index,
                button:GetName(),
                ColorSpecSummary(spec.t1, spec.t2, spec.t3),
                ColorSpecSummary(t1, t2, t3))
      )
      if spec then
        _G[this:GetName().."AlertIcon"]:SetTexture(spec.icon)
      else
        _G[this:GetName().."AlertIcon"]:SetTexture(button:GetIcon())
      end
    end,
    OnAccept = function()
      local button = talentButtons[mainFrame.currentButton]
      -- Send the appropriate gossip option:
      mainFrame.gossip_slots.load[mainFrame.currentButton]:Click()
    end,
    OnHide = function ()
      mainFrame:SetAlpha(1)
    end,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,
    preferredIndex = 3,
}

StaticPopupDialogs["EDIT_TALENT_SLOT"] = {
    text = "Choose icon for this spec:",
    button1 = "Save",
    button2 = "Cancel",

    OnShow = function(this)
        mainFrame:SetAlpha(dialog_alpha)

        local idx = mainFrame.currentButton
        local spec = BrainSaverDB.spec[idx]
        local currentIcon = spec and spec.icon or "Interface\\Icons\\INV_Misc_QuestionMark"

        -- Stocker l'icône actuelle au moment d'ouvrir la popup
        self.selectedIcon = currentIcon
        self.originalIcon = currentIcon -- pour restaurer en cas d'annulation

        -- Ouvrir le sélecteur avec surbrillance de l'icône actuelle
        BrainSaver_IconSelector:ShowSelector(function(selectedIcon)
            -- Mise à jour temporaire de l'icône sélectionnée
            self.selectedIcon = selectedIcon

            if idx and talentButtons[idx] then
                talentButtons[idx]:SetIcon(selectedIcon)
            end
        end, currentIcon)
    end,

    OnAccept = function(this)
        local idx = mainFrame.currentButton
        if self.selectedIcon and idx then
            -- Sauvegarde définitive dans la DB
            BrainSaverDB.spec[idx] = BrainSaverDB.spec[idx] or {}
            BrainSaverDB.spec[idx].icon = self.selectedIcon

        end

        if BrainSaver_IconSelector and BrainSaver_IconSelector:IsShown() then
            BrainSaver_IconSelector:Hide()
        end
    end,

    OnCancel = function(this)
        local idx = mainFrame.currentButton
        if idx and self.originalIcon then
            -- Restaurer l'icône originale dans le bouton talent si annulé
            if talentButtons[idx] then
                talentButtons[idx]:SetIcon(self.originalIcon)
            end
        end

        if BrainSaver_IconSelector and BrainSaver_IconSelector:IsShown() then
            BrainSaver_IconSelector:Hide()
        end
    end,

    OnHide = function(this)
        mainFrame:SetAlpha(1)
    end,

    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,
    preferredIndex = 3,
}



-- todo, show the spec numbers you're saving, and what exists in the slot
StaticPopupDialogs["SAVE_TALENT_LAYOUT"] = {
    -- text = "Save your current talents to slot %d?\n\n%s\n\n%s\n\nEnter new name:",
    text = "Do you want to save these talents?",
    button1 = "Save",
    button2 = "Cancel",
    hasEditBox = 1,
    showAlert = 1,
    OnShow = function()
      mainFrame:SetAlpha(dialog_alpha)
      local button = talentButtons[mainFrame.currentButton]
      local spec = BrainSaverDB.spec[mainFrame.currentButton]
      local t1,t2,t3 = TalentCounts()

      _G[this:GetName().."Text"]:SetText(
        format("|cff00ff55SAVE|r TALENTS\n\nSpec Slot %d:\nSpec name: %s\nSpec talents: %s\n\nCurrent talents: %s\nReplace spec talents with current talents?",
                button.index,
                button.layoutName:GetText(),
                spec and ColorSpecSummary(spec.t1,spec.t2,spec.t3) or "? | ? | ?",
                ColorSpecSummary(t1,t2,t3))
      )
      local editBox = _G[this:GetName().."EditBox"]
      if spec then
        _G[this:GetName().."AlertIcon"]:SetTexture(spec.icon)
        editBox:SetText(spec.name)
      else
        _G[this:GetName().."AlertIcon"]:SetTexture(button:GetIcon())
        editBox:SetText(button:GetName())
      end
    end,
    OnAccept = function()
      print("OnAccept called in SAVE_TALENT_LAYOUT")
      local button = talentButtons[mainFrame.currentButton]
      local newName = _G[this:GetParent():GetName().."EditBox"]:GetText()
      local t1, t2, t3 = TalentCounts()
      local talents = FetchTalents()

      local newIcon = BrainSaverDB.spec[button.index] and BrainSaverDB.spec[button.index].icon or "Interface\\Icons\\INV_Misc_QuestionMark"
      print("Icon saved:", newIcon)

      BrainSaverDB.spec[button.index] = BrainSaverDB.spec[button.index] or {}

      BrainSaverDB.spec[button.index].name = newName
      BrainSaverDB.spec[button.index].t1 = t1
      BrainSaverDB.spec[button.index].t2 = t2
      BrainSaverDB.spec[button.index].t3 = t3
      BrainSaverDB.spec[button.index].talents = talents
      BrainSaverDB.spec[button.index].icon = newIcon

      button.layoutName:SetText(newName)
      button.talentSummary:SetText(ColorSpecSummary(t1, t2, t3))
      button:SetIcon(newIcon)

      mainFrame.gossip_slots.save[mainFrame.currentButton]:Click()
    end,
    OnHide = function()
      _G[this:GetName() .. "EditBox"]:SetText("")
      mainFrame:SetAlpha(1)
      _G[this:GetName().."AlertIcon"]:SetTexture()
    end,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,
    preferredIndex = 3,
}

-- can't use the builtin since this doesn't use the CONFIRM_TALENT_WIPE event
-- and can't use CheckTalentMasterDist
StaticPopupDialogs["RESET_TALENTS"] = {
    text = "Reset your current talent points?\n\nThis costs gold and causes a 10 minute brainwasher use debuff.",
    button1 = "Yes",
    button2 = "No",
    OnShow = function()
      mainFrame:SetAlpha(dialog_alpha)
      _G[this:GetName().."AlertIcon"]:SetTexture("Interface\\Icons\\Spell_Nature_AstralRecalGroup")
    end,
    OnAccept = function()
      mainFrame.gossip_slots.reset:Click()
    end,
    OnHide = function()
      mainFrame:SetAlpha(1)
      _G[this:GetName().."AlertIcon"]:SetTexture()
    end,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,
    preferredIndex = 3,
    showAlert = 1,
}



--------------------------------------------------
-- Create 4 Talent Buttons in a 2x2 Grid
--------------------------------------------------

local numRows, numCols = 2, 2
local btnWidth, btnHeight = 64, 64
local spacing = 40

-- Calculs de position
local gridWidth = numCols * btnWidth + (numCols - 1) * spacing
local gridXOffset = (mainFrame:GetWidth() - gridWidth) / 2
local gridTopOffset = -110

local index = 1
for row = 1, numRows do
    for col = 1, numCols do
        local btn = CreateFrame("Button", "TalentButton"..index, mainFrame, "ActionButtonTemplate")
        btn:SetWidth(btnWidth)
        btn:SetHeight(btnHeight)

        local x = gridXOffset + (col - 1) * (btnWidth + spacing)
        local y = gridTopOffset - (row - 1) * (btnHeight + spacing)
        btn:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", x, y)
        btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")

        -- Numéro de slot
        btn.slotNumberText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        btn.slotNumberText:SetFont(btn.slotNumberText:GetFont(), 16, "")
        btn.slotNumberText:SetPoint("CENTER", btn, "BOTTOMRIGHT", -8, 9)
        btn.slotNumberText:SetText(index)

        -- Nom au-dessus
        btn.layoutName = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        btn.layoutName:SetPoint("BOTTOM", btn, "TOP", 0, 16)
        btn.layoutName:SetText("Spec " .. index)

        -- Résumé talents
        btn.talentSummary = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        btn.talentSummary:SetPoint("BOTTOM", btn, "TOP", 0, 2)
        btn.talentSummary:SetText("? | ? | ?")

        -- Indicateur actif
        btn.activeIndicator = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        local aif, ais = btn.activeIndicator:GetFont()
        btn.activeIndicator:SetFont(aif, ais, "OUTLINE")
        btn.activeIndicator:SetPoint("CENTER", btn, "CENTER", 0, 0)
        btn.activeIndicator:SetText("")

        -- Autres propriétés
        btn.isActive = false
        btn.clickPending = false
        btn.lastClickTime = 0

        -- Méthodes personnalisées
        function btn:SetName(name)
            self.layoutName:SetText(name)
        end
        function btn:GetName()
            return self.layoutName:GetText()
        end
        function btn:SetTalentSummary(t1, t2, t3)
            if not t1 then
                self.talentSummary:SetText("? | ? | ?")
            elseif type(t1) == "string" then
                self.talentSummary:SetText(t1)
            else
                self.talentSummary:SetText(ColorSpecSummary(t1, t2, t3))
            end
        end
        function btn:GetTalentSummary()
            return self.talentSummary:GetText()
        end
        function btn:GetIndex()
            return self.index
        end
        function btn:GetIcon()
            return self:GetNormalTexture():GetTexture()
        end
        function btn:SetIcon(source, disabled)
            if type(source) ~= "string" or source == "" then
                source = "Interface\\Icons\\INV_Misc_QuestionMark"
            end

            local icon = FindTexture(source)
            if not icon then
                icon = "Interface\\Icons\\INV_Misc_QuestionMark"
            end

            self:SetNormalTexture(icon)
            self:SetPushedTexture(icon)

            if disabled then
                self:GetNormalTexture():SetVertexColor(0.5, 0.5, 0.5)
            else
                self:GetNormalTexture():SetVertexColor(1, 1, 1)
            end

            return icon
        end

        btn:SetIcon("Interface\\Icons\\INV_Misc_QuestionMark")

        -- Chargement des données sauvegardées (icon, nom, talents)
        local savedSpec = BrainSaverDB.spec[index]
        if savedSpec then
            if savedSpec.icon then
                btn:SetIcon(savedSpec.icon)
            end
            if savedSpec.name then
                btn:SetName(savedSpec.name)
            end
            if savedSpec.t1 and savedSpec.t2 and savedSpec.t3 then
                btn:SetTalentSummary(savedSpec.t1, savedSpec.t2, savedSpec.t3)
            end
        end

        -- Gestion des clics
        btn:SetScript("OnClick", function()
            mainFrame.currentButton = this.index
            if this.isActive then
                if arg1 == "RightButton" and IsShiftKeyDown() then
                    StaticPopup_Show("EDIT_TALENT_SLOT")
                elseif arg1 == "RightButton" then
                    StaticPopup_Show("SAVE_TALENT_LAYOUT")
                elseif arg1 == "LeftButton" then
                    if BrainSaverDB.spec[this.index] then
                        StaticPopup_Show("ENABLE_TALENT_LAYOUT")
                    end
                end
            else
                local price
                for s,btn in mainFrame.gossip_slots.buy do
                    price = btn.price
                    break
                end
                StaticPopup_Show("BUY_TALENT_SLOT", price)
            end
        end)

        btn:SetScript("OnShow", function ()
            if this.isCurrentSpec then
                this.activeIndicator:SetText("|cff00ff00ACTIVE|r")
            else
                this.activeIndicator:SetText("")
            end
        end)

        btn.index = index
        talentButtons[index] = btn
        index = index + 1
    end
end

--------------------------------------------------
-- Event Handling
--------------------------------------------------
mainFrame:RegisterEvent("ADDON_LOADED")
mainFrame:RegisterEvent("GOSSIP_SHOW")
mainFrame:RegisterEvent("GOSSIP_CLOSED")
mainFrame:RegisterEvent("UI_ERROR_MESSAGE")
mainFrame:SetScript("OnEvent", function()
  this[event](this,arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8,arg9,arg10)
end)

function mainFrame:UI_ERROR_MESSAGE(msg)
  if not (string.find(msg, "^Scrambled brain detected")) then return end
  for i = 0, 16 do
    local ix = GetPlayerBuff(i, "HARMFUL")
    if ix < 0 then break end
    local texture = GetPlayerBuffTexture(ix)
    if string.lower(texture) == "interface\\icons\\spell_shadow_mindrot" then
      local timeRemaining = GetPlayerBuffTimeLeft(ix)
      if timeRemaining then
        UIErrorsFrame:Clear()
        UIErrorsFrame:AddMessage(format("Brainwasher Debuff: %dm %ds", timeRemaining/60,math.mod(timeRemaining,60)),1,0,0)
      end
      break -- stop once we've found the desired debuff
    end
  end
end

function mainFrame:GOSSIP_CLOSED()
  mainFrame:Hide()
end

function mainFrame:ADDON_LOADED(addon)
  if addon ~= addon_name then return end
  BrainSaverDB = BrainSaverDB or {}
  BrainSaverDB.spec = BrainSaverDB.spec or {}
end

function mainFrame:GOSSIP_SHOW()
  if GossipFrameNpcNameText:GetText() ~= "Goblin Brainwashing Device" then return end

  local titleButton;
  local t1,t2,t3 = TalentCounts()
  local current_spec = FetchTalents()

  self.talentSummaryText:SetText("Current talents: " .. ColorSpecSummary(t1,t2,t3))

  self.gossip_slots = {
    save = {},
    load = {},
    buy = {},
    -- reset = nil,
  }

  for i=1, NUMGOSSIPBUTTONS do
    titleButton = _G["GossipTitleButton" .. i]

    if titleButton:IsVisible() then
      local text = titleButton:GetText()
      local _,_,save_spec = string.find(text,"Save (%d+)(..) Specialization")
      local _,_,load_spec = string.find(text,"Activate (%d+)(..) Specialization")
      local _,_,buy_spec,_,price = string.find(text,"Buy (%d+)(..) Specialization tab for (%d+) gold")
      local reset = string.find(text,"Reset my talents")
      save_spec = tonumber(save_spec)
      load_spec = tonumber(load_spec)
      buy_spec  = tonumber(buy_spec)

      if save_spec then
        self.gossip_slots.save[save_spec] = titleButton
        talentButtons[save_spec].canSave = true
        talentButtons[save_spec].isActive = true

      elseif load_spec then
        self.gossip_slots.load[load_spec] = titleButton
        talentButtons[load_spec].canLoad = true
        talentButtons[load_spec].isActive = true

      elseif buy_spec then
        self.gossip_slots.buy[buy_spec] = { button = titleButton, price = price }

        for i=buy_spec,4 do
          talentButtons[i].isActive = false
          talentButtons[i]:SetIcon("Interface\\Icons\\INV_Misc_Coin_01",true)
          talentButtons[i]:SetName("")
          talentButtons[i]:SetTalentSummary("Buy Slot")
        end

      elseif reset then
        self.gossip_slots.reset = titleButton
      end
    end
  end

  for i=1,4 do
    local button = talentButtons[i]
    local spec = BrainSaverDB.spec[i]
    button.isCurrentSpec = false
    if button.isActive then
      if button.canLoad and spec then
        -- load spec data
        button:SetIcon(spec.icon)
        button:SetName(spec.name)
        button:SetTalentSummary(spec.t1,spec.t2,spec.t3)
        if spec.talents and IsSameSpec(spec.talents,current_spec) then
          button.isCurrentSpec = true
        end
      elseif button.canSave then -- if save but no load
        button:SetIcon("Interface\\Icons\\INV_Misc_QuestionMark")
        button:SetName("Spec "..button.index)
        button:SetTalentSummary("? | ? | ?")
      end
    end
  end


  -- if no gossip options occur we can't use the washer
  if not self.gossip_slots.reset then
    self.talentSummaryText:SetText("\n\n\n\nBrainwasher not available on this character.")
    for _,btn in talentButtons do
      btn:Hide()
    end
    self.resetButton:Hide()
    self.washerButton:Hide()
  else -- restore in case washer was just bought
    for _,btn in talentButtons do
      btn:Show()
    end
    self.resetButton:Show()
    self.washerButton:Show()
  end

  GossipFrame:SetAlpha(0) -- 'hide' but don't cause a GOSSIP_CLOSED
  self:Show()
end
