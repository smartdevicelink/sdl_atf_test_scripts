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

--[[ @inheritObjects: copy objects from source module to target
-- 'objects' means: tables, functions, fields
-- Function is useful for 'inheriting' data of one module to another
--! @parameters:
--! pTargetObject - target module
--! pSourceObject - source module
--! @return: none
--]]
function m.inheritObjects(pTargetObject, pSourceObject)
  for k, v in pairs(pSourceObject) do
    if type(v) == "table" then
      pTargetObject[k] = m.cloneTable(v)
    elseif type(v) == "function" then
      pTargetObject[k] = function(...)
        return v(...)
      end
    else
      pTargetObject[k] = v
    end
  end
end

--[[ @cprint: print color message to console
--! @parameters:
--! pColor - color code
--! pMsg - message
--]]
function m.cprint(pColor, pMsg)
  print("\27[" .. tostring(pColor) .. "m" .. tostring(pMsg) .. "\27[0m")
end

return m
