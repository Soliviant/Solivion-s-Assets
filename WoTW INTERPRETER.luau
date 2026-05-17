-- PROJ NAME: WoTW ~ Worst of The Worst
-- It's Lacking. you can't stack {} or do condition without being in main thread. Will leak memory if you don't keep track of things. and orders of operation are not respecting (), just parsed.
-- By @Soliviant, May 2026
-- Looking back at it, yeah, I can do all of it, but my brain lagged so hard I misplaced so many things(and I can't spot enough of it) and had to come bac k and fix it.
-- Stat: a bit stable, Last Commit 5/17/2026
--im bad at metatable ToT, I never realized it was this useful at making local Environment and Global Env Seperated and can Index to each other

local Codes = "x=1;y=2;z={};z[fuckyou]={};z.fuckyou[k]=1;u can index table too;z[a]=2;z[b]=~(x==1 & y==2);z[c]=(a=number);Solivion; #x=$(@x@*@a@+12); #y=$(@y@+1); end; z[d]=3;z:c(a=67,b=61,c=41); y = $(@x@+1);z[b]=~(x==1 & y==2);this is an if line;~(x>0) #y=1; end;v=~(y<2);"	
--[[CORE]]
function Verbose(...) print(...) end -- to silence, please comment the print()
local _SYNTAXES = {"<", ">", "=", "+", "-", "!", "(", ")", "{", "}", ":", ";", "#", ".", "[", "]", ",", "/", "^" , "~", "|", "'", "&", "*", "$", "%"}
local _MATH = {"^" ,"+", "-","*","/", "%"}
local _TGLINST = {"!", "|", "@"} -- INSTANTLY TOGGLED MATH(EXECUTE WHEN PARSED TO WITHOUT WAIT), ! is NEGATE, "|" ABS, @ IS FOR DEFINING VARIABLE IN THE MIDDLE OF EQUATION
--$ wraps math
--# States Global Modification In Local_ENV(function, et cetera)
--! mean NOT
--; Seperate the commands, type random ass bs between this mf and it is considered a comment
--{} Make Variable a Table
--"() end" wraps Initiating New Function
--"." Indicate Depth Pathing
--"," Seperates Values and Table Shit
--math stuff is math stuff here, just executed by String order rather than rulebooks.
--"=" Is an ASSIGNER
--"==", "!=" condit
--"~" means an IF statement(I'll check infront of () if there is a ~ to take it as if operation instead of function) ~(Condition) --[[outside of = functions will require ts]] end, can do ~() @ ValIfTrue ? ValIfFalse on = functions, can also be Variable = ~(Conditions) for alternative boolean method
--Condition doesn't respect () because I can't imagine suffering through syntax recursion.
--ternary isn't real
--There are no class laws here, no const, nothing, this is running on Luau. if it "errors" means you somehow managed to fail Luau itself.
--& and | or, condition ill run in Steps and will check iteratively trough string and condition order until false.
--@ Warps parser to the letter location
--Every if statement and while loops will also trigger Function and Environment wrapper to store local Variables and keep them local
--Might be inaccurate but I just use it like that. anyway this took me 3 fucking days, enjoy.

function _SHS(STR: string) -- string HAS syntax?
	if typeof(STR) ~= 'string' or STR == '' then return end
	for i,v in _SYNTAXES do if string.match(STR, '%'..v) then return true end end
	return false
end
function Struct(Parent: {}, StructureKey: string, ValuePack: string) -- must be assigned to something
	if typeof(Parent) ~= 'table' then warn('Invalid Structure Parent!') return end
	if typeof(StructureKey) ~= 'string' or _SHS(StructureKey) or StructureKey == '' then warn('Invalid Structure Assignment!') return end
	local Structure = {}
	if typeof(ValuePack) == 'string' then
		--- parse pre keyed Values here.
	end
	Structure = {
		Values={}, -- . To Access Too, Structure[Key]=Val; to Set, to differentiate Pathing and Writing to path 
		_Function={}, -- . To Acess, .Key(arg=value, arg2=value2...) to Run(it wwill package things between () into an Array for u when firing the Run), "Structure[Key]=(varname=val type arg) end" to set things inside this table, same for below, but below is immutable. .Function() will prioritize from Immutable list first. but writing will only go to this _Function
		_Inner={Clone = function() return table.clone(Structure) end,DoesIt = function(NameORClass: string, ClassIfName: string?, Verbose:boolean?) if typeof(NameORClass) ~= 'string' then warn('you need string as the first argument to use this function!') return end if typeof(Structure) ~= 'table' or typeof(Structure.Values) ~= 'table' then warn("Failed To Parse Instance's Children, Doesn't Exist!") return end for i,v in Structure.Values do if (typeof(v) == NameORClass or i == NameORClass) and (typeof(ClassIfName) ~= 'string' or ClassIfName == '' or ClassIfName == typeof(v)) then if Verbose then Verbose('Found!',NameORClass,typeof(ClassIfName) == "string" and " with class ", typeof(ClassIfName) == 'string' and ClassIfName or '[[Undefined]]') end return v end end 
			local mt = getmetatable(Structure.Values) while typeof(mt) == 'table' and typeof(mt.__index) == 'table' do
				for i, v in mt.__index do if (typeof(v) == NameORClass or i == NameORClass) and (typeof(ClassIfName) ~= 'string' or ClassIfName == '' or ClassIfName == typeof(v)) then
						if Verbose then Verbose('Found!', NameORClass, typeof(ClassIfName) == "string" and " with class from ascending order",typeof(ClassIfName) == 'string' and ClassIfName or '[[Undefined]]') end
						return v
					end
				end mt = getmetatable(mt.__index) end warn('Not Found!',NameORClass,typeof(ClassIfName) == "string" and " with class ", typeof(ClassIfName) == 'string' and ClassIfName) end, Clear = function() if typeof(Structure) ~= 'table' then warn("Failed To Parse Instance's Children, Doesn't Exist!") return --[[nil return to signal non-existence]] end Structure._Function = {} Structure.Values = {} end, GetValues = function() return Structure.Values end, Delete = function() if typeof(Parent) == 'table' and typeof(Parent.Values) == 'table' and Parent.Values[StructureKey] == Structure then Parent.Values[StructureKey] = nil Structure = nil else warn("Failed To Parse Instance's Children, Doesn't Exist!") end end},
		Parent = Parent, Name = StructureKey
	}
	Parent.Values[StructureKey] = Structure
	return Structure
end
local _ROOT = Struct({Values={}}, "_ROOT") -- assigned to a stray table outside of environment
function Math(MString: string, ENV: {}?) -- sorry I'm kinda lazy at shrinking the thing
	if typeof(MString) ~= 'string' then return end
	local AccumulatedNum = ""
	local CurVal
	local lastSym 
	local IsInPointerState = false -- @ triggered
	local AccumString = "" -- i need to find a way to trigger this so It works, like some kind of insane shit, I'll use @ to signal start and end @Navigatable Directory@
	local lastWasSym = false
	if string.sub(MString, 1, 1) == "$" then MString = string.sub(MString, 2) end
	if string.sub(MString, 1, 1) == "(" then MString = string.sub(MString, 2) end
	if string.sub(MString, -1, -1) == ")" then MString = string.sub(MString, 1,-2) end
	local newM = ""
	for i = 1, string.len(MString) do
		local sub = string.sub(MString, i,i)
		if sub ~= "@" and not IsInPointerState then newM = newM..sub continue end
		if not IsInPointerState then
			if sub == '@' then
				AccumString = ''
				IsInPointerState = true
				continue
			end
		else
			if sub == '@' then
				IsInPointerState = false
				local Addnew = tostring(retVal(AccumString, ENV)) or ''
				Verbose("Arg Found For ", AccumString, 'IS', Addnew, 'will be added at the back of ', newM)
				newM = newM..Addnew
				AccumString = ''
				continue
			end
			AccumString = AccumString..sub
		end
	end
	Verbose(MString, '->', newM)
	MString = newM
	local long = string.len(MString)
	for i = 1, long do
		local sub = string.sub(MString, i,i)
		if tonumber(sub) then
			if lastWasSym then lastWasSym = false AccumulatedNum = '' end
			AccumulatedNum = AccumulatedNum..sub
			continue
		end
		if table.find(_TGLINST, sub) then
			if typeof(CurVal) ~= 'number' then
				CurVal = tonumber(AccumulatedNum) or 0
				AccumulatedNum = ''
			end  
			-- finish this operation that came before. it wasn't executed yet, and needed immediate execution
			if lastSym == '+' then
				CurVal += tonumber(AccumulatedNum) or 0
			elseif lastSym == '-' then
				CurVal -= tonumber(AccumulatedNum) or 0
			elseif lastSym == '*' then
				CurVal *= tonumber(AccumulatedNum) or 1
			elseif lastSym == '/' then
				CurVal /= tonumber(AccumulatedNum) or 1
			elseif lastSym == '^' then
				CurVal ^= tonumber(AccumulatedNum) or 1
			elseif lastSym == '%' then
				CurVal %= tonumber(AccumulatedNum) or 1
			end 
			AccumulatedNum = ''
			lastSym=nil
				if sub == '!' then
					CurVal = -CurVal 
				elseif sub == '@' then
					CurVal = math.sign(CurVal)
				elseif sub == '|' then
					CurVal = math.abs(CurVal)
			end 
			continue 
		end
		if table.find(_MATH, sub) then
			lastWasSym = true
			if typeof(lastSym) ~= 'string' and typeof(CurVal) ~= 'number' then
				lastSym = sub 
				CurVal = tonumber(AccumulatedNum) or 0
				AccumulatedNum = ''
			else
				if lastSym == '+' then
					CurVal += tonumber(AccumulatedNum) or 0
				elseif lastSym == '-' then
					CurVal -= tonumber(AccumulatedNum) or 0
				elseif lastSym == '*' then
					CurVal *= tonumber(AccumulatedNum) or 1
				elseif lastSym == '/' then
					CurVal /= tonumber(AccumulatedNum) or 1
				elseif lastSym == '^' then
					CurVal ^= tonumber(AccumulatedNum) or 1
				elseif lastSym == '%' then
					CurVal %= tonumber(AccumulatedNum) or 1
				end 
				AccumulatedNum = ''
				lastSym = sub 
			end
		end
	end
	if AccumulatedNum ~= "" and not lastSym then warn("The math operation has a residue! ",AccumulatedNum) end
	if lastSym == '+' then
		CurVal += tonumber(AccumulatedNum) or 0
	elseif lastSym == '-' then
		CurVal -= tonumber(AccumulatedNum) or 0
	elseif lastSym == '*' then
		CurVal *= tonumber(AccumulatedNum) or 1
	elseif lastSym == '/' then
		CurVal /= tonumber(AccumulatedNum) or 1
	elseif lastSym == '^' then
		CurVal ^= tonumber(AccumulatedNum) or 1
	elseif lastSym == '%' then
		CurVal %= tonumber(AccumulatedNum) or 1
	end 
	return CurVal
end
function retVal(t, _ENV)
	if not t then return nil end
	if tonumber(t) then return tonumber(t) end
	if t == "true" then return true end
	if t == "false" then return false end
	if string.match(t, "^['\"].+['\"]$") then return string.sub(t, 2, -2) end
	return Navigate(t, _ENV or _ROOT)
end
function CheckOperation(OString: string, _ENV: {}) 
	if typeof(OString) ~= 'string' then return end
	-- I asked gemini for help to parse the thing easily, I mean yeah, this is clearly formatting them into easier ways to work with
	if string.sub(OString, 1, 1) == "~" then OString = string.sub(OString, 2) end
	if string.sub(OString, 1, 1) == "(" then OString = string.sub(OString, 2) end
	if string.sub(OString, -1, -1) == ")" then OString = string.sub(OString, 1,-2) end
	local tokens = {}
	local buf = ""
	local i = 1
	while i <= #OString do
		local c = OString:sub(i, i)
		if c:match("[%w_%.'\"]") then
			buf = buf .. c
		else
			if buf ~= "" then table.insert(tokens, buf); buf = "" end
			-- check for two-char operators
			local two = OString:sub(i, i+1)
			if two == "==" or two == "~=" or two == ">=" or two == "<=" or two == "!=" then
				table.insert(tokens, two)
				i = i + 1
			elseif c == "&" or c == "|" or c == ">" or c == "<" or c == "=" then
				table.insert(tokens, c)
			end
		end
		i = i + 1
	end
	if buf ~= "" then table.insert(tokens, buf) end
	local CurVal = true  
	local lastSym = nil 
	local waitingBool = nil  -- The "Accumulated" value to be processed, same deal as Math
	local i = 1
	while i <= #tokens do
		local token = tokens[i]
		if token == "&" or token == "|" then
			-- Symbols
			if lastSym == nil then
				CurVal = waitingBool
			else
				if lastSym == "&" then
					CurVal = CurVal and waitingBool
				elseif lastSym == "|" then
					CurVal = CurVal or waitingBool
				end
			end
			lastSym = token
			waitingBool = nil -- Clear it out for the next chunk
			i = i + 1
		else
			-- Vals
			local nextOp = tokens[i+1]
			if nextOp == "==" or nextOp == "~=" or nextOp == ">" or 
				nextOp == "<" or nextOp == ">=" or nextOp == "<=" then
				local left = DecodeVal(token, _ENV)
				local right = DecodeVal(tokens[i+2], _ENV)
				if nextOp == "==" then waitingBool = (left == right)
				elseif nextOp == "~=" then waitingBool = (left ~= right)
				elseif nextOp == ">" then waitingBool = (left > right)
				elseif nextOp == "<" then waitingBool = (left < right)
				elseif nextOp == ">=" then waitingBool = (left >= right)
				elseif nextOp == "<=" then waitingBool = (left <= right)
				end
				i = i + 3
			else
				local raw = DecodeVal(token, _ENV)
				waitingBool = (raw ~= nil and raw ~= false)
				i = i + 1
			end
		end
	end

	-- just like the math, since the operation doesn't have a new token to trigger it, e gotta manually clean up the last one.
	if lastSym == nil then
		CurVal = waitingBool
	else
		if lastSym == "&" then
			CurVal = CurVal and waitingBool
		elseif lastSym == "|" then
			CurVal = CurVal or waitingBool
		end
	end

	return CurVal
end
function Trimmed(String)
	if typeof(String) ~= 'string' then return '' end
	return string.match(String, "^%s*(.-)%s*$")
end
function process(Line: string, ENV)
	if typeof(Line) ~= 'string'  then return end
	if typeof(ENV) ~= 'table' then return end
	Line = Trimmed(Line)
	if Line:sub(1,1) == ';' then Line = Line:sub(2) end
	if Line:sub(-1,-1) == ';' then Line = Line:sub(1,-2) end
	Line = Trimmed(Line)
	local length = string.len(Line)

	if Line:match(':') and Line:match('%(') and Line:sub(-1,-1) == ')' then
		local Args = ""
		local pos
		local ArgComplete = false
		local FuncName = ""
		for p = 1, length do
			local sub = string.sub(Line,-p, -p)
			if not ArgComplete then	Args = sub..Args else if sub == ':' then pos = -p break end FuncName = sub..FuncName end
			if sub == '(' then
				ArgComplete = true
			end
		end
		if typeof(pos) ~= 'number' then return end
		local Dir = string.sub(Line, 1, pos)
		local SearchIn = ENV or _ROOT
		if Dir:match('[%.:]') then
			local NewSearchIn = Navigate(Dir, SearchIn)
			if typeof(NewSearchIn) == 'table' and typeof(NewSearchIn._Function) == 'table' and typeof(NewSearchIn._Inner) == 'table'  and ((typeof(NewSearchIn._Inner[FuncName]) == 'table' and typeof(NewSearchIn._Inner[FuncName]._Inner) == 'table' and typeof(NewSearchIn._Inner[FuncName]._Inner.Run) == 'function') or typeof(NewSearchIn._Function[FuncName]) == 'table' and typeof(NewSearchIn._Function[FuncName]._Inner) == 'table' and typeof(NewSearchIn._Function[FuncName]._Inner.Run) == 'function') then SearchIn = NewSearchIn end
		end
		if typeof(SearchIn) ~= 'table' then warn('Invalid Directory >>', Dir ~= '' and Dir or "_ENV" ,' << When Calling Function ', FuncName) return end
		if Args:sub(1,1) == '(' then Args = Args:sub(2) end if Args:sub(-1,-1) == ')' then Args = Args:sub(1, -2) end
		--Args => (a = value, b = value)
		local Arguments = Args:split(',')
		local ForSubmit = {}
		if #Arguments > 0 then
			for i,v in Arguments do
				if typeof(v) ~= 'string' then continue end
				if not v:match('=') then warn(v..' Is An Invalid Assignment!') continue end
				v = Trimmed(v)
				local posOfSign 
				local Sml = string.len(v) --statement length
				for the = 1,Sml do
					local Ts = string.sub(v,the,the)
					if Ts == '=' then
						posOfSign = the
						break
					end
				end -- split
				if typeof(posOfSign) ~= 'number' then warn('Failed to parse >> '.. v) continue end
				local VarName = Trimmed(string.sub(v, 1, posOfSign -1))
				local Value = DecodeVal(Trimmed(string.sub(v, posOfSign+1)))
				if typeof(VarName) ~= 'string' then continue end
				pcall(function() ForSubmit[VarName] = Value end)
			end
		end
		Verbose('Submitting ARGS:')
		for i,v in ForSubmit do
			Verbose(i,'=',v)
		end
		Verbose('END OF ARG LIST')
		if typeof(SearchIn._Inner) == 'table' and typeof(SearchIn._Inner[FuncName]) == 'table' then
			Verbose('Ran',FuncName,'__BUILTIN')
			SearchIn._Inner[FuncName]._Inner.Run(ForSubmit, ENV)
		elseif typeof(SearchIn._Function) == 'table' and typeof(SearchIn._Function[FuncName]) == 'table' then
			Verbose('Ran',FuncName,'DEFINED')
			SearchIn._Function[FuncName]._Inner.Run(ForSubmit, ENV)
		else warn('Directory Does Not Have function >> ', FuncName) end
	elseif Line:match('=') then 
			local pos = 1
			while pos <= length do
				local sub = string.sub(Line, pos,pos)
				if sub == '=' then break end
				pos += 1
			end
			local FirstHalves = Trimmed(string.sub(Line,1,pos-1))
			local Other = Trimmed(string.sub(Line,pos + 1, length))
			local NavigatePath = FirstHalves:match('%[') and FirstHalves:sub(-1,-1) == ']'
			local SetTo = ENV or _ROOT
			local Keyname = FirstHalves
			if NavigatePath then
				local L = string.len(FirstHalves)
				local the = 1
				local A
				for Pos = 1, L do
					local sub = string.sub(FirstHalves, -Pos, -Pos)
					if sub == '[' then
						A = Pos
						break
					end
				end
				if typeof(A) == 'number' then
					local Path = FirstHalves:sub(1, -(A+1))
					SetTo = Navigate(Path, ENV)
					if typeof(SetTo) == 'table' then
						Keyname = FirstHalves:sub(-A + 1, -2)
					end 
				end
			end
			local Value = DecodeVal(Other, ENV, Keyname)
			SetVal(SetTo or ENV or _ROOT, Keyname, Value, true)
	end 
end
--Wrapped Run
function CRun(Code: string ,Struct_ENV: {}) -- Root also need to submit itself in at the layer
	if typeof(Code) ~= 'string' or Code == '' then return end if typeof(Struct_ENV) ~= 'table' or typeof(Struct_ENV.Values) ~= 'table' then warn('Invalid Environment... Aboting!') return end
	if not _SHS(Code) then return end -- likely a comment or markdown
	--simple directory wrappers
	local function _Navigate(Path: string, From: {})
		return Navigate(Path, typeof(From) == 'table' and From or Struct_ENV or _ROOT)
	end
	Code = Trimmed(Code)
	--Execution here
	local length = string.len(Code)
	local IsWrapped = false --between () end, if in already and tried stacking, will result in error
	local Pointer
	local newchar = false
	local Accum = "" -- should remove every ; for commands and every "end;""
	local MathAccum = ""
	-- if ~(<condition>) comes out false, go right to the next end
	--all ts can happen at the same time so it's not a single state system
	local ToNextEnd = false
	local OperationState = false -- reigster a sub-operation checking Block(~(<Condition>))
	local MathState = false -- register a sub-math handler to handle the math strings inside $()
	local FunctionDefining = false -- AAAAAA I FORGOT THIS SHIT
	-- start at where(using #<character position> to return to parse that for condition without triggering a whole new Env)
	local function Parse(fromwhere: number)
		if typeof(fromwhere) ~= 'number' or fromwhere < 1 then fromwhere = 1 end
		for i = 1, length do
			local Sub = string.sub(Code,i,i)
			if ToNextEnd then
				if Accum:lower():match('end') then
					ToNextEnd = false Accum = ""
				else 
				Accum = Accum..Sub continue end
			else 	Accum = Accum..Sub  end
			if OperationState then
				if MathState then
					MathAccum = MathAccum..Sub
				end
				if Sub == "S" and not MathState then
					MathState = true
					MathAccum = ""
					continue
				elseif Sub == ')' then
					if MathState then
						MathState = false
						string.gsub(Accum, MathAccum..')', tostring(Math(MathAccum, Struct_ENV)) or "0")
						continue
					end
					MathAccum = ''
					MathState = false -- END OF CONDITION.
					Verbose('Completed Condition >>', Accum)
					local True = CheckOperation(Accum, Struct_ENV) Accum = ''
					if not True then
						Verbose("It wasn't true.... skipping")
						ToNextEnd = true
					else
						Verbose('True')
					end
					OperationState = false
					continue -- ignore ) and go to the next step
				end
			end
			if Sub == ';' then if Accum:match("=%s*%([^)]*%)") and not Accum:match("=%s*~") and not Accum:lower():match("end%s*$") then FunctionDefining = true end
				if FunctionDefining then if Accum:sub(-4):lower() == "end;" then FunctionDefining = false Verbose('processing potential Function() >>', Accum, 'in ENV >>', tostring(Struct_ENV)) process(Accum, Struct_ENV) Accum = '' newchar = true end continue else Verbose('processing ', Accum, 'in ENV >>', tostring(Struct_ENV)) process(Accum, Struct_ENV) Accum = '' newchar = true continue end end
			if Sub == '%s' then continue end -- ignore
			if newchar then
				if Sub == "~"  and string.sub(Code,i+1,i+1) == '('  and string.sub(Code,i-1,i-1) == ';' then
					--if rules(must check the () if it is true, continue as normal, if false, SKIP to the next end;)
				 OperationState = true Verbose('Start Logging Condition')
				elseif Sub == "@" and tonumber(string.sub(Code,i+1,i+1)) then -- return to pointer
					local CountNum=""
					local pos = i + 1
					while pos <= length do
						local sub = string.sub(Code, pos,pos)
						if sub == ';' then break end
						if tonumber(sub) then
							CountNum = CountNum..sub -- counted number
						end
						pos += 1
					end
					Parse(tonumber(CountNum))
					break -- stop the current iteration as it continued else where.
				end
			end
			
		end
	end
	Parse(1)
end
function ValidLine(Line: string)
	if typeof(Line) ~= 'string' or not _SHS(Line) then return false end
	--check syntax rules
	return true
end
function FARB(Fstring: string) -- Find and Seperate First bracket, Non Bracketed Return false
	--mostly for detecting function assignments, functions will look like this ... -> ; (a=val,b=val) end; <- ...
	if typeof(Fstring) ~= 'string' or Fstring == '' or not (Fstring:match('%(') and Fstring:match('%)')) then return false, "" end
	local firstOpen, _, firstClose, _ = string.find(Fstring, "(",1,true),  string.find(Fstring, ")",1,true) -- returns 2 per find
	if firstClose < firstOpen then return false, "" end
	return true, string.sub(Fstring, firstOpen+1, firstClose-1) --[[[between the ()]], string.sub(Fstring,firstClose+1) -- thigns after ()
end
function DisectF(Fstring: string) -- not sure how to detect function inside a function 
	if typeof(Fstring) ~= 'string' or string.sub(Fstring, -3,-1):lower() ~= 'end' then return end
	if Fstring == '' then return {} end
	Fstring = string.sub(Fstring, 1,-4) -- cut the "end" off
	local IsFunction, ArgString, AlgoString = FARB(Fstring)
	Verbose("IsFunction:",IsFunction,"ARGs:", ArgString,"ALGORITHMS:", AlgoString)
	if typeof(IsFunction) ~= 'boolean' or not IsFunction then return end
	local Codes = {}
	local Req = {}
	if typeof(ArgString) == 'string' and ArgString ~= '' then
		-- parse and make it require variable
		Req = string.split(ArgString, ",")
		local Cleaned = {}
		for i,v in Req do
			if v:match('=') and ValidLine() then  -- if u r not gonna define for a required variable, that's fine, this is for enforced typechecking rule, the actual shit is with .Run(), better submit the right string to batch the Starting Local Variables (a=ClassofvalueinA, b=ClassofvalueinB, ...)
				local Split = string.split(v,'=')
				local Key = Split[1]
				local Class = Split[2]
				Cleaned[Key] = Class -- will be checked with typeof() 
			end
		end
		Req = Cleaned
	end
	if typeof(AlgoString) == 'string' and AlgoString ~= '' then
		-- parse and get the codes line by line to execute with CRun
		Codes = string.split(AlgoString, ";") 
		local Cleaned = {}
		for i,v in Codes do
			if typeof(v) ~= 'string' then continue end
			v = Trimmed(v)
			if v == '' then continue end
			if ValidLine(v) then
				table.insert(Cleaned, v)
				Verbose(v,'ADDED')
			else
				warn(v, 'INVALID')
			end
		end
		Codes = Cleaned
	else
		warn('AlgoString EMPTY')
	end
	return Req, Codes
end
function DecodeVal(The: string, OnThread_ENV: {}, Name: string?) -- name will come from the string before "=" that was used to set the value
	if typeof(The) ~= 'string' then return The end -- take that back.
	The = Trimmed(The)
	if tostring(tonumber(The)) == The then return tonumber(The) end
	if The:lower() == 'nil' then return nil end
	if The:sub(-1,-1) == "}" and The:sub(1,1) == '{' then return Struct(OnThread_ENV or _ROOT, Name or 'Table', The) end
	local A,B = DisectF(The)
	if typeof(A) == 'table' and typeof(B) == 'table' then return FunctionStruct(OnThread_ENV, Name or 'Function', B, A) end
	local Op
	if The:sub(1,1) == '~' then Verbose('Checking ', The, ' AS CONDITION') Op = CheckOperation(The, OnThread_ENV) end if typeof(Op) == 'boolean' then Verbose('got '.. tostring(Op)) return Op end 
	local Num
	if The:sub(1,1) == '$' then Num = Math(The, OnThread_ENV) end if typeof(Num) == 'number' then return Num end
	local maybeBool = retVal(The, OnThread_ENV)
	if typeof(maybeBool) ~= 'nil' then return maybeBool end -- covers true false and potential deep variables(for deep pathing into this jumbo mumbo)
	--more here
	return The -- string
end 
function Navigate(Path: string, From: {Values: {string: any}}?)
	--may either start from root or Structure, Path is either ".thingy.thing" or "thingy.thing", if the first char is . then search with From, else Root.
	if Path == "" then return From end -- like wdym find bro. there's NOTHING.
	if typeof(Path) ~= 'string' or (string.sub(Path,1,1) == '.' and typeof(From) ~= 'table') then if typeof(Path) == 'string' and string.sub(Path,1,1) == '.' and typeof(From) ~= 'table' then warn('Cannot Path From '..typeof(From)) return end warn('Pathing Failed!') return end
	if typeof(From) ~= 'table' then From = _ROOT end
	if string.sub(Path,1,1) == '.' then Path = string.sub(Path,2) end
	local Find = string.split(Path, '.')
	local Gotta = Find[1]
	if typeof(Gotta) ~= 'string' then warn('string fail!') return end
	local Class = string.split(Gotta, ":")[2] -- if it doesn't exist, it just don't, no error
	if typeof(Class) == 'string' then Gotta = string.split(Gotta, ":")[1] end
	if #Find >0 then table.remove(Find, 1) else return From end	
	if typeof(From.Values) ~= 'table' then warn(typeof(From), 'Is Not Indexible!') end
	local NextLayer = From._Inner.DoesIt(Gotta, Class) or From.Values[Gotta]
	if not NextLayer then
		warn(From.Name or 'Thingymabob', 'Does Not Have', Path, ' Use .GetValues() to return value table or .DoesIt() to Check')
		return nil
	end
	if #Find == 0 then return NextLayer end
	return Navigate(table.concat(Find, '.'), NextLayer)
end
function FunctionStruct(Parent: {}, StructureKey: string, F: {string}?, R: {string: string}) -- Function is its own environment, not sending the code over will create a Stub. Internal values are MAINLY internal, and will not be written to Global unless # was added to Key to state its global changes(you need to still state the variable name as normal if defined interally btw) 
	if typeof(Parent) ~= 'table' or typeof(Parent._Function) ~= 'table' then warn('Invalid Structure Parent!') return end
	if typeof(StructureKey) ~= 'string' or _SHS(StructureKey) or StructureKey == '' then warn('Invalid Function Name Assignment!') return end
	local FStruct FStruct = {
		CoolSwag = F or {}, -- unparsed code strings here
		Require = R,
		_Inner = {Run = function(Args: {string: any}, Caller_ENV: {}) -- execute for .Key(arg)
			Verbose((StructureKey or 'Function')..' CALLED!')
			if typeof(FStruct) ~= 'table' or typeof(FStruct.CoolSwag) ~= 'table' then warn('Function is Nulled!') return end
			if typeof(FStruct.Require) == 'table' then for i,v in FStruct.Require do if typeof(i) ~= 'string' or typeof(v) ~= 'string'  then continue end  if typeof(Args[i]) ~= v then warn(StructureKey.." Cannot Be Called, need >>", i, "<< to be",v) return end  end end
			Verbose('INITING LOCAL ENV')
			local Local = Struct({Values = table.clone(Args or {}) or {}}, "__ROOT_ENV")
			if next(Args) then Verbose('WITH ARG:') for i,v in Args do Verbose(i,'=',v) Local.Values[i] = v end end
			local META = typeof(Caller_ENV) == 'table' and typeof(Caller_ENV.Values) == 'table' and Caller_ENV.Values or _ROOT.Values
			setmetatable(Local.Values, {__index = META or _ROOT.Values, __newindex = function(t,k,v) if typeof(k) ~= 'string' then Local[k] = nil return end --[[NO!]] if typeof(t) ~= 'table' then return end if string.sub(k,1,1) == '#' then if typeof(META) == 'table' then META[k] = v end --[[Chain this, will trigger them all]] rawset(_ROOT.Values,k:sub(2),v) rawset(Local.Values, k:sub(2),v) rawset(Local.Values, k,v) --[[null this, the chain will null the #key by itself]] else rawset(t,k,v) end end}) -- Pair so it can read/access all the ancestor processes' variables
			Verbose('FINISHED INIT')
			if #FStruct.CoolSwag <= 0 then
				warn((StructureKey or 'Function')..' IS EMPTY!')
			else
				Verbose('WILL RUN '..tostring(#FStruct.CoolSwag)..' LINES')
			end
			for i,v in FStruct.CoolSwag do
				Verbose('COOLSWAG:',i,v)
				if typeof(v) ~= 'string' or v == '' then continue end
				process(v, Local or _ROOT)
			end
			setmetatable(Local.Values, nil) -- Gone!
			table.clear(Local)
			Local = nil
		end, Parent = FStruct, Name = StructureKey}
	}
	Parent._Function[StructureKey] = FStruct
	return FStruct
end

function SetVal(Struct: {}, Key: string, Val: any, _Verbose: boolean)
	if typeof(Struct) ~= 'table' or typeof(Struct.Values) ~= 'table' then warn('Variables Are Not Able To Be Set For', typeof(Struct), 'It Does Not Contain Value Table, It Got', typeof(Struct) == 'table' and typeof(Struct.Values) or "Nothing Of that Sort!") return end
	if typeof(Key) ~= 'string' then pcall(function() Key = tostring(Key) end) end
	if typeof(Key) ~= 'string' or Key == "" then warn('Only Non-Empty Strings Are Allowed To Be Used As Variable Names!') return end
	if _SHS(Key) and Key:sub(1,1) ~= "#" then warn('Key', Key,'Had Syntaxes! Not Recommended! But will proceed anyway') end
	if typeof(Key) == 'table' and typeof(Key.CoolSwag) == 'table' then -- function Struct!
		if typeof(Struct._Function) ~= 'table' then if typeof(Struct._Inner) ~= 'table' then warn('Struct Is Not A Valid Struct! Cannot Store Function') return end Struct._Function = {} end
		Struct._Function[Key] = Val
	else Struct.Values[Key] = Val if Key:sub(1,1) == '#' then Verbose('Updated ',Key:sub(2), "Global Var To:", tostring(Val)) rawset(_ROOT.Values, Key:sub(2), Val) --[[the METATABLE DOESN'T WORK SO I PUT THIS HERE]] end end
end
--@Soliviant 5/17/2026 progress
if typeof(Codes) ~= 'string' then warn('Invalid Code!') return end
Verbose('Running', Codes)
CRun(Codes, _ROOT)