local castparams = RaycastParams.new()
castparams.IgnoreWater = true
castparams.RespectCanCollide = false
castparams.BruteForceAllSlow = true
local CreditName = 'Soli'
local Soundcloud: {number} = {FLOOR_IMP = 18195447789, FLOOR_IMP_ALT = 18195447581}
local ragdolldatas: {[Model?]: {any}} = {}
local ragdolldatas2: {[Model?]: {any}} = {}
local ragdolldatas3: {[Model?]: {any}} = {}
local ragdollcoroutessolver: {[Model?]: thread} = {}
local Ragtimeengine: RBXScriptConnection?
local RagdollCountdowner = {}
local CharRemoveProcessor = {}
local RagdollTimeThatWillForceUnequipTool = 60
local HasRagdoll = workspace.Name:upper() == 'VIPSERVER'
local CurrentAnimation = {}
local Debris = game:FindFirstChildOfClass('Debris')
if workspace.Name:upper() ~= 'VIPSERVER' then
	workspace:GetPropertyChangedSignal('Name'):Once(function()
		HasRagdoll = (workspace:FindFirstChild('Fun') and workspace:FindFirstChild('Fun').Value < 950) or workspace.Name:upper() == 'VIPSERVER'
	end)
end
local hipheights: {[Model?]: number} = {}
function sync() if script:GetActor() then task.synchronize() end end
function unsync() if script:GetActor() then task.desynchronize() end end
function Ragdoll(Who: Model, RagdollTime: number)
	if not HasRagdoll then return end
	unsync()
	if Who and (Who:GetAttribute('PermRag') or RagdollCountdowner[Who] and RagdollCountdowner[Who] >= math.huge) then if not Who:GetAttribute('PermRag') then sync() Who:SetAttribute('PermRag', true) end RagdollCountdowner[Who] = nil return end
	pcall(function() if Who:FindFirstChildOfClass('Humanoid') and (RagdollTime > RagdollTimeThatWillForceUnequipTool or (RagdollCountdowner[Who] and RagdollCountdowner[Who] > RagdollTimeThatWillForceUnequipTool)) then local istool = Who:FindFirstChildOfClass('Tool') sync() if istool and istool:FindFirstChild('Handle') then istool.Parent = workspace end Who:FindFirstChildOfClass('Humanoid'):UnequipTools() end end)
	sync() game:GetService("ServerScriptService"):FindFirstChild('Standalone Systems'):FindFirstChild("Ragdoll").Trigger:Fire(Who, RagdollTime)
end
function PlaySound(SoundName,ToWhere: Instance?)
	sync()
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
			sound.Volume = .05
			sound.SoundId = typeof(Soundcloud[SoundName]) == 'string' and Soundcloud[SoundName] or 'http://www.roblox.com/asset/?id='..tostring(Soundcloud[SoundName])
			sound.Name = SoundName
			sound:Play()
		else
			warn("Sound >"..SoundName.."< Not Found In Database")
		end
	end
end
local function Init_Fall(Who: Model)
	task.desynchronize()

	if not (Who:IsA("Model") and Who:FindFirstChildOfClass("Humanoid")) then
		return
	end

	local humanoid = Who:FindFirstChildOfClass("Humanoid")
	local root = Who:FindFirstChild('HumanoidRootPart') or humanoid.RootPart or Who.PrimaryPart or Who:FindFirstChild("Torso")

	-- Wait for root part if not found
	if not root then
		local timeout = 0
		while Who and not root and Who.Parent and timeout < 10 do
			timeout += task.wait()
			root = Who:FindFirstChild('HumanoidRootPart') or humanoid.RootPart or Who.PrimaryPart or Who:FindFirstChild("Torso")
		end
		if not root then return end
	end

	-- Validate components exist
	if not (Who and Who.Parent and humanoid and root) then
		return
	end

	-- Fall tracking variables
	local fallenCFrame = Who:GetPivot()
	local falling = false
	local highestVelo = 0
	local connections = {}

	-- Cleanup function
	local function cleanup()
		for _, connection in connections do
			if connection then
				connection:Disconnect()
			end
		end
		table.clear(connections)
	end

	-- Reset fall state
	local function resetFall()
		falling = false
		highestVelo = 0
		fallenCFrame = Who:GetPivot()
	end

	-- Check if should cancel fall (climbing/swimming)
	local function shouldCancelFall()
		return humanoid:GetState() == Enum.HumanoidStateType.Climbing or 
			(humanoid:GetState() == Enum.HumanoidStateType.Swimming and root.Position.Y <= 1) or root.Position.Y <= -1
	end

	-- Apply fall damage
	local function applyFallDamage()
		if not (Who and humanoid and root) then return end

		local fallDistance = fallenCFrame.Position.Y - Who:GetPivot().Position.Y
		pcall(function()
			if typeof(Who:GetAttribute('__Landtime')) == 'number' then -- press the land button
				fallDistance = fallDistance / ((.51 - math.clamp(Who:GetAttribute('__Landtime'), 0, 0.5)) * 10)
			end
		end)
		local damage = math.clamp(math.floor(fallDistance * 2) - 4, 0, math.huge)

		if damage >= 5 and fallDistance > 3 then
			humanoid.Health = humanoid.Health - damage

			if HasRagdoll then
				PlaySound('FLOOR_IMP', root)
				coroutine.resume(coroutine.create(function() 
					Ragdoll(Who, damage / 9) 
				end))
			else
				humanoid:ChangeState(Enum.HumanoidStateType.Physics)
				humanoid.Sit = true

				task.delay(damage / 9, function()
					if Who and humanoid then
						humanoid:ChangeState(Enum.HumanoidStateType.Running)
						humanoid.PlatformStand = false
						humanoid.Sit = false
					end
				end)
			end
		end
	end

	task.synchronize()

	-- Enable landed state and setup cleanup on destroy
	pcall(function()
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Landed, true)

		table.insert(connections, humanoid.Destroying:Once(cleanup))
		table.insert(connections, root.Destroying:Once(cleanup))
	end)

	-- Floor material change detection
	table.insert(connections, humanoid:GetPropertyChangedSignal('FloorMaterial'):Connect(function()
		task.desynchronize()

		if not humanoid then return end

		local isInAir = humanoid.FloorMaterial == Enum.Material.Air
		local notClimbingOrSwimming = humanoid:GetState() ~= Enum.HumanoidStateType.Climbing and 
			(humanoid:GetState() ~= Enum.HumanoidStateType.Swimming or root.Position.Y > 1)

		if not falling and isInAir and notClimbingOrSwimming then
			falling = true
			highestVelo = root.AssemblyLinearVelocity.Magnitude
			fallenCFrame = Who:GetPivot()
		elseif falling and isInAir and shouldCancelFall() then
			resetFall()
		end
	end))

	-- Velocity tracking
	if root then
		table.insert(connections, root:GetPropertyChangedSignal('AssemblyLinearVelocity'):Connect(function()
			task.desynchronize()

			if not humanoid then return end

			if shouldCancelFall() then
				resetFall()
				return
			end

			if falling then
				if highestVelo < root.AssemblyLinearVelocity.Magnitude then
					highestVelo = root.AssemblyLinearVelocity.Magnitude
				end
			else
				local currentPos = Who:GetPivot().Position
				if currentPos.Y > fallenCFrame.Y and root.AssemblyLinearVelocity.Y < 0 then
					fallenCFrame = Who:GetPivot()
					falling = true
				end
			end
		end))
	end

	-- State change handling
	table.insert(connections, humanoid.StateChanged:Connect(function(old, new)
		task.desynchronize()

		-- Cancel fall on climbing/swimming
		if new == Enum.HumanoidStateType.Climbing or 
			(new == Enum.HumanoidStateType.Swimming and root.Position.Y <= 1) then
			resetFall()
			return
		end

		-- Handle landing states
		local landingStates = {
			Enum.HumanoidStateType.Freefall,
			Enum.HumanoidStateType.Physics,
			Enum.HumanoidStateType.Seated,
			Enum.HumanoidStateType.PlatformStanding,
			Enum.HumanoidStateType.GettingUp,
			Enum.HumanoidStateType.Ragdoll,
			Enum.HumanoidStateType.FallingDown
		}

		if table.find(landingStates, old) and falling then
			-- Check if we should apply damage
			local validLanding = fallenCFrame.Position.Y > Who:GetPivot().Position.Y and
				(new ~= Enum.HumanoidStateType.Swimming or root.Position.Y > 1) and
				not table.find({Enum.Material.Water, Enum.Material.Leather, Enum.Material.Carpet, Enum.Material.Snow}, humanoid.FloorMaterial)

			if validLanding then
				task.synchronize()
				castparams.FilterDescendantsInstances = {Who}
				castparams.FilterType = Enum.RaycastFilterType.Exclude
				task.desynchronize()

				local raycast = workspace:Raycast(root.CFrame.Position, Vector3.new(0, root.AssemblyLinearVelocity.Y * 3, 0), castparams)

				if not raycast or not table.find({Enum.Material.Air, Enum.Material.Water, Enum.Material.Leather, Enum.Material.Carpet, Enum.Material.Snow}, raycast.Material) then
					task.synchronize()
					applyFallDamage()
					task.desynchronize()
				end
			end

			resetFall()
		end

		-- Start fall on falling states
		local fallingStates = {
			Enum.HumanoidStateType.Freefall,
			Enum.HumanoidStateType.Jumping,
			Enum.HumanoidStateType.GettingUp,
			Enum.HumanoidStateType.Ragdoll,
			Enum.HumanoidStateType.PlatformStanding,
			Enum.HumanoidStateType.Seated,
			Enum.HumanoidStateType.Physics
		}

		if table.find(fallingStates, new) and not falling then
			falling = true
			highestVelo = root.AssemblyLinearVelocity.Magnitude
			fallenCFrame = Who:GetPivot()
		elseif not table.find(fallingStates, new) then
			resetFall()
		end
	end))
end
coroutine.resume(coroutine.create(function()
	for i, v in game:FindFirstChildOfClass("CollectionService"):GetTagged("Initiate_Handler")  do
		--for i, v in pairs(workspace:GetDescendants())  do
		--print(v.Name.." Is A Workspace Children")
		if v:IsA("Model") and v:FindFirstChildOfClass("Humanoid") then
			Init_Fall(v)
		end
	end
end))
game.DescendantAdded:Connect(function(des)
	if des:IsA("Model") and des:FindFirstChildOfClass("Humanoid") and des.Name ~= "Effect_" then
		Init_Fall(des)
	end
end)