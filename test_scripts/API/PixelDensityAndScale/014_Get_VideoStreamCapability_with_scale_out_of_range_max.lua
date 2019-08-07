---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0179-pixel-density-and-scale.md
-- Description:
-- In case:
-- 1) During start HMI provides VideoStreamingCapability for 'scale' parameter = 10.01 - out of range value
-- 2) Mob app sends GetSystemCapability request to SDL
-- SDL does:
-- 1) send response with videoStreamingCapability to Mobile with default value for "scale, pixelPerInch,
--    diagonalScreenSize" from HMI capability
---------------------------------------------------------------------------------------------------
-- [[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/PixelDensityAndScale/commonPixelDensity')

-- [[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local diagonalScreenSize = nil
local pixelPerInch = nil
local scale = 10.01

local hmiValues = common.getUpdatedHMIValues(diagonalScreenSize, pixelPerInch, scale)
local hmiDefaultValues = common.hmiDefaultValues()

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { hmiValues })
runner.Step("RAI", common.registerAppWOPTU)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("Get Capability", common.getSystemCapability,
  { hmiDefaultValues.diagonalScreenSize, hmiDefaultValues.pixelPerInch, hmiDefaultValues.scale })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
