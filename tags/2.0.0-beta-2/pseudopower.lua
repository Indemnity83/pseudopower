-- $Id$
local VERSION = "2.0.0-beta-2"
local SIM_VER = "403-2"
local SIM_PROFILE = "Priest_Shadow_T11_372"


---------------
-- Libraries --
---------------
local StatLogic = LibStub("LibStatLogic-1.2")
local TipHooker = LibStub("LibTipHooker-1.1")


---------------------
-- Local Variables --
---------------------
local green = "|cff20ff20"
local red = "|cffff2020"
local yellow = "|cFFFFFF00"
local white = "|cffffffff"
local orange = "|cFFFF8000"
local grey = "|cFF888888"


--------------
-- Defaults --
--------------
local PP = {
	["env"] 			= "raid",
	["spellpower"]		= 0.7935,
	["hit"]				= 0.3741,
	["crit"]			= 0.4040,
	["haste"]			= 0.5031,
	["mastery"]			= 0.3857,
	["int"]				= 1.000,
	["spirit"]			= 0.3732,
}

-----------------
-- Options -- 
-----------------
-- TODO: make this SavedVariables
local quality_threshold = 1
local SPELL_POWER = 	PP["spellpower"]
local SPELL_HIT = 		PP["hit"]
local SPELL_CRIT = 		PP["crit"]
local SPELL_HASTE = 	PP["haste"]
local SPELL_MASTERY = 	PP["mastery"]
local BONUS_INT = 		PP["int"]
local BONUS_SPI = 		PP["spirit"]
local HIT_ENV = 		PP["env"]


----------
-- Gems --
----------
local rGemId = 52207 -- Brilliant Inferno Ruby (+40 Int)
local bGemId = 52236 -- Purified Demonseye (+20 Int & +20 Spi)
local yGemId = 52208 -- Reckless Ember Topaz (+20 Int & +20 Haste)
local mGemId = 68780 -- Burning Shadowspirit Diamond (+54 Int & 3% Crit Dmg)

local rGem = StatLogic:GetGemID(rGemId)
local bGem = StatLogic:GetGemID(bGemId)
local yGem = StatLogic:GetGemID(yGemId)
local mGem = StatLogic:GetGemID(mGemId)


---------------------
-- Command Handler --
---------------------
SLASH_PP1, SLASH_PP2 = '/pp', '/pseudopower'
function SlashCmdList.PP(msg, editbox)
	local command, rest = msg:match("^(%S*)%s*(.-)$")
	
	if command == "version" then 
		-- Display version
		DEFAULT_CHAT_FRAME:AddMessage("Pseudopower "..VERSION.." ("..SIM_VER.." "..SIM_PROFILE..")", 1, 1, 0);
	elseif command == "about" then 
		-- Display version
		DEFAULT_CHAT_FRAME:AddMessage("Pseudopower "..VERSION.." ("..SIM_VER.." "..SIM_PROFILE..")", 1, 1, 0);
	elseif command == "show" then 
		-- Display total Pseeudopower
		local ppsum = GetPPScore()
		DEFAULT_CHAT_FRAME:AddMessage("Total pseudopower "..ppsum, 1, 1, 0);
	elseif command == "env" then
		-- Display/Set Environment
		if rest == "raid" then HIT_ENV="raid"
		elseif rest == "pve" then HIT_ENV="pve" end
		DEFAULT_CHAT_FRAME:AddMessage("Pseudopower environment is "..HIT_ENV)
	elseif command == "qt" then
		-- Display/Set quality threashold
		if tonumber(rest) ~= nil then quality_threashold = rest end
		DEFAULT_CHAT_FRAME:AddMessage("Pseudopower quality threshold is "..quality_threashold)
	elseif command == "spellpower" then
		-- Display/Set spellpower scaling factor
		if tonumber(rest) ~= nil then SPELL_POWER=rest end
		if reset=="reset" then SPELL_POWER=PP["spellpower"] end
		DEFAULT_CHAT_FRAME:AddMessage("Pseudopower spell power scale factor is "..SPELL_POWER)
	elseif command == "hit" then
		-- Display/Set hit rating scaling factor
		if tonumber(rest) ~= nil then SPELL_HIT=rest end
		if reset=="reset" then SPELL_HIT=PP["hit"] end
		DEFAULT_CHAT_FRAME:AddMessage("Pseudopower spell hit scale factor is "..SPELL_HIT)	
	elseif command == "hitcap" then
		-- Display current hitcap information
		hitCap, hitSum = HitCap()
		DEFAULT_CHAT_FRAME:AddMessage("You need "..hitCap.." hit for the current environment. You currently have "..hitSum)	
	else
		-- Display usage
		DEFAULT_CHAT_FRAME:AddMessage("Usage: /pp command [options]") 	
		DEFAULT_CHAT_FRAME:AddMessage("Commands:") 	
		DEFAULT_CHAT_FRAME:AddMessage("    env [raid/pve] - Weigh hit for raids, or general PVE")	
		DEFAULT_CHAT_FRAME:AddMessage("    help - This help text")
		DEFAULT_CHAT_FRAME:AddMessage("    hit (value) - Display/set hit rating scaling factor")
		DEFAULT_CHAT_FRAME:AddMessage("    hitcap - Get information about your current hit cap")
		DEFAULT_CHAT_FRAME:AddMessage("    show - Output the total current Pseudopower")
		DEFAULT_CHAT_FRAME:AddMessage("    spellpower (value) - Display/set spellpower scaling factor")
		DEFAULT_CHAT_FRAME:AddMessage("    version - Show verbose version information")		
	end			
end

---------------------
-- Item Filtering ---
---------------------
local function isUsable( Item )
	class, subclass = select(6, GetItemInfo( Item ))
	
	if class == "Weapon" then 		
		if 	subclass == "One-Handed Maces" or 
			subclass == "Staves" or
			subclass == "Daggers" or
			subclass == "Wands"
		then return true end
	elseif class == "Armor" then 	
		if 	subclass == "Miscellaneous" or 
			subclass == "Cloth"
		then return true end
	elseif class == "Gem" then 
		return true
	else					
		-- Everything Else
		return false
	end
	
end

-------------------
-- Toptip Script --
-------------------
local function OnTooltipSetItem(self)
	local _, Item = self:GetItem()
	local _, _, itemQuality, _, _, _, _, _, _ = GetItemInfo(Item)
	if Item and itemQuality > quality_threshold and isUsable(Item) then
 		local pp, pph, _ = GetValue(Item)
		if pp then		
			-- Show optimizations
			self:AddLine(" ")
			
			-- Hit value hilight color
			hitCap, hitSum = HitCap()
			if (hitCap - hitSum) > 0 then hilight = orange else hilight = grey end
		 		
 			-- Display the PseudoPower of the item as-is
 			if pp then
 				if pph > pp then 
 					self:AddLine(white.."PseudoPower "..pp..hilight.." ("..pph..")")
 				else 
     				self:AddLine(white.."PseudoPower "..pp)
     			end
			end
			
			-- Display the optimal PseudoPower
			local optimalItem, optimalString = OptimalItem(Item)
			local opp, opph, _ = GetValue(optimalItem)
			
			-- Hack for Eternal Belt Buckle
			local _,_,_,_,_,_,_,_,ItemSlot = GetItemInfo(Item)
			if ItemSlot == "INVTYPE_WAIST" then opp = opp + 23 end	
			
			if opp > pp then					
				if opph > opp then
					self:AddLine(white.."Optimal PseudoPower "..opp..hilight.." ("..opph..")")
				else
	     			self:AddLine(white.."Optimal PseudoPower "..opp)		
	        	end
				
				-- Show optimizations
				self:AddLine(optimalString)		
			end
			
			-- repaint tooltip
			self:Show()
		end
	end
end


----------------------
-- Add tooltip hook --
----------------------
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

-------------
-- Hit Cap --
-------------
function HitCap()

	-- Cata formula hasn't been derived yet, so we need these scaling factors
	local scale = {
		[81] = 34.44481,
		[82] = 45.2318,
		[83] = 59.42037,
		[84] = 78.02179,
		[85] = 102.44574,
	}
	
	local level = UnitLevel("player")
	local race = UnitClass("player")
	local ratingBase = 8

	-- basic percent hit required for each environment
	if HIT_ENV == "raid" then pctHit = 17 end
	if HIT_ENV == "pve" then pctHit = 4 end
	
	-- Race bonuses
	if race == "Draenei" then pctHit = pctHit - 1 end 
	if race == "Human" then pctHit = pctHit - 3 end
	
	-- Level 1-10
	if level <= 10 then rating = pctHit * ratingBase * ( 2 / 52 )

	-- Level 11-60
    elseif level <= 60 then rating = pctHit * ratingBase * ((level - 8) / 52)
        
	-- Level 61-70
	elseif level <= 70 then rating = pctHit * ratingBase * (82 / (262 - 3 * level))
	
	-- Level 71-80
	elseif level <= 80 then rating = pctHit * ratingBase * ((82/52) * math.pow((131/63),((level - 70)/10)));
	
	-- Level 81-85
	else rating = pctHit * scale[level] end
	
	-- Get current Hit
	local sumHIT = 0
	for i=1,18 do
		local itemLink = GetInventoryItemLink("player", i)
		if (itemLink) then
			local _, _, hit = GetValue(itemLink)
			sumHIT = sumHIT + hit
		end
	end 
	
	hitcap = math.ceil(rating)
	return hitcap, sumHIT
end

--------------------------------
-- Calculate PP and PPH value --
--------------------------------
function GetValue(item)
	if not item then return end
	
	local _, itemLink, rarity, _, _, _, _, _, itemSlot = GetItemInfo(item)
	if not itemLink then return end
	
	-- Get the item ID to check against custom data
	local itemID = itemLink:match("item:(%d+)")
	if not itemID then return end
	itemID = tonumber(itemID)

	local statData = {}
	
	if CUSTOM_ITEM_DATA[itemID] then
		-- Use custom data for this item ID
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
	if (statData["MASTERY_RATING"]) then pp = pp + statData["MASTERY_RATING"] * SPELL_MASTERY end
	
	-- TODO: Find a better method for adding a red gem to an Eternal Belt Buckle
	if itemSlot == "INVTYPE_WAIST" then 
		local testItem = StatLogic:ModEnchantGem(3729)
		if testItem == itemLink then
			-- Appears to have a belt buckle, hack in a red gem
			rGemValue = GetValue(rGemId)
			pp = pp + rGemValue
		end		
	end
	
	-- Do the final calculation including Hit (spirit is now only a hit stat for spellcasters)
	local pph = pp
	if (statData["SPELL_HIT_RATING"]) then pph = pph + statData["SPELL_HIT_RATING"] * SPELL_HIT end
	if (statData["SPI"]) then pph = pph + statData["SPI"] * BONUS_SPI end

	-- Set the hit to a variable
	local hit = 0
	if (statData["SPELL_HIT_RATING"]) then hit = hit + statData["SPELL_HIT_RATING"] end
	if (statData["SPI"]) then hit = hit + statData["SPI"] end
		
	return math.ceil(pp), math.ceil(pph), math.ceil(hit)
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
	local hitCap = HitCap()
	
	for i=1,18 do
		local itemLink = GetInventoryItemLink("player", i)
		if (itemLink) then
			local pp, pph, hit = GetValue(itemLink)
			
			sumPP = sumPP + pp
			sumPPH = sumPPH + pph
			sumHIT = sumHIT + hit
		end
	end 
	
	if sumHIT < hitCap then
		-- We are below hit cap, everything counts
		return math.ceil(sumPPH)
	else
		-- We are at or above the hit cap, so we need to calculate the PP and ignore
		-- any hit above the hitcap (since its useless)
		sumPP = sumPP + (hitCap * SPELL_HIT)
		return math.ceil(sumPP)
	end	
end


--------------------------
-- Returns BIS enchants --
--------------------------
function OptimalEnchant( item )

	local _,_,_,_,_,_,_,_,itemSlot = GetItemInfo( item )

	local isEnchanter = false
	local isTailor = false
	local isEngineer = false
	local isScribe = false
	local isLeatherworker = false

	-- Determine the available skills
	prof1, prof2 = GetProfessions()	
	
	if prof1 ~= nil then 
		skillName = GetProfessionInfo(prof1)
		if skillName == "Enchanting" then isEnchanter = true end
		if skillName == "Tailoring" then isTailor = true end
		if skillName == "Inscription" then isScribe = true end
		if skillName == "Engineering" then isEngineer = true end
		if skillName == "Leatherworking" then isLeatherworker = true end
	end
	
	if prof2 ~= nil then 
		skillName = GetProfessionInfo(prof2)
		if skillName == "Enchanting" then isEnchanter = true end
		if skillName == "Tailoring" then isTailor = true end
		if skillName == "Inscription" then isScribe = true end
		if skillName == "Engineering" then isEngineer = true end
		if skillName == "Leatherworking" then isLeatherworker = true end
	end

	if     itemSlot == "INVTYPE_HEAD"		then return "Arcanum of Hyjal", 4207
    elseif itemSlot == "INVTYPE_SHOULDER"	then 
		if isScribe then return "Felfire Inscription", 4196
		else return "Greater Inscription of Charged Lodestone", 4200 end
    elseif itemSlot == "INVTYPE_ROBE" 		then return "Enchant Chest - Peerless Stats", 4102
	elseif itemSlot == "INVTYPE_WAIST" 		then return "Ebonsteel Belt Buckle + Red Gem", 3729
    elseif itemSlot == "INVTYPE_LEGS"       then return "Powerful Ghostly Spellthread", 4110    
    elseif itemSlot == "INVTYPE_FEET" 		then return "Enchant Boots - Haste", 4069
    elseif itemSlot == "INVTYPE_HAND" 		then 
    	if isEngineer then return "Synapse Springs", 4179
    	else return "Enchant Gloves - Greater Mastery", 4107 end
    elseif itemSlot == "INVTYPE_FINGER" 	then 
    	if isEnchanter then return "Enchant Ring - Intellect", 4080 end
    elseif itemSlot == "INVTYPE_CLOAK" 		then 
    	if isTailor then return "Lightweave Embroidery (Rank 2)", 4115
    	else return "Enchant Cloak - Greater Intellect", 4096 end
    elseif itemSlot == "INVTYPE_WEAPONMAINHAND" 	then return "Enchant Weapon - Power Torrent", 4097
    elseif itemSlot == "INVTYPE_2HWEAPON" 	then return "Enchant Weapon - Power Torrent", 4097
	elseif itemSlot == "INVTYPE_HOLDABLE" 	then return "Enchant Off-Hand - Superior Intellect", 4091
    elseif itemSlot == "INVTYPE_WRIST" 		then 
		if isLeatherworker then return "Draconic Embossment - Intellect", 4192
    	else return "Enchant Bracers - Mighty Intellect", 4257 end
	else									 return nil, 0	
	end

end 

----------------------------
-- Returns Optimized Gems --
----------------------------
-- TODO: Optimize! This function is fairly ineffecient and highly static
function OptimalGems( item )
	
	-- Build an item with all red gems, and one with matched sockets
	redGems = StatLogic:BuildGemmedTooltip( item, rGem, rGem, rGem, mGem )
	matchedGems  = StatLogic:BuildGemmedTooltip( item, rGem, yGem, bGem, mGem )
	
	-- If there was no change, the item doesn't have sockets
	if item == redGems and item == matchedGems then return nil, 0, 0, 0, 0 end 
	
	-- Do the fairly expensive valuation of each gem option
	local ppRedGems = GetValue( redGems )
	local ppMatchedGems = GetValue( matchedGems )
	
	-- Return the best option
	if ppRedGems >= ppMatchedGems then 
		return "All Red Gems", rGem, rgem, rgem, mGem
	else 
		return "Match Sockets", rGem, ygem, bgem, mGem
	end
	
end


--------------------
-- Optimize Item ---
--------------------
function OptimalItem( existingItem )

	-- Establish our local variables
	local baseItem = StatLogic:RemoveEnchantGem( existingItem )
	local existingEnchant = StatLogic:RemoveGem( existingItem )
	local existingGems = StatLogic:RemoveEnchant( existingItem )
	local optimizations = ""
	
	-- BIS enchant	
	local enchantName, enchantID = OptimalEnchant( baseItem )
	local optimalEnchant = StatLogic:ModEnchantGem( baseItem, enchantID )
	
	-- Optimal gems
	local gemTooltip, gemRed, gemYellow, gemBlue, gemMeta = OptimalGems( baseItem )
	local optimalGems = StatLogic:ModEnchantGem( baseItem, 0, gemRed, gemYellow, gemBlue, gemMeta )
	
	-- Build our optimal item
	optimalItem = StatLogic:ModEnchantGem( baseItem, enchantID, gemRed, gemYellow, gemBlue, gemMeta )
	
	-- Build the optimizations list
	if existingEnchant == optimalEnchant then enchantHighlight = green else enchantHighlight = red end
	if existingGems ==  optimalGems then gemHighlight = green else gemHighlight = red end
	if enchantName then optimizations = "     "..enchantHighlight..enchantName.."|r" end
	if enchantName and gemTooltop then optimizations = optimizations .. "\n" end
	if gemTooltip then optimizations = "     "..gemHighlight..gemTooltip.."|r" end
	
	-- TODO: Reforge stats	
	
	-- Return the Optimized item
	return optimalItem, optimizations

end