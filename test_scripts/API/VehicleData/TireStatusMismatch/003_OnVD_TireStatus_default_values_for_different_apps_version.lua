---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0236-TireStatus-Mismatch.md
---------------------------------------------------------------------------------------------------
-- Description: Check that SDL processes OnVehicleData notification with 'tirePressure' parameter
--  for different Apps versions (syncMsgVersion=7.1 and syncMsgVersion=8.0)
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) SubscribeVehicleData, OnVehicleData RPCs and tirePressure' parameter are allowed by policies
-- 3) App_1 is registered with syncMsgVersion=7.1
-- 4) App_2 is registered with syncMsgVersion=8.0
-- 5) Apps are subscribed to receive updates on 'tirePressure' vehicle data
--
-- In case:
-- 1. HMI sends 'OnVehicleData' notification with 'tirePressure' data to SDL
--   without <sub_vd_param> sub-parameter
-- SDL does:
--  - a) transfer 'OnVehicleData' notification with <tirePressure> data received from HMI to App_1
--      with default value for missing <sub_vd_param> sub-parameter
--  - b) transfer 'OnVehicleData' notification with <tirePressure> data received from HMI to App_2
-- 2. HMI sends 'OnVehicleData' notification with empty <tirePressure> array to SDL
-- SDL does:
--  - a) transfer 'OnVehicleData' notification with default value to App
--      for all missing <sub_vd_param> sub-parameter
--  - b) transfer 'OnVehicleData' notification with <tirePressure> data received from HMI to App_2
-- 3. HMI sends 'OnVehicleData' notification with 'tirePressure' data to SDL
--   with all <sub_vd_param> sub-parameters
-- SDL does:
--  - a) transfer 'OnVehicleData' notification with <tirePressure> data received from HMI to both Apps
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/TireStatusMismatch/common')

--[[ Test Configuration ]]
config.application1.registerAppInterfaceParams.syncMsgVersion.majorVersion = 7
config.application1.registerAppInterfaceParams.syncMsgVersion.minorVersion = 1
config.application2.registerAppInterfaceParams.syncMsgVersion.majorVersion = 8
config.application2.registerAppInterfaceParams.syncMsgVersion.minorVersion = 0

--[[ Local Variables ]]
local isExpectedSubscription = true
local isNotExpectedSubscription = false
local appSessionId1 = 1
local appSessionId2 = 2
local tirePressureNonDefaultValue = common.getTirePressureNonDefaultValue()

--[[ Local Functions ]]
local function validation(actualData, expectedData, pMessage)
  if actualData == nil then return false, "Actual table: nil" end
  if true ~= common.isTableEqual(actualData, expectedData) then
      return false, pMessage .. " contains unexpected parameters.\n" ..
      "Expected table: " .. common.tableToString(expectedData) .. "\n" ..
      "Actual table: " .. common.tableToString(actualData) .. "\n"
  end
  return true
end

local function sendOnVehicleDataTwoApps(pHmiNotification, pAppNotification1, pAppNotification2)
  common.getHMIConnection():SendNotification("VehicleInfo.OnVehicleData", { tirePressure = pHmiNotification })
  common.getMobileSession(appSessionId1):ExpectNotification("OnVehicleData")
  :ValidIf(function(_,data)
    return validation(data.payload, { tirePressure = pAppNotification1 }, "OnVehicleData notification for App_1")
  end)
  common.getMobileSession(appSessionId2):ExpectNotification("OnVehicleData")
  :ValidIf(function(_,data)
    return validation(data.payload, { tirePressure = pAppNotification2 }, "OnVehicleData notification for App_2")
  end)
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App_1", common.registerAppWOPTU, { appSessionId1 })
common.Step("Register App_2", common.registerApp, { appSessionId2 })
common.Step("PolicyTableUpdate", common.policyTableUpdate, { common.ptUpdate })
common.Step("Activate App_1", common.activateApp, { appSessionId1 })
common.Step("Subscribe VehicleData tirePressure for App_1", common.subscribeVehicleData,
  { appSessionId1, isExpectedSubscription })
common.Step("Activate App_2", common.activateApp, { appSessionId2 })
common.Step("Subscribe VehicleData tirePressure for App_2", common.subscribeVehicleData,
  { appSessionId2, isNotExpectedSubscription })

common.Title("Test")
for _, p in common.spairs(common.tirePressureParams) do
  local hmiValue = common.getTirePressureNonDefaultValue()
  hmiValue[p] = nil
  local appValue = common.getTirePressureNonDefaultValue()
  appValue[p] = common.getDefaultValue(p)
  common.Step("Send OnVehicleData param " .. p .. " missing", sendOnVehicleDataTwoApps,
    { hmiValue, appValue, hmiValue })
end
common.Step("Send OnVehicleData all params missing", sendOnVehicleDataTwoApps ,
  { {}, common.getTirePressureDefaultValue(), {} })
common.Step("Send OnVehicleData all params present", sendOnVehicleDataTwoApps,
  { tirePressureNonDefaultValue, tirePressureNonDefaultValue, tirePressureNonDefaultValue })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
