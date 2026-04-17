--mirror of the command in state sys. for emergency
-- soli 
local wordmodule = script:FindFirstChildOfClass('ModuleScript') and require(script:FindFirstChildOfClass('ModuleScript'))
local wordlist = (wordmodule and wordmodule.Words) or {}
local morseCode = {
	["A"] = ".-",      ["B"] = "-...",    ["C"] = "-.-.",    ["D"] = "-..",
	["E"] = ".",       ["F"] = "..-.",    ["G"] = "--.",     ["H"] = "....",
	["I"] = "..",      ["J"] = ".---",    ["K"] = "-.-",     ["L"] = ".-..",
	["M"] = "--",      ["N"] = "-.",      ["O"] = "---",     ["P"] = ".--.",
	["Q"] = "--.-",    ["R"] = ".-.",     ["S"] = "...",     ["T"] = "-",
	["U"] = "..-",     ["V"] = "...-",    ["W"] = ".--",     ["X"] = "-..-",
	["Y"] = "-.--",    ["Z"] = "--..",
	["1"] = ".----",   ["2"] = "..---",   ["3"] = "...--",   ["4"] = "....-", 
	["5"] = ".....",   ["6"] = "-....",   ["7"] = "--...",   ["8"] = "---..", 
	["9"] = "----.",   ["0"] = "-----",
	[" "] = " "
}
Players = game:FindFirstChildOfClass('Players') or game:GetService('Players')
local Uniheadsys 
task.spawn(function()
	pcall(
		function()
			task.synchronize()
			Uniheadsys = require((game:FindFirstChildOfClass('ServerStorage') or game:GetService('ServerStorage')):FindFirstChild('FacialUnification'))
		end
	)
end)

local function filterAndSort(inputTable)
	local seen = {}      -- Helper table to track duplicates
	local uniqueList = {} -- The final list without duplicates

	for _, str in ipairs(inputTable) do
		if not seen[str] then
			seen[str] = true
			table.insert(uniqueList, str)
		end
	end
	table.sort(uniqueList)

	return uniqueList
end
function randomStr()
	local randomstring = ''
	local possible = "+=_-*#%^&*(){}[]<>/?|:;:,.\~!@ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
	for i = 1, math.random(10,100) do
		local chosen = math.random(1, #possible)
		randomstring = randomstring..string.sub(possible, chosen, chosen)
	end
	return randomstring
end
local KeyChain = {}
function GenKey(forinstance: Instance)
	local condition = false
	local key 
	repeat key = randomStr() if (typeof(forinstance) ~= 'Instance' or not forinstance.Parent)then break end condition = not table.find(KeyChain, key) for i,v in forinstance.Parent:GetChildren() do if v:GetAttribute('__KEY') == key then condition = false break end end until condition
	return key
end
local function parseAssetId(input: number | string): number?
	if type(input) == "number" then
		return input
	end
	if type(input) == "string" then
		local id
		pcall(function()
			id = input:match("catalog/(%d+)")
				or input:match("assets/(%d+)")
				or input:match("asset/(%d+)")
				or input:match("marketplace/asset/(%d+)")
				or input:match("%?id=(%d+)")
				or input:match("^(%d+)$")
		end)
		if id then
			return tonumber(id)
		end
	end

	return nil
end
function fromPath(string, verifkey: string?)
	local path = string:split(".")
	local current = game
	local search = current
	for i = 1, #path do
		search = current
		current = current:FindFirstChild(path[i])
		if not current and not verifkey then return elseif not current and verifkey then break end
	end
	if verifkey and (not current or verifkey ~= current:GetAttribute('__KEY')) then for i,v in search:GetChildren() do if v:GetAttribute('__KEY') == verifkey then return v end end return nil end
	return current
end
local function SAFELOAD(assetId, assetTypeFilter)
	sync_()
	local MarketplaceService = game:GetService("MarketplaceService")
	local InsertService = game:GetService("InsertService")
	if typeof(assetId)~= 'string' and assetId then
		assetId = tostring(assetId)
	elseif not assetId then return end
	-- Parse asset ID
	local parsedId = parseAssetId(assetId) or tonumber(assetId)
	if not parsedId then
		Debug_Display("SAFELOAD: Invalid asset ID")
		return nil
	end

	-- Get product info
	local success, productInfo = pcall(function()
		return MarketplaceService:GetProductInfoAsync(parsedId)
	end)

	if not success or typeof(productInfo) ~= "table" then
		Debug_Display("SAFELOAD: Failed to get product info")
		return nil
	end

	-- Check asset type
	local assetType = tonumber(productInfo.AssetTypeId) or 0
	if not table.find(assetTypeFilter, assetType) then
		Debug_Display("SAFELOAD: Asset type " .. assetType .. " not allowed")
		return nil
	end
	-- Check creator info exists
	local creator = productInfo.Creator
	if typeof(creator) ~= "table" then
		Debug_Display("SAFELOAD: Invalid creator info")
		return nil
	end

	-- STRICT CHECK for 2D clothing (Shirt=11, Pants=12, TShirt=2)
	local isClothing = assetType == 11 or assetType == 12 or assetType == 2

	if isClothing then
		-- Must be Roblox official (CreatorId = 1) OR verified badge
		local isRobloxOfficial = tonumber(creator.Id or 0) == 1
		local isVerified = creator.HasVerifiedBadge == true

		if not isRobloxOfficial and not isVerified then
			Debug_Display("SAFELOAD: 2D clothing must be from Roblox or verified creator")
			return nil
		end
		
		if workspace.Name:lower():match('standard') and not isRobloxOfficial then
			return nil
		end
		
		-- Additional strict checks for clothing
		if productInfo.IsForSale ~= true and not isRobloxOfficial then
			Debug_Display("SAFELOAD: Clothing asset not properly published")
			return nil
		end
	end

	-- Load the asset
	local loadSuccess, asset = pcall(function()
		return InsertService:LoadAsset(parsedId)
	end)

	if not loadSuccess then
		Debug_Display("SAFELOAD: Failed to load asset")
		return nil
	end

	return asset
end
local MajorOperationProcessing: boolean = false
local ConnectedChats: {[Player?]: RBXScriptConnection} = {}
function trim(s)
	if typeof(s) ~= 'string' then return '' end
	return s:match("^%s*(.-)%s*$")
end
CommandList = {
	--{Command = "!togglerandomfont", Arguments = "{{Toggle random chat font}}"},
	{Command = "!sticker", Arguments = "{{Face Sticker; Format like face for the first argument, but the rest? %Transparency=NumberHere %Color3=R,G,B (not to mention RGB is 0-255) %UVScale=VC2:1,1 %UVOffset=VC2:0,0... yadda yadda, look in the Decal class, you could set some!}}"},
	{Command = "!face", Arguments = "{{wear face: EYES MOUTHS BROWS; invalid for nothing; number for choosing via index; string search via words}}"},
	{Command = "!wear", Arguments = "{{wears accessory by ID, privateserver only}}"},
	{Command = "!unchar", Arguments = "Removes linked character from the Player's Character slot if found invalid."},
	{Command = "!unwear", Arguments = "{{removes all !wear'ed accessories}}"},
	{Command = "!fix_head", Arguments = "{{offset the head like regular head before dynamic head}}"},
	{Command = "!float_head", Arguments = "{{offset the head like the Dynamic head}}"},
	{Command = "!replacehead_alt", Arguments = "{{a static fall back, fork of pixelwizard75's Code, my mesh}}"},
	{Command = "!replacehead", Arguments = "{{Replace dynamic head with Classic ones, Powered by 'FacialUnification' Version 1.4}}"},
	{Command = "!bodycolor", Arguments = "{{For classic avatar which utilizes BodyColor instance to represent clothings!}}"},
	{Command = "!clear_anim", Arguments = "{{Clear the Motor6Ds' transform CFrame.}}"},
	{Command = "!bgr6", Arguments = "{{BadGameplay, R6 edition, Need Custom Controller (!Alt_Control)}}"},
	{Command = "!bgrig", Arguments = "{{same as bgr6 but Meshed and support 2D clothing}}"},
	{Command = "!blocky", Arguments = "{{Make head blocky}}"},
	{Command = "!shirt", Arguments = "{{wear shirt if u don't have one, ONLY IN PRIVATE SERVER}}"},
	{Command = "!pants", Arguments = "{{wear pants if u don't have one, ONLY IN PRIVATE SERVER}}"},
	{Command = "!blockh", Arguments = "{{attach a block to the head incase mesh didn't load}}"},
	{Command = "!random_accessory", Arguments = "{{Give you random accessory, stack btw}}"},
	{Command = "!remove_accessory", Arguments = "{{Remove accessory using name}}"},
	{Command = "!remove_all_accessory", Arguments = "{{Remove accessory using name}}"},
	{Command = "!accessory", Arguments = "{{Give you accessory}}"},
	{Command = "!safechatwordlist", Arguments = "{{get list of available vocab for safechat}}"},
	{Command = "!offset_relative", Arguments = "Argument >> [Dimension(X,Y,Z), Section(HEAD, ARM, LEG)] : {{A Power-User Solution To Private Server Limb Offset Modification (Will Make This Affect The Public Server Animation Soon)}}"},
	{Command = "!alt_ui", Arguments = "{{Use another Stance controller UI}}"},
	{Command = "!no_anim", Arguments = "{{Retro Roblox Animate Will Replace Animation Based Animate.}}"},
	{Command = "!morse", Arguments = "{{get morsecode translation of any following string.}}"},
	{Command = "!subtosafechat", Arguments = "{{get safechat messages delivered to your log in real time.}}"},
	{Command = "!safechatlog", Arguments = "{{view up 100 safechat messages into the past}}"},
	{Command = "!safechat", Arguments = "{{word list approved, put a single word behind, one at a time, can form quite a hefty line.}}"},
	{Command = "!serverinfo", Arguments = "{{view server's current status}}"},
	{Command = "!seathelper", Arguments = "{{Get An Item That Helps You Back In A Seat, Incase you fell off a boat}}"},
	{Command = "!reset", Arguments = "<<Reset yourself>>"},
	{Command = "!experimental", Arguments = "{{teleport to the old version of the game(modified to be atleast playable due to massive lag spike)}}"},
	{Command = "!sitanchor", Arguments = "<<!SitAnchor: Sit on the nearby ground>>"},
	{Command = "!r6", Arguments = "<<become R6 character>>"},
	{Command = "!r15", Arguments = "<<become R15 character>>"},
	{Command = "!relative", Arguments = "CFrame; only number(under 0.25 in all axis)"},
	{Command = "!offset_lowertorso", Arguments = "CFrame; only number(under 0.25 in all axis)"},
	{Command = "!offset_head", Arguments = "CFrame; only number(under 0.5 in all axis)"},
	{Command = "!offset_arm", Arguments = "CFrame; only number(under 0.5 in all axis)"},
	{Command = "!offset_leg", Arguments = "CFrame; only number(under 0.5 in all axis)"},
	{Command = "!unstuck", Arguments = "<<unstuck and teleport above the ground>>"},
	{Command = "!leave", Arguments = "<<Kick yourself from the game>>"},
	{Command = "!rejoin", Arguments = "<<Rejoin the game>>"},
	{Command = "!reserve", Arguments = "(Both can be 'SAME' or Number); [[FUN]] [[ISITRAINING]]"},
	{Command = "!changechar", Arguments = "[[OUTFIT ID]]"},
	{Command = "!trip", Arguments = "<<Trip Yourself>>"},
	{Command = "!tospawn", Arguments = "<<TP to spawn, with small cooldown>>"},
	{Command = '!help', Arguments = "Introduction to '!' Commands"},
	{Command = '!faker6', Arguments = "<<Become Fake R6 Character with R15 rigs>>"},
	{Command = '!offset_relative_y', Arguments = 'Set IF Offset Will Relate to Y as an inverse or no'},
	{Command = '!rotation_relative', Arguments = 'Changes How Offset_ Rotation Works'},
	{Command = '!ratelimitanim', Arguments = '1-60'},
	{Command = '!joinrandom', Arguments = 'Self-Explanatory'},
	{Command = '!lockjoint', Arguments = 'Lock R15 Limbs, Best used with Oldschool Animation Pack'},
	{Command = '!mute', Arguments = 'Mute Notifications'},
	{Command = '!nodisturb', Arguments = 'Mute Notifications'},
	{Command = "!sit", Arguments = "<<!Sit: Sit unanchored>>"},
	{Command = "!listcmd", Arguments = "<<Raw List of all the commands>>"},
	{Command = "!stophandler", Arguments = "<<Raw List of all the commands>>"},
	{Command = "!pausehandler", Arguments = "temporarily pause the handler, best for reducing pings caused by handlers when you don't need it"},
	{Command = "!setscale", Arguments = "<<Number>>; Set your scale with the limit of 0.8-1.2"},
	{Command = "!destroycharacter", Arguments = "Destroy your character, Only respawn with '!re'"},
	{Command = '!offset_lowertorso', Arguments = "CFrame; only number(under 0.25 in all axis)"},
	{Command = '!storage', Arguments = "Open Storage GUI With All the saved tool slots"},
	{Command = '!saveto', Arguments = "!saveto [Slot number: {Whole Number Up To 10}] [Tool Name / Leave Nil For Equipped Tool]"},
	{Command = '!takeout', Arguments = "!takeout [Slot number: {Whole Number Up To 10}]"},
	{Command = '!badgameplay', Arguments = "makes the gameplay server based(not recommended)"},
	{Command = '!gift', Arguments = "[Target Player] [Tool or leave nil for in-hand]"},
	{Command ='!displayname', Arguments = "!displayname [[string]], the name will be filtered by TextService"},
	{Command ='!censor', Arguments = "toggle censor on your Character's head, useful if they're dynamic heads."}
}
local CommandsTable = {
	--[['!no_anim',
	'!clear_anim',]]
	'!random_accessory',
	'!remove_accessory',
	'!accessory',
	'!replacehead_alt',
	'!replacehead',
	'!bodycolor',
	'!safechatwordlist',
	'!morse',
	'!safechatlog',
	'!subtosafechat',
	'!safechat',
	'!bbchat',
	'!gift', '!offset_head', '!customchar', --allow choosing from generated r6 or r15
	--{'!badgameplay'},
	'!serverinfo',
	'!seathelper',
	--{"!experimental"},
	"!cmdlist",
	"!listcmd",
	"!cmd",
	"!pausehandler",
	--{"!stophandler"},
	"!setscale",
	"!scale",
	--{"!destroycharacter"},
	"!help",
	"!mute",
	"!nodisturb",
	"!offset_relative_y",
	"!offset_relative",	
	"!ratelimitanim",
	"!lockjoint",
	"!offset_arm",
	"!offset_leg",
	"!sitanchor",
	--{"!rejoin"},
	--{"!joinrandom"},
	--{"!reserve"},
	"!unstuck",
	--{"!leave"},
	"!faker6",
	"!R6",
	"!R15",
	"!reset",
	"!tospawn",
	"!spawn",
	"!char",
	"!changechar",
	"!trip",
	'!offset_lowertorso',
	'!displayname'
}

function Matchedcmd(String: string): boolean
	if not String then return false end
	for i,v in CommandsTable do
		if String:sub(#v):lower():match(v:lower()) then
			return true
		end
	end
	return false
end

local RAWTEXT: string
local CMD_RAWTEXT: string
local Commandsa = {}
for i,v in CommandList do
	table.insert(Commandsa,v.Command)
end
local function newMatrix(N, M)
	local mt = {}
	for i = 0, N do
		mt[i] = {}
		for j = 0, M do
			mt[i][j] = 0
		end
	end
	return mt
end
function LevenshteinDistance(strA: string, strB: string): number
	--if s1 == nil or s2 == nil or s1 == '' or s2 == '' then return 100 end
	if not strA or not strB or math.abs(#strA - #strB) > #strA/2 or math.abs(#strA - #strB) > #strB/2 then return 100 end
	local rows = string.len(strA) 
	local cols = string.len(strB) 
	if rows == 0 then --Length of a is 0? The distance is just the length of b, because it would take that many substitutions to make b
		return cols
	elseif cols == 0 then 
		return rows
	elseif strA == strB then --Same string? The distance is 0
		return 0
	end
	local matrix = newMatrix(rows, cols) --Create a matrix or 2D array

	--Initialize Matrix
	for i = 1, rows do
		matrix[i][0] = i
	end
	for j = 1, cols do
		matrix[0][j] = j
	end

	for i = 1, rows do --If you initialized your matrix with 1s instead of 0s, start at 2 instead of 1 here
		for j = 1, cols do
			if (strA:byte(i) == strB:byte(i)) then
				--If the two characters in both strings are the same
				matrix[i][j] = matrix[i-1][j-1]
			else
				local insertion = matrix[i][j-1] + 1
				local deletion = matrix[i - 1][j] + 1
				local subsitution = matrix[i - 1][j - 1] + 1

				matrix[i][j] = math.min(insertion, deletion, subsitution)
			end


		end
	end
	return matrix[rows][cols], matrix
end
local Soundcloud: {number} = {DOWNED = 4516507682, Scream = 8395374561 ,yap = 9091395418 , TRAUMA = 7076366171, TRAUMA_LEVEL_EXCEED = 1845391028}
-- Function to check if two strings are similar based on a threshold
local function StringIsSimilar(s1, s2, threshold)
	if not s1 or not s2 then return false end
	threshold = not threshold and 5 or math.ceil(threshold)
	local distance, matrix = LevenshteinDistance(s1, s2)
	return distance <= (threshold or 5), distance
end
local _issynced = true

local Joints = {}
function CreateWeldIfNeeded(AnimatedCharacter: Model, partName: string?, parentName: string?, part0Name: string?, part1Name: string?, weldName: string?, startcframe: CFrame?)
	if typeof(AnimatedCharacter) ~= 'Instance' then return end
	if not partName then partName = 'DICTIONARY_SLOT' end
	if (typeof(part1Name) ~= 'string' and typeof(part1Name) ~= 'Instance') or (typeof(part0Name) ~= 'string' and typeof(part0Name) ~= 'Instance') then return end
	if not Joints[AnimatedCharacter] then Joints[AnimatedCharacter] = {} Joints[AnimatedCharacter].destroycon = AnimatedCharacter.Destroying:Once(function() pcall(function() Joints[AnimatedCharacter].destroycon:Disconnect() end) Joints[AnimatedCharacter] = nil end) end
	if not Joints[AnimatedCharacter][partName] then
		task.synchronize()
		local newWeld = Instance.new('Weld')
		Joints[AnimatedCharacter][partName] = newWeld
		pcall(function()
		if partName:match('Hip') or partName:match('Root') then newWeld.Enabled = false end
		newWeld.Parent = typeof(parentName) == 'Instance' and parentName or parentName and FindFirstChildOfNameAndClass(AnimatedCharacter, parentName, 'BasePart') or AnimatedCharacter
		newWeld.Part1 = typeof(part1Name) == 'Instance' and part1Name or part1Name and FindFirstChildOfNameAndClass(AnimatedCharacter, part1Name, 'BasePart') or FindFirstChildOfNameAndClass(AnimatedCharacter, 'UpperTorso', 'BasePart') or FindFirstChildOfNameAndClass(AnimatedCharacter, 'Torso', 'BasePart')
		newWeld.Part0 = typeof(part0Name) == 'Instance' and part0Name or part0Name and FindFirstChildOfNameAndClass(AnimatedCharacter, part0Name, 'BasePart') or newWeld.Part1 or FindFirstChildOfNameAndClass(AnimatedCharacter, 'UpperTorso', 'BasePart') or FindFirstChildOfNameAndClass(AnimatedCharacter, 'Torso', 'BasePart') or nil
		--print(tostring(newWeld.Parent)..','..tostring(newWeld.Part1)..','..tostring(newWeld.Part0)..partName)
		newWeld.C0 = startcframe or CFrame.new()
		if newWeld.Part1.Name:match('UpperArm') then
			local SizeA: Vector3 = newWeld.Part1.Size
			local SizeB: Vector3 = newWeld.Part0.Size
			newWeld.C1 = CFrame.new(0,(SizeB.Y-SizeA.Y * 2)/2,0)
		end
		newWeld.Name = weldName or '__PLACEHOLDER'
		end)
		return newWeld
	end
end
function lockin(CFRAME: CFrame)
	return CFrame.new(math.clamp(CFRAME.X, -.5, .5),math.clamp(CFRAME.Y, -.5, .5),math.clamp(CFRAME.Z, -.5, .5)) * CFRAME.Rotation
end
function lockin_alt(CFRAME: CFrame)
	return CFrame.new(math.clamp(CFRAME.X, -.25, .25),math.clamp(CFRAME.Y, -.25, .25),math.clamp(CFRAME.Z, -.25, .25)) * CFRAME.Rotation
end
function CreateSeat(Position: CFrame, Anchored: boolean, LinkedTo: Instance): Seat?
	if not Position or not LinkedTo then Debug_Display('LACK LOCATION / CHARACTER') return end
	sync_()
	local seat = Instance.new('Seat', workspace:FindFirstChild('__SEATs') or workspace)
	if Anchored or Position then	seat.Anchored = true end
	seat.Color = BrickColor.random().Color
	seat.Disabled = true
	seat.CFrame = Position
	seat.CanCollide = false
	seat.CanTouch = false
	seat.CanQuery = false
	seat.CastShadow = false
	seat.Transparency = 1
	seat.Name = '__SEAT'..LinkedTo.Name..'_'
	if LinkedTo and LinkedTo:FindFirstChildOfClass('Humanoid') then sync_()	seat:Sit(LinkedTo:FindFirstChildOfClass('Humanoid')) seat:GetPropertyChangedSignal('Occupant'):Once(function() if seat then _RemoveInstance(seat) end end) end
	local connectseato 
	if LinkedTo then
		connectseato = LinkedTo.Destroying:Once(function()
			if seat then _RemoveInstance(seat) end
		end)
	end if connectseato then

		seat.Destroying:Once(function()
			if connectseato then sync_() connectseato:Disconnect() end
		end) end
	if seat and not seat.Occupant or not LinkedTo then
		_RemoveInstance(seat)
	end
	if seat and seat.Anchored then
		seat:GetPropertyChangedSignal('CFrame'):Once(function()
			_RemoveInstance(seat)
		end)
	end
	return seat
end
ServerStorage = game:FindFirstChildOfClass('ServerStorage') or game:GetService('ServerStorage')
local function getCommandSuggestions(input: string)
	if not input then return nil end
	if input:lower():sub(1,4):match('/e ') then input = input:lower():sub(4,500) end
	if input:sub(1,2):match('!_') and tonumber(input:sub(3,5)) and CommandsTable[tonumber(input:sub(3,5))] then return CommandsTable[tonumber(input:sub(3,5))]..input:sub(5,#input > 5 and #input or 20) end
	if table.find(Commandsa, input:lower()) then return input end
	local suggestions = input
	local FinalResult = ''
	local VanillaRes = ''
	local Wit_Slash = input:lower():sub(1,4):match('/e ')
	local splitargs = string.split(input, ' ')
	if Wit_Slash then
		table.remove(splitargs, 1)
	end
	if not splitargs[1] then
		return nil
	end
	local commandneedsarg = #splitargs > 1
	local latestdistance = #splitargs[1]
	local vanilladist = #splitargs[1]
	pcall( function()
		for _, command:string in ipairs(CommandList) do
			local leven = LevenshteinDistance(splitargs[1]:lower(), command:lower())
			if leven < vanilladist then
				vanilladist = leven
				VanillaRes = command
			end	
			if Wit_Slash then command = '/e '..command end
			local match = command:lower():match(splitargs[1]:lower()) 
			local FA, Distance = StringIsSimilar(splitargs[1]:lower(), command:sub(1, #splitargs[1] + 1):lower(), math.ceil(#command:sub(1, #splitargs[1] + 1)/4))
			local invFA, invDistance = StringIsSimilar(splitargs[1]:lower():sub(1, #command + 1), command:lower(), math.ceil(#command:sub(1, #splitargs[1] + 1)/4))
			local DistanceResult = math.huge
			if FA then
				DistanceResult = Distance
			end
			if invFA and invDistance < DistanceResult then
				DistanceResult = invDistance
			end
			if match and not invFA and not FA then
				DistanceResult = math.abs(#splitargs[1] - #command) * 2
			end
			if DistanceResult and latestdistance > DistanceResult then
				latestdistance = DistanceResult
				FinalResult = command
			end
		end end)

	if not FinalResult and not VanillaRes then return nil end
	local findist = (vanilladist < latestdistance)  and vanilladist or latestdistance
	local answer = (vanilladist < latestdistance) and VanillaRes or FinalResult or splitargs[1]
	if answer and trim(answer) ~= '' and findist < math.ceil(#input/2.5) and vanilladist < math.ceil(#input/1.5) and math.abs(#answer-#splitargs[1]) < math.ceil(#input/1.5) then
		if trim(answer) == '' then answer = splitargs[1] end
		suggestions = answer.. ((#splitargs > 1 and " ".. table.concat(splitargs, " ", 2)) or "")
		--[[local replaceend = #FinalResult + 1
		suggestions = FinalResult..input:sub(replaceend, #input)]]
	end
	return suggestions
end
Debris = game:FindFirstChildOfClass('Debris') or game:GetService('Debris')
function sync_() if script:GetActor() then _issynced = true task.synchronize() end end
function desync_() if script:GetActor() then _issynced = false task.desynchronize() end end
function _RemoveInstance(TargetInstance: Instance) 
	if TargetInstance and typeof(TargetInstance) == 'Instance' then
		local isCurrentlysynced = _issynced
		if not isCurrentlysynced then
			sync_()
			pcall(function() TargetInstance:Destroy() end)
			desync_()
		else
			pcall(function() TargetInstance:Destroy() end)
		end
	end
end
function _RegisterRemoval(TargetInstance: Instance, Time: number)
	if not Time then Time = task.wait() end
	if Debris and TargetInstance and typeof(TargetInstance) == 'Instance' and Time and typeof(Time) == 'number' then
		local isCurrentlysynced = _issynced
		if not isCurrentlysynced then
			sync_()
			pcall(function() TargetInstance:SetAttribute('Removing__', true) Debris:AddItem(TargetInstance, Time) end)
			desync_()
		else
			pcall(function() TargetInstance:SetAttribute('Removing__', true) Debris:AddItem(TargetInstance, Time) end)
		end
	end
end
local Loop = 0
sync_()
coroutine.resume(coroutine.create(function()
	wordlist = filterAndSort(wordlist)
end))
function isDimension(a: string)
	a = trim(a):upper()
	return table.find({'X', 'Y', 'Z'}, a), a
end
function isSection(a: string)
	a = trim(a):upper()
	return table.find({'LEG', 'ARM', 'HEAD'}, a), a
end
local chatlog = {[[Welcome To SafeChat! This message marks the start of the server!
Try !safechatwordlist for wordlist
Try !safechat {word from wordlist here} to test if it works!
Try !safechatlog to view up to 100 messages into the past!]]}
function runtime(): number
	return Loop or 0
end
function Debug_Display(...) end
function APPLYFAKER6(Character, changehead)
	local AppliedDescription: HumanoidDescription
	if not Character or typeof(Character) ~= 'Instance' or not Character:IsA('Model') or not Character:FindFirstChild('UpperTorso') or not Character:FindFirstChildOfClass('Humanoid') or Character:FindFirstChild('Char_R6') then
		Debug_Display('no char')
		return
	end
	local Models = game:FindFirstChildOfClass('ServerStorage') and game:FindFirstChildOfClass('ServerStorage'):FindFirstChild("Rig") --and game:FindFirstChildOfClass('ServerStorage'):FindFirstChild("Rig"):FindFirstChild("Fake_R6_Rig")
	if not Models or not Models:FindFirstChild("Fake_R6_Rig") then
		Debug_Display('no model')
		return
	end
	if Character:FindFirstChildOfClass("Humanoid") then
		local humanoid = Character:FindFirstChildOfClass("Humanoid")
		AppliedDescription = humanoid:GetAppliedDescription() 
		humanoid.BodyDepthScale.Value = 1
		humanoid.BodyHeightScale.Value = 1
		humanoid.BodyProportionScale.Value = 0
		humanoid.BodyTypeScale.Value = 0
		humanoid.BodyWidthScale.Value = 1
		humanoid.HeadScale.Value = 1
	end

	if Models and Models:FindFirstChild("Fake_R6_Rig") and Models:FindFirstChild("Fake_R6_Rig"):FindFirstChild("Char_R6") then
		local rig = Models:FindFirstChild("Fake_R6_Rig"):FindFirstChild("Char_R6"):Clone()
		rig.Parent = Character
		if not rig then return end
		if AppliedDescription and rig and rig:FindFirstChildOfClass('Humanoid') then
			if rig:FindFirstChildOfClass('Humanoid') then
				rig:FindFirstChildOfClass('Humanoid'):ApplyDescriptionResetAsync(AppliedDescription)
			end
			if Character:FindFirstChild("Head") and Character:FindFirstChild("Head"):FindFirstChild("face") then
				local face = Character:FindFirstChild("Head"):FindFirstChild("face"):Clone()
				if not changehead then
					rig:FindFirstChild("HeadR6").Transparency = 1
					Character:FindFirstChild("Head").Transparency = 0 end
				face.Parent = rig:FindFirstChild("HeadR6")
				Character:FindFirstChild("Head"):FindFirstChild("face").Color3 = Color3.new(0, 0, 0)
				Character:FindFirstChild("Head"):FindFirstChild("face").Transparency = 1
			end

			if Character:FindFirstChild("Body Colors") then
				local colors = Character:FindFirstChild("Body Colors"):Clone()
				colors.Parent = rig
				if rig:FindFirstChild("HeadR6") then
					rig:FindFirstChild("HeadR6").Color = colors.HeadColor3
				end
			end
		else
			local plrmodel = Character:GetChildren()
			for i, v in pairs(plrmodel) do
				if v:IsA("MeshPart") and (changehead or v.Name ~= 'Head') then
					v.Anchored = true
					v.CanCollide = false
					v.Transparency = 1
				end
			end

			for i, v in pairs(plrmodel) do
				if v:IsA("Accessory") then
					v.Parent = rig
				end
			end

			if Character:FindFirstChild("Head") and Character:FindFirstChild("Head"):FindFirstChild("face") then
				local face = Character:FindFirstChild("Head"):FindFirstChild("face"):Clone()
				face.Parent = rig:FindFirstChild("HeadR6")
				Character:FindFirstChild("Head"):FindFirstChild("face").Color3 = Color3.new(0, 0, 0)
				Character:FindFirstChild("Head"):FindFirstChild("face").Transparency = 1
			end

			if Character:FindFirstChild("Body Colors") then
				local colors = Character:FindFirstChild("Body Colors"):Clone()
				colors.Parent = rig
				if rig:FindFirstChild("HeadR6") then
					rig:FindFirstChild("HeadR6").Color = colors.HeadColor3
				end
			end
		end

		--SET TEXTURE
		if Character:FindFirstChildOfClass("Shirt") then
			if rig:FindFirstChild('Right Arm') and rig:FindFirstChild('Right Arm'):FindFirstChildOfClass('SpecialMesh') then
				Instance.new('Decal', rig:FindFirstChild('Right Arm')).Texture = Character:FindFirstChildOfClass("Shirt").ShirtTemplate
			end
			if rig:FindFirstChild('Left Arm') and rig:FindFirstChild('Left Arm'):FindFirstChildOfClass('SpecialMesh') then
				Instance.new('Decal', rig:FindFirstChild('Left Arm')).Texture = Character:FindFirstChildOfClass("Shirt").ShirtTemplate
			end
			if rig:FindFirstChild('Torso') and rig:FindFirstChild('Torso'):FindFirstChildOfClass('SpecialMesh') then
				Instance.new('Decal', rig:FindFirstChild('Torso')).Texture = Character:FindFirstChildOfClass("Shirt").ShirtTemplate
			end
			if not rig:FindFirstChildOfClass('Shirt') then Character:FindFirstChildOfClass("Shirt").Parent = rig end
		end
		if Character:FindFirstChildOfClass("ShirtGraphic") and not rig:FindFirstChildOfClass('ShirtGraphic') then
			Character:FindFirstChildOfClass("ShirtGraphic").Parent = rig
		end
		if Character:FindFirstChildOfClass("Pants") then
			if rig:FindFirstChild('Right Leg') and rig:FindFirstChild('Right Leg'):FindFirstChildOfClass('SpecialMesh') then
				Instance.new('Decal', rig:FindFirstChild('Right Leg')).Texture = Character:FindFirstChildOfClass("Pants").PantsTemplate
			end
			if rig:FindFirstChild('Left Leg') and rig:FindFirstChild('Left Leg'):FindFirstChildOfClass('SpecialMesh') then
				Instance.new('Decal', rig:FindFirstChild('Left Leg')).Texture = Character:FindFirstChildOfClass("Pants").PantsTemplate
			end
			if not rig:FindFirstChildOfClass('Pants') then Character:FindFirstChildOfClass("Pants").Parent = rig end
		end

		if rig:FindFirstChild("Torso") and rig:FindFirstChild("Torso"):FindFirstChild("Torso") then
			local weldtorso = rig["Torso"]["Torso"]
			weldtorso.Part1 = rig["Torso"]
			weldtorso.Part0 = Character:FindFirstChild("UpperTorso")
		end

		if rig:FindFirstChild("HeadR6") and rig:FindFirstChild("HeadR6"):FindFirstChild("HeadR6") then
			local weldhead = rig["HeadR6"]["HeadR6"]
			weldhead.Part1 = rig:FindFirstChild("HeadR6")
			weldhead.Part0 = Character:FindFirstChild("Head")
		end

		if rig:FindFirstChild("Right Arm") and rig["Right Arm"]:FindFirstChild("Right Arm") then
			local weldrarm = rig["Right Arm"]["Right Arm"]
			weldrarm.Part1 = rig["Right Arm"]
			weldrarm.Part0 = Character:FindFirstChild("RightLowerArm")
		end

		if rig:FindFirstChild("Left Arm") and rig["Left Arm"]:FindFirstChild("Left Arm") then
			local weldlarm = rig["Left Arm"]["Left Arm"]
			weldlarm.Part1 = rig["Left Arm"]
			weldlarm.Part0 = Character:FindFirstChild("LeftLowerArm")
		end

		if rig:FindFirstChild("Left Leg") and rig["Left Leg"]:FindFirstChild("Left Leg") then
			local weldlleg = rig["Left Leg"]["Left Leg"]
			weldlleg.Part1 = rig["Left Leg"]
			weldlleg.Part0 = Character:FindFirstChild("LeftLowerLeg")
		end

		if rig:FindFirstChild("Right Leg") and rig["Right Leg"]:FindFirstChild("Right Leg") then
			local weldrleg = rig["Right Leg"]["Right Leg"]
			weldrleg.Part1 = rig["Right Leg"]
			weldrleg.Part0 = Character:FindFirstChild("RightLowerLeg")
		end

		for i, v in pairs(Character:GetChildren()) do
			if v:IsA("MeshPart") and (changehead or v.Name ~= 'Head') then
				v.Anchored = false
				v.Transparency = 1
			end
			if v:IsA('Accessory') then
				v:Destroy()
			end
		end

		if rig:FindFirstChild("Char_R6") and rig:FindFirstChild("Char_R6"):FindFirstChildOfClass("Humanoid") then
			rig:FindFirstChild("Char_R6"):FindFirstChildOfClass("Humanoid").HipHeight = 1.8
			rig:FindFirstChild("Char_R6"):FindFirstChildOfClass("Humanoid").PlatformStand = true
			rig:FindFirstChild("Char_R6"):FindFirstChildOfClass("Humanoid").EvaluateStateMachine = false
		end
	end
end

function LoadRig(Type: ('R6' | 'R15'), Character: Model, plr: Player)
	if not Type then return end
	if plr and Character then
		local rig = game:FindFirstChildOfClass('ServerStorage') and game:FindFirstChildOfClass('ServerStorage'):FindFirstChild('Rig') and game:FindFirstChildOfClass('ServerStorage'):FindFirstChild('Rig'):FindFirstChild(Type or 'R6')
		if not rig then return end
		local clone = rig:Clone()
		if not clone or not clone:FindFirstChildOfClass('Humanoid') then return end
		local STUFF = Character and not Character:GetAttribute('__DEFAULT_CLOTHING_APPLIED') and Character:FindFirstChildOfClass('Humanoid') and Character:FindFirstChildOfClass('Humanoid'):GetAppliedDescription()
		clone.Parent = game:FindFirstChildOfClass('ServerStorage')
		if STUFF and typeof(STUFF) ~= 'boolean' then
			if clone and clone:FindFirstChildOfClass('Humanoid') then
				clone:FindFirstChildOfClass('Humanoid'):ApplyDescriptionReset(STUFF)
			end
		else
			if Character then
				for i,v in Character:GetChildren() do
					if not v:IsA('Humanoid') and not v:IsA('BasePart') then
						v.Parent = clone
					end
				end
			end
		end
		if clone and Character then
			if clone:FindFirstChildOfClass('Humanoid') and Character:FindFirstChildOfClass('Humanoid') then
				clone:FindFirstChildOfClass('Humanoid').DisplayName = Character:FindFirstChildOfClass('Humanoid').DisplayName
				clone:FindFirstChildOfClass('Humanoid').WalkSpeed = Character:FindFirstChildOfClass('Humanoid').WalkSpeed
				clone:FindFirstChildOfClass('Humanoid').JumpPower = Character:FindFirstChildOfClass('Humanoid').JumpPower
				clone:FindFirstChildOfClass('Humanoid').MaxHealth = Character:FindFirstChildOfClass('Humanoid').MaxHealth
				clone:FindFirstChildOfClass('Humanoid').MaxSlopeAngle = Character:FindFirstChildOfClass('Humanoid').MaxSlopeAngle
			end
			for i,v in pairs(Character:GetAttributes()) do
				clone:SetAttribute(i, v)
			end
			sync_()
			clone.Name = Character.Name
			clone:PivotTo(Character:GetPivot())
			if  Type == 'R6' then
				clone:SetAttribute('R6', true)
				clone:SetAttribute('NOT_R6', nil)
			else 
				clone:SetAttribute('R6', nil)
				clone:SetAttribute('NOT_R6', true)
				pcall(function()
					clone:FindFirstChildOfClass('Humanoid').HipHeight = 2
				end)
			end
			pcall(
				function()
					script:FindFirstAncestorWhichIsA('ServerScriptService'):FindFirstChild('Misc_Handler'):FindFirstChild('COLLISION CHECK'):FindFirstChildOfClass('BindableEvent'):Fire(clone)
				end
			)
			if plr then
				clone.Parent = Character.Parent
				sync_()
				task.synchronize()
				plr.Character = clone
				pcall(function()
					for i,v in game:GetService('StarterPlayer'):FindFirstChildOfClass('StarterCharacterScripts'):GetChildren() do
						v:Clone().Parent = clone
					end 
				end)
			else
				_RemoveInstance(clone)
			end
		else
			if clone then
				_RemoveInstance(clone)
			end
		end
	end
end

local Text = function(...)
	if game:FindFirstChildOfClass('ReplicatedStorage') and game:FindFirstChildOfClass('ReplicatedStorage'):FindFirstChild('LogMessageEvent') then
		for i,v in game:FindFirstChildOfClass('Players'):GetChildren() do
			if not v:GetAttribute('__NODISTURB') then
				sync_()
				game:FindFirstChildOfClass('ReplicatedStorage'):FindFirstChild('LogMessageEvent'):FireClient(v, ...)
			end
		end
	end
end
local Text_ALT = function(PLR,...)
	if game:FindFirstChildOfClass('ReplicatedStorage') and game:FindFirstChildOfClass('ReplicatedStorage'):FindFirstChild('LogMessageEvent') then
		if PLR then
			sync_()
			game:FindFirstChildOfClass('ReplicatedStorage'):FindFirstChild('LogMessageEvent'):FireClient(PLR, ...)
		end
	end
end 

sync_()
function DeltaT(number1: number, number2: number): number
	return (number1 > number2 and math.abs(number1 - number2)) or math.abs(number1 - (number2 - 360))
end
function PlaySound(SoundName,ToWhere: Instance?)
	sync_()
	local Mainplayfunction = function(hmm)
		hmm.PlaybackSpeed = math.random(100-20,100+20)/100
		hmm:Play()
	end
	if ToWhere == nil then
		return
	end
	if ToWhere and ToWhere:FindFirstChild(SoundName) and ToWhere:FindFirstChild(SoundName):IsA("Sound") then
		Mainplayfunction(ToWhere:FindFirstChild(SoundName))
	elseif ToWhere and not ToWhere:FindFirstChild(SoundName) then
		if Soundcloud[SoundName] then
			local sound = Instance.new("Sound")
			local Where = ToWhere
			sound.Parent = Where
			sound.Volume = .075
			sound.SoundId = typeof(Soundcloud[SoundName]) == 'string' and Soundcloud[SoundName] or 'http://www.roblox.com/asset/?id='..tostring(Soundcloud[SoundName])
			sound.Name = SoundName
			sound:Play()
		else
			Debug_Display("Sound >"..SoundName.."< Not Found In Database")
		end
	end
end
function LerpNum(start: number, goal: number, alpha: number): number
	return (math.abs(goal - start) <= .05 and goal) or (start + (goal - start) * alpha)
end
function FindFirstChildOfNameAndClass(Where: Instance, Name: string, Class: string)
	local Found: boolean = false
	if typeof(Where) ~= 'Instance' or typeof(Name) ~= 'string' or typeof(Class) ~= 'string' then
		return
	end
	if Where:FindFirstChild(Name) and Where:FindFirstChild(Name).ClassName:upper():match(Class:upper()) then
		return Where:FindFirstChild(Name)
	end
	for i,v in Where:GetChildren() do
		if not Found then
			if Where == nil then
				Found = true
				return nil
			end
			if v.Name:match(Name) and (v:IsA(Class) or v.ClassName:upper():match(Class:upper())) then
				Found = true
				return v
			end
		end
	end
end
function processcom(plr: Player, Character: Model, message: string, RAYPAR: RaycastParams?)
	if typeof(plr) ~= 'Instance' or not plr.Parent or typeof(message) ~= 'string' then return end
	if typeof(Character) ~= 'Instance' or not Character.Parent then
		Character = plr.Character
		if typeof(Character) ~= 'Instance' or not Character.Parent then
			for i,v in workspace:GetChildren() do
				if v.ClassName == 'Model' and v:GetAttribute('__REGPLRID') == plr.UserId then Character = v break end
			end
		end
	end
	--print(message:sub(1, 10))
	local sy = _issynced
	if plr:GetAttribute('CMD_DEBOUNCE') or plr:GetAttribute('CMD_ONHOLD') then Text_ALT(plr, "Slow Down!") return else sync_() plr:SetAttribute('CMD_DEBOUNCE', true) task.delay(1, function() if not plr or not plr.Parent then return end task.synchronize() plr:SetAttribute('CMD_DEBOUNCE', nil) end) end
	if not sy then desync_() end
	if message:upper():sub(1,#'!EXPERIMENTAL' + 1):match('!EXPERIMENTAL') or message:upper():sub(1,#'/E !EXPERIMENTAL' + 1):match('/E !EXPERIMENTAL') then
		sync_()
		task.synchronize()
		plr:SetAttribute('CMD_ONHOLD', true)
		if game.PrivateServerOwnerId ~= 0 then
			local preid = workspace:GetAttribute('EXP_ACCESS_ID') 
			local success, errormessage = pcall(function()
				local serverid = preid or game:FindFirstChildOfClass("TeleportService"):ReserveServerAsync(9935928129)
				if plr then workspace:SetAttribute('EXP_ACCESS_ID', serverid) game:FindFirstChildOfClass('TeleportService'):TeleportToPrivateServer(9935928129, serverid, {plr}) end
			end)
			if not success and plr then
				workspace:SetAttribute('EXP_ACCESS_ID', nil)
				Text_ALT(plr, 'Teleporting or Reserving Errored, Please try again later')
			end
		else
			pcall(function()
				game:FindFirstChildOfClass('TeleportService'):Teleport(9935928129, plr)
			end)
		end
		if plr and plr.Parent then 
			plr:SetAttribute('CMD_ONHOLD', nil) 
		end 
	elseif message:upper():sub(1,8):match('!CENSOR') then
		if not plr or not Character then return end
		local head = FindFirstChildOfNameAndClass(Character, 'Head', 'BasePart')
		if typeof(head) == 'Instance' then
			local theGui = FindFirstChildOfNameAndClass(head, '__CENSOR', "BillboardGui")
			task.synchronize()
			if typeof(theGui) == 'Instance' then theGui:Destroy() else local CensorBar = Instance.new('BillboardGui', head) CensorBar.Name = '__CENSOR' CensorBar.Size = UDim2.new(1.5,0,1.5,0) CensorBar.Adornee = head CensorBar.StudsOffset = Vector3.new(0,0,1.5) CensorBar.AlwaysOnTop = false local Frame = Instance.new('Frame', CensorBar) Frame.BackgroundColor3 = Color3.fromRGB(0,0,0) Frame.Size = UDim2.new(1,0,1,0) end
		end
	elseif message:upper():sub(1,6):match('!FACE') then
		if not plr or not Character then return end
		pcall(function()
			task.synchronize()
			local split = string.split(message, ' ')
			if #split <= 1 then
				return
			end
			table.remove(split,1)
			script:FindFirstAncestorWhichIsA('ServerScriptService'):FindFirstChild('face'):FindFirstChildOfClass('BindableEvent'):Fire(Character, unpack(split))
		end)
	elseif message:upper():sub(1,9):match('!STICKER') then
		if not plr or not Character then return end
		pcall(function()
			task.synchronize()
			local split = string.split(message, ' ')
			if #split <= 1 then
				return
			end
			table.remove(split,1)
			script:FindFirstAncestorWhichIsA('ServerScriptService'):FindFirstChild('stickers'):FindFirstChildOfClass('BindableEvent'):Fire(Character, split[1], table.concat(split, ' '))
		end)
	elseif message:upper():sub(1,8):match('!BLOCKY') then
		if not plr or not Character then return end
		local head: Part = FindFirstChildOfNameAndClass(Character, 'Head', 'BasePart')
		if typeof(head) == 'Instance' then
			local y, err = pcall(function()
				task.synchronize()
				for i,v in head:GetChildren() do
					if v:IsA("SpecialMesh") then
						v:Destroy()
					end
				end
				head.Size = Vector3.new(1.2,1.2,1.2) * Character:GetScale()	
				if head:IsA('MeshPart') then
					head.MeshContent = '' -- risky since RunLevel might be issue here.
					head.TextureContent = ''
				end 
			end)
			if typeof(err) == 'string' and (err:lower():match('capability') or err:lower():match('lacking') or err:lower():match('capability') or err:lower():match('cannot write') or err:lower():match('NotAccessible')) then
				local a,b = pcall(function()
					task.synchronize()
					--switch the head out
					local BLOCKHEAD = Instance.new('Part', head) BLOCKHEAD.Name = 'BLOCKHEAD' BLOCKHEAD.Size = Vector3.new(1.2,1.2,1.2) * (Character:GetScale()	or 1)
					BLOCKHEAD.Color = head.Color
					BLOCKHEAD.Material = head.Material
					BLOCKHEAD.Transparency = head.Transparency
					local JointInstances = {} -- all of them
					for i,v in Character:GetDescendants() do
						if v:IsA('JointInstance') then
							table.insert(JointInstances, v)
						end
					end
					for i,v in (head:GetConnectedParts(true) or {}) do
						for _, a in JointInstances do
							if a.Part1 == v or a.Part0 == v then
								pcall(function() if a.Part1 == head then
									a.Part1 = BLOCKHEAD
								end
								if a.Part0 == head then
									a.Part0 = BLOCKHEAD
								end
								if a.Parent == head then
									a.Parent = BLOCKHEAD
								end end)
							end
						end
					end
					table.clear(JointInstances)
					BLOCKHEAD.Parent = Character
					for i,v in head:GetChildren() do
						pcall(function()v.Parent = BLOCKHEAD end) 
					end
					head:Destroy()
					BLOCKHEAD.Name = 'Head'
				end) 
			end
		end
	elseif message:upper():sub(1,8):match('!BLOCKH') then
		if not plr or not Character then return end
		local head = FindFirstChildOfNameAndClass(Character, 'Head', 'BasePart')
		if typeof(head) == 'Instance' and not FindFirstChildOfNameAndClass(head, 'BLOCKHEAD', 'BasePart') then
			pcall(function()
				task.synchronize()
				for i,v in head:GetChildren() do
					if v.Name == 'BLOCKHEAD' and v.ClassName == 'Part' then
						v:Destroy()
					end
				end
				local BLOCKHEAD = Instance.new('Part', head) BLOCKHEAD.Name = 'BLOCKHEAD' BLOCKHEAD.Size = Vector3.new(1.2,1.2,1.2) * Character:GetScale() 
				BLOCKHEAD.Color = head.Color
				BLOCKHEAD.Material = head.Material
				BLOCKHEAD.Transparency = head.Transparency
				for i,v in head:GetChildren() do
					if not v:IsA('SpecialMesh') and not v:IsA('JointInstance')  and not v:IsA("Attachment") and not (v.Name:lower():match('neck') and (v.ClassName:lower():match("constraint") or v:IsA("JointInstance"))) then
						pcall(function()		v.Parent = BLOCKHEAD end)
					end
				end
				local BLOCKWELD = Instance.new('Weld', BLOCKHEAD) BLOCKWELD.Part0 = head BLOCKWELD.Part1 = BLOCKHEAD BLOCKWELD.C0 = CFrame.new(0,0,0)
				head.Transparency = 1
			end)
		end
	elseif message:upper():sub(1,11):match('!WIREFRAME') then
		pcall(function()
			if not plr or not plr.Parent or not plr:FindFirstChildOfClass('PlayerGui') then return
			end
			local found = false
			for i,v in plr:FindFirstChildOfClass('PlayerGui'):GetChildren() do
				if v.Name == 'theThingWoah' and v.ClassName == 'ScreenGui' then
					task.synchronize()v:Destroy()
					found = true
					break
				end
			end
			if found then return end
			task.synchronize()
			local theThingWoah = ServerStorage:FindFirstChild('theThingWoah')
			if theThingWoah then
				local clone = theThingWoah:Clone()
				clone.Enabled = true
				clone.Parent = plr:FindFirstChildOfClass('PlayerGui')
			end
		end)
	elseif message:lower():sub(1,18):match('!remove_accessory')  then
		if not Character then return end
		task.synchronize()
		local split = string.split(message, ' ')
		table.remove(split, 1)
		if typeof(split) ~= 'table' or #split < 1 then return end
		pcall(function()
			for i = 1, #split do
				for i,v in Character:GetChildren() do
					if v:GetAttribute('_ACCESSORY') and v.Name:lower():sub(1, #split[i]):match(split[i]) then
						v:Destroy()
					end
				end
			end
		end)
	elseif message:lower():sub(1,21):match('!remove_all_accessory')  then
		if not Character then return end
		task.synchronize()
		pcall(function()
			for i,v in Character:GetChildren() do
				if v:GetAttribute('_ACCESSORY')  then
					v:Destroy()
				end
			end
		end)
	elseif message:lower():sub(1,11):match('!accessory')  then
		if not Character then return end
		task.synchronize()
		local split = string.split(message, ' ')
		if typeof(split) ~= 'table' or #split < 1 then return end
		table.remove(split, 1)
		pcall(function() script:FindFirstAncestorWhichIsA('ServerScriptService'):FindFirstChild('Accessory_Service'):FindFirstChildOfClass('BindableEvent'):Fire(Character, unpack(split)) end)
	elseif message:lower():sub(1,6):match('!wear')  then
		if not Character then return end
		pcall(function()
			local split = string.split(message, ' ')
			table.remove(split, 1)
			if typeof(split) ~= 'table' or typeof(split[1]) ~= 'string' then return end
			task.synchronize() script:FindFirstAncestorWhichIsA('ServerScriptService'):FindFirstChild('Accessory_Wearer'):FindFirstChildOfClass('BindableEvent'):Fire('Wear', Character, split[1], plr)
		end)
	elseif message:lower():sub(1,8):match('!unwear')  then
		if not Character then return end
		pcall(function()
			task.synchronize() script:FindFirstAncestorWhichIsA('ServerScriptService'):FindFirstChild('Accessory_Wearer'):FindFirstChildOfClass('BindableEvent'):Fire('RemoveAll', Character)
		end) 
	elseif message:lower():sub(1,8):match('!unchar')  then
		pcall(function()
			task.synchronize()
			local chr = plr.Character
			if typeof(chr) ~= 'Instance' then
				plr.Character = nil
				Text_ALT(plr, 'Character Slot Is Now Cleared! (Invalid/Null Value)')
				return
			end
			if not chr:IsDescendantOf(workspace) then
				plr.Character = nil
				Text_ALT(plr, 'Character Slot Is Now Cleared (Character Out Of Workspace)!')
				return
			end
			Text_ALT(plr, 'Nothing to be done...')
		end)
	elseif message:lower():sub(1,18):match('!random_accessory')  then
		if not Character then return end
		task.synchronize()
		pcall(function() script:FindFirstAncestorWhichIsA('ServerScriptService'):FindFirstChild('Accessory_Service'):FindFirstChildOfClass('BindableEvent'):Fire(Character) end)
	elseif message:lower():sub(1,18):match('!safechatwordlist')  or message:lower():sub(1,10):match('!wordlist') or message:lower():sub(1,14):match('!allowedwords') or message:lower():sub(1,6):match('!word') or message:lower():sub(1,10):match('!listword') then
		pcall(function()	Text_ALT(plr, 'Here is the wordlist: ', table.concat(wordlist, ', ')) end)
	elseif message:lower():sub(1,9):match('!cmdlist') or message:lower():sub(1,12):match('/e !cmdlist') or message:lower():sub(1,9):match('!listcmd') or message:lower():sub(1,12):match('/e !listcmd') or message:lower():sub(1,4):match('!cmd') or message:lower():sub(1,7):match('/e !cmd') then
		local startertext = [[<<COMMANDS LIST>>
		]]
		local RawText = RAWTEXT or ""
		if not RAWTEXT then
			for i,v in ipairs(CommandList) do
				if v.Command then
					RawText = RawText..(v.Command)..(v.Arguments and '	(Description/Arguments:'..v.Arguments..')' or '')..[[)
					]]
				end
			end
			RAWTEXT = RawText
		end
		Text_ALT(plr, startertext, RAWTEXT)
	elseif message:lower():sub(1,10):match('!onlycmd') or message:lower():sub(1,13):match('/e !onlycmd') then
		local RawText = CMD_RAWTEXT or "!onlycmd"
		if not CMD_RAWTEXT then
			for i,v in ipairs(CommandsTable) do
				RawText = RawText..','..v
			end
			CMD_RAWTEXT = RawText
		end
		Text_ALT(plr, CMD_RAWTEXT)
	elseif message:lower():sub(1,12):match('!serverinfo') or message:lower():sub(1,15):match('/e !serverinfo') then
		local RawText = workspace.Name..[[
		]]
		for i,v in pairs(workspace:GetAttributes()) do
			RawText = RawText..[[
			]]..tostring(i)..': '..tostring(v)..[[
			]]
		end
		Text_ALT(plr, RawText)
	elseif message:lower():sub(1,12):match('!seathelper') or message:lower():sub(1,15):match('/e !seathelper') then
		if (plr and plr:FindFirstChildOfClass('Backpack') and not plr:FindFirstChildOfClass('Backpack'):FindFirstChild('SeatHelper3000')) and Character and typeof(Character) == 'Instance' and Character:IsA('Model') and not Character:FindFirstChild('SeatHelper3000') then
			sync_() script.SeatHelper3000:Clone().Parent = Character
		end
	elseif Character and (message:lower():sub(1,14):match('!pausehandler') or message:lower():sub(1,17):match('/e !pausehandler')) then
		if Character and typeof(Character) == 'Instance' and Character:IsA('Model') then
			sync_() Character:SetAttribute('Halt_Execution', true)
		end
	elseif Character and (message:lower():sub(1,13):match('!stophandler') or message:lower():sub(1,16):match('/e !stophandler')) then
		if Character and typeof(Character) == 'Instance' and Character:IsA('Model') then
			sync_() Character:SetAttribute('Disconnect_Execution', true)
		end
	elseif Character and (message:lower():sub(1,10):match('!setscale') or message:lower():sub(1,7):match('!scale') or message:lower():sub(1,10):match('/e !scale') or message:lower():sub(1,13):match('/e !setscale')) then
		if Character and typeof(Character) == 'Instance' and Character:IsA('Model') then
			sync_() local start = 0 for i,v in ipairs(message:split('')) do if tonumber(v) then break end start += 1 end message = message:sub(start, start + 10) Character:ScaleTo(tonumber(message) ~= nil and math.clamp(tonumber(message),0.8,1.2) or 1)
		end
	elseif Character and (message:lower():sub(1,18):match('!destroycharacter') or message:lower():sub(1,18):match('!removecharacter') or message:lower():sub(1,21):match('/e !destroycharacter')) then
		if Character and typeof(Character) == 'Instance' and Character:IsA('Model') then
			sync_() Character:Destroy()
		end
	elseif message:lower():sub(1,6):match('!help') or message:lower():sub(1,9):match('/e !help') then
		Text_ALT(plr, [[
		<<'!' COMMAND GUIDE >>
			If you wish to check out Client-Sided Commands, Please run '!local_help' and '!local_cmd' in the COMMAND BAR instead.
		
			(Commands have 1 second chat cooldown, Chat registeration has .5 Second cooldown)
			(Some Commands Have Auto-Correct For Tiny Mistyped Error)
			
			*>>{some commands requires absolute accuracy due to their irreversible/crucial nature, listed below}<<*
			!leave !reserve !joinrandom !rejoin !destroycharacter !stophandler !badgameplay !experimental !BGR6
			
			(Use the Command Bar To Send Silent Commands)
			(Commands Are Mostly Case Insensitive, and has other alternative forms to be called; Example: '!Spawn' and '!ToSpawn'; these alternatives will not be listed upon viewing '!cmd' list; but will on the '!onlycmd' list)
			(Type '!listcmd', '!cmdlist' or '!cmd' to view commands; For all the shortcuts and variation type '!onlycmd')
		]])
	elseif message:lower():sub(1,6):match('!mute') or message:lower():sub(1,9):match('/e !mute') or message:lower():sub(1,11):match('!nodisturb') or message:lower():sub(1,14):match('/e !nodisturb') then
		if plr then
			sync_()
			if not plr:GetAttribute('__NODISTURB') then
				Text_ALT('You will not receive any further server-wide announcement until you leave/retype this command!')
				plr:SetAttribute('__NODISTURB', true)
			else
				Text_ALT('You will now receive server-wide announcement!')
				plr:SetAttribute('__NODISTURB', nil)
			end
		end
	elseif message:upper():sub(1,#'!UNCOPYLOCK' + 1):match('!UNCOPYLOCK') then
		local success, errormessage = pcall(
			function()
				local serverid =  game:FindFirstChildOfClass("TeleportService"):ReserveServerAsync(18934407558)
				game:FindFirstChildOfClass('TeleportService'):TeleportToPrivateServer(18934407558, serverid, {plr})
			end
		)
		if not success and plr then
			Text_ALT(plr, 'Teleporting or Reserving Errored, Please try again later')
		end
	elseif (#message:split(' ') > 1) and message:split(' ')[1]:lower():match('!offset_relative') then -- [[args: Dimension, Section: (LEG | ARM | HEAD)]]
		if Character then
			local splitted = message:upper():split(' ')
			if #splitted == 2 then
				local isdim, dim = isDimension(splitted[2])
				local issec, section = isSection(splitted[2])
				if isdim then
					for i,sec in {"HEAD", 'ARM', 'LEG'} do
						local AttributeName = sec..'_'..dim..'_RELATIVE'
						if Character:GetAttribute(AttributeName) then Character:SetAttribute(AttributeName, false) else Character:SetAttribute(AttributeName, true)	end
					end
				elseif issec then
					for i,dima in {"X", 'Y', 'Z'} do
						local AttributeName = section..'_'..dima..'_RELATIVE'
						if Character:GetAttribute(AttributeName) then Character:SetAttribute(AttributeName, false) else Character:SetAttribute(AttributeName, true)	end
					end
				end
				--only dimension/section
			else
				--only dimension and section in the order
				local isdim, dim = isDimension(splitted[2])
				local issec, section = isSection(splitted[3])
				if not isdim and not issec then
					isdim, dim = isDimension(splitted[3])
					issec, section = isSection(splitted[2])
				end
				if isdim and issec then
					local AttributeName = section..'_'..dim..'_RELATIVE'
					sync_()
					task.synchronize()
					if Character:GetAttribute(AttributeName) then Character:SetAttribute(AttributeName, false) else Character:SetAttribute(AttributeName, true)	end
				end
			end
		end
	elseif message:lower():sub(1,18):match('!offset_relative_y') then -- legacy flag
		if Character then
			sync_()
			task.synchronize()
			if not Character:GetAttribute('Y_RELATIVE') then
				Character:SetAttribute('Y_RELATIVE', true)
			else
				Character:SetAttribute('Y_RELATIVE', nil)
			end
		end
	elseif message:lower():sub(1,20):match('!rotation_relative') then
		if Character then
			sync_()
			task.synchronize()
			if not Character:GetAttribute('ROTATION_RELATIVE') then
				Character:SetAttribute('ROTATION_RELATIVE', true)
			else
				Character:SetAttribute('ROTATION_RELATIVE', nil)
			end
		end
	elseif Character and (message:lower():sub(1,#'!RateLimitAnim' + 1):match('!ratelimitanim') or message:lower():sub(1,#'/e !ratelimitanim' + 1):match('/e !ratelimitanim')) then
		local startfromstring = message:lower():sub(1,#'!RateLimitAnim' + 1):match('!ratelimitanim') and #'!RateLimitAnim' + 1 or #'/e !ratelimitanim' + 1
		if Character then
			local num = tonumber(message:sub(startfromstring, startfromstring + 3))
			if num and typeof(num) == 'number' then
				num = math.abs(math.clamp(num,1,60))
				sync_()
				task.synchronize()
				Character:SetAttribute('__RATELIMIT', num)
			end
		end
	elseif Character and (message:upper():match('!CLEAR_ANIM')) then
		sync_()
		task.synchronize()
		pcall(function()
			for i,v in Character:GetDescendants() do
				if v.ClassName == 'Motor6D' then
					v.DesiredAngle = 0
					v.CurrentAngle = 0
					v.MaxVelocity = 0.1
				elseif v.ClassName == 'Animator' then
					if Character:FindFirstChild('Animate'):GetAttribute('__noremove') then
						v:Destroy()
					end
				end
			end
		end)
		pcall(function()
			if not Character:FindFirstChild('__Clear') or not Character:FindFirstChild('__Clear'):IsA('LocalScript') then
				local Clone = script.__Clear:Clone()
				Clone.Parent = Character
				Debris:AddItem(Clone, 5)
			end
		end)
	elseif message:upper():match('!ALT_UI') then
		pcall(function()
			if not plr:FindFirstChildOfClass('PlayerGui') then return end 
			if plr:FindFirstChildOfClass('PlayerGui'):FindFirstChild('__SprintUI') then
				plr:FindFirstChildOfClass('PlayerGui'):FindFirstChild('__SprintUI'):Destroy()
			end
			local clone = ServerStorage:FindFirstChild('__SprintUI'):Clone()
			if clone then
				clone.Parent = plr:FindFirstChildOfClass('PlayerGui')
				clone.Enabled = true
			end
		end)
	elseif Character and message:upper():match('!NO_ANIM') then
		pcall(function()
			local found = false
			local isM = 0
			for i,v in Character:GetDescendants() do
				if v.ClassName == 'AnimationConstraint'  then
					isM -= 1
				elseif v.ClassName == 'Motor6D' then
					isM += 1
				end
				if v.Name:upper() == 'ANIMATE' and v:IsA('Script') and v:GetAttribute('__noremove') then
					found = true
				end
			end
			if found then Text_ALT(plr, '!no_anim was already ran, Try !clear_anim if you wish to clear further.') end
			sync_()
			task.synchronize()
			if not Character:FindFirstChildOfClass('Actor') then
				Instance.new('Actor', Character)
			end
			local Clone 
			if isM < 0 then
				Clone = ServerStorage:WaitForChild('Animate', 10):Clone()
			else
				Clone = script.Parent.Parent.Misc_Handler["Error Handler (Reactivator)"].Animate:Clone()
			end
			for i,v in Character:GetChildren() do
				if v:IsA('BaseScript') and v.Name:upper() == "ANIMATE" then
					v:Destroy()
				end
			end
			for i,v in Character:GetDescendants() do
				if v.ClassName:upper() == 'ANIMATOR' then
					v:Destroy()
				end
			end
			Clone.Parent = Character:FindFirstChildOfClass('Actor') or Character
			Clone.Enabled = true
		end)
	elseif Character and (message:upper():sub(1, #'!LOCKJOINT' + 1):match('!LOCKJOINT') or message:upper():sub(1, #'/e !LOCKJOINT' + 1):match('/E !LOCKJOINT')) then
		sync_()
		task.synchronize()
		if not Character or Character:GetAttribute('Done') or not Character:FindFirstChild('UpperTorso') then return end
		Character:SetAttribute('Done', true)
		local R15LockWeld = {}
		pcall(function()
			for i,v in ipairs(Character:GetDescendants()) do
				if not Character or not Character.Parent then break end
				if (v.Name:match('Hand') or v.Name:match('Foot') or v.Name:match('UpperTorso') or v.Name:match('LowerLeg') or v.Name:match('LowerArm')) and v:IsA('BasePart') then
					pcall(function() if v:FindFirstChildOfClass('Motor6D') then
						local mt = v:FindFirstChildOfClass('Motor6D')
						if mt.Enabled == true then
							task.synchronize()
								mt.Enabled = false mt:SetAttribute('Enabled', true) -- swap inward so it doesn't lock out the higher joints
							local Replace = Instance.new('Weld', mt.Parent)
							Replace.Name = mt.Name
							Replace.Part1 = mt.Part0
							Replace.Part0 = mt.Part1
							Replace.C0 = mt.C1
							Replace.C1 = mt.C0
							table.insert(R15LockWeld, Replace)
							mt:Destroy()
						end 
					end end)
					pcall(function()
						if v:FindFirstChildOfClass('AnimationConstraint') then
							local mt = v:FindFirstChildOfClass('AnimationConstraint')
							if mt.Enabled == true and mt.Attachment0 and mt.Attachment1 and mt.Attachment0.Parent and mt.Attachment1.Parent then
							task.synchronize()
								mt.Enabled = false mt:SetAttribute('Enabled', true) -- swap inward so it doesn't lock out the higher joints
							local Replace = Instance.new('Weld', mt.Parent)
							Replace.Name = mt.Name
							Replace.Part1 = mt.Attachment0.Parent
							Replace.Part0 =  mt.Attachment1.Parent
							Replace.C0 = mt.Attachment1.CFrame
							Replace.C1 = mt.Attachment0.CFrame
							table.insert(R15LockWeld, Replace)
							mt:Destroy() end
						end
				end)			
				end
			end
		end) 
		if Character and Character.Parent and #R15LockWeld <= 0 then
			pcall(function()
				for i,v in ipairs(Character:GetChildren()) do
					if not v:IsA('BasePart') then continue end
					local TargetPart = v.Name
					if v.Name:upper():match('UPPER') then
						TargetPart = v.Name:gsub('Upper', 'Lower')
					elseif v.Name:upper():match('LOWER') then
						if v.Name:upper():match('ARM') then
							TargetPart = v.Name:gsub('LowerArm', 'Hand')
						elseif v.Name:upper():match('LEG') then
							TargetPart = v.Name:gsub('LowerLeg', 'Foot')
						end
					end
					if TargetPart == v.Name then continue end
					local ThisPart = FindFirstChildOfNameAndClass(Character, TargetPart, 'BasePart')
					if not ThisPart then continue end
					pcall(function()
					local LockWeld = CreateWeldIfNeeded(Character, 'LockWeld'..TargetPart, TargetPart, v.Name, TargetPart, v.Name..'_'..TargetPart, CFrame.new(0,v.Size.Y/2 + ThisPart.Size.Y/2,0):Inverse())
					if LockWeld then
						table.insert(R15LockWeld,LockWeld)
					end end)
				end
			end)
		end
	elseif Character and (message:lower():sub(1,19):match('!offset_lowertorso') or message:lower():sub(1,22):match('/e !offset_lowertorso')) then
		local startfromstring = message:lower():sub(1,19):match('!offset_lowertorso') and 20 or 23
		if Character then
			local OFFSETNUMS = string.split(string.sub(message, startfromstring,  startfromstring > #message and startfromstring or #message),',')
			local OFFSET = CFrame.new()
			local latestint = 1
			local intcontain = {}
			for i,v in OFFSETNUMS do
				if tonumber(v) then
					local num = tonumber(v)
					if (latestint >= 4 and latestint < 7)then
						if (math.abs(num) > (math.pi * 2))  then num = math.rad(num) end 
						-- 4 to 6 is angle, if more that (pi * 2) then it meeans they want radian
						num = math.clamp(num, -0.26179939, 0.26179939)
					end
					intcontain[latestint] = num
					latestint += 1 
				end
			end
			if #intcontain <= 3 then
				OFFSET = CFrame.new(intcontain[1] or 0, intcontain[2] or 0, intcontain[3] or 0)
			else
				local thisframe = pcall(function()
					OFFSET = CFrame.new(unpack(intcontain))
				end)	
				if not thisframe then
					OFFSET = CFrame.new(intcontain[1] or 0, intcontain[2] or 0, intcontain[3] or 0) * CFrame.Angles(intcontain[4] or 0, intcontain[5] or 0, intcontain[6] or 0)
				end
			end
			sync_()
			OFFSET = lockin_alt(OFFSET)
			if Character and Character.Parent and Character:FindFirstChildOfClass('Humanoid') and Character:FindFirstChildOfClass('Humanoid').RootPart and Character:FindFirstChildOfClass('Humanoid').RootPart:FindFirstChild('LowerTorsoWeld') and Character:FindFirstChildOfClass('Humanoid').RootPart:FindFirstChild('LowerTorsoWeld'):IsA('JointInstance') then
				local Target: JointInstance = Character:FindFirstChildOfClass('Humanoid').RootPart:FindFirstChild('LowerTorsoWeld')
				if not Target:GetAttribute('C0') then Target:SetAttribute('C0', Target.C0) end
				Target.C0 = Target:GetAttribute('C0') * OFFSET or CFrame.new(-OFFSET.Z, OFFSET.Y, -OFFSET.X)
			end
		end
	elseif Character and  (message:lower():sub(1,12):match('!fix_head') or message:lower():sub(1,15):match('/e !fix_head')) then
		pcall(function()
			task.synchronize()
			local head = FindFirstChildOfNameAndClass(Character, 'Head', 'BasePart')
			if head then
				local Att = FindFirstChildOfNameAndClass(head, 'NeckRigAttachment', 'Attachment')
				local MTR = FindFirstChildOfNameAndClass(head, 'Neck', 'Motor6D')
				if Att then
					Att.CFrame = CFrame.new(Att.CFrame.X, -head.Size.Y/2.4, Att.CFrame.Z) * Att.CFrame.Rotation
				end
				if MTR then
					MTR.C1 = CFrame.new(MTR.C1.X, -head.Size.Y/2.4, MTR.C1.Z) * MTR.C1.Rotation
				end
			end
		end)
	elseif Character and  (message:lower():sub(1,14):match('!float_head') or message:lower():sub(1,17):match('/e !float_head')) then
		pcall(function()
			task.synchronize()
			local head = FindFirstChildOfNameAndClass(Character, 'Head', 'BasePart')
			if head then
				local Att = FindFirstChildOfNameAndClass(head, 'NeckRigAttachment', 'Attachment')
				local MTR = FindFirstChildOfNameAndClass(head, 'Neck', 'Motor6D')
				if Att then
					Att.CFrame = CFrame.new(Att.CFrame.X, -head.Size.Y/2, Att.CFrame.Z) * Att.CFrame.Rotation
				end
				if MTR then
					MTR.C1 = CFrame.new(MTR.C1.X, -head.Size.Y/2, MTR.C1.Z) * MTR.C1.Rotation
				end
			end
		end)
	elseif Character and  (message:lower():sub(1,13):match('!offset_head') or message:lower():sub(1,17):match('/e !offset_head')) then
		local filteredmsg = message:gsub("/e !offset_head", ''):gsub("!offset_head", '')
		local OFFSET = CFrame.new()
		local latestint = 1
		local intcontain = {}
		for i,v in string.split(filteredmsg, ',') do v = trim(v)
			if tonumber(v) then
				local num = tonumber(v)
				if (latestint >= 4 and latestint < 7)then
					if (math.abs(num) > (math.pi * 2))  then num = math.rad(num) end 
					-- 4 to 6 is angle, if more that (pi * 2) then it meeans they want radian
					num = math.clamp(num, -0.52359878, 0.52359878)
				end
				intcontain[latestint] = num
				latestint += 1 
			end
		end
		if #intcontain <= 3 then
			OFFSET = CFrame.new(intcontain[1] or 0, intcontain[2] or 0, intcontain[3] or 0)
		else
			local thisframe = pcall(function()
				OFFSET = CFrame.new(unpack(intcontain))
			end)	
			if not thisframe then
				OFFSET = CFrame.new(intcontain[1] or 0, intcontain[2] or 0, intcontain[3] or 0) * CFrame.Angles(intcontain[4] or 0, intcontain[5] or 0, intcontain[6] or 0)
			end
		end
		OFFSET = lockin(OFFSET)sync_()
		Character:SetAttribute('OFFSETHEAD_', lockin(OFFSET))
		if Character and (Character.Parent and (Character.Parent.Name ~= 'Character' or Character:GetAttribute('Retro'))) then
			local offset = CFrame.new(OFFSET.X,  OFFSET.Z,OFFSET.Y) * OFFSET.Rotation
			local customoffset = CFrame.new((Character:GetAttribute('HEAD_X_RELATIVE') and 1 or -1) *  -OFFSET.X, (Character:GetAttribute('HEAD_Z_RELATIVE') and 1 or -1) * OFFSET.Z, (Character:GetAttribute('HEAD_Y_RELATIVE') and 1 or -1) * OFFSET.Y)
			local co_offset = (customoffset or --[[Character:GetAttribute('Y_RELATIVE') and CFrame.new(-OFFSET.X, OFFSET.Y, OFFSET.Z)]] offset.Position:Inverse()) * (Character:GetAttribute('ROTATION_RELATIVE') and OFFSET.Rotation:Inverse() or OFFSET.Rotation)
			for i,v in ipairs(Character:GetDescendants()) do
				if v.ClassName:lower():match('motor6d') and v.Name:upper():match('NECK') then
					if not v:GetAttribute('C0') then
						v:SetAttribute('C0', v.C0)
					end
					if v.Name:upper():match('LEFT') then
						v.C0 = v:GetAttribute('C0') * co_offset
						v:SetAttribute('offset__C0', co_offset)
					elseif v.Name:upper():match('RIGHT') then
						v.C0 = v:GetAttribute('C0') * offset v:SetAttribute('offset__C0', offset)
					else 
						v.C0 = v:GetAttribute('C0') * offset v:SetAttribute('offset__C0', offset)
					end
				elseif v:IsA('Attachment') and v.Name:upper():match('SHOULDER') and v.Parent.Name:lower():match('torso') then
					-- C0 rig attachment for hip
					if not v:GetAttribute('CF0') then
						v:SetAttribute('CF0', v.CFrame)
					end
					if v.Name:upper():match('LEFT') then
						v.CFrame = v:GetAttribute('CF0') * co_offset  v:SetAttribute('offset__C0', co_offset)
					elseif v.Name:upper():match('RIGHT') then
						v.CFrame = v:GetAttribute('CF0') * offset  v:SetAttribute('offset__C0', offset)
					else
						v.CFrame = v:GetAttribute('CF0') * offset  v:SetAttribute('offset__C0', offset)
					end
				end
			end
		end
	elseif Character and  (message:lower():sub(1,11):match('!offset_arm') or message:lower():sub(1,14):match('/e !offset_arm')) then
		local startfromstring = message:lower():sub(1,11):match('!offset_arm') and 12 or 15
		if Character then
			local OFFSETNUMS = string.split(string.sub(message, startfromstring,  startfromstring > #message and startfromstring or #message),',')
			local OFFSET = CFrame.new()
			local latestint = 1
			local intcontain = {}
			for i,v in OFFSETNUMS do v = trim(v)
				if tonumber(v) then
					local num = tonumber(v)
					if (latestint >= 4 and latestint < 7)then
						if (math.abs(num) > (math.pi * 2))  then num = math.rad(num) end 
						-- 4 to 6 is angle, if more that (pi * 2) then it meeans they want radian
						num = math.clamp(num, -0.52359878, 0.52359878)
					end
					intcontain[latestint] = num
					latestint += 1 
				end
			end
			if #intcontain <= 3 then
				OFFSET = CFrame.new(intcontain[1] or 0, intcontain[2] or 0, intcontain[3] or 0)
			else
				local thisframe = pcall(function()
					OFFSET = CFrame.new(unpack(intcontain))
				end)	
				if not thisframe then
					OFFSET = CFrame.new(intcontain[1] or 0, intcontain[2] or 0, intcontain[3] or 0) * CFrame.Angles(intcontain[4] or 0, intcontain[5] or 0, intcontain[6] or 0)
				end
			end
			OFFSET = lockin(OFFSET)
			sync_()
			task.synchronize()
			Character:SetAttribute('OFFSETARM_', lockin(OFFSET))sync_()
			task.synchronize()
			if Character and (Character.Parent and (Character.Parent.Name ~= 'Character' or Character:GetAttribute('Retro'))) then
				local offset = CFrame.new(OFFSET.Z, OFFSET.Y, OFFSET.X) * OFFSET.Rotation
				local customoffset = CFrame.new((Character:GetAttribute('ARM_Z_RELATIVE') and 1 or -1) *  -OFFSET.Z, (Character:GetAttribute('ARM_Y_RELATIVE') and 1 or -1) * OFFSET.Y, (Character:GetAttribute('ARM_X_RELATIVE') and 1 or -1) * OFFSET.X)
				local co_offset = (customoffset or --[[Character:GetAttribute('Y_RELATIVE') and CFrame.new(OFFSET.Z, OFFSET.Y, OFFSET.X) or]] offset.Position:Inverse()) * (Character:GetAttribute('ROTATION_RELATIVE') and OFFSET.Rotation:Inverse() or OFFSET.Rotation)
				for i,v in ipairs(Character:GetDescendants()) do
					if v.ClassName:lower():match('motor6d') and v.Name:upper():match('SHOULDER') then
						if not v:GetAttribute('C0') then
							v:SetAttribute('C0', v.C0)
						end
						if v.Name:upper():match('LEFT') then
							v.C0 = v:GetAttribute('C0') * co_offset v:SetAttribute('offset__C0', co_offset)
						elseif v.Name:upper():match('RIGHT') then
							v.C0 = v:GetAttribute('C0') * offset v:SetAttribute('offset__C0', offset)
						end
					elseif v:IsA('Attachment') and v.Name:upper():match('SHOULDER') and v.Parent.Name:lower():match('torso') then
						-- C0 rig attachment for hip
						if not v:GetAttribute('CF0') then
							v:SetAttribute('CF0', v.CFrame)
						end
						if v.Name:upper():match('LEFT') then
							v.CFrame = v:GetAttribute('CF0') * co_offset  v:SetAttribute('offset__C0', co_offset)
						elseif v.Name:upper():match('RIGHT') then
							v.CFrame = v:GetAttribute('CF0') * offset  v:SetAttribute('offset__C0', offset)
						end
					end
				end
			end
		end
	elseif Character and  (message:lower():sub(1,11):match('!offset_leg') or message:lower():sub(1,14):match('/e !offset_leg')) then
		local startfromstring = message:lower():sub(1,11):match('!offset_leg') and 12 or 15
		if Character then
			local OFFSETNUMS = string.split(string.sub(message, startfromstring,  startfromstring > #message and startfromstring or #message),',')
			local OFFSET = CFrame.new()
			local latestint = 1
			local intcontain = {}
			for i,v in OFFSETNUMS do v = trim(v)
				if tonumber(v) then
					local num = tonumber(v)
					if (latestint >= 4 and latestint < 7)then
						if (math.abs(num) > (math.pi * 2))  then num = math.rad(num) end 
						-- 4 to 6 is angle, if more that (pi * 2) then it meeans they want radian
						num = math.clamp(num, -0.52359878, 0.52359878)
					end
					intcontain[latestint] = num
					latestint += 1 
				end
			end
			if #intcontain <= 3 then
				OFFSET = CFrame.new(intcontain[1] or 0, intcontain[2] or 0, intcontain[3] or 0)
			else
				local thisframe = pcall(function()
					OFFSET = CFrame.new(unpack(intcontain))
				end)	
				if not thisframe then
					OFFSET = CFrame.new(intcontain[1] or 0, intcontain[2] or 0, intcontain[3] or 0) * CFrame.Angles(intcontain[4] or 0, intcontain[5] or 0, intcontain[6] or 0)
				end
			end
			OFFSET = lockin(OFFSET)
			Character:SetAttribute('OFFSETLEG_',lockin(OFFSET))sync_() 
			if Character and Character.Parent and (Character.Parent.Name ~= 'Character' or Character:GetAttribute('Retro')) then
				local offset = CFrame.new(OFFSET.Z, OFFSET.Y, OFFSET.X) * OFFSET.Rotation
				local customoffset = CFrame.new((Character:GetAttribute('LEG_Z_RELATIVE') and 1 or -1) *  OFFSET.Z, (Character:GetAttribute('LEG_Y_RELATIVE') and 1 or -1) * OFFSET.Y, (Character:GetAttribute('LEG_X_RELATIVE') and 1 or -1) * -OFFSET.X)
				local co_offset = (customoffset or --[[Character:GetAttribute('Y_RELATIVE') and CFrame.new(OFFSET.Z, OFFSET.Y, -OFFSET.X) or]] offset.Position:Inverse()) * (Character:GetAttribute('ROTATION_RELATIVE') and OFFSET.Rotation:Inverse() or OFFSET.Rotation)
				for i,v in ipairs(Character:GetDescendants()) do
					if v.ClassName:lower():match('motor6d') and v.Name:upper():match('HIP') then
						if not v:GetAttribute('C0') then
							v:SetAttribute('C0', v.C0)
						end
						if v.Name:upper():match('LEFT') then
							v.C0 = v:GetAttribute('C0') * co_offset  v:SetAttribute('offset__C0', co_offset)
						elseif v.Name:upper():match('RIGHT') then
							v.C0 = v:GetAttribute('C0') * offset  v:SetAttribute('offset__C0', offset)
						end
					elseif v:IsA('Attachment') and v.Name:upper():match('HIP') and v.Parent.Name:lower():match('torso') then
						-- C0 rig attachment for hip
						if not v:GetAttribute('CF0') then
							v:SetAttribute('CF0', v.CFrame)
						end
						if v.Name:upper():match('LEFT') then
							v.CFrame = v:GetAttribute('CF0') * co_offset  v:SetAttribute('offset__C0', co_offset)
						elseif v.Name:upper():match('RIGHT') then
							v.CFrame = v:GetAttribute('CF0') * offset  v:SetAttribute('offset__C0', offset)
						end
					end
				end
			end
		end
	elseif   Character and (message:sub(1, #'!replacehead_alt' + 1):lower():match('!replacehead_alt') or message:sub(1, #'/e !replacehead_alt' + 1):lower():match('/e !replacehead_alt')) then
		pcall(function()
			sync_()
			task.synchronize()
			script:FindFirstAncestorWhichIsA('ServerScriptService'):FindFirstChild('HeadChanger'):FindFirstChildOfClass('BindableEvent'):Fire(plr)
		end)
	elseif   Character and (message:sub(1, #'!replacehead' + 1):lower():match('!replacehead') or message:sub(1, #'/e !replacehead' + 1):lower():match('/e !replacehead')) then
		pcall(function()
			if Uniheadsys then
				sync_()
				task.synchronize()
				Uniheadsys:ConvertAnimatedHead(Character)
			end
		end)
	elseif   Character and (message:sub(1, #'!sitanchor' + 1):lower():match('!sitanchor') or message:sub(1, #'/e !sitanchor' + 1):lower():match('/e !sitanchor')) then
		if Character and Character:FindFirstChildOfClass('Humanoid') and Character:FindFirstChildOfClass('Humanoid').RootPart then
			if Character and (workspace:FindFirstChild('__SEATs') or workspace):FindFirstChild('__SEAT'..Character.Name..'_') then
				_RemoveInstance((workspace:FindFirstChild('__SEATs') or workspace):FindFirstChild('__SEAT'..Character.Name..'_'))
			end
			local SizeR = Character:FindFirstChildOfClass('Humanoid').RootPart.Size
			local raycast = workspace:Raycast(Character:FindFirstChildOfClass('Humanoid').RootPart.Position, Vector3.new(0,-7,0), RAYPAR) or workspace:Blockcast(Character:FindFirstChildOfClass('Humanoid').RootPart.CFrame, Vector3.new(SizeR.X,.05,SizeR.Z), Vector3.new(0,-7,0), RAYPAR)
			if raycast and raycast.Instance then
				if raycast.Instance.ClassName:upper():match('SEAT') or (raycast.Instance:FindFirstAncestorWhichIsA('Model') and raycast.Instance:FindFirstAncestorWhichIsA('Model'):FindFirstChildOfClass('Humanoid')) then Text_ALT(plr, '<<You can not sit here!>>') return end
				if not Character.PrimaryPart  then
					Character.PrimaryPart = Character:FindFirstChildOfClass('Humanoid').RootPart
				end
				local rx, ry, rz =  Character.PrimaryPart.CFrame:ToOrientation()
				local pcf = (CFrame.new(raycast.Position , (raycast.Position + raycast.Normal)) * CFrame.Angles(0,0,ry):Inverse()) * CFrame.Angles(0,-math.rad(90),math.rad(90)) - Vector3.new(0,.9,0)
				if raycast.Instance == workspace:FindFirstChildOfClass('Terrain') then
					if raycast.Material == Enum.Material.Air or raycast.Material == Enum.Material.Water then
						CreateSeat(CFrame.new(raycast.Position, raycast.Position + Character:GetPivot().LookVector), false, Character)
					else
						CreateSeat(pcf, true, Character)
					end
				else
					if raycast.Instance:IsA('BasePart') then
						CreateSeat(pcf, raycast.Instance.Anchored or raycast.Instance:IsGrounded(), Character)
					else
						CreateSeat(pcf, true, Character)
					end 
				end
			else
				if Character and Character:FindFirstChildOfClass('Humanoid') then
					sync_()
					task.synchronize()
					Character:FindFirstChildOfClass('Humanoid').Sit = true
				end
				Text_ALT(plr, '<<No ground was found!>>') 
			end
		end
	elseif  Character and (message:sub(1, #'!sit' + 1):lower():match('!sit') or message:sub(1, #'/e !sit' + 1):lower():match('/e !sit')) then	
		if Character and Character:FindFirstChildOfClass('Humanoid') then
			sync_()
			task.synchronize()
			Character:FindFirstChildOfClass('Humanoid').Sit = true
		end
	elseif message:sub(1, #'!rejoin' + 1):lower():match('!rejoin') or message:sub(1, #'/e !rejoin' + 1):lower():match('/e !rejoin') then
		if plr then
			sync_()
			task.synchronize() 
			plr:SetAttribute('CMD_ONHOLD', true)
			local isnoterror = pcall(function() game:FindFirstChildOfClass('TeleportService'):TeleportToPlaceInstance(game.PlaceId, game.JobId, plr, nil, game:FindFirstChildOfClass("TeleportService"):GetLocalPlayerTeleportData(),game:FindFirstChildOfClass("TeleportService"):GetArrivingTeleportGui()) end)
			if not isnoterror and plr then
				Text_ALT(plr, 'Rejoin Errored, Please try again later')
			end
			if plr and plr.Parent then 
				plr:SetAttribute('CMD_ONHOLD', nil) 
			end 
		end
	elseif message:sub(1, #'!fre' + 1):lower():match('!fre') or message:sub(1, #'/e !fre' + 1):lower():match('/e !fre') then
		if plr then
			sync_()  task.synchronize() 
			local isnoterror = pcall(function() game:FindFirstChildOfClass('ServerScriptService'):FindFirstChild('CharacterLoaderEnsure'):FindFirstChild('Trigger'):Fire(plr) end)
			if not isnoterror and plr then
				Text_ALT(plr, 'Force Respawn Errored, Please try again later')
			end
		end
	elseif message:lower():sub(1,#'!joinreserved' + 1):match('!joinreserved') or message:lower():sub(1,#'!joinreserved' + 4):match('/e !joinreserved') then
		local args = message:split(' ')
		if message:match('/e ') then
			table.remove(args, 1)
		end
		if not args[2] then return end
		local servid = trim(args[2])
		local serinfo
		for i,v in ServerStorage.__RESERVEDCACHE:GetChildren() do
			if v.Name == servid then
				serinfo = v
				break
			end
		end
		if not serinfo then return end
		local whitelisted = false
		for i,v in serinfo:GetChildren() do
			if v:IsA("NumberValue") and v.Value == plr.UserId then whitelisted = true break elseif v:IsA("StringValue") and v.Value == plr.Name then whitelisted = true break end
		end
		if not whitelisted then return end
		sync_()
		task.synchronize()
		local datasetri = (plr:GetJoinData() and plr:GetJoinData().TeleportData) or {}
		pcall(function() datasetri.ORIGIN_PLACE = game.Players datasetri.ORIGINJOBID = game.JobId end)
		local sucess = false
		local tries = 6
		while not sucess and plr and plr.Parent and tries > 0 and task.wait(10) do
			sucess = pcall(function() game:FindFirstChildOfClass('TeleportService'):TeleportToPrivateServer(game.PlaceId, serinfo.Value, {plr}, '_SpawnLocation', datasetri, game:FindFirstChildOfClass('ServerStorage'):FindFirstChild('RESERVED_SCREEN')) end) tries -= 1 if sucess or not plr or not plr.Parent then break end end
		if tries <= 0 then
			Text_ALT(plr, 'Error Teleporting, Please Try Again Later!')
		end
	elseif message:sub(1, #'!joinrandom' + 1):lower():match('!joinrandom') or message:sub(1, #'/e !joinrandom' + 1):lower():match('/e !joinrandom') then
		if plr then
			sync_()
			local attemptleft = 10
			local isnoterror = pcall(function() game:FindFirstChildOfClass('TeleportService'):Teleport(game.PlaceId, plr, game:FindFirstChildOfClass("TeleportService"):GetLocalPlayerTeleportData(),game:FindFirstChildOfClass("TeleportService"):GetArrivingTeleportGui()) end)
			if not isnoterror then
				repeat
					task.wait(1)
					if plr then
						attemptleft -= 1
						isnoterror = pcall(function() game:FindFirstChildOfClass('TeleportService'):Teleport(game.PlaceId, plr, game:FindFirstChildOfClass("TeleportService"):GetLocalPlayerTeleportData(),game:FindFirstChildOfClass("TeleportService"):GetArrivingTeleportGui()) end)
					else
						break
					end
				until isnoterror or not plr or attemptleft <= 0	
			end
			if attemptleft <= 0 and plr then
				Text_ALT(plr, 'Random Teleport Errored, Please try again later')
			end
		end
	elseif message:lower():sub(1,#'!reserve' + 1):match('!reserve') or message:lower():sub(1,#'!reserve' + 4):match('/e !reserve') then
		local startofarguments = message:lower():sub(1,#'!reserve' + 1):match('!reserve') and (#'!reserve' + 1) or (#'!reserve' + 4)
		local argu1, argu2
		local whitelist = {usernames = {}, ids= {}}
		local split = message:sub(#message > startofarguments and startofarguments or #message, #message)
		local tablesofarguments = split ~= '' and split:split(' ')
		if tablesofarguments then
			for i,v in tablesofarguments do
				v = v:gsub(' ','')
				if not ( argu1 and argu2) then
					if v:upper() == 'SAME' then
						if not argu1 then
							argu1 = workspace.Fun.Value
						else
							argu2 = workspace.IsItRaining.Value
						end
					elseif v:upper() == 'RANDOM' then
						if not argu1 then
							argu1 = math.random(1,1000)
						else
							argu2 = math.random(-2,5)
						end
					else
						if tonumber(v) and tonumber(v) ~= '' then
							if not argu1 then
								argu1 = tonumber(v)
							else
								argu2 = tonumber(v)
							end
						end
					end
				else
					if typeof(v) == 'string' then
						if v == tostring(tonumber(v)) then -- id
							table.insert(whitelist.ids, v)
						elseif string.sub(v, 1,1) == '@' then
							table.insert(whitelist.usernames, (v:gsub('#',' ')))
						else -- likely display Name
							for i,v in Players:GetChildren() do
								if v.DisplayName:lower():match(v:lower():gsub('#',' ')) then -- orignal commands must use hash for spaced arguments
									table.insert(whitelist.usernames, v.DisplayName)
								end
							end
						end
					end
				end
			end
			if not argu1 then
				argu1 = workspace.Fun.Value
			end
			if not argu2 then
				argu2 = workspace.IsItRaining.Value
			end
			sync_()
			task.synchronize()
			local namea = plr.Name
			local teleportid = tick()..plr.Name
			local ui
			local plrready = true
			local cloned = pcall(function()
				if plr:FindFirstChildOfClass('PlayerGui') then
					ui = script.TP:Clone()
					ui.Parent = plr:FindFirstChildOfClass('PlayerGui') plrready = false end end)
			if not cloned then if ui then pcall(function()ui:Destroy() end) end ui = nil end
			local fflag if not cloned or not ui or not ui.Parent or not ui:FindFirstChildOfClass('RemoteEvent') then plrready = true else
				fflag = ui:FindFirstChildOfClass('RemoteEvent').OnServerEvent:Once(function(plr) plrready = true end) end
			local serverid
			local reserved, errormessage = pcall(function() 
				serverid =  game:FindFirstChildOfClass("TeleportService"):ReserveServerAsync(game.PlaceId)
			end)
			if not reserved or not serverid then
				Text_ALT(plr, 'Server Reservation Errored, Please try again later')
				if ui then	ui:SetAttribute('datsent', true)
					ui:SetAttribute('shutui', true)
					ui:SetAttribute('cleanup', true)
					Debris:AddItem(ui, 10) if fflag then fflag:Disconnect() fflag = nil end end
				return
			end
			if ui then	ui:SetAttribute('INITED', true)
				ui:SetAttribute('datsent',true) end
			local DATA = {
				FUN = argu1,
				RAINVALUE = argu2,
				[(serverid or 0)..'_FUN_'..tostring(game.JobId)] = argu1,
				[(serverid or 0)..'_RAINVALUE_'..tostring(game.JobId)] = argu2,
				ORIGIN_PLACE = game.PlaceId,
				ORIGINJOBID = game.JobId,
				REQUESTOR_NAME = plr and plr.Name or 'NIL',
				REQUESTOR_ID = plr.UserId or 0,
				PRIVATESERVERACCESSCODE = serverid or 0
			}
			local servarchive = Instance.new('StringValue', ServerStorage.__RESERVEDCACHE)
			servarchive.Name = teleportid
			servarchive.Value = serverid
			servarchive:SetAttribute('requestor', namea)
			servarchive:SetAttribute('requestorid', plr.UserId)
			Debris:AddItem(servarchive, 3600)
			for i,v in whitelist.ids do
				Instance.new('NumberValue', servarchive).Value = v
				local pfid = Players:GetPlayerByUserId(v)
				if pfid then
					Text_ALT(pfid, 'You were included in a reserved server by @'.. namea ..'. use command !joinreserved '..teleportid.. ' to join the server.')
				end
			end
			for i,v in whitelist.usernames do
				Instance.new('StringValue', servarchive).Value = v
				local close = Players:FindFirstChild(v)
				if close and close:IsA('Player') and close.Name == v then
					Text_ALT(close, 'You were included in a reserved server by @'.. namea ..'. use command !joinreserved '..teleportid.. ' to join the server.')
				end
			end
			Debug_Display('Teleportin To Server: '..tostring(serverid))
			local c
			local teleported, errormessage = pcall(function() 
				if ui then	ui:SetAttribute('shutui', true)
					task.wait(1.5 + math.random(100, 250)/100) 
					local tiem = 0
					repeat tiem+= task.wait(1) until plrready or tiem > 300 if fflag then fflag:Disconnect() fflag = nil end end
				if not plr then  return end
				game:FindFirstChildOfClass('TeleportService'):TeleportToPrivateServer(game.PlaceId, serverid, {plr}, '_SpawnLocation', DATA, game:FindFirstChildOfClass('ServerStorage'):FindFirstChild('RESERVED_SCREEN'))
			end)
			if not teleported and plr then
				Text_ALT(plr, 'Server Teleportation Errored, Please try again later')
				if ui then	ui:SetAttribute('cleanup', true)
					Debris:AddItem(ui, 10) if fflag then fflag:Disconnect() fflag = nil end end
				return
			end
			--clone gui
		end
	elseif  Character and (message:sub(1, #'!unstuck' + 1):lower():match('!unstuck') or message:sub(1, #'/e !unstuck' + 1):lower():match('/e !unstuck')) then
		if Character and Character:FindFirstChildOfClass('Humanoid') and not Character:GetAttribute('TP__COOLDOWN') then task.synchronize()
			sync_()
			task.synchronize()
			Character:SetAttribute('TP__COOLDOWN', true)
			task.delay(.5, function()
				if Character then
					sync_()
					Character:SetAttribute('TP__COOLDOWN', nil)
				end
			end)
			local startpos = Character:GetPivot() + Vector3.new(0,10,0)
			local cast = workspace:Raycast(startpos.Position, -Vector3.new(0,12,0), RAYPAR) or workspace:Raycast(Character:GetPivot().Position + Vector3.new(10,0,0), -Vector3.new(12,0,0), RAYPAR) or workspace:Raycast(Character:GetPivot().Position + Vector3.new(-10,0,0), Vector3.new(12,0,0), RAYPAR) or workspace:Raycast(Character:GetPivot().Position + Vector3.new(0,0,-10), Vector3.new(0,0,12), RAYPAR) or workspace:Raycast(Character:GetPivot().Position + Vector3.new(0,0,10), Vector3.new(0,0,-12), RAYPAR)
			if cast and cast.Position then
				sync_()
				if Character:FindFirstChildOfClass('Humanoid').SeatPart then
					pcall(function()	
						Character:FindFirstChildOfClass('Humanoid').PlatformStand = true task.wait() sync_() Character:FindFirstChildOfClass('Humanoid').PlatformStand = false
					end)
				end
				Character:FindFirstChildOfClass('Humanoid').PlatformStand = false
				Character:SetAttribute('PIVOTING__ENABLED', true)
				Character:SetAttribute('TARGET_DES', CFrame.new(cast.Position) + Vector3.new(0,2,0))
				task.delay(1, function() if Character and Character:GetAttribute('TARGET_DES') ==  CFrame.new(cast.Position) + Vector3.new(0,2,0) then Character:SetAttribute('TARGET_DES', nil) end end)
				Character:PivotTo(CFrame.new(cast.Position) + Vector3.new(0,2,0))
				task.wait(.1)
				Character:SetAttribute('PIVOTING__ENABLED', nil)
			end
		end
	elseif message:sub(1, #'!leave' + 1):lower():match('!leave') or message:sub(1, #'/e !leave' + 1):lower():match('/e !leave') then
		sync_() task.synchronize()
		plr:SetAttribute('CMD_ONHOLD', true)  
		if plr then
			local tries = 0
			while task.wait(1) and plr and plr.Parent and tries < 60 do
				tries += 1
				plr:Kick('User Requested Disconnection Fron The Server') 
			end
			if plr and plr.Parent then plr:Destroy() end
		end
	elseif  Character and (message:sub(1, #'!FAKER6' + 1):upper():match('!FAKER6') or message:sub(1, #'/e !FAKER6' + 1):upper():match('/E !FAKER6')) then
		if not Character or Character:GetAttribute('__DEFAULT_CLOTHING_APPLIED') then return end 
		pcall(function() task.synchronize() APPLYFAKER6(Character or (plr and plr.Character), message:lower():match('true')) end)
	elseif message:sub(1, #'!R6' + 1):upper():match('!R6') or message:sub(1, #'/e !R6' + 1):upper():match('/E !R6') then
		if not Character or not plr then
			return
		end 
		pcall(function() sync_() task.synchronize() LoadRig('R6', Character, plr) end)
	elseif message:sub(1, #'!HEAD' + 1):upper():match('!HEAD') or message:sub(1, #'/e !HEAD' + 1):upper():match('/E !HEAD') then
		if not Character or not plr then
			return
		end sync_()
		pcall(function()
			game:GetService('ServerScriptService'):FindFirstChild('HeadChanger'):FindFirstChild('Bound'):Fire(plr)
		end)
	elseif message:split(' ')[1]:lower():match('!morse') then
		if not plr then return end
		pcall(function()
			local translated = ''
			local started = table.concat(message:split(' '), ' ', 2) or string.sub(message, 6)
			translated = (started or '') .. ' => '
			local split =  string.split(started, ' ')
			for i,v in split do
				for i2,val in v:split('') do
					if val == ' ' then
						translated = translated .. ' / '
					elseif morseCode[string.upper(val)] then
						translated = translated .. morseCode[string.upper(val)].. ' '
					end
				end
				translated = translated .. ' / '
			end

			Text_ALT(plr, translated)
		end)
	elseif message:sub(1, #'!GIFT' + 1):upper():match('!GIFT') or message:sub(1, #'/e !GIFT' + 1):upper():match('/E !GIFT') then
		if not plr then
			return
		end
		sync_()
		pcall(function() task.synchronize() if not Players:FindFirstChild(trim(message:split(' ')[2])) or not Players:FindFirstChild(trim(message:split(' ')[2])):IsA('Player') or Players:FindFirstChild(trim(message:split(' ')[2])) == plr then return end (game:FindFirstChildOfClass('ServerScriptService') or game:FindFirstChild('ServerScriptService') or game:WaitForChild("ServerScriptService",10) or game:GetService("ServerScriptService") or game['ServerScriptService']):FindFirstChild('Standalone Systems').GIFTING.Event:Fire(plr, Players:FindFirstChild(trim(message:split(' ')[2])), (message:split(' ')[3] and trim(message:split(' ')[3])) or plr.Character ~= nil and plr.Character:FindFirstChildOfClass('Tool')) end)
	elseif message:sub(1, #'!BADGAMEPLAY' + 1):upper():match('!BADGAMEPLAY') or message:sub(1, #'/e !BADGAMEPLAY' + 1):upper():match('/E !BADGAMEPLAY') then
		if not plr or plr:GetAttribute('BadG') then
			return
		end
		pcall(function() task.synchronize() game:GetService('ServerScriptService').CAMPAIGN.GAMEPLAY_HANDLER.Event:Fire(plr) end)
	elseif message:sub(1, #'!SHIRT' + 1):upper():match('!SHIRT') or message:sub(1, #'/e !SHIRT' + 1):upper():match('/E !SHIRT') then	
		pcall(function()if not plr or not Character  or Character:FindFirstChildOfClass('Shirt') then return end
			task.synchronize()
			local arg = string.split(message, ' ') if not arg[2] or not  parseAssetId(arg[2]) then return end
			local a = SAFELOAD(arg[2], {11})
			if a then
				local b = a:FindFirstChildOfClass('Shirt')
				if not b  then
					a:Destroy()
					return
				end
				b.Parent = Character
			end
		end)
	elseif message:sub(1, #'!PANTS' + 1):upper():match('!PANTS') or message:sub(1, #'/e !PANTS' + 1):upper():match('/E !PANTS') then	
		pcall(function()if not plr or not Character  or Character:FindFirstChildOfClass('Pants') then return end
			task.synchronize()
			local arg = string.split(message, ' ') if not arg[2] or not   parseAssetId(arg[2]) then return end
			local a = SAFELOAD(arg[2], {12})
			if a then
				local b = a:FindFirstChildOfClass('Pants')
				if not b  then
					a:Destroy()
					return
				end
				b.Parent = Character
			end
		end)
	elseif message:sub(1, #'!TSHIRT' + 1):upper():match('!TSHIRT') or message:sub(1, #'/e !TSHIRT' + 1):upper():match('/E !TSHIRT') then	
		pcall(function()if not plr or not Character  or Character:FindFirstChildOfClass('ShirtGraphic') then return end
			task.synchronize()
			local arg = string.split(message, ' ') if not arg[2] or not parseAssetId(arg[2]) then return end
			local a = SAFELOAD(arg[2], {2})
			if a then
				local b = a:FindFirstChildOfClass('ShirtGraphic')
				if not b  then
					a:Destroy()
					return
				end
				b.Parent = Character
			end
		end)
	elseif message:sub(1, #'!BGR6' + 1):upper():match('!BGR6') or message:sub(1, #'/e !BGR6' + 1):upper():match('/E !BGR6') then
		if not plr then
			return
		end
		task.synchronize() pcall(function() (game:FindFirstChildOfClass('ServerScriptService') or game:FindFirstChild('ServerScriptService') or game:WaitForChild("ServerScriptService",10) or game:GetService("ServerScriptService") or game['ServerScriptService']):FindFirstChild('AltCharacterService'):FindFirstChildOfClass("BindableEvent"):Fire(plr, 1) end)
	elseif message:sub(1, #'!BGRIG' + 1):upper():match('!BGRIG') or message:sub(1, #'/e !BGRIG' + 1):upper():match('/E !BGRIG') then
		if not plr then
			return
		end
		task.synchronize() pcall(function() (game:FindFirstChildOfClass('ServerScriptService') or game:FindFirstChild('ServerScriptService') or game:WaitForChild("ServerScriptService",10) or game:GetService("ServerScriptService") or game['ServerScriptService']):FindFirstChild('AltCharacterService'):FindFirstChildOfClass("BindableEvent"):Fire(plr, 2) end)
	elseif message:sub(1, #'!BODYCOLOR' + 1):upper():match('!BODYCOLOR') or message:sub(1, #'/e !BODYCOLOR' + 1):upper():match('/E !BODYCOLOR') then
		if not plr or not plr.Character then
			return
		end
		pcall(function() task.synchronize() game:GetService('ServerScriptService').Accessory_Fixer_Actor["Default Clothing"].Request:Fire(plr.Character or Character) end)
	elseif  Character and (message:sub(1, #'!R15' + 1):upper():match('!R15') or message:sub(1, #'/e !R15' + 1):upper():match('/E !R15')) then
		if Character and Character:FindFirstChildOfClass('Humanoid') and Character:FindFirstChildOfClass('Humanoid').RigType == Enum.HumanoidRigType.R15 then
			return
		end
		sync_()
		task.synchronize()
		pcall(function() LoadRig('R15', Character, plr) end)
	elseif (message:lower() == '!re') or (message:lower() == '/e !re') or message:sub(1, #'!reset' + 1):lower():match('!reset') or message:sub(1, #'/e !reset' + 1):lower():match('/e !reset') then
		if plr then
			sync_()
			task.synchronize()
			local success = pcall(function() plr:LoadCharacterAsync() end)
			if not success then
				Text_ALT(plr, "Respawn Errored, Try the command '!fre' instead.")
			end
		end
	elseif  Character and (message:sub(1, #'!tospawn' + 1):lower():match('!tospawn') or message:sub(1, #'!spawn' + 1):lower():match('!spawn') or message:sub(1, #'/e !spawn' + 1):lower():match('/e !spawn') or message:sub(1, #'/e !tospawn' + 1):lower():match('/e !tospawn')) then
		if plr and Character and Character:FindFirstChildOfClass('Humanoid') and not Character:GetAttribute('TP__COOLDOWN') then
			sync_()
			task.synchronize()
			Character:SetAttribute('TP__COOLDOWN', true)
			task.delay(1, function()
				if Character then
					sync_()
					Character:SetAttribute('TP__COOLDOWN', nil)
				end
			end)
			sync_()
			pcall(function()
				local this
				Character:SetAttribute('PIVOTING__ENABLED', true)
				if Character:FindFirstChildOfClass('Humanoid').SeatPart and Character:FindFirstChildOfClass('Humanoid').SeatPart:FindFirstChild('SeatWeld') then
					this = true
					Character:FindFirstChildOfClass('Humanoid').PlatformStand = true
				end
				Character:SetAttribute('TARGET_DES', (FindFirstChildOfNameAndClass(workspace, '_SpawnLocation', 'SpawnLocation') or workspace:FindFirstChildOfClass('SpawnLocation') or {CFrame = CFrame.new(59.558, 2.5, -1.039)}).CFrame)
				task.delay(1, function() if Character and Character:GetAttribute('TARGET_DES') ==   (FindFirstChildOfNameAndClass(workspace, '_SpawnLocation', 'SpawnLocation') or workspace:FindFirstChildOfClass('SpawnLocation') or {CFrame = CFrame.new(59.558, 2.5, -1.039)}).CFrame then Character:SetAttribute('TARGET_DES', nil) end end)
				Character:PivotTo( (FindFirstChildOfNameAndClass(workspace, '_SpawnLocation', 'SpawnLocation') or workspace:FindFirstChildOfClass('SpawnLocation') or {CFrame = CFrame.new(59.558, 2.5, -1.039)}).CFrame)
				if this then
					task.wait()
					sync_()
					Character:FindFirstChildOfClass('Humanoid').PlatformStand = false
				end
				task.wait(.1)
				Character:SetAttribute('PIVOTING__ENABLED', nil)
			end)
		end
	elseif  Character and (message:sub(1, #'!char' + 1):lower():match('!char') or message:sub(1, #'!changechar' + 1):lower():match('!changechar') or message:sub(1, #'/e !char' + 1):lower():match('/e !char') or message:sub(1, #'/e !changechar' + 1):lower():match('/e !changechar')) then
		if plr and Character and not Character:GetAttribute('__DEFAULT_CLOTHING_APPLIED') and tonumber(message:sub(#'!char', #message)) then
			sync_()
			if workspace.Name:upper():match('STANDARD') then Text_ALT(plr, "[[The Command '!char' Is Disabled In This Server.]]") end
			if not game:FindFirstChildOfClass('Players') or not game:FindFirstChildOfClass('Players'):GetHumanoidDescriptionFromOutfitIdAsync(tonumber(message:sub(#'!char', #message))) then
				Text_ALT(plr, 'Please input a valid OUTFIT_ID')
				if Character and Character:FindFirstChildOfClass('Humanoid') then
					Character:FindFirstChildOfClass('Humanoid'):ApplyDescriptionReset(game:FindFirstChildOfClass('Players'):GetHumanoidDescriptionFromOutfitIdAsync(tonumber(message:sub(#'!char', #message))))
				end
			end
		end
	elseif  Character and (message:sub(1, #'!trip' + 1):lower():match('!trip') or message:sub(1, #'/e !trip' + 1):lower():match('/e !trip')) then
		if plr and Character and Character:FindFirstChildOfClass('Humanoid') then
			sync_()
			pcall(function()
				if Character:FindFirstChildOfClass('Humanoid').SeatPart then
					Character:FindFirstChildOfClass('Humanoid').PlatformStand = true task.wait() sync_() Character:FindFirstChildOfClass('Humanoid').PlatformStand = false
				end
			end)
			Character:FindFirstChildOfClass('Humanoid').Sit = false
			Character:PivotTo(Character:GetPivot() * CFrame.Angles(math.random() > .5 and math.rad(90) or math.rad(-90),math.random(),math.random()))
		end
	elseif  Character and (message:sub(1, #'!displayname' + 1):lower():match('!displayname') or message:sub(1, #'/e !displayname' + 1):lower():match('/e !displayname')) then
		if plr and Character and Character:FindFirstChildOfClass('Humanoid') then
			sync_()
			local startingpoint = (message:sub(1, #'/e !displayname' + 1):lower():match('/e !displayname') and  (#'/e !displayname' + 2)) or  (#'!displayname' + 2)
			local didit = pcall(function()
				Character:FindFirstChildOfClass('Humanoid').DisplayName = game:GetService('TextService'):FilterStringAsync(trim(string.gsub(message:sub((startingpoint or (#'/e !displayname' + 2)), #message), "[^%w]", "")), plr.UserId, Enum.TextFilterContext.PublicChat):GetNonChatStringForBroadcastAsync()
			end)
			if not didit and  workspace.Name:upper():match('RESERVED') then
				pcall(function()Character:FindFirstChildOfClass('Humanoid').DisplayName = trim(string.gsub(message:sub((startingpoint or (#'/e !displayname' + 2)), #message), "[^%w]", ""))end)
			elseif not didit then Text_ALT(plr, '[[Text Filtering Failed: Please Try "!displayname" Again Later!]]') end
		end
	elseif  Character and (message:sub(1, #'!bbchat' + 1):lower():match('!bbchat') or message:sub(1, #'/e !bbchat' + 1):lower():match('/e !bbchat')) then
		if plr and Character and Character.Parent and Character:IsDescendantOf(workspace) and Character:FindFirstChildOfClass('Humanoid') then
			sync_()
			if workspace.Name:upper():match('STANDARD') then Text_ALT(plr, '<{Feature Not Available In Public Servers!}>') end
			local startingpoint = (message:sub(1, #'/e !bbchat' + 1):lower():match('/e !bbchat') and  (#'/e !bbchat' + 2)) or  (#'!bbchat' + 2)
			local didit = pcall(function()
				game:GetService('ServerScriptService'):FindFirstChild('BUBBLECHAT!').Event:Fire(Character, game:GetService('TextService'):FilterStringAsync(trim(string.gsub(message:sub((startingpoint or (#'/e !bbchat' + 2)), #message), "[^%w_%s]", "")), plr.UserId, Enum.TextFilterContext.PublicChat):GetNonChatStringForBroadcastAsync(), nil, true)
			end)
			if not didit and  workspace.Name:upper():match('RESERVED') then
				pcall(function() Character:FindFirstChildOfClass('Humanoid').DisplayName = trim(string.gsub(message:sub((startingpoint or (#'/e !bbchat' + 2)), #message), "[^%w]", "")) end)
			elseif not didit then Text_ALT(plr, '[[Text Filtering Failed: Please Try "!bbchat" Again Later!]]') end
		end
	elseif  (message:sub(1, #'!subtosafechat' + 1):lower():match('!subtosafechat') or message:sub(1, #'/e !subtosafechat' + 1):lower():match('/e !subtosafechat')) or ((message:sub(1, #'!safechat' + 1):lower():match('!safechat') or message:sub(1, #'/e !safechat' + 1):lower():match('/e !safechat') )and #string.split(message, ' ') <= 1) then
		if plr and plr.Parent then sync_()
			task.synchronize()
			pcall(function()
				if not plr:GetAttribute('subtosafechat') then
					plr:SetAttribute('subtosafechat', true)Text_ALT(plr, '{SYSTEM}: You are now subscribed to safechat messages!')
				else plr:SetAttribute('subtosafechat', nil)Text_ALT(plr, '{SYSTEM}: You have been unsubscribed from safechat messages!')  end
			end) end
	elseif (message:sub(1, #'!safechatlog' + 1):lower():match('!safechatlog') or message:sub(1, #'/e !safechatlog' + 1):lower():match('/e !safechatlog')) then
		if plr and plr.Parent then 
			local uptolog = #chatlog
			message = message:gsub('/e', '')
			local splitted = string.split(message, ' ')
			local arg=splitted[3] -- maybe they input it
			if arg and typeof(tonumber(arg)) == 'number' then
				uptolog = math.clamp(tonumber(arg),0,100)
			end
			uptolog-=1 sync_()
			pcall(function()
				Text_ALT(plr, '{RELAYING LOGS}:','\n',table.concat(chatlog, '\n', math.clamp(#chatlog - uptolog,1,100), math.clamp(#chatlog,1,100)))
			end) end
	elseif  Character and (message:sub(1, #'!safechat' + 1):lower():match('!safechat') or message:sub(1, #'/e !safechat' + 1):lower():match('/e !safechat')) then
		if plr and Character and Character.Parent and Character:IsDescendantOf(workspace) and (Character:FindFirstChildOfClass('Humanoid') or Character:GetAttribute('__REGPLRID')) then
			sync_()
			local startingpoint = (message:sub(1, #'/e !safechat' + 1):lower():match('/e !safechat') and  (#'/e !safechat' + 2)) or  (#'!safechat' + 2)
			local filtered = trim(message:sub((startingpoint or (#'/e !safechat' + 2)), #message))
			if not table.find(wordlist , filtered:lower()) then
				pcall(function() Text_ALT(plr, 'Word Not Found In Wordlist, Use Command "!safechatwordlist" To Check The Words That Had Been Whitelisted') end)
				return
			end
			local success = pcall(function() filtered = string.sub(filtered,1,1):upper().. string.sub(filtered, 2):lower() end)
			if not success then Text(plr, 'Message did not go through, Try Again!') end
			local didit = pcall(function()
				game:GetService('ServerScriptService'):FindFirstChild('BUBBLECHAT!').Event:Fire(Character, filtered, nil, true)
			end)
			pcall(function()
				for i,v in Players:GetChildren() do
					if v:IsA('Player') and v:GetAttribute('subtosafechat') then
						Text_ALT(v, '['..plr.Name.. ']: '.. filtered)
					end
				end
			end)
			pcall(function()
				table.insert(chatlog, '['..plr.Name.. ']: '.. filtered)
			end)if #chatlog > 100 then
				table.remove(chatlog, 1)
			end
		end	
	end
	--print(message:sub(1, #'!bbchat' + 1):lower())
end
task.synchronize()
local replicated = (game:FindFirstChildOfClass('ReplicatedStorage') or game:GetService('ReplicatedStorage'))
local binder = replicated:FindFirstChild('COMMANDS_NORMAL_ACCESS') or replicated:WaitForChild('COMMANDS_NORMAL_ACCESS', 10)
if not binder then
	binder = Instance.new('BindableEvent') binder.Name = 'COMMANDS_NORMAL_ACCESS' binder.Parent = replicated end
binder.Event:Connect(function(plr: Player, message)
	if typeof(plr) ~= 'Instance' or typeof(message) ~= 'string' or  (not message:sub(1,2):match('!') and not message:sub(1,5):match('/e !')) or plr.ClassName ~= 'Player' or plr.Parent ~= Players or typeof(plr.Parent) ~= `Instance` then return end
	local filt = RaycastParams.new()
	filt.FilterType = Enum.RaycastFilterType.Exclude
	local CHR
	for i,v in workspace:GetChildren() do
		if v:GetAttribute('__REGPLRID') == plr.UserId then
			CHR = v
		end
	end
	filt.FilterDescendantsInstances = {CHR or plr.Character}
	filt.IgnoreWater = true
	filt.RespectCanCollide = true
	if not Matchedcmd(message) and not table.find(Commandsa, message:lower()) then message = getCommandSuggestions(message) or message end
	pcall(function()
	processcom(plr, CHR or plr.Character, message, filt)
end) end)