--------------------------------------------------------------------------------
-- User story: https://github.com/SmartDeviceLink/sdl_core/issues/1399

-- Steps to reproduce:
-- 1. Mobile app is registered and activated
-- 2. RPC ReadDID is allowed by policy
-- 3. Mobile app requests ReadDID
-- 4. HMI sends response VehicleInfo.ReadDID to SDL with resultCode = "TRUNCATED_DATA"

-- Expected:
-- 1. SDL sends response ReadDID(TRUNCATED_DATA) with success:true to mobile app
--------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("user_modules/sequences/actions")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function setReadDIDRequest()
  local temp = {
    ecuName = 2000,
    didLocation = {
      100,
      1000,
      10000
    }
  }
  return temp
end

local function setReadDIDSuccessResponse(didLocationValues)
  local temp = {
    didResult = {}
  }
  for i = 1, #didLocationValues do
    temp.didResult[i] = {
      resultCode = "SUCCESS",
      didLocation = didLocationValues[i],
      data = "123"
    }
  end
  return temp
end

local function readDID()
  local paramsSend = setReadDIDRequest()
  local response = setReadDIDSuccessResponse(paramsSend.didLocation)
  local cid = common.getMobileSession():SendRPC("ReadDID",paramsSend)
  paramsSend.appID = common.getHMIAppId()
  EXPECT_HMICALL("VehicleInfo.ReadDID",paramsSend)
  :Do(function(_,data)
    common.getHMIConnection():SendResponse(data.id, data.method, "TRUNCATED_DATA", response)
  end)
  local expectedResult = response
  expectedResult.success = true
  expectedResult.resultCode = "TRUNCATED_DATA"
  common.getMobileSession():ExpectResponse(cid, expectedResult)
end

local function ptuFunc(tbl)
  tbl.policy_table.app_policies[config.application1.registerAppInterfaceParams.fullAppID].groups = { "Base-4", "PropriataryData-1" }
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.registerApp)
runner.Step("PTU", common.policyTableUpdate, { ptuFunc })
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("ReadDID with resultCode TRUNCATED_DATA", readDID)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
