---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0257-New-vehicle-data-HandsOffSteering.md
--
-- Description: Processing of SubscribeVehicleData RPC with unsuccessful resultCode for handsOffSteering data
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) RPC SubscribeVehicleData and handsOffSteering parameter are allowed by policies
-- 3) App is registered
--
-- In case:
-- 1) App sends valid SubscribeVehicleData(handsOffSteering=true) request to SDL
-- SDL does:
-- - a) transfer this request to HMI.
-- 2) HMI responds with "SUCCESS" result to SubscribeVehicleData request
--  and with not success result for handsOffSteering vehicle data
-- SDL does:
-- - a) respond "SUCCESS", success:true and with unsuccessful resultCode for handsOffSteering data to the mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/HandsOffSteering/common')

--[[ Local Variables ]]
local resultCodes = {
  "TRUNCATED_DATA",
  "DISALLOWED",
  "USER_DISALLOWED",
  "INVALID_ID",
  "VEHICLE_DATA_NOT_AVAILABLE",
  "DATA_NOT_SUBSCRIBED",
  "IGNORED",
  "DATA_ALREADY_SUBSCRIBED"
}

--[[ Local Variables ]]
local function subscribeToVDwithUnsuccessCodeForVD(pCode)
  local handsOffSteeringData = { dataType = "VEHICLEDATA_HANDSOFFSTEERING", resultCode = pCode}
  local cid = common.getMobileSession():SendRPC("SubscribeVehicleData", { handsOffSteering = true })
  common.getHMIConnection():ExpectRequest("VehicleInfo.SubscribeVehicleData", { handsOffSteering = true })
  :Do(function(_,data)
    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS",
      { handsOffSteering = handsOffSteeringData })
  end)
  common.getMobileSession():ExpectResponse(cid,
    { success = true, resultCode = "SUCCESS", handsOffSteering = handsOffSteeringData })
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment and update preloaded_pt file", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)

common.Title("Test")
for _, code in common.spairs(resultCodes) do
  common.Step("SubscribeVehicleData with handsOffSteering resultCode =" .. code,
    subscribeToVDwithUnsuccessCodeForVD, { code })
end

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
