-- VERSÃO DE EMERGÊNCIA - FUNCIONAL E SIMPLES
ClickMorph = {}
local CM = ClickMorph
CM.isRetail = (WOW_PROJECT_ID == WOW_PROJECT_MAINLINE)
CM.project = CM.isRetail and "Live" or "Classic"
local FileData

-- inventory type -> equipment slot -> slot name
CM.SlotNames = {
	[INVSLOT_HEAD] = "head", -- 1
	[INVSLOT_SHOULDER] = "shoulder", -- 3
	[INVSLOT_BODY] = "shirt", -- 4
	[INVSLOT_CHEST] = "chest", -- 5
	[INVSLOT_WAIST] = "belt", -- 6
	[INVSLOT_LEGS] = "legs", -- 7
	[INVSLOT_FEET] = "feet", -- 8
	[INVSLOT_WRIST] = "wrist", -- 9
	[INVSLOT_HAND] = "hands", -- 10
	[INVSLOT_BACK] = "cloak", -- 15
	[INVSLOT_MAINHAND] = "mainhand", -- 16
	[INVSLOT_OFFHAND] = "offhand", -- 17
	[INVSLOT_RANGED] = "ranged", -- 18
	[INVSLOT_TABARD] = "tabard", -- 19
}

-- https://wow.gamepedia.com/Enum_Item.InventoryType
local InvTypeToSlot = {
	INVTYPE_HEAD = INVSLOT_HEAD, -- 1
	INVTYPE_SHOULDER = INVSLOT_SHOULDER, -- 3
	INVTYPE_BODY = INVSLOT_BODY, -- 4
	INVTYPE_CHEST = INVSLOT_CHEST, -- 5
	INVTYPE_ROBE = INVSLOT_CHEST, -- 5 (cloth)
	INVTYPE_WAIST = INVSLOT_WAIST, -- 6
	INVTYPE_LEGS = INVSLOT_LEGS, -- 7
	INVTYPE_FEET = INVSLOT_FEET, -- 8
	INVTYPE_WRIST = INVSLOT_WRIST, -- 9
	INVTYPE_HAND = INVSLOT_HAND, -- 10
	INVTYPE_CLOAK = INVSLOT_BACK, -- 15
	INVTYPE_2HWEAPON = INVSLOT_MAINHAND, -- 16
	INVTYPE_WEAPON = INVSLOT_MAINHAND, -- 16
	INVTYPE_WEAPONMAINHAND = INVSLOT_MAINHAND, -- 16
	INVTYPE_WEAPONOFFHAND = INVSLOT_OFFHAND, -- 17
	INVTYPE_HOLDABLE = INVSLOT_OFFHAND, -- 17
	INVTYPE_RANGED = INVSLOT_RANGED, -- 18
	INVTYPE_THROWN = INVSLOT_RANGED, -- 18
	INVTYPE_RANGEDRIGHT = INVSLOT_RANGED, -- 18
	INVTYPE_SHIELD = INVSLOT_OFFHAND, -- 17
	INVTYPE_TABARD = INVSLOT_TABARD, -- 19
}

local GearSlots = {
	INVSLOT_HEAD, -- 1
	INVSLOT_SHOULDER, -- 3
	INVSLOT_BODY, -- 4
	INVSLOT_CHEST, -- 5
	INVSLOT_WAIST, -- 6
	INVSLOT_LEGS, -- 7
	INVSLOT_FEET, -- 8
	INVSLOT_WRIST, -- 9
	INVSLOT_HAND, -- 10
	INVSLOT_BACK, -- 15
	INVSLOT_TABARD, -- 19
}

local lastWeaponSlot = INVSLOT_OFFHAND

local DualWieldSlot = {
	[INVSLOT_MAINHAND] = INVSLOT_OFFHAND,
	[INVSLOT_OFFHAND] = INVSLOT_MAINHAND,
}

function CM:PrintChat(msg, r, g, b)
	if not ClickMorphDB or not ClickMorphDB.silent then
		DEFAULT_CHAT_FRAME:AddMessage(format("|cff7fff00ClickMorph|r: |r%s", msg), r, g, b)
	end
end

function CM:GetFileData(frame)
	if not FileData then
		local addon = "ClickMorphData"
		local loaded, reason = LoadAddOn(addon)
		if not loaded then
			if reason == "DISABLED" then
				EnableAddOn(addon, true)
				LoadAddOn(addon)
			else
				if frame then
					frame:SetScript("OnUpdate", nil) -- cancel any wardrobe timer
				end
				self:PrintChat("The ClickMorphData folder could not be found. Using basic functionality.", 1, 1, 0)
				-- Criar dados básicos temporários
				FileData = {
					Live = { ItemAppearance = {}, ItemVisuals = {} },
					Classic = { ItemSet = {}, Mount = {}, Npc = {} }
				}
				return FileData
			end
		end
		FileData = _G[addon]
	end
	return FileData
end

function CM:CanMorph(override)
	if IsAltKeyDown() or override then
		for _, morpher in pairs(self.morphers) do
			if morpher.loaded() then
				return morpher
			end
		end
		local name = "iMorph"
		self:PrintChat("Could not find |cffFFFF00"..name.."|r. Make sure iMorph is loaded and injected.", 1, 1, 0)
	end
end

function CM:CanMorphMount()
	local isMounted = IsMounted()
	local onTaxi = UnitOnTaxi("player")
	if isMounted and not onTaxi then
		return true
	else
		if onTaxi then
			CM:PrintChat("You need to be not on a flight path", 1, 1, 0)
		elseif not isMounted then
			CM:PrintChat("You need to be mounted", 1, 1, 0)
		end
	end
end

CM.morphers = {
	iMorph = { -- funciona em retail e classic
		loaded = function() return IMorphInfo end,
		reset = function()
			if iMorphFrame then
				iMorphFrame:Reset()
			end
			if ClickMorph_iMorphV1 then
				wipe(ClickMorph_iMorphV1)
			end
		end,
		model = function(_, displayID)
			if Morph then
				Morph(displayID)
			end
		end,
		race = function(_, raceID, genderID)
			if SetRace then
				SetRace(raceID, genderID)
			end
		end,
		mount = function(_, displayID)
			if CM:CanMorphMount() and SetMount then
				SetMount(displayID)
				return true
			end
		end,
		item = function(_, slotID, itemID)
			if SetItem then
				SetItem(slotID, itemID)
			end
		end,
		scale = function(_, value)
			if SetScale then
				SetScale(value)
				if ClickMorph_iMorphV1 then
					ClickMorph_iMorphV1.tempscale = value -- workaround
				end
			end
		end,
	},
}

function CM:ResetMorph()
	local morph = self:CanMorph(true)
	if morph and morph.reset then
		morph.reset()
	end
end

function CM:Undress(unit)
	local morph = self:CanMorph(true)
	if morph and morph.item then
		for _, invSlot in pairs(GearSlots) do
			morph.item(unit, invSlot, 0)
		end
	end
end

-- Items
function CM:GetItemInfo(item)
	if type(item) == "string" then
		local itemID = tonumber(item:match("item:(%d+)"))
		local equipLoc = select(9, GetItemInfo(itemID))
		return itemID, item, equipLoc
	else
		local itemLink, _, _, _, _, _, _, equipLoc = select(2, GetItemInfo(item))
		return item, itemLink, equipLoc
	end
end

function CM:GetDualWieldSlot(slot)
	if DualWieldSlot[slot] and IsDualWielding() then
		lastWeaponSlot = DualWieldSlot[lastWeaponSlot]
		return lastWeaponSlot
	else
		return slot
	end
end

local function IsLooting()
	if ElvLootSlot1 then -- elvui
		return ElvLootSlot1:IsShown()
	else
		return LootFrame:IsShown()
	end
end

function CM:MorphItem(unit, item, silent)
	local morph = CM:CanMorph()
	if item and morph and morph.item and not IsLooting() then
		local itemID, itemLink, equipLoc = CM:GetItemInfo(item)
		local slotID = InvTypeToSlot[equipLoc]
		if slotID then
			slotID = CM:GetDualWieldSlot(slotID)
			morph.item(unit, slotID, itemID)
			if not silent then
				CM:PrintChat(format("|cffFFFF00%s|r -> item |cff71D5FF%d|r %s", CM.SlotNames[slotID], itemID, itemLink))
			end
		end
	end
end

-- Hook principal para Alt+Click
hooksecurefunc("HandleModifiedItemClick", function(item)
	CM:MorphItem("player", item)
end)

-- ADICIONE ESSAS FUNÇÕES NO FINAL DO SEU ClickMorph.lua
-- (depois da função Debug, antes dos comandos)

-- Mounts
function CM:MorphMount(unit, mountID)
	local morph = self:CanMorph()
	if morph and morph.mount then
		local _, spellID, icon = C_MountJournal.GetMountInfoByID(mountID)
		local displayID = C_MountJournal.GetMountInfoExtraByID(mountID)
		if not displayID then
			local multipleIDs = C_MountJournal.GetMountAllCreatureDisplayInfoByID(mountID)
			if multipleIDs and #multipleIDs > 0 then
				displayID = multipleIDs[math.random(#multipleIDs)].creatureDisplayID
			end
		end
		if displayID and morph.mount(unit, displayID) then
			local spellLink = GetSpellLink(spellID) or "Mount ID: "..mountID
			CM:PrintChat(format("mount -> %d %s", displayID, spellLink))
		else
			CM:PrintChat("Failed to morph mount - no display ID found", 1, 1, 0)
		end
	end
end

function CM.MorphMountModelScene()
	local mountID = MountJournal.selectedMountID
	if mountID then
		CM:MorphMount("player", mountID)
	end
end

function CM.MorphMountScrollFrame(frame)
	if frame.index then
		local mountID = select(12, C_MountJournal.GetDisplayedMountInfo(frame.index))
		if mountID then
			CM:MorphMount("player", mountID)
		end
	end
end

-- Appearances/Transmog Sets
function CM.MorphTransmogSet()
	local morph = CM:CanMorph()
	if morph and morph.item then
		local setID = WardrobeCollectionFrame.SetsCollectionFrame.selectedSetID
		if not setID then
			CM:PrintChat("No set selected", 1, 1, 0)
			return
		end
		
		local setInfo = C_TransmogSets.GetSetInfo(setID)
		if not setInfo then
			CM:PrintChat("Could not get set info", 1, 1, 0)
			return
		end

		-- Undress first
		CM:Undress("player")
		
		-- Get set sources
		local sources = C_TransmogSets.GetSetSources(setID)
		if sources then
			for _, sourceID in pairs(sources) do
				local sourceInfo = C_TransmogCollection.GetSourceInfo(sourceID)
				if sourceInfo and sourceInfo.itemID then
					local slotID = C_Transmog.GetSlotForInventoryType(sourceInfo.invType)
					if slotID then
						morph.item("player", slotID, sourceInfo.itemID)
					end
				end
			end
			CM:PrintChat(format("itemset -> %d %s", setID, setInfo.name))
		else
			CM:PrintChat("Could not get set sources", 1, 1, 0)
		end
	end
end

-- Inicializar hooks quando os UIs carregarem
local function InitializeHooks()
	-- Mount Journal hooks
	if MountJournal then
		-- Model scene click
		if MountJournal.MountDisplay and MountJournal.MountDisplay.ModelScene then
			MountJournal.MountDisplay.ModelScene:HookScript("OnMouseUp", function(self, button)
				if button == "LeftButton" and IsAltKeyDown() then
					CM.MorphMountModelScene()
				end
			end)
		end
		
		-- List scroll frame buttons
		if MountJournal.ListScrollFrame and MountJournal.ListScrollFrame.buttons then
			for _, button in pairs(MountJournal.ListScrollFrame.buttons) do
				if button then
					button:HookScript("OnClick", function(self, btn)
						if btn == "LeftButton" and IsAltKeyDown() then
							CM.MorphMountScrollFrame(self)
						end
					end)
				end
			end
		end
		
		CM:PrintChat("Mount Journal hooks initialized")
	end
	
	-- Wardrobe Set hooks
	if WardrobeCollectionFrame and WardrobeCollectionFrame.SetsCollectionFrame then
		local setsFrame = WardrobeCollectionFrame.SetsCollectionFrame
		
		-- Hook set model
		if setsFrame.Model then
			setsFrame.Model:HookScript("OnMouseUp", function(self, button)
				if button == "LeftButton" and IsAltKeyDown() then
					CM.MorphTransmogSet()
				end
			end)
		end
		
		CM:PrintChat("Wardrobe Sets hooks initialized")
	end
end

-- Hook de inicialização
local hookFrame = CreateFrame("Frame")
hookFrame:RegisterEvent("ADDON_LOADED")
hookFrame:SetScript("OnEvent", function(self, event, addonName)
	if addonName == "Blizzard_Collections" then
		-- Collections UI carregou, inicializar hooks
		C_Timer.After(0.5, InitializeHooks)
		self:UnregisterEvent(event)
	end
end)

-- Verificar Collections com delay para evitar erro de carregamento
C_Timer.After(2, function()
	if IsAddOnLoaded("Blizzard_Collections") then
		InitializeHooks()
	end
end)

-- SUBSTITUA TODO O FINAL DO SEU ARQUIVO (da linha "-- Sistema de debug SEM emojis" até o final)
-- Por este código:

-- Sistema de debug SEM emojis
function CM:Debug()
	self:PrintChat("=== ClickMorph Debug ===")
	self:PrintChat("Version: WoW 11.x Compatible")
	self:PrintChat("Project: " .. self.project)
	self:PrintChat("IsRetail: " .. tostring(self.isRetail))
	
	-- Verificar morpher
	for name, morpher in pairs(self.morphers) do
		local status = morpher.loaded() and "[OK] LOADED" or "[FAIL] NOT LOADED"
		self:PrintChat("Morpher " .. name .. ": " .. status)
	end
	
	-- Verificar UIs
	local uis = {
		["MountJournal"] = MountJournal,
		["WardrobeCollectionFrame"] = WardrobeCollectionFrame,
		["Collections"] = IsAddOnLoaded("Blizzard_Collections")
	}
	
	for name, obj in pairs(uis) do
		local status = obj and "[OK] AVAILABLE" or "[FAIL] NOT AVAILABLE"
		self:PrintChat("UI " .. name .. ": " .. status)
	end
	
	-- Teste básico
	local morpher = self:CanMorph(true)
	if morpher then
		self:PrintChat("[OK] Ready to morph!")
	else
		self:PrintChat("[FAIL] No morpher found - load iMorph first")
	end
end

-- Comandos de debug
SLASH_CLICKMORPH_DEBUG1 = "/cmdebug"
SlashCmdList.CLICKMORPH_DEBUG = function()
	CM:Debug()
end

-- Frame principal de inicialização (combinando tudo)
local mainFrame = CreateFrame("Frame")
mainFrame:RegisterEvent("ADDON_LOADED")
mainFrame:SetScript("OnEvent", function(self, event, addonName)
	if addonName == "ClickMorph" then
		CM:PrintChat("Loaded! Use /cmdebug to check status. Make sure iMorph is injected!")
		-- Não desregistrar ainda, vamos aguardar Collections também
	elseif addonName == "Blizzard_Collections" then
		-- Collections UI carregou, inicializar hooks
		C_Timer.After(0.5, InitializeHooks)
		self:UnregisterEvent(event)
	end
end)

-- Se Collections já estiver carregado
if IsAddOnLoaded("Blizzard_Collections") then
	C_Timer.After(1, InitializeHooks)
end
