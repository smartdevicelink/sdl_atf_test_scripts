------------------------------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0189-Restructuring-OnResetTimeout.md
------------------------------------------------------------------------------------------------------------------------
-- Description: Check SDL is able to respond with GENERIC_ERROR:false to Mobile app in case:
--  - invalid data is provided in 'OnResetTimeout()' notification from HMI
--  - and default reset period is expired
--  - and HMI hasn't responded
------------------------------------------------------------------------------------------------------------------------
-- Preconditions:
-- 1) Default SDL timeout is 10s (defined in .INI by 'DefaultTimeout' parameter)
--
-- In case:
-- 1) App sends applicable RPC
-- 2) SDL transfers this request to HMI
-- 3) HMI sends 'BC.OnResetTimeout' notification with invalid data after delay of 6s
-- 4) HMI doesn't provide a response
-- SDL does:
--  - ignore invalid 'OnResetTimeout()' notification
--  - wait for the response from HMI within 'default timeout' (10s)
--  - respond with GENERIC_ERROR:false to Mobile app once this timeout expires
------------------------------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/Restructuring_OnResetTimeout/common_OnResetTimeout')

--[[ Local Variables ]]
local pOnResetTimeOut = {
  missingMandatory = { resetPeriod = 13000 },
  invaidType = { requestID = "wrongType", methodName = "Navigation.SendLocation", resetPeriod = 13000 },
  incorrectStructure = { requestID = {}, methodName = "Navigation.SendLocation", resetPeriod = 13000 },
  resetPeriodOutOfBoundsMaxValue = { methodName = "Navigation.SendLocation", resetPeriod = 1000001 },
  resetPeriodOutOfBoundsMinValue = { methodName = "Navigation.SendLocation", resetPeriod = -1 }
}

local paramsForRespFunction = {
  notificationTime = 6000
}

local rpcResponse = { success = false, resultCode = "GENERIC_ERROR" }

--[[ Local Functions ]]
local function invalidParamOnResetTimeout(pData, pOnRTParams)
  if pOnRTParams.testName == "resetPeriodOutOfBoundsMaxValue" or
    pOnRTParams.testName == "resetPeriodOutOfBoundsMinValue" then
    pOnRTParams.onResetParams.requestID = pData.id
  end
  local function sendOnResetTimeout()
    common.getHMIConnection():SendNotification("BasicCommunication.OnResetTimeout", pOnRTParams.onResetParams)
    common.notificationTime = timestamp()
  end
  RUN_AFTER(sendOnResetTimeout, pOnRTParams.notificationTime)
end

local function getOnResetTimeoutParams(pCaseName, pValue)
  paramsForRespFunction.onResetParams = pValue
  paramsForRespFunction.testName = pCaseName
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("App registration", common.registerAppWOPTU)
common.Step("App activation", common.activateApp)

common.Title("Test")
for k, value in pairs(pOnResetTimeOut) do
  common.Step("Set params for OnResetTimeout notification", getOnResetTimeoutParams, { k, value })
  common.Step("Send SendLocation " .. k, common.rpcs.SendLocation,
    { 11000, 10000, invalidParamOnResetTimeout, paramsForRespFunction, rpcResponse, common.responseTimeCalculationFromMobReq })
end

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
