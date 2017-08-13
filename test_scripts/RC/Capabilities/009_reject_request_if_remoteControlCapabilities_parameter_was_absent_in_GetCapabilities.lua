---------------------------------------------------------------------------------------------------
-- Requirement summary:
-- [SDL_RC] Set available control module settings SetInteriorVehicleData
--
-- Description:
-- In case:
-- 1) SDL didn't receive in GetCapabilites response remoteControlCapability parameter
-- SDL must:
-- 1) Reject any RC related RPCs with UNSUPPORTED_RESOURCE result code, success: false
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/commonRC')

--[[ Local Variables ]]
local rc_capabilities = commonRC.buildHmiRcCapabilities(commonRC.DEFAULT, commonRC.DEFAULT, commonRC.DEFAULT)
rc_capabilities.RC.GetCapabilities.params.remoteControlCapability = nil

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start, {rc_capabilities})
runner.Step("RAI, PTU", commonRC.rai_ptu)
runner.Step("Activate_App", commonRC.activate_app)
--Check that all RC RPCs are rejected by SDL
runner.Title("Test")
for _, module_name in pairs({"CLIMATE", "RADIO"}) do
    runner.Step("GetInteriorVehicleData for " .. module_name,
        commonRC.rpcDenied,
        {module_name, 1, "GetInteriorVehicleData", "UNSUPPORTED_RESOURCE"})
    runner.Step("SetInteriorVehicleData for " .. module_name,
        commonRC.rpcDenied,
        {module_name, 1, "SetInteriorVehicleData", "UNSUPPORTED_RESOURCE"})
    runner.Step("ButtonPress for " .. module_name,
        commonRC.rpcDenied,
        {module_name, 1, "ButtonPress", "UNSUPPORTED_RESOURCE"})
end
