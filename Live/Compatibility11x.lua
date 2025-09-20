-- Live/Compatibility11x.lua
-- Correções específicas para WoW 11.x
local CM = ClickMorph
if not CM.isRetail then return end

local BUILD_VERSION = select(4, GetBuildInfo())

-- Só aplicar correções se for WoW 11.x ou superior
if BUILD_VERSION < 110000 then return end

local f = CreateFrame("Frame")
local isInitialized = false

-- Tabela para rastrear APIs problemáticas
local apiStatus = {
	mount = false,
	transmog = false,
	wardrobe = false
}

-- Verificar se APIs críticas existem
local function VerifyAPIs()
	local issues = {}
	
	-- Verificar C_MountJournal
	if C_MountJournal and C_MountJournal.GetMountIDs then
		apiStatus.mount = true
	else
		table.insert(issues, "C_MountJournal")
	end
	
	-- Verificar C_TransmogCollection
	if C_TransmogCollection and C_TransmogCollection.GetAppearanceSources then
		apiStatus.transmog = true
	else
		table.insert(issues, "C_TransmogCollection")
	end
	
	-- Verificar Wardrobe
	if WardrobeCollectionFrame then
		apiStatus.wardrobe = true
	else
		table.insert(issues, "WardrobeCollectionFrame")
	end
	
	if #issues > 0 then
		CM:PrintChat("⚠️ WoW 11.x Compatibility Issues: " .. table.concat(issues, ", "), 1, 1, 0)
	else
		CM:PrintChat("✅ WoW 11.x APIs verified successfully!")
	end
	
	return #issues == 0
end

-- Correções específicas para problemas do 11.x
local function Apply11xFixes()
	-- Fix 1: Problema com model display no Wardrobe
	if WardrobeCollectionFrame and WardrobeCollectionFrame.ItemsCollectionFrame then
		local ItemsCollection = WardrobeCollectionFrame.ItemsCollectionFrame
		
		-- Hook melhorado para atualização de modelos
		if ItemsCollection.Models then
			for _, model in pairs(ItemsCollection.Models) do
				if model and model.SetUnit then
					-- Forçar refresh do modelo quando necessário
					local originalOnShow = model:GetScript("OnShow")
					model:SetScript("OnShow", function(self)
						if originalOnShow then originalOnShow(self) end
						
						-- Delay pequeno para garantir que o modelo carregou
						C_Timer.After(0.1, function()
							if model:IsShown() then
								pcall(function() model:SetUnit("player") end)
							end
						end)
					end)
				end
			end
		end
	end
	
	-- Fix 2: Melhorar compatibilidade com Mount Journal
	if MountJournal then
		-- Verificar se a estrutura mudou no 11.x
		local function VerifyMountStructure()
			if not MountJournal.MountDisplay then
				CM:PrintChat("🔧 WoW 11.x: MountDisplay structure changed", 1, 1, 0)
				return false
			end
			
			if not MountJournal.ListScrollFrame then
				CM:PrintChat("🔧 WoW 11.x: ListScrollFrame structure changed", 1, 1, 0)
				return false
			end
			
			return true
		end
		
		-- Hook de verificação
		hooksecurefunc("CollectionsJournal_LoadUI", function()
			C_Timer.After(0.5, VerifyMountStructure)
		end)
	end
	
	-- Fix 3: Melhorar tratamento de erros de morphing
	local originalMorphItem = CM.MorphItem
	CM.MorphItem = function(self, unit, item, silent)
		local success, result = pcall(originalMorphItem, self, unit, item, silent)
		if not success then
			if not silent then
				self:PrintChat("🔧 WoW 11.x morphing error: " .. tostring(result), 1, 0.5, 0)
			end
		end
		return success and result
	end
end

-- Event handler principal
function f:OnEvent(event, addonName)
	if event == "ADDON_LOADED" and addonName == "ClickMorph" then
		-- Aguardar um pouco para garantir que tudo carregou
		C_Timer.After(2, function()
			if not isInitialized then
				isInitialized = true
				CM:PrintChat("🚀 Initializing WoW 11.x compatibility layer...")
				
				if VerifyAPIs() then
					Apply11xFixes()
					CM:PrintChat("✅ WoW 11.x compatibility layer loaded!")
				else
					CM:PrintChat("❌ Some WoW 11.x APIs are missing - addon may not work fully", 1, 1, 0)
				end
			end
		end)
		
		self:UnregisterEvent(event)
		
	elseif event == "ADDON_LOADED" and addonName == "Blizzard_Collections" then
		-- Aplicar fixes específicos quando Collections carrega
		C_Timer.After(1, function()
			if apiStatus.wardrobe then
				Apply11xFixes()
			end
		end)
	end
end

-- Comando para re-verificar compatibilidade
SLASH_CLICKMORPH_11X1 = "/cm11x"
SlashCmdList.CLICKMORPH_11X = function()
	CM:PrintChat("🔍 Re-checking WoW 11.x compatibility...")
	if VerifyAPIs() then
		Apply11xFixes()
		CM:PrintChat("✅ WoW 11.x compatibility re-applied!")
	end
end

-- Registrar eventos
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", f.OnEvent)

		-- Debug info
CM:PrintChat("🔧 WoW 11.x Compatibility module loaded (Build: " .. BUILD_VERSION .. ") - Configured for iMorph")
