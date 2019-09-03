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
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/VehicleData/commonVehicleData')
local actions = require("user_modules/sequences/actions")

--[[ Local Functions ]]
local function processGetVehicleDataSuccess(pData, self)
  local mobileSession = common.getMobileSession(self, 1)
  local reqParams = {
    [pData] = true
  }
  local hmiResParams = {
    [pData] = common.allVehicleData[pData].value
  }
  local cid = mobileSession:SendRPC("GetVehicleData", reqParams)
  EXPECT_HMICALL("VehicleInfo.GetVehicleData", reqParams)
  :Do(function(_, data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", hmiResParams )
    end)
  local mobResParams = common.cloneTable(hmiResParams)
  if mobResParams.emergencyEvent then
    mobResParams.emergencyEvent.maximumChangeVelocity = 0
  end
  mobResParams.success = true
  mobResParams.resultCode = "SUCCESS"
  mobileSession:ExpectResponse(cid, mobResParams)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("`100, 1` in GetVehicleDataRequest in ini file", actions.setSDLIniParameter,
  { "GetVehicleDataRequest", "100, 1" })
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI with PTU", common.registerAppWithPTU)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
for vehicleDataName in pairs(common.allVehicleData) do
  runner.Step("RPC GetVehicleData " .. vehicleDataName, processGetVehicleDataSuccess,{ vehicleDataName })
end

runner.Title("Postconditions")
runner.Step("restore ini file", actions.restoreSDLIniParameters)
runner.Step("Stop SDL", common.postconditions)
