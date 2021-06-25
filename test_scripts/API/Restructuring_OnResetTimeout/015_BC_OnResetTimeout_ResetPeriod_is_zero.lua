------------------------------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0189-Restructuring-OnResetTimeout.md
------------------------------------------------------------------------------------------------------------------------
-- Description: Check SDL is able to apply default RPC (or default System) timeout and
--  respond with GENERIC_ERROR:false to Mobile app in case:
--  - zero reset period received within 'OnResetTimeout()' notification from HMI
--  - and HMI hasn't responded
-- Notes:
--  - RPCs without specific timeout: 'SendLocation', 'Speak', 'DiagnosticMessage', 'SetInteriorVehicleData'
--  - RPCs with specific timeout: 'PerformInteraction' (5s), 'ScrollableMessage' (1s), 'Alert' (3s),
--     'SubtleAlert' (3s), 'Slider' (1s)
------------------------------------------------------------------------------------------------------------------------
-- Preconditions:
-- 1) Default SDL timeout is 10s (defined in .INI by 'DefaultTimeout' parameter)
--
-- In case:
-- 1) App sends applicable RPC
-- 2) SDL transfers this request to HMI
-- 3) HMI sends 'BC.OnResetTimeout' notification to SDL with 'resetPeriod=0' parameter within the <delay>
-- after receiving request from SDL:
--  - 15s for 'GetInteriorVehicleDataConsent' RPC
--  - 5s for all other RPCs
-- 4) HMI doesn't provide a response
-- SDL does:
--  - wait for the response from HMI within:
--    - '2 x default timeout' (20s) for 'GetInteriorVehicleDataConsent'
--    - 'default timeout' (10s) for RPCs without specific timeout
--    - 'default timeout + RPC timeout' for RPCs with specific timeout
--  - respond with GENERIC_ERROR:false to Mobile app once this timeout expires
------------------------------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/Restructuring_OnResetTimeout/common_OnResetTimeout')

--[[ Local Variables ]]
local paramsForRespFunction = {
  notificationTime = 5000,
  resetPeriod = 0
}

local paramsForRespFunctionWithConsent = {
  notificationTime = 15000,
  resetPeriod = 0
}

local rpcResponse = { success = false, resultCode = "GENERIC_ERROR" }

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("App_1 registration", common.registerAppWOPTU)
common.Step("App_2 registration", common.registerAppWOPTU, { 2 })
common.Step("App_1 activation", common.activateApp)
common.Step("Set RA mode: ASK_DRIVER", common.defineRAMode, { true, "ASK_DRIVER" })
common.Step("Create InteractionChoiceSet id 100", common.createInteractionChoiceSet, { 100 })
common.Step("Create InteractionChoiceSet id 200", common.createInteractionChoiceSet, { 200 })
common.Step("Add AddSubMenu", common.addSubMenu)

common.Title("Test")
for _, rpc in pairs(common.rpcsArrayWithoutRPCWithCustomTimeout) do
  common.Step("Send " .. rpc , common.rpcs[rpc],
    { 11000, 5000, common.withoutResponseWithOnResetTimeout, paramsForRespFunction, rpcResponse, common.responseTimeCalculationFromNotif})
end
common.Step("Send PerformInteraction" , common.rpcs.PerformInteraction,
  { 16000, 10000, common.withoutResponseWithOnResetTimeout, paramsForRespFunction, rpcResponse, common.responseTimeCalculationFromNotif })
common.Step("Send ScrollableMessage" , common.rpcs.ScrollableMessage,
  { 12000, 6000, common.withoutResponseWithOnResetTimeout, paramsForRespFunction, rpcResponse, common.responseTimeCalculationFromNotif })
common.Step("Send Alert" , common.rpcs.Alert,
  { 14000, 8000, common.withoutResponseWithOnResetTimeout, paramsForRespFunction, rpcResponse, common.responseTimeCalculationFromNotif })
common.Step("Send SubtleAlert" , common.rpcs.SubtleAlert,
  { 14000, 8000, common.withoutResponseWithOnResetTimeout, paramsForRespFunction, rpcResponse, common.responseTimeCalculationFromNotif })
common.Step("Send Slider" , common.rpcs.Slider,
  { 12000, 6000, common.withoutResponseWithOnResetTimeout, paramsForRespFunction, rpcResponse, common.responseTimeCalculationFromNotif })

common.Step("Module allocation for App_1" , common.rpcAllowed, { "CLIMATE", 1, "SetInteriorVehicleData" })
common.Step("App_2 activation", common.activateApp, { 2 })
common.Step("Send SetInteriorVehicleData with consent" , common.rpcs.rpcAllowedWithConsent,
  { 21000, 5000, common.withoutResponseWithOnResetTimeout, paramsForRespFunctionWithConsent, rpcResponse, common.responseTimeCalculationFromNotif})

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
