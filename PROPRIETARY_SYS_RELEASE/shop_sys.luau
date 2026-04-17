--Properties that should be in Table for every registered shop, too lazy to just move the variable to make it OOP
local reloading = false
local Healing = 30
local HealingTime = 2.5
local canheal = true
local Mag = 7
local FullMag = 7
local AllBusy = false
local weaponcooldown = false -- need to add to clerk table
local rate = 1/30
local lasttense = false
local ChosenClerk
--Private?
local function getServerType()
	if game.PrivateServerId ~= "" or game:FindFirstChildOfClass("RunService"):IsStudio() then
		if game.PrivateServerOwnerId ~= 0 or game:FindFirstChildOfClass("RunService"):IsStudio()  then
			return "VIPServer"
		else
			return "ReservedServer"
		end
	else
		return "StandardServer"
	end
end
--TODO: Make Clerk Use Table To Actually Store Thing
-- Add Anim
--Make Clerk Heal Themselves. And Dies If Health Hits 0
--local SoundLib = {["GunShot"] = {"3742264505"}}
local SoundLib = {
	LedgeGrab = {"7850652207" -- Flashlight
	},
	ClimbingUp = {
		"138084889"
	},
	HumHit = {
		"4529474217"
	}
}
local sound = function(loud:number,whichcate:string,where:Instance)
	if SoundLib[whichcate] then
		local sounloca = SoundLib[whichcate]
		local all = {}
		for key, _ in pairs(sounloca) do
			table.insert(all, key)
		end
		local chosensound = sounloca[all[math.random(1, #all)]]
		if chosensound then
			local ThisIns = Instance.new("Sound",where)
			ThisIns.Volume = loud
			ThisIns.Name = whichcate
			ThisIns.SoundId = "rbxassetid://"..chosensound
			ThisIns:Play()
			game:FindFirstChildOfClass('Debris'):AddItem(ThisIns,math.clamp(ThisIns.TimeLength,1,10))
		end
	end
end
local weapontype = {["Glock"] = "Gun"}
local function look(looker,Target, dt)
	task.desynchronize()
	if not Target then
		Target = CFrame.new()
	end
	if looker == nil or (looker and not looker.PrimaryPart) then
		return
	end
	if not Target then return end
	if Target and typeof(Target) == 'Instance' and Target:IsA('Model') then
		Target = Target.PrimaryPart and Target.PrimaryPart.Position or Target:GetPivot().Position
	elseif Target and typeof(Target) == 'Instance' and Target:IsA('BasePart') then
		Target = Target.Position
	elseif Target and (typeof(Target) == 'CFrame') then
		Target = Target.Position
	end
	if looker and looker.PrimaryPart ~= nil then
		local factor = dt and (1 - ((10 ^ -6) ^ dt)) or .3
		local lockedin = CFrame.new(looker.PrimaryPart.Position, Vector3.new(Target.x,looker.PrimaryPart.Position.y,Target.z))
		local lookerPrimaryPartCFrame = looker.PrimaryPart.CFrame.LookVector:Dot(lockedin.LookVector) < .9 and looker.PrimaryPart.CFrame:Lerp(lockedin,factor or 0.3) or lockedin
		if looker.PrimaryPart.CFrame.LookVector:Dot(lookerPrimaryPartCFrame.LookVector) < math.min(factor * 4,.95) then
			task.synchronize()
			looker.PrimaryPart.CFrame = lookerPrimaryPartCFrame
			task.desynchronize()
			if lockedin.LookVector:Dot(lookerPrimaryPartCFrame.LookVector) >= .975 then return true end
		end
	end
end
local function HandAim(Looker,Weld,TargetCFrame, dt)
	local tr = Looker:FindFirstChild("UpperTorso") or Looker:FindFirstChild("Torso") or Looker:FindFirstChild("HumanoidRootPart")
	if tr == nil then
		return
	end
	task.desynchronize()
	local speed = dt and (1 - (10^-6) ^dt) or 0.3
	local tframe = tr.CFrame or CFrame.new(0,0,0)
	tframe = tframe + tframe:VectorToWorldSpace(Vector3.new(1.5, 0.5, -0.5))
	local taim = ((TargetCFrame and TargetCFrame.p) or Vector3.new(0,0,0)) -( tframe.Position )
	local Where
	if TargetCFrame == nil then
		Where = CFrame.new(1.5, 0.5, -0.5) * CFrame.Angles(math.rad(0),math.rad(0),math.rad(0))
	--[[else
		if not script.Parent.Parent.Torso then
			return
		end
		local tframe = script.Parent.Parent.Torso.CFrame
		tframe = tframe + tframe:vectorToWorldSpace(Vector3.new(1.5, 0.5, -0.5))
		local taim = mousetarget.Position -( tframe.Position )
		Where = (CFrame.new(Vector3.new(),tframe:vectorToObjectSpace(taim))*CFrame.Angles(math.rad(-90),math.rad(90),math.rad(-90)))+Vector3.new( 1.5, 0.5, 0.5 )]]
	else
		Where =  CFrame.new(Vector3.new(),tframe:VectorToObjectSpace(taim))*CFrame.Angles(math.rad(-90),math.rad(180),math.rad(180))+Vector3.new( 1.5, 0.5, -0.5 )	
	end
	local nweld = Looker:FindFirstChildOfClass("Weld")
	if nweld then
		local nweldC0 = nweld.C0
		local NewAttachmentWeld = nweld
		if not TargetCFrame then
			nweldC0 = nweld.C0:Lerp(CFrame.new(1.5, 0, 0) * CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),speed/3)
		else
			Where = Where.Rotation * CFrame.new(math.clamp(Where.X,-2,2),math.clamp(Where.Y,-2,2),math.clamp(Where.Z,-2,2))
			nweldC0 = nweld.C0:Lerp(Where,speed)
			--local Meh = (hand.CFrame.Position - TargetCFrame.Position).Magnitude
			--local Offseter:CFrame = CFrame.new(math.clamp((-Meh + 0.0625 * 20) * C1X, -1, 1),math.clamp(Meh,-2,2),math.clamp(Meh,-0.5,0.5))
			----[[if Looker:FindFirstChild("Torso") and Looker:FindFirstChild("Torso"):FindFirstChild("BodyFrontAttachment") and Looker:FindFirstChild("Torso"):FindFirstChild("BodyBackAttachment")  then
			--	if (Looker:FindFirstChild("Torso"):FindFirstChild("BodyFrontAttachment").Position - TargetCFrame.Position).Magnitude > (Looker:FindFirstChild("Torso"):FindFirstChild("BodyBackAttachment").Position - TargetCFrame.Position).Magnitude or IsBehind(Looker:FindFirstChild("Torso"),TargetCFrame) --[[or (Looker:FindFirstChild("Torso"):FindFirstChild(CurHandName.."CollarAttachment").Position - TargetCFrame.Position).Magnitude < (Looker:FindFirstChild("Torso"):FindFirstChild(OppoHandName.."CollarAttachment").Position - TargetCFrame.Position).Magnitude]] or Offseter == CFrame.new(-1, 2, 0.5) or Offseter == CFrame.new(1, 2, 0.5) then
			--		-- Inverted Formula, In This Case The Hand Is Bent Backward
			--		nweld:SetAttribute("Formula","Inverted")
			--		Offseter = CFrame.new(math.clamp((-Meh - 0.0625 * 20) * (-C2 + (-C2 * 0.5)), -2, 2),math.clamp(Meh,-2,2),-math.clamp(Meh,-0.5,0.5))
			--	else-- Normal Formula
			--		nweld:SetAttribute("Formula","Normal")
			--		Offseter = CFrame.new(math.clamp((-Meh + 0.0625 * 20) * C1X, -1, 1),math.clamp(Meh,-2,2),math.clamp(Meh,-0.5,0.5))
			--	end
			--else
			--	-- Attachment Not Found
			--	nweld:SetAttribute("Formula","Normal")
			--	Offseter = CFrame.new(math.clamp((-Meh + 0.0625 * 20) * C1X, -1, 1),math.clamp(Meh,-2,2),math.clamp(Meh,-0.5,0.5))
			--end]]
			--nweld.C1 = nweld.C1:Lerp(Offseter,0.45)
		end
		task.synchronize()
		nweld.C0 = nweldC0
	else task.synchronize()
		local NewHandWeld = Weld or Instance.new("Weld",Looker)
		NewHandWeld.Name = "Hand Door"
		NewHandWeld.Enabled = true
		nweld = NewHandWeld
		local hand
		local Torso
		if not Torso then Torso = Looker:FindFirstChild('Torso') end
		if not hand then hand = Looker:FindFirstChild('Right Arm') end
		local NewHandWeldC0 = NewHandWeld.C0
		local NewHandWeldC1 = NewHandWeld.C1
		if hand:IsDescendantOf(Looker) then
			NewHandWeld.Part1 = hand
		end
		if Looker:FindFirstChild("Torso") or Looker:FindFirstChild("UpperTorso") then
			NewHandWeld.Part0 = Looker:FindFirstChild("Torso") or Looker:FindFirstChild("UpperTorso")
		end task.desynchronize()
			NewHandWeldC0 = NewHandWeld.C0:Lerp(CFrame.new(1.5, 0, 0) * CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),0.6) 
			NewHandWeldC1 = NewHandWeld.C1:Lerp(CFrame.new(0,0,0),0.6)
			--	NewHandWeld.C0 = NewHandWeld.C0:Lerp(CFrame.new(1.5, 0, 0) * CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),0.1)
		task.synchronize()
		NewHandWeld.C1 = NewHandWeldC1
		NewHandWeld.C0 = NewHandWeldC0
	end
end
EffectInstance = {}
TweenService= game:FindFirstChildOfClass('TweenService')
Debris = game:FindFirstChildOfClass('Debris')
--<<Gun System(Feat GPT. For Some Lazy Trail Effect)>>--
local function CreateBulletTrail(startPos, endPos, bulletColor, extend)
	local bulletTrail = Instance.new("Part")
	bulletTrail.Material = Enum.Material.Neon
	bulletTrail.Size = Vector3.new(0.1, 0.1, (startPos - endPos).magnitude)
	bulletTrail.CFrame = CFrame.new(startPos, endPos) * CFrame.new(0, 0, -bulletTrail.Size.Z / 2)
	bulletTrail.Color = bulletColor
	bulletTrail.Anchored = true
	bulletTrail.CanCollide = false
	bulletTrail.Parent = workspace
	TweenService:Create(bulletTrail, TweenInfo.new(0.49), {Color = Color3.new(0,0,0), Transparency = 1, Size = extend and Vector3.new(0.1, 0.1, (startPos - endPos).magnitude * 1.2) or Vector3.new(0.1, 0.1, 0)}):Play()
	table.insert(EffectInstance, bulletTrail)
	task.delay(0.49, function() if table.find(EffectInstance, bulletTrail) then table.remove(EffectInstance, table.find(EffectInstance, bulletTrail)) end end)
	Debris:AddItem(bulletTrail, 0.5)
	return bulletTrail
end

local function CreateBulletHole(hitPosition, hitNormal)
	local bulletHole = Instance.new("Part")
	bulletHole.Size = Vector3.new(0.2, 0.2, 0.01)
	bulletHole.Anchored = true
	bulletHole.CFrame = CFrame.new(hitPosition, hitPosition + hitNormal) * CFrame.new(0, 0, -bulletHole.Size.Z / 2)
	bulletHole.CanCollide = false
	bulletHole.Color = Color3.new(0, 0, 0)
	bulletHole.Parent = workspace
	TweenService:Create(bulletHole, TweenInfo.new(9.9), {Transparency = 1}):Play()
	task.delay(9.9, function() if table.find(EffectInstance, bulletHole) then table.remove(EffectInstance, table.find(EffectInstance, bulletHole)) end end)
	Debris:AddItem(bulletHole, 10)
	return bulletHole
end

local weaponexecute = {
	["Gun"] = function(Shooter,Weapon,Target)
		task.synchronize()
		coroutine.resume( coroutine.create(function() 
			--Running
			if Weapon.Parent and Weapon.Parent:IsA('Tool') then
				Weapon = Weapon.Parent
			end
			local param = RaycastParams.new()
			param.FilterDescendantsInstances = EffectInstance param:AddToFilter({Shooter, Weapon})
			param.FilterType = Enum.RaycastFilterType.Exclude
			param.RespectCanCollide = true
			if not Target:FindFirstChildOfClass("Humanoid") or (Target:FindFirstChildOfClass("Humanoid") and Target:FindFirstChildOfClass("Humanoid"):GetState() == Enum.HumanoidStateType.Dead ) then
				if Shooter:FindFirstChild("Weapon_Keep") then
					Shooter:FindFirstChild("Weapon_Keep").Transparency = 0
				end
				if Weapon:FindFirstChild("Weapon_Mesh") then
					Weapon:FindFirstChild("Weapon_Mesh").Transparency = 1
				end
				return
			end
			if Shooter:FindFirstChild("Weapon_Keep") then
				Shooter:FindFirstChild("Weapon_Keep").Transparency = 1
			end
			if Weapon:FindFirstChild("Weapon_Mesh") then
				Weapon:FindFirstChild("Weapon_Mesh").Transparency = 0
			end
			--Shooter.PrimaryPart.CFrame = Shooter.PrimaryPart.CFrame:lerp(CFrame.new( CFrame.new(Shooter.PrimaryPart.CFrame.Position, Target.PrimaryPart.CFrame.Position).X, CFrame.new(Shooter.PrimaryPart.CFrame.Position, Target.PrimaryPart.CFrame.Position).Y,CFrame.new(Shooter.PrimaryPart.CFrame.Position, Target.PrimaryPart.CFrame.Position).Z) * CFrame.Angles(CFrame.new(Shooter.PrimaryPart.CFrame.Position, Target.PrimaryPart.CFrame.Position).Rotation.X,0,CFrame.new(Shooter.PrimaryPart.CFrame.Position, Target.PrimaryPart.CFrame.Position).Rotation.Z),0.3)--o Shooter.PrimaryPart.CFrame 
			--Shooter.PrimaryPart.CFrame = Shooter.PrimaryPart.CFrame * (Shooter.PrimaryPart.CFrame.Position - Target.PrimaryPart.CFrame.Position)
			if Target and Target:FindFirstChildOfClass("Humanoid") and not weaponcooldown then
				
				
				--if Target:FindFirstChildOfClass("Humanoid").Health > 20 then
					weaponcooldown = true
				sound(0.5,"LedgeGrab",Shooter.PrimaryPart)
				--sound(1,"GunShot",Weapon:FindFirstChildOfClass("BasePart"))
				Mag = math.clamp(Mag - 1,0,7)
				local start = (Weapon:FindFirstChild('Dispenser') and Weapon:FindFirstChild('Dispenser').Position) or Weapon:GetPivot().Position
				local dir = (Target:GetPivot().Position - start).Unit * 100
				local ray = workspace:Raycast(start, dir, param)
				local result = ray
				local hole
				local success, aerror = pcall(function()
					if ray and ray.Instance then
						if ray.Instance:FindFirstAncestorWhichIsA('Model') and ray.Instance:FindFirstAncestorWhichIsA('Model'):FindFirstChildOfClass('Humanoid') then
							Target = ray.Instance:FindFirstAncestorWhichIsA('Model')
						end
						Target:FindFirstChildOfClass("Humanoid").Health = Target:FindFirstChildOfClass("Humanoid").Health - math.random(10,17)
						--Target:FindFirstChildOfClass("Humanoid"):ChangeState(Enum.HumanoidStateType.Dead)
						hole = CreateBulletHole(ray.Position, ray.Normal)
						CreateBulletTrail(start, ray.Position, Color3.new(1,1,1), Vector3.new())
					else
						CreateBulletTrail(start, start + dir, Color3.new(1,1,1), Vector3.new())
					end
					hole = false
					if hole then
						if result and result.Instance:IsA('BasePart') then
							local bullet = {Damage = math.random(1000,1700), Type = 'Bullet'}
							if not result.Instance:IsDescendantOf(Shooter) and result.Instance:FindFirstAncestorWhichIsA('Model') and result.Instance:FindFirstAncestorWhichIsA('Model'):FindFirstChildOfClass('Humanoid') and result.Instance:FindFirstAncestorWhichIsA('Model'):FindFirstChildOfClass('Humanoid').Health > 0 and result.Instance:FindFirstAncestorWhichIsA('Model'):FindFirstChildOfClass('Humanoid').Health == result.Instance:FindFirstAncestorWhichIsA('Model'):FindFirstChildOfClass('Humanoid').Health then
								local humanoid = result.Instance:FindFirstAncestorWhichIsA('Model'):FindFirstChildOfClass('Humanoid')
								humanoid.Health = humanoid.Health - humanoid.MaxHealth * (typeof(bullet) == 'table' and bullet.Damage or 500) / 100
								if result.Instance.Name:upper():match('LEG') or result.Instance.Name:upper():match('FOOT') then
									humanoid.Health = humanoid.Health - humanoid.MaxHealth * (typeof(bullet) == 'table' and bullet.Damage or 500) / 150
									humanoid.Sit = true
								end
								if result.Instance.Name:upper():match('HEAD') then
									humanoid.Health = humanoid.Health - humanoid.MaxHealth * (typeof(bullet) == 'table' and bullet.Damage or 1000) / 25
								end
								sound('HumHit', hole)
							end
							if result.Material == Enum.Material.Glass or result.Material == Enum.Material.Ice then
								result.Instance.Anchored = false
							end
							if result.Instance.Anchored == false then
								result.Instance.AssemblyLinearVelocity = result.Instance.AssemblyLinearVelocity + dir * 100
							end
							local weld = Instance.new('Weld', hole)
							weld.C0 = result.Instance.CFrame:ToObjectSpace(hole.CFrame)
							hole.Anchored = false
							hole.Parent = result.Instance
							weld.Part1 = hole
							weld.Part0 = result.Instance
						else
							hole.Anchored = true
						end
					end
				end)
				if not success then
					warn(aerror)
				end
				if Mag > 0 then
					task.wait(0.5)
				else
					reloading = true
					sound(1,"ClimbingUp",Shooter.PrimaryPart)
					task.wait(2)
					Mag = 7
					reloading = false
				end
				
					weaponcooldown = false
				--end
				
			end
		end))
	end,
}
local EasyTween = function(itemtotween,property,value,tweentime,easingstyle,easingdirection)
	local info = TweenInfo.new(tweentime,easingstyle and Enum.EasingStyle[easingstyle] or Enum.EasingStyle.Linear,easingdirection and Enum.EasingDirection[easingdirection] or Enum.EasingDirection.InOut,0,false,0)
	local goal = {}
	goal[property] = value
	return game:FindFirstChildOfClass("TweenService"):Create(itemtotween,info,goal)
end
local KickOut = function(Clerk,Target)
	if (Clerk:FindFirstChildOfClass("Humanoid") and Clerk:FindFirstChildOfClass("Humanoid").Health > Clerk:FindFirstChildOfClass("Humanoid").MaxHealth/2) or not canheal then
		if not Clerk:FindFirstChildOfClass('Tool') then
			return
		else
			if weapontype[ Clerk:FindFirstChildOfClass('Tool').Name] then
				if weaponexecute[weapontype[ Clerk:FindFirstChildOfClass('Tool').Name]] then
					weaponexecute[weapontype[ Clerk:FindFirstChildOfClass('Tool').Name]](Clerk,Clerk:FindFirstChildOfClass('Tool'),Target)
				end
			end
		end
	elseif (Clerk:FindFirstChildOfClass("Humanoid") and Clerk:FindFirstChildOfClass("Humanoid").Health <= Clerk:FindFirstChildOfClass("Humanoid").MaxHealth/3) and canheal then
		if not canheal then
			return
		else
			canheal = false
		end
		Clerk:FindFirstChildOfClass("Humanoid").Health = Clerk:FindFirstChildOfClass("Humanoid").Health + (Clerk:FindFirstChildOfClass("Humanoid").MaxHealth/100) * Healing
		task.delay(HealingTime, function()
		canheal = true end)
	end
end
local function from_part(part)
	local pos, half_size = part.Position, part.Size/2
	return Region3.new(pos - half_size, pos + half_size)
end
function KeyUsed(Key:Enum.KeyCode, Dir: Instance)
	task.desynchronize()
	for i,v in Dir:GetChildren() do
		if v:IsA("ProximityPrompt") then
			if v.KeyboardKeyCode == Key then
				task.synchronize() return true
			end
		end
	end 
	task.synchronize()return false
end
local standard = getServerType() == "StandardServer"
task.wait(.5)
--if workspace:FindFirstChild('Fun') and workspace:FindFirstChild('Fun').Value == 875 and math.random() > .5 then return end
for i,Workspace_Children in workspace:GetChildren() do
	if string.match(Workspace_Children.Name,"Shop_") then
		if standard then Workspace_Children:Destroy() end
		local Threat = {}
		local ThreatWarned = {}
		local ChosenClerkNonWeap = {}
		local Cooldown = {}
		local RegisteredClerk = {}
		local Param = OverlapParams.new()
		Param.FilterType = Enum.RaycastFilterType.Exclude
		Param.RespectCanCollide = true
		Param.FilterDescendantsInstances = {Workspace_Children, workspace.Map}
		--print("Found Shop >>"..Workspace_Children:GetFullName())
		if Workspace_Children:FindFirstChild("a") then
			local DownIndices = 0
			local UpIndices = 0
			local CurrentOffset = Vector2.new(0,0)
			local CurrentShopsDownwardList = {}
			local CurrentShopsUpwardList = {}
			local CurrentOffsetUsed = 1 or 2
			local RemoveFunction = {}
			local USEDKEY = {}
			local KEY = {Enum.KeyCode.B,Enum.KeyCode.C,Enum.KeyCode.E,Enum.KeyCode.F,Enum.KeyCode.G,Enum.KeyCode.H,Enum.KeyCode.I,Enum.KeyCode.J,Enum.KeyCode.K,Enum.KeyCode.L,Enum.KeyCode.M,Enum.KeyCode.N,Enum.KeyCode.O,Enum.KeyCode.P,Enum.KeyCode.Q,Enum.KeyCode.R,Enum.KeyCode.T,Enum.KeyCode.U,Enum.KeyCode.V,Enum.KeyCode.X,Enum.KeyCode.Y,Enum.KeyCode.Z}
			--print("Found Clerk >>"..Workspace_Children:FindFirstChild("a"):GetFullName())
			-- Protect The Shop
			if not table.find(RegisteredClerk, Workspace_Children:FindFirstChild("a")) then
				table.insert(RegisteredClerk, Workspace_Children:FindFirstChild("a"))
				--print(RegisteredClerk)
				if game:FindFirstChildOfClass('ServerStorage'):FindFirstChild(Workspace_Children.Name.."_Item") then
					local Active = false
					local queue = {}
					function list(v)
						if not RegisteredClerk or not Workspace_Children or not Workspace_Children:FindFirstChild("a") or not Workspace_Children:FindFirstChild("a").PrimaryPart then return end
						task.wait()
						table.insert(queue, v)
						repeat wait(.1) until not Active and queue[1] == v
						Active = true
						if v:IsA("Tool") and not Workspace_Children:FindFirstChild("a").PrimaryPart:FindFirstChild(v.Name.." Prompt") and not Workspace_Children:FindFirstChild("a").PrimaryPart:FindFirstChild(v.Name.."_Prompt") then
							if CurrentOffsetUsed == 1 then
								CurrentOffsetUsed = 2
							else
								CurrentOffsetUsed = 1
							end
							if Workspace_Children:FindFirstChild("a").PrimaryPart:FindFirstChildOfClass("ProximityPrompt") then
								if CurrentOffsetUsed == 1 then
									DownIndices = DownIndices + 1
								else
									UpIndices = UpIndices + 1
								end
							end
							local NewInteraction = Instance.new("ProximityPrompt",Workspace_Children:FindFirstChild("a").PrimaryPart)
							NewInteraction.RequiresLineOfSight = false
							NewInteraction.ActionText = "Buy Item"
							local ChosenKey = math.random(1,#KEY)
							local daKEY = KEY[ChosenKey]
							task.desynchronize()
							local suc,key
							local done = false
							if  KeyUsed(daKEY,Workspace_Children:FindFirstChild("a").PrimaryPart) then
								coroutine.resume(coroutine.create(function() task.wait(10) done = true end))
								while task.wait(rate) and not suc and not done do
									task.desynchronize()
									if done or key then break end
									local suc, thenewkey = pcall(function()
										ChosenKey = math.random(1,#KEY)
										if not table.find(USEDKEY, KEY[ChosenKey]) and not KeyUsed(KEY[ChosenKey],Workspace_Children:FindFirstChild("a").PrimaryPart) then
											task.synchronize() key = KEY[ChosenKey] return KEY[ChosenKey]
										end
									end)
									key = thenewkey
								end
							else
								suc = true key = daKEY
							end
							
							task.synchronize()
							local removed = false
							if not key then
								for i,v in KEY do
									if not KeyUsed(v,Workspace_Children:FindFirstChild("a").PrimaryPart) then
										key = v break
									end
								end
							end
							NewInteraction.KeyboardKeyCode = key or Enum.KeyCode.V
							if not table.find(USEDKEY, KEY[ChosenKey]) then
								table.insert(USEDKEY,NewInteraction.KeyboardKeyCode)
							end
							if --[[table.find(KEY,key)]] KEY[ChosenKey] then
								KEY[ChosenKey] = nil
							end
							NewInteraction.Name = v.Name.."_Prompt"
							NewInteraction.ObjectText = v.Name
							if not NewInteraction then repeat task.wait() if NewInteraction then break end until NewInteraction end
							if CurrentOffsetUsed == 1 then
								local off = CurrentOffset + Vector2.new(0,-75 * DownIndices) 
								if NewInteraction.Parent ~= nil then
									EasyTween(NewInteraction,"UIOffset",off ,1,"Circular","InOut"):Play()
									coroutine.resume(coroutine.create(function()
										task.wait(1)	
										NewInteraction.UIOffset = off
									end))
								else
									NewInteraction.UIOffset = off
								end
								
								CurrentShopsDownwardList[NewInteraction] = {Offset = CurrentOffset + Vector2.new(0,-75 * DownIndices), Indices = DownIndices }
							else
								local off = CurrentOffset + Vector2.new(0,75 * UpIndices) 
								if NewInteraction.Parent ~= nil then
									EasyTween(NewInteraction,"UIOffset",off ,1,"Circular","InOut"):Play()
									coroutine.resume(coroutine.create(function()
										task.wait(1)	
										NewInteraction.UIOffset = off
									end))
								else
									NewInteraction.UIOffset = off
								end
								CurrentShopsUpwardList[NewInteraction] = {Offset = CurrentOffset + Vector2.new(0,75 * UpIndices), Indices = UpIndices }
							end
							local remove = function()
								if removed or (game:FindFirstChildOfClass('ServerStorage') and game:FindFirstChildOfClass('ServerStorage'):FindFirstChild(Workspace_Children.Name.."_Item") and game:FindFirstChildOfClass('ServerStorage'):FindFirstChild(Workspace_Children.Name.."_Item"):FindFirstChild(NewInteraction.ObjectText)) then return end
								removed = true
								if CurrentShopsUpwardList[NewInteraction]  then
									for i,v in pairs(CurrentShopsUpwardList) do
										if v.Indices > CurrentShopsUpwardList[NewInteraction].Indices then
											v.Indices = v.Indices - 1
											v.Offset = CurrentOffset + Vector2.new(0,75 * v.Indices)
											EasyTween(i,"UIOffset",v.Offset,1,"Sine","InOut"):Play()
											coroutine.resume(coroutine.create(function()
												task.wait(1)	
												i.UIOffset = v.Offset
											end))
										end
									end
									UpIndices = UpIndices - 1	
									CurrentShopsUpwardList[NewInteraction] = nil	
								else
									for i,v in pairs(CurrentShopsDownwardList) do
										if v.Indices > CurrentShopsDownwardList[NewInteraction].Indices then
											v.Indices = v.Indices - 1
											v.Offset = CurrentOffset + Vector2.new(0,-75 * v.Indices)
											EasyTween(i,"UIOffset",v.Offset,1,"Sine","InOut"):Play()
											coroutine.resume(coroutine.create(function()
												task.wait(1)	
												i.UIOffset = v.Offset
											end))	
										end
									end
									DownIndices = DownIndices - 1
									CurrentShopsDownwardList[NewInteraction] = nil	
								end
								if table.find(USEDKEY,NewInteraction.KeyboardKeyCode) then
									table.insert(KEY,NewInteraction.KeyboardKeyCode)
									table.remove(USEDKEY, table.find(USEDKEY,NewInteraction.KeyboardKeyCode))
								end
								RemoveFunction[NewInteraction] = nil
								NewInteraction:Destroy()	
								game:FindFirstChildOfClass("ServerScriptService")["BUBBLECHAT!"].Event:Fire(Workspace_Children:FindFirstChild("a") and (Workspace_Children:FindFirstChild("a"):FindFirstChild("Head") or Workspace_Children:FindFirstChild("a")) or workspace.BOUND,"Sorry, We Are Out Of >>"..NewInteraction.ObjectText.."<<.",Enum.ChatColor.Red)	
							end
							RemoveFunction[NewInteraction] = remove
							NewInteraction.Triggered:Connect(function(who)
								if not who or not who.Character or who.Character:GetAttribute('IsRagdoll') or (who.Character.PrimaryPart and (who.Character.PrimaryPart.Position - Vector3.new(23.784, 5.555, -72.281)).Magnitude > 20) or not Workspace_Children:FindFirstChild("a") or not Workspace_Children:FindFirstChild("a"):FindFirstChildOfClass('Humanoid')   then return end
							if not Threat[who.Character] then	
								if AllBusy == false then
									if who.Character and game:FindFirstChildOfClass('ServerStorage'):FindFirstChild(Workspace_Children.Name.."_Item") and game:FindFirstChildOfClass('ServerStorage'):FindFirstChild(Workspace_Children.Name.."_Item"):FindFirstChild(NewInteraction.ObjectText) and not who.Backpack:FindFirstChild(v.Name) and not who.Character:FindFirstChild(v.Name) then
										if getServerType() == "StandardServer" and who.Name ~= "Solivion" then
											Threat[who.Character] = (Threat[who.Character] or 0) + 50
											game:FindFirstChildOfClass("ServerScriptService")["BUBBLECHAT!"].Event:Fire(Workspace_Children:FindFirstChild("a") and (Workspace_Children:FindFirstChild("a"):FindFirstChild("Head") or Workspace_Children:FindFirstChild("a")) or workspace.BOUND,"Sorry, You Need To Be In A Private Server.",Enum.ChatColor.Red)
											task.wait(1)
											game:FindFirstChildOfClass("ServerScriptService")["BUBBLECHAT!"].Event:Fire(Workspace_Children:FindFirstChild("a") and (Workspace_Children:FindFirstChild("a"):FindFirstChild("Head") or Workspace_Children:FindFirstChild("a")) or workspace.BOUND,"You Can Make One For Free.",Enum.ChatColor.Red)
											return
									--[[	elseif game:FindFirstChildOfClass("BadgeService"):UserHasBadgeAsync(who.UserId, 753112426002159) ~= (true or false) then
											game:FindFirstChildOfClass("ServerScriptService")["BUBBLECHAT!"].Event:Fire(Workspace_Children:FindFirstChild("a") and (Workspace_Children:FindFirstChild("a"):FindFirstChild("Head") or Workspace_Children:FindFirstChild("a")) or workspace.BOUND,"Too Many Request!",Enum.ChatColor.Red)
											return]]
											end
											pcall(function()
												if game:FindFirstChildOfClass("BadgeService"):UserHasBadgeAsync(who.UserId,48758500306611)	== false then
													if game:FindFirstChildOfClass("ServerStorage"):FindFirstChild("BadgeInvoke") then
														game:FindFirstChildOfClass("ServerStorage"):FindFirstChild("BadgeInvoke"):Fire(who,48758500306611,"Yippe")
														--game:FindFirstChildOfClass("ServerStorage"):FindFirstChild("BadgeInvoke"):Fire(game:FindFirstChildOfClass("Players"):GetPlayerFromCharacter(p:FindFirstAncestorWhichIsA("Model")),753112426002159,"RequestPopUp")
													end	
												end
											end)
										-- Condition Is Met, True. Process	
										if who.Backpack:FindFirstChild(v.Name) or who.Character:FindFirstChild(v.Name)  then
											return
										end	
										local tool = game:FindFirstChildOfClass('ServerStorage'):FindFirstChild(Workspace_Children.Name.."_Item"):FindFirstChild(NewInteraction.ObjectText)
										if not tool then
											return
										end
										if who.Backpack:FindFirstChild(v.Name) or who.Character:FindFirstChild(v.Name)  then
											return
										end	
										tool.Parent = who.Character
										if who.Backpack:FindFirstChild(v.Name)  then
											task.wait()
											tool.Parent = game:FindFirstChildOfClass('ServerStorage'):FindFirstChild(Workspace_Children.Name.."_Item")
											return
										end	
										if who.Character:FindFirstChildOfClass("Humanoid") then
											who.Character:FindFirstChildOfClass("Humanoid"):EquipTool(tool)
										end
										if not game:FindFirstChildOfClass('ServerStorage'):FindFirstChild(Workspace_Children.Name.."_Item"):FindFirstChild(NewInteraction.ObjectText) then
											NewInteraction.ActionText = "B?u?y? ?I?t?e?m?"
											--NewInteraction.ObjectText = "Out_Of_Stock"
										end
										tool.Enabled = true
										game:FindFirstChildOfClass("ServerScriptService")["BUBBLECHAT!"].Event:Fire(Workspace_Children:FindFirstChild("a") and (Workspace_Children:FindFirstChild("a"):FindFirstChild("Head") or Workspace_Children:FindFirstChild("a")) or workspace.BOUND,"Here You Go.",Enum.ChatColor.White)
									else
										if Workspace_Children:FindFirstChild("a") and Workspace_Children:FindFirstChild("a"):FindFirstChild("Head") then
											if game:FindFirstChildOfClass('ServerStorage') and game:FindFirstChildOfClass('ServerStorage'):FindFirstChild(Workspace_Children.Name.."_Item") and game:FindFirstChildOfClass('ServerStorage'):FindFirstChild(Workspace_Children.Name.."_Item"):FindFirstChild(NewInteraction.ObjectText) then
												game:FindFirstChildOfClass("ServerScriptService")["BUBBLECHAT!"].Event:Fire(Workspace_Children:FindFirstChild("a") and (Workspace_Children:FindFirstChild("a"):FindFirstChild("Head") or Workspace_Children:FindFirstChild("a")) or workspace.BOUND,"Sorry, We Can't Sell You Any Extra >>"..NewInteraction.ObjectText.."<<.",Enum.ChatColor.Red)	
											else
												remove()
											end
										end
									end
								else
										game:FindFirstChildOfClass("ServerScriptService")["BUBBLECHAT!"].Event:Fire(Workspace_Children:FindFirstChild("a") and (Workspace_Children:FindFirstChild("a"):FindFirstChild("Head") or Workspace_Children:FindFirstChild("a")) or workspace.BOUND,"Sorry, We Can't Currently Provide Our Service.",Enum.ChatColor.Red)
								end
							else
									game:FindFirstChildOfClass("ServerScriptService")["BUBBLECHAT!"].Event:Fire(Workspace_Children:FindFirstChild("a") and (Workspace_Children:FindFirstChild("a"):FindFirstChild("Head") or Workspace_Children:FindFirstChild("a")) or workspace.BOUND,"Please Leave Our Store Alone For A Moment.",Enum.ChatColor.Red)
							end
							end)
						end
						if v and table.find(queue, v) then
							table.remove(queue, table.find(queue, v))
						end
						Active = false
					end
					for i,v in game:FindFirstChildOfClass('ServerStorage'):FindFirstChild(Workspace_Children.Name.."_Item"):GetChildren() do
						list(v)
					end
					local con1, con2
					con1 = game:FindFirstChildOfClass('ServerStorage'):FindFirstChild(Workspace_Children.Name.."_Item").ChildAdded:Connect(list)
					con2 = game:FindFirstChildOfClass('ServerStorage'):FindFirstChild(Workspace_Children.Name.."_Item").ChildRemoved:Connect(function()
						if Workspace_Children and Workspace_Children:FindFirstChild("a") and not Workspace_Children:FindFirstChild("a").PrimaryPart then
							Workspace_Children:FindFirstChild("a").PrimaryPart = Workspace_Children:FindFirstChild("a"):FindFirstChild('Head')
						end
						if Workspace_Children and Workspace_Children:FindFirstChild("a") and Workspace_Children:FindFirstChild("a").PrimaryPart then
							for i,v in Workspace_Children:FindFirstChild("a").PrimaryPart:GetChildren() do
								if RemoveFunction[v] and v:IsA('ProximityPrompt') and (not game:FindFirstChildOfClass('ServerStorage'):FindFirstChild(Workspace_Children.Name.."_Item") or not game:FindFirstChildOfClass('ServerStorage'):FindFirstChild(Workspace_Children.Name.."_Item"):FindFirstChild(v.ObjectText)) then
									RemoveFunction[v]()
								end
							end
						end
						local success = pcall(function()
							task.synchronize()
							if Workspace_Children:FindFirstChild("a") and not Workspace_Children:FindFirstChild("a").PrimaryPart and Workspace_Children:FindFirstChild("a"):FindFirstChild('Head') then
								Workspace_Children:FindFirstChild("a").PrimaryPart = Workspace_Children:FindFirstChild("a"):FindFirstChild('Head')
							end
							if not Workspace_Children or not Workspace_Children:FindFirstChild("a") or not Workspace_Children:FindFirstChild("a").PrimaryPart or ((not Workspace_Children:FindFirstChild("a").PrimaryPart:FindFirstChildOfClass('ProximityPrompt') and Workspace_Children:FindFirstChild("a"):FindFirstChild('Head') and not Workspace_Children:FindFirstChild("a"):FindFirstChild('Head'):FindFirstChildOfClass('ProximityPrompt') and (not game:FindFirstChildOfClass('ServerStorage'):FindFirstChild(Workspace_Children.Name.."_Item") or #game:FindFirstChildOfClass('ServerStorage'):FindFirstChild(Workspace_Children.Name.."_Item"):GetChildren() <= 0))) then
								print('no prompt or no item')
								for i,v in pairs(RegisteredClerk) do
								if v:IsA('Model') and v:FindFirstChildOfClass('Humanoid') then
									v:FindFirstChildOfClass('Humanoid').NameDisplayDistance = 0
									v:FindFirstChildOfClass('Humanoid').DisplayName = '	'
								end
								game:FindFirstChildOfClass('Debris'):AddItem(v, 250)
							end
							RegisteredClerk = nil
							if con1 then con1:Disconnect() end if con2 then con2:Disconnect() end
							end end)
						if not success then
							task.synchronize()
							for i,v in pairs(RegisteredClerk) do
								if v:IsA('Model') and v:FindFirstChildOfClass('Humanoid') then
									v:FindFirstChildOfClass('Humanoid').NameDisplayDistance = 0
									v:FindFirstChildOfClass('Humanoid').DisplayName = '	'
								end
								game:FindFirstChildOfClass('Debris'):AddItem(v, 250)
							end
							RegisteredClerk = nil
							if con1 then con1:Disconnect() end if con2 then con2:Disconnect() end
						end
					end)
				end
			end
		end
		function Determine_Asset(Shop_Asset: Instance)
			if (string.match(Shop_Asset.Name:upper(),"CLERK") or string.match(Shop_Asset.Name:upper(),"A")) and Shop_Asset:FindFirstChildOfClass('Humanoid') then
				if not table.find(RegisteredClerk , Shop_Asset) then
					table.insert(RegisteredClerk , Shop_Asset)
					if Shop_Asset:FindFirstChildOfClass('Humanoid') and Shop_Asset:FindFirstChildOfClass('Humanoid').RootPart then
						--task.wait()
						Shop_Asset:FindFirstChildOfClass('Humanoid').RootPart.Anchored = true
					end
				end
			elseif string.match(Shop_Asset.Name,"Hitbox_") and Shop_Asset:IsA('BasePart') then
				--print("Found Hitbox >>"..Shop_Asset:GetFullName())
				local windowshutangle = math.random(5,15)
				local shutted = false
				local sizeOffsetFrontBack = Vector3.new(-(Shop_Asset.Size.X - 0.1), -(Shop_Asset.Size.Y - 1), 0)
				local sizeOffsetLeftRight = Vector3.new(0, -(Shop_Asset.Size.Y - 1), -(Shop_Asset.Size.Z - 0.1))
				task.wait(.25)
				if workspace:FindFirstChild('IsItRaining') and workspace:FindFirstChild('IsItRaining').Value > 3 then
					shutted = math.random() > .5
				end
				local function cloneTransition(Shop_Asset, direction, sizeOffset, angleOffset, nowalking: boolean?)
					local directionVector = Vector3.new()
					if direction == "front" then
						directionVector = Vector3.new(0, 0, (-Shop_Asset.Size.Z + 1) / 2)
					elseif direction == "back" then
						directionVector = Vector3.new(0, 0, -(-Shop_Asset.Size.Z + 1) / 2)
					elseif direction == "left" then
						directionVector = Vector3.new((-Shop_Asset.Size.X + 1) / 2, 0, 0)
					elseif direction == "right" then
						directionVector = Vector3.new(-(-Shop_Asset.Size.X + 1) / 2, 0, 0)
					end
					if not nowalking then
						if Workspace_Children:FindFirstChild("a") and Workspace_Children:FindFirstChild("a"):FindFirstChildOfClass('Humanoid') and Workspace_Children:FindFirstChild("a"):FindFirstChildOfClass('Humanoid').RootPart and Workspace_Children:FindFirstChild("a"):FindFirstChildOfClass('Humanoid').RootPart.Anchored == false then
							for i,v in Workspace_Children:FindFirstChild("a"):GetChildren() do
								if v:IsA('BasePart') then
									v.Anchored = false
								end
							end
							Workspace_Children:FindFirstChild("a"):FindFirstChildOfClass('Humanoid'):MoveTo(Shop_Asset.Position + directionVector/1.5)
							local long = 0
							repeat local dt = task.wait(.1) long += dt if long >= 2 then if 	Workspace_Children and 	Workspace_Children:FindFirstChild("a") then 	Workspace_Children:FindFirstChild("a"):PivotTo(CFrame.new(Shop_Asset.Position + directionVector/1.5)) end  break end if Workspace_Children and Workspace_Children:FindFirstChild("a") and Workspace_Children:FindFirstChild("a"):FindFirstChildOfClass('Humanoid') then Workspace_Children:FindFirstChild("a"):FindFirstChildOfClass('Humanoid'):MoveTo(Shop_Asset.Position + directionVector/1.5) else break end until not Workspace_Children or not Workspace_Children:FindFirstChild("a") or not Workspace_Children:FindFirstChild("a"):FindFirstChildOfClass('Humanoid') or not Workspace_Children:FindFirstChild("a"):FindFirstChildOfClass('Humanoid').RootPart or (Workspace_Children:FindFirstChild("a"):FindFirstChildOfClass('Humanoid').RootPart.Position - (Shop_Asset.Position + directionVector/1.5)).Magnitude <= 7
						end
					end
					for i = 1, math.round(Shop_Asset.Size.Y) do
						Shop_Asset.Archivable = true
						local clone: BasePart = Shop_Asset:Clone()
						clone.Position = Shop_Asset.Position + directionVector - Vector3.new(0, -Shop_Asset.Size.Y / 2 + (i + 1), 0)
						clone.Size = Shop_Asset.Size + sizeOffset
						clone.Transparency = 1
						clone.CanCollide = true
						clone.Material = Enum.Material.Metal
						clone.Parent = Shop_Asset.Parent
						task.delay(.4, function()
							if clone then
								clone.Anchored = true
							end
						end)
						
						-- Sound effects
						if clone:FindFirstChild('Metal Impacts 1 (SFX)') then
							clone:FindFirstChild('Metal Impacts 1 (SFX)').PlaybackSpeed = 1 + math.random(-10, 10) / 100
							clone:FindFirstChild('Metal Impacts 1 (SFX)'):Play()
						end

						if i >= math.round(Shop_Asset.Size.Y) then
							if clone:FindFirstChild('Metal Ladder Hits 3 (SFX)') then
								clone:FindFirstChild('Metal Ladder Hits 3 (SFX)').PlaybackSpeed = 1 + math.random(-10, 10) / 100
								clone:FindFirstChild('Metal Ladder Hits 3 (SFX)'):Play()
							end
							if Shop_Asset.Parent:FindFirstChild('Locked') and Shop_Asset.Parent:FindFirstChild('Locked'):FindFirstChild(direction) then
								for i,v in pairs( Shop_Asset.Parent:FindFirstChild('Locked'):FindFirstChild(direction):GetDescendants()) do
									if v:IsA('BasePart') then
										v.Transparency = 0
									end
								end
							end
						end

						-- Tweening
						EasyTween(clone, 'CFrame', CFrame.new(clone.Position) * Shop_Asset.CFrame.Rotation * ((direction == 'front' or direction == 'back') and CFrame.Angles(0, 0, -angleOffset) or CFrame.Angles(angleOffset, 0, 0)), 0.2):Play()
						EasyTween(clone, 'Transparency', 0, 0.2):Play()
						EasyTween(clone, 'Color', Color3.new(0.372549, 0.372549, 0.372549), 0.2):Play()

						task.wait(0.1)
					end
				end
				if shutted then
					task.synchronize()
					cloneTransition(Shop_Asset, "front", sizeOffsetFrontBack, math.rad(-windowshutangle))
					cloneTransition(Shop_Asset, "left", sizeOffsetLeftRight, math.rad(-windowshutangle))
					cloneTransition(Shop_Asset, "right", sizeOffsetLeftRight, math.rad(windowshutangle))
				end
				task.desynchronize()
				local conditionfalse = 0
				while Shop_Asset and conditionfalse < 10 and  game:FindFirstChildOfClass('ServerStorage'):FindFirstChild('Shop_1_Item') do
					task.desynchronize()
					local delta = task.wait(rate) or 1/60
					local busy = false
					Cooldown = {}
					AllBusy = false
					if (RegisteredClerk and RegisteredClerk ~= nil and #RegisteredClerk > 0) then
						conditionfalse = 0
					else conditionfalse += delta end
					--print("Hitbox log >>"..Shop_Asset:GetFullName())
					local allthing = workspace:GetPartsInPart(Shop_Asset,Param)
					if next(allthing) then
						for i,v in ipairs(allthing)  do
							task.desynchronize()
							--print("Found Part >>"..tostring(Shop_Asset))
							if v and v.Parent and RegisteredClerk ~= {} then
								if v:FindFirstAncestorWhichIsA("Model") and v:FindFirstAncestorWhichIsA("Model"):FindFirstChildOfClass("Humanoid") and v:FindFirstAncestorWhichIsA("Model"):FindFirstChildOfClass("Humanoid").Health > 0 and v:FindFirstAncestorWhichIsA("Model"):FindFirstChildOfClass("Humanoid"):GetState() ~= (Enum.HumanoidStateType.Ragdoll or Enum.HumanoidStateType.Dead or Enum.HumanoidStateType.Physics or Enum.HumanoidStateType.PlatformStanding or Enum.HumanoidStateType.Flying or Enum.HumanoidStateType.None or Enum.HumanoidStateType.FallingDown ) and not RegisteredClerk[v:FindFirstAncestorWhichIsA("Model")] and not Cooldown[v:FindFirstAncestorWhichIsA("Model")] then
									Cooldown[v:FindFirstAncestorWhichIsA("Model")] = true
									busy = true
									AllBusy = true
									local theweapon
									for i,v in RegisteredClerk do
										if v.Name == 'a' then theweapon = v break end
									end
									ChosenClerk = theweapon or RegisteredClerk[math.random(1,#RegisteredClerk)]
									if ChosenClerk == nil or (ChosenClerk and not ChosenClerk:FindFirstChild("Head")) then
										return
									end
									if typeof(Threat[v:FindFirstAncestorWhichIsA("Model")]) ~= 'number' then
										Threat[v:FindFirstAncestorWhichIsA("Model")] = 1
									else
										Threat[v:FindFirstAncestorWhichIsA("Model")] = math.clamp( Threat[v:FindFirstAncestorWhichIsA("Model")] + math.abs(4 * delta), 0 , 100)
										--		print("Threat ["..v:FindFirstAncestorWhichIsA("Model"):GetFullName().. "] >> "..Threat[v:FindFirstAncestorWhichIsA("Model")])
									end
									if v then
									--	print("Found Threat >>"..v:FindFirstAncestorWhichIsA("Model"):GetFullName())
									
										task.desynchronize()
										if not next(Threat) then busy = false AllBusy = false 
											elseif (not workspace:FindFirstChild('Fun') or workspace:FindFirstChild('Fun').Value == 875) then	busy = false AllBusy = false end	
									look(ChosenClerk,v:FindFirstAncestorWhichIsA("Model"), delta)
									if not ThreatWarned[v:FindFirstAncestorWhichIsA("Model")] then	ThreatWarned[v:FindFirstAncestorWhichIsA("Model")] = 0 end
										if ChosenClerk:FindFirstChild("Head") then
											local ph = ChosenClerk and ChosenClerk:FindFirstChild("Head") or ChosenClerk
										if Threat[v:FindFirstAncestorWhichIsA("Model")] >= 25 and ThreatWarned[v:FindFirstAncestorWhichIsA("Model")] <= 0 then
											--if Threat[v:FindFirstAncestorWhichIsA("Model")] == 25 then
												ThreatWarned[v:FindFirstAncestorWhichIsA("Model")] = 1 task.synchronize()
												game:FindFirstChildOfClass("ServerScriptService")["BUBBLECHAT!"].Event:Fire(ph,"Please leave the shop.",Color3.new(0,1,1))
											--end
										elseif Threat[v:FindFirstAncestorWhichIsA("Model")] >= 50 and ThreatWarned[v:FindFirstAncestorWhichIsA("Model")] == 1 then
											--if Threat[v:FindFirstAncestorWhichIsA("Model")] == 50 then
												ThreatWarned[v:FindFirstAncestorWhichIsA("Model")] = 2 task.synchronize()
												game:FindFirstChildOfClass("ServerScriptService")["BUBBLECHAT!"].Event:Fire(ph,"This area is restricted, Please leave",Color3.new(1,1,0.2))
											--end
											--look(ChosenClerk,v:FindFirstAncestorWhichIsA("Model"))
										elseif Threat[v:FindFirstAncestorWhichIsA("Model")] >= 75 and ThreatWarned[v:FindFirstAncestorWhichIsA("Model")] == 2 then
											--if Threat[v:FindFirstAncestorWhichIsA("Model")] == 75 then
												ThreatWarned[v:FindFirstAncestorWhichIsA("Model")] = 3 task.synchronize()
												game:FindFirstChildOfClass("ServerScriptService")["BUBBLECHAT!"].Event:Fire(ph,"leave the shop, This is your last warning.",Color3.new(1,0,0))
											--end
											--look(ChosenClerk,v:FindFirstAncestorWhichIsA("Model"))
										elseif Threat[v:FindFirstAncestorWhichIsA("Model")] >= 100 and ThreatWarned[v:FindFirstAncestorWhichIsA("Model")] == 3 then
											--if Threat[v:FindFirstAncestorWhichIsA("Model")] == 100 then
												if ChosenClerk:FindFirstChildOfClass("Tool") then
													task.synchronize()
												KickOut(ChosenClerk,v:FindFirstAncestorWhichIsA("Model"))
												if not v:FindFirstAncestorWhichIsA("Model") or not v:FindFirstAncestorWhichIsA("Model"):FindFirstChildOfClass('Humanoid') or v:FindFirstAncestorWhichIsA("Model"):FindFirstChildOfClass('Humanoid').Health <= 0 then
													Threat[v:FindFirstAncestorWhichIsA("Model")] = nil
													if Threat then	busy = false end
												end
												else
													task.desynchronize()
												if ThreatWarned[v:FindFirstAncestorWhichIsA("Model")] ~= 3 and not table.find(ChosenClerkNonWeap, ChosenClerk) then
													ThreatWarned[v:FindFirstAncestorWhichIsA("Model")] = 3
														table.insert(ChosenClerkNonWeap, ChosenClerk)
														task.synchronize()
													game:FindFirstChildOfClass("ServerScriptService")["BUBBLECHAT!"].Event:Fire(ChosenClerk:FindFirstChild("Head"),"...",Enum.ChatColor.Red)
												end
											end
											if v:FindFirstAncestorWhichIsA("Model").PrimaryPart ~= nil then
													if ChosenClerk:FindFirstChildOfClass("Tool") then
														task.synchronize()
													HandAim(ChosenClerk,nil,v:FindFirstAncestorWhichIsA("Model").PrimaryPart.CFrame, delta)
												end
											end
											end
										end
									end

									task.desynchronize()
								end
							end
						end
					end
					task.desynchronize()
					if not busy and RegisteredClerk and ChosenClerk then
						AllBusy = false
						if RegisteredClerk then task.synchronize()	look(ChosenClerk,ChosenClerk:FindFirstChildOfClass("Model"), delta) end
						task.desynchronize()
						coroutine.resume(coroutine.create(function()
							if Mag < FullMag and not reloading then
								reloading = true
								sound(1,"ClimbingUp",ChosenClerk.PrimaryPart)
								task.wait(2)
								Mag = FullMag
								reloading = false
							end
							if ChosenClerk and ChosenClerk:FindFirstChildOfClass("Tool") and ChosenClerk:FindFirstChildOfClass("Tool"):FindFirstChild("Weapon_Keep") and ChosenClerk:FindFirstChildOfClass("Tool"):FindFirstChild("Weapon_Keep").Transparency ~= 0 then
								task.synchronize() ChosenClerk:FindFirstChildOfClass("Tool"):FindFirstChild("Weapon_Keep").Transparency = 0
							end
							task.desynchronize()
							if ChosenClerk and  ChosenClerk:FindFirstChildOfClass("Tool") and ChosenClerk:FindFirstChildOfClass("Tool"):FindFirstChild("Weapon_Mesh") and ChosenClerk:FindFirstChildOfClass("Tool"):FindFirstChild("Weapon_Mesh").Transparency ~= 1 then
								task.synchronize() ChosenClerk:FindFirstChildOfClass("Tool"):FindFirstChild("Weapon_Mesh").Transparency = 1
							end
							task.desynchronize()
							if ChosenClerk and ChosenClerk:FindFirstChildOfClass("Humanoid") and ChosenClerk:FindFirstChildOfClass("Humanoid").Health <= ChosenClerk:FindFirstChildOfClass("Humanoid").MaxHealth then
								if not canheal then
									return
								else
									canheal = false
								end
								--print("Healed Via Handler")s 
									ChosenClerk:FindFirstChildOfClass("Humanoid").Health = ChosenClerk:FindFirstChildOfClass("Humanoid").Health + (ChosenClerk:FindFirstChildOfClass("Humanoid").MaxHealth/100) * Healing
								task.delay(HealingTime, function()
									canheal = true end)
								--print("Healable!")
							else
								--print("uNHealable!")
							end 
							if not RegisteredClerk then return end
							local clerk = ChosenClerk
							HandAim(clerk,Shop_Asset,nil, delta)

							if clerk:FindFirstChild("Handy Weld") then
								task.synchronize()
								clerk:FindFirstChild("Handy Weld"):Destroy()
							end
						end)) 
					end
					--print("Hitbox log End >>"..Shop_Asset:GetFullName())
					if typeof(RegisteredClerk) == 'table' and next(RegisteredClerk) ~= nil then
						task.desynchronize()
						if (typeof(Threat) == 'table' and next(Threat) ~= nil) or busy then
							if lasttense then
								for i,c in pairs(RegisteredClerk)  do
									if c ~= nil and c:FindFirstChild("Head") then for i,v in c:FindFirstChild("Head"):GetChildren() do
										task.desynchronize()
										if v:IsA("ProximityPrompt") and v.Enabled == true then
											task.synchronize()
											v.Enabled = false
										end
									end end
								end
							end
							lasttense = false
							if #allthing <= 0 then
							for i,Danger in pairs(Threat) do
								Threat[i] = math.clamp(Threat[i] - 10 * delta,0,100) 
								--	print("Threat ["..tostring(i).. "] >> "..Danger)
								if Threat[i] <= 0 or not i or (i and i:FindFirstChildOfClass("Humanoid") and (i:FindFirstChildOfClass("Humanoid") and i:FindFirstChildOfClass("Humanoid"):GetState() == Enum.HumanoidStateType.Dead)or (i and i:FindFirstChildOfClass("Humanoid") and i:FindFirstChildOfClass("Humanoid").Health <= 0)) then
									Threat[i] = nil
									task.desynchronize()
								end
							end end
						elseif not busy and RegisteredClerk and not lasttense and (typeof(Threat) ~= 'table' or next(Threat) == nil) then
							lasttense = true
							for i,c in pairs(RegisteredClerk)  do
								if c ~= nil and c:FindFirstChild("Head") then
									for i,v in c:FindFirstChild("Head"):GetChildren() do
										task.desynchronize()
										if v:IsA("ProximityPrompt") then
											if not v.Enabled then task.synchronize()	v.Enabled = true end
											AllBusy = false
										end
									end
									if c:FindFirstChild("Handy Weld") then
										task.synchronize()
										c:FindFirstChild("Handy Weld"):Destroy()
									end
									pcall(function() local returned = 10 repeat returned = (look(c,c:FindFirstChildOfClass("Model") or Workspace_Children, delta) and 0) or returned - delta until busy or not lasttense or returned <= 0 end)
								end
							end	
						end
					end
				end
				--[[print('ASSET:'..tostring(Shop_Asset:GetFullName()))
				print('RegisteredClerk:'..tostring(RegisteredClerk))
				print('RegisteredClerkam:'..tostring(#RegisteredClerk))
				print('Shop_1_Item:'..tostring(game:FindFirstChildOfClass('ServerStorage'):FindFirstChild('Shop_1_Item'):GetFullName()))]]
				-- back
				task.wait(.25)
				task.synchronize()

				-- Example usage
				
				
				--[[cloneTransition(Shop_Asset, "front", sizeOffsetFrontBack, math.rad(-windowshutangle))
				cloneTransition(Shop_Asset, "back", sizeOffsetFrontBack, math.rad(windowshutangle))
				cloneTransition(Shop_Asset, "left", sizeOffsetLeftRight, math.rad(-windowshutangle))
				cloneTransition(Shop_Asset, "right", sizeOffsetLeftRight, math.rad(windowshutangle))
				]]
				coroutine.resume(coroutine.create(function()
					for i,v in pairs( Shop_Asset.Parent:GetDescendants()) do
						if v:IsA('Light') then
							local sound = Instance.new('Sound', v.Parent)
							sound.SoundId = 'rbxassetid://6593042054'
							sound.Volume = .1
							sound:Play()
							EasyTween(v, 'Brightness', 0, v.Brightness/5):Play()
							EasyTween(v, 'Range', 0, v.Range/5):Play()
							task.wait(.05)
						elseif v:IsA('BasePart') then
							if v.Material == Enum.Material.Neon then
								EasyTween(v, 'Color', Color3.new(0,0,0), 2):Play()
								EasyTween(v, 'Transparency', 0.1, 2):Play()
								task.delay(2,function()
									if v then
										v.Material = Enum.Material.Glass
									end
								end)
							end
							task.wait(.1)
						end
					end
				end))
				if workspace:FindFirstChild('IsItRaining') and workspace:FindFirstChild('IsItRaining').Value < 4 and shutted then	
				else
					if Workspace_Children:FindFirstChild("a") and Workspace_Children:FindFirstChild("a"):FindFirstChildOfClass('Humanoid') and Workspace_Children:FindFirstChild("a"):FindFirstChildOfClass('Humanoid').RootPart then
						Workspace_Children:FindFirstChild("a"):FindFirstChildOfClass('Humanoid').RootPart.Anchored = false
					end
				end
				if Workspace_Children:FindFirstChild("a") then
					pcall(function()
						for i,v in ipairs( Workspace_Children:FindFirstChild("a"):GetDescendants()) do
							if v:IsA('ProximityPrompt') then
								v:Destroy()
							end
						end
					end)
				end
				if shutted then
					cloneTransition(Shop_Asset, "back", sizeOffsetFrontBack, math.rad(windowshutangle))
				else
					-- Function to shuffle a table
					local function shuffleTable(t)
						for i = #t, 2, -1 do
							local j = math.random(i)
							t[i], t[j] = t[j], t[i]
						end
					end

					-- Example usage with randomized direction order
					local directions = {
						{name = "front", sizeOffset = sizeOffsetFrontBack, angleOffset = math.rad(windowshutangle)},
						{name = "back", sizeOffset = sizeOffsetFrontBack, angleOffset = math.rad(-windowshutangle)},
						{name = "left", sizeOffset = sizeOffsetLeftRight, angleOffset = math.rad(-windowshutangle)},
						{name = "right", sizeOffset = sizeOffsetLeftRight, angleOffset = math.rad(windowshutangle)}
					}
					
					local leave = false
					local path = {}
					if workspace:FindFirstChild('IsItRaining') and workspace:FindFirstChild('IsItRaining').Value > 1 and workspace:FindFirstChild('IsItRaining').Value < 4 then
						leave = math.random() > .5
					end
					-- Call cloneTransition for each direction in random order
					
					if leave then
						table.remove(directions, 3)
						if Workspace_Children then
							if Workspace_Children:FindFirstChild('pathway point') and Workspace_Children:FindFirstChild('pathway point'):FindFirstChild('Leaving Pathway') then
								for i,v in Workspace_Children:FindFirstChild('pathway point'):FindFirstChild('Leaving Pathway'):GetChildren() do
									table.insert(path, tonumber(v.Name), v.Position)
								end
							end
						end
					end
					-- Shuffle the directions to make the closing random
					shuffleTable(directions)
					for _, dir in ipairs(directions) do
						cloneTransition(Shop_Asset, dir.name, dir.sizeOffset, dir.angleOffset)
					end
					if leave then
						for i,v in ipairs(path) do
							if Workspace_Children:FindFirstChild("a") and Workspace_Children:FindFirstChild("a"):FindFirstChildOfClass('Humanoid') and Workspace_Children:FindFirstChild("a"):FindFirstChildOfClass('Humanoid').RootPart then
								Workspace_Children:FindFirstChild("a"):FindFirstChildOfClass('Humanoid').RootPart.Anchored = false
								Workspace_Children:FindFirstChild("a"):FindFirstChildOfClass('Humanoid'):MoveTo(v)
								local long = 0
								if not  Workspace_Children:FindFirstChild("a") then break end
								repeat local dt = task.wait(.1) long += dt if long >= 5 and  Workspace_Children:FindFirstChild("a") then Workspace_Children:FindFirstChild("a"):PivotTo(CFrame.new(v)) break end if Workspace_Children and Workspace_Children:FindFirstChild("a") and Workspace_Children:FindFirstChild("a"):FindFirstChildOfClass('Humanoid') then Workspace_Children:FindFirstChild("a"):FindFirstChildOfClass('Humanoid'):MoveTo(v) else break end until not Workspace_Children or not Workspace_Children:FindFirstChild("a") or not Workspace_Children:FindFirstChild("a"):FindFirstChildOfClass('Humanoid') or not Workspace_Children:FindFirstChild("a"):FindFirstChildOfClass('Humanoid').RootPart or (Workspace_Children:FindFirstChild("a"):FindFirstChildOfClass('Humanoid').RootPart.Position - v).Magnitude <= ((i < 3 and 5) or 7)
							end
							if i == 3 then
								cloneTransition(Shop_Asset, "left", sizeOffsetLeftRight, math.rad(-windowshutangle), true)
							end
							if i == 4 then
								if Workspace_Children and Workspace_Children:FindFirstChild('Shop Boat') and Workspace_Children:FindFirstChild('Shop Boat'):FindFirstChildOfClass('Seat') and Workspace_Children:FindFirstChild("a") and Workspace_Children:FindFirstChild("a"):FindFirstChildOfClass('Humanoid') then	Workspace_Children:FindFirstChild('Shop Boat'):FindFirstChildOfClass('Seat'):Sit(Workspace_Children:FindFirstChild("a"):FindFirstChildOfClass('Humanoid')) end
								task.wait()
								if not workspace.Name:upper():match('RESERVED') then	EasyTween(Workspace_Children:FindFirstChild('Shop Boat'):FindFirstChild('the boat'), 'Position', Workspace_Children:FindFirstChild('Shop Boat'):FindFirstChild('the boat').Position - Vector3.new(0,0,10000),1000):Play()
								if Workspace_Children and	Workspace_Children:FindFirstChild("a") and Workspace_Children:FindFirstChild("a"):FindFirstChild("Left Arm") and Workspace_Children:FindFirstChild("a"):FindFirstChild("Left Arm"):FindFirstChild("oar") then
									Workspace_Children:FindFirstChild("a"):FindFirstChild("Left Arm"):FindFirstChild("oar").Transparency = 0
								end
									pcall(function()Workspace_Children:FindFirstChild('Shop Boat'):FindFirstChild('oar'):Destroy() end) else pcall(function() Debris:AddItem(Workspace_Children:FindFirstChild("a"), 1) end) end
							end
						end
						
					end
					if Shop_Asset then
						Shop_Asset.CanCollide = true
					end
				end
			end
		end
		for i, Shop_Asset in Workspace_Children:GetChildren() do
			Determine_Asset(Shop_Asset)
		end
		task.synchronize()
		local a, b a = Workspace_Children.ChildAdded:Connect(function(Shop_Asset)
			if not RegisteredClerk then task.synchronize() a:Disconnect() b:Disconnect() return end
			Determine_Asset(Shop_Asset)
		end)
		b = Workspace_Children.ChildRemoved:Connect(function(Shop_Asset)
			if not RegisteredClerk then task.synchronize() a:Disconnect() b:Disconnect() return end
			if table.find(RegisteredClerk, Shop_Asset) then table.remove(RegisteredClerk,  table.find(RegisteredClerk, Shop_Asset)) end 
		end)
	end
end
-- Inserting Shop Isn't Allowed, but inserting things in the shop are