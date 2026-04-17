local RunService = game:GetService("RunService")
-- Physics constants
local GRAVITY = Vector3.new(0, -98, 0)  -- custom gravity (studs/s^2)
local SLIDE_ACCEL = 98                -- how hard the player is pushed along the slope
local FRICTION = .33           -- multiplicative decay per frame
-- Roblox Material Friction Factors
local materialFriction = {
	[Enum.Material.Asphalt] = 0.8,
	[Enum.Material.Basalt] = 0.7,
	[Enum.Material.Brick] = 0.8,
	--[Enum.Material.Cardboard] = 0.5,
	[Enum.Material.Carpet] = 0.4,
	--[Enum.Material.Ceramic] = 0.51,
	--[Enum.Material.Clay] = 0.51,
	[Enum.Material.Cobblestone] = 0.5,
	[Enum.Material.Concrete] = 0.7,
	[Enum.Material.CorrodedMetal] = 0.7,
	[Enum.Material.CrackedLava] = 0.65,
	[Enum.Material.DiamondPlate] = 0.35,
	[Enum.Material.Fabric] = 0.35,
	[Enum.Material.Foil] = 0.4,
	[Enum.Material.ForceField] = 0.25,
	[Enum.Material.Glacier] = 0.05,
	[Enum.Material.Glass] = 0.25,
	[Enum.Material.Granite] = 0.4,
	[Enum.Material.Grass] = 0.4,
	[Enum.Material.Ground] = 0.45,
	[Enum.Material.Ice] = 0.02,
	[Enum.Material.LeafyGrass] = 0.4,
	[Enum.Material.Leather] = 0.35,
	[Enum.Material.Limestone] = 0.5,
	[Enum.Material.Marble] = 0.2,
	[Enum.Material.Metal] = 0.4,
	[Enum.Material.Mud] = 0.3,
	[Enum.Material.Neon] = 0.3,
	[Enum.Material.Pavement] = 0.5,
	[Enum.Material.Pebble] = 0.4,
	[Enum.Material.Plaster] = 0.6,
	[Enum.Material.Plastic] = 0.3,
	[Enum.Material.Rock] = 0.5,
	[Enum.Material.RoofShingles] = 0.8,
	[Enum.Material.Rubber] = 1.5,
	[Enum.Material.Salt] = 0.5,
	[Enum.Material.Sand] = 0.5,
	[Enum.Material.Sandstone] = 0.5,
	[Enum.Material.SmoothPlastic] = 0.2,
	[Enum.Material.Slate] = 0.4,
	[Enum.Material.Snow] = 0.3,
	[Enum.Material.Wood] = 0.48,
	[Enum.Material.WoodPlanks] = 0.48,
}

local TERMINAL_VELOCITY = 100          -- max slide speed (studs/s)
local MIN_SLIDE_SPEED = .1             -- minimal speed to be considered sliding
local WALL_CHECK_DIST = 3             -- distance to check for wall collisions
local par = RaycastParams.new()
par.RespectCanCollide = true
par.IgnoreWater = true
par.FilterType = Enum.RaycastFilterType.Exclude

local characters = {}
local datas = {}
local Processing = {}
local running
local Elasped = 0

function RegKey() return tostring(Elasped)..tostring(math.random()) end
function UpdateFilter()
	task.synchronize()
	par.FilterDescendantsInstances = characters
end
function Init(character)
	task.desynchronize()
	local character: Model = character
	if not character or not character.Parent or not character:FindFirstChildOfClass('Humanoid') then repeat task.wait(.1) until not character or not character.Parent or character:FindFirstChildOfClass('Humanoid') end
	if not character or datas[character] or table.find(characters, character) or not character.Parent then return end
	table.insert(characters, character)
	task.synchronize()
	character.Destroying:Once(function()
		task.desynchronize()
		datas[character] = nil
		if table.find(characters, character) then table.remove(characters, table.find(characters, character)) end
		Processing[character] = nil
	end)
	task.desynchronize()
	local h = character:FindFirstChildOfClass('Humanoid')
	if not h then return end
	local hrp = h.RootPart
	if not hrp then return end
	datas[character] = {
		h = h,
		hrp = hrp,
		lastgrounded= 0,
		slideVelocity = Vector3.new(0, 0, 0), slideDir = Vector3.new(),
		isSliding = false,
		Regkey = RegKey()
	}
	UpdateFilter()
end


-- Runtime state

-- Helper: Projects vector onto plane defined by normal
local function projectOnPlane(vector, planeNormal)
	local dot = vector:Dot(planeNormal)
	return vector - planeNormal * dot
end

-- Main update function (to be called every frame when sliding)
local function updateSlide(dataset,dt)
	task.desynchronize()
	if not dataset then return end
	local hrp,h = dataset.hrp, dataset.h
	if not hrp or not h then return end
	-- Raycast downwards to get the floor normal
	local Pivot = hrp.CFrame
	local ExtentSize = hrp.Size
	local high = math.abs(3 * hrp.CFrame.UpVector:Dot(Vector3.yAxis))
	local floorRay = workspace:Raycast(hrp.Position, Vector3.new(0, -(high * 1.1), 0), par) or workspace:Raycast(hrp.Position, hrp.CFrame:VectorToWorldSpace(Vector3.new(0, -(high * 1.1), 0)).Unit * high * 1.1, par)
	if floorRay then
		local floorNormal = floorRay.Normal
		-- Compute slope angle relative to the upward axis.
		local slopeAngle = math.acos(floorNormal:Dot(Vector3.new(0, 1, 0)))
		-- In this simplified system, we allow sliding if the slope isn t too steep.
		if slopeAngle >= math.rad(80) then
			-- Too steep: cancel sliding.
			dataset.isSliding = false
			return
		end

		-- Project gravity onto the floor to get the slide direction.
		dataset.slideDir = projectOnPlane(GRAVITY, floorNormal)

		-- Normalize (if there s no slide component, nothing happens)
		if dataset.slideDir .Magnitude > 0 then
			dataset.slideDir  = dataset.slideDir.Unit
		else
			dataset.slideDir  = Vector3.new(0, 0, 0)
		end

		-- If velocity is below the minimum threshold, give it an initial boost.
		if dataset.slideVelocity.Magnitude < MIN_SLIDE_SPEED then
			dataset.slideVelocity = dataset.slideDir * 5
		else
			-- Increase slide velocity along the slide direction.
			dataset.slideVelocity = dataset.slideVelocity + dataset.slideDir * SLIDE_ACCEL * dt
		end

		-- Apply friction (e.g. air resistance and contact friction)
		if floorRay then dataset.slideVelocity = (dataset.slideVelocity * (1 - ((1 - (materialFriction[floorRay.Material] or FRICTION or 0.25)) * dt))) end

		if dataset.slideVelocity.Magnitude < MIN_SLIDE_SPEED then
			dataset.slideVelocity = Vector3.zero
			dataset.isSliding = false
			return  -- Skip further updates for this frame.
		end
	else
		dataset.slideVelocity += GRAVITY * dt
	end
	-- Cap the speed at terminal velocity.
	if dataset.slideVelocity.Magnitude > TERMINAL_VELOCITY then
		dataset.slideVelocity = dataset.slideVelocity.Unit * TERMINAL_VELOCITY
	end
	local CollidedMargin: Vector3 = Vector3.new()
	local CollisionRight: RaycastResult = workspace:Blockcast(Pivot - Pivot.RightVector * ExtentSize.X/2, ExtentSize, Pivot.RightVector * ExtentSize.X, par)
	local CollisionLeft: RaycastResult = workspace:Blockcast(Pivot + Pivot.RightVector * ExtentSize.X/2, ExtentSize, Pivot.RightVector * -ExtentSize.X, par)
	local CollisionFront: RaycastResult = workspace:Blockcast(Pivot - Pivot.LookVector * ExtentSize.Z/2, ExtentSize, Pivot.LookVector * ExtentSize.Z, par)
	local CollisionBack: RaycastResult = workspace:Blockcast(Pivot + Pivot.LookVector * ExtentSize.Z/2, ExtentSize, Pivot.LookVector * -ExtentSize.Z, par)
	local CollisionTop: RaycastResult = workspace:Blockcast(Pivot - Pivot.UpVector * ExtentSize.Y/2, ExtentSize, Pivot.UpVector * ExtentSize.Y, par)
	local CollisionBottom: RaycastResult = workspace:Blockcast(Pivot + Pivot.UpVector * ExtentSize.Y/2, ExtentSize, Pivot.UpVector * -ExtentSize.Y, par)
	local CollidedMargin: Vector3 = Vector3.new()
	if CollisionRight then CollidedMargin += Pivot.RightVector * ((ExtentSize.X) - CollisionRight.Distance) end
	if CollisionLeft then CollidedMargin -= Pivot.RightVector * ((ExtentSize.X) - CollisionLeft.Distance) end
	if CollisionFront then CollidedMargin += Pivot.LookVector * ((ExtentSize.Z) - CollisionFront.Distance) end
	if CollisionBack then CollidedMargin -= Pivot.LookVector * ((ExtentSize.Z) - CollisionBack.Distance) end
	if CollisionTop then CollidedMargin += Pivot.UpVector * ((ExtentSize.Y) - CollisionTop.Distance) end
	if CollisionBottom then CollidedMargin -= Pivot.UpVector * ((ExtentSize.Y) - CollisionBottom.Distance) end
	-- Predict next position.
	local nextPos = hrp.Position + dataset.slideVelocity * dt - CollidedMargin + (floorRay and floorRay.Normal * math.clamp(high - floorRay.Distance,0,3) or Vector3.new())

	-- Check for wall collision: raycast in slide direction from current position.
	local wallRay = workspace:Raycast(hrp.Position, dataset.slideVelocity.Unit * WALL_CHECK_DIST, par)
	if wallRay then
		-- If a wall (or obstacle) is detected, stop the slide.
		local dot = wallRay.Normal:Dot(dataset.slideVelocity)
		dataset.slideVelocity = dataset.slideVelocity - wallRay.Normal * dot
	else
		-- Update HRP's position.
		if not floorRay then floorRay = CollisionBottom end
		-- For orientation, we align the "forward" direction with the slide direction (if needed)
		local grounded
		if floorRay then
			dataset.lastgrounded = 0
			dataset.thisray = floorRay
		else
			if dataset.lastgrounded < .5 then
				dataset.lastgrounded += dt else
				dataset.isSliding = false
				return
			end
		end
		if dataset.thisray and dataset.thisray.Position.Y >= -1 and dataset.lastgrounded < .5 then
			local surfaceNormal = dataset.thisray.Normal
			local projectedSlide = projectOnPlane(dataset.slideVelocity, surfaceNormal)
			-- If the projected vector is too small (e.g. nearly zero), then default to the current forward direction.
			if projectedSlide.Magnitude < 1e-5 then
				projectedSlide = hrp.CFrame.LookVector
			else
				projectedSlide = projectedSlide.Unit
			end

			local forwardVector = hrp.CFrame.LookVector
			local rightVector = forwardVector:Cross(surfaceNormal).Unit
			local adjustedForward = surfaceNormal:Cross(rightVector).Unit
			grounded = CFrame.lookAt(nextPos, nextPos + projectedSlide, surfaceNormal)
		end
		if hrp:FindFirstChild('SLIDE__FlySFX') and hrp:FindFirstChild('SLIDE__FlySFX'):IsA('Sound') then
			task.synchronize()
			hrp:FindFirstChild('SLIDE__FlySFX').Volume = dataset.slideVelocity.Magnitude/TERMINAL_VELOCITY
			hrp:FindFirstChild('SLIDE__FlySFX').PlaybackSpeed = dataset.slideVelocity.Magnitude*2.5/TERMINAL_VELOCITY
		end
		if hrp.CFrame.Y < -1 then
			dataset.slideVelocity = dataset.slideVelocity + GRAVITY * (1.25 + hrp.CFrame.Y/4) * dt
		end
		if  dataset.slideVelocity.Y > 0 then
			grounded = nil
		end
		if grounded then
			if (grounded.X ~= grounded.X) or (grounded.Y ~= grounded.Y) or (grounded.Z ~= grounded.Z) then
				grounded = CFrame.new(nextPos) * hrp.CFrame.Rotation
			end
			grounded = grounded.Rotation + Vector3.new(math.clamp(grounded.X ,-1000, 1000),math.clamp(grounded.Y ,-50, 1000),math.clamp(grounded.Z ,-1000, 1000))
		end	
		task.synchronize()
		hrp.CFrame = (typeof(grounded) == 'CFrame' and grounded) or hrp.CFrame.Rotation:Lerp(CFrame.new(nextPos, nextPos + dataset.slideVelocity).Rotation, (10 ^ -1) ^ dt) + nextPos
		hrp.AssemblyLinearVelocity = dataset.slideVelocity
		if hrp.Position.Y < -5 then
			dataset.isSliding = false
		end
	end

end

function RUN()
	if running then return end
	-- Simulation loop: update sliding physics every step.
	task.synchronize()
	running = RunService.Stepped:Connect(function(_, dt)
		if not next(Processing) then if running then pcall(function() running:Disconnect() end) end running = nil return end
		for i,v in pairs(Processing) do
			if typeof(datas[i]) ~= 'table' or not datas[i].isSliding or datas[i].Regkey ~= v then EndSlide(i) continue end
			if datas[i].Running then continue end
			task.spawn(function() datas[i].Running = true updateSlide(datas[i] , dt) datas[i].Running = false end)
		end
		Elasped += dt
		if Elasped > 1000 then
			Elasped -= 2000
		end
	end)
	task.desynchronize()
end

function EndSlide(character)
	task.desynchronize()
	if not	Processing[character] then return else Processing[character] = RegKey() end
	Processing[character] = nil
	if not character then return end
	if datas[character].hrp then task.synchronize() if datas[character].hrp:FindFirstChild('SLIDE__FlySFX') then datas[character].hrp:FindFirstChild('SLIDE__FlySFX'):Destroy() end datas[character].hrp.Anchored = false datas[character].hrp.AssemblyLinearVelocity = datas[character].slideVelocity end
	task.synchronize()
	character:SetAttribute('Sliding', nil)
	if character:FindFirstChild('Crouching') then	character:FindFirstChild('Crouching'):SetAttribute("SpecialPose", 'None') end
end
-- For example purposes, trigger slide by setting isSliding to true when pressing E.
function StartSlide(character)
	task.desynchronize()
	if character and not  datas[character] then
		Init(character)
	end
	if not character or not datas[character] or Processing[character] then return end
	local dataset = datas[character]
	local h, hrp = dataset.h, dataset.hrp
	datas[character].Regkey = RegKey()
	if hrp and h and h.FloorMaterial and h:GetState() == Enum.HumanoidStateType.Running and hrp.AssemblyLinearVelocity.Magnitude > 0 then
		-- Optionally: reset slideVelocity when starting a new slide
		dataset.slideVelocity = hrp.AssemblyLinearVelocity
		dataset.isSliding = true
		RUN()
		Processing[character] = datas[character].Regkey
		task.synchronize()
		hrp.Anchored =true
		if not hrp:FindFirstChild('SLIDE__FlySFX') then
			local FlySFX = Instance.new('Sound', hrp)
		FlySFX.SoundId = 'rbxassetid://12222046'
		FlySFX.Looped = true
		FlySFX.Name = 'SLIDE__FlySFX'
		FlySFX:Play()
		FlySFX.Volume = 0
			FlySFX.PlaybackSpeed = 0 elseif hrp:FindFirstChild('SLIDE__FlySFX'):IsA('Sound') then hrp:FindFirstChild('SLIDE__FlySFX'):Play() end
		character:SetAttribute('Sliding', true)
		if character:FindFirstChild('Crouching') then	character:FindFirstChild('Crouching'):SetAttribute("SpecialPose", 'Slide') end
	end
end
function StopSlide(character)
	task.desynchronize()
	datas[character].Regkey = RegKey()
	if not character or not datas[character] or not Processing[character] then return end
	datas[character].isSliding = false
end
script.Event.Event:Connect(function(Char, bool)
	if bool then
		StartSlide(Char)
	else
		StopSlide(Char)
	end
end)
--[[game.UserInputService.InputBegan:Connect(function(a,b) if b then return end
	if a.KeyCode == Enum.KeyCode.E then
		Init(game.Players.LocalPlayer.Character)
		StartSlide(game.Players.LocalPlayer.Character)
	end
end)
game.UserInputService.InputEnded:Connect(function(a,b) if b then return end
	if a.KeyCode == Enum.KeyCode.E then
		StopSlide(game.Players.LocalPlayer.Character)
	end
end)]]

coroutine.resume(coroutine.create(function()
	while task.wait(300) do
		for i,v in pairs(characters) do
			if not v or not v.Parent then table.remove(characters, i) if Processing[v] then Processing[v] = nil end end
		end
	end
end))