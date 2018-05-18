---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/7
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/Policy_Support_of_basic_RC_functionality.md
-- Item: Use Case 1: Main Flow
--
-- Requirement summary:
-- [SDL_RC] Set available control module settings SetInteriorVehicleData
-- [SDL_RC] Policy support of basic RC functionality
--
-- Description:
-- In case:
-- 1) "moduleType" in app's assigned policies has an empty array
-- 2) and RC app sends SetInteriorVehicleData request with valid parameters
-- SDL must:
-- 1) Allow this RPC to be processed
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local json = require('modules/json')
local common = require('test_scripts/RC/AUDIO_LIGHT_HMI_SETTINGS/commonRCmodules')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
--modules array does not contain "RADIO" because "RADIO" module has read only parameters
local modules = { "CLIMATE", "AUDIO", "LIGHT", "HMI_SETTINGS" }

--[[ Local Functions ]]
local function setVehicleData(pModuleType)
  local cid = common.getMobileSession():SendRPC("SetInteriorVehicleData", {
      moduleData = common.getSettableModuleControlData(pModuleType)
    })

  EXPECT_HMICALL("RC.SetInteriorVehicleData", {
      appID = common.getHMIAppId(),
      moduleData = common.getSettableModuleControlData(pModuleType)
    })
  :Do(function(_, data)
      common.getHMIconnection():SendResponse(data.id, data.method, "SUCCESS", {
          moduleData = common.getSettableModuleControlData(pModuleType)
        })
    end)

  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

local function PTUfunc(tbl)
  tbl.policy_table.app_policies[config.application1.registerAppInterfaceParams.appID] = common.getRCAppConfig()
  tbl.policy_table.app_policies[config.application1.registerAppInterfaceParams.appID].moduleType = json.EMPTY_ARRAY
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI, PTU", common.raiPTUn, { PTUfunc })
runner.Step("Activate App", common.activateApp)

runner.Title("Test")

for _, mod in pairs(modules) do
  runner.Step("SetInteriorVehicleData " .. mod, setVehicleData, { mod })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
