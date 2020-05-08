---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0179-pixel-density-and-scale.md
-- Description:
-- In case:
-- 1) During start HMI doesn't send VideoStreamingCapability value for parameters: "scale, pixelPerInch,
--    diagonalScreenSize"
-- 2) Mob app sends GetSystemCapability request to SDL
-- SDL does:
-- 1) send response with videoStreamingCapability to Mobile without parameters: scale, pixelPerInch, diagonalScreenSize
---------------------------------------------------------------------------------------------------
-- [[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/PixelDensityAndScale/commonPixelDensity')

-- [[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local diagonalScreenSize = nil
local pixelPerInch = nil
local scale = nil

local hmiValues = common.getUpdatedHMIValues(diagonalScreenSize, pixelPerInch, scale)

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { hmiValues })
runner.Step("RAI", common.registerAppWOPTU)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("Get Capability", common.getSystemCapability, { nil, nil, nil })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
