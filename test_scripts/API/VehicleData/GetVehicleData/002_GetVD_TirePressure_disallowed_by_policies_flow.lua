---------------------------------------------------------------------------------------------------
-- User story: TO ADD !!!
-- Use case: TO ADD !!!
--
-- Requirement summary:
-- [GetVehicleData] As a mobile app wants to send a request to get the details of the vehicle data
--
-- Description:
-- In case:
-- 1) mobile application sends valid GetVehicleData to SDL and this request is allowed by Policies
-- 2) HMI sends boundary values of parameters in response
-- SDL must:
-- transfer parameter values to mobile app
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/VehicleData/commonVehicleData')
local commonTestCases = require("user_modules/shared_testcases/commonTestCases")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local rpc = {
  name = "GetVehicleData",
  params = {
    tirePressure = true
  }
}

--[[ Local Functions ]]
local function processRPCFailure()
  local mobileSession = common.getMobileSession()
  local cid = mobileSession:SendRPC(rpc.name, rpc.params)
  EXPECT_HMICALL("VehicleInfo." .. rpc.name, rpc.params):Times(0)

  commonTestCases:DelayedExp(common.timeout)
  mobileSession:ExpectResponse(cid, { success = false, resultCode = "DISALLOWED" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI with PTU", common.registerApp)
runner.Step("Activate App_1", common.activateApp)

runner.Title("Test")
runner.Step("RPC " .. rpc.name, processRPCFailure)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)

