task.wait()
if script:FindFirstAncestorWhichIsA('ServerStorage') then return end
function SetGrip(Tool: Tool, Torso: BasePart)
	if Tool and Tool.Grip.LookVector:Dot(CFrame.Angles(math.rad(Torso.CFrame.LookVector:Dot(Vector3.new(0,1,0)) * 90),0,0).LookVector) < .95 then
		task.synchronize()
		Tool.Grip = CFrame.new(Tool.Grip.Position) * CFrame.Angles(math.rad(Torso.CFrame.LookVector:Dot(Vector3.new(0,1,0)) * 90),0,0)
	end
end		function FindFirstChildOfNameAndClass(Where: Instance, Name: string, Class: string)
			local Found: boolean = false
			if Where == nil then
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
local attempt = 0
repeat local dt = task.wait(.1) attempt += dt if attempt >= 10 then break end until workspace:FindFirstChild('IsItRaining') and workspace:FindFirstChild('IsItRaining'):IsA('NumberValue') and workspace:FindFirstChild('IsItRaining').Value >= 4
if FindFirstChildOfNameAndClass(workspace,'IsItRaining','NumberValue') and FindFirstChildOfNameAndClass(workspace,'IsItRaining','NumberValue').Value >= 4 then
	local loopprocessor = {}
	local ongoing = false
	function SETUPLOOP()
		if ongoing then return end
		task.synchronize()
		coroutine.resume(coroutine.create(function()
			ongoing = true
			while task.wait(.05) and next(loopprocessor) do
				for i,v in pairs(loopprocessor) do
					task.desynchronize()
					local handle = FindFirstChildOfNameAndClass(i, "Handle", "Part")
					if i and not (i.Parent and v and v.Torso and v.Torso.Parent and handle) then loopprocessor[i] = nil continue end
					SetGrip(i, v['Torso'])
					if v['MESH'] then
						if not v['MESH']:FindFirstChild('Intersection') then task.synchronize() v['MESH']:Destroy() v['MESH'] = nil end
						task.synchronize()
						v['MESH'].Parent = workspace
						v['MESH'].Intersection.Anchored = true
						v['MESH'].Intersection.CFrame = handle.CFrame * CFrame.Angles(0,0,math.rad(-90))
					end
				end
			end
			ongoing = false
		end))	
	end
	local function setupumbrella(TOOL: Tool)
		if not TOOL or not TOOL:IsA('Tool') or TOOL:GetAttribute('REGGED') or not TOOL.Parent then return end
		local tool, Tool = TOOL, TOOL
		local weld: Weld
		local equipping = false
		local specialmesh -- the MESH
		local handle = FindFirstChildOfNameAndClass(Tool, 'Handle', 'Part') or Tool:WaitForChild('Handle', 10)
		if not handle then return end
		
		task.synchronize()
		TOOL:SetAttribute('REGGED', true)
		if script and Tool and handle and handle:FindFirstChildOfClass('SpecialMesh') then
			pcall(function()
			--[[if game:FindFirstChildOfClass('ContentProvider'):GetAssetFetchStatus(handle.Mesh.MeshId) == Enum.AssetFetchStatus.None then	game:FindFirstChildOfClass('ContentProvider'):PreloadAsync(handle.Mesh.MeshId) task.wait(10) else task.wait(1) end
			local loaded = game:FindFirstChildOfClass('ContentProvider'):GetAssetFetchStatus(handle.Mesh.MeshId)]]
				task.synchronize()
				if not workspace:GetAttribute('NEWYEAR') then
					handle.MESH:Destroy()
				else
					for i,v in handle.MESH:GetChildren() do
						if v:IsA('BasePart') or v:IsA('IntersectOperation') or v:IsA('UnionOperation') then
							v.Transparency = 0
							if v.Name == 'GRID' then
								v.Color = Color3.fromRGB(
									math.random(1,255),math.random(1,255),math.random(1,255)
								)
								if workspace:FindFirstChild('IsItRaining').Value == 5 then
									v.Material = Enum.Material.Neon
								end
							end
						end
					end
					handle.Transparency = 1
				end
			end)
		else return end

		tool.Equipped:Connect(function()
			task.desynchronize()
			if equipping then return end
			local handle = FindFirstChildOfNameAndClass(Tool, 'Handle', 'Part')
			loopprocessor[tool] = nil
			equipping = true
			if weld then task.synchronize() weld:Destroy() task.desynchronize() end
			local character: Model =  tool.Parent
			local rarm: BasePart? = FindFirstChildOfNameAndClass(character, 'RightUpperArm', 'BasePart') or FindFirstChildOfNameAndClass(character, 'Right Arm', 'BasePart') or FindFirstChildOfNameAndClass(character, 'RightHand', 'BasePart') or FindFirstChildOfNameAndClass(character, 'RightLowerArm', 'BasePart')
			local Torso: BasePart? = FindFirstChildOfNameAndClass(character, 'UpperTorso', 'BasePart') or FindFirstChildOfNameAndClass(character, 'Torso', 'BasePart') or FindFirstChildOfNameAndClass(character, 'HumanoidRootPart', 'BasePart')
			if rarm and Torso and equipping and character:IsA('Model') and character:FindFirstChildOfClass('Humanoid') then
				task.synchronize()	
				local newweld = Instance.new('Weld', tool) newweld.Parent = tool
				newweld.Part1 = rarm newweld.Part0 = Torso
				newweld.C0 = CFrame.new(newweld.Part0.Size.X/2 + newweld.Part1.Size.X/2, 0, 0)
				game:FindFirstChildOfClass('TweenService'):Create(newweld, TweenInfo.new(math.clamp(math.random(), 0.25, 0.75), Enum.EasingStyle:GetEnumItems()[math.random(1, #Enum.EasingStyle:GetEnumItems())], Enum.EasingDirection:GetEnumItems()[math.random(1, #Enum.EasingDirection:GetEnumItems())]), {C0 = CFrame.Angles(math.rad(90),math.rad(5),math.rad(-20)) * CFrame.new(math.random()/4, math.random()/4, math.random()/4) * CFrame.Angles(math.random()/8, math.random()/8, math.random()/8): Inverse() * CFrame.new(newweld.Part0.Size.X/2 - newweld.Part1.Size.X/4, (newweld.Part1.Size.Z/2 - newweld.Part0.Size.Y/2)/2, newweld.Part0.Size.Y/2 - newweld.Part1.Size.Z/2)	}):Play()	
				weld = newweld if not equipping then newweld:Destroy() end
			end
			task.desynchronize()
			specialmesh =specialmesh or FindFirstChildOfNameAndClass(handle, "MESH", "Model")
			loopprocessor[tool] = {Torso = Torso, MESH=specialmesh or nil}
			if not ongoing then	SETUPLOOP() end
		end)

		tool.Unequipped:Connect(function()
			equipping = false
			if weld then task.synchronize() weld:Destroy()end
			loopprocessor[tool] = nil
			if specialmesh then if specialmesh:FindFirstChild('Intersection') then task.synchronize() specialmesh.Intersection.Anchored = false end task.synchronize() specialmesh.Parent = handle end
		end)

		tool.Destroying:Once(function()
			loopprocessor[tool] = nil
		end)
	end
	local Event = FindFirstChildOfNameAndClass(game:GetService('ServerStorage'), 'Umbrella_Event','BindableEvent') or Instance.new('BindableEvent', game:GetService('ServerStorage'))
	Event.Name = 'Umbrella_Event'
	Event.Event:Connect(setupumbrella)
else script:Destroy() return end