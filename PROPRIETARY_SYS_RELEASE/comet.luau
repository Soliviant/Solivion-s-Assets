task.wait(2)
if not workspace:GetAttribute('NEWYEAR') then script:Destroy() return end
-- Variables
local TService = game:FindFirstChildOfClass('TweenService')
local comet = workspace:FindFirstChild('__COMET') and workspace:FindFirstChild('__COMET'):FindFirstChild('COMET') or Instance.new('Part',workspace) -- Assume the comet object is the parent of this script
local center = Vector3.new(0, 0, 0) -- The center of the circular orbit
local radius = 956 -- Radius of the orbit
local speed = 0.5 -- Speed of the comet's orbit
local heightMultiplier = 1.075 -- Multiplier to control the height change

if comet.Name == 'Part' then
	comet.Name = "COMET"
	comet.Anchored = true
	comet.BottomSurface = Enum.SurfaceType.Smooth
	comet.TopSurface = Enum.SurfaceType.Smooth
	comet.Color = Color3.fromRGB(0, 255, 255)
	comet.Material = Enum.Material.Neon
	comet.Size = Vector3.new(8, 8, 8)
	comet.CFrame = CFrame.new(150.77999877929688, 4, 822.77001953125)
end
-- Function to calculate comet position
local function getPositionOnOrbit(elapsedTime)
	local angle = elapsedTime * speed
	local x = math.cos(angle) * radius
	local z = math.sin(angle) * radius

	-- Height calculation (up and down movement)
	local y = heightMultiplier * math.sin(angle) * radius

	return Vector3.new(x, y, z) + center
end

-- Main loop
local last = 0
local Light = Instance.new('PointLight',comet)
Light.Color = comet.Color
local CircularSphere1: Part = Instance.new('Part', comet.Parent)
CircularSphere1.Material = Enum.Material.Neon
CircularSphere1.Shape = Enum.PartType.Ball
CircularSphere1.Transparency = .5
local CircularSphere2: Part = Instance.new('Part', comet.Parent)
CircularSphere2.Material = Enum.Material.Neon
CircularSphere2.Shape = Enum.PartType.Ball
CircularSphere2.Transparency = .5
local CircularSphere3: Part = Instance.new('Part', comet.Parent)
CircularSphere3.Material = Enum.Material.Neon
CircularSphere3.Shape = Enum.PartType.Ball
CircularSphere3.Transparency = .5
CircularSphere3.Anchored = true
CircularSphere2.Anchored = true
CircularSphere1.Anchored = true
local passed = 0
local nextnum = math.random(15,125)
local started = false
local ended = false
local Update = true
game:FindFirstChildOfClass('RunService').Heartbeat:Connect(function(deltatime)
	task.desynchronize()
	passed = passed + deltatime
	if Update then Update = false task.delay(0.05, function() Update = true end) else return end
	-- Calculate new position
	if not ended and getPositionOnOrbit(passed).Y > -10 then
		local newPosition = getPositionOnOrbit(passed)
		started = true
		task.synchronize()
		local trail = comet:Clone()
		trail:ClearAllChildren()
--[[		coroutine.resume(coroutine.create(function()
			while task.wait() and trail do
				task.synchronize()
				trail.CFrame = trail.CFrame * CFrame.Angles(math.random(), math.random(), math.random())
			end
		end))]]
		task.desynchronize()
		local range, bright, colour, a,b,c = math.random() * 20, math.random() * 5, comet.Color:Lerp(Color3.new(math.abs(math.cos(passed/2)),0,1), 1 - (10 ^ (-6 * passed))), .5 + math.random()/2, .5 + math.random()/2, .5 + math.random()/2
		local second,third = colour:Lerp(Color3.new(1,1,1),0.25), colour:Lerp(Color3.new(1,1,1),0.5)
		local s1, s2, s3 = comet.Size * 2 + Vector3.new(math.random() * 2,-math.random() * 2,math.random() * 2), comet.Size * 3 - Vector3.new(-math.random() * 3,math.random() * 3,math.random() * 3), comet.Size * 4 + Vector3.new(math.random() * 4,math.random() * 4,-math.random() * 4)
		local newpos = CFrame.new(newPosition) * CFrame.Angles(math.random(), math.random(), math.random())
		task.synchronize()
		trail.Parent = comet.Parent
		Light.Color = comet.Color
		Light.Range = range
		Light.Brightness = bright
		game:FindFirstChildOfClass('Debris'):AddItem(trail, 1)
		game:FindFirstChildOfClass('TweenService'):Create(trail, TweenInfo.new(1), {Transparency = 1, Size = trail.Size/4, CFrame = trail.CFrame * CFrame.Angles(math.random(), math.random(), math.random())}): Play()
		comet.Color = colour
		CircularSphere1.Transparency = a
		CircularSphere1.Color = colour
		CircularSphere2.Transparency = b
		CircularSphere3.Transparency = c
		CircularSphere2.Color = second
		CircularSphere3.Color = third
		CircularSphere1.Size = s1
		CircularSphere2.Size = s2
		CircularSphere3.Size = s3
		comet.CFrame = newpos
		CircularSphere2.CFrame = newpos
		CircularSphere1.CFrame = newpos
		CircularSphere3.CFrame = newpos
	else
		if started then ended = true end
		if passed > nextnum then	passed -= nextnum started = false ended = false nextnum = math.random(15,125) end
	end
end)
