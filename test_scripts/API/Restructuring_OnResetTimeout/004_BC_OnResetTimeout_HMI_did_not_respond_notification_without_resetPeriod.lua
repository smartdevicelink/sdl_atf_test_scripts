------------------------------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0189-Restructuring-OnResetTimeout.md
------------------------------------------------------------------------------------------------------------------------
-- Description: Check SDL is able to respond with GENERIC_ERROR:false to Mobile app in case:
--  - default reset period received within 'OnResetTimeout(nil)' notification from HMI is expired
--  - and HMI hasn't responded
-- Applicable RPCs: 'SendLocation', 'Alert', 'SubtleAlert', 'PerformInteraction', 'Slider', 'Speak',
--  'ScrollableMessage', 'DiagnosticMessage', 'SetInteriorVehicleData'
------------------------------------------------------------------------------------------------------------------------
-- Preconditions:
-- 1) Default SDL timeout is 10s (defined in .INI by 'DefaultTimeout' parameter)
--
-- In case:
-- 1) App sends applicable RPC
-- 2) SDL transfers this request to HMI
-- 3) HMI sends 'BC.OnResetTimeout' notification to SDL without 'resetPeriod' parameter within the <delay>
-- after receiving request from SDL:
--  - 16s for 'GetInteriorVehicleDataConsent' RPC
--  - 6s for all other RPCs
-- 4) HMI doesn't provide a response
-- SDL does:
--  - wait for the response from HMI within:
--    - 'default timeout + delay' (26s) for 'GetInteriorVehicleDataConsent'
--    - 'default timeout + delay' (16s) for all other requests
--  - respond with GENERIC_ERROR:false to Mobile app once this timeout expires
------------------------------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/Restructuring_OnResetTimeout/common_OnResetTimeout')

--[[ Local Variables ]]
local paramsForRespFunction = {
  notificationTime = 6000
}

local paramsForRespFunctionWithConsent = {
  notificationTime = 16000
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
for _, rpc in pairs(common.rpcsArray) do
  common.Step("Send " .. rpc , common.rpcs[rpc],
    { 17000, 10000, common.withoutResponseWithOnResetTimeout, paramsForRespFunction, rpcResponse, common.responseTimeCalculationFromNotif })
end
common.Step("Module allocation for App_1" , common.rpcAllowed, { "CLIMATE", 1, "SetInteriorVehicleData" })
common.Step("App_2 activation", common.activateApp, { 2 })
common.Step("Send SetInteriorVehicleData with consent" , common.rpcs.rpcAllowedWithConsent,
  { 27000, 10000, common.withoutResponseWithOnResetTimeout, paramsForRespFunctionWithConsent, rpcResponse, common.responseTimeCalculationFromNotif })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
