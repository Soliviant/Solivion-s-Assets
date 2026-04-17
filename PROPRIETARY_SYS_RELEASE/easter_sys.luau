--soliviant
local Debris: Debris = game:FindFirstChildOfClass('Debris')
local ConnectionA, ConnectionB

function CalculateEaster(year)
	local a = year % 19
	local b = math.floor(year / 100)
	local c = year % 100
	local d = math.floor(b / 4)
	local e = b % 4
	local f = math.floor((b + 8) / 25)
	local g = math.floor((b - f + 1) / 3)
	local h = (19 * a + b - d - g + 15) % 30
	local i = math.floor(c / 4)
	local k = c % 4
	local l = (32 + 2 * e + 2 * i - h - k) % 7
	local m = math.floor((a + 11 * h + 22 * l) / 451)
	local month = math.floor((h + l - 7 * m + 114) / 31)
	local day = ((h + l - 7 * m + 114) % 31) + 1
	return month, day
end
local saveda, savedb = '[[NULL_MONTH]]', '[[NULL_DATE]]'
-- Function to check if today is Easter

function IsEaster()
	local currentDate = os.date("*t")  -- Get the current date
	local year = currentDate.year or 2024
	local easterMonth, easterDay
	-- Calculate Easter for this year
	if not saveda or not savedb then
		local easterMonth, easterDay = CalculateEaster(year)
		saveda = easterMonth or 4
		savedb = easterDay or 15
	else
		easterMonth = saveda
		easterDay = savedb
	end
	-- Check if today's date matches Easter Sunday
	if currentDate.month == easterMonth and currentDate.day == easterDay then
		return true
	else
		return false
	end
end

if not IsEaster() then task.synchronize() script:Destroy() return end

--this is the one and only 'Egg RNG', Peak 2024 send off frfr??????????
--By @Solivion
--Disclaimer: this script completely generates random egg names from random mixup, it was never meant to correlate to any terms in any language whatsoever, please add filter for possible bad words

local Debris: Debris = game:FindFirstChildOfClass('Debris')
local Text = function(...)
	if game:FindFirstChildOfClass('ReplicatedStorage') and game:FindFirstChildOfClass('ReplicatedStorage'):FindFirstChild('LogMessageEvent') then
		for i,v in game:FindFirstChildOfClass('Players'):GetChildren() do
			if not v:GetAttribute('__NODISTURB') then
				task.synchronize()
				game:FindFirstChildOfClass('ReplicatedStorage'):FindFirstChild('LogMessageEvent'):FireClient(v, ...)
			end
		end
	end
end
local Text_ALT = function(PLR,...)
	if game:FindFirstChildOfClass('ReplicatedStorage') and game:FindFirstChildOfClass('ReplicatedStorage'):FindFirstChild('LogMessageEvent') then
		if PLR then
			task.synchronize()
			game:FindFirstChildOfClass('ReplicatedStorage'):FindFirstChild('LogMessageEvent'):FireClient(PLR, ...)
		end
	end
end 
function FindFirstChildOfNameAndClass(Where: Instance, Name: string, Class: string)
	local Found: boolean = false
	if Where == nil then
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

--this unique name maker thing from Chat-GPT
local randomPrefixes = {"Zor", "Lux", "Fen", "Vor", 'pho', 'pher', "Ark", 'flux', 'pha', 'pol', "Zyn", "Gra", "Kil", "Mur", "Tan", "Xa", "laz", "Beo", "El", "Qua", 'Kir', 'Cur', 'Bhur'}
local randomSyllables = {"li", "no", "sha", "ra", "mi", "to", "ze", "ka", "me", "do", "ri", "ti", "la", "vi", 'que', 'ax', "go"}
local randomSuffixes = {"lon", "ra", "xis", "tor", "nik", "sil", "dra", "mon", "tak", "mir", "vok", "zan", "nok", 'vion', 'lyth', 'acz', 'nor', 'xo', "tas", "lox"}

type RegisterTypes = ('Touch' | 'Tool' | 'None')
type EggTypeInfo = {
	Name: string,
	Texture: (string | BrickColor | Color3),
	Mesh: (Instance | string),  -- Either an Asset ID or an instance (MeshPart or special mesh)
	Rarity: number,
	RegisterType: RegisterTypes
}
type EggInfo = {
	Collected: boolean,
	AnchorType: ('Anchored' | 'Unanchored'),
	Name: string,
	RegisterType: RegisterTypes,
	EggType: number,
	Event: RBXScriptConnection?  -- Storing event for disconnecting later
}

local CheckedMaximumRarity = 0;
local Dataset: {[BasePart?]: EggInfo} = {}
local Eggpedia: {[number?]: EggTypeInfo} = {}
local Storage: {[number?]: {[number?]: number}} = {}  -- Table to store player inventories
local LeaderStatPlayer: {[Player?]: {Object: NumberValue, On: boolean}} = {}
local ChatCon: {[Player?] : RBXScriptConnection} = {}
local Players = game:FindFirstChildOfClass("Players")

--Stuff
local registerTypes: {RegisterTypes} = {'Touch', 'Tool', 'None'}
local eggNames: {string} = {"Egg", 'Thingamabob', 'Silly Egg', 'Egg 2', 'Random Egg Thing', 'Name', 'Placeholder', '???', 'Cool Egg'}
local textures: {(string | BrickColor | Color3)} = {}
for r = 1,255,25 do
	for g = 1,255,25 do
		for b = 1,255,25 do
			table.insert(textures, Color3.fromRGB(r,g,b))
		end
	end
end
local uniqueNames = {}
local function GenerateKeycode(i) -- The Code Isn't That Hard To Crack.
	local code = ""
	local characters = "ABCDGHIJKLMNOPQRTVWYZabcdeghijlmnopqrstvwxyz01246789!@#$%^&*()_+-=[]{}|;:',.<>/?"
	local numCharacters = #characters

	for i = 1, i or math.random(1,20) do -- You can adjust the length of the keycode as needed
		local charIndex = math.random(1, numCharacters)
		code = code .. characters:sub(charIndex, charIndex)
	end
	return code
end
function GenerateName()
	local name
	local isunique = false
	local left = 1000
	repeat
		name = ""
		local componentCount = math.random(2, 4)  -- Number of components in the name (2-4 parts)

		for _ = 1, componentCount do
			local componentType = math.random(1, 3)
			if componentType == 1 then
				name = name .. randomPrefixes[math.random(#randomPrefixes)]
			elseif componentType == 2 then
				name = name .. randomSyllables[math.random(#randomSyllables)]
			else
				name = name .. randomSuffixes[math.random(#randomSuffixes)]
			end
		end
		if not uniqueNames[name] then
			isunique = true
		end
		left -= 1
	until left <= 0 or not uniqueNames[name]  -- Ensure uniqueness
	if not isunique then
		name = GenerateKeycode()
	end
	
	uniqueNames[name] = true
	return name
end
function ProperCase(name)
	return name:sub(1, 1):upper() .. name:sub(2):lower()
end
for i = 1,1000 do
	local Name = ProperCase(GenerateName() or 'ERROR')..' Egg'
	if not table.find(eggNames, Name) then
		table.insert(eggNames, Name)
	end
end
uniqueNames = {}

local meshes: {(string | SpecialMesh | MeshPart)} = {"rbxassetid://1527559", 0}
local pcallload = pcall(function()
	game:GetService('ContentProvider'):PreloadAsync({1527559}, function(stringthing, fetchstatus: Enum.AssetFetchStatus)
		if fetchstatus == Enum.AssetFetchStatus.Failure then
			if table.find(meshes, "rbxassetid://1527559") then
				table.remove(meshes, table.find(meshes, "rbxassetid://1527559"))
			end
		end
	end)
end)
if not pcallload then
	if table.find(meshes, "rbxassetid://1527559") then
		table.remove(meshes, table.find(meshes, "rbxassetid://1527559"))
	end
end

local latestapply: number = 0
local NoneLeft = math.round(25)

function GenerateRandomEggs(numEggs: number): {number}
	task.desynchronize()
	if not numEggs or typeof(numEggs) ~= 'number' or numEggs < 1 then numEggs = 1 end
	local Sofar: {number} = {}
	local ToolAmount = math.floor(numEggs/3)

	for i = 1, numEggs do
		if #eggNames <= 0 then warn('Ran out of Egg names') break end
		if #textures <= 0 then warn('Ran out of Egg textures') break end
		local eggName = #eggNames > 0 and eggNames[math.random(1, #eggNames)] or 'NULL'
		local texture = #textures > 0 and textures[math.random(1, #textures)] or Color3.new(math.random(),math.random(),math.random) or BrickColor.random() or nil
		local mesh = #meshes > 0 and meshes[math.random(1, #meshes)] or nil
		local rarity = math.random(1, 10)  -- Rarity between 1 and 5
		local registerType = #registerTypes > 0 and registerTypes[math.random(1, #registerTypes)] or 'Touch'
		local indice = latestapply + 1
		if registerType == 'None' then NoneLeft -= 1 if NoneLeft <= 0 and table.find(registerTypes, 'None') then table.remove(registerTypes, table.find(registerTypes, 'None')) end end
		if registerType == 'Tool' then ToolAmount -= 1 if ToolAmount <= 0 and table.find(registerTypes, 'Tool') then table.remove(registerTypes, table.find(registerTypes, 'Tool')) end end
		if Eggpedia[indice] then
			repeat
				indice += 1
				if not Eggpedia[indice] then break end
			until not Eggpedia[indice]
		end
		if table.find(eggNames, eggName) then	table.remove(eggNames, table.find(eggNames, eggName)) end
		if table.find(textures, texture) then	table.remove(textures, table.find(textures, texture)) end
		-- Add egg to Eggpedia
		Eggpedia[indice] = {
			Name = eggName,
			Texture = texture,
			Mesh = mesh,
			Rarity = rarity,
			RegisterType = registerType
		}

		-- Update maximum rarity if this egg has a higher rarity
		if rarity > CheckedMaximumRarity then
			CheckedMaximumRarity = rarity
		end
		latestapply = indice
		table.insert(Sofar, indice)
	end
	return Sofar
end

-- Function to determine which egg to spawn based on rarity
function GetRandomEggBasedOnRarity(): number?
	task.desynchronize()
	local totalWeight = 0
	local eggWeights = {}

	-- Calculate weights based on rarity
	for id, eggData in pairs(Eggpedia) do
		if eggData.Rarity then
			local weight = CheckedMaximumRarity - eggData.Rarity + 1
			totalWeight = totalWeight + weight
			table.insert(eggWeights, {id = id, weight = totalWeight})
		end
	end

	-- Generate a random number and select the egg
	local randomWeight = math.random(1, totalWeight)
	for _, eggWeight in ipairs(eggWeights) do
		if randomWeight <= eggWeight.weight then
			return eggWeight.id  -- Return the selected egg ID
		end
	end
	return nil  -- If no egg is selected, return nil
end

task.desynchronize()
for i,v in ipairs(Eggpedia) do
	if v and v.Rarity and v.Rarity > CheckedMaximumRarity then
		CheckedMaximumRarity = v.Rarity
	end
end

-- Function to register egg data
function Register_Data(Egg: BasePart, Data: EggInfo, Overwrite: boolean?)
	task.desynchronize()
	if not Egg or not (typeof(Egg) == 'Instance') then warn('[[Egg requires a "BasePart" argument]]') return {} end
	if not Overwrite and Dataset[Egg] then warn('[[Egg already registered]]') return end
	if not Data then Data = {} end
	Data.Collected = Data.Collected or false
	Data.AnchorType = (Data.AnchorType == 'Anchored' or Data.AnchorType == 'Unanchored') and Data.AnchorType or 'Unanchored'
	Data.RegisterType = (Data.RegisterType == 'Touch' or Data.RegisterType == 'Tool' or Data.RegisterType == 'None') and Data.RegisterType or 'None'
	Dataset[Egg] = Data
	return Data
end

function DefaultSM(Parent: Instance, Texture: string, Mesh: string): SpecialMesh
	-- Default mesh if none specified
	if not Parent then Parent = workspace end
	task.synchronize()
	local spMesh = Instance.new("SpecialMesh")
	spMesh.Parent = Parent
	if not Mesh or typeof(Mesh) ~= 'string' then
		spMesh.MeshType = Enum.MeshType.Sphere
	else
		spMesh.MeshId = Mesh
	end
	if Texture and typeof(Texture) == "string" then
		spMesh.TextureId = Texture
	end
	return spMesh
end
-- Function to create an egg
function CreateEgg(Parent: Instance?, EggType: number, Anchored: boolean?): BasePart
	task.desynchronize()
	if not EggType then return end
	local EggData = Eggpedia[EggType]
	if not EggData then warn("Invalid Egg Type") return end
	task.synchronize()
	-- Create the basic part (egg body)
	local Part = Instance.new('Part', Parent or workspace)
	Part.Name = EggData.Name
	Part.Anchored = Anchored or false

	local TextureID = EggData.Texture or ""
	if EggData.Texture and TextureID and (typeof(TextureID) == 'Color3' or typeof(TextureID) == 'BrickColor') then
		if typeof(TextureID) == 'BrickColor'  then
			Part.BrickColor = TextureID
		elseif typeof(TextureID) == 'Color3' then
			Part.Color = TextureID
		end
	end

	if typeof(EggData.Mesh) == "string" then
		DefaultSM(Part, EggData.Texture or "", EggData.Mesh)
	elseif typeof(EggData.Mesh) == "Instance" then
		local Mesh = EggData.Mesh:Clone()
		if Mesh:IsA("BasePart") then
			if Part then Mesh.Parent = Part.Parent Part:Destroy() end
			Part = Mesh
		elseif Mesh:IsA("SpecialMesh") then
			Mesh.Parent = Part
			Mesh.TextureID = EggData.Texture or Mesh.TextureID or ""  -- Use texture if provided, otherwise use default
		else -- unrelated
			EggData.Mesh = nil
			Mesh:Destroy()
			DefaultSM(Part)
		end
	else
		DefaultSM(Part)
	end

	Register_Data(Part, {
		Collected = false,
		AnchorType = Anchored and 'Anchored' or 'Unanchored',
		RegisterType = EggData.RegisterType or 'None',
		Name = Part.Name or 'LOREM IPSUM',
		EggType = EggType or 0,
		Event = nil  -- Initially no event is connected
	})

	return Part
end

task.synchronize()
local Parameter = RaycastParams.new()
Parameter.IgnoreWater = true
Parameter.FilterType = Enum.RaycastFilterType.Include
Parameter.RespectCanCollide = true
Parameter.FilterDescendantsInstances = {}
if workspace:FindFirstChild('Map') then
	Parameter:AddToFilter(workspace:FindFirstChild('Map'))
end
if workspace:FindFirstChildOfClass('Terrain') then
	Parameter:AddToFilter(workspace:FindFirstChildOfClass('Terrain'))
end

-- Function to spawn an egg at a specified position
function SpawnEgg(Parent: Instance,Position: Vector3?, EggType: number)
	local Egg = CreateEgg(workspace, EggType or 0, false)
	if not Egg then return end
	task.synchronize()
	Egg.Position = Position or Vector3.new(0, 10, 0)
	Egg.Parent = Parent or workspace
	local destroy
	destroy = Egg.Destroying:Once(function()
		if Egg and Dataset[Egg] and Dataset[Egg].Event then task.synchronize() Dataset[Egg].Event:Disconnect() end
		Dataset[Egg] = nil
		if destroy then task.synchronize() destroy:Disconnect() end
	end)
	if Eggpedia[EggType] and Eggpedia[EggType].RegisterType ~= 'None' then
		task.synchronize() Debris:AddItem(Egg, 600)
		SetupEggCollection(Egg, Dataset[Egg].RegisterType)
	else
		local Cast = workspace:Blockcast(Egg.CFrame, Egg.Size, Vector3.new(0,-100,0), Parameter)
		if Egg and Cast and Cast.Instance and (not Cast.Instance:FindFirstAncestorWhichIsA("Model") or not not Cast.Instance:FindFirstAncestorWhichIsA("Model"):FindFirstChildOfClass('Humanoid')) then
			Egg.Parent = workspace
			Egg.Anchored = true
			Egg.CFrame = CFrame.new(Cast.Position, Cast.Position + Cast.Normal) * CFrame.Angles(math.rad(-90),math.random(),0)
		end
		if Egg and Dataset[Egg] and Dataset[Egg].Event then task.synchronize() Dataset[Egg].Event:Disconnect() end
		Dataset[Egg] = nil
		if destroy then task.synchronize() destroy:Disconnect() end
	end
end

-- Function to handle egg collection
function CollectEgg(Player, Egg)
	task.desynchronize()
	if not Player or not Egg then return end
	local EggData = Dataset[Egg]
	if EggData and not EggData.Collected then
		EggData.Collected = true
		if not Storage[Player.UserId] then Storage[Player.UserId] = {} end
		Storage[Player.UserId][EggData.EggType] = (Storage[Player.UserId][EggData.EggType] and Storage[Player.UserId][EggData.EggType] + 1) or 1
		if LeaderStatPlayer[Player] and LeaderStatPlayer[Player].Object then task.synchronize() LeaderStatPlayer[Player].Object.Value = not LeaderStatPlayer[Player].On and 0 or #Storage[Player.UserId] end
		
		-- Display collection UI
		ShowCollectedUI(Player, EggData)

		-- Disconnect the event for this egg (if it exists)
		task.synchronize()
		if EggData.Event then
			EggData.Event:Disconnect()
			EggData.Event = nil
		end

		-- Clear Data
		if Egg and Dataset[Egg] then
			Dataset[Egg] = nil
		end
		Debris:AddItem(Egg, .25)
	end
end

-- Setting up a simple UI for when an egg is collected
function CreateUI(PlayerGui: PlayerGui?): (ScreenGui , BindableEvent)
	task.desynchronize()
	if not PlayerGui then return end
	local CollectedUI: ScreenGui?, TriggerEvent: BindableEvent?
	if not PlayerGui:FindFirstChild('__EASTER') then
		task.synchronize()
		local LastType: number = 0
		CollectedUI = Instance.new("ScreenGui", PlayerGui)
		CollectedUI.Name = '__EASTER'
		local latestspawn: thread
		local LastTween: Tween
		local Streak = 0
		local Message = Instance.new("TextLabel", CollectedUI)
		Message.Size = UDim2.new(0.3, 0, 0.1, 0)
		Message.Position = UDim2.new(0.35, 0, 0.1, 0)
		Message.Text = "SOLIVION WAS HERE"
		Message.BackgroundColor3 = Color3.new(0, 0, 0)
		Message.TextScaled = true
		local COMBOMessage = Instance.new("TextLabel", CollectedUI)
		COMBOMessage.Size = UDim2.new(0.3, 0, 0.05, 0)
		COMBOMessage.Position = UDim2.new(0.15, 0, -0.1, 0)
		COMBOMessage.Text = "COMBO: 0"
		COMBOMessage.TextStrokeTransparency = 0
		COMBOMessage.Visible = false
		COMBOMessage.BackgroundTransparency = 1
		COMBOMessage.BackgroundColor3 = Color3.new(0, 0, 0)
		COMBOMessage.TextScaled = true
		local UICORNER = Instance.new('UICorner', Message)
		UICORNER.CornerRadius = UDim.new(1,0)
		game:FindFirstChildOfClass('TweenService'):Create(UICORNER, TweenInfo.new(.5), {CornerRadius = UDim.new(0.25,0)}):Play()
		TriggerEvent = Instance.new('BindableEvent', CollectedUI)
		TriggerEvent.Name = '__UIREQUEST'
		local Connection: RBXScriptConnection
		Connection = TriggerEvent.Event:Connect(function(SentFrom: Script, Data: EggInfo, Extra_Overwrite: Boolean?)
			task.desynchronize()
			if (not Message or not CollectedUI or not PlayerGui) and Connection then
				task.synchronize()
				Connection:Disconnect()
				return
			end
			if SentFrom == script and Data and Data.Name and Data.EggType and Eggpedia[Data.EggType] then
				task.synchronize()
				if LastTween then LastTween:Cancel() end
				local Rarity: number? = Eggpedia[Data.EggType].Rarity or 0
				local BounceSpecial: boolean = Extra_Overwrite
				local MatchLast: boolean = LastType == Data.EggType
				LastType = Data.EggType
				if MatchLast  then
					Streak += (BounceSpecial and -1 or 1)
				else
					Streak = 0
				end
				local Output = math.clamp(Rarity/CheckedMaximumRarity, 0, 1)
				if PlayerGui and PlayerGui:FindFirstChild('__INVENTORIES') and PlayerGui:FindFirstChild('__INVENTORIES'):FindFirstChildOfClass('BindableEvent') then
					PlayerGui:FindFirstChild('__INVENTORIES'):FindFirstChildOfClass('BindableEvent'):Fire(Data.EggType)
				end
				if Message then
					local Additional = 15 * (Rarity/CheckedMaximumRarity)
					local Saved = Message.Rotation
					if Saved ~= 0 then
						Message.Rotation = -(Saved) + (Saved >=0 and -Additional or Additional)
					else
						Message.Rotation = (math.random() > .5 and -Additional or Additional)
					end
					Message.Transparency = 0
					Message.TextColor3 = Color3.new(1,1,1)
					Output = MatchLast and Output * 2 or Output
					if COMBOMessage then
						if Streak ~= 0 then
							local onetenth = math.clamp(Streak/10, 0, 1)
							COMBOMessage.Visible = true
							COMBOMessage.TextStrokeTransparency = 0
							COMBOMessage.TextStrokeColor3 = Color3.new(onetenth, onetenth, onetenth)
							COMBOMessage.TextColor3 = Color3.new(1 - onetenth, 1 - onetenth, 1 - onetenth)
							COMBOMessage.TextTransparency = 0
							COMBOMessage.Text = 'STREAK: '..tostring(Streak)
							COMBOMessage.Size = COMBOMessage.Size + COMBOMessage.Size
							COMBOMessage.Position = COMBOMessage.Position + UDim2.new(math.random(-Output, Output)/2, math.random(-Output, Output)/2)
							game:FindFirstChildOfClass('TweenService'):Create(COMBOMessage, TweenInfo.new(Output * 2), {Size = UDim2.new(0.3, 0, 0.05, 0), TextColor3 = Color3.new(1,1,1), TextStrokeColor3 = Color3.new(0,0,0), TextTransparency = 1, TextStrokeTransparency = 1, Position = UDim2.new(0.15, 0, -0.1, 0)}):Play()
						else
							COMBOMessage.Visible = false
						end
					end					
					Message.Text = (BounceSpecial and 'You took out: ' or "You collected: ") .. Data.Name ..(Streak ~= 0 and string.rep('!',Streak) or '')
					Message.BackgroundColor3 = (BounceSpecial and Color3.new(.3,.3,.3)) or Color3.new(Output, 0, 1 - Output)
					Message.BorderSizePixel = Message.BorderSizePixel + ((Rarity/CheckedMaximumRarity) * Message.AbsoluteSize.Magnitude)
					local ThisLastTween = game:FindFirstChildOfClass('TweenService'):Create(Message, TweenInfo.new(Message.BorderSizePixel/25), {Transparency = 1, BorderSizePixel = 0, Rotation = 0, TextColor3 = Color3.new(0,0,0), BackgroundColor3 = Color3.new(1,1,1)})
					LastTween = ThisLastTween
					if LastTween == ThisLastTween then
						LastTween:Play()
						if latestspawn then task.cancel(latestspawn) end
						latestspawn = task.spawn(function()
							task.wait(LastTween.TweenInfo.Time)
							if LastTween == ThisLastTween and CollectedUI then
								CollectedUI:Destroy()
							end
							latestspawn = nil
						end)
					end
				end
			end
		end)
	else
		CollectedUI = PlayerGui:FindFirstChild('__EASTER')
		if CollectedUI:FindFirstChildOfClass('BindableEvent') then
			TriggerEvent = CollectedUI:FindFirstChildOfClass('BindableEvent')
		end
	end
	return CollectedUI, TriggerEvent
end

function ShowCollectedUI(Player: Player, EggData: EggInfo)
	task.desynchronize()
	if not Player or not EggData then return end
	local VariantNumber = EggData.EggType
	if not Eggpedia[VariantNumber] then
		return
	end
	local PlayerGui: PlayerGui? = Player:FindFirstChildOfClass("PlayerGui")
	if PlayerGui and EggData then
		local UI, Event = CreateUI(PlayerGui)
		if UI and Event then
			task.synchronize()
			Event:Fire(script, EggData)
		end
	end
end

function Inventory(PlrGUI: PlayerGui, Player: Player)
	task.desynchronize()
	if PlrGUI and Player then
		local UIEvent
		if not PlrGUI:FindFirstChild("__INVENTORIES") then
			task.synchronize()
			local ScreenUI: ScreenGui = Instance.new("ScreenGui")
			local ScreenUIFrame: ScrollingFrame = Instance.new("ScrollingFrame")
			local ScrollingFrame: UIListLayout = Instance.new("UIListLayout")
			local UICornerScrollingFrame: UICorner = Instance.new("UICorner")
			local UIGradientScrollingFrame: UIGradient = Instance.new("UIGradient")
			local BindedEvent: BindableEvent = Instance.new("BindableEvent")
			local Disclaimer: TextLabel = Instance.new('TextLabel')
			ScreenUI.Parent = PlrGUI
			ScreenUI.Name = '__INVENTORIES'
			Disclaimer.Parent = ScreenUI
			Disclaimer.BackgroundTransparency = 1
			Disclaimer.TextSize = 25
			Disclaimer.TextStrokeTransparency = 1
			Disclaimer.TextColor3 = Color3.new(1,0,0)
			Disclaimer.TextTransparency = 1
			Disclaimer.Position = UDim2.fromScale(-.25,.5)
			Disclaimer.Size = UDim2.fromScale(.25, .075)
			Disclaimer.Text = [[Egg names are never meant to be correlated to any terms, They're randomly generated]]
			Disclaimer.TextWrapped = true
			Disclaimer.TextScaled = true
			ScreenUIFrame.Name = '__SCREENUIFRAME'
			ScreenUIFrame.Position = UDim2.fromScale(-.25,0)
			ScreenUIFrame.Size = UDim2.fromScale(0,.5)
			ScreenUIFrame.Parent = ScreenUI
			ScreenUIFrame.BackgroundTransparency = 1
			ScreenUIFrame.CanvasSize = UDim2.fromScale(.1,0.3) + UDim2.fromOffset(0,55 * math.clamp(#ScreenUIFrame:GetChildren() - 2, 0, math.huge))
			ScreenUIFrame.VerticalScrollBarInset = Enum.ScrollBarInset.None
			ScreenUIFrame.ScrollBarThickness = .25
			ScreenUIFrame.VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Left
			ScrollingFrame.Parent = ScreenUIFrame
			ScrollingFrame.Padding = UDim.new(0,5)
			ScrollingFrame.Wraps = true
			ScrollingFrame.SortOrder = Enum.SortOrder.LayoutOrder
			UIGradientScrollingFrame.Parent = Disclaimer
			UIGradientScrollingFrame.Transparency = NumberSequence.new(0,1)
			UIGradientScrollingFrame.Offset = Vector2.new(-1,0)
			game:FindFirstChildOfClass('TweenService'):Create(Disclaimer, TweenInfo.new(1.25), {Position = UDim2.fromScale(.05,.5), TextStrokeTransparency = 0, TextTransparency = 0}):Play()
			game:FindFirstChildOfClass('TweenService'):Create(ScreenUIFrame, TweenInfo.new(1), {Size = UDim2.fromScale(.25,.5), Position = UDim2.fromScale(.05,0), BackgroundTransparency = .5 , BackgroundColor3 = Color3.new(0.133333, 0.133333, 0.133333)}):Play()
			game:FindFirstChildOfClass('TweenService'):Create(UIGradientScrollingFrame, TweenInfo.new(1), {Offset = Vector2.new(1,0)}):Play()
			UICornerScrollingFrame.Parent = ScreenUIFrame
			BindedEvent.Parent = ScreenUI
			local function CreateNewLabel(i: number): Frame?
				local EggType = i
				local EggData = Eggpedia[EggType]
				if EggType and EggData and ScreenUIFrame then
					local EntryFrame: Frame?
					if ScreenUIFrame and ScreenUIFrame:FindFirstChild("OBJECT_"..EggData.Name.."_ENTRY") then
						EntryFrame = ScreenUIFrame:FindFirstChild("OBJECT_"..EggData.Name.."_ENTRY")
						if EntryFrame then
							EntryFrame.BackgroundColor3 = Color3.new(1,1,1)
							EntryFrame.Size = UDim2.new(1, 0, 0, 100)
							game:FindFirstChildOfClass("TweenService"):Create(EntryFrame, TweenInfo.new(1), {BackgroundColor3 = (EggData.Texture and typeof(EggData.Texture) == 'Color3' and EggData.Texture) or Color3.new(100,100,100), Size = UDim2.new(1, 0, 0, 50)}):Play()
							if EntryFrame:FindFirstChild('__AMOUNT') then
								EntryFrame:FindFirstChild('__AMOUNT').Text = tostring(Storage[Player.UserId][i] and Storage[Player.UserId][i] > 1 and (Storage[Player.UserId][i] > 99 and Storage[Player.UserId][i]..'+' or Storage[Player.UserId][i]) or '')..'	'
							end
						end
					else
						EntryFrame = Instance.new("Frame")
						EntryFrame.Size = UDim2.new(1, 0, 0, 0)
						EntryFrame.BackgroundColor3 = Color3.new(0,0,0)
						game:FindFirstChildOfClass("TweenService"):Create(EntryFrame, TweenInfo.new(1), {Size = UDim2.new(1, 0, 0, 50), BackgroundColor3 = (EggData.Texture and typeof(EggData.Texture) == 'Color3' and EggData.Texture) or Color3.new(100,100,100)}):Play()
						EntryFrame.Parent = ScreenUIFrame
						EntryFrame.Name = "OBJECT_"..EggData.Name.."_ENTRY"

						local Corner = Instance.new("UICorner", EntryFrame)
						Corner.CornerRadius = UDim.new(0.5,0)

						local Gradient = Instance.new('UIGradient', EntryFrame)
						Gradient.Offset = Vector2.new(0,5)
						if (EntryFrame.BackgroundColor3.R + EntryFrame.BackgroundColor3.B + EntryFrame.BackgroundColor3.B) < 1.5 then
							Gradient.Color = ColorSequence.new(Color3.new(0,0,0), Color3.new(1,1,1))
						else
							Gradient.Color = ColorSequence.new(Color3.new(1,1,1), Color3.new(0,0,0))
						end
						Gradient.Rotation = 90
						game:FindFirstChildOfClass("TweenService"):Create(Gradient, TweenInfo.new(1), {Offset = Vector2.new(0,0)}):Play()

						local EggName = Instance.new("TextLabel")
						EggName.Size = UDim2.new(1, 0, 0.25, 0)
						EggName.Position = UDim2.new(0, 0, 0.5, 5)
						EggName.Text = '		Variant ID:'..tostring(i)
						EggName.TextColor3 = Color3.fromRGB(255, 255, 255)
						EggName.TextScaled = true
						EggName.BackgroundTransparency = 1
						EggName.Parent = EntryFrame
						EggName.TextXAlignment = Enum.TextXAlignment.Left

						local EggRetrievedDate = Instance.new("TextLabel")
						EggRetrievedDate.Size = UDim2.new(1, 0, 0.5, 0)
						EggRetrievedDate.Position = UDim2.new(0, 0, 0, 5)
						EggRetrievedDate.Text = '	'..(EggData.Name or "Unknown Egg").. '	'
						EggRetrievedDate.TextColor3 = Color3.fromRGB(255, 255, 255)
						EggRetrievedDate.TextScaled = true
						EggRetrievedDate.BackgroundTransparency = 1
						EggRetrievedDate.Parent = EntryFrame
						EggRetrievedDate.TextXAlignment = Enum.TextXAlignment.Left

						local EggRarity = Instance.new("TextLabel")
						EggRarity.Size = UDim2.new(1, 0, 0.4, 0)
						EggRarity.Position = UDim2.new(0, 0, 0.55, 0)
						EggRarity.Text = "Rarity: " .. tostring(EggData.Rarity or "N/A") .. '	'
						EggRarity.TextColor3 = Color3.new(EggData.Rarity/CheckedMaximumRarity,0, 1 - EggData.Rarity/CheckedMaximumRarity)
						EggRarity.TextStrokeColor3 = Color3.new(1 - EggRarity.TextColor3.R, 0, 1 - EggRarity.TextColor3.B)
						EggRarity.TextStrokeTransparency = 0
						EggRarity.TextScaled = true
						EggRarity.BackgroundTransparency = 1
						EggRarity.Parent = EntryFrame
						EggRarity.TextXAlignment = Enum.TextXAlignment.Right

						local EggAmount = Instance.new("TextLabel")
						local color = EggData.Rarity/CheckedMaximumRarity
						EggAmount.Name = '__AMOUNT'
						EggAmount.Size = UDim2.new(1, 0, 0.45, 0)
						EggAmount.Position = UDim2.new(0, 0, 0.1, 0)
						EggAmount.Text = tostring(Storage[Player.UserId][i] and Storage[Player.UserId][i] > 1 and (Storage[Player.UserId][i] > 99 and Storage[Player.UserId][i]..'+' or Storage[Player.UserId][i]) or '')..'	'
						EggAmount.TextColor3 = Color3.new(color,color,color)
						EggAmount.TextStrokeColor3 = Color3.new(1 - color, 1 - color, 1 - color)
						EggAmount.TextScaled = true
						EggAmount.TextStrokeTransparency = 0
						EggAmount.BackgroundTransparency = 1
						EggAmount.Parent = EntryFrame
						EggAmount.TextXAlignment = Enum.TextXAlignment.Right

						if ScreenUIFrame then
							ScreenUIFrame.CanvasSize = ScreenUIFrame.CanvasSize + UDim2.fromOffset(0,55)
						end
					end
					if EntryFrame then
						EntryFrame.LayoutOrder = EggData.Rarity
					end
					return EntryFrame
				end
			end
			if Player and Storage[Player.UserId] then
				for i,v in pairs(Storage[Player.UserId]) do
					--create entries for eggpedia
					if i and Eggpedia[i] then
						CreateNewLabel(i)
					end
				end
			end
			if ScreenUIFrame and not ScreenUIFrame:FindFirstChildOfClass('Frame') then
				local PlaceHolder = Instance.new('TextLabel', ScreenUIFrame)
				PlaceHolder.Size = UDim2.fromScale(1,1)
				PlaceHolder.Position = UDim2.fromScale(0, .2)
				PlaceHolder.Text = '~<{Inventory Is Currently Empty}>~'
				PlaceHolder.TextSize = 10
				PlaceHolder.BackgroundTransparency = 1
				PlaceHolder.TextStrokeTransparency = 0
				PlaceHolder.TextColor3 = Color3.new(1,1,1)
				PlaceHolder.TextWrapped = true
				PlaceHolder.TextScaled = false
				ScreenUIFrame.ChildAdded:Once(function()
					ScreenUIFrame.BackgroundColor3 = Color3.new(1,1,1)
					game:FindFirstChildOfClass('TweenService'):Create(ScreenUIFrame, TweenInfo.new(.5), {BackgroundColor3 = Color3.new(0.133333, 0.133333, 0.133333)}):Play()
					if PlaceHolder then
						Debris:AddItem(PlaceHolder, .5)
						game:FindFirstChildOfClass('TweenService'):Create(PlaceHolder, TweenInfo.new(.5), {TextTransparency = 1, TextSize = 15, TextStrokeTransparency = 1, TextColor3 = Color3.new(0.333333, 1, 0) , TextStrokeColor3 = Color3.new(1,1,1)}):Play()
					end
				end)
			end
			UIEvent = BindedEvent.Event:Connect(function(i: number)
				task.desynchronize()
				if i and Eggpedia[i] then
					task.synchronize()
					if Storage[Player.UserId][i] then
						CreateNewLabel(i)
					else
						local EggData = Eggpedia[i]
						if ScreenUIFrame and ScreenUIFrame:FindFirstChild("OBJECT_"..EggData.Name.."_ENTRY") and ScreenUIFrame:FindFirstChild("OBJECT_"..EggData.Name.."_ENTRY"):IsA('Frame') then
							Debris:AddItem(ScreenUIFrame:FindFirstChild("OBJECT_"..EggData.Name.."_ENTRY"), 1)
							ScreenUIFrame.CanvasSize = ScreenUIFrame.CanvasSize - UDim2.fromOffset(0,55)
							game:FindFirstChildOfClass('TweenService'):Create(ScreenUIFrame:FindFirstChild("OBJECT_"..EggData.Name.."_ENTRY"), TweenInfo.new(1), {Transparency = 1, Size = UDim2.new(1, 0, 0, 0)}):Play()
							for i,v in ScreenUIFrame:FindFirstChild("OBJECT_"..EggData.Name.."_ENTRY"):GetChildren() do
								if v:IsA('Frame') or v:IsA('TextLabel') then
									game:FindFirstChildOfClass('TweenService'):Create(v, TweenInfo.new(1), {Transparency = 1}):Play()
								end
							end
							if ScreenUIFrame:FindFirstChild("OBJECT_"..EggData.Name.."_ENTRY") then
								ScreenUIFrame:FindFirstChild("OBJECT_"..EggData.Name.."_ENTRY").Name = '__REMOVING'
							end
						end
					end
				end
			end)
		else
			task.synchronize()
			local GUI = PlrGUI:FindFirstChild("__INVENTORIES")
			Debris:AddItem(GUI, 1)
			GUI.Name = '__REMOVING_INVENTORIES'
			for i,v in ipairs(GUI:GetDescendants()) do
				if v:IsA('Frame') or v:IsA('TextLabel') and v.Name ~= '__SCREENUIFRAME' then
					game:FindFirstChildOfClass('TweenService'):Create(v, TweenInfo.new(1), {Transparency = 1, BackgroundColor3 = Color3.new(1,1,1)}):Play()
				elseif v:IsA('ScrollingFrame') and v.Name == '__SCREENUIFRAME' then
					game:FindFirstChildOfClass('TweenService'):Create(v, TweenInfo.new(1), {Size = UDim2.fromScale(v.Size.X.Scale, 0), BackgroundColor3 = Color3.new(1,1,1), BackgroundTransparency = 1}):Play()
				end
			end
		end
		return UIEvent
	end
end

function ProcessMessage(Player,UIEvent,Message,Target,Debounce,uiDebounce)
	task.desynchronize()
	if not Player or Debounce or Target or not Message or not Storage[Player.UserId] then if not Storage[Player.UserId] then Storage[Player.UserId] = {} end if not Player then if ThisCon then ThisCon:Disconnect() end if Player and ChatCon[Player] then ChatCon[Player]:Disconnect() ChatCon[Player] = nil end end return end
		Debounce = true
		task.delay(.1, function()
			Debounce = false
		end)
	
		if Message:upper():sub(1,#"!INVENTORY" + 1):match("!INVENTORY") or Message:upper():sub(1,#"/e !INVENTORY" + 1):match("/E !INVENTORY") then
			--Create UI if none existed
			if uiDebounce then
				Text_ALT(Player, '[[UI TOGGLE IS CURRENTLY ON DEBOUNCE, PLEASE WAIT 1 SECOND BEFORE EACH OPERATION]]')
			end
			uiDebounce = true
			task.delay(1, function()
				uiDebounce = false
			end)
		pcall(function()	local PlrGUI: PlayerGui? = Player and Player:FindFirstChildOfClass("PlayerGui") 
		if UIEvent then task.synchronize() UIEvent:Disconnect() UIEvent = nil end
			local Connection = Inventory(PlrGUI, Player)
			if Connection then
				return Connection
			end end)
		elseif Message:upper():sub(1,#"!HIDESTAT" + 1):match("!HIDESTAT") or Message:upper():sub(1,#"/e !HIDESTAT" + 1):match("/E !HIDESTAT") then
		pcall(function()	if Player and LeaderStatPlayer[Player] then
				LeaderStatPlayer[Player].On = not LeaderStatPlayer[Player].On
				if not LeaderStatPlayer[Player].On and LeaderStatPlayer[Player].Object then
					task.synchronize() LeaderStatPlayer[Player].Object.Value = 0
				else
					task.synchronize() LeaderStatPlayer[Player].Object.Value = #Storage[Player.UserId]
				end
			end end)
		elseif Message:upper():sub(1,#"!TEGGOUT" + 1):match("!TEGGOUT") or Message:upper():sub(1,#"/e !TEGGOUT" + 1):match("/E !TEGGOUT") then
			local startfrom = Message:upper():sub(1,#"!TEGGOUT" + 1):match("!TEGGOUT") and #"!TEGGOUT" + 1 or #"/E !TEGGOUT" + 1
			local submessage = Message:sub(startfrom, #Message)
			if submessage and tonumber(submessage) then
				if not Eggpedia[tonumber(submessage)] then
					Text_ALT(Player, '[[EGG VARIANT ID INVALID]]')
					return
				end
				task.desynchronize()
				local Variant_ID = tonumber(submessage)
				local EggData = Eggpedia[Variant_ID]
				local newinfo = {
					Collected = false,
					AnchorType = 'Unanchored',
					RegisterType = 'None',
					Name = EggData.Name or 'LOREM IPSUM',
					EggType = Variant_ID,
					Event = nil  -- Initially no event is connected
				}
				if not Storage[Player.UserId] or not Storage[Player.UserId][Variant_ID] then
					Text_ALT(Player, '[[EGG NOT IN INVENTORY]]')
					return
				else
					Storage[Player.UserId][Variant_ID] = Storage[Player.UserId][Variant_ID] - 1
					if Storage[Player.UserId][Variant_ID] <= 0 then
						Storage[Player.UserId][Variant_ID] = nil
						if #Storage[Player.UserId] <= 0 then
							Inventory(Player:FindFirstChildOfClass('PlayerGui'), Player)
						end
					end
					task.desynchronize()
					local PlayerGui = Player:FindFirstChildOfClass('PlayerGui')
					if not PlayerGui then Text_ALT('[[No UI]]') return end
					local CollectedUI = PlayerGui:FindFirstChild('__EASTER')
					if CollectedUI and CollectedUI:FindFirstChildOfClass('BindableEvent') then
						task.synchronize()CollectedUI:FindFirstChildOfClass('BindableEvent'):Fire(script, newinfo, true)
					end
					if PlayerGui and PlayerGui:FindFirstChild('__INVENTORIES') and PlayerGui:FindFirstChild('__INVENTORIES'):FindFirstChildOfClass('BindableEvent') then
						task.synchronize()PlayerGui:FindFirstChild('__INVENTORIES'):FindFirstChildOfClass('BindableEvent'):Fire(Variant_ID)
					end
					task.synchronize()
					local newtool = Instance.new('Tool', Player.Backpack)
					local handle = CreateEgg(newtool, Variant_ID, false)
					local Character = Player.Character
					task.synchronize()
					handle.Name = 'Handle'
					Register_Data(handle, newinfo, true)
					task.synchronize()
					newtool.Name = EggData.Name
					local activetime = -123
					local throw = false
					local weld: Weld?
					local function timer()
						local curtime = activetime + math.random()
						if curtime > 123 then
							curtime -= math.random(200,300)
						end
						activetime = curtime
						return curtime
					end
					newtool.ToolTip = EggData.Name..', Rarity: '..tostring(EggData.Rarity)
					newtool.Activated:Connect(function()
						task.synchronize()
						Character = newtool.Parent
						local curtime = timer()
						newtool.ToolTip = 'Release LMB TO Put in Inventory'
						if workspace:GetAttribute('PVP_ON') then
							newtool.ToolTip = 'Hold LMB For .5 Seconds TO Throw'
							task.delay(.1, function()
								if curtime == activetime then
									if not weld or not weld:IsDescendantOf(Character) then
										if weld then task.synchronize() weld:Destroy() end
										task.desynchronize()
										local Torso: BasePart? = Character and FindFirstChildOfNameAndClass(Character, 'UpperTorso', 'BasePart') or FindFirstChildOfNameAndClass(Character, 'Torso', 'BasePart')
										local Arm: BasePart? = Character and FindFirstChildOfNameAndClass(Character, 'RightUpperArm', 'BasePart') or FindFirstChildOfNameAndClass(Character, 'Right Arm', 'BasePart')
										local LeftArmDefaultOffset = CFrame.new(Torso.Size.X/1.35,0,0)
										if Arm and Torso then
											task.synchronize()
											local thisweld = Instance.new('Weld', Character)
											thisweld.Part1 = Arm
											thisweld.Part0 = Torso
											thisweld.C0 = LeftArmDefaultOffset
											weld = thisweld
										end
										--make joint here
									end
									if not weld then return end
									task.synchronize()
									weld.Enabled = true
									game:FindFirstChildOfClass('TweenService'):Create(weld, TweenInfo.new(.4), {C1 = CFrame.Angles(math.rad(-120),0,0):Inverse() * CFrame.new(0,-weld.Part0.Size.Y/3,0)}):Play()
									task.delay(.4, function()
										if curtime == activetime then
											throw = true
										end
									end)
								end
							end)
						end
					end)
					newtool.Deactivated:Connect(function()
						local curtime = timer()
						task.desynchronize()
						if workspace:GetAttribute('PVP_ON') and weld and curtime == activetime then
							if not throw then
								task.synchronize()
								game:FindFirstChildOfClass('TweenService'):Create(weld, TweenInfo.new(.1), {C1 = CFrame.new(math.rad(-90),0,0)}):Play()
								task.delay(.1, function()
									if curtime == activetime and weld then
										task.synchronize()
										weld.Enabled = false
									end
								end)
							else
								task.synchronize()
								newtool.Enabled = false
								game:FindFirstChildOfClass('TweenService'):Create(weld, TweenInfo.new(.1), {C1 = CFrame.new(math.rad(-45),0,0)}):Play()
								--physics here
								local function boom()
									if not handle then return end
									task.synchronize()
									local explode = Instance.new('Explosion', workspace)
									explode.ExplosionType = Enum.ExplosionType.NoCraters
									explode.BlastPressure = EggData.Rarity * 5
									explode.BlastRadius = EggData.Rarity * 5
									explode.DestroyJointRadiusPercent = 0
									explode.Position = handle.Position
									Debris:AddItem(explode)
									local hit = {Character}
									explode.Hit:Connect(function(BasePart, Distance)
										if BasePart and BasePart:FindFirstAncestorWhichIsA('Model') and not table.find(hit, BasePart:FindFirstAncestorWhichIsA('Model'))  and BasePart:FindFirstAncestorWhichIsA('Model'):FindFirstChildOfClass('Humanoid') then
											table.insert(hit, BasePart:FindFirstAncestorWhichIsA('Model'))
											BasePart:FindFirstAncestorWhichIsA('Model'):FindFirstChildOfClass('Humanoid').Health = BasePart:FindFirstAncestorWhichIsA('Model'):FindFirstChildOfClass('Humanoid').Health - (explode.BlastRadius - Distance) * explode.BlastPressure	
										end
									end)
									if handle then	handle:Destroy() end
								end
								local success = pcall(function()
									task.synchronize()
									local PAR = RaycastParams.new()
									PAR.FilterDescendantsInstances = {Character, handle}
									PAR.FilterType = Enum.RaycastFilterType.Exclude
									PAR.RespectCanCollide = true
									handle.Name = '__Thrown'
									handle.Parent = workspace
									handle.Anchored = true
									Debris:AddItem(handle, 125)
									local totaled = 0
									local rayed: RaycastResult
									local Velocity = (weld and weld.Part0 and weld.Part0.CFrame.LookVector or Vector3.new(math.random(-100,100)/100,math.random(-100,100)/100,math.random(-100,100)/100).Unit) * math.random(20,35)
									local currentlocation = handle.CFrame
									coroutine.resume(coroutine.create(function()
										while handle and not rayed and totaled < 120 do
											task.desynchronize()
											local dt = task.wait(1/60)
											rayed = workspace:Blockcast(handle.CFrame, handle.Size/1.25, Velocity, Parameter)
											totaled += dt
											dt = dt * 10
											if not rayed then
												currentlocation = currentlocation + Velocity * dt
												if Velocity.Y > -50 then
													Velocity = Velocity + Vector3.new(0,-10,0) * dt
												end
											task.synchronize()
											handle.CFrame = currentlocation
											end
										end
										task.synchronize()
										boom()
									end))
								end)
								if not success then
									task.synchronize()
									boom()
								end
								task.synchronize()
								Debris:AddItem(weld, .4)
								task.wait(.1)
								if weld then
									task.synchronize()
									game:FindFirstChildOfClass('TweenService'):Create(weld, TweenInfo.new(.4), {C1 = CFrame.new(0,0,0)}):Play()
								end
								task.synchronize()
								Debris:AddItem(newtool, .2)
							end
						else
							task.synchronize()
							if newtool and newtool.Parent and newtool.Enabled and Players:GetPlayerFromCharacter(newtool.Parent) then
								task.synchronize()
								CollectEgg(Players:GetPlayerFromCharacter(newtool.Parent), handle)
								newtool:Destroy()
							end
						end
						if not newtool then return end
						task.synchronize()
						newtool.ToolTip = EggData.Name..', Rarity: '..tostring(EggData.Rarity)
						throw = false
					end)
					newtool.Unequipped:Connect(function()
						task.desynchronize()
						local curtime = timer()
						throw = false
						if weld then
							task.synchronize()
							weld:Destroy()
						end
						task.desynchronize()
						if not newtool or not newtool.Parent then
							return
						end
						if script:FindFirstAncestorWhichIsA('Backpack') or newtool.Parent:IsA('Model') then
							task.synchronize() newtool.ToolTip = EggData.Name..', Rarity: '..tostring(EggData.Rarity)
						else
							task.synchronize() 
							newtool.Enabled = false
							if handle then
								newinfo.RegisterType = EggData.RegisterType
								Register_Data(handle, newinfo, true)
								task.synchronize()
								newtool.Equipped:Once(function()
									newtool.Enabled = true
								end)
							end
						end
					end)
				end
			end
			if LeaderStatPlayer[Player] and LeaderStatPlayer[Player].Object then LeaderStatPlayer[Player].Object.Value = not LeaderStatPlayer[Player].On and 0 or #Storage[Player.UserId] end
		elseif Message:upper():sub(1,#"!GIFT" + 1):match("!GIFT") or Message:upper():sub(1,#"/e !GIFT" + 1):match("/E !GIFT") then
			local startfrom = Message:upper():sub(1,#"!GIFT" + 1):match("!GIFT") and #"!GIFT" + 1 or #"/E !GIFT" + 1
			local submessage = Message:sub(startfrom, #Message):gsub(' ', '')
			if not Player.Character or not Player.Character:FindFirstChildOfClass('Tool') or not Player.Character:FindFirstChildOfClass('Tool'):FindFirstChild('Handle') or not Dataset[Player.Character:FindFirstChildOfClass('Tool'):FindFirstChild('Handle')] then Text_ALT(Player, 'No Character or Tool Invalid') return end
			if Players:FindFirstChild(submessage) and Players:FindFirstChild(submessage):IsA('Player') and Players:FindFirstChild(submessage):FindFirstChildOfClass('Backpack') then
				task.synchronize()Player.Character:FindFirstChildOfClass('Tool').Parent = Players:FindFirstChild(submessage):FindFirstChildOfClass('Backpack')
			else
				Text_ALT(Player, 'Player not found with username: '..submessage)
			end
		end
end
-- Setting up player storage and connecting events
task.synchronize()
ConnectionA = Players.PlayerAdded:Connect(function(Player: Player)
	if not Player or not IsEaster() then return end
	if Player:FindFirstChildOfClass('StarterGear') and not Player:FindFirstChildOfClass('StarterGear'):FindFirstChild('Basket') then
		task.synchronize()
		script:FindFirstChild('Basket'):Clone().Parent = Player:FindFirstChildOfClass('StarterGear')
	end
	local UIEvent: RBXScriptConnection = nil
	local ThisCon: RBXScriptConnection = nil
	local Debounce: boolean = false
	local uiDebounce: boolean = false
	if Player and not Storage[Player.UserId] then Storage[Player.UserId] = {} 
		Text_ALT(Player,
			[[
			-~<{Easter Event IS ON!!}>~-
				Collect Eggs And Have Fun! It'll only be active in ]]..saveda..'/'..savedb..[[
				After that, As long as you don't leave the game, various event commands and inventories will remain usable
				Eggs are all completely autogenerated, They are not meant to be associated with anything whatsoever.

				<<Chat commands are primarily used for Triggering events, this includes>>
				!inventory -- view your current inventory
				!hidestat -- effectively set zero your leaderstat to hide the number until you toggle this off, will not save between same server join
				(WIP)!TEGGOUT [Variant_ID] -- an egg from your inventory will be taken out as a tool, LMB to put it back in inventory
				(WIP)!gift [PlayerName] -- This requires you to hold the tool from !TEGGOUT currently, as I'll figure out inventory to inventory method later
			]])
	end  -- Initialize player inventory
	if Player and ChatCon[Player] then ChatCon[Player]:Disconnect() end
	if Player and not LeaderStatPlayer[Player] then
		LeaderStatPlayer[Player] = {}
		task.synchronize()
		LeaderStatPlayer[Player].Object = Instance.new('NumberValue', Player)
		if LeaderStatPlayer[Player].Object then
			LeaderStatPlayer[Player].Object.Name = 'TotalEggTypes'
			LeaderStatPlayer[Player].Object.Value = not LeaderStatPlayer[Player].On and 0 or #Storage[Player.UserId]
		end
		LeaderStatPlayer[Player].On = true
	end
	while Player and Player.Parent and Player.Parent == Players and not ThisCon and not ChatCon[Player] do
		local chatter = Player:WaitForChild("ChatEvent", 60)
		task.synchronize()
		if not chatter then Text_ALT(Player, "ChatEvent not found! defaulting...") end
		local fa = pcall(function()
			ThisCon = ((chatter and chatter.Event) or Player.Chatted):Connect(function(Message, Target)
				task.desynchronize()
				if Debounce then return end
				local MB = ProcessMessage(Player, UIEvent, Message, Target, Debounce, uiDebounce)
				if MB and typeof(MB) == 'RBXScriptConnection' then
					if UIEvent then
						task.synchronize()
						UIEvent:Disconnect()
					end
					UIEvent = MB
				end
			end)
			if Player and ThisCon then ChatCon[Player] = ThisCon end
		end)
		if not fa or not ThisCon or not ChatCon[Player] then
			Text_ALT(Player, "Error Occured During Chat SetUp For EASTER SCRIPT! Retrying!")
		end
		task.wait(5)
	end
end)

task.synchronize()
ConnectionB = Players.PlayerRemoving:Connect(function(Player: Player)
	if Player and ChatCon[Player] then task.synchronize() ChatCon[Player]:Disconnect() ChatCon[Player] = nil end
	if Player and LeaderStatPlayer[Player] then if LeaderStatPlayer[Player].Object then task.synchronize() LeaderStatPlayer[Player].Object:Destroy() end LeaderStatPlayer[Player] = nil end
end)

-- Collect eggs on touch
function SetupEggCollection(Egg: BasePart, Type: RegisterTypes)
	task.desynchronize()
	if not Egg or not Dataset[Egg] then return end
	local EggData = Dataset[Egg]
	if EggData and EggData.RegisterType == Type then
		local Debounce = false
		local thisevent: RBXScriptConnection
		local BillboardGui, TweenOut, TextLabel, UICorner, UIStroke
		if EggData.RegisterType == 'Tool' and not Egg:FindFirstChildOfClass('BillboardGui') then
			task.synchronize()
			BillboardGui = Instance.new("BillboardGui", Egg)
			BillboardGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
			BillboardGui.Active = true
			BillboardGui.LightInfluence = 1
			BillboardGui.AlwaysOnTop = true
			BillboardGui.Size = UDim2.new(1.5, 0, 1.5, 0)
			BillboardGui.ClipsDescendants = false
			BillboardGui.MaxDistance = 15

			TextLabel = Instance.new("TextLabel")
			TextLabel.Size = UDim2.new(1, 0, 1, 0)
			TextLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
			TextLabel.BackgroundTransparency = 1
			TextLabel.BorderSizePixel = 0
			TextLabel.TextStrokeTransparency = 0
			TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			TextLabel.TextSize = 14
			TextLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
			TextLabel.Text = "Require Basket"
			TextLabel.TextWrapped = true
			TextLabel.Font = Enum.Font.SourceSans
			TextLabel.TextScaled = true
			TextLabel.Parent = BillboardGui

			UICorner = Instance.new("UICorner")
			UICorner.CornerRadius = UDim.new(1, 0)
			UICorner.Parent = TextLabel

			UIStroke = Instance.new("UIStroke")
			UIStroke.Transparency = 1
			UIStroke.Thickness = 0
			UIStroke.Color = Color3.fromRGB(255, 255, 255)
			UIStroke.Parent = TextLabel
		elseif EggData.RegisterType == 'Tool' and Egg:FindFirstChildOfClass('BillboardGui') then
			BillboardGui = Egg:FindFirstChildOfClass('BillboardGui')
			TextLabel = BillboardGui:FindFirstChildOfClass('TextLabel')
			UICorner = TextLabel:FindFirstChildOfClass('UICorner')
			UIStroke = TextLabel:FindFirstChildOfClass('UIStroke')
		end
		if UIStroke then
			task.synchronize()
			TweenOut =	game:FindFirstChildOfClass('TweenService'):Create(UIStroke, TweenInfo.new(1), {Thickness = 10, Transparency = 1, Color = Color3.new(1,1,1)})
		end
		task.synchronize()
		thisevent = Egg.Touched:Connect(function(Hit: BasePart)
			task.desynchronize()
			if Debounce or not Hit or not Hit.Parent or not Hit.Parent:FindFirstChildOfClass('Humanoid') then return end  -- Safeguard against deleted parts or null hierarchy
			Debounce = true
			task.synchronize()
			Egg.CanTouch = false
			task.delay(1, function() Debounce = false task.synchronize() Egg.CanTouch = true end)
			if not Egg or not Dataset[Egg] or Dataset[Egg].Collected then if thisevent then task.synchronize() thisevent:Disconnect() end return end
			task.desynchronize()
			if EggData.RegisterType == 'Tool' and (not Hit.Parent:FindFirstChildOfClass('Tool') or not Hit.Parent:FindFirstChildOfClass('Tool'):GetAttribute('__EasterRegister')) then if UIStroke then task.synchronize() UIStroke.Color = Color3.new(1,0,0) UIStroke.Transparency = 0 UIStroke.Thickness = 0 TweenOut:Play() end return end
			task.synchronize()
			local Player = Players:GetPlayerFromCharacter(Hit.Parent)
			if Player then
				task.synchronize()
				if Hit.Parent and Hit.Parent:IsA('Model') then
					Egg.Material =Enum.Material.Neon
					Egg.CanCollide = false
					Egg.Anchored = true
					game:FindFirstChildOfClass('TweenService'):Create(Egg, TweenInfo.new(.25), {CFrame = Hit.Parent:GetPivot(), Size = Vector3.new(), Transparency = 1}):Play()
					if Egg:FindFirstChildOfClass('SpecialMesh') then
						game:FindFirstChildOfClass('TweenService'):Create(Egg:FindFirstChildOfClass('SpecialMesh'), TweenInfo.new(.25), {Scale = Vector3.new()}):Play()
					end
					if Egg and Dataset[Egg] and Dataset[Egg].EggType and Eggpedia[Dataset[Egg].EggType] then
						local particle = Instance.new('ParticleEmitter', Egg)
						local pedia: EggTypeInfo = Eggpedia[Dataset[Egg].EggType]
						particle.Brightness = pedia.Rarity * 5/CheckedMaximumRarity
						particle.SpreadAngle = Vector2.new(360,360)
						particle.Color = ColorSequence.new(Egg.Color, Color3.new(1,1,1))
						particle.Transparency = NumberSequence.new(0,1)
						particle.RotSpeed = NumberRange.new(30,60)
						particle.Speed = NumberRange.new(pedia.Rarity * 2.5,pedia.Rarity * 5)
						particle:Emit(math.round(pedia.Rarity * 5))
						Debris:AddItem(particle, .2)
					end
				end
				CollectEgg(Player, Egg)
			end
		end)
		if EggData.Event then
			task.synchronize()
			EggData.Event:Disconnect()
		end
		EggData.Event = thisevent
	end
end

task.desynchronize()
GenerateRandomEggs(1000)
local UncollectableSpawnLeft = 25
task.synchronize()
local Folder = Instance.new('Folder',workspace)
Folder.Name = '__Easter'
while task.wait(math.random(7,14)) and IsEaster() do
	if #Folder:GetChildren() < 250 then
		local RandomEgg = GetRandomEggBasedOnRarity()
		if Eggpedia[RandomEgg] and (Eggpedia[RandomEgg].RegisterType ~= 'None' or UncollectableSpawnLeft > 0) then
			if Eggpedia[RandomEgg].RegisterType == 'None' then UncollectableSpawnLeft -= 1 end
			SpawnEgg(Folder,Vector3.new(59.558, 2.5, -1.039) + Vector3.new(math.random(-2000,2000)/15,math.random(10,200),math.random(-2000,2000)/15), RandomEgg)
		elseif Eggpedia[RandomEgg] and Eggpedia[RandomEgg].RegisterType == 'None' and UncollectableSpawnLeft <= 0 then
			Eggpedia[RandomEgg] = nil -- limit reached, removing unneccessary data to save memory
		end
	end
end
--[[for i,v in pairs(ChatCon) do
	v:Disconnect()
end
ChatCon = {}]]
if ConnectionA then task.synchronize() ConnectionA:Disconnect() end if ConnectionB then task.synchronize() ConnectionB:Disconnect() end
for i,v in pairs(Dataset) do
	if i then
		task.synchronize()
		i:Destroy()
	end
end
Dataset = {}
if not IsEaster() then task.synchronize() Text('Thanks Everybody For Playing The Easter Event, The Next Event Should Be Scheduled On Christmas IF a dynamic seasonal event was made on it') end

-- SillySolyMyle lolol