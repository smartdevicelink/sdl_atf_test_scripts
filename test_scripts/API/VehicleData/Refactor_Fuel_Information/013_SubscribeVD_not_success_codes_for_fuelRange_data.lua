---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0256-Refactor-Fuel-Information-Related-Vehicle-Data.md
-- Description: Processing of SubscribeVehicleData with unsuccessful resultCode for `FuelRange` data
-- In case:
-- 1) App sends SubscribeVehicleData(fuelRange:true) request
-- 2) SDL transfers this request to HMI
-- 3) HMI responds with `SUCCESS` result to SubscribeVehicleData request
--  and with not success result for `fuelRange` vehicle data
-- SDL does:
--  a) respond `SUCCESS`, success:true and with unsuccessful resultCode for fuelRange data to the mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/Refactor_Fuel_Information/common')

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
local function subscribeVDwithUnsuccessCodeForVD(pCode)
  local fuelRangeData = { dataType = "VEHICLEDATA_FUELRANGE", resultCode = pCode}
  local cid = common.getMobileSession():SendRPC("SubscribeVehicleData", { fuelRange = true })
  common.getHMIConnection():ExpectRequest("VehicleInfo.SubscribeVehicleData", { fuelRange = true })
  :Do(function(_,data)
    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS",
      { fuelRange = fuelRangeData })
  end)
  common.getMobileSession():ExpectResponse(cid,
    { success = true, resultCode = "SUCCESS", fuelRange = fuelRangeData })
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("Activate App", common.activateApp)

common.Title("Test")
for _, code in pairs(resultCodes) do
  common.Step("SubscribeVehicleData with fuelRange resultCode =" .. code, subscribeVDwithUnsuccessCodeForVD, { code })
end

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
