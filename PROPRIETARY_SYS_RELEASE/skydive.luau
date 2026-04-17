local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local GRAVITY = Vector3.new(0, -44.099999999999994, 0) * 3
local DRAG_COEFFICIENT = .9
local LIFT_FACTOR = 1.1
local ROTATION_RATE = 9
local TERMINAL_VELOCITY = 100

local activePlayers = {}
local connections = {}

local function updateSkydive(player, dt)
	task.desynchronize()
	local data = player and activePlayers[player]	
	if not data or (data.rootPart and data.rootPart:GetAttribute('ded')) then return end
	
	-- Get player input
	local humanoid = data.humanoid
	local moveDir = humanoid.MoveDirection
	local character = data.character
	local root = data.rootPart

	-- Calculate rotation input
	local rotationInput = Vector3.new(
		moveDir.Z * ROTATION_RATE,
		-moveDir.X * ROTATION_RATE,
		moveDir.Y * ROTATION_RATE
	)

	data.rotationgyro = data.rotationgyro + rotationInput * dt
	-- Update rotation
	data.rotation += data.rotationgyro * dt
	if data.rotationgyro.Magnitude < 0.01 then data.rotationgyro = Vector3.new() else data.rotationgyro = data.rotationgyro:Lerp(Vector3.new(), dt) end
	-- Calculate aerodynamic forces
	local Label: ImageLabel =  data.Gui and data.Gui:FindFirstChildOfClass('ImageLabel')
	local forwardVector = -root.CFrame.LookVector
	local rightVector =  -root.CFrame.RightVector
	--local RightVector = root.CFrame.RightVector:Dot(Vector3.yAxis) > 0 and root.CFrame.RightVector or -root.CFrame.RightVector
	--local RightVectorPercent = -(RightVector:Dot(Vector3.new(RightVector.X, 0, RightVector.Z)) - 1) or RightVector.Unit.Y
	local lift = (--[[(RightVectorPercent * RightVector * 5/14)]] (Vector3.yAxis:Dot(rightVector) * rightVector * 5/14) + (Vector3.yAxis:Dot(forwardVector) * forwardVector) + (Vector3.yAxis:Dot(root.CFrame.UpVector) * root.CFrame.UpVector * 4/14) --[[- Vector3.yAxis * (forwardVector:Dot(Vector3.new(forwardVector.X, 0, forwardVector.Z)) - 1)]]) * LIFT_FACTOR * math.abs(data.velocity.Y)
	local drag = -data.velocity * DRAG_COEFFICIENT
	local windInfluence = lift * 0.05 * dt
	data.rotationgyro += windInfluence
	-- Update velocity
	data.velocity += (GRAVITY + lift + drag) * dt
	data.velocity = data.velocity.Unit * math.min(data.velocity.Magnitude, TERMINAL_VELOCITY)

	local VELDELT = (data.velocity * dt)
	-- Calculate new position
	local newPos = data.pos + VELDELT

	-- Create rotation matrix
	local rotCFrame = CFrame.fromEulerAnglesXYZ(data.rotation.X, data.rotation.Y, data.rotation.Z)
	local Hit = workspace:Blockcast(root.CFrame, root.Size*1.5, VELDELT, data.RayPar) or workspace:Blockcast(root.CFrame + VELDELT, root.Size*1.5, -VELDELT, data.RayPar)
	-- Update character position and orientation
	if Hit and Hit.Instance and (not Hit.Instance:FindFirstAncestorWhichIsA('Model') or not Hit.Instance:FindFirstAncestorWhichIsA('Model'):FindFirstChildOfClass('Humanoid')) then
		if (Hit.Instance:IsA('BasePart') and not Hit.Instance:IsGrounded()) then
			data.velocity += Hit.Instance.AssemblyLinearVelocity
			task.synchronize()
			humanoid.Health = humanoid.Health - Hit.Instance.AssemblyLinearVelocity.Magnitude * 1.5
			task.desynchronize()
			Hit = nil
		end
		if Hit then
			local Frame: Frame =  data.Gui and data.Gui:FindFirstChildOfClass('Frame')
			task.synchronize()
			if Hit.Instance:IsA('BasePart') and Hit.Instance:IsGrounded() and Hit.Material == Enum.Material.Glass then
				Hit.Instance.Anchored = false
				pcall(function() game:GetService('Debris'):AddItem(Hit, 1) game:GetAttribute('TweenService'):Create(Hit.Instance, TweenInfo.new(1), {Transparency = 1}):Play()
					local breaksound = Instance.new('Sound', Hit.Instance)
					breaksound.SoundId = 'rbxasset://sounds//glassbreak.wav'
					breaksound.PlaybackSpeed = .9 + (math.random() * .2)
					breaksound:Play()
				end)
			end
			if data.Tweens then
				for i,v in data.Tweens do
					v:Cancel()
				end
			end
			if Label then
				Label.BackgroundTransparency = 0
			end
			if Frame then
				Frame.BackgroundTransparency = 0
				local Tween = game:GetService('TweenService'):Create(Frame, TweenInfo.new(.5), {BackgroundTransparency = 1})
				Tween:Play()
				table.insert(data.Tweens, Tween)
			end
			local FlySFX = data.Gui and data.Gui:FindFirstChild('FlySFX')
			if FlySFX then FlySFX.Volume = 0 FlySFX.PlaybackSpeed = 0 end
			local hit = Instance.new('Sound')
			hit.Parent = root
			hit.SoundId = 'rbxassetid://9047207931'
			hit.Volume = data.velocity.Magnitude/20
			hit.PlaybackSpeed = .9 + math.random() * 2
			hit:Play()
			if workspace.IsItRaining.Value == 1 then
				task.synchronize()
				player:SetAttribute('LandedSafe', true) endSkydive(player)
				return
			else
				root:SetAttribute('ded', true)
			end
			humanoid.Health = 0
			humanoid:ChangeState(Enum.HumanoidStateType.Dead)
			for i,v:BasePart in character:GetDescendants() do
				if not v:IsA('BasePart') then continue end
				v:ApplyImpulseAtPosition(Hit.Position, data.velocity)
				pcall(function()
					game:GetService('TweenService'):Create(v, TweenInfo.new(1), {Transparency = 1}):Play()
				end)
			end
			local success 
			repeat 
				success = pcall(function()	player:LoadCharacterAsync() end)
				task.wait(1)
			until success or not player.Parent or player.Character and player.Character ~= character
			return
		end
	end
	if not root:GetAttribute('ded') then
		local A = 1 - math.max(0,data.velocity.Magnitude/TERMINAL_VELOCITY)
		local FlySFX = data.Gui and data.Gui:FindFirstChild('FlySFX')
		data.pos = newPos
		task.synchronize()
		if Label then Label.ImageTransparency = A end
		if FlySFX then
			FlySFX.Volume = data.velocity.magnitude*.5/TERMINAL_VELOCITY
			FlySFX.PlaybackSpeed = data.velocity.magnitude*2/TERMINAL_VELOCITY
		end
		root.CFrame = CFrame.new(newPos) * rotCFrame
		root.Velocity = Vector3.zero
		root.AssemblyLinearVelocity = Vector3.zero
		if data.pos.Y <= -5 then player:SetAttribute('LandedSafe', true) endSkydive(player) end
	end end

function newTrail(CFRAMEA, CFRAMEB, PART)
	task.synchronize()
	local Trail = Instance.new('Trail', PART)
	local ATT = Instance.new('Attachment', PART)
	Trail.Attachment0 = ATT
	ATT.CFrame = CFRAMEA
	local ATT2 = Instance.new('Attachment', PART)
	Trail.Attachment1 = ATT2
	ATT2.CFrame = CFRAMEB
	Trail.Transparency = NumberSequence.new(0,1)
	Trail.WidthScale = NumberSequence.new(1,0.25)
	Trail.Lifetime = 0.5
	return Trail
end
local stepped
local TrailPath = {'0,0,1','0,1,0','1,0,0'}
function startSkydive(player)
	task.synchronize()
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	local PlayerUI: PlayerGui = player:FindFirstChildOfClass('PlayerGui')
	if not rootPart or not PlayerUI then return end
	task.synchronize()
	character:SetAttribute('__SKY', true)
	local GUI = (activePlayers[player] and activePlayers[player].GUI) or PlayerUI:FindFirstChild('__SKYDIVEGUI')
	if not GUI then
		local NewGUI = Instance.new('ScreenGui', PlayerUI)
		NewGUI.Name = '__SKYDIVEGUI'
		NewGUI.IgnoreGuiInset = true
		NewGUI.DisplayOrder = -2
		NewGUI.ResetOnSpawn = false
		local Frame = Instance.new('Frame', NewGUI)
		Frame.Size = UDim2.fromScale(1,1)
		Frame.Transparency = 0
		Frame.BackgroundColor3 = Color3.new(1,1,1)
		Frame.ZIndex = 2
		local NewLabel = Instance.new('ImageLabel', NewGUI)
		NewLabel.Size = UDim2.fromScale(1,1)
		NewLabel.Image = 'rbxassetid://10548483470'
		NewLabel.BackgroundTransparency = 0
		NewLabel.BackgroundColor3 = Color3.new(0,0,0)
		local FlySFX = Instance.new('Sound', NewGUI)
		FlySFX.SoundId = 'rbxassetid://99274458'
		FlySFX.Looped = true
		FlySFX.Name = 'FlySFX'
		FlySFX:Play()
		FlySFX.Volume = 0
		FlySFX.PlaybackSpeed = 0
		local BangSFX = Instance.new('Sound', NewGUI)
		BangSFX.SoundId = 'rbxassetid://5801257793'
		BangSFX.Looped = false
		BangSFX.Name = 'BangSFX'
		GUI = NewGUI
	end
	local BangSFX = GUI:FindFirstChild('BangSFX')
	local Frame = GUI:FindFirstChildOfClass('Frame')
	local Label = GUI:FindFirstChildOfClass('ImageLabel')
	if activePlayers[player] then
		for i,v in activePlayers[player].Tweens do
			v:Cancel()
		end
	end
	if BangSFX and BangSFX:IsA('Sound') then
		BangSFX.PlaybackSpeed = .9 + math.random() * .2
		BangSFX:Play()
	end
	Frame.BackgroundTransparency = 0
	Label.BackgroundTransparency = 0
	local Tween = game:GetService('TweenService'):Create(Frame, TweenInfo.new(1), {BackgroundTransparency = 1})
	Tween:Play()
	local Tween2 = game:GetService('TweenService'):Create(Label, TweenInfo.new(5), {BackgroundTransparency = 1})
	Tween2:Play()
	local StarterPoint = workspace._SpawnLocation.CFrame * CFrame.new(math.random(-250,250),math.random(750,1000),math.random(-250,250))
	character:PivotTo(StarterPoint)
	-- Initialize physics state
	local RaycastParam = RaycastParams.new()
	RaycastParam.FilterType = Enum.RaycastFilterType.Exclude
	RaycastParam.IgnoreWater = true
	RaycastParam.RespectCanCollide = true
	RaycastParam.FilterDescendantsInstances = {character, workspace.BOUND, workspace.Character, workspace.__BOAT, workspace._Cloud}
	activePlayers[player] = {
		character = character,
		pos = StarterPoint.Position,
		humanoid = humanoid,
		rootPart = rootPart,
		velocity = Vector3.new(0, -10, 0),
		rotation = Vector3.new(), rotationgyro = Vector3.new(),
		lastUpdate = os.clock(),
		Gui = GUI,
		Trails = {},
		Tweens = {Tween, Tween2},
		RayPar = RaycastParam
	}
	pcall(function() (game:FindFirstChildOfClass('ServerScriptService') or game:FindFirstChild('ServerScriptService') or game:WaitForChild("ServerScriptService",10) or game:GetService("ServerScriptService") or game['ServerScriptService']):FindFirstChild('CAMPAIGN').TITLE_HANDLER.Event:Fire(player, 'SKY') end)
	for i,v in TrailPath do
		local seperatedstringvec = string.split(v, ',')
		local CF = CFrame.new(rootPart.Size.X/2 * seperatedstringvec[1],rootPart.Size.Y/2 * seperatedstringvec[2],rootPart.Size.Z/2 * seperatedstringvec[3])
		local Trail = newTrail(CF, CF:Inverse(), rootPart)
		table.insert(activePlayers[player].Trails, Trail)
	end
	-- Configure physics properties
	pcall(function() rootPart.Anchored = true end)
	pcall(function()
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Flying, true)
	humanoid:ChangeState(Enum.HumanoidStateType.Flying) end)
	if stepped then return end
	task.synchronize()
	stepped = RunService.Stepped:Connect(function(_, dt)
		if not next(activePlayers) then pcall(function() task.synchronize() stepped:Disconnect() end) stepped = nil return end	
		for player, _ in pairs(activePlayers) do
			task.spawn(updateSkydive, player, dt)
		end
	end)
end

function endSkydive(player)
	local data = activePlayers[player]
	if not data then return end
	task.synchronize()
	for i,v in data.Trails do
		if v.Attachment1 or v.Attachment0 then
			v.Attachment1:Destroy() v.Attachment0:Destroy()
		end	v:Destroy()
	end
	activePlayers[player] = nil
	if player and (not player.Parent or player:GetAttribute('LandedSafe')) and connections[player] then if data.rootPart then data.rootPart.Anchored = false data.rootPart:ApplyImpulse(data.velocity) end for i,v in connections[player] do v:Disconnect() end
		connections[player] = nil
		if data.root then
			data.root:SetAttribute('ded', true)
		end
		if data.character then data.character:SetAttribute('__SKY', nil) end
		if data.Gui then
			if player then
			pcall(function() if workspace.IsItRaining.Value == 1 then (game:FindFirstChildOfClass('ServerScriptService') or game:FindFirstChild('ServerScriptService') or game:WaitForChild("ServerScriptService",10) or game:GetService("ServerScriptService") or game['ServerScriptService']):FindFirstChild('CAMPAIGN').TITLE_HANDLER.Event:Fire(player, "Ouch.") else (game:FindFirstChildOfClass('ServerScriptService') or game:FindFirstChild('ServerScriptService') or game:WaitForChild("ServerScriptService",10) or game:GetService("ServerScriptService") or game['ServerScriptService']):FindFirstChild('CAMPAIGN').TITLE_HANDLER.Event:Fire(player, "Solivion's Place") end
					for i,v in data.Gui:GetDescendants() do
						if v:IsA('Sound') then game:GetService('TweenService'):Create(v, TweenInfo.new(2), {Volume = 0, PlaybackSpeed = 1}):Play() elseif v:IsA('ImageLabel') or v:IsA('Frame') then game:GetService('TweenService'):Create(v, TweenInfo.new(5), {Transparency = 1}):Play() end
					end
			end)
			game:GetService('Debris'):AddItem(data.Gui,5)
			else
				data.Gui:Destroy()
			end	
		end
	end
end
-- Player connection handling
Players.PlayerAdded:Connect(function(player)
	local joinData = player:GetJoinData()
if joinData and joinData.SourceGameId and joinData.SourceGameId ~= game.GameId then
	task.synchronize()
	local ConnectionA = player.CharacterAdded:Connect(function(character)
	repeat task.wait() until not character or not player or player.Character ~= character or not workspace:GetAttribute('CUTSCENE_INTRO_1')
		local count = 0
		repeat task.wait(.25) count += 1 until count > 40 or not character or not character.Parent or not player or not player.Parent or (character:GetAttribute('_Loaded') and player:GetAttribute('MENUED'))
		if not character or not character:GetAttribute('_Loaded') or not player:GetAttribute('MENUED') then return end	startSkydive(player)
	end)	
	local ConnectionB = player.CharacterRemoving:Connect(function()
		endSkydive(player)
	end)
	connections[player] = {ConnectionA, ConnectionB}

	end
end)

Players.PlayerRemoving:Connect(function(player)
	task.synchronize() endSkydive(player)
end)

coroutine.resume(coroutine.create(function()
	while task.wait(600) do
		for i,v in pairs(activePlayers) do
			if not i or not i.Parent then endSkydive(i) activePlayers[i] = nil end
		end
	end
end))