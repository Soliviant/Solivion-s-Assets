-- Server-Sided Ragdoll Handler (Complete with All Features)
-- Place in ServerScriptService
-- Create a BindableEvent named "Trigger" as a child of this script

local map = workspace.Map or workspace:WaitForChild('Map')
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

-- Configuration
local CONFIG = {
	CREDIT_NAME = 'Soli',
	RAGDOLL_TOOL_UNEQUIP_TIME = 60,
	UNDERWATER_DAMAGE_RATE = 4/3, -- damage per second underwater
	BREATHING_BLOCKED_DAMAGE_RATE = 10/9, -- damage per second when breathing blocked
	FALL_DAMAGE_THRESHOLD = 50, -- studs
	FALL_DAMAGE_MULTIPLIER = 2,
	MAX_FALL_DAMAGE = math.huge,
	DEATH_CLEANUP_TIME = 30,
	PERMANENT_RAGDOLL_CLEANUP_TIME = {30, 60}, -- random between these values
	VOLUME_MASTER = 1, -- Master volume multiplier
	DEATH_SFX_ENABLED = true,
}

-- Sound IDs
local SOUNDS = {
	FLOOR_IMP = 18195447789,
	FLOOR_IMP_ALT = 18195447581,
	DEATH_SFX = "rbxassetid://1080610827",
	DEATH_SFX_ALT = "rbxassetid://5195087640",
	SCREAM_SFX = "rbxassetid://9081160607",
	DEATH_SFX_GENERAL = "rbxassetid://5195087640"
}

-- Global variables
local activeRagdolls = {}
local ragdollData = {}
local ragdollTimers = {}
local ragdollCoroutines = {}
local characterCleanupHandlers = {}
local originalHipHeights = {}
local fallVelocities = {}

local characterRemoveProcessors = {}
local ragdollWasOnStates = {}

-- Timer loop control
local isLoopRunning = false
local activeRagdollCount = 0

-- Raycast parameters
local raybloxk = RaycastParams.new()
raybloxk.IgnoreWater = false
raybloxk.RespectCanCollide = true
raybloxk.FilterType = Enum.RaycastFilterType.Exclude

-- Utility functions
function isValidCharacter(character)
	return character and character.Parent and character:FindFirstChildOfClass("Humanoid") and character:FindFirstChild("HumanoidRootPart") and character.Parent ~= map
end

function playSound(soundId, parent, volume)
	if not parent then return end

	local sound = Instance.new("Sound")
	sound.Parent = parent
	sound.SoundId = typeof(soundId) == "string" and soundId or "rbxassetid://" .. tostring(soundId)
	sound.Volume = (volume or 0.5) * CONFIG.VOLUME_MASTER
	sound.PlaybackSpeed = math.random(80, 120) / 100
	sound:Play()

	sound.Ended:Connect(function()
		sound:Destroy()
	end)
end

function getCharacterMass(character)
	local mass = 0
	for _, part in pairs(character:GetChildren()) do
		if part:IsA("BasePart") then
			mass = mass + part.Mass
		end
	end
	return mass
end

-- Enhanced joint creation with all constraint types
function createRagdollJoints(character)
	local joints = {}
	local constraints = {}
	local originalStates = {}

	-- Use parallel processing for descendants
	local descendants = character:GetDescendants()
	local jointsToProcess = {}
	local partsToProcess = {}
	local scriptsToProcess = {}
	local toolsToProcess = {}
	local weldsToProcess = {}
	local ntpt = pcall(function() if script.Parent.Parent.ToolPerm.Signal:IsA("BindableEvent") then end end)
	ntpt = not (ntpt ~= nil) -- inverse condit
	--short for "need to process tool"
	
	-- Categorize descendants for parallel processing
	task.desynchronize()
	for _, descendant in pairs(descendants) do
		pcall(function()
			if descendant.ClassName:lower():match('motor6d') then
				table.insert(jointsToProcess, descendant)
			elseif descendant:IsA("BasePart") and descendant.Parent == character then
				table.insert(partsToProcess, descendant)
			elseif descendant:IsA("Script") and descendant ~= script and not (ntpt and script:FindFirstAncestorWhichIsA('Tool')) then
				table.insert(scriptsToProcess, descendant)
			elseif ntpt and descendant:IsA("Tool") then
				table.insert(toolsToProcess, descendant)
			elseif (descendant:IsA("Weld") or table.find({"Motor", "ManualWeld"},descendant.ClassName)) and descendant.Name ~= 'AccessoryWeld' then
				table.insert(weldsToProcess, descendant)
			elseif descendant:IsA("Highlight") then
				descendant:Destroy()
			end
		end)
	end
	task.synchronize()

	-- Process Motor6Ds in parallel
	task.spawn(function()
		task.desynchronize()
		for _, descendant in pairs(jointsToProcess) do 
			task.desynchronize()
			-- Store original state
			originalStates[descendant] = descendant:GetAttribute('overwritethisone') or descendant.Enabled

			-- Create ball socket constraint
			local socket = Instance.new("BallSocketConstraint")
			local attachment1 = Instance.new("Attachment")
			local attachment2 = Instance.new("Attachment")

			task.synchronize()
			attachment1.Parent = descendant.Part0
			attachment2.Parent = descendant.Part1
			socket.Parent = descendant.Parent
			socket.Attachment0 = attachment1
			socket.Attachment1 = attachment2
			attachment1.CFrame = descendant.C0
			attachment2.CFrame = descendant.C1

			socket.LimitsEnabled = true
			socket.TwistLimitsEnabled = true
			socket.Name = descendant.Name .. "FakeAhhJoints"

			-- Create no collision constraints
			local noCollision1 = Instance.new("NoCollisionConstraint")
			noCollision1.Parent = descendant.Parent
			noCollision1.Part0 = descendant.Part0
			noCollision1.Part1 = descendant.Part1
			noCollision1.Name = descendant.Name

			local noCollision2 = Instance.new("NoCollisionConstraint")
			noCollision2.Parent = descendant.Parent
			noCollision2.Part0 = descendant.Part1
			noCollision2.Part1 = character:FindFirstChild("HumanoidRootPart")
			noCollision2.Name = descendant.Name

			-- Disable the motor6d
			descendant.Enabled = false

			table.insert(constraints, socket)
			table.insert(constraints, attachment1)
			table.insert(constraints, attachment2)
			table.insert(constraints, noCollision1)
			table.insert(constraints, noCollision2)
			table.insert(joints, descendant)
		end
		task.synchronize()
	end)

	-- Process Welds
	task.spawn(function()
		task.desynchronize()
		for _, descendant in pairs(weldsToProcess) do
			local a,b = pcall(function()
				if descendant:GetAttribute('__LOCKWELD') then
					descendant:Destroy()
					return true
				end
			end) if (a and b) or typeof(descendant) ~= 'Instance' then continue end
			pcall(function() originalStates[descendant] = descendant:GetAttribute('Enabled') or descendant.Enabled

			local noCollision = Instance.new("NoCollisionConstraint")
			task.synchronize()
			noCollision.Parent = descendant.Parent
			noCollision.Part1 = descendant.Part1
			noCollision.Part0 = descendant.Part0
			noCollision.Name = descendant.Name

			if descendant:GetAttribute('R_DIS') then
				descendant.Enabled = false
			end

			table.insert(constraints, noCollision) end)
		end
		task.synchronize()
	end)

	-- Process BaseParts in parallel
	task.spawn(function()
		task.desynchronize()
		for _, descendant in pairs(partsToProcess) do
			pcall(function() originalStates[descendant] = descendant.CanCollide
			task.synchronize() 
			descendant.CanCollide = true
				descendant.CanTouch = true end)
		end
		task.synchronize()
	end)

	-- Process Scripts in parallel
	task.spawn(function()
		task.desynchronize()
		for _, descendant in pairs(scriptsToProcess) do
			pcall(function() originalStates[descendant] = descendant:GetAttribute('Enabled') or descendant.Enabled
				task.synchronize() descendant.Enabled = false end)
		end
		task.synchronize()
	end)

	-- Process Tools in parallel
	task.spawn(function()
		task.desynchronize()
		for _, descendant in pairs(toolsToProcess) do 
			pcall(function() originalStates[descendant] = descendant:GetAttribute('Enabled') or descendant.Enabled
				task.synchronize() descendant.Enabled = false end)
		end
	end)

	-- Handle special attributes
	task.spawn(function()
		task.desynchronize()
		for _, descendant in pairs(descendants) do
			pcall(function() if descendant:GetAttribute('R_ENA') then
				task.synchronize()
				descendant.Enabled = true
				end end)
		end
	end)

	return joints, constraints, originalStates
end

function cleanupRagdollConstraints(constraints)
	-- Use parallel processing for constraint cleanup
	task.spawn(function()
		task.desynchronize()
		for _, constraint in pairs(constraints) do
			task.desynchronize()
			pcall(function() if constraint and constraint.Parent then
				if constraint:GetAttribute('R_ENA') then
					task.synchronize()
					constraint.Enabled = false
				else
					task.synchronize() 
					constraint:Destroy()
				end
			end end)
		end
		task.synchronize()
	end)
end

function restoreOriginalStates(character, joints, originalStates)
	-- Use parallel processing for state restoration
	task.spawn(function()
		task.desynchronize()
		for object, originalState in pairs(originalStates) do
			task.desynchronize()
			if object and object.Parent then
				pcall(function()
				if object.ClassName:lower():match('motor6d') or object:IsA("Script") or object:IsA("Tool") or object:IsA("Weld") or table.find({"Motor", "ManualWeld"},object.ClassName) then
						pcall(function() if originalState == true then
						task.synchronize() object:SetAttribute('overwritethisone', nil)  object.Enabled = true
					elseif originalState == false then
						task.synchronize() object.Enabled = false
					end
					if object:GetAttribute('R_DIS') then
						task.synchronize() object.Enabled = true
					end end)
				elseif object:IsA("BasePart") then
					pcall(function() if originalState == true then
						task.synchronize() object.CanCollide = true
					elseif originalState == false then
						task.synchronize() object.CanCollide = false
					end end)
				end end)
			end
		end
		task.synchronize()
	end)
end

function handleFallDamage(character, humanoid)
	task.desynchronize()
	if typeof(character) ~= 'Instance' or character.ClassName ~= 'Model' then return end
	if typeof(humanoid) ~= 'Instance' or humanoid.ClassName ~= 'Humanoid' then return end
	if not fallVelocities[character] then
		fallVelocities[character] = 0
	end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	local velocity = rootPart.Velocity
	local verticalVelocity = math.abs(velocity.Y)

	-- Track maximum fall velocity
	if verticalVelocity > fallVelocities[character] then
		fallVelocities[character] = verticalVelocity
	end
	
	if not character or not character.Parent then return end
	-- Check if we've hit the ground (low vertical velocity after high fall velocity)
	if((rootPart and rootPart.Position.Y or character and character:GetPivot().Y or 0) < -1) or (humanoid and humanoid:GetState() or Enum.HumanoidStateType.Running or {Name = 'Physics'}).Name:upper():match('SWIMMING') then
		fallVelocities[character] = 0
	else
	if fallVelocities[character] > CONFIG.FALL_DAMAGE_THRESHOLD and verticalVelocity < 5 then
		local fallDistance = (fallVelocities[character] - CONFIG.FALL_DAMAGE_THRESHOLD) / 4
		local damage = math.min(fallDistance * CONFIG.FALL_DAMAGE_MULTIPLIER, CONFIG.MAX_FALL_DAMAGE)

		if damage > 0 then
			pcall(function()
			local feinhealth = math.max(0, humanoid.Health - damage)
			local soundId = math.random() > 0.5 and SOUNDS.FLOOR_IMP or SOUNDS.FLOOR_IMP_ALT
			task.synchronize()
			if rootPart.Position.Y > -1 then
				humanoid.Health = feinhealth

				-- Play impact sound
				playSound(soundId, rootPart, 0.3)
			else
				playSound(142431247, rootPart, 0.3)
			end
			end)
		end

		fallVelocities[character] = 0
	end end
end

function checkUnderwater(character, humanoid)
	local head = character:FindFirstChild("Head")
	if not head then return true end

	return character:GetPivot().Y < -1
end

function checkBreathingBlocked(character, humanoid)
	local head = character:FindFirstChild("Head")
	if not head then return false end

	-- Cast rays in multiple directions from head
	task.synchronize()
	raybloxk.FilterDescendantsInstances = {character}
	task.desynchronize()
	local result = workspace:Raycast(head.Position, head.CFrame.LookVector * head.Size.Z/1.8, raybloxk)
	if result then
		return true
	end
	return false
end

function stopTimerLoop()
	isLoopRunning = false
end

-- Enhanced timer loop with fall damage
function startTimerLoop()
	if isLoopRunning then return end
	isLoopRunning = true

	task.spawn(function()
		while isLoopRunning do
			task.desynchronize()
			local deltaTime = task.wait(0.025)
			local charactersToRemove = {}
			local hasActiveRagdolls = false

			for character, timeLeft in pairs(ragdollTimers) do
				task.desynchronize()
				if not isValidCharacter(character) then
					table.insert(charactersToRemove, character)
					continue
				end

				hasActiveRagdolls = true
				local humanoid = character:FindFirstChildOfClass("Humanoid")

				-- Fall damage, breathing/underwater checks
				if humanoid and humanoid.Health > 0 then
					handleFallDamage(character, humanoid)

					local isUnderwater = checkUnderwater(character, humanoid)
					local isBreathingBlocked = checkBreathingBlocked(character, humanoid)
					local hp = humanoid.Health	
					if isUnderwater then
						hp = math.max(0, humanoid.Health - CONFIG.UNDERWATER_DAMAGE_RATE * humanoid.MaxHealth/100 * deltaTime)
					elseif isBreathingBlocked then
						hp = math.max(0, humanoid.Health - CONFIG.BREATHING_BLOCKED_DAMAGE_RATE * humanoid.MaxHealth/100 * deltaTime)
					end
					if (hp - humanoid.Health) > .05 then 
						task.synchronize()   
						humanoid.Health = hp 
						task.desynchronize() 
					end
				end

				-- Timer logic
				if timeLeft >= math.huge then
					-- Permanent ragdoll, skip but count as active
					continue
				end

				ragdollTimers[character] = timeLeft - deltaTime

				if ragdollTimers[character] <= 0 then
					-- Create unragdoll coroutine
					ragdollCoroutines[character] = task.spawn(function()
						unragdollCharacter(character)
						ragdollCoroutines[character] = nil
					end)
				end
			end
			task.synchronize()

			-- Clean up invalid characters
			for _, character in pairs(charactersToRemove) do
				cleanupRagdoll(character)
			end

			-- Stop timer loop if no active ragdolls
			if not hasActiveRagdolls then
				stopTimerLoop()
			end
		end
	end)
end

function updateActiveRagdollCount()
	activeRagdollCount = 0
	for _ in pairs(activeRagdolls) do
		activeRagdollCount = activeRagdollCount + 1
	end
end

function ragdollCharacter(character, ragdollTime)
	if not isValidCharacter(character) or character.Parent == map or (character.Parent and character.Parent.Name == 'Shop_1') then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	-- Enhanced validation checks
	if character:GetAttribute('PermRag') or 
		(humanoid.Health <= 0 or humanoid:GetState() == Enum.HumanoidStateType.Dead) and character:GetAttribute('IsRagdoll') then
		return
	end

	-- Check if already ragdolled and extend time
	if activeRagdolls[character] then
		if ragdollTimers[character] then
			ragdollTimers[character] = ragdollTimers[character] + ragdollTime
		end
		return
	end

	-- Store original hip height
	originalHipHeights[character] = humanoid.HipHeight

	-- Mark as ragdolled
	activeRagdolls[character] = true
	task.synchronize()
	character:SetAttribute("IsRagdoll", true)
	task.desynchronize()
	ragdollTimers[character] = ragdollTime

	-- Start timer loop if this is the first ragdoll
	if not isLoopRunning then
		startTimerLoop()
	end

	task.synchronize()
	script.Parent.Parent.ToolPerm.Signal:Fire(character, false)
	-- Configure humanoid for ragdoll
	humanoid.RequiresNeck = false
	humanoid.BreakJointsOnDeath = false
	humanoid.EvaluateStateMachine = false
	humanoid.AutoRotate = false
	humanoid.HipHeight = 0

	-- Enhanced state management
	if humanoid.Health ~= humanoid.Health or humanoid.Health <= 0 then
		ragdollTime = math.huge
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
		humanoid:ChangeState(Enum.HumanoidStateType.Dead)
	else
		humanoid:ChangeState(Enum.HumanoidStateType.Physics)
	end

	-- Disable various states
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Running, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)

	-- Handle tools with enhanced logic
	if ragdollTime > CONFIG.RAGDOLL_TOOL_UNEQUIP_TIME then
		local tool = character:FindFirstChildOfClass("Tool")
		if tool and tool:FindFirstChild("Handle") then
			tool.Parent = workspace
		end
		humanoid:UnequipTools()
	end

	-- Create ragdoll joints (using parallel processing)
	local joints, constraints, originalStates = createRagdollJoints(character)

	-- Store ragdoll data
	ragdollData[character] = {
		joints = joints,
		constraints = constraints,
		originalStates = originalStates,
		startTime = tick()
	}
	
	local no= false
	local function bruh() task.desynchronize() if no then return else no = true end
		-- Handle current animations

		ragdollTimers[character] = math.huge
		task.synchronize()
		character:SetAttribute("PermRag", true)

		-- Play appropriate death sound
		local rootPart = character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart
		if rootPart and CONFIG.DEATH_SFX_ENABLED then
			if character.Name == CONFIG.CREDIT_NAME then
				local soundId = math.random() > 0.5 and SOUNDS.DEATH_SFX or SOUNDS.DEATH_SFX_ALT
				playSound(soundId, rootPart, 0.3)
			else
				playSound(SOUNDS.SCREAM_SFX, rootPart, 0.5)
			end
		end

		-- Schedule cleanup
		local cleanupTime = math.random(CONFIG.PERMANENT_RAGDOLL_CLEANUP_TIME[1], CONFIG.PERMANENT_RAGDOLL_CLEANUP_TIME[2])
		Debris:AddItem(character, cleanupTime)
		if characterCleanupHandlers[character] then 
			task.synchronize()
			characterCleanupHandlers[character]:Disconnect()
			characterCleanupHandlers[character] = nil
		end

		if characterRemoveProcessors[character] then
			task.synchronize()
			characterRemoveProcessors[character]:Disconnect()
			characterRemoveProcessors[character] = nil
		end

		ragdollData[character] = nil
		-- Clean up timers and states
		activeRagdolls[character] = nil
		ragdollTimers[character] = nil
		originalHipHeights[character] = nil
		fallVelocities[character] = nil
		ragdollWasOnStates[character] = nil
	end
	-- Enhanced death handling
	local deathConnection = humanoid.Died:Once(bruh)
	local deathConnection2 = character:GetAttributeChangedSignal('permaded'):Once(bruh)
	
	-- Store cleanup handler
	characterCleanupHandlers[character] = deathConnection
	characterRemoveProcessors[character] = deathConnection2

	-- Handle character removal
	local ancestryConnection = character.AncestryChanged:Connect(function()
		if not character.Parent then
			cleanupRagdoll(character)
		end
	end)

	if not ragdollData[character] then
		ragdollData[character] = {}
	end
	ragdollData[character].ancestryConnection = ancestryConnection
end

function cleanupRagdoll(character, nocon)
	task.desynchronize()
	if not character then return end

	-- Clean up timers and states
	activeRagdolls[character] = nil
	ragdollTimers[character] = nil
	originalHipHeights[character] = nil
	fallVelocities[character] = nil
	ragdollWasOnStates[character] = nil

	-- Clean up connections
	if characterCleanupHandlers[character] then 
		task.synchronize()
		pcall(function()	characterCleanupHandlers[character]:Disconnect() end)
		characterCleanupHandlers[character] = nil
	end

	if characterRemoveProcessors[character] then
		task.synchronize()
		pcall(function()	characterRemoveProcessors[character]:Disconnect() end)
		characterRemoveProcessors[character] = nil
	end

	-- Clean up ragdoll data
	if ragdollData[character] then
		task.synchronize()
		if ragdollData[character].constraints and not nocon then
			cleanupRagdollConstraints(ragdollData[character].constraints)
		end

		if ragdollData[character].ancestryConnection then
			ragdollData[character].ancestryConnection:Disconnect()
		end

		ragdollData[character] = nil
	end

	task.desynchronize()

	-- Clean up coroutines
	if ragdollCoroutines[character] then
		-- Don't try to cancel, just clear the reference
		ragdollCoroutines[character] = nil
	end
end

function unragdollCharacter(character)
	if not isValidCharacter(character) then
		cleanupRagdoll(character)
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		cleanupRagdoll(character)
		return
	end

	-- Don't unragdoll if permanently ragdolled
	if character:GetAttribute("PermRag") then
		return
	end

	local data = ragdollData[character]
	if not data then
		cleanupRagdoll(character)
		return
	end

	-- Restore original states (using parallel processing)
	if data.originalStates then
		restoreOriginalStates(character, data.joints, data.originalStates)
	end

	-- Clean up constraints (using parallel processing)
	if data.constraints then
		cleanupRagdollConstraints(data.constraints)
	end

	-- Enhanced humanoid restoration
	task.synchronize()
	humanoid.RequiresNeck = false
	humanoid.AutoRotate = true
	humanoid.EvaluateStateMachine = true
	humanoid.HipHeight = originalHipHeights[character] or 2

	-- Re-enable states
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Running, true)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)

	-- Change back to running state
	humanoid:ChangeState(Enum.HumanoidStateType.Running)

	-- Remove ragdoll attribute
	character:SetAttribute("IsRagdoll", nil)
	script.Parent.Parent.ToolPerm.Signal:Fire(character, true)
	
	-- Clean up
	cleanupRagdoll(character)
end

-- Enhanced bindable event connection with better validation
script.Trigger.Event:Connect(function(character, ragdollTime)
	task.desynchronize()
	if not isValidCharacter(character) then
		warn("Invalid character passed to ragdoll handler")
		return
	end

	if not ragdollTime or ragdollTime <= 0 then
		warn("Invalid ragdoll time passed to ragdoll handler")
		return
	end

	local humanoid = character:FindFirstChildOfClass('Humanoid')
	if not humanoid or 
		character:GetAttribute('PermRag') or 
		((humanoid.Health <= 0 or humanoid:GetState() == Enum.HumanoidStateType.Dead) and character:GetAttribute('IsRagdoll')) then 
		return 
	end

	ragdollCharacter(character, ragdollTime)
end)

-- Enhanced player cleanup
Players.PlayerRemoving:Connect(function(player)
	if player.Character then
		cleanupRagdoll(player.Character)
	end
end)

-- Additional cleanup for character spawning
Players.PlayerAdded:Connect(function(player)
	player.CharacterRemoving:Connect(function(character)
		cleanupRagdoll(character)
	end)
end)

-- Periodic cleanup function to remove invalid or lingering ragdoll entries

	while script and script.Parent do
		task.wait(60) -- Run every 60 seconds
		local toCleanup = {}

		-- Check all ragdoll-related tables for invalid characters
		for character in pairs(activeRagdolls) do
			if not isValidCharacter(character) then
				table.insert(toCleanup, character)
			end
		end
		for character in pairs(ragdollTimers) do
			if not isValidCharacter(character) then
				table.insert(toCleanup, character)
			end
		end
		for character in pairs(ragdollData) do
			if not isValidCharacter(character) then
				table.insert(toCleanup, character)
			end
		end
		for character in pairs(characterCleanupHandlers) do
			if not isValidCharacter(character) then
				table.insert(toCleanup, character)
			end
		end
		for character in pairs(originalHipHeights) do
			if not isValidCharacter(character) then
				table.insert(toCleanup, character)
			end
		end
		for character in pairs(fallVelocities) do
			if not isValidCharacter(character) then
				table.insert(toCleanup, character)
			end
		end
		for character in pairs(characterRemoveProcessors) do
			if not isValidCharacter(character) then
				table.insert(toCleanup, character)
			end
		end
		for character in pairs(ragdollWasOnStates) do
			if not isValidCharacter(character) then
				table.insert(toCleanup, character)
			end
		end

		-- Remove duplicates
		local seen = {}
		local uniqueToCleanup = {}
		for _, character in pairs(toCleanup) do
			if not seen[character] then
				seen[character] = true
				table.insert(uniqueToCleanup, character)
			end
		end

		-- Cleanup
		for _, character in pairs(uniqueToCleanup) do
			cleanupRagdoll(character)
		end
	end

-- Start the periodic cleanup in the background

