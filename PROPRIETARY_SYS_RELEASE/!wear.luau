-- Accessory Wearer - BindableEvent Request System
-- Usage: Fire the event with action name and arguments
-- Events: "Wear", "RemoveAll", "GetAccessories", "FixHandle"
-- assistant

local AccessoryWearer = {}

-- Create the BindableEvent for requests
local RequestEvent = script:FindFirstChildOfClass('BindableEvent')
if not RequestEvent then
	RequestEvent = Instance.new("BindableEvent")
	RequestEvent.Name = "Event"
	RequestEvent.Parent = script
end

-- R6 Attachment positions mapped by part name and attachment name
local R6_ATTACHMENTS = {
	Head = {
		HairAttachment = Vector3.new(0, 0.6, 0),
		HatAttachment = Vector3.new(0, 0.6, 0),
		FaceFrontAttachment = Vector3.new(0, 0, -0.6),
		FaceCenterAttachment = Vector3.new(0, 0, 0),
	},
	Torso = {
		NeckAttachment = Vector3.new(0, 1, 0),
		BodyFrontAttachment = Vector3.new(0, 0, -0.5),
		BodyBackAttachment = Vector3.new(0, 0, 0.5),
		LeftCollarAttachment = Vector3.new(-1, 1, 0),
		RightCollarAttachment = Vector3.new(1, 1, 0),
		WaistFrontAttachment = Vector3.new(0, -1, -0.5),
		WaistCenterAttachment = Vector3.new(0, -1, 0),
		WaistBackAttachment = Vector3.new(0, -1, 0.5),
	},
	["Left Arm"] = {
		LeftShoulderAttachment = Vector3.new(0, 1, 0),
		LeftGripAttachment = Vector3.new(0, -1, 0),
	},
	["Right Arm"] = {
		RightShoulderAttachment = Vector3.new(0, 1, 0),
		RightGripAttachment = Vector3.new(0, -1, 0),
	},
	["Left Leg"] = {
		LeftFootAttachment = Vector3.new(0, -1, 0),
	},
	["Right Leg"] = {
		RightFootAttachment = Vector3.new(0, -1, 0),
	},
	HumanoidRootPart = {
		RootAttachment = Vector3.new(0, 0, 0),
	},
}

-- FindFirstChildOfNameAndClass
local function FFCAC(parent: Instance, namePattern: string, className: string): Instance?
	if typeof(parent) ~= "Instance" then return nil end
	if typeof(namePattern) ~= "string" then return nil end
	if typeof(className) ~= "string" then return nil end
	
	for _, child in parent:GetChildren() do
		local a, isC = pcall(function()
			return child:IsA(className) -- asking IsA an impossible class might result in error
		end)
		if child.Name:match(namePattern) and ((a and isC) or child.ClassName == className) then
			return child
		end
	end
	return nil
end
AccessoryWearer.FFCAC = FFCAC

-- Map attachment names to body parts
local ATTACHMENT_TO_PART = {
	HairAttachment = "Head",
	HatAttachment = "Head",
	FaceFrontAttachment = "Head",
	FaceCenterAttachment = "Head",
	NeckAttachment = "Torso",
	BodyFrontAttachment = "Torso",
	BodyBackAttachment = "Torso",
	LeftCollarAttachment = "Torso",
	RightCollarAttachment = "Torso",
	WaistFrontAttachment = "Torso",
	WaistCenterAttachment = "Torso",
	WaistBackAttachment = "Torso",
	LeftShoulderAttachment = "Left Arm",
	LeftGripAttachment = "Left Arm",
	RightShoulderAttachment = "Right Arm",
	RightGripAttachment = "Right Arm",
	LeftFootAttachment = "Left Leg",
	RightFootAttachment = "Right Leg",
	RootAttachment = "HumanoidRootPart",
}

-- Extract asset ID from URL or return the number directly
local function parseAssetId(input: number | string): number?
	if type(input) == "number" then
		return input
	end
	if type(input) == "string" then
		local id
		pcall(function()
		id = input:match("catalog/(%d+)")
			or input:match("assets/(%d+)")
			or input:match("asset/(%d+)")
			or input:match("marketplace/asset/(%d+)")
			or input:match("%?id=(%d+)")
			or input:match("^(%d+)$")
end)
		if id then
			return tonumber(id)
		end
	end

	return nil
end

-- Ensure a part has the required attachment, create if missing
local function ensureAttachment(part: BasePart, attachmentName: string, position: Vector3): Attachment?
	if typeof(part) ~= "Instance" or not part:IsA("BasePart") then return nil end
	if typeof(attachmentName) ~= "string" then return nil end
	if typeof(position) ~= "Vector3" then return nil end
	
	local existingAttachment = FFCAC(part, "^" .. attachmentName .. "$", "Attachment")
	if existingAttachment then
		return existingAttachment
	end

	local attachment = Instance.new("Attachment")
	attachment.Name = attachmentName
	attachment.Position = position
	attachment.Parent = part
	return attachment
end

-- Ensure all R6 attachments exist on the character
local function ensureCharacterAttachments(character: Model): boolean
	if typeof(character) ~= "Instance" then return false end
	
	-- Check for R15 (incompatible)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local upperTorso = FFCAC(character, "UpperTorso", "BasePart")
	if humanoid and upperTorso then
		warn("AccessoryWearer: R15 characters are not supported")
		return false
	end
	
	for partName, attachments in pairs(R6_ATTACHMENTS) do
		local part = FFCAC(character, "^" .. partName .. "$", "BasePart")
		if part then
			for attachmentName, position in pairs(attachments) do
				ensureAttachment(part, attachmentName, position)
			end
		end
	end
	return true
end

-- Get the attachment point info from an accessory handle
local function getAccessoryAttachmentInfo(handle: BasePart): (string?, Vector3?, Vector3?)
	if typeof(handle) ~= "Instance" or not handle:IsA("BasePart") then return nil, nil, nil end
	
	local attachment = FFCAC(handle, ".+", "Attachment")
	if attachment then
		return attachment.Name, attachment.Position, attachment.Orientation
	end
	return nil, nil, nil
end

-- Find the matching body part and attachment for an accessory
local function findMatchingAttachment(character: Model, attachmentName: string): (BasePart?, Attachment?)
	if typeof(character) ~= "Instance" then return nil, nil end
	if typeof(attachmentName) ~= "string" then return nil, nil end
	
	local partName = ATTACHMENT_TO_PART[attachmentName]
	if not partName then
		warn("AccessoryWearer: Unknown attachment name: " .. attachmentName)
		return nil, nil
	end

	local part = FFCAC(character, "^" .. partName .. "$", "BasePart")
	if not part then
		-- Debug: List available parts
		local availableParts = {}
		for _, child in pairs(character:GetChildren()) do
			if child:IsA("BasePart") then
				table.insert(availableParts, child.Name)
			end
		end
		warn("AccessoryWearer: Part '" .. partName .. "' not found for attachment '" .. attachmentName .. "'. Available parts: " .. table.concat(availableParts, ", "))
		return nil, nil
	end

	local attachment = FFCAC(part, "^" .. attachmentName .. "$", "Attachment")
	if not attachment then
		local position = R6_ATTACHMENTS[partName] and R6_ATTACHMENTS[partName][attachmentName]
		if position then
			attachment = ensureAttachment(part, attachmentName, position)
		end
	end

	return part, attachment
end
function isBeforePublicUGC(date)
	if typeof(date) ~= 'string' then return false end
	-- Parse ISO date directly (Roblox supports this)
	local createdDate = DateTime.fromIsoDate(date)

	local cutoffDate = DateTime.fromUniversalTime(2023, 3, 24, 0, 0, 0)

	return createdDate.UnixTimestamp < cutoffDate.UnixTimestamp
end
-- Check if character is R6
local function isR6(character: Model): boolean
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.RigType == Enum.HumanoidRigType.R6 then
		return true
	end
	if FFCAC(character, "^Torso$", "BasePart") and not FFCAC(character, "UpperTorso", "BasePart") then
		return true
	end
	return false
end

-- Manual weld function (complex system)
local function manualWeldAccessory(character: Model, accessory: Instance, handle: BasePart): boolean
	-- Get attachment info
	local attachmentName = getAccessoryAttachmentInfo(handle)
	if not attachmentName then
		attachmentName = "HatAttachment"
	end

	-- Ensure character has all required attachments
	ensureCharacterAttachments(character)

	-- Find matching body part and attachment
	local bodyPart, bodyAttachment = findMatchingAttachment(character, attachmentName)

	if not bodyPart or not bodyAttachment then
		warn("AccessoryWearer: Could not find matching attachment for " .. attachmentName)
		return false
	end

	-- Set handle properties
	task.defer(function()
		handle.CanCollide = false
		handle.CanTouch = false
		handle.Massless = true
	end)

	-- Create a Weld
	local weld = Instance.new("Weld")
	weld.Name = "AccessoryWeld"
	weld.Part0 = bodyPart
	weld.Part1 = handle

	local handleAttachment = FFCAC(handle, "^" .. attachmentName .. "$", "Attachment")
	if handleAttachment then
		weld.C0 = CFrame.new(bodyAttachment.Position)
		weld.C1 = CFrame.new(handleAttachment.Position)
	else
		weld.C0 = CFrame.new(bodyAttachment.Position)
		weld.C1 = CFrame.new(0, 0, 0)
	end

	weld.Parent = handle
	return true
end

local AllowedType = {8,
	41,
	42,
	43,
	44,
	45,
	46,
	47}
-- Main function to wear an accessory
function AccessoryWearer.Wear(character: Model, accessoryId: number | string, player): Instance?
	-- Type checking
	if typeof(character) ~= "Instance" then
		warn("AccessoryWearer: Invalid character argument")
		return nil
	end
	if typeof(accessoryId) ~= 'string' and typeof(accessoryId) ~= 'number' then
		warn("AccessoryWearer: Missing accessoryId argument")
		return nil
	end

	-- Parse the accessory ID
	local parsedId = parseAssetId(accessoryId)
	if typeof(parsedId) ~= 'number' then
		warn("AccessoryWearer: Could not parse accessory ID from input: " .. tostring(accessoryId))
		return nil
	end
	local passed = false
	local Mark, yay = pcall(function() return game:GetService('MarketplaceService'):GetProductInfoAsync(parsedId) end)
	passed = Mark and typeof(yay) == 'table' and ((typeof(yay.AssetTypeId) == 'number' and table.find(AllowedType, yay.AssetTypeId)) or (typeof(yay.AssetTypeId) == 'string' and table.find(AllowedType, tonumber(yay.AssetTypeId) or 0)) or (typeof(yay.AssetTypeId) == 'EnumItem' and table.find(AllowedType, yay.AssetTypeId.Value)))
	pcall(function()
		if typeof(yay.Creator) ~= 'table' or yay.Creator.HasVerifiedBadge ~= true then  passed = false end
		if passed and (tonumber(yay.Creator.Id or 0) ~= 1 and yay.IsForSale ~= true) then 
			if typeof(player) == 'Instance' then 
			local a, b = pcall(function()
					return game:GetService('MarketplaceService'):PlayerOwnsAssetAsync(player, parsedId or nil)
				end) if not (a and b) then
					
						passed = false
				end
			else passed = false end
		end -- they don't want to publish it? then don't. Roblox Event items are usually offsale and from OFFICIAL Roblox account
	end)
	pcall(function()
		if passed and workspace.Name:lower():match('standard') and not isBeforePublicUGC(yay.Created) then
			passed = false
		end
	end)
	if not passed then return end
	-- Load the accessory using InsertService
	local InsertService = game:GetService("InsertService")
	local success, asset = pcall(function()
		return InsertService:LoadAsset(parsedId)
	end)

	if not success then
		warn("AccessoryWearer: Failed to load accessory with ID " .. tostring(parsedId) .. ": " .. tostring(asset))
		return nil
	end

	-- Find the accessory using FFCAC
	local accessory = FFCAC(asset, ".+", "Accessory") or FFCAC(asset, ".+", "Hat") 
	
	if not accessory then
		for _, child in pairs(asset:GetChildren()) do
			if child:IsA("Model") then
				accessory = FFCAC(child, ".+", "Accessory") or FFCAC(child, ".+", "Hat")
				if accessory then break end
			end
		end
	end
	
	if not accessory then
		for _, child in pairs(asset:GetChildren()) do
			if FFCAC(child, "Handle", "BasePart") then
				accessory = child
				break
			end
		end
	end

	if not accessory then
		warn("AccessoryWearer: No accessory found in loaded asset")
		asset:Destroy()
		return nil
	end

	-- Get the handle using FFCAC
	local handle = FFCAC(accessory, "Handle", "BasePart")
	if not handle then
		for _, child in pairs(accessory:GetDescendants()) do
			if child:IsA("BasePart") then
				handle = child
				break
			end
		end
	end

	if not handle then
		warn("AccessoryWearer: No handle found in accessory")
		accessory:Destroy()
		asset:Destroy()
		return nil
	end

	-- Check for Humanoid
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local characterIsR6 = isR6(character)

	if humanoid then
		-- Try simple method: let Humanoid handle it
		accessory.Parent = character

		-- Wait 0.5s and check if AccessoryWeld was created
		task.wait(0.5)

		local existingWeld = FFCAC(handle, "AccessoryWeld", "Weld")
			or FFCAC(handle, "AccessoryWeld", "Motor6D")
			or handle:FindFirstChildOfClass("Weld")
			or handle:FindFirstChildOfClass("Motor6D")

		if existingWeld then
			-- Humanoid successfully welded it
			-- Clean up
			if asset ~= accessory and asset ~= handle then
				asset:Destroy()
			end
			return accessory
		end

		-- No weld created, check if R6
		if characterIsR6 then
			-- Fallback to manual welding for R6
			if manualWeldAccessory(character, accessory, handle) then
				-- Clean up
				if asset ~= accessory and asset ~= handle then
					asset:Destroy()
				end
				return accessory
			else
				accessory:Destroy()
				asset:Destroy()
				return nil
			end
		else
			-- R15 but no weld - something went wrong
			warn("AccessoryWearer: Humanoid did not create weld for R15 character")
			accessory:Destroy()
			asset:Destroy()
			return nil
		end
	else
		-- No Humanoid, use manual welding
		accessory.Parent = character

		if manualWeldAccessory(character, accessory, handle) then
			-- Clean up
			if asset ~= accessory and asset ~= handle then
				asset:Destroy()
			end
			return accessory
		else
			accessory:Destroy()
			asset:Destroy()
			return nil
		end
	end
end

-- Remove all accessories
function AccessoryWearer.RemoveAllAccessories(character: Model): number
	if typeof(character) ~= "Instance" then return 0 end
	
	local count = 0
	local toRemove = {}
	
	for _, child in pairs(character:GetChildren()) do
		if child:IsA("Accessory") or child:IsA("Hat") then
			table.insert(toRemove, child)
			count = count + 1
		elseif child:IsA("Model") then
			if FFCAC(child, "Handle", "BasePart") then
				table.insert(toRemove, child)
				count = count + 1
			end
		end
	end
	
	for _, item in pairs(toRemove) do
		item:Destroy()
	end
	
	return count
end

-- Get all accessories
function AccessoryWearer.GetAccessories(character: Model): {Instance}
	if typeof(character) ~= "Instance" then return {} end

	local accessories = {}
	for _, child in pairs(character:GetChildren()) do
		if child:IsA("Accessory") or child:IsA("Hat") then
			table.insert(accessories, child)
		elseif child:IsA("Model") then
			if FFCAC(child, "Handle", "BasePart") then
				table.insert(accessories, child)
			end
		end
	end
	return accessories
end

-- Fix handle properties
function AccessoryWearer.FixHandleProperties(accessory: Instance): boolean
	if typeof(accessory) ~= "Instance" then return false end

	local handle = FFCAC(accessory, "Handle", "BasePart")
	if handle then
		handle.CanCollide = false
		handle.CanTouch = false
		handle.Massless = true
		return true
	end
	return false
end

-- BindableEvent handler
local function handleRequest(action: string, ...)
	local args = {...}
	
	if action == "Wear" then
		local character = args[1]
		local accessoryId = args[2]
		local plr = args[3]
		if typeof(plr) ~= 'Instance' then
			plr = nil
		end
		local result = AccessoryWearer.Wear(character, accessoryId, plr)
	elseif action == "RemoveAll" then
		local character = args[1]
		local count = AccessoryWearer.RemoveAllAccessories(character)
	elseif action == "GetAccessories" then
		local character = args[1]
		local accessories = AccessoryWearer.GetAccessories(character)
	elseif action == "FixHandle" then
		local accessory = args[1]
		local success = AccessoryWearer.FixHandleProperties(accessory)
	else
		warn("AccessoryWearer: Unknown action: " .. tostring(action))
	end
end

RequestEvent.Event:Connect(handleRequest)

-- Export events
AccessoryWearer.RequestEvent = RequestEvent
return AccessoryWearer