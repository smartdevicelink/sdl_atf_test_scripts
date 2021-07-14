---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0236-TireStatus-Mismatch.md
---------------------------------------------------------------------------------------------------
-- Description: Check that SDL applies default values for 'tirePressure' parameters within 'GetVehicleData' response
--  for old Apps (syncMsgVersion<=7.1) in case HMI responds without tirePressure parameters
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) GetVehicleData RPC and 'tirePressure' parameter are allowed by policies
-- 3) App is registered with syncMsgVersion=7.1
--
-- In case:
-- 1) App sends 'GetVehicleData' request with tirePressure=true to SDL
-- SDL does:
-- - a) transfer this request to HMI
-- 2) HMI sends VI.GetVehicleData response with <tirePressure> data to SDL
--   without <sub_vd_param> sub-parameter
-- SDL does:
-- - a) send GetVehicleData response with <tirePressure> data received from HMI and with default value
--     for missing <sub_vd_param> sub-parameter (success = true, resultCode = "SUCCESS",
--       <tirePressure> = <<data received from HMI, <sub_vd_param> = <default data>>) to App
-- 3) App sends 'GetVehicleData' request with tirePressure=true to SDL
-- SDL does:
-- - a) transfer this request to HMI
-- 4) HMI sends VI.GetVehicleData response with empty <tirePressure> array to SDL
-- SDL does:
-- - a) send GetVehicleData response with <tirePressure> data with default value
--     for all missing <sub_vd_param> sub-parameters (success = true, resultCode = "SUCCESS",
--       <tirePressure> = <default data>) to App
-- 5) App sends 'GetVehicleData' request with tirePressure=true to SDL
-- SDL does:
-- - a) transfer this request to HMI
-- 6) HMI sends VI.GetVehicleData response with <tirePressure> data and to SDL
--   with all <sub_vd_param> sub-parameters
-- SDL does:
-- - a) send GetVehicleData response with <tirePressure> data received from HMI (success = true, resultCode = "SUCCESS",
--     <tirePressure> = <data received from HMI>) to App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/TireStatusMismatch/common')

--[[ Test Configuration ]]
config.application1.registerAppInterfaceParams.syncMsgVersion.majorVersion = 7
config.application1.registerAppInterfaceParams.syncMsgVersion.minorVersion = 1

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("PolicyTableUpdate", common.policyTableUpdate, { common.ptUpdate })
common.Step("Activate App", common.activateApp)

common.Title("Test")
for _, p in common.spairs(common.tirePressureParams) do
  local hmiValue = common.getTirePressureNonDefaultValue()
  hmiValue[p] = nil
  local appValue = common.getTirePressureNonDefaultValue()
  appValue[p] = common.getDefaultValue(p)
  common.Step("Send GetVehicleData param " .. p .. " missing", common.sendGetVehicleData, { hmiValue, appValue })
end
common.Step("Send GetVehicleData all params missing", common.sendGetVehicleData,
  { {}, common.getTirePressureDefaultValue() })
common.Step("Send GetVehicleData all params present", common.sendGetVehicleData,
  { common.getTirePressureNonDefaultValue(), common.getTirePressureNonDefaultValue() })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
