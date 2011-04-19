-- $Id$

local VERSION = "2.0.0-beta"
local SIM_VER = "403-2"
local SIM_PROFILE = "Priest_Shadow_T11_372"

---------------
-- Libraries --
---------------
local StatLogic = LibStub("LibStatLogic-1.2")
local TipHooker = LibStub("LibTipHooker-1.1")
local Who = LibStub('LibWho-2.0')

---------------------
-- Local variables --
---------------------
local DEBUG = true
local quality_threshold = 1
local green = "|cff20ff20"
local red = "|cffff2020"
local yellow = "|cFFFFFF00"
local white = "|cffffffff"

--------------------
-- Config Options --
--------------------
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
-- Multiplyers -- 
-----------------
-- TODO: make this SavedVariables
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
		hitCap, hitBal = HitCap()
		DEFAULT_CHAT_FRAME:AddMessage("You need "..hitCap.." hit for the current environment. Your balance is "..hitBal)	
	elseif command == "help" then
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
	else 
		-- Command missing/error, display usage
		DEFAULT_CHAT_FRAME:AddMessage("Usage: /pp command [options]", 1, 1, 0) 			
		DEFAULT_CHAT_FRAME:AddMessage("       /pp help (for more information)", 1, 1, 0) 			
	end			
end


-------------------
-- Toptip Script --
-------------------
local function OnTooltipSetItem(self)
	local _, Item = self:GetItem()
	local _, _, rarity, _, _, _, _, _, _ = GetItemInfo(Item)
	if Item and rarity > quality_threshold then
 		local pp, pph, _ = GetValue(Item)
		if pp then		
			-- Show optimizations
			self:AddLine(" ")
			
			-- Hit value hilight color
			_, hitBal = HitCap()
			if hitBal > 0 then hilight = "|cFFFF8000" else hilight = "|cFF888888" end
		 		
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

-------------
-- Hit Cap --
-------------
function HitCap()
	local scale = {
		[80] = 26.232,
		[81] = 34.445,
		[82] = 45.231,
		[83] = 59.420,
		[84] = 78.022,
		[85] = 102.446,
	}
	
	local level = UnitLevel("player")
	local race = UnitClass("player")
	local sumHIT = 0
	
	-- Base hit for raid and pve situtions
	if HIT_ENV == "raid" then base_hit = 83	end
	if HIT_ENV == "pve" then base_hit = 96 end
	
	-- Dranai with [Heroic Presence]
	if race == "Draenei" then base_hit = base_hit + 1 end 
	
	-- Get current Hit
	for i=1,18 do
		local itemLink = GetInventoryItemLink("player", i)
		if (itemLink) then
			local _, _, hit = GetValue(itemLink)
			sumHIT = sumHIT + hit
		end
	end 
	
	hitcap = math.ceil((100 - base_hit) * scale[level])
	balance = hitcap - sumHIT
	return hitcap, balance
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
	if (statData["SPELL_HIT_RATING"]) then hit = statData["SPELL_HIT_RATING"] end
		
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
			
			--debugPrint(itemLink.." "..pp.." ("..pph.." w/ hit)")
		end
	end 
	
	if sumHIT < hitCap then
		-- We are below hit cap, everything counts
		--debugPrint("Your current gear setup is not optimal for raiding, you need "..(hitCap - sumHIT).." more hit")
		return math.ceil(sumPPH)
	else
		-- We are at or above the hit cap, so we need to calculate the PP and ignore
		-- any hit above the hitcap (since its useless)
		sumPP = sumPP + (hitCap * SPELL_HIT)
		return math.ceil(sumPP)
	end	
end


----------------------------------------
-- Returns the best enchants per slot --
----------------------------------------
function OptimalEnchant(itemSlot)

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
	
	-- Reforge stats (if prudent)
	
	
	-- Return the Optimized item
	return link, optimalString

end