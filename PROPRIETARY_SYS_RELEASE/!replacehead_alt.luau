--by wizard guy; solivion's fork
local rep = game:GetService("ReplicatedStorage")
repeat task.wait(1) until rep
local staticcontainer=game:GetService("ReplicatedStorage"):FindFirstChild('Offline Media')
repeat task.wait(1) until staticcontainer local staticdatacontainer=game:GetService("ReplicatedStorage"):FindFirstChild('Offline Media'):FindFirstChild('StaticHeadTable')
repeat task.wait(1) until staticdatacontainer 
local staticHeadTable = require(staticdatacontainer)
local replaceNonIdentifiedHeads = true --If true: Heads that cannot be found (Typically UGC Heads) will be replaced with the default smile as a failsafe.
local players = game:GetService("Players")
function findhead(chr)
	if typeof(chr) ~= 'Instance' or not chr:IsA("Model") or not chr.Parent then return end
	for i,v in chr:GetChildren() do
		if v:isA("BasePart") and v.Name:lower():match("head") then
			return v
		end
	end
end
local function FFCAC(parent: Instance, namePattern: string, className: string): Instance?
	if typeof(parent) ~= "Instance" then return nil end
	if typeof(namePattern) ~= "string" then return nil end
	if typeof(className) ~= "string" then return nil end

	for _, child in parent:GetChildren() do
		local a, isC = pcall(function()
			return child:IsA(className) -- asking IsA an impossible class might result in error
		end)
		if child.Name:upper():match(namePattern:upper()) and ((a and isC) or child.ClassName:upper():match(className:upper())) then
			return child
		end
	end
	return nil
end
local function addHead(plr, char)
	local head = findhead(char) if typeof(head) ~= 'Instance' or not string.match(string.lower(head.ClassName), 'part') then return end
	if head:FindFirstChildWhichIsA("FaceControls") then
		head.FaceControls:Destroy()
	end

	for i, accessory:Accessory in ipairs(char:GetChildren()) do
		if accessory:IsA("Accessory") then
			if accessory.AccessoryType == Enum.AccessoryType.Eyebrow or accessory.AccessoryType == Enum.AccessoryType.Eyelash then
				accessory:Destroy()
			end
		end
	end
	
	if head and head.Parent then
		local inittpr  = head.Transparency
		head.Transparency = 1
		
		pcall(function()
			local The = FFCAC(head, 'Neck', 'Motor6D')
			if The then
				The.C1 = CFrame.new(The.C1.X,-head.Size.Y/2.4,The.C1.Z) * The.C1.Rotation
			end
		end)
		pcall(function()
			local The: Attachment = FFCAC(head, 'NeckRig', 'Attachment')
			if The then
				The.CFrame = CFrame.new(The.CFrame.X,-head.Size.Y/2.4,The.CFrame.Z) * The.CFrame.Rotation
			end
		end)

		local c = script:FindFirstChild('FakeHead'):Clone()
		if not c then return end
		c.CFrame = head.CFrame
		c.Color = head.Color
		c.Transparency = inittpr
		pcall(function()
			head:FindFirstChildOfClass('Decal').Transparency = 1
		end)

		
		local w2 = Instance.new("Weld")
		w2.Part0 = head
		w2.Part1 = c
		c.Parent = char
		w2.Parent = c
		pcall(function()
			if head:FindFirstChild("Animated_Eye") or head:FindFirstChild("Animated_Mouth") or head:FindFirstChild("Animated_Expression") then return end
		local d = Instance.new("Decal")
		if char:FindFirstChild("Torso") then --R6
			if staticHeadTable[head.Mesh.MeshId] then
				d.Texture = staticHeadTable[head.Mesh.MeshId]
			else
				if replaceNonIdentifiedHeads == true then
					d.Texture = "rbxasset://textures/face.png"
				end
			end
		else --R15/Failsafe
			if staticHeadTable[head.MeshId] then
				d.Texture = staticHeadTable[head.MeshId]
			else
				if replaceNonIdentifiedHeads == true then
					d.Texture = "rbxasset://textures/face.png"
				end
			end
			end
			d.Name = 'face'
			d.Parent = c end) if c then pcall(function()
		local legit = true
		local a = head:GetPropertyChangedSignal("Size"):Connect(function() --Update fake head
			c.Size = head.Size
		end)
		local b = head:GetPropertyChangedSignal("Color"):Connect(function() --Update fake head
			c.Color = head.Color
		end)
		local ca = head:GetPropertyChangedSignal("Transparency"):Connect(function() --Update fake head
			if not legit then return end
			c.Transparency = head.Transparency
			legit = false
			head.Transparency = 1
			legit = true
		end) 
				-- Function to copy a decal/texture from real head to fake head
				local function copyDecal(decal)
					if not c or not c.Parent or decal.Name == 'face' then return end
					local newDecal 	if decal:IsA("Texture") then
						newDecal = Instance.new("Decal", c)
						newDecal.Name = decal.Name
						newDecal.Texture = decal.Texture
						newDecal.ColorMapContent = decal.ColorMapContent
					elseif decal:IsA("Decal") then task.spawn(function() if not decal.Parent then return end newDecal = decal.Name:match("Animated_") and decal:Clone() or decal end)
					else return end
					if not newDecal then return end
					decal.Transparency = 1
					if newDecal.Name:match("Animated_") then
						task.spawn(function()
							pcall(function()
								while task.wait(.1) do
									if not newDecal or not newDecal.Parent or not c or not c.Parent then
										break
									end
									if newDecal.Transparency ~= c.Transparency then	newDecal.Transparency = c.Transparency end
									if newDecal.ZIndex ~= c.ZIndex then	newDecal.ZIndex = decal.ZIndex end
									if newDecal.Texture ~= c.Texture then	newDecal.Texture = decal.Texture end
								end
							end)
						end)
						newDecal.Transparency = 0
					else
						newDecal.Parent = c
					end
				end
				
				-- Copy existing decals/textures from the real head
				for _, child in head:GetChildren() do
					if child:IsA("Decal") or child:IsA("Texture") then
						copyDecal(child)
					end
				end
				
				-- Replicate new decals/textures added to the real head
				local replicate = head.ChildAdded:Connect(function(child)
					if child:IsA("Decal") or child:IsA("Texture") then
						copyDecal(child)
					end
				end)		
				c.Destroying:Once(function()
				if a then pcall(function()	a:Disconnect() end) end
					if b then	 pcall(function() b:Disconnect() end) end
					if ca then  pcall(function()	ca:Disconnect() end) end
					if replicate then pcall(function() replicate:Disconnect() end) end
				a = nil b=nil ca=nil replicate=nil
				end) end) end
	end
end
local newbin = script:WaitForChild('Bound', 60)
if not script:FindFirstChild('Bound') or not script:FindFirstChildOfClass('BindableEvent') or not script:FindFirstChild('Bound').ClassName:match('BindableEvent') then if script:FindFirstChild('Bound') then script:FindFirstChild('Bound'):Destroy() end newbin  = Instance.new('BindableEvent', script) newbin.Name = 'Bound' else newbin = script:FindFirstChildOfClass('BindableEvent') end
newbin.Event:Connect(function(plr)
	if typeof(plr) ~= 'Instance' then return end if plr.ClassName == 'Model' then plr = {Character = plr} elseif plr.ClassName ~= 'Player' then return end
	local char = plr.Character
		if not char or not char.Parent then return end
		local head = findhead(char) 
		repeat task.wait(.2) head = findhead(char) until head or not char or not char.Parent
		if char:FindFirstChild("Torso") then
			if staticHeadTable[head.Mesh.MeshId] or replaceNonIdentifiedHeads == true then --R6
				addHead(plr, char)
			end
		else
			if staticHeadTable[head.MeshId] or replaceNonIdentifiedHeads == true then --R15/Failsafe
				addHead(plr, char)
			end
		end
	end)

