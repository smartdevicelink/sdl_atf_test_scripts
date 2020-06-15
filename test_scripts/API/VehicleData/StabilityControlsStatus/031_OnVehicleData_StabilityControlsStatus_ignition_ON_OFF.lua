---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0253-New-vehicle-data-StabilityControlsStatus.md
--
-- Description: Check receiving StabilityControlsStatus data via OnVehicleData notification
-- after mobile application data resumption.
--
-- Precondition:
-- 1) SDL and HMI are started
-- 2) App is registered
-- 3) PTU is successfully performed
-- 4) App is activated
-- 5) App is subscribed on StabilityControlsStatus vehicle data
--
-- Steps:
-- 1) HMI sends VehicleInfo.OnVehicleData notification with StabilityControlsStatus
--    SDL sends OnVehicleData notification with received from HMI data to App
-- 2) Perform Ignition OFF/ON
-- 3) HMI sends VehicleInfo.OnVehicleData notification with StabilityControlsStatus
--    SDL sends OnVehicleData notification with received from HMI data to App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/commonVehicleData')

--[[ Test Configuration ]]
config.application1.registerAppInterfaceParams.syncMsgVersion.majorVersion = 6
config.application1.registerAppInterfaceParams.syncMsgVersion.minorVersion = 2

--[[ Local Functions ]]
local function reregisterApp()
  local mobSession = common.getMobileSession()
  local params = common.cloneTable(common.getConfigAppParams())
  params.hashID = common.hashId
  mobSession:StartService(7)
  :Do(function()
    local cid = common.getMobileSession():SendRPC("RegisterAppInterface", params)
    common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppRegistered")
    common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
    :Do(function()
      common.getMobileSession():ExpectNotification("OnPermissionsChange")
      :Times(AnyNumber())
      end)
    common.getHMIConnection():ExpectRequest("BasicCommunication.ActivateApp")
    :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS")
      end)
    common.getMobileSession():ExpectNotification("OnHMIStatus",
    { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" },
    { hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN" })
    :Times(2)
    end)
  common.wait(common.timeout)
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, init HMI, connect default mobile", common.start)
common.Step("Register App1", common.registerApp)
common.Step("PTU", common.policyTableUpdate, { common.ptUpdate })
common.Step("Activate App1", common.activateApp)
common.Step("Subscribe on StabilityControlsStatus VehicleData", common.processRPCSubscriptionSuccess,
  { "SubscribeVehicleData", { "stabilityControlsStatus" }})

common.Title("Test")
common.Step("Expect OnVehicleData with StabilityControlsStatus", common.checkNotificationSuccess,
  {{ "stabilityControlsStatus" }})
common.Step("Ignition OFF", common.ignitionOff)
common.Step("Ignition ON", common.start)
common.Step("Register App1", reregisterApp)
common.Step("Expect OnVehicleData with StabilityControlsStatus", common.checkNotificationSuccess,
  {{ "stabilityControlsStatus" }})

common.Title("Postconditions")
common.Step("Stop SDL, restore environment", common.postconditions)
