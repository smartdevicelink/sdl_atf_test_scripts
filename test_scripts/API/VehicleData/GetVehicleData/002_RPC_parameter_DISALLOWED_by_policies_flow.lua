---------------------------------------------------------------------------------------------------
-- User story: TO ADD !!!
-- Use case: TO ADD !!!
-- Item: Use Case: request is allowed but parameter of this request is NOT allowed by Policies
--
-- Requirement summary:
-- [GetVehicleData] As a mobile app wants to send a request to get the details of the vehicle data
--
-- Description:
-- In case:
-- 1) mobile application sends valid GetVehicleData to SDL and this request is allowed
--    by Policies but RPC parameter is not allowed
-- SDL must:
-- SDL responds DISALLOWED, success:false to mobile application
-- and doesn't transfer this request to HMI
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/commonVehicleData')

--[[ Local Variables ]]
local rpc = {
  name = "GetVehicleData",
  params = {
    engineOilLife = true,
    fuelRange = true,
    tirePressure = true,
    electronicParkBrakeStatus = true,
    turnSignal = true
  }
}

--[[ Local Functions ]]
local function processRPCFailure()
  local cid = common.getMobileSession():SendRPC(rpc.name, rpc.params)
  common.getHMIConnection():ExpectRequest("VehicleInfo." .. rpc.name, rpc.params):Times(0)
  common.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "DISALLOWED" })
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("RAI", common.registerApp)
common.Step("PTU", common.policyTableUpdate, { common.ptUpdateMin })
common.Step("Activate App", common.activateApp)

common.Title("Test")
common.Step("RPC " .. rpc.name .. " DISALLOWED", processRPCFailure)

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
