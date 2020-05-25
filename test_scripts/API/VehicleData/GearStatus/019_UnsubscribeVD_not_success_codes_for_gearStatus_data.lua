---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0266-New-vehicle-data-GearStatus.md
--
-- Description: Processing of UnsubscribeVehicleData with unsuccessful resultCode for gearStatus data
--
-- Preconditions:
-- 1) App is subscribed to `gearStatus` data.
-- In case:
-- 1) App sends UnsubscribeVehicleData request with gearStatus=true to the SDL and this request is allowed by Policies.
-- SDL does:
--  a) transfer this request to HMI.
-- 2) HMI responds with `SUCCESS` result to UnsubscribeVehicleData request
--  and with not success result for `gearStatus` vehicle data
-- SDL does:
--  a) respond `SUCCESS`, success:true and with unsuccessful resultCode for gearStatus data to the mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/GearStatus/common')

--[[ Local Variables ]]
local rpc = "SubscribeVehicleData"
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

--[[ Local functions ]]
local function unsubscribeVDwithUnsuccessCodeForVD(pCode)
  local gearStatusData = common.getGearStatusSubscriptionResData()
  gearStatusData.resultCode = pCode
  local cid = common.getMobileSession():SendRPC("UnsubscribeVehicleData", { gearStatus = true })
  common.getHMIConnection():ExpectRequest("VehicleInfo.UnsubscribeVehicleData", { gearStatus = true })
  :Do(function(_,data)
    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { gearStatus = gearStatusData })
  end)
  common.getMobileSession():ExpectResponse(cid,
    { success = true, resultCode = "SUCCESS", gearStatus = gearStatusData })
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("Activate App", common.activateApp)
common.Step("App subscribes to gearStatus data", common.processSubscriptionRPC, { rpc })

common.Title("Test")
for _, code in common.spairs(resultCodes) do
  common.Step("UnsubscribeVehicleData with gearStatus resultCode =" .. code,
    unsubscribeVDwithUnsuccessCodeForVD, { code })
end

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
