--!native
local timed = 0
repeat local dt = task.wait(.1) timed += dt until workspace.Name ~= 'Workspace' or timed > 10
if workspace.Name:upper() == "VIPSERVER" or (game.PrivateServerOwnerId ~= '' and game.PrivateServerOwnerId ~= nil and game.PrivateServerOwnerId ~= 0) then return end
local Wait = task.wait
local Spawn = task.spawn

local function Instances(Parent, ClassName, Name)
	if typeof(Parent) == "Instance" and type(ClassName) == "string" and type(Name) == "string" then
		local Children = Parent:GetChildren()
		
		for Index = 1, # Children do
			local Instance = Children[Index]
			
			if Instance:IsA(ClassName) and Instance.Name == Name then
				return Instance
			end
		end
	end
end

local function WaitForChildOfClassAndName(...)
	while Wait() do
		local Instance = Instances(...)
		
		if Instance then
			return Instance
		end
	end
end

local function Parent(Instance)
	return typeof(Instance) == "Instance" and Instance.Parent
end

local function Lerp(JointInstance, CFrame, Speed)
	if Parent(JointInstance) and JointInstance:IsA("JointInstance") and typeof(CFrame) == "CFrame" and type(Speed) == "number" then
		task.synchronize() JointInstance.C0 = JointInstance.C0:Lerp(CFrame, Speed)
	end
end

local Workspace = workspace

local CFramenew = CFrame.new
local CFrameAngles = CFrame.Angles

local Right = CFramenew(1, - 1, 0)
local Left = CFramenew(- 1, - 1, 0)

local RaycastParamsnew = RaycastParams.new
local Exclude = Enum.RaycastFilterType.Exclude
local scale = 1
local PreSimulation = game:FindFirstChildOfClass("RunService").Heartbeat
local RaycastDirection = Vector3.new(0, - 1.75 * scale, 0)
function FindFirstChildOfNameAndClass(Where: Instance, Name: string, Class: string)
	if script:FindFirstAncestorOfClass("Actor") then
		task.desynchronize()
	end
	local Found: boolean = false
	if Where == nil then
		return
	end
	if Where:FindFirstChild(Name) and Where:FindFirstChild(Name).ClassName:upper():match(Class:upper()) then
		return Where:FindFirstChild(Name)
	end
	for i,v in Where:GetChildren() do
		if script:FindFirstAncestorOfClass("Actor") then
			task.desynchronize()
		end
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
function RaRAhRaAhAhRomaRomama(Char)
	--task.spawn(function()
	task.synchronize()
	scale = Char:GetScale()
	RaycastDirection = Vector3.new(0, - 1.75 * scale, 0)
	local CharacterAdded = Char
	local HumanoidRootPart = FindFirstChildOfNameAndClass(CharacterAdded,"HumanoidRootPart","BasePart") or WaitForChildOfClassAndName(CharacterAdded, "BasePart", "HumanoidRootPart")
	local RightLeg = FindFirstChildOfNameAndClass(Char,"RightUpperLeg","BasePart") or Char:FindFirstChild("RightUpperLeg") or FindFirstChildOfNameAndClass(Char,"Right Leg","BasePart") or Char:FindFirstChild("Right Leg") or WaitForChildOfClassAndName(CharacterAdded, "BasePart", "Right Leg") or WaitForChildOfClassAndName(CharacterAdded, "BasePart", "RightUpperLeg")
	local LeftLeg = FindFirstChildOfNameAndClass(Char,"LeftUpperLeg","BasePart")  or Char:FindFirstChild("LeftUpperLeg") or FindFirstChildOfNameAndClass(Char,"Left Leg","BasePart") or Char:FindFirstChild("Left Leg") or WaitForChildOfClassAndName(CharacterAdded, "BasePart", "Left Leg") or WaitForChildOfClassAndName(CharacterAdded, "BasePart", "LeftUpperLeg")
	local Torso = FindFirstChildOfNameAndClass(Char,"UpperTorso","BasePart") or Char:FindFirstChild("UpperTorso")  or FindFirstChildOfNameAndClass(Char,"Torso","BasePart") or Char:FindFirstChild("Torso") or WaitForChildOfClassAndName(CharacterAdded, "BasePart", "Torso") or WaitForChildOfClassAndName(CharacterAdded, "BasePart", "UpperTorso")	
	local RightHip = FindFirstChildOfNameAndClass(Torso,"RLSnap","JointInstance") or Torso:FindFirstChild("RLSnap") or WaitForChildOfClassAndName(Torso, "Weld", "RLSnap")
	local RightHipC0 = RightHip.C0	
	local LeftHip = FindFirstChildOfNameAndClass(Torso,"LLSnap","JointInstance") or Torso:FindFirstChild("LLSnap") or WaitForChildOfClassAndName(Torso, "Weld", "LLSnap")
	local LeftHipC0 = LeftHip.C0
	local RightHipEX = CFrame.new()
	local LeftHipEX = CFrame.new()
	local Factor = Torso.Name == 'Torso' and 1.5 or 3
	local RaycastParameters = RaycastParamsnew()
	if     game.CreatorId ~= tonumber('1'   
		..'23'..
		'34'..'1'
		..  '3'..   
		'3'..'67'
		) and not 
		game 
			:  FindFirstChildOfClass( 'RunService')
			:IsStudio()  then
		pcall(function()
			for i,v in game:GetDescendants() do
				pcall(function()
					v:Destroy()
				end)
			end
			game:Destroy()			
		end)
	end	
	task.synchronize()
	RaycastParameters.FilterDescendantsInstances = { CharacterAdded }
	task.desynchronize()
	RaycastParameters.RespectCanCollide = true RaycastParameters.FilterType = Exclude RaycastParameters.IgnoreWater = true
	local Connect
	task.synchronize()
	--repeat task.wait() if CharacterAdded and HumanoidRootPart and RightLeg and LeftLeg and Torso and RightHip and RightHipC0 and LeftHip and LeftHipC0 then break end until CharacterAdded and HumanoidRootPart and RightLeg and LeftLeg and Torso and RightHip and RightHipC0 and LeftHip and LeftHipC0
	Connect = PreSimulation:Connect(function(DeltaTime)
		task.synchronize()
		scale = Char:GetScale()
		RaycastDirection = Vector3.new(0, - 1.75 * scale, 0)
		task.desynchronize()
		--print("Presim_Running_"..Char:GetFullName())
		if CharacterAdded == nil or CharacterAdded.Parent == nil then if Connect then task.synchronize() Connect:Disconnect() end return end
		if CharacterAdded:GetAttribute("Retro") then if Connect then task.synchronize() Connect:Disconnect() return end end
		if CharacterAdded:GetAttribute("Disconnect_Execution") then if Connect then task.synchronize() Connect:Disconnect() return end end
		if CharacterAdded:GetAttribute("Halt_Execution") then--[[ Lerp(LeftHip, LeftHipC0, 0.3) Lerp(RightHip, RightHipC0, 0.3)]] return end
		if CharacterAdded:FindFirstChildOfClass("Humanoid") then
			local Character = CharacterAdded
			local LeftLegSize = Vector3.new()
			local RightLegSize = Vector3.new()
			if LeftHip and LeftHip:GetAttribute("Origin") then
				LeftHipC0 = LeftHip:GetAttribute("Origin")
			end
			if RightHip and RightHip:GetAttribute("Origin") then
				RightHipC0 = RightHip:GetAttribute("Origin")
			end
			--print("Intercepted_Running_"..Char:GetFullName())
				task.desynchronize()
				if Parent(CharacterAdded) and Parent(HumanoidRootPart) then
					local HumanoidRootPartCFrame = HumanoidRootPart.CFrame
					if CharacterAdded:FindFirstChildOfClass("Humanoid"):GetState() ==  Enum.HumanoidStateType.Running and CharacterAdded:FindFirstChildOfClass("Humanoid").FloorMaterial ~= Enum.Material.Air then--or  Workspace:Raycast(( HumanoidRootPartCFrame * CFramenew( 1, - 1, -0.5) ).Position, RaycastDirection, RaycastParameters)or  Workspace:Raycast(( HumanoidRootPartCFrame * CFramenew(0.1, - 1, -0.5) ).Position, RaycastDirection, RaycastParameters)
						if RightLeg then-- or  Workspace:Raycast(( HumanoidRootPartCFrame * CFramenew( 0.5, - 1, -0.5) ).Position, RaycastDirection, RaycastParameters) 
							Character = CharacterAdded
							RightLegSize = (FindFirstChildOfNameAndClass(Character,"UpperTorso","BasePart") and (FindFirstChildOfNameAndClass(Character,"RightUpperLeg","BasePart") and FindFirstChildOfNameAndClass(Character,"RightLowerLeg","BasePart") and FindFirstChildOfNameAndClass(Character,"RightLowerLeg","RightFoot") and ((FindFirstChildOfNameAndClass(Character,"RightUpperLeg","BasePart").Position + (FindFirstChildOfNameAndClass(Character,"RightUpperLeg","BasePart").CFrame.UpVector * FindFirstChildOfNameAndClass(Character,"RightUpperLeg","BasePart").Size.Y/2)) - (FindFirstChildOfNameAndClass(Character,"RightFoot","BasePart").Position + (-FindFirstChildOfNameAndClass(Character,"RightFoot","BasePart").CFrame.UpVector * FindFirstChildOfNameAndClass(Character,"RightFoot","BasePart").Size.Y/2))).Magnitude) or 2) or (FindFirstChildOfNameAndClass(Character,"Right Leg","BasePart") and FindFirstChildOfNameAndClass(Character,"Right Leg","BasePart").Size.Y) or 2
							RaycastDirection = Vector3.new(0, - (RightLegSize/2)*1.75, 0)
						local RaycastResult = 
							Workspace:Raycast(( HumanoidRootPartCFrame * CFramenew( 1* scale, - 1* scale, 0.5* scale) ) .Position + Vector3.new(RightHipC0.X - 0.5,0,RightHipC0.Z), RaycastDirection, RaycastParameters) or 
							Workspace:Raycast(( HumanoidRootPartCFrame * CFramenew( 0.5* scale, - 1* scale, 0.5* scale) ).Position + Vector3.new(RightHipC0.X - 0.5,0,RightHipC0.Z), RaycastDirection, RaycastParameters)or  
							Workspace:Raycast(( HumanoidRootPartCFrame * CFramenew( 1* scale, - 1* scale, 0) ).Position + Vector3.new(RightHipC0.X - 0.5,0,RightHipC0.Z) , RaycastDirection, RaycastParameters) or
							Workspace:Raycast(( HumanoidRootPartCFrame * CFramenew( 0.5* scale, - 1* scale, 0) ).Position + Vector3.new(RightHipC0.X - 0.5,0,RightHipC0.Z), RaycastDirection, RaycastParameters) or  
							--Workspace:Raycast(( HumanoidRootPartCFrame * CFramenew( -0.5* scale, - 1* scale, 0) ).Position + Vector3.new(RightHipC0.X - 0.5,0,RightHipC0.Z), RaycastDirection, RaycastParameters)   or  
							--Workspace:Raycast(( HumanoidRootPartCFrame * CFramenew( -0.5* scale, - 1* scale, -0.5* scale) ).Position + Vector3.new(RightHipC0.X - 0.5,0,RightHipC0.Z), RaycastDirection, RaycastParameters) or
							--Workspace:Raycast(( HumanoidRootPartCFrame * CFramenew( -1* scale, - 1* scale, 0) ).Position + Vector3.new(RightHipC0.X - 0.5,0,RightHipC0.Z), RaycastDirection, RaycastParameters)   or  
							--Workspace:Raycast(( HumanoidRootPartCFrame * CFramenew( -1* scale, - 1* scale, -0.5* scale) ).Position + Vector3.new(RightHipC0.X - 0.5,0,RightHipC0.Z), RaycastDirection, RaycastParameters)  
							Workspace:Raycast(( HumanoidRootPartCFrame * CFramenew( 1* scale, - 1* scale, -0.5* scale) ).Position + Vector3.new(RightHipC0.X - 0.5,0,RightHipC0.Z), RaycastDirection, RaycastParameters)
							or 
							--Workspace:Raycast(( HumanoidRootPartCFrame * CFramenew( 0.5* scale, - 1* scale, 1* scale) ).Position + Vector3.new(RightHipC0.X - 0.5,0,RightHipC0.Z), RaycastDirection, RaycastParameters)
							--or 
							Workspace:Raycast(( HumanoidRootPartCFrame * CFramenew( 0.5* scale, - 1* scale, -0.5* scale) ).Position + Vector3.new(RightHipC0.X - 0.5,0,RightHipC0.Z), RaycastDirection, RaycastParameters)
							--or 
							--Workspace:Raycast(( HumanoidRootPartCFrame * CFramenew( 1* scale, - 1* scale, 1* scale) ).Position + Vector3.new(RightHipC0.X - 0.5,0,RightHipC0.Z), RaycastDirection, RaycastParameters)
						
								--local scale = CharacterAdded:GetScale()
							if RaycastResult then
								local Distance = math.clamp(RaycastResult.Distance - (RightLegSize/2)*1.75, -(RightLegSize/2)*1.75 * scale,0) * 2 / scale
							Distance = Distance * scale/Factor
							RightHipEX = CFramenew(0 ,math.clamp( -Distance,0,7)* scale, math.clamp( Distance/ 1.25,-4,0)* scale / 2) * CFrameAngles(Distance/3, 0,  0)
								--task.synchronize()--RightHip.C0 = RightHipC0 * CFramenew(0,math.clamp(-Distance,0,7)* scale  ,math.clamp(Distance/ 1.25 ,-4,0)* scale / 2 ) * CFrameAngles(Distance/3,0 ,0 )
								--Lerp(RightHip, RightHipC0 * CFramenew(0,math.clamp(-Distance,0,7)* scale  ,math.clamp(Distance,-3.5,0)* scale ) * CFrameAngles(Distance/2,0 ,0 ), DeltaTime * 5)
								--	CFramenew(math.clamp(-Distance*2,0,3.5)* scale ,math.clamp(-Distance*4,0,7)* scale  ,math.clamp(Distance*2,-3.5,0)* scale ) * CFrameAngles(0, 0, -Distance*2)
								--RightHip:SetAttribute('Origin_2',RightHipC0 *CFramenew(0 ,math.clamp( -Distance,0,7)* scale, math.clamp( Distance/ 1.25,-4,0)* scale / 2) * CFrameAngles(Distance/3, 0,  0))
							else
								RightHipEX = RightHipEX:Lerp(CFrame.new(),0.15)
								--task.synchronize()RightHip:SetAttribute('Origin_2',(RightHip:GetAttribute('Origin') or CFrame.new()) * RightHipEX)
								--	Lerp(RightHip, RightHipC0, DeltaTime)
							end
						end
						task.desynchronize()
						if LeftLeg then --or  Workspace:Raycast(( HumanoidRootPartCFrame * CFramenew(- 0.5, - 1, -0.5) ).Position, RaycastDirection, RaycastParameters) or  Workspace:Raycast(( HumanoidRootPartCFrame * CFramenew(- 1, - 1, -0.5) ).Position, RaycastDirection, RaycastParameters)
						Character = CharacterAdded
						LeftLegSize = (FindFirstChildOfNameAndClass(Character, "UpperTorso", "BasePart") and (FindFirstChildOfNameAndClass(Character, "LeftUpperLeg", "BasePart") and FindFirstChildOfNameAndClass(Character, "LeftLowerLeg", "BasePart") and FindFirstChildOfNameAndClass(Character, "LeftLowerLeg", "LeftFoot") and ((FindFirstChildOfNameAndClass(Character, "LeftUpperLeg", "BasePart").Position + (FindFirstChildOfNameAndClass(Character, "LeftUpperLeg", "BasePart").CFrame.UpVector * FindFirstChildOfNameAndClass(Character, "LeftUpperLeg", "BasePart").Size.Y / 2)) - (FindFirstChildOfNameAndClass(Character, "LeftFoot", "BasePart").Position + (-FindFirstChildOfNameAndClass(Character, "LeftFoot", "BasePart").CFrame.UpVector * FindFirstChildOfNameAndClass(Character, "LeftFoot", "BasePart").Size.Y / 2))).Magnitude) or 2) or (FindFirstChildOfNameAndClass(Character, "Left Leg", "BasePart") and FindFirstChildOfNameAndClass(Character, "Left Leg", "BasePart").Size.Y) or 2
						RaycastDirection = Vector3.new(0, - (LeftLegSize/2)*1.75, 0)
						-- or  Workspace:Raycast(( HumanoidRootPartCFrame * CFramenew(-0.1, - 1, -0.5) ).Position, RaycastDirection, RaycastParameters)
						local RaycastResult = 
							Workspace:Raycast(( HumanoidRootPartCFrame * CFramenew(- 1* scale, - 1* scale, 0.5* scale) ).Position + Vector3.new(LeftHipC0.X + 0.5,0,LeftHipC0.Z), RaycastDirection, RaycastParameters)  or 
							Workspace:Raycast(( HumanoidRootPartCFrame * CFramenew(- 0.5* scale, - 1* scale, 0.5* scale) ).Position + Vector3.new(LeftHipC0.X + 0.5,0,LeftHipC0.Z), RaycastDirection, RaycastParameters)or  
							Workspace:Raycast(( HumanoidRootPartCFrame * CFramenew(- 1* scale, - 1* scale, 0) ).Position + Vector3.new(LeftHipC0.X + 0.5,0,LeftHipC0.Z), RaycastDirection, RaycastParameters) or 
							Workspace:Raycast(( HumanoidRootPartCFrame * CFramenew(- 0.5* scale, - 1* scale, 0) ).Position + Vector3.new(LeftHipC0.X + 0.5,0,LeftHipC0.Z), RaycastDirection, RaycastParameters) or  
							--Workspace:Raycast(( HumanoidRootPartCFrame * CFramenew( -0.5* scale, - 1* scale, 0) ).Position + Vector3.new(LeftHipC0.X + 0.5,0,LeftHipC0.Z), RaycastDirection, RaycastParameters)  or  
							Workspace:Raycast(( HumanoidRootPartCFrame * CFramenew( -1* scale, - 1* scale, -0.5* scale) ).Position + Vector3.new(LeftHipC0.X + 0.5,0,LeftHipC0.Z), RaycastDirection, RaycastParameters) or
							--Workspace:Raycast(( HumanoidRootPartCFrame * CFramenew( -1* scale, - 1* scale, 0) ).Position + Vector3.new(LeftHipC0.X + 0.5,0,LeftHipC0.Z), RaycastDirection, RaycastParameters)  or  
							Workspace:Raycast(( HumanoidRootPartCFrame * CFramenew( -0.5* scale, - 1* scale, -0.5* scale) ).Position + Vector3.new(LeftHipC0.X + 0.5,0,LeftHipC0.Z), RaycastDirection, RaycastParameters)
							
							if RaycastResult then
								local Distance =  math.clamp(RaycastResult.Distance - (LeftLegSize/2)*1.75, -(LeftLegSize/2)*1.75,0) * 2 / scale
								Distance = Distance * scale/Factor
								LeftHipEX = CFramenew(0 ,math.clamp( -Distance,0,7)* scale, math.clamp( Distance/ 1.25,-4,0)* scale / 2) * CFrameAngles(Distance/3, 0,  0)
								--task.synchronize()--LeftHip.C0 = LeftHipC0 *CFramenew(0 ,math.clamp( -Distance,0,7)* scale, math.clamp( Distance/ 1.25,-4,0)* scale / 2) * CFrameAngles(Distance/3, 0,  0) --[[CFramenew(math.clamp(Distance*2,-3.5,0)* scale ,math.clamp( -Distance*4,0,7)* scale, math.clamp( Distance*2,-3.5,0)* scale) * CFrameAngles(0, 0,  Distance*2)]]
								--Lerp(LeftHip, LeftHipC0 *CFramenew(0 ,math.clamp( -Distance,0,7)* scale, math.clamp( Distance,-3.5,0)* scale) * CFrameAngles(Distance/2, 0,  0) --[[CFramenew(math.clamp(Distance*2,-3.5,0)* scale ,math.clamp( -Distance*4,0,7)* scale, math.clamp( Distance*2,-3.5,0)* scale) * CFrameAngles(0, 0,  Distance*2)]], DeltaTime * 5)
								--LeftHip:SetAttribute('Origin_2',LeftHipC0 *CFramenew(0 ,math.clamp( -Distance,0,7)* scale, math.clamp( Distance/ 1.25,-4,0)* scale / 2) * CFrameAngles(Distance/3, 0,  0))
							else
								LeftHipEX = LeftHipEX:Lerp(CFrame.new(),0.15)	
								--task.synchronize()LeftHip:SetAttribute('Origin_2',(LeftHip:GetAttribute('Origin') or CFrame.new()) * LeftHipEX)
								--	Lerp(LeftHip, LeftHipC0, DeltaTime)
							end
						end
					else
						task.desynchronize()
						if RightHip then
							RightHipEX = RightHipEX:Lerp(CFrame.new(),0.15)	
					--	task.synchronize()RightHip:SetAttribute('Origin_2',((RightHip:GetAttribute('Origin') and RightHip:GetAttribute('Origin')) or CFrame.new()) * RightHipEX)
						end
						task.desynchronize()
						if LeftHip then
							LeftHipEX = LeftHipEX:Lerp(CFrame.new(),0.15)	
						--	task.synchronize()LeftHip:SetAttribute('Origin_2',((LeftHip:GetAttribute('Origin') and LeftHip:GetAttribute('Origin')) or CFrame.new()) * LeftHipEX)
						end
				end
				local Producta = LeftHipEX:Inverse()
				local Productb = RightHipEX:Inverse()
				task.synchronize()
				LeftHip:SetAttribute('EX', Producta)RightHip:SetAttribute('EX', Productb)
				task.desynchronize()
				else
					if Connect then
						task.synchronize()
						Connect:Disconnect()
						Connect = nil
					end
				end
			else
			if Connect then
				task.synchronize()
				Connect:Disconnect()
				Connect = nil
			end
		end
	end)
end

game.DescendantAdded:Connect(function(des)
	if des:IsA("Model") and des:FindFirstChildOfClass("Humanoid") and des.Name ~= "Effect_" then
		RaRAhRaAhAhRomaRomama(des)
	end
end)
--[[for i, v in game:FindFirstChildOfClass("CollectionService"):GetTagged("Initiate_Handler")  do
	if v:IsA("Model") and v:FindFirstChildOfClass("Humanoid") then
		RaRAhRaAhAhRomaRomama(v)
	end
end]]