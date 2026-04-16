--by @Soliviant, or Solivion
local Cam = workspace.CurrentCamera
if typeof(Cam) ~= 'Instance' or Cam.ClassName ~= 'Camera' then return end
local Target = Vector3.new()
local X, Y, Z = 0,0,0 -- no input detection just yet.
local Dist = 1 -- same for above
local Saved = {}

function getSubjectFilter()
	local subject = typeof(Cam) == 'Instance' and Cam.ClassName == 'Camera' and Cam.CameraSubject
	if typeof(subject) ~= 'Instance' then return nil end

	if subject:IsA('Humanoid') then
		return subject:FindFirstAncestorWhichIsA('Model') or subject.Parent
	elseif subject:IsA('BasePart') then
		return subject:FindFirstAncestorWhichIsA('Model') or subject.Parent
	elseif subject:IsA('Model') then
		return subject
	else return subject.Parent or subject end
end

local RayPar = RaycastParams.new()
RayPar.IgnoreWater = true
RayPar.RespectCanCollide = false
RayPar.FilterType = Enum.RaycastFilterType.Exclude
RayPar.FilterDescendantsInstances = {getSubjectFilter()}

function FilterResult(RayRes: RaycastResult) if typeof(RayRes) ~= 'RaycastResult' then return end if typeof(RayRes.Instance) == 'Instance' and RayRes.Instance.Transparency <= 0.1 and RayRes.Material ~= Enum.Material.ForceField --[[ceck transparency]] then return RayRes end return nil end

while Cam and Cam.Parent and script and script.Parent do
	local last = task.wait()
	Cam.CameraType = Enum.CameraType.Scriptable
	Target =  typeof(Cam.CameraSubject) == 'Instance' and (Cam.CameraSubject:IsA('BasePart') and Cam.CameraSubject.Position or Cam.CameraSubject:IsA('Humanoid') and Cam.CameraSubject.RootPart and Cam.CameraSubject.RootPart.Position or Cam.CameraSubject:IsA('Model') and Cam.CameraSubject:GetPivot().Position) or Target
	--save everyframe with condition to match the phyics processing in case it was so fast
	if Cam.CameraType ~= Enum.CameraType.Scriptable then pcall(function()	Cam.CFrame = Cam.CFrame.Rotation + Target Cam.CameraType = Enum.CameraType.Scriptable end) end
	if typeof(Saved[1]) ~= 'Vector3' or (Saved[1] - Target).Magnitude > 10 ^ -3 then table.insert(Saved, 1, Target) if #Saved > 1024 then table.remove(Saved, #Saved) end end 
	local filter = {getSubjectFilter()}
	if #filter > 0 then pcall(function()	RayPar.FilterDescendantsInstances = filter end) end
	local PrevTar = Target
	local Between = (Target - Cam.CFrame.Position)
	local IsBlocked = FilterResult(workspace:Blockcast(Cam.CFrame, Vector3.new(.1,.1,.1), Between, RayPar)) or FilterResult(workspace:Blockcast(Cam.CFrame.Rotation + Target , Vector3.new(.1,.1,.1), -Between, RayPar))
	if IsBlocked then
		for i,v in Saved do
			local ToV = (v - Cam.CFrame.Position)
			local IsVBlocked = FilterResult(workspace:Blockcast(Cam.CFrame, Vector3.new(.1,.1,.1), ToV, RayPar)) or FilterResult(workspace:Blockcast(Cam.CFrame.Rotation + v , Vector3.new(.1,.1,.1), -ToV, RayPar))
			if not IsVBlocked then
				Target = v -- should be the closest location to the target
				break
			end
		end
	end
	local speed = 1 - math.clamp(.25^last, 0, 1)
	if speed > 0 and speed<=1 then -- stop the slowing don motion when the target is not visible, allowing for reaching the saved node
		local Pos = Target + Vector3.new(math.sin(X),math.sin(Y), math.sin(Z)) * math.clamp(Dist or 1, 1, 25)
		local targetCF = Cam.CFrame:Lerp(Cam.CFrame.Rotation + Target, speed * (IsBlocked and ((math.clamp((PrevTar - Cam.CFrame.Position).Magnitude - 10,-10,25)/10)) or (math.clamp((Target - Cam.CFrame.Position).Magnitude - 10,-10,25))/10)) local Dir = Cam.CFrame.Position - targetCF.Position if IsBlocked or (not FilterResult(workspace:Blockcast(Cam.CFrame, Vector3.new(.1,.1,.1), -Dir, RayPar)) and not FilterResult(workspace:Blockcast(targetCF, Vector3.new(.1,.1,.1), Dir, RayPar))) then Cam.CFrame = targetCF else Cam.CFrame = Cam.CFrame + Dir end
		local Looking = CFrame.lookAt(Cam.CFrame.Position, Target)
		pcall(function()	Cam.CFrame = Cam.CFrame:Lerp(Looking, speed * (1.25-(Cam.CFrame.LookVector:Dot(Looking.LookVector)))) end)
	end
end
pcall(function()	Cam.CameraType = Enum.CameraType.Custom end)