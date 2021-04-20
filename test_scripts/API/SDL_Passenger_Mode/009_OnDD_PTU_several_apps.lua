---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0119-SDL-passenger-mode.md
-- Description:
-- In case:
-- 1) OnDriverDistraction notification is  allowed by Policy for (FULL, LIMITED, BACKGROUND) HMILevel
-- 2) In Policy "lock_screen_dismissal_enabled" parameter is defined with correct value (false)
-- 3) HMI sends OnDriverDistraction notification with all mandatory fields (state = "DD_ON")
-- 4) App1 and App2 are registered (HMI level NONE)
-- 5) App1 is activated (HMI level FULL)
-- SDL does:
--  - Send OnDriverDistraction notification to mobile App1 with "lockScreenDismissalEnabled"=false
--    and without "lockScreenDismissalWarning" parameters
-- 6) Policy Table update ("lock_screen_dismissal_enabled" = true)
-- SDL does:
--  - Send OnDriverDistraction(DD_ON) notification to mobile App1 with both "lockScreenDismissalEnabled"=true
--    and "lockScreenDismissalWarning" parameters
-- 7) App2 is activated(HMI level FULL)
-- SDL does:
--  - Send OnDriverDistraction(DD_ON) notification to mobile App2 with both "lockScreenDismissalEnabled"=true
--    and "lockScreenDismissalWarning" parameters
-- 8) HMI sends OnDriverDistraction notifications with state=DD_OFF and then with state=DD_ON one by one
-- SDL does:
--  - Resend OnDriverDistraction(DD_OFF) notification to both mobile apps without both "lockScreenDismissalEnabled"
--    and "lockScreenDismissalWarning" parameters
--  - Resend OnDriverDistraction(DD_ON) notification to both mobile apps with both "lockScreenDismissalEnabled"=true
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
local function ptUpdate(pPT)
  pPT.policy_table.module_config.lock_screen_dismissal_enabled = lockScreenDismissalEnabled
end

local function updatePreloadedPT(pLockScreenDismissalEnabled)
  local function updatePT(pPT)
    pPT.policy_table.functional_groupings["Base-4"].rpcs.OnDriverDistraction.hmi_levels = { "FULL", "LIMITED", "BACKGROUND"}
  end
  common.updatePreloadedPT(pLockScreenDismissalEnabled, updatePT)
end

local function ptuWithOnDD()
  common.expOnDriverDistraction("DD_ON", lockScreenDismissalEnabled, 1)
  common.getMobileSession(2):ExpectNotification("OnDriverDistraction")
  :Times(0)
  common.policyTableUpdate(ptUpdate)
end

local function activateApp(pAppIdExpect, pAppIdNotExpect, pLockScreenDismissalEnabledValue)
  common.expOnDriverDistraction("DD_ON", pLockScreenDismissalEnabledValue, pAppIdExpect)
  common.getMobileSession(pAppIdNotExpect):ExpectNotification("OnDriverDistraction")
  :Times(0)
  common.activateApp(pAppIdExpect)
end

local function onDriverDistractionTwoApps(pLockScreenDismissalEnabled)
  local function msg(pValue)
    return "Parameter `lockScreenDismissalEnabled` is transfered to Mobile with `" .. tostring(pValue) .. "` value"
  end
  common.getHMIConnection():SendNotification("UI.OnDriverDistraction", { state = "DD_OFF" })
  common.getHMIConnection():SendNotification("UI.OnDriverDistraction", { state = "DD_ON" })
  common.getMobileSession():ExpectNotification("OnDriverDistraction",
    { state = "DD_OFF" },
    { state = "DD_ON", lockScreenDismissalEnabled = pLockScreenDismissalEnabled })
  :ValidIf(function(e, d)
      if e.occurences == 1 and d.payload.lockScreenDismissalEnabled ~= nil then
        return false, d.payload.state .. ": " .. msg(d.payload.lockScreenDismissalEnabled)
      end
      return true
    end)
  :ValidIf(function(e, d)
      if e.occurences == 2 and pLockScreenDismissalEnabled == nil and d.payload.lockScreenDismissalEnabled ~= nil then
        return false, d.payload.state .. ": " .. msg(d.payload.lockScreenDismissalEnabled)
      end
      return true
    end)
  :Times(2)

  common.getMobileSession(2):ExpectNotification("OnDriverDistraction",
    { state = "DD_OFF" },
    { state = "DD_ON", lockScreenDismissalEnabled = pLockScreenDismissalEnabled })
  :ValidIf(function(e, d)
      if e.occurences == 1 and d.payload.lockScreenDismissalEnabled ~= nil then
        return false, d.payload.state .. ": " .. msg(d.payload.lockScreenDismissalEnabled)
      end
      return true
    end)
  :ValidIf(function(e, d)
      if e.occurences == 2 and pLockScreenDismissalEnabled == nil and d.payload.lockScreenDismissalEnabled ~= nil then
        return false, d.payload.state .. ": " .. msg(d.payload.lockScreenDismissalEnabled)
      end
      return true
    end)
  :Times(2)
end

local function onDriverDistraction()
  common.getHMIConnection():SendNotification("UI.OnDriverDistraction", { state = "DD_ON" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Set LockScreenDismissalEnabled", updatePreloadedPT, { false })
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("onDriverDistraction DD_ON", onDriverDistraction)
runner.Step("Register App1", common.registerAppWOPTU, { 1 })
runner.Step("Register App2", common.registerApp, { 2 })
runner.Step("App1 activation HMI level FULL", activateApp, { 1, 2, false })

runner.Title("Test")
runner.Step("Policy Table Update", ptuWithOnDD)
runner.Step("App2 activation HMI level FULL", activateApp, { 2, 1, lockScreenDismissalEnabled })
runner.Step("OnDriverDistraction ON/OFF true", onDriverDistractionTwoApps, { lockScreenDismissalEnabled })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
