---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0189-Restructuring-OnResetTimeout.md
-- User story: TBD
-- Use case: TBD
--
-- Requirement summary: TBD
--
-- Description:
-- In case:
-- 1) RPC is requested
-- 2) Some time after receiving RPC request on HMI is passed
-- 3) HMI sends BC.OnResetTimeout(resetPeriod = 6000) with wrong requestID to SDL in 6 sec after HMI request
-- 4) HMI does not send response in 10 seconds after receiving request
-- SDL does:
-- 1) Respond in 10 seconds with GENERIC_ERROR resultCode to mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/Restructuring_OnResetTimeout/common_OnResetTimeout')
local commonRC = require('test_scripts/RC/commonRC')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]

-- Slider is removed from array, because specific timeout must be applicable for it(default timeout + timeout from request)
for key, value in pairs(common.rpcsArray) do
  if value == "Slider"then
    table.remove(common.rpcsArray, key)
  end
end

local wrongRequestID = "Wrong_RequestID"

local paramsForRespFunction = {
  notificationTime = 6000,
  resetPeriod = 6000
}

local rpcResponse = { success = false, resultCode = "GENERIC_ERROR" }

--[[ Local Functions ]]
local function invaliParamOnResetTimeout(pData, pParams)
  local function sendOnResetTimeout()
    common.onResetTimeoutNotification(wrongRequestID, pData.method, pParams.resetPeriod)
  end
  RUN_AFTER(sendOnResetTimeout, pParams.notificationTime)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App_1 registration", common.registerAppWOPTU)
runner.Step("App_2 registration", common.registerAppWOPTU, { 2 })
runner.Step("App_1 activation", common.activateApp)
runner.Step("Set RA mode: ASK_DRIVER", commonRC.defineRAMode, { true, "ASK_DRIVER" })
runner.Step("Create InteractionChoiceSet", common.createInteractionChoiceSet)

runner.Title("Test")
for _, rpc in pairs(common.rpcsArray) do
  runner.Step("Send " .. rpc , common.rpcs[rpc],
    { 11000, 4000, invaliParamOnResetTimeout, paramsForRespFunction, rpcResponse })
end
runner.Step("Send Slider" , common.rpcs.Slider,
  { 12000, 5000, invaliParamOnResetTimeout, paramsForRespFunction, rpcResponse })
runner.Step("App_2 activation", common.activateApp, { 2 })
runner.Step("Send SetInteriorVehicleData with consent" , common.rpcs.rpcAllowedWithConsent,
  { 11000, 4000, invaliParamOnResetTimeout, paramsForRespFunction, rpcResponse })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
