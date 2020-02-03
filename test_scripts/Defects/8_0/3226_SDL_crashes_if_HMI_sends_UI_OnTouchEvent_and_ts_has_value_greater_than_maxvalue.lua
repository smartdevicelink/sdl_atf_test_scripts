---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/3226
---------------------------------------------------------------------------------------------------
-- Description: SDL crashes when the HMI sends UI.OnTouchEvent
--   with the 'ts' param has a value greater than maxvalue (not valid)
--
-- In case:
-- 1. Navi_app is registered and activated
-- 2. OnTouchEventOnlyGroup is allowed by policies
-- 3. HMI sends UI.OnTouchEvent with the 'ts' param has a value greater than maxvalue (not valid)
--
-- SDL does:
--  - not transfer OnTouchEvent notification to the application
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('user_modules/sequences/actions')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.application1.registerAppInterfaceParams.appHMIType = { "NAVIGATION" }
config.application1.registerAppInterfaceParams.isMediaApplication = false
config.ExitOnCrash = false

--[[ Local Variables ]]
local maxTsValue = 2147483647
local onTouchEventParams = {
  type = "BEGIN",
  event = { { c = { { x = 1, y = 1 } }, id = 1, ts = { maxTsValue + 1 } } }
}

--[[ Local Functions ]]
local function ptUpdate(pTbl)
  local appParams = pTbl.policy_table.app_policies[common.app.getPolicyAppId()]
  appParams.AppHMIType = { "NAVIGATION" }
  appParams.groups = { "Base-4", "OnTouchEventOnlyGroup" }
end

local function OnTouchEvent()
  common.mobile.getSession():ExpectNotification("OnTouchEvent", onTouchEventParams):Times(0)
  common.hmi.getConnection():SendNotification("UI.OnTouchEvent", onTouchEventParams)
  common.run.runAfter(function()
      if not common.sdl.isRunning() then common.run.fail("SDL crashed") end
    end,
    common.timeout)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, init HMI, connect Mobile", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("PolicyTableUpdate with HMI types", common.policyTableUpdate, { ptUpdate })
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("HMI sends UI.OnTouchEvent with the 'ts' param has a value greater than maxvalue", OnTouchEvent)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
