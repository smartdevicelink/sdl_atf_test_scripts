----------------------------------------------------------------------------------------------------
-- API Test Data Generator module
----------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]-------------------------------------------------------------------
local ah = require("user_modules/api/APIHelper")

--[[ Module ]]--------------------------------------------------------------------------------------
local m = {}

--[[ Constants ]]-----------------------------------------------------------------------------------
m.valueType = {
  VALID_RANDOM = 1,
  LOWER_IN_BOUND = 2,
  UPPER_IN_BOUND = 3,
  LOWER_OUT_OF_BOUND = 4,
  UPPER_OUT_OF_BOUND = 5,
  INVALID_TYPE = 6
}

--[[ Value generators ]]----------------------------------------------------------------------------
math.randomseed(tonumber(tostring(os.time()):reverse():sub(1,6)))

--[[ @getStringValue: Return value for 'string' data type
--! @parameters:
--! pTypeData: table with data type restrictions
--! @return: value for the parameter
--]]
local function getStringValue(pTypeData)
  local length
  if pTypeData.valueType == m.valueType.LOWER_IN_BOUND then
    length = pTypeData.minlength
    if not length or length == 0 then length = ah.dataType.STRING.min end
  elseif pTypeData.valueType == m.valueType.UPPER_IN_BOUND then
    length = pTypeData.maxlength
    if not length or length == 0 then length = ah.dataType.STRING.max end
  elseif pTypeData.valueType == m.valueType.LOWER_OUT_OF_BOUND then
    length = pTypeData.minlength
    if not length or length == 0 then length = ah.dataType.STRING.min end
    length = length - 1
  elseif pTypeData.valueType == m.valueType.UPPER_OUT_OF_BOUND then
    length = pTypeData.maxlength
    if not length or length == 0 then length = ah.dataType.STRING.max end
    length = length + 1
  elseif pTypeData.valueType == m.valueType.VALID_RANDOM then
    local min = pTypeData.minlength
    local max = pTypeData.maxlength
    if not min or min == 0 then min = ah.dataType.STRING.min end
    if not max or max == 0 then max = ah.dataType.STRING.max end
    length = math.random(min, max)
  elseif pTypeData.valueType == m.valueType.INVALID_TYPE then
    return false
  end
  return string.rep("a", length)
end

--[[ @getIntegerValue: Return value for 'integer' data type
--! @parameters:
--! pTypeData: table with data type restrictions
--! @return: value for the parameter
--]]
local function getIntegerValue(pTypeData)
  local value
  if pTypeData.valueType == m.valueType.LOWER_IN_BOUND then
    value = pTypeData.minvalue
    if not value then value = ah.dataType.INTEGER.min end
  elseif pTypeData.valueType == m.valueType.UPPER_IN_BOUND then
    value = pTypeData.maxvalue
    if not value then value = ah.dataType.INTEGER.max end
  elseif pTypeData.valueType == m.valueType.LOWER_OUT_OF_BOUND then
    value = pTypeData.minvalue
    if not value then value = ah.dataType.INTEGER.min end
    value = value - 1
  elseif pTypeData.valueType == m.valueType.UPPER_OUT_OF_BOUND then
    value = pTypeData.maxvalue
    if not value then value = ah.dataType.INTEGER.max end
    value = value + 1
  elseif pTypeData.valueType == m.valueType.VALID_RANDOM then
    local min = pTypeData.minvalue
    local max = pTypeData.maxvalue
    if not min then min = ah.dataType.INTEGER.min end
    if not max then max = ah.dataType.INTEGER.max end
    value = math.random(min, max)
  elseif pTypeData.valueType == m.valueType.INVALID_TYPE then
    return true
  end
  return value
end

--[[ @getFloatValue: Return value for 'float' data type
--! @parameters:
--! pTypeData: table with data type restrictions
--! @return: value for the parameter
--]]
local function getFloatValue(pTypeData)
  local value
  if pTypeData.valueType == m.valueType.LOWER_IN_BOUND then
    value = pTypeData.minvalue
    if not value then value = ah.dataType.FLOAT.min end
  elseif pTypeData.valueType == m.valueType.UPPER_IN_BOUND then
    value = pTypeData.maxvalue
    if not value then value = ah.dataType.FLOAT.max end
  elseif pTypeData.valueType == m.valueType.LOWER_OUT_OF_BOUND then
    value = pTypeData.minvalue
    if not value then value = ah.dataType.FLOAT.min end
    value = value - 0.1
  elseif pTypeData.valueType == m.valueType.UPPER_OUT_OF_BOUND then
    value = pTypeData.maxvalue
    if not value then value = ah.dataType.FLOAT.max end
    value = value + 0.1
  elseif pTypeData.valueType == m.valueType.VALID_RANDOM then
    local min = pTypeData.minvalue
    local max = pTypeData.maxvalue
    if not min then min = ah.dataType.FLOAT.min end
    if not max then max = ah.dataType.FLOAT.max end
    value = tonumber(string.format('%.02f', math.random() + math.random(min, max-1)))
  elseif pTypeData.valueType == m.valueType.INVALID_TYPE then
    return true
  end
  return value
end

--[[ @getDoubleValue: Return value for 'double' data type
--! @parameters:
--! pTypeData: table with data type restrictions
--! @return: value for the parameter
--]]
local function getDoubleValue(pTypeData)
  local value
  if pTypeData.valueType == m.valueType.LOWER_IN_BOUND then
    value = pTypeData.minvalue
    if not value then value = ah.dataType.DOUBLE.min end
  elseif pTypeData.valueType == m.valueType.UPPER_IN_BOUND then
    value = pTypeData.maxvalue
    if not value then value = ah.dataType.DOUBLE.max end
  elseif pTypeData.valueType == m.valueType.LOWER_OUT_OF_BOUND then
    value = pTypeData.minvalue
    if not value then value = ah.dataType.DOUBLE.min end
    value = value - 0.1
  elseif pTypeData.valueType == m.valueType.UPPER_OUT_OF_BOUND then
    value = pTypeData.maxvalue
    if not value then value = ah.dataType.DOUBLE.max end
    value = value + 0.1
  elseif pTypeData.valueType == m.valueType.VALID_RANDOM then
    local min = pTypeData.minvalue
    local max = pTypeData.maxvalue
    if not min then min = ah.dataType.DOUBLE.min end
    if not max then max = ah.dataType.DOUBLE.max end
    value = tonumber(string.format('%.02f', math.random() + math.random(min, max-1)))
  elseif pTypeData.valueType == m.valueType.INVALID_TYPE then
    return true
  end
  return value
end

--[[ @getBooleanValue: Return value for 'boolean' data type
--! @parameters:
--! pTypeData: table with data type restrictions
--! @return: value for the parameter
--]]
local function getBooleanValue(pTypeData)
  if pTypeData.data and #pTypeData.data == 1 then
    return pTypeData.data[1]
  end
  if pTypeData.valueType == m.valueType.VALID_RANDOM then
    return math.random(0, 1) == 1
  elseif pTypeData.valueType == m.valueType.INVALID_TYPE then
    return 123
  end
  return true
end

--[[ @getEnumTypeValue: Return value for 'enum' data type
--! @parameters:
--! pTypeData: table with data type restrictions
--! @return: value for the parameter
--]]
local function getEnumTypeValue(pTypeData)
  if pTypeData.valueType == m.valueType.UPPER_OUT_OF_BOUND then
    return #pTypeData.data + 1
  elseif pTypeData.valueType == m.valueType.VALID_RANDOM then
    return pTypeData.data[math.random(1, #pTypeData.data)]
  elseif pTypeData.valueType == m.valueType.INVALID_TYPE then
    return false
  end
  return pTypeData.data[1]
end

--[[ @getStructTypeValue: Return value for 'struct' data type
--! @parameters:
--! pGraph: graph with structure of parameters
--! pId: id of the parameter in graph
--! @return: value for the parameter
--]]
local function getStructTypeValue(_, pGraph, pId)
  local childrenIds = {}
  for k, v in pairs(pGraph) do
    if v.parentId == pId then table.insert(childrenIds, k) end
  end
  if #childrenIds == 0 then
    return {}
  else
    local out = {}
    for _, id in pairs(childrenIds) do
      m.buildParams(pGraph, id, out)
    end
    return out
  end
end

--[[ @getTypeValue: Return value for defined data type
--! Returned value depends on 'pTypeData.valueType' value
--! Could be any of 'm.valueType', default is VALID_RANDOM
--! @parameters:
--! pTypeData: table with data type restrictions
--! pGraph: graph with structure of parameters
--! pId: id of the parameter in graph
--! @return: value for the parameter
--]]
local function getTypeValue(pTypeData, pGraph, pId)
  if not pTypeData.valueType then pTypeData.valueType = m.valueType.VALID_RANDOM end
  local getValueFuncMap = {
    [ah.dataType.INTEGER.type] = getIntegerValue,
    [ah.dataType.FLOAT.type] = getFloatValue,
    [ah.dataType.DOUBLE.type] = getDoubleValue,
    [ah.dataType.STRING.type] = getStringValue,
    [ah.dataType.BOOLEAN.type] = getBooleanValue,
    [ah.dataType.ENUM.type] = getEnumTypeValue,
    [ah.dataType.STRUCT.type] = getStructTypeValue
  }
  return getValueFuncMap[pTypeData.type](pTypeData, pGraph, pId)
end

--[[ @getNumOfItems: Return number of items for the parameter
--! For the array number of items depends on 'pTypeData.valueTypeArray' value
--! Could be any of 'm.valueType', default is VALID_RANDOM
--! For non-array '-1' will be returned
--! @parameters:
--! pTypeData: table with data type restrictions
--! @return: number of items for the parameter
--]]
local function getNumOfItems(pTypeData)
  local arrayValueType = m.valueType.VALID_RANDOM
  if pTypeData.valueTypeArray then arrayValueType = pTypeData.valueTypeArray end
  local numOfItems = -1
  if pTypeData.array == true then
    if arrayValueType == m.valueType.LOWER_IN_BOUND then
      numOfItems = pTypeData.minsize
      if not numOfItems or numOfItems == 0 then numOfItems = 1 end
    elseif arrayValueType == m.valueType.UPPER_IN_BOUND then
      numOfItems = pTypeData.maxsize
      if not numOfItems or numOfItems == 0 then numOfItems = 100 end
    elseif arrayValueType == m.valueType.LOWER_OUT_OF_BOUND then
      numOfItems = pTypeData.minsize
      if not numOfItems or numOfItems == 0 then numOfItems = 1 end
      numOfItems = numOfItems - 1
    elseif arrayValueType == m.valueType.UPPER_OUT_OF_BOUND then
      numOfItems = pTypeData.maxsize
      if not numOfItems or numOfItems == 0 then numOfItems = 100 end
      numOfItems = numOfItems + 1
    elseif arrayValueType == m.valueType.VALID_RANDOM then
      local min = 1
      local max = 5
      if pTypeData.minsize ~= nil and pTypeData.minsize > min then min = pTypeData.minsize end
      if pTypeData.maxsize ~= nil and pTypeData.maxsize < max then max = pTypeData.maxsize end
      numOfItems = math.random(min, max)
    end
  end
  return numOfItems
end

--[[ @buildParams: Provide value for defined parameter and it's sub-parameters
--! @parameters:
--! pGraph: graph with structure of parameters
--! pId: id of the parameter in graph
--! pParams: table with result (used for recursion)
--! @return: table with parameter and it's value
--]]
function m.buildParams(pGraph, pId, pParams)
  local name = pGraph[pId].name
  local data = pGraph[pId]
  local numOfItems = getNumOfItems(data)
  if numOfItems == -1 then
    pParams[name] = getTypeValue(data, pGraph, pId)
  else
    pParams[name] = {}
    for i = 1, numOfItems do
      pParams[name][i] = getTypeValue(data, pGraph, pId)
    end
  end
  return pParams
end

--[[ @getParamValues: Provide values for parameter(s) and it's sub-parameters
--! @parameters:
--! pGraph: graph with structure of parameters
--! @return: table with parameters and it's values
--]]
function m.getParamValues(pGraph)
  local out = {}
  for id in pairs(pGraph) do
    if pGraph[id].parentId == nil then
      m.buildParams(pGraph, id, out)
    end
  end
  return out
end

return m
