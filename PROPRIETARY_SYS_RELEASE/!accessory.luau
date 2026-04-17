--solivion
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ACCESSORIES = ReplicatedStorage:WaitForChild('ACCESSORIES')

local foundu = {
	"glass", "shade", "eyewear", "eyecover" , "blindfold", "eye"
}

local introvertplus = {
	"box", "paperbag", "bag", "mask"
}

function ffcac(par, n, c)
	if typeof(par) ~= 'Instance' or typeof(n) ~= 'string' or typeof(c) ~= 'string' then return end
	for _, v in pairs(par:GetChildren()) do
		if v.Name:match(n) and (v.ClassName == c or v:IsA(c)) then
			return v
		end
	end
	return false
end

local function isitrsix(chr)
	return ffcac(chr, "Torso", 'BasePart') and not ffcac(chr, "UpperTorso", 'BasePart')
end

local function istsfaceacc(name)
	local lowerName = string.lower(name)
	for _, keyword in ipairs(foundu) do
		if string.find(lowerName, keyword) then
			return true
		end
	end
	return false
end

local function isOneoff(name)
	local lowerName = string.lower(name)
	for _, keyword in ipairs(introvertplus) do
		if string.find(lowerName, keyword) then
			return true
		end
	end
	return false
end

local function shuffleTable(tbl)
	for i = #tbl, 2, -1 do
		local j = math.random(1, i)
		tbl[i], tbl[j] = tbl[j], tbl[i]
	end
	return tbl
end

local function makeh(chr, accStuffs, attachmentPartName, namae)
	if typeof(accStuffs) ~= 'Instance' or accStuffs.ClassName ~= 'ModuleScript' or typeof(attachmentPartName) ~= 'string' then return end
	local attachmentPart = ffcac(chr, attachmentPartName, 'BasePart')
	if not attachmentPart then return true end
	
	local ran = pcall(function()
		local accessoryData = require(accStuffs)
		if not accessoryData then error('hell no') return end
		local accessory 
		pcall(function() accessory = Instance.new("Accessory") end)
		if typeof(accessory) ~= 'Instance' then pcall(function() accessory = Instance.new("Folder") end) end
		if typeof(accessory) ~= 'Instance' then pcall(function() accessory = Instance.new("Model") end) end
		if typeof(accessory) ~= 'Instance' then pcall(function() accessory = Instance.new("CFrameValue") end) end
		accessory.Name = namae or accessoryData.Name or accStuffs.Name or 'NO_NAME!'
		accessory.Parent = chr
		accessory:SetAttribute('_ACCESSORY', true)

		for i, v in accessoryData do
			local part = Instance.new('Part', accessory)
			part.Name = v.Name or 'NO'
			part.Color = v.Color or Color3.new(0,0,0)
			part.Material = v.Material or Enum.Material.SmoothPlastic
			part.Shape = v.Shape or Enum.PartType.Block
			part.Size = v.Size or Vector3.new()
			part.Transparency = math.clamp((v.Transparency or 0), 0, 1)
			part.CanCollide = false
			part.CFrame = attachmentPart.CFrame * (v.WeldC0 or CFrame.new())
			part.Anchored = false
			local w = Instance.new('Weld', part)
			w.Name = 'AccessoryWeld'
			w.Part0 = attachmentPart or part
			w.Part1 = part or attachmentPart
			w.C0 = (v.WeldC0 or CFrame.new())
		end
	end)
	
	return ran or false
end

local function randomie(chr)
	local headFolder = ACCESSORIES:FindFirstChild('Head')
	if not headFolder then return end
	
	local normieHeadacc = {}
	local Iwearamaskwithasmileforhoursatatime = {}
	local facecover = {}
	
	pcall(function()	
	for _, accStuffs in ipairs(headFolder:GetChildren()) do
		if accStuffs:IsA('ModuleScript') then
			if istsfaceacc(accStuffs.Name) then
				table.insert(facecover, accStuffs)
			elseif accStuffs:GetAttribute('ONEOFF') then
				table.insert(Iwearamaskwithasmileforhoursatatime, accStuffs)
			else
				table.insert(normieHeadacc, accStuffs)
			end
		end
	end
	end)	
	
	normieHeadacc = shuffleTable(normieHeadacc)
	Iwearamaskwithasmileforhoursatatime = shuffleTable(Iwearamaskwithasmileforhoursatatime)
	facecover = shuffleTable(facecover)
	
	local Hatz = {}
	for _, hat in ipairs(normieHeadacc) do
		table.insert(Hatz, hat)
		if math.random() > 0.95 and #Iwearamaskwithasmileforhoursatatime > 0 then
			local entry = math.random(1, #Iwearamaskwithasmileforhoursatatime)
			pcall(function()	math.randomseed(Random.new(entry or math.random()):NextNumber()) end)
			if not Iwearamaskwithasmileforhoursatatime[entry] then continue end
			table.insert(Hatz, Iwearamaskwithasmileforhoursatatime[math.random(1, #Iwearamaskwithasmileforhoursatatime)])
			table.remove(Iwearamaskwithasmileforhoursatatime, entry)
		end
	end
	for _, hat in ipairs(Iwearamaskwithasmileforhoursatatime) do
		table.insert(Hatz, hat)
	end

	pcall(function()	
	local numHats = math.random(1, math.min(3, #Hatz))
	local oneoff = nil
	for i = 1, numHats do if Hatz[i] and Hatz[i]:GetAttribute('ONEOFF') then oneoff = i break end end
	if not (oneoff and Hatz[oneoff] and typeof(Hatz[oneoff]) == 'Instance' and Hatz[oneoff]:IsA("ModuleScript")) then
	for i = 1, numHats do 
		if Hatz[i] then
			makeh(chr, Hatz[i], 'Head', Hatz[i].Name)
			if Hatz[i]:GetAttribute('ONEOFF') then break end
		end
	end else makeh(chr, Hatz[oneoff], 'Head', Hatz[oneoff].Name) end
	end)

	pcall(function()
	if #facecover > 0 and math.round(math.random(1, 2)) == 1 then
		local faceacc = false
		repeat task.wait()
			if #facecover <= 0 then break end
			local passed =	makeh(chr, facecover[1], 'Head', facecover[1].Name)
			if passed then faceacc = true break else table.remove(facecover, 1) end 
		until faceacc or #facecover <= 0
	end end)
	

	if isitrsix(chr) then
		local torsoFolder = ACCESSORIES:FindFirstChild('Torso')
		if torsoFolder and math.random(1, 2) == 1 then
			local torsoAccessories = torsoFolder:GetChildren()
			local torsoacc = false
			repeat task.wait()
			if #torsoAccessories > 0 and not torsoacc then
				local randomTorso = torsoAccessories[math.random(1, #torsoAccessories)]
				if randomTorso:IsA('ModuleScript') then
					if chr:FindFirstChild(randomTorso.Name) then continue end	
					local success =	makeh(chr, randomTorso, 'Torso', randomTorso.Name)
						if success then torsoacc = true break end	
				end
			else break end until false
		end
	end
end

script:WaitForChild('Event', 60)
if not script:FindFirstChild('Event') or not script:FindFirstChildOfClass('BindableEvent') then
	local event = Instance.new('BindableEvent', script)
	event.Name = 'Event'
end
local function levenshtein(str1, str2)
	-- Ensure inputs are strings
	if type(str1) ~= "string" or type(str2) ~= "string" then
		return math.huge
	end

	local len1, len2 = #str1, #str2

	-- If one string is empty, distance is the length of the other
	if len1 == 0 then return len2 end
	if len2 == 0 then return len1 end

	-- Create a 2D table for distances
	local matrix = {}
	for i = 0, len1 do
		matrix[i] = {}
		matrix[i][0] = i
	end
	for j = 0, len2 do
		matrix[0][j] = j
	end

	-- Fill the matrix
	for i = 1, len1 do
		for j = 1, len2 do
			local cost = (str1:sub(i, i) == str2:sub(j, j)) and 0 or 1
			matrix[i][j] = math.min(
				matrix[i - 1][j] + 1,      -- deletion
				matrix[i][j - 1] + 1,      -- insertion
				matrix[i - 1][j - 1] + cost -- substitution
			)
		end
	end

	return matrix[len1][len2]
end
script:FindFirstChildOfClass('BindableEvent').Event:Connect(function(chld, ...)
	local optiona = {...} -- all the other arguments from the thing (...)
	if chld:IsA('Model') and (chld:FindFirstChildOfClass('Humanoid') or typeof(chld:GetAttribute('__REGPLRID')) == 'number') then
		if (typeof(optiona) ~= "table" or #optiona <= 0)	then pcall(function() randomie(chld) end) else
			local blocklist = {}
			for i = 1, #optiona do
				local the
				local cato = ''
				if typeof(optiona[i]) == 'string' then
					--search for the first accessory with the name, filter out next time around
					local lastdist = 100
					for _,v in ACCESSORIES:GetChildren() do
						for _, module in v:GetChildren() do
							if module:IsA('ModuleScript') and not table.find(blocklist, module) then
								local distance = levenshtein(module.Name, optiona[i])
								if distance < lastdist then
									lastdist = distance cato = v.Name
								the = module end if lastdist <= 0 then
									cato = v.Name break end
							end
						end
					end
				elseif typeof(optiona[i]) == 'number' then
					local countdown = optiona[i]
					for _,v in ACCESSORIES:GetChildren() do
						for _, module in v:GetChildren() do
							if module:IsA('ModuleScript') then
								countdown -= 1
								if countdown <= 0 then cato = v.Name the = module
								break end
							end
						end
					end
				end
				if typeof(the) == 'Instance' and the:IsA('ModuleScript') and not table.find(blocklist, the) then pcall(function() makeh(chld, the, the.Parent.Name or cato, the.Name) table.insert(blocklist, the) end) end
			end
		end
 	end
end)