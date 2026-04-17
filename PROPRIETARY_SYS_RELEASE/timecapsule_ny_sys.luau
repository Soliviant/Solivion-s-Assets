--new year resolution, fix parser as it returns strings
--Solivion

local SET = false

local Players = game:GetService("Players")
local Datastore = game:GetService("DataStoreService")
type UISTRUCT = {
	Type: StorageTypes,
	Name: string, -- unique indicator
	Attributes: {string: any},
	Properties: {string: any},
}
type UISAVESTRUCT = {
	YEAR: number,
	LASTMODDEDYEAR: number,
	UI: {StorageTypes: {UISTRUCT}} --dataname
}
type HISTORYSTRUCT = {
	SAVEDSTRUCT: UISTRUCT,
	LABEL: string
}
type DATASTRUCT = {
	DRAFT: UISAVESTRUCT,
	CURRENT: UISAVESTRUCT,
	LAST: {UISAVESTRUCT},
	HISTORY: {HISTORYSTRUCT}
}
type StorageTypes = ("Frame"|"ImageLabel"|"TextLabel"|"UIGradient"|"UIStroke"|"UICorner")
local Datas: {[Player?]: DATASTRUCT} = {}
local TypeData: {[string?]: {string: any}} = {
	Frame = {
		BackgroundColor3 = "Color3",
		BackgroundTransparency = "number",
		BorderColor3 = "Color3",
		BorderSizePixel = "number",
		Size = "UDim2",
		Position = "UDim2",
		AnchorPoint = "Vector2",
		Visible = "boolean",
		ZIndex = "number"
	},
	ImageLabel = {
		Image = "string",
		ImageColor3 = "Color3",
		ImageTransparency = "number",
		ScaleType = "EnumItem",  -- e.g. Enum.ScaleType
		BackgroundColor3 = "Color3",
		BackgroundTransparency = "number",
		BorderSizePixel = "number",
		Size = "UDim2",
		Position = "UDim2",
		ZIndex = "number"
	},
	TextLabel = {
		Text = "string",
		Font = "EnumItem",       -- e.g. Enum.Font
		TextColor3 = "Color3",
		TextSize = "number",
		TextTransparency = "number",
		BackgroundColor3 = "Color3",
		BackgroundTransparency = "number",
		BorderSizePixel = "number",
		Size = "UDim2",
		Position = "UDim2",
		ZIndex = "number"
	},
	UIGradient = {
		Color = "ColorSequence",
		Rotation = "number",
		Transparency = "NumberSequence"
	},
	UIStroke = {
		Color = "Color3",
		Transparency = "number",
		Thickness = "number",
		LineJoinMode = "EnumItem",     -- e.g. Enum.LineJoinMode
		ApplyStrokeMode = "EnumItem"     -- e.g. Enum.ApplyStrokeMode
	},
	UICorner = {
		CornerRadius = "UDim"
	}
}
local osdate = {month = 12, day = 31, year = 1}
local CachedDatas: {DATASTRUCT} = {}
local CacheWriteSession = 1
pcall(function() osdate = os.date('!*t') end)
if not osdate then osdate = {month = math.random(1,12), day = math.random(1,31), YEAR = 1}
end
local ThisYear = osdate and osdate.year or 0
if osdate.month == 1 and osdate.day <= 2 then
	ThisYear -= 1
end
--util
function FindFirstChildOfNameAndClass(Where: Instance, Name: string, Class: string)
	local Found: boolean = false
	if Where == nil or not Name or not Class then
		return
	end
	if Where:FindFirstChild(Name) and Where:FindFirstChild(Name).ClassName:upper():match(Class:upper()) then
		return Where:FindFirstChild(Name)
	end
	for i,v in Where:GetChildren() do
		if not Found then
			if Where == nil then
				Found = true
				return nil
			end
			if v.Name:match(Name) and (v:IsA(Class) or v.ClassName:upper():match(Class:upper())) then
				Found = true
				return v
			end
		end
	end
end
local PlayerLASTUI: {[Player?]: {UISTRUCT}} = {}
function IsPlayer(Value: any) return typeof(Value) == "Instance" and Value:IsA('Player') end
function IsTable(Value: any) return typeof(Value) == "table" end
function IsString(Value: any) return typeof(Value) == "string" end
function IsUISTRUCT(Value: any) return IsTable(Value) and IsString(Value.Name) and IsTable(Value.Properties) and IsTable(Value.Attributes) end
function IsUISAVESTRUCT(Value: any) return IsTable(Value) and IsTable(Value.UI) and typeof(Value.YEAR) == "number" and typeof(Value.LASTMODDEDYEAR) == "number" end
function IsValidInstances(Value: string) return typeof(Value) == "string" and table.find({"Frame","ImageLabel","TextLabel","UIGradient","UIStroke","UICorner"},Value) end
--Func
function GetPossibleNames(Player: Player,Request: string, Type: StorageTypes)
	if not IsString(Request) or not FindTargetUI(Player, 'DRAFT', Type, Request) then return Request end
	local OptimalRequest = Request
	local Number = 1
	while FindTargetUI(Player, 'DRAFT', Type, OptimalRequest) do
		OptimalRequest = Request..'_'..tostring(Number)
		Number += 1
	end
	return OptimalRequest
end
function NEWUISTRUCT(Info: UISTRUCT, Player: Player?)
	return IsTable(Info) and {
		Name = tostring(math.random()..tostring(Info.Type)) ,Type = IsValidInstances(Info.Type) and Info.Type or "Frame", Attributes = (IsTable(Info.Attributes) and Info.Attributes) or {}, Properties = (IsTable(Info.Properties) and Info.Properties) or {}
	} or {Name = tostring(math.random()),Type = "Frame", Attributes = {}, Properties = {}}
end
function NEWUISAVESTRUCT()
	return {YEAR = ThisYear, LASTMODDEDYEAR = ThisYear, UI = {Frame = {}, ImageLabel = {}, TextLabel = {}}} 
end
function DRAFT_ADDUI(Player:Player, Data: UISTRUCT, Name: string?)
	if not IsPlayer(Player) then return end
	if not IsTable(Datas[Player]) then Datas[Player] = {LAST = {}, CURRENT = NEWUISAVESTRUCT(), DRAFT = NEWUISAVESTRUCT(), HISTORY = {}} end
	Data = NEWUISTRUCT(Data)
	if IsString(Data.Name) then Data.Name = GetPossibleNames(Player, (Name or Data.Name), Data.Type) else return end
	if IsString(Data.Type) and IsTable(Data.Properties) then Data.Properties = FilterProperties(Data.Properties, Data.Type) else return end
	if IsUISTRUCT(Data) then if not Datas[Player].DRAFT then Datas[Player].DRAFT = IsUISAVESTRUCT(Datas[Player].CURRENT) and table.clone(Datas[Player].CURRENT) or NEWUISAVESTRUCT() end if not Datas[Player].DRAFT.UI then Datas[Player].DRAFT.UI = {[Data.Type] = {}} end table.insert(Datas[Player].DRAFT.UI[Data.Type], Data)  end
end
function DRAFT_OVERWRITE_CURRENT(Player)
	if not IsPlayer(Player) then return end
	if Datas[Player] and IsUISAVESTRUCT(Datas[Player].DRAFT) then
		Datas[Player].CURRENT = table.clone(Datas[Player].DRAFT)
	end
end
function DRAFT_RESET(Player)
	if not IsPlayer(Player) then return end
	if Datas[Player] then
		Datas[Player].DRAFT = IsUISAVESTRUCT(Datas[Player].CURRENT) and table.clone(Datas[Player].CURRENT) or NEWUISAVESTRUCT()
	end
end
function FindPlayerUIVersion(Player: Player, UIVersion: ("CURRENT" | "DRAFT" | number))
	if not IsPlayer(Player) then return end
	if IsTable(Datas[Player]) and IsUISAVESTRUCT(Datas[Player][string.upper(tostring(UIVersion))]) then return Datas[Player][string.upper(tostring(UIVersion))] end
	if IsTable(Datas[Player]) and IsTable(Datas[Player]['LAST']) and tonumber(UIVersion) and IsUISAVESTRUCT(Datas[Player]['LAST'][tonumber(UIVersion)]) then return Datas[Player]['LAST'][tonumber(UIVersion)] end
end
function FindTargetUI(Player: Player, Version: ("CURRENT"| "DRAFT"), Type: StorageTypes, Name: string)
	local StructTable = FindPlayerUIVersion(Player, Version)
	if IsUISAVESTRUCT(StructTable) and IsTable(StructTable.UI[Type]) then
		for indice, value in ipairs(StructTable.UI[Type]) do
			if not IsTable(value) then continue end
			if value.Name == Name then return value,indice end
		end
	end
end
function DRAFT_IMPORT(Player: Player, ArchivalIndices: number)
	if not IsPlayer(Player) or not IsTable(Datas[Player]) or not IsTable(Datas[Player].LAST) then return end
	local TheIMPORTEDONE = Datas[Player].LAST[ArchivalIndices]
	if not TheIMPORTEDONE then 
		for i,v in Datas[Player].LAST do
			if v.LASTMODDEDYEAR == ArchivalIndices then TheIMPORTEDONE = v break end
		end
		if not TheIMPORTEDONE then 
			for i,v in Datas[Player].LAST do
				if v.YEAR == ArchivalIndices then TheIMPORTEDONE = v break end
			end
		end
	end
	if not TheIMPORTEDONE then return end
	Datas[Player].DRAFT = SAVESTRUCT_UI_FILTER(Datas[Player].LAST[ArchivalIndices])
end
function DRAFT_REMOVEUI(Player: Player, Type: StorageTypes, Name: string)
	local Target, TargetIndices = FindTargetUI(Player, "DRAFT", Type, Name)
	local VerTable = FindPlayerUIVersion(Player, "DRAFT")
	local UITable = IsTable(VerTable) and VerTable 
	if Target and UITable and IsUISAVESTRUCT(UITable[TargetIndices]) and IsTable(UITable[TargetIndices].UI) and IsTable(UITable[TargetIndices].UI[Type]) and IsUISTRUCT(UITable[TargetIndices].UI[Type][TargetIndices]) then
		table.remove(UITable[TargetIndices].UI[Type], TargetIndices)
	end
end
function DRAFT_MODIFYUI(Player: Player, Type: StorageTypes, Name: string, Config: ({string: any}|string), Extra: any?)
	local newercon = {}
	if IsString(Config) then newercon[Config] = Extra Config = newercon end
	if not IsTable(Config) then return end
	local Target, TargetIndices = FindTargetUI(Player, "DRAFT", Type, Name)
	local VerTable = FindPlayerUIVersion(Player, "DRAFT")
	local UITable = IsTable(VerTable) and VerTable 
	if Target and UITable and IsUISAVESTRUCT(UITable[TargetIndices]) and IsTable(UITable[TargetIndices].UI) and IsTable(UITable[TargetIndices].UI[Type]) and IsUISTRUCT(UITable[TargetIndices].UI[Type][TargetIndices]) then
		VerTable.LASTMODDEDYEAR = ThisYear or VerTable.LASTMODDEDYEAR
		local TargetMod
		if IsTable(PlayerLASTUI[Player]) and IsTable(PlayerLASTUI[Player][Type]) then
			for i, v in IsTable(PlayerLASTUI[Player][Type]) do
				if v.Name:match(Name) then TargetMod = v break end
			end
		end
		for i,v in pairs(Config) do
			UITable[TargetIndices].UI[Type][TargetIndices].Properties[i] = v
			if TargetMod then pcall(function() TargetMod[i] = v end) end
		end
		UITable[TargetIndices].UI[Type][TargetIndices].Properties = FilterProperties(UITable[TargetIndices].UI[Type][TargetIndices].Properties, Type)
	end
end
function DRAFT_UISETATTRIBUTES(Player: Player, Type: StorageTypes, Name: string, AttributeName: string, Value: any)
	if not IsString(AttributeName) then return end
	local Target, TargetIndices = FindTargetUI(Player, "DRAFT", Type, Name)
	local VerTable = FindPlayerUIVersion(Player, "DRAFT")
	local UITable = IsTable(VerTable) and VerTable
	if Target and UITable and IsUISAVESTRUCT(UITable[TargetIndices]) and IsTable(UITable[TargetIndices].UI) and IsTable(UITable[TargetIndices].UI[Type]) and IsUISTRUCT(UITable[TargetIndices].UI[Type][TargetIndices]) then
		UITable[TargetIndices].UI[Type][TargetIndices].Attributes[AttributeName] = Value
	end
end
function SearchCache(Player:Player)
	if not IsPlayer(Player) then return end
	local id = Player.UserId
	for i,v in ipairs(CachedDatas) do
		if IsTable(v) and v.USERID == id then return v,i end
	end
end

local IDONLINE: {number} = {}
local IDTASK: {[number?]: thread} = {}

function trimSpaces(inputString)
	return inputString:match("^%s*(.-)%s*$")
end
function execute(PLAYER: Player, WHAT: string, TYPE: string, NAME: string, VALUEA: string?, VALUEB: any?)
	if WHAT:upper():match('CREATE') or WHAT:upper():match('ADD') or WHAT:upper():match('INSTANCE') or WHAT:upper():match('INSERT') then
		DRAFT_ADDUI(PLAYER, NEWUISTRUCT({Name = NAME or 'Frame', Type = TYPE or "Frame"}), NAME)
	elseif WHAT:upper():match('MOD') or WHAT:upper():match('PROPERTY') then
		DRAFT_MODIFYUI(PLAYER, TYPE, NAME, VALUEA, VALUEB)
	elseif (WHAT:upper():match('CLOSE') or WHAT:upper():match('STOP') or WHAT:upper():match('HIDE')) and (WHAT:upper():match('DISPLAY') or WHAT:upper():match('SHOW') or WHAT:upper():match('PREVIEW')) then
		Closedisplay(PLAYER)
	elseif WHAT:upper():match('DISPLAY') or WHAT:upper():match('SHOW') or WHAT:upper():match('PREVIEW') then
		local VersionStruct: UISAVESTRUCT = FindPlayerUIVersion(PLAYER, VALUEB)
		if not IsUISAVESTRUCT(VersionStruct) then return end
		PlayerLASTUI[PLAYER] = Display(PLAYER, PlayerLASTUI[PLAYER] or {}, VersionStruct)
	elseif WHAT:upper():match('DESTROY') or WHAT:upper():match('REMOVE') then
		DRAFT_REMOVEUI(PLAYER, TYPE, NAME)
	elseif WHAT:upper() == 'RESET' or WHAT:upper() == 'RELOAD' then
		DRAFT_RESET(PLAYER)
	elseif WHAT:upper() == 'IMPORT' then
		DRAFT_IMPORT(PLAYER, VALUEB)
	elseif WHAT:upper() == 'SAVE' or WHAT:upper() == 'CONFIRM' or WHAT:upper() == 'UPDATE' then
		DRAFT_OVERWRITE_CURRENT(PLAYER)
	elseif WHAT:upper() == 'ASSIGN' or WHAT:upper() == 'ATTRIBUTE' then
		DRAFT_UISETATTRIBUTES(PLAYER, TYPE, NAME, VALUEA, VALUEB)
	end
end
local function makeJSONSafe(val)
	local t = type(val)
	if t == "table" then
		local safe = {}
		for k, v in pairs(val) do
			-- Ensure keys are strings (JSON requires string keys).
			local safeKey = (type(k) == "string") and k or tostring(k)
			safe[safeKey] = makeJSONSafe(v)
		end
		return safe
	elseif t == "number" or t == "string" or t == "boolean" then
		return val
	else
		-- For Roblox userdata (Vector3, CFrame, etc.) or functions, convert to a string.
		return stringifyValue(val)
	end
end
local function decodeJSONSafe(val)
	local t = type(val)
	if t == "table" then
		local decoded = {}
		for k, v in pairs(val) do
			-- Process each key and value recursively.
			-- JSON keys are always strings, so we can keep them as-is.
			decoded[(tonumber(k) == tonumber(tostring(tonumber(k))) and tonumber(k)) or k] = decodeJSONSafe(v)
		end
		return decoded
	elseif t == "string" then
		-- Attempt to parse the string into its intended type.
		return parseValue(val)
	else
		-- Numbers, booleans, and other JSON-safe types are returned directly.
		return val
	end
end
local HttpService = game:GetService("HttpService")
function SetUp()
	if SET then return else SET = true end
	local function RetrieveDataStore(Player: Player)
		if not IsPlayer(Player) then return end
		local id = Player.UserId
		local fromdatastore
		IDTASK[id] = task.spawn(function()
			local success = false
			local tries = 0
			while not success and not fromdatastore and tries < 10 and table.find(IDONLINE, id) do
				success = pcall(function() task.synchronize() fromdatastore = HttpService:JSONDecode(Datastore:GetAsync('NEWYEARRESOLUTIONCARD'..tostring(id))) end)
				tries += 1
				task.wait(1)
			end
			IDTASK[id] = nil
		end)
		local Cached, indice = SearchCache(Player)
		local Data = fromdatastore or Cached or Datas[Player]
		if IsTable(Data) then
			return Data
		end
		return {LAST = {}, DRAFT = NEWUISAVESTRUCT(), CURRENT = NEWUISAVESTRUCT()}
	end
	task.synchronize()
	Players.PlayerAdded:Connect(function(Player)
		task.desynchronize()
		if not IsPlayer(Player) then task.synchronize() Player:Destroy() task.desynchronize() end
		if IDTASK[Player.UserId] then task.cancel(IDTASK[Player.UserId]) end 
		if not table.find(IDONLINE,Player.UserId) then	 table.insert(IDONLINE, Player.UserId) else Player:Kick('SESSION OVERLAP: TRY AGAIN LATER') return end
		Datas[Player] = PLAYER_FILTER_DATA(decodeJSONSafe(RetrieveDataStore(Player)))
		task.synchronize()
		pcall(function()
			if game:FindFirstChildOfClass('ReplicatedStorage') and game:FindFirstChildOfClass('ReplicatedStorage'):FindFirstChild('LogMessageEvent') then
				game:FindFirstChildOfClass('ReplicatedStorage'):FindFirstChild('LogMessageEvent'):FireClient(Player, [[Player Documentation for UI Management Script
	Welcome to the the game's ANNUAL UI Management System! This system allows you to create, modify, display, and save UI configurations in the game. Below is a guide on how to use the available commands to interact with the system. It's for using chat, no '/e' support available unfortunately.
	(not sure if this will work, but in theory, it should work!)
	{try using the command bar, it was added recently compared to all other system that require chat-based signals.}
		Commands Overview
				Create/Add UI Element
			Command: ;create [Type] [Name]
			Description: Creates a new UI element of the specified type and name.
			Example: ;create Frame MyFrame
				Modify UI Element Properties
			Command: ;mod [Type] [Name] [Property] [Value]
			Description: Modifies the properties of an existing UI element.
			Example: ;mod Frame MyFrame BackgroundColor3 Color3.new(1, 0, 0)
				Display UI Configuration
			Command: ;display [Version]
			Description: Displays the specified version of the UI configuration.
			Example: ;display CURRENT
				Close/Hide UI Display
			Command: ;close display
			Description: Closes the currently displayed UI configuration.
			Example: ;close display
				Remove UI Element
			Command: ;destroy [Type] [Name]
			Description: Removes a UI element of the specified type and name.
			Example: ;destroy Frame MyFrame
				Reset Draft UI Configuration
			Command: ;reset
			Description: Resets the draft UI configuration to the current version.
			Example: ;reset
				Import UI Configuration
			Command: ;import [Index]
			Description: Imports a UI configuration from the archival index.
			Example: ;import 1
				Save/Confirm UI Configuration
			Command: ;save
			Description: Saves the draft UI configuration as the current version.
			Example: ;save
				Assign UI Element Attributes
			Command: ;assign [Type] [Name] [Attribute] [Value]
			Description: Assigns attributes to a UI element.
			Example: ;assign Frame MyFrame CustomAttribute true
	Important Notes
		-Commands must start with a semicolon (;).
		-Ensure the type and name of UI elements are correctly specified.
		-Use the correct data types for properties and attributes (e.g., Color3.new, UDim2.new).
		-The system supports various UI element types such as Frame, ImageLabel, TextLabel, etc.
		-The System Will Automatically Archive The Current GUI if it's modified(even by a little bit) once you joined next year.
		-You'd have to remember archival index by the number of saves or "last modified year" as of currently.
		-Importing Will Overwrite The Draft. It's Reccommended To Save. You can reset to the saved Current Year version With ;reset 
		-Archival Has A Limit
		-Nobody Else Will See Your UI Design, If You Want To Share, Screenshot With Your Device.
		-Display Will Not Update In RealTime(When Importing Or Creating New UI Elements)
Feel free to experiment with creating and modifying UI elements.]])
			end
		end)
		local ce = Player:WaitForChild('ChatEvent', 60);
		((ce and ce:IsA('BindableEvent') and ce.Event) or Player.Chatted):Connect(function(MESSAGE, WHO)
			task.desynchronize()
			local cutmessages = trimSpaces((MESSAGE)):split(' ')
			local first, second, third, fourth, fifth
			for i,v in ipairs(cutmessages) do
				v = trimSpaces(v)
				if (i == 1 and string.sub(v, 1,1) == ';') or i ~= 1 then
					if i == 1 then
						first = string.sub(v, 2, #v)
					elseif i == 2 then
						second = v
					elseif i == 3 then
						third = v
					elseif i == 4 then
						fourth = v
					elseif i == 5 then
						fifth = parseValue(v) or v
					else
						break
					end
				else 
					break
				end
			end
			if first and second and third then
				if not (((osdate.month == 1 and osdate.day <= 2) or (osdate.month == 12 and osdate.day >= 30)) and math.abs(osdate.year-ThisYear) <= 1) then 
					local allowedkeys = {'SAVE', 'DISPLAY', 'CONFIRM', 'CLOSE', 'UPDATE', 'SHOW', 'PREVIEW', 'STOP','HIDE'}
					local pass = false
					for i,v in allowedkeys do
						if first:upper():match(v) then
							pass = true
							break
						end
					end
					if not pass then return end
				end
				execute(Player, first,second,third,fourth,fifth)
			end
		end)
		task.desynchronize()
		if not IsPlayer(Player) or not Player.Parent or not IsTable(Datas[Player]) then return end
		if not IsUISAVESTRUCT(Datas[Player].CURRENT) or Datas[Player].CURRENT.YEAR == ThisYear  then return end
		--Archive Old Version
		local SimilarFound = false
		local Oldestone = ThisYear
		local OldestIndice = #Datas[Player].LAST
		for i, v in ipairs(Datas[Player].LAST) do
			if SimilarFound then break else if not IsUISAVESTRUCT(v) then continue end OldestIndice = v.LASTMODDEDYEAR < (Oldestone and i) or OldestIndice Oldestone = v.LASTMODDEDYEAR < (Oldestone and v.LASTMODDEDYEAR) or Oldestone SimilarFound = TABLE_SIMILAR(v, Datas[Player].CURRENT) or v.UI == Datas[Player].CURRENT.UI end
		end
		if not SimilarFound then
			if not Datas[Player].LAST then Datas[Player].LAST = {} end
			if #Datas[Player].LAST > 50 and Oldestone < ThisYear then
				-- how even. how.
				table.remove(Datas[Player].LAST, OldestIndice)
			end
			table.insert(Datas[Player].LAST, Datas[Player].CURRENT)
		end
	end)
	Players.PlayerRemoving:Connect(function(Player)
		if table.find(IDONLINE,Player.UserId) then	table.remove(IDONLINE, table.find(IDONLINE,Player.UserId)) end
		local id = Player.UserId
		--Cache To Save Data For Thread.
		local Data_FINAL = makeJSONSafe(table.clone(Datas[Player]))
		Datas[Player] = nil
		PlayerLASTUI[Player] = nil
		local CachedData, Indice = SearchCache(Player)
		if not CachedData then
			Data_FINAL.USERID = id
			CachedDatas[CacheWriteSession] = Data_FINAL
			CacheWriteSession += 1
			if CacheWriteSession > 250 then CacheWriteSession -= 250 end
		else
			CachedDatas[Indice] = Data_FINAL --overwrite
		end
		if IDTASK[Player.UserId] then task.cancel(IDTASK[Player.UserId]) end 
		IDTASK[id] = task.spawn(function()
			local success = false
			local tries = 0
			while not success and tries < 10 and not table.find(IDONLINE, id) do
				success = pcall(function() task.synchronize() Datastore:UpdateAsync('NEWYEARRESOLUTIONCARD'..tostring(id),HttpService:JSONEncode(Data_FINAL)) end)
				tries += 1
				task.wait(1)
			end
			IDTASK[id] = nil
		end)
	end)

end
--for displaying
function Display(Player: Player, PreviousTable: {UISTRUCT}, Struct: UISAVESTRUCT)
	if not IsPlayer(Player) or not IsUISAVESTRUCT(Struct) or not Player:FindFirstChildOfClass("PlayerGui") then return end
	local PlayerGUI: PlayerGui? = Player:FindFirstChildOfClass("PlayerGui")
	local Display = PlayerGUI and FindFirstChildOfNameAndClass(PlayerGUI, "__Card_Display", "ScreenGui")
	if not Display then task.synchronize() local newui = Instance.new("ScreenGui") newui.Name = "__Card_Display" newui.ResetOnSpawn = false newui.IgnoreGuiInset = true newui.Parent = PlayerGUI Display = newui end
	--Display update
	PreviousTable = IsTable(PreviousTable) and PreviousTable or {}
	-- Iterate through the UIStructs to create or update UI elements
	for uiStructcategory, categorytable in pairs(Struct.UI) do
		if not IsTable(categorytable) then continue end
		for _, uiStruct in ipairs(categorytable) do
			task.desynchronize()
			if not IsTable(uiStruct) or not uiStruct.Name or not uiStruct.Type then continue end
			-- Check if the UI element already exists
			if not PreviousTable[uiStruct.Type] then PreviousTable[uiStruct.Type] = {} end
			local TargetInstance = PreviousTable[uiStruct.Type][uiStruct.Name]
			if not TargetInstance then
				-- Create a new instance based on the specified type
				task.synchronize()
				TargetInstance = Instance.new(uiStruct.Type)
				TargetInstance.Name = uiStruct.Name
				TargetInstance.Parent = Display
				PreviousTable[uiStruct.Type][uiStruct.Name] = TargetInstance
			end

			-- Set properties for the UI element
			pcall(function()
				if not TargetInstance then return end
				task.synchronize()
				for property, value in pairs(uiStruct.Properties) do
					TargetInstance[property] = value
				end
				task.desynchronize()
			end)
		end
	end
	-- Return the updated table of UI elements
	return PreviousTable
end
function Closedisplay(Player: Player)
	if not IsPlayer(Player) or not Player:FindFirstChildOfClass("PlayerGui") then return end
	local PlayerGUI: PlayerGui? = Player:FindFirstChildOfClass("PlayerGui")
	local Display = PlayerGUI and FindFirstChildOfNameAndClass(PlayerGUI, "__Card_Display", "ScreenGui")
	PlayerLASTUI[Player] = nil
	if Display then
		task.synchronize()
		Display:Destroy()
	end
end
function FilterProperties(Table: {string: any}, Type: StorageTypes)
	if not IsValidInstances(Type) or not TypeData[Type] then return {} end
	local DeprecatedProperties = {}
	local FilteredProperties = {}
	for i,v in pairs(Table) do
		if TypeData[Type][i] == typeof(v) then FilteredProperties[i] = v else DeprecatedProperties[i] = v end
	end
	return table.clone(FilteredProperties), table.clone(DeprecatedProperties)
end
function SAVESTRUCT_UI_FILTER(Struct: UISAVESTRUCT)
	if not IsUISAVESTRUCT(Struct) then return Struct end
	local USEDNAMES = {}
	for i,v in pairs(Struct) do
		if not IsValidInstances(i) or not IsTable(v) then continue end
		for indice, uistructs: UISTRUCT in ipairs(v) do
			if uistructs.Type ~= i then table.remove(v, indice) end
			if not IsUISTRUCT(uistructs) then continue end
			if not USEDNAMES[uistructs.Type] then USEDNAMES[uistructs.Type]= {} end
			if table.find(USEDNAMES[uistructs.Type],uistructs.Name) then
				uistructs.Name = uistructs.Name..tostring(#USEDNAMES[uistructs.Type])
			else
				table.insert(USEDNAMES[uistructs.Type],uistructs.Name)
			end
			local Valid, Deprecated = FilterProperties(uistructs.Properties, uistructs.Type)
			uistructs.Properties = Valid
			for name,value in pairs(Deprecated) do uistructs.Attributes[name..'_archive'] = value end
		end
	end
	return table.clone(Struct)
end
function PLAYER_FILTER_DATA(Table: DATASTRUCT)
	if not IsTable(Table) then return Table end
	local finalfiltered = {}
	for i,v in pairs(Table) do
		if IsUISAVESTRUCT(v) then finalfiltered[i] = SAVESTRUCT_UI_FILTER(v) elseif IsTable(v) then if not finalfiltered[i] then finalfiltered[i] = {} end for indice, savestruct in ipairs(v) do if IsUISAVESTRUCT(savestruct) then table.insert(finalfiltered[i],SAVESTRUCT_UI_FILTER(savestruct)) end end end
	end
	return finalfiltered
end
function TABLE_SIMILAR(TableA: {any}, TableB: {any})
	if not IsTable(TableA) or not IsTable(TableB) then return false end
	for i,v in pairs(TableA) do
		if	TableB[i] ~= v then return false end
	end
	return true
end

function splitArgs(str)
	local args = {}
	for token in string.gmatch(str, "[^,]+") do
		local trimmed = token:match("^%s*(.-)%s*$")
		table.insert(args, trimmed)
	end
	return args
end

-- Helper function: Converts tokens to numbers/booleans if possible.
function convertArgs(argTable)
	local converted = {}
	for i, token in ipairs(argTable) do
		local num = tonumber(token)
		if num then
			converted[i] = num
		elseif token == "true" then
			converted[i] = true
		elseif token == "false" then
			converted[i] = false
		else
			converted[i] = token
		end
	end
	return converted
end
function parseValue(input)
	input = input:match("^%s*(.-)%s*$") -- Trim input

	-- Detect literal strings: single/double quotes or long brackets.
	local firstChar, lastChar = input:sub(1, 1), input:sub(-1)
	if (firstChar == '"' and lastChar == '"') or (firstChar == "'" and lastChar == "'") then
		return input:sub(2, -2)
	end
	if input:sub(1, 2) == "[[" and input:sub(-2) == "]]" then
		return input:sub(3, -3)
	end

	-- Check for boolean literals.
	if input == "true" then return true end
	if input == "false" then return false end

	-- Check for numeric literal.
	local num = tonumber(input)
	if num then return num end

	-- Check for a simple table literal like "{1,2,3}"
	if input:sub(1, 1) == "{" and input:sub(-1) == "}" then
		local inner = input:sub(2, -2)
		local tokens = splitArgs(inner)
		local values = {}
		for i, token in ipairs(tokens) do
			values[i] = parseValue(token)
		end
		return values
	end

	-- Detect Enum items e.g., "Enum.Material.Wood"
	local enumCategory, enumName = input:match("^Enum%.(%w+)%.(%w+)$")
	if enumCategory and enumName then
		local enumTable = Enum[enumCategory]
		if enumTable then
			local enumValue = enumTable[enumName]
			if enumValue then return enumValue end
		end
	end

	-- Patterns for constructors:
	local patterns = {
		{pattern = "^CFrame%.new%((.-)%)$", constructor = function(args) 
			local tokens = splitArgs(args)
			local conv = convertArgs(tokens)
			return CFrame.new(unpack(conv))
		end},
		{pattern = "^Vector3%.new%((.-)%)$", constructor = function(args)
			local tokens = splitArgs(args)
			local conv = convertArgs(tokens)
			return Vector3.new(unpack(conv))
		end},
		{pattern = "^Vector2%.new%((.-)%)$", constructor = function(args)
			local tokens = splitArgs(args)
			local conv = convertArgs(tokens)
			return Vector2.new(unpack(conv))
		end},
		{pattern = "^UDim2%.new%((.-)%)$", constructor = function(args)
			local tokens = splitArgs(args)
			local conv = convertArgs(tokens)
			return UDim2.new(unpack(conv))
		end},
		{pattern = "^UDim%.new%((.-)%)$", constructor = function(args)
			local tokens = splitArgs(args)
			local conv = convertArgs(tokens)
			return UDim.new(unpack(conv))
		end},
		{pattern = "^Color3%.fromRGB%((.-)%)$", constructor = function(args)
			local tokens = splitArgs(args)
			local conv = convertArgs(tokens)
			return Color3.fromRGB(unpack(conv))
		end},
		{pattern = "^Color3%.new%((.-)%)$", constructor = function(args)
			local tokens = splitArgs(args)
			local conv = convertArgs(tokens)
			return Color3.new(unpack(conv))
		end},
		{pattern = "^BrickColor%.new%((.-)%)$", constructor = function(args)
			local tokens = splitArgs(args)
			local conv = convertArgs(tokens)
			return BrickColor.new(unpack(conv))
		end},
		{pattern = "^NumberSequence%.new%((.-)%)$", constructor = function(args)
			local inner = args:match("^%s*{(.-)}%s*$")
			if inner then
				local keypoints = {}
				for kp in inner:gmatch("NumberSequenceKeypoint%.new%((.-)%)") do
					local tokens = splitArgs(kp)
					local conv = convertArgs(tokens)
					table.insert(keypoints, NumberSequenceKeypoint.new(unpack(conv)))
				end
				return NumberSequence.new(keypoints)
			end
		end},
		{pattern = "^ColorSequence%.new%((.-)%)$", constructor = function(args)
			local inner = args:match("^%s*{(.-)}%s*$")
			if inner then
				local keypoints = {}
				for kp in inner:gmatch("ColorSequenceKeypoint%.new%((.-)%)") do
					local tokens = splitArgs(kp)
					local conv = convertArgs(tokens)
					table.insert(keypoints, ColorSequenceKeypoint.new(unpack(conv)))
				end
				return ColorSequence.new(keypoints)
			end
		end},
	}

	for _, p in ipairs(patterns) do
		local args = input:match(p.pattern)
		if args then
			return p.constructor(args)
		end
	end

	-- Fallback: return original input if no known pattern matches.
	return input
end
-- Vice Versa: Converts a Lua value into a string representation that
-- can be fed to parseValue to re-create the value.
function stringifyValue(value)
	local valueType = typeof(value)

	if valueType == "string" then
		-- Escape any embedded double quotes for safety.
		local escaped = value:gsub('"', '\\"')
		return '"' .. escaped .. '"'

	elseif valueType == "number" or valueType == "boolean" then
		return tostring(value)

	elseif valueType == "table" then
		-- Assume it's an array-like table.
		local parts = {}
		for i = 1, #value do
			table.insert(parts, stringifyValue(value[i]))
		end
		return "{" .. table.concat(parts, ",") .. "}"

	elseif valueType == "Vector3" then
		return string.format("Vector3.new(%f,%f,%f)", value.X, value.Y, value.Z)

	elseif valueType == "Vector2" then
		return string.format("Vector2.new(%f,%f)", value.X, value.Y)

	elseif valueType == "CFrame" then
		-- CFrame.new returns 12 numbers for a full CFrame.
		local components = {value:GetComponents()}
		return "CFrame.new(" .. table.concat(components, ",") .. ")"

	elseif valueType == "UDim" then
		return string.format("UDim.new(%f,%d)", value.Scale, value.Offset)

	elseif valueType == "UDim2" then
		return string.format("UDim2.new(%f,%d,%f,%d)", value.X.Scale, value.X.Offset, value.Y.Scale, value.Y.Offset)

	elseif valueType == "Color3" then
		-- You could also use Color3.fromRGB if you want integer values.
		return string.format("Color3.new(%f,%f,%f)", value.R, value.G, value.B)

	elseif valueType == "BrickColor" then
		-- Serializes by name.
		return "BrickColor.new('" .. value.Name .. "')"

	elseif valueType == "EnumItem" then
		-- Constructs a string like "Enum.Material.Wood"
		return "Enum." .. tostring(value.EnumType) .. "." .. value.Name
	elseif valueType == "NumberSequence" then
		local keypoints = {}
		for i, kp in ipairs(value.Keypoints) do
			table.insert(keypoints, string.format("NumberSequenceKeypoint.new(%f,%f)", kp.Time, kp.Value))
		end
		return "NumberSequence.new({" .. table.concat(keypoints, ",") .. "})"

	elseif valueType == "ColorSequence" then
		local keypoints = {}
		for i, kp in ipairs(value.Keypoints) do
			table.insert(keypoints, string.format("ColorSequenceKeypoint.new(%f,%s)", kp.Time, stringifyValue(kp.Value)))
		end
		return "ColorSequence.new({" .. table.concat(keypoints, ",") .. "})"

	else
		-- Fallback: just use tostring
		return tostring(value)
	end
end

if ((osdate.month == 1 and osdate.day <= 2) or (osdate.month == 12 and osdate.day >= 30)) and math.abs(osdate.year-ThisYear) <= 1 then
	SetUp()
else
	task.synchronize()
	script:Destroy()
end