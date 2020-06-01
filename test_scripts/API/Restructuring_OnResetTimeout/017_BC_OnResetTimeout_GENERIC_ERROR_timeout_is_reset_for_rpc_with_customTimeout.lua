---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0189-Restructuring-OnResetTimeout.md
--
-- Description:
-- In case:
-- 1) RPC with own timeout is requested
-- 2) SDL re-sends this request to HMI and wait for response
-- 3) Default (10 sec) timeout is expired
-- 4) HMI sends BC.OnResetTimeout(resetPeriod = 7000) to SDL
-- 5) HMI does not send response
-- SDL does:
-- 1) Respond with GENERIC_ERROR resultCode to mobile app after 17 seconds
---------------------------------------------------------------------------------------------------
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
common.Step("Send Slider" , common.rpcs.Slider,
  { 18000, 7000, common.withoutResponseWithOnResetTimeout, paramsForRespFunction, rpcResponse, common.responseTimeCalculationFromNotif })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
