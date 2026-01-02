local bit = bit or bit32 or require('bit')
local unpack = table.unpack or unpack

local stm_lua_bytecode
local wrap_lua_func
local stm_lua_func

local FIELDS_PER_FLUSH = 50

local opcode_t = {[0] = 'ABC',
	'ABx',
	'ABC',
	'ABC',
	'ABC',
	'ABx',
	'ABC',
	'ABx',
	'ABC',
	'ABC',
	'ABC',
	'ABC',
	'ABC',
	'ABC',
	'ABC',
	'ABC',
	'ABC',
	'ABC',
	'ABC',
	'ABC',
	'ABC',
	'ABC',
	'AsBx',
	'ABC',
	'ABC',
	'ABC',
	'ABC',
	'ABC',
	'ABC',
	'ABC',
	'ABC',
	'AsBx',
	'AsBx',
	'ABC',
	'ABC',
	'ABC',
	'ABx',
	'ABC',}

local opcode_m = {[0] = {b = 'OpArgR', c = 'OpArgN'},
	{b = 'OpArgK', c = 'OpArgN'},
	{b = 'OpArgU', c = 'OpArgU'},
	{b = 'OpArgR', c = 'OpArgN'},
	{b = 'OpArgU', c = 'OpArgN'},
	{b = 'OpArgK', c = 'OpArgN'},
	{b = 'OpArgR', c = 'OpArgK'},
	{b = 'OpArgK', c = 'OpArgN'},
	{b = 'OpArgU', c = 'OpArgN'},
	{b = 'OpArgK', c = 'OpArgK'},
	{b = 'OpArgU', c = 'OpArgU'},
	{b = 'OpArgR', c = 'OpArgK'},
	{b = 'OpArgK', c = 'OpArgK'},
	{b = 'OpArgK', c = 'OpArgK'},
	{b = 'OpArgK', c = 'OpArgK'},
	{b = 'OpArgK', c = 'OpArgK'},
	{b = 'OpArgK', c = 'OpArgK'},
	{b = 'OpArgK', c = 'OpArgK'},
	{b = 'OpArgR', c = 'OpArgN'},
	{b = 'OpArgR', c = 'OpArgN'},
	{b = 'OpArgR', c = 'OpArgN'},
	{b = 'OpArgR', c = 'OpArgR'},
	{b = 'OpArgR', c = 'OpArgN'},
	{b = 'OpArgK', c = 'OpArgK'},
	{b = 'OpArgK', c = 'OpArgK'},
	{b = 'OpArgK', c = 'OpArgK'},
	{b = 'OpArgR', c = 'OpArgU'},
	{b = 'OpArgR', c = 'OpArgU'},
	{b = 'OpArgU', c = 'OpArgU'},
	{b = 'OpArgU', c = 'OpArgU'},
	{b = 'OpArgU', c = 'OpArgN'},
	{b = 'OpArgR', c = 'OpArgN'},
	{b = 'OpArgR', c = 'OpArgN'},
	{b = 'OpArgN', c = 'OpArgU'},
	{b = 'OpArgU', c = 'OpArgU'},
	{b = 'OpArgN', c = 'OpArgN'},
	{b = 'OpArgU', c = 'OpArgN'},
	{b = 'OpArgU', c = 'OpArgN'},}

local function rd_int_basic(src, s, e, d)
	local num = 0

	for i = s, e, d do num = num + string.byte(src, i, i) * 256 ^ (i - s) end

	return num
end

local function rd_flt_basic(f1, f2, f3, f4)
	local sign = (-1) ^ bit.rshift(f4, 7)
	local exp = bit.rshift(f3, 7) + bit.lshift(bit.band(f4, 0x7F), 1)
	local frac = f1 + bit.lshift(f2, 8) + bit.lshift(bit.band(f3, 0x7F), 16)
	local normal = 1

	if exp == 0 then
		if frac == 0 then
			return sign * 0
		else
			normal = 0
			exp = 1
		end
	elseif exp == 0x7F then
		if frac == 0 then
			return sign * (1 / 0)
		else
			return sign * (0 / 0)
		end
	end

	return sign * 2 ^ (exp - 127) * (1 + normal / 2 ^ 23)
end

local function rd_dbl_basic(f1, f2, f3, f4, f5, f6, f7, f8)
	local sign = (-1) ^ bit.rshift(f8, 7)
	local exp = bit.lshift(bit.band(f8, 0x7F), 4) + bit.rshift(f7, 4)
	local frac = bit.band(f7, 0x0F) * 2 ^ 48
	local normal = 1

	frac = frac + (f6 * 2 ^ 40) + (f5 * 2 ^ 32) + (f4 * 2 ^ 24) + (f3 * 2 ^ 16) + (f2 * 2 ^ 8) + f1

	if exp == 0 then
		if frac == 0 then
			return sign * 0
		else
			normal = 0
			exp = 1
		end
	elseif exp == 0x7FF then
		if frac == 0 then
			return sign * (1 / 0)
		else
			return sign * (0 / 0)
		end
	end

	return sign * 2 ^ (exp - 1023) * (normal + frac / 2 ^ 52)
end

local function rd_int_le(src, s, e) return rd_int_basic(src, s, e - 1, 1) end

local function rd_int_be(src, s, e) return rd_int_basic(src, e - 1, s, -1) end

local function rd_flt_le(src, s) return rd_flt_basic(string.byte(src, s, s + 3)) end

local function rd_flt_be(src, s)
	local f1, f2, f3, f4 = string.byte(src, s, s + 3)
	return rd_flt_basic(f4, f3, f2, f1)
end

local function rd_dbl_le(src, s) return rd_dbl_basic(string.byte(src, s, s + 7)) end

local function rd_dbl_be(src, s)
	local f1, f2, f3, f4, f5, f6, f7, f8 = string.byte(src, s, s + 7)
	return rd_dbl_basic(f8, f7, f6, f5, f4, f3, f2, f1)
end

local float_types = {[4] = {little = rd_flt_le, big = rd_flt_be},
	[8] = {little = rd_dbl_le, big = rd_dbl_be},}

local function stm_byte(S)
	local idx = S.index
	local bt = string.byte(S.source, idx, idx)

	S.index = idx + 1
	return bt
end

local function stm_string(S, len)
	local pos = S.index + len
	local str = string.sub(S.source, S.index, pos - 1)

	S.index = pos
	return str
end

local function stm_lstring(S)
	local len = S:s_szt()
	local str

	if len ~= 0 then str = string.sub(stm_string(S, len), 1, -2) end

	return str
end

local function cst_int_rdr(len, func)
	return function(S)
		local pos = S.index + len
		local int = func(S.source, S.index, pos)
		S.index = pos

		return int
	end
end

local function cst_flt_rdr(len, func)
	return function(S)
		local flt = func(S.source, S.index)
		S.index = S.index + len

		return flt
	end
end

local function stm_instructions(S)
	local size = S:s_int()
	local code = {}

	for i = 1, size do
		local ins = S:s_ins()
		local op = bit.band(ins, 0x3F)
		local args = opcode_t[op]
		local mode = opcode_m[op]
		local data = {value = ins, op = op, A = bit.band(bit.rshift(ins, 6), 0xFF)}

		if args == 'ABC' then
			data.B = bit.band(bit.rshift(ins, 23), 0x1FF)
			data.C = bit.band(bit.rshift(ins, 14), 0x1FF)
			data.is_KB = mode.b == 'OpArgK' and data.B > 0xFF
			data.is_KC = mode.c == 'OpArgK' and data.C > 0xFF
		elseif args == 'ABx' then
			data.Bx = bit.band(bit.rshift(ins, 14), 0x3FFFF)
			data.is_K = mode.b == 'OpArgK'
		elseif args == 'AsBx' then
			data.sBx = bit.band(bit.rshift(ins, 14), 0x3FFFF) - 131071
		end

		code[i] = data
	end

	return code
end

local function stm_constants(S)
	local size = S:s_int()
	local consts = {}

	for i = 1, size do
		local tt = stm_byte(S)
		local k

		if tt == 1 then
			k = stm_byte(S) ~= 0
		elseif tt == 3 then
			k = S:s_num()
		elseif tt == 4 then
			k = stm_lstring(S)
		end

		consts[i] = k
	end

	return consts
end

local function stm_subfuncs(S, src)
	local size = S:s_int()
	local sub = {}

	for i = 1, size do
		sub[i] = stm_lua_func(S, src)
	end

	return sub
end

local function stm_lineinfo(S)
	local size = S:s_int()
	local lines = {}

	for i = 1, size do lines[i] = S:s_int() end

	return lines
end

local function stm_locvars(S)
	local size = S:s_int()
	local locvars = {}

	for i = 1, size do locvars[i] = {varname = stm_lstring(S), startpc = S:s_int(), endpc = S:s_int()} end

	return locvars
end

local function stm_upvals(S)
	local size = S:s_int()
	local upvals = {}

	for i = 1, size do upvals[i] = stm_lstring(S) end

	return upvals
end

function stm_lua_func(S, psrc)
	local proto = {}
	local src = stm_lstring(S) or psrc

	proto.source = src

	S:s_int()
	S:s_int()

	proto.numupvals = stm_byte(S)
	proto.numparams = stm_byte(S)

	stm_byte(S)
	stm_byte(S)

	proto.code = stm_instructions(S)
	proto.const = stm_constants(S)
	proto.subs = stm_subfuncs(S, src)
	proto.lines = stm_lineinfo(S)

	stm_locvars(S)
	stm_upvals(S)

	for _, v in ipairs(proto.code) do
		if v.is_K then
			v.const = proto.const[v.Bx + 1]
		else
			if v.is_KB then v.const_B = proto.const[v.B - 0xFF] end

			if v.is_KC then v.const_C = proto.const[v.C - 0xFF] end
		end
	end

	return proto
end

function stm_lua_bytecode(src)

	local rdr_func

	local little
	local size_int
	local size_szt
	local size_ins
	local size_num
	local flag_int

	local stream = {index = 1,
		source = src,}

	assert(stm_string(stream, 4) == '\27Lua', 'invalid Lua signature')
	assert(stm_byte(stream) == 0x51, 'invalid Lua version')
	assert(stm_byte(stream) == 0, 'invalid Lua format')

	little = stm_byte(stream) ~= 0
	size_int = stm_byte(stream)
	size_szt = stm_byte(stream)
	size_ins = stm_byte(stream)
	size_num = stm_byte(stream)
	flag_int = stm_byte(stream) ~= 0

	rdr_func = little and rd_int_le or rd_int_be
	stream.s_int = cst_int_rdr(size_int, rdr_func)
	stream.s_szt = cst_int_rdr(size_szt, rdr_func)
	stream.s_ins = cst_int_rdr(size_ins, rdr_func)

	if flag_int then
		stream.s_num = cst_int_rdr(size_num, rdr_func)
	elseif float_types[size_num] then
		stream.s_num = cst_flt_rdr(size_num, float_types[size_num][little and 'little' or 'big'])
	else
		error('unsupported float size')
	end

	return stm_lua_func(stream, '@virtual')
end

local function close_lua_upvalues(list, index)
	for i, uv in pairs(list) do
		if uv.index >= index then
			uv.value = uv.store[uv.index]
			uv.store = uv
			uv.index = 'value'
			list[i] = nil
		end
	end
end

local function open_lua_upvalue(list, index, stack)
	local prev = list[index]

	if not prev then
		prev = {index = index, store = stack}
		list[index] = prev
	end

	return prev
end

local function wrap_lua_variadic(...) return select('#', ...), {...} end

local function on_lua_error(exst, err)
	local src = exst.source
	local line = exst.lines[exst.pc - 1]
	local psrc, pline, pmsg = string.match(err, '^(.-):(%d+):%s+(.+)')
	local fmt = '%s:%i: [%s:%i] %s'

	line = line or '0'
	psrc = psrc or '?'
	pline = pline or '0'
	pmsg = pmsg or err

	error(string.format(fmt, src, line, psrc, pline, pmsg), 0)
end

local function exec_lua_func(exst)

	local code = exst.code
	local subs = exst.subs
	local env = exst.env
	local upvs = exst.upvals
	local vargs = exst.varargs

	local stktop = -1
	local openupvs = {}
	local stack = exst.stack
	local pc = exst.pc

	while true do
		local inst = code[pc]
		local op = inst.op
		pc = pc + 1

		if op < 19 then
			if op < 9 then
				if op < 4 then
					if op < 2 then
						if op < 1 then

							stack[inst.A] = stack[inst.B]
						else

							stack[inst.A] = inst.const
						end
					elseif op > 2 then

						for i = inst.A, inst.B do stack[i] = nil end
					else

						stack[inst.A] = inst.B ~= 0

						if inst.C ~= 0 then pc = pc + 1 end
					end
				elseif op > 4 then
					if op < 7 then
						if op < 6 then

							stack[inst.A] = env[inst.const]
						else

							local index

							if inst.is_KC then
								index = inst.const_C
							else
								index = stack[inst.C]
							end

							stack[inst.A] = stack[inst.B][index]
						end
					elseif op > 7 then

						local uv = upvs[inst.B]

						uv.store[uv.index] = stack[inst.A]
					else

						env[inst.const] = stack[inst.A]
					end
				else

					local uv = upvs[inst.B]

					stack[inst.A] = uv.store[uv.index]
				end
			elseif op > 9 then
				if op < 14 then
					if op < 12 then
						if op < 11 then

							stack[inst.A] = {}
						else

							local A = inst.A
							local B = inst.B
							local index

							if inst.is_KC then
								index = inst.const_C
							else
								index = stack[inst.C]
							end

							stack[A + 1] = stack[B]
							stack[A] = stack[B][index]
						end
					elseif op > 12 then

						local lhs, rhs

						if inst.is_KB then
							lhs = inst.const_B
						else
							lhs = stack[inst.B]
						end

						if inst.is_KC then
							rhs = inst.const_C
						else
							rhs = stack[inst.C]
						end

						stack[inst.A] = lhs - rhs
					else

						local lhs, rhs

						if inst.is_KB then
							lhs = inst.const_B
						else
							lhs = stack[inst.B]
						end

						if inst.is_KC then
							rhs = inst.const_C
						else
							rhs = stack[inst.C]
						end

						stack[inst.A] = lhs + rhs
					end
				elseif op > 14 then
					if op < 17 then
						if op < 16 then

							local lhs, rhs

							if inst.is_KB then
								lhs = inst.const_B
							else
								lhs = stack[inst.B]
							end

							if inst.is_KC then
								rhs = inst.const_C
							else
								rhs = stack[inst.C]
							end

							stack[inst.A] = lhs / rhs
						else

							local lhs, rhs

							if inst.is_KB then
								lhs = inst.const_B
							else
								lhs = stack[inst.B]
							end

							if inst.is_KC then
								rhs = inst.const_C
							else
								rhs = stack[inst.C]
							end

							stack[inst.A] = lhs % rhs
						end
					elseif op > 17 then

						stack[inst.A] = -stack[inst.B]
					else

						local lhs, rhs

						if inst.is_KB then
							lhs = inst.const_B
						else
							lhs = stack[inst.B]
						end

						if inst.is_KC then
							rhs = inst.const_C
						else
							rhs = stack[inst.C]
						end

						stack[inst.A] = lhs ^ rhs
					end
				else

					local lhs, rhs

					if inst.is_KB then
						lhs = inst.const_B
					else
						lhs = stack[inst.B]
					end

					if inst.is_KC then
						rhs = inst.const_C
					else
						rhs = stack[inst.C]
					end

					stack[inst.A] = lhs * rhs
				end
			else

				local index, value

				if inst.is_KB then
					index = inst.const_B
				else
					index = stack[inst.B]
				end

				if inst.is_KC then
					value = inst.const_C
				else
					value = stack[inst.C]
				end

				stack[inst.A][index] = value
			end
		elseif op > 19 then
			if op < 29 then
				if op < 24 then
					if op < 22 then
						if op < 21 then

							stack[inst.A] = #stack[inst.B]
						else

							local str = stack[inst.B]

							for i = inst.B + 1, inst.C do str = str .. stack[i] end

							stack[inst.A] = str
						end
					elseif op > 22 then

						local lhs, rhs

						if inst.is_KB then
							lhs = inst.const_B
						else
							lhs = stack[inst.B]
						end

						if inst.is_KC then
							rhs = inst.const_C
						else
							rhs = stack[inst.C]
						end

						if (lhs == rhs) ~= (inst.A ~= 0) then pc = pc + 1 end
					else

						pc = pc + inst.sBx
					end
				elseif op > 24 then
					if op < 27 then
						if op < 26 then

							local lhs, rhs

							if inst.is_KB then
								lhs = inst.const_B
							else
								lhs = stack[inst.B]
							end

							if inst.is_KC then
								rhs = inst.const_C
							else
								rhs = stack[inst.C]
							end

							if (lhs <= rhs) ~= (inst.A ~= 0) then pc = pc + 1 end
						else

							if (not stack[inst.A]) == (inst.C ~= 0) then pc = pc + 1 end
						end
					elseif op > 27 then

						local A = inst.A
						local B = inst.B
						local C = inst.C
						local params
						local sz_vals, l_vals

						if B == 0 then
							params = stktop - A
						else
							params = B - 1
						end

						sz_vals, l_vals = wrap_lua_variadic(stack[A](unpack(stack, A + 1, A + params)))

						if C == 0 then
							stktop = A + sz_vals - 1
						else
							sz_vals = C - 1
						end

						for i = 1, sz_vals do stack[A + i - 1] = l_vals[i] end
					else

						local A = inst.A
						local B = inst.B

						if (not stack[B]) == (inst.C ~= 0) then
							pc = pc + 1
						else
							stack[A] = stack[B]
						end
					end
				else

					local lhs, rhs

					if inst.is_KB then
						lhs = inst.const_B
					else
						lhs = stack[inst.B]
					end

					if inst.is_KC then
						rhs = inst.const_C
					else
						rhs = stack[inst.C]
					end

					if (lhs < rhs) ~= (inst.A ~= 0) then pc = pc + 1 end
				end
			elseif op > 29 then
				if op < 34 then
					if op < 32 then
						if op < 31 then

							local A = inst.A
							local B = inst.B
							local vals = {}
							local size

							if B == 0 then
								size = stktop - A + 1
							else
								size = B - 1
							end

							for i = 1, size do vals[i] = stack[A + i - 1] end

							close_lua_upvalues(openupvs, 0)
							return size, vals
						else

							local A = inst.A
							local step = stack[A + 2]
							local index = stack[A] + step
							local limit = stack[A + 1]
							local loops

							if step == math.abs(step) then
								loops = index <= limit
							else
								loops = index >= limit
							end

							if loops then
								stack[inst.A] = index
								stack[inst.A + 3] = index
								pc = pc + inst.sBx
							end
						end
					elseif op > 32 then

						local A = inst.A
						local func = stack[A]
						local state = stack[A + 1]
						local index = stack[A + 2]
						local base = A + 3
						local vals

						stack[base + 2] = index
						stack[base + 1] = state
						stack[base] = func

						vals = {func(state, index)}

						for i = 1, inst.C do stack[base + i - 1] = vals[i] end

						if stack[base] ~= nil then
							stack[A + 2] = stack[base]
						else
							pc = pc + 1
						end
					else

						local A = inst.A
						local init, limit, step

						init = assert(tonumber(stack[A]), '`for` initial value must be a number')
						limit = assert(tonumber(stack[A + 1]), '`for` limit must be a number')
						step = assert(tonumber(stack[A + 2]), '`for` step must be a number')

						stack[A] = init - step
						stack[A + 1] = limit
						stack[A + 2] = step

						pc = pc + inst.sBx
					end
				elseif op > 34 then
					if op < 36 then

						close_lua_upvalues(openupvs, inst.A)
					elseif op > 36 then

						local A = inst.A
						local size = inst.B

						if size == 0 then
							size = vargs.size
							stktop = A + size - 1
						end

						for i = 1, size do stack[A + i - 1] = vargs.list[i] end
					else

						local sub = subs[inst.Bx + 1]
						local nups = sub.numupvals
						local uvlist

						if nups ~= 0 then
							uvlist = {}

							for i = 1, nups do
								local pseudo = code[pc + i - 1]

								if pseudo.op == 0 then
									uvlist[i - 1] = open_lua_upvalue(openupvs, pseudo.B, stack)
								elseif pseudo.op == 4 then
									uvlist[i - 1] = upvs[pseudo.B]
								end
							end

							pc = pc + nups
						end

						stack[inst.A] = wrap_lua_func(sub, env, uvlist)
					end
				else

					local A = inst.A
					local C = inst.C
					local size = inst.B
					local tab = stack[A]
					local offset

					if size == 0 then size = stktop - A end

					if C == 0 then
						C = inst[pc].value
						pc = pc + 1
					end

					offset = (C - 1) * FIELDS_PER_FLUSH

					for i = 1, size do tab[i + offset] = stack[A + i] end
				end
			else

				local A = inst.A
				local B = inst.B
				local params

				if B == 0 then
					params = stktop - A
				else
					params = B - 1
				end

				close_lua_upvalues(openupvs, 0)
				return wrap_lua_variadic(stack[A](unpack(stack, A + 1, A + params)))
			end
		else

			stack[inst.A] = not stack[inst.B]
		end

		exst.pc = pc
	end
end

function wrap_lua_func(state, env, upvals)
	local st_code = state.code
	local st_subs = state.subs
	local st_lines = state.lines
	local st_source = state.source
	local st_numparams = state.numparams

	local function exec_wrap(...)
		local stack = {}
		local varargs = {}
		local sizevarg = 0
		local sz_args, l_args = wrap_lua_variadic(...)

		local exst
		local ok, err, vals

		for i = 1, st_numparams do stack[i - 1] = l_args[i] end

		if st_numparams < sz_args then
			sizevarg = sz_args - st_numparams
			for i = 1, sizevarg do varargs[i] = l_args[st_numparams + i] end
		end

		exst = {varargs = {list = varargs, size = sizevarg},
			code = st_code,
			subs = st_subs,
			lines = st_lines,
			source = st_source,
			env = env,
			upvals = upvals,
			stack = stack,
			pc = 1,}

		ok, err, vals = pcall(exec_lua_func, exst, ...)

		if ok then
			return unpack(vals, 1, err)
		else
			on_lua_error(exst, err)
		end

		return
	end

	return exec_wrap
end

return function(bCode, env)
	return wrap_lua_func(stm_lua_bytecode(bCode), env or getfenv(0))
end