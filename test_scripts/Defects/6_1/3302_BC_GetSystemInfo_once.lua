---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/3302
--
-- Description: Check that SDL sends BC.GetSystemInfo request once on boot
--
-- Steps:
-- 1. HMI and SDL are started.
-- SDL does:
-- - SDL requests BC.GetSystemInfo one time
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("user_modules/sequences/actions")
local hmi_values = require("user_modules/hmi_values")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function getHMIParams()
  local hmiCaps = hmi_values.getDefaultHMITable()
  hmiCaps.BasicCommunication.GetSystemInfo.mandatory = true
  return hmiCaps
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)

runner.Title("Test")
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { getHMIParams() })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
