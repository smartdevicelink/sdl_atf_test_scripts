---------------------------------------------------------------------------------------------------
-- Proposal:
--  https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0173-Read-Generic-Network-Signal-data.md
--
-- Description: GetPolicyConfigurationData processing with incorrect parameters

-- Precondition:
-- 1. SDL and HMI started

-- Sequence:
-- 1. HMI requests valid SDL.GetPolicyConfigurationData with undefined value in policyType or property
--  a. SDL responds to SDL.GetPolicyConfigurationData with resultCode DATA_NOT_AVAILABLE
-- 2. HMI requests invalid SDL.GetPolicyConfigurationData with incorrect value in policyType or property
--  a. SDL responds to SDL.GetPolicyConfigurationData with resultCode INVALID_DATA
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('/test_scripts/API/GetPolicyConfigurationData/commonGetPolicyConfigurationData')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local dataReqRes = {
  undefinedPolicyType =  {
    request = { policyType = "undefinedKey", property = "endpoints" },
    response = { error = { code = 9 } } -- DATA_NOT_AVAILABLE
  },
  undefinedProperty =  {
    request = { policyType = "module_config", property = "undefinedKey" },
    response = { error = { code = 9 } } -- DATA_NOT_AVAILABLE
  },
  incorrectTypePolicyType =  {
    request = { policyType = true, property = "endpoints" },
    response = { error = { code = 11 } } -- INVALID_DATA
  },
  incorrectTypeProperty =  {
    request = { policyType = "module_config", property = 5 },
    response = { error = { code = 11 } } -- INVALID_DATA
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
