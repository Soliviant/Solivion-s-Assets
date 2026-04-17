--solivion
type Array = {string: any}
type GameState = {  
	Position: Vector3,  
	Velocity: Vector3,  
	CharacterSize: Vector3,  
	WalkDirection: Vector3,  
	CameraAngle: CFrame,  
	Inertia: number,
	--ClientScript: ScreenGui,  
	State: {  
		CanJump: boolean,  
		JumpPower: number,  
		Attributes: Array
	}  
}
local GSREF = {
	Position = 'Vector3', Velocity = 'Vector3', CharacterSize = 'Vector3', WalkDirection = 'Vector3', Inertia = 'number', CameraAngle = 'CFrame', State = {CanJump = 'boolean', JumpPower = 'number', WalkSpeed = 'number', Health = 'number', MaxHealth = 'number', Attributes = 'table'}
}
local DefaultValue: Array = {
	["CFrame"] = CFrame.new(), ["Vector3"] = Vector3.new(), ["Color3"] = Color3.new(0,0,0), ["number"] = 0, ["string"] = '', ["boolean"] = true, ["table"] = {}, 
}
--local ServerStorage = game:GetService('ServerStorage') or game:FindFirstChildOfClass('ServerStorage')
local GSTable: {[Model?]: GameState} = {}
function IsTable(Value: {}) return typeof(Value) == 'table' end
function SafeRetrieve(Table: {}, Key: string) if IsTable(Table) then return Table[Key] end end
function FilterRetreive(Table: {}, Key: string, Type: string) if not IsTable(Table) or not Type or not Key then return end 
	local Retrieved = SafeRetrieve(Table, Key)
	if typeof(Retrieved) == Type then return Retrieved end
end 
function IsHumanoid(Thisthing) return typeof(Thisthing) == 'Instance' and Thisthing:IsA('Humanoid') end
function IsCharacter(Thisthing) return typeof(Thisthing) == 'Instance' and Thisthing:IsA('Model') and (Thisthing:FindFirstChildOfClass('Humanoid') or Thisthing:GetAttribute('__REGPLRID')) end
function FilterType(Value: any, Type: string)
	if typeof(Value) == Type or not DefaultValue[Type] then return Value end
	return DefaultValue[Type]
end

local CollisionParameter = RaycastParams.new()
CollisionParameter.RespectCanCollide = true
CollisionParameter.FilterType = Enum.RaycastFilterType.Exclude
CollisionParameter.IgnoreWater = true

function MatchUp(TableA: {any}, Directory: string)
	task.desynchronize()
	if typeof(TableA) ~= 'table' then TableA = {} end
	local Order = (typeof(Directory) == 'string' and string.split(Directory, '|')) or {}
	local LastTable = TableA
	local LastRef = GSREF
	local latestentry
	if #Order > 0 then
		for i,v in ipairs(Order) do
			if LastTable[v] == nil then
				--print('newtable'..v)
				LastTable[v] = {}
			end
			LastTable = LastTable[v]
			if LastRef[v] == nil then
				return TableA
			end
			LastRef = LastRef[v]
		end
	end
	if typeof(LastRef) == 'string' then  return FilterType(LastTable, LastRef) end
	local complete = LastTable
	for i,v in pairs(LastRef) do
		if (v == 'table' or typeof(v) == 'table') and typeof(complete[i]) ~= 'table' then complete[i] = {} end
		complete[i] = ((v == 'table' or typeof(v) == 'table') and MatchUp(TableA or complete, ((Directory and Directory..'|'..i) or i))) or FilterType(complete[i], v)
		--	print(i,'=', complete[i])
	end
	return complete 
end
function NewGSStruct(Extra: Array?): GameState 
	--[[local StarterTable = {
		Position =  FilterRetrieve(Extra, "Position","Vector3") or Vector3.new(), Velocity =  FilterRetrieve(Extra, "Velocity","Vector3") or Vector3.new(), Character =  FilterRetrieve(Extra, "CharacterSize","Vector3") or Vector3.new(), WalkingDirection = FilterRetrieve(Extra, "WalkingDirection","Vector3") or Vector3.new(),CameraAngle =  FilterRetrieve(Extra, "CameraAngle","CFrame") or CFrame.new(),
		ViewportCameraGui =  FilterRetrieve(Extra, "ViewportCameraGui","Instance"),
			State = FilterRetrieve(Extra, "State", "table") or {}
	}
	if typeof(StarterTable["State"]["CanJump"]) ~= "boolean" then StarterTable["State"]["CanJump"] = FilterRetrieve(Extra, "CanJump", "boolean") or false end
	if typeof(StarterTable["State"]["JumpPower"]) ~= "number" then StarterTable["JumpPower"] = FilterRetrieve(Extra, "JumpPower", "boolean") or 50 end
	if typeof(StarterTable["State"]["Attributes"]) ~= "table" then StarterTable["Attributes"] = FilterRetrieve(Extra, "Attributes", "table") end
	]]
	return MatchUp(Extra or {})
end
local Loop
local Characters = {}
function compare(cf1, cf2)
	if cf1 and cf2 and cf1.LookVector:Dot(cf2.LookVector) >= 0.999 and math.abs(cf1.X - cf2.X) <= 0.01 and
		math.abs(cf1.Y - cf2.Y) <= 0.01 and
		math.abs(cf1.Z - cf2.Z) <= 0.01 then
		return true
	end
	return false
end
function comparevec(v1, v2, threshold)
	local threshold = threshold or 0.001
	return math.abs(v1.X - v2.X) <= threshold and
		math.abs(v1.Y - v2.Y) <= threshold and
		math.abs(v1.Z - v2.Z) <= threshold
end
local function ClipVelocity(velocity: Vector3, normal: Vector3): Vector3
	local backoff = velocity:Dot(normal)

	if backoff < 0 then
		return velocity - (normal * backoff)
	end


	return velocity
end
local function alignToNormal(cf, surfaceNormal)
	if typeof(cf) ~= 'CFrame' then return CFrame.new() end
	if typeof(surfaceNormal) ~= 'Vector3' or surfaceNormal.Magnitude < 0.001 or surfaceNormal.Unit.Magnitude < 1 then return cf end
	local lookVector = cf.LookVector

	-- 2. Calculate the new Right vector (Look x Up = Right)
	local rightVector = lookVector:Cross(surfaceNormal)

	-- Edge case: If the part is looking straight up or down the normal, the cross product is 0.
	-- We fall back to the part's current right vector to prevent it from disappearing/glitching.
	if rightVector.Magnitude < 0.001 then
		rightVector = cf.RightVector:Cross(surfaceNormal)
	end

	rightVector = rightVector.Unit

	-- 3. Calculate the new Back vector (Right x Up = Back)
	-- Note: fromMatrix requires the Z vector to be the "Back" vector, not the Look vector.
	local backVector = rightVector:Cross(surfaceNormal).Unit

	-- 4. Apply the new CFrame
	return CFrame.fromMatrix(cf.Position, rightVector, surfaceNormal, backVector)
end
DEFAULT_LIMIT = 2048
function sanitizeNumber(n, limit)
	limit = limit or DEFAULT_LIMIT
	if n ~= n then
		return 0 
	end return math.clamp(n, -limit, limit)
end
local function fixCFrame(cf, limit)
	local x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = cf:GetComponents()

	-- Sanitize the position
	local safeX = sanitizeNumber(x, limit)
	local safeY = sanitizeNumber(y, limit)
	local safeZ = sanitizeNumber(z, limit)

	-- Check if the rotation matrix is corrupted
	local rotIsValid = true
	local rotValues = {r00, r01, r02, r10, r11, r12, r20, r21, r22}

	for _, r in ipairs(rotValues) do
		-- If any rotation number is NaN or Infinity, it's broken
		if r ~= r or math.abs(r) == math.huge then
			rotIsValid = false
			break
		end
	end

	-- Return the corrected CFrame
	if rotIsValid then
		-- Keep the original rotation, but use the clamped position
		return cf
	else
		-- Reset rotation to default, use the clamped position
		return CFrame.new(safeX, safeY, safeZ)
	end
end

function SetUpLoop()
	if Loop then return end
	local timer = 0.02
	pcall(function()
		if workspace.Name:lower():match('reserved') then
			timer = 1/240
		end
	end)
	Loop = coroutine.create(function()
		while next(GSTable) ~= nil do
			task.desynchronize()
			local Delta = task.wait(timer)
			local InterpolationSpeed = 1 - ((10^-6)^Delta)
			task.synchronize()
			CollisionParameter.FilterDescendantsInstances = Characters
			for i: (Model | Humanoid), v: GameState in pairs(GSTable) do
				task.desynchronize()
				if v.Running then continue end
				task.spawn(function()
				-- Physics initialization
				if typeof(i) ~= 'Instance' and i ~= nil then GSTable[i] = nil elseif i.ClassName == 'Model' then local FakeData = {MoveDirection = Vector3.new(), Jump = false} if typeof(i:GetAttribute('MVDir')) == 'Vector3' then FakeData.MoveDirection = i:GetAttribute('MVDir') end if typeof(i:GetAttribute('JUMP')) == 'boolean' then FakeData.Jump = i:GetAttribute('JUMP') end i = FakeData end
				local MovementDir = Vector3.new()
				local TotalForces = v.Position.Y > -1 and Vector3.new(0, -9.8, 0) * 4 or Vector3.new(0, -9.8, 0) * (1.25+v.Position.Y/4) * 4  -- Gravity
				
				-- Character state validation
				if (typeof(i) ~= 'Instance' and typeof(i) ~= 'table') or not v.Character or typeof(v['Character']) ~= 'Instance' or not v['Character'].Parent or typeof(v['Player']) ~= 'Instance' or not v['Player'].Parent then 
					GSTable[i] = nil 
					return 
				else 
					MovementDir = i.MoveDirection
					if	typeof(GSTable[i]) == 'table' then GSTable[i].Running = true end
				end
				
				-- Slope handling variables
				local groundNormal = Vector3.new(0, 1, 0)
				local onSlope = false
				local slopeAngle = 0
				local slopeFriction = 1

				-- Raycast setup
				local Pivot = CFrame.new(v.Position) * v.CameraAngle
				Pivot = fixCFrame(Pivot)
				local ExtentSize: Vector3 = v.Character:FindFirstChild('UpperTorso') and v.CharacterSize/2.25 or v.CharacterSize/1.575
				if not v.Character:FindFirstChild('UpperTorso') then
					--[[if ExtentSize.Y < 3.75 then
						ExtentSize = Vector3.new(ExtentSize.X, 3.75, ExtentSize.Z)
					end]] -- const size
					ExtentSize = Vector3.new(3,3.5,0.75)
				end
				if v.Character:GetAttribute('__REGPLRID') then
					ExtentSize = Vector3.new(3, 5, 3)/2
				end
				local groundCast = TotalForces.Y <= 0 and workspace:Blockcast(Pivot, ExtentSize, Vector3.new(0, -ExtentSize.Y/2, 0), CollisionParameter)
				-- Ground detection and slope calculation
				ExtentSize = Vector3.new(sanitizeNumber(ExtentSize.X), sanitizeNumber(ExtentSize.Y), sanitizeNumber(ExtentSize.Z))
				if groundCast then
					groundNormal = groundCast.Normal
					slopeAngle = math.deg(math.acos(groundNormal:Dot(Vector3.new(0, 1, 0))))
					onSlope = slopeAngle > 5  -- Minimum slope angle threshold
					Pivot = alignToNormal(Pivot, groundNormal)
					-- Adjust movement for slope surface
					local right = groundNormal:Cross(Vector3.new(0, 0, 1))
					local slopeForward = right:Cross(groundNormal).Unit
					MovementDir = MovementDir - (MovementDir:Dot(groundNormal)) * groundNormal
				else
					onSlope = false
				end

				-- Slope movement physics
				if onSlope then
					-- Walking up slope
					local maxClimbAngle = 45  -- Maximum climbable angle
					if slopeAngle <= maxClimbAngle then
						local slopeFactor = 1 - (slopeAngle / maxClimbAngle)
						MovementDir = MovementDir * slopeFactor
					else
						-- Too steep to climb
						MovementDir = Vector3.new()
					end

					-- Sliding down slope
					if MovementDir.Magnitude <= 0 then
						local slideDirection = (groundNormal - Vector3.new(0, 1, 0)).Unit
						TotalForces = TotalForces + slideDirection * 5 * 9.8 * math.sin(math.rad(slopeAngle))
					end

					-- Adjust friction based on slope material
					if groundCast.Material == Enum.Material.Ice then
						slopeFriction = 0.2
					else
						slopeFriction = 0.6 - (slopeAngle / 100)
					end
				end
				-- Movement interpolation

				-- Collision detection and response (existing code)
				local RayList = {}
				local ExtentHeight: number = math.abs(Pivot.UpVector:Dot(Vector3.new(0, -1, 0)) * ExtentSize.Y * 1.575)
				--local CollisionGround: RaycastResult = workspace:Blockcast(Pivot + (Pivot.UpVector * ExtentSize.Y/2), ExtentSize, Vector3.new(0, -ExtentHeight, 0), CollisionParameter) or workspace:Blockcast(Pivot - (Pivot.UpVector * ExtentSize.Y/2), ExtentSize, Vector3.new(0, ExtentHeight/2,0), CollisionParameter)
				--local CollisionCeiling: RaycastResult = workspace:Blockcast(Pivot - (Pivot.UpVector * ExtentSize.Y/2), ExtentSize, Vector3.new(0, ExtentHeight,0), CollisionParameter) or workspace:Blockcast(Pivot + (Pivot.UpVector * ExtentSize.Y/2), ExtentSize, Vector3.new(0, -ExtentHeight/2,0), CollisionParameter)
				local CollisionGround: RaycastResult = workspace:Blockcast(Pivot, ExtentSize, Vector3.new(0, -ExtentHeight/2, 0), CollisionParameter) or workspace:Blockcast(Pivot - (Pivot.UpVector * ExtentSize.Y/2), ExtentSize, Vector3.new(0, ExtentHeight/2,0), CollisionParameter) --or workspace:Blockcast(Pivot - (Pivot.UpVector * ExtentSize.Y/2), ExtentSize, Vector3.new(0,-math.abs(RayDirection.Y),0), CollisionParameter) 
				local CollisionCeiling: RaycastResult = workspace:Blockcast(Pivot, ExtentSize, Vector3.new(0, ExtentHeight/2,0), CollisionParameter) or workspace:Blockcast(Pivot + (Pivot.UpVector * ExtentSize.Y/2), ExtentSize, Vector3.new(0, -ExtentHeight/2,0), CollisionParameter)
				local CollidedMargin: Vector3 = Vector3.new()
				local CollisionRight: RaycastResult = workspace:Blockcast(Pivot - Pivot.RightVector * ExtentSize.X/2, ExtentSize, Pivot.RightVector * ExtentSize.X, CollisionParameter)
				local CollisionLeft: RaycastResult = workspace:Blockcast(Pivot + Pivot.RightVector * ExtentSize.X/2, ExtentSize, Pivot.RightVector * -ExtentSize.X, CollisionParameter)
				local CollisionFront: RaycastResult = workspace:Blockcast(Pivot - Pivot.LookVector * ExtentSize.Z/2, ExtentSize, Pivot.LookVector * ExtentSize.Z, CollisionParameter)
				local CollisionBack: RaycastResult = workspace:Blockcast(Pivot + Pivot.LookVector * ExtentSize.Z/2, ExtentSize, Pivot.LookVector * -ExtentSize.Z, CollisionParameter)
				local CollisionTop: RaycastResult = workspace:Blockcast(Pivot - Pivot.UpVector * ExtentSize.Y/2, ExtentSize, Pivot.UpVector * ExtentSize.Y, CollisionParameter)
				local CollisionBottom: RaycastResult = workspace:Blockcast(Pivot + Pivot.UpVector * ExtentSize.Y/2, ExtentSize, Pivot.UpVector * -ExtentSize.Y, CollisionParameter)
				local CollidedMargin: Vector3 = Vector3.new()
				local RayList: {RaycastResult} = {}
				local function addresulttolist(result: RaycastResult)
					if not IsTable(result) then return end
					table.insert(RayList, result)
				end
				if CollisionGround or v.Position.Y <= -1 then
					if i.MoveDirection.Magnitude <= 0 then v.Inertia-=Delta*2 else v.Inertia+=Delta end
					v.Inertia = math.clamp(v.Inertia, 0.05, 1) * math.clamp((v.WalkDirection:Dot(i.MoveDirection)/2) + .5,0,1)
					--print(v.Character,GetStateData(v.Character, 'WalkSpeed'), GetStateData(v.Character, 'Health'), GetStateData(v.Character, 'MaxHealth'), GetStateData(v.Character, 'CanJump'))
					v.WalkDirection = v.WalkDirection:Lerp(
						MovementDir * v.Inertia * GetStateData(v.Character, 'WalkSpeed') * 
							(0.5 + (GetStateData(v.Character, 'Health')/GetStateData(v.Character, 'MaxHealth')/2)), 
						InterpolationSpeed * slopeFriction
					)
					if v.WalkDirection ~= v.WalkDirection then
						v.WalkDirection = MovementDir * GetStateData(v.Character, 'WalkSpeed')
					end
					if v.Position.Y > -1 and v.Velocity.Y <= 0 and (v.WalkDirection.Y > 1 or i.Jump == true) and GetStateData(v.Character, 'CanJump') then
						--juump
						task.synchronize()
						i.Jump = false
						task.desynchronize()
						SetStateData(v.Character, 'CanJump', false)
						local jumpvel = TotalForces/2
						v.Velocity = v.Velocity + (-TotalForces.Unit * GetStateData(v.Character, 'JumpPower'))
						task.delay(3, function()
							if not i or not v.Character then return end
							SetStateData(v.Character, 'CanJump', true)
						end)
					end
					if v.Position.Y > -1 then v.WalkDirection = Vector3.new(v.WalkDirection.X,0,v.WalkDirection.Z) end
					--if v.WalkDirection.Magnitude > 0 then v.CameraAngle = CFrame.lookAlong(v.Position,v.WalkDirection) end
				elseif CollisionGround then
					Pivot = alignToNormal(Pivot, CollisionGround.Normal)
				end
				task.desynchronize()
				if CollisionGround then TotalForces = Vector3.new(TotalForces.X, math.max(TotalForces.Y, 0), TotalForces.Z) v.Velocity = Vector3.new(v.Velocity.X, math.max(v.Velocity.Y, 0), v.Velocity.Z) end
				if CollisionCeiling then TotalForces = Vector3.new(TotalForces.X, math.min(TotalForces.Y, 0), TotalForces.Z) v.Velocity = Vector3.new(v.Velocity.X, math.min(v.Velocity.Y, 0), v.Velocity.Z) end
				addresulttolist(CollisionGround)
				addresulttolist(CollisionCeiling)
				if CollisionRight then addresulttolist(CollisionRight) CollidedMargin += Pivot.RightVector * math.max(0,(ExtentSize.X) - CollisionRight.Distance) end
				if CollisionLeft then addresulttolist(CollisionLeft) CollidedMargin -= Pivot.RightVector * math.max(0,(ExtentSize.X) - CollisionLeft.Distance) end
				if CollisionFront then addresulttolist(CollisionFront) CollidedMargin += Pivot.LookVector * math.max(0,(ExtentSize.Z) - CollisionFront.Distance) end
				if CollisionBack then addresulttolist(CollisionBack) CollidedMargin -= Pivot.LookVector * math.max(0,(ExtentSize.Z) - CollisionBack.Distance) end
				if CollisionTop then addresulttolist(CollisionTop) CollidedMargin += Pivot.UpVector * math.max(0,(ExtentSize.Y) - CollisionTop.Distance) end
				if CollisionBottom then addresulttolist(CollisionBottom) CollidedMargin -= Pivot.UpVector * math.max(0,(ExtentSize.Y) - CollisionBottom.Distance) end
				if (#RayList > 0) then
					local MaterialCompare: {[Enum.Material?]: number} = {}
					local MostCollidedMat = Enum.Material.Air
					local MostCollidedNumber = 0
					local InstanceCompare: {[Instance]: number} = {}
					local MostCollidedIns = workspace
					local MostCollidedInstanceNumber = 0
					local generalnormal = Vector3.new()
					local generaldistance = 0
					local function addtomatlist(Material: Enum.Material)
						MaterialCompare[Material] = (MaterialCompare[Material] and MaterialCompare[Material] + 1 or 0)
					end
					local function addtoInslist(Instances: Instance)
						InstanceCompare[InstanceCompare] = (InstanceCompare[InstanceCompare] and InstanceCompare[InstanceCompare] + 1 or 0)
					end
					for i,v in ipairs(RayList) do
						if v.Material then
							addtomatlist(v.Material)
						end
						if v.Instance then
							addtoInslist(v.Instance)
						end
						if v.Normal then
							generalnormal += v.Normal
						end
						if v.Distance then
							generaldistance += v.Distance
						end
					end
					generaldistance = generaldistance/#RayList
					generalnormal = generalnormal.Unit
					for i,v in pairs(MaterialCompare) do
						if v > MostCollidedNumber then
							MostCollidedMat = i
							MostCollidedNumber = v
						end
					end
					for i,v in pairs(InstanceCompare) do
						if v > MostCollidedNumber then
							MostCollidedIns = i
							MostCollidedInstanceNumber = v
						end
					end
				end
				v.Position = Vector3.new(sanitizeNumber(v.Position.X), sanitizeNumber(v.Position.Y), sanitizeNumber(v.Position.Z))
				Pivot = fixCFrame(Pivot)
				-- Velocity integration with slope forces
				local Prev = v.Position
				v.Velocity = v.Velocity + (Delta * TotalForces)
				local tmovement = ((v.Velocity + v.WalkDirection) * Delta) 
				tmovement = Vector3.new(sanitizeNumber(tmovement.X), sanitizeNumber(tmovement.Y), sanitizeNumber(tmovement.Z))
				local velcheck = workspace:Blockcast(Pivot, ExtentSize, tmovement, CollisionParameter)
				if velcheck then
					v.Velocity = ClipVelocity(v.Velocity, velcheck.Normal)
					tmovement = ClipVelocity(tmovement, velcheck.Normal)
				end
				v.Velocity = Vector3.new(sanitizeNumber(v.Velocity.X), sanitizeNumber(v.Velocity.Y), sanitizeNumber(v.Velocity.Z))
				tmovement = Vector3.new(sanitizeNumber(tmovement.X), sanitizeNumber(tmovement.Y), sanitizeNumber(tmovement.Z))
				v.Position = v.Position - CollidedMargin + tmovement
				if groundCast or CollisionGround then
					  -- Ground friction
					if v.Velocity.Magnitude <= 0.01 or v.Velocity ~= v.Velocity then v.Velocity = Vector3.new() else v.Velocity = v.Velocity - (v.Velocity.Unit * ((1 - Delta) * 0.5)) end
					--v.Position = v.Position + (groundNormal or CollisionGround.Normal) * 0.1  -- Prevent sinking
				end
				v.Position = Vector3.new(math.clamp(v.Position.X,-1000,1000),math.clamp(v.Position.Y,-100,2000),math.clamp(v.Position.Z,-1000,1000))
				if v.WalkDirection.Magnitude > 0 then local rota = CFrame.lookAlong(Vector3.new(),Vector3.new(v.WalkDirection.X,0,v.WalkDirection.Z)).Rotation lastang = typeof(lastang) == 'CFrame' and lastang:Lerp(rota,InterpolationSpeed) or rota end
				local moveto = (lastang == lastang and lastang or v.CameraAngle) + v.Position
				moveto = fixCFrame(moveto)
				local Velo = Prev - v.Position
				local CamAng = Velo
					if compare(v.LastCharacterPos, moveto) then  if typeof(GSTable[i]) == 'table' then GSTable[i].Running = false end return else v.LastCharacterPos = moveto
					if typeof(v.Character) == 'Instance' and v.Character.ClassName == 'Model' then
						task.synchronize()
						v.Character:PivotTo(moveto)  end
				end
				task.desynchronize()
				if typeof(v.Character) == 'Instance' and typeof(v.Character:GetAttribute('__REGPLRID')) == 'number' and v.Character:GetAttribute('Grounded') ~= (groundCast ~= nil or CollisionGround ~= nil) then
					task.synchronize() v.Character:SetAttribute("Grounded", (groundCast ~= nil or CollisionGround ~= nil)) task.desynchronize()
					end if typeof(GSTable[i]) == 'table' then GSTable[i].Running = false end
			end) end
		end
		Loop = nil
	end)
	coroutine.resume(Loop)
end
function GetGSDirectory(Character: Model): GameState?
	--print(IsCharacter(Character) , GSTable[Character:FindFirstChildOfClass('Humanoid') or Character] , {})
	return IsCharacter(Character) and GSTable[Character:FindFirstChildOfClass('Humanoid') or Character] or {}
end
function SetGSDirectory(Character: Model, Key: string?, Value: any)
	local Retrieve = GetGSDirectory(Character)
	if not GSTable[Character:FindFirstChildOfClass('Humanoid') or Character] then SetUpGSDirectory(Character, {Key = Value}) end
	if  typeof(Retrieve) ~= 'table' or Retrieve == {} or typeof(GSTable[Character:FindFirstChildOfClass('Humanoid') or Character]) ~= 'table' then return {} end
	if Key then
		GSTable[Character:FindFirstChildOfClass('Humanoid') or Character][Key] = FilterType(Value, GSREF[Key])
	else
		GSTable[Character:FindFirstChildOfClass('Humanoid') or Character] = Value
	end
end
function GetStateData(Character: Model, Key: string)
	local Data = GetGSDirectory(Character) or {}
	return Data['State'] and Data['State'][Key] or nil
end
function GetData(Character: Model, Key: string)
	return (GetGSDirectory(Character) or {})[Key]
end
function SetStateData(Character: Model, Bulkset: Array)
	if not IsTable(Bulkset) then return end
	local Data = GetData(Character, 'State')
	if not Data then return end
	for i,v in pairs(Bulkset) do
		Data[i] = FilterType(v, GSREF['State'][i])
	end
	SetGSDirectory(Character, 'State', Data)
end
function SetData(Character: Model, Bulkset: Array)
	if not IsTable(Bulkset) then return end
	local Data = GetGSDirectory(Character)
	if not Data then return end
	for i,v in pairs(Bulkset) do
		SetGSDirectory(Character, i, v)
	end
end
function SetUpGSDirectory(Humanoid: Humanoid, Extra: Array?)
	if (((typeof(Humanoid) == 'Instance' and Humanoid.ClassName == 'Model' and not Humanoid:FindFirstChildOfClass("Humanoid")) or IsHumanoid(Humanoid)) and GSTable[Humanoid]) then return end
	GSTable[Humanoid] = NewGSStruct(Extra)
	InitNewPlayerLocalScript(Humanoid.ClassName == 'Humanoid' and Humanoid.Parent or Humanoid)
end
function InitNewPlayerLocalScript(Character: Model)
	if typeof(Character) ~= 'Instance' or Character.ClassName ~= 'Model' then return end
	local Prior = GetData(Character, 'ClientScript')
	if not Prior and Character:FindFirstChild('Cam_GAMEPLAY') and Character:FindFirstChild('Cam_GAMEPLAY'):IsA('LocalScript') then SetData(Character, {ClientScript = Character:FindFirstChild('Cam_GAMEPLAY')}) return end
	if typeof(Prior) == 'Instance' and Prior:IsA('LocalScript') and Prior.Parent == Character then return end
	pcall(function()
		task.synchronize()
		local Clone = script:FindFirstChild('Cam_GAMEPLAY'):Clone()
		Clone.Parent = Character
		--If Fail Will not be set anyway.
		SetData(Character, {ClientScript = Clone})
	end)
end

task.synchronize()

function INITPLR(plr: Player, last: boolean?)
	
end

local plrcon = {} -- struct: {acon: Event, destruction: Event, charspawn: Event}
for i,v in game:GetService("Players"):GetChildren() do
	if v:IsA("Player") and v:GetAttribute("BadG") then INITPLR(v) end
end
local Event = script:FindFirstChildOfClass('BindableEvent') or script:WaitForChild('Event', 60)
if not Event or Event.ClassName ~= 'BindableEvent' then Event = Instance.new('BindableEvent', script) Event.Name = 'Event' end

function RegisterCharacter(char, plr)
	if typeof(char) ~= 'Instance' then return end
	
	task.synchronize()
	char:SetAttribute('Disconnect_Execution', true)
	-- Handle Anchoring
	local hum = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild('Humanoid', 5)

	if hum and hum.ClassName == 'Humanoid' and hum.RootPart then
		hum.RootPart.Anchored = true
	else
		local rootPart = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")  or char:FindFirstChild("Head") or char:FindFirstChildOfClass("BasePart")
		if rootPart then
			pcall(function() 
				rootPart.Anchored = true 
			end)
		end
	end

	-- Validation
	if not hum and typeof(char:GetAttribute("__REGPLRID")) ~= 'number' then 
		return 
	end

	-- Registry
	table.insert(Characters, char)

	local Regwith = (hum or char)
	if typeof(Regwith) ~= 'Instance' then return end
	SetUpGSDirectory(Regwith, {
		Character = char, 
		Position = workspace._SpawnLocation.Position + Vector3.new(0, 10, 0), 
		CharacterSize = char:GetExtentsSize(), 
		State = {WalkSpeed = 16, MaxHealth = 100, Health = 100, JumpPower = 30}, 
		CamAng = Vector3.new(),
		Player = plr
	})
	task.synchronize()
	char.Destroying:Once(function()
		local charIndex = table.find(Characters, char)
		if charIndex then
			table.remove(Characters, charIndex)
		end
		GSTable[Regwith] = nil
	end)
	SetUpLoop()
end


-- Main Event Connection
Event.Event:Connect(function(plr, chr)
	if typeof(plr) ~= 'Instance' or plr.ClassName ~= 'Player' or plr:GetAttribute('BadG') then 
		return 
	end
	if typeof(chr) == 'Instance' and chr.ClassName == 'Model' and not plr:GetAttribute("BadG") and not chr:FindFirstChildOfClass('Humanoid') then
		--register that sepecific player to character without registering
		RegisterCharacter(chr, plr)
		return
	end

	plr:SetAttribute('BadG', true)

	pcall(function() 
		(game:FindFirstChildOfClass('ServerScriptService') or game:FindFirstChild('ServerScriptService') or game:WaitForChild("ServerScriptService",10) or game:GetService("ServerScriptService") or game['ServerScriptService']):FindFirstChild('CAMPAIGN'):FindFirstChild('TITLE_HANDLER'):FindFirstChild('Event'):Fire(plr, 'Gameplay Ready, Respawn To Start') 
	end)

	local acon
	acon = plr:GetPropertyChangedSignal('Character'):Connect(function()
		if not plr or not plr.Parent then
			if acon then 
				acon:Disconnect() 
				acon = nil
			end
			return
		end

		local char = plr.Character
		if char then
			RegisterCharacter(char, plr)
		end
	end)

	plr.Destroying:Once(function()
		if acon then
			acon:Disconnect()
			acon = nil
		end
	end)
end)