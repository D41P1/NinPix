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
local FP_EPSILON = 1e-6
local I16_PRECISION = 32767                 -- int16 range { -32,786, 32,767 }
local BUFF_CFRAME_SIZE = (3*4) + (1 + 3*2)  -- i.e. 3x f32, 1x u8 and 3x i16 -- 19 bytes

local function getNormalisedQuaternion(cframe)
	local axis, angle = cframe:ToAxisAngle()
	axis = axis.Magnitude > FP_EPSILON and axis.Unit or Vector3.xAxis

	local ha = angle / 2
	local sha = math.sin(ha)

	local x = sha*axis.X
	local y = sha*axis.Y
	local z = sha*axis.Z
	local w = math.cos(ha)

	local length = math.sqrt(x*x + y*y + z*z + w*w)
	if length < FP_EPSILON then
		return 0, 0, 0, 1
	end

	return x / length,	y / length, z / length,	w / length
end


local function compressQuaternion(cframe: CFrame)
	local qx, qy, qz, qw = getNormalisedQuaternion(cframe)

	local index = -1
	local value = -math.huge

	local sign
	for i = 1, 4, 1 do
		local val = select(i, qx, qy, qz, qw)
		local abs = math.abs(val)
		if abs > value then
			index = i
			value = abs
			sign = val
		end
	end
	sign = sign >= 0 and 1 or -1

	local v0, v1, v2
	if index == 1 then
		v0 = math.floor(qy * sign * I16_PRECISION + 0.5)
		v1 = math.floor(qz * sign * I16_PRECISION + 0.5)
		v2 = math.floor(qw * sign * I16_PRECISION + 0.5)
	elseif index == 2 then
		v0 = math.floor(qx * sign * I16_PRECISION + 0.5)
		v1 = math.floor(qz * sign * I16_PRECISION + 0.5)
		v2 = math.floor(qw * sign * I16_PRECISION + 0.5)
	elseif index == 3 then
		v0 = math.floor(qx * sign * I16_PRECISION + 0.5)
		v1 = math.floor(qy * sign * I16_PRECISION + 0.5)
		v2 = math.floor(qw * sign * I16_PRECISION + 0.5)
	elseif index == 4 then
		v0 = math.floor(qx * sign * I16_PRECISION + 0.5)
		v1 = math.floor(qy * sign * I16_PRECISION + 0.5)
		v2 = math.floor(qz * sign * I16_PRECISION + 0.5)
	end

	return index, v0, v1, v2
end
local function decompressQuaternion(index, v0, v1, v2)
	v0 /= I16_PRECISION
	v1 /= I16_PRECISION
	v2 /= I16_PRECISION

	local d = math.sqrt(1 - (v0*v0 + v1*v1 + v2*v2))
	if index == 1 then
		return d, v0, v1, v2
	elseif index == 2 then
		return v0, d, v1, v2
	elseif index == 3 then
		return v0, v1, d, v2
	end
	return v0, v1, v2, d
end
local PosWriter =function(input:CFrame, b ,offset:number )
	local buf = b or buffer.create(19) 
	local Needle = offset or 0	
	local WriteF32 =buffer.writef32 
	local Writei16 = buffer.writei16
	local qi, q0, q1, q2 = compressQuaternion(input)
	
	WriteF32(buf, Needle + 0, input.X)
	WriteF32(buf, Needle + 4, input.Y)
	WriteF32(buf, Needle + 8, input.Z)

	buffer.writeu8(buf, Needle + 12, qi)
	Writei16(buf, Needle + 13, q0)
	Writei16(buf, Needle + 15, q1)
	Writei16(buf, Needle + 17, q2)

	return buf
end

local PosReader = function(buf, offset)
	local Needle = offset or 0
	local ReadF32 = buffer.readf32 
	local Readi16 = buffer.readi16
	
	local x = ReadF32(buf, Needle + 0)
	local y = ReadF32(buf, Needle + 4)
	local z = ReadF32(buf, Needle + 8)

	local qi = buffer.readu8(buf, Needle + 12)
	local q0 = Readi16(buf, Needle + 13)
	local q1 = Readi16(buf, Needle + 15)
	local q2 = Readi16(buf, Needle + 17)

	local qx, qy, qz, qw = decompressQuaternion(qi, q0, q1, q2)
	return CFrame.new(x, y, z, qx, qy, qz, qw),	BUFF_CFRAME_SIZE
end

BufferConverter.PosWriter = PosWriter
BufferConverter.PosReader = PosReader
BufferConverter.Read = Read




--[[ Example
local buff: buffer =  BufferConverter:ConvertArray({Vector3.one, "Hello"})

local References = {"Vector3", "string"}
local Vector, String = BufferConverter.Read(References, buff)
]]
return BufferConverter
