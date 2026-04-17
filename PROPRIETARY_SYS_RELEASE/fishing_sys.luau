--Type Stuff
function showdebug(...) end
local PlayerService = game:GetService("Players") or game:FindFirstChildOfClass('Players')
local TweenService = game:GetService("TweenService") or game:FindFirstChildOfClass('TweenService')
local GravityForce = Vector3.new(0, -9.8, 0) -- yeahhhhhhhhhhhhhhhh
type ItemTypes = ('Fish'|'Rod'|'Item'|'Trash'|'Misc')
type RodStatusTypes = ('Throw'| 'Reel'| 'Idle'| 'Unequipped')
type RodProgressType = ('Reeling' | 'Baiting' | 'Fighting' | 'None')
type InfoStruct = {DisplayName: string, Type: ItemTypes, Description: string, ITEM_ID: number, Object: Instance?}
type ItemStruct = {string: number}
type RodStruct = {
	RodStatus: RodStatusTypes,
	RodProgress: RodProgressType,
	TriggerDebounce: boolean,
	ProgressDebounce: boolean,
	RodTool: Tool,
	RodType: number
}
type InventoryStruct = {
	Items: {ItemStruct},
	Fishes: {ItemStruct},
	FishingRod: {ItemStruct},
	Index: {Fish: {number}, Rod: {number}},
	RodStatus: RodStruct,
	LinkedTool: Tool,
	string: (RBXScriptConnection|thread) -- Either connection or thread I'm to lazy to predefine.
}
local item_infos: {string: InfoStruct} = {}
-- all of them will be cluttered until further improvement
local inventory: {Tool: InventoryStruct} = {}
--Infinite loop
function Loopy(val, delt)
	if val > 100 and delt > 0 then
		val = val - 100
	elseif val < 0 and delt < 0 then
		val = val + 100
	end
	return math.clamp(val, 0, 100)
end--Utility Function To Check If CFrame Is As Intended
function isCFrameInvalid(cframe: CFrame): boolean|string
	if cframe == nil or not CheckFalse(cframe, 'CFrame') then
		return true, "CFrame is nil or contains incompatible type"
	end
	local components = {cframe:GetComponents()}
	for _, component in ipairs(components) do
		if component ~= component then -- Check for NaN
			return true, "CFrame contains NaN"
		end
		if component == math.huge or component == -math.huge then -- Check for infinity
			return true, "CFrame contains infinite value"
		end
	end
	if cframe.Position.Magnitude == 0 and cframe.LookVector.Magnitude == 0 then
		return true, "CFrame is zero"
	end
	return false, "CFrame is valid"
end
--Utility Function To Check If Vector3 Is As Intended
function isVector3Invalid(vector3: Vector3): boolean|string
	if vector3 == nil or typeof(vector3) ~= 'Vector3' then
		return true, "Vector3 is nil"
	end
	if vector3.X ~= vector3.X or vector3.Y ~= vector3.Y or vector3.Z ~= vector3.Z then -- Check for NaN
		return true, "Vector3 contains NaN"
	end
	if math.abs(vector3.X) == math.huge or math.abs(vector3.Y) == math.huge or math.abs(vector3.Z) == math.huge then -- Check for infinity
		return true, "Vector3 contains infinite value"
	end
	return false, "Vector3 is valid"
end
--Type Checking Core Function
function CheckFalse(CheckedInstance: Instance, ClassType: string, IsA: string?)
	if not CheckedInstance or typeof(ClassType) ~= "string" or typeof(CheckedInstance):upper() ~= ClassType:upper() then return false end
	if ClassType:upper() == "INSTANCE" and (typeof(IsA) ~= "string" or not CheckedInstance.Parent or (not CheckedInstance:IsA(IsA) and IsA:upper() ~= CheckedInstance.ClassName:upper())) then return false end
	return true
end
--Clamp Magnitude Of A Vector
function ClampVector(Vector: Vector3)
	if not IsVector(Vector) or Vector.Magnitude == 0 then return Vector3.new() end
	return Vector.Unit * math.clamp(Vector.Magnitude, 0, 10000)
end
--Colour Conversion
function GetColour(Value: (Color3 | BrickColor))
	return (IsColour(Value) and (typeof(Value) == "BrickColor" and Value.Color) or (typeof(Value) == "Color3" and Value)) or Color3.FromRGB(math.random(1,255), math.random(1,255), math.random(1,255))
end
--Type Checking Shortcuts
function IsThread(Thread: thread) return CheckFalse(Thread, "thread") end
function IsTable(Table: {}) return CheckFalse(Table, "table") end
function IsNumber(Number: number) return CheckFalse(Number, "number") end
function IsAttachment(Attachment: Attachment) return CheckFalse(Attachment, "Instance", "Attachment") end
function IsColour(Colour: (Color3 | BrickColor)) return CheckFalse(Colour, "Color3") or CheckFalse(Colour, "BrickColor") end
function IsVector(Vector: Vector3) return (not isVector3Invalid(Vector)) and CheckFalse(Vector, "Vector3") end
function IsEvent(Event: RbxScriptConnections) return CheckFalse(Event, "RbxScriptConnections") end
function IsPlayer(Instance: Player) return CheckFalse(Instance, "Instance", "Player") end
function IsCharacter(Instance: Model) return CheckFalse(Instance, "Instance", "Model") and Instance:FindFirstChildOfClass("Humanoid") end
function IsTool(Instance: Tool) return CheckFalse(Instance, "Instance", "Tool") end
function IsPart(Instance: BasePart) return CheckFalse(Instance, "Instance", "BasePart") end
function deepMerge(target, source)
	if type(target) ~= "table" or type(source) ~= "table" then
		warn("Both arguments must be tables")
		return IsTable(source) and source or IsTable(target) and target or {}
	end
	for key, value in pairs(source) do
		local targetValue = target[key]
		if type(value) == "table" and type(targetValue) == "table" then
			target[key] = mergeTables(targetValue, value)
		elseif type(value) == "number" and type(targetValue) == "number" then
			target[key] = targetValue + value
		elseif type(value) == "string" and type(targetValue) == "string" then
			target[key] = value
		elseif type(targetValue) == "table" then
			-- the target array was not containing a table
			target[key] = value
		else
			target[key] = value
		end
	end
	return target or {}
end
function mergeTables(base, mixin)
	if type(base) ~= "table" or type(mixin) ~= "table" then
		warn("Both arguments must be tables")
		return IsTable(mixin) and mixin or IsTable(base) and base or {}
	end
	-- Check if both tables are array-based
	if #base > 0 and #mixin > 0 then
		for _, value in ipairs(mixin) do
			if type(value) == "table" then
				table.insert(base, mergeTables({}, value))
			else
				table.insert(base, value)
			end
		end
	else
		-- Both are dictionaries or mixed, perform deep merge
		base = deepMerge(base, mixin)
	end
	return base or {}
end
--Visual Management
function NewBait(Colour: Color3): Part if not script:FindFirstChild("Bait") then local NewBait: Part = Instance.new("Part", script) NewBait.Size = Vector3.new(.5,.5,.5) NewBait.Name = "Bait" end local Bait = script:FindFirstChild("Bait") if IsColour(Colour) then Bait.Color = GetColour(Colour) else Bait.Color = Color3.new(1,1,1) end return Bait:Clone() end
function RuntimePhysic(Tool: Tool, Object: BasePart, StartPos: Vector3, InitialVelocity: Vector3)
	task.desynchronize()	
	if not IsTool(Tool) or not IsPart(Object) then 
		showdebug('no part')
		return 
	end

	local Physic_Task = coroutine.create(function()
		if not IsVector(InitialVelocity) then 
			InitialVelocity = Vector3.new() 
		end
		if not IsVector(StartPos) then
			StartPos = Tool:GetPivot().Position or Object.Position or Vector3.new()
		end
		
		task.synchronize()
		Object.Parent = Tool or workspace
		Object.Position = StartPos
		Object.Anchored = true
		
		local CurPos: Vector3 = StartPos
		local Floor: RaycastResult
		local IsWaterMatNow: boolean
		local CurrentVelocity = InitialVelocity
		local Filter = RaycastParams.new()
		Filter.IgnoreWater = true
		Filter.RespectCanCollide = true
		Filter.FilterDescendantsInstances = {Object}
		while Object and IsTool(Tool) and  IsCharacter(Tool.Parent)
			and Object:IsDescendantOf(workspace)
			and CurPos.Y >= workspace.FallenPartsDestroyHeight 
			and ((not Floor and not IsWaterMatNow) or Vector3.new(CurrentVelocity.X,0,CurrentVelocity.Z).Magnitude > 0.01) do
			task.desynchronize()	
			local Delta = task.wait() * 15
			task.synchronize()
			local ToolPivot = Tool:GetPivot()
			task.desynchronize()
			local NewPosition = CurPos + (CurrentVelocity * Delta / 1.5)
			local CollisionCast = workspace:Raycast(CurPos, NewPosition - CurPos, Filter)
			IsWaterMatNow = CurPos.Y < .1 --true or MatNow and (MatNow[1] == Enum.Material.Water) or (MatNow[1] and MatNow[1][1] == Enum.Material.Water) or (MatNow[1] and MatNow[1][1] and MatNow[1][1][1] == Enum.Material.Water)
			Floor = workspace:Raycast(
				CurPos, 
				Vector3.new(0, -(Object.Size.Y / 2 * (-Object.CFrame.UpVector):Dot(Vector3.new(0, -1, 0))), 0), 
				Filter
			)
			if not CollisionCast or CollisionCast.Instance == Object or CollisionCast.Material == Enum.Material.Air or CollisionCast.Material == Enum.Material.Water then
				CurPos = NewPosition
				local Final = CFrame.new(CurPos, CurPos +  Vector3.new(CurrentVelocity.X, 0, CurrentVelocity.Z))
				task.synchronize()
				Object.CFrame = Final
				task.desynchronize()
			else
				CurrentVelocity = (CurrentVelocity - (2 * CollisionCast.Normal * CurrentVelocity:Dot(CollisionCast.Normal))) * (3 / 4)
			end
			local Dir = (CurPos - ToolPivot.Position)
			local DirUn = Dir.Unit
			CurrentVelocity -= ((Vector3.new(CurrentVelocity.X, 0, CurrentVelocity.Z).Magnitude ^ 2)/25) * Delta * Vector3.new(DirUn.X, 0, DirUn.Z) -- Centrifugal hori
			CurrentVelocity -= ((CurrentVelocity.Y ^ 2)/25) * Delta * Vector3.new(0, DirUn.Y, 0) -- Centrifugal hori
			if Dir.Magnitude > 35 then
				break
			elseif Vector3.new(Dir.X,0,Dir.Z).Magnitude > 30 then
				CurPos = ToolPivot.Position - Vector3.new(0,ToolPivot.Y - CurPos.Y,0) + Vector3.new(Dir.X,0,Dir.Z).Unit * 30
			elseif Dir.Magnitude > 25 then
				CurrentVelocity -= DirUn * (-25 + Dir.Magnitude)/5
			end
			local FrictionForce = -Vector3.new(CurrentVelocity.X, 0, CurrentVelocity.Z).Unit * 0.5 * Delta
			CurrentVelocity += FrictionForce
			if Floor and Floor.Instance ~= Object and Floor.Material ~= Enum.Material.Air and Floor.Material ~= Enum.Material.Water then
				local SlopeForce = GravityForce - (Floor.Normal * GravityForce:Dot(Floor.Normal))

				if Floor.Normal:Dot(Vector3.yAxis) >= .99 then
					CurrentVelocity = Vector3.new(CurrentVelocity.X,math.max(CurrentVelocity.y,0),CurrentVelocity.Z)
				elseif Floor.Normal:Dot(Vector3.yAxis) <= -.99 then
					CurrentVelocity = Vector3.new(CurrentVelocity.X,math.min(CurrentVelocity.y,0),CurrentVelocity.Z)
				else
					CurrentVelocity = CurrentVelocity + (SlopeForce * Delta)
				end
			elseif not IsWaterMatNow then
				CurrentVelocity = CurrentVelocity + (GravityForce * Delta)
			else
				CurrentVelocity = Vector3.new(CurrentVelocity.X,math.max(CurrentVelocity.y,0),CurrentVelocity.Z) CurrentVelocity = CurrentVelocity - (GravityForce * Delta/2)
			end
			CurrentVelocity = ClampVector(CurrentVelocity)
		end
		if Object and (not IsTool(Tool) or not IsCharacter(Tool.Parent)) then
			task.synchronize()
			Object:Destroy()
			return
		end
		if not Tool or not Tool:IsDescendantOf(workspace) or not Tool:FindFirstChild('Handle') or (Object.Position - Tool:FindFirstChild('Handle').Position).Magnitude > 25 or (not workspace:FindFirstChild('IsItRaining') or not workspace:FindFirstChild('IsItRaining'):IsA('NumberValue') or workspace:FindFirstChild('IsItRaining').Value ~= 1) and (not IsWaterMatNow and CurPos.Y > .5 and Floor and Floor.Material ~= Enum.Material.Water and Floor.Material ~= Enum.Material.Air) then
			--[[Fade out]]
			task.synchronize()
			game:GetService("TweenService"):Create(
				Object, 
				TweenInfo.new(1), 
				{Transparency = 1, Size = Object.Size * 2}
			):Play()
			game:GetService("Debris"):AddItem(Object,1)
			tool_reel(Tool)
		else
			if Object.Position.Y < 0 then
			task.synchronize()
			game:GetService("TweenService"):Create(
				Object, 
				TweenInfo.new(math.abs(Object.Position.Y)/8, Enum.EasingStyle.Back, Enum.EasingDirection.InOut), 
				{Position = Object.Position - Vector3.new(0,Object.Position.Y,0)}
				):Play()
				task.desynchronize()
			end
			BulkSet(Tool, "Rod", {TriggerDebounce = true, RodProgress = "Waiting", RodStatus = "Waiting"})
			tool_fishing(Tool)
		end
	end)
	coroutine.resume(Physic_Task)
	SetNewThread(Tool, "Bait_Physic", Physic_Task)
end
function RetrievePlayer(PlayerName: (string|Model))
	if IsCharacter(PlayerName) then
		for i,v in PlayerService:GetChildren() do if IsPlayer(v) and v.Character == PlayerName then return v end end
	elseif typeof(PlayerName) == 'string' then
		for i,v in PlayerService:GetChildren() do if v.Name:upper() == PlayerName:upper() then return v end end
	end
end
--Index Management
function register_index() end
function reflect(val, thres)
	if not thres then thres = val/2 end
	if val > thres then
		return thres - (val % thres)
	end
	return val
end
--Data Management
function GetInfo(Tool: Tool,Name: (string|number)): any return IsTool(Tool) and IsTable(inventory[Tool]) and inventory[Tool][Name] or nil end
function SetInfo(Tool: Tool, Name: string, value: any): any if IsTool(Tool) and IsTable(inventory[Tool]) then inventory[Tool][Name] = value return value end return {} or nil end
function SetRodInfo(Tool: Tool, Name: string, value: any): any if IsTable(GetInfo(Tool, "RodStatus")) then showdebug('erm') inventory[Tool]["RodStatus"][Name] = value return value end return nil end
function BulkSet(Tool: Tool, Type: ("Rod"|"Main"), Data: {any: any}): (RodStruct | InventoryStruct | nil) if not IsTable(Data) or (Type ~= "Rod" and Type ~= "Main") then showdebug('bulk fail') return end for i,v in pairs(Data) do if Type == "Rod" then SetRodInfo(Tool,i,v) elseif Type == "Main" then SetInfo(Tool,i,v) end end return  (Type == "Rod" and GetInfo(Tool, "RodStatus")) or Type == "Main" and inventory[Tool] or nil end
function GetRodInfo(Tool: Tool, Name: string): any return IsTable(GetInfo(Tool, "RodStatus")) and GetInfo(Tool, "RodStatus") and GetInfo(Tool, "RodStatus")[Name] or {} or nil end
-- should be used if the tool is being indirecly referred(not the actor)
function SetNewConnection(Tool: Tool, Name: string, value: RBXScriptConnection): RBXScriptConnection? if IsEvent(GetInfo(Tool, Name)) then GetInfo(Tool, Name):Disconnect() end return SetInfo(Tool, Name, value) end 
function SetNewThread(Tool: Tool, Name: string, value: thread): thread? if IsThread(GetInfo(Tool, Name)) then task.cancel(GetInfo(Tool, Name)) end return SetInfo(Tool, Name, value) end
function NewRodStruct(Extra: {any}): RodStruct local DefaultData = {RodStatus = "Unequipped",RodProgress = "None",TriggerDebounce = false,ProgressDebounce = false,RodTool = nil,RodType = 0,} if IsTable(Extra) then DefaultData = mergeTables(DefaultData, Extra) end return DefaultData end
function NewToolStruct(Extra: {any}): InventoryStruct local DefaultData = {Items = {},Fishes = {},FishingRod = {},Index = {Fish = {},Rod = {}},RodStatus = NewRodStruct(IsTable(Extra) and Extra.RodStatus), LinkedTool = nil,} if IsTable(Extra) then DefaultData = mergeTables(DefaultData, Extra) end return DefaultData end
function SetUpTool(Tool: Tool): InventoryStruct? if IsTool(Tool) and not inventory[Tool] then local Data = NewToolStruct(inventory[Tool] or {LinkedTool = Tool}) inventory[Tool] = Data showdebug('dataed') Tool.Destroying:Once(function() if inventory[Tool] then for i,v in pairs(inventory[Tool]) do if typeof(v) == 'RBXScriptSignal' then v:Disconnect() end v = nil end inventory[Tool] = nil end end) SetNewConnection(Tool, 'Equip', Tool.Equipped:Connect(function() showdebug('eq') SetRodInfo(Tool, 'TriggerDebounce', true) SetInfo(Tool, 'ToolHolder', Tool.Parent) SetInfo(Tool, 'HolderPlayer', ToolRetrievePlayer(Tool) or RetrievePlayer(Tool.Parent)) SetNewThread(Tool, 'Undebounce', task.spawn(function() task.wait(.25) SetRodInfo(Tool, 'TriggerDebounce', false) SetRodInfo(Tool, 'RodStatus', 'Idle') end)) end)) SetNewConnection(Tool, 'Unequip', Tool.Unequipped:Connect(function() showdebug('uneq') tool_reel(Tool) SetRodInfo(Tool, 'TriggerDebounce', true) SetRodInfo(Tool, 'RodStatus', 'Unequipped') SetNewThread(Tool, 'Undebounce') SetNewThread(Tool, "Waiting") SetNewThread(Tool, "Fishing") end)) SetNewConnection(Tool, 'Activate', Tool.Activated:Connect(function() showdebug('acti') SetInfo(Tool, 'Active', true) tool_throw(Tool) end)) SetNewConnection(Tool, 'Deactivate', Tool.Deactivated:Connect(function() showdebug('deacti') SetInfo(Tool, 'Active', false) if GetRodInfo(Tool, 'RodStatus') == "Waiting" then tool_reel(Tool) end end)) showdebug('Connected') return Data end return nil end
function UIDisplay(Tool, UIInstance: ScreenGui, PlayerInstance: Player, PreviousTable: {[string]: Instance}, UIStructs: {UIStruct})
	-- Check if the player is valid
	if not IsPlayer(PlayerInstance) then
		--print('UI not plr')
		if UIInstance then
			UIInstance:Destroy()
			SetInfo(Tool, "UIHolder", nil)
		end
		SetInfo(Tool,"HolderPlayer", nil)
		print('uhhh')
		return
	end
	
	--print('UIDISED')
	-- Create a new ScreenGui if it doesn't exist
	if not UIInstance or UIInstance.Parent == nil then
		task.synchronize()
		local NEWUI = Instance.new("ScreenGui", PlayerInstance)
		NEWUI.Name = 'ui'
		SetInfo(Tool, "UIHolder", NEWUI)
		NEWUI.Parent = PlayerInstance:FindFirstChildOfClass("PlayerGui")
		UIInstance = NEWUI
	else
		if not UIInstance.Enabled then
			task.synchronize()
			UIInstance.Enabled = true
		end
	end
	
	PreviousTable = IsTable(PreviousTable) and PreviousTable or {}
	
	task.synchronize()
	-- Iterate through the UIStructs to create or update UI elements
	for _, uiStruct in pairs(UIStructs) do
		if not IsTable(uiStruct) or not uiStruct.Name or not uiStruct.Type then continue end
		-- Check if the UI element already exists
		local TargetInstance = PreviousTable[uiStruct.Name]
		if not TargetInstance then
			-- Create a new instance based on the specified type
			TargetInstance = Instance.new(uiStruct.Type)
			TargetInstance.Name = uiStruct.Name
			TargetInstance.Parent = UIInstance
			PreviousTable[uiStruct.Name] = TargetInstance
		end

		-- Set properties for the UI element
		for property, value in pairs(uiStruct.Properties) do
			TargetInstance[property] = value
		end
	end

	-- Return the updated table of UI elements
	return PreviousTable
end
function ToolRetrievePlayer(Tool: Tool): Player? local BasedData = GetInfo(Tool, 'ToolHolder') if IsCharacter(BasedData) then for i,v in ipairs(PlayerService:GetChildren()) do if v:IsA("Player") and v.Character == BasedData then return v end end end end
	--Action Management
function tool_throw(Tool: Tool): RodStruct? showdebug('threw') local RodData: RodStruct = GetInfo(Tool, 'RodStatus') if RodData and RodData.RodStatus == "Idle" and RodData.TriggerDebounce == false then Tool.ToolTip = 'throwing bait' showdebug('passed con') if IsThread(GetInfo(Tool, 'UnanchorEvent')) then task.cancel(GetInfo(Tool, 'UnanchorEvent')) end SetRodInfo(Tool, "TriggerDebounce", true) SetRodInfo(Tool, "RodStatus", "Throw") SetRodInfo(Tool, "RodProgress", "Baiting") local Bait = GetRodInfo(Tool, 'Bait') if not IsPart(Bait) or Bait.Parent == nil then Bait = NewBait() task.synchronize() local ropefake pcall(function() ropefake = Instance.new('RopeConstraint', Bait) if not ropefake then ropefake = Instance.new('Beam', Bait) end end) if ropefake then ropefake.Visible = true local fakeatt = Tool:FindFirstChild('Handle'):Clone() fakeatt.Anchored = true fakeatt.CanCollide = false fakeatt.Transparency = 1 fakeatt.Parent = Bait coroutine.resume(coroutine.create(function() local ys = Tool:FindFirstChild('Handle').Size.Y/2.5 fakeatt.Anchored = true while task.wait() and Tool and Tool:FindFirstChild('Handle') and ropefake and Bait and Bait:IsDescendantOf(workspace) and Tool.Parent and (not fakeatt or (fakeatt.Position - Bait.Position).Magnitude <= 30) and (Tool:FindFirstChild('Handle').Position - Bait.Position).Magnitude <= 30 and Tool.Parent:IsA('Model') and  fakeatt:IsDescendantOf(workspace) do if not fakeatt or not fakeatt.Parent then fakeatt = Tool:FindFirstChild('Handle'):Clone() fakeatt.Anchored = true fakeatt.CanCollide = false fakeatt.Transparency = 1 fakeatt.Parent = Bait end if not ropefake.Attachment1 or not ropefake.Attachment1.Parent then if Tool:FindFirstChild('Handle') then ropefake.Attachment1 = (fakeatt or Tool:FindFirstChild('Handle')):FindFirstChildOfClass('Attachment') or Instance.new('Attachment', fakeatt or Tool:FindFirstChild('Handle')) end end fakeatt.CFrame =Tool:FindFirstChild('Handle') and (Tool:FindFirstChild('Handle').CFrame + Tool:FindFirstChild('Handle').CFrame.UpVector * ys) or fakeatt.CFrame end if fakeatt then task.synchronize() fakeatt:Destroy() end if Tool then tool_reel(Tool) end end)) if ropefake:IsA("RopeConstraint") then ropefake.Length = 25 ropefake.Thickness = .1 end ropefake.Attachment0 = Instance.new('Attachment', Bait) if Tool:FindFirstChild('Handle') then ropefake.Attachment1 = (fakeatt or Tool:FindFirstChild('Handle')):FindFirstChildOfClass('Attachment') or Instance.new('Attachment', fakeatt or Tool:FindFirstChild('Handle')) end end end if not Bait then return end if not IsPart(GetRodInfo(Tool, 'Bait')) then SetRodInfo(Tool, 'Bait', Bait) Bait.Destroying:Once(function() if Tool then SetRodInfo(Tool, 'Bait', nil) end end) end Bait.Anchored = true showdebug('baiting') Bait.Parent = workspace RuntimePhysic(Tool, Bait, Tool:GetPivot(), Tool:GetPivot().LookVector * math.random(1000,2000)/100 + Tool:GetPivot().UpVector * math.random(1000,1750)/100) return RodData end return nil end
function tool_fishing(Tool: Tool): RodStruct? showdebug('fishing')local RodData: RodStruct = GetInfo(Tool, 'RodStatus') if RodData and RodData.RodStatus == "Waiting" and RodData.TriggerDebounce == true then task.synchronize() Tool.ToolTip = 'waiting for fish' --[[Wait for fish, make system]] SetNewThread(Tool, "Waiting", task.spawn(function() task.wait(math.random(5,25)) local RodDataAnotherTimeAround: RodStruct = GetInfo(Tool, 'RodStatus') if not IsTool(Tool) or not IsCharacter(Tool.Parent) or not RodDataAnotherTimeAround or RodDataAnotherTimeAround.RodStatus ~= "Waiting" then return end tool_initfight(Tool) end)) return RodData end end
function tool_initfight(Tool: Tool): RodStruct? showdebug('fight')
	local RodData: RodStruct = GetInfo(Tool, 'RodStatus') 
	if RodData and RodData.RodStatus == "Waiting" then--[[init minigame here]] Tool.ToolTip = 'Minigaming' BulkSet(Tool, "Rod", {RodStatus = "Minigame", RodProgress = "Minigame"}) 
		local Progress = math.random(75,125)/10 local BarPosition = math.random(1,100) local BarSize = 10 local CalibrationLocation = BarPosition local CalibrationRange = math.random(10,250)/100 --[[The maximum range of calibration. if exceeded will reduce progress, the further from position, the slower it will progress]] 
		local Routine: thread = coroutine.create(function() 
			showdebug('corouter')
			local ELAPSEDTIME = 0
			local maxEXP = (3 - CalibrationRange) * 60
			local diff = 3 - CalibrationRange
			local velocity = 0 -- intertia
			local maxvel = (20/3) * diff
			task.synchronize()
			Tool.ToolTip = '(LMB to control, YOUR CALIBRATION BAR IS GREEN; LEVEL: '..tostring(math.ceil(2.5 - CalibrationRange))..')' 
			while IsTool(Tool) and Progress > 0 and Progress < 100 and GetRodInfo(Tool, 'RodStatus') == 'Minigame' and IsCharacter(Tool.Parent) do
				task.desynchronize()
				local Delta = task.wait() CalibrationLocation = Loopy(CalibrationLocation + (Delta * velocity) + (Delta * (3 + CalibrationRange) * (GetInfo(Tool, 'Active') and 1 or -1)), (GetInfo(Tool, 'Active') and 1 or -1)) local RandMin = (15 ^ math.max(.5, 2.5 - CalibrationRange)) local rand = math.random(-RandMin,RandMin) BarPosition = Loopy(BarPosition + Delta * rand, rand) 
				local Distance =math.max(0,reflect(math.abs(CalibrationLocation - BarPosition), 50) - BarSize/8) - CalibrationRange
				if Distance < 0 then Progress += (Delta * (30 * (1 + CalibrationRange/2.5)) * -Distance) * (1 - math.abs(velocity)/6) else Progress -= Delta * Distance * math.ceil((Progress + 1 + CalibrationRange)/25) end
				local cola = 255 * math.floor((1 - Distance / CalibrationRange) * 50)
				local targetpos = UDim2.new(CalibrationLocation / 100, 0, 0.7, 0)
				if GetInfo(Tool, 'Active') then
					velocity += Delta * maxvel/(1 + diff/2)
				else
					velocity -= Delta * maxvel/(1 + diff * 2/3)
				end
				velocity = math.clamp(velocity,-maxvel,maxvel)
				ELAPSEDTIME += Delta
				if ELAPSEDTIME > maxEXP then
					break
				end 
				tool_ui(Tool, true,
					-- Calibration Line (Background)
					{
						Name = "CalibrationLine",
						Type = "Frame",
						Properties = {
							Size = UDim2.new(0.8, 0, 0, 0.02), -- Horizontal line
							Position = UDim2.new(0.1, 0, 0.7, 0), -- Positioned below the progress bar
							BackgroundColor3 = Color3.fromRGB(100, 100, 100), -- Gray line
							AnchorPoint = Vector2.new(0, 0.5),
						},
					},
					-- Target Marker (CalibrationLocation)
					{
						Name = "TargetMarker",
						Type = "Frame",
						Properties = {
							Size = UDim2.new(0.01, 0, 0.05, 0), -- Thin vertical line
							Position = targetpos, -- Positioned on the calibration line
							BackgroundColor3 = Color3.fromRGB(0, 255, 0), -- Green marker
							AnchorPoint = Vector2.new(0.5, 0.5),
						},
					},
					-- Current Marker (BarPosition)
					{
						Name = "CurrentMarker",
						Type = "Frame",
						Properties = {
							Size = UDim2.new(0.01, 0, 0.05, 0), -- Thin vertical line
							Position = UDim2.new(BarPosition / 100, 0, 0.7, 0), -- Positioned on the calibration line
							BackgroundColor3 = Color3.fromRGB(255, 0, 0), -- Red marker
							AnchorPoint = Vector2.new(0.5, 0.5),
						},
					},
					-- Accuracy Indicator
					{
						Name = "AccuracyIndicator",
						Type = "TextLabel",
						Properties = {
							Size = UDim2.new(0.2, 0, 0.05, 0),
							Position = targetpos - UDim2.fromScale(0.1,.1),
							BackgroundColor3 = Color3.fromRGB(255-cola, 255-cola, 255-cola),
							Text = "Accuracy: " .. tostring(math.floor((1 - Distance / CalibrationRange) * 50)) .. "%",
							TextColor3 = Color3.fromRGB(cola, cola, cola),
							TextScaled = true,
						},
					},
					-- Progress Text (Displays progress as a percentage)
					{
						Name = "ProgressText",
						Type = "TextLabel",
						Properties = {
							Size = UDim2.new(0.2 * math.floor(Progress)/100, 0, 0.05, 0),
							Position = targetpos - UDim2.fromScale(0.1 * math.floor(Progress)/100,.05),
							BackgroundColor3 = Color3.fromRGB(50, 50, 50),
							Text = "Progress: " .. tostring(math.floor(Progress)) .. "%",
							TextColor3 = Color3.fromRGB(255, 255, 255),
							TextScaled = true,
						},
					})
			end 
			task.synchronize()
			tool_ui(Tool, false)
			if Progress >= 100 and IsCharacter(Tool.Parent) then showdebug('Catch Sucess') Tool.ToolTip = 'Caught' --[[Catch event]] local FISHTOOL = Instance.new('Tool', Tool.Parent) FISHTOOL.ToolTip = 'Caught By: '..(Tool.Parent and Tool.Parent:FindFirstChildOfClass('Humanoid') and Tool.Parent:FindFirstChildOfClass('Humanoid').DisplayName) or Tool.Parent.Name FISHTOOL.Name = 'FISH' local FISHHANDLE = Instance.new('Part') FISHHANDLE.Name = 'Handle' FISHHANDLE.Parent = FISHTOOL FISHHANDLE.Color = Color3.new(CalibrationRange/2.5,CalibrationRange/2.5,CalibrationRange/2.5) local UIINTERFACE = Instance.new('BillboardGui', FISHHANDLE) UIINTERFACE.Size = UDim2.new(3,0,1.5,0) local UILabel2 = Instance.new('TextLabel', UIINTERFACE) UILabel2.Size = UDim2.fromScale(1,.5) UILabel2.Position = UDim2.fromScale(0,-.25) local greattext pcall(function() greattext = tostring(os.date()) end) UILabel2.Text = greattext or tostring(os.clock()) UILabel2.Parent = UIINTERFACE local UILabel = Instance.new('TextLabel', UIINTERFACE) UILabel.Size = UDim2.fromScale(1,.5) UILabel.Position = UDim2.fromScale(0,.25) UILabel.Text = 'DIFFICULTY: '..tostring(math.round(250 - CalibrationRange * 100)/100) UILabel.Parent = UIINTERFACE UILabel2.BackgroundTransparency = 1 UILabel.TextScaled = true UILabel2.TextScaled = true FISHHANDLE.Transparency = 0.5 FISHHANDLE.Size = Vector3.new(math.random() * 3, math.random(), math.random()* 1.5)/2 UILabel.BackgroundTransparency = 1 if Tool:FindFirstChild('Handle') and Tool:FindFirstChild('Handle'):IsA('Part') then local cloneboom = Tool:FindFirstChild('Handle'):Clone() if cloneboom and TweenService then cloneboom.CanCollide = false cloneboom.Color = Color3.new(0,1 - (ELAPSEDTIME/maxEXP),0) cloneboom.Material = Enum.Material.ForceField cloneboom.CanTouch = false cloneboom.CanQuery = false cloneboom.Parent = Tool:FindFirstChild('Handle') TweenService:Create(cloneboom, TweenInfo.new(ELAPSEDTIME * 5/maxEXP), {Size = Vector3.new(cloneboom.Size.X * math.random() * 2,cloneboom.Size.Y * math.random() * 2,cloneboom.Size.Z * math.random() * 2), Transparency = 1}) end end tool_reel(Tool) else tool_reel(Tool) Tool.ToolTip = 'Caught Fail' end 
			if maxEXP <= ELAPSEDTIME then
				task.synchronize()
				local exp = Instance.new('Explosion', workspace)
				exp.ExplosionType = Enum.ExplosionType.NoCraters
				exp.BlastPressure = 0
				exp.DestroyJointRadiusPercent = 0
				exp.Position = Tool:GetPivot()
				if game:GetService('Debris') then
					game:GetService('Debris'):AddItem(exp,1)
				else
					task.delay(1,function()
						exp:Destroy()
					end)
				end
			end
		end) 
		SetNewThread(Tool, "Fishing", Routine) 
		if Routine and IsTool(Tool) and IsCharacter(Tool.Parent) then 
			coroutine.resume(Routine) end 
		return RodData 
	end 
end
function tool_reel(Tool: Tool?): RodStruct? showdebug('reel') local RodData: RodStruct = GetInfo(Tool, 'RodStatus') if RodData and RodData.RodStatus ~= "Idle" and RodData.RodStatus ~= "Unequipped" then showdebug('yay reel') tool_ui(Tool, false) --[[reel back to idle, if fish is attached then add to inventory]] BulkSet(Tool, "Rod", {TriggerDebounce = false, RodStatus = "Idle", RodProgress = "None"}) Tool.ToolTip = 'Reeling Back' local TargetObj = GetRodInfo(Tool, 'Bait') if IsPart(TargetObj) then if not IsCharacter(Tool.Parent) then TargetObj:Destroy() SetRodInfo(Tool, 'Bait', nil) else local targetpos = Tool:GetPivot().Position game:GetService('TweenService'):Create(TargetObj, TweenInfo.new(1), {Position = targetpos}):Play() SetInfo(Tool, 'UnanchorEvent', task.spawn(function() if GetRodInfo(Tool, 'Bait') == TargetObj and TargetObj:IsDescendantOf(workspace) then TargetObj.Anchored = false end end)) end end return RodData end end
function tool_ui(Tool: Tool?, Enabled: boolean, ...) 
	local PreviousUIs = GetInfo(Tool, "UIs") 
	if not Enabled then if	GetInfo(Tool, "UIHolder") then task.synchronize() GetInfo(Tool, "UIHolder").Enabled = false return end end 
	if not IsPlayer(GetInfo(Tool, "HolderPlayer")) then  
		task.synchronize()
		if IsTable(PreviousUIs) then for i, v in pairs(PreviousUIs) do v:Destroy() end end 
		SetInfo(Tool, "UIs", {}) 
		if 	GetInfo(Tool, "UIHolder") then
			GetInfo(Tool, "UIHolder"):Destroy()
			SetInfo(Tool, "UIHolder")
		end
	else
		local NewUITable = UIDisplay(Tool, GetInfo(Tool, "UIHolder"), GetInfo(Tool, "HolderPlayer"), PreviousUIs,{...}) SetInfo(Tool,"UIs", NewUITable or {}) 
	end 
end

script.Event.Event:Connect(function(what)
	SetUpTool(what)
	showdebug('yeah')
end)

coroutine.resume(coroutine.create(function()
	while task.wait(150) do --//stray cases, events not picked up
		task.desynchronize()
		for Tool,v: InventoryStruct in pairs(inventory) do
			if not Tool or not Tool.Parent then if v then for aa,bb in pairs(inventory[Tool]) do if typeof(bb) == 'RBXScriptSignal' then bb:Disconnect() end bb = nil end inventory[Tool] = nil end end
		end
	end
end))
