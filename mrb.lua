#!/usr/bin/env lua

--local Prof = require "profiler"

-- TODO: different instances of the same sb shall be treated as different sb's
-- TODO: do we really support memory writing w/ renaming?
-- TODO: super block merging coelessing
--       the sb's that only depends on a single predecessor, can be merged into the predecessor

local List = require "list"

function logd(...)
   print(...)
end

-- Core
-- to manage all the cores in the processor
Core = {num=0, clocks=0}
function Core.new()
   local core_id = Core.num + 1
   local core = {id=core_id, inst_total=0, inst_pend=0, sb_cnt=0}
   Core[core_id] = core
   Core.num = Core.num + 1
   return core
end

-- return the least busy core
function Core.get_free_core()
   local core = Core[1]
   for i=1, Core.num do
      if core.inst_pend > Core[i].inst_pend then
	 core = Core[i]
      end
   end
   return core
end

-- TODO we shall do the work in Core.run() directly
function Core.tick(clocks)

   local core

   for i=1, Core.num do
      core = Core[i]
      if core.inst_pend >= clocks then
	 core.inst_total = core.inst_total + clocks
	 core.inst_pend = core.inst_pend - clocks
      else
	 core.inst_total = core.inst_total + core.inst_pend
	 core.inst_pend = 0
      end
   end   

   Core.clocks = Core.clocks + clocks
   -- TODO add a switch verbose or terse
   -- logd(i_sum, ' in ', clocks, 'clocks')
end

-- to run until at least one core is free (finishes its pending
-- instructions)
function Core.run()
   local clocks = 0
   local isum = 0
   for i=1, Core.num do
      local c = Core[i]
      if clocks < c.inst_pend then clocks = c.inst_pend end
      isum = isum + c.inst_pend
      c.inst_total = c.inst_total + c.inst_pend
      c.inst_pend = 0
   end

   Core.clocks = Core.clocks + clocks
   

   -- -- collect the cores with pending sb's to run
   -- local busy_cores = {}
   -- for i=1, Core.num do
   --    if Core[i].inst_pend ~= 0 then
   -- 	 busy_cores[#busy_cores + 1] = Core[i]
   --    end
   -- end

   -- if #busy_cores > 0 then
   --    -- find the least busy core
   --    local pend = busy_cores[1].inst_pend
   --    for i=2, #busy_cores do
   -- 	 if pend > busy_cores[i].inst_pend then pend = busy_cores[i].inst_pend end
   --    end
   --    -- tick as many clocks as needed to free the least busy core
   --    Core.tick(pend)
   -- end

end

local sb_addr = 0
-- the collection of the predecessors of the current sb
local deps = {}
local sb_weight = 0
-- collection of all the buffered sb's, key is the addr, val is the sb
local sbs = {}

-- re-order buffer that contains the super blocks awaiting for issuing
local rob = {}

function init_rob(rob, MAX, WIDTH)
   -- the rob.buf is a list of list, as each level of the rob shall
   -- contain several sb's that with the same depth
   -- E.g. with MAX=3 and WIDTH=2, it looks like
   -- {{l00,l01},{l10,l11},{l20,l21}}
   rob.buf = List.new()
   rob.MAX = MAX
   rob.WIDTH = WIDTH
end

-- we are entering a new superblock
function start_sb(addr)
   sb_addr = addr
end

-- place the superblock in the rob
function place_sb(rob, sb)

   -- the sb should be placed after all of its depending sb's
   local buf = rob.buf
   -- d is the depth, i.e. in which level/line of the rob the sb should be put
   local d = buf.first
   local i = 0
   for k, v in pairs(deps) do
      i = i + 1
      if d <= v.d then d = v.d end
   end

   -- look for a non-full line which can hold the sb
   found_slot = false
   local l
   for i=d+1, buf.last do
      l = buf[i]
      if #l < rob.WIDTH then 
	 found_slot = true 
	 d = i
	 break
      end
   end

   if not found_slot then
      List.pushright(buf, {})
      d = buf.last
      l = buf[d]
   end

   -- place the sb in the proper level of the rob
   sb['d'] = d 
   l[#l + 1] = sb

end				-- function place_sb(rob, sb)

-- issue a line of sb's from the rob when necessary
function issue_sb(rob)
   local buf = rob.buf
   if List.size(buf) > rob.MAX then
      local l = List.popleft(buf)
      local w_sum = 0
      local w_max = 0

      -- to make room for more sb's
      Core.run()

      -- TODO add a switch verbose or terse
      logd('issue:')      
      
      for k, v in pairs(l) do
	 -- TODO add a switch verbose or terse
	 logd('     ', v.addr, v.w)
	 w_sum = w_sum + v.w
	 if w_max < 0 + v.w then
	    w_max = 0 + v.w
	 end

	 -- dispatch the sb to a free core
	 local core = Core.get_free_core()
	 core.inst_pend = core.inst_pend + v.w
	 core.sb_cnt = core.sb_cnt + 1

	 sbs[v.addr] = nil
      end      

      -- TODO add a switch verbose or terse
      logd(w_sum, '->', w_max)
   end
end

-- the current superblock ends, we'll analyze it here
function end_sb()
   -- build the superblock
   local sb = {}
   sb['addr'] = sb_addr
   sb['w'] = sb_weight
   sb['deps'] = deps
   sbs[sb_addr] = sb

   place_sb(rob, sb)
   issue_sb(rob)

   deps = {}
end				-- function end_sb()

-- the table deps is a set, we use addr as key, so searching it is
-- efficient
function add_depended(addr)
   deps[addr] = sbs[addr]
   logd('add_depended:', addr)
end

function set_sb_weight(w)
   sb_weight = w
end

function parse_lackey_log(sb_size)
   local i = 0
   local weight_accu = 0
   for line in io.lines() do
      if line:sub(1,2) ~= '==' then
	 i = i + 1
	 local k = line:sub(1,2)
	 if k == 'SB' then
	    if weight_accu >= sb_size then
	       set_sb_weight(weight_accu)
	       end_sb()
	       start_sb(line:sub(4))	       
	       weight_accu = 0
	    end
	 elseif k == ' D' then
	    add_depended(line:sub(4))
	 elseif k == ' W' then
	    weight_accu = weight_accu + tonumber(line:sub(4))
	 end
      end
   end
   -- TODO add a switch verbose or terse
   -- logd(i)
end				--  function parse_lackey_log()

-- the parameters that affects the parallelism 
local core_num = 16
local rob_w = 16
local rob_d = 8
local sb_size = 50

for i, v in ipairs(arg) do
   --print(type(v))
   if (v:sub(1,2) == "-c") then
      --print("core number:")
      core_num = tonumber(v:sub(3))
   -- elseif (v:sub(1,2) == "-w") then
   --    --print("ROB width:")
   --    rob_w = tonumber(v:sub(3))
   elseif (v:sub(1,2) == "-d") then
      --print("ROB depth:")
      rob_d = tonumber(v:sub(3))
   elseif (v:sub(1,2) == "-s") then
      --print("minimum superblock size:")
      sb_size = tonumber(v:sub(3))
   end
end

--Prof.start("mrb.prof.data")

for i=1, core_num do
   Core.new()
end

rob_w = core_num
init_rob(rob, rob_d, rob_w)
parse_lackey_log(sb_size)

-- summarize
local inst_total_sum = 0
for i=1, Core.num do
   print(Core[i].inst_total, Core[i].sb_cnt)
   inst_total_sum = inst_total_sum + Core[i].inst_total
end

print ("c/s/w/d=" .. core_num .. "/" .. sb_size .. "/" .. rob_w .. "/" .. rob_d .. ":", "execute " .. inst_total_sum .. " insts in " .. Core.clocks .. ": ", inst_total_sum/Core.clocks)

--Prof.stop()
