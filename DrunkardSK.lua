--[[
	CostaSK.lua
		Drunkard Suicide Kings
--]]

local CostaSK = LibStub("AceAddon-3.0"):NewAddon("CostaSK", "AceConsole-3.0", "AceHook-3.0", "AceComm-3.0", "AceSerializer-3.0", "AceEvent-3.0")

CostaSK.bg = {
	bgFile = 'Interface\\DialogFrame\\UI-DialogBox-Background',
	edgeFile = 'Interface\\DialogFrame\\UI-DialogBox-Border',
	insets = {left = 11, right = 11, top = 12, bottom = 11},
	tile = true,
	tileSize = 32,
	edgeSize = 32,
}

--master globals
local Master = false;
local BidNotOpen = true;
local ItemLink = nil
local HighRank = 5000
local HighName = ""
local BidsReceived = 0
local BidList = {}
local OffspecList = {}
local OffspecCount = 0
local HighRoller = "" 
local HighRoll = 0

--other globals
local EntrySelected = nil
local MyBidType = ""

--hand out item to the winner automaticly
local function GiveLoot(itemLink, lootReciever) -- Added by Kelzu 1.3.6
	local itemDrops = GetNumLootItems() or 0 -- Added 0 to prevent errors by Kelzu 1.3.8 -- Fixed the GetNum function by Kelzu 1.3.9
	if itemDrops < 1 or itemDrops == nil then -- Added the nil to prevent errors by Kelzu 1.3.8
		return
	end

	for iterSlot = 1, itemDrops do
		local slotLink = GetLootSlotLink(iterSlot)

		if slotLink == itemLink then
			for index = 1, math.max(GetNumSubgroupMembers() + 1, GetNumGroupMembers()) do
				local candidate = GetMasterLootCandidate(iterSlot, index)

				if not candidate then
					break
				end

				if candidate == lootReciever then
					GiveMasterLoot(iterSlot, index)
					return
				end
			end
		end
	end
end -- Added by Kelzu 1.3.6

--on loot item icon mouseover
local function IconEnter(self)
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
	--GameTooltip:SetPoint("BOTTOMRIGHT", self, "TOPLEFT");
	GameTooltip:SetHyperlink(ItemLink);
	GameTooltip:Show();
	CursorUpdate(self);
end

--no more loot item icon mouseover
local function IconLeave()
	GameTooltip:Hide();
	ResetCursor();
end

--icon on update
local function IconUpdate(self)
	if ( GameTooltip:IsOwned(self) ) then
		IconEnter(self);
	end
	CursorOnUpdate(self);
end

--icon click
local function IconClick(self)
	if ( IsModifiedClick() ) then
		HandleModifiedItemClick(ItemLink);
	end
end

--on mouseover of openlist button
local function OpenListEnter(self)
	GameTooltip:SetOwner(self, "ANCHOR_NONE")
	GameTooltip:SetPoint("BOTTOMLEFT", self, "TOPRIGHT")
	GameTooltip:SetText("View Lists")
	GameTooltip:Show()
end

--no more mouseover of openlist button
local function OpenListLeave()
	GameTooltip:Hide()
end

--suicide entry
local function Suicide(entry, list)
	local suicider = entry;
	local current = entry + 1;

	if(list == "nList") then
		if (current < CostaSK.db.realm.nLength) then
			for i=current, CostaSK.db.realm.nLength, 1 do
				if (UnitPlayerOrPetInRaid(CostaSK.db.realm.nList[i].name) == true) then -- Fixed by Kelzu, changed from 1 to true for WoD
					--swap selected with current
					local temp = CostaSK.db.realm.nList[i];
					CostaSK.db.realm.nList[i] = CostaSK.db.realm.nList[suicider];
					CostaSK.db.realm.nList[suicider] = temp;
					--set new suicider position
					suicider = i;
				end
			end
			CostaSK.db.realm.nStamp = CostaSK:CreateTimeStamp(CostaSK.db.realm.nStamp);
		end
	else
		if (current < CostaSK.db.realm.tLength) then
			for i=current, CostaSK.db.realm.tLength, 1 do
				if (UnitPlayerOrPetInRaid(CostaSK.db.realm.tList[i].name) == true) then -- Fixed by Kelzu, changed from 1 to true for WoD
					--swap selected with current
					local temp = CostaSK.db.realm.tList[i];
					CostaSK.db.realm.tList[i] = CostaSK.db.realm.tList[suicider];
					CostaSK.db.realm.tList[suicider] = temp;
					--set new suicider position
					suicider = i;
				end
			end
			CostaSK.db.realm.tStamp = CostaSK:CreateTimeStamp(CostaSK.db.realm.tStamp);
		end
	end
	CSKListFrame.selectedEntry = suicider;
end

--update scroll frame
local function ScrollList_Update()
	--local entryOffset = FauxScrollFrame_GetOffset(ScrollList);
	local entryOffset = FauxScrollFrame_GetOffset(CSKListFrame.list);

	--set hightlight and up/down buttons on selected entry
	for i=1, 18, 1 do
		local entryIndex = entryOffset + i;
		if ( entryIndex == CSKListFrame.selectedEntry ) then
			--getglobal("entry"..i):LockHighlight();
			--CSKListFrame.down:SetPoint('RIGHT', getglobal("entry"..i), 'RIGHT', -2, 0);
			CSKListFrame["entry" .. i]:LockHighlight(); -- 1.5.0
			CSKListFrame.down:SetPoint('RIGHT', CSKListFrame["entry" .. i], 'RIGHT', -2, 0); -- 1.5.0
			CSKListFrame.down:Show();
			CSKListFrame.up:Show();
		else
			--getglobal("entry"..i):UnlockHighlight();
			CSKListFrame["entry" .. i]:UnlockHighlight();
		end
	end

	--if selected entry is not on screen hide up/down buttons
	if (CSKListFrame.selectedEntry > entryOffset+18) or (CSKListFrame.selectedEntry <= entryOffset) then
		--downButton:Hide();
		--upButton:Hide();
		CSKListFrame.down:Hide(); -- 1.5.0
		CSKListFrame.up:Hide(); -- 1.5.0
	end

	--which tab is selected
	if(PanelTemplates_GetSelectedTab(CSKListFrame) == 1) then
		local line; -- 1 through 18 of our window to scroll
		local lineplusoffset; -- an index into our data calculated from the scroll offset
		--loop through and set names and colors in list
		for line=1,18 do
			--lineplusoffset = line + FauxScrollFrame_GetOffset(ScrollList);
			lineplusoffset = line + FauxScrollFrame_GetOffset(CSKListFrame.list); -- 1.5.0
			if lineplusoffset <= CostaSK.db.realm.nLength then
				if CostaSK.db.realm.nList[lineplusoffset].bid == "" then
					--getglobal("entry"..line).text:SetText(lineplusoffset..". "..CostaSK.db.realm.nList[lineplusoffset].name);
					CSKListFrame["entry" .. line].text:SetText(lineplusoffset..". "..CostaSK.db.realm.nList[lineplusoffset].name); -- 1.5.0
				else
					--getglobal("entry"..line).text:SetText(lineplusoffset..". "..CostaSK.db.realm.nList[lineplusoffset].name.." - "..CostaSK.db.realm.nList[lineplusoffset].bid);
					CSKListFrame["entry" .. line].text:SetText(lineplusoffset..". "..CostaSK.db.realm.nList[lineplusoffset].name.." - "..CostaSK.db.realm.nList[lineplusoffset].bid); -- 1.5.0
				end
				local color = RAID_CLASS_COLORS[CostaSK.db.realm.nList[lineplusoffset].class];
				if (UnitPlayerOrPetInRaid(CostaSK.db.realm.nList[lineplusoffset].name) == true) then -- Fixed by Kelzu, changed from 1 to true for WoD
					--getglobal("entry"..line).text:SetTextColor(color.r, color.g, color.b);
					CSKListFrame["entry" .. line].text:SetTextColor(color.r, color.g, color.b); -- 1.5.0
				else
					--getglobal("entry"..line).text:SetTextColor(0.5, 0.5, 0.5);
					CSKListFrame["entry" .. line].text:SetTextColor(0.5, 0.5, 0.5); -- 1.5.0
				end
				--getglobal("entry"..line).text:Show();
				CSKListFrame["entry" .. line].text:Show(); -- 1.5.0
			else
				--getglobal("entry"..line).text:Hide();
				CSKListFrame["entry" .. line].text:Hide(); -- 1.5.0
			end
		end

		--disable up/down if top/bottom entry selected
		if(CSKListFrame.selectedEntry == 1) and Master then
			--upButton:Disable();
			CSKListFrame.up:Disable(); -- 1.5.0
		elseif Master then
			--upButton:Enable();
			CSKListFrame.up:Enable(); -- 1.5.0
		end

		if(CSKListFrame.selectedEntry == CostaSK.db.realm.nLength) and Master then
			--downButton:Disable();
			CSKListFrame.down:Disable(); -- 1.5.0
		elseif Master then
			--downButton:Enable();
			CSKListFrame.down:Enable(); -- 1.5.0
		end

		if(CSKListFrame.selectedEntry > CostaSK.db.realm.nLength) and Master then
			--downButton:Disable();
			--upButton:Disable();
			CSKListFrame.down:Disable(); -- 1.5.0
			CSKListFrame.up:Disable(); -- 1.5.0
		end

		--FauxScrollFrame_Update(ScrollList,CostaSK.db.realm.nLength,18,16);
		FauxScrollFrame_Update(CSKListFrame.list,CostaSK.db.realm.nLength,18,16); -- 1.5.0
	elseif(PanelTemplates_GetSelectedTab(CSKListFrame) == 2) then
		local line; -- 1 through 18 of our window to scroll
		local lineplusoffset; -- an index into our data calculated from the scroll offset
		--loop through and set names and colors in list
		for line=1,18 do
			--lineplusoffset = line + FauxScrollFrame_GetOffset(ScrollList);
			lineplusoffset = line + FauxScrollFrame_GetOffset(CSKListFrame.list); -- 1.5.0
			if lineplusoffset <= CostaSK.db.realm.tLength then
				if CostaSK.db.realm.tList[lineplusoffset].bid == "" then
					--getglobal("entry"..line).text:SetText(lineplusoffset..". "..CostaSK.db.realm.tList[lineplusoffset].name);
					CSKListFrame["entry" .. line].text:SetText(lineplusoffset..". "..CostaSK.db.realm.tList[lineplusoffset].name); -- 1.5.0
				else
					--getglobal("entry"..line).text:SetText(lineplusoffset..". "..CostaSK.db.realm.tList[lineplusoffset].name.." - "..CostaSK.db.realm.tList[lineplusoffset].bid);
					CSKListFrame["entry" .. line].text:SetText(lineplusoffset..". "..CostaSK.db.realm.tList[lineplusoffset].name.." - "..CostaSK.db.realm.tList[lineplusoffset].bid); -- 1.5.0
				end 
				local color = RAID_CLASS_COLORS[CostaSK.db.realm.tList[lineplusoffset].class];
				if (UnitPlayerOrPetInRaid(CostaSK.db.realm.tList[lineplusoffset].name) == true) then -- Fixed by Kelzu, changed from 1 to true for WoD
					--getglobal("entry"..line).text:SetTextColor(color.r, color.g, color.b);
					CSKListFrame["entry" .. line].text:SetTextColor(color.r, color.g, color.b); -- 1.5.0
				else
					--getglobal("entry"..line).text:SetTextColor(0.5, 0.5, 0.5);
					CSKListFrame["entry" .. line].text:SetTextColor(0.5, 0.5, 0.5); -- 1.5.0
				end
				--getglobal("entry"..line).text:Show();
				CSKListFrame["entry" .. line].text:Show(); -- 1.5.0
			else
				--getglobal("entry"..line).text:Hide();
				CSKListFrame["entry" .. line].text:Hide(); -- 1.5.0
			end
		end

		--disable up/down if top/bottom entry selected
		if(CSKListFrame.selectedEntry == 1) and Master then
			--upButton:Disable();
			CSKListFrame.up:Disable(); -- 1.5.0
		elseif Master then
			--upButton:Enable();
			CSKListFrame.up:Enable(); -- 1.5.0
		end

		if(CSKListFrame.selectedEntry == CostaSK.db.realm.tLength) and Master then
			--downButton:Disable();
			CSKListFrame.down:Disable(); -- 1.5.0
		elseif Master then
			--downButton:Enable();
			CSKListFrame.down:Enable(); -- 1.5.0
		end

		if(CSKListFrame.selectedEntry > CostaSK.db.realm.tLength) and Master then
			--downButton:Disable();
			--upButton:Disable();
			CSKListFrame.down:Disable(); -- 1.5.0
			CSKListFrame.up:Disable(); -- 1.5.0
		end

		--FauxScrollFrame_Update(ScrollList,CostaSK.db.realm.tLength,18,16);
		FauxScrollFrame_Update(CSKListFrame.list,CostaSK.db.realm.tLength,18,16); -- 1.5.0
	end
end

--on Token tab click
local function ClickTTab()
	PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB) --7.3 PlaySound("igCharacterInfoTab");
	PanelTemplates_SetTab(CSKListFrame, 2);
	CSKListFrame.title:SetText("Token List");
	CSKListFrame.selectedEntry = 0;
	CSKListFrame.add:Show();
	CSKListFrame.del:Show();
	CSKListFrame.up:Show();
	CSKListFrame.down:Show();
	CSKListFrame.murder:Show();
	CSKListFrame.closeBid:Show();
	CSKListFrame.sync:Show();
	CSKListFrame.list:Show();
	for i = 1, 18 do -- 1.5.0
		CSKListFrame["entry" .. i]:Show()
	end
	CSKListFrame.import:Hide();
	CSKListFrame.export:Hide();
	CSKListFrame.tokenRadio:Hide();
	CSKListFrame.normalRadio:Hide();
	CSKListFrame.editScroll:Hide()
	ScrollList_Update();
end

--on Normal Tab click
local function ClickNTab()
	PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB) --7.3 PlaySound("igCharacterInfoTab");
	PanelTemplates_SetTab(CSKListFrame, 1);
	CSKListFrame.title:SetText("Normal List");
	CSKListFrame.selectedEntry = 0;
	CSKListFrame.add:Show();
	CSKListFrame.del:Show();
	CSKListFrame.up:Show();
	CSKListFrame.down:Show();
	CSKListFrame.murder:Show();
	CSKListFrame.closeBid:Show();
	CSKListFrame.sync:Show();
	CSKListFrame.list:Show();
	for i = 1, 18 do -- 1.5.0
		CSKListFrame["entry" .. i]:Show()
	end
	CSKListFrame.import:Hide();
	CSKListFrame.export:Hide();
	CSKListFrame.tokenRadio:Hide();
	CSKListFrame.normalRadio:Hide();
	CSKListFrame.editScroll:Hide()
	ScrollList_Update();
end

--on i/e Tab click
local function ClickITab()
	PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB) --7.3 PlaySound("igCharacterInfoTab");
	PanelTemplates_SetTab(CSKListFrame, 3);
	CSKListFrame.title:SetText("Import/Export Lists");
	CSKListFrame.add:Hide();
	CSKListFrame.del:Hide();
	CSKListFrame.up:Hide();
	CSKListFrame.down:Hide();
	CSKListFrame.murder:Hide();
	CSKListFrame.closeBid:Hide();
	CSKListFrame.sync:Hide();
	CSKListFrame.list:Hide();
	for i = 1, 18 do -- 1.5.0
		CSKListFrame["entry" .. i]:Hide()
	end
	CSKListFrame.import:Show();
	CSKListFrame.export:Show();
	CSKListFrame.tokenRadio:Show();
	CSKListFrame.normalRadio:Show();
	CSKListFrame.editScroll:Show()
	--CSKListFrame.selectedEntry = 0;
	--ScrollList_Update();
end


--on open list click
local function OpenListClick()
	ScrollList_Update()
	CSKListFrame:Show()
end

--on entry button click
local function EntrySelect(self)
	--CSKListFrame.selectedEntry = FauxScrollFrame_GetOffset(ScrollList) + self:GetID()
	CSKListFrame.selectedEntry = FauxScrollFrame_GetOffset(CSKListFrame.list) + self:GetID() -- 1.5.0
	ScrollList_Update()
end

local function EntryClick(self, button, down)
	EntrySelect(self);
end

--on add button click
local function AddClick(self, button, down)
	if(PanelTemplates_GetSelectedTab(CSKListFrame) == 1) then
		if (UnitExists("target") == true) and (UnitIsPlayer("target") == true) then -- Fixed by Kelzu, changed from 1 to true for WoD
			if (CostaSK.db.realm.nLength == nil) then
				CostaSK.db.realm.nLength = 0;
			end
			if (CostaSK.db.realm.nList == nil) then
				CostaSK.db.realm.nList = {};
			end

			CostaSK.db.realm.nLength = CostaSK.db.realm.nLength + 1;

			local _, englishClass = UnitClass("target");
			CostaSK.db.realm.nList[CostaSK.db.realm.nLength] = {name = UnitName("target"), class = englishClass, bid = ""};
			CostaSK.db.realm.nStamp = CostaSK:CreateTimeStamp(CostaSK.db.realm.nStamp);

		end
	elseif(PanelTemplates_GetSelectedTab(CSKListFrame) == 2) then
		if (UnitExists("target") == true) and (UnitIsPlayer("target") == true) then
			if (CostaSK.db.realm.tLength == nil) then
				CostaSK.db.realm.tLength = 0;
			end
			if (CostaSK.db.realm.tList == nil) then
				CostaSK.db.realm.tList = {};
			end

			CostaSK.db.realm.tLength = CostaSK.db.realm.tLength + 1;

			local _, englishClass = UnitClass("target");
			CostaSK.db.realm.tList[CostaSK.db.realm.tLength] = {name = UnitName("target"), class = englishClass, bid = ""};
			CostaSK.db.realm.tStamp = CostaSK:CreateTimeStamp(CostaSK.db.realm.tStamp);

		end
	end
	CostaSK:SendCommMessage("CSKBroadcast", CostaSK:Serialize(CostaSK.db.realm.nStamp, CostaSK.db.realm.nLength, CostaSK.db.realm.nList, CostaSK.db.realm.tStamp, CostaSK.db.realm.tLength, CostaSK.db.realm.tList), "GUILD");
	ScrollList_Update();
end

--on up button click
local function UpClick(self, button, down)
	if(PanelTemplates_GetSelectedTab(CSKListFrame) == 1) then
		local temp = CostaSK.db.realm.nList[CSKListFrame.selectedEntry];
		CostaSK.db.realm.nList[CSKListFrame.selectedEntry] = CostaSK.db.realm.nList[CSKListFrame.selectedEntry-1];
		CostaSK.db.realm.nList[CSKListFrame.selectedEntry-1] = temp;
		CSKListFrame.selectedEntry = CSKListFrame.selectedEntry-1;
		CostaSK.db.realm.nStamp = CostaSK:CreateTimeStamp(CostaSK.db.realm.nStamp);
	elseif(PanelTemplates_GetSelectedTab(CSKListFrame) == 2) then
		local temp = CostaSK.db.realm.tList[CSKListFrame.selectedEntry];
		CostaSK.db.realm.tList[CSKListFrame.selectedEntry] = CostaSK.db.realm.tList[CSKListFrame.selectedEntry-1];
		CostaSK.db.realm.tList[CSKListFrame.selectedEntry-1] = temp;
		CSKListFrame.selectedEntry = CSKListFrame.selectedEntry-1;
		CostaSK.db.realm.tStamp = CostaSK:CreateTimeStamp(CostaSK.db.realm.tStamp);
	end
	CostaSK:SendCommMessage("CSKBroadcast", CostaSK:Serialize(CostaSK.db.realm.nStamp, CostaSK.db.realm.nLength, CostaSK.db.realm.nList, CostaSK.db.realm.tStamp, CostaSK.db.realm.tLength, CostaSK.db.realm.tList), "GUILD");
	ScrollList_Update();
end

--on down button click
local function DownClick(self, button, down)
	if(PanelTemplates_GetSelectedTab(CSKListFrame) == 1) then
		local temp = CostaSK.db.realm.nList[CSKListFrame.selectedEntry];
		CostaSK.db.realm.nList[CSKListFrame.selectedEntry] = CostaSK.db.realm.nList[CSKListFrame.selectedEntry+1];
		CostaSK.db.realm.nList[CSKListFrame.selectedEntry+1] = temp;
		CSKListFrame.selectedEntry = CSKListFrame.selectedEntry+1;
		CostaSK.db.realm.nStamp = CostaSK:CreateTimeStamp(CostaSK.db.realm.nStamp);
	elseif(PanelTemplates_GetSelectedTab(CSKListFrame) == 2) then
		local temp = CostaSK.db.realm.tList[CSKListFrame.selectedEntry];
		CostaSK.db.realm.tList[CSKListFrame.selectedEntry] = CostaSK.db.realm.tList[CSKListFrame.selectedEntry+1];
		CostaSK.db.realm.tList[CSKListFrame.selectedEntry+1] = temp;
		CSKListFrame.selectedEntry = CSKListFrame.selectedEntry+1;
		CostaSK.db.realm.tStamp = CostaSK:CreateTimeStamp(CostaSK.db.realm.tStamp);
	end
	CostaSK:SendCommMessage("CSKBroadcast", CostaSK:Serialize(CostaSK.db.realm.nStamp, CostaSK.db.realm.nLength, CostaSK.db.realm.nList, CostaSK.db.realm.tStamp, CostaSK.db.realm.tLength, CostaSK.db.realm.tList), "GUILD");
	ScrollList_Update();
end

--on delete button click
local function DeleteClick(self, button, down)
	if(CSKListFrame.selectedEntry ~= 0) then
		if(PanelTemplates_GetSelectedTab(CSKListFrame) == 1) then
			--if(CostaSK.db.realm.nLength > 0) then
			if(CostaSK.db.realm.nLength >= CSKListFrame.selectedEntry) then  -- Make sure we haven't selected empty slot and accidentally delete the last name in the list, added in 1.5.0
				table.remove(CostaSK.db.realm.nList, CSKListFrame.selectedEntry)
				CostaSK.db.realm.nLength = CostaSK.db.realm.nLength - 1;
				CostaSK.db.realm.nStamp = CostaSK:CreateTimeStamp(CostaSK.db.realm.nStamp);
			end
		elseif(PanelTemplates_GetSelectedTab(CSKListFrame) == 2) then
			--if(CostaSK.db.realm.tLength > 0) then
			if(CostaSK.db.realm.tLength >= CSKListFrame.selectedEntry) then  -- Make sure we haven't selected empty slot and accidentally delete the last name in the list, added in 1.5.0
				table.remove(CostaSK.db.realm.tList, CSKListFrame.selectedEntry);
				CostaSK.db.realm.tLength = CostaSK.db.realm.tLength - 1;
				CostaSK.db.realm.tStamp = CostaSK:CreateTimeStamp(CostaSK.db.realm.tStamp);
			end
		end
		CostaSK:SendCommMessage("CSKBroadcast", CostaSK:Serialize(CostaSK.db.realm.nStamp, CostaSK.db.realm.nLength, CostaSK.db.realm.nList, CostaSK.db.realm.tStamp, CostaSK.db.realm.tLength, CostaSK.db.realm.tList), "GUILD");
		ScrollList_Update();
	end 
end

--close bid button click
local function CloseBidClick(self, button, down)
	if (HighName ~= "") then
		local list = CostaSK:WhichList();
		SendChatMessage(HighName.." wins "..ItemLink.."!", "RAID");
		GiveLoot(ItemLink, HighName) -- Added by Kelzu 1.3.6
		Suicide(HighRank, list);
		CostaSK:SendCommMessage("CSKBroadcast", CostaSK:Serialize(CostaSK.db.realm.nStamp, CostaSK.db.realm.nLength, CostaSK.db.realm.nList, CostaSK.db.realm.tStamp, CostaSK.db.realm.tLength, CostaSK.db.realm.tList), "GUILD");
	elseif (HighRoller ~= "") then
		SendChatMessage(HighRoller.." wins "..ItemLink.."!", "RAID");
		GiveLoot(ItemLink, HighRoller) -- Added by Kelzu 1.3.6
	end

	--reset everything
	HighRank = 5000;
	HighName = "";
	BidsReceived = 0;
	ItemLink = nil;
	BidList = {};
	OffspecList = {};
	OffspecCount = 0;
	HighRoller = ""; 
	HighRoll = 0;
	BidNotOpen = true;

	CostaSK:SendCommMessage("CSKCloseBid", "cb", "RAID");

	CSKListFrame.closeBid:Disable();

	ScrollList_Update();
end

--murder button click
local function MurderClick(self, button, down)
	local list;
	if (CSKListFrame.selectedEntry ~= 0) then
		if(PanelTemplates_GetSelectedTab(CSKListFrame) == 1) then
			list = "nList";
		elseif(PanelTemplates_GetSelectedTab(CSKListFrame) == 2) then
			list = "tList";
		end
		Suicide(CSKListFrame.selectedEntry, list);
		CostaSK:SendCommMessage("CSKBroadcast", CostaSK:Serialize(CostaSK.db.realm.nStamp, CostaSK.db.realm.nLength, CostaSK.db.realm.nList, CostaSK.db.realm.tStamp, CostaSK.db.realm.tLength, CostaSK.db.realm.tList), "GUILD");
		ScrollList_Update();
	end 
end

--sync button click
local function SyncClick(self, button, down)
	if (Master) then
		--send sync req with master
		CostaSK:SendCommMessage("CSKSyncReq", "master", "RAID");
	else
		--send sync req without master
		CostaSK:SendCommMessage("CSKSyncReq", "not master", "RAID");
	end
end

--export click
local function ExportClick(self, button, down)
	local exportList = "";

	if(CSKListFrame.normalRadio:GetChecked() == true) then -- Fixed by Kelzu, changed from 1 to true for WoD
		for i=1, CostaSK.db.realm.nLength, 1 do
			exportList = exportList..i..". "..CostaSK.db.realm.nList[i].name.." "..strlower(CostaSK.db.realm.nList[i].class).."\n";
		end
		CSKListFrame.editArea:SetText(exportList);
		CSKListFrame.editArea:HighlightText(0);

	elseif(CSKListFrame.tokenRadio:GetChecked() == true) then -- Fixed by Kelzu, changed from 1 to true for WoD
		for i=1, CostaSK.db.realm.tLength, 1 do
			exportList = exportList..i..". "..CostaSK.db.realm.tList[i].name.." "..strlower(CostaSK.db.realm.tList[i].class).."\n";
		end
		CSKListFrame.editArea:SetText(exportList);
		CSKListFrame.editArea:HighlightText(0);
	end
end

--import click
local function ImportClick(self, button, down)
--CostaSK:Print("Import functionality is not currently implemented... but how did you manage to hit the button?");
	CSKConfirmFrame:Show();
end

local function NormalRadioClick(self, button, down)
	CSKListFrame.tokenRadio:SetChecked(nil);
end

local function TokenRadioClick(self, button, down)
	CSKListFrame.normalRadio:SetChecked(nil);
end

--bid button click
local function BidClick(self, button, down)
	MyBidType = "bid";
	CostaSK:SendCommMessage("CSKSendBid", CostaSK:Serialize(MyBidType, UnitName("player")), "RAID");
	CSKBidFrame.offspec:Disable();
	CSKBidFrame.pass:Disable();
	CSKBidFrame.bid:Disable();
	CSKBidFrame.retract:Enable();
end

--offspec button click
local function OffspecClick(self, button, down)
	MyBidType = "offspec";
	CostaSK:SendCommMessage("CSKSendBid", CostaSK:Serialize(MyBidType, UnitName("player")), "RAID");
	CSKBidFrame.offspec:Disable();
	CSKBidFrame.pass:Disable();
	CSKBidFrame.bid:Disable();
	CSKBidFrame.retract:Enable();
end

--pass button click
local function PassClick(self, button, down)
	MyBidType = "pass";
	CostaSK:SendCommMessage("CSKSendBid", CostaSK:Serialize(MyBidType, UnitName("player")), "RAID");
	CSKBidFrame.offspec:Disable();
	CSKBidFrame.pass:Disable();
	CSKBidFrame.bid:Disable();
	CSKBidFrame.retract:Enable();
end

--retract button click
local function RetractClick(self, button, down)
	CostaSK:SendCommMessage("CSKSendRetract", CostaSK:Serialize(MyBidType, UnitName("player")), "RAID");
	CSKBidFrame.offspec:Enable();
	CSKBidFrame.pass:Enable();
	CSKBidFrame.bid:Enable();
	CSKBidFrame.retract:Disable();
end

--accept button click
local function AcceptClick(self, button, down)
	local text = CSKListFrame.editArea:GetText();
	local i = 1;
	local found, e, rank, pname, class, uclass;

	if (CSKListFrame.normalRadio:GetChecked() == true) then -- Fixed by Kelzu, changed from 1 to true for WoD
		CostaSK.db.realm.nLength = 0;
		CostaSK.db.realm.nList = {};
	elseif (CSKListFrame.tokenRadio:GetChecked() == true) then -- Fixed by Kelzu, changed from 1 to true for WoD
		CostaSK.db.realm.tLength = 0;
		CostaSK.db.realm.tList = {};
	end

	text = text:gsub(".", function(c) local b = c:byte() if b > 127 then return "\\" .. b end end) -- UTF-8 to ASCII, added in 1.4.11 by Kelzu

	while 1 do
		--found, e, rank, pname, class = string.find(text, "(%d+)%p%s(%a+)%s(%a+)", i);
		found, e, rank, pname, class = string.find(text, "(%d+)%p%s([\\%d{3}%a]+)%s(%a+)", i); -- UTF-8 magic matching, added in 1.4.11 by Kelzu
		if (found == nil) then
			break;
		else
			uclass = strupper(class);
			--CostaSK:Print(rank.." "..pname.." "..uclass);

			--make sure entered classes are actually classes
			if ((uclass ~= "SHAMAN") and (uclass ~= "PALADIN") and (uclass ~= "DRUID") and (uclass ~= "WARRIOR") and (uclass ~= "ROGUE") and 
			--(uclass ~= "DEATHKNIGHT") and (uclass ~= "PRIEST") and (uclass ~= "WARLOCK") and (uclass ~= "MAGE") and (uclass ~= "HUNTER")) then
			(uclass ~= "DEATHKNIGHT") and (uclass ~= "PRIEST") and (uclass ~= "WARLOCK") and (uclass ~= "MAGE") and (uclass ~= "HUNTER") and
			(uclass ~= "MONK") and (uclass ~= "DEMONHUNTER")) then -- Updated by Kelzu
				CostaSK:Print("Error: "..class.." is not a valid class!");
				break;
			end

			pname = pname:gsub("\\(%d+)", string.char) -- ASCII to UTF-8, added in 1.4.11 by Kelzu

			--name to vars
			--class to vars
			if (CSKListFrame.normalRadio:GetChecked() == true) then -- Fixed by Kelzu, changed from 1 to true for WoD
				CostaSK.db.realm.nLength = CostaSK.db.realm.nLength + 1;

				CostaSK.db.realm.nList[CostaSK.db.realm.nLength] = {name = pname, class = uclass, bid = ""};
				CostaSK.db.realm.nStamp = CostaSK:CreateTimeStamp(CostaSK.db.realm.nStamp);
				
			elseif (CSKListFrame.tokenRadio:GetChecked() == true) then -- Fixed by Kelzu, changed from 1 to true for WoD
				CostaSK.db.realm.tLength = CostaSK.db.realm.tLength + 1;
			
				CostaSK.db.realm.tList[CostaSK.db.realm.tLength] = {name = pname, class = uclass, bid = ""};
				CostaSK.db.realm.tStamp = CostaSK:CreateTimeStamp(CostaSK.db.realm.tStamp);
			end
			
		end
		i = e + 1;
	end
	CSKConfirmFrame:Hide();
	CostaSK:SendCommMessage("CSKBroadcast", CostaSK:Serialize(CostaSK.db.realm.nStamp, CostaSK.db.realm.nLength, CostaSK.db.realm.nList, CostaSK.db.realm.tStamp, CostaSK.db.realm.tLength, CostaSK.db.realm.tList), "GUILD");
	ScrollList_Update();
end

--decline button click
local function DeclineClick(self, button, down)
	CSKConfirmFrame:Hide();
end

--[[
	Loading/Profile Functions
--]]



function CostaSK:OnInitialize()
--CostaSK:Print(HandleModifiedItemClick);
	--saved vars
	self.db = LibStub("AceDB-3.0"):New("CostaSKDB")

	if (CostaSK.db.realm.nLength == nil) then
		CostaSK.db.realm.nLength = 0;
	end
	if (CostaSK.db.realm.tLength == nil) then
		CostaSK.db.realm.tLength = 0;
	end

	if (CostaSK.db.realm.nStamp == nil) then
		CostaSK.db.realm.nStamp = 0;
	end
	if (CostaSK.db.realm.tStamp == nil) then
		CostaSK.db.realm.tStamp = 0;
	end



	--slash command
	CostaSK:RegisterChatCommand("csk", "OpenList")
	CostaSK:RegisterChatCommand("CSK", "OpenList")

	--set bids in list to ensure backwards compatability
	if (CostaSK.db.realm.nLength > 0) then
		for i=1, CostaSK.db.realm.nLength, 1 do
			CostaSK.db.realm.nList[i].bid = "";
		end
	end

	if (CostaSK.db.realm.tLength > 0) then
		for i=1, CostaSK.db.realm.tLength, 1 do
			CostaSK.db.realm.tList[i].bid = "";
		end
	end
	
end

function CostaSK:OnEnable()
	-- Called when the addon is enabled
	--hooks
	--hookexists, hookhandler = CostaSK:IsHooked("HandleModifiedItemClick")
	--if(hookexists == false) then
	--	CostaSK:SecureHook("HandleModifiedItemClick", "CSK_HandleModifiedItemClick")
	--end
--CostaSK:Print(HandleModifiedItemClick);
	--set bids in list to ensure backwards compatability
	local f = CreateFrame('Frame', 'CSKBidFrame', UIParent,CostaSK.bg)
	f:Hide()

	f:SetWidth(350);
	f:SetHeight(120);
	f:SetPoint("CENTER");
	f:EnableMouse(true)
	f:SetToplevel(true)
	f:SetMovable(true)
	f:SetClampedToScreen(true)
	f:SetFrameStrata('DIALOG')
	f:SetScript('OnMouseDown', f.StartMoving)
	f:SetScript('OnMouseUp', f.StopMovingOrSizing)

	--title text
	f.text = f:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
	f.text:SetText('<No High Bidder>')
	f.text:SetPoint('TOP', 0, -15)

	--item link
	f.link = CreateFrame('ScrollingMessageFrame', nil, f)
	f.link:SetWidth(290)
	f.link:SetHeight(14)
	f.link:SetMaxLines(1)
	f.link:SetFontObject("GameFontNormal");
	f.link:EnableMouse(true)
	f.link:SetScript("OnHyperlinkClick", ChatFrame_OnHyperlinkShow)
	f.link:SetFading(false)
	f.link:SetPoint('CENTER', 0, -35)
	f.link:SetTextColor(1, 1, 1) -- 7.3 requires this now for some reason?

	--item icon
	f.item = CreateFrame('ItemButton', "ItemIcon", f)
	--f.item:SetNormalTexture(GetItemIcon(itemID))
	f.item:SetScale(1.2);
	f.item:EnableMouse(true)
	f.item:SetPoint('CENTER', 0, 0)
	f.item.hasItem = 1;
	f.item:Show()
	f.item:RegisterForClicks("LeftButtonUp", "RightButtonUp");
	f.item:SetScript("OnEnter", IconEnter);
	f.item:SetScript("OnLeave", IconLeave);
	f.item:SetScript("OnUpdate", IconUpdate);
	f.item:SetScript("OnClick", IconClick);

	--bid button
	f.bid = CreateFrame('Button', nil, f, "OptionsButtonTemplate")
	f.bid:SetText('Bid')
	f.bid:SetPoint('TOPLEFT', 30, -40)
	f.bid:SetScript('OnClick', BidClick)

	--pass button
	f.pass = CreateFrame('Button', nil, f, "OptionsButtonTemplate")
	f.pass:SetText('Pass')
	f.pass:SetPoint('TOPRIGHT', -30, -65)
	f.pass:SetScript('OnClick', PassClick)

	--offspec button
	f.offspec = CreateFrame('Button', nil, f, "OptionsButtonTemplate")
	f.offspec:SetText('Offspec')
	f.offspec:SetPoint('TOPRIGHT', -30, -40)
	f.offspec:SetScript('OnClick', OffspecClick)

	--retract button
	f.retract = CreateFrame('Button', nil, f, "OptionsButtonTemplate")
	f.retract:SetText('Retract')
	f.retract:SetPoint('TOPLEFT', 30, -65)
	f.retract:SetScript('OnClick', RetractClick)
	f.retract:Disable()

	--close button
	--f.close = CreateFrame('Button', nil, f, 'UIPanelCloseButton')
	--f.close:SetPoint('TOPRIGHT', -5, -5)

	--open list button
	f.openList = CreateFrame('Button', nil, f, 'UIPanelScrollDownButtonTemplate')
	f.openList:SetPoint('BOTTOMRIGHT', -12, 10)
	f.openList:EnableMouse(true)
	f.openList:SetScript("OnEnter", OpenListEnter)
	f.openList:SetScript("OnLeave", OpenListLeave)
	f.openList:SetScript("OnClick", OpenListClick)


	local l = CreateFrame('Frame', 'CSKListFrame', UIParent,CostaSK.bg)
	l:Hide()

	l:SetWidth(250); 
	l:SetHeight(400);
	l:SetPoint("CENTER");
	l:EnableMouse(true)
	l:SetToplevel(true)
	l:SetMovable(true)
	l:SetClampedToScreen(true)
	l:SetFrameStrata('DIALOG')
	l:SetScript('OnMouseDown', l.StartMoving)
	l:SetScript('OnMouseUp', l.StopMovingOrSizing)

	--listframe title
	l.title = l:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
	l.title:SetText('Normal List')
	l.title:SetPoint('TOP', 0, -15)

	--close button
	l.close = CreateFrame('Button', nil, l, 'UIPanelCloseButton')
	l.close:SetPoint('TOPRIGHT', -5, -5)

	--normal list tab
	l.nTab = CreateFrame('Button', 'CSKListFrameTab1', l, "CharacterFrameTabButtonTemplate")
	l.nTab:SetPoint('CENTER', l, 'BOTTOMLEFT', 50, -10)
	l.nTab:SetID(1)
	l.nTab:SetText('Normal List')
	l.nTab:SetScript('OnClick', ClickNTab)


	--token list tab
	l.tTab = CreateFrame('Button', 'CSKListFrameTab2', l, "CharacterFrameTabButtonTemplate")
	--l.tTab:SetPoint("LEFT", CSKListFrameTab1, "RIGHT", -14, 0);
	l.tTab:SetPoint("LEFT", l.nTab, "RIGHT", -14, 0); -- 1.5.0
	l.tTab:SetID(2)
	l.tTab:SetText('Token List')
	l.tTab:SetScript('OnClick', ClickTTab)


	--i/e list tab
	l.iTab = CreateFrame('Button', 'CSKListFrameTab3', l, "CharacterFrameTabButtonTemplate")
	--l.iTab:SetPoint("LEFT", CSKListFrameTab2, "RIGHT", -14, 0);
	l.iTab:SetPoint("LEFT", l.tTab, "RIGHT", -14, 0); -- 1.5.0
	l.iTab:SetID(3)
	l.iTab:SetText('I/E Lists')
	l.iTab:SetScript('OnClick', ClickITab)


	--add button
	l.add = CreateFrame('Button', 'ListAddButton', l, "OptionsButtonTemplate")
	l.add:SetText('Add')
	l.add:SetPoint('TOPLEFT', 35, -28)
	l.add:SetScript('OnClick', AddClick)

	--delete button
	l.del = CreateFrame('Button', nil, l, "OptionsButtonTemplate")
	l.del:SetText('Delete')
	--l.del:SetPoint('LEFT', ListAddButton, 'RIGHT', 0, 0)
	l.del:SetPoint('LEFT', l.add, 'RIGHT', 0, 0) -- 1.5.0
	l.del:SetScript('OnClick', DeleteClick)

	--murder button
	l.murder = CreateFrame('Button', 'ListMurderButton', l, "OptionsButtonTemplate")
	l.murder:SetText('Murder')
	l.murder:SetPoint('BOTTOMLEFT', 35, 38)
	l.murder:SetScript('OnClick', MurderClick)

	--close bid button
	l.closeBid = CreateFrame('Button', nil, l, "OptionsButtonTemplate")
	l.closeBid:SetText('Close Bid')
	l.closeBid:SetPoint('BOTTOM', 0, 15)
	l.closeBid:SetScript('OnClick', CloseBidClick)

	--sync button
	l.sync = CreateFrame('Button', nil, l, "OptionsButtonTemplate")
	l.sync:SetText('Sync')
	--l.sync:SetPoint('LEFT', ListMurderButton, 'RIGHT', 0, 0)
	l.sync:SetPoint('LEFT', l.murder, 'RIGHT', 0, 0) -- 1.5.0
	l.sync:SetScript('OnClick', SyncClick)

	--export button
	l.export = CreateFrame('Button', 'ExportButton', l, "OptionsButtonTemplate")
	l.export:SetText('Export')
	l.export:SetPoint('BOTTOMLEFT', 35, 15)
	l.export:SetScript('OnClick', ExportClick)
	l.export:Hide();

	--import button
	l.import = CreateFrame('Button', nil, l, "OptionsButtonTemplate")
	l.import:SetText('Import')
	--l.import:SetPoint('LEFT', ExportButton, 'RIGHT', 0, 0)
	l.import:SetPoint('LEFT', l.export, 'RIGHT', 0, 0) -- 1.5.0
	l.import:SetScript('OnClick', ImportClick)
	l.import:Hide();

	--normal radio button
	l.normalRadio = CreateFrame("CheckButton", "NormalRadioButton", l, "UIRadioButtonTemplate")
	NormalRadioButtonText:SetText('Normal List')
	l.normalRadio:SetPoint('BOTTOMLEFT', 35, 40)
	l.normalRadio:SetScript('OnClick', NormalRadioClick)
	l.normalRadio:SetChecked(1)
	l.normalRadio:Hide()

	--token radio button
	l.tokenRadio = CreateFrame("CheckButton", "TokenRadioButton", l, "UIRadioButtonTemplate")
	TokenRadioButtonText:SetText('Token List')
	--l.tokenRadio:SetPoint('LEFT', NormalRadioButton, 'RIGHT', 75, 0)
	l.tokenRadio:SetPoint('LEFT', l.normalRadio, 'RIGHT', 75, 0) -- 1.5.0
	l.tokenRadio:SetScript('OnClick', TokenRadioClick)
	l.tokenRadio:Hide()

	--editbox
	l.editScroll = CreateFrame("ScrollFrame", "IEEditScroll", l, "UIPanelScrollFrameTemplate")
	l.editScroll:SetPoint('TOPLEFT', 20, -50)
	l.editScroll:SetWidth(190); 
	l.editScroll:SetHeight(288);

	l.editArea = CreateFrame("EditBox", "IEEditScrollText", l.editScroll)
	l.editArea:SetAutoFocus(false)
	l.editArea:SetMultiLine(true)
	l.editArea:SetFontObject(ChatFontNormal) --GameFontHighlightSmall)
	l.editArea:SetMaxLetters(99999)
	l.editArea:EnableMouse(true)
	l.editArea:SetScript("OnEscapePressed", l.editArea.ClearFocus)
	-- XXX why the fuck doesn't SetPoint work on the editbox?
	l.editArea:SetWidth(190)
	l.editArea:SetText("To Export: Select a list below and hit export.\n\nTo Import: Fill this box with the following format. Make sure names are capitalized correctly. Make sure the correct list is selected below and hit import.\n\nFormat:\n1. Name Class\n2. Name Class\netc")

	l.editScroll:SetScrollChild(l.editArea)
	l.editScroll:Hide()

--[[
	--down button
	l.down = CreateFrame('Button', 'downButton', l, 'UIPanelScrollDownButtonTemplate')
	l.down:SetPoint('RIGHT', entry1, 'RIGHT')
	l.down:SetFrameStrata('FULLSCREEN')
	l.down:SetScript('OnClick', DownClick)
	l.down:Hide()

	--up button
	l.up = CreateFrame('Button', 'upButton', l, 'UIPanelScrollUpButtonTemplate')
	l.up:SetPoint('RIGHT', downButton, 'LEFT')
	l.up:SetFrameStrata('FULLSCREEN')
	l.up:SetScript('OnClick', UpClick)
	l.up:Hide()
]]

	--scroll frame (actual list)
	l.list = CreateFrame('ScrollFrame', 'ScrollList', l, 'FauxScrollFrameTemplate')
	l.list:SetPoint('TOPLEFT', 10, -50)
	l.list:SetWidth(200); 
	l.list:SetHeight(288);
	l.list:SetScript('OnVerticalScroll', function(self, offset)
			FauxScrollFrame_OnVerticalScroll(self, offset, 16, ScrollList_Update);
			end)

	-- Shortening hard coded stuff down with iterator and reducing the amount of globals 1.5.0
	--entry buttons
	for i = 1, 18 do
		l["entry" .. i] = CreateFrame('Button', 'entry' .. i, l)
		if i == 1 then
			l["entry" .. i]:SetPoint('TOPLEFT', l.list, 'TOPLEFT', 8, 0)
		else
			l["entry" .. i]:SetPoint('TOPLEFT', l["entry" .. i - 1], 'BOTTOMLEFT')
		end
		l["entry" .. i].text = l["entry" .. i]:CreateFontString('entry' .. i .. '_Text', 'BORDER','GameFontHighlightLeft')
		l["entry" .. i].text:SetText('entry' .. i)
		l["entry" .. i].text:SetPoint('LEFT')
		l["entry" .. i]:SetWidth(200)
		l["entry" .. i]:SetHeight(16)
		l["entry" .. i]:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
		l["entry" .. i]:EnableMouse(true)
		l["entry" .. i]:SetScript('OnClick', EntryClick)
		l["entry" .. i]:SetID(i)
	end

	--down button
	l.down = CreateFrame('Button', 'downButton', l, 'UIPanelScrollDownButtonTemplate')
	l.down:SetPoint('RIGHT', l.entry1, 'RIGHT')
	l.down:SetFrameStrata('FULLSCREEN')
	l.down:SetScript('OnClick', DownClick)
	l.down:Hide()

	--up button
	l.up = CreateFrame('Button', 'upButton', l, 'UIPanelScrollUpButtonTemplate')
	l.up:SetPoint('RIGHT', l.down, 'LEFT')
	l.up:SetFrameStrata('FULLSCREEN')
	l.up:SetScript('OnClick', UpClick)
	l.up:Hide()

--[[
	--entry buttons
	l.entry1 = CreateFrame('Button', 'entry1', l)
	l.entry1:SetPoint('TOPLEFT', ScrollList, 'TOPLEFT', 8, 0)
	l.entry1.text = l.entry1:CreateFontString('entry1_Text', 'BORDER','GameFontHighlightLeft')
	l.entry1.text:SetText('entry1')
	l.entry1.text:SetPoint('LEFT')
	l.entry1:SetWidth(200)
	l.entry1:SetHeight(16)
	l.entry1:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
	l.entry1:EnableMouse(true)
	l.entry1:SetScript('OnClick', EntryClick)
	l.entry1:SetID(1)

	l.entry2 = CreateFrame('Button', 'entry2', l)
	l.entry2:SetPoint('TOPLEFT', entry1, 'BOTTOMLEFT')
	l.entry2.text = l.entry2:CreateFontString('entry2_Text', 'BORDER','GameFontHighlightLeft')
	l.entry2.text:SetText('entry2')
	l.entry2.text:SetPoint('LEFT')
	l.entry2:SetWidth(200)
	l.entry2:SetHeight(16)
	l.entry2:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
	l.entry2:EnableMouse(true)
	l.entry2:SetScript('OnClick', EntryClick)
	l.entry2:SetID(2)

	l.entry3 = CreateFrame('Button', 'entry3', l)
	l.entry3:SetPoint('TOPLEFT', entry2, 'BOTTOMLEFT')
	l.entry3.text = l.entry3:CreateFontString('entry3_Text', 'BORDER','GameFontHighlightLeft')
	l.entry3.text:SetText('entry3')
	l.entry3.text:SetPoint('LEFT')
	l.entry3:SetWidth(200)
	l.entry3:SetHeight(16)
	l.entry3:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
	l.entry3:EnableMouse(true)
	l.entry3:SetScript('OnClick', EntryClick)
	l.entry3:SetID(3)

	l.entry4 = CreateFrame('Button', 'entry4', l)
	l.entry4:SetPoint('TOPLEFT', entry3, 'BOTTOMLEFT')
	l.entry4.text = l.entry4:CreateFontString('entry4_Text', 'BORDER','GameFontHighlightLeft')
	l.entry4.text:SetText('entry4')
	l.entry4.text:SetPoint('LEFT')
	l.entry4:SetWidth(200)
	l.entry4:SetHeight(16)
	l.entry4:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
	l.entry4:EnableMouse(true)
	l.entry4:SetScript('OnClick', EntryClick)
	l.entry4:SetID(4)

	l.entry5 = CreateFrame('Button', 'entry5', l)
	l.entry5:SetPoint('TOPLEFT', entry4, 'BOTTOMLEFT')
	l.entry5.text = l.entry5:CreateFontString('entry5_Text', 'BORDER','GameFontHighlightLeft')
	l.entry5.text:SetText('entry5')
	l.entry5.text:SetPoint('LEFT')
	l.entry5:SetWidth(200)
	l.entry5:SetHeight(16)
	l.entry5:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
	l.entry5:EnableMouse(true)
	l.entry5:SetScript('OnClick', EntryClick)
	l.entry5:SetID(5)

	l.entry6 = CreateFrame('Button', 'entry6', l)
	l.entry6:SetPoint('TOPLEFT', entry5, 'BOTTOMLEFT')
	l.entry6.text = l.entry6:CreateFontString('entry6_Text', 'BORDER','GameFontHighlightLeft')
	l.entry6.text:SetText('entry6')
	l.entry6.text:SetPoint('LEFT')
	l.entry6:SetWidth(200)
	l.entry6:SetHeight(16)
	l.entry6:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
	l.entry6:EnableMouse(true)
	l.entry6:SetScript('OnClick', EntryClick)
	l.entry6:SetID(6)

	l.entry7 = CreateFrame('Button', 'entry7', l)
	l.entry7:SetPoint('TOPLEFT', entry6, 'BOTTOMLEFT')
	l.entry7.text = l.entry7:CreateFontString('entry7_Text', 'BORDER','GameFontHighlightLeft')
	l.entry7.text:SetText('entry7')
	l.entry7.text:SetPoint('LEFT')
	l.entry7:SetWidth(200)
	l.entry7:SetHeight(16)
	l.entry7:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
	l.entry7:EnableMouse(true)
	l.entry7:SetScript('OnClick', EntryClick)
	l.entry7:SetID(7)

	l.entry8 = CreateFrame('Button', 'entry8', l)
	l.entry8:SetPoint('TOPLEFT', entry7, 'BOTTOMLEFT')
	l.entry8.text = l.entry8:CreateFontString('entry8_Text', 'BORDER','GameFontHighlightLeft')
	l.entry8.text:SetText('entry8')
	l.entry8.text:SetPoint('LEFT')
	l.entry8:SetWidth(200)
	l.entry8:SetHeight(16)
	l.entry8:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
	l.entry8:EnableMouse(true)
	l.entry8:SetScript('OnClick', EntryClick)
	l.entry8:SetID(8)

	l.entry9 = CreateFrame('Button', 'entry9', l)
	l.entry9:SetPoint('TOPLEFT', entry8, 'BOTTOMLEFT')
	l.entry9.text = l.entry9:CreateFontString('entry9_Text', 'BORDER','GameFontHighlightLeft')
	l.entry9.text:SetText('entry9')
	l.entry9.text:SetPoint('LEFT')
	l.entry9:SetWidth(200)
	l.entry9:SetHeight(16)
	l.entry9:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
	l.entry9:EnableMouse(true)
	l.entry9:SetScript('OnClick', EntryClick)
	l.entry9:SetID(9)

	l.entry10 = CreateFrame('Button', 'entry10', l)
	l.entry10:SetPoint('TOPLEFT', entry9, 'BOTTOMLEFT')
	l.entry10.text = l.entry10:CreateFontString('entry10_Text', 'BORDER','GameFontHighlightLeft')
	l.entry10.text:SetText('entry10')
	l.entry10.text:SetPoint('LEFT')
	l.entry10:SetWidth(200)
	l.entry10:SetHeight(16)
	l.entry10:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
	l.entry10:EnableMouse(true)
	l.entry10:SetScript('OnClick', EntryClick)
	l.entry10:SetID(10)

	l.entry11 = CreateFrame('Button', 'entry11', l)
	l.entry11:SetPoint('TOPLEFT', entry10, 'BOTTOMLEFT')
	l.entry11.text = l.entry11:CreateFontString('entry11_Text', 'BORDER','GameFontHighlightLeft')
	l.entry11.text:SetText('entry11')
	l.entry11.text:SetPoint('LEFT')
	l.entry11:SetWidth(200)
	l.entry11:SetHeight(16)
	l.entry11:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
	l.entry11:EnableMouse(true)
	l.entry11:SetScript('OnClick', EntryClick)
	l.entry11:SetID(11)

	l.entry12 = CreateFrame('Button', 'entry12', l)
	l.entry12:SetPoint('TOPLEFT', entry11, 'BOTTOMLEFT')
	l.entry12.text = l.entry12:CreateFontString('entry12_Text', 'BORDER','GameFontHighlightLeft')
	l.entry12.text:SetText('entry12')
	l.entry12.text:SetPoint('LEFT')
	l.entry12:SetWidth(200)
	l.entry12:SetHeight(16)
	l.entry12:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
	l.entry12:EnableMouse(true)
	l.entry12:SetScript('OnClick', EntryClick)
	l.entry12:SetID(12)

	l.entry13 = CreateFrame('Button', 'entry13', l)
	l.entry13:SetPoint('TOPLEFT', entry12, 'BOTTOMLEFT')
	l.entry13.text = l.entry13:CreateFontString('entry13_Text', 'BORDER','GameFontHighlightLeft')
	l.entry13.text:SetText('entry13')
	l.entry13.text:SetPoint('LEFT')
	l.entry13:SetWidth(200)
	l.entry13:SetHeight(16)
	l.entry13:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
	l.entry13:EnableMouse(true)
	l.entry13:SetScript('OnClick', EntryClick)
	l.entry13:SetID(13)

	l.entry14 = CreateFrame('Button', 'entry14', l)
	l.entry14:SetPoint('TOPLEFT', entry13, 'BOTTOMLEFT')
	l.entry14.text = l.entry14:CreateFontString('entry14_Text', 'BORDER','GameFontHighlightLeft')
	l.entry14.text:SetText('entry14')
	l.entry14.text:SetPoint('LEFT')
	l.entry14:SetWidth(200)
	l.entry14:SetHeight(16)
	l.entry14:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
	l.entry14:EnableMouse(true)
	l.entry14:SetScript('OnClick', EntryClick)
	l.entry14:SetID(14)

	l.entry15 = CreateFrame('Button', 'entry15', l)
	l.entry15:SetPoint('TOPLEFT', entry14, 'BOTTOMLEFT')
	l.entry15.text = l.entry15:CreateFontString('entry15_Text', 'BORDER','GameFontHighlightLeft')
	l.entry15.text:SetText('entry15')
	l.entry15.text:SetPoint('LEFT')
	l.entry15:SetWidth(200)
	l.entry15:SetHeight(16)
	l.entry15:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
	l.entry15:EnableMouse(true)
	l.entry15:SetScript('OnClick', EntryClick)
	l.entry15:SetID(15)

	l.entry16 = CreateFrame('Button', 'entry16', l)
	l.entry16:SetPoint('TOPLEFT', entry15, 'BOTTOMLEFT')
	l.entry16.text = l.entry16:CreateFontString('entry16_Text', 'BORDER','GameFontHighlightLeft')
	l.entry16.text:SetText('entry16')
	l.entry16.text:SetPoint('LEFT')
	l.entry16:SetWidth(200)
	l.entry16:SetHeight(16)
	l.entry16:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
	l.entry16:EnableMouse(true)
	l.entry16:SetScript('OnClick', EntryClick)
	l.entry16:SetID(16)

	l.entry17 = CreateFrame('Button', 'entry17', l)
	l.entry17:SetPoint('TOPLEFT', entry16, 'BOTTOMLEFT')
	l.entry17.text = l.entry17:CreateFontString('entry17_Text', 'BORDER','GameFontHighlightLeft')
	l.entry17.text:SetText('entry17')
	l.entry17.text:SetPoint('LEFT')
	l.entry17:SetWidth(200)
	l.entry17:SetHeight(16)
	l.entry17:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
	l.entry17:EnableMouse(true)
	l.entry17:SetScript('OnClick', EntryClick)
	l.entry17:SetID(17)

	l.entry18 = CreateFrame('Button', 'entry18', l)
	l.entry18:SetPoint('TOPLEFT', entry17, 'BOTTOMLEFT')
	l.entry18.text = l.entry18:CreateFontString('entry18_Text', 'BORDER','GameFontHighlightLeft')
	l.entry18.text:SetText('entry18')
	l.entry18.text:SetPoint('LEFT')
	l.entry18:SetWidth(200)
	l.entry18:SetHeight(16)
	l.entry18:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
	l.entry18:EnableMouse(true)
	l.entry18:SetScript('OnClick', EntryClick)
	l.entry18:SetID(18)
]]

	--confirm import frame
	local c = CreateFrame('Frame', 'CSKConfirmFrame', UIParent,CostaSK.bg);
	c:Hide();

	c:SetWidth(350); 
	c:SetHeight(80);
	c:SetPoint("CENTER");
	c:EnableMouse(true)
	c:SetToplevel(true)
	c:SetMovable(true)
	c:SetClampedToScreen(true)
	c:SetFrameStrata('DIALOG')
	c:SetScript('OnMouseDown', c.StartMoving)
	c:SetScript('OnMouseUp', c.StopMovingOrSizing)

	--confirmframe title
	c.title = c:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
	c.title:SetText('This will delete and replace the existing list.\nAre you sure?')
	c.title:SetPoint('TOP', 0, -15)

	--accept button
	c.accept = CreateFrame('Button', 'AcceptButton', c, "OptionsButtonTemplate")
	c.accept:SetText('Accept')
	c.accept:SetPoint('BOTTOMLEFT', 35, 15)
	c.accept:SetScript('OnClick', AcceptClick)

	--decline button
	c.decline = CreateFrame('Button', nil, c, "OptionsButtonTemplate")
	c.decline:SetText('Decline')
	c.decline:SetPoint('BOTTOMRIGHT', -35, 15)
	c.decline:SetScript('OnClick', DeclineClick)

	--default disable master functions
	CSKListFrame.add:Disable();
	CSKListFrame.del:Disable();
	CSKListFrame.murder:Disable();
	CSKListFrame.up:Disable();
	CSKListFrame.down:Disable();
	CSKListFrame.closeBid:Disable();
	CSKListFrame.import:Disable();

	CSKListFrame.selectedEntry = 0;

	--[[
	--setup tabs
	PanelTemplates_SetNumTabs(CSKListFrame, 3);
	PanelTemplates_TabResize(CSKListFrameTab1, 30)
	PanelTemplates_TabResize(CSKListFrameTab2, 30)
	PanelTemplates_TabResize(CSKListFrameTab3, 30)
	PanelTemplates_SetTab(CSKListFrame, 1);
	]]
	-- Reduce amount of different globals in 1.5.0
	--setup tabs
	PanelTemplates_SetNumTabs(l, 3);
	PanelTemplates_TabResize(l.nTab, 30)
	PanelTemplates_TabResize(l.tTab, 30)
	PanelTemplates_TabResize(l.iTab, 30)
	PanelTemplates_SetTab(l, 1);

	--hooks
	CostaSK:SecureHook("HandleModifiedItemClick", "CSK_HandleModifiedItemClick")

	--comm setup
	CostaSK:RegisterComm("CSKOpenBid", "OpenBidding")
	CostaSK:RegisterComm("CSKSendBid", "ReceiveBid")
	CostaSK:RegisterComm("CSKNewHigh", "HighBidder")
	CostaSK:RegisterComm("CSKCloseBid", "CloseBid");
	CostaSK:RegisterComm("CSKSendRetract", "RetractBid");
	CostaSK:RegisterComm("CSKSyncReq", "ReceiveSyncReq");
	CostaSK:RegisterComm("CSKBroadcast", "ReceiveBroadcast");
	CostaSK:RegisterComm("CSKSendList", "ReceiveList");

	--register for events
	--CostaSK:RegisterEvent("RAID_ROSTER_UPDATE")
	CostaSK:RegisterEvent("GROUP_ROSTER_UPDATE") -- Fixed by Kelzu
end

function CostaSK:OnDisable()
	-- Called when the addon is disabled
end
--[[function CostaSK:IsOfficer() -- 7.3 GuildControlSetRank() is now Protected function
	-- Checking if player can edit Officer Notes instead of Officer Chat speak rights
	return CanEditOfficerNote()
end]]

--is masterlooter and guild officer
function CostaSK:IsOfficer()
  local ret

  if C_GuildInfo.CanEditOfficerNote() then
    ret = true;
  else
    ret = false;
  end
  return ret;
end

--handle RAID_ROSTER_UPDATE event
--function CostaSK:RAID_ROSTER_UPDATE()
function CostaSK:GROUP_ROSTER_UPDATE() -- Fixed by Kelzu
	if (CostaSK:IsMaster()) then
		CSKListFrame.add:Enable();
		CSKListFrame.del:Enable();
		CSKListFrame.murder:Enable();
		CSKListFrame.up:Enable();
		CSKListFrame.down:Enable();
		CSKListFrame.import:Enable();
		Master = true;
	else
		CSKListFrame.add:Disable();
		CSKListFrame.del:Disable();
		CSKListFrame.murder:Disable();
		CSKListFrame.up:Disable();
		CSKListFrame.down:Disable();
		CSKListFrame.closeBid:Disable();
		CSKListFrame.import:Disable();
		Master = false;
	end
	ScrollList_Update();
end

--create list timestamp
function CostaSK:CreateTimeStamp(oldstamp)
	local _, hour, minute = GameTime_GetGameTime(false);
	--local _, month, day, year = CalendarGetDate();
	local CalendarDate = C_DateAndTime.GetTodaysDate() -- CalendarGetDate() came in WotLK, C_DateAndTime was introduced in 8.1 and C_DateAndTime.GetTodaysDate() is available in Classic in 1.5.0, use C_DateAndTime.GetCurrentCalendarTime() on Retail
	local month, day, year = CalendarDate.month, CalendarDate.weekday, CalendarDate.year
	if (hour < 10) then
		hour = "0"..hour;
	end
	if (minute < 10) then
		minute = "0"..minute;
	end
	if (day < 10) then
		day = "0"..day;
	end
	if (month < 10) then
		month = "0"..month;
	end

	local newstr = year..month..day..hour..minute;

	local oldstr = strsub(tostring(oldstamp), 1, -3);
	local oldcount = strsub(tostring(oldstamp), -2)

	local newstamp
	if(newstr == oldstr) then
		newstamp = tonumber(oldstr..oldcount);
		newstamp = newstamp + 1;
	else
		newstamp = tonumber(newstr.."00");
	end
	
	return newstamp;
end

--on csk slash command
function CostaSK:OpenList(input)
--CostaSK:Print(HandleModifiedItemClick);
	ScrollList_Update();
	CSKListFrame:Show();
end

--set item being bid on
function CostaSK:SetOpenItem(item)
	--[[
	local n, l, quality, iL, reqL, t, subT, maxS, equipS, texture = GetItemInfo(item)
	CSKBidFrame.link:AddMessage(item);

	--texture = texture or GetItemIcon(strmatch(item, "item:(%d+)")) -- Fixing the missing/wrong icon bug, Added by Kelzu 1.4.1
	texture = texture or GetItemIcon(item) -- No need to strmatch, itemLink is as good as itemID
	quality = quality or 1 -- Fixing this as well, Added by Kelzu 1.4.1

	if (texture ~= nil) or (quality ~= nil) then
		SetItemButtonTexture(CSKBidFrame.item, texture);
		local r, g, b, hex = GetItemQualityColor(quality); -- local scoped by Kelzu 1.4.1
		SetItemButtonNormalTextureVertexColor(CSKBidFrame.item, r, g, b);
	end
	]]
	-- Doing it the 8.0 way, this should make sure we have the Icon and QualityColor always available to us in 1.5.0
	local i = Item:CreateFromItemLink(item)
	i:ContinueOnItemLoad(function() -- Information should be cached now
		local itemIcon = i:GetItemIcon()
		local r, g, b = i:GetItemQualityColor()

		CSKBidFrame.link:AddMessage(item)

		SetItemButtonTexture(CSKBidFrame.item, itemIcon)
		SetItemButtonNormalTextureVertexColor(CSKBidFrame.item, r, g, b)
	end)
end

--find persons spot in table
function CostaSK:FindInTable(person, list)
	local ret = 0;
	if (list == "nList") then
		for i=1, CostaSK.db.realm.nLength, 1 do
			if (CostaSK.db.realm.nList[i].name == person) then
				ret = i;
			end
		end
	else
		for i=1, CostaSK.db.realm.tLength, 1 do
			if (CostaSK.db.realm.tList[i].name == person) then
				ret = i;
			end
		end
	end
	return ret;
end

--open bid frame for everyone
function CostaSK:OpenBidding(prefix, message, distribution, sender)
	ItemLink = message;
	CostaSK:SetOpenItem(ItemLink);
	CSKBidFrame:Show();
end

--close bid frame on bid close
function CostaSK:CloseBid(prefix, message, distribution, sender)
	CSKBidFrame:Hide();
	CSKBidFrame.offspec:Enable();
	CSKBidFrame.pass:Enable();
	CSKBidFrame.bid:Enable();
	CSKBidFrame.retract:Disable();
	CSKBidFrame.text:SetText('<No High Bidder>');
	CSKBidFrame.text:SetTextColor(1, 1, 1);

	for i=1, CostaSK.db.realm.nLength, 1 do
		CostaSK.db.realm.nList[i].bid = "";
	end

	for i=1, CostaSK.db.realm.tLength, 1 do
		CostaSK.db.realm.tList[i].bid = "";
	end

	ScrollList_Update();
	
end


--determine which list to use based on item
function CostaSK:WhichList()
	--local _, _, _, _, _, iType, iSubType, _, _, _ = GetItemInfo(ItemLink);
	local _, _, _, _, _, iType, iSubType, _, _, _, _, _, _, _, _, itemSetID = GetItemInfo(ItemLink) -- 7.3 Tier-item fix
	--if (iType == "Miscellaneous") and (iSubType == "Junk") then
	if itemSetID or (not itemSetID and (iType == AUCTION_CATEGORY_MISCELLANEOUS and iSubType == BAG_FILTER_JUNK)) then -- Checked from DE variant of GlobalStrings.lua, Misc can be also MISCELLANEOUS ?
		return "tList";
	else
		return "nList";
	end
end

--find high roller
function CostaSK:FindHighRoller()
	local roll = 0; 
	local name = "";
	local found = false;
	for i=1, OffspecCount, 1 do 
		if (OffspecList[i].roll > roll) and (OffspecList[i].retracted == false) then
			roll = OffspecList[i].roll;
			name = OffspecList[i].name;
			found = true;
			break -- 1.5.0
		end
	end
	if (found) then
		return name, roll;
	else
		return "", 0;
	end
end

--find roller by name and remove
function CostaSK:RemoveRoller(name) 
	for i=1, OffspecCount, 1 do 
		if (OffspecList[i].name == name) then
			OffspecList[i].retracted = true;
			break -- 1.5.0
		end
	end
	--return name, roll;
	return true -- 1.5.0
end

--find bidder by name and remove
function CostaSK:RemoveBidder(name)
	local list = CostaSK:WhichList();
	local rank = CostaSK:FindInTable(name, list);
	local bidrank = 0;
	for index,value in ipairs(BidList) do 
		if (value == rank) then
			bidrank = index;
			break -- 1.5.0
		end
	end
	table.remove(BidList, bidrank);
	table.sort(BidList);
end

--add a roller
function CostaSK:AddRoller(name)
	local found = false;
	local roll;
	for i=1, OffspecCount, 1 do 
		if (OffspecList[i].name == name) and (OffspecList[i].retracted) then
			OffspecList[i].retracted = false;
			roll = OffspecList[i].roll;
			found = true;
			break -- 1.5.0
		end
	end
	--add to OffspecList
	if(found == false) then
		roll = math.random(1, 1000);
		OffspecCount = OffspecCount+1;
		OffspecList[OffspecCount] = {name = name, roll = roll, retracted = false}
	end
	return roll;
end

--update bid in list
function CostaSK:AddBidToList(bid, list, rank)
	if(list == "nList") then
		CostaSK.db.realm.nList[rank].bid = bid;
	elseif(list == "tList") then
		CostaSK.db.realm.tList[rank].bid = bid;
	end
	ScrollList_Update();
end

--update winner
function CostaSK:UpdateWinner()
	if (HighName ~= "") then
		local list = CostaSK:WhichList();
		local _, englishClass = UnitClass(HighName)
		CostaSK:SendCommMessage("CSKNewHigh", CostaSK:Serialize("Bid: "..HighRank..". "..HighName, englishClass), "RAID");
	elseif (HighRoller ~= "") then
		local _, englishClass = UnitClass(HighRoller)
		CostaSK:SendCommMessage("CSKNewHigh", CostaSK:Serialize("Offspec: "..HighRoller..": "..HighRoll, englishClass), "RAID");
	else
		CostaSK:SendCommMessage("CSKNewHigh", CostaSK:Serialize("<No High Bidder>", "PRIEST"), "RAID");
	end
end

--receive bid
function CostaSK:ReceiveBid(prefix, message, distribution, sender)
	if (BidNotOpen == false) then
		local success, bidType, bidder = CostaSK:Deserialize(message);
		local list = CostaSK:WhichList();
		local rank = CostaSK:FindInTable(bidder, list);

		--make sure a bid is open and person is in the list
		if(rank ~= 0) then
			if (Master) then
				BidsReceived = BidsReceived + 1;

				if (bidType == "bid") then
					table.insert(BidList, rank);
					table.sort(BidList);
					if (rank < HighRank) then
						HighRank = rank;
						HighName = bidder;
					end
				elseif (bidType == "offspec") then
					--gerenate random number 1-1000 and add to offspec list
					local roll = CostaSK:AddRoller(bidder);

					--display in raid chat
					SendChatMessage(bidder.." rolls "..roll.." (1-1000)" , "RAID");
					HighRoller, HighRoll = CostaSK:FindHighRoller();
				end

				CostaSK:UpdateWinner();

				--if (BidsReceived == GetNumRaidMembers()) then
				if (BidsReceived == GetNumGroupMembers()) then -- Fixed by Kelzu
					SendChatMessage("All bids received!" , "RAID");
				end
			end

			if (bidType == "bid") then
				CostaSK:AddBidToList("Bid", list, rank);
			elseif (bidType == "offspec") then
				CostaSK:AddBidToList("Offspec", list, rank);
			elseif (bidType == "pass") then
				CostaSK:AddBidToList("Pass", list, rank);
			end
		else
			if (Master) then
				CostaSK:Print(string.format("|cffff0000Warning:|r %s tried to bid '%s' while not on %s list.", bidder, bidType, list == "nList" and "normal" or "token"))
			end
		end
	end
end

--receive a request to sync
function CostaSK:ReceiveSyncReq(prefix, message, distribution, sender)
	if (message == "master") and (CostaSK:IsOfficer()) and (Master == false) then
		CostaSK:SendCommMessage("CSKBroadcast", CostaSK:Serialize(CostaSK.db.realm.nStamp, CostaSK.db.realm.nLength, CostaSK.db.realm.nList, CostaSK.db.realm.tStamp, CostaSK.db.realm.tLength, CostaSK.db.realm.tList), "GUILD");
	elseif (message == "not master") and (Master) then
		CostaSK:SendCommMessage("CSKBroadcast", CostaSK:Serialize(CostaSK.db.realm.nStamp, CostaSK.db.realm.nLength, CostaSK.db.realm.nList, CostaSK.db.realm.tStamp, CostaSK.db.realm.tLength, CostaSK.db.realm.tList), "GUILD");
	end
end

--receive list broadcast from master via guild
function CostaSK:ReceiveBroadcast(prefix, message, distribution, sender)
	local success, nstamp, nlength, nlist, tstamp, tlength, tlist = CostaSK:Deserialize(message);
	--if (Master == false) then
		if (tonumber(nstamp) > CostaSK.db.realm.nStamp) then
			CostaSK.db.realm.nStamp = tonumber(nstamp);
			CostaSK.db.realm.nLength = tonumber(nlength);
			CostaSK.db.realm.nList = nlist;
		end
		if (tonumber(tstamp) > CostaSK.db.realm.tStamp) then
			CostaSK.db.realm.tStamp = tonumber(tstamp);
			CostaSK.db.realm.tLength = tonumber(tlength);
			CostaSK.db.realm.tList = tlist;
		end
	--end
	if (Master) then
		CostaSK:SendCommMessage("CSKSendList", CostaSK:Serialize(CostaSK.db.realm.nStamp, CostaSK.db.realm.nLength, CostaSK.db.realm.nList, CostaSK.db.realm.tStamp, CostaSK.db.realm.tLength, CostaSK.db.realm.tList), "RAID");
	end

	ScrollList_Update();
end

--master rebroadcasts list update via guild to raid
function CostaSK:ReceiveList(prefix, message, distribution, sender)
	local success, nstamp, nlength, nlist, tstamp, tlength, tlist = CostaSK:Deserialize(message);
	--if (Master) then
		if (tonumber(nstamp) > CostaSK.db.realm.nStamp) then
			CostaSK.db.realm.nStamp = tonumber(nstamp);
			CostaSK.db.realm.nLength = tonumber(nlength);
			CostaSK.db.realm.nList = nlist;
		end
		if (tonumber(tstamp) > CostaSK.db.realm.tStamp) then
			CostaSK.db.realm.tStamp = tonumber(tstamp);
			CostaSK.db.realm.tLength = tonumber(tlength);
			CostaSK.db.realm.tList = tlist;
		end
	--end
	ScrollList_Update();
end

--retract bid
function CostaSK:RetractBid(prefix, message, distribution, sender)
	if (BidNotOpen == false) then
		local success, bidType, bidder = CostaSK:Deserialize(message);
		local list1 = CostaSK:WhichList();
		local rank = CostaSK:FindInTable(bidder, list1);

		--make sure a bid is open and person is in the list
		if (rank ~= 0) then
			if (Master) then

				BidsReceived = BidsReceived - 1;

				if(bidType == "bid") then
					CostaSK:RemoveBidder(bidder);
					SendChatMessage(bidder.." has retracted their bid." , "RAID");

					if(BidList[1] ~= nil) then
						HighRank = BidList[1];
						local list = CostaSK:WhichList();
						if(list == "nList") then
							HighName = CostaSK.db.realm.nList[HighRank].name;
						else
							HighName = CostaSK.db.realm.tList[HighRank].name;
						end
					else
						HighRank = 5000;
						HighName = "";
					end
				elseif (bidType == "offspec") then
					CostaSK:RemoveRoller(bidder);
					HighRoller, HighRoll = CostaSK:FindHighRoller();
					SendChatMessage(bidder.." has retracted their roll." , "RAID");
				elseif (bidType == "pass") then
					SendChatMessage(bidder.." has retracted their pass." , "RAID");
				end
				CostaSK:UpdateWinner();
			end

			local list = CostaSK:WhichList();
			local rank = CostaSK:FindInTable(bidder, list);

			if(list == "nList") then
				CostaSK.db.realm.nList[rank].bid = "";
			elseif(list =="tList") then
				CostaSK.db.realm.tList[rank].bid = "";
			end
			ScrollList_Update();
		end
	end
end


--update high bidder
function CostaSK:HighBidder(prefix, message, distribution, sender)
	local success, text, class = CostaSK:Deserialize(message);
	local color = RAID_CLASS_COLORS[class];
	CSKBidFrame.text:SetText(text);
	CSKBidFrame.text:SetTextColor(color.r, color.g, color.b);
end

--hook alt clicks to open bid
function CostaSK:CSK_HandleModifiedItemClick(item)
	if (Master) then
		if (BidNotOpen) then
			if (IsAltKeyDown() and 
				not IsShiftKeyDown() and 
					not IsControlKeyDown()) then
				ItemLink = item;
				--local _ = GetItemInfo(ItemLink) -- Try to cache GetItemInfo for detecting Tier-items in 7.3 -- We don't need this anymore in 1.5.0
				CostaSK:SendCommMessage("CSKOpenBid", ItemLink, "RAID");
				BidNotOpen = false;
				CSKListFrame.closeBid:Enable();
			end
		end
	end
end


