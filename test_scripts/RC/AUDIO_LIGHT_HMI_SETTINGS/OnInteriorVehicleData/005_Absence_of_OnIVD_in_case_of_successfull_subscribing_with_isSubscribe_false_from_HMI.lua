---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/4
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/subscription_on_module_status_change_notification.md
-- Use Case 1: Alternative flow 1
--
-- Requirement summary:
-- [SDL_RC] Subscribe on RC module change notification
--
-- Description: TRS: GetInteriorVehicleData, #5
-- In case:
-- 1) RC app sends valid and allowed-by-policies GetInteriorVehicleData request with "subscribe:true" parameter
-- 2) and SDL received GetInteriorVehicleData response with "isSubscribed: false", "resultCode: SUCCESS" from HMI
-- 3) and then SDL received OnInteriorVehicleData notification
-- SDL must:
-- 1) Transfer GetInteriorVehicleData response with "isSubscribed: false", "resultCode: SUCCESS", "success:true" to the related app
-- 2) Does not re-send OnInteriorVehicleData notification to the app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/RC/AUDIO_LIGHT_HMI_SETTINGS/commonRCmodules')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local modules = { "AUDIO", "LIGHT", "HMI_SETTINGS" }

--[[ Local Functions ]]
local function subscriptionToModule(pModuleType)
  local mobileSession = common.getMobileSession()
  local cid = mobileSession:SendRPC("GetInteriorVehicleData", {
      moduleType = pModuleType,
      subscribe = true
    })

  EXPECT_HMICALL("RC.GetInteriorVehicleData", {
      appID = common.getHMIAppId(),
      moduleType = pModuleType,
      subscribe = true
    })
  :Do(function(_, data)
      common.getHMIconnection():SendResponse(data.id, data.method, "SUCCESS", {
          moduleData = common.getModuleControlData(pModuleType),
          isSubscribed = false -- not subscribe
        })
    end)

  mobileSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS",
      moduleData = common.getModuleControlData(pModuleType),
      isSubscribed = false
    })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI, PTU", common.rai_ptu_n)
runner.Step("Activate App", common.activate_app)

runner.Title("Test")

for _, mod in pairs(modules) do
  runner.Step("Subscribe app to " .. mod, subscriptionToModule, { mod })
  runner.Step("Send notification OnInteriorVehicleData " .. mod .. ". App is not subscribed", common.isUnsubscribed,
    { mod })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
