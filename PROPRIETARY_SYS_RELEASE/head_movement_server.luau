--!native
local Rate = 1/60
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Utility: strict name/class equality
function FindFirstChildOfNameAndClass(Where, Name, Class)
	if not Where then return nil end
	for i, v in Where:GetChildren() do
		if v.Name:match(Name) and v:IsA(Class) then
			return v
		end
	end
	return nil
end

local alldisable = {}

function Looker(Player)
	task.desynchronize()
	local IsHere = true
	local co
	local localPlayer = Player
	local character
	local head
	local torso
	local rootPart
	local neckMotor

	local function updateCharacterMouseFollow(Character)
		task.desynchronize()
		if not Player or not Character then
			IsHere = false
			return
		end
		IsHere = true

		local input = ServerStorage and ServerStorage:FindFirstChild('Input_Storage')
		if input then
			input = input:FindFirstChild(localPlayer.Name..'#>(')
		end
		if co then
			task.synchronize()
			coroutine.close(co)
			co = nil
		end
		if not input then return end
		local hum = Character:FindFirstChildOfClass('Humanoid')
		if not hum then return end

		local tco
		tco = coroutine.create(function()
			while co == tco and IsHere and input do
				task.desynchronize()
				local Delta = task.wait(Rate)
				local Speed = 1 - (1 / 10000000) ^ Delta
				if not localPlayer then break end
				if not Character.Parent then return end
				character = localPlayer.Character
				if Character:GetAttribute('Disconnect_Execution') or Player.Character ~= Character or Character ~= character then
					break
				end

				if not Character:GetAttribute('Halt_Execution') and not Character:GetAttribute('Sliding') and input:GetAttribute('Focused') and hum and not table.find({Enum.HumanoidStateType.PlatformStanding,Enum.HumanoidStateType.Ragdoll,Enum.HumanoidStateType.FallingDown,Enum.HumanoidStateType.Dead}, hum:GetState()) then
					character = Character
					if not head or not head.Parent then head = FindFirstChildOfNameAndClass(Character,'Head',"BasePart") end
					if not rootPart or not rootPart.Parent then  rootPart = FindFirstChildOfNameAndClass(Character,'HumanoidRootPart',"BasePart") end
					if not torso or not torso.Parent then  torso = FindFirstChildOfNameAndClass(character,'UpperTorso',"BasePart") or FindFirstChildOfNameAndClass(character,'Torso',"BasePart") end
					task.desynchronize()
					if not head and not rootPart and not torso then
						break
					end

					if head and torso then neckMotor = FindFirstChildOfNameAndClass(torso,'HSnap',"Weld") end

					if localPlayer and input and Character and Character.Parent ~= nil and torso and head and neckMotor and torso.Parent ~= nil and Character:FindFirstChildOfClass('Humanoid') and Character:FindFirstChildOfClass('Humanoid'):GetState() ~= Enum.HumanoidStateType.Dead then
						local usemouse = (input and input:GetAttribute('IsInFirstPerson') == true and true) or false
						local crouchObj = FindFirstChildOfNameAndClass(Character,'Crouching','StringValue')
						local Crawling = crouchObj and crouchObj.Value == 'Crawl' and Character and Character:FindFirstChildOfClass('Humanoid') and Character:FindFirstChildOfClass('Humanoid'):GetState() ~= Enum.HumanoidStateType.Climbing and Character:FindFirstChildOfClass('Humanoid'):GetState() ~= Enum.HumanoidStateType.Seated and Character:FindFirstChildOfClass('Humanoid'):GetState() ~= Enum.HumanoidStateType.Freefall and Character:FindFirstChildOfClass('Humanoid'):GetState() ~= Enum.HumanoidStateType.Jumping and Character:FindFirstChildOfClass('Humanoid'):GetState() ~= Enum.HumanoidStateType.Swimming
						local torsoLookVector = (torso and torso.CFrame.LookVector) or (rootPart and rootPart.CFrame.LookVector) or (head and head.CFrame.LookVector) or Vector3.new()
						local headPosition = (head and head.CFrame.Position) or (torso and torso.CFrame.Position) or (rootPart and rootPart.CFrame.Position) or Vector3.new()
						local mouseHitPosition = (usemouse and input:GetAttribute('Mouse')) or input:GetAttribute('CamPos') or Vector3.new()

						local mouseHitHeadDist = (headPosition - mouseHitPosition).magnitude
						local YDifference = mouseHitPosition.Y - head.CFrame.Y
						local YDiffmouseHeadDistUnit = (usemouse and (headPosition - mouseHitPosition).Unit) or (mouseHitPosition - headPosition).Unit

						local goalNeckCFrame = CFrame.Angles(
							-(math.atan(YDifference / mouseHitHeadDist) * (Crawling and 4 or 1) * ((usemouse  and -0.5) or 0.5)),
							YDiffmouseHeadDistUnit:Cross(torsoLookVector).Y * (Crawling and 6 or 1) * ((usemouse and 2) or 1),
							0)  * (neckMotor:GetAttribute('offset__C0') or CFrame.new())
						task.desynchronize()
						if goalNeckCFrame.LookVector:Dot(Vector3.new(0,0,1)) > 0 then goalNeckCFrame = goalNeckCFrame:Inverse() end
						if neckMotor and neckMotor.C0.Rotation.LookVector:Dot(goalNeckCFrame.LookVector) <= .975 then
							local rotat = (Crawling and goalNeckCFrame.Rotation) or neckMotor.C0:Lerp(goalNeckCFrame, Speed/2).Rotation
							local dot = rootPart.CFrame:ToWorldSpace(rotat).LookVector:Dot(rootPart.CFrame.LookVector)
							if dot <= 0 then
								rotat = CFrame.new()
							elseif dot < 0.05 then
								rotat = rotat:Inverse()
							end
							local setto = rotat + neckMotor.C0.Position
							task.synchronize() neckMotor.C0 = setto
						end
					end
				end
			end
			if neckMotor then task.synchronize() neckMotor.C0 = CFrame.new(neckMotor.C0.Position) * (neckMotor:GetAttribute('offset__C0') or CFrame.new()) end
		end)
		co = tco
		coroutine.resume(co)
	end

	task.synchronize()
	local connectiona, connectionb, connectionc, connectiond
	local disall
	disall = function()
		task.synchronize()
		if co then
			task.synchronize()
			coroutine.close(co)
		end 
		if connectiona then connectiona:Disconnect() end
		if connectionb then connectionb:Disconnect() end
		if connectionc then connectionc:Disconnect() end
		if connectiond then connectiond:Disconnect() end
		connectiona = nil
		connectionb = nil
		connectionc = nil
		connectiond = nil
		co = nil
		if table.find(alldisable, disall) then
			table.remove(alldisable, table.find(alldisable, disall))
		end
		disall = nil
	end
	table.insert(alldisable, disall)
	connectiona = Player.Destroying:Connect(function()
		if co then
			task.synchronize() coroutine.close(co)
		end 
		IsHere = false
		Player = nil
		disall()
	end)
	connectionb = Players.PlayerRemoving:Connect(function(p)
		if p == Player then
			if co then
				task.synchronize() coroutine.close(co)
			end
			IsHere = false
			Player = nil
			disall()
		end
	end)
	connectionc = Player.CharacterRemoving:Connect(function(char)
		if co then
			task.synchronize() coroutine.close(co)
		end
		-- Only set IsHere false if THIS character is the one currently tracked
		if Player and char == Player.Character then
			IsHere = false
		end
		co = nil
	end)
	connectiond = Player.CharacterAdded:Connect(function(char)
		task.desynchronize()
		-- On respawn, always reset state and start a new coroutine
		IsHere = true
		head, torso, rootPart, neckMotor = nil, nil, nil, nil
		if co then
			task.synchronize() coroutine.close(co)
			co = nil
		end
		if Player and char then
			updateCharacterMouseFollow(char)
		else
			IsHere = false
		end
	end)
	task.delay(5, function()
		if Player and not Player:GetAttribute('MENUED') then
			local plrgui = Player:FindFirstChildOfClass('PlayerGui')
			if not plrgui and Player then return end
			task.synchronize()
			for i, v in game:GetService('StarterGui'):GetChildren() do
				if v.Name ~= 'LoadingGui(Preload)' and not FindFirstChildOfNameAndClass(plrgui, v.Name, v.ClassName) then
					v:Clone().Parent = plrgui
				end
			end
		end
	end)
	-- Attach to current character if present
	if Player.Character then
		updateCharacterMouseFollow(Player.Character)
	end
end

-- Attach to all existing players on startup
for i, player in Players:GetPlayers() do
	Looker(player)
end

local connection = Players.PlayerAdded:Connect(Looker)
local conw = workspace:GetPropertyChangedSignal('Name'):Connect(function()
	if workspace.Name == 'VIPSERVER' then
		connection:Disconnect()
		for i, v in alldisable do
			v()
		end
	end
end)
task.wait(5)
conw:Disconnect()
conw = nil
if workspace.Name == 'VIPSERVER' then
	pcall(function()
		connection:Disconnect()
	end)
	pcall(function()
		for i, v in alldisable do
			v()
		end
	end)
	script:Destroy()
end
--RunService.Heartbeat:Connect(updateCharacterMouseFollow)

