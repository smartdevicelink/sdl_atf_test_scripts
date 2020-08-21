---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0248-hmi-ptu-support.md
-- Issue:https://github.com/smartdevicelink/sdl_core/issues/3279

-- Description: Check that PTU is successfully performed via HMI

-- In case:
-- 1. No app is registered
-- 2. And 'Exchange after X ignition cycles' PTU trigger occurs
-- SDL does:
--   a) Start new PTU sequence through HMI:
--      - Send 'BC.PolicyUpdate' request to HMI
--      - Send 'SDL.OnStatusUpdate(UPDATE_NEEDED)' notification to HMI
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Policies/HMI_PTU/common_hmi_ptu')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
runner.testSettings.restrictions.sdlBuildOptions = { { extendedPolicy = { "PROPRIETARY", "EXTERNAL_PROPRIETARY" } } }

--[[ Local Variables ]]
local cycles = 3

--[[ Local Functions ]]
local function updFunc(pTbl)
  pTbl.policy_table.module_config.exchange_after_x_ignition_cycles = cycles
end

local function ignitionOnNoPTU()
  common.start()
  common.hmi():ExpectRequest("BasicCommunication.PolicyUpdate")
  :Times(0)
  common.hmi():ExpectNotification("SDL.OnStatusUpdate")
  :Times(0)
end

local function ignitionOnWithPTU()
  common.start()
  common.hmi():ExpectRequest("BasicCommunication.PolicyUpdate")
  :Do(function(_, data)
      common.hmi():SendResponse(data.id, data.method, "SUCCESS", { })
    end)
  common.hmi():ExpectNotification("SDL.OnStatusUpdate", { status = "UPDATE_NEEDED" }, { status = "UPDATING" })
  :Times(2)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Clear HMICapabilitiesCacheFile parameter in INI file",
  common.setSDLIniParameter, {"HMICapabilitiesCacheFile", ""})
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.registerApp)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("HMI PTU Successful", common.ptuViaHMI, { updFunc })
runner.Step("Ignition Off", common.ignitionOff)
runner.Step("Ignition On without PTU", ignitionOnNoPTU)
runner.Step("Ignition Off", common.ignitionOff)
runner.Step("Ignition On without PTU", ignitionOnNoPTU)
runner.Step("Ignition Off", common.ignitionOff)
runner.Step("New HMI PTU on Ignition cycles trigger", ignitionOnWithPTU)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
