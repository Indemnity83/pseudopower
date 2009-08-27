-- $Id$
local REV = "$Id$:"

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
-- Scaled from http://code.google.com/p/simulationcraft/wiki/SampleOutputT8_Details
local SPELL_POWER = 1.00
local SPELL_HIT = 1.35
local SPELL_CRIT = 0.72
local SPELL_HASTE = 0.64
local BONUS_INT = 0.22
local BONUS_SPI = 0.26


----------
-- Gems --
----------
local rGem = StatLogic:GetGemID(40113) -- Runed Cardinal Ruby (+23 SP)
local bGem = StatLogic:GetGemID(40133) -- Purified Dreadstone (+12 SP & +10 Spi)
local yGem = StatLogic:GetGemID(40152) -- Potent Ametrine (+12 SP & +10 Crit)
local mGem = StatLogic:GetGemID(41285) -- Chaotic Skyflare Diamond (+21 Crit & 3% Crit Dmg)
	
	
-----------------
-- Debug Tools --
-----------------
local function debugPrint(text)
	if DEBUG == true then
		print(green.."PP:|r "..text)
	end
end


---------------------
-- Command Handler --
---------------------
SLASH_PP1, SLASH_PP2 = '/pp', '/pseudopower'
function SlashCmdList.PP(msg, editbox)
	-- Debug info, print the file revision
	debugPrint(REV)

	-- Spit out the total PP for this user
	pp = GetPPScore()
	local dps = string.format("%d", pp * 1.56)	
	print("Total PseudoPower: "..pp.." (approx. "..dps.." peak dps)")
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
 			if pp then
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
				self:AddLine(optimalString)		
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
	-- [Item ID] = { sp, crit, haste, spi, int, hit } only use whole numbers
	
	-- Equip Chance Items
	[40682] = { 112, 84, 0, 0, 0, 0 },	-- Sundial of the Exiled
	[40255] = { 128, 0, 0, 0, 0, 71 },	-- Dying Curse
	[45518] = { 189, 120, 0, 0, 0, 0 },	-- Flare of the Heavens
	[45490] = { 167, 0, 0, 0, 108, 0 },	-- Pandora's Plea
	[39229] = { 98, 0, 112, 0, 0, 0 },	-- Embrace of the Spider
	[37660] = { 114, 73, 0, 0, 0, 0 },	-- Forge Ember
	[40373] = { 49, 95, 0, 0, 0, 0 },	-- Extract of Necromantic Power
	[47213] = { 131, 0, 84, 0, 0, 0 },	-- Abyssal Rune
		
	-- On Use (assumed to be used every cooldown)
	[48724] = { 100, 0, 0, 0, 128, 0 },	-- Talisman of Resurgence
	[48722] = { 0, 0, 85, 0, 0, 128 }, 	-- Shard of the Crystal Heart
	[45466] = { 125, 0, 72, 0, 0, 0 },	-- Scale of Fates
	[45148] = { 84, 0, 0, 0, 0, 107 },	-- Living Flame
	
	-- Stacking Buff (assumed to be full stacks)
	[40432] = { 200, 0, 0, 0, 0, 0 },	-- Illustration of the Dragon Soul
	[47316] = { 309, 0, 0, 0, 0, 0 }, 	-- Reign of the Dead (assuming a crit every 2.5 seconds)
	[47182] = { 309, 0, 0, 0, 0, 0 }, 	-- Reign of the Unliving (assuming a crit every 2.5 seconds)
	[45308] = { 125, 87, 0, 0, 0, 0 }, 	-- Eye of the Broodmother
	
	-- Meta Gems (these are somewhat hacked)
	[41285] = { 70, 0, 0, 0, 0, 0 },	-- Chaotic Skyflare Diamond
	
	-- TODO: Confirm the following items (currently, the haste is an educated guess)	
	[48018] = { 0, 126, 47, 0, 0, 0}, 	-- Fetish of Volatile Power (ilvl 245)
	[47946] = { 0, 126, 47, 0, 0, 0}, 	-- Talisman of Volatile Power (ilvl 245)
	[47879] = { 0, 114, 42, 0, 0, 0}, 	-- Fetish of Volatile Power (ilvl 232)
	[47726] = { 0, 114, 42, 0, 0, 0}, 	-- Talisman of Volatile Power (ilvl 232)
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

	local statData = {}
	
	-- Check to see if there is custom data for this item ID
	if CUSTOM_ITEM_DATA[itemID] then
		statData["SPELL_DMG"], statData["SPELL_CRIT_RATING"], statData["SPELL_HASTE_RATING"], 
		statData["SPI"], statData["INT"], statData["SPELL_HIT_RATING"] = unpack(CUSTOM_ITEM_DATA[itemID])
	else 	
		-- Build Summary Table using LibStatLogic
		StatLogic:GetSum(itemLink, statData)
	end 
			
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
	local pp = 0
	local pph = 0
	local hit = 0
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
			
			debugPrint(itemLink.." "..pp.." ("..pph.." w/ hit)")
		end
	end 
	
	if sumHIT < hitCap then
		-- We are below hit cap, everything counts
		debugPrint("Your current gear setup is not optimal for raiding, you need "..(hitCap - sumHIT).." more hit")
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

	local isEnchanter = false
	local isTailor = false
	local isEngineer = false
	local isLeatherworker = false

	-- Determine the available skills
	for skillIndex = 1, GetNumSkillLines() do
		skillName, isHeader, isExpanded, skillRank, numTempPoints, skillModifier,
		skillMaxRank, isAbandonable, stepCost, rankCost, minLevel, skillCostType,
		skillDescription = GetSkillLineInfo(skillIndex)
		if isHeader == nil then
			if skillName == "Enchanting" then isEnchanter = true end
			if skillName == "Tailoring" then isTailor = true end
			if skillName == "Engineering" then isEngineer = true end
			if skillName == "Leatherworking" then isLeatherworker = true end
		end
	end
		

	if     itemSlot == "INVTYPE_HEAD"		then return "Arcanum of Burning Mysteries", 3820
    elseif itemSlot == "INVTYPE_SHOULDER"	then return "Greater Inscription of the Storm", 3810
    elseif itemSlot == "INVTYPE_CHEST" 		then return "Enchant Chest - Powerful Stats", 3832
    elseif itemSlot == "INVTYPE_ROBE" 		then return "Enchant Chest - Powerful Stats", 3832
    elseif itemSlot == "INVTYPE_WAIST" 		then return "Eternal Belt Buckle", 3729
    elseif itemSlot == "INVTYPE_LEGS" 		then return "Brilliant Spellthread", 3719
    elseif itemSlot == "INVTYPE_FEET" 		then 
    	if isEngineer then return "Nitro Boosts", 3606
    	else return "Enchant Boots - Icewalker", 3826 end
    elseif itemSlot == "INVTYPE_HAND" 		then 
    	if isEngineer then return "Hyperspeed Accelerators", 3604
    	else return "Enchant Gloves - Exceptional Spellpower", 3246 end
    elseif itemSlot == "INVTYPE_FINGER" 	then 
    	if isEnchanter then return "Enchant Ring - Greater Spellpower", 3840 end
    elseif itemSlot == "INVTYPE_CLOAK" 		then 
    	if isTailor then return "Lightweave Embroidery", 3722
    	elseif isEngineer then return "Springy Arachnoweave", 3859
    	else return "Enchant Cloak - Greater Speed", 3831 end
    elseif itemSlot == "INVTYPE_WEAPON" 	then return "Enchant Weapon - Mighty Spellpower", 3855
    elseif itemSlot == "INVTYPE_2HWEAPON" 	then return "Enchant Staff - Greater Spellpower", 3854
    elseif itemSlot == "INVTYPE_WRIST" 		then 
		if isLeatherworker then return "Fur Lining - Spell Power", 3758
    	else return "Enchant Bracers - Superior Spellpower", 2332 end
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
	
	-- Check if the optimal enchant, is the current enchant
	linkEnchant = StatLogic:ModEnchantGem(item, eID)
		
	local optimalString = ""
	if eName then	
		if linkEnchant == item then optimalString = "     "..green..eName.."|r" else 
		   							optimalString = "     "..red..eName.."|r" 
		end	  
	end	
	
	-- Build and determine the better gem option
	unmatchedLink = StatLogic:BuildGemmedTooltip(link, rGem, rGem, rGem, mGem)
	matchedLink  = StatLogic:BuildGemmedTooltip(link, rGem, yGem, bGem, mGem)
	
	-- Check to make sure something actually happened, if we 
	-- actually gemed something, the links wont be the same
	if matchedLink ~= link then
		linkGem = StatLogic:RemoveEnchant(item)
	
		if eName then optimalString = optimalString.."\n" end	 
		local _, upph, _ = GetValue(unmatchedLink)
		local _, mpph, _ = GetValue(matchedLink)	
		if upph >= mpph then 
			link = unmatchedLink
			if linkGem == link then optimalString = optimalString..green else optimalString = optimalString..red end
			optimalString = optimalString.."     All Red Gems"
		else 
			link = matchedLink
			if linkGem == link then optimalString = optimalString..green else optimalString = optimalString..red end 
			optimalString = optimalString.."     Match Sockets"
		end
	end
	
	-- Return the Optimized item
	return link, optimalString

end
	