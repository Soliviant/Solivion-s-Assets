local fcount={} -- fail count
local desco={} --external destruction connection

game:GetService('ScriptContext').Error:ConnectParallel(function(m, t, s)
	if not s or typeof(s) ~= 'Instance' or not s.Parent or typeof(m) ~= 'string' or m:lower():match('failed to load') or m:lower():match('internalservererror') or m:lower():match('dnsresolve') or m:lower():match('httperror')  then return end
	local sre = true -- should reactivate
	local rgn = s:GetFullName() --registered name
	if not s:GetAttribute('__noremove') then
	if not fcount[rgn] then fcount[rgn] = 0 end
	fcount[rgn] += 1 
	if fcount[rgn] >= 5 then
		sre = false -- count your days
	end end
	task.synchronize()
	if desco[rgn] then desco[rgn]:Disconnect() end
	local isanimate = s:FindFirstAncestorWhichIsA('Model') and s:FindFirstAncestorWhichIsA('Model'):FindFirstChildOfClass('Humanoid') and s.Name == 'Animate' and #s:GetChildren() > 0
	pcall(function()
	if sre then
		local clone = s:Clone()
		s:SetAttribute('Removing', true)
			task.wait()
			if s.Name:upper():match('STATE_ENGINE') or s.Name:upper():match('COMMANDS+') or s.Name:upper():match('BOAT+') then
				repeat task.wait() until s:GetAttribute("ReadyToBRemoved")
			end
		clone.Parent = s.Parent
		desco[rgn] = clone.Destroying:Once(function() if desco[rgn] then desco[rgn]:Disconnect() end desco[rgn] = nil fcount[rgn] = nil end)
		s:Destroy()
	else
		s:Destroy()
		fcount[rgn] = nil
	end end)
	if isanimate then
		pcall(function()
			local sss = game:GetService('ServerScriptService')
			if sss and sss:FindFirstChild('Heavily_Calculized_Handler') and sss:FindFirstChild('Heavily_Calculized_Handler'):FindFirstChild('Animation_Handler') and sss:FindFirstChild('Heavily_Calculized_Handler'):FindFirstChild('Animation_Handler'):FindFirstChild('Registry') then
				sss:FindFirstChild('Heavily_Calculized_Handler'):FindFirstChild('Animation_Handler'):FindFirstChild('Registry'):Fire(s:FindFirstAncestorWhichIsA('Model'))
			else 
				local isM = 0
				for i,v in s:FindFirstAncestorWhichIsA('Model'):GetDescendants() do
					if v.ClassName == 'Motor6D' then isM+=1 elseif v.ClassName == 'AnimationConstraint'
					then isM -=1 end				end
				local clone 
				if isM >=0  then
					clone = script:FindFirstChild('Animate'):Clone()
				else
					clone = game:GetService('ServerStorage'):WaitForChild('Animate', 10):Clone()
				end
				if not s:FindFirstAncestorWhichIsA('Model'):FindFirstChildOfClass('Actor') then
					Instance.new('Actor', s:FindFirstAncestorWhichIsA('Model'))
				end
				clone.Parent = s:FindFirstAncestorWhichIsA('Model'):FindFirstChildOfClass('Actor') or s:FindFirstAncestorWhichIsA('Model')
				clone.Enabled = true
			end
		end)
	end
end)

task.desynchronize()
while task.wait(210) do
	task.desynchronize()
	for i,v in pairs(fcount) do
		fcount[i] = fcount[i] - 1
		if fcount[i] <= 0 then
			if desco[i] then task.synchronize() desco[i]:Disconnect() task.desynchronize() end desco[i] = nil fcount[i] = nil
		end
	end
end