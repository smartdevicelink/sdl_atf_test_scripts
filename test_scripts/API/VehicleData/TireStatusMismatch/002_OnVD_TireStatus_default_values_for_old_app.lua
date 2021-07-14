---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0236-TireStatus-Mismatch.md
---------------------------------------------------------------------------------------------------
-- Description: Check that SDL applies default values for 'tirePressure' parameters within 'OnVehicleData' notification
--  for old Apps (syncMsgVersion<=7.1) in case HMI sends 'OnVehicleData' notification without tirePressure parameters
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) SubscribeVehicleData, OnVehicleData RPCs and tirePressure' parameter are allowed by policies
-- 3) App is registered with syncMsgVersion=7.1
-- 4) App is subscribed to receive updates on 'tirePressure' vehicle data
--
-- In case:
-- 1. HMI sends 'OnVehicleData' notification with 'tirePressure' data to SDL
--   without <sub_vd_param> sub-parameter
-- SDL does:
--  - a) transfer 'OnVehicleData' notification with <tirePressure> data received from HMI to App
--      with default value for missing <sub_vd_param> sub-parameter
-- 2. HMI sends 'OnVehicleData' notification with empty <tirePressure> array to SDL
-- SDL does:
--  - a) transfer 'OnVehicleData' notification with default value to App
--      for all missing <sub_vd_param> sub-parameter
-- 3. HMI sends 'OnVehicleData' notification with 'tirePressure' data to SDL
--   with all <sub_vd_param> sub-parameters
-- SDL does:
--  - a) transfer 'OnVehicleData' notification with <tirePressure> data received from HMI to App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/TireStatusMismatch/common')

--[[ Test Configuration ]]
config.application1.registerAppInterfaceParams.syncMsgVersion.majorVersion = 7
config.application1.registerAppInterfaceParams.syncMsgVersion.minorVersion = 1

--[[ Local Functions ]]
local function sendOnVehicleData(pHmiNotification, pAppNotification)
  common.getHMIConnection():SendNotification("VehicleInfo.OnVehicleData", { tirePressure = pHmiNotification })
  common.getMobileSession():ExpectNotification("OnVehicleData", { tirePressure = pAppNotification })
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("PolicyTableUpdate", common.policyTableUpdate, { common.ptUpdate })
common.Step("Activate App", common.activateApp)
common.Step("Subscribe VehicleData tirePressure", common.subscribeVehicleData)

common.Title("Test")
for _, p in common.spairs(common.tirePressureParams) do
  local hmiValue = common.getTirePressureNonDefaultValue()
  hmiValue[p] = nil
  local appValue = common.getTirePressureNonDefaultValue()
  appValue[p] = common.getDefaultValue(p)
  common.Step("Send OnVehicleData param " .. p .. " missing", sendOnVehicleData, { hmiValue, appValue })
end
common.Step("Send OnVehicleData all params missing", sendOnVehicleData,
  { {}, common.getTirePressureDefaultValue() })
common.Step("Send OnVehicleData all params present", sendOnVehicleData,
  { common.getTirePressureNonDefaultValue(), common.getTirePressureNonDefaultValue() })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
