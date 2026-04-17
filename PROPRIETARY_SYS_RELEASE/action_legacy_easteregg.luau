-- diffidentmyle 
--!native
task.wait(1)
if workspace:FindFirstChild('Fun').Value == 0 then repeat task.wait(1) until not workspace:FindFirstChild('Fun') or workspace:FindFirstChild('Fun').Value ~= 0 end
if not workspace:FindFirstChild('Fun') or not (workspace:FindFirstChild('Fun').Value <= 100 and workspace:FindFirstChild('Fun').Value >= 50) then
	script:Destroy()
	return
end
local rate = 1/15
local tablesofid = {}
function uniqueid(number: number) -- to register different freefall that occured so the cancoyotejump will not be disabled for that new fall if u r so fast
	local uniqueid = math.random()
	if uniqueid == number or table.find(tablesofid, uniqueid) then
		repeat if uniqueid == number or table.find(tablesofid, uniqueid) then  uniqueid += math.random() end until not table.find(tablesofid, uniqueid)
	end
	table.insert(tablesofid, uniqueid)
	task.delay(20, function()
		if table.find(tablesofid, uniqueid) then
			table.remove(tablesofid, table.find(tablesofid, uniqueid))
		end
	end)
	return uniqueid
end
local FakeArm = true
local SoundLib = {
	LedgeGrab = {"12222170" -- switch
		,"12222054" -- kerplunk
		,'12221996' -- Flashlight
	},
	Whoops = {"12222152" -- switch
	},
	ClimbingUp = {
		"5567303707",
		"12221831"
	}
}local LedgeCombinationChecker = {
				["0000"] = "Void", 
				["0001"] = "Vault",   
				["0010"] = "Grab",  
				["0011"] = "Grab",
				["0100"] = "Grab", 
				["0101"] = "Climb",  
				["0110"] = "Grab",   
				["0111"] = "Grab", 
				["1000"] = "Void",  
				["1001"] = "Vault",  
				["1010"] = "Climb",    
				["1011"] = "Grab", 
				["1100"] = "Crawl",  
				["1101"] = "Grab",  
				["1110"] = "Void",    
				["1111"] = "Void",  
			}
			local LedgeWhenRunningChecker = {
				["0000"] = "Void", 
				["0001"] = "Void",   
				["0010"] = "Void",  
				["0011"] = "Boost",
				["0100"] = "Void", 
				["0101"] = "Climb",  
				["0110"] = "Void",   
				["0111"] = "Boost", 
				["1000"] = "Void",  
				["1001"] = "Void",  
				["1010"] = "Climb",    
				["1011"] = "Void", 
				["1100"] = "Void",  
				["1101"] = "Boost",  
				["1110"] = "Boost",    
				["1111"] = "Boost",  
			}local combinations = {
			["0000"] = "Nothing", 
			["0001"] = "Nothing",   
			["0010"] = "Nothing",  
			["0011"] = "Nothing",
			["0100"] = "Crawl", 
			["0101"] = "Crawl",  
			["0110"] = "Crawl",   
			["0111"] = "Nothing", 
			["1000"] = "Crouch",  
			["1001"] = "Crawl",  
			["1010"] = "Crawl",    
			["1011"] = "Nothing", 
			["1100"] = "Crawl",  
			["1101"] = "Crawl",  
			["1110"] = "Crawl",    
			["1111"] = "Nothing",  
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
local function Thing(c)
	local SPECIALON = false
	if  c and c:IsA("Model") and c:FindFirstChildOfClass("Humanoid") and not c:GetAttribute("AlreadyFound_Action") then
		task.synchronize()
		c:SetAttribute("Already_Found_Action",true)
		local character = c
		local rayParamsWall = RaycastParams.new()
		rayParamsWall.FilterType = Enum.RaycastFilterType.Exclude
		rayParamsWall.RespectCanCollide = true
		rayParamsWall.IgnoreWater = true
		rayParamsWall.FilterDescendantsInstances = { character } -- Exclude the player's character
		--[[repeat wait()
			if script.CastVisuals then
				break
			end
		until false
		local CastVisuals = require(script.CastVisuals)

		local RaycastVisualiser = CastVisuals.new(Color3.new(1, 1, 1), workspace) -- second arg is the WorldRoot you want the cast to be performed in (optional)
		local BlockcastVisualiser = CastVisuals.new(Color3.new(1, 1, 0))
		local SpherecastVisualiser = CastVisuals.new(Color3.new(1, 0.333333, 0))
		local UnableVisual = CastVisuals.new(Color3.new(0.333333, 0, 0))

		local RaycastVisualiserUp = CastVisuals.new(Color3.new(1, 1, 1), workspace) -- second arg is the WorldRoot you want the cast to be performed in (optional)
		local BlockcastVisualiserUp = CastVisuals.new(Color3.new(1, 1, 0))
		local SpherecastVisualiserUp = CastVisuals.new(Color3.new(1, 0.333333, 0))
		local UnableVisualUp = CastVisuals.new(Color3.new(0.333333, 0, 0))]]

		local rayParamsCrouchableGap = rayParamsWall
		local rayParamsUncrouchableGap = rayParamsWall
		local rayParamsUnpassableWall = rayParamsWall
		
		
		--[[local LGVisual1 = CastVisuals.new(Color3.new(0, 1, 0))
		local LGVisual2 = CastVisuals.new(Color3.new(0, 0, 0.498039))
		local LGVisual3 = CastVisuals.new(Color3.new(0, 0.666667, 1))
		local LGVisual4 = CastVisuals.new(Color3.new(0, 1, 1))
		local LDVisual  = CastVisuals.new(Color3.new(0.666667, 0, 1))]]
		
		local function hasHumanoidSibling(hitResult:RaycastResult,RayDir)
			if hitResult then
				local hitInstance = hitResult.Instance
				if hitInstance then
					local hitParent = hitInstance.Parent
					if hitParent then
						local humanoidSibling = hitParent:FindFirstChildOfClass("Humanoid")
						if not humanoidSibling then
							--print("A Ray Found "..hitInstance.Name)
							return true
						else
							--print("A Ray Found A Humanoid Sibling. casting Further")
							-- Cast a new ray from the hit position and check if it hits a humanoid
							local hitPosition = hitResult.Position
							local Calid = RaycastParams.new()
							Calid.FilterType = Enum.RaycastFilterType.Exclude
							Calid.RespectCanCollide = true
							Calid.IgnoreWater = true task.synchronize()
							Calid.FilterDescendantsInstances = { character, hitParent, hitInstance } -- Exclude the player's character, and also the part
							task.desynchronize()
							local newRaycastResult = workspace:Raycast(hitPosition, RayDir * (5- hitResult.Distance), rayParamsWall)
							if newRaycastResult then
								local newHitInstance = newRaycastResult.Instance
								if newHitInstance then
									local newHitParent = newHitInstance.Parent
									if newHitParent then
										local newHumanoidSibling = newHitParent:FindFirstChildOfClass("Humanoid")
										if not newHumanoidSibling then
											--print("Casting Further found a valid part")
											return true
										else
											--print("Casting Further found an Invalid part")
											return false
										end
									end
								end
							else
								--print("Casting Further found an Invalid part")
								return false -- If no hit, consider it as having no humanoid sibling
							end
						end
					end
				end
			end
			return false -- If a humanoid sibling is found, return false
		end
		local function checkObstacles()
			task.desynchronize()
			local characterRoot = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
			--	local playerCamera = workspace.CurrentCamera

			if characterRoot then
				local rayStart = characterRoot.Position
				local rayDir = characterRoot.CFrame.LookVector -- Cast ray in the direction the player is looking
				local rayDirUp = characterRoot.CFrame.UpVector -- Cast ray in the direction the player is looking

				local hitWall = workspace:Raycast(rayStart + Vector3.new(0, 1.5, 0), rayDir * 5,rayParamsWall)
				local hitCrouchableGap = workspace:Raycast(rayStart + Vector3.new(0, 0.5, 0), rayDir * 5,rayParamsCrouchableGap)
				local hitUncrouchableGap = workspace:Raycast(rayStart + Vector3.new(0, -1, 0), rayDir * 5,rayParamsUncrouchableGap)
				local hitUnpassableWall = workspace:Raycast(rayStart + Vector3.new(0, -2, 0), rayDir * 5,rayParamsUnpassableWall)

				local hitWallUp = workspace:Raycast(rayStart + Vector3.new(0, 1.5, 0), rayDirUp * 2,rayParamsWall)
				local hitCrouchableGapUp = workspace:Raycast(rayStart + Vector3.new(0, 0.5, 0), rayDirUp * 1.5,rayParamsCrouchableGap)
				local hitUncrouchableGapUp = workspace:Raycast(rayStart + Vector3.new(0, -1, 0), rayDirUp * 1.5,rayParamsUncrouchableGap)
				local hitUnpassableWallUp = workspace:Raycast(rayStart + Vector3.new(0, -2, 0), rayDirUp * 0.5,rayParamsUnpassableWall)
				
				local hitWallUpForward = workspace:Raycast(rayStart + rayDir * Vector3.new(0,0,5) + Vector3.new(0, 1.5, 0), rayDirUp * 2,rayParamsWall)
				local hitCrouchableGapUpForward = workspace:Raycast(rayStart + rayDir * Vector3.new(0,0,5) + Vector3.new(0, 0.5, 0), rayDirUp * 1.5,rayParamsCrouchableGap)
				local hitUncrouchableGapUpForward = workspace:Raycast(rayStart + rayDir * Vector3.new(0,0,5) + Vector3.new(0, -1, 0), rayDirUp * 1.5,rayParamsUncrouchableGap)
				local hitUnpassableWallUpForward = workspace:Raycast(rayStart + rayDir * Vector3.new(0,0,5) + Vector3.new(0, -2, 0), rayDirUp * 0.5,rayParamsUnpassableWall)
				--[[task.synchronize()
				RaycastVisualiser:Raycast(rayStart + Vector3.new(0, 1.5, 0), rayDir * 5,rayParamsWall)
				BlockcastVisualiser:Raycast(rayStart + Vector3.new(0, 0.5, 0), rayDir * 5,rayParamsCrouchableGap)
				SpherecastVisualiser:Raycast(rayStart + Vector3.new(0, -1, 0), rayDir * 5,rayParamsUncrouchableGap)
				UnableVisual:Raycast(rayStart + Vector3.new(0, -2, 0), rayDir * 5,rayParamsUnpassableWall)
				RaycastVisualiserUp:Raycast(rayStart + rayDir * Vector3.new(0,0,2.5)  + Vector3.new(0, 1.5, 0), rayDirUp * 2,rayParamsWall)
				BlockcastVisualiserUp:Raycast(rayStart + rayDir * Vector3.new(0,0,2.5)  + Vector3.new(0, 0.5, 0), rayDirUp * 1.5,rayParamsCrouchableGap)
				SpherecastVisualiserUp:Raycast(rayStart + rayDir * Vector3.new(0,0,2.5)  + Vector3.new(0, -1, 0), rayDirUp * 1.5,rayParamsUncrouchableGap)
				UnableVisualUp:Raycast(rayStart + rayDir * Vector3.new(0,0,2.5)  + Vector3.new(0, -2, 0), rayDirUp * 0.5,rayParamsUnpassableWall)
				task.desynchronize()]]
				local ray1Result = (hasHumanoidSibling(hitWall,rayDir) or hasHumanoidSibling(hitWallUp,rayDir)) and 1 or 0
				local ray2Result = (hasHumanoidSibling(hitCrouchableGap,rayDir) or hasHumanoidSibling(hitCrouchableGapUp,rayDir)) and 1 or 0
				local ray3Result = (hasHumanoidSibling(hitUncrouchableGap,rayDir) or hasHumanoidSibling(hitUncrouchableGapUp,rayDir)) and 1 or 0
				local ray4Result = (hasHumanoidSibling(hitUnpassableWall,rayDir) or hasHumanoidSibling(hitUnpassableWallUp,rayDir)) and 1 or 0
				if hitWall then
					if hitWall.Instance and hitWall.Instance:IsA("BasePart") and ( (hitWall.Instance:FindFirstAncestorWhichIsA("Model") and hitWall.Instance:FindFirstAncestorWhichIsA("Model"):FindFirstChildOfClass("Humanoid")) or (hitWall.Instance:FindFirstAncestorWhichIsA("Model"):FindFirstAncestorWhichIsA("Model") and hitWall.Instance:FindFirstAncestorWhichIsA("Model"):FindFirstAncestorWhichIsA("Model"):FindFirstChildOfClass("Humanoid"))) then
						ray1Result = 0
						--print("ray1 Invalid")
					end
				end
				if hitCrouchableGap then
					if hitCrouchableGap.Instance and hitCrouchableGap.Instance:IsA("BasePart") and ( (hitCrouchableGap.Instance:FindFirstAncestorWhichIsA("Model") and hitCrouchableGap.Instance:FindFirstAncestorWhichIsA("Model"):FindFirstChildOfClass("Humanoid")) or (hitCrouchableGap.Instance:FindFirstAncestorWhichIsA("Model"):FindFirstAncestorWhichIsA("Model") and hitCrouchableGap.Instance:FindFirstAncestorWhichIsA("Model"):FindFirstAncestorWhichIsA("Model"):FindFirstChildOfClass("Humanoid"))) then
						ray2Result = 0
						--print("ray2 Invalid")
					end
				end
				if hitUncrouchableGap then
					if hitUncrouchableGap.Instance and hitUncrouchableGap.Instance:IsA("BasePart") and ( (hitUncrouchableGap.Instance:FindFirstAncestorWhichIsA("Model") and hitUncrouchableGap.Instance:FindFirstAncestorWhichIsA("Model"):FindFirstChildOfClass("Humanoid")) or (hitUncrouchableGap.Instance:FindFirstAncestorWhichIsA("Model"):FindFirstAncestorWhichIsA("Model") and hitUncrouchableGap.Instance:FindFirstAncestorWhichIsA("Model"):FindFirstAncestorWhichIsA("Model"):FindFirstChildOfClass("Humanoid"))) then
						ray3Result = 0
						--print("ray3 Invalid")
					end
				end
				if hitUnpassableWall then
					if hitUnpassableWall.Instance and hitUnpassableWall.Instance:IsA("BasePart") and ( (hitUnpassableWall.Instance:FindFirstAncestorWhichIsA("Model") and hitUnpassableWall.Instance:FindFirstAncestorWhichIsA("Model"):FindFirstChildOfClass("Humanoid")) or (hitUnpassableWall.Instance:FindFirstAncestorWhichIsA("Model"):FindFirstAncestorWhichIsA("Model") and hitUnpassableWall.Instance:FindFirstAncestorWhichIsA("Model"):FindFirstAncestorWhichIsA("Model"):FindFirstChildOfClass("Humanoid"))) then
						ray4Result = 0
						--print("ray4 Invalid")
					end
				end
				local combination = tostring(ray1Result) .. tostring(ray2Result) .. tostring(ray3Result) .. tostring(ray4Result)
				task.synchronize()				
				if combinations[combination] then
					--	if character:FindFirstChild("Trigger") then
					task.synchronize()	
					if character:FindFirstChild("Crouching") and not SPECIALON then
						if not hasHumanoidSibling(hitWallUp,rayDir) and not hasHumanoidSibling(hitUncrouchableGapUp,rayDir) and not hasHumanoidSibling(hitCrouchableGapUp,rayDir) and not hasHumanoidSibling(hitUnpassableWallUp,rayDir) and not hasHumanoidSibling(hitUncrouchableGapUpForward,rayDirUp) and not hasHumanoidSibling(hitCrouchableGapUpForward,rayDirUp) and not hasHumanoidSibling(hitUnpassableWallUpForward,rayDirUp) and not hasHumanoidSibling(hitWallUpForward,rayDirUp) then
							--print(combinations[combination],
							--	combination
							--)
						if character:FindFirstChild("Crouching") then
							task.synchronize()	
							--print("Found String Value "..character:FindFirstChild("Crouching"):GetFullName())
							character:FindFirstChild("Crouching").Value = combinations[combination]
						end
							--character:FindFirstChild("Trigger"):FireServer(combinations[combination])
						else
							task.synchronize()	
							if (hasHumanoidSibling(hitCrouchableGapUp,rayDir) or hasHumanoidSibling(hitWallUp,rayDir) or hasHumanoidSibling(hitWallUpForward,rayDirUp) or hasHumanoidSibling(hitCrouchableGapUpForward,rayDirUp)) and not hasHumanoidSibling(hitUncrouchableGapUpForward,rayDirUp) and not hasHumanoidSibling(hitUncrouchableGapUp,rayDir) and not hasHumanoidSibling(hitUnpassableWallUp,rayDir)then
								--print("Crouching Under A Part")
							if character:FindFirstChild("Crouching") then
								task.synchronize()	
								--print("Found String Value "..character:FindFirstChild("Crouching"):GetFullName())
								character:FindFirstChild("Crouching").Value = "Crouch"
							end
								--character:FindFirstChild("Trigger"):FireServer("Crouch")
							elseif (hasHumanoidSibling(hitCrouchableGapUp,rayDir) and hasHumanoidSibling(hitUncrouchableGapUp,rayDir)) or hasHumanoidSibling(hitUncrouchableGapUp,rayDir) or hasHumanoidSibling(hitUnpassableWallUpForward,rayDirUp) or hasHumanoidSibling(hitUncrouchableGapUpForward,rayDirUp) or hasHumanoidSibling(hitUnpassableWallUp,rayDir) then
								--print("Crawling Under A Part")
							if character:FindFirstChild("Crouching") then
								task.synchronize()	
								--print("Found String Value "..character:FindFirstChild("Crouching"):GetFullName())
								character:FindFirstChild("Crouching").Value = "Crawl"
								end
							end
						end
					end
				else
					--print("Unable To Consider An Action",combination)
				end
				task.desynchronize()	
			end
		end
		local CanGrab = true
		local BoostCooldown = false
		local ClimbRope = nil
		local processed = true
		local currentid = uniqueid(0)
		
		local CheckLedge = function()
			task.desynchronize()
			if character:FindFirstChildOfClass("Tool") and character:FindFirstChildOfClass("Tool"):FindFirstChildOfClass("BasePart") then
				return
			end
			local RH = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm") or character:FindFirstChild("Left Arm")
			local LH =character:FindFirstChild("LeftHand") or character:FindFirstChild("Left Arm") or character:FindFirstChild("Right Arm")
			local TS =character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso") or character:FindFirstChild("HumanoidRootPart")
			
			local characterRoot = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
			--	local playerCamera = workspace.CurrentCamera
			if characterRoot and CanGrab == true and character:FindFirstChildOfClass("Humanoid") and character:FindFirstChildOfClass("Humanoid").FloorMaterial == Enum.Material.Air  then
		--		print("Found Root")
				local curid = uniqueid(currentid)
				currentid = curid
				local CastPos = characterRoot.Position
				--<<Direction>>--
				local Front = characterRoot.CFrame.LookVector
				local Up = characterRoot.CFrame.UpVector
				local Down = -characterRoot.CFrame.UpVector
				local Right = characterRoot.CFrame.RightVector
				local Left = -characterRoot.CFrame.RightVector
				--<<Raycast>>--
				local FirstWallCheck1 = workspace:Raycast(CastPos + Vector3.new(0, -2, 0), Front * 5,rayParamsWall)
				local FirstWallCheck2 = workspace:Raycast(CastPos + Vector3.new(0, 0, 0), Front * 5,rayParamsWall)
				local FirstWallCheck3 = workspace:Raycast(CastPos + Vector3.new(0, 2, 0), Front * 5,rayParamsWall)
				local FirstWallCheck4 = workspace:Raycast(CastPos + Vector3.new(0, 4, 0), Front * 5,rayParamsWall)
				--<<Visual>>--
				--[[task.synchronize()
				LGVisual1:Raycast(CastPos + Vector3.new(0, -1.5, 0), Front * 5,rayParamsWall)
				LGVisual2:Raycast(CastPos + Vector3.new(0, 0, 0), Front * 5,rayParamsWall)
				LGVisual3:Raycast(CastPos + Vector3.new(0, 1.5, 0), Front * 5,rayParamsWall)
				LGVisual4:Raycast(CastPos + Vector3.new(0,3, 0), Front * 5,rayParamsWall)
				task.desynchronize()]]
				--<<Result>>--
				if currentid ~= curid then return end
				local ray1Result = (FirstWallCheck1 and hasHumanoidSibling(FirstWallCheck1,Front)) and 1 or 0 --Lowest Ray
				local ray2Result = (FirstWallCheck2 and hasHumanoidSibling(FirstWallCheck2,Front)) and 1 or 0 --Lower Ray
				local ray3Result = (FirstWallCheck3 and hasHumanoidSibling(FirstWallCheck3,Front)) and 1 or 0 --Higher Ray
				local ray4Result = (FirstWallCheck4 and hasHumanoidSibling(FirstWallCheck4,Front)) and 1 or 0 --Highest Ray
				
				--pcall(function()
					if FirstWallCheck1 then
						if FirstWallCheck1 ~= nil and typeof(FirstWallCheck1) == "RaycastResult" and  FirstWallCheck1.Instance and FirstWallCheck1.Instance:IsA("BasePart") and (  FirstWallCheck1.Instance.Transparency == 1 or (FirstWallCheck1.Instance:FindFirstAncestorWhichIsA("Model") and FirstWallCheck1.Instance:FindFirstAncestorWhichIsA("Model"):FindFirstChildOfClass("Humanoid")) or (FirstWallCheck1.Instance:FindFirstAncestorWhichIsA("Model"):FindFirstAncestorWhichIsA("Model") and FirstWallCheck1.Instance:FindFirstAncestorWhichIsA("Model"):FindFirstAncestorWhichIsA("Model"):FindFirstChildOfClass("Humanoid"))) then
							ray1Result = 0
							--print("ray1 Invalid")
						end
					end
					if FirstWallCheck2 then
						if FirstWallCheck2 ~= nil and typeof(FirstWallCheck2) == "RaycastResult" and FirstWallCheck2.Instance and FirstWallCheck2.Instance:IsA("BasePart") and ( FirstWallCheck2.Instance.Transparency == 1 or (FirstWallCheck2.Instance:FindFirstAncestorWhichIsA("Model") and FirstWallCheck2.Instance:FindFirstAncestorWhichIsA("Model"):FindFirstChildOfClass("Humanoid")) or (FirstWallCheck2.Instance:FindFirstAncestorWhichIsA("Model"):FindFirstAncestorWhichIsA("Model") and FirstWallCheck2.Instance:FindFirstAncestorWhichIsA("Model"):FindFirstAncestorWhichIsA("Model"):FindFirstChildOfClass("Humanoid"))) then
							ray2Result = 0
							--print("ray2 Invalid")
						end
					end
					if FirstWallCheck3 then
						if FirstWallCheck3 ~= nil and typeof(FirstWallCheck3) == "RaycastResult" and FirstWallCheck3.Instance and FirstWallCheck3.Instance:IsA("BasePart") and ( FirstWallCheck3.Instance.Transparency == 1 or (FirstWallCheck3.Instance:FindFirstAncestorWhichIsA("Model") and FirstWallCheck3.Instance:FindFirstAncestorWhichIsA("Model"):FindFirstChildOfClass("Humanoid")) or (FirstWallCheck3.Instance:FindFirstAncestorWhichIsA("Model"):FindFirstAncestorWhichIsA("Model") and FirstWallCheck3.Instance:FindFirstAncestorWhichIsA("Model"):FindFirstAncestorWhichIsA("Model"):FindFirstChildOfClass("Humanoid"))) then
							ray3Result = 0
							--print("ray3 Invalid")
						end
					end
					if FirstWallCheck4 then
						if FirstWallCheck4 ~= nil and typeof(FirstWallCheck4) == "RaycastResult"  and FirstWallCheck4.Instance and FirstWallCheck4.Instance:IsA("BasePart") and ( FirstWallCheck4.Instance.Transparency == 1 or (FirstWallCheck4.Instance:FindFirstAncestorWhichIsA("Model") and FirstWallCheck4.Instance:FindFirstAncestorWhichIsA("Model"):FindFirstChildOfClass("Humanoid")) or (FirstWallCheck4.Instance:FindFirstAncestorWhichIsA("Model"):FindFirstAncestorWhichIsA("Model") and FirstWallCheck4.Instance:FindFirstAncestorWhichIsA("Model"):FindFirstAncestorWhichIsA("Model"):FindFirstChildOfClass("Humanoid"))) then
							ray4Result = 0
							--print("ray4 Invalid")
						end
					end
				--end)
				local CurrentLedgeCombination = tostring(ray4Result) .. tostring(ray3Result) .. tostring(ray2Result) .. tostring(ray1Result)
				--[[if character:FindFirstChild("Crouching") and character:FindFirstChild("Crouching"):GetAttribute("Running") and character:FindFirstChild("Crouching"):GetAttribute("Running") == true then
					if LedgeWhenRunningChecker[CurrentLedgeCombination] then
						local ChosenResult = nil
						local FirstNotNil,SecondNotNil = string.find(CurrentLedgeCombination,"01")
						if FirstNotNil and SecondNotNil then
							if SecondNotNil == 2 then
								ChosenResult = FirstWallCheck3
							elseif SecondNotNil == 3 then
								ChosenResult = FirstWallCheck2
							elseif SecondNotNil == 4 then
								ChosenResult = FirstWallCheck1
							end
						end
						if LedgeWhenRunningChecker[CurrentLedgeCombination] == "Boost"  then
							task.synchronize()
							character:FindFirstChild("Crouching"):SetAttribute("SpecialState",true)
							SPECIALON = true
							if characterRoot.Velocity.Magnitude > 16 and not characterRoot:FindFirstChild("BoostUp") and not BoostCooldown and ChosenResult ~= nil and ChosenResult.Instance then
								characterRoot.Velocity = Vector3.new(0,50,0)
								ClimbRope = Instance.new("RopeConstraint",characterRoot)
								ClimbRope.Name = "BoostUp"
								ClimbRope.Attachment1 = TS:FindFirstChild("WaistCenterAttachment") or  RH:FindFirstChild("RightGripAttachment") or Instance.new("Attachment",RH)
								BoostCooldown = true
								task.wait(5)
								BoostCooldown = false
								ClimbRope:Destroy()
								ClimbRope = nil
							else
								if BoostCooldown and ClimbRope ~= nil and ClimbRope:IsA("RopeConstraint") and ChosenResult ~= nil and ChosenResult.Instance then
									--Roping Sim
									local newA = Instance.new("Attachment", ChosenResult.Instance)
									newA.CFrame = characterRoot.CFrame:toObjectSpace(CFrame.new(ChosenResult.Position))
									newA.Name = "OFFSET"
									newA.Visible = true
									ClimbRope.Attachment0 = newA
									ClimbRope.Visible = true
									game:FindFirstChildOfClass('Debris'):AddItem(newA,10)
								end
							end
							character:FindFirstChildOfClass("Humanoid").AutoRotate = true
						elseif LedgeWhenRunningChecker[combinations] == "Climb" then
							task.synchronize()
							SPECIALON = true
							character:FindFirstChild("Crouching"):SetAttribute("SpecialState",true)
							character:FindFirstChild("Crouching").Value = "Climbing"
						else
							task.synchronize()
							SPECIALON = false
							character:FindFirstChild("Crouching"):SetAttribute("SpecialState",false)
						end
						task.desynchronize()
					end
				else
					task.synchronize()
					SPECIALON = false
					character:FindFirstChild("Crouching"):SetAttribute("SpecialState",false)
					task.desynchronize()
				end]]
				if LedgeCombinationChecker[CurrentLedgeCombination] then
					if LedgeCombinationChecker[CurrentLedgeCombination] == "Grab" and CanGrab then
						local ChosenResult = nil
						local FirstNotNil,SecondNotNil = string.find(CurrentLedgeCombination,"01")
						if FirstNotNil and SecondNotNil then
							if SecondNotNil == 2 then
								ChosenResult = FirstWallCheck3
							elseif SecondNotNil == 3 then
								ChosenResult = FirstWallCheck2
							elseif SecondNotNil == 4 then
								ChosenResult = FirstWallCheck1
							end
						end
						--task.synchronize()
						--characterRoot.CFrame = CFrame.new(characterRoot.Position,ChosenResult.Position)
						task.desynchronize()
						if ChosenResult ~= nil then
							if currentid ~= curid then return end
						--	print("Print Used "..5-SecondNotNil.."'s Cast Result")
							local SecondWallCheckDown = workspace:Raycast(Vector3.new(ChosenResult.Position.X,ChosenResult.Position.Y + 3, ChosenResult.Position.Z), Down * 5,rayParamsWall)
							task.synchronize()
							--LDVisual:Raycast(Vector3.new(ChosenResult.Position.X,ChosenResult.Position.Y + -3, ChosenResult.Position.Z), Down * 5,rayParamsWall)
							if SecondWallCheckDown and SecondWallCheckDown.Instance == ChosenResult.Instance and (SecondWallCheckDown.Position.Y - characterRoot.Position.Y) > 1.5 then
								if not CanGrab or not processed then
									return
								end
								local look = CFrame.new(TS.Position,SecondWallCheckDown.Position)
							--	TS.CFrame = CFrame.new(TS.Position)  * CFrame.Angles(look.Rotation.X,0,look.Rotation.Z)
								character:FindFirstChildOfClass("Humanoid").AutoRotate = false
								CanGrab = false
								processed = false
								--print("Found Valid Part")
								coroutine.resume(coroutine.create(function()
									if FakeArm == true then
										if RH then
											RH.Transparency = 1
										end
										if LH then
											LH.Transparency = 1
										end
									else
										if RH then
											RH.Transparency = 0
										end
										if LH then
											LH.Transparency = 0
										end
									end
									if FakeArm == true then
										task.synchronize()
										RH = RH:Clone()
										RH.Parent = character
										LH = LH:Clone()
										LH.Parent = character
										if RH then
											RH.Transparency = 0
										end
										if LH then
											LH.Transparency = 0
										end
									--	task.desynchronize()
									end
								
									for index,joint in pairs(character:GetDescendants()) do -- Mostly Copied The Same Code And Pasted. lol
									if joint:IsA("JointInstance") and (string.match(string.upper(joint.Name),"Shoulder") or joint.Part1 == LH or joint.Part0 == RH or joint.Part1 == RH or joint.Part0 == LH or joint.Name == "Left Shoulder" or joint.Name == "Right Shoulder") and not joint.Parent:FindFirstChild(joint.Name.."RopeConnect")  then
										if not joint.Parent:FindFirstChild(joint.Name.."RopeConnect") then
											local socket = Instance.new("RopeConstraint",joint.Parent)
											--socket.LimitsEnabled = true
											local a1 = Instance.new("Attachment")
											local a2 = Instance.new("Attachment")
											a1.Visible = false
											a2.Visible = false
											a1.Parent = joint.Part0
											if FakeArm then
												if joint.Part1.Name == RH.Name then
													a2.Parent = RH
												elseif joint.Part1.Name == LH.Name then
													a2.Parent = LH
												end
											else
												a2.Parent = joint.Part1	
											end 
											socket.Attachment0 = a1
											socket.Attachment1 = a2
											a1.CFrame = joint.C0
											a2.CFrame = joint.C1
											socket.Length = 2
											socket.WinchTarget = 1
											socket.WinchResponsiveness = 1
											socket.Restitution = 0	
											socket.Visible = false
											socket.Color = BrickColor.Red()
											socket.Name = joint.Name.."RopeConnect"
											socket.Enabled = false
												local socket2 = Instance.new("RodConstraint",joint.Parent)
												socket2.LimitsEnabled = true
												socket2.Attachment0 = a1
												socket2.Attachment1 = a2
												socket2.Name = joint.Name.."AEwf"
												socket2.Enabled = true
												socket2.Length = 0.5
											--end		
										else
											joint.Parent:FindFirstChild(joint.Name.."RopeConnect").Enabled = true
										end
										if joint.Enabled == true then
											joint:SetAttribute("WasOn",true)
										else
											joint:SetAttribute("WasOn",false)
										end		
										joint.Enabled = false	
										--[[elseif joint:IsA('BasePart') then
											if joint.Name ~= "HumanoidRootPart" then
												joint.CanCollide = false
											end]]
										end
									end
										
								end))
								local vector = --[[(CFrame.new(characterRoot.Position) * CFrame.new(characterRoot.Position,SecondWallCheckDown.Position))]]TS.CFrame:VectorToObjectSpace(Vector3.new(2.5,0.25,-0.25))
								local altvector = --[[(CFrame.new(characterRoot.Position) * CFrame.new(characterRoot.Position,SecondWallCheckDown.Position))]]TS.CFrame:VectorToObjectSpace(Vector3.new(-2.5,0.25,-0.25))
								local NewAttachmentLeftPart = Instance.new("Attachment",SecondWallCheckDown.Instance or workspace)
								local NewAttachmentRightPart = Instance.new("Attachment",SecondWallCheckDown.Instance  or workspace)
								local NewAttachmentLeftHand = (LH and LH:FindFirstChild("LeftGripAttachment")) or (RH and RH:FindFirstChild("RightGripAttachment")) or Instance.new("Attachment",LH)
								local NewAttachmentRightHand =  (RH and RH:FindFirstChild("RightGripAttachment")) or (LH and LH:FindFirstChild("LeftGripAttachment")) or Instance.new("Attachment",RH)
								if not ChosenResult.Instance then
									NewAttachmentRightPart.CFrame = CFrame.new(SecondWallCheckDown.Position )+ vector
									NewAttachmentLeftPart.CFrame = CFrame.new(SecondWallCheckDown.Position )+ altvector
								else
									NewAttachmentRightPart.CFrame = ChosenResult.Instance.CFrame:toObjectSpace(CFrame.new(SecondWallCheckDown.Position )+ vector) or CFrame.new(0,0,0)
									NewAttachmentLeftPart.CFrame = ChosenResult.Instance.CFrame:toObjectSpace(CFrame.new(SecondWallCheckDown.Position)+ altvector) or CFrame.new(0,0,0)
								end
								task.desynchronize()
								local SlopeCheckRight = workspace:Raycast(NewAttachmentRightPart.WorldPosition+ Vector3.new(0,5,0) --[[+ vector]],Vector3.new(0,-1,0) * 10,rayParamsWall)
								local SlopeCheckLeft = workspace:Raycast(NewAttachmentLeftPart.WorldPosition + Vector3.new(0,5,0) --[[+ altvector]],Vector3.new(0,-1,0) * 10,rayParamsWall)
								task.synchronize()
								if SlopeCheckRight then
									if SlopeCheckRight.Instance then
										if SlopeCheckRight.Instance ~= SecondWallCheckDown.Instance then
											NewAttachmentRightPart:Destroy()
											NewAttachmentRightPart = Instance.new("Attachment", SlopeCheckRight.Instance  or workspace)
										end
										NewAttachmentRightPart.CFrame = SlopeCheckRight.Instance.CFrame:toObjectSpace(CFrame.new(SlopeCheckRight.Position ))
										sound(1,"LedgeGrab",NewAttachmentRightPart)
									else
										NewAttachmentRightPart:Destroy()
										NewAttachmentRightPart = Instance.new("Attachment", workspace)
										NewAttachmentRightPart.CFrame = SlopeCheckRight.Position
										sound(1,"LedgeGrab",NewAttachmentRightPart)
									end
								else
									local CheckRightTheSecond = workspace:Raycast(NewAttachmentRightPart.WorldPosition+ (NewAttachmentRightPart.WorldPosition - SecondWallCheckDown.Position).Unit * -5--[[+ vector]],(NewAttachmentRightPart.WorldPosition - SecondWallCheckDown.Position).Unit * 15,rayParamsWall)
									if CheckRightTheSecond then
										NewAttachmentRightPart.CFrame = CheckRightTheSecond.Instance.CFrame:toObjectSpace(CFrame.new(CheckRightTheSecond.Position ))
										sound(1,"LedgeGrab",NewAttachmentRightPart)
									else
										local CheckRightTheThird = workspace:Raycast(NewAttachmentRightPart.WorldPosition+ (NewAttachmentRightPart.WorldPosition - SecondWallCheckDown.Position).Unit * 5--[[+ vector]],(NewAttachmentRightPart.WorldPosition - SecondWallCheckDown.Position).Unit * -15,rayParamsWall)
										if CheckRightTheThird then
											NewAttachmentRightPart.CFrame = CheckRightTheThird.Instance.CFrame:toObjectSpace(CFrame.new(CheckRightTheThird.Position ))
											sound(1,"LedgeGrab",NewAttachmentRightPart)
										else
											sound(1,"Whoops",RH)
											NewAttachmentRightPart:Destroy()
										end
									end
								--[[	NewAttachmentRightPart:Destroy()
									NewAttachmentRightPart = NewAttachmentRightHand:Clone()
									NewAttachmentRightPart.Name = "AyoThisIsADulp"
									NewAttachmentRightPart.Parent = NewAttachmentRightHand.Parent]]
								end
								if SlopeCheckLeft then
									if SlopeCheckLeft.Instance then
										if SlopeCheckLeft.Instance ~= SecondWallCheckDown.Instance then
											NewAttachmentLeftPart:Destroy()
											NewAttachmentLeftPart = Instance.new("Attachment",SlopeCheckLeft.Instance)
										end	
										NewAttachmentLeftPart.CFrame = SlopeCheckLeft.Instance.CFrame:toObjectSpace(CFrame.new(SlopeCheckLeft.Position ))
										sound(1,"LedgeGrab",NewAttachmentLeftPart)
									else
										NewAttachmentLeftPart:Destroy()
										NewAttachmentLeftPart = Instance.new("Attachment",workspace)
										NewAttachmentLeftPart.CFrame = SlopeCheckLeft.Position
										sound(1,"LedgeGrab",NewAttachmentLeftPart)
									end
								else
									local CheckLeftTheSecond = workspace:Raycast(NewAttachmentLeftPart.WorldPosition+ (NewAttachmentLeftPart.WorldPosition - SecondWallCheckDown.Position).Unit * -5--[[+ vector]],(NewAttachmentLeftPart.WorldPosition - SecondWallCheckDown.Position).Unit * 15,rayParamsWall)
									if CheckLeftTheSecond then
										NewAttachmentLeftPart.CFrame = CheckLeftTheSecond.Instance.CFrame:toObjectSpace(CFrame.new(CheckLeftTheSecond.Position ))
										sound(1,"LedgeGrab",NewAttachmentLeftPart)
									else
										local CheckLeftTheThird = workspace:Raycast(NewAttachmentLeftPart.WorldPosition+ (NewAttachmentLeftPart.WorldPosition - SecondWallCheckDown.Position).Unit * 5--[[+ vector]],(NewAttachmentLeftPart.WorldPosition - SecondWallCheckDown.Position).Unit * -15,rayParamsWall)
										if CheckLeftTheThird then
											NewAttachmentLeftPart.CFrame = CheckLeftTheThird.Instance.CFrame:toObjectSpace(CFrame.new(CheckLeftTheThird.Position ))
											sound(1,"LedgeGrab",NewAttachmentLeftPart)
										else
											sound(1,"Whoops",LH)
											NewAttachmentLeftPart:Destroy()
										end
									end
									--[[if NewAttachmentRightPart.Name ~= "AyoThisIsADulp" then
										NewAttachmentLeftPart:Destroy()
										NewAttachmentLeftPart = NewAttachmentLeftHand:Clone()
										NewAttachmentLeftPart.Parent = NewAttachmentLeftHand.Parent
										NewAttachmentLeftPart.Name = "AyoThisIsADulp"
									end]]
								end
								NewAttachmentLeftPart .Visible = true --[[NewAttachmentRightHand .Visible = true]] NewAttachmentRightPart .Visible = true --NewAttachmentLeftHand .Visible = true
								local RopeRight = Instance.new("RopeConstraint",RH or character)
								--if NewAttachmentRightHand ~= nil then
									RopeRight.Attachment0 = ((NewAttachmentRightPart.WorldPosition - NewAttachmentRightHand.WorldPosition).Magnitude < (NewAttachmentLeftPart.WorldPosition - NewAttachmentRightHand.WorldPosition).Magnitude and NewAttachmentRightPart ) or NewAttachmentLeftPart or NewAttachmentRightHand
									RopeRight.Attachment1 = (NewAttachmentRightHand.WorldPosition - RopeRight.Attachment0.WorldPosition).Magnitude < 10 and NewAttachmentRightHand or nil
								--end
								RopeRight.Enabled = true
								RopeRight.Visible = false
								RopeRight.Restitution = 0
								RopeRight.WinchResponsiveness = 1
								RopeRight.WinchEnabled = false
								RopeRight.WinchForce = 10 or Vector3.new(10,10,10)
								RopeRight.Length = 0.5 or (NewAttachmentRightPart.WorldPosition - NewAttachmentRightHand.WorldPosition).Magnitude
								RopeRight.Name = "weldright"
								local RopeLeft = Instance.new("RopeConstraint",LH or character)
								--if NewAttachmentLeftHand ~= nil then
									RopeLeft.Attachment0 = ((RopeRight.Attachment0 ~= NewAttachmentRightPart and NewAttachmentRightPart) or NewAttachmentLeftPart) or (((NewAttachmentLeftPart.WorldPosition - NewAttachmentLeftHand.WorldPosition).Magnitude < (NewAttachmentRightPart.WorldPosition - NewAttachmentLeftHand.WorldPosition).Magnitude and NewAttachmentLeftPart ) or NewAttachmentRightPart) or NewAttachmentLeftHand
									RopeLeft.Attachment1 = (NewAttachmentLeftHand.WorldPosition - RopeLeft.Attachment0.WorldPosition).Magnitude < 10 and NewAttachmentLeftHand or nil
								--end
								RopeLeft.Enabled = true
								RopeLeft.Visible = false
								RopeLeft.Restitution = 0
								RopeLeft.WinchResponsiveness = 1
								RopeLeft.WinchEnabled = false
								RopeLeft.WinchForce = 10 or Vector3.new(10,10,10)
								RopeLeft.Length = 0.5 or (NewAttachmentLeftPart.WorldPosition - NewAttachmentLeftHand.WorldPosition).Magnitude
								RopeLeft.Name = "weldleft"
								RopeLeft.Enabled = false
								local weldr = Instance.new("Weld",character)
								weldr.Part1 = RH
								weldr.Part0 = TS
								weldr.Enabled = false
								local weldl = Instance.new("Weld",character)
								weldl.Part1 = LH
								weldl.Part0 = TS
								weldl.Enabled = false
								task.wait(0.1)
								--local propconnect = character:FindFirstChildOfClass("Humanoid").Changed:Once(function(thing)
								--if CanGrab or processed then
								--	return
								--end
								local Pos = CFrame.new(SecondWallCheckDown.Position) + Vector3.new(0,5,0) or CFrame.new(NewAttachmentRightPart.WorldPosition) + Vector3.new(0,5,0) or CFrame.new(NewAttachmentLeftPart.WorldPosition) + Vector3.new(0,5,0) or CFrame.new(characterRoot.Position) + Vector3.new(0,5,0)
								Pos = (CFrame.new(Pos.Position) * characterRoot.CFrame.Rotation  + 2.5 * (characterRoot.CFrame.LookVector * Vector3.new(0,0,1)))  or CFrame.new(characterRoot.Position)
								if Pos.X == (nil or math.huge ) or Pos.Y == (nil or math.huge ) or Pos.Z == (nil or math.huge ) or Pos.XVector == (nil or math.huge ) or Pos.YVector == (nil or math.huge ) or Pos.ZVector == (nil or math.huge )  then
									Pos = CFrame.new(characterRoot.Position)
								end
								local Coroute = coroutine.create(function()
									while weldr and weldl and NewAttachmentLeftPart and NewAttachmentRightPart and Pos ~= nil and game["Run Service"].Heartbeat:Wait() do
										--characterRoot.CFrame = characterRoot.CFrame:Lerp(Pos,0.1)
										if RH then
											RH.CanCollide = false
										end
										if LH then
											LH.CanCollide = false
										end
										TS.CanCollide = false
										characterRoot.CanCollide = false
										weldr.C1 = weldr.C1:Lerp(CFrame.new(0,0,0) * CFrame.lookAt(weldr.Part0.Position , NewAttachmentLeftPart.WorldPosition).Rotation ,0.3)
										weldl.C1 = weldl.C1:Lerp(CFrame.new(0,0,0) * CFrame.lookAt(weldl.Part0.Position , NewAttachmentLeftPart.WorldPosition).Rotation,0.3) 
									end
								end)
								if character:FindFirstChildOfClass("Humanoid"):GetState() == Enum.HumanoidStateType.Running or character:FindFirstChildOfClass("Humanoid"):GetState() == Enum.HumanoidStateType.Jumping or character:FindFirstChildOfClass("Humanoid"):GetState() == Enum.HumanoidStateType.Flying or character:FindFirstChildOfClass("Humanoid"):GetState() == Enum.HumanoidStateType.FallingDown or character:FindFirstChildOfClass("Humanoid"):GetState() == Enum.HumanoidStateType.Ragdoll or character:FindFirstChildOfClass("Humanoid"):GetState() == Enum.HumanoidStateType.Dead or character:FindFirstChildOfClass("Humanoid"):GetState() == Enum.HumanoidStateType.Freefall or character:FindFirstChildOfClass("Humanoid").Jump == true or character:FindFirstChildOfClass("Humanoid").FloorMaterial ~= (Enum.Material.Air and Enum.Material.Water)  or character:FindFirstChildOfClass("Humanoid").Sit == true  or character:FindFirstChildOfClass("Humanoid").PlatformStand == true then
									for i,v in character:GetChildren() do
										if v == RH or v == LH or v == TS then
											v.CanCollide = false
										end
									end
									if weldr then
										weldr.Enabled = false
									end
									if weldl then
										weldl.Enabled = false
									end
									coroutine.resume(Coroute)
									if RH and RH:FindFirstChild("RopeConnect") then
											RH:FindFirstChild("RopeConnect").Length = 0.5
											RH:FindFirstChild("RopeConnect").Enabled = false
										end
									if LH and LH:FindFirstChild("RopeConnect") then
											LH:FindFirstChild("RopeConnect").Length = 0.5
											LH:FindFirstChild("RopeConnect").Enabled = false
										end
									if LH and LH:FindFirstChild("AEwf") then
											LH:FindFirstChild("AEwf").Length = 0.5
											LH:FindFirstChild("AEwf").Enabled = true
										end
										if RopeRight then
										RopeRight.Length = 1
										RopeRight.Enabled = true
										--RopeRight.WinchEnabled = true
										end
										if RopeLeft then
										RopeLeft.Length = 1
										RopeLeft.Enabled = true
										--RopeLeft.WinchEnabled = true
										end
									if not tweein and not tweening and Pos ~= nil and (NewAttachmentLeftPart or NewAttachmentRightPart) then
										sound(1,"ClimbingUp",TS)
										tweein = true
										tweening = game:FindFirstChildOfClass('TweenService'):Create(TS,TweenInfo.new(0.5,Enum.EasingStyle.Exponential,Enum.EasingDirection.In),{CFrame = Pos})
										tweening:Play()
										local tweening2 = game:FindFirstChildOfClass('TweenService'):Create(characterRoot,TweenInfo.new(0.5,Enum.EasingStyle.Exponential,Enum.EasingDirection.In),{CFrame = Pos})
										tweening2:Play()
											coroutine.resume(coroutine.create(
												function() tweening.Completed:Connect(function()
														tweein = false tweening = nil
													end)	end))
										end
										--thing:Play()
									--thing.Completed:Wait()
									task.wait(0.5)
									characterRoot.AssemblyLinearVelocity = Vector3.new(0,50,50)* characterRoot.CFrame.LookVector
										characterRoot.CFrame = Pos					
										coroutine.close(Coroute)
										characterRoot.CFrame = Pos
									characterRoot.AssemblyLinearVelocity = Vector3.new(0,50,25) * characterRoot.CFrame.LookVector
										NewAttachmentLeftPart:Destroy()
										NewAttachmentRightPart:Destroy()
										if RH:FindFirstChild("RopeConnect") then
											RH:FindFirstChild("RopeConnect"):Destroy()
										end
										if LH:FindFirstChild("RopeConnect") then
											LH:FindFirstChild("RopeConnect"):Destroy()
										end
										if RopeRight then
											RopeRight:Destroy()
										end
										if RopeLeft then
											RopeLeft:Destroy()
										end				
									if weldr then
										weldr:Destroy()
									end
									if weldl then
										weldl:Destroy()
									end	
									repeat
										task.wait(0.1)
										characterRoot.AssemblyLinearVelocity = Vector3.new(0,50,0)
										characterRoot.CFrame = Pos
									until characterRoot.CFrame == Pos
									characterRoot.AssemblyLinearVelocity = Vector3.new(0,50,0)
										coroutine.resume(coroutine.create(function()
											for index,joint in pairs(character:GetDescendants()) do -- Mostly Copied The Same Code And Pasted. lol
												if joint:GetAttribute("WasOn") and joint:GetAttribute("WasOn") == true then
													joint.Enabled = true
													joint:SetAttribute("WasOn",nil)
												end
												if string.find(joint.Name,"RopeConnect") then
													joint:Destroy()
											end
											if string.find(joint.Name,"AEwf") then
												joint:Destroy()
											end
										end
									end))
									processed = true
									RH.CanCollide = true
									LH.CanCollide = true
									TS.CanCollide = true
									for i,v in character:GetChildren() do
										if v == RH or v == LH or v == TS then
											v.CanCollide = true
										end
									end
									if FakeArm then
										task.synchronize()
										RH:Destroy()
										LH:Destroy()
										local RH = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm") or character:FindFirstChild("Left Arm")
										local LH =character:FindFirstChild("LeftHand") or character:FindFirstChild("Left Arm") or character:FindFirstChild("Right Arm")
										if RH then
											RH.Transparency = 0
										end
										if LH then
											LH.Transparency = 0
										end
										task.desynchronize()
									end
									task.synchronize()
									character:FindFirstChildOfClass("Humanoid").AutoRotate = true
									task.wait(1.5)
									CanGrab = true return
								end
								
								--end)
								--character:FindFirstChildOfClass("Humanoid").Jumping:Once(function()
								--	task.wait(1)
								----	propconnect:Disconnect()
								--end)
								--[[coroutine.resume(coroutine.create(function()
									while not CanGrab and game["Run Service"].Stepped:Wait() do
										for i,v in character:GetChildren() do
											if v:IsA("BasePart") then
												v.CanCollide = false
											end
										end
									end
								end))]]
								
								--while character:FindFirstChildOfClass("Humanoid") and character:FindFirstChildOfClass("Humanoid").WalkDirection.Magnitude > 0 do
								--end
							end
						end
					elseif LedgeCombinationChecker[CurrentLedgeCombination] == "Vault" then
						--print("Can Vault")
						local FirstNotNil,SecondNotNil = string.find(CurrentLedgeCombination,"01")
						if FirstNotNil and SecondNotNil then
							if SecondNotNil == 2 then

							elseif SecondNotNil == 3 then

							elseif SecondNotNil == 4 then

							end
						end		
					end
				end
			end
		end
		task.synchronize()
		while character and character.Parent and task.wait(rate) do
			task.desynchronize()
			if not character then return end
			if character:FindFirstChildOfClass("Humanoid") and (table.find({Enum.HumanoidStateType.Dead},character:FindFirstChildOfClass("Humanoid"):GetState()) or character:FindFirstChildOfClass("Humanoid").Health <= 0) then return end
			--[[if character:FindFirstChildOfClass("Humanoid") and character:FindFirstChildOfClass("Humanoid"):GetState() == (Enum.HumanoidStateType.Physics or Enum.HumanoidStateType.Ragdoll or Enum.HumanoidStateType.PlatformStanding or Enum.HumanoidStateType.Flying or Enum.HumanoidStateType.FallingDown or Enum.HumanoidStateType.Climbing) then
				
			end]]
			--[[if character:FindFirstChildOfClass("Humanoid") and character:FindFirstChildOfClass("Humanoid"):GetState() == Enum.HumanoidStateType.Running and character:FindFirstChildOfClass("Humanoid").RootPart.Velocity.Magnitude > 0 then
				--checkObstacles()
			else]]
			if character:FindFirstChildOfClass("Humanoid") and table.find({Enum.HumanoidStateType.Freefall, Enum.HumanoidStateType.Jumping},character:FindFirstChildOfClass("Humanoid"):GetState()) and (character:FindFirstChildOfClass("Humanoid").Jump or character:FindFirstChildOfClass("Humanoid").MoveDirection.Magnitude >= 0.1) then
				CheckLedge()
			end
		--[[	if  and  and c then
				--print("Checking Obstacle")
			--	checkObstacles()
				
			else
				return
				-- break
			end]]
			--CheckLedge()

		end
		
	end
end
	-- Listen for user input to check for obstacles
coroutine.resume(coroutine.create(function()
	for i, v in pairs(workspace:GetDescendants())  do
		if v:IsA("Model") and v:FindFirstChildOfClass("Humanoid") then
			Thing(v)
			--print("Checking Ledge")
		end
	end
end))
workspace.DescendantAdded:Connect(function(c)
	Thing(c)
end)