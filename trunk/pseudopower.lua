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


-----------------
-- Multiplyers -- 
-----------------
local SPELL_POWER = 1
local SPELL_HIT = 1.53
local SPELL_CRIT = 0.72
local SPELL_HASTE = 0.68
local BONUS_INT = 0.22
local BONUS_SPI = 0.25	


----------
-- Gems --
----------
local rGem = StatLogic:GetGemID(40113) -- Runed Cardinal Ruby (+23 SP)
local bGem = StatLogic:GetGemID(40133) -- Purified Dreadstone (+12 SP & +10 Spi)
local yGem = StatLogic:GetGemID(40152) -- Potent Flawless Ametrine (+12 SP & +10 Crit)
local mGem = StatLogic:GetGemID(41285) -- Chaotic Skyflare Diamond (+21 Crit & 3% Crit Dmg)
	
	
-----------------
-- Debug Tools --
-----------------
local function debugPrint(text)
	if DEBUG == true then
		print(text)
	end
end


---------------------
-- Command Handler --
---------------------
SLASH_PP1, SLASH_PP2 = '/pp', '/pseudopower'
function SlashCmdList.PP(msg, editbox)
	pp = GetPPScore()
	print("Total PseudoPower: "..pp)
end


-------------------
-- Toptip Script --
-------------------
local function OnTooltipSetItem(self)
	local _, Item = self:GetItem()
	if Item then
 		local pp, pph, _ = GetValue(Item)
		if pp then
		
			-- Show optimizations
			self:AddLine(" ")
		 		
 			-- Display the PseudoPower of the item as-is
 			if pp > 0 then
 				if pph > pp then 
 					self:AddLine(white.."PseudoPower:|r "..pp.." ("..pph.." w/ hit)")
 				else 
     				self:AddLine(white.."PseudoPower:|r "..pp)
     			end
			end
			
			-- Display the optimal PseudoPower
			local optimalItem, optimalString = OptimalItem(Item)
			local opp, opph, _ = GetValue(optimalItem)
			if opp > pp then					
				if opph > opp then
					self:AddLine(white.."Optimal PseudoPower:|r "..opp.." ("..opph.." w/ hit)")
				else
	     			self:AddLine(white.."Optimal PseudoPower:|r "..opp)		
	        	end
				
				-- Show optimizations
				self:AddLine(red..optimalString)		
			end
			
			-- repaint tooltip
			self:Show()
	
		end		
		
	end

end


-----------------------
-- Add tooltip hooks --
-----------------------
local _, class = UnitClass("player")
if (class == "PRIEST") then	
	TipHooker:Hook(OnTooltipSetItem, "item")	
end 


------------------------------------------------------
-- Used to display PP values for special case items --
------------------------------------------------------
local CUSTOM_ITEM_DATA = {
	-- Equip Chance Items
	[39229] = { 147.8, 147.8, 0 },
	[40255] = { 148, 241.01, 0 },
	
	
	-- Meta Gems
	[41285] = { 70, 70, 0 },
	
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
		return nil, nil, nil
	end
	
	-- Get the item ID to check against custom data
	local itemID = itemLink:match("item:(%d+)")
	if not itemID then return end
	itemID = tonumber(itemID)

	-- Check to see if there is custom data for this item ID
	if CUSTOM_ITEM_DATA[itemID] then
		pp, pph, hit = unpack(CUSTOM_ITEM_DATA[itemID])
		return pp, pph, hit
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

	-- Set the hit to a variable
	local hit = 0
	if (statData["SPELL_HIT_RATING"]) then hit = statData["SPELL_HIT_RATING"] end
		
	return pp, pph, hit
end


-------------------------
-- Get Total PP Score  --
-------------------------
function GetPPScore() 
	local sumPP = 0
	local sumPPH = 0
	local sumHIT = 0
	local hitCap = 289
	
	-- Fix hitCap if we are a Draenei 
	local race = UnitClass("player")
	if race == "Draenei" then
		hitCap = 263
	end 
	
	for i=1,18 do
		local itemLink = GetInventoryItemLink("player", i)
		if (itemLink) then
			local pp, pph, hit = GetValue(itemLink)
			
			sumPP = sumPP + pp
			sumPPH = sumPPH + pph
			sumHIT = sumHIT + hit
		end
	end 
	
	if hit > hitCap then
		-- We are below hit cap, everything counts
		return sumPPH
	else
		-- We are at or above the hit cap, so we need to calculate the PP and ignore
		-- any hit above the hitcap (since its useless)
		sumPP = sumPP + (hitCap * SPELL_HIT)
		return sumPP
	end	
end

----------------------------------------
-- Returns the best enchants per slot --
----------------------------------------
function OptimalEnchant(itemSlot)

	if     itemSlot == "INVTYPE_HEAD"		then return "Arcanum of Burning Mysteries", 3820
    elseif itemSlot == "INVTYPE_SHOULDER"	then return "Greater Inscription of the Storm", 3810
    elseif itemSlot == "INVTYPE_CHEST" 		then return "Enchant Chest - Powerful Stats", 3832
    elseif itemSlot == "INVTYPE_ROBE" 	then return "Enchant Chest - Powerful Stats", 3832
    elseif itemSlot == "INVTYPE_WAIST" 	then return "Eternal Belt Buckle", 3729
    elseif itemSlot == "INVTYPE_LEGS" 	then return "Brilliant Spellthread", 3719
    elseif itemSlot == "INVTYPE_FEET" 	then 
    	-- Engineering
    	return "Enchant Boots - Icewalker", 3826
    elseif itemSlot == "INVTYPE_HAND" 	then 
    	-- Engineering
    	return "Enchant Gloves - Exceptional Spellpower", 3246 -- Everyone
    elseif itemSlot == "INVTYPE_FINGER" 	then 
    	--return "Enchant Ring - Greater Spellpower", 3840 -- Enchanting
    	return nil, nil
    elseif itemSlot == "INVTYPE_CLOAK" 	then 
    	-- Tailoring
    	-- Engineering
    	return "Enchant Cloak - Greater Speed", 3831 -- Everyone
    elseif itemSlot == "INVTYPE_WEAPON" 	then return "Enchant Weapon - Mighty Spellpower", 3855
    elseif itemSlot == "INVTYPE_2HWEAPON" then return "Enchant Staff - Greater Spellpower", 3854
    elseif itemSlot == "INVTYPE_WRIST" 	then 
		-- Leatherworking
    	return "Enchant Bracers - Superior Spellpower", 2332 -- Everyone
	else									 return nil, nil	
	end

end 


--------------------
-- Optimize Item ---
--------------------
function OptimalItem(item)
	
	-- Strip off anything thats on it now
	link = StatLogic:RemoveEnchantGem(item)
	
	-- Add the enchant (if applicable)
	local _,_,_,_,_,_,_,_,ItemSlot = GetItemInfo(item)
	local eName, eID = OptimalEnchant(ItemSlot)
	if eID then link = StatLogic:ModEnchantGem(link,eID) end
	
	local optimalString = ""
	if eName then optimalString = eName end
	
	-- Build and determine the better gem option
	unmatchedLink = StatLogic:BuildGemmedTooltip(link, rGem, rGem, rGem, mGem)
	matchedLink  = StatLogic:BuildGemmedTooltip(link, rGem, yGem, bGem, mGem)
	local _, upph, _ = GetValue(unmatchedLink)
	local _, mpph, _ = GetValue(matchedLink)	
	if upph >= mpph then 
		link = unmatchedLink
		optimalString = optimalString.." w/ All Red Gems"
	else 
		link = matchedLink 
		optimalString = optimalString.." & Match Gems"
	end
	
	-- Return the Optimized item
	return link, optimalString

end
	