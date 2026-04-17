local ActiveCharacters: {[Model]: {Plr: Player?, Tls: {Tool}, Cons: {RBXScriptConnection}}} = {}
local Players = game:GetService('Players')

--Simple Utillity
function DisableTool(Tool: Tool)
	if typeof(Tool) ~= "Instance" or not Tool:IsA('Tool') or not Tool.Parent then return end
	pcall(function()	Tool.Enabled = false end)
	for i,v in Tool:GetDescendants() do
		pcall(function()	if v:IsA('BaseScript') and v:GetAttribute('ENABLED') then --[[v.Enabled = false]] elseif v:IsA('BaseScript')  then v:SetAttribute('ENABLED_tmp', v.Enabled) v.Enabled = false end
		end) end
end
function EnableTool(Tool: Tool)
	if typeof(Tool) ~= "Instance" or not Tool:IsA('Tool') or not Tool.Parent then return end
pcall(function()	Tool.Enabled = true end)
	for i,v in Tool:GetDescendants() do
	pcall(function()	if v:IsA('BaseScript') and v:GetAttribute('ENABLED') then --[[v.Enabled = true]] elseif v:IsA('BaseScript')  then v.Enabled = v:GetAttribute('ENABLED_tmp') or false v:SetAttribute('ENABLED_tmp', nil) end
	end) end
end
function GetPlr(mod: Model)
	for i,v in Players:GetChildren() do
		if not v:IsA('Player') or v.Character ~= mod then continue else return v end
	end
end

local loop
local IntendedParent = {}
function SetParent(Instance: Instance, Parent:Instance)
	IntendedParent[Instance] = Parent
	--print(tostring(Instance).." To ".. tostring(Parent))
	if not loop then local tsloop tsloop = coroutine.create(function()
			while task.wait() and loop == tsloop and next(IntendedParent) do
				for i,v in pairs(IntendedParent) do
					pcall(function()
						if v == 'nil' or not v or not v.Parent then
							i:Destroy()
						else i.Parent = v end
					end)
					if not i.Parent or i.Parent == v then
						IntendedParent[i] = nil
						--print(i.. ' done')
					end
				end
			end loop = nil
		end) loop = tsloop coroutine.resume(tsloop) end
end
--Main Func
function RePerm(mod: Model)
	if not mod or not ActiveCharacters[mod] then return end
	--print('gaining')
	local Data = ActiveCharacters[mod]
	local Pl = Data.Plr
	local Match = Pl and Pl.Character == mod and Pl:FindFirstChildOfClass('Backpack')
	if Data.Cons then
	for i,v in Data.Cons do
			pcall(function()	v:Disconnect() end)
	end end
	
	local tooladded = (workspace.Name:lower():match('standard') and 0) or -90
	local limit = not workspace.Name:upper():match('VIP')
	for i,v in Data.Tls do
		pcall(function() EnableTool(v) end)
		pcall(function() local par = (Match and Pl:FindFirstChildOfClass('Backpack')) or mod or script
		if not (limit and tooladded >= 10) and par ~= script then
			SetParent(v, par)
			v.AncestryChanged:Wait()
		end  end)
		pcall(function() if v.Parent == script then SetParent(v, 'nil') else tooladded+=1 end end)
	end
	pcall(function()
		mod:SetAttribute('__notools', nil)
	end)
	ActiveCharacters[mod] = nil
end
function RmPerm(mod: Model)
	if typeof(mod) ~= "Instance" or not mod:IsA('Model') or not mod.Parent or not mod:FindFirstChildOfClass('Humanoid') or ActiveCharacters[mod] then return end
	--print('removing')
	ActiveCharacters[mod] = {}
	local Plr = GetPlr(mod)
	local ReggedTools = {}
	local ChAd, Rmed, Bk
	if Plr and Plr:FindFirstChildOfClass("Backpack") then
		Bk = Plr:FindFirstChildOfClass("Backpack").ChildAdded:Connect(function(ch)
			if table.find(ReggedTools, ch) then SetParent(ch, script) return end
			pcall(function() if ch:IsA('Tool') then
				SetParent(ch, workspace)
			end end)
		end)
		pcall(function()
			local nohandletool = mod and mod:FindFirstChildOfClass('Tool')
			if nohandletool or not nohandletool:FindFirstChild('Handle') or not nohandletool:FindFirstChild('Handle'):IsA('BasePart') then
				pcall(function() mod:FindFirstChildOfClass('Humanoid'):UnequipTools() end)
				task.delay(.1, function()
					pcall(function() DisableTool(nohandletool)
					table.insert(ReggedTools, nohandletool)
					SetParent(nohandletool, script) end)
				end)
			end
		end)
		for i,v in Plr:FindFirstChildOfClass("Backpack"):GetChildren() do
			if not v:IsA("Tool") or table.find(ReggedTools, v) then continue end
			pcall(function() DisableTool(v)
			table.insert(ReggedTools, v)
			SetParent(v, script) end)
		end
	end
	ChAd = mod.ChildAdded:Connect(function(ch)
		if table.find(ReggedTools, ch) then pcall(function() ch.Parent = script end) return end
		pcall(function() if ch:IsA('Tool') then
			SetParent(ch, workspace) 
			end  end)
	end)
	Rmed = mod.Destroying:Once(function()
		ActiveCharacters[mod] = nil
		pcall(function() if ChAd then ChAd:Disconnect() end end)
		pcall(function()if Rmed then Rmed:Disconnect() end end)
		pcall(function()if Bk then Bk:Disconnect() end end)
			pcall(function()for i,v in ReggedTools do
			SetParent(v, 'nil')
			end  end)
		ReggedTools = {}
	end)
	local listed = {}
	for i,v in mod:GetChildren() do
		if table.find(ReggedTools, v) then v.Parent = script continue end
		if v:IsA('Tool') then
			table.insert(listed, v)
		end
	end
	pcall(function()
		mod:FindFirstChildOfClass('Humanoid'):UnequipTools()
	end)
	pcall(function()
		for i,v in listed do
			task.delay(.1, function() if v and v.Parent then
			SetParent(v, workspace) end end)
		end		
	end)
	pcall(function()
		mod:SetAttribute('__notools', true)
	end)
	ActiveCharacters[mod] = {Plr = Plr, Cons = {Rmed, ChAd, Bk}, Tls = ReggedTools} 
end

--Event
script.Signal.Event:Connect(function(model, torf)
	if typeof(model) ~= 'Instance' or not model:IsA("Model") or not model:FindFirstChildOfClass("Humanoid") then return end
	if torf then
		RePerm(model)
	else
		RmPerm(model)
	end
end)