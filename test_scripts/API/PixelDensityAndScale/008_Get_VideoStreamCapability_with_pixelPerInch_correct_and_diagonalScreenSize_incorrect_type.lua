---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0179-pixel-density-and-scale.md
-- Description:
-- In case:
-- 1) During start HMI provides VideoStreamingCapability for parameters: "pixelPerInch = 111.11" correct and
--    "diagonalScreenSize = abc" incorrect value
-- 2) Mob app sends GetSystemCapability request to SDL
-- SDL does:
-- 1) send response videoStreamingCapability to Mobile with default value for "scale, pixelPerInch, diagonalScreenSize"
-- from HMI capability
---------------------------------------------------------------------------------------------------
-- [[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/PixelDensityAndScale/commonPixelDensity')

-- [[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local diagonalScreenSize = "abc"
local pixelPerInch = 111.11
local scale = nil

local hmiValues = common.updateHMIValue( diagonalScreenSize, pixelPerInch, scale )
local hmiCapabilities = common.readHmiCapabilities()

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { hmiValues })
runner.Step("RAI", common.registerAppWOPTU)
runner.Step("Activate App", common.activateApp)

-- [[ Test ]]
runner.Title("Test")
runner.Step("Get Capability", common.getSystemCapability,
    { hmiCapabilities.diagonalScreenSize, hmiCapabilities.pixelPerInch, hmiCapabilities.scale })

-- [[ Postconditions ]]
runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
