local X,Y = 0,0
local Ang = CFrame.new()
local Dist = 5
local LDist = 0.5
local Centre = Vector3.new()
local UIP = game:GetService('UserInputService')
local LastThumbStickPos = Vector3.new()
local TriggerR2 = 0
local TriggerL2 = 0
local Sensitivity = 1.0 -- Gamepad sensitivity multiplier
local L1Held = false -- Track L1 for sensitivity adjustment
local SkewEnabled = true
local SkewX,SkewY,SkewZ,SquishX,SquishY = 0,0,0,0,0
local SkewUp, SkewDown, SkewLeft, SkewRight = false, false, false, false
local SkewForward, SkewBack = false, false
local ResetSkew = false
local SquishXUp, SquishXDown = false, false
local SquishYUp, SquishYDown = false, false 

-- Get user's camera sensitivity from Roblox settings
function applySkew(cframe, skewX, skewY, skewZ) 
	if skewX == 0 and skewY == 0 and skewZ == 0 then
		return cframe
	end
	local pos = cframe.Position
	local look = cframe.LookVector
	local up = cframe.UpVector
	local right = cframe.RightVector
	local skewedRight = right + (up * skewY) + (look * skewZ)
	local skewedUp = up + (right * skewX) + (look * skewZ)
	local newLook = look
	skewedRight = skewedRight - (skewedRight:Dot(look)) * look
	skewedUp = skewedUp - (skewedUp:Dot(look)) * look
	return CFrame.fromMatrix(pos, skewedRight, skewedUp)
end
local function getUserSensitivity()
	local success, value = pcall(function()
		return UserSettings().GameSettings:GetCameraSensitivity()
	end)
	if success and typeof(value) == 'number' then
		return value
	end
	return 1.0 -- Default
end
UIP.InputChanged:Connect(function(inp, pr)
	if pr then return end
	if UIP.MouseBehavior ~= Enum.MouseBehavior.Default and inp.UserInputType == Enum.UserInputType.MouseMovement  then
		local moved = inp.Delta
		local userSens = getUserSensitivity()
		X -= math.sign(90-math.abs(Y)) * moved.X * userSens * 0.5
		Y -= moved.Y * userSens * 0.5
	end
	if inp.UserInputType == Enum.UserInputType.Gamepad1 then
		if inp.KeyCode == Enum.KeyCode.Thumbstick2 then
			LastThumbStickPos = inp.Position
		elseif inp.KeyCode == Enum.KeyCode.ButtonR2 then
			TriggerR2 = inp.Position.Z
		elseif inp.KeyCode == Enum.KeyCode.ButtonL2 then
			TriggerL2 = inp.Position.Z
		end
	elseif inp.UserInputType == Enum.UserInputType.MouseWheel then
		Dist = math.clamp(Dist - inp.Position.Z, 0.5, 25)
	end
end)
local U,D,L,R = false,false,false,false
local taskA, taskB, taskC, taskD = nil, nil, nil, nil
local m2d = false
UIP.InputBegan:Connect(function(inp, pr)
	if pr then return end
	if inp.UserInputType == Enum.UserInputType.MouseButton2 then
		UIP.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition m2d = true
		task.spawn(function()
			while m2d and task.wait() do
				UIP.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
			end UIP.MouseBehavior = Enum.MouseBehavior.Default
		end)
	elseif inp.KeyCode == Enum.KeyCode.ButtonL1 then
		L1Held = true
	elseif inp.KeyCode == Enum.KeyCode.DPadUp then
		if L1Held then
			-- Increase sensitivity
			Sensitivity = math.min(Sensitivity + 0.1, 5.0)
		else
			Y += 1
			if taskA then
				task.cancel(taskA) taskA = nil
			end
			taskA = task.spawn(function()
				task.wait(0.25) 
				U = true
			end)
		end
	elseif inp.KeyCode == Enum.KeyCode.DPadDown then
		if L1Held then
			-- Decrease sensitivity
			Sensitivity = math.max(Sensitivity - 0.1, 0.1)
		else
			Y -= 1
			if taskB then
				task.cancel(taskB) taskB = nil
			end
			taskB = task.spawn(function()
				task.wait(0.25)
				D = true
			end)
		end
	elseif inp.KeyCode == Enum.KeyCode.DPadLeft then
		X += math.sign(90-math.abs(Y))
		if taskC then
			task.cancel(taskC) taskC = nil
		end
		taskC = task.spawn(function()
			task.wait(0.25)
			L = true
		end)
	elseif inp.KeyCode == Enum.KeyCode.DPadRight then
		X -= math.sign(90-math.abs(Y))
		if taskD then
			task.cancel(taskD) taskD = nil
		end
		taskD = task.spawn(function()
			task.wait(0.25)
			R = true
		end)
	elseif inp.KeyCode == Enum.KeyCode.I then
		SkewUp = true
	elseif inp.KeyCode == Enum.KeyCode.K then
		SkewDown = true
	elseif inp.KeyCode == Enum.KeyCode.J then
		SkewLeft = true
	elseif inp.KeyCode == Enum.KeyCode.L then
		SkewRight = true
	elseif inp.KeyCode == Enum.KeyCode.U then
		SkewForward = true
	elseif inp.KeyCode == Enum.KeyCode.O then
		SkewBack = true
	elseif inp.KeyCode == Enum.KeyCode.R then
		ResetSkew = true
	elseif inp.KeyCode == Enum.KeyCode.T then
		SquishYUp = true
	elseif inp.KeyCode == Enum.KeyCode.Y then
		SquishXDown = true
	elseif inp.KeyCode == Enum.KeyCode.G then
		SquishYDown = true
	elseif inp.KeyCode == Enum.KeyCode.H then
		SquishXUp = true
	end
end)
UIP.InputEnded:Connect(function(inp, pr)
	if pr then return end
	if inp.UserInputType == Enum.UserInputType.Gamepad1 then
		if inp.KeyCode == Enum.KeyCode.Thumbstick2 then
			LastThumbStickPos = Vector3.new()
		elseif inp.KeyCode == Enum.KeyCode.ButtonR2 then
			TriggerR2 = 0
		elseif inp.KeyCode == Enum.KeyCode.ButtonL2 then
			TriggerL2 = 0
		elseif inp.KeyCode == Enum.KeyCode.ButtonL1 then
			L1Held = false
		end
	elseif inp.UserInputType == Enum.UserInputType.MouseButton2 then
		m2d = false		UIP.MouseBehavior = Enum.MouseBehavior.Default
	end
	-- DPad handling (outside Gamepad1 check)
	if inp.KeyCode == Enum.KeyCode.DPadUp then
		if taskA then 		
			task.cancel(taskA) taskA = nil
		end
		U = false 		
	elseif inp.KeyCode == Enum.KeyCode.DPadDown then
		if taskB then
			task.cancel(taskB) taskB = nil
		end
		D = false
	elseif inp.KeyCode == Enum.KeyCode.DPadLeft then
		if taskC then
			task.cancel(taskC) taskC = nil
		end
		L = false
	elseif inp.KeyCode == Enum.KeyCode.DPadRight then
		if taskD then
			task.cancel(taskD) taskD = nil
		end
		R = false
	elseif inp.KeyCode == Enum.KeyCode.I then
		SkewUp = false
	elseif inp.KeyCode == Enum.KeyCode.K then
		SkewDown = false
	elseif inp.KeyCode == Enum.KeyCode.J then
		SkewLeft = false
	elseif inp.KeyCode == Enum.KeyCode.L then
		SkewRight = false
	elseif inp.KeyCode == Enum.KeyCode.U then
		SkewForward = false
	elseif inp.KeyCode == Enum.KeyCode.O then
		SkewBack = false
	elseif inp.KeyCode == Enum.KeyCode.R then
		ResetSkew = false
	elseif inp.KeyCode == Enum.KeyCode.T then
		SquishYUp = false
	elseif inp.KeyCode == Enum.KeyCode.Y then
		SquishXDown = false
	elseif inp.KeyCode == Enum.KeyCode.G then
		SquishYDown = false
	elseif inp.KeyCode == Enum.KeyCode.H then
		SquishXUp = false
	end
end)
-- Touch camera controls using GUI frame (top-right corner like Roblox default)
local TweenService = game:GetService('TweenService')
local touchZoneGui = nil
local touchZoneFrame = nil
local touchDragActive = {} -- Track active drags by input object (key = input)
local lastPinchDist = nil
local touchStartPositions = {} -- Track where each touch STARTED globally

-- ID System: Simple counter with 200 entry log (for debugging)
local touchIdCounter = 0
local touchIdLog = {} -- Last 200 entries
local inputToId = {} -- Map input object to ID
local function newTouchId(input)
	touchIdCounter = touchIdCounter + 1
	local id = touchIdCounter
	inputToId[input] = id
	table.insert(touchIdLog, 1, id)
	if #touchIdLog > 200 then table.remove(touchIdLog) end
	return id
end

local function createTouchZone()
	local playerGui = game:GetService('Players').LocalPlayer:FindFirstChildOfClass('PlayerGui')
	if not playerGui then return end
	-- Create ScreenGui
	for i,v in playerGui:GetChildren() do
		if v.Name == 'CameraTouchZoneGui' and v:IsA('ScreenGui') and v:GetAttribute('TheControl') then
			v:Destroy()
		end
	end
	touchZoneGui = Instance.new('ScreenGui')
	touchZoneGui.Name = 'CameraTouchZoneGui'
	touchZoneGui.ResetOnSpawn = false
	touchZoneGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	touchZoneGui.Parent = playerGui
	touchZoneGui.IgnoreGuiInset = true touchZoneGui:SetAttribute("TheControl", true)

	-- Create touch zone frame (top-right corner, 40% width, 50% height)
	touchZoneFrame = Instance.new('Frame')
	touchZoneFrame.Name = 'TouchZone'
	touchZoneFrame.Size = UDim2.new(0.5, 0, 0.7125, 0)
	touchZoneFrame.Position = UDim2.new(0.5, 0, 0, 0) -- Top-right corner
	touchZoneFrame.BackgroundColor3 = Color3.fromRGB(100, 200, 255)
	touchZoneFrame.BackgroundTransparency = 0.9 -- Mostly transparent
	touchZoneFrame.BorderSizePixel = 2
	touchZoneFrame.BorderColor3 = Color3.fromRGB(100, 200, 255)
	touchZoneFrame.Active = false -- Capture input
	touchZoneFrame.Parent = touchZoneGui

	-- Add corner radius
	local corner = Instance.new('UICorner')
	corner.CornerRadius = UDim.new(.1, 0)
	corner.Parent = touchZoneFrame

	-- Fade out after 10 seconds using TweenService (don't set Visible)
	TweenService:Create(touchZoneFrame, TweenInfo.new(10, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = 1,
	}):Play()

	-- Frame InputBegan is NOT used - we use global UIP.InputBegan instead
	-- This avoids race conditions where frame events fire before global events
end

-- Global InputChanged: Handle drag anywhere on screen (for inputs that started in zone)
UIP.InputChanged:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.UserInputType == Enum.UserInputType.MouseMovement then
		return
	end

	-- Only process touch or mouse button drags, not mouse movement
	if input.UserInputType ~= Enum.UserInputType.Touch and input.UserInputType ~= Enum.UserInputType.MouseButton1 then
		return
	end

	if not touchDragActive[input] then return end

	local data = touchDragActive[input]
	local currentPos = Vector2.new(input.Position.X, input.Position.Y)
	local delta = data.lastPos - currentPos

	-- Check for pinch zoom (2+ active touches)
	local touchCount = 0
	local positions = {}
	for inp, d in pairs(touchDragActive) do
		touchCount = touchCount + 1
		table.insert(positions, d.lastPos)
	end

	if touchCount >= 2 and #positions >= 2 then
		-- Pinch zoom mode
		local currentDist = (positions[1] - positions[2]).Magnitude
		if lastPinchDist then
			local pinchDelta = currentDist - lastPinchDist
			Dist = math.clamp(Dist - pinchDelta * 0.03, 0.5, 25)
		end
		lastPinchDist = currentDist
	else
		-- Single touch: rotation
		local userSens = getUserSensitivity()
		X += math.sign(90-math.abs(Y)) * delta.X * userSens * 0.5
		Y += delta.Y * userSens * 0.5
	end

	data.lastPos = currentPos
end)

-- Global InputBegan: Track where ALL touches START and register if inside frame
UIP.InputBegan:Connect(function(input, gameProcessed)
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
		local startPos = Vector2.new(input.Position.X, input.Position.Y)
		touchStartPositions[input] = startPos

		-- Check if touch started inside the frame bounds
		if touchZoneFrame then
			local framePos = touchZoneFrame.AbsolutePosition
			local frameSize = touchZoneFrame.AbsoluteSize

			if startPos.X >= framePos.X and startPos.X <= framePos.X + frameSize.X and
				startPos.Y >= framePos.Y and startPos.Y <= framePos.Y + frameSize.Y then
				newTouchId(input)
				touchDragActive[input] = {
					startPos = startPos,
					lastPos = startPos
				}
				lastPinchDist = nil
			end
		end
	end
end)

-- Global InputEnded: Stop tracking when touch ends
UIP.InputEnded:Connect(function(input, gameProcessed)
	if touchDragActive[input] then
		touchDragActive[input] = nil
		inputToId[input] = nil -- Clean up ID mapping
		lastPinchDist = nil
	end
	-- Clean up start position tracking
	touchStartPositions[input] = nil
end)

-- Create touch zone on start
if UIP.TouchEnabled then createTouchZone() end

function getSubjectFilter(Cam)
	local subject = typeof(Cam) == 'Instance' and Cam.ClassName == 'Camera' and Cam.CameraSubject
	if typeof(subject) ~= 'Instance' then return nil end

	if subject:IsA('Humanoid') then
		return subject:FindFirstAncestorWhichIsA('Model') or subject.Parent
	elseif subject:IsA('BasePart') then
		return subject:FindFirstAncestorWhichIsA('Model') or subject.Parent
	elseif subject:IsA('Model') then
		return subject
	else return subject.Parent or subject end
end

local Param = RaycastParams.new()
Param.FilterType = Enum.RaycastFilterType.Exclude
Param.IgnoreWater = true
local LastMax = 25

while script and script.Parent do
	local dt = task.wait()
	local userSens = getUserSensitivity()
	local sens = Sensitivity * userSens
	X %= 360
	Y = (Y + 180) % 360 - 180
	if U then
		Y += dt * 32 * sens
	end
	if D then
		Y -= dt * 32 * sens
	end
	if L then
		X += math.sign(90-math.abs(Y)) * dt * 32 * sens
	end
	if R then
		X-= math.sign(90-math.abs(Y)) * dt * 32 * sens
	end
	if typeof(LastThumbStickPos) == 'Vector3' then
		X -= LastThumbStickPos.X * math.sign(90-math.abs(Y)) * dt * 32 * sens
		Y += LastThumbStickPos.Y * dt * 32 * sens
	end
	Dist = math.clamp(Dist + (TriggerR2 - TriggerL2) * 10 * dt, 0.5, 25)
	local Cam = workspace.CurrentCamera
	if typeof(Cam) == 'Instance' and Cam:IsA('Camera') then
		local Speed = 1 - (10^-3) ^ dt
		if Cam.CameraType ~= Enum.CameraType.Scriptable then	pcall(function()	Cam.CameraType = Enum.CameraType.Scriptable end) end
		local Inverted = 0
		pcall(function()
			Inverted = UserSettings().GameSettings:GetCameraYInvertValue()
		end)
		if typeof(Inverted) ~= 'number' then Inverted = 0 end
		Ang = Ang:Lerp(CFrame.Angles(0, math.rad(X * math.sign(SquishX + 1)), 0) * CFrame.Angles(math.rad(Y * Inverted * math.sign(SquishY + 1)), 0, 0), Speed)
		Centre = typeof(Cam.CameraSubject) == 'Instance' and (Cam.CameraSubject:IsA('BasePart') and Cam.CameraSubject.Position or Cam.CameraSubject:IsA('Humanoid') and Cam.CameraSubject.RootPart and Cam.CameraSubject.RootPart.Position or Cam.CameraSubject:IsA('Model') and Cam.CameraSubject:GetPivot().Position) or (script:FindFirstAncestorWhichIsA('Player') and script:FindFirstAncestorWhichIsA('Player'):FindFirstChildOfClass('PlayerGui') and script:FindFirstAncestorWhichIsA('Player'):FindFirstChildOfClass('PlayerGui'):FindFirstChild('theThingWoah') and typeof(script:FindFirstAncestorWhichIsA('Player'):FindFirstChildOfClass('PlayerGui'):FindFirstChild('theThingWoah'):GetAttribute('__POS')) == 'Vector3' and script:FindFirstAncestorWhichIsA('Player'):FindFirstChildOfClass('PlayerGui'):FindFirstChild('theThingWoah'):GetAttribute('__POS')) or Centre
		local BackwardVec = -Ang.LookVector * LDist
		LDist = math.min(LDist + (Dist - LDist) * Speed, LastMax)
		pcall(function()	Param.FilterDescendantsInstances = {getSubjectFilter(Cam)} end)
		local TotalDist = workspace:Blockcast(CFrame.new(Centre), Vector3.new(.1,.1,.1), -Ang.LookVector * Dist, Param)
		if TotalDist then
			LDist = math.min(LDist, TotalDist.Distance)
			LastMax = math.min(LastMax, TotalDist.Distance)
		else
			LastMax = 25
		end
		local SETTO = Ang + (Centre + BackwardVec)
		if SkewEnabled then -- non-orthogonal rotation
			if not SkewUp and not SkewDown and not SkewLeft and not SkewRight and not SkewForward and not SkewBack then
				SkewX = SkewX * .98
				SkewY = SkewY * .98
				SkewZ = SkewZ * .98
			else
				if SkewUp then SkewY = math.min(SkewY + dt * userSens, 0.99) end
				if SkewDown then SkewY = math.max(SkewY - dt * userSens, -0.99) end
				if SkewLeft then SkewX = math.max(SkewX - dt * userSens, -0.99) end
				if SkewRight then SkewX = math.min(SkewX + dt * userSens, 0.99) end
				if SkewForward then SkewZ = math.min(SkewZ + dt * userSens, 0.99) end --  2 of ts not noticable
				if SkewBack then SkewZ = math.max(SkewZ - dt * userSens, -0.99) end
			end
			if not SquishXUp and not SquishXDown and not SquishYUp and not SquishYDown then
				SquishX = SquishX * .98
				SquishY = SquishY * .98
			else
				if SquishXUp then SquishX = math.min(SquishX + dt * userSens, .2) end  -- unfortunately limited because positive direction(stretch) is buggy, I manged tto either only make Stretch limitless or make Squish limitless, only one at a time
				if SquishXDown then SquishX = math.max(SquishX - dt * userSens, -2) end
				if SquishYUp then SquishY = math.min(SquishY + dt * userSens, .2) end
				if SquishYDown then SquishY = math.max(SquishY - dt * userSens, -2) end
			end
			local skewedCFrame = applySkew(SETTO, SkewX, SkewY, SkewZ)
			if math.abs(SquishX) > 0.0001 or math.abs(SquishY) > 0.0001 then
				local squishCFrame = CFrame.new(0, 0, 0, 1 + SquishX, 0, 0, 0, 1 + SquishY, 0, 0, 0, 1) 
				pcall(function()	Cam.CFrame = skewedCFrame * squishCFrame end)
			else
				pcall(function()	Cam.CFrame = skewedCFrame end)
			end
		else
		pcall(function()	Cam.CFrame = SETTO end)
		end
	end
end