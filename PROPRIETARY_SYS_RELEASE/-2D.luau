local parent = script.Parent.Parent
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local triangle = require(script.Parent.triangle)

-- R6 Character Body Part Definitions (accurate R6 dimensions)
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

-- Triangle rendering
local trianglePool = {}
local trianglesToRender = {}

-- Animation state
local previousPosition = Vector3.new(0, 0, 0)
local previousTime = 0
local walkSpeed = 0
local animationTime = 0

-- Create a dot frame for 3D point


-- Create triangle images for rendering
local function createTrianglePair()
	task.synchronize()
	
	local img1 = Instance.new("ImageLabel")
	img1.Name = "Triangle1"
	img1.BackgroundTransparency = 1
	img1.BorderSizePixel = 0
	img1.Visible = false
	img1.Parent = parent
	
	local img2 = Instance.new("ImageLabel")
	img2.Name = "Triangle2"
	img2.BackgroundTransparency = 1
	img2.BorderSizePixel = 0
	img2.Visible = false
	img2.Parent = parent
	
	return {img1, img2}
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
-- Head: 12, Torso: 12, LeftArm: 12, RightArm: 12, LeftLeg: 10, RightLeg: 10 = 68 triangles
local MAX_TRIANGLES = 72
for i = 1, MAX_TRIANGLES do
	table.insert(trianglePool, createTrianglePair())
end

task.synchronize()
-- Parallel task: Update 3D point positions based on R6 character
local epox = require(game:GetService('ReplicatedStorage'):WaitForChild('Epoxyish'))
local epoxies = {}
local animatedPositions = {}
local function updatePointsParallel(dt)
	task.desynchronize()

	-- Get player's HumanoidRootPart CFrame
	local player = Players.LocalPlayer
	if typeof(player) ~= 'Instance' or typeof(player.UserId) ~= 'number' then return end
	local character = player and player.Character or workspace:FindFirstChild(tostring(player.UserId))
	if typeof(player.Character) ~= 'Instance' and (typeof(character) ~= 'Instance' or character:GetAttribute('__REGPLRID') ~= player.UserId) then return end
	local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
	local check = typeof(humanoidRootPart) ~= 'Instance' or not humanoidRootPart.ClassName:lower():match('part')
	local cf = check and character.ClassName:lower():match('model') and character:GetPivot() or CFrame.new()

	if check then humanoidRootPart = {CFrame = cf, Position = cf.Position} end
	local currentPosition = humanoidRootPart.Position

	-- Calculate speed from X,Z delta
	if dt > 0 then
		local timeDelta = dt
		if timeDelta > 0 then
			local positionDelta = Vector3.new(currentPosition.X - previousPosition.X, 0, currentPosition.Z - previousPosition.Z)
			walkSpeed = positionDelta.Magnitude / timeDelta
		end
	else
		walkSpeed = 16
	end

	previousPosition = currentPosition

	-- Update animation time based on speed
	animationTime = animationTime + dt * walkSpeed * 0.5
	animationTime = animationTime % (2 * math.pi)

	centerCFrame = humanoidRootPart.CFrame


	-- Apply OldR6-style animation with proper joint rotations
	local walkCycle = math.sin(animationTime)

	-- Check if player is in air (FloorMaterial is not an EnumItem)
	local humanoid = character and character:FindFirstChildOfClass("Humanoid") or {MoveDirection = Vector3.new(), Health = 100, MaxHealth = 100}
	local isInAir = (character:GetAttribute('Grounded') == nil and (typeof(humanoid) == 'Instance' and (typeof(humanoid.FloorMaterial) ~= "EnumItem" or humanoid.FloorMaterial == Enum.Material.Air or (typeof(humanoid.RootPart) == 'Instance' and humanoid.RootPart.Anchored))) or (character:GetAttribute('Grounded') == false)) or false

	-- Check if player is standing still (very low speed)
	local isStandingStill = (walkSpeed < (10 ^ -3)) and (typeof(humanoid) ~= 'Instance' or humanoid.MoveDirection.Magnitude < 0.01)

	-- Create animated positions based on static R6 positions
	local animatedPositions = {}
	for i, staticPos in ipairs(staticR6Positions) do
		local partIndex = pointPartIndex[i]
		local animatedPos = staticPos

		-- Apply animation based on body part with joint rotation
		if partIndex == 3 then -- LeftArm - rotate around shoulder (forward/back)
			local jointPivot = R6_PARTS[3].jointPivot
			local relativeToPivot = staticPos - jointPivot
			local rotationAngle = walkCycle

			-- In air: rotate 180 degrees so arms face up
			if isInAir then
				rotationAngle = math.pi
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
				rotationAngle = math.pi
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
			if isStandingStill or isInAir then
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
			if isStandingStill or isInAir then
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

	-- Transform animated R6 positions to world space based on center CFrame
	for i = 1, #animatedPositions do
		local relativePos = animatedPositions[i]
		-- Use VectorToWorldSpace to transform the point position
		local worldOffset = centerCFrame:VectorToWorldSpace(relativePos)
		local ae = centerCFrame.Position + worldOffset
		if not epoxies[i] then
			epoxies[i] = epox.Spring({Target = epox.Value(ae), Position = Vector3.new(), Speed = 3 + math.random() , Dampening = 2 + math.random() * 2})
		else
			epoxies[i].Target = epox.Value(ae)
		end
		points[i] = epoxies[i].Position
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
		local RelPos = centerCFrame:VectorToWorldSpace(animatedPositions[partIndex] or Vector3.new())
		local dist = (RelPos - camera.CFrame.Position).Magnitude/4
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
					local point = (Center - camera.CFrame.Position)
					local rel = -camera.CFrame.LookVector:Dot(point.Unit)
					local CenterDepth = point.Magnitude * rel
					
					-- Triangle 1: c1, c2, c3 - check culling
					if not shouldCullTriangle(idx1, idx2, idx3, camera, character) then
						local tri1Center = (p1 + p2 + p3) / 3
						local tri1Depth = (tri1Center - camera.CFrame.Position).Magnitude
						
						table.insert(trianglesToRender, {
							screenPoints = {screenPositions[idx1], screenPositions[idx2], screenPositions[idx3]},
							depth = CenterDepth,
							color = partColor,
							normalDot = math.abs(dotProduct)
						})
					end
					
					-- Triangle 2: c1, c3, c4 - check culling
					if not shouldCullTriangle(idx1, idx3, idx4, camera, character) then
						local tri2Center = (p1 + p3 + p4) / 3
						local tri2Depth = (tri2Center - camera.CFrame.Position).Magnitude
						
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
local function drawFilledTriangle(p1, p2, p3, imgPair, color, normalDot, depth)
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
	
	-- Draw the triangle
	local success, err = pcall(function()
		triangle.draw2dTriangle(p1, p2, p3, parent, imgPair[1], imgPair[2])
	end)
	
	if success then
		task.synchronize()
		imgPair[1].ImageColor3 = litColor
		imgPair[2].ImageColor3 = litColor
		imgPair[1].ZIndex = zIndex
		imgPair[2].ZIndex = zIndex
		imgPair[1].Visible = true
		imgPair[2].Visible = true
		task.desynchronize()
	end
end

-- Main render loop
local a = false
while script:FindFirstAncestorWhichIsA('Player') do
	local camera = workspace.CurrentCamera
	if not camera then continue end
	task.spawn(updatePointsParallel, task.wait())
	-- Get character for occlusion detection
	local player = Players.LocalPlayer
	local character = player and player.Character
	
	-- Run parallel tasks
	task.spawn(projectAndBuildTrianglesParallel, camera, character)
	if a then continue end
	task.spawn(function() a= true
	-- Hide all triangles first
	for i, imgPair in ipairs(trianglePool) do
		if i < #trianglesToRender then continue end
		task.desynchronize()
		if typeof(imgPair[1]) == 'Instance' and imgPair[1].Visible ~= false then	task.synchronize()imgPair[1].Visible = false task.desynchronize() end
		if typeof(imgPair[2]) == 'Instance' and imgPair[2].Visible ~= false then	task.synchronize()imgPair[2].Visible = false task.desynchronize() end
	end
	
		-- Draw filled triangles (sorted back to front)
		task.spawn(function() local size = camera.ViewportSize
		for i, tri in ipairs(trianglesToRender) do
			if i <= #trianglePool then 
				
			drawFilledTriangle(
				tri.screenPoints[1],
				tri.screenPoints[2],
				tri.screenPoints[3],
						trianglePool[i],
				tri.color,
				tri.normalDot,
						tri.depth, size
			) 
		end
			end a= false end) 
	end)


	task.desynchronize()
end