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
local commonSmoke = require('test_scripts/Smoke/commonSmoke')

--[[ Local Variables ]]
local preloadedPT = commonSmoke:read_parameter_from_smart_device_link_ini("PreloadedPT")
local preloadedFile = commonSmoke:GetPathToSDL() .. preloadedPT
local pt = commonSmoke.jsonFileToTable(preloadedFile)

--[[ Local Functions ]]
local function GetPolicyConfigurationData(self)
  local requestId = self.hmiConnection:SendRequest("SDL.GetPolicyConfigurationData",
    { policyType = "module_config", property = "endpoints" })
  EXPECT_HMIRESPONSE(requestId, { result = { code = 0 } })
  :ValidIf(function(_, data)
      if true ~= commonSmoke:is_table_equal(commonSmoke.decode(data.result.value[1]),
        pt.policy_table.module_config.endpoints) then
        return false, "GetPolicyConfigurationData contains unexpected parameters.\n" ..
        "Expected table: " .. commonSmoke.tableToString(pt.policy_table.module_config.endpoints) .. "\n" ..
        "Actual table: " .. commonSmoke.tableToString(commonSmoke.decode(data.result.value[1])) .. "\n"
      end
      return true
    end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonSmoke.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonSmoke.start)

runner.Title("Test")
runner.Step("GetPolicyConfigurationData from HMI", GetPolicyConfigurationData)

runner.Title("Postconditions")
runner.Step("Stop SDL", commonSmoke.postconditions)
