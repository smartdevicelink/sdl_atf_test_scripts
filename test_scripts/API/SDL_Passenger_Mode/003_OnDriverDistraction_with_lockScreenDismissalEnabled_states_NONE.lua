---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0119-SDL-passenger-mode.md
--
-- Description:
-- In case:
-- 1) By policy OnDriverDistraction allowed for (FULL, LIMITED, BACKGROUND) HMILevel
-- 2) App registered (HMI level NONE)
-- 3) HMI sends "lockScreenDismissalEnabled"=true (and all mandatory fields) as a parameter
--    of OnDriverDistraction notification
-- 4) App activated (HMI level FULL)
-- 5) HMI sends valid OnDriverDistraction notification with "lockScreenDismissalEnabled"=false param
-- SDL does:
-- 1) Not send  OnDriverDistraction notification to mobile when (HMI level NONE)
-- 2) Send OnDriverDistraction notification to mobile with "lockScreenDismissalEnabled"=true once app is activated
-- 3) Send OnDriverDistraction notification to mobile with "lockScreenDismissalEnabled"=false once HMI sends it
--    to SDL when app is in FULL
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/SDL_Passenger_Mode/commonPassengerMode')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local utils = require('user_modules/utils')
local json = require("modules/json")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local preloadedPT = commonFunctions:read_parameter_from_smart_device_link_ini("PreloadedPT")

--[[ Local Functions ]]
local function backupPreloadedPT()
  commonPreconditions:BackupFile(preloadedPT)
end

local function updatePreloadedPT()
  local preloadedFile = commonPreconditions:GetPathToSDL() .. preloadedPT
  local pt = utils.jsonFileToTable(preloadedFile)
  pt.policy_table.functional_groupings["DataConsent-2"].rpcs = json.null
  pt.policy_table.functional_groupings["Base-4"].rpcs.OnDriverDistraction.hmi_levels = { "BACKGROUND", "FULL", "LIMITED" }
  utils.tableToJsonFile(pt, preloadedFile)
end

local function registerApp()
  common.registerAppWOPTU()
  common.getMobileSession():ExpectNotification("OnDriverDistraction", { state = "DD_OFF" })
  :Times(0)
end

local function activateApp()
  common.activateApp()
  common.getMobileSession():ExpectNotification("OnDriverDistraction",
    { lockScreenDismissalEnabled = true, state = "DD_OFF" })
end

local function restorePreloadedPT()
  commonPreconditions:RestoreFile(preloadedPT)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Back-up PreloadedPT", backupPreloadedPT)
runner.Step("Update PreloadedPT", updatePreloadedPT)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration HMI level NONE", registerApp)

-- runner.Title("Test")
for _, v in pairs(common.OnDDValue) do
  runner.Step("OnDriverDistraction with state " .. v .. " with lockScreenDismissalEnabled " .. tostring(true),
  common.onDriverDistractionUnsuccess, { v, true })
end
runner.Step("App activation HMI level FULL", activateApp)

for _, v in pairs(common.OnDDValue) do
  runner.Step("OnDriverDistraction with state " .. v .. " with lockScreenDismissalEnabled " .. tostring(false),
  common.onDriverDistraction, { v, false })
end


runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
runner.Step("Restore PreloadedPT", restorePreloadedPT)
