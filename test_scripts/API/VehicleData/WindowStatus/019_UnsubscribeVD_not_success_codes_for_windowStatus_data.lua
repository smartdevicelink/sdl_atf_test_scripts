---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0261-New-vehicle-data-WindowStatus.md
--
-- Description: Processing of UnsubscribeVehicleData with unsuccessful resultCode for windowStatus data
--
-- Preconditions:
-- 1) App is subscribed to windowStatus data
--
-- In case:
-- 1) App sends UnsubscribeVehicleData request with windowStatus=true to the SDL and this request is allowed by Policies.
-- SDL does:
--  a) transfer this request to HMI.
-- 2) HMI responds with `SUCCESS` result to UnsubscribeVehicleData request
--  and with not success result for `windowStatus` vehicle data
-- SDL does:
--  a) respond `SUCCESS`, success:true and with unsuccessful resultCode for windowStatus data to the mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/WindowStatus/common')

--[[ Local Variables ]]
local rpcSubVD = "SubscribeVehicleData"
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
local function scribeVDwithUnsuccessCodeForVD(pCode)
  local windowStatusData = { dataType = "VEHICLEDATA_WINDOWSTATUS", resultCode = pCode}
  local cid = common.getMobileSession():SendRPC("UnsubscribeVehicleData", { windowStatus = true })
  common.getHMIConnection():ExpectRequest("VehicleInfo.UnsubscribeVehicleData", { windowStatus = true })
  :Do(function(_,data)
    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS",
      { windowStatus = windowStatusData })
  end)
  common.getMobileSession():ExpectResponse(cid,
    { success = true, resultCode = "SUCCESS", windowStatus = windowStatusData })
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("Activate App", common.activateApp)
common.Step("App subscribes to windowStatus data", common.subUnScribeVD, { rpcSubVD })

common.Title("Test")
for _, code in common.spairs(resultCodes) do
  common.Step("UnsubscribeVehicleData with windowStatus resultCode =" .. code, scribeVDwithUnsuccessCodeForVD, { code })
end

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
