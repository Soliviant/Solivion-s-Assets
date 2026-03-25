--By @Solivion; I doubt anybody would need this unless they want clothing support for custom R6 without Humanoid
local chr = script:FindFirstAncestorWhichIsA('Model')
if not chr then return end
local removeConT: RBXScriptConnection
local removeConShirt: RBXScriptConnection
local removeConPants: RBXScriptConnection
local listPant = {"Foot", 'Leg'} -- pants override the torso texture when there is no shirt
function Process(child)
	if typeof(child) ~= 'Instance' or not child:IsDescendantOf(chr) then return end
	if child.ClassName == 'Shirt' then
		if removeConShirt then	removeConShirt:Disconnect() end
		local tremoveConShirt = child.AncestryChanged:Connect(function()
			if child.Parent ~= chr then
				for i,v in chr:GetChildren() do
					local normalizedName = v.Name:gsub('Left', ''):gsub('Right', ''):gsub('Upper', ''):gsub('Lower', ''):gsub(" ", '')
					if v:IsA('BasePart') and normalizedName ~= '' and table.find({"Torso", 'Arm', 'Hand'},normalizedName) then
						if v:IsA('MeshPart') then
							--[[if not v:FindFirstChildOfClass('SurfaceAppearance') then
								Instance.new('SurfaceAppearance', v)
							end]]
							v.TextureID = (normalizedName == 'Torso' and chr:FindFirstChildOfClass('Pants') and chr:FindFirstChildOfClass('Pants').PantsTemplate) or ''
						else local suc = pcall(function() if not v:FindFirstChildOfClass('Decal') then Instance.new('Decal', v) end v:FindFirstChildOfClass('Decal').Texture = (normalizedName == 'Torso' and chr:FindFirstChildOfClass('Pants') and chr:FindFirstChildOfClass('Pants').PantsTemplate) or ''  end) if not suc and v:FindFirstChildOfClass('SpecialMesh') then v:FindFirstChildOfClass('SpecialMesh').TextureId = (normalizedName == 'Torso' and chr:FindFirstChildOfClass('Pants') and chr:FindFirstChildOfClass('Pants').PantsTemplate) or '' end end end
				end
				removeConShirt:Disconnect() removeConShirt = nil
			end
		end)removeConShirt = tremoveConShirt
		repeat task.wait() until (typeof(child.ShirtTemplate) == 'string' and child.ShirtTemplate:match('asset')) or tremoveConShirt ~= removeConShirt or not child.Parent
		for i,v in chr:GetChildren() do local normalizedName = v.Name:gsub('Left', ''):gsub('Right', ''):gsub('Upper', ''):gsub('Lower', ''):gsub(" ", '')
			if v:IsA('BasePart')  and normalizedName ~= '' and table.find({"Torso", 'Arm', 'Hand'},normalizedName) then
				if v:IsA('MeshPart') then
					--[[if not v:FindFirstChildOfClass('SurfaceAppearance') then
						Instance.new('SurfaceAppearance', v)
					end]]
					v.TextureID = child.ShirtTemplate
				else local suc = pcall(function() if not v:FindFirstChildOfClass('Decal') then Instance.new('Decal', v) end v:FindFirstChildOfClass('Decal').Texture = child.ShirtTemplate or ''  end) if not suc and  v:FindFirstChildOfClass('SpecialMesh') then  v:FindFirstChildOfClass('SpecialMesh').TextureId = child.ShirtTemplate end end end
		end
	elseif child.ClassName == 'Pants' then
		if removeConPants then	removeConPants:Disconnect() end
		local tremoveConPants = child.AncestryChanged:Connect(function()
			if child.Parent ~= chr then
				local thischeck = table.clone(listPant)
				if not chr:FindFirstChildOfClass('Shirt') then
					table.insert(thischeck, 'Torso')
				end
				for i,v in chr:GetChildren() do local normalizedName = v.Name:gsub('Left', ''):gsub('Right', ''):gsub('Upper', ''):gsub('Lower', ''):gsub(" ", '')

					if v:IsA('BasePart') and normalizedName ~= '' and table.find(thischeck,normalizedName) then
						if v:IsA('MeshPart') then
							--[[if not v:FindFirstChildOfClass('SurfaceAppearance') then
								Instance.new('SurfaceAppearance', v)
							end]]
							v.TextureID = ''
						else local suc = pcall(function() if not v:FindFirstChildOfClass('Decal') then Instance.new('Decal', v) end v:FindFirstChildOfClass('Decal').Texture = ''  end) if not suc and v:FindFirstChildOfClass('SpecialMesh') then v:FindFirstChildOfClass('SpecialMesh').TextureId = '' end end end
				end
				removeConPants:Disconnect() removeConPants = nil
			end
		end) removeConPants = tremoveConPants
		repeat task.wait() until (typeof(child.PantsTemplate) == 'string' and child.PantsTemplate:match('asset')) or removeConPants ~= tremoveConPants or not child.Parent
		local thischeck = table.clone(listPant)
		if not chr:FindFirstChildOfClass('Shirt') then
			table.insert(thischeck, 'Torso')
		end
		for i,v in chr:GetChildren() do
			local normalizedName = v.Name:gsub('Left', ''):gsub('Right', ''):gsub('Upper', ''):gsub('Lower', ''):gsub(" ", '')
			if v:IsA('BasePart') and normalizedName ~= '' and table.find(thischeck,normalizedName) then
				if v:IsA('MeshPart') then
					--[[if not v:FindFirstChildOfClass('SurfaceAppearance') then
						Instance.new('SurfaceAppearance', v)
					end]]
					v.TextureID =  child.PantsTemplate
				else local suc = pcall(function() if not v:FindFirstChildOfClass('Decal') then Instance.new('Decal', v) end v:FindFirstChildOfClass('Decal').Texture = child.PantsTemplate or ''  end) if not suc and v:FindFirstChildOfClass('SpecialMesh') then v:FindFirstChildOfClass('SpecialMesh').TextureId = child.PantsTemplate end end end
		end
	elseif child.ClassName == 'BodyColors' then
		for i,v in chr:GetChildren() do
			local normalizedName = v.Name:gsub('Upper', ''):gsub('Lower', ''):gsub(" ", '')
			if v:IsA('BasePart') and normalizedName ~= '' then
				pcall(function()
					if v.Name:match('Left') then
						if v.Name:match('Leg') then
							v.Color = child.LeftLegColor3
						elseif v.Name:match('Arm') then
							v.Color = child.LeftArmColor3
						end
					elseif v.Name:match('Right') then
						if v.Name:match('Leg') then
							v.Color = child.RightLegColor3
						elseif v.Name:match('Arm') then
							v.Color = child.RightArmColor3
						end
					elseif v.Name:match('Torso') then
						v.Color = child.TorsoColor3
elseif v.Name:match('Head') then
						v.Color = child.HeadColor3

					end end)
			end
		end
	elseif child.ClassName == 'ShirtGraphic' then
		local Torso = chr:FindFirstChild('Torso') or chr:FindFirstChild('UpperTorso')
		if Torso then
			if not Torso:FindFirstChildOfClass('Decal') then
				Instance.new('Decal', Torso)
			end
			if removeConT then
				removeConT:Disconnect() removeConT = nil
			end
			local tremoveConT = child.AncestryChanged:Connect(function()
				if child.Parent ~= chr then
					if Torso:FindFirstChildOfClass('Decal') then
						local anotherT = chr:FindFirstChildOfClass('ShirtGraphic')
						Torso:FindFirstChildOfClass('Decal').Color3 = anotherT and anotherT.Color3 or Color3.new(1,1,1)
						Torso:FindFirstChildOfClass('Decal').ColorMap = anotherT and anotherT.Graphic or ''
					end
					removeConT:Disconnect() removeConT = nil
				end
			end) removeConT = tremoveConT
			repeat task.wait() until (typeof(child.Graphic) == 'string' and child.Graphic:match('asset')) or removeConT ~= tremoveConT or not child.Parent
			pcall(function() Torso:FindFirstChildOfClass('Decal').ColorMap = child.Graphic end) pcall(function() Torso:FindFirstChildOfClass('Decal').Color3 = child.Color3 end)
		end
	end
end
for i, v in chr:GetChildren() do
	Process(v)
end
chr.ChildAdded:Connect(Process)