---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/4
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/subscription_on_module_status_change_notification.md
-- Item: Use Case 1: Main Flow
--
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/5
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/unsubscribe_from_module_status_change_notification.md
-- Item: Use Case 1: Main Flow
--
-- Requirement summary:
-- [SDL_RC] Subscribe on RC module change notification
--
-- Description: TRS: GetInteriorVehicleData, #4
-- In case:
-- 1) RC app sends valid and allowed-by-policies GetInteriorVehicleData request with "subscribe:true" parameter
-- 2) and SDL received GetInteriorVehicleData response with "isSubscribed: true", "resultCode: SUCCESS" from HMI
-- 3) and then SDL received OnInteriorVehicleData notification
-- SDL must:
-- 1) Internally subscribe this application for requested <moduleType_value>
-- 2) Transfer GetInteriorVehicleData response with "isSubscribed: true", "resultCode: SUCCESS", "success:true" to the related app
-- 3) Re-send OnInteriorVehicleData notification to the related app
--
-- [SDL_RC] Unsubscribe from RC module change notifications
--
-- Description: TRS: GetInteriorVehicleData, #8
-- In case:
-- 1) RC app is subscribed to "<moduleType_value>"
-- 2) RC app sends valid and allowed-by-policies GetInteriorVehicleData request with "subscribe:false" parameter
-- 3) and SDL received GetInteriorVehicleData response with "isSubscribed: false", "resultCode: SUCCESS" from HMI
-- 4) and then SDL received OnInteriorVehicleData notification
-- SDL must:
-- 1) Internally un-subscribe this application for requested <moduleType_value>
-- 2) Transfer GetInteriorVehicleData response with "isSubscribed: false", "resultCode: SUCCESS", "success:true" to the related app
-- 3) Does not re-send OnInteriorVehicleData notification to the related app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("test_scripts/RC/commonRC")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local Module =  "LIGHT"

--[[ Local Functions ]]
local function isSubscribed(pStatus)
  local mobSession = common.getMobileSession()
  local rpc = "OnInteriorVehicleData"

  local notificationHMIParams = common.getHMIResponseParams(rpc, Module)
  notificationHMIParams.moduleData.lightControlData.lightState[1].status = pStatus

  local notificationParams = common.getAppResponseParams(rpc, Module)
  notificationParams.moduleData.lightControlData.lightState[1].status = pStatus

  common.getHMIConnection():SendNotification(common.getHMIEventName(rpc), notificationHMIParams)
  mobSession:ExpectNotification(common.getAppEventName(rpc), notificationParams)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI, PTU", common.registerAppWOPTU)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")

runner.Step("Subscribe app to " .. Module, common.subscribeToModule, { Module })
for _, status in pairs(common.readOnlyLightStatus) do
  runner.Step("Send notification OnInteriorVehicleData Light status " .. status, isSubscribed, { status })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
