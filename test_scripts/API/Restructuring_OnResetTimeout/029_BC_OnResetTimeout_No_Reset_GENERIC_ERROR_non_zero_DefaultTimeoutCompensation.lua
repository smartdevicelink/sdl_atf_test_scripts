------------------------------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0189-Restructuring-OnResetTimeout.md
------------------------------------------------------------------------------------------------------------------------
-- Description: Check SDL is able to respond with GENERIC_ERROR:false to Mobile app in case:
--  - 'DefaultTimeoutCompensation' is non-zero in .ini file
--  - and HMI hasn't responded
-- Notes:
--  - RPCs with specific timeout: 'PerformInteraction' (5s), 'ScrollableMessage' (1s), 'Alert' (3s),
--     'SubtleAlert' (3s), 'Slider' (1s)
------------------------------------------------------------------------------------------------------------------------
-- Preconditions:
-- 1) Default SDL timeout is 10s (defined in .INI by 'DefaultTimeout' parameter)
--
-- In case:
-- 1) App sends applicable RPC
-- 2) SDL transfers this request to HMI
-- 3) HMI doesn't provide a response
-- SDL does:
--  - wait for the response from HMI within 'DefaultTimeout + DefaultTimeoutCompensation + custom timeout'
--  - respond with GENERIC_ERROR:false to Mobile app once this timeout expires
------------------------------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/Restructuring_OnResetTimeout/common_OnResetTimeout')

--[[ Apps configuration ]]
common.getConfigAppParams(1).appHMIType = { "REMOTE_CONTROL" }
common.getConfigAppParams(2).appHMIType = { "REMOTE_CONTROL" }

--[[ Local Variables ]]
local defTimeout = common.defaultTimeout + common.defaultTimeoutCompensation
local rpcResponse = { success = false, resultCode = "GENERIC_ERROR" }

--[[ Local Functions ]]
local function preconditions()
  common.preconditions()
  common.setSDLIniParameter("DefaultTimeoutCompensation", common.defaultTimeoutCompensation)
end

local function noResponseFromHMI()
  -- HMI does not respond
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", preconditions)
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
  local timeout = defTimeout
  if common.rpcsArrayWithCustomTimeout[rpc] then
    timeout = timeout + common.rpcsArrayWithCustomTimeout[rpc].timeout
  end
  common.Step("Send " .. rpc , common.rpcs[rpc],
    { timeout + 1000, timeout, noResponseFromHMI, {}, rpcResponse, common.responseTimeCalculation })
end

common.Step("Module allocation for App_1" , common.rpcAllowed, { "CLIMATE", 1, "SetInteriorVehicleData" })
common.Step("App_2 activation", common.activateApp, { 2 })
common.Step("Send SetInteriorVehicleData with consent" , common.rpcs.rpcAllowedWithConsent,
  { defTimeout + 1000, defTimeout, noResponseFromHMI, {}, rpcResponse, common.responseTimeCalculation })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
