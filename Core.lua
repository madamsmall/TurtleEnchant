----------------------------------------------------------------------------------------------------
-- TurtleEnchant by Madamsmall
--
-- Sorting/Filtering can be done by Enchant Target type or Enchantment Bonus type
----------------------------------------------------------------------------------------------------

-- Define our main class object
TurtleEnchant = AceLibrary("AceAddon-2.0"):new("AceDB-2.0", "AceEvent-2.0", "AceHook-2.0", "AceConsole-2.0", "AceDebug-2.0");

-- Define libraries we will be using
local Dewdrop = AceLibrary("Dewdrop-2.0");
local Compost = AceLibrary("Compost-2.0");

--Grab the database of translations for the current spec
local L = AceLibrary("AceLocale-2.1"):GetInstance("TurtleEnchant", true);

--Register our database with AceDB
TurtleEnchant:RegisterDB("TurtleEnchantDB");

--Register default settings
TurtleEnchant:RegisterDefaults("profile", {		
		Sort     = L.Bonus
});

----------------------------------------------------------------------------------------------------
-- Addon Initializing/Enabling/Disabling
----------------------------------------------------------------------------------------------------
function TurtleEnchant:OnInitialize()
	--Define a debug level to a level that does not completly spam the user with stuff from us
	self:SetDebugLevel(1);
	
	self.ArmorSubTypes = {
		INVTYPE_FEET = 1,
		INVTYPE_WRIST = 2,
		INVTYPE_ROBE = 3,
		INVTYPE_CHEST = 3,
		INVTYPE_CLOAK = 4,
		INVTYPE_HAND = 5,
		INVTYPE_SHIELD = 6
	};

	--Define the header displays, which are the text shown for the groupings
	self.HeaderDisplay = {
		[L.Armor] = {
			L.ArmorBoots,			--1
			L.ArmorBracer,			--2
			L.ArmorChest,			--3
			L.ArmorCloak,			--4
			L.ArmorGloves,			--5
			L.ArmorShield,			--6
			L.ArmorWeapon,			--7
			L.ArmorOils,			--8
			L.ArmorWands,			--9	
			L.ArmorProfs,			--10
			L.ArmorRods,			--11
			L.ArmorOther,			--12
			n = 12
		},

		[L.Bonus] = {
			L.BonusAgility, 		--1			
			L.BonusIntellect, 		--2
			L.BonusSpirit,			--3
			L.BonusStamina,			--4
			L.BonusStrength,		--5
			L.BonusDefense,			--6
			L.BonusArmor,			--7
			L.BonusSpellPower,		--8
			L.BonusVamp,			--9
			L.BonusHealth,			--10
			L.BonusMana,			--11
			L.BonusStats,			--12
			L.BonusResistance,		--13		
			L.BonusSpeed,			--14
			L.BonusDamage,			--15			
			L.BonusSpecialty,		--16
			L.BonusProc,			--17			
			L.BonusOils,			--18			
			L.BonusWands,			--19
			L.BonusRods,			--20		 
			L.BonusProf,			--21 
			L.BonusReag,			--22
			L.BonusMisc,			--23
			n = 23
		},
	}
			
	--Setup our regex for finding enchantment id
	self.EnchantRegex = "|c%x+|Henchant:(%d+)|h%[.*%]|h|r";
	self.ItemRegex    = "|c%x+|H(item:%d+:%d+:%d+:%d+)|h%[.*%]|r";

	--Setup our default user enchant database as an empty one, to ensure all of the erase commands work properly
	self.UserEnchantDB = Compost:AcquireHash("IsInvalidated", true, "IsCollapsed", Compost:Acquire());

	--Setup our chat command interface
	self:RegisterChatCommand({"/te", "/madam", "/turtleenchant"},
		{
			type = "group",
			args = {				
				sort = {
					type = "text",
					name = L.Sort,
					desc = L.SortDesc,
					get = function() return self.db.profile.Sort end,
					set = function(value) self.db.profile.Sort = value; self.UserEnchantDB.IsCollapsed = Compost:Recycle(self.UserEnchantDB.IsCollapsed); self:UpdateCraftFrame() end,
					validate = {L.Armor, L.Bonus}
				}
			}
		},
		"TURTLEENCHANT"
	);

	self:LevelDebug(1, "TurtleEnchant has been Initialized");
end

function TurtleEnchant:OnEnable()
	-- Don't enable this addon at all if the enchanting skill is not present
	if not self:CheckSkill() then
		self:LevelDebug(1, "Enchanting skill not found, disabling TurtleEnchant");
		return;
	end

	--Reset our saved data if it is from the old version of TurtleEnchant
	if (not self.db.profile.Sort) then
		self:ResetDB("profile");
	end

	--Catch the event that tell us when something in the Enchanting window changes
	--This event also triggers whenever the window is opened, so we need not worry
	--About any other events
	self:RegisterEvent("CRAFT_UPDATE");

	--Catch the profile change event so we can close the GUI to ensure it is updated
	self:RegisterEvent("ACE_PROFILE_LOADED", "UpdateCraftFrame");

	--Hook into all the functions we will be using
	self:Hook("GetNumCrafts");
	self:Hook("GetCraftInfo");
	self:Hook("ExpandCraftSkillLine");
	self:Hook("CollapseCraftSkillLine");
	self:Hook("SelectCraft");
	
	self:Hook("GetCraftSelectionIndex");
	self:Hook("DoCraft");
	self:Hook("GetCraftIcon");
	self:Hook("GetCraftDescription");
	self:Hook("GetCraftNumReagents");
	self:Hook("GetCraftReagentInfo");
	self:Hook("GetCraftSpellFocus");
	self:Hook("GetCraftItemLink");
	self:Hook("GetCraftReagentItemLink");
	self:Hook(GameTooltip, "SetCraftItem", "TooltipSetCraftItem");
	self:Hook(GameTooltip, "SetCraftSpell", "TooltipSetCraftSpell");

	self:UpdateCraftFrame();

	self:CreateSearchBox(CraftFrame);
	self:CreateSortDewdrop(CraftFrame);
	self:PositionCollapseAllButton();

	self:LevelDebug(1, "TurtleEnchant has been Enabled");
end

function TurtleEnchant:OnDisable()
	--Refresh the craft frame to ensure it picks up its new data
	self:UpdateCraftFrame();

	self:LevelDebug(1, "TurtleEnchant has been Disabled");
end

----------------------------------------------------------------------------------------------------
-- Event Processing
----------------------------------------------------------------------------------------------------
function TurtleEnchant:PositionCollapseAllButton()
	-- Bring collapse all button to front and widen it so it's easier to click
	if CraftCollapseAllButton then
		CraftCollapseAllButton:SetFrameLevel(50);
		CraftCollapseAllButton:SetWidth(50);
	end
end
function TurtleEnchant:UpdateCraftFrame()
	--Make the CraftFrame update itself it has not yet
	if CraftFrame and CraftFrame:IsVisible() then
		--Recreate all data, to ensure nothing changed that we did not track
		if self.IsEnabled then
			self:CreateUserEnchantDB();
		end
		CraftFrame_Update();			
	end
end

function TurtleEnchant:CRAFT_UPDATE()
	self:LevelDebug(2, "CRAFT_UPDATE event fired, invalidating data");
	--Invalidate our db to ensure it is not wrongfully used
	self.UserEnchantDB.IsInvalidated = true;		
end

----------------------------------------------------------------------------------------------------
-- User Enchant DB functions
----------------------------------------------------------------------------------------------------
--Recreate our temporary data from scratch
function TurtleEnchant:CreateUserEnchantDB()
	self:LevelDebug(2, "Creating the UserEnchantDB");
	--Clear out the invalidated flag, this is not part of any of the bottom databases
	self.UserEnchantDB.IsInvalidated = false;
	--Clear all of our databases, to ensure that we start fresh
	Compost:Reclaim(self.UserEnchantDB.AllEnchants);
	self.UserEnchantDB.AllEnchants = Compost:AcquireHash("n", 0);
	Compost:Reclaim(self.UserEnchantDB.CurrentList);
	self.UserEnchantDB.CurrentList = Compost:AcquireHash("n", 0);

	local EnchantValue;
	local EnchantId;

	--Insert the type tables of all of the user's enchants into the AllEnchants table
	for i = 1, self.hooks.GetNumCrafts.orig() do
		EnchantId = gsub(self.hooks.GetCraftItemLink.orig(i), self.EnchantRegex, "%1");
		EnchantValue = self.EnchantDB[tonumber(EnchantId, 10)];
		if EnchantValue then
			tinsert(self.UserEnchantDB.AllEnchants, EnchantValue);
		else
			self:Print("Could not find value " .. EnchantId .. " which is part of " .. self.hooks.GetCraftItemLink.orig(i) .. " please contact the author with these details.");
		end
	end

	--Now our basic data has been setup
	--Call the type select function to set up the actual data for the settings the user has chosen
	local SubTables = Compost:AcquireHash("n", self.HeaderDisplay[self.db.profile.Sort].n);
	--Define an insert function which avoids nil reference errors
	SubTables.insert = function(self, i, data) if not self[i] then self[i] = Compost:AcquireHash("n", 0); end; tinsert(self[i], data); end;
	local craftData;

	for i = 1, self.UserEnchantDB.AllEnchants.n do
		--Create a table with the data for the current enchant in it
		craftData = Compost:Acquire(self.hooks.GetCraftInfo.orig(i));
		craftData.gameId = i;

		--Only add the data to the sub table if it is visible
		if self:IsVisible(craftData) then
			--Add that data to the appropriate sub table
			if self.db.profile.Sort == L.Armor then
				if not self.UserEnchantDB.AllEnchants[i] then
					self:Print(i);
				end
				SubTables:insert(self.UserEnchantDB.AllEnchants[i].armor, craftData);
			elseif self.db.profile.Sort == L.Bonus then
				SubTables:insert(self.UserEnchantDB.AllEnchants[i].bonus, craftData);						
			else
				self:LevelDebug("Unknown Sort setting " .. self.db.profile.Sort .. " reseting to Bonus", 2);
				self.db.profile.Sort = L.Bonus;
				tinsert(self.UserEnchantDB.CurrentList, craftData);
			end
		end
	end

	local tableExpanded;

	--Convert our sub tables into the final current list that is used to communicate with the craft frame
	for i = 1, SubTables.n do
		if SubTables[i] then
			tinsert(self.UserEnchantDB.CurrentList,{self.HeaderDisplay[self.db.profile.Sort][i], "", "header", 0, not self.UserEnchantDB.IsCollapsed[i], 0, 0, headerId = i});
			if not self.UserEnchantDB.IsCollapsed[i] then
				for j = 1, SubTables[i].n do
					tinsert(self.UserEnchantDB.CurrentList, SubTables[i][j]);
				end
			end
		end
	end

	--Note this should be 1 and not 2 as would be intuitive, this is because the lowest layer (CraftData) is used as a table outside
	--Of this function, and should be left alone
	Compost:Reclaim(SubTables, 1);

	--Just to be safe, nil out the refence to the table
	SubTables = nil;
end

--Grabs the inverse of the value stored in memory, because that is the way it is stored there
function TurtleEnchant:TableExpanded(tableIndex)
	return not self.UserEnchantDB.IsCollapsed[tableIndex];
end

--Checks if the item should be visible, using dropdowns and searchBox
function TurtleEnchant:IsVisible(craftData)
 	local filter = self:GetSearchFilter()  
    local name = craftData[1];
	if not filter or strfind(strlower(name), filter, 1, true) then
            return true;
        else
            -- filtered out
			return false;
        end    
	--If we got this far, there is nothing to stop the item from being displayed
	return true;
end

----------------------------------------------------------------------------------------------------
-- Misc functions
-- Used by other functions for repeated sets of code
----------------------------------------------------------------------------------------------------
function TurtleEnchant:CheckSkill()
	--Simply return the first value from this function, as it will be a string in the case of the
	--Enchanting window, or nil in the case of the Beast Training window
	return (GetCraftDisplaySkillLine())
end

function TurtleEnchant:VerifyUserEnchantDB()
	if self.UserEnchantDB.IsInvalidated then
		self:CreateUserEnchantDB();
	end
end
----------------------------------------------------------------------------------------------------
-- Hooking functions
-- Note that any complicated functions should move the hardest code to another function in the class
-- To make this section as simple as possible (Due to its extreme size)
--
-- A note about why these are being hooked:
-- We are replacing the default return values of a list of items with our own specially formatted
-- List of values, so whenever we call the Blizzard API, we need to overwrite the default value
-- With our own
--
-- Quick note about things that are pretty standard across functions
-- Always check title of display to ensure we are not in the pet window, which uses the same frame
--
-- Note to myself:
-- Need to organize these in some more logical fashion
----------------------------------------------------------------------------------------------------
--------------------------------------------------
-- Overall functions, return basic data
-- Hooked to return data we have instead
--------------------------------------------------
function TurtleEnchant:GetNumCrafts()
	self:LevelDebug(3, "GetNumCrafts called");
	if not self:CheckSkill() then return self.hooks.GetNumCrafts.orig(); end
	self:VerifyUserEnchantDB();

	--The n only references integer indexed variables, so it gives how
	--Many enchantments we want the GUI to worry about
	return self.UserEnchantDB.CurrentList.n;
end

function TurtleEnchant:GetCraftInfo(id)
	self:LevelDebug(3, "GetCraftInfo called");
	if not self:CheckSkill() then return self.hooks.GetCraftInfo.orig(id); end
	self:VerifyUserEnchantDB();

	--Simply grab the cache we have for the requested item
	if not self.UserEnchantDB.CurrentList[id] then
		return nil;
	else
		return self.UserEnchantDB.CurrentList[id][1], self.UserEnchantDB.CurrentList[id][2], self.UserEnchantDB.CurrentList[id][3],
				self.UserEnchantDB.CurrentList[id][4], self.UserEnchantDB.CurrentList[id][5], self.UserEnchantDB.CurrentList[id][6],
				 self.UserEnchantDB.CurrentList[id][7];
	end
end

--------------------------------------------------
-- Expansion code, change expanded/contracted for
-- Various headers, not supported in default
-- Enchanting environment, so we support them here
--------------------------------------------------
function TurtleEnchant:ExpandCraftSkillLine(id)
	self:LevelDebug(2, "ExpandCraftSkillLine called, id = " .. id);
	if not self:CheckSkill() then return self.hooks.ExpandCraftSkillLine.orig(id); end
	self:VerifyUserEnchantDB();

	self:LevelDebug(2, "Trying to expand with id: " .. id);

	--If they pressed the ExpandAll button, expand all catgories
	if id == 0 then
		--Empty the table, this will ensure they all count as collapsed now
		self.UserEnchantDB.IsCollapsed = Compost:Erase(self.UserEnchantDB.IsCollapsed);
	else
		--Clear the flag for the selected variable
		self.UserEnchantDB.IsCollapsed[self.UserEnchantDB.CurrentList[id].headerId] = false;
	end

	--Recreate our db from scratch
	self:CreateUserEnchantDB();

	--Causes the window to be refreshed with new settings
	self:UpdateCraftFrame();
end

function TurtleEnchant:CollapseCraftSkillLine(id)
	self:LevelDebug(2, "CollapseCraftSkillLine called id = " .. id);
	if not self:CheckSkill() then return self.hooks.CollapseCraftSkillLine.orig(id); end
	self:VerifyUserEnchantDB();

	--Set the flag for the selected variable
	if id == 0 then
		--self.Locale.DISPLAY holds the number of total categories
		for i = 1, self.HeaderDisplay[self.db.profile.Sort].n do
			self.UserEnchantDB.IsCollapsed[i] = true;
		end
	else
		self.UserEnchantDB.IsCollapsed[self.UserEnchantDB.CurrentList[id].headerId] = true;
	end

	--Redo the visible portion of our temporary data
	self:CreateUserEnchantDB();
	--Causes the window to be refreshed with new settings
	self:UpdateCraftFrame();
end

--------------------------------------------------
-- Selection code, these set the selection in our
-- Database instead of the game's
--------------------------------------------------
function TurtleEnchant:SelectCraft(id)
	self:LevelDebug(3, "SelectCraft called");
	if not self:CheckSkill() then return self.hooks.SelectCraft.orig(id); end

	--Store the new selection
	self.Selected = id;

	--Clear any hidden selection we have
	self.HiddenSelection = nil;
end

--Selects a skill by its name, returns whether the operation succeded or not
function TurtleEnchant:SelectCraftByName(craftName)
	self:LevelDebug(2, "SelectCraftByName called name = " .. craftName);
	--Don't need to check header, as only our functions will call this
	for i = 1, self.UserEnchantDB.CurrentList.n do
		if self.UserEnchantDB.CurrentList[i][1] == craftName then
			--Found the item, select it, use the GUI to ensure it catches up too
			CraftFrame_SetSelection(i);
			return TRUE;
		end
	end

	--Could not find the item in our GUI list
	return FALSE;
end


function TurtleEnchant:GetCraftSelectionIndex()
	self:LevelDebug(3, "GetCraftSelectionIndex called");
	if not self:CheckSkill() then return self.hooks.GetCraftSelectionIndex.orig(); end

	--Simply retrieve the stored selection
	return self.Selected;
end

--------------------------------------------------
-- Get functions, these get data about the
-- Currently selected index, we must supply the
-- Real gameId to the sub functions for these
--------------------------------------------------
function TurtleEnchant:DoCraft(id)
	self:LevelDebug(2, "DoCraft called id = " .. id);
	if not self:CheckSkill() then return self.hooks.DoCraft.orig(id); end
	self:VerifyUserEnchantDB();
	
	--If we have a selection that is not on screen, use it
	if self.HiddenSelection and not id then
		if self.HiddenSelection.gameId then
			return self.hooks.DoCraft.orig(self.HiddenSelection.gameId);
		else
			return;
		end
	else --Otherwise, use the Selected index
		if self.UserEnchantDB.CurrentList[id].gameId then
			return self.hooks.DoCraft.orig(self.UserEnchantDB.CurrentList[id].gameId);
		else
			return;
		end
	end
end

function TurtleEnchant:GetCraftIcon(id)
	self:LevelDebug(3, "GetCraftIcon called");
	if not self:CheckSkill() then return self.hooks.GetCraftIcon.orig(id); end
	self:VerifyUserEnchantDB();
	
	--If we have a selection that is not on screen, use it
	if self.HiddenSelection and not id then
		if self.HiddenSelection.gameId then
			return self.hooks.GetCraftIcon.orig(self.HiddenSelection.gameId);
		else
			return;
		end
	else --Otherwise, use the Selected index
		if self.UserEnchantDB.CurrentList[id].gameId then
			return self.hooks.GetCraftIcon.orig(self.UserEnchantDB.CurrentList[id].gameId);
		else
			return;
		end
	end
end

function TurtleEnchant:GetCraftDescription(id)
	self:LevelDebug(3, "GetCraftDescription called");
	if not self:CheckSkill() then return self.hooks.GetCraftDescription.orig(id); end
	self:VerifyUserEnchantDB();
	
	--If we have a selection that is not on screen, use it
	if self.HiddenSelection and not id then
		if self.HiddenSelection.gameId then
			return self.hooks.GetCraftDescription.orig(self.HiddenSelection.gameId);
		else
			return;
		end
	else --Otherwise, use the Selected index
		if self.UserEnchantDB.CurrentList[id].gameId then
			return self.hooks.GetCraftDescription.orig(self.UserEnchantDB.CurrentList[id].gameId);
		else
			return;
		end
	end
end

function TurtleEnchant:GetCraftNumReagents(id)
	self:LevelDebug(3, "GetCraftNumReagents called");
	if not self:CheckSkill() then return self.hooks.GetCraftNumReagents.orig(id); end
	self:VerifyUserEnchantDB();
	
	--If we have a selection that is not on screen, use it
	if self.HiddenSelection and not id then
		if self.HiddenSelection.gameId then
			return self.hooks.GetCraftNumReagents.orig(self.HiddenSelection.gameId);
		else
			return 0;
		end
	else --Otherwise, use the Selected index
		if self.UserEnchantDB.CurrentList[id].gameId then
			return self.hooks.GetCraftNumReagents.orig(self.UserEnchantDB.CurrentList[id].gameId);
		else
			return 0;
		end
	end
end

function TurtleEnchant:GetCraftReagentInfo(id, reagentId)
	self:LevelDebug(3, "GetCraftReagentInfo called");
	if not self:CheckSkill() then return self.hooks.GetCraftReagentInfo.orig(id, reagentId); end
	self:VerifyUserEnchantDB();
	
	--If we have a selection that is not on screen, use it
	if self.HiddenSelection and not id then
		if self.HiddenSelection.gameId then
			return self.hooks.GetCraftReagentInfo.orig(self.HiddenSelection.gameId, reagentId);
		else
			return;
		end
	else --Otherwise, use the Selected index
		if self.UserEnchantDB.CurrentList[id].gameId then
			return self.hooks.GetCraftReagentInfo.orig(self.UserEnchantDB.CurrentList[id].gameId, reagentId);
		else
			return;
		end
	end
end

function TurtleEnchant:GetCraftSpellFocus(id)
	self:LevelDebug(3, "GetCraftSpellFocus called");
	if not self:CheckSkill() then return self.hooks.GetCraftSpellFocus.orig(id); end
	self:VerifyUserEnchantDB();
	
	--If we have a selection that is not on screen, use it
	if self.HiddenSelection and not id then
		if self.HiddenSelection.gameId then
			return self.hooks.GetCraftSpellFocus.orig(self.HiddenSelection.gameId);
		else
			return;
		end
	else --Otherwise, use the Selected index
		if self.UserEnchantDB.CurrentList[id].gameId then
			return self.hooks.GetCraftSpellFocus.orig(self.UserEnchantDB.CurrentList[id].gameId);
		else
			return;
		end
	end
end

--------------------------------------------------
-- Item link creation functions, called by Default
-- UI during Shift Click of specific buttons
--
-- May later make these more verbouse
--------------------------------------------------
function TurtleEnchant:GetCraftItemLink(id)
	self:LevelDebug(3, "GetCraftItemLink called");
	if not self:CheckSkill() then return self.hooks.GetCraftItemLink.orig(id); end
	self:VerifyUserEnchantDB();
	
	--If we have a selection that is not on screen, use it
	if self.HiddenSelection and not id then
		if self.HiddenSelection.gameId then
			return self.hooks.GetCraftItemLink.orig(self.HiddenSelection.gameId);
		else
			return;
		end
	else --Otherwise, use the Selected index
		if self.UserEnchantDB.CurrentList[id].gameId then
			return self.hooks.GetCraftItemLink.orig(self.UserEnchantDB.CurrentList[id].gameId);
		else
			return;
		end
	end
end

function TurtleEnchant:GetCraftReagentItemLink(id, reagentId)
	self:LevelDebug(3, "GetCraftReagentItemLink called");
	if not self:CheckSkill() then return self.hooks.GetCraftReagentItemLink.orig(id, reagentId); end
	self:VerifyUserEnchantDB();
	
	--If we have a selection that is not on screen, use it
	if self.HiddenSelection and not id then
		if self.HiddenSelection.gameId then
			return self.hooks.GetCraftReagentItemLink.orig(self.HiddenSelection.gameId, reagentId);
		else
			return;
		end
	else --Otherwise, use the Selected index
		if self.UserEnchantDB.CurrentList[id].gameId then
			return self.hooks.GetCraftReagentItemLink.orig(self.UserEnchantDB.CurrentList[id].gameId, reagentId);
		else
			return;
		end
	end
end

--------------------------------------------------
-- Tooltip related functions, called by Default
-- UI during Mouseovers of specific buttons
--------------------------------------------------
function TurtleEnchant:TooltipSetCraftItem(tooltip, id, reagentId)
	self:LevelDebug(3, "TooltipSetCraftItem called");
	if not self:CheckSkill() then return self.hooks[tooltip].SetCraftItem.orig(GameTooltip, id, reagentId); end
	self:VerifyUserEnchantDB();
	
	--If we have a selection that is not on screen, use it
	if self.HiddenSelection and not id then
		if self.HiddenSelection.gameId then
			return self.hooks[tooltip].SetCraftItem.orig(tooltip, self.HiddenSelection.gameId, reagentId);
		else
			return;
		end
	else
		if self.UserEnchantDB.CurrentList[id].gameId then
			return self.hooks[tooltip].SetCraftItem.orig(tooltip, self.UserEnchantDB.CurrentList[id].gameId, reagentId);
		else
			return;
		end
	end
end

function TurtleEnchant:TooltipSetCraftSpell(tooltip, id)
	self:LevelDebug(3, "TooltipSetCraftSpell called");
	if not self:CheckSkill() then return self.hooks[tooltip].SetCraftSpell.orig(GameTooltip, id); end
	self:VerifyUserEnchantDB();
	
	--If we have a selection that is not on screen, use it
	if self.HiddenSelection and not id then
		if self.HiddenSelection.gameId then
			return self.hooks[tooltip].SetCraftSpell.orig(tooltip, self.HiddenSelection.gameId);
		else
			return;
		end
	else
		if self.UserEnchantDB.CurrentList[id].gameId then
			return self.hooks[tooltip].SetCraftSpell.orig(tooltip, self.UserEnchantDB.CurrentList[id].gameId);
		else
			return;
		end
	end
end

-- Create a simple search box and filtering support
function TurtleEnchant:CreateSearchBox(parent)
    if self.searchBox then return end

    -- ensure a valid parent; CraftFrame is the enchanting UI
    parent = parent or (CraftFrame and CraftFrame) or UIParent

    local sb = CreateFrame("EditBox", "TurtleEnchantSearchBox", parent, "InputBoxTemplate")
    if sb.SetSize then
        sb:SetSize(180, 20)
    else
        sb:SetWidth(180)
        sb:SetHeight(20)
    end
    sb:SetPoint("TOPLEFT", parent, "TOPLEFT", 60, -37) -- adjust offsets as needed

    sb:SetParent(parent)
    if parent.GetFrameLevel and sb.SetFrameLevel then
        sb:SetFrameLevel((parent:GetFrameLevel() or 0) + 5)
    end
    if parent.GetFrameStrata and sb.SetFrameStrata then
        sb:SetFrameStrata(parent:GetFrameStrata() or "MEDIUM")
    end

    sb:SetAutoFocus(false)
    sb:SetMaxLetters(64)
    if sb.SetTextInsets then sb:SetTextInsets(6,6,0,0) end
    sb:ClearFocus()
    if sb.SetPropagateKeyboardInput then
        sb:SetPropagateKeyboardInput(true)
    end

    -- Focus only on click
    sb:SetScript("OnMouseDown", function(_, button)
        if button == "LeftButton" then sb:SetFocus() end
    end)
    sb:SetScript("OnShow", function()
        sb:ClearFocus()    end)
    sb:SetScript("OnHide", function() sb:ClearFocus() end)

    sb:SetScript("OnEscapePressed", function()
        sb:SetText("")
        sb:ClearFocus()
        self:SetSearchFilter("")
        self:UpdateCraftFrame()
    end)
    sb:SetScript("OnEnterPressed", function() sb:ClearFocus() end)

    local label = sb:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("LEFT", sb, "LEFT", 4, 0)
    label:SetText("Search...")
    label:SetJustifyH("LEFT")
    label:Show()

    sb:SetScript("OnTextChanged", function()
        local txt = sb:GetText() or ""
        if txt == "" then label:Show() else label:Hide() end
        self:SetSearchFilter(txt)
        if self.UserEnchantDB then self.UserEnchantDB.IsInvalidated = true end
        self:UpdateCraftFrame()
    end)

    sb:Show()
    self.searchBox = sb
end

function TurtleEnchant:SetSearchFilter(text)
    self.filter = (text and text ~= "") and strlower(text) or nil
end

function TurtleEnchant:GetSearchFilter()
    return self.filter
end

-- Create a Dewdrop-2.0 sort button that opens the menu below the button, toggles and closes on outside click.
function TurtleEnchant:CreateSortDewdrop(parent)
    if self.sortBtn or not Dewdrop then return end
    parent = parent or (CraftFrame and CraftFrame) or UIParent

    local btn = CreateFrame("Button", "TurtleEnchantSortBtn", parent, "UIPanelButtonTemplate")
    btn:SetHeight(20)
	btn:SetWidth(60)
    if self.searchBox then
        btn:SetPoint("LEFT", self.searchBox, "RIGHT", 8, 0)
    else
        btn:SetPoint("TOPLEFT", parent, "TOPLEFT", 300, -40)
    end

    local function openBelow(anchor, childrenFunc)
        -- preferred param names for Dewdrop-2.0 (best-effort)
        local ok = pcall(function()
            Dewdrop:Open(anchor,
                'children', childrenFunc,
                'point', 'TOPLEFT', 'relativePoint', 'BOTTOMLEFT',
                'offsetX', 0, 'offsetY', -5)
        end)
        if not ok then
            -- fallback: simpler call
            pcall(function() Dewdrop:Open(anchor, 'children', childrenFunc) end)
        end
    end

    local function updateText()
        local label = (self.db and self.db.profile and self.db.profile.Sort) or L.Bonus
        if btn.SetText then btn:SetText(tostring(label)) end
    end

    btn:SetScript("OnClick", function()
        -- toggle behavior
        if self._dewdropOpen and self._dewdropAnchor == btn then
            pcall(function() Dewdrop:Close() end)
            self._dewdropOpen = nil
            self._dewdropAnchor = nil
            return
        end

        self._dewdropOpen = true
        self._dewdropAnchor = btn

        openBelow(btn, function()
            -- Example items: adjust L.Bonus / L.Armor to your localization table
            Dewdrop:AddLine(
                'text', L.Bonus,
                'checked', (self.db.profile.Sort == L.Bonus),
                'closeWhenClicked', true,
                'func', function()
                    self.db.profile.Sort = L.Bonus
                    updateText()
                    if self.UserEnchantDB then self.UserEnchantDB.IsInvalidated = true end
                    pcall(function() self:UpdateCraftFrame() end)
                    pcall(function() Dewdrop:Close() end)
                    self._dewdropOpen = nil
                    self._dewdropAnchor = nil
                end
            )

            Dewdrop:AddLine(
                'text', L.Armor,
                'checked', (self.db.profile.Sort == L.Armor),
                'closeWhenClicked', true,
                'func', function()
                    self.db.profile.Sort = L.Armor
                    updateText()
                    if self.UserEnchantDB then self.UserEnchantDB.IsInvalidated = true end
                    pcall(function() self:UpdateCraftFrame() end)
                    pcall(function() Dewdrop:Close() end)
                    self._dewdropOpen = nil
                    self._dewdropAnchor = nil
                end
            )           
        end)
    end)

    self.sortBtn = btn
    updateText()
end