--!native
local bufferWriter = require(script.Buffer_Util)
local writef32NoAlloc = bufferWriter.writef32
local BufferConverter = { 
	--TODO CFrames are unoptimised Rxyz should be i16 cos -180,180
	--[[ bug checking
	1. first check are the Refs correct
	2. check the types here
	3. check the bufferwriter
	]]
	["Vector3"] = {
		read = function(b: buffer, cursor: number)
			return Vector3.new(buffer.readf32(b, cursor), buffer.readf32(b, cursor + 4), buffer.readf32(b, cursor + 8)), 12
		end,
		write = function(value: Vector3)
			bufferWriter.alloc(12)
			writef32NoAlloc(value.X)
			writef32NoAlloc(value.Y)
			writef32NoAlloc(value.Z)
		end,
	},
	["string"] = {
		read = function(b: buffer, cursor: number)
			local Length = buffer.readu16(b, cursor)
			return  buffer.readstring(b, cursor + 2, Length), Length + 2 
		end,
		write = function(value: string)
			local Length  = string.len(value)
			bufferWriter.alloc(Length)
			bufferWriter.writeu16(Length)
			bufferWriter.writestring(value)
		end,
	},
	["boolean"] = {
		-- 1 = true, 0 = false --Write and read based off a uint8
		read = function(b: buffer, cursor: number) return buffer.readu8(b, cursor) == 1, 1 end,
		write = bufferWriter.writebool,
	},
	["CFrame"] = {
		read = function(b: buffer, cursor: number)
			local x = buffer.readf32(b, cursor)
			local y = buffer.readf32(b, cursor + 4)
			local z = buffer.readf32(b, cursor + 8)
			local rx = buffer.readf32(b, cursor + 12)
			local ry = buffer.readf32(b, cursor + 16)
			local rz = buffer.readf32(b, cursor + 20)
	
			-- Re-construct the CFrame from the axis-angle representation
			local axis = Vector3.new(rx, ry, rz)
			local angle = axis.Magnitude
	
			return CFrame.fromAxisAngle(axis, angle) + Vector3.new(x, y, z), 24
		end,
		write = function(value: CFrame)
			-- Convert the CFrame to an axis-angle representation
			local x, y, z = value.X, value.Y, value.Z
			local axis, angle = value:ToAxisAngle()
			local rx, ry, rz = axis.X, axis.Y, axis.Z
			axis = axis * angle
			-- Math done, write it now
			bufferWriter.alloc(24)
			writef32NoAlloc(x)
			writef32NoAlloc(y)
			writef32NoAlloc(z)
			writef32NoAlloc(rx)
			writef32NoAlloc(ry)
			writef32NoAlloc(rz)
		end,
	},
	["number"] = {
		write = function(value: number)
			if value > 2^32 then  return bufferWriter.writef64(value) , 8	end
			return writef32NoAlloc(value) , 4
		end ,
		read = function(b: buffer, cursor: number) return buffer.readf32(b, cursor), 4 end,
	},
	["number64"]  = { read = function(b: buffer, cursor: number) return buffer.readf64(b, cursor), 8 end, },
	["Vector2"] = {
		--[[ 2 float32s, one for X, one for Y]]
		read = function(b: buffer, cursor: number) return Vector2.new(buffer.readf32(b, cursor), buffer.readf32(b, cursor + 4)), 8
		end,
		write = function(value: Vector2)
			bufferWriter.alloc(8)
			bufferWriter.writef32(value.X)
			bufferWriter.writef32(value.Y)
		end,
	},
	["buffer"] = {
		read = function(b: buffer, cursor: number)
			local length = buffer.readu16(b, cursor)
			local freshBuffer = buffer.create(length)
			-- copy the data from the main buffer to the new buffer with an offset of 2 because of length
			buffer.copy(freshBuffer, 0, b, cursor + 2, length)
			return freshBuffer, length + 2
		end,
		write = function(data: buffer)
			local length = buffer.len(data)
			bufferWriter.writeu16(length)
			bufferWriter.alloc(length)
			-- write the length of the buffer, then the buffer itself
			bufferWriter.writecopy(data)
		end,
	}
}
function BufferConverter:ConvertArray(Array: {any})
	for _ , value in Array do
		local TypeOFValue = typeof(value)
		if BufferConverter[TypeOFValue] then
			BufferConverter[TypeOFValue].write(value)
		end
	end	
	local buff: buffer = bufferWriter:GetBuff()
	bufferWriter:ClearBuff()
	return buff
end
local Read = function(TableOfReferences: { string }, buff: buffer)
	if typeof(buff) ~= "buffer" then  return end
	local ReturnValues = {}
	local GlobalCursor = 0
	for _, ValueType in TableOfReferences do
		local Value, cursor = BufferConverter[ValueType].read(buff, GlobalCursor)
		GlobalCursor += cursor
		table.insert(ReturnValues, Value)
	end
	return unpack(ReturnValues)
end
local function UnitVector_Buffer(LookVector:Vector3) --* UnitVector	
	local WI16 = buffer.writei16
	local X, Y, Z = LookVector.X, LookVector.Y, LookVector.Z
	local AngleBuffer = buffer.create(2)	
	local Atan2 = math.atan2
	if X == 0 then 
		--* Y-Z		
		local Angle = Atan2(Z, Y)
		WI16(AngleBuffer, 0, Angle*1000)
	elseif Y == 0 then
		--* X-Z
		local Angle = Atan2(Z, X)
		WI16(AngleBuffer, 0, Angle *1000)
	elseif Z == 0 then
		--* X-Y
		local Angle = Atan2(Y, X)
		WI16(AngleBuffer, 0, Angle *1000)
	end	
	
	return AngleBuffer
end
local function Reader_UnitVector_Buffer(AngleBuffer:buffer, UpVector:Vector3, offset:number?)--* Send UV3V ONLY
	-- read the AngleBuffer and convert it to its 2 inputs
	local Needle = offset or 0
	local RI16 = buffer.readi16
	local Angle = RI16(AngleBuffer, Needle)
	Angle *= 0.001
	local X, Y, Z = UpVector.X, UpVector.Y, UpVector.Z
	local i1, i2 = math.cos(Angle), math.sin(Angle)
	local LookVector	
	if X == 1 or X == -1 then 
		--* Y-Z		
		LookVector = Vector3.new(0, i1, i2).Unit
	elseif Y == 1 or Y == -1 then
		--* X-Z
		LookVector = Vector3.new(i1, 0, i2).Unit		
	elseif Z == 1 or Z == -1 then
		--* X-Y
		LookVector = Vector3.new(i1, i2, 0).Unit
	end	
	return LookVector 
end

--↓ outdated
local CF_Write_Buffer = function(CF:CFrame, offset:number, b:buffer?): buffer
	local Needle = offset or 0	
	local Wi16 = buffer.writei16
	local CF_Buffer = b or buffer.create(8)
	local Ro = math.round
	
	Wi16(CF_Buffer, Needle, Ro(CF.X))
	Wi16(CF_Buffer, Needle+2, Ro(CF.Y))
	Wi16(CF_Buffer, Needle+4, Ro(CF.Z))
	local V = Vector3.new(CF.LookVector.X, 0, CF.LookVector.Z).Unit
	local Atan2 = math.atan2(V.Z, V.X);  
	Atan2 = Atan2 * 1000 -- number can be anywhere from 0 - 6.3 radians (360 degrees)
	--print(CF.LookVector)
	Wi16(CF_Buffer, Needle+6, Atan2)	
	--Atan2 = buffer.readu8(CF_Buffer, 6)
	--print(V.Z, V.X, math.sin(Atan2/1000), math.cos(Atan2/1000) )
	Needle += 8
	return CF_Buffer, Needle
end
local CF_Read_Buffer = function(CF_Buffer:buffer, offset:number):CFrame
	local Needle = offset or 0	
	local Ri16 = buffer.readi16
	local PosX, PosY, PosZ = Ri16(CF_Buffer, Needle), Ri16(CF_Buffer, Needle+2), Ri16(CF_Buffer, Needle+4)
	local Atan2 = Ri16(CF_Buffer, Needle+6)
	Atan2 = Atan2 + 1e-8 -- prevent NAN Values 
	Atan2 = Atan2/ 1000	
	local LookX = math.cos(Atan2)
	local LookZ = math.sin(Atan2)
	
	local Pos = Vector3.new(PosX, PosY, PosZ)
	local LookPos = Vector3.new(LookX, 0, LookZ).Unit --MUST BE UNIT or ERROR
	--print(LookPos, "\n|\n")
	--print("\n\n", LookZ, LookX, Atan2)
	Needle += 8
	--//return CFrame.new(PosX, PosY, PosZ, LookX, 0, LookZ, 0, 1, 0, LookZ, 0, LookX)
	return CFrame.lookAlong(Pos, LookPos, Vector3.new(0, 1, 0) )	
end
local PosWriter =function(Pos: Vector3, Look:Vector3, Up:Vector3, b ,offset:number )
	local buf = b or buffer.create(24) 
	local Needle = offset or 0	
	local WriteF32 = buffer.writef32 
	local Writei16 = buffer.writei16

	WriteF32(buf, Needle + 0, Pos.X)
	WriteF32(buf, Needle + 4, Pos.Y)
	WriteF32(buf, Needle + 8, Pos.Z)

	Writei16(buf, Needle + 12, Look.X*10000)
	Writei16(buf, Needle + 14, Look.Y*10000)
	Writei16(buf, Needle + 16, Look.Z*10000)

	Writei16(buf, Needle + 18, Up.X*10000)
	Writei16(buf, Needle + 20, Up.Y*10000)
	Writei16(buf, Needle + 22, Up.Z*10000)
	Needle += 22
	return buf, Needle
end
local PosReader = function(buf, offset)
	local Needle = offset or 0
	local ReadF32 = buffer.readf32 
	local Readi16 = buffer.readi16
	
	local x = ReadF32(buf, Needle + 0)
	local y = ReadF32(buf, Needle + 4)
	local z = ReadF32(buf, Needle + 8)
	local Pos = Vector3.new(x,y,z)
	
	local T = {}
	Needle += 12
	for i = 1, 6 do 
		local n = Readi16(buf, Needle)
		Needle += 2
		table.insert(T, n)--* n is multiplied by 10,000 so .Unit will make it back to mag of 1
	end
	--//local Lx = Readi16(buf, Needle + 13)
	--//local Ly = Readi16(buf, Needle + 15)
	--//local Lz = Readi16(buf, Needle + 17)
	local Look = Vector3.new(T[1], T[2], T[3]).Unit
	local Up = Vector3.new(T[4], T[5], T[6]).Unit
	local CF = CFrame.lookAlong(Pos, Look, Up)
	--// local Ux = Readi16(buf, Needle + 13)
	--// local Uy = Readi16(buf, Needle + 15)
	--// local Uz = Readi16(buf, Needle + 17)

	return CF
end
--↑
local CF_Write = function(Made_CF_Buffer:buffer?, offset:number?, look_Vector_Buffer:buffer, Position:Vector3)
	local Needle = offset or 0
	local CF_Buffer = Made_CF_Buffer or buffer.create(8)
	buffer.writei16(CF_Buffer, Needle, Position.X)
	buffer.writei16(CF_Buffer, Needle + 2, Position.Y)
	buffer.writei16(CF_Buffer, Needle + 4, Position.Z)
	buffer.copy(CF_Buffer, Needle + 6, look_Vector_Buffer, 0, 2)
	return CF_Buffer
end
local CF_Read= function(offset:number?, CF_Buffer:buffer, LookVector:Vector3, UpVector:Vector3):CFrame
	--* get LookVector from Reader_Unit_Vector, UV3V.Value = UpVector
	local Needle =  offset or 0
	local Ri16 = buffer.readi16
	local PosX, PosY, PosZ = Ri16(CF_Buffer, Needle), Ri16(CF_Buffer, Needle+2), Ri16(CF_Buffer, Needle+4)	
	local Pos = Vector3.new(PosX, PosY, PosZ)
	return CFrame.lookAlong(Pos, LookVector, UpVector)
end
BufferConverter.PosWriter = PosWriter
BufferConverter.PosReader = PosReader
BufferConverter.Read = Read
BufferConverter["CF_Write_Buffer"] = CF_Write
BufferConverter["CF_Read_Buffer"] = CF_Read 
BufferConverter["UnitVector_Buffer"] = UnitVector_Buffer
BufferConverter["Reader_UnitVector_Buffer"] = Reader_UnitVector_Buffer




--[[ Example
local buff: buffer =  BufferConverter:ConvertArray({Vector3.one, "Hello"})

local References = {"Vector3", "string"}
local Vector, String = BufferConverter.Read(References, buff)
]]
return BufferConverter
