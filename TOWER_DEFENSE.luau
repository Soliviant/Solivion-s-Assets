--Solivion's Shitty Tower Defense Engine; 31st May 2026
-- I thin kcalculating significant time frame(for event snapping(dividing each tower's targeting/firng event was too unpredictable because there either is mob or not) if the task.wwait() was so long that it wwould trigger things multiple time, so I just put throttle for easy approach) is a bit too much
local SS = game:GetService('ServerStorage')
function ReNode(Name)
	local a = SS:WaitForChild(Name, 10)
	if not a then
		a = Instance.new('BindableEvent', SS) a.Name = Name
	elseif not a:IsA('BindableEvent') then
		a = Instance.new('BindableEvent', SS) a.Name = Name
	else
		return a
	end
	return a
end
local Bind_BASE = ReNode('__BASE')
local Bind_ENEMY = ReNode('__ENEMY')
local Bind_TOWER = ReNode('__TOWER')
local Bind_NODE = ReNode('__NODE')
local Bases, Mobs, Towers, Nodes = {}, {}, {}, {}
local Real = function(a) return typeof(a) == 'Instance' and typeof(a.Parent) == 'Instance' end
local UsedIDs = {}
local poolS = [[`~1234567890qwertyuiop[]\asdfghjkl;'zxcvbnm,./!@#$%^&*()_+QWERTYUIOP{}|ASDFGHJKL:"ZXCVBNM<>?]]
function GenerateID()
	local NID = ''
	for i = 1, math.random(1, 2000) do local a = math.random(1, string.len(poolS)) NID = NID..string.sub(poolS,a,a) end
	if table.find(UsedIDs, NID) then
		NID = GenerateID() -- should recurse until found
	end
	table.insert(UsedIDs, NID)
	return NID
end 
function _AddNode(Idx, Position, Part)
	if Nodes[Idx] then warn('Node '..Idx..' already exists') return end
	Nodes[Idx] = {Index = Idx, Position = Position, Connections = {}, LinkedBase = nil, Part = Part}
	return Nodes[Idx]
end
function _RemoveNode(Idx)
	if not Nodes[Idx] then return end
	for _, conn in Nodes[Idx].Connections do
		if Nodes[conn] then
			local t = Nodes[conn].Connections
			for i = #t, 1, -1 do if t[i] == Idx then table.remove(t, i) end end
		end
	end
	Nodes[Idx] = nil
end
function _ConnectNodes(A, B)
	if not Nodes[A] or not Nodes[B] then return end
	if table.find(Nodes[A].Connections, B) then return end
	table.insert(Nodes[A].Connections, B)
	table.insert(Nodes[B].Connections, A)
end
function _DisconnectNodes(A, B)
	if not Nodes[A] or not Nodes[B] then return end
	local tA = Nodes[A].Connections
	local tB = Nodes[B].Connections
	for i = #tA, 1, -1 do if tA[i] == B then table.remove(tA, i) end end
	for i = #tB, 1, -1 do if tB[i] == A then table.remove(tB, i) end end
end
--dfs
function getNodeType(nodeIdx, Team, EnemyTeam)
	local node = Nodes[nodeIdx]
	if typeof(node) ~= "table" or typeof(node.LinkedBase) == 'string' then return "clean" end
	if node.Team == EnemyTeam then return "enemy" -- their base, dangerous
	elseif node.Team ~= Team then return "neutral" end -- somebody's bases, not our target
	return "clean" -- our base
end
local MAX_PATHS =  10^4 -- 10,000 limit, very slow to compute, still little if you think about how many there could be
local NodeTraffic = {}
local TRAFFIC_DURATION = 1 -- jammr
function registerTrafficAndReturn(chosenPath, now) if typeof(now) ~= 'number' or typeof(chosenPath) ~= 'table' then return chosenPath end
	for i = 2, #chosenPath do
		NodeTraffic[chosenPath[i]] = now + TRAFFIC_DURATION
	end
	return chosenPath
end
function PathTo(startIdx, endIdx, Team, EnemyTeam, ignoreJammed)
	if startIdx == endIdx then return {startIdx} end
	if not Nodes[startIdx] or not Nodes[endIdx] then return {} end
	local allPaths = {}
	local now = os.clock()
	local function dfs(current, currentPath, visited, a)
		if #allPaths >= MAX_PATHS then return end
		if current == endIdx then
			if #allPaths % 10 == 0 then task.wait() end
			table.insert(allPaths, table.clone(currentPath))
			return
		end
		if a % 20 == 0 then task.wait() end
		local node = Nodes[current]
		if typeof(node) ~= 'table' then return end
		local sortedConnections = table.clone(node.Connections)
		table.sort(sortedConnections, function(a, b)
			local typeA = getNodeType(a, Team, EnemyTeam)
			local typeB = getNodeType(b, Team, EnemyTeam)
			local scoreA = (typeA == "clean" and 1) or (typeA == "neutral" and 2) or 3
			local scoreB = (typeB == "clean" and 1) or (typeB == "neutral" and 2) or 3
			return scoreA < scoreB
		end)
		for _, connIdx in sortedConnections do
			local isJammed = not ignoreJammed and NodeTraffic[connIdx] and NodeTraffic[connIdx] > now
			if not isJammed and not visited[connIdx] then
				visited[connIdx] = true
				table.insert(currentPath, connIdx)
				dfs(connIdx, currentPath, visited, a+1)
				table.remove(currentPath)
				visited[connIdx] = nil
			end
		end
	end
	dfs(startIdx, {startIdx}, {[startIdx] = true}, 0)
	if #allPaths == 0 then return {} end
	local tier1_perfect = {}
	local tier2_neutral = {}
	local tier3_enemy   = {}
	for aa, path in ipairs(allPaths) do
		local enemyCount = 0
		local neutralCount = 0
		if aa % 50 == 0 then task.wait() end 
		for i = 2, #path do
			local nType = getNodeType(path[i], Team, EnemyTeam)
			if nType == "enemy" then
				enemyCount = enemyCount + 1
			elseif nType == "neutral" then
				neutralCount = neutralCount + 1
			end
		end
		if enemyCount == 0 and neutralCount == 0 then
			table.insert(tier1_perfect, path)
		elseif enemyCount == 0 and neutralCount > 0 then
			table.insert(tier2_neutral, path)
		else
			table.insert(tier3_enemy, { path = path, enemyCount = enemyCount })
		end
	end
	if #tier1_perfect > 0 then return registerTrafficAndReturn(tier1_perfect[math.random(1, #tier1_perfect)], now)  end
	if #tier2_neutral > 0 then return registerTrafficAndReturn(tier2_neutral[math.random(1, #tier2_neutral)], now) end
	if #tier3_enemy > 0 then
		local minEnemyBases = math.huge
		for _, data in ipairs(tier3_enemy) do
			if data.enemyCount < minEnemyBases then
				minEnemyBases = data.enemyCount
			end
		end
		local bestTier3Choices = {}
		for _, data in ipairs(tier3_enemy) do
			if data.enemyCount == minEnemyBases then
				table.insert(bestTier3Choices, data.path)
			end
		end
		return registerTrafficAndReturn(bestTier3Choices[math.random(1, #bestTier3Choices)], now)
	end
	if ignoreJammed then return {} end -- just no hope
	--no path fall back
	return PathTo(startIdx,endIdx,Team,EnemyTeam, true) or {} 
end
-- Get Team's
function GT(What: string,Num: number) if typeof(Num) ~= 'number' or typeof(What) ~= 'string' then return {} end if not table.find({'mobs', 'bases', 'nodes'}, What:lower()) then return {} end
	local All = {}
	local CheckAgainst = What:lower() == 'bases' and Mobs or What:lower() == 'nodes' and GT("bases", Num) -- mob doesn't need to be checked against external
	for i,v in What:lower() == 'bases' and Bases or What:lower() == 'nodes' and Nodes or Mobs do
		if typeof(v) ~= 'table' then continue end -- nodes are tables with linked directions(connections) and linked base, also contain positional value
		if What:lower() == 'nodes' then
			for a,b in CheckAgainst do if b.Team == Num and b.ID == v.LinkedBase then table.insert(All, v) end end
		elseif What:lower() == 'mobs' then
			if v.Team == Num then table.insert(All, v) end
		elseif What:lower() == 'bases' then -- check against mob since they do share same table
			if v.Team == Num and not CheckAgainst[i] then table.insert(All, v) end
		end
	end return All or {}
end
function _NewBase(BInst: Instance, REQUEST: {any: any})
	if not Real(BInst) or typeof(Bases[BInst]) == 'table' then return end -- exist, you can simply just walk around it
	local Container = {Health = 100, MaxHealth = 100, Team = 0, Attribute = {}, ID = GenerateID()}
	if typeof(REQUEST) == 'table' then for i,v in Container do if typeof(REQUEST[i]) == typeof(v) then Container[i] = REQUEST[i] end end end
	BInst:SetAttribute('_BASE', true)
	BInst:SetAttribute('_BASE_ID', Container.ID)
	function Container:Damage(Num: number) if typeof(Num) ~= 'number' then return end if typeof(Container.Health) ~= 'number' then Container:Die() return end Container.Health = Container.Health - Num BInst:SetAttribute('_BASE_HP', Container.Health) if Container.Health <= 0 then Container:Die() end end
	function Container:SetStat(Key: any, Value: any) if typeof(Key) == 'nil' then return end Container[Key] = Value end  -- doesn't register dead, like a one hit challenge it you set the hp
	function Container:Die() pcall(function() Instance.new('Explosion',BInst).Position = BInst:IsA('BasePart') and BInst.Position or BInst:GetPivot().Position end) pcall(function() BInst.Anchored = false end) pcall(function() for i,v in BInst:GetDescendants() do if v:IsA('BasePart') then v.Anchored = false end end end) Bases[BInst] = nil table.clear(Container) Container = nil --[[add something here if u want, anim or sum]] end
	function Container:SetAttribute(Key: any, Value: any) if typeof(Key) == 'nil' then return end Container[Key] = Value end 
	Bases[BInst] = Container
	return Container
end
function _BaseEvent(Inst: Instance, A: any, B: any) if not Real(Inst) then warn('Invalid Instance Submitted') return end  if typeof(A) == 'nil' then if typeof(_NewBase(Inst, B)) ~= 'table' then if typeof(Bases[Inst]) == 'table' then warn('Already reigstered') return end warn('Failed To Register Base') return end end
	local Cont = Bases[Inst]
	if typeof(Cont) ~= 'table' then Cont = _NewBase(Inst, B) end if typeof(Cont) ~= 'table' then warn('Unable To Locate Contianer') return end
	if A == 'Damage' then
		Cont:Damage(B)
		return true
	elseif A == 'Set' then
		if typeof(B) ~= 'table' then warn('Son, B must be a table.') return end
		for i,v in B do
			Cont:SetStat(i,v)
		end
		return true
	end
end
function _FromID(ID: string) if typeof( ID) ~= 'string' then return end
	for i,v in Bases do
		if v.ID == ID then
			return v
		end
	end
end
function AllTeams(Except: {number})
	local ALLTEAMS = {}
	for i,v in Bases do
		if typeof(v) ~= 'table' or typeof(v.Team) ~= 'number' then continue end
		if typeof(Except) == 'table' and table.find(Except, v.Team) then continue end
		if not table.find(ALLTEAMS, v.Team) then table.insert(ALLTEAMS, v.Team) end
	end
	if #ALLTEAMS <= 0 then return {} end
	return ALLTEAMS
end
function RandomTeam(Except: {number})
	local ALLTEAMS = AllTeams(Except) or {}
	if #ALLTEAMS <= 0 then return {} end
	return ALLTEAMS[math.random(1, #ALLTEAMS)]
end
function _NewMob(Chr: Instance, REQUEST: {any: any}) if not Real(Chr) then return end
	--same as base but have Walking Nodes and Etc
	local BaseClass = _NewBase(Chr, REQUEST)
	if typeof(BaseClass) ~= 'table' then if typeof(Bases[Chr]) then warn('Mob Already Registered') return end warn('Failed To Register Mob') return end
	BaseClass["Speed"] = 16
	BaseClass['WalkInverted'] = false
	BaseClass['Progress'] = 0 -- should start at default
	BaseClass['Team'] = 0
	if typeof(REQUEST) == 'table' then for i,v in BaseClass do if typeof(REQUEST[i]) == typeof(v) then BaseClass[i] = REQUEST[i] end end end
	local OurTeam = BaseClass['Team'] or 0
	local Team_Nodes = GT('nodes', OurTeam)
	local NodeFound = #Team_Nodes > 0 and Team_Nodes[math.random(1, #Team_Nodes)] or nil
	if not NodeFound then -- our team dead bruh
		local idxs = {}
		for k, a in pairs(Nodes) do if typeof(a) ~= 'table' then continue end if typeof(a.LinkedBase ~= 'string') then table.insert(idxs, k) end end
		if #idxs == 0 then warn('Unable To Pick A Node!') return end
		NodeFound = Nodes[idxs[math.random(1, #idxs)]]
	end
	BaseClass['NodeCurrent'] = NodeFound.Index
	BaseClass['Position'] = NodeFound.Position
	local checked = {OurTeam} -- by default we don't friendly fire
	local NodePath = {}
	local EnemyTeam = RandomTeam(checked)
	local NodeTheirs
	local Their_Nodes
	task.desynchronize()
	while #(AllTeams(checked) or {}) > 0 and #(NodePath or {}) <= 0 do
		EnemyTeam = RandomTeam(checked)
		Their_Nodes = EnemyTeam and GT('nodes', EnemyTeam) or {}
		local RIDX = #Their_Nodes > 0 and math.random(1, #Their_Nodes)
		NodeTheirs = #Their_Nodes > 0 and Their_Nodes[RIDX] or nil
		if not NodeTheirs then -- their team is already dead bruh
			local idxs = {}
			for k, a in pairs(Nodes) do if typeof(a) ~= 'table' then continue end if typeof(a.LinkedBase ~= 'string') then table.insert(idxs, k) end end
			if #idxs == 0 then warn('Unable To Pick Target Node!') continue end
			NodeTheirs = Nodes[idxs[math.random(1, #idxs)]]
		end
		if not NodeTheirs then
			table.insert(checked, EnemyTeam)
		else
			NodePath = PathTo(NodeFound.Index, NodeTheirs.Index, OurTeam) 
		end
	end  task.synchronize()
	if not NodeTheirs then warn('NO TARGET!') return end
	local Targeted = NodeTheirs.LinkedBase and _FromID(NodeTheirs.LinkedBase) or nil
	if Targeted then BaseClass['DamageAt'] = Targeted end
	BaseClass['NodeNext'] = NodePath
	function BaseClass:Die() Mobs[Chr] = nil Bases[Chr] = nil table.clear(BaseClass) BaseClass = nil pcall(function() Chr.Parent = script end) end -- override
	Mobs[Chr] = BaseClass -- last part
end
function _MobEvent(Chr: Instance, A: any, B: any)
	local Inherited = _BaseEvent(Chr, A, B)
	if Inherited then return end
	-- aa I don't knwo whwat to add aaa
end
-- TOWER DOESNT USE THE SAME BASE CUZ NO HP WAAA
function _NewTower(TInst: Instance, REQUEST: {any: any})
	if not Real(TInst) or typeof(Towers[TInst]) == 'table' then return end
	local Container = {Damage = 10, Range = 30, FireRate = 1, LastFired = 0, Team = 0, Level = 1, SplashRadius = 0, ID = GenerateID()}
	if typeof(REQUEST) == 'table' then for i,v in Container do if typeof(REQUEST[i]) == typeof(v) then Container[i] = REQUEST[i] end end end
	TInst:SetAttribute('_TOWER', true)
	TInst:SetAttribute('_TOWER_ID', Container.ID)
	function Container:Upgrade() Container.Level += 1 Container.Damage = Container.Damage * 1.5 Container.Range = Container.Range * 1.2 Container.FireRate = Container.FireRate * 0.85 end
	function Container:Die()
		Towers[TInst] = nil
		table.clear(Container)
		pcall(function() TInst:Destroy() --[[ts not pooled so we trashed it.]] end)
		Container = nil
	end
	Towers[TInst] = Container
	return Container
end
function _TowerEvent(Inst: Instance, A: any, B: any)
	if not Real(Inst) then warn('Invalid Instance Submitted') return end
	if A == nil then
		if typeof(_NewTower(Inst, B)) ~= 'table' then
			if typeof(Towers[Inst]) == 'table' then warn('Already registered') return end
			warn('Failed To Register Tower') return
		end
		return
	end
	local Cont = Towers[Inst]
	if typeof(Cont) ~= 'table' then Cont = _NewTower(Inst, B) end
	if typeof(Cont) ~= 'table' then warn('Unable To Locate Tower Container') return end
	if A == 'Upgrade' then
		Cont:Upgrade()
		return true
	elseif A == 'Remove' then
		Cont:Die()
		return true
	elseif A == 'Set' then
		if typeof(B) ~= 'table' then warn('B must be a table.') return end
		for i,v in B do Cont[i] = v end
		return true
	end
end

Bind_NODE.Event:Connect(function(A, B, C)
	if A == 'Add' then
		_AddNode(B, C.Position or Vector3.zero, C.Part or nil)
		if C.LinkedBase then Nodes[B].LinkedBase = C.LinkedBase end
		if C.Connections then for _, conn in C.Connections do _ConnectNodes(B, conn) end end
	elseif A == 'Remove' then
		_RemoveNode(B)
	elseif A == 'Connect' then
		_ConnectNodes(B, C)
	elseif A == 'Disconnect' then
		_DisconnectNodes(B, C)
	elseif A == 'LinkBase' then
		if Nodes[B] then Nodes[B].LinkedBase = C end
	end
end) -- end main loop
Bind_BASE.Event:Connect(_BaseEvent)
Bind_ENEMY.Event:Connect(function(Inst, A, B)
	if A == 'Add' then
		_NewMob(Inst, B)
	elseif A == 'Remove' then
		local cont = Mobs[Inst]
		if cont then cont:Die() end
	else
		_MobEvent(Inst, A, B)
	end
end)
Bind_TOWER.Event:Connect(_TowerEvent)

-- I was met with so many race condition so this should signal u
script:SetAttribute('_READY', true)

function FindNearestMob(towerPos, range, team)
	local best, bestDist = nil, range
	for inst, mob in Mobs do
		if mob.Team == team then continue end
		local mobPos = mob.Position or (inst:IsA('BasePart') and inst.Position) or nil
		if not mobPos then continue end
		local dist = (towerPos - mobPos).Magnitude
		if dist < bestDist then best = inst bestDist = dist end
	end
	return best
end
function FireProjectile(towerInst, targetInst, damage, splash)
	local tPos = towerInst:IsA('BasePart') and towerInst.Position or (towerInst:IsA('Model') and towerInst:GetPivot().Position) or nil
	local mPos = targetInst:IsA('BasePart') and targetInst.Position or (targetInst:IsA('Model') and targetInst:GetPivot().Position) or nil
	if not tPos or not mPos then return end
	local bullet = Instance.new('Part')
	bullet.Size = Vector3.new(0.5, 0.5, 0.5)
	bullet.Shape = Enum.PartType.Ball
	bullet.Color = Color3.new(1, 1, 0)
	bullet.Material = Enum.Material.Neon
	bullet.Anchored = true
	bullet.CanCollide = false
	bullet.Position = tPos
	bullet.Parent = workspace
	local dir = (mPos - tPos).Unit
	local dist = (mPos - tPos).Magnitude
	local speed = 150
	local traveled = 0
	task.spawn(function()
		while traveled < dist and bullet.Parent do
			local dt = task.wait()
			local step = speed * dt
			traveled += step
			bullet.CFrame = bullet.CFrame + dir * step
		end
		if bullet.Parent then
			if splash and splash > 0 then
				for inst, mob in Mobs do
					local mp = mob.Position or (inst:IsA('BasePart') and inst.Position) or nil
					if mp and (mp - bullet.Position).Magnitude <= splash then
						_MobEvent(inst, 'Damage', damage)
					end
				end
			else
				_MobEvent(targetInst, 'Damage', damage)
			end
			bullet.Parent = nil
		end
	end)
end
task.spawn(function()
	while true do
		local dt = task.wait()
		for inst, mob in Mobs do
			if typeof(mob.Health) ~= 'number' or mob.Health <= 0 then continue end
			local path = mob.NodeNext
			if not path or #path == 0 then
				-- reached the end and kinda dies
				if typeof(mob.DamageAt) == 'table' and not mob.ded then pcall(function() mob.ded = true end) pcall(function() mob.DamageAt:Damage(mob.Health or 10) end) end
				mob:Die()
				if inst.Parent then inst.Parent = nil end
				continue
			end
			local targetIdx = path[1]
			local targetNode = Nodes[targetIdx]
			if not targetNode then
				table.remove(path, 1)
				continue
			end
			local targetPos = targetNode.Position
			local mobPos = mob.Position
			local moveDir = targetPos - mobPos
			local moveDist = moveDir.Magnitude
			local step = (mob.Speed or 16) * dt
			if step >= moveDist then
				mob.Position = targetPos
				mob.NodeCurrent = targetIdx
				table.remove(path, 1)
			else
				mob.Position = mobPos + moveDir.Unit * step
			end
			if inst:IsA('Model') and inst.PrimaryPart then
				inst:PivotTo(CFrame.new(mob.Position))
				elseif inst:IsA('BasePart') then
				inst.Position = mob.Position
			end
		end
		local now = os.clock()
		for inst, tower in Towers do
			if (now - tower.LastFired) < tower.FireRate then continue end
			local tPos = inst:IsA('BasePart') and inst.Position or (inst:IsA('Model') and inst:GetPivot().Position) or nil
			if not tPos then continue end
			local target = FindNearestMob(tPos, tower.Range, tower.Team)
			if target then
				tower.LastFired = now
				FireProjectile(inst, target, tower.Damage, tower.SplashRadius)
			end
		end
	end
end)
--Soliviant From Youtube 5/31/2026; Solivion
