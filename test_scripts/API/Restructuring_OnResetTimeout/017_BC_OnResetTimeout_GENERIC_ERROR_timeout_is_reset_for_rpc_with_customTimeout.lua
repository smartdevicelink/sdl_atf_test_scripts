------------------------------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0189-Restructuring-OnResetTimeout.md
------------------------------------------------------------------------------------------------------------------------
-- Description: Check SDL does not apply default RPC timeout and respond with GENERIC_ERROR:false to Mobile app in case:
--  - App sends RPC with specific timeout
--  - reset period received within 'OnResetTimeout(resetPeriod)' notification from HMI is expired
--  - and HMI hasn't responded
-- Notes:
--  - RPCs with specific timeout: 'PerformInteraction' (5s), 'ScrollableMessage' (1s), 'Alert' (3s),
--     'SubtleAlert' (3s), 'Slider' (1s)
------------------------------------------------------------------------------------------------------------------------
-- Preconditions:
-- 1) Default SDL timeout is 10s (defined in .INI by 'DefaultTimeout' parameter)
--
-- In case:
-- 1) App sends applicable RPC with specific timeout
-- 2) SDL transfers this request to HMI
-- 3) HMI sends 'BC.OnResetTimeout' notification to SDL with 'resetPeriod=7s' parameter within the 10.5s
-- after receiving request from SDL
-- 4) HMI doesn't provide a response
-- SDL does:
--  - wait for the response from HMI within 'delay + reset period' (17.5s)
--  - respond with GENERIC_ERROR:false to Mobile app once this timeout expires
------------------------------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/Restructuring_OnResetTimeout/common_OnResetTimeout')

--[[ Local Variables ]]
local paramsForRespFunction = {
  notificationTime = 10500,
  resetPeriod = 7000
}

local rpcResponse = { success = false, resultCode = "GENERIC_ERROR" }

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("App_1 registration", common.registerAppWOPTU)
common.Step("App_2 registration", common.registerAppWOPTU, { 2 })
common.Step("App_1 activation", common.activateApp)
common.Step("Create InteractionChoiceSet", common.createInteractionChoiceSet)

common.Title("Test")
common.Step("Send PerformInteraction" , common.rpcs.PerformInteraction,
  { 18000, 7000, common.withoutResponseWithOnResetTimeout, paramsForRespFunction, rpcResponse, common.responseTimeCalculationFromNotif })
common.Step("Send ScrollableMessage" , common.rpcs.ScrollableMessage,
  { 18000, 7000, common.withoutResponseWithOnResetTimeout, paramsForRespFunction, rpcResponse, common.responseTimeCalculationFromNotif })
common.Step("Send Alert" , common.rpcs.Alert,
  { 18000, 7000, common.withoutResponseWithOnResetTimeout, paramsForRespFunction, rpcResponse, common.responseTimeCalculationFromNotif })
common.Step("Send SubtleAlert" , common.rpcs.SubtleAlert,
  { 18000, 7000, common.withoutResponseWithOnResetTimeout, paramsForRespFunction, rpcResponse, common.responseTimeCalculationFromNotif })
common.Step("Send Slider" , common.rpcs.Slider,
  { 18000, 7000, common.withoutResponseWithOnResetTimeout, paramsForRespFunction, rpcResponse, common.responseTimeCalculationFromNotif })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
