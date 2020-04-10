---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0256-Refactor-Fuel-Information-Related-Vehicle-Data.md
-- Description: SDL successfully processes RPC GetVehicleData if FuelRange structure contains one new parameter
-- In case:
-- 1) App sends GetVehicleData(fuelRange:true) request
-- 2) SDL transfers this request to HMI
-- 3) HMI sends the `FuelRange` structure with only one param in GetVehicleData response
-- SDL does:
-- 1) respond with resultCode:"SUCCESS" to app with only one param
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/Refactor_Fuel_Information/common')

--[[ Local Functions ]]
local function getVDWithOneParam(pData)
  local cid = common.getMobileSession():SendRPC("GetVehicleData", { fuelRange = true })
  common.getHMIConnection():ExpectRequest("VehicleInfo.GetVehicleData", { fuelRange = true })
  :Do(function(_,data)
    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { fuelRange = pData })
  end)
  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS", fuelRange = pData })
  :ValidIf(function(_, data)
    return common.checkParam(data, "GetVehicleData")
  end)
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("PTU", common.policyTableUpdate, { common.pTUpdateFunc })
common.Step("Activate App", common.activateApp)

common.Title("Test")
for k,v in pairs(common.allVehicleData) do
  common.Step("HMI sends response with " .. k, getVDWithOneParam, { { { [k] = v } } })
end

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
