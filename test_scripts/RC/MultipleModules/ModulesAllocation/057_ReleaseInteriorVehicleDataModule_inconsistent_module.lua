---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0221-multiple-modules.md
-- Description:
--  Check of releasing of RC modules with moduleId of other module type using ReleaseInteriorVehicleDataModule RPC
--
-- Precondition:
-- 1) SDL and HMI are started
-- 2) HMI sent RC capabilities with modules of each type to SDL (moduleId: A0A is correct for AUDIO module type only)
-- 3) Mobile is connected to SDL
-- 4) App1 (appHMIType: ["REMOTE_CONTROL"]) is registered from Mobile
-- 5) HMI level of App1 is FULL
--
-- Steps:
-- 1) Send ReleaseInteriorVehicleDataModule RPC for each RC module except AUDIO
--     (moduleType: <moduleType>, moduleId: A0A) from App1
--   Check:
--    SDL responds on ReleaseInteriorVehicleDataModule RPC with
--     resultCode:"UNSUPPORTED_RESOURCE", info:"Accessing not supported module", success:false
--    SDL does not release module and does not send OnRCStatus notifications to HMI and App1
---------------------------------------------------------------------------------------------------
local runner = require('user_modules/script_runner')
local common = require("test_scripts/RC/MultipleModules/commonRCMulModules")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local appLocation = {
  [1] = common.grid.BACK_CENTER_PASSENGER
}

local rcAppIds = { 1 }

--[[ Local Functions ]]
local function getRcModuleTypesWithoutAudio()
	local moduleTypessWithoutAudio = common.getRcModuleTypes()
	local id
	for k, v in ipairs(moduleTypessWithoutAudio) do
		if v == "AUDIO" then id = k end
	end
	if id then table.remove(moduleTypessWithoutAudio, id) end
	return moduleTypessWithoutAudio
end

local testModuleTypes = getRcModuleTypesWithoutAudio()
local rcCapabilities = common.initHmiRcCapabilitiesForRelease(appLocation[1])

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Prepare preloaded policy table", common.preparePreloadedPT, { rcAppIds })
runner.Step("Prepare RC modules capabilities and initial modules data", common.initHmiDataState, { rcCapabilities })
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { rcCapabilities })
runner.Step("Set RA mode: AUTO_ALLOW", common.defineRAMode, { true, "AUTO_ALLOW" })
runner.Step("Register App1", common.registerAppWOPTU, { 1 })
runner.Step("Activate App1", common.activateApp, { 1 })
runner.Step("Send user location of App1 (Back seat)", common.setUserLocation, { 1, appLocation[1] })

runner.Title("Test")
for _, moduleType in ipairs(testModuleTypes) do
	runner.Step("Try to release not existing module [" .. moduleType .. ":A0A]",
	    common.releaseModuleWithInfoCheck,
	    { 1, moduleType, "A0A", "UNSUPPORTED_RESOURCE", "NOT_EXISTING_MODULE", rcAppIds })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
