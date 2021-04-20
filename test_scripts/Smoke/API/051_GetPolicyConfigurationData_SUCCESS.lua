---------------------------------------------------------------------------------------------------
-- User story: Smoke
-- Use case: GetPolicyConfigurationData
-- Item: Happy path
--
-- Requirement summary:
-- [GetPolicyConfigurationData] SUCCESS: getting SUCCESS:SDL.GetPolicyConfigurationData()
--
-- Description:
-- Processing GetPolicyConfigurationData request from HMI

-- Pre-conditions:
-- a. HMI and SDL are started

-- Steps:
-- HMI requests GetPolicyConfigurationData with valid parameters

-- Expected:
-- SDL responds with value for requested parameter
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Smoke/commonSmoke')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function GetPolicyConfigurationData()
  local hmi = common.getHMIConnection()
  local requestId = hmi:SendRequest("SDL.GetPolicyConfigurationData",
    { policyType = "module_config", property = "endpoints" })
  hmi:ExpectResponse(requestId, { result = { code = 0 } })
  :ValidIf(function(_, data)
      local expectedEndpoints = common.sdl.getPreloadedPT().policy_table.module_config.endpoints
      local actualEndpoints = common.json.decode(data.result.value[1])
      if true ~= common.isTableEqual(actualEndpoints, expectedEndpoints) then
        return false, "GetPolicyConfigurationData contains unexpected parameters.\n" ..
          "Expected table: " .. common.tableToString(expectedEndpoints) .. "\n" ..
          "Actual table: " .. common.tableToString(actualEndpoints) .. "\n"
      end
      return true
    end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Update Preloaded PT", common.updatePreloadedPT)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)

runner.Title("Test")
runner.Step("GetPolicyConfigurationData from HMI", GetPolicyConfigurationData)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
