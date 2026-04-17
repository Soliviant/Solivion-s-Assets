task.wait(1) if game.PrivateServerOwnerId ~= '' and game.PrivateServerOwnerId ~= nil and game.PrivateServerOwnerId ~= 0 then return end
local list = {}
function integrate(Char: Model)
	if typeof(Char) ~= 'Instance' or not Char.ClassName:match('Model') then return end
	task.desynchronize()
	local Character: Model = Char
	if Char:GetAttribute('theregged') then return end
	table.insert(list, Char)
local Humanoid = Character:FindFirstChildOfClass('Humanoid')
	local TS: BasePart = Character:FindFirstChild('UpperTorso') or Character:FindFirstChild('Torso')
	DEFAULT_LIMIT = 2048
	function sanitizeNumber(n, limit)
		limit = limit or DEFAULT_LIMIT
		if n ~= n then
			return 0 
		end return math.clamp(n, -limit, limit)
	end

	
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
	if not TS or not Character or not Humanoid then return end	
	if not workspace:FindFirstChild('_SpawnLocation') or not workspace:FindFirstChildOfClass('SpawnLocation') then
		local SpawnLocation = Instance.new('SpawnLocation',workspace)
		SpawnLocation.Name = '_SpawnLocation'
	end
	local footing = RaycastParams.new() local footingovr = OverlapParams.new()
	task.synchronize()
	footing.FilterDescendantsInstances = list footing.RespectCanCollide = true footing.FilterType = Enum.RaycastFilterType.Exclude footing.IgnoreWater = true
	footingovr.FilterDescendantsInstances = list footingovr.RespectCanCollide = true footingovr.FilterType = Enum.RaycastFilterType.Exclude footingovr.MaxParts = 5
	task.desynchronize()
	local LastStandingCFrame = CFrame.new(workspace._SpawnLocation.CFrame.Position + Vector3.new(0,2,0))
	local LastPartPos = {}
	local LastPos = LastStandingCFrame
	local LastLookVector = Character:GetPivot().LookVector
	
	-- Suspicion logging system
	local SuspicionLog = {}
	local LastSuspicionTime = 0
	local SuspicionCount = 0
	local SuspicionThreshold = (TS.Name == 'Torso' and 3) or (TS.Name == 'UpperTorso' and 7)
	local MaxLogSize = 600
	local totalsus = 0
	local Apass = 0
	task.synchronize()
	if  not Character:GetAttribute('__SKY') then pcall(function() Character:PivotTo(CFrame.new(workspace._SpawnLocation.CFrame.Position + Vector3.new(0,2,0))) end) end
	Character:GetAttributeChangedSignal('PIVOTING__ENABLED'):Connect(function()
		if Character:GetAttribute('PIVOTING__ENABLED') then
			LastStandingCFrame = Character:GetAttribute('TARGET_DES') or Character:GetPivot()
			Apass = 3
		end
	end)
	Character:SetAttribute('theregged', true)
	while Character and Character.Parent ~= nil and Humanoid and Humanoid.Parent do
		local delt=task.wait(.1) -- << ADD TO THE INCREASING TIMER INSTEAD OF USING OS.CLOCK
		task.desynchronize()
		if Character then
			LastSuspicionTime+=delt
			if footing.FilterDescendantsInstances ~= list then
				task.synchronize()
				footing.FilterDescendantsInstances = list
				task.desynchronize()
			end
			if footingovr.FilterDescendantsInstances ~= list then
				task.synchronize()
				footingovr.FilterDescendantsInstances = list
				task.desynchronize()
			end
			if not Character.Name:match('(High Quality Version)') and not Character:GetAttribute('_Loaded') and not Character:GetAttribute('__SKY') then	
				task.synchronize()
				Character:PivotTo(CFrame.new(workspace._SpawnLocation.CFrame.Position + Vector3.new(0,2,0))	) 
				if (Character:GetPivot().Position - CFrame.new(workspace._SpawnLocation.CFrame.Position + Vector3.new(0,2,0)).Position).Magnitude < 1 then Character:SetAttribute('_Loaded', true) end 
				task.desynchronize()
			end
			local currentCFrame = Character:GetPivot()
			local currentLookVector = currentCFrame.LookVector
			local angleSimilarity = LastLookVector:Dot(currentLookVector)
			local positionChanged = (LastPos.Position - currentCFrame.Position).Magnitude >= 0.5
			local angleChanged = angleSimilarity < 0.9
			
			local fixedcurrentCFrame = fixCFrame(currentCFrame)
			local FRewind = false
			if fixedcurrentCFrame ~= currentCFrame then
				FRewind = true
			end
			if positionChanged or angleChanged then
				local topos = LastStandingCFrame
				topos = LastPos
				local Rewind = true
				local pass = (TS.Name == 'Torso' and 3) or (TS.Name == 'UpperTorso' and 8) or  math.ceil(#LastPartPos/1.25)
				local suspiciousTriggered = false
				
				if not FRewind then
				for i,v in Character:GetChildren()  do
					if v:IsA("BasePart") then
						if LastPartPos[v] then
							local direction = v.Position - LastPartPos[v]
							local distance = direction.Magnitude
							if distance > 0 then
								if distance > 1024 then
									suspiciousTriggered = true
									Rewind = true
								else
								local size = v.Size
								local orientation = v.CFrame.Rotation
								local blockcastResult = workspace:Blockcast(orientation + LastPartPos[v], size, direction, footing) 
								if not blockcastResult then local s = workspace:GetPartsInPart(v, footingovr) if s and #s > 0 then blockcastResult = true end end
								
								if not blockcastResult then
									pass = pass - 1
									if pass <= 0 then
										Rewind = false
										break
									end
								else
									suspiciousTriggered = true
								end end
							end
							LastPartPos[v] = v.Position
						else
							LastPartPos[v] = v.Position
						end
					end
				end
				for i,v in pairs(LastPartPos) do
					if not i or not i:IsDescendantOf(Character) then
						v = nil
					end
				end end
				--[[-- Suspicion logging system
				if suspiciousTriggered and totalsus < 10 then
					totalsus += LastSuspicionTime
					LastSuspicionTime = 0
					SuspicionCount = SuspicionCount + 1
					
					-- Log current position
					table.insert(SuspicionLog, {
						position = currentCFrame,
					})
					
					-- Remove oldest entries if exceeding max log size
					if #SuspicionLog > MaxLogSize then
						table.remove(SuspicionLog, 1)
					end
				elseif (#SuspicionLog > 0 and (LastSuspicionTime) >= 10) or totalsus >= 10 then
					-- No suspicious activity for 10 seconds, check if we should rewind
					if SuspicionCount >= SuspicionThreshold and #SuspicionLog > 0 then
						-- Rewind to first logged position
						local firstEntry = SuspicionLog[1]
						if firstEntry then
							task.synchronize()
							pcall(function() LastPos = firstEntry.position LastLookVector = Character:GetPivot().LookVector Character:PivotTo(firstEntry.position)
							LastPos = firstEntry.position
								LastLookVector = Character:GetPivot().LookVector end)
							task.desynchronize()
						end
					end
					-- Clear logs after checking
					SuspicionLog = {}
					SuspicionCount = 0
					totalsus = 0
				end]]
				----((pass)
				if FRewind or (Apass <= 0 and (Rewind or pass > 0) and not Character:GetAttribute('PIVOTING__ENABLED') and not Character:GetAttribute('Roll') and not ((Humanoid:GetState() == Enum.HumanoidStateType.PlatformStanding or Humanoid:GetState() == Enum.HumanoidStateType.Physics) and Humanoid.RootPart.Anchored == true)) then
					if Humanoid and Humanoid.Sit and (not Humanoid.SeatPart or not Humanoid.SeatPart.Name:lower():match(Character.Name:lower())) then local isthereseat = Humanoid.SeatPart if isthereseat and (not isthereseat:IsDescendantOf(workspace.Map) or isthereseat.Anchored == false) then task.synchronize() Humanoid.PlatformStand = true end task.wait() task.synchronize() if Character then task.synchronize() if not Character:GetAttribute('Sliding') then Character:PivotTo((topos + (Character:GetPivot().Position - topos.Position).Unit * 2) or LastStandingCFrame) end if isthereseat and Humanoid then task.synchronize() Humanoid.PlatformStand = false end end end
					if not Humanoid.SeatPart and not Character:GetAttribute('IsRagdoll') then task.synchronize() if not Character:GetAttribute('Sliding') then Character:PivotTo((topos or LastStandingCFrame) - ((Humanoid.RootPart and Humanoid.RootPart.AssemblyLinearVelocity * delt) or Vector3.new())) end if Humanoid.RootPart then Humanoid.RootPart.AssemblyLinearVelocity = Vector3.new() end pcall(function() Humanoid.MoveDirection = Humanoid.RootPart and -Humanoid.RootPart.AssemblyLinearVelocity.Unit or -Humanoid.MoveDirection end) end
				elseif not suspiciousTriggered then
					if currentCFrame.Position.Y >= - 350 then
						LastPos = currentCFrame
						LastLookVector = currentLookVector
					end
				else
					LastStandingCFrame = Character:GetAttribute('TARGET_DES') or Character:GetPivot()
				end	
				if Apass > 0 then LastStandingCFrame = Character:GetAttribute('TARGET_DES') or Character:GetPivot()	Apass -= 1 end
			end	
		end
	end pcall(function() task.synchronize() Character:SetAttribute('theregged', nil) end) pcall(function()
		table.remove(list, table.find(list, Char))
	end)
end

workspace.ChildAdded:Connect(function(a)
	if a:IsA('Model') and a:FindFirstChildOfClass('Humanoid') then
		integrate(a)
	end
end)

script:WaitForChild('Event', 60)
if not script:FindFirstChildOfClass('BindableEvent') then local a = Instance.new('BindableEvent', script) a.Name = 'Event' end
script:FindFirstChildOfClass('BindableEvent').Event:Connect(function(a)
	if typeof(a) ~= 'Instance' then return end
	if a:IsA('Model') and a:FindFirstChildOfClass('Humanoid') then
		integrate(a)
	end
end)

while task.wait(600) do
	for i,v in list do
		if typeof(v) ~= 'Instance' or not v:IsDescendantOf(workspace) then
		pcall(function()	table.remove(list, table.find(list, v)) end) end
	end
end