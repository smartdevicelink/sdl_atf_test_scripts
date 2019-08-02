---------------------------------------------------------------------------------------------------
-- Proposal:
--  https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0173-Read-Generic-Network-Signal-data.md
--
-- Description: GetPolicyConfigurationData processing with all correct parameters

-- Precondition:
-- 1. SDL and HMI started

-- Sequence:
-- 1. HMI requests valid SDL.GetPolicyConfigurationData
--  a. SDL responds to SDL.GetPolicyConfigurationData with appropriate data
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('/test_scripts/API/GetPolicyConfigurationData/commonGetPolicyConfigurationData')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local CHECK_TYPES = { PRIMITIVE = 1, OBJECT = 2, ARRAY_OF_PRIMITIVES = 3, ARRAY_OF_OBJECTS = 4 }

local function validation(pActualData, pPolicyType, pProperty, pCheckType)
  local msg = tostring(pPolicyType) .. "." .. tostring(pProperty) .. " from GetPolicyConfigurationData response"
  local policyTable = common.getPreloadedTable()
  local expectedData = policyTable.policy_table[pPolicyType][pProperty]
  local actualData = pActualData.result.value

  if pCheckType == CHECK_TYPES.PRIMITIVE then
    expectedData = { tostring(expectedData) }
  elseif pCheckType == CHECK_TYPES.OBJECT then
    actualData = common.decode(actualData[1])
  elseif pCheckType == CHECK_TYPES.ARRAY_OF_PRIMITIVES then
    local array = {}
    for _, item in pairs(expectedData) do
      table.insert(array, tostring(item))
    end
    expectedData = array
  elseif pCheckType == CHECK_TYPES.ARRAY_OF_OBJECTS then
    local array = {}
    for _, jsonStr in pairs(actualData) do
      local jsonTbl = common.decode(jsonStr)
      table.insert(array, jsonTbl)
    end
    actualData = array
  end

  if true ~= common:is_table_equal(actualData, expectedData) then
      return false, msg .. " contains unexpected parameters.\n" ..
      "Expected table: " .. common.tableToString(expectedData) .. "\n" ..
      "Actual table: " .. common.tableToString(actualData) .. "\n"
  end
  return true
end

local dataReqRes = {
  number = {
    request = { policyType = "module_config", property = "timeout_after_x_seconds" },
    response = { result = { code = 0 } },
    validIf = function(data)
      return validation(data, "module_config", "timeout_after_x_seconds", CHECK_TYPES.PRIMITIVE)
    end
  },
  string = {
    request = { policyType = "consumer_friendly_messages", property = "version" },
    response = { result = { code = 0 } },
    validIf = function(data)
    return validation(data, "consumer_friendly_messages", "version", CHECK_TYPES.PRIMITIVE)
    end
  },
  boolean = {
    request = { policyType = "module_config", property = "lock_screen_dismissal_enabled" },
    response = { result = { code = 0 } },
    validIf = function(data)
    return validation(data, "module_config", "lock_screen_dismissal_enabled", CHECK_TYPES.PRIMITIVE)
    end
  },
  object = {
    request = { policyType = "module_config", property = "endpoints" },
    response = { result = { code = 0 } },
    validIf = function(data)
    return validation(data, "module_config", "endpoints", CHECK_TYPES.OBJECT)
    end
  },
  hugeJson = {
    request = { policyType = "consumer_friendly_messages", property = "messages" },
    response = { result = { code = 0 } },
    validIf = function(data)
    return validation(data, "consumer_friendly_messages", "messages", CHECK_TYPES.OBJECT)
    end
  },
  arrayOfNumbers = {
    request = { policyType = "module_config", property = "seconds_between_retries" },
    response = { result = { code = 0 } },
    validIf = function(data)
      return validation(data, "module_config", "seconds_between_retries", CHECK_TYPES.ARRAY_OF_PRIMITIVES)
    end
  },
  arrayOfObjects = {
    request = { policyType = "vehicle_data", property = "schema_items" },
    response = { result = { code = 0 } },
    validIf = function(data)
      return validation(data, "vehicle_data", "schema_items", CHECK_TYPES.ARRAY_OF_OBJECTS)
    end
  }
}


-- [[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)

runner.Title("Test")
for caseName, testData in pairs(dataReqRes) do
  runner.Step("GetPolicyConfigurationData " .. caseName, common.GetPolicyConfigurationData, { testData })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
