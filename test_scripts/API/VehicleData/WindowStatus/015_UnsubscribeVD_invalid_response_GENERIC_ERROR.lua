---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0261-New-vehicle-data-WindowStatus.md
--
-- Description: Check that SDL sends response `GENERIC_ERROR` to mobile app
--  if HMI sends VD.UnsubscribeVehicleData response with invalid `windowStatus` data
--
-- In case:
-- 1) App sends UnsubscribeVehicleData request with windowStatus=true to the SDL and this request is allowed by Policies.
-- SDL does:
--  a) transfer this request to HMI.
-- 2) HMI sends the invalid `windowStatus` structure in VD.UnsubscribeVehicleData response
-- SDL does:
--  a) respond GENERIC_ERROR to mobile after receiving invalid HMI response
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/WindowStatus/common')

--[[ Local Variables ]]
local rpc = "UnsubscribeVehicleData"
local rpcSubscribe = "SubscribeVehicleData"
local invalidValues = {
  wrongDataType = "VEHICLEDATA_GPS",
  invalidDataType = 123
}

local function getData(pValue)
  local params = common.cloneTable(common.subUnsubParams)
  params.dataType = pValue
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("Activate App", common.activateApp)
common.Step("App subscribes to windowStatus data", common.subUnScribeVD, { rpcSubscribe })

common.Title("Test")
for k, v in common.spairs(invalidValues) do
  common.Step("HMI sends UnsubscribeVehicleData response with " .. k,
    common.processRPCgenericError, { rpc, getData(v) })
end

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
