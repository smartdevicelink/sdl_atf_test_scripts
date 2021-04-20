---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0119-SDL-passenger-mode.md
-- Description:
-- In case:
-- 1) OnDriverDistraction notification is  allowed by Policy for (FULL, LIMITED, BACKGROUND, NONE) HMILevel
-- 2) In Policy:
--  - "lock_screen_dismissal_enabled" parameter is defined with correct value (true)
--  - there is non-empty value in "LockScreenDismissalWarning" section for 'DE-DE' language
-- 3) App registered (HMI level NONE) with 'DE-DE' language
-- 4) HMI sends OnDriverDistraction notifications with state=DD_OFF and then with state=DD_ON one by one
-- SDL does:
--  - Send OnDriverDistraction(DD_OFF) notification to mobile without both "lockScreenDismissalEnabled"
--    and "lockScreenDismissalWarning" parameters and all mandatory fields
--  - Send OnDriverDistraction(DD_ON) notification to mobile with both "lockScreenDismissalEnabled"=true
--    and "lockScreenDismissalWarning" parameters and all mandatory fields
--    and message text is correspond to app's language 'DE-DE'
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/SDL_Passenger_Mode/commonPassengerMode')
local hmi_values = require('user_modules/hmi_values')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local lockScreenDismissalEnabled = true
common.language = "DE-DE"

--[[ Local Functions ]]
local function updatePreloadedPT()
  local function updatePT(pPT)
    local langs = pPT.policy_table.consumer_friendly_messages.messages["LockScreenDismissalWarning"].languages
    langs[string.lower(common.language)] = {
      textBody = "Wischen Sie zum Entlassen nach oben"
    }
  end
  common.updatePreloadedPT(lockScreenDismissalEnabled, updatePT)
end

local function updateAppConfig()
  common.getConfigAppParams().languageDesired = common.language
  common.getConfigAppParams().hmiDisplayLanguageDesired = common.language
end

local function getHMIParams()
  local hmiParams = hmi_values.getDefaultHMITable()
  for _, iface in pairs({ "UI", "VR", "TTS" }) do
    hmiParams[iface].GetLanguage.params.language = common.language
  end
  return hmiParams
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Set language for App", updateAppConfig)
runner.Step("Set LockScreenDismissalEnabled", updatePreloadedPT)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { getHMIParams() })
runner.Step("Register App", common.registerAppWOPTU)
runner.Step("Activate App to FULL", common.activateApp)

runner.Title("Test")
runner.Step("OnDriverDistraction OFF true", common.onDriverDistraction, { "DD_OFF", lockScreenDismissalEnabled })
runner.Step("OnDriverDistraction ON true", common.onDriverDistraction, { "DD_ON", lockScreenDismissalEnabled })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
