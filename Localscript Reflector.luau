--This is a Script, Not magic, If the LocalScript depends on the Character as It's Ancestor, It won't work. Link your character through the ID attached to the Folder Instead. for i,v parse loop until you find it or use Folder's Attribute to locate it
--Solivion, 2026
--Reflect Some Camera Script To The Player Backpack Because This Is A Pseudo-Character(It is a model without a Humanoid; not Connected To The Player Directly But Player Got Alternative Control Over)
local Reflected: {[Instance]: Instance} = {}
local ScriptLinkedTo: Model
local Count = 0;
while typeof(ScriptLinkedTo) ~= 'Instance' do
	ScriptLinkedTo = script:FindFirstAncestorWhichIsA('Model')
	Count += task.wait(1)
	if Count > 20 then
		break
	end
end
if typeof(ScriptLinkedTo) ~= 'Instance' then script:Destroy() return end -- [[This script is not associated with a Character]]
local PID: number
local Folder: Folder?
Count = 0;
function CleanUP() pcall(function() if ScriptLinkedTo then ScriptLinkedTo:Destroy() end end) pcall(function() if Folder then Folder:Destroy() end end) script:Destroy() end
while typeof(PID) ~= 'number' and ScriptLinkedTo and ScriptLinkedTo.Parent do
	PID = ScriptLinkedTo and ScriptLinkedTo:GetAttribute('__REGPLRID')
	Count += task.wait(1)
	if Count > 20 then
		break
	end
end
if typeof(PID) ~= 'number' then script:Destroy() return end -- [[This is not the associated Character Type]]
if not ScriptLinkedTo or not ScriptLinkedTo.Parent then CleanUP() end
local Plr: Player?
--GetPlayerFromId but Able to run in Parallel Luau, In case this script got Desynchronized
for i,v in game:GetService('Players'):GetDescendants() do
	if v.ClassName == 'Player' and v.UserId == PID then
		Plr = v
		break
	end
end
if not Plr then CleanUP() return end -- [[invalid character]]
local Foldir = Plr:FindFirstChildOfClass('PlayerScripts') or Plr:FindFirstChildOfClass('Backpack') or Plr:FindFirstChildOfClass('PlayerGui') or Plr
if typeof(Foldir) ~= 'Instance' then CleanUP() return end -- [[invalid Player Structure]]
Folder = Foldir:FindFirstChild('__LINKED_SCRIPTS') or Instance.new('Folder', Foldir) Folder.Name = '__LINKED_SCRIPTS'
if typeof(Folder) ~= 'Instance' or not Folder.Parent then CleanUP() return end
local Hook = {}
function Reflect(Tscript: LocalScript)
	if not Plr or typeof(ScriptLinkedTo) ~= 'Instance' or typeof(ScriptLinkedTo.Parent) ~= 'Instance' or not Plr.Parent or typeof(Folder) ~= 'Instance' or Folder.ClassName ~= 'Folder' or typeof(Foldir) ~= 'Instance' or not Folder:IsDescendantOf(Foldir) or not Folder:IsDescendantOf(Plr) then CleanUP() return end
	if typeof(Tscript) ~= 'Instance' or Tscript.ClassName ~= "LocalScript" or not Tscript:IsDescendantOf(ScriptLinkedTo) then return end
	local ALR = Reflected[Tscript]
	if typeof(ALR) == 'Instance' and ALR:IsDescendantOf(Folder) then return end
	local Cloned = Tscript:Clone() Cloned.Parent = typeof(Tscript:GetActor()) == 'Instance' and Folder:FindFirstChildOfClass('Actor') or Folder
	Reflected[Tscript] = Cloned
	if typeof(Cloned) ~= 'Instance' then return end
	if not Hook[Tscript] then Hook[Tscript] = {} end
	local Clean Clean = function()
		if Hook[Tscript] then
			for i,v in Hook[Tscript] do
				pcall(function()
				if typeof(v) == 'RBXScriptConnection' then
					v:Disconnect()
				end end)
			end
			Hook[Tscript] = nil
		end
		Reflected[Tscript] = nil
		Cloned:Destroy()
		Clean = nil
	end
	Hook[Tscript][1] = Cloned.AncestryChanged:Connect(function()
		if not (typeof(Cloned) == 'Instance' and Cloned.Parent and Cloned:IsDescendantOf(Folder)) then
			Clean()
		end
	end)
	Hook[Tscript][2] = Tscript.AncestryChanged:Once(Clean)
	Hook[Tscript][3] = Tscript.Changed:Connect(function(ChangedName) if typeof(Cloned) == 'Instance' and Cloned.Parent and Cloned:IsDescendantOf(Folder) then pcall(function() Cloned[ChangedName] = Tscript[ChangedName] end) end end)
end

--Recheck
if not Plr or typeof(ScriptLinkedTo) ~= 'Instance' or typeof(ScriptLinkedTo.Parent) ~= 'Instance' or not Plr.Parent or typeof(Folder) ~= 'Instance' or Folder.ClassName ~= 'Folder' or typeof(Foldir) ~= 'Instance' or not Folder:IsDescendantOf(Foldir) or not Folder:IsDescendantOf(Plr) then CleanUP() return end
Folder:ClearAllChildren() -- Unreflect Last
Instance.new("Actor", Folder)
Folder:SetAttribute('ID_SOURCE', PID)
Folder:SetAttribute('FULL_NAME', ScriptLinkedTo:GetFullName())
Folder:SetAttribute('DIRECTORY', ScriptLinkedTo.Parent:GetFullName())
for I,V in ScriptLinkedTo:GetChildren() do
	if V.ClassName == 'Actor' then
		for i,v in V:GetChildren() do
			Reflect(v)
		end
		continue	
	end
	Reflect(V)
end
ScriptLinkedTo.DescendantAdded:Connect(Reflect)