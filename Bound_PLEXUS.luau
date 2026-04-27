-- Bound Detection System By Assistant
-- Detects characters touching the bound and monitors them with Region3

-- Plexus by Solivion
-- Cooler Shi


local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Configuration
local BOUND_NAME = "_BOUND"
local REGION_PADDING = 10 -- Extra padding around the bound for Region3

-- State
local registeredCharacters = {}
local monitorTask = nil
local boundPart = nil

-- Find the bound part
local function findBoundPart()
	if boundPart and boundPart.Parent then
		return boundPart
	end
	boundPart = workspace:FindFirstChild(BOUND_NAME)
	return boundPart
end

-- Get the Region3 for the bound area
local function getBoundRegion()
	local part = findBoundPart()
	if not part then return nil end

	local pos = part.Position
	local halfSize = part.Size / 2

	-- Create Region3 from min and max corners
	local min = Vector3.new(
		pos.X - halfSize.X - REGION_PADDING,
		pos.Y - halfSize.Y - REGION_PADDING,
		pos.Z - halfSize.Z - REGION_PADDING
	)
	local max = Vector3.new(
		pos.X + halfSize.X + REGION_PADDING,
		pos.Y + halfSize.Y + REGION_PADDING,
		pos.Z + halfSize.Z + REGION_PADDING
	)

	return Region3.new(min, max)
end

function posKey(pos)
	return string.format('%.3f,%.3f,%.3f', pos.X, pos.Y, pos.Z)
end
function posMatch(p1, p2)
	return (p1 - p2).Magnitude <  0.001
end

-- Check if a character is inside the Region3
local function isCharacterInRegion(character, region)
	if not character or not character.Parent then
		return false
	end

	if not character:IsA("Model") then return false end

	local pos = character:GetPivot()
	local cframe, size = region.CFrame, region.Size
	local min = cframe.Position - size / 2
	local max = cframe.Position + size / 2

	return pos.X >= min.X and pos.X <= max.X
		and pos.Y >= min.Y and pos.Y <= max.Y
		and pos.Z >= min.Z and pos.Z <= max.Z
end

local PartPool = {}
local ParticleData = {} -- vel and shi
local WedgePool = {}

local TriangleModule = require(script.Traingle)

function VoidPart()
	local part = Instance.new('Part', workspace)
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Material = Enum.Material.Neon
	part.CastShadow = false
	part.Transparency = 0.3 + math.random() * 0.4
	part.Size = Vector3.new(0.1 + math.random() * 0.2, 0.1 + math.random() * 0.2, 0.1 + math.random() * 0.2)
	part.Color = Color3.new(math.random(), math.random(), math.random())
	part.CFrame = CFrame.new(0, 100000, 0)
	return part
end

function UpdatePool(needed) if typeof(needed) ~= 'number' then return end
	local PoolCur = #PartPool
	local Dif = needed - PoolCur
	if Dif == 0 then return end
	task.synchronize()
	if Dif > 0 then
		for i = 1, Dif do 
			local part = VoidPart()
			table.insert(PartPool, part)
			table.insert(ParticleData, {velocity = Vector3.new((math.random() - 0.5) * 2,(math.random() - 0.5) * 2,(math.random() - 0.5) * 2),phase = math.random() * math.pi * 2,speed = 0.5 + math.random() * 1.5})
		end
	else
		for i = 1, math.abs(Dif) do
			local part = PartPool[#PartPool]
			table.remove(PartPool, #PartPool)
			table.remove(ParticleData, #ParticleData)
			if typeof(part) == 'Instance' then
				part:Destroy()
			end
		end
	end
end

function VoidWedge()
	local wedge = Instance.new('WedgePart', workspace)
	wedge.Anchored = true
	wedge.CanCollide = false
	wedge.CanQuery = false
	wedge.CanTouch = false
	wedge.Material = Enum.Material.Neon
	wedge.CastShadow = false
	wedge.Transparency = 0.5 + math.random() * 0.3
	wedge.TopSurface = Enum.SurfaceType.Smooth
	wedge.BottomSurface = Enum.SurfaceType.Smooth
	wedge.Color = Color3.new(math.random(), math.random(), math.random())
	wedge.CFrame = CFrame.new(0, 100000, 0)
	return wedge
end

function UpdateWedgePool(needed)
	if typeof(needed) ~= 'number' then return end
	local PoolCur = #WedgePool
	local Dif = needed - PoolCur
	if Dif == 0 then return end
	task.synchronize()
	if Dif > 0 then
		for i = 1, Dif do
			local wedge = VoidWedge()
			table.insert(WedgePool, wedge)
		end
	else
		for i = 1, math.abs(Dif) do
			local wedge = WedgePool[#WedgePool]
			table.remove(WedgePool, #WedgePool)
			if typeof(wedge) == 'Instance' then
				wedge:Destroy()
			end
		end
	end
end

function updVFX(dt)
	if typeof(dt) ~= 'number' then dt = 1/60 end
	local NeededNode = #registeredCharacters * 20 -- needed part wil calculate after node and connection was properly calculated
	if #PartPool <= 0 then
		UpdatePool(NeededNode)
	end
	local PosOper = {}
	local Connection = {}
	local Triangles = {}
	local UsedCounter = 0
	task.desynchronize()
	for i = 1, #registeredCharacters do
		local char = registeredCharacters[i]
		if char and char.Parent then
			local pos = char:GetPivot()
			local vel = (pos.Position - (char:GetAttribute('lastpos') or pos.Position))/dt
			task.synchronize() char:SetAttribute('lastpos', pos.Position) task.desynchronize()
			pos = pos + vel/8
			for	v = 1, 20 do
				UsedCounter += 1 -- it starts at 1
				local partInd = UsedCounter
				local part = PartPool[partInd]
				if typeof(part) ~= 'Instance' then
					if part then
						table.remove(PartPool, partInd) end -- something exist there, remove
					task.synchronize() part = VoidPart() task.desynchronize()
					table.insert(PartPool, partInd, part)
				elseif not part.ClassName:lower():match('part') then
					table.remove(PartPool, partInd)
					task.synchronize() part:Destroy() -- something exist there, remove
					part = VoidPart() task.desynchronize()
					table.insert(PartPool, partInd, part)
				end
				local ParticleDat = ParticleData[partInd]
				if typeof(ParticleDat) ~= 'table' then
					ParticleDat = {velocity = Vector3.new((math.random() - 0.5) * 2, 0.5 + math.random() * 1.5, (math.random() - 0.5) * 2),phase = math.random() * math.pi * 2,speed = 0.5 + math.random() * 1.5}
					ParticleData[partInd] = ParticleDat
				end
				ParticleDat.phase = ParticleDat.phase + dt * ParticleDat.speed
				ParticleDat.velocity = (ParticleDat.velocity + Vector3.new((math.random() - 0.5) * 0.1, (math.random() - 0.5) * 0.1, (math.random() - 0.5) * 0.1) * dt) * 0.98
				local a = (pos.Position - part.CFrame.Position)
				if a.Magnitude > 12 then	
					ParticleDat.velocity = ParticleDat.velocity + vel/3 * dt + (a.Unit * (a.Magnitude - 12)) * dt 
				end
				local PartPos = (typeof(part) == 'Instance' and (part.CFrame.Position - pos.Position).Magnitude < (10*math.sqrt(2)) and CFrame.new(part.Position + ParticleDat.velocity * 3 * dt + Vector3.new(math.sin(ParticleDat.phase) * 2,math.sin(ParticleDat.phase * 0.7) * 1.5,math.cos(ParticleDat.phase * 0.9) * 2)/80)) or pos * CFrame.new(math.random(-10, 10), math.random(-10, 10), math.random(-10, 10))
				if typeof(part) ~= 'Instance' then table.remove(PartPool, UsedCounter) continue end
				--just incase it somehow passed through, simulate
				if typeof(part) ~= 'Instance' then part = {CFrame = PartPos, Color = Color3.new(math.random(),math.random(),math.random()), Transparency = 0, Size = Vector3.new(1, 1, 1), Position = Vector3.new(1, 1, 1), Parent = workspace, Name = 'VFX'}
					function part:Destroy()
						part.Parent = nil -- stub
					end
					function part:MoveTo(CF: CFrame)
						if typeof(CF) ~= 'CFrame' then return end
						part.CFrame = CF
					end end
				PosOper[part] = {pos =  CFrame.lookAt(PartPos.Position, PartPos.Position + ParticleDat.velocity) or CFrame.new(), ind = UsedCounter or 1, color = part.Color or Color3.new(math.random(),math.random(),math.random()), Transparency = part.Transparency or 1}
			end
		end
	end
	local ICount = 0
	for part,data in PosOper do
		ICount += 1
		if typeof(part) ~= 'Instance' or typeof(data) ~= 'table' or typeof(data.pos) ~= 'CFrame' then print(data) continue end
		if typeof(data.ind) ~= 'number' then data.ind = 1 end
		if typeof(data.color) ~= 'Color3' then data.color = Color3.new(math.random(),math.random(),math.random()) end
		local Icounted = 0
		for i,v in PosOper do
			Icounted += 1
			if Icounted <= ICount then continue end -- don't reparse 
			-- only data was necessary to determine the linkage
			local pos = v.pos
			if typeof(pos) ~= 'CFrame' then print('no pos') continue end
			if typeof(v.color) ~= 'Color3' then v.color = Color3.new(math.random(),math.random(),math.random()) end
			local dist = (part.Position - pos.Position).Magnitude
			local Transparency = ((part.Transparency + (typeof(v.Transparency) == 'number' and v.Transparency or 0))/2) + dist/15
			if dist < 15 and Transparency < 1 then
				UsedCounter += 1
				table.insert(Connection, {Start = data.pos, End = v.pos, Transparency = Transparency, Color = part.Color:Lerp(v.color, 0.5)})
			end
		end
	end
	
	local ConnectionLookup = {}
	for _, conn in Connection do
		local key1 = posKey(conn.Start.Position)
		local key2 = posKey(conn.End.Position)
		if not ConnectionLookup[key1] then ConnectionLookup[key1] = {} end
		if not ConnectionLookup[key2] then ConnectionLookup[key2] = {} end
		ConnectionLookup[key1][key2] = conn
		ConnectionLookup[key2][key1] = conn
	end
	
	local TriangleCount = 0
	local triangles = {}
	
	for i, conn1 in Connection do
		local a1, b1 = conn1.Start.Position, conn1.End.Position
		local keyA1, keyB1 = posKey(a1), posKey(b1)
		-- Find third point connected to both a1 and b1
		if ConnectionLookup[keyA1] and ConnectionLookup[keyB1] then
			for keyC, conn2 in ConnectionLookup[keyA1] do
				if keyC == keyB1 then continue end
				if ConnectionLookup[keyB1] and ConnectionLookup[keyB1][keyC] then
					local conn3 = ConnectionLookup[keyB1][keyC]
					local c = conn2.Start.Position
					if posMatch(c, conn1.Start.Position) or posMatch(c, conn1.End.Position) then
						c = conn2.End.Position
					end
					local triKeys = {keyA1, keyB1, keyC}
					table.sort(triKeys)
					local triKey = table.concat(triKeys, '|')
					if not triangles[triKey] then
						triangles[triKey] = true
						local centroid = (a1 + b1 + c) / 3
						local adist,bdist,cdist = (a1 - centroid), (b1 - centroid), (c - centroid)
						local distt = (adist.Magnitude + bdist.Magnitude + cdist.Magnitude) 
						local avgdist = distt / 3
						if avgdist < 12 then
							TriangleCount += 1
							local transparency = math.min(((conn1.Transparency + conn2.Transparency + conn3.Transparency)/3) + avgdist/12, 1)
							if transparency < 1 then
							table.insert(Triangles, {
								a = a1,
								b = b1,
								c = c,
								color = conn1.Color:Lerp(conn2.Color, 0.5):Lerp(conn3.Color, 0.33),
								transparency = transparency
							}) end
						end
					end
				end
			end
		end
	end
	
	task.synchronize() -- tons of table parsing operations above
	UpdatePool(UsedCounter)
	local using = 0
	for i,v in PosOper do
		using += 1 -- forced early count to dismiss the null since already updated
		if typeof(i) ~= 'Instance' then continue end
		if typeof(v) ~= 'table' then continue end
		if typeof(v.pos) ~= 'CFrame' then continue end
		i.CFrame = v.pos
		i.Size = Vector3.new(0.1 + math.random() * 0.2, 0.1 + math.random() * 0.2, 0.1 + math.random() * 0.2)
	end
	for i,v in Connection do
		using += 1
		if typeof(v) ~= 'table' then print('con val not table') continue end
		if typeof(v.Start) ~= 'CFrame' then print('start not cf') continue end
		if typeof(v.End) ~= 'CFrame' then print('end not cf') continue end
		if typeof(v.Transparency) ~= 'number' then v.Transparency = 0 end
		if typeof(v.Color) ~= 'Color3' then v.Color = Color3.new(math.random(),math.random(),math.random()) end
		local Part = PartPool[using]
		if typeof(Part) ~= 'Instance' then print('con part not instance') continue end
		Part.Size = Vector3.new(0.1, 0.1, (v.Start.Position - v.End.Position).Magnitude)
		Part.CFrame = CFrame.lookAt((v.Start.Position + v.End.Position)/2, v.End.Position)
		Part.Transparency = v.Transparency or 0
		Part.Color = v.Color or Color3.new(math.random(),math.random(),math.random())
	end
	--for wedges Only
	UpdateWedgePool(TriangleCount * 2)
	local wedgeIdx = 1
	for i, tri in Triangles do
		if typeof(tri) ~= 'table' then continue end
		if typeof(tri.a) ~= 'Vector3' or typeof(tri.b) ~= 'Vector3' or typeof(tri.c) ~= 'Vector3' then continue end
		local w1 = WedgePool[wedgeIdx]
		local w2 = WedgePool[wedgeIdx + 1]
		if typeof(w1) ~= 'Instance' or typeof(w2) ~= 'Instance' then continue end
		local success, w1Result, w2Result = pcall(function()	return TriangleModule.draw3dTriangle(tri.a, tri.b, tri.c, workspace, w1, w2) end)
		if success then
			if typeof(w1Result) == 'Instance' then
				w1Result.Transparency = tri.transparency or 0.5
				w1Result.Color = tri.color or Color3.new(math.random(), math.random(), math.random())
				w1Result.Material = Enum.Material.Neon
			end
			if typeof(w2Result) == 'Instance' then
				w2Result.Transparency = tri.transparency or 0.5
				w2Result.Color = tri.color or Color3.new(math.random(), math.random(), math.random())
				w2Result.Material = Enum.Material.Neon
			end
		end
		wedgeIdx += 2
	end
	--clean up excess cuz somehow it fails to do for some
	UpdateWedgePool(wedgeIdx - 1)
end

-- Start the monitoring task
local function startMonitorTask()
	-- Only start if task doesn't exist
	if monitorTask then
		return
	end

	monitorTask = task.spawn(function()
		while #registeredCharacters > 0 do
			local dt = task.wait() -- Check every 0.5 seconds

			local region = getBoundRegion()
			if not region then
				-- Bound part not found, clear all and stop
				registeredCharacters = {}
				break
			end
			updVFX(dt)
			-- Check each registered character
			local allOutside = true
			local toRemove = {}

			for i, char in ipairs(registeredCharacters) do
				local inRegion = isCharacterInRegion(char, region)
				if inRegion then
					allOutside = false
				else
					-- Character is outside region, mark for removal
					table.insert(toRemove, i)
				end
			end

			-- Remove characters outside the region (in reverse to preserve indices)
			for i = #toRemove, 1, -1 do
				table.remove(registeredCharacters, toRemove[i])
			end

			-- If all characters are outside region, the loop will stop
			-- because #registeredCharacters will be 0
		end

		pcall(function() UpdatePool(0) end)
		pcall(function() UpdateWedgePool(0) end)
		table.clear(PartPool)
		table.clear(ParticleData)
		table.clear(WedgePool)
		-- Task finished, set to nil
		monitorTask = nil
	end)
end

-- Handle touch event
local function onTouch(otherPart)
	local character = otherPart.Parent
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	-- Check if already registered
	for _, char in ipairs(registeredCharacters) do
		if char == character then
			return -- Already registered
		end
	end

	-- Register the character
	table.insert(registeredCharacters, character)

	-- Start monitoring task if not already running
	startMonitorTask()
end

-- Setup the bound part connection
local function setupBound()
	local part = findBoundPart()
	if not part then
		warn("Bound part '" .. BOUND_NAME .. "' not found in Workspace")
		return false
	end

	part.Touched:Connect(onTouch)
	return true
end

-- Initial setup
setupBound()

-- Also watch for the bound part being added later
workspace.ChildAdded:Connect(function(child)
	if child.Name == BOUND_NAME then
		boundPart = child
		setupBound()
	end
end)

-- Handle bound part removal
workspace.ChildRemoved:Connect(function(child)
	if child.Name == BOUND_NAME then
		boundPart = nil
		-- Clear all registered characters when bound is removed
		registeredCharacters = {}
	end
end)