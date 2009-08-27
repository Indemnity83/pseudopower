---------------
-- Libraries --
---------------
local StatLogic = LibStub("LibStatLogic-1.1")
local TipHooker = LibStub("LibTipHooker-1.1")


---------------------
-- Local variables --
---------------------
local DEBUG = true
local quality_threshold = 2
local green = "|cff20ff20"
local red = "|cffff2020"
local white = "|cffffffff"
local purple = "|cffff00ff"


-----------------
-- Debug Tools --
-----------------
local function debugPrint(text)
	if DEBUG == true then
		print(text)
	end
end


-------------------
-- Toptip Script --
-------------------
local function OnTooltipSetItem(self)
	local _, Item = self:GetItem()
	if Item then
 		local pp, pph = GetValue(Item)
 		
 		if pp then
			if pph > pp then
     			self:AddLine(L[white.."PseudoPower:|r %d (%d)"]:format(pp, pph))		
        	else 
				self:AddLine(L[white.."PseudoPower:|r %d"]:format(pp))
			end
		end		
	end
end


-----------------------
-- Add tooltip hooks --
-----------------------
local _, class = UnitClass("player")
if (class == "PRIEST") then
	-- GameTooltip:SetScript("OnTooltipSetItem", OnTooltipSetItem)
	-- ItemRefTooltip:SetScript("OnTooltipSetItem", OnTooltipSetItem)	
	TipHooker:Hook(OnTooltipSetItem, "item")
	
	-- Multiplyers
	-- Weights :  Int=0.35  Spi=0.39  SP=1.56  Hit=2.39  Crit=1.12  Haste=1.07
	local SPELL_POWER = 1
	local SPELL_HIT = 1.53
	local SPELL_CRIT = 0.72
	local SPELL_HASTE = 0.68
	local BONUS_INT = 0.22
	local BONUS_SPI = 0.25	
end 

if (class == "MAGE") then
	-- GameTooltip:SetScript("OnTooltipSetItem", OnTooltipSetItem)
	-- ItemRefTooltip:SetScript("OnTooltipSetItem", OnTooltipSetItem)	
	TipHooker:Hook(OnTooltipSetItem, "item")
	
	-- Multiplyers
	--  Weights :  Int=0.58  Spi=0.60  SP=1.40  Hit=2.88  Crit=0.85  Haste=1.66
	local SPELL_POWER = 1.40
	local SPELL_HIT = 2.88
	local SPELL_CRIT = 0.85
	local SPELL_HASTE = 1.66
	local BONUS_INT = 0.58
	local BONUS_SPI = 0.60
end 



------------------------------------------------------
-- Used to display PP values for special case items --
------------------------------------------------------
local CUSTOM_ITEM_DATA = {
	-- Equip Chance Items
	[39229] = { 147.8, 147.8 },
	[40255] = { 148, 241.01 },
}


--------------------------------
-- Calculate PP and PPH value --
--------------------------------
function GetValue(item)
	if not item then return end
	
	local _, itemLink, rarity, _, _, _, _, _, _ = GetItemInfo(item)
	if not itemLink then return end
	
	-- Is the item above our minimum threshold?
	if not rarity or rarity < quality_threshold then
		return nil, nil
	end
	
	-- Get the item ID to check against custom data
	local itemID = itemLink:match("item:(%d+)")
	if not itemID then return end
	itemID = tonumber(itemID)

	-- Check to see if there is custom data for this item ID
	if CUSTOM_ITEM_DATA[itemID] then
		pp, pph = unpack(CUSTOM_ITEM_DATA[itemID])
		return pp, pph
	end
	
	-- Build Summary Table
	local statData = {}
	StatLogic:GetSum(itemLink, statData)
			
	-- Do the math for base PsudoPower
	local pp = 0
	if (statData["SPELL_DMG"]) then pp = pp + statData["SPELL_DMG"] * SPELL_POWER end
	if (statData["SPELL_CRIT_RATING"]) then pp = pp + statData["SPELL_CRIT_RATING"] * SPELL_CRIT end
	if (statData["SPELL_HASTE_RATING"]) then pp = pp + statData["SPELL_HASTE_RATING"] * SPELL_HASTE end
	if (statData["INT"]) then pp = pp + statData["INT"] * BONUS_INT end
	if (statData["SPI"]) then pp = pp + statData["SPI"] * BONUS_SPI end
	
	-- Do the final calculation including Hit
	local pph = pp
	if (statData["SPELL_HIT_RATING"]) then pph = pph + statData["SPELL_HIT_RATING"] * SPELL_HIT end
		
	return pp, pph
end	