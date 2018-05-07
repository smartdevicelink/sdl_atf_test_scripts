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

local tirePressureValue = 100
local pressureDataSet_1 = {status = "NORMAL", tpms = "SYSTEM_ACTIVE"}
local pressureDataSet_2 = {status = "NORMAL", pressure = tirePressureValue}
local pressureDataSet_3 = {status = "NORMAL", tpms = "SYSTEM_ACTIVE", pressure = tirePressureValue}


--[[ Local Functions ]]
local function processRPCInvalidData(tirePressureRangeValue)
  local mobileSession = common.getMobileSession()
  local cid = mobileSession:SendRPC(rpc.name, rpc.params)
  EXPECT_HMICALL("VehicleInfo." .. rpc.name, rpc.params)
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, 
	data.method, 
	"SUCCESS",
	tirePressureRangeValue)
    end)

  mobileSession:ExpectResponse(cid,
    { success = true, resultCode = "SUCCESS", tirePressure = tirePressureRangeValue.tirePressure })
  commonTestCases:DelayedExp(500)
end

local function ptuFunc(tbl)
  local AppGroup = {
    rpcs = {
      GetVehicleData = {
        hmi_levels = { "NONE", "BACKGROUND", "FULL", "LIMITED" }
      }
    }
  }
  tbl.policy_table.functional_groupings.NewTestCaseGroup1 = AppGroup
  tbl.policy_table.app_policies[config.application1.registerAppInterfaceParams.appID].groups =
  { "Base-4", "NewTestCaseGroup1" }
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI with PTU", common.registerApp)
runner.Step("Activate App_1", common.activateApp)
runner.Step("PTU", common.policyTableUpdate, { ptuFunc })

runner.Title("Test")
runner.Step("GetVehicleData_tirePressure_not_full_set_of_data", processRPCInvalidData,
   {{ tirePressure = {
		pressureTelltale = "ON",
		leftFront = pressureDataSet_1,
		rightFront = pressureDataSet_2,
		leftRear = systemFaultDataSet_3,
		rightRear = pressureDataSet_3
	}}})

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)

