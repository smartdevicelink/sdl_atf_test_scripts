---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0119-SDL-passenger-mode.md
-- Description:
-- In case:
-- 1) OnDriverDistraction notification is  allowed by Policy for (FULL, LIMITED, BACKGROUND) HMILevel
-- 2) In Policy "lock_screen_dismissal_enabled" parameter is defined with "true" value
-- 3) App registered (HMI level NONE)
-- 4) HMI sends OnDriverDistraction notification with all mandatory fields (state = "DD_OFF")
-- SDL does:
--  - Not send OnDriverDistraction notification to mobile when HMI level is NONE
-- 5) App activated (HMI level FULL)
-- SDL does:
--  - Send OnDriverDistraction notification without both "lockScreenDismissalEnabled"
--    and "lockScreenDismissalWarning" parameters
-- 6) HMI sends OnDriverDistraction notification with all mandatory fields
-- SDL does:
--  - Send OnDriverDistraction notification to mobile without both "lockScreenDismissalEnabled"
--    and "lockScreenDismissalWarning" parameters
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/SDL_Passenger_Mode/commonPassengerMode')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local lockScreenDismissalEnabled = true

--[[ Local Functions ]]
local function updatePreloadedPT()
  local function updatePT(pPT)
    pPT.policy_table.functional_groupings["Base-4"].rpcs.OnDriverDistraction.hmi_levels = { "FULL" }
  end
  common.updatePreloadedPT(lockScreenDismissalEnabled, updatePT)
end

local function registerApp()
  common.registerAppWOPTU()
  common.getMobileSession():ExpectNotification("OnDriverDistraction")
  :Times(0)
end

local function onDriverDistractionUnsuccess()
  common.getHMIConnection():SendNotification("UI.OnDriverDistraction", { state = "DD_OFF" })
  common.getMobileSession():ExpectNotification("OnDriverDistraction")
  :Times(0)
end

local function activateApp()
  common.expOnDriverDistraction("DD_OFF", nil)
  common.activateApp()
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Set LockScreenDismissalEnabled", updatePreloadedPT, { lockScreenDismissalEnabled })
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration HMI level NONE", registerApp)

runner.Title("Test")
runner.Step("OnDriverDistraction OFF not transfered", onDriverDistractionUnsuccess)
runner.Step("App activation HMI level FULL", activateApp)
runner.Step("OnDriverDistraction OFF missing", common.onDriverDistraction, { "DD_OFF", nil })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
