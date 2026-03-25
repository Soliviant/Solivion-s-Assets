-- walk type sh wit xtra borgir and fri
--By Solivion

--Type
local ActionENUM = {'Crawling','Crouching','Walking','Running'}
local ActionData = {{a=1/4,b=1/4},{a=1/2,b=1/2},{a=1,b=1},{a=1.25,b=1.5}}

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- Configuration
local LEG_SWING_ANGLE = 60 -- Maximum leg swing angle in degrees
local ARM_SWING_ANGLE = -40 -- Maximum arm swing angle in degrees

--core
local Actored = script:GetActor() ~= nil
local tn = game:FindFirstChildOfClass('TweenService') or game:GetService('TweenService')
local WALK_SPEED = 10 

-- R6 Rig References
local rig = Actored and script:GetActor():FindFirstAncestorWhichIsA('Model') or  script:FindFirstAncestorWhichIsA('Model')
if not rig or not rig:FindFirstChildOfClass('Humanoid') then
    return
end

rig:SetAttribute('NO_DIR', true)

local og__lsa = LEG_SWING_ANGLE
local og__asa = ARM_SWING_ANGLE
function UpdateStance(num)
	if typeof(num) ~= 'number' then print('upd can') return end
	num = math.clamp(num, 1, 4)
	local datalabel = ActionData[num] or {a=1,b=1,c=1}
	if typeof(datalabel.a) ~= 'number' or typeof(datalabel.b) ~= 'number' then print('not num') return end
	LEG_SWING_ANGLE = og__lsa * datalabel.a
	ARM_SWING_ANGLE = og__asa * datalabel.b
end

local action_main = rig:GetAttribute('__ACTION') or 'Walking'
pcall(function()
	rig:GetAttributeChangedSignal('__ACTION'):Connect(function()
		local nowatt = rig:GetAttribute('__ACTION')
		if not table.find(ActionENUM, nowatt) then return end
		action_main = nowatt
		print(action_main)
		print(table.find(ActionENUM, nowatt))
		UpdateStance(table.find(ActionENUM, nowatt))
	end)
end)
local humanoid = rig:FindFirstChildOfClass("Humanoid")
local torso = rig:FindFirstChild("Torso")
local head = rig:FindFirstChild("Head")
local leftArm = rig:FindFirstChild("Left Arm")
local rightArm = rig:FindFirstChild("Right Arm")
local leftLeg = rig:FindFirstChild("Left Leg")
local rightLeg = rig:FindFirstChild("Right Leg")
local r15 = false
-- Motor6D References
local leftHip = torso and torso:FindFirstChild("Left Hip")
local rightHip = torso and torso:FindFirstChild("Right Hip")
local leftShoulder = torso and torso:FindFirstChild("Left Shoulder")
local rightShoulder = torso and torso:FindFirstChild("Right Shoulder")
local neck = torso and torso:FindFirstChild("Neck")
local rootJoint = rig:FindFirstChild("HumanoidRootPart") and rig:FindFirstChild("HumanoidRootPart"):FindFirstChild("RootJoint")

if not (leftHip or rightHip or leftShoulder or rightShoulder or neck or rootJoint) then
	torso = rig:FindFirstChild("UpperTorso")
	 head = rig:FindFirstChild("Head")
	 leftArm = rig:FindFirstChild("LeftUpperArm")
	rightArm = rig:FindFirstChild("RightUpperArm")
	leftLeg = rig:FindFirstChild("LeftUpperLeg")
	rightLeg = rig:FindFirstChild("RightUpperLeg")

	-- Motor6D References
	neck = head and head:FindFirstChild("Neck")
	leftHip = leftLeg and leftLeg:FindFirstChild("LeftHip")
	rightHip = rightLeg and rightLeg:FindFirstChild("RightHip")
	leftShoulder = leftArm and leftArm:FindFirstChild("LeftShoulder")
	rightShoulder = rightArm and rightArm:FindFirstChild("RightShoulder") r15 = true
	rootJoint = rig:FindFirstChild('LowerTorso') and rig:FindFirstChild('LowerTorso'):FindFirstChild("Root")
end

-- Store original C1 values
local originalLeftHip = leftHip and (leftHip:GetAttribute('og__1') or leftHip.C1) or CFrame.new()
local originalRightHip = rightHip and (rightHip:GetAttribute('og__1') or rightHip.C1) or CFrame.new()
local originalLeftShoulder = leftShoulder and (leftShoulder:GetAttribute('og__1') or leftShoulder.C1) or CFrame.new()
local originalRightShoulder = rightShoulder and (rightShoulder:GetAttribute('og__1') or rightShoulder.C1) or CFrame.new()
if Actored then task.synchronize() end
if leftHip then
	leftHip:SetAttribute('og__1', originalLeftHip)
end
if rightHip then
	rightHip:SetAttribute('og__1', originalRightHip)
end
if leftShoulder then
	leftShoulder:SetAttribute('og__1', originalLeftShoulder)
end
if rightShoulder then
	rightShoulder:SetAttribute('og__1', originalRightShoulder)
end
--others
local originalNeck = neck and (neck:GetAttribute('og__1') or neck.C1) or CFrame.new()
local originalRootJoint = rootJoint and (rootJoint:GetAttribute('og__1') or rootJoint.C1) or CFrame.new()
if rootJoint then
	rootJoint:SetAttribute('og__1', originalRootJoint)
end
if neck then
	neck:SetAttribute('og__1', originalNeck)
end

-- Validate all required parts
if not (rig and humanoid and torso) then
    warn("Missing required R6 rig parts!")
    return
end

-- Animation state
local isWalking = false
local walkTime = 0

local mul = 1
-- Function to start walking animation
local function startWalking()
    if isWalking then return end
    isWalking = true
	walkTime = 0 local state = (humanoid:GetState() or {Name = 'running'}).Name:lower()
	if not (state:match('climb') or state:match('swim')) then mul = -mul end
end

function tooled()
	return rig:FindFirstChildOfClass('Tool') and rig:FindFirstChildOfClass('Tool').RequiresHandle and rig:FindFirstChildOfClass('Tool'):FindFirstChild('Handle')
end
-- Function to stop walking animation
function stopWalking(a)
	local divisor
	if humanoid.Sit then
		divisor = WALK_SPEED > 2 and math.max(WALK_SPEED, 2) or 2
		local legdesl = originalLeftHip * CFrame.Angles(r15 and math.rad(-90) or 0, 0, r15 and 0 or math.rad(90))
		local legdesr = originalRightHip * CFrame.Angles(r15 and math.rad(-90) or 0, 0, r15 and 0 or math.rad(-90))
		if Actored then task.synchronize() end
		if leftHip and originalLeftHip then tn:Create(leftHip, TweenInfo.new(leftHip.C1.LookVector:Dot(legdesl.LookVector)/divisor), {C1 = legdesl}):Play() end
		if rightHip and originalRightHip then tn:Create(rightHip, TweenInfo.new(rightHip.C1.LookVector:Dot(legdesr.LookVector)/divisor), {C1 = legdesr}):Play() end
	end
    if not isWalking then return end
    isWalking = false
	
	divisor = WALK_SPEED > 2 and math.max(WALK_SPEED, 2) or 2
	-- Reset all joints to original positions
	if Actored then task.synchronize() end
	if not humanoid.Sit then
	if leftHip and originalLeftHip then tn:Create(leftHip, TweenInfo.new(leftHip.C1.LookVector:Dot(originalLeftHip.LookVector)/divisor), {C1 = originalLeftHip}):Play() end
	if rightHip and originalRightHip then tn:Create(rightHip, TweenInfo.new(rightHip.C1.LookVector:Dot(originalRightHip.LookVector)/divisor), {C1 = originalRightHip}):Play() end
	end local state = (humanoid:GetState() or {Name = 'running'})
	local des = (a or (table.find({'jump', 'freefall', 'swimming'}, state.Name:lower()))) and CFrame.Angles(0,r15 and math.rad(180) or 0,math.rad(180)) or CFrame.new()
	if leftShoulder and originalLeftShoulder then tn:Create(leftShoulder, TweenInfo.new(leftShoulder.C1.LookVector:Dot((originalLeftShoulder * des).LookVector)/divisor), {C1 = originalLeftShoulder * des}):Play() end
	if rootJoint and originalRootJoint then tn:Create(rootJoint, TweenInfo.new(rootJoint.C1.LookVector:Dot((originalRootJoint).LookVector)/divisor), {C1 = originalRootJoint}):Play() end
	if neck and originalNeck then tn:Create(neck, TweenInfo.new(neck.C1.LookVector:Dot((originalNeck).LookVector)/divisor), {C1 = originalNeck}):Play() end
	if tooled() then
		if rightShoulder and originalRightShoulder then tn:Create(rightShoulder, TweenInfo.new(rightShoulder.C1.LookVector:Dot((originalRightShoulder  * CFrame.Angles(r15 and math.rad(-90) or 0,0, r15 and 0 or math.rad(-90))).LookVector)/divisor), {C1 = originalRightShoulder * CFrame.Angles(r15 and math.rad(-90) or 0,0, r15 and 0 or math.rad(-90))}):Play() end
	else
		if rightShoulder and originalRightShoulder then tn:Create(rightShoulder, TweenInfo.new(rightShoulder.C1.LookVector:Dot((originalRightShoulder * des).LookVector)/divisor), {C1 = originalRightShoulder * des}):Play() end
	end
	rightShoulderC1 = originalRightShoulder * des
   -- if neck and originalNeck then neck.C1 = originalNeck end
   -- if rootJoint and originalRootJoint then rootJoint.C1 = originalRootJoint end
end

-- Animation update function
local leftShoulderC1, leftHipC1, rightHipC1, rootJointC1, neckC1 = originalLeftShoulder, originalLeftHip, originalRightHip, originalRootJoint, originalNeck
function updateAnimation(deltaTime)
	if Actored then task.desynchronize() end
	local vel = humanoid.RootPart.AssemblyLinearVelocity
	local action = action_main
	if action == 'Running' then vel = vel/1.25 end -- slow down speed because the step is wide
	local state = (humanoid:GetState() or {Name = 'running'}).Name:lower()
	local exemption = (state:match('climb') or state:match('swim'))
	WALK_SPEED = WALK_SPEED - (WALK_SPEED - (exemption and vel or Vector3.new(vel.X, 0, vel.Z)).Magnitude/1.5) * (1 - ((10 ^ -1) ^ deltaTime) )
	if not isWalking then return end
	if exemption then action = 'Walking' end
	walkTime = walkTime + deltaTime
	if walkTime > (math.pi*2/WALK_SPEED) then
		walkTime %= (math.pi*2/WALK_SPEED)
	end
    local walkCycle = walkTime * WALK_SPEED
	-- Calculate sine wave for smooth animation
  	if walkCycle > math.pi * 2 then
		walkTime = (walkCycle%(math.pi * 2))/WALK_SPEED
		walkCycle = walkTime * WALK_SPEED
	end
	local sinValue = mul * math.sin(walkCycle)
	local cosValue =  math.cos(walkCycle)
	
	if Actored then task.desynchronize()  end 
    -- Leg animation (opposite movement)
	if leftHip and originalLeftHip then
		leftHipC1 = originalLeftHip * CFrame.Angles(
			(r15 and math.rad(-LEG_SWING_ANGLE * sinValue) or 0) + (not r15 and action == 'Running' and math.rad(-15 * sinValue) or 0) ,  -- Forward/backward swing
			r15 and action == 'Running' and (math.max(0, math.rad(sinValue * 10)) + math.max(0, math.rad(cosValue * 10))) or 0,
			r15 and 0 or math.rad(LEG_SWING_ANGLE * sinValue) -- Slight rotation
		)if Actored then task.synchronize() end leftHip.C1 = leftHipC1 if Actored then task.desynchronize() end
    end
    
    if rightHip and originalRightHip then
		rightHipC1 = originalRightHip * CFrame.Angles(
			(r15 and math.rad(LEG_SWING_ANGLE * sinValue) or 0) + (not r15 and action == 'Running' and math.rad(15 * sinValue) or 0) ,  -- Opposite swing
			r15 and action == 'Running' and (math.min(0, math.rad(sinValue * 10)) + math.min(0, math.rad(cosValue * -10))) or 0,
			r15 and 0 or math.rad(LEG_SWING_ANGLE * sinValue) -- Opposite rotation
		)if Actored then task.synchronize() end rightHip.C1 = rightHipC1 if Actored then task.desynchronize() end
    end
	if Actored then task.desynchronize()  end 
	local grounded = state:match('climb') or state:match('swim') or humanoid.FloorMaterial == Enum.Material.Air
    -- Arm animation (opposite to legs)
	if leftShoulder and originalLeftShoulder then
		leftShoulderC1 = originalLeftShoulder * CFrame.Angles((r15 and math.rad(-ARM_SWING_ANGLE * sinValue) or 0) + (not r15 and action == 'Running' and math.rad(30 * sinValue + math.abs(-cosValue * 30)) or 0), (r15 and action == 'Running' and -(math.min(0, math.rad(sinValue * 30)) + math.min(0, math.rad(cosValue * -30))) or 0) + (not r15 and action == 'Running' and math.rad(30 * cosValue) or 0),r15 and 0 or math.rad(ARM_SWING_ANGLE * sinValue)) * (grounded and CFrame.Angles(math.rad(180),r15 and 0 or math.rad(180),0) or CFrame.new())
		if Actored then task.synchronize() end leftShoulder.C1 = leftShoulderC1 if Actored then task.desynchronize() end
	end
    
	if rightShoulder and originalRightShoulder then
		if tooled() then
			rightShoulderC1 = originalRightShoulder  * CFrame.Angles(r15 and math.rad(-90) or 0,0, r15 and 0 or math.rad(-90))
		else
		rightShoulderC1 = originalRightShoulder * CFrame.Angles(
				(r15 and math.rad(ARM_SWING_ANGLE * sinValue) or 0) + (not r15 and action == 'Running' and math.rad(-30 * sinValue + math.abs(cosValue * 30)) or 0) ,  -- Opposite to left leg
				(r15 and action == 'Running' and (math.min(0, math.rad(sinValue * -30)) + math.min(0, math.rad(cosValue * -30))) or 0) + (not r15 and action == 'Running' and math.rad(30 * cosValue) or 0),
			r15 and 0 or  math.rad(ARM_SWING_ANGLE * sinValue) -- Slight rotation
			)* (grounded and CFrame.Angles(math.rad(180),r15 and 0 or math.rad(180),0) or CFrame.new()) 
		end
		if Actored then task.synchronize() end rightShoulder.C1 = rightShoulderC1 if Actored then task.desynchronize()  end 
	end
	if rootJoint and originalRootJoint then
		local rootcf = CFrame.Angles(r15 and action == 'Running' and math.rad(math.abs(cosValue) * 5) or 0, r15 and action == 'Running' and math.rad(sinValue * -15) or 0, not r15 and action == 'Running' and math.rad(sinValue * 15) or 0)
		rootJointC1 = originalRootJoint * rootcf
		if Actored then task.synchronize() end rootJoint.C1 = rootJointC1 if Actored then task.desynchronize() end 
		if neck and originalNeck then
			local neckcf = rootcf:Inverse()
			neckC1 = originalNeck * neckcf
			if Actored then task.synchronize() end neck.C1 = neckC1 if Actored then task.desynchronize() end 
		end
	end
end

-- Connect to humanoid movement events
if humanoid then 
	if Actored then task.synchronize() end
    humanoid.Running:Connect(function(speed)
        if speed > 0.5 then
            startWalking()
        else
            stopWalking()
        end
	end)
	humanoid.Climbing:Connect(startWalking)
	humanoid.Swimming:Connect(startWalking)
    
    -- Handle jumping/falling
    humanoid.StateChanged:Connect(function(oldState, newState)
		if newState == Enum.HumanoidStateType.Jumping or newState == Enum.HumanoidStateType.Freefall or newState == Enum.HumanoidStateType.Landed then
			stopWalking(true)
		else
			if humanoid.RootPart.AssemblyLinearVelocity.Magnitude > 0.05 then
            startWalking() else stopWalking() end
        end
    end)
end
rig.ChildAdded:ConnectParallel(function()
	if tooled() then
		task.synchronize()
		pcall(function()
		rightShoulder.C1 = originalRightShoulder  * CFrame.Angles(r15 and math.rad(-90) or 0,0, r15 and 0 or math.rad(-90))
		end) 
	end
end)
rig.ChildRemoved:ConnectParallel(function()
	if not tooled() then
		task.synchronize()
		pcall(function()
			rightShoulder.C1 = rightShoulderC1 or originalRightShoulder 
		end) 
	end
end)

-- Main animation loop
RunService.Heartbeat:Connect(updateAnimation)

-- Initialize with current state
startWalking()
