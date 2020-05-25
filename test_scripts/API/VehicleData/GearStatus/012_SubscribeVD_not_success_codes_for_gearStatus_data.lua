---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0266-New-vehicle-data-GearStatus.md
--
-- Description: Processing of SubscribeVehicleData with unsuccessful resultCode for gearStatus data
--
-- In case:
-- 1) App sends SubscribeVehicleData request with gearStatus=true to the SDL and this request is allowed by Policies.
-- SDL does:
--  a) transfer this request to HMI.
-- 2) HMI responds with `SUCCESS` result to SubscribeVehicleData request
--  and with not success result for `gearStatus` vehicle data
-- SDL does:
--  a) respond `SUCCESS`, success:true and with unsuccessful resultCode for gearStatus data to the mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/GearStatus/common')

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

--[[ Local Functions ]]
local function subscribeVDwithUnsuccessCodeForVD(pCode)
  local gearStatusData = common.getGearStatusSubscriptionResData()
  gearStatusData.resultCode = pCode
  local cid = common.getMobileSession():SendRPC("SubscribeVehicleData", { gearStatus = true })
  common.getHMIConnection():ExpectRequest("VehicleInfo.SubscribeVehicleData", { gearStatus = true })
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

common.Title("Test")
for _, code in common.spairs(resultCodes) do
  common.Step("SubscribeVehicleData with gearStatus resultCode=" .. code, subscribeVDwithUnsuccessCodeForVD, { code })
end

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
