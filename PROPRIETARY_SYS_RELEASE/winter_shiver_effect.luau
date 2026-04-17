local timer = 0 repeat timer += task.wait(1) until (workspace:FindFirstChild('IsItRaining').Value == 1 or workspace.Chrismah.Value == true) or timer > 60
if timer > 60 then
	script:Destroy()
	return
end
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

-- Reference point for distance check (origin)
local REFERENCE_POSITION = Vector3.new(0, 0, 0)
local SHIVER_DISTANCE = 25

-- Tables to track affected characters and their welds/connections
local ActiveCharacters = {}
local WeldsInCharacter = {}
local Restorables = {}
local CharTimers = {}
local RootJointCache = {}
local isxmas=false
local cs = workspace.Chrismah 
local rn = workspace.IsItRaining
local rain=0
function close(cfa: CFrame, cfb: CFrame)
	return cfa and cfb and cfa.LookVector:Dot(cfb.LookVector) >= .99 and (cfa.Position - cfb.Position).Magnitude < 0.05
end

function collectWelds(model)  if typeof(model) ~= 'Instance' then return end
	local welds = {}
	for i, b in model:GetDescendants() do
		task.desynchronize()
		if b.Name == 'AccessoryWeld' then continue end
		if b:IsA("Weld") or b.ClassName:lower():match('motor6d') or table.find({"Snap", "Glue"},b.ClassName) then
			if b.Name:upper():match('ELBOW') or b.Name:upper():match('HIP') or b.Name:upper():match('WAIST') or b.Name:upper():match('KNEE') or b.Name:upper():match('ANKLE') then
				continue
			end
			table.insert(welds, b)
			if not Restorables[b] then
				task.synchronize()
				Restorables[b] = b.C0
			end
		end
	end
	return welds
end

function cleanupCharacter(char)  if typeof(char) ~= 'Instance' then return end
	if not table.find(ActiveCharacters, char) then return end
	if  WeldsInCharacter[char]  then
	for i, b in WeldsInCharacter[char] do
		if Restorables[b] then
			task.synchronize()
			b.C0 = Restorables[b]
			task.desynchronize()
			if close(b.C0, Restorables[b]) then
				Restorables[b] = nil
			end
		end
	end end
	task.desynchronize()
	WeldsInCharacter[char] = nil
	CharTimers[char] = nil
	RootJointCache[char] = nil
	table.remove(ActiveCharacters, table.find(ActiveCharacters, char))
end

function applyShiver(char, dt)
	task.desynchronize()  if typeof(char) ~= 'Instance' then return end
	if not WeldsInCharacter[char] or not char.Parent then
		cleanupCharacter(char)
		return
	end
	
	task.desynchronize()
	local mag = char:GetPivot().Position.Magnitude * (not isxmas and 1 or (rain >= 4 and (rain - 2)/1.5) or 1) * 1.25 - 31.25
	if not CharTimers[char] then
		local mag = char:GetPivot().Position.Magnitude 
		local rate = 1 / (0.5 + mag/500)
		CharTimers[char] = {timer = 0, rate = rate}
	end

	local timerData = CharTimers[char]
	timerData.timer = timerData.timer + dt

	local period = 2 * math.pi / timerData.rate
	if timerData.timer > period then
		timerData.timer = timerData.timer - period
	end

	local ctime = timerData.timer
	
	for a, b in WeldsInCharacter[char] do
		task.desynchronize()
		if b:IsA("Weld") or b.ClassName:lower():match('motor6d') or table.find({"Snap", "Glue"},b.ClassName) then
			local freq1 = 24 + math.random(-2,2)
			local freq2 = 48 + math.random(-4,4)
			local freq3 = 36 + math.random(-3,3)
			local burst = math.abs(math.sin(ctime * 2 + mag/100))
			local intensity = (0.5 + burst * 0.5) * mag/500
			local angleX = math.rad(math.cos(ctime * freq1) * intensity + math.sin(ctime * freq2) * intensity * 0.5)
			local angleY = math.rad(math.sin(ctime * freq2) * intensity + math.cos(ctime * freq3) * intensity * 0.3)
			local angleZ = math.rad(math.sin(ctime * freq3) * intensity * 0.7)
			local noiseX = (math.noise(ctime, mag) + math.random(-5,5)/10) * mag/25000
			local noiseY = (math.noise(ctime+1, mag) + math.random(-5,5)/10) * mag/25000
			local noiseZ = (math.noise(ctime+2, mag) + math.random(-5,5)/10) * mag/25000
			local C0 = Restorables[b]
				* (b.Name:upper():match("ROOT") and (CFrame.Angles(0,angleY,angleZ) + Vector3.new(noiseX, noiseY, 0)/2) or (CFrame.Angles(angleX, angleY, angleZ)
				+ Vector3.new(noiseX, noiseY, noiseZ)))
			task.synchronize()
			b.C0 = C0
		end
	end
end

cs:GetPropertyChangedSignal('Value'):Once(function()
	isxmas=cs.Value
end)
rn:GetPropertyChangedSignal('Value'):Once(function()
	rain=rn.Value
end)
function isFarEnough(char)
	task.desynchronize()  if typeof(char) ~= 'Instance' then return end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return false end
	return (hrp.Position - REFERENCE_POSITION).Magnitude > (SHIVER_DISTANCE / ((not isxmas) and 1 or (rain >=4 and (rain-2)/1.5) or 1))
end

function processCharacter(char)
	task.desynchronize() if typeof(char) ~= 'Instance' then return end
	if not char:IsA("Model") or WeldsInCharacter[char] or table.find(ActiveCharacters, char) then return end
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not humanoid or not hrp then return end
	if not WeldsInCharacter[char] then
		WeldsInCharacter[char] = collectWelds(char)
	end
	table.insert(ActiveCharacters, char)
end

function periodicCleanup()
	-- Remove characters that are no longer valid
	for _, char in ActiveCharacters do
		task.desynchronize()
		if not char.Parent or not char:FindFirstChild("HumanoidRootPart") then
			cleanupCharacter(char)
		end
	end
end

local timer = 0
-- Main loop
while script and workspace:FindFirstChild('IsItRaining') and (workspace:FindFirstChild('IsItRaining').Value == 1 or workspace.Chrismah.Value == true)  do
	task.desynchronize()
	local dt = task.wait(#ActiveCharacters <= 0 and 1 or #ActiveCharacters/100)
	timer += dt
	for i, player in Players:GetChildren() do
		task.desynchronize()
		if not player:IsA('Player') then continue end
		local char = player.Character
		if char and not char:GetAttribute('__Animated') and isFarEnough(char) then
			processCharacter(char)
			applyShiver(char, dt)	
		elseif char then
			cleanupCharacter(char)
		end
		if typeof(char) == 'Instance' then
			if not char:GetAttribute('NO_DIR') then
				task.synchronize()
				char:SetAttribute('NO_DIR', true)
			end
		end
		task.desynchronize()
		if char then
			local mag = (char:GetPivot().Position - Vector3.new(59.558, 2.5, -1.039)).Magnitude * 0.5 - 50
			local Previous = char:GetAttribute('__Htm') or 0
			local NowHTM = math.clamp(Previous + (mag/1500) * dt,0,1)
			if NowHTM > Previous and NowHTM > math.max(mag/300,0) then
				NowHTM = Previous
			end
			NowHTM = math.clamp(NowHTM, 0, 1)
			if math.abs(Previous - NowHTM) > .01 then
				task.synchronize()
				char:SetAttribute('__Htm', NowHTM)
				task.desynchronize()
			end
		end
	end
	if timer >= 60 then
		periodicCleanup() timer = 0
	end
end

task.synchronize()
script:Destroy()