---------------------------------------------------------------------------------------------------
-- Utils
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local json = require("modules/json")
local events = require('events')

--[[ Module ]]
local m = {}

--[[ Constants ]]
m.timeout = 2000

--[[ Functions ]]
m.json = json

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
  elseif pTbl == json.EMPTY_ARRAY then
    return pTbl
  end
  local copy = {}
  for k, v in pairs(pTbl) do
    if type(v) == 'table' then
      v = m.cloneTable(v)
    end
    copy[k] = v
  end
  if getmetatable(pTbl) ~= nil then
    setmetatable(copy, getmetatable(pTbl))
  end
  return copy
end

-- Get table size on top level
local function getTableSize(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end

--[[ @isTableEqual: check equality of two tables does not taking into account their metatables
--! @parameters:
--! pTable1 - table one
--! pTable2 - table two
--! @return: boolean which represents equality of two tables
--]]
function m.isTableEqual(pTable1, pTable2)
  -- compare value types
  local type1 = type(pTable1)
  local type2 = type(pTable2)
  if type1 ~= type2 then return false end
  if type1 ~= 'table' and type2 ~= 'table' then return pTable1 == pTable2 end
  local size_tab1 = getTableSize(pTable1)
  local size_tab2 = getTableSize(pTable2)
  if size_tab1 ~= size_tab2 then return false end

  --compare arrays
  if json.isArray(pTable1) and json.isArray(pTable2) then
    local found_element
    local copy_table2 = m.cloneTable(pTable2)
    for i, _  in pairs(pTable1) do
      found_element = false
      for j, _ in pairs(copy_table2) do
        if m.isTableEqual(pTable1[i], copy_table2[j]) then
          copy_table2[j] = nil
          found_element = true
          break
        end
      end
      if found_element == false then
        break
      end
    end
    if getTableSize(copy_table2) == 0 then
      return true
    else
      return false
    end
  end

  -- compare tables by elements
  local already_compared = {} --optimization
  for _,v1 in pairs(pTable1) do
    for k2,v2 in pairs(pTable2) do
      if not already_compared[k2] and m.isTableEqual(v1,v2) then
        already_compared[k2] = true
      end
    end
  end
  if size_tab2 ~= getTableSize(already_compared) then
    return false
  end
  return true
end

--[[ @isTableContains: check whether table contains value
--! @parameters:
--! pTable - table
--! pValue - value
--! @return: boolean which represents whether table contains value
--]]
function m.isTableContains(pTable, pValue)
  if not pTable then return false end
  for _,val in pairs(pTable) do
    if val == pValue then return true end
  end
  return false
end

--- [DEPRECATED]
--[[ @wait: delay test step for specific timeout
--! @parameters:
--! pTimeOut - time to wait in ms
--! @return: Expectation object
--]]
function m.wait(pTimeOut)
  if not pTimeOut then pTimeOut = m.timeout end
  local event = events.Event()
  event.matches = function(event1, event2) return event1 == event2 end
  local ret = EXPECT_EVENT(event, "Delayed event")
  :Timeout(pTimeOut + 60000)
  RUN_AFTER(function() RAISE_EVENT(event, event) end, pTimeOut)
  return ret
end

--- [DEPRECATED]
--[[ @getDeviceName: provide device name
--! @parameters: none
--! @return: name of the device
--]]
function m.getDeviceName(pHost, pPort)
  if not pHost then pHost = config.mobileHost end
  if not pPort then pPort = config.mobilePort end
  if config.defaultMobileAdapterType == "TCP" then
    local parameters = {
      host = pHost,
      port = pPort
    }
    return m.buildDeviceName("TCP", parameters)
  else
    return m.buildDeviceName("WS")
  end
end

--- [DEPRECATED]
--[[ @getDeviceMAC: provide device MAC address
--! @parameters: none
--! @return: MAC address of the device
--]]
function m.getDeviceMAC(pHost, pPort)
  if not pHost then pHost = config.mobileHost end
  if not pPort then pPort = config.mobilePort end
  local parameters = nil
  if config.defaultMobileAdapterType == "TCP" then
    parameters = { host = pHost, port = pPort }
  end
  return m.buildDeviceMAC(config.defaultMobileAdapterType, parameters)
end

--[[ @buildDeviceName: provide device name
--! @parameters:
--! pDeviceType - device type (TCP, WS)
--! pParams - device specific parameters
--! TCP:
--!   host - host of connection
--!   port - port of connection
--! WS: none
--! @return: name of the device
--]]
function m.buildDeviceName(pDeviceType, pParams)
  if pDeviceType == "TCP" then
    local host = config.mobileHost
    local port = config.mobilePort
    if type(pParams) == "table" then
      host = pParams.host or host
      port = pParams.port or port
    end
    return host .. ":" .. port
  elseif pDeviceType == "WS" or pDeviceType == "WSS" then
    return "Web Engine"
  else
    m.cprint(35, "Unknown device type " .. tostring(pDeviceType)
      .. "\n Possible values: TCP, WS, WSS")
  end
  return nil
end

--[[ @buildDeviceMAC: provide device MAC address
--! @parameters:
--! pDeviceType - device type (TCP, WS)
--! pParams - device specific parameters
--! TCP:
--!   host - host of connection
--!   port - port of connection
--! WS:
--!   vin - vin of vehicle
--! @return: MAC address of the device
--]]
function m.buildDeviceMAC(pDeviceType, pParams)
  local function makeHash(pValue)
    local cmd = "echo -n " .. tostring(pValue) .. " | sha256sum | awk '{printf $1}'"
    local handle = io.popen(cmd)
    local result = handle:read("*a")
    handle:close()
    return result
  end

  if pDeviceType == "TCP" then
    return makeHash(pParams.host .. ":" .. pParams.port)
  elseif pDeviceType == "WS" or pDeviceType == "WSS" then
    return makeHash(config.webengineUniqueId)
  else
    m.cprint(35, "ERROR: Unknown device type " .. tostring(pDeviceType)
      .. "\n Possible values: TCP, WS, WSS")
    return makeHash(nil)
  end
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
  local function toString(v)
    if type(v) == "string" then
      return "'" .. tostring(v) .. "'"
    end
      return tostring(v)
  end

  local s = ""
  local function tPrint(tbl, level)
    local indent = string.rep(" ", level * 4)
    s = s .. "{\n"
    for k, v in m.spairs(tbl) do
      s = s .. indent .. "[" .. toString(k) .. "]: "
      if type(v) == "table" then
        tPrint(v, level + 1)
      else
        s = s .. toString(v)
      end
      s = s .. "\n"
    end
    s = s .. string.rep(" ", (level - 1) * 4) .. "}"
  end
  tPrint(pTbl, 1)
  return string.sub(s, 1, string.len(s))
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

--[[ @toString: create string representation for Lua variable
--! @parameters:
--! pVar - variable to string
--! @return: string
--]]
function m.toString(pVar)
  if type(pVar) == "table" then
    return m.tableToString(pVar)
  end
    return tostring(pVar)
end

--[[ @isFileExist: check if file or directory exists
--! @parameters:
--! pFile - path to file or directory
--! @return: true - in case if file exists, otherwise - false
--]]
function m.isFileExist(pFile)
  local file = io.open(pFile, "r")
  if file == nil then
    return false
  else
    file:close()
    return true
  end
end

--[[ @addNetworkInterface: add network interface for new connection emulation
--! @parameters:
--! pId - unique id of connection
--! pAddress - network address
--! @return: none
--]]
function m.addNetworkInterface(pId, pAddress)
  if config.remoteConnection.enabled then
    m.cprint(31, "!!! utils.addNetworkInterface has been not implemented yet !!!")
  else
    os.execute("ifconfig lo:" .. pId .." " .. pAddress)
  end
end

--[[ @addNetworkInterface: remove network interface
--! @parameters:
--! pId - unique id of connection
--! pAddress - network address
--! @return: none
--]]
function m.deleteNetworkInterface(pId)
  if config.remoteConnection.enabled then
    m.cprint(31, "!!! utils.deleteNetworkInterface has been not implemented yet !!!")
  else
    os.execute("ifconfig lo:" .. pId .." down")
  end
end

--[[ @getDeviceTransportType: provide transport type name
--! @parameters: none
--! @return: none
--]]
function m.getDeviceTransportType()
  if config.defaultMobileAdapterType == "TCP" then
    return "WIFI"
  elseif config.defaultMobileAdapterType == "WS" then
    return "WEBENGINE_WEBSOCKET"
  elseif config.defaultMobileAdapterType == "WSS" then
    return "WEBENGINE_WEBSOCKET"
  end
end

--[[ @splitString: split string by defined delimiter
--! @parameters:
--! pStr - string to be split
--! pDelimiter - delimiter
--! @return: table with string parts
--]]
function m.splitString(pStr, pDelimiter)
  local result = {}
  for match in (pStr .. pDelimiter):gmatch("(.-)%" .. pDelimiter) do
    if string.len(match) > 0 then table.insert(result, match) end
  end
  return result
end

return m
