---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/2
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/current_module_status_data.md
-- Item: Use Case 1: Main Flow
--
-- Requirement summary:
-- [SDL_RC] Current module status data GetInteriorVehicleData
--
-- Description:
-- In case:
-- 1) RC app sends GetInteriorVehicleData request with valid parameters
-- 2) and SDL gets response (resultCode: READ_ONLY) from HMI
-- SDL must:
-- 1) Respond to App with success:false, "GENERIC_ERROR"
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/RC/AUDIO_LIGHT_HMI_SETTINGS/commonRCmodules')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local modules = { "AUDIO", "LIGHT", "HMI_SETTINGS" }

--[[ Local Functions ]]
local function getDataForModule(module_type)
  local mobileSession = common.getMobileSession()
  local cid = mobileSession:SendRPC("GetInteriorVehicleData", {
      moduleType = module_type,
      subscribe = true
    })

  EXPECT_HMICALL("RC.GetInteriorVehicleData", {
      appID = common.getHMIAppId(),
      moduleType = module_type,
      subscribe = true
    })
  :Do(function(_, data)
      common.getHMIconnection():SendError(data.id, data.method, "READ_ONLY", "Info message")
    end)

  mobileSession:ExpectResponse(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Info message" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI, PTU", common.rai_ptu_n)
runner.Step("Activate App", common.activate_app)

runner.Title("Test")

for _, mod in pairs(modules) do
  runner.Step("GetInteriorVehicleData " .. mod, getDataForModule, { mod })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
