----------------------------------------------------------------------------------------------------
-- API Helper module
----------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]-------------------------------------------------------------------
local utils = require("user_modules/utils")
local apiLoader = require("modules/api_loader")

--[[ Module ]]--------------------------------------------------------------------------------------
local m = {}

--[[ Constants ]]-----------------------------------------------------------------------------------
m.apiType = {
  MOBILE = "mobile",
  HMI = "hmi"
}

m.eventType = {
  REQUEST = "request",
  RESPONSE = "response",
  NOTIFICATION = "notification"
}

m.dataType = {
  INTEGER = { type = "Integer", min = -2147483647, max = 2147483647 },
  FLOAT = { type = "Float", min = -1000000, max = 1000000 },
  DOUBLE = { type = "Double", min = -1000000000, max = 1000000000 },
  STRING = { type = "String", min = 1, max = 100 },
  BOOLEAN = { type = "Boolean" },
  ENUM = { type = "Enum" },
  STRUCT = { type = "Struct" }
}

--[[ Variables ]]-----------------------------------------------------------------------------------
local api = {
  mobile = apiLoader.init("data/MOBILE_API.xml"),
  hmi = apiLoader.init("data/HMI_API.xml")
}

local schema = {
  mobile = api.mobile.interface[next(api.mobile.interface)],
  hmi = api.hmi.interface["Common"]
}

--[[ Functions ]]-----------------------------------------------------------------------------------

--[[ @getType: Provide type of the parameter without interface
--! @parameters:
--! pType: type of the parameter (possibly with interface)
--! @return: type of the parameter
--]]
local function getType(pType)
  if string.find(pType, "%.") then
    return utils.splitString(pType, ".")[2]
  end
  return pType
end

--[[ @getParamsData: Provide hierarchy of parameters and sub-parameters for the defined API function
--! @parameters:
--! pAPIType: type of the API, e.g. 'mobile' or 'hmi'
--! pEventType: type of the event, e.g. 'request', 'response' or 'notification'
--! pFuncName: name of the API function, e.g. 'GetVehicleData'
--! @return: structure with hierarchy of parameters
--]]
local function getParamsData(pAPIType, pEventType, pFuncName)

  local function buildParams(pTbl, pParams)
    for k, v in pairs(pParams) do
      pTbl[k] = utils.cloneTable(v)
      if schema[pAPIType].struct[getType(v.type)] then
        pTbl[k].data = {}
        buildParams(pTbl[k].data, schema[pAPIType].struct[getType(v.type)].param)
        pTbl[k].type = m.dataType.STRUCT.type
      elseif schema[pAPIType].enum[getType(v.type)] then
        pTbl[k].data = {}
        for kk in utils.spairs(schema[pAPIType].enum[getType(v.type)]) do
          table.insert(pTbl[k].data, kk)
        end
        pTbl[k].type = m.dataType.ENUM.type
      end
    end
  end

  local function getAPIParams()
    if pAPIType == m.apiType.MOBILE then
      return schema.mobile.type[pEventType].functions[pFuncName].param
    elseif pAPIType == m.apiType.HMI then
      local iName = utils.splitString(pFuncName, ".")[1]
      local fName = utils.splitString(pFuncName, ".")[2]
      return api.hmi.interface[iName].type[pEventType].functions[fName].param
    end
  end

  local params = getAPIParams(pAPIType)

  local out = {}
  buildParams(out, params)

  local function updateBooleanValue(pValue)
    local o = pValue
    if type(pValue) == "string" then
      if pValue == "true" then o = true
      elseif pValue == "false" then o = false
      end
    end
    return o
  end

  local function updateValues(pTbl)
    for k, v in pairs(pTbl) do
      if type(v) == "table" then
        updateValues(v)
      else
        pTbl[k] = updateBooleanValue(v)
      end
    end
  end
  updateValues(out)

  return out
end

--[[ @getGraph: Provide graph of all parameters for defined API function
--! @parameters:
--! pAPIType: type of the API, e.g. 'mobile' or 'hmi'
--! pEventType: type of the event, e.g. 'request', 'response' or 'notification'
--! pFuncName: name of the API function, e.g. 'GetVehicleData'
--! @return: graph of all parameters (incl. sub-parameters) for the API function
--]]
function m.getGraph(pAPIType, pEventType, pFuncName)

  local function getGraph(pParams, pGraph, pParentId)
    for k, v in utils.spairs(pParams) do
      local item = utils.cloneTable(v)
      item.parentId = pParentId
      item.name = k
      if v.type ~= m.dataType.ENUM.type then
        item.data = nil
      end
      table.insert(pGraph, item)
      v.id = #pGraph
      if v.type == m.dataType.STRUCT.type then
        getGraph(v.data, pGraph, #pGraph)
      end
    end
    return pGraph
  end

  local apiParamsData = getParamsData(pAPIType, pEventType, pFuncName)
  return getGraph(apiParamsData, {})
end

--[[ @getFullParamName: Provide full parameter name created based on hierarchy.
--! E.g. for the `pressure` sub-parameter it returns `tirePressure.innerLeftRear.pressure`
--! @parameters:
--! pGraph: graph which includes defined parameter
--! pId: id of the parameter in graph
--! @return: full name of the parameter
--]]
function m.getFullParamName(pGraph, pId)
  local out = pGraph[pId].name
  pId = pGraph[pId].parentId
  while pId do
    out = pGraph[pId].name .. "." .. out
    pId = pGraph[pId].parentId
  end
  return out
end

--[[ @getBranch: Provide branch (part of the initial graph) related to defined parameter
--! @parameters:
--! pGraph: graph which includes defined parameter
--! pId: id of the parameter in graph
--! @return: reduced graph with defined parameter and all it's sub-parameters
--]]
function m.getBranch(pGraph, pId)
  local function getChildren(pGraph, pId, pTbl)
    pTbl[pId] = true
    for k, v in pairs(pGraph) do
      if v.parentId == pId then
        pTbl[k] = true
        getChildren(pGraph, k, pTbl)
      end
    end
    return pTbl
  end
  local children = getChildren(pGraph, pId, {})
  local branch = utils.cloneTable(pGraph)
  for k in pairs(branch) do
    if not children[k] then branch[k] = nil end
  end
  return branch
end

return m
