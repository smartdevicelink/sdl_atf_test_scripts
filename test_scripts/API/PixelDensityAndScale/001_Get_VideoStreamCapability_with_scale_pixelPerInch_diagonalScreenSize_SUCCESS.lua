---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0179-pixel-density-and-scale.md
-- Description:
-- In case:
-- 1) During start HMI provides VideoStreamingCapability for parameters: "diagonalScreenSize, pixelPerInch, scale"
-- 2) Mob app sends GetSystemCapability request to SDL
-- SDL does:
-- 1) send response videoStreamingCapability to Mobile with default value for "scale, pixelPerInch, diagonalScreenSize"
---------------------------------------------------------------------------------------------------
-- [[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/PixelDensityAndScale/commonPixelDensity')

-- [[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.registerAppWOPTU)
runner.Step("Activate App", common.activateApp)

-- [[ Test ]]
runner.Title("Test")
runner.Step("Get Capability", common.getSystemCapability,
    { common.diagonalScreenSize, common.defaultValue.pixelPerInch, common.defaultValue.scale })

-- [[ Postconditions ]]
runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
