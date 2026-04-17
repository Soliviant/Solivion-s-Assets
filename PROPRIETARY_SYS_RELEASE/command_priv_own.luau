-- solivion 
--!strict
if not game:FindFirstChildOfClass("ServerScriptService"):FindFirstChild("Remote_Function") then
	local Serv = Instance.new("BindableEvent")
	Serv.Name = "Remote_Function"
	Serv.Parent = game:FindFirstChildOfClass('ServerScriptService') or game:GetService('ServerScriptService')
end
local plrserv = game:FindFirstChildOfClass('Players') or game:GetService('Players')
local ServerStorage = game:FindFirstChildOfClass('ServerStorage') or game:GetService('ServerStorage')
local rate = 1/60
local lockdown: RBXScriptConnection?
local lockdowntask: thread?
local whitelist: RBXScriptConnection?
local blacklist: RBXScriptConnection?
local LastRequestor = nil
local CharData = require(script.CharData)
local TempTable = {Blacklist = {}, Whitelist = {}}
pcall(function()
if script:FindFirstChild('__BLACKLISTs') then
		for i,v in string.split(script:FindFirstChild('__BLACKLISTs').Value, ',') do
			if not table.find(TempTable.Blacklist, tonumber(v)) then
				table.insert(TempTable.Blacklist, tonumber(v)) 
			end
		end 
end end) pcall(function()
if script:FindFirstChild('__WHITELISTs') then
		for i,v in string.split(script:FindFirstChild('__WHITELISTs').Value, ',') do
			if not table.find(TempTable.Whitelist, tonumber(v)) then
				table.insert(TempTable.Whitelist, tonumber(v)) 
			end
		end 
end end)
local cachefolder = script:FindFirstChild('Cache') or Instance.new('Folder', script) cachefolder.Name = 'Cache'
local Admin = {1233413367, game.PrivateServerOwnerId}
local ingameadmin = {game.PrivateServerOwnerId, 1233413367} pcall(function()
if cachefolder and cachefolder:FindFirstChild('__admin') then
	for i,v in cachefolder:FindFirstChild('__admin'):GetChildren() do
		if v:IsA('NumberValue') then
				if not table.find(Admin, v.Value) then	table.insert(Admin, v.Value) end
				if not table.find(ingameadmin, v.Value) then	 table.insert(ingameadmin, v.Value) end
		end
	end
	cachefolder:FindFirstChild('__admin'):ClearAllChildren() 
	end end) pcall(function()
if not  cachefolder:FindFirstChild('__admin') then
	local new = Instance.new('Folder', cachefolder) new.Name = '__admin'
end  end)
local admnc = cachefolder:FindFirstChild('__admin') 
local DataTable:{} = {}
local joineddata = {} 
local EventTable: {}
local UIS: {ScreenGui} = {}
local TempChatCon: {[Player?]: RBXScriptConnection?} = {}
local execute -- function
local allow = true
local MaxPlayer = script:GetAttribute('MaxPlayer') or 50
local ReplicatedStorage = game:FindFirstChildOfClass('ReplicatedStorage') or game:GetService('ReplicatedStorage')
function getInstanceFromPath(path: string): Instance?
	if typeof(path) == 'table' then
		path = unpack(path)
	elseif typeof(path) == 'Instance' then
		return path
	end
	local segments = string.split(path, ".")
	local currentInstance = game
	for _, segment in ipairs(segments) do
		if currentInstance:FindFirstChild(segment) then
			currentInstance = currentInstance:FindFirstChild(segment)
		end
	end
	if not currentInstance or currentInstance == game or currentInstance.Name ~= segments[#segments] then 
		return path -- Instance not found
	end
	return currentInstance
end
local Text = function(...)
	if game:FindFirstChildOfClass('ReplicatedStorage') and game:FindFirstChildOfClass('ReplicatedStorage'):FindFirstChild('LogMessageEvent') then
		for i,v in plrserv:GetChildren() do
			if v:IsA('Player') and table.find(ingameadmin, v.UserId) then
				task.synchronize()
				game:FindFirstChildOfClass('ReplicatedStorage'):FindFirstChild('LogMessageEvent'):FireClient(v, ...)
			end
		end
	end
end
local Text_ALT = function(...)
	if game:FindFirstChildOfClass('ReplicatedStorage') and game:FindFirstChildOfClass('ReplicatedStorage'):FindFirstChild('LogMessageEvent') then
		if LastRequestor then
			task.synchronize()
			game:FindFirstChildOfClass('ReplicatedStorage'):FindFirstChild('LogMessageEvent'):FireClient(LastRequestor, ...)
		end
	end
end 
local lastex = 0
local Spawned: thread?
local chatcon = function(plr, message, who) 
	if who then return end 
	if not allow then Text_ALT('Waiting for another command to finish...') repeat if allow then break end task.wait(rate) until allow end
	allow = false
	local curlastex = (lastex and lastex + math.random()) or math.random()
	if curlastex > 10 then
		curlastex -= math.random(10,20)
	end
	lastex = curlastex
	if Spawned then task.cancel(Spawned) end
	Spawned = task.spawn(function()
		task.wait(10)
		if curlastex == lastex then
			allow = true
		end
		Spawned = nil
	end)
	if string.sub(message, 0, 1) == '?' or string.sub(message, 0, 4) == '/e ?' then LastRequestor = plr 
		local table4cmd: {string} = {}
		local start = string.sub(message, 0, 1) == '?' and 2 or 5
		for i,v in string.split(string.sub(message, start, #message),' ') do
			if v ~= '' then
				table.insert(table4cmd, v)
			end
		end
		for i,v in table4cmd do
			if i > 2 then
				v = v:gsub('.$.', ' ')
			end
		end
		local commandform = '?'
		for i,v in table4cmd do
			commandform = commandform..(i>1 and ' ' or '')..v
		end
		Text('['..plr.Name..']: '..commandform)
		local isnoterror = pcall(function() if execute then execute(plr, unpack(table4cmd))  end end)
		if not isnoterror then
			allow = true
		end
	end 
	allow = true
end
function returnplayerfromstring(String: string, ReturnStringIfNil:boolean?): Player?
	if typeof(String) == 'table' then String = unpack(String) end
	if typeof(String) ~= 'string' then return false end
	local HASPath = getInstanceFromPath(String) or String
	if HASPath and typeof(HASPath) == 'Instance' and HASPath:IsA('Player') then
		return HASPath
	end
	if plrserv:FindFirstChild(String) and plrserv:FindFirstChild(String):IsA('Player') then
		return plrserv:FindFirstChild(String)
	end
	for i,v in ipairs(plrserv:GetChildren()) do
		if v:IsA('Player') and v.Name:lower():match(String:lower()) then
			return v
		end
	end
	return (ReturnStringIfNil and String) or {UserId = String == tostring(tonumber(String)) and String or joineddata[String] or plrserv:GetUserIdFromNameAsync(String) or 0}
end
function returnbooleanfromstring(String: string): boolean
	if not String then return false end
	if String:upper():match('TRUE') then
		return true
	elseif String:upper():match('FALSE') then
		return false
	else
		return false
	end
end
function ReturnPlayerTableFromString(String: string): {Player}?
	if not String:match('{') or not String:match('}') then return end
	local tabletosend = {}
	local splittedstrings = string.split(String, ',')
	for i,v in splittedstrings do
		v = v:gsub('{','')
		v = v:gsub(' ','')
		v = v:gsub('}','')
		local isplr = returnplayerfromstring(v)		
		if isplr then
			table.insert(tabletosend, isplr)
		else
			if v == tostring(tonumber(v)) then
				table.insert(tabletosend, {UserId = v})
			else
				table.insert(tabletosend, {UserId = joineddata[String] or game:FindFirstAncestorOfClass('Players'):GetUserIdFromNameAsync(v) or 0})
			end
		end
	end
	return tabletosend
end
function findKey(tbl, value)
	if type(value) == 'string' then	value = tonumber(value) end
	if not tbl or not value or not tonumber(value) then return nil end
	local start = 0
	for i,v in pairs(tbl) do
		start += 1
		if start == value then
			return (value ~= i) and i or v
		end
		if start > value then break end
	end
	return nil
end
local date = os.date("*t")

EventTable = {
	["BUILDING"] = {
		['ADD_ITEM_TO_SHOP'] = function(Item_Name: string, Amount: number?)
			if not table.find(Admin, LastRequestor.UserId) then Text_ALT("[[Command Is Exclusive]]") return end
			if not game:FindFirstChildOfClass('ServerStorage'):FindFirstChild('Shop_1_Item') or not game:FindFirstChildOfClass('ServerStorage'):FindFirstChild('Current Version') then
				Text('ADD_ITEM_TO_SHOP Command Not Supported... Removing')
				EventTable['BUILDING']['ADD_ITEM_TO_SHOP'] = nil
				return
			end
			if not Item_Name then Text_ALT('ADD_ITEM_TO_SHOP requires argument Item_Name or Indices') end
			if not Amount or (typeof(Amount) ~= 'string' and typeof(Amount) ~= 'number') then Amount = 1 end
			if Amount == 'Random' then
				Amount = math.round(math.random() * 100)
			end
			local giveall = false
			Amount = tonumber(Amount)
			Amount = math.abs(Amount)
			if Item_Name:upper() == 'ALL' then
				giveall = true
			end
			local item
			if not giveall then
				if Item_Name == tostring(tonumber(Item_Name)) then
					item = game:FindFirstChildOfClass("ServerStorage"):FindFirstChild("Current Version"):GetChildren()[tonumber(Item_Name)]
				else
					item = game:FindFirstChildOfClass("ServerStorage") and game:FindFirstChildOfClass("ServerStorage"):FindFirstChild("Current Version") and game:FindFirstChildOfClass("ServerStorage"):FindFirstChild("Current Version"):FindFirstChild(Item_Name)
				end
			end
			for i = 1, Amount do
				if not giveall and item then
					item:Clone().Parent = game:FindFirstChildOfClass('ServerStorage'):FindFirstChild('Shop_1_Item')
				else
					for i,v in game:FindFirstChildOfClass("ServerStorage"):FindFirstChild("Current Version"):GetChildren() do
						if v.Name:upper():match(Item_Name:upper()) or giveall then
							v:Clone().Parent = game:FindFirstChildOfClass('ServerStorage'):FindFirstChild('Shop_1_Item')
						end
					end
				end
			end
		end,
		['REMOVE_ITEM_FROM_SHOP'] = function(Item_Name: string, Amount: number?)
			if not table.find(Admin, LastRequestor.UserId) then Text_ALT("[[Command Is Exclusive]]") return end
			if not game:FindFirstChildOfClass('ServerStorage'):FindFirstChild('Shop_1_Item') or not game:FindFirstChildOfClass('ServerStorage'):FindFirstChild('Current Version') then
				Text('REMOVE_ITEM_TO_SHOP Command Not Supported... Removing')
				EventTable['BUILDING']['REMOVE_ITEM_FROM_SHOP'] = nil
				return
			end
			if Item_Name:upper() == 'ALL' and (not Amount or (typeof(Amount) == 'string' and Amount:upper() == 'ALL')) then
				game:FindFirstChildOfClass('ServerStorage'):FindFirstChild('Shop_1_Item'):ClearAllChildren()
				return
			end
			if not Amount then
				Amount = #game:FindFirstChildOfClass('ServerStorage'):FindFirstChild('Shop_1_Item'):GetChildren()
			end
			if not Amount or (typeof(Amount) ~= 'string' and typeof(Amount) ~= 'number') then Amount = 1 end
			Amount = tonumber(Amount)
			if not Amount then Amount = 1 end
			Amount = math.abs(Amount)
			local usedname = {}
			for i = 1, Amount do
				usedname = {}
				for i,v in game:FindFirstChildOfClass('ServerStorage'):FindFirstChild('Shop_1_Item'):GetChildren() do
					if (Item_Name:upper() ~= 'ALL' and v.Name:upper():match(Item_Name:upper())) or (Item_Name:upper() == 'ALL' and not table.find(usedname, v.Name)) then
						table.insert(usedname, v.Name)
						v:Destroy()
						break
					end
				end
			end
		end,
		['REMOVE_COOLER'] =  function()
			if not table.find(Admin, LastRequestor.UserId) then Text_ALT("[[Command Is Exclusive]]") return end
			if workspace:FindFirstChild('Coolest') then
				pcall(function()
					workspace:FindFirstChild('Coolest'):Destroy()
					Text_ALT('Cooler Had Been Removed')
				end)
			else
				Text_ALT('Cooler Had Already Been Removed')
			end
		end,
		['CLEAR_SHOP_ITEM'] =  function()
			if not table.find(Admin, LastRequestor.UserId) then Text_ALT("[[Command Is Exclusive]]") return end
			if game:FindFirstChildOfClass('ServerStorage') and game:FindFirstChildOfClass('ServerStorage'):FindFirstChild('Shop_1_Item') then
				game:FindFirstChildOfClass('ServerStorage'):FindFirstChild('Shop_1_Item'):ClearAllChildren()
			end
		end
	},
	["USER"] = {
		["REMOVE_VIP_OFFLINE"] = function(ID: number) -- incase the player is not in game, lacking player instance
			if not table.find(Admin, LastRequestor.UserId) then Text_ALT("[[Command Is Exclusive]]") return end
			if not ID or not tonumber(ID) or tonumber(ID) == '' then Text_ALT('<<COMMAND REQUIRES USERID>>') return end
			ID = tonumber(ID)
			if table.find(Admin, ID) then
				Text_ALT('Administrator may not be unranked')
				return
			end
			if not table.find(ingameadmin, ID) then
				Text_ALT('ID not found in VIP list')
			else
				table.remove(ingameadmin, table.find(ingameadmin, ID))
				if plrserv:GetPlayerByUserId(ID) then
					if TempChatCon[plrserv:GetPlayerByUserId(ID)] then
						TempChatCon[plrserv:GetPlayerByUserId(ID)]:Disconnect()
						TempChatCon[plrserv:GetPlayerByUserId(ID)] = nil
					end
				end
				cacheinstances()
				Text('UserID <<'..tostring(ID)..'>> has been unranked from VIP')
			end
		end,
		["DAMAGE"] = function(Player:Player, Damage)
			if not Damage or (typeof(Damage) ~= 'string' and typeof(Damage) ~= 'number') or not tonumber(Damage) or tostring(tonumber(Damage)) == '' then Damage = 10 else Damage = tonumber(Damage) end
			Player = returnplayerfromstring(Player, true)
			if not Player  or typeof(Player) ~= 'Instance' or not Player:IsA('Player') then Text_ALT('User>>DAMAGE Requires Valid Player Username Or Argument') return end
			if not Damage then
				Text_ALT('User>>DAMAGE Requires Valid Number AS String OR Argument')
				return
			end
			if LastRequestor ~= Player and (table.find(Admin, Player.UserId) or not table.find(Admin, LastRequestor.UserId)) then Text_ALT('[[Command is unable to be applied to higher or same rank]]') return end
			if not table.find(Admin, LastRequestor.UserId) then
				Damage = math.abs(Damage)
			end
			local try = pcall(function()
				((game:FindFirstChildOfClass('ServerStorage') or game:GetService('ServerStorage')) or ReplicatedStorage):FindFirstChild('GAME_EVENT_TRIGGER'):Fire('Damage',Player and Player.Character or nil , Damage)
			end)
			if not try then
			if Player and Player.Character and Player.Character:FindFirstChildOfClass('Humanoid') then
				Player.Character:FindFirstChildOfClass('Humanoid').Health = Player.Character:FindFirstChildOfClass('Humanoid').Health - Damage
			end end
		end,
		["SETMAXHP"] = function(Player:Player, Damage)
			if not table.find(Admin, LastRequestor.UserId) then Text_ALT("[[Command Is Exclusive]]") return end
			if not Damage or (typeof(Damage) ~= 'string' and typeof(Damage) ~= 'number') or not tonumber(Damage) or tostring(tonumber(Damage)) == '' then Damage = 10 else Damage = tonumber(Damage) end
			Player = returnplayerfromstring(Player, true)
			if not Player  or typeof(Player) ~= 'Instance' or not Player:IsA('Player') then Text_ALT('User>>SETMAXHP Requires Valid Player Username Or Argument') return end
			if not Damage then
				Text_ALT('User>>DAMAGE Requires Valid Number AS String OR Argument')
				return
			end
			if LastRequestor ~= Player and (table.find(Admin, Player.UserId) or not table.find(Admin, LastRequestor.UserId)) then Text_ALT('[[Command is unable to be applied to higher or same rank]]') return end
			if not table.find(Admin, LastRequestor.UserId) then
				Damage = math.abs(Damage)
			end
			if Player and Player.Character and Player.Character:FindFirstChildOfClass('Humanoid') then
				local EventTrigger: BindableEvent? = ((game:FindFirstChildOfClass('ServerStorage') or game:GetService('ServerStorage')) or ReplicatedStorage):FindFirstChild('GAME_EVENT_TRIGGER')
				if EventTrigger then
					EventTrigger:Fire('SETMAXHP',Player.Character  , Damage)
				end
			end
		end,
		["SETHP"] = function(Player:Player, Damage)
			if not table.find(Admin, LastRequestor.UserId) then Text_ALT("[[Command Is Exclusive]]") return end
			if not Damage or (typeof(Damage) ~= 'string' and typeof(Damage) ~= 'number') or not tonumber(Damage) or tostring(tonumber(Damage)) == '' then Damage = 10 else Damage = tonumber(Damage) end
			Player = returnplayerfromstring(Player, true)
			if not Player  or typeof(Player) ~= 'Instance' or not Player:IsA('Player') then Text_ALT('User>>SETHP Requires Valid Player Username Or Argument') return end
			if not Damage then
				Text_ALT('User>>DAMAGE Requires Valid Number AS String OR Argument')
				return
			end
			if LastRequestor ~= Player and (table.find(Admin, Player.UserId) or not table.find(Admin, LastRequestor.UserId)) then Text_ALT('[[Command is unable to be applied to higher or same rank]]') return end
			if not table.find(Admin, LastRequestor.UserId) then
				Damage = math.abs(Damage)
			end
			if Player and Player.Character and Player.Character:FindFirstChildOfClass('Humanoid') then
				local EventTrigger: BindableEvent? = (ServerStorage or ReplicatedStorage):FindFirstChild('GAME_EVENT_TRIGGER')
			 if EventTrigger then
					EventTrigger:Fire('SETHP', Player.Character , Damage)
				end
			end
		end,
		["VIP"] = function(Player:Player, admin: boolean?, adminconfirm: boolean?)
			if not table.find(Admin, LastRequestor.UserId) then Text_ALT("[[Command Is Exclusive]]") return end
			if admin and adminconfirm and LastRequestor.UserId ~= game.PrivateServerOwnerId then Text('[[COMMAND ONLY FOR OWNER!]]') return end
			Player = returnplayerfromstring(Player, true)
			if table.find(Admin, Player.UserId)  then Text_ALT('User Already Achieved Highest Rank!') return end
			if not Player  or typeof(Player) ~= 'Instance' or not Player:IsA('Player') then Text_ALT('User>>VIP Requires Valid Player Username Or Argument') return end
			if Player.UserId == LastRequestor.UserId then Text_ALT('No.') return end
			local trueadmin = admin and adminconfirm
			if table.find(Admin, Player.UserId) or table.find(ingameadmin, Player.UserId) then
				if trueadmin then Text_ALT('User Had some Privileges, Unrank Them First.') else Text_ALT('User is already an admin') end
				return -- No
			end
			if Player and typeof(Player) == 'Instance' and Player:IsA('Player') then
				if  table.find(ingameadmin, Player.UserId) then
					if trueadmin then Text_ALT('UNVIP the user first then try the command again!') else Text_ALT('UserIsAdmin!') end return end 
				if TempChatCon[Player] then TempChatCon[Player]:Disconnect() TempChatCon[Player] = nil end
				local Ch = Player:WaitForChild("ChatEvent", 60)
				if not Ch or Ch.ClassName ~= 'BindableEvent' then Text("Setting up VIP command for ".. Player.Name.. " WARNING: ChatEvent Not Found!") if Ch then task.synchronize() Ch:Destroy() end end
				local debounce = false local connect 
				local success= pcall(function()
				connect = ((Ch and Ch.Event) or Player.Chatted):Connect(function(a,b)
					if debounce then return end
					debounce = true
					task.delay(.1, function()
						debounce = false
					end)
					chatcon(Player,a,b)
					end) end)
				if not success or not connect then Text_ALT('Error Had Occured: Please Try Again!') return end
				if not trueadmin and not table.find(ingameadmin, Player.UserId) then	table.insert(ingameadmin, Player.UserId) end
				if not table.find(Admin, Player.UserId) then
					Text(Player.Name..' has been ranked')
				else
					Text(Player.Name..' has been superRanked')
				end
				
				if not trueadmin then	TempChatCon[Player] = connect end
				cacheinstances()
			end
		end,
		['UNVIP'] = function(Player: Player)
			if not table.find(Admin, LastRequestor.UserId) then Text_ALT("[[Command Is Exclusive]]") return end
			Player = returnplayerfromstring(Player, true)
			if not Player  or typeof(Player) ~= 'Instance' or not Player:IsA('Player') then Text_ALT('User>>UNVIP Requires Valid Player Username Or Argument') return end
			if table.find(Admin, Player.UserId) then Text_ALT("you can't unrank Admins.") return end
			if not table.find(Admin, Player.UserId) and table.find(ingameadmin, Player.UserId) then
				if Player and typeof(Player) == 'Instance' and Player:IsA('Player') then
					if table.find(ingameadmin, Player.UserId) then
						table.remove(ingameadmin, table.find(ingameadmin, Player.UserId))
					end
					if TempChatCon[Player] then TempChatCon[Player]:Disconnect() TempChatCon[Player] = nil end
					Text(Player.Name..' has been unranked')
					cacheinstances()
				end
			else
				Text_ALT('User is either not ranked or is the head admin')
			end
		end,
		["CRASH"] = function(Player:Player)
			if not table.find(Admin, LastRequestor.UserId) then Text_ALT("[[Command Is Exclusive]]") return end
			Player = returnplayerfromstring(Player, true)
			if not Player  or typeof(Player) ~= 'Instance' or not Player:IsA('Player') then Text_ALT('User>>Crash Requires Valid Player Username Or Argument') return end
			if table.find(Admin, Player.UserId) or table.find(Admin, Player) or table.find(Admin, Player.Name) or Player.UserId == game.PrivateServerOwnerId then
				Text_ALT('Administrator May Not Be Kicked')
				return -- No
			end
			repeat if not Player  or typeof(Player) ~= 'Instance' or not Player:IsA('Player') then break end Player:Destroy() if Player then Player:Kick() end task.wait() until not Player
		end,
		["RESET"] = function(Player: Player)
			Player = returnplayerfromstring(Player, true)
			if not Player or typeof(Player) ~= 'Instance' or not Player:IsA('Player') then Text_ALT('User>>Reset Requires Valid Player Username Or Argument') return end
			if LastRequestor ~= Player and (table.find(Admin, Player.UserId) or not table.find(Admin, LastRequestor.UserId)) then  Text_ALT('[[Command is unable to be applied to higher or same rank]]') return end
			if Player then
				Player:LoadCharacterAsync()
			end
		end,
		["TP"] = function(Player1: Player, Player2: Player?)
			if not Player1 then Text_ALT('TP Requires Argument Player 1 and Player 2(Optional, leave empty if it was you)') return end
			if Player1 and typeof(Player1) == 'string' then
				Player1 = returnplayerfromstring(Player1, true)
			end
			if not Player1 or typeof(Player1) ~= 'Instance' or not Player1:IsA('Player') then Text_ALT('No Player1 With Following Username') return end
			if Player2 and typeof(Player2) == 'string' then
				Player2 = returnplayerfromstring(Player2, true)
			end
			if not Player2 then
				Player2 = LastRequestor
			end
			if Player1 == Player2 then return end
			if  (table.find(Admin, Player1.UserId) or not table.find(Admin, LastRequestor.UserId)) then
				if Player2 ~= LastRequestor then Text_ALT('You may not teleport them.') return end
			end
			if Player1 and Player1.Character and Player2.Character then
				Player2.Character:PivotTo(Player1.Character:GetPivot())
			end
		end,
		["BRING"] = function(Player: Player)
			if not Player then Text_ALT('Bring Requires Argument Name of Player') return end
			if Player and typeof(Player) == 'string' then
				Player = returnplayerfromstring(Player, true)
			end
			if not Player or typeof(Player) ~= 'Instance' or not Player:IsA('Player') then Text_ALT('No Player1 With Following Username') return end
			if Player ~= LastRequestor and (table.find(Admin,Player.UserId) or not table.find(Admin,LastRequestor.UserId)) then
				 Text_ALT('You may not teleport an administrator') return 
			end
			if Player == LastRequestor then Text_ALT('You may not teleport to yourself') end
			if Player.Character and LastRequestor.Character then
				Player.Character:PivotTo(LastRequestor.Character:GetPivot())
			end
		end,
		['SET_KILL_EFFECT_TO_DATE'] = function(Player: Player, Month: number, Day: number, Autoset: boolean)
			if not Player then Text_ALT('Setting Death Effect Requires Argument (Player) via name or path as a string type') return end
			if Player and typeof(Player) == 'string' then
				Player = returnplayerfromstring(Player)
			end
			if not Player or typeof(Player) ~= 'Instance' or not Player:IsA('Player') then Text_ALT('User>>SET_KILL_EFFECT_TO_DATE Requires Valid Player Username Or Argument') return end
			if LastRequestor ~= Player and (table.find(Admin, Player.UserId) or not table.find(Admin,LastRequestor.UserId)) then  Text_ALT('[[Command is unable to be applied to higher or same rank]]') return end
			local targetchar
			if Player.Character then
				targetchar = Player.Character
			else
				Text_ALT('Player Character Not Found, Please Try Adding True As The Forth Argument If You Want To Autoset When Available(Everytime Character spawn, Revoke Autoset when leave)')
				return
			end
			if not tonumber(Month) or tonumber(Month) == '' then Month = date.month end
			if not tonumber(Day) or tonumber(Day) == '' then Day = date.day end
			if Autoset and typeof(Autoset) == 'string' and Autoset:upper() == 'TRUE' then
				Player:SetAttribute('Autoset', true)
			elseif Autoset and typeof(Autoset) == 'string' and Autoset:upper() == 'FALSE' then
				Player:SetAttribute('Autoset', nil)
			end
			Player:SetAttribute('month', Month)
			Player:SetAttribute('day', Day)
		end,
		['SET_ANIMATION_RATELIMIT'] = function(number)
			if not number or not tonumber(number) then Text_ALT('Command Requires Number') return end
			if not table.find(Admin, LastRequestor.UserId) then Text_ALT("[[Command Is Exclusive]]") return end
			if game:FindFirstChildOfClass('ServerScriptService') and game:FindFirstChildOfClass('ServerScriptService'):FindFirstChild('Heavily_Calculized_Handler') and game:FindFirstChildOfClass('ServerScriptService'):FindFirstChild('Heavily_Calculized_Handler'):FindFirstChild('Animation_Handler') then
				game:FindFirstChildOfClass('ServerScriptService'):FindFirstChild('Heavily_Calculized_Handler'):FindFirstChild('Animation_Handler'):SetAttribute('RATELIMIT', tonumber(number))
			end
		end,
	},
	["SERVER"] = {
		["ONETIME_REGISTER_PRIVATE_GC"] = function()
			if not table.find(Admin, LastRequestor.UserId) then Text_ALT("[[Command Is Exclusive]]") return end
			local comd = pcall(function() game:GetService('ServerScriptService'):FindFirstChild('__Chat').Install:Fire() end)
			if comd then	Text('A MEMBER-LOCKED GC HAS BEEN INSTALLED FOR THIS PRIVATE SERVER! YOU WILL HAVE ACCESS TO THIS CHAT AS LONG AS THE SERVER IS UP.') EventTable["SERVER"]["ONETIME_REIGISTER_PRIVATE_GC"] = nil end
		end,
		["SHUTDOWN"] = function()
			if not table.find(Admin, LastRequestor.UserId) then Text_ALT("[[Command Is Exclusive]]") return end
			for i,v in game:FindFirstChildOfClass("Players"):GetChildren() do
				if v:IsA('Player') then
					v:Kick()
					if v then
						v:Destroy()
					end
				end
			end
			game:FindFirstChildOfClass("Players").DescendantAdded:Connect(function(descendant)
				if typeof(descendant) ~= 'Instance' or not descendant:IsA('Player') then return end
				descendant:Kick('This server has already been shutted down')
				if descendant then
					descendant:Destroy()
				end
			end)
		end,
		["LOCKDOWN"] = function(How_Long: number?)
			if not table.find(Admin, LastRequestor.UserId) then Text_ALT("[[Command Is Exclusive]]") return end
			if lockdown then Text_ALT('Server is already on lockdown') return end
			for i,v in ipairs(UIS) do
				if v then v:Destroy() end
			end
			UIS = {}
			local function CreateUI(Player: Player)
				if not lockdown or not Player or typeof(Player) ~= 'Instance' or not Player:IsA('Player') or not Player:FindFirstChildOfClass('PlayerGui') then return end
					local hintGui = Instance.new("ScreenGui", Player:FindFirstChildOfClass('PlayerGui'))
					hintGui.ResetOnSpawn = false
					hintGui.DisplayOrder = -1
					hintGui.Name = "HintGui"
					hintGui.IgnoreGuiInset = true

					local hintLabel = Instance.new("TextLabel")
					hintLabel.Size = UDim2.new(1, 0, 0, 25)
					hintLabel.Position = UDim2.new(0, 0, 0, 0)
					hintLabel.BackgroundColor3 = Color3.new(0, 0, 0)
					hintLabel.BackgroundTransparency = 0.5
					hintLabel.TextColor3 = Color3.new(1, 1, 1)
					hintLabel.Text = "This Server Has Been Locked"..((How_Long and How_Long ~= math.huge) and ' For '..tostring(How_Long)..' second(s)' or '')
					hintLabel.Font = Enum.Font.SourceSans
					hintLabel.TextSize = 24
					hintLabel.Parent = hintGui
					table.insert(UIS, hintGui)
			end
			local success = false --[[or pcall(function()
				local Hint = Instance.new("Hint", workspace)
				Hint.Name = "TEMP_LOCK_ONLY_FUNC"
				Hint.Text = "This Server Has Been Locked"
				if lockdown then
					lockdown:Disconnect()
				end
				Hint.Destroying:Once(function()
					if lockdown then
						lockdown:Disconnect()
					end
				end)
				if How_Long and How_Long ~= math.huge then
					game:FindFirstChildOfClass('Debris'):AddItem(Hint, How_Long)
				end
			end)]] -- if not, object had been removed from api
			Text('<<SERVER HAS BEEN LOCKED DOWN BY '..(LastRequestor and LastRequestor.Name or 'AN ADMIN')..">>")
			local thislockdown = game:FindFirstChildOfClass("Players").PlayerAdded:Connect(function(plr)
				if plr.UserId == game.PrivateServerOwnerId then CreateUI(plr) return end
				plr:Kick("The Server Is Currently In Lockdown")
				task.wait()
				if plr then
					plr:Destroy()
					task.wait()
					if plr then
						plr:Destroy()
					end
				end
			end)
			if lockdown then	lockdown:Disconnect() end
			lockdown = thislockdown
			if not success and plrserv then
				if How_Long and typeof(How_Long)  == 'number' then
					if lockdowntask then task.cancel(lockdowntask) end
					lockdowntask = task.spawn(function()
						task.wait(How_Long)
						if thislockdown and lockdown == thislockdown then
							thislockdown:Disconnect()
							if lockdown then	lockdown:Disconnect() end
							lockdown = nil
						end
						lockdowntask = nil
					end)
				end
				for i, v in plrserv:GetChildren() do
					if v:IsA('Player') then	CreateUI(v) end
				end
			end
		end,
		["WHITELIST"] = function(Table: {}, MergeTable: boolean?)
			if not table.find(Admin, LastRequestor.UserId) then Text_ALT("[[Command Is Exclusive]]") return end
			--players cant type table in chat
			if Table and typeof(Table) == 'string' then
				Table = ReturnPlayerTableFromString(Table) or returnplayerfromstring(Table)
				if Table and typeof(Table) == 'Instance' and Table:IsA('Player') then
					Table = {Table}
				end
			end
			if MergeTable == nil then
				if not blacklist then
					MergeTable = true
				else
					MergeTable = false
				end
			else
				MergeTable = returnbooleanfromstring(MergeTable)
			end
			if blacklist then
				blacklist:Disconnect()
				blacklist = nil
			end
			if whitelist then
				whitelist:Disconnect()
				whitelist = nil
			end
			local Whilelist_ = TempTable["Whitelist"]
			if not Whilelist_ then
				TempTable["Whitelist"] = {}
				Whilelist_ = TempTable["Whitelist"]
			end
			if not MergeTable then
				Whilelist_ = Table
			else
				for i,v in pairs(Table) do
					if not table.find(Whilelist_, v.UserId) then
						table.insert(Whilelist_, v.UserId)
					end
				end
			end
			for i,v in Admin do
				if not table.find(Whilelist_, v) then
					table.insert(Whilelist_, v)
				end
			end
			whitelist = game:FindFirstChildOfClass("Players").PlayerAdded:Connect(function(Player)
				if whitelist ~= nil and not table.find(Whilelist_, Player.UserId) and not table.find(Admin, Player.UserId) and not Whilelist_[Player.Name] and not Whilelist_[Player.UserId] then
					Player:Kick("Sorry , It Seems The Whitelist Didn't Contain Your Name")
					task.wait()
					if Player then
						Player:Destroy()
						task.wait()
						if Player then
							Player:Destroy()
						end
					end
				end
			end)
			cacheinstances()
		end,
		["BLACKLIST"] = function(Table: {}, MergeTable: boolean?)
			if not table.find(Admin, LastRequestor.UserId) then Text_ALT("[[Command Is Exclusive]]") return end
			--players cant type table in chat
			if Table and typeof(Table) == 'string' then
				Table = ReturnPlayerTableFromString(Table) or returnplayerfromstring(Table)
				if Table and typeof(Table) == 'Instance' and Table:IsA('Player') then
					Table = {Table}
				end
			end
			if MergeTable == nil then
				if blacklist then
					MergeTable = true
				else
					MergeTable = false
				end
			else
				MergeTable = returnbooleanfromstring(MergeTable)
			end
			if blacklist then
				blacklist:Disconnect()
				blacklist = nil
			end
			if whitelist then
				whitelist:Disconnect()
				whitelist = nil
			end
			local Blacklist_ = TempTable["Blacklist"]
			if not Blacklist_ then
				TempTable["Blacklist"] = {}
				Blacklist_ = TempTable["Blacklist"]
			end
			if not MergeTable then
				Blacklist_ = Table
			else
				for i,v in pairs(Table) do
					if not table.find(Blacklist_, v.UserId) and not table.find(Admin, v.UserId) then
						table.insert(Blacklist_, v.UserId)
					end
				end
			end
			blacklist = game:FindFirstChildOfClass("Players").PlayerAdded:Connect(function(Player)
				if blacklist ~= nil and not table.find(Admin, Player.UserId) and (Blacklist_[Player.Name] or Blacklist_[Player] or table.find(Blacklist_, Player.UserId) or Blacklist_[Player.UserId]) then
					Player:Kick("You Are Blacklisted From The Server")
					task.wait()
					if Player then
						Player:Destroy()
						task.wait()
						if Player then
							Player:Destroy()
						end
					end
				end
			end)
			cacheinstances()
		end,
		["REMOVE_CLIENT_SERVER_COMMUNICATION"] = function()
			if not table.find(Admin, LastRequestor.UserId) then Text_ALT("[[Command Is Exclusive]]") return end
			if ReplicatedStorage and ReplicatedStorage:FindFirstChild('???') and ReplicatedStorage:FindFirstChild('???'):FindFirstChild('BridgeNet') then
				ReplicatedStorage:FindFirstChild('???'):FindFirstChild('BridgeNet'):Destroy()
			end
		end,
		["UNLOCK"] = function()
			if not table.find(Admin, LastRequestor.UserId) then Text_ALT("[[Command Is Exclusive]]") return end
			if not lockdown then
				Text_ALT("Invalid Unlock[Server Has Not Been Locked]")
			end
			if lockdown ~= nil then
				Text('<<SERVER HAS BEEN UNLOCKED BY '..(LastRequestor and LastRequestor.Name or 'AN ADMIN')..'>>')
				lockdown:Disconnect()
				lockdown = nil
			end
			for i,v in ipairs(UIS) do
				if v then v:Destroy() end
			end
			UIS = {}
			if workspace:FindFirstChild("TEMP_LOCK_ONLY_FUNC") then
				workspace:FindFirstChild("TEMP_LOCK_ONLY_FUNC"):Destroy()
			end
		end,
		["SETMAXPLAYER"] = function(Amount)
			if not table.find(Admin, LastRequestor.UserId) then Text_ALT("[[Command Is Exclusive]]") return end
			if not Amount then Amount = #plrserv:GetChildren() else Amount = tonumber(Amount) end
			if Amount == '' or (typeof(Amount) ~= 'number' and typeof(Amount) ~= 'string') then
				Text_ALT('Please Specify Amount As A Number')
			end
			MaxPlayer = Amount
			script:SetAttribute('MaxPlayer', Amount)
			if Amount < #plrserv:GetChildren() then
			if blacklist then
				for i,v in pairs(TempTable['Blacklist']) do
						if typeof(v) == 'number' and plrserv:GetPlayerByUserId(v) then	plrserv:GetPlayerByUserId(v):Kick('Server Has Exceeded Player Limit') if Amount >= #plrserv:GetChildren() then
								break
							end end 		
				end
			elseif whitelist then
					for i,v in plrserv:GetChildren() do
						if v:IsA('Player') and not table.find(TempTable['Whitelist'], v.UserId) then
							v:Kick('Server Has Exceeded Player Limit')
							if Amount >= #plrserv:GetChildren() then
								break
							end
						end
					end
			else
					for i,v in plrserv:GetChildren() do
						if v:IsA('Player') then
							v:Kick('Server Has Exceeded Player Limit')
						end
						if Amount >= #plrserv:GetChildren() then
							break
						end
					end
				end end
			if Amount < #plrserv:GetChildren()  then
				for i,v in plrserv:GetChildren() do
					if v:IsA('Player') then
						v:Kick('Server Has Exceeded Player Limit')
					end
					if Amount >= #plrserv:GetChildren() then
						break
					end
				end
			end
		end,
		['SETGRAVITY'] = function(Amount)
			if not table.find(Admin, LastRequestor.UserId) then Text_ALT("[[Command Is Exclusive]]") return end
			if not Amount or not tonumber(Amount) or tonumber(Amount) == '' then Text_ALT('SETGRAVITY requires Number') return end
			workspace.Gravity = tonumber(Amount)
		end,
		['SETFUNVALUE'] = function(Amount)
			if not table.find(Admin, LastRequestor.UserId) then Text_ALT("[[Command Is Exclusive]]") return end
			if not Amount or not tonumber(Amount) or tonumber(Amount) == '' then Text_ALT('SETFUNVALUE requires Number') return end
			workspace.Fun.Value = tonumber(Amount)
		end,
		['SETTIME'] = function(Amount)
			if not table.find(Admin, LastRequestor.UserId) then Text_ALT("[[Command Is Exclusive]]") return end
			if not Amount or not tonumber(Amount) or tonumber(Amount) == '' then Text_ALT('SETTIME requires Number') return end
			game:FindFirstChildOfClass('Lighting').ClockTime = math.clamp(tonumber(Amount), 0, 24)
		end,
		["ENABLE_BRICKVFX"] = function(Boolean)
			if not table.find(Admin, LastRequestor.UserId) then Text_ALT("[[Command Is Exclusive]]") return end
			if not Boolean or typeof(Boolean) ~= 'string' or (not Boolean:upper():sub(1, 5):match('TRUE') and not Boolean:upper():sub(1, 6):match('FALSE')) then Text_ALT('[[Setting Toggled Off Due To Invalid Input]]') workspace:SetAttribute('BrickVFX_ON', nil)
			else
			if Boolean:upper():sub(1, 5):match('TRUE') then
					workspace:SetAttribute('BrickVFX_ON', true)
				else
					workspace:SetAttribute('BrickVFX_ON', false)
				end end
			Text('Brick Effect Setting: '..tostring(workspace:GetAttribute('BrickVFX_ON')) or 'false')
		end,
		["ENABLE_BOAT_SPAWN"] = function(Boolean)
			if not table.find(Admin, LastRequestor.UserId) then Text_ALT("[[Command Is Exclusive]]") return end
			if not Boolean or typeof(Boolean) ~= 'string' or (not Boolean:upper():sub(1, 5):match('TRUE') and not Boolean:upper():sub(1, 6):match('FALSE')) then Text_ALT('[[Setting Toggled Off Due To Invalid Input]]') workspace:SetAttribute('ENABLE_BOAT_SPAWN', nil)
			else
				if Boolean:upper():sub(1, 5):match('TRUE') then
					workspace:SetAttribute('ENABLE_BOAT_SPAWN', true)
				else
					workspace:SetAttribute('ENABLE_BOAT_SPAWN', false)
				end end
			Text('Boat Spawning Setting: '..tostring(workspace:GetAttribute('BrickVFX_ON')) or 'false')
		end,
		["ENABLE_PVP"] = function(Boolean)
			if not table.find(Admin, LastRequestor.UserId) then Text_ALT("[[Command Is Exclusive]]") return end
			if not Boolean or typeof(Boolean) ~= 'string' or (not Boolean:upper():sub(1, 5):match('TRUE') and not Boolean:upper():sub(1, 6):match('FALSE')) then Text_ALT('[[Setting Toggled Off Due To Invalid Input]]') workspace:SetAttribute('PVP_ON', nil)
			else
				if Boolean:upper():sub(1, 5):match('TRUE') then
					workspace:SetAttribute('PVP_ON', true)
				else
					workspace:SetAttribute('PVP_ON', false)
				end
			end
			Text('PVP Setting: '..tostring(workspace:GetAttribute('PVP_ON')) or 'false')
		end,
		["ENABLE_DESTRUCTION"] = function(Boolean)
			if not table.find(Admin, LastRequestor.UserId) then Text_ALT("[[Command Is Exclusive]]") return end
			if not Boolean or typeof(Boolean) ~= 'string' or (not Boolean:upper():sub(1, 5):match('TRUE') and not Boolean:upper():sub(1, 6):match('FALSE')) then Text_ALT('[[Setting Toggled Off Due To Invalid Input]]') workspace:SetAttribute('Breakable', nil)
			else
				if Boolean:upper():sub(1, 5):match('TRUE') then
					workspace:SetAttribute('Breakable', true)
				else
					workspace:SetAttribute('Breakable', false)
				end
			end
			Text('PVP Setting: '..tostring(workspace:GetAttribute('Breakable')) or 'false')
		end,
		["ENABLE_ACCESSORY_SCRIPT"] = function(Boolean)
			if not table.find(Admin, LastRequestor.UserId) then Text_ALT("[[Command Is Exclusive]]") return end
			if not Boolean or typeof(Boolean) ~= 'string' or (not Boolean:upper():sub(1, 5):match('TRUE') and not Boolean:upper():sub(1, 6):match('FALSE')) then Text_ALT('[[Setting Toggled Off Due To Invalid Input]]') workspace:SetAttribute('ENABLE_SCRIPT', nil)
			else
				if Boolean:upper():sub(1, 5):match('TRUE') then
					workspace:SetAttribute('ENABLE_SCRIPT', true)
				else
					workspace:SetAttribute('ENABLE_SCRIPT', false)
				end  end
			Text('Accessory Script Setting: '..tostring(workspace:GetAttribute('ENABLE_SCRIPT')) or 'false')
		end,
		["ENABLE_ACCESSORY_SOUND"] = function(Boolean)
			if not table.find(Admin, LastRequestor.UserId) then Text_ALT("[[Command Is Exclusive]]") return end
			if not Boolean or typeof(Boolean) ~= 'string' or (not Boolean:upper():sub(1, 5):match('TRUE') and not Boolean:upper():sub(1, 6):match('FALSE')) then Text_ALT('[[Setting Toggled Off Due To Invalid Input]]') workspace:SetAttribute('ENABLE_SOUND', nil)
			else
				if Boolean:upper():sub(1, 5):match('TRUE') then
					workspace:SetAttribute('ENABLE_SOUND', true)
				else
					workspace:SetAttribute('ENABLE_SOUND', false)
				end end
			Text('Accessory Sound Setting: '..tostring(workspace:GetAttribute('ENABLE_SOUND')) or 'false')
		end,
		["ENABLE_ACCESSORY_UNLOCK_PARTICLE"] = function(Boolean)
			if not table.find(Admin, LastRequestor.UserId) then Text_ALT("[[Command Is Exclusive]]") return end
			if not Boolean or typeof(Boolean) ~= 'string' or (not Boolean:upper():sub(1, 5):match('TRUE') and not Boolean:upper():sub(1, 6):match('FALSE')) then Text_ALT('[[Setting Toggled Off Due To Invalid Input]]') workspace:SetAttribute('UNLOCK_PARTICLE', nil)
			else
				if Boolean:upper():sub(1, 5):match('TRUE') then
					workspace:SetAttribute('UNLOCK_PARTICLE', true)
				else
					workspace:SetAttribute('UNLOCK_PARTICLE', false)
				end end
			Text('Accessory Particle Unlocking Setting: '..tostring(workspace:GetAttribute('UNLOCK_PARTICLE')) or 'false')
		end,
	},
	["UNSORTED"] = {
		["CHANGE_CHARACTER"] = 
			function(Who: any,CharacterName:string)
				if Who and typeof(Who) == 'string' then
					Who = returnplayerfromstring(Who, true)
				end
				if typeof(Who) == "string" then
					if game:FindFirstChildOfClass("Players"):FindFirstChild(Who) then
						Who = game:FindFirstChildOfClass("Players"):FindFirstChild(Who)
					else
						return
					end
				elseif typeof(Who) == "Instance" then
					
				else
					Text_ALT("Invalid Type For Command(Player|String , String)")
					return
				end
				if not Who then
					Who = LastRequestor
				end
				local Player = Who
				if LastRequestor ~= Player and (table.find(Admin, Player.UserId) or not table.find(Admin,LastRequestor.UserId)) then  Text_ALT('[[Command is unable to be applied to higher or same rank]]') return end
				if DataTable["CharDetail"] and (DataTable["CharDetail"][CharacterName] or table.find(DataTable["CharDetail"],CharacterName)) then
					local Character:Model = CharData.Create(CharacterName)
					repeat task.wait() until Character and Character:IsA("Model") -- Wait
					Text_ALT('Received Character As An '..typeof(Character).. " or Model: ".. tostring(Character:IsA("Model")) )
					if Character:IsA("Model") then
					if Character and Character:FindFirstChildOfClass('Humanoid') and Character:FindFirstChildOfClass('Humanoid').SeatPart ~= nil then
							Character:FindFirstChildOfClass('Humanoid').Jump = true
						end
						if Who.Character ~= nil--[[ and Who:FindFirstChild("HumanoidRootPart")]] then
							Character:PivotTo(Who.Character:GetPivot())
							--Character:FindFirstChild("HumanoidRootPart").CFrame = Who.Character:FindFirstChild("HumanoidRootPart").CFrame
						else
						if workspace:FindFirstChildOfClass("SpawnLocation") then							
								Character:PivotTo(workspace:FindFirstChildOfClass("SpawnLocation").CFrame)
							end
						end
						task.wait()
						Who.Character = Character
					end
				end
			end,
		["SUMMON_RAGDOLL"] = 
			function(CharacterName:string, Where)
				if Where and typeof(Where) == 'string' then
				if getInstanceFromPath(Where) then
					Where = getInstanceFromPath(Where)
				end
			end
				if type(Where) == "string" then
					if game:FindFirstChildOfClass("Players"):FindFirstChild(Where) and game:FindFirstChildOfClass("Players"):FindFirstChild(Where).Character  then
						Where = game:FindFirstChildOfClass("Players"):FindFirstChild(Where).Character:GetPivot()
					end
				end
				if not Where then
					if workspace:FindFirstChildOfClass("SpawnLocation") then
						Where = workspace:FindFirstChildOfClass("SpawnLocation").CFrame
					end
				end
				
				if not Where then
					Where = CFrame.new(0,0,0)
				end
				--if typeof(Where) == "CFrame" then
				if DataTable["CharDetail"] and (DataTable["CharDetail"][CharacterName] or table.find(DataTable["CharDetail"],CharacterName)) then
				local Character:Model = CharData.Create(CharacterName)
				repeat task.wait() until Character and Character:IsA("Model") and Character:FindFirstChildOfClass("Humanoid") -- Wait
				Text_ALT('Received Character As An '..typeof(Character).. " or Model: ".. tostring(Character:IsA("Model")) )
				if Character and Character:FindFirstChildOfClass('Humanoid') and Character:FindFirstChildOfClass('Humanoid').SeatPart ~= nil then
						Character:FindFirstChildOfClass('Humanoid').Jump = true
					end
					Character:PivotTo(Where)
					Character:SetAttribute("Disconnect_Execution",true)
					if Character:FindFirstChildOfClass("Humanoid") then -- Guranteed Not nil.
						local WhosHumanoid: Humanoid? = Character:FindFirstChildOfClass("Humanoid")
						WhosHumanoid.DisplayName = "Ragdoll"
						WhosHumanoid.PlatformStand = true
						WhosHumanoid:ChangeState(Enum.HumanoidStateType.Physics)
						WhosHumanoid:UnequipTools()
						WhosHumanoid.MaxHealth = math.huge
						WhosHumanoid.Health = math.huge
						WhosHumanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
						WhosHumanoid.HealthDisplayDistance = 0
						WhosHumanoid.NameOcclusion = Enum.NameOcclusion.EnemyOcclusion
						WhosHumanoid.NameDisplayDistance = 25
						WhosHumanoid.HipHeight = 0			
						WhosHumanoid.RequiresNeck = false
						WhosHumanoid:ChangeState(Enum.HumanoidStateType.Ragdoll)
						WhosHumanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
						WhosHumanoid:SetStateEnabled(Enum.HumanoidStateType.Running, false)
						WhosHumanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
						WhosHumanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
						WhosHumanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
						WhosHumanoid:SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics, false)
						WhosHumanoid:SetStateEnabled(Enum.HumanoidStateType.Flying, false)	
						WhosHumanoid:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding, false)	
						WhosHumanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
						WhosHumanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming, false)
						WhosHumanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
						WhosHumanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)	
						coroutine.resume(coroutine.create(function()
							for i,v in pairs(Character:GetDescendants()) do
							if not v:IsA("Weld") and v:IsA("JointInstance") and not v:GetAttribute("RagdollJoint") and v.Name ~= "RootJoint" then
									local altsocket = Instance.new("NoCollisionConstraint",v.Parent)
									altsocket.Part0 = v.Part0
									altsocket.Part1 = v.Part1
									local socket = Instance.new("RopeConstraint",v.Parent)
									socket:SetAttribute("RagdollJoint",true)
									socket.Thickness = 0.1
									socket.Length = 0.5
									local a1 = Instance.new("Attachment")
									local a2 = Instance.new("Attachment")
									a1.Visible = false
									a2.Visible = false
									a1.Parent = v.Part0
									a2.Parent = v.Part1
									socket.Restitution= 0
									socket.Attachment0 = a1
									socket.Attachment1 = a2
									socket.WinchResponsiveness = 1
									socket.WinchForce = 5
									socket.WinchSpeed = 1
									socket.WinchEnabled = false
									a1.CFrame = v.C0
									a2.CFrame = v.C1
									socket.Visible = false
									--socket.LimitsEnabled = true
									--socket.WinchResponsiveness = 1
									socket.Color = BrickColor.Black()
									socket.Name = '"'..v.Name..'"'
									v:Destroy()
								elseif v:IsA("BasePart") then
									--if not table.find(v:GetConnectedParts(true),Character:FindFirstChild("Head") then
										v.CanCollide = true
										v:SetNetworkOwner(nil)
										v.CanTouch = true
										if v:IsA("UnionOperation") then
											v.UsePartColor = true
										end		
									--end
								end
							end
						end))
					end
				end
				--end
			end,
		["GIVE"] = 
			function(Item_Name:string, Where)
				if Where and typeof(Where) == 'string' then
				if getInstanceFromPath(Where) then
					Where = getInstanceFromPath(Where)
				end
			end
				local giveall = false
				if not table.find(Admin, LastRequestor.UserId) then Text_ALT('[[Command Is Exclusive]]') return end
				if Where and typeof(Where) == 'string' then
					if plrserv:FindFirstChild(Where) then
						Where = plrserv:FindFirstChild(Where).Backpack
					else
						if workspace:FindFirstChild(Where) then
							Where = workspace:FindFirstChild(Where)
						end
					end
				end
				if Item_Name:upper() == 'ALL' then
					giveall = true
				end
				local item
				if not giveall then
					if Item_Name == tostring(tonumber(Item_Name)) then
						item = game:FindFirstChildOfClass("ServerStorage"):FindFirstChild("Current Version"):GetChildren()[tonumber(Item_Name)]
					else
						item = game:FindFirstChildOfClass("ServerStorage") and game:FindFirstChildOfClass("ServerStorage"):FindFirstChild("Current Version") and game:FindFirstChildOfClass("ServerStorage"):FindFirstChild("Current Version"):FindFirstChild(Item_Name)
					end
				end
				local lox = (typeof(Where) == 'Instance' and Where) or (LastRequestor and LastRequestor:FindFirstChildWhichIsA('Backpack')) or workspace
				if lox then
				if not giveall and item then
					item:Clone().Parent = lox
				else
					for i,v in game:FindFirstChildOfClass("ServerStorage"):FindFirstChild("Current Version"):GetChildren() do
						if v.Name:upper():match(Item_Name:upper()) or giveall then
							v:Clone().Parent = lox
						end
					end
				end else Text_ALT('invalid item destination') end
			end,
		["SETATTRIBUTE"] =
			function(Where, Name, Value)
				if not table.find(Admin, LastRequestor.UserId) then Text_ALT("[[Command Is Exclusive]]") return end
				pcall(function()
				if not getInstanceFromPath(Where) then
					Text_ALT('SETATTRIBUTE requires path to instance from game object')
				end
				Where = getInstanceFromPath(Where)
				if Where:FindFirstAncestorWhichIsA('ServerScriptService') or Where:FindFirstAncestorWhichIsA('ServerStorage') or Where:FindFirstAncestorWhichIsA('ReplicatedFirst') or Where:FindFirstAncestorWhichIsA('ReplicatedStorage') then Text_ALT("[[Instance Is Protected]]") return end
				if tonumber(Value) and Value == tostring(tonumber(Value)) then
					Value = tonumber(Value)
				end
				if Where and typeof(Where) == 'Instance' then
					Where:SetAttribute(Name or 'Untitled', Value or nil)
				end end)
			end,
	}
}

function flattenTable(inputTable)
	local resultTable = {}

	for key, value in pairs(inputTable) do
		if type(value) == "table" then
			resultTable[key] = {}
			for innerKey, innerValue in pairs(value) do
				table.insert(resultTable[key], innerKey)
			end
		end
	end

	return resultTable
end
function removeEndingS(inputString: string)
	if typeof(inputString) ~= 'string' then return '' end
	if inputString:sub(-1) == 'S' then return string.sub(inputString, 1, -2) end
	return inputString
end
DataTable["CharDetail"] = flattenTable(CharData.RequestData())["Char"]
DataTable["CommandDetail"] = flattenTable(EventTable)
--game:FindFirstChildOfClass("LogService"):ClearOutput()
execute = function(LastRequestor: Player ,WhichCategory: string, EventName: string?, ...)
	task.desynchronize()
	if not game.PrivateServerOwnerId and not Admin[LastRequestor.UserId] and not ingameadmin[LastRequestor.UserId] then return end
	-- Manual Instruction.
	if not WhichCategory then Text_ALT('NO CATEGORY PROVIDED') return end
	if WhichCategory:upper() == 'CMD' or WhichCategory:upper() == 'LIST_CMD' or WhichCategory:upper() == 'LIST_CMDS' or WhichCategory:upper() == 'CMDS' or WhichCategory:upper():match("SHOW_LIST") or WhichCategory:upper():match("SHOW_ALL") or WhichCategory:upper():match("CATEGORY") or WhichCategory:upper():match("CMDS") or WhichCategory:upper():match("ALL") or WhichCategory:upper():match("SHOW_CMD") or WhichCategory:upper():match("HELP") or WhichCategory:upper():match("LIST_COMMAND") or WhichCategory:upper():match("PROVIDE_CMD") or WhichCategory:upper():match("GET_CMD") or WhichCategory:upper():match("CHECK_CMD") or WhichCategory:upper():match("REQUEST_CMD") or WhichCategory:upper():match("REQ_CMD")--[[ or WhichCategory:upper():match("??")]] then
		Text_ALT('<<MISC COMMANDS>>')
		Text_ALT('{?HELP, ?COMMAND_EXPLAINATION}')
		Text_ALT('((TO USE THE COMMANDS BELOW, PLEASE START THE MESSAGE WITH ?, Write the message in format ? + (Category or Category_Number) + (Specific_Command or Command_Number) + ...[required or optional variables] , And replace spaces in speciific variable with .$. [variable such as item names and such]))')
		Text_ALT('<<HELPER COMMANDS>>')
		Text_ALT('{LIST, CHECK} + _ + {CMD, CHAR, ITEM}')
		Text_ALT(">>Events<<")
		for key: string, value: {} in pairs(DataTable["CommandDetail"]) do
			Text_ALT(key..":", unpack(value)) -- Use unpack to print the values
		end
		return
	end
	if WhichCategory:upper() == 'COMMAND_EXPLAINATION' then
		Text_ALT([[
####Command Table Structure
	####Command is a table that holds different categories of commands:
		>BUILDING: Commands related to managing items in the shop.
		>USER: Commands related to user management, such as VIP status and teleportation.
		>SERVER: Commands related to server management, such as shutdown and lockdown.
>>>BUILDING Commands
	>ADD_ITEM_TO_SHOP(ItemName or 'All', Amount)
		This function adds a specified item to the shop.
		Checks if the user is an admin.
		Verifies the existence of required objects in ServerStorage.
		Validates the Item_Name and Amount parameters.
		If Amount is 'Random', it generates a random number.
		If Item_Name is 'ALL', it sets a flag to add all items.
		Finds the specified item in ServerStorage.
		Clones the item and adds it to the shop the specified number of times.
	>REMOVE_ITEM_FROM_SHOP(ItemName or 'All', Amount or 'All')
		This function removes a specified item from the shop.
		Checks if the user is an admin.
		Verifies the existence of required objects in ServerStorage.
		If Item_Name is 'ALL', it clears all items from the shop.
		Validates the Amount parameter.
		Removes the specified item from the shop the specified number of times.
>>>USER Commands
	>REMOVE_VIP_OFFLINE(UserID: number)
		This function removes VIP status from a user who is not currently in the game.
		Checks if the user is an admin.
		Validates the ID parameter.
		Removes the user from the VIP list and disconnects any temporary chat connections.
	>ADMIN/UNADMIN(Player)
	>VIP(Player, ?confirmheadadmin1(expect true/nil), ?confirmheadadmin2(expect true/nil))
		This function grants VIP status to a specified player.
		Checks if the user is an admin.
		Validates the Player parameter.
		Adds the player to the VIP list and sets up a chat connection.
		{if you are an owner and used true on two more arguments, 
		user will rank into admin.(or what I expected my code to do) 
		!!! USE WISELY !!!
		***YOU CANNOT UNRANK THEM LATER***
		(IT WILL ONLY REMOVE THE RANK WHEN THE TARGET PLAYER LEFT!)
		}
	>UNVIP(Player)
		This function removes VIP status from a specified player.
		Checks if the user is an admin.
		Validates the Player parameter.
		!!CANT UNRANK ADMINS!!
		Removes the player from the VIP list and disconnects any temporary chat connections.
	>CRASH(Player)
		This function crashes a specified player's game.
		Checks if the user is an admin.
		Validates the Player parameter.
		Kicks and destroys the player's instance.
	>RESET(Player)
		This function resets a specified player's character.
		Validates the Player parameter.
		Resets the player's character if they are not a higher-ranked admin.
	>TP(Plr1, Plr2(empty if u)); Plr1 Destination Plr 2 Teleporter
		This function teleports one player to another.
		Validates the Player1 and Player2 parameters.
		Teleports Player1 to Player2's location.
	>BRING(Player)
		This function brings a specified player to the command issuer's location.
		Validates the Player parameter.
		Teleports the player to the command issuer's location.
	>SET_KILL_EFFECT_TO_DATE(Player, month: number, day:number, Autoset:boolean)
		This function sets a kill effect for a player based on a specified date.
		Validates the Player, Month, and Day parameters.
		Sets the player's attributes for the kill effect.
>>>SERVER Commands[EXCLUSIVE]
	>SHUTDOWN()
		This function shuts down the server.
		Checks if the user is an admin.
		Kicks all players and prevents new players from joining.
	>LOCKDOWN(Duration or Infinity)
		This function locks down the server for a specified duration.
		Checks if the user is an admin.
		Displays a hint message and kicks new players trying to join.
	>WHITELIST(Player or {Players})
		This function manages the server's whitelist.
		Checks if the user is an admin.
		Validates and merges the whitelist table.
		Kicks players not in the whitelist.
	>BLACKLIST(Player or {Players})
		This function manages the server's blacklist.
		Checks if the user is an admin.
		Validates and merges the blacklist table.
		Kicks players in the blacklist.
	>UNLOCK()
		This function unlocks the server.
		Checks if the user is an admin.
		Removes the lockdown and hint message.
	>SETMAXPLAYER(Number)
		This function sets the maximum number of players allowed in the server.
		Checks if the user is an admin.
		Validates the Amount parameter.
		Kicks players if the current number exceeds the new limit.
	>SETGRAVITY(Number)
		This function sets the gravity in the game.
		Checks if the user is an admin.
		Validates the Amount parameter.
		Sets the gravity in the workspace.
	>SETFUNVALUE(Number)
		This function sets a fun value in the game.
		Checks if the user is an admin.
		Validates the Amount parameter.
		Sets the fun value in the workspace.
	>SETTIME(Number)
		This function sets the time in the game.
		Checks if the user is an admin.
		Validates the Amount parameter.
		Sets the clock time in the lighting.
>>>UNSORTED Commands
	>CHANGE_CHARACTER; function(Who{Player or character name(either yourself or lower rank)},CharacterName:string)
		This function changes a player's character to a specified model.
		Validates the Who and CharacterName parameters.
		Changes the player's character to the specified model.
	>SUMMON_RAGDOLL; function(CharacterName:string, Where)
		This function summons a ragdoll character at a specified location.
		Validates the CharacterName and Where parameters.
		Summons the ragdoll character at the specified location.
	>GIVE; function(Item_Name:string, Where); [EXCLUSIVE]
		This function gives an item to a specified location or player.
		Checks if the user is an admin.
		Validates the Item_Name and Where parameters.
		Clones the item and gives it to the specified location or player.
	>SETATTRIBUTE; function(InstancePath, Name, Value); [EXCLUSIVE]
		This function sets an attribute for a specified instance.
		Checks if the user is an admin.
		Validates the Where, Name, and Value parameters.
		Sets the attribute for the specified instance.]])
	end
	if WhichCategory:upper():match("LIST_CHAR") or WhichCategory:upper():match("REQUEST_CHAR") or WhichCategory:upper():match("CHECK_CHAR") or WhichCategory:upper():match("PROVIDE_CHAR") or WhichCategory:upper():match("GET_CHAR")--[[ or WhichCategory:upper():match("??")]] then
		for key: string, value: {} in pairs(DataTable["CharDetail"]) do
			Text_ALT(key..":", value) -- Use unpack to print the values
		end
		return
	end
	if WhichCategory:upper():match("CHECK_ITEM") or WhichCategory:upper():match("REQUEST_ITEM") or WhichCategory:upper():match("LIST_ITEM") or WhichCategory:upper():match("PROVIDE_ITEM") or WhichCategory:upper():match("GET_ITEM")--[[ or WhichCategory:upper():match("??")]] then
		--game.LogService:ClearOutput()
		if game:FindFirstChildOfClass("ServerStorage") and game:FindFirstChildOfClass("ServerStorage"):FindFirstChild("Current Version") then
			Text_ALT("ITEM_LIST>>")
			for i, item in game:FindFirstChildOfClass("ServerStorage"):FindFirstChild("Current Version"):GetChildren() do
				if item:IsA("Tool") then
					Text_ALT(tostring(i)..":"..item.Name)
				end
			end
		end

		return
	end
	task.desynchronize()
	if type(WhichCategory) == 'string' then
		WhichCategory = WhichCategory:upper()
		if not EventTable[WhichCategory] then
			WhichCategory = removeEndingS(WhichCategory)
		end
	end
	if type(EventName) == 'string' then
		EventName = EventName:upper()
		if EventTable[WhichCategory] and not EventTable[WhichCategory][EventName] then
			EventName = removeEndingS(EventName)
		end
	end
	if tostring(tonumber(WhichCategory)) == WhichCategory then
		WhichCategory = findKey(DataTable["CommandDetail"], WhichCategory) or WhichCategory
		Text_ALT('Category From Shortcut:'.. tostring(WhichCategory))
	end
	task.desynchronize()
	if tostring(tonumber(EventName)) == EventName then
		EventName = (DataTable["CommandDetail"][WhichCategory] and findKey(DataTable["CommandDetail"][WhichCategory], EventName)) or EventName
		Text_ALT('Command From Shortcut:'.. tostring(EventName))
	end
	task.desynchronize()
	--print('execute')
	if type(EventName) == "string" and tostring(tonumber(EventName)) ~= EventName then
		--print('EventName id string')
		if EventTable[WhichCategory] or EventTable[string.upper(WhichCategory)] then
			--print('WhichCategory work string')
			local Categorized = EventTable[WhichCategory] or EventTable[string.upper(WhichCategory)]
			if Categorized[string.upper(EventName)] then
				--game.LogService:ClearOutput()
				--print('EventName work string') 
				task.synchronize()
				local varag = {...}
				pcall(function()
				if #varag > 0 then for i,v in varag do varag[i] = string.gsub(v, '.$.', ' ') end end 
				end) local RunSuccess, err = pcall(function() Categorized[string.upper(EventName)](unpack(varag)) end)
				Text_ALT(RunSuccess and "Command Successfully Ran!" or ("Command Errored: ".. err))
			else
				--game.LogService:ClearOutput()
				 Text_ALT(WhichCategory.."[Event] Does Not Exist.")
			end
		else
			--game.LogService:ClearOutput()
			Text_ALT(WhichCategory.."[Category] Does Not Exist.")
		end
	elseif typeof(EventName) == 'number' or tostring(tonumber(EventName)) == EventName then
		--print('execute b')
		local a = EventTable[tonumber(WhichCategory)] or EventTable[string.upper(WhichCategory)]
		if a then
			local Categorized = a[tonumber(EventName) or 1] or a[string.upper(EventName)]
			if Categorized then
				--game.LogService:ClearOutput()
				task.synchronize()
				local varag = {...}
				pcall(function()
					if #varag > 0 then for i,v in varag do varag[i] = string.gsub(v, '.$.', ' ') end end 
				end) local RunSuccess, err = pcall(function() Categorized(unpack(varag)) end)
				Text_ALT(RunSuccess and "Command Successfully Ran!" or ("Command Errored: ".. err))
			else
				--game.LogService:ClearOutput()
				Text_ALT(WhichCategory.."[Event Slot] Does Not Exist.")
			end
		else
			--game.LogService:ClearOutput()
			Text_ALT(WhichCategory.."[Category Slot] Does Not Exist.")
		end
	end
	allow = true
end

task.synchronize()
game:FindFirstChildOfClass("ServerScriptService"):FindFirstChild("Remote_Function").Event:Connect(execute)
function removeOldestData(threshold)
	local oldestEntry = next(joineddata)
	joineddata[oldestEntry] = nil
end

function checktablelength(tablehere) : number
	local length = 0
	for i,v in pairs(tablehere) do length += 1 end
	return length
end

function updatePlayerData(plr)
	if checktablelength(joineddata) > 100 and not joineddata[plr.Name] then
		removeOldestData(100)
	end
	if checktablelength(joineddata) > 110 then joineddata = {} end
	joineddata[plr.Name] = plr.UserId
end
if not  cachefolder:FindFirstChild('__falseadmin') then
	local new = Instance.new('Folder', cachefolder) new.Name = '__falseadmin'
end
local fadmnc = cachefolder:FindFirstChild('__falseadmin')
local RankREMOVE = {}
if fadmnc then
	pcall(function()
	for i,v in fadmnc:GetChildren() do
		if not v:IsA('NumberValue') then
			continue
		end
		local savedid = v.Value
		if RankREMOVE[v.Value] then continue end
		RankREMOVE[v.Value] = task.spawn(function()
			task.wait(60)
			if not plrserv then if table.find(ingameadmin, savedid) then table.remove(ingameadmin, table.find(ingameadmin, savedid)) end  RankREMOVE[savedid] = nil return end
			for i,v in plrserv:GetChildren() do
				if v:IsA('Player') and v.UserId == savedid then RankREMOVE[savedid] = nil return end
			end
			if table.find(ingameadmin, savedid) then table.remove(ingameadmin, table.find(ingameadmin, savedid)) end  RankREMOVE[savedid] = nil
		end)
	end end) pcall(function()
 fadmnc:ClearAllChildren() end) end
local register = function(plr)
		task.desynchronize()
		if #plrserv:GetChildren() > MaxPlayer then
			task.synchronize()
			plr:Kick('Server Has Exceeded The Player Limit')
			return
		end
		local debounce = false
	if RankREMOVE[plr.UserId] then task.cancel(RankREMOVE[plr.UserId]) RankREMOVE[plr.UserId] = nil
		local Player =  plr
		if Player and Player.Parent and not table.find(Admin, Player.UserId) and typeof(Player) == 'Instance' and Player:IsA('Player') then
			if  table.find(ingameadmin, Player.UserId) then
			if TempChatCon[Player] then TempChatCon[Player]:Disconnect() TempChatCon[Player] = nil end
			local Ch = Player:WaitForChild("ChatEvent", 60)
			if not Ch or Ch.ClassName ~= 'BindableEvent' then Text("Setting up VIP command for ".. Player.Name.. " WARNING: ChatEvent Not Found!") if Ch then task.synchronize() Ch:Destroy() end end
			local debounce = false local connect 
			local success= pcall(function()
				connect = ((Ch and Ch.Event) or Player.Chatted):Connect(function(a,b)
					if debounce then return end
					debounce = true
					task.delay(.1, function()
						debounce = false
					end)
					chatcon(Player,a,b)
				end) end)
				if not success or not connect then Text_ALT('Error Had Occured: Please Try Again!') else
				Text(Player.Name..' has been re-ranked')
				TempChatCon[Player] = connect end
			end 
		end
	end
		updatePlayerData(plr)
		task.synchronize()
	if game:FindFirstChildOfClass('RunService'):IsStudio() or table.find(ingameadmin, plr.UserId) or table.find(Admin, plr.UserId) or plr.UserId == game.PrivateServerOwnerId or (game.PrivateServerId ~= 0 and game.PrivateServerOwnerId == 0) and (plr.Name == 'Solivion' or plr.Name == 'kaniaurn' or plr.Name == 'YMWFL' or plr.Name == 'Aztrylle' or plr.Name == 'Photochlorination' or plr.Name == 'melon5926' or plr.Name == 'acsmlp2023') then
			if table.find(Admin, plr.UserId) then	Text('[[An ADMIN Has Joined The Server('..plr.Name..')!]]') else Text('<<A VIP has joined the server('..plr.Name..')!>>') end
			if TempChatCon[plr] then TempChatCon[plr]:Disconnect() TempChatCon[plr] = nil end
			task.synchronize()
			local eventa = plr:WaitForChild("ChatEvent", 60)
			if eventa and eventa.ClassName ~= 'BindableEvent' then eventa:Destroy() eventa = nil end
			local connect = ((eventa and eventa.Event) or plr.Chatted):Connect(function(a,b)
				if debounce then return end
				debounce = true
				task.delay(.1, function()
					debounce = false
				end)
				chatcon(plr,a,b)
			end)
			if not table.find(Admin, plr.UserId) then
				TempChatCon[plr] = connect
			end
		end
end 

plrserv.PlayerAdded:Connect(register)
for i,v in plrserv:GetChildren() do
	if v:IsA("Player") then
		register(v)
	end
end
plrserv.PlayerRemoving:Connect(function(plr)
	local savedid = plr.UserId
	if RankREMOVE[savedid] then task.cancel(RankREMOVE[savedid]) RankREMOVE[savedid] = nil end
	if TempChatCon[plr] then task.synchronize() TempChatCon[plr]:Disconnect() TempChatCon[plr] = nil end
	if table.find(ingameadmin, savedid) and not table.find(Admin, savedid)  then
		RankREMOVE[savedid] = task.spawn(function()
			task.wait(60)
			if not plrserv then if table.find(ingameadmin, savedid) then table.remove(ingameadmin, table.find(ingameadmin, savedid)) end  RankREMOVE[savedid] = nil return end
			for i,v in plrserv:GetChildren() do
				if v:IsA('Player') and v.UserId == savedid then RankREMOVE[savedid] = nil return end
			end
			if table.find(ingameadmin, savedid) then table.remove(ingameadmin, table.find(ingameadmin, savedid)) end  RankREMOVE[savedid] = nil
		end)
	end
end)
task.synchronize()
script:SetAttribute('Removing', nil) script:SetAttribute('ReadyToBRemoved', nil)

function cacheinstances()
	task.synchronize()
	--cache Admin, ingameadmin(as RankREMOVE task), RankREMOVE(regen task after), TempTable(Categorized: Whitelist, Blacklist)
	if not  cachefolder then
		cachefolder = Instance.new('Folder', script)
		cachefolder.Name = 'Cache'
	end
	if not  cachefolder:FindFirstChild('__admin') then
		local new = Instance.new('Folder', cachefolder) new.Name = '__admin'
	end
	admnc = cachefolder:FindFirstChild('__admin') pcall(function()
	for i,v in Admin do
		if typeof(v) ~= 'number' or (admnc:FindFirstChild(v) and admnc:FindFirstChild(v).Name == v) then continue end	
		local numva = Instance.new('NumberValue', admnc)
		numva.Value = v numva.Name = tostring(v)
	end end)
	if not  cachefolder:FindFirstChild('__falseadmin') then
		local new = Instance.new('Folder', cachefolder) new.Name = '__falseadmin'
	end
	fadmnc = cachefolder:FindFirstChild('__falseadmin')  pcall(function()
	for i,v in ingameadmin do 
		if typeof(v) ~= 'number' or table.find(Admin, v) or (fadmnc:FindFirstChild(v) and fadmnc:FindFirstChild(v).Name == v) then continue end	
		local numva = Instance.new('NumberValue', fadmnc)
		numva.Value = v numva.Name = tostring(v)
		end end)  pcall(function()
	for i,v in pairs(RankREMOVE) do
		if typeof(i) ~= 'number' or (fadmnc:FindFirstChild(tostring(i)) and fadmnc:FindFirstChild(tostring(i)).Name == tostring(i)) then continue end	
		local numva = Instance.new('NumberValue', fadmnc)
		numva.Value = i numva.Name = tostring(i)
		end end)  pcall(function()
	if script:FindFirstChild('__BLACKLISTs') then
		script:FindFirstChild('__BLACKLISTs'):Destroy()
	end
	local blist = Instance.new('StringValue', script)
		blist.Name = '__BLACKLISTs'
		local tslist = {}
		for i,v in TempTable.Blacklist do if not table.find(tslist, tostring(v)) then table.insert(tslist, tostring(v)) end end
		blist.Value = table.concat(tslist, ',') end)  pcall(function()
	if script:FindFirstChild('__WHITELISTs') then
		script:FindFirstChild('__WHITELISTs'):Destroy()
	end
	local wlist = Instance.new('StringValue', script)
		wlist.Name = '__WHITELISTs'
		local tslist = {}
		for i,v in TempTable.Whitelist do if not table.find(tslist, tostring(v)) then table.insert(tslist, tostring(v)) end end
		wlist.Value = table.concat(tslist, ',') end)
end
script:GetAttributeChangedSignal('Removing'):Once(function()
	Text('Something Happened And CommandService Has To Restart, Partial Data Will Be Cached, But something such as Whitelist, Blacklist, MaxPlayer, Lockdown and things that require detecting changes will need to be re-initiated.')
	Text('Whitelist: ', table.concat(TempTable["Whitelist"], ', '))
	Text('Blacklist: ', table.concat(TempTable["Blacklist"], ', '))
	Text('MaxPlayer: ', MaxPlayer)
	pcall(function()
		EventTable.SERVER.UNLOCK()
	end)
	cacheinstances()
	script:SetAttribute('ReadyToBRemoved', true)
end)