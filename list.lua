local pairs = pairs

module(...)

local _m = {}

function init()
   local m = {first = 0, last = -1}
   for k, v in pairs(_m) do
      m[k] = v
   end
   return m
end

function _m.new ()
   return {first = 0, last = -1}
end

-- FIXME: the term "self" is incorrect below, should use "lst" or so.

function _m.size(self)
   return self.last - self.first + 1
end

function _m.pushleft (self, value)
   local first = self.first - 1
   self.first = first
   self[first] = value
end
    
function _m.pushright (self, value)
   local last = self.last + 1
   self.last = last
   self[last] = value
end
    
function _m.popleft (self)
   local first = self.first
   if first > self.last then return nil end
   local value = self[first]
   self[first] = nil        -- to allow garbage collection
   self.first = first + 1
   return value
end
    
function _m.popright (self)
   local last = self.last
   if self.first > last then return nil end
   local value = self[last]
   self[last] = nil         -- to allow garbage collection
   self.last = last - 1
   return value
end

function _m.clearright(self)
   self.last = self.first - 1
end

function _m.clearleft(self)
   self.first = self.last + 1
end

return _m
