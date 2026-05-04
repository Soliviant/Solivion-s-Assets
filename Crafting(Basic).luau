--Soliviant's Basic Crafting System, Find the bindableEvent under this script and then :Fire() your part(To be used as a crafting table, for the prompt to work) inside of it in.
--May 4th 2026 By @Solivion.
export type structure = {name:string, class:string, child: {structure}}
local Item: {string: Instance} = {} -- for example: {nameHere: Tool.Directory or namehere: string here(For simple name checking)}
local Recipes: {string: {string}} = {} -- for repeated ingredient just repeat it, noway you'd use 999 metal scrap to craft something right?
local allTable = {} -- crafting tables
local offsetMul = 75
local PromptSpeed = 160 --tween speed for prompts
local MinigameFail = 5
local MinigameRequired = 10
local MinigameTime = 60
local PromptKeyCodeWhiteList = {
	Enum.KeyCode.B, Enum.KeyCode.C, Enum.KeyCode.E,
	Enum.KeyCode.F, Enum.KeyCode.G, Enum.KeyCode.H, Enum.KeyCode.I, Enum.KeyCode.J,
	Enum.KeyCode.K, Enum.KeyCode.L, Enum.KeyCode.M, Enum.KeyCode.N, Enum.KeyCode.O,
	Enum.KeyCode.P, Enum.KeyCode.Q, Enum.KeyCode.R, Enum.KeyCode.T,
	Enum.KeyCode.U, Enum.KeyCode.V, Enum.KeyCode.X, Enum.KeyCode.Y, Enum.KeyCode.Z,
	Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Four, Enum.KeyCode.Five,
	Enum.KeyCode.Six, Enum.KeyCode.Seven, Enum.KeyCode.Eight, Enum.KeyCode.Nine, Enum.KeyCode.Zero,
	Enum.KeyCode.F1, Enum.KeyCode.F2, Enum.KeyCode.F3, Enum.KeyCode.F4, Enum.KeyCode.F5,
	Enum.KeyCode.F6, Enum.KeyCode.F7, Enum.KeyCode.F8, Enum.KeyCode.F9, Enum.KeyCode.F10,
	Enum.KeyCode.F11, Enum.KeyCode.F12, Enum.KeyCode.Return, Enum.KeyCode.Tab, Enum.KeyCode.BackSlash,
	Enum.KeyCode.Slash, Enum.KeyCode.Period, Enum.KeyCode.Comma, Enum.KeyCode.Minus,
	Enum.KeyCode.Equals, Enum.KeyCode.LeftBracket, Enum.KeyCode.RightBracket,
	Enum.KeyCode.Semicolon, Enum.KeyCode.Quote, Enum.KeyCode.Backspace
}
local WhereResult: {string: Instance} = {} -- result LIST HERE, name based on the same key as the recipe
--all workbench share same recipe above, if u want unique per bench then please make this script use metatable and put module under the workbench, I will NEVER make it so complicated.

--Core
local EntryLater = {}
function validInstance(Instance: Instance) return typeof(Instance) == 'Instance' and Instance.Parent end
local TweenService = game:GetService('TweenService')
if typeof(PromptSpeed) ~= 'number' then PromptSpeed = 160 end
function MovePromptTo(Prompt:Instance, Offset:Vector2)
	if not validInstance(Prompt) or not Prompt.ClassName:lower():match('proximityprompt') or typeof(Offset) ~= 'Vector2' then return end
	local a = pcall(function() TweenService:Create(Prompt, TweenInfo.new((Prompt.UIOffset - Offset).Magnitude/160), {UIOffset = Offset}):Play() end)
	if not a then pcall(function() Prompt.UIOffset = Offset end) end
end
if next(allTable) then for i,v in allTable do if validInstance(v) then if typeof(EntryLater) ~= 'table' then EntryLater = {} end table.insert(EntryLater, v) else warn("Table Invalid") end end end
for i,v in Recipes do if typeof(v) ~= 'table' then warn('atleast one of the recipe it formatted incorrectly, must use {string(s)}') return end for a,b in v do if typeof(b) ~= 'string' then warn("inside recipe tables must be string") return end end end
for i,v in Item do if not validInstance(v) and typeof(v) ~= 'string' then warn('ingredient item is not properly formatted, but be "string = DirectoryOftheItem or string(Name)"]') return end end
for i,v in WhereResult do if not validInstance(v) then warn('result item is not properly formatted, but be "string = DirectoryOftheItem"]') return end end
for i,v in PromptKeyCodeWhiteList do if tostring(typeof(v)):lower() ~= "enumitem" then warn(tostring(v), ' is not EnumItem') return end end
if typeof(offsetMul) ~= 'number' then offsetMul = 75 end
if typeof(MinigameFail) ~= 'number' then MinigameFail = 5 end
if typeof(MinigameRequired) ~= 'number' then MinigameRequired = 5 end
if typeof(MinigameTime) ~= 'number' then MinigameTime = 60 end
local Players = game:GetService("Players")
local NameBased: {string} = {}
local StructureBased: {string: structure} = {}
for i,v in Item do
	if typeof(i) == 'string' and typeof(v) == 'Instance' then
		--serialize
		local function cavedive(thing)
			if typeof(thing) ~= 'Instance' then return {} end
			local a = {}
			for _,the in thing:GetChildren() do
				table.insert(a, {name = the.Name, class = the.ClassName, child = cavedive(the)})
			end
			return a
		end
		StructureBased[i:lower()] = {name = v.Name, class = v.ClassName, child = cavedive(v)}
	elseif typeof(v) == 'table' and typeof(v.name) == 'string' and typeof(v.classname) == 'string' then
		NameBased[v.name:lower()] = v.classname
	end
end
function trim(str: string) if typeof(str) ~= 'string' then return '' end
	return string.gsub(str, "^%s*(.-)%s*$", "%1")
end
function ItemIs(item: Instance)
	if typeof(item) ~= 'Instance' then return false end
	local query = trim(item.Name:lower())
	if typeof(StructureBased[query]) == 'table' and typeof(StructureBased[query].child) == 'table' then
		local function check(a, name, val, child, used)
			if typeof(a) ~= 'Instance' then return false end
			if a.Name ~= name or a.ClassName ~= val then return false end
			if typeof(child) == 'table' then
				local localUsed = {}
				for _, expectedChild in child do
					local found = false
					for _, actualChild in a:GetChildren() do
						if not localUsed[actualChild] and check(actualChild, expectedChild.name, expectedChild.class, expectedChild.child, localUsed) then
							found = true
							localUsed[actualChild] = true
							break
						end
					end
					if not found then return false end
				end
			end

			return true
		end

		local valid = true
		local usedChildren = {}
		for _, v in StructureBased[query].child do
			if not valid then break end
			local found = false
			for _, childInstance in item:GetChildren() do
				if not usedChildren[childInstance] and check(childInstance, v.name, v.class, v.child, usedChildren) then
					found = true
					usedChildren[childInstance] = true
					break
				end
			end
			if not found then valid = false end
		end
		return ((valid and query) or false)
	end
	if (item.ClassName == NameBased[query]) or '' then
		return query
	end
end
function get_difference(tableA, tableB) if typeof(tableA) ~= 'table' or typeof(tableB) ~= 'table' then return {}, {} end 
	local diffA = {}
	local diffB = {}
	local matched_indices_B = {}
	-- Find items in A that are not in B (accounting for counts)
	for _, valA in ipairs(tableA) do
		local found = false
		for i, valB in ipairs(tableB) do
			if not matched_indices_B[i] and valA == valB then
				matched_indices_B[i] = true
				found = true
				break
			end
		end

		if not found then
			table.insert(diffA, valA)
		end
	end
	-- Find items in B that were never matched by an item in A
	for i, valB in ipairs(tableB) do
		if not matched_indices_B[i] then
			table.insert(diffB, valB)
		end
	end
	return diffA --, diffB
end
function is_subset(tableA, tableB) if typeof(tableA) ~= 'table' or typeof(tableB) ~= 'table' then return false end 
	local used_indices = {}
	for _, valA in ipairs(tableA) do
		local found = false
		for i, valB in ipairs(tableB) do
			if valA == valB and not used_indices[i] then
				used_indices[i] = true found = true
				break
			end
		end
		if not found then return false end
	end
	return true
end

function QueryRecipe(Query :{string})
	if typeof(Query) ~= 'table' then return {} end
	local viable = {}
	for i,v in Recipes do if typeof(v) ~= 'table' then pcall(function() warn("Invalid Recipe, Must be table: ", tostring(i)) end) continue end
		local A = is_subset(Query, v)
		local B = is_subset(v, Query)
		if A or B then
			if B then -- ready 
				table.insert(viable, 1, {name = i, done = true, required = v}) -- done, no need to check, return required for resource tracking in the crafting state
			else 
				table.insert(viable, (#viable + 1), {name = i, required = v}) -- need more stuff
			end
		end
	end return viable
end

function GetPlayer(Character: Instance)
	if typeof(Character) ~= 'Instance' or not Character.Parent or not Character:FindFirstChildOfClass("Humanoid") then return end
	for i,v in Players:GetChildren() do
		if typeof(v) ~= 'Instance' or not v.ClassName:lower():match('player') then continue end
		if v.Character == Character then
			return v
		end
	end
end 

function Gui(Player: Instance)
	if typeof(Player) ~= 'Instance' or not Player.Parent then return end
	return Player:FindFirstChildOfClass("PlayerGui")
end 

--find first child of name and class
function FFCONAC(Parent: Instance, Name: string, Class: string?, Recursive: boolean?)
	if typeof(Parent) ~= 'Instance' or not Parent.Parent or typeof(Name) ~= 'string' then return end
	if typeof(Recursive) ~= 'boolean' then Recursive = false end
	local ClassIdentified = typeof(Class) == 'string' and Class or nil
	for i,v in (Recursive and Parent:GetDescendants() or Parent:GetChildren()) do
		if v.Name:match(Name) and (not ClassIdentified or (v.ClassName:lower() == ClassIdentified:lower() or v:IsA(ClassIdentified))) then
			return v
		end
	end
end

function FakeEvent()
	local Fake = {}
	function Fake:Connect() end function Fake:Once() end function Fake:ConnectParellel() end function Fake:Wait() end function Fake:Disconnect() end function Fake:DisconnectAll() end function Fake:Destroy() end
	function Fake:Fire() end
	return Fake
end
function Default(Class: string) 
	if typeof(Class) ~= 'string' then if Class then return Class else return false end end if Class == 'number' then return 0 elseif Class == 'clock' then return os.clock() elseif Class == 'string' then return '' elseif Class == 'table' then return {} elseif Class == 'boolean' then return false elseif Class == 'instance' then 
		local Mime = {Parent = workspace or Default('Instance'),  ClassName = 'Mime', UniqueId = Default('number') or 0, Sandboxed = true, Archivable = false, Attributes = {}, PredictionMode = {Value = 'null', Name = 'null'}, Capabilities = {Value = 'null', Name = 'null'}, Children = {}, Tag = {}}
		Mime.__newindex = function(_, key, value)if key == "Parent" then if Mime.Parent and type(Mime.Parent) == "table" and Mime.Parent:GetChildren() then local oldSiblings = Mime.Parent:GetChildren() local idx = table.find(oldSiblings, Mime) if idx then table.remove(oldSiblings, idx) end end Mime.Parent = value if value and type(value) == "table" and value:GetChildren() then table.insert(value:GetChildren(), Mime) end else Mime[key] = value end end
		Mime.__tostring = function() return Mime.Name or 'MIME' end Mime.__metatable = function() warn("Cannot Wrap MIME") end Mime.__tonumber = function() return Mime.UniqueId or 0 end Mime.__getmetatable = function() warn("Cannot Wrap MIME") end Mime.__call = function() return Mime end Mime.__typeof = function() return 'Mime' end Mime.__type = function() return 'table' end
		Mime.Destroying = FakeEvent() Mime.ChildAdded = FakeEvent() Mime.ChildRemoved = FakeEvent() Mime.Changed = FakeEvent() Mime.DescendantAdded = FakeEvent() Mime.DescendantRemoving = FakeEvent() Mime.AncestryChanged = FakeEvent() Mime.AttributeChanged = FakeEvent() 
		function Mime:GetAttributeChangedSignal() return FakeEvent() end function Mime:GetPropertyChangedSignal() return FakeEvent() end function Mime:AddTag(any: any) if typeof(Mime.Tag) ~= 'table' then Mime.Tag = {} end table.insert(Mime.Tag, any) end function Mime:RemoveTag(any: any) if typeof(Mime.Tag) ~= 'table' then Mime.Tag = {} return end local indice = table.find(Mime.Tag, any) if type(indice) == 'number' then table.remove(Mime.Tag, indice) end end function Mime:SetAttribute(key: any,any: any) if typeof(key) == 'nil' then return end  if typeof(Mime.Attributes) ~= 'table' then Mime.Attributes = {} end Mime.Attributes[key] = any end function Mime:GetAttribute(key: any) if typeof(key) == 'nil' then return nil end return (Mime.Attributes or {})[key] end function Mime:Destroy() Mime.Parent = nil Mime:ClearAllChildren() Mime.Children = {} end function Mime:FindFirstAncestor() end function Mime:ClearAllChildren() if typeof(Mime.Children) == 'table' then for i,v in Mime.Children do v:Destroy() end end Mime.Children = {} end function Mime:FindFirstAncestorOfClass() end function Mime:FindFirstAncestorWhichIsA() end function Mime:GetActor() return nil end  function Mime:GetChildren() if typeof(Mime.Children) ~= 'table' then Mime.Children = {} end return Mime.Children or {} end function Mime:GetDescendants() if typeof(Mime.Children) ~= 'table' then Mime.Children = {} end local Accumulated = {} for i,v in Mime:GetChildren() do if not table.find(Accumulated,v) then table.insert(Accumulated, v) end for _, x in v:GetDescendants() do if not table.find(Accumulated, x) then table.insert(Accumulated, x) end end end return Accumulated or {} end function Mime:FindFirstChild(name: string) for i,v in Mime:GetChildren() do if typeof(v) == 'table' and v.Name:match(name) then return v end end end function Mime:FindFirstChildOfClass(...) --[[there is only one class]] return Mime:FindFirstChild(...) end function Mime:FindFirstChildWhichIsA(...) --[[there is only one class]] return Mime:FindFirstChild(...) end function Mime:Clone() return table.clone(Mime) end elseif Class == 'vector3' then return Vector3.zero elseif Class == 'vector2' then return Vector2.zero elseif Class == 'cframe' then return CFrame.new() elseif Class == 'rect' then return Rect.new(0, 0, 0, 0) elseif Class == 'color3' then return Color3.new(0, 0, 0) elseif Class == 'brickcolor' then return BrickColor.new("White") elseif Class == 'colorsequence' then return ColorSequence.new(Color3.new(1, 1, 1)) elseif Class == 'numbersequence' then return NumberSequence.new(0) elseif Class == 'numberrange' then return NumberRange.new(0) elseif Class == 'udim' then return UDim.new(0, 0) elseif Class == 'udim2' then return UDim2.new(0,0,0,0) end
return false end

--InitialState MUST BE ITEMINPUT
export type State = ("Minigame" | "ItemInput" | "EmptyState" | "CraftingSelection" | "Retrieving")
local BaseBenchStruct = {State = 'string', HoldingItem = 'table', HoldingItemString = 'table', UsedBind = 'table', __temp = 'table', ProximityPrompts = 'table', --[[Current Player and Other Run Time Stuff Checked Later]]}
local Workbenches = {}

function Bind(ProximityPrompt, Used: {string}) if not validInstance(ProximityPrompt) then return end if typeof(Used) ~= 'table' then Used = {} end 
	local ReggedKeys = typeof(PromptKeyCodeWhiteList) == 'table' and PromptKeyCodeWhiteList or Enum.KeyCode:GetEnumItems()
	local Found = nil
	for i,v in ReggedKeys do
		if not table.find(Used, v.Name:lower()) then local Pass = pcall(function() ProximityPrompt.KeyboardKeyCode = v end) if not Pass then continue end Found = v.Name:lower() break end
	end
	if not Found then --[[no choice, use E]] ProximityPrompt.KeyboardKeyCode = Enum.KeyCode.E end
	return Found
end
function Entry(PhysicalBench: Instance, ReqData: {}?) -- ReqData Checked Against BenchStruct
	if not validInstance(PhysicalBench) or Workbenches[PhysicalBench] then return end
	if typeof(ReqData) ~= 'table' then ReqData = {} end
	for i,v in BaseBenchStruct do
		if (typeof(ReqData[v]) or 'nuller'):lower() ~= v:lower() then ReqData[v] = Default(v) end  
	end
	local Bench = table.clone(ReqData or {}) or {}
	local BenchStorage = game:FindFirstChildOfClass('ServerStorage'):FindFirstChild('Storage__'..PhysicalBench:GetFullName())
	if not validInstance(BenchStorage) then BenchStorage = Instance.new('Folder', game:FindFirstChildOfClass('ServerStorage')) or Default('instance') BenchStorage.Name = 'Storage__'..PhysicalBench:GetFullName() end
	function Bench:UpdateItemTable()
		if not validInstance(BenchStorage) then return end
		local Refreshed = {}
		for i,v in BenchStorage:GetChildren() do
			table.insert(Refreshed, v)
		end
		Bench.HoldingItem = Refreshed or {}
		Bench:UpdateStringTable()
	end
	function Bench:UpdateStringTable()
		if typeof(Bench.HoldingItem) ~= 'table' then Bench.HoldingItem = {} Bench.HoldingItemString = {} return end
		local NewTable = {}
		for i,v in Bench.HoldingItem do
			local Identified = ItemIs(v) if typeof(Identified) ~= 'string' then continue end
			table.insert(NewTable, Identified)
		end
		Bench.HoldingItemString = NewTable or {}
	end
	function Bench:StoreItem(Item: Instance)
		if not validInstance(Item) then return end
		local Identified = ItemIs(Item) if typeof(Identified) ~= 'string' then return end
		if typeof(Bench.HoldingItem) ~= 'table' then Bench.HoldingItem = {} end
		if table.find(Bench.HoldingItem, Item) then return end
		local HoldIn = BenchStorage or Default('instance')
		if typeof(HoldIn) ~= 'Instance' then return end	
		table.insert(Bench.HoldingItem, Item) table.insert(Bench.HoldingItemString, Identified)
		pcall(function() Item.Parent = HoldIn end)
		task.spawn(function() while validInstance(BenchStorage) and not table.find(BenchStorage:GetChildren(), Item) and table.find(Bench.HoldingItemString, Identified) and table.find(Bench.HoldingItem, Item) do task.wait(.1) pcall(function() Item.Parent = BenchStorage end) end if not validInstance(PhysicalBench) then Bench:Destroy() return end --[[whoops]] if not validInstance(BenchStorage) then BenchStorage = Instance.new('Folder', game:FindFirstChildOfClass('ServerStorage')) or Default('instance') BenchStorage.Name = 'Storage__'..PhysicalBench:GetFullName() end end)
		if #Bench.HoldingItem ~= #Bench.HoldingItemString then Bench:UpdateStringTable() end -- inaccurate reading
	end
	function Bench:NewPrompt(Label: string, Act: string?, Obj: string?, Offset: Vector2?) if typeof(Label) ~= 'string' or typeof(Bench.ProximityPrompts) ~= 'table' then Bench.ProximityPrompts = {} end
		local Prompt = Instance.new('ProximityPrompt', (validInstance(PhysicalBench) and (PhysicalBench:IsA('Model') and PhysicalBench.PrimaryPart) or PhysicalBench:FindFirstChildOfClass('BasePart') or PhysicalBench)) or workspace:FindFirstChildOfClass('BasePart') or workspace or script or Default('instance')
		pcall(function() if typeof(Act) == 'string' then Prompt.ActionText = Act end end)
		pcall(function() if typeof(Obj) == 'string' then Prompt.ObjectText = Obj end end)
		pcall(function() if typeof(Offset) == 'Vector2' then MovePromptTo(Prompt, Offset * offsetMul) end end)
		pcall(function() Prompt.RequiresLineOfSight = false end)
		pcall(function()  local Binded = Bind(Prompt, Bench.UsedBind)
		if typeof(Binded) == 'string' then
			if typeof(Bench.UsedBind) ~= 'table' then Bench.UsedBind = {} end
			table.insert(Bench.UsedBind, Binded)
		end end)
		if not validInstance(Bench.ProximityPrompts[Label]) or Bench.ProximityPrompts[Label] ~= Prompt then if validInstance(Bench.ProximityPrompts[Label]) then pcall(function() Bench.ProximityPrompts[Label]:Destroy() end) end Bench.ProximityPrompts[Label] = Prompt end
		return Prompt
	end
	function Bench:ClearPrompt(Except: {}?)
		if typeof(Except) ~= 'table' then Except = {} end if typeof(Bench.ProximityPrompts) ~= 'table' then Bench.ProximityPrompts = {} return end
		local RemoveSoon = {}
		for i,v in Bench.ProximityPrompts do
			if not table.find(Except, v) then table.insert(RemoveSoon, v) end
		end
						--[[if validInstance(PhysicalBench) then
	for i,v in PhysicalBench:GetChildren() do if not v.ClassName:lower():match('proximityprompt') then continue end
				if not table.find(Except, v) and v:GetAttribute("Wired__") then table.insert(RemoveSoon, v) end
	end end]] -- could destroy external ProximityPrompts
		for i,v in RemoveSoon do
			pcall(function() if table.find(Bench.ProximityPrompts, v) then table.remove(Bench.ProximityPrompts, table.find(Bench.ProximityPrompts, v)) end end)
			pcall(function() v:Destroy() end)
		end
		RemoveSoon = nil
	end
	function Bench:CreateResult(Name: string) -- from recipe to result 
		if typeof(Name) ~= 'string' then return Default('instance') end
		if not validInstance(WhereResult[Name]) then warn('Result for '..Name.. ' is not valid!') return end
		local Result = WhereResult[Name]:Clone() or Default('instance')
		Result.Parent = BenchStorage or PhysicalBench or workspace
		if not validInstance(Result) then warn('Clone Result for '..Name.. ' is not valid! Is .Archivable On?') return end
		return Result
	end
	function Bench:Craft(IDName: string,Recipe: {}) -- safely handles step by step. before making actual changes
		if typeof(Recipe) ~= 'table' or typeof(IDName) ~= 'string' then return end -- must be from Query, so we get the .required table from the struct
		if typeof(Recipe.required) ~= 'table' then return end
		Bench:UpdateItemTable() if typeof(Bench.HoldingItem) ~= 'table' then warn('something wrong about UpdateItemTable: VALUE NOT TABLE') return end if #Bench.HoldingItem <= 0 then return end -- NO ITEM
		if typeof(Bench.HoldingItemString) ~= 'table' then Bench:UpdateItemTable() end
		if #Bench.HoldingItem ~= #Bench.HoldingItemString then Bench:UpdateStringTable() end -- refresh
		if not is_subset(Recipe.required ,Bench.HoldingItemString) then return end --not READY
		local MarkForDeletion = {} -- used
		local stringclone = table.clone(Bench.HoldingItemString) -- clone to not modify the original
		local used = {}
		for i,v in Recipe.required do
			local Item = table.find(stringclone, v)
			if not Item then return end -- not ready
			table.remove(stringclone, Item)
			for a,b in Bench.HoldingItem do
				if ItemIs(b) == v and not used[a] then used[a] = true table.insert(MarkForDeletion, b) break end
			end
		end
		local clone = table.clone(Bench.HoldingItem)
		for i,v in MarkForDeletion do
			if not table.find(Bench.HoldingItem, v) then return end -- FALSE ITEM ALERT
			if not table.find(clone, v) then return else table.remove(clone, table.find(clone, v)) end
		end
		local item = Bench:CreateResult(IDName)
		if not validInstance(item) then pcall(function() item:Destroy() item = nil end) return end -- halt, Result not valid
		for i,v in MarkForDeletion do
			pcall(function()
				v:Destroy()
			end)
		end
		Bench.HoldingItem = clone
		Bench.HoldingItemString = stringclone
		if typeof(Bench.HoldingItem) ~= 'table' then Bench:UpdateItemTable() end
		if typeof(Bench.HoldingItemString) ~= 'table' then Bench.HoldingItemString = {} end
		pcall(function()	if #Bench.HoldingItem ~= #Bench.HoldingItemString then Bench:UpdateStringTable() end end)
		--we gotta generate crafting result here, things have already been correctly subtracted from the table
		if validInstance(Bench.CurrentPlayer) and validInstance(Bench.CurrentPlayer.Character or Bench.CurrentPlayer:FindFirstChildOfClass("Backpack") or workspace) then
			local goTo = Bench.CurrentPlayer.Character or Bench.CurrentPlayer:FindFirstChildOfClass("Backpack") or workspace
			pcall(function() item.Parent = goTo end)
			task.spawn(function()
				while validInstance(goTo) and validInstance(item) and item.Parent ~= goTo do
					task.wait(1)
					item.Parent = goTo
				end
				if not validInstance(item) then return end
				if not validInstance(goTo) then item.Parent = workspace or Default('instance') end
			end)
		else
			Bench:StoreItem(item)
		end
	end
	function Bench:RemoveItem(Item: Instance, ToParent: Instance?)
		if not validInstance(Item) then return end
		if not table.find(Bench.HoldingItem, Item) then return end
		if validInstance(ToParent) then pcall(function() Item.Parent = ToParent end) task.spawn(function() while validInstance(ToParent) and validInstance(Item) and Item.Parent ~= ToParent do task.wait(1) pcall(function() Item.Parent = ToParent end) end if not validInstance(Item) then return end if not validInstance(ToParent) then Item.Parent = workspace or Default('instance') end end) else Item:Destroy() end
		Bench:UpdateItemTable()
		Bench:UpdateStringTable()
	end
	function Bench:Destroy()
		pcall(function() Bench:UpdateItemTable() for i,v in Bench.HoldingItem do pcall(function() Bench:RemoveItem(v, workspace) end) end end)
		pcall(function() Bench:EjectPlayer() end) pcall(function() allTable[PhysicalBench] = nil end)
		pcall(function() table.clear(Bench) end)
		Bench = nil
	end
	function Bench:RefreshWire()
		if typeof(Bench.State) ~= 'string' then Bench.State = 'EmptyState' end
		local State = Bench.State
		if State == 'EmptyState' then -- crafting is just waiting state
			Bench:ClearPrompt()
		else
			if typeof(Bench.__temp) ~= 'table' then Bench.__temp = {} end
			local Wiring = {
				['ItemInput'] = {
					Prompt = {
						[1] = {
							ActionText = 'Add', ObjectText = 'Item', Label = 'ItemInput', OnTrigger = function(plr) if not validInstance(plr) or not validInstance(plr.Character) then return end local a = plr.Character:FindFirstChildOfClass('Tool') local Is = validInstance(a) and ItemIs(a) or false if typeof(Is) == 'string' then Bench:StoreItem(a) end end,
						},
						[2] = {
							ActionText = 'Retrieve', ObjectText = 'Item', Label = 'ItemOutput', OnTrigger = function(plr) if not validInstance(plr) or not validInstance(plr.Character) then return end Bench:ToState('Retrieving') end, Offset = Vector2.new(0,1)
						},
						[3] = {
							ActionText = 'Craft', ObjectText = 'Item', Label = 'CraftPrompt', OnTrigger = function(plr) if not validInstance(plr) or not validInstance(plr.Character) then return end Bench:UpdateItemTable() if typeof(Bench.HoldingItemString) ~= 'table' or typeof(Bench.HoldingItem) ~= 'table' then Bench:UpdateItemTable() end if #Bench.HoldingItem <= 0 or #Bench.HoldingItemString < 0 then return end  local Query = QueryRecipe(Bench.HoldingItemString or {}) local ValidYet = typeof(Query) == 'table' and typeof(Query[1]) == 'table' and Query[1].done == true --[[need atleast one ready to go into selection]] if not ValidYet then return end Bench:ToState('CraftingSelection') end, Offset = Vector2.new(0,-1)
						}
					}
				},
				['Retrieving'] = {
					Prompt = (function() local List = {{ActionText = 'Return' , ObjectText = 'Item Input', Label = 'ItemInput', OnTrigger = function(plr) if not validInstance(plr) or not validInstance(plr.Character) then return end Bench:ToState("ItemInput") end --[[Backward 2]], Offset = Vector2.new(1,0)}} if State ~= 'Retrieving' then return end if typeof(Bench.HoldingItem) == 'table' then for i,v in ipairs(Bench.HoldingItem) do local Add = {} Add.ActionText = 'Remove' Add.ObjectText = v.Name Add.Label = 'Item__'..tostring(v) Add.OnTrigger = function(plr) if not validInstance(plr) or not validInstance(plr.Character) then return end Bench:RemoveItem(v, plr.Character or plr:FindFirstChildOfClass('Backpack') or workspace) end Add.Offset = Vector2.new(0, math.round(i/2 - 0.1) * ((i%2 == 0) and -1 or 1)) table.insert(List, Add) end end return List end)() -- generate based on Query
				},
				['CraftingSelection'] = {
					Prompt = (function() local List = {{ActionText = 'Return' , ObjectText = 'Item Input', Label = 'ItemInput', OnTrigger = function(plr) if not validInstance(plr) or not validInstance(plr.Character) then return end Bench:ToState("ItemInput") end --[[Backward]], Offset = Vector2.new(1,0)}} if State ~= 'CraftingSelection' then return end local Query = QueryRecipe(Bench.HoldingItemString) if #Query > 0 then for i,v in ipairs(Query) do local Add = {} --[[must have .done == true, objectname to .name, actionname to ingredient, offset based on (indice%2 and -1 or 1) * math.round(indice/2)]] if typeof(v.required) == 'table' and typeof(v.name) == 'string' then Add = {Label = (v.done ~= true and v.name..[[(incomplete)]]) or v.name, ObjectText = (v.done ~= true and v.name..[[(Suggestion)]]) or v.name, ActionText = (v.done == true and 'Using: ' or 'Need: ')..tostring(table.concat(v.done == true and v.required or get_difference(v.required or {}, Bench.HoldingItemString or {}), ', ')), OnTrigger = function(plr) if not validInstance(plr) or not validInstance(plr.Character) then return end if typeof(Bench.__temp) ~= 'table' then Bench.__temp = {} end if typeof(v) ~= 'table' or typeof(v.name) ~= 'string' or v.done ~= true then return end Bench.__temp.__name = v.name Bench.__temp.__v = v Bench:ToState("Minigame") --[[Bench:Craft(v.name, v)]] end, Offset = Vector2.new(0,((i%2 == 0) and -1 or 1) * math.round(i/2 - 0.1))} table.insert(List, Add) end end end return List end)() -- generate based on Query
				}	
				,['Minigame'] = { -- state for crafting the item
					Prompt = {
					[1] = {
							ActionText = '^', ObjectText = 'Up', Label = 'MinigameController_Up', OnTrigger =  function(plr, prompt) if not validInstance(plr) or not validInstance(plr.Character) then return end  pcall(function() Bench.__temp.RegisterInput('Up',  prompt) end) end, Offset = Vector2.new(0,1)
					},
					[2] = {
							ActionText = 'v', ObjectText = 'Down', Label = 'MinigameController_Down',  OnTrigger =  function(plr, prompt) if not validInstance(plr) or not validInstance(plr.Character) then return end  pcall(function() Bench.__temp.RegisterInput('Down', prompt) end) end, Offset = Vector2.new(0,-1)
					},
					[3] = {
							ActionText = '>', ObjectText = 'Left', Label = 'MinigameController_Left',  OnTrigger =  function(plr, prompt) if not validInstance(plr) or not validInstance(plr.Character) then return end  pcall(function() Bench.__temp.RegisterInput('Left', prompt) end) end, Offset = Vector2.new(1,0)
					},
					[4] = {
							ActionText = '<', ObjectText = 'Right', Label = 'MinigameController_Right',  OnTrigger =  function(plr, prompt) if not validInstance(plr) or not validInstance(plr.Character) then return end  pcall(function() Bench.__temp.RegisterInput('Right', prompt) end) end, Offset = Vector2.new(-1,0)
						}},
					['Value'] = { -- value struct used in temp for this state, will be set to __temp, if not string will simply return itself
						Needed = (function() if State ~= 'Minigame' then return {"Up"} --[[for escaping softlocks]] end local Potential = {"Up", "Down", "Left", "Right"} local Needs = {} for i = 1, (MinigameRequired or 20) do table.insert(Needs, Potential[math.random(1, #Potential)]) end return Needs end)(),
						Fail = 'number',
						StartTime = 'clock',
						UsedItem = 'table',
						Result = 'table', 
						RegisterInput = function(Input: string, Prompt) if typeof(Input) ~= 'string' or typeof(Bench.__temp) ~= 'table' or typeof(Bench.__temp.Needed) ~= 'table' then Bench:ToState("ItemInput") --[[state fail]] return end
							if typeof(Bench.__temp.Needed) == 'table' and Bench.__temp.Needed[1] == Input then
								table.remove(Bench.__temp.Needed, 1)
							elseif typeof(Bench.__temp.Fail) == 'number' and Bench.__temp.Fail < MinigameFail then Bench.__temp.Fail = Bench.__temp.Fail + 1 else Bench:ToState("ItemInput") return --[[fail]] end
							if typeof(Bench.__temp.StartTime) ~= 'number' or ((os.clock() - Bench.__temp.StartTime) > MinigameTime) or (typeof(Bench.__temp.__name) ~= 'string' or typeof(Bench.__temp.__v) ~= 'table') then
								Bench:ToState("ItemInput") return  -- either the entry somehow was not registered or ur too slow gng
							end
							if validInstance(Prompt) and Prompt.ClassName:lower():match('prompt') and typeof(Bench.__temp.Needed[1]) == 'string' then if validInstance(Bench.__temp.LastPrompt) then pcall(function() Bench.__temp.LastPrompt.ObjectText = Bench.__temp.LastPrompt:GetAttribute("OG") or Prompt.ObjectText  end) end Bench.__temp.LastPrompt = Prompt if typeof(Prompt:GetAttribute('OG')) ~= 'string' then Prompt:SetAttribute('OG', Prompt.ObjectText) end pcall(function()	Prompt.ObjectText = Prompt:GetAttribute('OG').." <<Next IS "..Bench.__temp.Needed[1]..">> (Fail: "..tostring(Bench.__temp.Fail)..'/'.. tostring(MinigameFail)..')' end) end 
							if #Bench.__temp.Needed <= 0 then
								--CRAFT, gotta add this between select and state
								Bench:Craft(Bench.__temp.__name, Bench.__temp.__v)
								Bench:ToState("ItemInput") -- wait a bit before finishing
							end
						end,
					}
				}	
			}
			local ForState = Wiring[Bench.State]
			if typeof(ForState) ~= 'table' then return end
			if typeof(ForState.Prompt) == 'table' and next(ForState.Prompt) then local Keep = {}
				for i,v in ForState.Prompt do
					if typeof(v) == 'table' then
						local Prompt: ProximityPrompt = Bench:GetPrompt(v.Label, v.ActionText, v.ObjectText, v.Offset) or Instance.new('ProximityPrompt', PhysicalBench) or Default('instance')
						if Prompt:GetAttribute("Wired__") then --[[let the old already connected one be cleaned up, since we can't disconnect it]] Prompt = Bench:NewPrompt(v.Label, v.ActionText, v.ObjectText) end
						if typeof(v.OnTrigger) == 'function' then pcall(function() -- try before going with labeling
							Prompt.Triggered:Connect(function(plr) if validInstance(plr) and (not validInstance(Bench.CurrentPlayer) or plr == Bench.CurrentPlayer) then if not validInstance(Bench.CurrentPlayer) then pcall(function() Bench:SignIn(plr) end) end pcall(function() v.OnTrigger(plr, Prompt) end) end end)
						Prompt:SetAttribute("Wired__", true) if typeof(Bench.State) == 'string' then Prompt:SetAttribute("ForState", Bench.State) Prompt:SetAttribute(Bench.State, true) else Bench:ToState("EmptyState") return end end) end
						if typeof(v.Offset) == 'Vector2' then
						pcall(function() MovePromptTo(Prompt, v.Offset * offsetMul) end)
						end
						table.insert(Keep, Prompt)
					end
				end Bench:ClearPrompt(Keep)
				Bench:RefreshBind()
				if typeof(Bench.ProximityPrompts) ~= 'table' or not next(Bench.ProximityPrompts) then Bench:ToState("ItemInput") return end  -- failing!
			else Bench:ClearPrompt() Bench:ToState("ItemInput") return end
			if typeof(ForState.Value) == 'table' and next(ForState.Value) then
				for i,v in ForState.Value do
					if typeof(v) == 'string' then
						Bench.__temp[i] = Default(v) or v
					else Bench.__temp[i] = v end
				end
			end
			if State == 'ItemInput' then Bench.__temp = {} end -- not needed at that state
		end
	end
	function Bench:ToState(State: State)
		if typeof(Bench.State) ~= 'string' then Bench.State = 'EmptyState' end
		if typeof(State) ~= 'string' then return end
		--Can Use At Same State To Refresh
		Bench:RefreshBind()
		if Bench.State ~= State and not (Bench.State == 'CraftingSelection' and State == 'Minigame') then
			Bench.__temp = {}
		end
		Bench.State = State
		Bench:RefreshWire()
	end
	function Bench:RefreshBind()
		Bench.UsedBind = {}
		if typeof(Bench.ProximityPrompts) ~= 'table' then Bench.ProximityPrompts = {} end
		local Marked = {}
		local DestroySoon = {}
		for i,v in Bench.ProximityPrompts do if not validInstance(v) or not v.ClassName:lower():match('proximityprompt') then table.insert(DestroySoon, v) continue end 
			if not table.find(Bench.UsedBind, v.KeyboardKeyCode.Name:lower()) then table.insert(Bench.UsedBind, v.KeyboardKeyCode.Name:lower()) else table.insert(Marked, v) end
		end
		for i,v in Marked do
			local Binded = Bind(v, Bench.UsedBind)
			if typeof(Binded) == 'string' then
				table.insert(Bench.UsedBind, Binded)
			end
		end
		for i,v in DestroySoon do
			pcall(function() v:Destroy() end)
			pcall(function()
				if table.find(Bench.ProximityPrompts, v) then table.remove(Bench.ProximityPrompts, table.find(Bench.ProximityPrompts, v)) end
			end)
		end
	end
	function Bench:GetPrompt(Label, Act: string?, Obj: string?, Offset: Vector2?, ...) if typeof(Bench.ProximityPrompts) ~= 'table' then Bench.ProximityPrompts = {} end
		if not Bench.ProximityPrompts[Label] then Bench.ProximityPrompts[Label] = Bench:NewPrompt(Label, Act, Obj, Offset, ...) else pcall(function() if typeof(Act) == 'string' then Bench.ProximityPrompts[Label].ActionText = Act end end) pcall(function() if typeof(Offset) == 'Vector2' then MovePromptTo(Bench.ProximityPrompts[Label], Offset * offsetMul) end end) pcall(function() if typeof(Obj) == 'string' then Bench.ProximityPrompts[Label].ObjectText = Obj end end) end
		return Bench.ProximityPrompts[Label]
	end
	function Bench:Janitor()
		for i,v in BaseBenchStruct do
			if (typeof(ReqData[v]) or 'nuller'):lower() ~= v:lower() then ReqData[v] = Default(v) end  
		end
		Bench:RefreshBind()
	end
	function Bench:EjectPlayer()
		Bench:Janitor()
		-- if player left or not valid mid eject, the item stays in bench.
		if validInstance(Bench.CurrentPlayer) then for i,v in Bench.HoldingItem do Bench:RemoveItem(v, Bench.CurrentPlayer.Character or Bench.CurrentPlayer:FindFirstChildOfClass("Backpack") or workspace or Default("instance")) Bench.HoldingItem = {} Bench.HoldingItemString = {} end
			if typeof(Bench.TimeoutThread) == 'thread' then task.cancel(Bench.TimeoutThread) end
			if typeof(Bench.RemovedEvent) == 'RBXScriptSignal' then Bench.RemovedEvent:Disconnect() end
			Bench.RemovedEvent = nil
			Bench.TimeoutThread = nil
			Bench.CurrentPlayer = nil
			Bench:UpdateItemTable()
		end
	end
	function Bench:SignIn(Plr: Instance)
		if not validInstance(Plr) or validInstance(Bench.CurrentPlayer) or not Plr.ClassName:lower():match('player') then return end
		Bench:EjectPlayer() -- Eject before setting player so item stays
		Bench.CurrentPlayer = Plr
		--no greedy ass mf overhere tryna claim the whole damn workbench industries
		for i,v in Workbenches do
			if i == PhysicalBench then continue end
			if typeof(v) == 'table' then
				pcall(function()
					if v.CurrentPlayer == Plr then v:EjectPlayer() end
				end)
			end
		end
		Bench.TimeoutThread = task.spawn(function()
			task.wait(600)
			Bench:EjectPlayer()
		end)
		Bench.RemovedEvent = Plr.Destroying:Once(function() Bench:EjectPlayer() end)
	end
	--Initial!
	Bench:EjectPlayer()
	Bench:ToState("EmptyState")
	Bench:RefreshBind()
	Bench:RefreshWire()
	Bench:ToState("ItemInput")
	Bench:UpdateItemTable()
	Workbenches[PhysicalBench] = Bench
	PhysicalBench.Destroying:Once(function()
		Bench:Destroy()
	end)
end

local Bindable = script:FindFirstChildOfClass('BindableEvent') or script:WaitForChild('BenchBindable', 10) or Instance.new('BindableEvent', script)
Bindable.Name = 'BenchBindable'
Bindable.Event:Connect(Entry)

if typeof(EntryLater) ~= 'table' then return end
for i,v in EntryLater do 
	if validInstance(v) then Entry(v) end 
end
--By @Solivion 2026