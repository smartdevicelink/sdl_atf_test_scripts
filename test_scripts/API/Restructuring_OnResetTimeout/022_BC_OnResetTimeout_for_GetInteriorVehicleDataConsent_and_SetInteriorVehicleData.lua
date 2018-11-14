---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0189-Restructuring-OnResetTimeout.md
--
-- Description:
-- In case:
-- 1) SetInteriorVehicleData is requested by mobile app1
-- 2) SDL sends RC.GetInteriorVehicleDataConsent
-- 3) HMI sends BC.OnResetTimeout(resetPeriod =  25000) to SDL for RC.GetInteriorVehicleDataConsent right after receiving requests on HMI
-- 4) HMI responds to RC.GetInteriorVehicleDataConsent with SUCCESS resultCode in 23 seconds after receiving HMI requests
-- 5) SDL sends RC.SetInteriorVehicleData to HMI
-- 6) HMI sends BC.OnResetTimeout(resetPeriod =  15000) to SDL RC.SetInteriorVehicleData right after receiving requests on HMI
-- 7) HMI responds to RC.SetInteriorVehicleData with SUCCESS resultCode in 13 seconds after receiving HMI requests
-- SDL does:
-- 1) Respond in 36 seconds with SUCCESS resultCode to mobile app.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/Restructuring_OnResetTimeout/common_OnResetTimeout')
local commonRC = require('test_scripts/RC/commonRC')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local paramsForRespFunction = {
  respTime = 13000,
  notificationTime = 0,
  resetPeriod = 15000
}

local paramsForRespFunctionConsent = {
  respTime = 23000,
  notificationTime = 0,
  resetPeriod = 25000
}

local RespParams = { success = true, resultCode = "SUCCESS" }

--[[ Local Functions ]]
local function SetInteriorVehicleDataWithConsentResetToBoth()
  local cid = common.getMobileSession(2):SendRPC(commonRC.getAppEventName("SetInteriorVehicleData"),
    commonRC.getAppRequestParams("SetInteriorVehicleData", "CLIMATE"))
  local requestTime = timestamp()
  local delay
  local consentRPC = "GetInteriorVehicleDataConsent"
  EXPECT_HMICALL(commonRC.getHMIEventName(consentRPC), commonRC.getHMIRequestParams(consentRPC, "CLIMATE", 2))
  :Do(function(_, data)
      paramsForRespFunctionConsent.respParams = commonRC.getHMIResponseParams(consentRPC, true)
      common.responseWithOnResetTimeout(data, paramsForRespFunctionConsent)

      EXPECT_HMICALL(commonRC.getHMIEventName("SetInteriorVehicleData"),
      commonRC.getHMIRequestParams("SetInteriorVehicleData", "CLIMATE", 2))
      :Do(function(_, dataSet)
          paramsForRespFunction.respParams = commonRC.getHMIResponseParams("SetInteriorVehicleData", "CLIMATE")
          delay = timestamp() - requestTime - paramsForRespFunctionConsent.respTime
          common.responseWithOnResetTimeout(dataSet, paramsForRespFunction)
        end)
      :Timeout(24000)
    end)

  common.getMobileSession(2):ExpectResponse(cid, RespParams)
  :Timeout(37000)
  :ValidIf(function()
      return common.responseTimeCalculationFromMobReq(36000 + delay, nil, requestTime)
    end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App_1 registration", common.registerAppWOPTU)
runner.Step("App_2 registration", common.registerAppWOPTU, { 2 })
runner.Step("App_1 activation", common.activateApp)
runner.Step("Set RA mode: ASK_DRIVER", commonRC.defineRAMode, { true, "ASK_DRIVER" })
runner.Step("SetInteriorVehicleData CLIMATE",
  commonRC.rpcAllowed, { "CLIMATE", 1, "SetInteriorVehicleData" })

runner.Title("Test")
runner.Step("App_2 activation", common.activateApp, { 2 })
runner.Step("OnResetTimeout to SetInteriorVehicleData and Consent" , SetInteriorVehicleDataWithConsentResetToBoth)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
