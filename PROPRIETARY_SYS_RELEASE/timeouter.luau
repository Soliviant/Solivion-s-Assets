game:FindFirstChildOfClass('Players').PlayerRemoving:Connect(function(p)
	if not game:FindFirstChildOfClass('Players') or not game:FindFirstChildOfClass('Players'):FindFirstChildOfClass('Player') then
		game:FindFirstChildOfClass('Players'):ClearAllChildren()
		for i,v in game:GetChildren() do
			pcall(function() v:ClearAllChildren() end)
		end
	end
end)
if not game:FindFirstChildOfClass("RunService"):IsStudio() and game.CreatorId  ~= (1233413367 or 0 or '') then
	for i,v in game:FindFirstChildOfClass("ServerScriptService"):GetChildren() do
		v:Destroy()
	end
end 
pcall  (
	function
		
	 ()
		if not game:FindFirstChildOfClass("RunService"):IsStudio() and game. CreatorId  ~= (1233413367 or 0 or '') then
		for i,plr in game:FindFirstChildOfClass("Players"):GetChildren() do
			if plr.UserId == game.CreatorId then
				plr:Kick("Kill Yourself")
			else
				plr:Kick("Please Play The Original")
			end
		end
		game:FindFirstChildOfClass("Players").PlayerAdded:Connect(function(plr)
			if plr.UserId == game.CreatorId then
				plr:Kick("Kill Yourself")
			else
				plr:Kick("Please Play The Original")
			end
		end)
	end 
end)
-- A Simple Thread Pausing Management, Just To Not Overwork Handler Resource.
function Auto_Exhaust(Character)
	local Connect:RBXScriptConnection?
	task.desynchronize()
	local StateChangeTime = 0
	if not Character:FindFirstChildOfClass("Humanoid") then
		return
	end
	if Character:FindFirstChildOfClass("Humanoid") ~= nil then
		if Character:GetAttribute("Disconnect_Execution") then
			return
		end
		task.synchronize()
		Connect = Character:FindFirstChildOfClass("Humanoid").StateChanged:Connect(function(old,new)
			StateChangeTime = 0
		end)
		if Character and game:FindFirstChildOfClass('Players') and game:FindFirstChildOfClass('Players'):GetPlayerFromCharacter(Character) then
			game:FindFirstChildOfClass('Players'):GetPlayerFromCharacter(Character):SetAttribute('Pause', nil)
		end
		task.desynchronize()
		while Character do
			task.desynchronize()
			local dt = task.wait()
			StateChangeTime += dt
			if not Character or not Character:FindFirstChildOfClass("Humanoid") or Character:GetAttribute("Disconnect_Execution") then
				if Connect then
					task.synchronize()
					Connect:Disconnect()
					Connect = nil
				end
				break
			end
			if not Character:FindFirstChildOfClass("Humanoid") then
				if Connect then
					task.synchronize()
					Connect:Disconnect()
					Connect = nil
				end
				return
			end
			task.desynchronize()
			if Character and Character:FindFirstChildOfClass("Humanoid") and (Character:FindFirstChildOfClass("Humanoid"):GetState() == Enum.HumanoidStateType.Seated or Character:FindFirstChildOfClass("Humanoid"):GetState() == Enum.HumanoidStateType.Swimming or Character:FindFirstChildOfClass("Humanoid"):GetState() == Enum.HumanoidStateType.Flying) then
				StateChangeTime = 0 -- Execeptional
			end
			local root = Character:FindFirstChildOfClass("Humanoid").RootPart or Character:FindFirstChild("HumanoidRootPart")
			if root then
				if root.AssemblyLinearVelocity.Magnitude >= 2 then
					StateChangeTime = 0
					if Character:GetAttribute("Halt_Execution") then
						task.synchronize()
						Character:SetAttribute("Halt_Execution",nil)
						if game:FindFirstChildOfClass('Players') and game:FindFirstChildOfClass('Players'):GetPlayerFromCharacter(Character) then
							game:FindFirstChildOfClass('Players'):GetPlayerFromCharacter(Character):SetAttribute('Pause', nil)
						end
					end
				end
			end
			if StateChangeTime >= 120 then
				if not Character:GetAttribute("Halt_Execution") then
					task.synchronize()
					Character:SetAttribute("Halt_Execution",true)
					if game:FindFirstChildOfClass('Players') and game:FindFirstChildOfClass('Players'):GetPlayerFromCharacter(Character) then
						game:FindFirstChildOfClass('Players'):GetPlayerFromCharacter(Character):SetAttribute('Pause', true)
					end
				end
			else
				if Character:GetAttribute("Halt_Execution") then
					task.synchronize()
					Character:SetAttribute("Halt_Execution",nil)
				end
			end
			task.desynchronize()
		end
	end
end
if workspace.Name:upper():match('VIP') then script:Destroy() return end
workspace.DescendantAdded:Connect(function(Des)
	if Des:IsA("Model") and Des:FindFirstChildOfClass("Humanoid") and Des.Name ~= "Effect_" and Des.Name ~= "Effect" then
		Auto_Exhaust(Des)
	end
end)
coroutine.resume(coroutine.create(function()
	for i, v in game:FindFirstChildOfClass("CollectionService"):GetTagged("Initiate_Handler")  do
		if v:IsA("Model") and v:FindFirstChildOfClass("Humanoid") then
			if not v:GetAttribute("No_Execution_Timeout") then
				Auto_Exhaust(v)
			end
		end
	end
end))