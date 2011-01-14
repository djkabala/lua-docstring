--[[ Lua "help" module
allows setting docstrings for Lua objects,
and optionally forwarding help calls
to other subsystems that have introspective
information about objects (Luabind, osgLua
included)
]]

--[[ Original Author: Ryan Pavlik <rpavlik@acm.org> <abiryan@ryand.net>
Copyright 2011 Iowa State University.
Distributed under the Boost Software License, Version 1.0.

Boost Software License - Version 1.0 - August 17th, 2003

Permission is hereby granted, free of charge, to any person or organization
obtaining a copy of the software and accompanying documentation covered by
this license (the "Software") to use, reproduce, display, distribute,
execute, and transmit the Software, and to prepare derivative works of the
Software, and to permit third-parties to whom the Software is furnished to
do so, all subject to the following:

The copyright notices in the Software and this entire statement, including
the above license grant, this restriction and the following disclaimer,
must be included in all copies of the Software, in whole or in part, and
all derivative works of the Software, unless such copies or derivative
works are solely in the form of machine-executable object code generated by
a source language processor.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE, TITLE AND NON-INFRINGEMENT. IN NO EVENT
SHALL THE COPYRIGHT HOLDERS OR ANYONE DISTRIBUTING THE SOFTWARE BE LIABLE
FOR ANY DAMAGES OR OTHER LIABILITY, WHETHER IN CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.
]]

local mt = {}
help = setmetatable({}, mt)
local docstrings = setmetatable({}, {__mode = "kv"})
local helpExtensions = {}

function mt:__call(obj,...)
	if obj == nil then
		print("help(obj) - call to learn information about a particular object or value.")
		return
	end
	local helpContent = help.lookup(obj)
	
	if helpContent then
		print("Help:\t" .. help.formatHelp(helpContent))
	else
		print("type(obj) = " .. type(obj))	
		print("No further help available!")
	end
end

function help.formatHelp(h)
  if type(h) == "string" then
    return h
  elseif type(h) == "table" then
    local keys = {}
    local str = ""
    for i, v in ipairs(h) do
      keys[i] = true
      str = str .. "\n" .. v
    end
    for k,v in pairs(h) do
      if not keys[k] then
        if type(v) == "table" then
          str = string.format("%s\n%s = {", str, k)
          for _, val in ipairs(v) do
            str = str .. "\n\t" .. tostring(val)
          end
          str = str .. "\n}\n"
        else
          str = str .. string.format("\n%s = %s", k, tostring(v))
        end
      end
    end
    return str
  else
    return h
  end
end

function help.lookup(obj)
	if docstrings[obj] then
		 return docstrings[obj]
	end
	for _, v in ipairs(helpExtensions) do
		local helpContent = v(obj)
		if helpContent then 
			return helpContent
		end
	end
	return nil
end

function help.docstring(docs)
	local mt = {}
	-- handle the .. operator for inline documentation
	function mt.__concat(a, f)
		docstrings[f] = docs
		return f
	end
	
	-- hanadle the () operator for after-the-fact docs
	function mt:__call(f)
		docstrings[f] = docs
		return f
	end
	return setmetatable({}, mt)
end

function help.addHelpExtension(func)
	table.insert(helpExtensions, func)
end

if class_info then
  require("helpLuabind")
end

if osgLua then
  require("helpOsgLua")
end