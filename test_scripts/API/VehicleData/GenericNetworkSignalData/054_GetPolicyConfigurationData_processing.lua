---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0173-Read-Generic-Network-Signal-data.md
--
-- Description: GetPolicyConfigurationData successful processing

-- Precondition:
-- 1. Preloaded file contains VehicleDataItems for all RPC spec VD
-- 2. App is registered

-- Sequence:
-- 1. HMI requests valid SDL.GetPolicyConfigurationData
--  a. SDL responds to SDL.GetPolicyConfigurationData with appropriate data
-- 2. HMI requests valid SDL.GetPolicyConfigurationData with undefined value in policyType or property
--  a. SDL responds to SDL.GetPolicyConfigurationData with resultCode DATA_NOT_AVAILABLE
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/VehicleData/GenericNetworkSignalData/commonGenericNetSignalData')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local preloadedTable = common.getPreloadedFileAndContent()

local dataReqRes = {
  jsonInResponse = {
    request = { policyType = "module_config", property = "endpoints" },
    response = { result = { code = 0 } },
    validIf = function(data)
      return common.validation(common.decode(data.result.value[1]), preloadedTable.policy_table.module_config.endpoints,
        "endpoints from GetPolicyConfigurationData response ")
    end
  },
  arrayInResponse = {
    request = { policyType = "module_config", property = "seconds_between_retries" },
    response = { result = { code = 0 } },
    validIf = function(data)
      local expectedData = {}
      for _, item in ipairs(preloadedTable.policy_table.module_config.seconds_between_retries) do
        table.insert(expectedData, tostring(item))
      end
      return common.validation(data.result.value, expectedData,
        "seconds_between_retries from GetPolicyConfigurationData response ")
    end
},
  undefinedPolicyType =  {
    request = { policyType = "undefinedKey", property = "endpoints" },
    response = { error = { code = 9 } }
  },
  undefinedProperty =  {
    request = { policyType = "module_config", property = "undefinedKey" },
    response = { error = { code = 9 } }
  }
}

--[[ Local Functions ]]
local function GetPolicyConfigurationData(pData)
  local requestId = common.getHMIConnection():SendRequest("SDL.GetPolicyConfigurationData",pData.request)
  common.getHMIConnection():ExpectResponse(requestId, pData.response)
  :ValidIf(function(_, data)
    if pData.validIf then
      return pData.validIf(data)
    end
    return true
    end)
end

-- [[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerApp)
runner.Step("App activation", common.activateApp)

runner.Title("Test")
for caseName, testData in pairs(dataReqRes) do
  runner.Step("GetPolicyConfigurationData " .. caseName, GetPolicyConfigurationData, { testData })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
