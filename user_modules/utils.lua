---------------------------------------------------------------------------------------------------
-- Utils
---------------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.mobileHost = "127.0.0.1"

--[[ Required Shared libraries ]]
local json = require("modules/json")
local events = require('events')

--[[ Module ]]
local m = {}

--[[ Constants ]]
m.timeout = 2000

--[[ Functions ]]

--[[ @jsonFileToTable: convert .json file to table
--! @parameters:
--! pFileName - file name
--! @return: table
--]]
function m.jsonFileToTable(pFileName)
  local f = io.open(pFileName, "r")
  local content = f:read("*all")
  f:close()
  return json.decode(content)
end

--[[ @tableToJsonFile: convert table to .json file
--! @parameters:
--! pTbl - table
--! pFileName - file name
--! @return: none
--]]
function m.tableToJsonFile(pTbl, pFileName)
  local f = io.open(pFileName, "w")
  f:write(json.encode(pTbl))
  f:close()
end

--[[ @readFile: read data from file
--! @parameters:
--! pPath - path to file
-- @return: content of the file
--]]
function m.readFile(pPath)
  local open = io.open
  local file = open(pPath, "rb")
  if not file then return nil end
  local content = file:read "*a"
  file:close()
  return content
end

--[[ @cloneTable: clone table
--! @parameters:
--! pTbl - table to clone
--! @return: cloned table
--]]
function m.cloneTable(pTbl)
  if pTbl == nil then
    return {}
  end
  local copy = {}
  for k, v in pairs(pTbl) do
    if type(v) == 'table' then
      v = m:cloneTable(v)
    end
    copy[k] = v
  end
  return copy
end

--[[ @wait: delay test step for specific timeout
--! @parameters:
--! pTimeOut - time to wait in ms
--! @return: none
--]]
function m.wait(pTimeOut)
  if not pTimeOut then pTimeOut = m.timeout end
  local event = events.Event()
  event.matches = function(event1, event2) return event1 == event2 end
  EXPECT_EVENT(event, "Delayed event")
  :Timeout(pTimeOut + 60000)
  RUN_AFTER(function() RAISE_EVENT(event, event) end, pTimeOut)
end

--[[ @getDeviceName: provide device name
--! @parameters: none
--! @return: name of the device
--]]
function m.getDeviceName()
  return config.mobileHost .. ":" .. config.mobilePort
end

--[[ @getDeviceMAC: provide device MAC address
--! @parameters: none
--! @return: MAC address of the device
--]]
function m.getDeviceMAC()
  local cmd = "echo -n " .. m.getDeviceName() .. " | sha256sum | awk '{printf $1}'"
  local handle = io.popen(cmd)
  local result = handle:read("*a")
  handle:close()
  return result
end

--[[ @protect: make table immutable
--! @parameters:
--! pTbl - mutable table
--! @return: immutable table
--]]
function m.protect(pTbl)
  local mt = {
    __index = pTbl,
    __newindex = function(_, k, v)
      error("Attempting to change item " .. tostring(k) .. " to " .. tostring(v), 2)
    end
  }
  return setmetatable({}, mt)
end

--[[ @cprint: print color message to console
--! @parameters:
--! pColor - color code
--! pMsg - message
--]]
function m.cprint(pColor, ...)
  print("\27[" .. tostring(pColor) .. "m" .. table.concat(table.pack(...), "\t") .. "\27[0m")
end

--[[ @spairs: sorted iterator, allows to get items from table sorted by key
-- Usually used as a replacement of standard 'pairs' function
--! @parameters:
--! pTbl - table to iterate
--! @return: iterator
--]]
function m.spairs(pTbl)
  local keys = {}
  for k in pairs(pTbl) do
    keys[#keys+1] = k
  end
  table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
  local i = 0
  return function()
    i = i + 1
    if keys[i] then
      return keys[i], pTbl[keys[i]]
    end
  end
end

--[[ @tableToString: convert table to string
--! @parameters:
--! pTbl - table to convert
--! @return: string
--]]
function m.tableToString(pTbl)
  local s = ""
  local function tPrint(tbl, level)
    if not level then level = 0 end
    for k, v in m.spairs(tbl) do
      local indent = string.rep(" ", level * 4)
      s = s .. indent .. "[" .. k .. "]: "
      if type(v) == "table" then
        s = s .. "{\n"
        tPrint(v, level + 1)
        s = s .. indent .. "}"
      elseif type(v) == "string" then
        s = s .. "'" .. tostring(v) .. "'"
      else
        s = s .. tostring(v)
      end
      s = s .. "\n"
    end
  end
  tPrint(pTbl)
  return string.sub(s, 1, string.len(s) - 1)
end

--[[ @printTable: print table
--! @parameters:
--! pColor - color code
--! pTbl - table to print
--! @return: none
--]]
function m.cprintTable(pColor, pTbl)
  m.cprint(pColor, string.rep("-", 50))
  m.cprint(pColor, m.tableToString(pTbl))
  m.cprint(pColor, string.rep("-", 50))
end

--[[ @printTable: print table
--! @parameters:
--! pTbl - table to print
--! @return: none
--]]
function m.printTable(pTbl)
  m.cprintTable(39, pTbl)
end

return m
