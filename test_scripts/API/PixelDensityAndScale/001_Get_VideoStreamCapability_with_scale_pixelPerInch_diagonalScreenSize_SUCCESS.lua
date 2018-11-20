---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0179-pixel-density-and-scale.md
-- Description:
-- In case:
-- 1) During start HMI provides VideoStreamingCapability for parameters: "diagonalScreenSize, pixelPerInch, scale"
-- 2) Mob app sends GetSystemCapability request to SDL
-- SDL does:
-- 1) send response videoStreamingCapability to Mobile with value for "scale, pixelPerInch, diagonalScreenSize"
--    that HMI provied
---------------------------------------------------------------------------------------------------
-- [[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/PixelDensityAndScale/commonPixelDensity')
local hmi_values = require('user_modules/hmi_values')

-- [[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Function]]
local function getDefaultHMIValue()
  local hmiValues = hmi_values.getDefaultHMITable()
  local hmiDefaultValues = {
    diagonalScreenSize = hmiValues.UI.GetCapabilities.params.systemCapabilities.videoStreamingCapability.diagonalScreenSize,
    pixelPerInch = hmiValues.UI.GetCapabilities.params.systemCapabilities.videoStreamingCapability.pixelPerInch,
    scale = hmiValues.UI.GetCapabilities.params.systemCapabilities.videoStreamingCapability.scale
  }
  return hmiDefaultValues
end

local defaultHMIValue = getDefaultHMIValue()

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.registerAppWOPTU)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("Get Capability", common.getSystemCapability, {
  defaultHMIValue.diagonalScreenSize, defaultHMIValue.pixelPerInch, defaultHMIValue.scale
})

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
