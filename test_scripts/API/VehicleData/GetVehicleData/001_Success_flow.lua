---------------------------------------------------------------------------------------------------
-- User story: TO ADD !!!
-- Use case: TO ADD !!!
-- Item: Use Case 1: Main Flow
--
-- Requirement summary:
-- [GetVehicleData] As a mobile app wants to send a request to get the details of the vehicle data
--
-- Description:
-- In case:
-- mobile application sends valid GetVehicleData to SDL and this request is allowed by Policies
-- SDL must:
-- 1) Transfer this request to HMI
-- 2) After successful response from hmi
--    respond SUCCESS, success:true and parameter value received from HMI to mobile application
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/commonVehicleData')

--[[ Local Functions ]]
local function processRPCSuccess(pData)
  local reqParams = {
    [pData] = true
  }
  local hmiResParams = {
    [pData] = common.allVehicleData[pData].value
  }
  local cid = common.getMobileSession():SendRPC("GetVehicleData", reqParams)
  common.getHMIConnection():ExpectRequest("VehicleInfo.GetVehicleData", reqParams)
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", hmiResParams)
    end)
  local mobResParams = common.cloneTable(hmiResParams)
  if mobResParams.emergencyEvent then
    mobResParams.emergencyEvent.maximumChangeVelocity = 0
  end
  mobResParams.success = true
  mobResParams.resultCode = "SUCCESS"
  common.getMobileSession():ExpectResponse(cid, mobResParams)
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("`100, 1` in GetVehicleDataRequest in ini file", common.setSDLIniParameter,
  { "GetVehicleDataRequest", "100, 1" })
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("RAI", common.registerApp)
common.Step("PTU", common.policyTableUpdate, { common.ptUpdate })
common.Step("Activate App", common.activateApp)

common.Title("Test")
for vehicleDataName in pairs(common.allVehicleData) do
  common.Step("RPC GetVehicleData " .. vehicleDataName, processRPCSuccess, { vehicleDataName })
end

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
