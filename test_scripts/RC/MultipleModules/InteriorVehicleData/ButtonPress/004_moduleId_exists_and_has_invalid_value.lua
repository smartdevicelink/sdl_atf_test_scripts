---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0221-multiple-modules.md
-- Description:
--  Mobile App sends to the SDL "ButtonPress" request where "moduleId" has value of incorrect data types.
--  Check that SDL declines these "ButtonPress" requests and responds back to the mobile App with
--  ( resultCode = "UNSUPPORTED_RESOURCE" )
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) HMI sent all modules capabilities to the SDL
-- 3) Mobile is connected to the SDL
-- 4) App is registered and activated
--
-- Steps:
-- 1) App sends "ButtonPress"
--     (moduleType = "RADIO", moduleId = "invalid_values", buttonName = "SOURCE", buttonPressMode = "LONG") request
--     to the SDL
--   Check:
--    SDL does NOT resend "Buttons.ButtonPress" request to the HMI
--    SDL responds with "ButtonPress"(success = false, resultCode = "INVALID_DATA") to the App
-- 2-4) Repeat step 1 setting different data types in "moduleId"
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("test_scripts/RC/MultipleModules/commonRCMulModules")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local invalid_values = { true, {1, 2, 3}, 1234, common.EMPTY_ARRAY }
local rcCapabilities = {RADIO = common.DEFAULT}

--[[ Local Variables ]]
local function sendPreparedRequestData( pModuleType, pModuleId, pAppId, rpc, pResultCode )
  local requestModuleData = {
    moduleType = "RADIO",
    buttonName = "SOURCE",
    buttonPressMode = "LONG"
  }
  requestModuleData.moduleId = pModuleId
  common.rpcReject(pModuleType, pModuleId, pAppId, rpc, requestModuleData, pResultCode)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Build default actual module state", common.initHmiDataState, { rcCapabilities })
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { rcCapabilities })
runner.Step("RAI", common.registerApp)
runner.Step("PTU", common.policyTableUpdate, { common.PTUfunc })
runner.Step("Activate App", common.activateApp)

runner.Title("Test")

for _, invValue in pairs(invalid_values) do
  runner.Step("Send ButtonPress request with invalid "..type(invValue).." moduleId",
    sendPreparedRequestData, { "CLIMATE", invValue, 1, "ButtonPress", "INVALID_DATA"})
end


runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
