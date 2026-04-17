--!native
--Solivion: Simple Boat Controller
local ManageBoat: {[Model?]: BoatData} = {}
local Rate = 1/60
pcall(function()
	if workspace.Name:lower():match('reserved') then
		Rate = 1/240
	end
end)
local CollisionParameter = RaycastParams.new()
local ongoing = false
CollisionParameter.FilterDescendantsInstances = {workspace.Map, workspace.BOUND, workspace:FindFirstChildOfClass('Terrain')}
CollisionParameter.FilterType = Enum.RaycastFilterType.Include
CollisionParameter.RespectCanCollide = true
CollisionParameter.IgnoreWater = true

type BoatData = {
	Vel: Vector3,
	Acc: Vector3,
	Dir: Vector3,
	HP: number,
	Occupants: {Model?},
	Driver: (Player | Humanoid)?,
	MainSeats: VehicleSeat,
	Seats: {Seat?},
	RaycastParameter: RaycastParams,
	OverlapParameter: OverlapParams,
	ExtentSize: Vector3?,
	LastPivot: CFrame?,
	LastEmpty: number
}

function Cache()
	pcall(function()
	for i,v in pairs(ManageBoat) do
		if typeof(i) ~= 'Instance' or typeof(v) ~= 'table' or not i:IsDescendantOf(workspace) then continue end
		for header, value in pairs(v) do
			if typeof(value) == 'Instance' or typeof(value) == 'OverlapParams' or typeof(value) == 'RaycastParams' or typeof(value) == 'table' or typeof(value) == 'RBXScriptConnection' then continue end
			i:SetAttribute(header, value)
		end
			if typeof(v.Anchor) == 'Instance' and v.Anchor.Parent then
				v.Anchor:Destroy()
			end
		end 
	end)
end

function ClampVector3(vector: Vector3)
	if not vector or not vector.Magnitude or vector.Magnitude ~= vector.Magnitude or vector.Magnitude <= 0 then return Vector3.new() end
	return vector.Unit * math.clamp(vector.Magnitude,1,24)
end

function NewBoatData(ExtraData: {any}?): BoatData
	return {
		Vel = Vector3.new(0,0,0),
		Acc = Vector3.new(0,0,0),
		Dir = Vector3.new(0,0,0),
		HP = ((ExtraData and ExtraData.HP and typeof(ExtraData.HP) == 'number' and ExtraData.HP) or 100),
		Occupants = ((ExtraData and ExtraData.Occupants and typeof(ExtraData.Occupants) == 'table' and ExtraData.Occupants) or {}),
		Driver = (ExtraData and ExtraData.Driver and typeof(ExtraData.Driver) == "Instance" and ExtraData.Driver:IsA("Player") and ExtraData.Driver) or nil,
		Seats = ((ExtraData and ExtraData.Seats and typeof(ExtraData.Seats) == 'table' and ExtraData.Seats) or {}),
		MainSeats = ((ExtraData and ExtraData.MainSeats and typeof(ExtraData.MainSeats) == 'Instance' and ExtraData.MainSeats) or nil),
		RaycastParameter = ((ExtraData and ExtraData.RaycastParameter and typeof(ExtraData.RaycastParameter) == 'RaycastParams' and ExtraData.RaycastParameter) or RaycastParams.new()),
		OverlapParameter = ((ExtraData and ExtraData.OverlapParameter and typeof(ExtraData.OverlapParameter) == 'OverlapParams' and ExtraData.OverlapParameter) or OverlapParams.new()),
		ExtentSize = Vector3.new(),
		LastPivot = CFrame.new(),
		LastEmpty = 0
	}
end

function Register_Boat(Boat: Model, Extras: {any}): BoatData?
	task.desynchronize()
	if not Boat or typeof(Boat) ~= "Instance" or not Boat:IsA("Model") or ManageBoat[Boat] then return end
	if ManageBoat[Boat] then return ManageBoat[Boat] end
	local Dataset: BoatData = ManageBoat[Boat] or NewBoatData(Extras)
	if not Dataset then warn("<NO DATA>") return end
	task.synchronize()
	if Dataset.RaycastParameter then Dataset.RaycastParameter.FilterDescendantsInstances = {Boat, workspace.Character} Dataset.RaycastParameter.FilterType = Enum.RaycastFilterType.Exclude Dataset.RaycastParameter.RespectCanCollide = true Dataset.RaycastParameter.IgnoreWater = true end -- Water Can't Be Hit
	if Dataset.OverlapParameter then Dataset.OverlapParameter.FilterDescendantsInstances = {Boat, workspace.Character} Dataset.OverlapParameter.FilterType = Enum.RaycastFilterType.Exclude Dataset.OverlapParameter.RespectCanCollide = true Dataset.OverlapParameter.MaxParts = 5 end -- Water Can't Be Hit
	Dataset.ExtentSize = Boat:GetExtentsSize()/1.575
	Dataset.LastPivot = Boat:GetPivot()
	pcall(function()
		Dataset.Anchor=script["Boat Stopper"]:Clone()
		if Dataset.Anchor then
			Dataset.Anchor.Parent = script
			Dataset.AnClear = Boat.Destroying:Once(function() Dataset.Anchor:Destroy() end) 
		end	
	end)Dataset.Connections = {}
	Boat.Parent = workspace.__BOAT
	Boat.Destroying:Once(function() for i,v in Dataset.Connections do if typeof(v) == 'RBXScriptConnection' then v:Disconnect() end end Dataset.Connections = nil ManageBoat[Boat] = nil end)
	task.desynchronize()
	if #Dataset.Seats <= 0 then
		for i,v in ipairs(Boat:GetDescendants()) do
			if v:IsA('VehicleSeat') then
				if v.Occupant and not table.find(Dataset.Occupants, v) then
					table.insert(Dataset.Occupants, v.Occupant)
					Dataset.Driver = v
				end
				if not Dataset.MainSeats then
					Dataset.MainSeats = v
				end
			elseif v:IsA('Seat') then
				table.insert(Dataset.Seats, v)
				local lastoccupant
				if v.Occupant and not table.find(Dataset.Occupants, v.Occupant.Parent) then
					lastoccupant = v.Occupant.Parent
					table.insert(Dataset.Occupants, v.Occupant.Parent)
				end
				task.synchronize()
				table.insert(Dataset.Connections, 
					v:GetPropertyChangedSignal('Occupant'):Connect(function()
						task.desynchronize()
						assert(Boat, 'NO BOAT')
						assert(ManageBoat[Boat], 'NO DATA')
						assert(ManageBoat[Boat].Occupants, 'NO TABLE')
						if v and Boat and ManageBoat[Boat] and v.Occupant then
							lastoccupant = v.Occupant.Parent
							if v.Occupant and not table.find(ManageBoat[Boat].Occupants, lastoccupant) then
								table.insert(ManageBoat[Boat].Occupants, lastoccupant)
							end
						else
							if Boat and ManageBoat[Boat] and ManageBoat[Boat].Occupants and lastoccupant and table.find(ManageBoat[Boat].Occupants, lastoccupant) then
								table.remove(ManageBoat[Boat].Occupants, table.find(ManageBoat[Boat].Occupants, lastoccupant))
							end
						end
					end)
				)
				task.desynchronize()
			end
		end
	end
	if not Dataset.MainSeats then warn('<NO DRIVER SEAT>') end
	ManageBoat[Boat] = Dataset
	if not ongoing then SetUpLoop() end
end

function SetUpLoop()
	if ongoing then return end
	coroutine.resume(coroutine.create(function()
		ongoing = true
		while script and next(ManageBoat) do
			task.desynchronize()
			local DT = task.wait(Rate)
			local Speed = (10 ^ -6) ^ DT
			for Boat: Model, Data: BoatData in pairs(ManageBoat) do
				task.desynchronize()
				task.spawn(function()
				if Data and Boat and Boat.Parent then
					local BoatPivot = Data.LastPivot or Boat:GetPivot() or CFrame.new()
					local BoatSize = Data.ExtentSize or Vector3.new()
					if Data.Vel.Magnitude > 1 then
						local TimedVelocity = Data.Vel * DT
						--or workspace:Blockcast(BoatPivot - (BoatPivot.LookVector * BoatSize.Z/2), BoatSize, TimedVelocity, Data.RaycastParameter) or workspace:Blockcast(BoatPivot + (BoatPivot.LookVector * BoatSize.Z/2), BoatSize, - TimedVelocity, Data.RaycastParameter) or workspace:Blockcast(BoatPivot - (BoatPivot.LookVector * BoatSize.Z/2) + TimedVelocity, BoatSize, - TimedVelocity, Data.RaycastParameter)
						local Collision = workspace:Blockcast(BoatPivot + (BoatPivot.LookVector * BoatSize.Z/2) - TimedVelocity, BoatSize, TimedVelocity, Data.RaycastParameter) or workspace:Blockcast(BoatPivot, BoatSize, TimedVelocity, Data.RaycastParameter)
						if Collision then
							if not Data.HP then Data.HP = 100 end
							Data.HP = Data.HP - TimedVelocity.Magnitude
							if Data.HP <= 0 and Boat then task.synchronize() ManageBoat[Boat] = nil Boat:Destroy() Boat = nil return end
							Data.Acc = -Data.Vel
							Data.Vel = Data.Vel/4
						else
							Data.LastPivot = CFrame.new(BoatPivot.Position + TimedVelocity, BoatPivot.Position + TimedVelocity * 2)
							task.synchronize()
							Boat:PivotTo(Data.LastPivot)
							task.desynchronize()
							if Boat:GetPivot().Position.Magnitude > 600 then if Data.HP <= 0 and Boat then ManageBoat[Boat] = nil task.synchronize() Boat:Destroy() Boat = nil return end end
						end
					end
					if #Data.Occupants <= 0 and not Data.Driver then
						Data.LastEmpty += DT
						if Data.LastEmpty > 120 then
							task.synchronize()
							Boat:Destroy()
							return
						end
					else
						Data.LastEmpty = 0
					end
					local CollisionRight = workspace:Blockcast(BoatPivot, BoatSize, BoatPivot.RightVector * BoatSize.X/2, CollisionParameter)
					local CollisionLeft = workspace:Blockcast(BoatPivot, BoatSize, BoatPivot.RightVector * -BoatSize.X/2, CollisionParameter)
					local CollisionFront = workspace:Blockcast(BoatPivot, BoatSize, BoatPivot.LookVector * BoatSize.Z/2, CollisionParameter)
					local CollisionBack = workspace:Blockcast(BoatPivot, BoatSize, BoatPivot.LookVector * -BoatSize.Z/2, CollisionParameter)
					local CollidedMargin = Vector3.new()
					if CollisionRight then CollidedMargin += BoatPivot.RightVector * ((BoatSize.X/2) - CollisionRight.Distance) end
					if CollisionLeft then CollidedMargin -= BoatPivot.RightVector * ((BoatSize.X/2) - CollisionLeft.Distance) end
					if CollisionFront then CollidedMargin += BoatPivot.LookVector * ((BoatSize.Z/2) - CollisionFront.Distance) end
					if CollisionBack then CollidedMargin -= BoatPivot.LookVector * ((BoatSize.Z/2) - CollisionBack.Distance) end
					local Driver = Data.Driver
					if not Data.MainSeats.Occupant then Data.Driver = nil end
					local stopped = true
					if Driver and Driver:IsA("Player") and Driver.Character and Driver.Character:FindFirstChildOfClass("Humanoid") and Driver.Character:FindFirstChildOfClass("Humanoid").SeatPart and Driver.Character:FindFirstChildOfClass("Humanoid").SeatPart == Data.MainSeats and Driver.Character:FindFirstChildOfClass("Humanoid"):GetState() == Enum.HumanoidStateType.Seated then
						local h = Driver.Character:FindFirstChildOfClass("Humanoid")
						local Direction = h.MoveDirection
						if Direction.Magnitude < 1 or Direction.Unit.Magnitude < 1 or h:GetAttribute('stop') then Data.Dir = Vector3.new() else 
						Data.Dir = Vector3.new(Direction.X,0,Direction.Z) end
					else
						Data.Dir = Vector3.new()
						if Data.MainSeats and Data.MainSeats.Occupant and Data.MainSeats.Occupant.Parent and game:FindFirstChildOfClass('Players'):FindFirstChild(Data.MainSeats.Occupant.Parent.Name) then
							task.synchronize()
							Data.RaycastParameter.FilterDescendantsInstances = {Boat, Data.MainSeats.Occupant.Parent, Data.Occupants, workspace.Character}
							Data.MainSeats.Name = string.upper(Data.MainSeats.Occupant.Parent.Name)..'__DRIVER_SEAT'
							Data.Driver = game:FindFirstChildOfClass('Players'):GetPlayerFromCharacter(Data.MainSeats.Occupant.Parent)
							if Data.Anchor and Data.Driver and Data.Driver:FindFirstChildOfClass('Backpack') then
								Data.Anchor.Parent = Data.Driver:FindFirstChildOfClass('Backpack')
							end
							task.desynchronize()
						end
					end
					task.desynchronize()
					if not Data.Anchor or not Data.Anchor.Parent then task.synchronize() Data.Anchor = script["Boat Stopper"]:Clone()  if Data.AnClear then Data.AnClear:Disconnect() end if Data.Anchor then Data.AnClear = Boat.Destroying:Once(function() Data.Anchor:Destroy() end) Data.Anchor.Parent = script end end
					if (not Data.Driver or not Data.Driver.Character) and Data.Anchor then task.synchronize() Data.Anchor.Parent = script end
					if CollidedMargin ~= Vector3.new() then
						Data.LastPivot = Data.LastPivot - CollidedMargin
						Data.HP = Data.HP - CollidedMargin.Magnitude
						task.synchronize()
						Boat:PivotTo(Data.LastPivot)
						task.desynchronize()
					end
					Data.Acc = Data.Acc:Lerp(Data.Dir, Speed)
					if Data.Acc.Magnitude <= 0.01 or (Data.Dir.Unit.Magnitude ~= Data.Dir.Unit.Magnitude or Data.Dir.Unit.Magnitude < 1) then
						if Data.Vel.Magnitude > 0.01 then	Data.Vel = ClampVector3(Data.Vel.Unit * math.max(0,Data.Vel.Magnitude-(DT * 20))) else Data.Vel = Vector3.new() end
					else
						Data.Vel = ClampVector3(Data.Vel + Data.Acc * DT * 30)
					end
				elseif not Data and Boat and Boat.Parent then
					ManageBoat[Boat] = NewBoatData()
				elseif Boat and not Boat.Parent then
					ManageBoat[Boat] = nil
				end end)
			end
		end
		ongoing = false
	end))
end

task.synchronize()
script:SetAttribute('Removing', nil) script:SetAttribute('ReadyToBRemoved', nil)
script:GetAttributeChangedSignal('Removing'):Once(function()
	task.synchronize()
	Cache()
	script:SetAttribute('ReadyToBRemoved', true)
end)

for i,child in workspace.__BOAT:GetChildren() do
	if #ManageBoat >= 25 or workspace.IsItRaining.Value == 1 then return end
	if child.Name:upper() == 'BOAT' and child:IsA('Model') then
		Register_Boat(child, child:GetAttributes())
	end
end
task.synchronize()
workspace.__BOAT.ChildAdded:Connect(function(child)
	if #ManageBoat >= 25 or workspace.IsItRaining.Value == 1 then return end
	if child.Name:upper() == 'BOAT' and child:IsA('Model') then
		Register_Boat(child, child:GetAttributes())
	end
end)