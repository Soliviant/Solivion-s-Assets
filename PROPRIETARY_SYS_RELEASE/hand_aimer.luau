local function IsBehind(CharHRP, Part)
	-- Use direct vector math for performance
	local hrpPos = CharHRP.Position
	local lookVec = CharHRP.CFrame.LookVector
	local frontPoint = hrpPos + lookVec
	local backPoint = hrpPos - lookVec * 0.5 + Vector3.new(-0.5, 0, 0)
	local partPos = Part.Position
	local magFront = (frontPoint - partPos).Magnitude
	local magBack = (backPoint - partPos).Magnitude
	return magFront > magBack
end
local function FindFirstChildOfNameAndClass(Par, Name, Var)
	if typeof(Par) ~= "Instance" then return end
	for i,v in Par:GetChildren() do
		if v.Name:match(Name) and v.ClassName == Var then return v end
	end
end
local function HandAim(Looker, Weld, TargetCFrame, hand)
	task.desynchronize()
	if not Looker or not hand then return end

	-- Cache torso reference
	local tr = Looker:FindFirstChild("UpperTorso") or Looker:FindFirstChild("Torso") or Looker:FindFirstChild("HumanoidRootPart")
	if not tr then return end

	local tframe = tr.CFrame
	-- Determine hand side once
	local isLeft = hand.Name:find("Left") ~= nil
	local C1X = isLeft and -0.5 or 0.5
	local C2 = isLeft and -1 or 1
	local HandOff = isLeft and Vector3.new(-1.5, 0.5, -0.5) or Vector3.new(1.5, 0.5, -0.5)
	local CurHandName = isLeft and "Left" or "Right"
	local OppoHandName = isLeft and "Right" or "Left"

	tframe = tframe + tframe:VectorToWorldSpace(HandOff)
	local targetPos = TargetCFrame and TargetCFrame.p or Vector3.new(0, 0, 0)
	local taim = targetPos - tframe.Position
	local LookAtVec = hand.Position - targetPos
	
	local Where
	if not TargetCFrame then
		Where = CFrame.new(HandOff) * CFrame.Angles(0, 0, 0)
	else
		Where = CFrame.new(Vector3.new(), tframe:vectorToObjectSpace(taim)) * CFrame.Angles(math.rad(-90), math.rad(180), math.rad(180))
	end
	
	local name = "Hand"..(isLeft and "Left" or "Right")
	local nweld = Weld or FindFirstChildOfNameAndClass(Looker, name, "Weld")
	local nweldC0 = nweld and nweld.C0 or CFrame.new()
	local nweldC1 = nweld and nweld.C1 or CFrame.new()

	if nweld then
		if not TargetCFrame then
			nweldC0 = nweldC0:Lerp(CFrame.new(HandOff), 0.1)
		else
			Where = Where.Rotation * CFrame.new(
				math.clamp(Where.X, -2, 2),
				math.clamp(Where.Y, -2, 2),
				math.clamp(Where.Z, -2, 2)
			) + HandOff
			nweldC0 = nweldC0:Lerp(Where, 0.3)
			local Meh = (hand.CFrame.Position - targetPos).Magnitude
			-- Offseter calculation (commented logic retained for reference)
			-- local Offseter = CFrame.new(math.clamp((-Meh + 0.0625 * 20) * C1X, -1, 1), math.clamp(Meh, -2, 2), math.clamp(Meh, -0.5, 0.5))
			-- Attachments logic omitted for performance
			-- nweld.C1 = nweld.C1:Lerp(Offseter, 0.45)
		end
	else
		task.synchronize()
		local NewHandWeld = Weld or Instance.new("Weld", Looker)
		NewHandWeld.Name = name
		NewHandWeld.Enabled = true
		nweld = NewHandWeld
		if hand:IsDescendantOf(Looker) then
			NewHandWeld.Part1 = hand
		end
		local torso = Looker:FindFirstChild("Torso") or Looker:FindFirstChild("UpperTorso")
		if torso then
			NewHandWeld.Part0 = torso
		end
		task.desynchronize()
		if not TargetCFrame then
			nweldC0 = NewHandWeld.C0:Lerp(CFrame.new(HandOff), 0.6)
			nweldC1 = NewHandWeld.C1:Lerp(CFrame.new(0, 0, 0), 0.6)
		else
			Where = Where.Rotation * CFrame.new(
				math.clamp(Where.X, -2, 2),
				math.clamp(Where.Y, -2, 2),
				math.clamp(Where.Z, -2, 2)
			)
			local NewHandWeldC0 = NewHandWeld.C0:Lerp(Where, 0.6)
			local Meh = (hand.CFrame.Position - targetPos).Magnitude
			local Offseter = CFrame.new(
				math.clamp((-Meh + 0.0625 * 20) * C1X, -1, 1),
				math.clamp(Meh, -2, 2),
				math.clamp(Meh, -0.5, 0.5)
			)
			nweldC1 = nweld.C1:Lerp(Offseter, 0.45)
		end
		task.synchronize()
		nweld.C0 = nweldC0
		nweld.C1 = nweldC1
		task.desynchronize()
	end
	
	if nweld.Part1.Name:match("Hand") then
		nweldC0 += nweldC0.UpVector * -.5
	end
	if nweld and (nweldC0 ~= nweld.C0 or nweldC1 ~= nweld.C1) then
		if nweldC0 ~= nweld.C0 then
			task.synchronize()
			nweld.C0 = nweldC0
		end
		if nweldC1 ~= nweld.C1 then
			task.synchronize()
			nweld.C1 = nweldC1
		end
	end
	return nweld
end

local tasker = {}
local function GetCF(thing)
	if not thing then return end
	if typeof(thing) == 'CFrame' then return thing end
	return thing.CFrame
end
local tasko = {}
function setuptask(Looker, hand, Target: (BasePart | CFrame))
	task.desynchronize()
	if not Looker or not hand or not Target then return end
	stopaim(Looker, hand, true)
	if not Looker.Parent or hand.Parent ~= Looker then return end
	local WELDED = HandAim(Looker, nil, GetCF(Target), hand)
	if not WELDED then return end
	if tasko[hand] then return end
	local taska taska = coroutine.create(function()
		while Looker and tasko[hand] == taska and hand and Target and Looker.Parent and hand.Parent and WELDED do
			task.wait(1/60)
			HandAim(Looker, WELDED, GetCF(Target), hand)
			task.desynchronize()
		end
		if tasko[hand] == taska then tasko[hand] = nil end
		print('condit fail')
		if WELDED then pcall(function() WELDED:Destroy() end) end
	end) tasko[hand] = taska if tasko[hand] == taska then coroutine.resume(taska) end
end
function stopaim(Looker, hand, keep)
	task.desynchronize()
	if not hand then return end
	if tasko[hand] then coroutine.close(tasko[hand])
		tasko[hand] = nil
	 end
	if not Looker then return end
	local isLeft = hand.Name:find("Left") ~= nil
	local name = "Hand"..(isLeft and "Left" or "Right")
	pcall(function()	
		if keep then return end
	local weld = FindFirstChildOfNameAndClass(Looker, name, "Weld")
		if weld then 	task.synchronize() weld:Destroy() end
end) end

script.Event.Event:Connect(function(start: boolean, specificarm: Part, looker: Model, targ: (Instance | CFrame))
	if not looker or (targ == nil and start) then return end
	if not start then
		if specificarm then	stopaim(looker,specificarm) else for i,v in looker:GetChildren() do stopaim(looker,v) end end
	elseif specificarm then
		setuptask(looker, specificarm, targ)
	end
end)

while task.wait(60) do
	for i,v in pairs(tasko) do
		if not i or not i.Parent or not v then pcall(function() if i then stopaim(i) else coroutine.close(v) end end) tasko[i] = nil end
	end
end