type RequestStruct = {
	Requestor: Player,
	Target: Player,
	Tool: Instance,
	Task: {thread},
	Connections: {RBXScriptConnection},
	CleanUpRequest: thread
}
local tablesofid = {}
function uniqueid(number: number) -- to register different freefall that occured so the cancoyotejump will not be disabled for that new fall if u r so fast
	local uniqueid = math.random()
	if uniqueid == number or table.find(tablesofid, uniqueid) then
		repeat if uniqueid == number or table.find(tablesofid, uniqueid) then  uniqueid += math.random() end until not table.find(tablesofid, uniqueid)
	end
	table.insert(tablesofid, uniqueid)
	task.delay(200, function()
		if table.find(tablesofid, uniqueid) then
			table.remove(tablesofid, table.find(tablesofid, uniqueid))
		end
	end)
	return uniqueid
end
local PlayerData: {Player: {RequestStruct}} = {}
function NewRQStruct(Player, ToPlayer, Item)
	return {
		Requestor = Player,
		Target = ToPlayer,
		Tool = Item,
		Connections = {},
		Task = {}
	}
end
function RunRQStruct(Struct: RequestStruct)
	task.desynchronize()
	if typeof(Struct) ~= "table" then return end
	local DestinationPlayer: Player = Struct.Target
	local SenderPlayer: Player = Struct.Requestor
	local TheTool: Tool = Struct.Tool
	if not DestinationPlayer or not SenderPlayer or not TheTool then return true end
	if PlayerData[DestinationPlayer] and #next(PlayerData[DestinationPlayer]) > 5 then return end
	task.synchronize()
	TheTool.Parent = script -- SERVERSCRIPTSERVICE
	task.desynchronize()
	local StructKeys = tostring(uniqueid()).."__STRUCTKEY__"..tostring(Struct.Requestor).."__"..tostring(Struct.Target).."__ITEM__"..tostring(Struct.Tool).."__WRAPPER" 
	local PublicKey = tostring(math.round(math.random() * 100000))..'_'..tostring(Struct.Requestor)..'_'..tostring(Struct.Target)..'_END'
	local StoredToolData = {CFrame = TheTool:GetPivot() or CFrame.new(), OriginPlayer = SenderPlayer}
	local SelfDestruct = function()
		if not Struct.CleanUpRequest then return end
		task.synchronize()
		for i,v in Struct.Connections do
			v:Disconnect()
		end
		if Struct.Task then coroutine.close(Struct.Task) Struct.Task = nil end
		if TheTool and not (DestinationPlayer and TheTool:IsDescendantOf(DestinationPlayer)) and StoredToolData.OriginPlayer and StoredToolData.OriginPlayer.Parent then TheTool.Parent = StoredToolData.OriginPlayer.Backpack elseif not DestinationPlayer then TheTool.Parent = workspace TheTool:PivotTo(StoredToolData.CFrame) end
		Struct.CleanUpRequest = nil
		if not DestinationPlayer and not PlayerData[DestinationPlayer] then return end
		PlayerData[DestinationPlayer][StructKeys] = nil
	end
	task.synchronize()
	pcall(function()
		game:FindFirstChildOfClass('ReplicatedStorage'):FindFirstChild('LogMessageEvent'):FireClient(SenderPlayer, 'Inform Your Partner, OPERATION KEY IS: '..PublicKey)
	end)
	table.insert(Struct.Connections, TheTool.Destroying:Once(SelfDestruct))table.insert(Struct.Connections, SenderPlayer.Destroying:Once(SelfDestruct))table.insert(Struct.Connections, DestinationPlayer.Destroying:Once(SelfDestruct))
	local event = SenderPlayer and SenderPlayer:FindFirstChild('ChatEvent')
	local eventa = DestinationPlayer and DestinationPlayer:FindFirstChild('ChatEvent')
	if not event:IsA('BindableEvent') then event = nil end if not eventa:IsA('BindableEvent') then eventa = nil end
	table.insert(Struct.Connections, ((event and event.Event) or SenderPlayer.Chatted):Connect(function(message)
		if not message:split(' ')[1]:upper():match('!CANCEL') or not  message:split(' ')[2]:upper():match(PublicKey:upper()) then return end
		SelfDestruct()
	end))
	table.insert(Struct.Connections, ((eventa and eventa.Event) or DestinationPlayer.Chatted):Connect(function(message)
		if (message:split(' ')[1]:upper():match('!ACCEPT') or message:split(' ')[1]:upper():match('!CONFIRM') or message:split(' ')[1]:upper():match('!YES')or message:split(' ')[1]:upper():match('!RECEIVE')) and message:split(' ')[2]:upper():match(PublicKey:upper()) then 
			task.synchronize()	TheTool.Parent = DestinationPlayer.Backpack
			SelfDestruct() return
		end
		if not message:split(' ')[1]:upper():match('!CANCEL') or not  message:split(' ')[2]:upper():match(PublicKey:upper()) then return end
		SelfDestruct()
	end))
	task.desynchronize()
	Struct.Task = coroutine.create(function()
		task.wait(200) -- Request Time Out
		if not Struct.CleanUpRequest then return end
		SelfDestruct()
	end)
	Struct.CleanUpRequest = SelfDestruct
	if not PlayerData[DestinationPlayer] then PlayerData[DestinationPlayer] = {} DestinationPlayer.Destroying:Once(function() PlayerData[DestinationPlayer] = nil end) end
	PlayerData[DestinationPlayer][StructKeys] = Struct
	coroutine.resume(Struct.Task)
end
function InitiateGift(Player: Player, Target: Player, Item: Tool)
	task.desynchronize()
	if not Player or not Target or not Player.Parent or not Target.Parent or (typeof(Target) ~= 'string' and typeof(Target) ~= nil and typeof(Target) ~= 'Instance') then return end
	RunRQStruct(NewRQStruct(Player, Target, (typeof(Item) == 'Instance' and Item) or (Item and Player.Backpack:FindFirstChild(Item) and Player.Backpack:FindFirstChild(Item):IsA('Tool') and Player.Backpack:FindFirstChild(Item)) or Player.Character and Player.Character:FindFirstChildOfClass('Tool')))	
end

task.synchronize()
script.Event.Event:Connect(InitiateGift) -- via server chat from somewhere else


coroutine.resume(coroutine.create(function()
	while task.wait(200) do --//stray cases, events not picked up
		task.desynchronize()
		for i,v: RequestStruct in pairs(PlayerData) do
			if i and not i.Parent or not v.Requestor or not v.Target or not v.Tool or not v.Requestor.Parent or not v.Target.Parent or not v.Tool.Parent then if v.CleanUpRequest ~= nil then v.CleanUpRequest() end PlayerData[i] = nil end
		end
	end
end))
