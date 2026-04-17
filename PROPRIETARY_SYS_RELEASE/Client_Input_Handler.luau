--<<A Simple Client Input Transmitter>>--
--<<This Is Made For ServerSided Exclusive Script>>--
--// Useful For My Almost 90%(I made this number up lol don't ask me about it) Server Dependencies //--
task.synchronize()
ss = game:FindFirstChildOfClass("ServerStorage")
rs = game:FindFirstChildOfClass("ReplicatedStorage")
if ss:FindFirstChild("Input_Storage") then ss:FindFirstChild("Input_Storage"):Destroy() end
isactored = script:FindFirstAncestorWhichIsA("Actor")
netmodu = game:FindFirstChildOfClass("ReplicatedStorage") and game:FindFirstChildOfClass("ReplicatedStorage"):FindFirstChild("???") and game:FindFirstChildOfClass("ReplicatedStorage"):FindFirstChild("???"):FindFirstChild("BridgeNet")
local brid = require(netmodu)
bridinp = brid.WaitForBridge('Client_Input') or  brid.CreateBridge("Client_Input")
local PlrStuff = {}
if not rs:FindFirstChild("Client_Input") then
	local NewRemote = Instance.new("RemoteEvent")
	NewRemote.Name = "Client_Input"
	NewRemote.Parent = rs
end
if not ss:FindFirstChild("Input_Storage") then
	task. synchronize() 
	local NewFolder = Instance.new("Folder")
	NewFolder.Name = "Input_Storage"
	NewFolder.Parent = ss
	task. desynchronize() 
end

local cpms = {}
local lpms = {}
task.synchronize()
game:GetService('Players').PlayerAdded:Connect(function(Plr)
	task. desynchronize() 
	if not ss:FindFirstChild("Input_Storage"):FindFirstChild(Plr.Name..'#>(') then
		task. synchronize() 
		local NewFolder = Instance.new("Folder")
		NewFolder.Name = Plr.Name..'#>('
		NewFolder.Parent = ss:FindFirstChild("Input_Storage")
		NewFolder:SetAttribute("Focused",true)
		NewFolder:SetAttribute("Menu",false)
		NewFolder:SetAttribute("TextBoxFocused",false)
		task. desynchronize() 
	end
	if not PlrStuff[Plr] then
		PlrStuff[Plr] = {}
		PlrStuff[Plr].Menu = false
		PlrStuff[Plr].Focus = true
		PlrStuff[Plr].Camera = CFrame.new()
		PlrStuff[Plr].Mouse = Vector3.new()
		PlrStuff[Plr].TextBox = false
	end
	cpms[Plr] =  0 lpms[Plr] =  0
end)
game:GetService('Players').PlayerRemoving:Connect(function(Plr)
	task. synchronize() 
	pcall(function()
		task. desynchronize() 
		if ss:FindFirstChild("Input_Storage"):FindFirstChild(Plr.Name..'#>(') then
			task. synchronize()  ss:FindFirstChild("Input_Storage"):FindFirstChild(Plr.Name..'#>('):Destroy()
		end
	end)
	cpms[Plr] = nil lpms[Plr] =  0
end)

coroutine.resume(coroutine.create(function()
	while workspace.Name ~= 'VIPSERVER' do
		local dt = task.wait(1) 
		for i,v in pairs(cpms) do
			cpms[i] = 0
		end
		for i,v in pairs(lpms) do
			lpms[i] = 0
		end
	end
end))

script.Event.Event:Connect(function(Plr)
	if not PlrStuff[Plr] then return end
	PlrStuff[Plr].Focus = true
	PlrStuff[Plr].Menu = false
end)
bridinp:Connect(function(Plr :Player,In_Out :string,Input--[[ :Enum.KeyCode | string]],...)
	task. desynchronize() 
	local Place = ss:FindFirstChild("Input_Storage"):FindFirstChild(Plr.Name..'#>(')
	if not Place then return end
	if not string.match(tostring(Input),'Enum.KeyCode') then
		cpms[Plr] = (cpms[Plr] and math.min(cpms[Plr] + 1,35)) or 30
		if cpms[Plr] >= 30 and workspace.Name ~= 'VIPSERVER' then
			return
		end
		if In_Out == 'Focus' then
			if Input == 'In'  or Input:upper():match('IN') then
				if Plr.Character and Plr.Character:FindFirstChild('Head') and Plr.Character:FindFirstChild('Head'):FindFirstChild('__AFKui') then
					task. synchronize() Plr.Character:FindFirstChild('Head'):FindFirstChild('__AFKui'):Destroy() task. desynchronize() 
				end
				if Place then
					PlrStuff[Plr].Focus = true
					task. synchronize() 
					Place:SetAttribute("Focused",true)
					--Place:ClearAllChildren()
				end
			elseif Input == 'Out' or Input:upper():match('OUT') then
				if Plr.Character and Plr.Character:FindFirstChild('Head') and Plr.Character:FindFirstChild('Head'):IsA('BasePart') then
					task. synchronize() 
					script.__AFKui.PlayerToHideFrom = Plr
					script.__AFKui:Clone().Parent = Plr.Character:FindFirstChild('Head')
					task. desynchronize() 
				end
				if Place then
					PlrStuff[Plr].Focus = false
					task. synchronize() 
					Place:SetAttribute("Focused",false)
					Place:ClearAllChildren()
				end
			end
		elseif In_Out == 'Menu' then
			if Input == 'In'  or Input:upper():match('IN') then
				if Place then
					PlrStuff[Plr].Menu = true
					task. synchronize() 
					Place:SetAttribute("Menu",true)
					Place:ClearAllChildren()
				end
			elseif Input == 'Out' or Input:upper():match('OUT') then
				if Place then
					PlrStuff[Plr].Menu = false
					task. synchronize() 
					Place:SetAttribute("Menu",false)
				end
			end
		elseif In_Out == 'TextBoxFocused' then
			if Input == 'In' or Input:upper():match('IN') then
				if Place then
					PlrStuff[Plr].TextBox = true
					task. synchronize() 
					Place:SetAttribute("TextBoxFocused",true)
					Place:ClearAllChildren()
				end
			elseif Input == 'Out' or Input:upper():match('OUT') then
				if Place then
					PlrStuff[Plr].TextBox = false
					task. synchronize() 
					Place:SetAttribute("TextBoxFocused",false)
					Place:ClearAllChildren()
				end
			end
		elseif In_Out == 'Camera'  and PlrStuff[Plr].Camera ~= Input then
			if Place then
				PlrStuff[Plr].Camera = In_Out
				task. synchronize() 
				Place:SetAttribute("CamPos",Input)
			end
		elseif In_Out == 'IsInFirstPerson' then
			if Place then
				task. synchronize() 
				Place:SetAttribute("IsInFirstPerson",Input)
			end
		elseif In_Out == 'Jumping' then
			if Plr.Character then
				task. synchronize() 
				Plr.Character:SetAttribute('Jumping', true)
				----((Plr.Name..' Jumped')
			end
		elseif In_Out == 'Mouse' then
			if Place and PlrStuff[Plr].Mouse ~= Input then
				PlrStuff[Plr].Mouse = In_Out
				task. synchronize() 
				Place:SetAttribute("Mouse",Input)
				----(('a')
			end
		end
	else
		lpms[Plr] = (lpms[Plr] and  math.min(lpms[Plr] + 1, 50)) or 45
		if lpms[Plr] >= 45 and workspace.Name ~= 'VIPSERVER' then
			return
		end
		if Place and PlrStuff[Plr].Menu == false and PlrStuff[Plr].TextBox == false and PlrStuff[Plr].Focus == true and tostring(Input) then
			if In_Out == "In"..Plr.UserId then
				if not Place:FindFirstChild(tostring(Input)) then
					task. synchronize() 
					local NewItem = Instance.new("ClickDetector")
					NewItem.Name = tostring(Input)
					NewItem.Parent = Place
				end
			elseif In_Out == "Out"..Plr.UserId then
				if Place then
					if Place:FindFirstChild(tostring(Input)) then
						task. synchronize() 
						if ss:FindFirstChild("Input_Storage") and Place and Place:FindFirstChild(tostring(Input)) then Place:FindFirstChild(tostring(Input)):Destroy() end
					end
				end
			end
		end
	end
end)