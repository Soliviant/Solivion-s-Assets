--//Snowball System Framework//--
local Debris = game:FindFirstChildOfClass('Debris')
local SS: (ServerScriptService | Instance) = script.Parent or script:FindFirstAncestorWhichIsA("ServerScriptService")
local Players: Players = game:FindFirstChildOfClass('Players') or game:GetService("Players")
if not SS or not Players then script:Destroy() return end

type MaterialInfo = {
	Hardness: number,
	Breakble: boolean,
	Durability: number,
	EnumLog: Enum.Material?
} 
type BallData = {
	Material: Enum.Material,
	Size: Vector3,
	Damage: number,
	Durability: nunber?
}

local degugging = false
function showtext(...)
	if not degugging then return else print(...) end
end

local PlayerFromChar: {[Model?]: Player} = {}
local Rate = 1/60
local Storage_PLR: {[string?]: {BallData}} = {}
local Material_Data: {[Enum.Material?]: MaterialInfo} = {
}
pcall(function()
	Material_Data[Enum.Material.Ice] = {
		Hardness = 0.1,
		Breakable = true,
		Durability = 8,
		EnumLog = Enum.Material.Ice
	}
	Material_Data[Enum.Material.Snow] = {
		Hardness = 0.1,
		Breakable = true,
		Durability = 4,
		EnumLog = Enum.Material.Snow
	}
	Material_Data[Enum.Material.Rock] = {
		Hardness = 0.6,
		Breakable = false,
		Durability = 9,
		EnumLog = Enum.Material.Rock
	}
	Material_Data[Enum.Material.Grass] = {
		Hardness = 0.2,
		Breakable = true,
		Durability = 4,
		EnumLog = Enum.Material.Grass
	}
	Material_Data[Enum.Material.LeafyGrass] = {
		Hardness = 0.25,
		Breakable = true,
		Durability = 5,
		EnumLog = Enum.Material.LeafyGrass
	}
	Material_Data[Enum.Material.Neon] = {
		Hardness = 0,
		Breakable = true,
		Durability = 2,
		EnumLog = Enum.Material.Neon
	}
	Material_Data[Enum.Material.Sand] = {
		Hardness = 0.1,
		Breakable = true,
		Durability = 2,
		EnumLog = Enum.Material.Sand
	}
	Material_Data[Enum.Material.Pebble] = {
		Hardness = 0.3,
		Breakable = true,
		Durability = 7,
		EnumLog = Enum.Material.Pebble
	}
	Material_Data[Enum.Material.Rubber] = {
		Hardness = 0.4,
		Breakable = true,
		Durability = 10,
		EnumLog = Enum.Material.Rubber
	}
	
end)
local Registered_Projectile: {[Part?]: BallData} = {}
local UserIDThrownCooldown: {string} = {}
local UserIDPickUpCooldown: {string} = {}
local ConnectedTools: {[Tool?]: {RBXScriptConnection}} = {}
local RaycastParameters: RaycastParams = RaycastParams.new()
RaycastParameters.FilterDescendantsInstances = {workspace:FindFirstChildOfClass('Terrain'), workspace.Map}
RaycastParameters.IgnoreWater = true
RaycastParameters.FilterType = Enum.RaycastFilterType.Include
RaycastParameters.RespectCanCollide = true

local Soundcloud = {
	HIT_HARD = 4518881974, HIT = 9119310655, HIT_ALT = 9119312304, SWOOSH = 9119312304, PICKUP = 5530025800
}
function PlaySound(SoundName,ToWhere: Instance?)
	task.synchronize()
	local Mainplayfunction = function(hmm)
		hmm.PlaybackSpeed = math.random(100-20,100+20)/100
		hmm:Play()
	end
	if ToWhere == nil then
		return
	end
	if ToWhere and ToWhere:FindFirstChild(SoundName) and ToWhere:FindFirstChild(SoundName):IsA("Sound") then
		Mainplayfunction(ToWhere:FindFirstChild(SoundName))
	elseif ToWhere and not ToWhere:FindFirstChild(SoundName) then
		if Soundcloud[SoundName] then
			local sound = Instance.new("Sound")
			local Where = ToWhere
			sound.Parent = Where
			sound.Volume = .1
			sound.SoundId = typeof(Soundcloud[SoundName]) == 'string' and Soundcloud[SoundName] or 'http://www.roblox.com/asset/?id='..tostring(Soundcloud[SoundName])
			sound.Name = SoundName
			sound:Play()
		else
			warn("Sound >"..SoundName.."< Not Found In Database")
		end
	end
end

function BounceAngle(rayDirection: Vector3, raycastResult: RaycastResult) : Vector3
	local normal = raycastResult.Normal
	local dotProduct = rayDirection:Dot(normal)
	local reflection = rayDirection - 2 * dotProduct * normal
	if (rayDirection.Unit.X + rayDirection.Unit.Z) < 0.1 then
		reflection = Vector3.new()
	end
	return reflection :: Vector3
end

function StoreData(Player: Player, Data: BallData)
	task.desynchronize()
	if not Storage_PLR or not Player or not Data or typeof(Player) ~= 'Instance' or typeof(Data) ~= 'table' or not Player:IsA('Player') then showtext('bruh') return end
	local ID = tostring(Player.UserId)
	if not Storage_PLR['_'..ID..'_'] then Storage_PLR['_'..ID..'_'] = {} end
	table.insert(Storage_PLR['_'..ID..'_'], Data)
end

function ExportData(Object: Instance, DataTable: {[any?]: any})
	task.desynchronize()
	if not DataTable and Object then DataTable = Registered_Projectile[Object] end
	if not DataTable or not Object or typeof(Object) ~= "Instance" or typeof(DataTable) ~= "table" then return end
	for i,v in pairs(DataTable) do
		if typeof(v) ~= 'Instance' then pcall(function() task.synchronize() Object:SetAttribute(i, v) end) end
	end
end

function NewMaterialData(matname, ext)
	if typeof(matname) ~= 'string' or typeof(ext) ~= 'table' then return end
	if not ext.EnumLog or not table.find(Enum.Material:GetEnumItems(), ext.EnumLog) then
		ext.EnumLog = Enum.Material.Snow
	end
	Material_Data[matname] = {
		Hardness = ext.Hardness or 0,
		Breakable = ext.Breakable or false,
		Durability = ext.Durability or 1,
		EnumLog =  ext.EnumLog or Enum.Material.Snow
	}
end

function RegisterNewBall(Material: (MaterialInfo | Enum.Material | string)?, Extra: BallData?) : BallData?
	task.desynchronize()
	if typeof(Material) ~= "table" then Material = Material_Data[Material] or (Enum.Material[Material] and Material_Data[Enum.Material[Material]]) or (Extra and Extra.Material) or NewMaterialData(Enum.Material, Extra) end
	if not Material then return end
	local Table: BallData = (Extra ~= nil and typeof(Extra) == "table" and Extra) or {}
	local TableMaterial = Table.Material or (typeof(Material) == 'table' and Material.EnumLog) or (typeof(Material) == 'string' and Enum.Material[Material]) or Material or Enum.Material.Ice
	Table.Material = TableMaterial
	local RandomSize = math.random(650,900)/1000
	Table.Size = Table.Size or Vector3.new(RandomSize,RandomSize,RandomSize)
	Table.Damage = Table.Damage or Material.Hardness * 2 or 0
	Table.Durability = Table.Durability or (Material.Durability * Table.Size.Magnitude)
	return Table	
end

function CharacterPickup(Character: Model, Player: Player)
	task.desynchronize()
	if Character and not Player then Player = PlayerFromChar[Character] or Players:GetPlayerFromCharacter(Character) if Player and Player.Character ~= Character then PlayerFromChar[Character] = nil else PlayerFromChar[Character] = Player end end
	if not Character or not Player or typeof(Player) ~= 'Instance' or typeof(Character) ~= 'Instance' or not Character:IsA('Model') or not Character:FindFirstChildOfClass('Humanoid') or not Player:IsA('Player') or Player.Character ~= Character then return end
	local ID: number = tostring(Player.UserId) or '0'
	if table.find(UserIDPickUpCooldown, '_'..ID..'_') then return else table.insert(UserIDPickUpCooldown, '_'..ID..'_') task.delay(1, function() if table.find(UserIDPickUpCooldown, '_'..ID..'_') then table.remove(UserIDPickUpCooldown, table.find(UserIDPickUpCooldown, '_'..ID..'_')) end end) end
	local Raycast = workspace:Raycast(Character:GetPivot().Position, (Character:GetPivot().LookVector * Character.PrimaryPart.Size.Z * 4) - (Character:GetPivot().UpVector * Character.PrimaryPart.Size.Y * 6), RaycastParameters)
	if Raycast and Raycast.Instance and Material_Data[Raycast.Material] then
		local New_Data = RegisterNewBall(Raycast.Material)
		StoreData(Player, New_Data)
		PlaySound('PICKUP', Character.PrimaryPart or Character:FindFirstChildOfClass('BasePart'))
		task.desynchronize()
		showtext('pickup success')
	else
		showtext('pickup fail')
		if Raycast and not Material_Data[Raycast.Material] then
			showtext('no data'..tostring(Raycast.Material.Name))
		end
	end
end

local function BreakGlass(glassPart, hitPosition, hitNormal, projectileVelocity)
	if not glassPart or not hitPosition or not hitNormal or typeof(glassPart) ~= 'Instance' or not glassPart:IsA('BasePart') or (glassPart.Parent == workspace and not glassPart:GetAttribute("__GLASS")) or glassPart:IsA('Terrain') then return end
	
	task.synchronize()
	local size = glassPart.Size or Vector3.new(1,1,1)
	local parent = workspace or glassPart.Parent
	local orientation = glassPart.CFrame or CFrame.new(hitNormal)

	-- Helper function to create a fragment
	local function CreateFragment(position, sizer)
		local fragment = Instance.new("Part")
		if not position then position = orientation.Position end
		if not sizer then sizer = size end
		sizer = Vector3.new(math.min(sizer.X, size.X),math.min(sizer.Y, size.Y),math.min(sizer.Z, size.Z))
		fragment.Size = sizer
		fragment.CFrame = position
		fragment.Material = glassPart.Material
		fragment.Color = glassPart.Color
		fragment.Anchored = false
		fragment.CanCollide = true
		fragment.Parent = parent
		fragment:SetAttribute('__GLASS', true)
		if game:FindFirstChildOfClass('TweenService') then game:FindFirstChildOfClass('TweenService'):Create(fragment, TweenInfo.new(10), {Transparency = 1}):Play() end
		Debris:AddItem(fragment, 10)
		return fragment
	end

	-- Calculate the hit offset relative to the glass's CFrame
	local localHit = orientation:PointToObjectSpace(hitPosition)

	-- Compute the regions and create fragments
	local fragments = {}
	
	local function FragmentAlongAxis(axis, primarySize, secondarySize1, secondarySize2, hitOffset)
		local posOffset = Vector3.new()
		local negOffset = Vector3.new()

		-- Determine size of positive and negative fragments along the hit axis
		local posSize = primarySize / 2 - hitOffset
		local negSize = primarySize / 2 + hitOffset

		-- Clamp the sizes to ensure they remain valid
		posSize = math.max(posSize, 0)
		negSize = math.max(negSize, 0)

		-- Adjust offsets for positioning
		if axis == "X" then
			posOffset = Vector3.new(posSize / 2, 0, 0)
			negOffset = Vector3.new(-negSize / 2, 0, 0)
		elseif axis == "Y" then
			posOffset = Vector3.new(0, posSize / 2, 0)
			negOffset = Vector3.new(0, -negSize / 2, 0)
		elseif axis == "Z" then
			posOffset = Vector3.new(0, 0, posSize / 2)
			negOffset = Vector3.new(0, 0, -negSize / 2)
		end

		-- Create positive and negative fragments
		if posSize > 0 then
			table.insert(fragments, CreateFragment(
				orientation * CFrame.new(posOffset),
				Vector3.new(axis == "X" and posSize or secondarySize1, axis == "Y" and posSize or secondarySize2, axis == "Z" and posSize or secondarySize1)
				))
		end
		if negSize > 0 then
			table.insert(fragments, CreateFragment(
				orientation * CFrame.new(negOffset),
				Vector3.new(axis == "X" and negSize or secondarySize1, axis == "Y" and negSize or secondarySize2, axis == "Z" and negSize or secondarySize1)
				))
		end
	end

	-- Check the hit side and split accordingly
	-- Determine the local hit axis based on the highest dot product
	local xDot = math.abs(hitNormal:Dot(orientation.RightVector or Vector3.xAxis) or 0)
	local yDot = math.abs(hitNormal:Dot(orientation.UpVector or Vector3.yAxis) or 0)
	local zDot = math.abs(hitNormal:Dot(orientation.LookVector or Vector3.zAxis) or 0)

	if xDot > yDot and xDot > zDot then
		-- Hit on the X-axis (RightVector)
		FragmentAlongAxis("X", size.X, size.Y, size.Z, localHit.X)
	elseif yDot > xDot and yDot > zDot then
		-- Hit on the Y-axis (UpVector)
		FragmentAlongAxis("Y", size.Y, size.X, size.Z, localHit.Y)
	else
		-- Hit on the Z-axis (LookVector)
		FragmentAlongAxis("Z", size.Z, size.X, size.Y, localHit.Z)
	end


	-- Apply force to each fragment based on the impact
	for _, fragment in ipairs(fragments) do
		local fragmentCenter = fragment.Position
		local forceDirection = (fragmentCenter - hitPosition).Unit
		fragments.AssemblyLinearVelocity = forceDirection * (projectileVelocity and projectileVelocity.Magnitude or 1) * 10 -- Adjust multiplier as needed
	end

	-- Remove the original glass part
	glassPart:Destroy()
end
function BreakApart(Part: BasePart, HitPos: Vector3?, Normal: Vector3?, HitVel: Vector3?)
	if not Part or Part:IsA('Terrain') or not workspace:GetAttribute('Breakable') or Part.Parent == workspace then return end
	task.synchronize()
	if Part.Anchored or Part:IsGrounded() then
		-- into pieces
		BreakGlass(Part, HitPos, Normal, HitVel)
		if Part then	Part.Anchored = false end
		for _,child in ipairs(Part:GetJoints()) do
			child:Destroy()
		end
	else
		Part:SetNetworkOwner(nil) -- server
		if HitVel and Part:IsA('BasePart') then
			Part.AssemblyLinearVelocity = Part.AssemblyLinearVelocity + HitVel
		end
	end
end

function text2(plr, txt)
	if typeof(plr) ~= 'Instance' or not plr:IsA("Player") or not plr.Parent or typeof(txt) ~= 'string' then return end
	pcall(function()
		game:FindFirstChildOfClass('ReplicatedStorage'):FindFirstChild('LogMessageEvent'):FireClient(plr, txt)
	end)
end
function CharacterThrow(Character: Model, Player: Player, Force: number?)
	task.desynchronize()
	if Character and not Player then Player = PlayerFromChar[Character] or Players:GetPlayerFromCharacter(Character) if Player and Player.Character ~= Character then PlayerFromChar[Character] = nil else PlayerFromChar[Character] = Player end end
	if not Storage_PLR or not Character or not Player or typeof(Player) ~= 'Instance' or typeof(Character) ~= 'Instance' or not Character:IsA('Model') or not Character:FindFirstChildOfClass('Humanoid') or not Player:IsA('Player') or Player.Character ~= Character then return end
	local ID: number = tostring(Player.UserId) or '0'
	if table.find(UserIDThrownCooldown, '_'..ID..'_') then return else table.insert(UserIDThrownCooldown, '_'..ID..'_') task.delay(1, function() if table.find(UserIDThrownCooldown, '_'..ID..'_') then table.remove(UserIDThrownCooldown, table.find(UserIDThrownCooldown, '_'..ID..'_')) end end) end
	if not Storage_PLR or not Storage_PLR['_'..ID..'_'] or #Storage_PLR['_'..ID..'_'] <= 0 then text2(Player, 'No Snowballs Have Been Picked Up Yet') return end
	local Target: BallData = Storage_PLR['_'..ID..'_'][Character:FindFirstChildOfClass('Tool'):GetAttribute('Selected_Slot') or 1]
	if not Target or typeof(Target) ~= 'table' then showtext('<NULL>') return end
	task.synchronize()
	local Part: Part = Instance.new('Part')
	Part.Shape = Enum.PartType.Ball
	Part.Parent = workspace
	Part.Size = Target.Size
	Part.Material = (typeof(Target.Material) == 'table' and Target.Material.EnumLog) or Target.Material or Enum.Material.SmoothPlastic
	Part.Name = '_Effect_'..Player.Name
	Part.Anchored = true
	Part.CFrame = Character:GetPivot()
	PlaySound('SWOOSH', Part)
	Debris:AddItem(Part, 120)
	local AttachmentA: Attachment = Instance.new('Attachment')
	AttachmentA.Parent = Part
	AttachmentA.CFrame = CFrame.new(0,Part.Size.Y,0)
	local AttachmentB: Attachment = Instance.new('Attachment')
	AttachmentB.Parent = Part
	AttachmentB.CFrame = CFrame.new(0,-Part.Size.Y,0)
	local Trail = Instance.new('Trail')
	Trail.Parent = Part
	Trail.Attachment0 = AttachmentA
	Trail.Attachment1 = AttachmentB
	Trail.Lifetime = .1
	Trail.Transparency = NumberSequence.new(.1,1)
	Trail.Color = ColorSequence.new(Color3.new(1,1,1), Color3.new(0,0,0))
	Trail.WidthScale = NumberSequence.new(1,0.5)
	Registered_Projectile[Part] = table.clone(Target)
	local NotInitialMass: number = Material_Data[Target.Material] and Material_Data[Target.Material].Hardness or 1 -- idk mass but yeah
	NotInitialMass *= 1/Target.Size.Magnitude
	local Acceleration: number = (Force/NotInitialMass) or 10 -->> F = ma
	local Velocity: Vector3 = Character:GetPivot().LookVector * Acceleration + Character:GetPivot().UpVector * Acceleration/(math.random(35,50)/10)
	local CurrentAcceleration: Vector3 = Velocity.Unit * Acceleration
	local Durability: number = Target.Durability or 10
	local Damage: number = Target.Damage or 0
	local LastCFrame: CFrame = Character:GetPivot()
	local Raycast: RaycastResult
	local RaycastParameter = RaycastParams.new()
	RaycastParameter.FilterDescendantsInstances = {Character, Part}
	RaycastParameter.FilterType = Enum.RaycastFilterType.Exclude
	RaycastParameter.RespectCanCollide = true
	RaycastParameter.IgnoreWater = true
	if game:FindFirstChildOfClass('Debris') and Part then
		game:FindFirstChildOfClass('Debris'):AddItem(Part, (Durability * 2) + 60)
	end
	coroutine.resume(coroutine.create(function()
		local TimeElapsed = 0
		while Part and Part.Parent and CurrentAcceleration.Magnitude > 0.1 and TimeElapsed < Durability * 4 and LastCFrame.Y >= workspace.FallenPartsDestroyHeight do
			task.desynchronize()
			local DeltaTime = task.wait(Rate) * 10
			local DeltaAcc = CurrentAcceleration * DeltaTime
			if DeltaAcc.Magnitude > 1024 then DeltaAcc = DeltaAcc.Unit * 1024 end
			TimeElapsed += DeltaTime
			--[[if CurrentAcceleration.Unit.X > .01 and CurrentAcceleration.Unit.Z > .01 then CurrentAcceleration -= CurrentAcceleration.Unit * DeltaTime else CurrentAcceleration = Vector3.new(0,CurrentAcceleration.Y,0) end]] if CurrentAcceleration.Y > (-NotInitialMass * 1000) then CurrentAcceleration -= Vector3.new(0,9.8,0) * DeltaTime end
			local LastFrom = LastCFrame
			local Done = false
			local Bounce = function()
				if Done then return else Done = true end
				CurrentAcceleration = BounceAngle(CurrentAcceleration, Raycast)/(Part.Material.Name ~= 'Rubber' and 4 or 2)
				if Part.Material.Name == 'Pebble' or Part.Material.Name == 'Rock' then
					CurrentAcceleration = Vector3.new(CurrentAcceleration.X, CurrentAcceleration.Y/10, CurrentAcceleration.Z)
				end
				LastCFrame = LastCFrame - DeltaAcc * 2
			end
			LastCFrame = CFrame.new(LastCFrame.Position + DeltaAcc, LastCFrame.Position + (DeltaAcc * 2))
			task.synchronize()
			Part.CFrame = LastCFrame
			task.desynchronize()
			if Damage > 0 then	Damage -= (TimeElapsed/Durability) if Damage < 0 then Damage = 0 end end
			local ThisRaycast = workspace:Blockcast(LastCFrame, Part.Size, DeltaAcc, RaycastParameter) or workspace:Blockcast(LastFrom, Part.Size, LastCFrame.Position - LastFrom.Position, RaycastParameter)
			if not ThisRaycast then
				local ReverseRay = workspace:Blockcast(LastCFrame, Part.Size, -DeltaAcc, RaycastParameter) or workspace:Blockcast(LastCFrame, Part.Size, LastFrom.Position - LastCFrame.Position, RaycastParameter)
				if ReverseRay then
					ThisRaycast = {
						Instance = ReverseRay.Instance,
						Position = ReverseRay.Position,
						Normal = -ReverseRay.Normal,
						Material = ReverseRay.Material,
					}
				end
			end
			--[[local ThisRaycast = workspace:Raycast(LastCFrame.Position, DeltaAcc, RaycastParameter) or workspace:Raycast(LastFrom.Position , LastCFrame.Position - LastFrom.Position, RaycastParameter)
			if not ThisRaycast then
				local ReverseRay = workspace:Raycast(LastCFrame.Position, -DeltaAcc, RaycastParameter) or workspace:Raycast(LastCFrame.Position , LastFrom.Position - LastCFrame.Position, RaycastParameter)
				if ReverseRay then
					ReverseRay.Normal = -ReverseRay.Normal
					ThisRaycast = ReverseRay
				end
			end]]
			Raycast = ThisRaycast
			--[[if Raycast and Raycast.Instance then
				-- reduce Durability based on hit
				if not Raycast.Instance:IsA('Terrain') and Material_Data[Raycast.Material] and (Material_Data[Raycast.Material].Hardness < Material_Data[Part.Material].Hardness) then
					if Material_Data[Raycast.Material].Durability < (Durability * CurrentAcceleration.Magnitude) then
						CurrentAcceleration = BounceAngle(CurrentAcceleration, Raycast)
						LastCFrame = LastCFrame - DeltaAcc * 2
					else
						--break obstacle, comes at cost of lowering Durability
						Durability -= Material_Data[Raycast.Material].Durability
						BreakApart(Raycast.Instance)
					end
					if Raycast.Instance:IsA('BasePart') then Raycast.Instance.Anchored = false Raycast.Instance.AssemblyLinearVelocity = Raycast.Instance.AssemblyLinearVelocity + CurrentAcceleration * Damage end
					if workspace:GetAttribute('PVP_ON') and Raycast.Instance:FindFirstAncestorWhichIsA('Model') and Raycast.Instance:FindFirstAncestorWhichIsA('Model'):FindFirstChildOfClass('Humanoid') then
						Raycast.Instance:FindFirstAncestorWhichIsA('Model'):FindFirstChildOfClass('Humanoid').Health = Raycast.Instance:FindFirstAncestorWhichIsA('Model'):FindFirstChildOfClass('Humanoid').Health - (Raycast.Instance.Name:upper():match('HEAD') and Damage * 2 or Damage)
					end
				else
					local Calculated = Part.CFrame.Rotation * CFrame.new(Raycast.Position)
					LastCFrame = Calculated
					Part.CFrame = Calculated
					BreakApart(Part)
					CurrentAcceleration = -CurrentAcceleration
					break -- projectile break, unbreakable terrain or material
				end
			end]]
			if Raycast and Raycast.Instance then
				if Durability <= 6 then
					Durability -= (Material_Data[Raycast.Material] and Material_Data[Raycast.Material].Hardness) or 1 
					if Raycast.Instance:IsA('BasePart') then
						if Material_Data[Raycast.Material] then
							if Material_Data[Raycast.Material].Durability < (Durability * CurrentAcceleration.Magnitude) then
								Bounce()
								LastCFrame = LastCFrame - DeltaAcc * 2
							else
								--break obstacle, comes at cost of lowering Durability
								Durability -= Material_Data[Raycast.Material].Durability
								BreakApart(Raycast.Instance, Raycast.Position, Raycast.Normal, Velocity)
							end
						else
							task.synchronize()
							if workspace:GetAttribute('Breakable') then	Raycast.Instance.Anchored = false end
							if (Raycast.Instance.Size.Magnitude < Part.Size.Magnitude) or (Raycast.Material == Enum.Material.Glass or Raycast.Material == Enum.Material.Ice) then
								BreakApart(Raycast.Instance, Raycast.Position, Raycast.Normal, Velocity)
							else
								break
							end
						end
					end
					if Durability <= 0 then
						break
					end
					if workspace:GetAttribute('PVP_ON') and Raycast.Instance:FindFirstAncestorWhichIsA('Model') and Raycast.Instance:FindFirstAncestorWhichIsA('Model'):FindFirstChildOfClass('Humanoid') then
						task.synchronize()
						Raycast.Instance:FindFirstAncestorWhichIsA('Model'):FindFirstChildOfClass('Humanoid').Health = Raycast.Instance:FindFirstAncestorWhichIsA('Model'):FindFirstChildOfClass('Humanoid').Health - (Raycast.Instance.Name:upper():match('HEAD') and Damage * 2 or Damage)
						RaycastParameter:AddToFilter(Raycast.Instance)
					end
				else
					BreakApart(Raycast.Instance,  Raycast.Position, Raycast.Normal, Velocity)
					Bounce()
					if workspace:GetAttribute('PVP_ON') and Raycast.Instance:FindFirstAncestorWhichIsA('Model') and Raycast.Instance:FindFirstAncestorWhichIsA('Model'):FindFirstChildOfClass('Humanoid') then
						task.synchronize()
						Raycast.Instance:FindFirstAncestorWhichIsA('Model'):FindFirstChildOfClass('Humanoid').Health = Raycast.Instance:FindFirstAncestorWhichIsA('Model'):FindFirstChildOfClass('Humanoid').Health - (Raycast.Instance.Name:upper():match('HEAD') and Damage * 4 or Damage * 2)
						RaycastParameter:AddToFilter(Raycast.Instance)
					end
				end
			end
		end
		if Part then
			if Part.Position.Y < workspace.FallenPartsDestroyHeight then
				Registered_Projectile[Part] = nil
				task.synchronize()
				Part:Destroy()
				Part = nil
				return
			end
			task.synchronize()
			PlaySound('HIT', Part)
			Part.Anchored = false
			if Durability <= Material_Data[Part.Material].Durability then
				BreakApart(Part, Part.Position, Vector3.new(), Velocity)
			end
			task.desynchronize()
			if Raycast then
				CurrentAcceleration = CurrentAcceleration.Unit * math.clamp(CurrentAcceleration.Magnitude/10,0,100)
				local ParticlesAmount = math.clamp(CurrentAcceleration.Magnitude,0,math.floor(Part.Size.Magnitude * 25))
				if ParticlesAmount >= 1 then
					local OriginMagnitude = math.floor(CurrentAcceleration.Magnitude)
					for i = 1, ParticlesAmount do
						task.synchronize()
						local part = Part:Clone()
						part.Transparency = 0
						part.Position = Part.Position
						part.Parent = Part.Parent
						part.Size = part.Size/ParticlesAmount
						part.AssemblyLinearVelocity = CurrentAcceleration --+ Vector3.new(math.random(-Magnitude,Magnitude),math.random(-Magnitude,Magnitude),math.random(-Magnitude,Magnitude))
						Debris:AddItem(part, 20)
						if game:FindFirstChildOfClass('TweenService') then game:FindFirstChildOfClass('TweenService'):Create(part, TweenInfo.new(1), {Transparency = 1, Size = Vector3.new()}):Play() end
					end
				end
				task.synchronize()
				Debris:AddItem(Part, 20)
				if Part:FindFirstChildOfClass('Trail') then
					Part:FindFirstChildOfClass('Trail').Enabled = false
				end
				if game:FindFirstChildOfClass('TweenService') then game:FindFirstChildOfClass('TweenService'):Create(Part, TweenInfo.new(1), {Transparency = 1}):Play() end
				if Part and game:FindFirstChildOfClass('Debris') then game:FindFirstChildOfClass('Debris'):AddItem(Part, 1) end
			else
				--not even hit(how even), allow pickup
				ExportData(Part)
				local Done = false
				task.synchronize()
				local Trigger = Instance.new('ProximityPrompt', Part)
				local Event: RBXScriptConnection
				local DestroyingThread: thread
				Trigger.HoldDuration = 0
				Trigger.RequiresLineOfSight = false
				Event = Trigger.Triggered:Connect(function(Plr: Player)
					if not Part or Done or not Trigger then return end
					if not Plr or typeof(Plr) ~= 'Instance' or not Plr:IsA('Player') or not Plr.Character then return end
					local PlrDistance  = Plr.Character.PrimaryPart and (Part.Position - Plr.Character.PrimaryPart.Position).Magnitude or 10
					if PlrDistance < 10 then
						if not table.find(RaycastParameter.FilterDescendantsInstances, Plr.Character) then RaycastParameter:AddToFilter(Plr.Character) end
						if not workspace:Raycast(Plr.Character.PrimaryPart.Position, (Part.Position - Plr.Character.PrimaryPart.Position), RaycastParameter) and not workspace:Raycast(Part.Position, (Plr.Character.PrimaryPart.Position - Part.Position), RaycastParameter) then Done = true StoreData(Player, Part:GetAttributes()) if DestroyingThread then task.cancel(DestroyingThread) DestroyingThread = nil end if Event then Event:Disconnect() Event = nil end if Part then Part:Destroy() end end
					end
				end)
				DestroyingThread = task.spawn(function() task.wait(59)
					if Event then Event:Disconnect() Event = nil end
					if Trigger then	Trigger:Destroy() end
					DestroyingThread = nil
				end)
				if Part:FindFirstChildOfClass('Trail') then
					Part:FindFirstChildOfClass('Trail').Enabled = false
				end
				if game:FindFirstChildOfClass('TweenService') then game:FindFirstChildOfClass('TweenService'):Create(Part, TweenInfo.new(60), {Transparency = 1}):Play() end
				if Part and game:FindFirstChildOfClass('Debris') then game:FindFirstChildOfClass('Debris'):AddItem(Part, 60) end
			end
			Registered_Projectile[Part] = nil
		end
	end))
	table.remove(Storage_PLR['_'..ID..'_'], 1)
end

function Activation(Tool: Tool)
	task.desynchronize()
	if not Tool or typeof(Tool) ~= 'Instance' or not Tool.Parent or not Tool:FindFirstAncestorWhichIsA('Model') or not Tool:IsA('Tool') then return end
	local Character: Model = Tool:FindFirstAncestorWhichIsA('Model')
	if not Character:FindFirstChildOfClass('Humanoid') then return end
	local Humanoid: Humanoid = Character:FindFirstChildOfClass('Humanoid')
	local SelectedBallData = Tool:GetAttribute('Selected_Slot') or 0
	local Player = PlayerFromChar[Character] or Players:GetPlayerFromCharacter(Character)
	local IDstring = '_'..tostring(Player.UserId)..'_'
	local Handle = Tool:FindFirstChild('Handle')
	local function SetFirst()
		local SetSlotTo = 0
		if not Storage_PLR[IDstring] then Storage_PLR[IDstring] = {} else if Storage_PLR[IDstring][1] then SetSlotTo = 1 end end
		SelectedBallData = SetSlotTo
		task.synchronize()
		Tool:SetAttribute('Selected_Slot', SetSlotTo)
		local ThisData = Storage_PLR[IDstring][SelectedBallData]
		if ThisData and Handle then Tool.ToolTip = 'Selected: '..ThisData.Material.Name Handle.Size = ThisData.Size Handle.Color = (workspace:FindFirstChildOfClass('Terrain'):GetMaterialColor(ThisData.Material or Enum.Material.Ice) or Color3.new(0.478431, 0.478431, 0.478431)) Handle.Material = ThisData.Material or Enum.Material.ForceField Handle.Transparency = 0 else Tool.ToolTip = 'Press LMB to pickup or select' Handle.Transparency = 1 end
	end
	task.desynchronize()
	showtext('a')
	if SelectedBallData <= 0 then
		showtext('pickup')
		CharacterPickup(Character)
		if  Storage_PLR[IDstring] and #Storage_PLR[IDstring] > 0 then
			showtext('sf')
			SetFirst()
		end
	else
		if Player and Storage_PLR[IDstring] and Storage_PLR[IDstring][SelectedBallData] then
			showtext('throw')
			CharacterThrow(Character, Player, math.random(900,1000)/175)
		end
		showtext('sf')
		SetFirst()
	end
end

function RegisterTool(Tool: Tool)
	if not Tool or typeof(Tool) ~= 'Instance' or not Tool.Parent or not Tool:IsA('Tool') or not Tool:FindFirstChild('Handle') then showtext('np') return end
	task.synchronize()
	Tool.Destroying:Once(function()
		if ConnectedTools[Tool] then for i,v in ConnectedTools[Tool] do v:Disconnect() end end
	end)
	local ConnectionA = Tool.Activated:Connect(function()
		Activation(Tool)
	end)
	ConnectedTools[Tool] = {ConnectionA}
end

local MainConnection: RBXScriptConnection
local Sub_Connections: {RBXScriptConnection} = {}

task.synchronize()
MainConnection = Players.PlayerAdded:Connect(function(PLR)
	task.synchronize()
	table.insert(Sub_Connections, PLR.CharacterAdded:Connect(function(CHAR)
		PlayerFromChar[CHAR] = PLR
		task.synchronize()
		local Tool = Instance.new('Tool', CHAR)
		Tool.Name = 'Snowball'
		Tool.ToolTip = "WIP, LMB to make a ball(Requires Terrain)"
		local Handle = Instance.new('Part')
		Handle.Name = 'Handle'
		Handle.Shape = Enum.PartType.Ball
		Handle.Transparency = 1
		Handle.Parent = Tool
		RegisterTool(Tool)
	end))
	if not Storage_PLR['_'..PLR.UserId..'_'] then Storage_PLR['_'..PLR.UserId..'_'] = {} end
end)

task.wait(1)
if not (workspace:FindFirstChild('Chrismah') and workspace:FindFirstChild('Chrismah').Value == true) then
	task.synchronize()
	if MainConnection then MainConnection:Disconnect() end
	for i,v in ipairs(Sub_Connections) do v:Disconnect() end
	script:Destroy()
end

coroutine.resume(coroutine.create(function()
	while task.wait(120) do --//stray cases, events not picked up
		task.desynchronize()
		for i,v in pairs(PlayerFromChar) do
			if v and v.Parent and i and i.Parent and v.Character == i then continue end
			if not v.Parent then Storage_PLR['_'..v.UserId..'_'] = nil end
			PlayerFromChar[i] = nil
		end
	end
end))
