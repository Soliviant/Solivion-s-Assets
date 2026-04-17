local parent = script.Parent.Parent
local Players = game:GetService("Players")

-- Configuration
local POINT_COUNT = 48 -- 6 parts × 8 corners each
local CONNECTION_DISTANCE = 20
local Epox = game:GetService('ReplicatedStorage'):FindFirstChild("Epoxyish")
local requiredEP = require(Epox)
local SPRINGS = {}


-- (might be accurate R6 dimensions)
local R6_PARTS = {
	{name = "Head", center = Vector3.new(0, 1.5, 0), size = Vector3.new(1, 1, 1), pointCount = 8, Color = Color3.fromRGB(245, 205, 48)},
	{name = "Torso", center = Vector3.new(0, 0, 0), size = Vector3.new(2, 2, 1), pointCount = 8, Color = Color3.fromRGB(math.random(0,255), math.random(0,255), math.random(0,255))},
	--{name = "Torso", center = Vector3.new(0, 0, 0), size = Vector3.new(2, 2, 1), pointCount = 8, Color = Color3.fromRGB(13, 105, 172)},
	{name = "LeftArm", center = Vector3.new(-1.5, 0, 0), size = Vector3.new(1, 2, 1), pointCount = 8, jointPivot = Vector3.new(-1.5, 1, 0), Color = Color3.fromRGB(245, 205, 48)},
	{name = "RightArm", center = Vector3.new(1.5, 0, 0), size = Vector3.new(1, 2, 1), pointCount = 8, jointPivot = Vector3.new(1.5, 1, 0), Color = Color3.fromRGB(245, 205, 48)},
	{name = "LeftLeg", center = Vector3.new(-0.5, -2, 0), size = Vector3.new(1, 2, 1), pointCount = 8, Color = Color3.fromRGB(164, 189, 71), jointPivot = Vector3.new(-0.5, -1, 0)},
	{name = "RightLeg", center = Vector3.new(0.5, -2, 0), size = Vector3.new(1, 2, 1), pointCount = 8, Color = Color3.fromRGB(164, 189, 71), jointPivot = Vector3.new(0.5, -1, 0)},
}
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


-- So many TABLES!!!!
local staticR6Positions = {}
local points = {}
local linePool = {}
local screenPositions = {}
local depths = {}
local connections = {}
local centerCFrame = CFrame.new()
local pointPartIndex = {} -- assign the R6 part indice the point belongs to
local pointOnScreen = {} -- check on screen things
local pointSprings = {} -- make table like the way I make the combat2 springy
local offset = Vector3.new()
local vels = Vector3.new()

-- Animation state
local previousPosition = Vector3.new(0, 0, 0)
local walkSpeed = 0
local animationTime = 0

-- Create a line frame
function createLine()
	local line = Instance.new("Frame")
	line.Name = "ConnectionLine3D"
	line.BackgroundColor3 = Color3.new(1, 1, 1)
	line.BackgroundTransparency = 0.5
	line.BorderSizePixel = 0
	line.Size = UDim2.fromOffset(0, 1)
	line.Visible = false
	line.AnchorPoint = Vector2.new(0, 0.5)
	line.Parent = parent
	return line
end

-- Helper function to add points at corners of a box
function addBoxPoints(center, size, positions)
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
	-- Create spring for each point
	pointSprings[i] = {}
	pointSprings[i].pos = requiredEP.Value(staticR6Positions[i])
	pointSprings[i].Spring = requiredEP.Spring({
		Target = pointSprings[i].pos,
		Speed = 4 + math.random() * 2,
		Dampening = 3 + math.random() * 0.4,
	})
end

-- Create line pool
for i = 1, POINT_COUNT * (POINT_COUNT - 1) / 2 do
	table.insert(linePool, createLine())
end

local cachedchr = nil
local CastSize = Vector3.new(3,2.5,3)
local chrpos = (workspace:FindFirstChild('_SpawnLocation') and workspace:FindFirstChild('_SpawnLocation'):IsA('SpawnLocation') and workspace:FindFirstChild('_SpawnLocation').CFrame) or CFrame.new()
chrpos += Vector3.new(0,2,0)
BASE_POSITION = chrpos.Position + Vector3.new(0,20,0)
--x axis, y axis, z axis, 1 and -1 casts
local rayp = RaycastParams.new()
rayp.RespectCanCollide = true
rayp.IgnoreWater = true
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
function changething(dt)
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
				local grounded = vels.Y <= 0 and workspace:Blockcast(chrpos, CastSize, Vector3.new(0, (0-CastSize.Y/2) -0.2 , 0), rayp) or workspace:Blockcast(chrpos, CastSize, chrpos:VectorToWorldSpace(Vector3.new(0, (0-CastSize.Y/2) -0.2 , 0)), rayp)
				local ceil = vels.Y > 0 and  workspace:Blockcast(chrpos, CastSize, Vector3.new(0, (CastSize.Y/2) + 0.2 , 0), rayp) or workspace:Blockcast(chrpos, CastSize, chrpos:VectorToWorldSpace(Vector3.new(0, (CastSize.Y/2) + 0.2 , 0)), rayp)
				local grounded2 = vels.Y <= 0 and workspace:Blockcast(chrpos, CastSize, Vector3.new(0, (0-CastSize.Y/2) -1 , 0), rayp) 
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

		-- springy realistic rotation momentum

		if SPRINGS == {} or typeof(SPRINGS) ~= 'table' or #SPRINGS <= 0 then
			SPRINGS.pos = requiredEP.Value(humanoidRootPart.CFrame)
			SPRINGS.Spring = requiredEP.Spring({
				Target = SPRINGS.pos,
				Speed = 5 + math.random() * (math.random() > .5 and -1 or 1)/2,
				Dampening = 3 + math.random() * (math.random() > .5 and -1 or 1)/4,
			})
		elseif SPRINGS.pos then
			SPRINGS.pos:Set(humanoidRootPart.CFrame)
		end
		centerCFrame = SPRINGS.Spring and SPRINGS.Spring:Get() or ((typeof(humanoidRootPart) == 'table' or typeof(humanoidRootPart) == 'Instance') and humanoidRootPart.CFrame) or (typeof(player:GetAttribute('__LOCAL_CFRAME')) == 'CFrame' and player:GetAttribute('__LOCAL_CFRAME')) or (typeof(workspace.CurrentCamera) == 'Instance' and workspace.CurrentCamera.ClassName == 'Camera' and workspace.CurrentCamera.CFrame)  or centerCFrame or CFrame.new()
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
		pointSprings[i].pos:Set(targetPosition)
		points[i] = pointSprings[i].Spring:Get() or targetPosition
	end

	task.synchronize()
end

function MapWireFrame(camera:Camera)
	for i = 1, #points do
		local screenPos, onScreen = camera:WorldToViewportPoint(points[i])
		screenPositions[i] = Vector2.new(screenPos.X, screenPos.Y)
		depths[i] = (points[i] - camera.CFrame.Position).Magnitude
		pointOnScreen[i] = onScreen
	end

	task.desynchronize()
	table.clear(connections)

	for i = 1, #points do
		for j = i + 1, #points do
			--Kinda normal optimization
			if pointPartIndex[i] == pointPartIndex[j] and (pointOnScreen[i] or pointOnScreen[j]) then
				local distance = (points[i] - points[j]).Magnitude
				local ZinD = (depths[i] + depths[j]) / 2
				if distance < CONNECTION_DISTANCE then
					table.insert(connections, {
						index1 = i,
						index2 = j,
						distance = distance,
						Color = (R6_PARTS[pointPartIndex[i] or 1] or {Color = Color3.new(1,1,1)}).Color or Color3.new(1,1,1),
						ZIn = -ZinD or 0 -- Roblox got their ZIndex so Z-fighting haxx
					})
				end
			end
		end
	end

	task.synchronize()
end

function lerp(a, b, c)
	return a + (b - a) * c
end

function drawLine(pos1, pos2, line, depth1, depth2, dist, Color, Z, dt)
	local delta = pos2 - pos1
	local length = math.sqrt(delta.X * delta.X + delta.Y * delta.Y)

	if length > 0 then
		local Speed = math.clamp(1 - ((10 ^ -24) ^ dt),0,1) 
		local size = line.Size:Lerp(UDim2.fromOffset(length, 1), Speed)
		local rota = math.deg(math.atan2(delta.Y, delta.X))
		local midpoint = pos1 + delta / 2 - Vector2.new(length, 1) / 2
		local posp = line.Position:Lerp(UDim2.fromOffset(midpoint.X, midpoint.Y), Speed)
		local avgDepth = (depth1 + depth2) / 2
		local depthFactor = math.clamp(1 - (avgDepth / 100), 0, 1)
		local Transparency = math.clamp(math.clamp(dist/20 ,0,1) + math.clamp((1 - depthFactor) * 1 ,0,1) ,0,1)
		local color = line.BackgroundColor3:Lerp(Color or Color3.new(1,1,1), Speed)
		local rot = lerp(line.Rotation, rota, math.clamp(Speed, 0, 1))
		task.synchronize()
		line.Size = size
		line.Rotation = rot or rota
		line.Position = posp
		line.Visible = true
		line.BackgroundColor3 = color
		line.BackgroundTransparency = Transparency
		line.ZIndex = Z or 0
	end
end

-- Main render loop
local a = false
while script:FindFirstAncestorWhichIsA('Player') do
	local dt = task.wait() or 1/60
	task.spawn(changething, dt)
	local camera = workspace.CurrentCamera
	if not camera then continue end

	-- runs
	task.spawn(MapWireFrame, camera)
	if a then continue end
	-- Draw connections
	task.spawn(function() a = true for i, conn in ipairs(connections) do
		task.desynchronize()
		if i <= #linePool then
			--unfortunately I can't read shit when I needed to add way more stuff 
				--task.spawn(function()  -- 1000% overhead
					drawLine(
						screenPositions[conn.index1],
						screenPositions[conn.index2],
						linePool[i],
						depths[conn.index1],
						depths[conn.index2],
						conn.distance,
						conn.Color, conn.ZIn, dt
					) 
				--end)
		end
	end
	local count = #connections
	if #linePool > count then
		for i = count + 1, #linePool, 1 do
			if not linePool[i] then continue end
			task.synchronize()
			linePool[i].Visible = false
			task.desynchronize()
		end
	end a = false end)
end