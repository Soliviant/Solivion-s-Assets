--By Solivion
task.desynchronize()
task.wait(math.pi)

local Chr = script:FindFirstAncestorWhichIsA('Model') and script:FindFirstAncestorWhichIsA('Model'):FindFirstAncestorWhichIsA('Model') or script:FindFirstAncestorWhichIsA('Model')
if not Chr then return end
local Hum: Humanoid = Chr:FindFirstChildOfClass('Humanoid') or Chr:WaitForChild('Humanoid', 10)
if not Hum or not Hum:IsA('Humanoid') then return end
local root = Hum.RootPart
local camera = workspace.CurrentCamera
local HipOri = {}
local snowing = workspace:FindFirstChild('IsItRaining') and workspace:FindFirstChild('IsItRaining'):IsA('NumberValue') and workspace:FindFirstChild('IsItRaining').Value == 1

-- Check if this is an Avatar Joint Upgrade rig (uses AnimationConstraint)
--[[local isAJU = false
local counta = 0
local countb = 0
for _, v in Chr:GetDescendants() do
	if v:IsA('AnimationConstraint') then
		counta += 1
	elseif v.ClassName:lower():match('motor6d') then
		countb += 1
	end
end
if counta >= countb then
	isAJU = true
else isAJU = false
end]]
local DEFAULT_LIMIT = 4056

function sanitizeNumber(n, limit)
	limit = limit or DEFAULT_LIMIT
	if n ~= n then
		return 0 
	end return math.clamp(n, -limit, limit)
end

function fixVector3(vec, limit) return Vector3.new(sanitizeNumber(vec.X, limit),sanitizeNumber(vec.Y, limit),sanitizeNumber(vec.Z, limit))end

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
function register(v) if typeof(v) ~= 'Instance' then return end
	if (v:IsA('AnimationConstraint')) and (v.Name:upper():match('HIP') or v.Name:upper():match('ROOT') or v.Name:upper():match('NECK')) then
		local att0 = v.Attachment0
		local att1 = v.Attachment1
		if att0 and att1 then
			HipOri[v] = {
				C0 = v:GetAttribute('failsafe') or att0.CFrame,
				C1 = v:GetAttribute('c1') or att1.CFrame,
				Attachment0 = att0,
				Attachment1 = att1
			}
			if not v:GetAttribute('c1') then task.synchronize() v:SetAttribute('c1', att1.CFrame) task.desynchronize() end
			if not v:GetAttribute('failsafe') then task.synchronize() v:SetAttribute('failsafe', att0.CFrame) task.desynchronize() end
		end
	elseif (v.ClassName:lower():match('motor6d')) and (v.Name:upper():match('HIP') or v.Name:upper():match('ROOT') or v.Name:upper():match('NECK')) then
		HipOri[v] = v:GetAttribute('failsafe') or v.C0
		if not v:GetAttribute('c1') then task.synchronize() v:SetAttribute('c1', v.C1) task.desynchronize() end
		if not v:GetAttribute('failsafe') then	task.synchronize() v:SetAttribute('failsafe', v.C0) task.desynchronize() end
	end
end
for i,v in Chr:GetDescendants() do
	if snowing and v.Name:upper():match('ROOT') then continue end
	register(v)
end
task.synchronize()
Chr.DescendantAdded:Connect(function(v)
	if snowing and v.Name:upper():match('ROOT') then return end
	register(v)
end)
function compareCFrame(a, b)
	if typeof(a) ~= "CFrame" or typeof(b) ~= 'CFrame' or a.LookVector:Dot(b.LookVector) < .98 or (a.Position - b.Position).Magnitude > .1 then return false end return true -- if cframe look the same(close enough), this thing will return false
end

--roblox's rig system befeelin lass trust worthy day by day.
local isr15 = Chr:FindFirstChild('UpperTorso') and Chr:FindFirstChild('UpperTorso'):IsA('BasePart') and Chr:FindFirstChild('LowerTorso') and Chr:FindFirstChild('LowerTorso'):IsA('BasePart')
if Chr:GetAttribute('R6') or (Chr:FindFirstChild('Animate') and Chr:FindFirstChild('Animate'):IsA('Script')) then
	isr15 = false
end
pcall(function()
	if Chr:FindFirstChildOfClass('Humanoid') and Chr:FindFirstChildOfClass('Humanoid').RigType == Enum.HumanoidRigType.R15 and not Chr:FindFirstChild('Animate'):IsA('Script') then
		isr15 = true
	end
end)
task.synchronize()
Chr:GetAttributeChangedSignal('R6'):Connect(function()
	if Chr:GetAttribute('NOT_R6') then isr15 = true return end
	isr15 = not Chr:GetAttribute('R6')
end)
if Chr:GetAttribute('NOT_R6') then isr15 = true end
task.desynchronize()

while Hum and root do
	task.desynchronize()
	local dt = task.wait()
	local speed = 1 - (10 ^ -2) ^ dt
	local WalkDirection = Hum.MoveDirection
	if not table.find({Enum.HumanoidStateType.Freefall, Enum.HumanoidStateType.Running, Enum.HumanoidStateType.Landed, Enum.HumanoidStateType.Jumping},Hum:GetState()) or (WalkDirection.Unit.Magnitude ~=  WalkDirection.Unit.Magnitude or WalkDirection.Unit.Magnitude < 1) then
		WalkDirection = root.CFrame.UpVector
	end
	WalkDirection = fixVector3(WalkDirection)
	local rootlook = root.CFrame.LookVector
	rootlook = fixVector3(rootlook)
	--detect walking backward, it's lower with a bit offset so it doesn't do a quick spin while walking 90 degree to the left or right.
	if WalkDirection:Dot(rootlook) < -0.05 then WalkDirection = -WalkDirection end
	local rvec = root.CFrame.RightVector
	local LeftRight = -rvec:Dot(WalkDirection)
	local FrontBack = table.find({Enum.HumanoidStateType.Freefall, Enum.HumanoidStateType.Swimming, Enum.HumanoidStateType.Climbing, Enum.HumanoidStateType.Landed, Enum.HumanoidStateType.Jumping},Hum:GetState()) and rootlook:Dot(Hum.MoveDirection) or 0
	if Enum.HumanoidStateType.Running == Hum:GetState() then FrontBack = (root.AssemblyLinearVelocity:Dot(rootlook) * root.AssemblyLinearVelocity.Magnitude/(96 * math.pi)) end
	
	-- 30 degree max for backward/forward stuff
	local XAng = snowing and 0 or math.pi/6 * FrontBack
	-- 45 degree max for legs and torso. should add up to the walking angle if you ask me.
	local LegTransform = CFrame.Angles(0, math.pi/4 * LeftRight * (snowing and 2 or 1), 0)
	local LegUntra = CFrame.Angles(0, math.pi/2 * LeftRight, 0)
	local camYaw = 0 
	local camlook = camera.CFrame.LookVector
	camlook = fixVector3(camlook)
	local rootYaw = math.atan2(rootlook.X, rootlook.Z)
	local camPitch = 0
	if typeof(camera) ~= "Instance" or camera.ClassName ~= "Camera" then
		camYaw = rootYaw
	else
		camYaw = math.atan2(camlook.X, camlook.Z)
		camPitch = math.asin(math.clamp(camlook.Y, -1, 1))
	end
	local yawDiff = camYaw - rootYaw
	yawDiff = (yawDiff + math.pi) % (2 * math.pi) - math.pi -- wrap around and normalize
	local movementTiltYaw = math.pi/4 * LeftRight
	local torsoCameraYaw = 0
	if math.abs(yawDiff) > math.rad(90) then
		torsoCameraYaw = yawDiff - math.sign(yawDiff) * math.rad(90)
	end
	local totalTorsoYaw = torsoCameraYaw + movementTiltYaw
	local clampedTotalTorsoYaw = math.clamp(totalTorsoYaw, -math.rad(90), math.rad(90))
	local torsoYaw = clampedTotalTorsoYaw - movementTiltYaw
	local headPitch = math.clamp(camPitch, -math.rad(60), math.rad(60))
	local torsoPitch = math.clamp(camPitch - headPitch, -math.rad(30), math.rad(30))
	local CameraTransform = CFrame.new()
	if not Chr:GetAttribute('NO_DIR') then
	if isr15 then
		CameraTransform = CFrame.Angles(torsoPitch, torsoYaw, 0)
	else
		CameraTransform = CFrame.Angles(-torsoPitch, 0, torsoYaw)
	end CameraTransform = fixCFrame(CameraTransform) end
	local MovementTilt = CFrame.new()
	if isr15 then
		MovementTilt = CFrame.Angles(0, movementTiltYaw, 0)
	else
		MovementTilt = CFrame.Angles(
			Chr:GetAttribute('NO_DIR') and 0 or XAng,
			Chr:GetAttribute('NO_DIR') and 0 or movementTiltYaw/3,
			movementTiltYaw
		)
	end
	local TorsTransform = isr15 and (CameraTransform * MovementTilt) or (MovementTilt * CameraTransform)
	local headYawRelative = yawDiff - clampedTotalTorsoYaw
	headYawRelative = math.clamp(headYawRelative, -math.rad(90), math.rad(90))
	local headPitchRelative = headPitch - torsoPitch
	local HeadTransform = CFrame.new() if not Chr:GetAttribute('NO_DIR') then
	if isr15 then
		HeadTransform = CFrame.Angles(headPitchRelative, headYawRelative, 0)
	else
		HeadTransform = CFrame.Angles(-headPitchRelative, 0, headYawRelative)
	end HeadTransform = fixCFrame(HeadTransform) end
	local HipCounterTransform = CFrame.new() if not Chr:GetAttribute('NO_DIR') then
	if isr15 then
		HipCounterTransform = CameraTransform:Inverse()
	else
		HipCounterTransform = CFrame.Angles(-torsoPitch, -torsoYaw, 0)
	end HipCounterTransform = fixCFrame(HipCounterTransform) end
	TorsTransform = fixCFrame(TorsTransform) or CFrame.new()
	for i,v in HipOri do
		task.desynchronize()
		local isAJUJoint = type(v) == 'table'
		local origC0, origC1, att0, att1
		
		if isAJUJoint then
			origC0, origC1 = v.C0, v.C1
			att0, att1 = v.Attachment0 or {CFrame = CFrame.new()}, v.Attachment1 or {CFrame = CFrame.new()}
			if typeof(att0) ~= 'Instance' or typeof(att1) ~= 'Instance' then HipOri[i] = nil end
		else
			origC0 = v
		end
		
		if typeof(i:GetAttribute('offset__C0')) == 'CFrame' then origC0 = origC0 * i:GetAttribute('offset__C0') end
		
		local iC0, iC1
		
		if i.Name:upper():match('ROOT') then
			if snowing then continue end
			if isAJUJoint then
				iC0 = att0.CFrame:Lerp(origC0 * TorsTransform, speed)
			else
				iC0 = i.C0:Lerp(origC0 * TorsTransform, speed)
			end
		elseif i.Name:upper():match('NECK') then
			if isAJUJoint then
				iC0 = att0.CFrame:Lerp(origC0 * HeadTransform, speed)
			else
				iC0 = i.C0:Lerp(origC0 * HeadTransform, speed)
			end 
		else
			-- Apply counter-rotation to hips to prevent leg displacement
			local revleg = (isr15 or Chr:GetAttribute('NO_DIR')) and CFrame.new() or CFrame.Angles(0,0,(i.Name:upper():match("LEFT") and -1 or 1) * XAng)
			-- Counter the torso rotation: apply inverse BEFORE origC0 to account for position offset
			-- This compensates for the arc movement of hip attachment points when torso rotates
			local counterC0 = HipCounterTransform * origC0
			local leg = CFrame.new(LegTransform:ToWorldSpace(counterC0).Position) * counterC0.Rotation * LegTransform
			
		    if isAJUJoint then
				iC0 = att0.CFrame:Lerp(leg * revleg, speed)
			else
				iC0 = i.C0:Lerp(leg * revleg, speed)
			end
			
			if not isr15 then
				local cw = isAJUJoint and origC1 or i:GetAttribute('c1')
				local leg2 = CFrame.new(LegUntra:ToWorldSpace(cw).Position) * origC0.Rotation * LegUntra
				if isAJUJoint then
					iC1 = Chr:GetAttribute('NO_DIR') and att1.CFrame or att1.CFrame:Lerp(leg2 + Vector3.new(0, math.abs(math.cos(XAng) - 1), math.sin(XAng)), speed)
				else
					iC1 = Chr:GetAttribute('NO_DIR') and i.C1 or i.C1:Lerp(leg2 + Vector3.new(0, math.abs(math.cos(XAng) - 1), math.sin(XAng)), speed)
					task.synchronize()
					pcall(function() i.C1 = iC1 end)
					task.desynchronize()
				end
			end
		end
		
		task.synchronize()
		pcall(function() if isAJUJoint then
			att0.CFrame = iC0
			if iC1 then att1.CFrame = iC1 end
		else
			i.C0 = iC0 
		end end)
	end
end
