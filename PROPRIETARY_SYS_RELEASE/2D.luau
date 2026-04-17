local parent = script.Parent.Parent
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local triangle = require(script.Parent.triangle)

-- Independent character physics
local chrpos = CFrame.new(59.558, 2.5, -1.039)
local velocity = Vector3.new()
local grounded = false
local CastSize = Vector3.new(3, 2.5, 3)
local rayp = RaycastParams.new()
rayp.RespectCanCollide = true
rayp.IgnoreWater = true

local R6_PARTS = {
	{name = "Head", center = Vector3.new(0, 1.5, 0), size = Vector3.new(1, 1, 1), pointCount = 12, Color = Color3.fromRGB(245, 205, 48)},
	{name = "Torso", center = Vector3.new(0, 0, 0), size = Vector3.new(2, 2, 1), pointCount = 12, Color = Color3.fromRGB(math.random(0,255), math.random(0,255), math.random(0,255))},
	{name = "LeftArm", center = Vector3.new(-1.5, 0, 0), size = Vector3.new(1, 2, 1), pointCount = 12, jointPivot = Vector3.new(-1.5, 1, 0), Color = Color3.fromRGB(245, 205, 48)},
	{name = "RightArm", center = Vector3.new(1.5, 0, 0), size = Vector3.new(1, 2, 1), pointCount = 12, jointPivot = Vector3.new(1.5, 1, 0), Color = Color3.fromRGB(245, 205, 48)},
	{name = "LeftLeg", center = Vector3.new(-0.5, -2, 0), size = Vector3.new(1, 2, 1), pointCount = 12, Color = Color3.fromRGB(164, 189, 71), jointPivot = Vector3.new(-0.5, -1, 0)},
	{name = "RightLeg", center = Vector3.new(0.5, -2, 0), size = Vector3.new(1, 2, 1), pointCount = 12, Color = Color3.fromRGB(164, 189, 71), jointPivot = Vector3.new(0.5, -1, 0)},
}
-- Define faces for each body part (each face is defined by 4 corner indices, split into 2 triangles)
-- Corner indices: 1-8 for each part (8 corners of a box)
-- Layout: corners are in order: (-X,-Y,-Z), (-X,-Y,+Z), (-X,+Y,-Z), (-X,+Y,+Z), (+X,-Y,-Z), (+X,-Y,+Z), (+X,+Y,-Z), (+X,+Y,+Z)
-- Face indices: 1=Front, 2=Back, 3=Right, 4=Left, 5=Top, 6=Bottom
local FACES = {
	-- Front face (Z+): corners 2, 6, 8, 4
	{corners = {2, 6, 8, 4}, normal = Vector3.new(0, 0, 1)},
	-- Back face (Z-): corners 5, 1, 3, 7
	{corners = {5, 1, 3, 7}, normal = Vector3.new(0, 0, -1)},
	-- Right face (X+): corners 6, 5, 7, 8
	{corners = {6, 5, 7, 8}, normal = Vector3.new(1, 0, 0)},
	-- Left face (X-): corners 1, 2, 4, 3
	{corners = {1, 2, 4, 3}, normal = Vector3.new(-1, 0, 0)},
	-- Top face (Y+): corners 4, 8, 7, 3
	{corners = {4, 8, 7, 3}, normal = Vector3.new(0, 1, 0)},
	-- Bottom face (Y-): corners 1, 5, 6, 2
	{corners = {1, 5, 6, 2}, normal = Vector3.new(0, -1, 0)},
}

-- Faces to skip for each body part (internal faces where limbs connect)
-- Part indices: 1=Head, 2=Torso, 3=LeftArm, 4=RightArm, 5=LeftLeg, 6=RightLeg
-- Face indices: 1=Front, 2=Back, 3=Right, 4=Left, 5=Top, 6=Bottom
local SKIP_FACES = {
	[1] = {}, -- Head: all faces visible
	[2] = {}, -- Torso: all faces visible
	[3] = {}, -- LeftArm: all faces visible (top shows when arms raised)
	[4] = {}, -- RightArm: all faces visible (top shows when arms raised)
	[5] = {}, -- LeftLeg: skip top (hip connection)
	[6] = {}, -- RightLeg: skip top (hip connection)
}

-- Static R6 positions (relative to center)
local staticR6Positions = {}

-- Shared data structures (accessible from parallel threads)
local points = {}
local screenPositions = {}
local depths = {}
local centerCFrame = CFrame.new()
local pointPartIndex = {} -- Tracks which body part each point belongs to
local pointOnScreen = {} -- Tracks which points are currently on-screen

-- Triangle rendering - separate pools for LEFT and RIGHT
local leftTrianglePool = {}
local rightTrianglePool = {}
local trianglesToRender = {}

-- Animation state
local previousPosition = Vector3.new(0, 0, 0)
local previousTime = 0
local walkSpeed = 0
local animationTime = 0

-- Helper functions for independent physics


local function getIntersection(cf)
	if typeof(cf) ~= 'CFrame' then return Vector3.new() end
	local SR = workspace:Blockcast(cf - (cf.RightVector * CastSize.X/2), CastSize, cf.RightVector * CastSize.X, rayp)
	local SL = workspace:Blockcast(cf - (cf.RightVector * -CastSize.X/2), CastSize, cf.RightVector * -CastSize.X, rayp)
	local F = workspace:Blockcast(cf - (cf.LookVector * CastSize.Z/2), CastSize, cf.LookVector * CastSize.Z, rayp)
	local B = workspace:Blockcast(cf - (cf.LookVector * -CastSize.Z/2), CastSize, cf.LookVector * -CastSize.Z, rayp)
	local T = workspace:Blockcast(cf - (cf.UpVector * CastSize.Y/2), CastSize, cf.UpVector * CastSize.Y, rayp)
	local BT = workspace:Blockcast(cf - (cf.UpVector * -CastSize.Y/2), CastSize, cf.UpVector * -CastSize.Y, rayp)
	local offset = Vector3.new()
	if SR then offset -= cf.RightVector * (CastSize.X - SR.Distance) end
	if SL then offset += cf.RightVector * (CastSize.X - SL.Distance) end
	if F then offset -= cf.LookVector * (CastSize.Z - F.Distance) end
	if B then offset += cf.LookVector * (CastSize.Z - B.Distance) end
	if T then offset -= cf.UpVector * (CastSize.Y - T.Distance) end
	if BT then offset += cf.UpVector * (CastSize.Y - BT.Distance) end
	return offset
end


-- Create triangle images for rendering - separate LEFT and RIGHT
local function createLeftTriangle()
	task.synchronize()

	local img = Instance.new("ImageLabel")
	img.Name = "TriangleLeft"
	img.BackgroundTransparency = 1
	img.BorderSizePixel = 0
	img.Visible = false
	img.Image = triangle.LEFT
	img.Parent = parent

	return img
end

local function createRightTriangle()
	task.synchronize()

	local img = Instance.new("ImageLabel")
	img.Name = "TriangleRight"
	img.BackgroundTransparency = 1
	img.BorderSizePixel = 0
	img.Visible = false
	img.Image = triangle.RIGHT
	img.Parent = parent

	return img
end

-- Helper function to add points at corners of a box
local function addBoxPoints(center, size, positions)
	task.desynchronize()
	local halfX, halfY, halfZ = size.X/2, size.Y/2, size.Z/2

	-- 8 corners of the box
	local corners = {
		Vector3.new(-halfX, -halfY, -halfZ),
		Vector3.new(-halfX, -halfY, halfZ),
		Vector3.new(-halfX, halfY, -halfZ),
		Vector3.new(-halfX, halfY, halfZ),
		Vector3.new(halfX, -halfY, -halfZ),
		Vector3.new(halfX, -halfY, halfZ),
		Vector3.new(halfX, halfY, -halfZ),
		Vector3.new(halfX, halfY, halfZ),
	}

	for _, corner in ipairs(corners) do
		table.insert(positions, center + corner)
	end
end

-- Initialize R6 character points at corners of each body part
for partIndex, part in ipairs(R6_PARTS) do
	local startIndex = #staticR6Positions + 1
	addBoxPoints(part.center, part.size, staticR6Positions)
	-- Track which part each point belongs to
	for i = startIndex, #staticR6Positions do
		pointPartIndex[i] = partIndex
	end
end

-- Create points and frames
for i = 1, #staticR6Positions do
	table.insert(points, staticR6Positions[i])
end

-- Calculate max triangles needed (6 faces × 2 triangles × 6 parts = 72, but legs skip top face)
-- Head: 12, Torso: 12, LeftArm: 12, RightArm: 12, LeftLeg: 12, RightLeg: 12 = 68 triangles
local MAX_TRIANGLES = 72
for i = 1, MAX_TRIANGLES do
	table.insert(leftTrianglePool, createLeftTriangle())
	table.insert(rightTrianglePool, createRightTriangle())
end

task.synchronize()
-- Parallel task: Update 3D point positions based on R6 character
local epox = require(game:GetService('ReplicatedStorage'):WaitForChild('Epoxyish'))
local epoxies = {}

local cachedchr = nil
local CastSize = Vector3.new(3,2.5,3)
local chrpos = (workspace:FindFirstChild('_SpawnLocation') and workspace:FindFirstChild('_SpawnLocation'):IsA('SpawnLocation') and workspace:FindFirstChild('_SpawnLocation').CFrame) or CFrame.new()
chrpos += Vector3.new(0,2,0)
BASE_POSITION = chrpos.Position + Vector3.new(0,20,0)
--x axis, y axis, z axis, 1 and -1 casts
local rayp = RaycastParams.new()
rayp.RespectCanCollide = true
rayp.IgnoreWater = true
local offset = Vector3.new()
local vels = Vector3.new()
function GIn(CF: CFrame) -- Get intersect
	if typeof(CF) ~= 'CFrame' then return Vector3.new() end
	-- moved back incase the middle was covered(inside parts) and starting from there not found
	local SR = workspace:Blockcast(CF - (CF.RightVector * CastSize.X/2), CastSize, CF.RightVector * CastSize.X, rayp)
	local SL = workspace:Blockcast(CF - (CF.RightVector * -CastSize.X/2), CastSize, CF.RightVector * -CastSize.X, rayp)
	local F = workspace:Blockcast(CF - (CF.LookVector * CastSize.Z/2), CastSize, CF.LookVector * CastSize.Z, rayp)
	local B = workspace:Blockcast(CF - (CF.LookVector * -CastSize.Z/2), CastSize, CF.LookVector * -CastSize.Z, rayp)
	local T = workspace:Blockcast(CF - (CF.UpVector * CastSize.Y/2), CastSize, CF.UpVector * CastSize.Y, rayp)
	local BT = workspace:Blockcast(CF - (CF.UpVector * -CastSize.Y/2), CastSize, CF.UpVector * -CastSize.Y, rayp)
	local ToUnIntersected = Vector3.new()
	if SR then
		ToUnIntersected -= CF.RightVector * (CastSize.X - SR.Distance) end
	if SL then
		ToUnIntersected += CF.RightVector * (CastSize.X - SL.Distance) end
	if F then
		ToUnIntersected -= CF.LookVector * (CastSize.Z - F.Distance) end
	if B then
		ToUnIntersected += CF.LookVector * (CastSize.Z - B.Distance) end
	if T then
		ToUnIntersected -= CF.UpVector * (CastSize.Y - T.Distance) end
	if BT then
		ToUnIntersected += CF.UpVector * (CastSize.Y - BT.Distance) end
	return ToUnIntersected or Vector3.new()
end
chrpos = chrpos + GIn(chrpos)
local BASE_POSITION = Vector3.new(0, 20, 30)
local MAX_DISTANCE = 40
local LOOK_OFFSET = Vector3.new(0, 5, 0)

local currentCameraPosition = BASE_POSITION
function updateCamera(deltaTime, pos, cam)
	if typeof(cam) ~= 'Instance' or cam.ClassName ~= 'Camera' or typeof(pos) ~= 'Vector3' or typeof(deltaTime) ~= 'number' then return end

	local playerPosition = pos
	local distanceToBase = (playerPosition - BASE_POSITION).Magnitude

	-- Calculate target position
	local targetPosition
	if distanceToBase > MAX_DISTANCE then
		local directionFromPlayerToBase = (BASE_POSITION - playerPosition).Unit
		targetPosition = playerPosition + (directionFromPlayerToBase * MAX_DISTANCE)
	else
		targetPosition = BASE_POSITION
	end

	-- Frame-independent lerp
	local lerpFactor = math.clamp(1 - (10 ^ -1) ^ deltaTime, 0, 1)
	currentCameraPosition = currentCameraPosition:Lerp(targetPosition, lerpFactor)

	-- Update camera
	local lookAtPosition = playerPosition + LOOK_OFFSET
	cam.CFrame =  cam.CFrame :Lerp( CFrame.lookAt(currentCameraPosition, lookAtPosition), lerpFactor)
end
function flatter(vectorthing)
	if typeof(vectorthing) ~= 'Vector3' then return Vector3.new() end
	return Vector3.new(vectorthing.X, 0, vectorthing.Z)
end
function alignToNormal(cf, surfaceNormal)
	if typeof(cf) ~= 'CFrame' then return CFrame.new() end
	if typeof(surfaceNormal) ~= 'Vector3' or surfaceNormal.Magnitude < 0.001 or surfaceNormal.Unit.Magnitude < 1 then return cf end
	local lookVector = cf.LookVector
	local rightVector = lookVector:Cross(surfaceNormal)
	if rightVector.Magnitude < 0.001 then
		rightVector = cf.RightVector:Cross(surfaceNormal)
	end
	rightVector = rightVector.Unit
	local backVector = rightVector:Cross(surfaceNormal).Unit
	return CFrame.fromMatrix(cf.Position, rightVector, surfaceNormal, backVector)
end
function updatePointsParallel(dt)
	task.desynchronize()

	local player = Players.LocalPlayer
	local character = player and player.Character or workspace:FindFirstChild(tostring(player.UserId))
	if typeof(player.Character) ~= 'Instance' and (typeof(character) ~= 'Instance' or character:GetAttribute('__REGPLRID') ~= player.UserId) then character = nil end
	local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
	local altg = false
	if typeof(humanoidRootPart) ~= 'Instance' or not humanoidRootPart.ClassName:lower():match('part') then
		humanoidRootPart = {CFrame = (typeof(cachedchr) == 'Instance' and cachedchr.ClassName == 'Model' and typeof(cachedchr.Parent) == 'Instance' and cachedchr:GetPivot()) or (typeof(workspace.CurrentCamera) == 'Instance' and workspace.CurrentCamera.ClassName == 'Camera' and workspace.CurrentCamera.CFrame)  or centerCFrame or CFrame.new()}
		if not (typeof(cachedchr) == 'Instance' and cachedchr.ClassName == 'Model' and typeof(cachedchr.Parent) == 'Instance' ) then
			for i,v in workspace:GetChildren() do
				if v.ClassName == 'Model' and v:GetAttribute('__REGPLRID') == player.UserId then
					cachedchr = v
					humanoidRootPart = {CFrame = (typeof(cachedchr) == 'Instance' and cachedchr.ClassName == 'Model' and typeof(cachedchr.Parent) == 'Instance' and cachedchr:GetPivot()) or (typeof(workspace.CurrentCamera) == 'Instance' and workspace.CurrentCamera.ClassName == 'Camera' and workspace.CurrentCamera.CFrame)  or centerCFrame or CFrame.new()}
					break
				end
			end
			if typeof(cachedchr) ~= 'Instance' or typeof(cachedchr.Parent) ~= 'Instance' then
				humanoidRootPart = {CFrame = (typeof(workspace.CurrentCamera) == 'Instance' and workspace.CurrentCamera.ClassName == 'Camera' and workspace.CurrentCamera.CFrame)  or centerCFrame or CFrame.new()}
				local a = (player:GetAttribute('__MOVEDIR'))
				if typeof(a) ~= 'Vector3' then
					a = Vector3.new()
				elseif a.Magnitude > (10 ^ -3) then
					a = flatter(a.Unit * math.min(1, a.Magnitude))
				end
				local move = ((a or Vector3.new()) * 16 + vels) * dt 
				local PanOut = workspace:Blockcast(chrpos, CastSize, move, rayp)
				local grounded = vels.Y <= 0 and  workspace:Blockcast(chrpos, CastSize, Vector3.new(0, (0-CastSize.Y/2) -0.2 , 0), rayp) or workspace:Blockcast(chrpos, CastSize, chrpos:VectorToWorldSpace(Vector3.new(0, (0-CastSize.Y/2) -0.2 , 0)), rayp)
				local ceil = vels.Y > 0 and  workspace:Blockcast(chrpos, CastSize, Vector3.new(0, (CastSize.Y/2) + 0.2 , 0), rayp) or workspace:Blockcast(chrpos, CastSize, chrpos:VectorToWorldSpace(Vector3.new(0, (CastSize.Y/2) + 0.2 , 0)), rayp)
				local grounded2 = vels.Y <= 0 and  workspace:Blockcast(chrpos, CastSize, Vector3.new(0, (0-CastSize.Y/2) -1 , 0), rayp) 
				local dotted = (grounded2 and grounded2.Normal:Dot(Vector3.yAxis)) or 0
				local aligned = false
				if not grounded2 then grounded2 = grounded end
				if dotted < 0.85 and dotted > 0 then -- no veritcal wall and don't react to upside down platform
					chrpos = alignToNormal(chrpos, grounded2.Normal)
					aligned = true
				else
					chrpos = alignToNormal(chrpos, Vector3.yAxis)
					if dotted <= 0 then grounded = nil end
				end
				if grounded and dotted > 0 then
					vels = Vector3.new(0, math.max(vels.Y, (aligned and -98) or 0), 0) 
					altg = true
				end
				if ceil then
					local dotty = ceil.Normal:Dot(-Vector3.yAxis)
					local taligned = false
					if dotty < 0.85 and dotty > 0 then -- no veritcal wall and don't react to upside down platform
						taligned = true
						chrpos = alignToNormal(chrpos, -ceil.Normal)
					else
						if dotty <= 0 then ceil = nil end
					end
					vels = Vector3.new(0, math.min(vels.Y, (taligned and 98 or 0)), 0) 
				end
				if PanOut then
					move = move - (PanOut.Normal *  math.min(0, PanOut.Normal:Dot(move)))
					vels = vels - PanOut.Normal * math.min(0, PanOut.Normal:Dot(move))
				end
				local nowoff = offset
				if offset.Magnitude < (10 ^ -3) and typeof(workspace.CurrentCamera) == 'Instance' and workspace.CurrentCamera.ClassName == 'Camera' then
					nowoff = workspace.CurrentCamera.CFrame.LookVector * 5
				end
				offset += move
				if a and a.Magnitude > 0.1 then
					chrpos = CFrame.new(chrpos.Position, chrpos.Position + a)			
				end
				if offset.Magnitude < (10 ^ -3) then
					humanoidRootPart.CFrame = (offset.Magnitude < (10 ^ -3) and humanoidRootPart.CFrame or (workspace:FindFirstChild('_SpawnLocation') and workspace:FindFirstChild('_SpawnLocation').ClassName == 'SpawnLocation' and workspace:FindFirstChild('_SpawnLocation').CFrame) or CFrame.new()) + nowoff
				else
					humanoidRootPart.CFrame = chrpos or CFrame.new()
					if typeof(workspace.CurrentCamera) == 'Instance' and workspace.CurrentCamera.ClassName == 'Camera' and not (script:FindFirstAncestorWhichIsA('Player') and script:FindFirstAncestorWhichIsA('Player'):FindFirstChildOfClass('PlayerScripts') and script:FindFirstAncestorWhichIsA('Player'):FindFirstChildOfClass('PlayerScripts'):FindFirstChild('CamAltEarlyBeta_LimitlessRotaPatch')) then
						task.synchronize()
						workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
						updateCamera(dt, chrpos.Position, workspace.CurrentCamera)
						task.desynchronize()
					elseif (script:FindFirstAncestorWhichIsA('ScreenGui') and script:FindFirstAncestorWhichIsA('Player') and script:FindFirstAncestorWhichIsA('Player'):FindFirstChildOfClass('PlayerScripts') and script:FindFirstAncestorWhichIsA('Player'):FindFirstChildOfClass('PlayerScripts'):FindFirstChild('CamAltEarlyBeta_LimitlessRotaPatch')) then
						task.synchronize()
						script:FindFirstAncestorWhichIsA('ScreenGui'):SetAttribute('__POS', (chrpos or {Position = Vector3.new()}).Position or Vector3.new())
						task.desynchronize()
					end
				end
				chrpos = chrpos + (move + GIn(chrpos + (move)))
				chrpos = chrpos + GIn(chrpos)
				local b = (player:GetAttribute('__JUMP'))
				if chrpos.Y < -1 then
					vels += Vector3.new(0,196,0) * dt
				elseif b and grounded then
					vels += Vector3.new(0,1776,0) * dt
				elseif not grounded then
					vels -= Vector3.new(0,196,0) * dt
				end
				if vels.Y ~= vels.Y then
					vels = Vector3.new(0,0,0)
				end
				vels = Vector3.new(0, math.clamp(vels.Y, -320, 320), 0)
			end
		end
	end

	if humanoidRootPart then
		local currentPosition = humanoidRootPart.CFrame.Position or humanoidRootPart.Position or Vector3.new()

		-- delta speed like the thing from Custom Character
		if dt > 0 then
			local positionDelta = Vector3.new(currentPosition.X - previousPosition.X, 0, currentPosition.Z - previousPosition.Z)
			walkSpeed = positionDelta.Magnitude / dt
		end

		previousPosition = currentPosition

		animationTime = animationTime + dt * walkSpeed * 0.5
		animationTime = animationTime % (2 * math.pi)
		--update and clamp
		centerCFrame = humanoidRootPart.CFrame
		-- springy realistic rotation momentum
	end

	-- sinWave-O!
	local walkCycle = math.sin(animationTime)

	local humanoid = character and character:FindFirstChildOfClass("Humanoid") or {MoveDirection = Vector3.new(), Health = 100, MaxHealth = 100}
	local validchar = typeof(character) == 'Instance' and character:IsDescendantOf(workspace)
	local ForceGrounded = false 
	local sit = false
	if typeof(humanoid) == 'Instance' then
		humanoidRootPart = humanoid.RootPart
		if typeof(humanoidRootPart) == 'Instance' and humanoidRootPart.Anchored  then
			ForceGrounded = true
		end
		sit = humanoid.Sit
	end
	local isInAir = (typeof(humanoid) == 'Instance' and (typeof(humanoid.FloorMaterial) ~= "EnumItem" or humanoid.FloorMaterial == Enum.Material.Air)) or (validchar and typeof(character.PrimaryPart) == 'Instance' and character.PrimaryPart:IsGrounded() and (character:GetAttribute('Grounded') == false)) or (not validchar and not altg) or false -- invalid ground or Aerial
	if ForceGrounded or sit then isInAir = false end
	-- are they in-place (slowed + reverb), accounted for floating point by making it threshold instead
	local isStandingStill = walkSpeed < (10 ^ -2)
	local animatedPositions = {}
	--claude said ts fire
	for i, staticPos in ipairs(staticR6Positions) do
		local partIndex =	pointPartIndex[i] <= 6 and pointPartIndex[i] or ((pointPartIndex[i] % 6) + 1) -- reset to 0 if more
		local animatedPos = staticPos

		-- Apply animation based on body part with joint rotation
		if partIndex == 3 then -- LeftArm - rotate around shoulder (forward/back)
			local jointPivot = R6_PARTS[3].jointPivot
			local relativeToPivot = staticPos - jointPivot
			local rotationAngle = walkCycle

			-- In air: rotate 180 degrees so arms face up
			if isInAir then
				rotationAngle = (isStandingStill and 0 or walkCycle) + math.pi
			elseif sit then
				rotationAngle = math.pi/2
				jointPivot -= Vector3.new(0,0.5,-0.5)
				-- Standing still: snap to normal
			elseif isStandingStill then
				rotationAngle = 0
			end

			local rotated = Vector3.new(
				relativeToPivot.X,
				relativeToPivot.Y * math.cos(rotationAngle) - relativeToPivot.Z * math.sin(rotationAngle),
				relativeToPivot.Y * math.sin(rotationAngle) + relativeToPivot.Z * math.cos(rotationAngle)
			)
			animatedPos = jointPivot + rotated
		elseif partIndex == 4 then -- RightArm - rotate around shoulder (opposite)
			local jointPivot = R6_PARTS[4].jointPivot
			local relativeToPivot = staticPos - jointPivot
			local rotationAngle = -walkCycle

			-- In air: rotate 180 degrees so arms face up
			if isInAir then
				rotationAngle = math.pi - (isStandingStill and 0 or walkCycle)
			elseif sit then
				rotationAngle = math.pi/2
				jointPivot -= Vector3.new(0,0.5,-0.5)
				-- Standing still: snap to normal
			elseif isStandingStill then
				rotationAngle = 0
			end

			local rotated = Vector3.new(
				relativeToPivot.X,
				relativeToPivot.Y * math.cos(rotationAngle) - relativeToPivot.Z * math.sin(rotationAngle),
				relativeToPivot.Y * math.sin(rotationAngle) + relativeToPivot.Z * math.cos(rotationAngle)
			)
			animatedPos = jointPivot + rotated
		elseif partIndex == 5 then -- LeftLeg - rotate around hip (opposite to left arm)
			local jointPivot = R6_PARTS[5].jointPivot
			local relativeToPivot = staticPos - jointPivot
			local rotationAngle = -walkCycle

			-- Standing still or in air: snap to normal
			if sit then
				rotationAngle = math.pi/2
			elseif isStandingStill then
				rotationAngle = 0
			end

			local rotated = Vector3.new(
				relativeToPivot.X,
				relativeToPivot.Y * math.cos(rotationAngle) - relativeToPivot.Z * math.sin(rotationAngle),
				relativeToPivot.Y * math.sin(rotationAngle) + relativeToPivot.Z * math.cos(rotationAngle)
			)
			animatedPos = jointPivot + rotated
		elseif partIndex == 6 then -- RightLeg - rotate around hip (opposite to right arm)
			local jointPivot = R6_PARTS[6].jointPivot
			local relativeToPivot = staticPos - jointPivot
			local rotationAngle = walkCycle

			-- Standing still or in air: snap to normal
			if sit then
				rotationAngle = math.pi/2
			elseif isStandingStill then
				rotationAngle = 0
			end

			local rotated = Vector3.new(
				relativeToPivot.X,
				relativeToPivot.Y * math.cos(rotationAngle) - relativeToPivot.Z * math.sin(rotationAngle),
				relativeToPivot.Y * math.sin(rotationAngle) + relativeToPivot.Z * math.cos(rotationAngle)
			)
			animatedPos = jointPivot + rotated
		end

		animatedPositions[i] = animatedPos
	end

	for i = 1, #animatedPositions do
		local relativePos = animatedPositions[i]
		-- get position relative to the center's rotation
		local worldOffset = centerCFrame:VectorToWorldSpace(relativePos)
		local targetPosition = centerCFrame.Position + worldOffset
		-- Gelatinious
		if typeof(epoxies[i]) ~= 'table' or typeof(epoxies[i].Spring) ~= 'table' then
			epoxies[i] = {}
			epoxies[i].pos = epox.Value(targetPosition)
			epoxies[i].Spring	= epox.Spring({Target = epoxies[i].pos, Speed = 4 + math.random() , Dampening = 4 + math.random() * 2})
		end
		epoxies[i].pos:Set(targetPosition)
		points[i] = epoxies[i].Spring:Get() or targetPosition
	end

	task.synchronize()
end
-- Raycast params for occlusion detection
local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Exclude
raycastParams.FilterDescendantsInstances = {}

-- Check if a triangle should be culled (all 3 points offscreen, behind camera, or blocked by closer surface)
local last = nil
local function shouldCullTriangle(p1Idx, p2Idx, p3Idx, camera, character)
	-- Check if all three points are offscreen
	task.desynchronize()
	if not pointOnScreen[p1Idx] and not pointOnScreen[p2Idx] and not pointOnScreen[p3Idx] then
		return true
	end

	-- Check if all three points are behind the camera (negative Z in view space)
	local camPos = camera.CFrame.Position
	local camLook = camera.CFrame.LookVector
	local function isBehindCamera(pointIdx)
		local point = points[pointIdx]
		local toPoint = point - camPos
		return toPoint:Dot(camLook) < 0
	end

	if isBehindCamera(p1Idx) and isBehindCamera(p2Idx) and isBehindCamera(p3Idx) then
		return true
	end

	-- Occlusion check: raycast from each point toward camera to see if blocked by closer surface
	if character then
		if last ~= character then
			last = character
			task.synchronize()
			raycastParams.FilterDescendantsInstances = {character}
			task.desynchronize()
		end

		local function isPointBlocked(pointIdx)
			local point = points[pointIdx]
			local pointDepth = depths[pointIdx]
			local direction = (camPos - point).Unit
			local rayResult = workspace:Raycast(point, direction * pointDepth, raycastParams)

			-- If ray hit something and it's closer to camera than our point, point is blocked
			if rayResult then
				local hitDistance = (rayResult.Position - point).Magnitude
				return hitDistance < (pointDepth - 0.1) -- Small tolerance
			end
			return false
		end

		-- Only cull if ALL three points are blocked by closer surfaces
		if isPointBlocked(p1Idx) and isPointBlocked(p2Idx) and isPointBlocked(p3Idx) then
			return true
		end
	end

	return false
end

-- Parallel task: Project points and build triangles
local function projectAndBuildTrianglesParallel(camera:Camera, character)
	-- Project all points to screen (must be on main thread for WorldToScreenPoint)
	for i = 1, #points do
		local screenPos, onScreen = camera:WorldToViewportPoint(points[i])
		screenPositions[i] = Vector2.new(screenPos.X, screenPos.Y)
		depths[i] = (points[i] - camera.CFrame.Position).Magnitude
		pointOnScreen[i] = onScreen
	end

	task.desynchronize()

	-- Clear previous triangles
	table.clear(trianglesToRender)

	-- Build triangles for each face of each body part
	for partIndex = 1, #R6_PARTS do
		local baseIndex = (partIndex - 1) * 8 -- 8 corners per part
		local partColor = R6_PARTS[partIndex].Color
		local skipFaces = SKIP_FACES[partIndex] or {}

		for faceIndex, face in ipairs(FACES) do
			-- Skip internal faces
			if not skipFaces[faceIndex] then
				-- Get the 4 corners of this face (in local part space)
				local c1, c2, c3, c4 = face.corners[1], face.corners[2], face.corners[3], face.corners[4]

				-- Get point indices for these corners
				local idx1, idx2, idx3, idx4 = baseIndex + c1, baseIndex + c2, baseIndex + c3, baseIndex + c4

				-- Get world positions for these corners
				local p1 = points[idx1]
				local p2 = points[idx2]
				local p3 = points[idx3]
				local p4 = points[idx4]

				if p1 and p2 and p3 and p4 then
					-- Calculate face normal in world space for lighting
					local worldNormal = centerCFrame:VectorToWorldSpace(face.normal)
					local cameraDir = camera.CFrame.LookVector
					local dotProduct = worldNormal:Dot(cameraDir)
					local Center = (p1 + p2 + p3 + p4) / 4
					local CenterDepth = (Center - camera.CFrame.Position).Magnitude

					-- Triangle 1: c1, c2, c3 - check culling
					if not shouldCullTriangle(idx1, idx2, idx3, camera, character) then
						--local tri1Center = (p1 + p2 + p3) / 3
						--local tri1Depth = (tri1Center - camera.CFrame.Position).Magnitude

						table.insert(trianglesToRender, {
							screenPoints = {screenPositions[idx1], screenPositions[idx2], screenPositions[idx3]},
							depth = CenterDepth,
							color = partColor,
							normalDot = math.abs(dotProduct)
						})
					end

					-- Triangle 2: c1, c3, c4 - check culling
					if not shouldCullTriangle(idx1, idx3, idx4, camera, character) then
						--local tri2Center = (p1 + p3 + p4) / 3
						--local tri2Depth = (tri2Center - camera.CFrame.Position).Magnitude

						table.insert(trianglesToRender, {
							screenPoints = {screenPositions[idx1], screenPositions[idx3], screenPositions[idx4]},
							depth = CenterDepth,
							color = partColor,
							normalDot = math.abs(dotProduct)
						})
					end
				end
			end
		end
	end

	-- Sort triangles by depth (back to front for painter's algorithm)
	table.sort(trianglesToRender, function(a, b)
		return a.depth > b.depth
	end)

	task.synchronize()
end

-- Draw a filled triangle using the triangle module
local function drawFilledTriangle(p1, p2, p3, leftTri, rightTri, color, normalDot, depth)
	-- Calculate lighting based on normal direction
	task.desynchronize()
	local brightness = math.clamp(0.4 + normalDot * 0.6, 0.3, 1)
	local litColor = Color3.new(
		color.R * brightness,
		color.G * brightness,
		color.B * brightness
	)

	-- Calculate ZIndex based on depth (negative so further surfaces render behind)
	-- Closer to camera = higher ZIndex, further = lower ZIndex
	local zIndex = math.floor(1000 - depth)

	-- Draw the triangle - pass LEFT and RIGHT triangles
	local success, err = pcall(function()
		triangle.draw2dTriangle(p1, p2, p3, parent, leftTri, rightTri)
	end)

	if success then
		task.synchronize()
		leftTri.ImageColor3 = litColor
		rightTri.ImageColor3 = litColor
		leftTri.ZIndex = zIndex
		rightTri.ZIndex = zIndex
		leftTri.Visible = true
		rightTri.Visible = true
		task.desynchronize()
	end
end

-- Main render loop
local fin = true
local phys = false
while script:FindFirstAncestorWhichIsA('Player') do
	task.desynchronize()
	local dt = task.wait()
	
	local camera = workspace.CurrentCamera
	if not camera then continue end
	if not phys then task.spawn(function() phys = true updatePointsParallel(dt) phys = false end) end
	if not fin then continue end
	-- Get character for occlusion detection
	local player = Players.LocalPlayer
	local character = player and player.Character

	-- Run parallel tasks
	task.spawn(projectAndBuildTrianglesParallel, camera, character)

	-- Hide all triangles first
	task.spawn(function() fin = false for i = 1, MAX_TRIANGLES do
		if i < #trianglesToRender then continue end
		task.desynchronize()
		if typeof(leftTrianglePool[i]) == 'Instance' and leftTrianglePool[i].Visible ~= false then	task.synchronize()leftTrianglePool[i].Visible = false task.desynchronize() end
		if typeof(rightTrianglePool[i]) == 'Instance' and rightTrianglePool[i].Visible ~= false then	task.synchronize()rightTrianglePool[i].Visible = false task.desynchronize() end
	end
		
		
		local size = camera.ViewportSize

	-- Draw filled triangles (sorted back to front)
	task.spawn(function() for i, tri in ipairs(trianglesToRender) do
			if i <= MAX_TRIANGLES then
				
			drawFilledTriangle(
				tri.screenPoints[1],
				tri.screenPoints[2],
				tri.screenPoints[3],
				leftTrianglePool[i],
				rightTrianglePool[i],
				tri.color,
				tri.normalDot,
						tri.depth, size
			) 
		end
		end end)
		fin = true
end)
	-- Hide dots (we're rendering solid now, not wireframe) task.desynchronize()
end