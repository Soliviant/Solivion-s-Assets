function ManualLoad(plr: Player)
	local Chr = script.StarterCharacter:Clone()
	Chr.Name = plr.Name
	Chr:FindFirstChildOfClass('Humanoid').DisplayName = plr.DisplayName
	Chr.Parent = workspace
	pcall(function()
		script:FindFirstAncestorWhichIsA('ServerScriptService'):FindFirstChild('Misc_Handler'):FindFirstChild('COLLISION CHECK'):FindFirstChildOfClass('BindableEvent'):Fire(Chr)
	end
	)
	pcall(function() plr.Character = Chr end)
	pcall(function()
		for i,v in game:GetService('StarterPlayer'):FindFirstChildOfClass('StarterCharacterScripts'):GetChildren() do
			v:Clone().Parent = Chr
		end 
	end)
end
function validchar(plr: Player)
	if typeof(plr) ~= 'Instance' or typeof(plr.Parent) ~= 'Instance' then return true end -- spoof to not trigger respawn
	local thething
	if typeof(plr.Character) ~= 'Instance' or not plr.Character:IsDescendantOf(workspace) then
	for i,v in plr:GetChildren() do if v:GetAttribute('__REGPLRID') == plr.UserId then thething = v break end end
	if typeof(thething) == 'Instance' and thething:GetAttribute('__REGPLRID') == plr.UserId then
		local arg = (thething:FindFirstChild('HumanoidRootPart') or thething:FindFirstChild('Torso'))
		return typeof(arg) == 'Instance' and arg:IsA('BasePart')
	end end
	return plr and plr.Parent and plr.Character and plr.Character.Parent and plr.Character:FindFirstChildOfClass('Humanoid') and (plr.Character:FindFirstChild('HumanoidRootPart') or plr.Character:FindFirstChild('Torso')) and (plr.Character:FindFirstChild('HumanoidRootPart') or plr.Character:FindFirstChild('Torso')):IsA('BasePart') and plr.Character:FindFirstChildOfClass('Humanoid').Health == plr.Character:FindFirstChildOfClass('Humanoid').Health
end

local Trigger = script:WaitForChild('Trigger', 60)
if not script:FindFirstChild('Trigger') or not script:FindFirstChildOfClass('BindableEvent') or not script:FindFirstChild('Trigger').ClassName:match('BindableEvent') then if script:FindFirstChild('Trigger') then script:FindFirstChild('Trigger'):Destroy() end newbin  = Instance.new('BindableEvent', script) newbin.Name = 'Trigger' else newbin = script:FindFirstChildOfClass('BindableEvent') end
Trigger.Event:Connect(ManualLoad)

while task.wait(600) do
	pcall(function()
	for i,v in game:GetService('Players'):GetChildren() do
		if not v:IsA("Player") then continue end
		if not validchar(v) and v:GetAttribute("MENUED") then
			task.delay(5, function()
				if not v or not v.Parent or validchar(v) then return end
				local loader, err = pcall(function() v:LoadCharacterAsync() end)-- check for respawning error
				if not loader then
					pcall(function()
					ManualLoad(v) end)
				end
			end)
		end
	end end)
end