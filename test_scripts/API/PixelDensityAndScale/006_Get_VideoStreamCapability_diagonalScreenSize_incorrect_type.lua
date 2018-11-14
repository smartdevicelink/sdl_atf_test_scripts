---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0179-pixel-density-and-scale.md
-- Description:
-- In case:
-- 1) Update hmiCapabilities for videoStreamingCapability param: diagonalScreenSize - incorrect type
-- 2) Mob app sends GetSystemCapability request to SDL
-- SDL does:
-- 1) Send response to Mobile with default value for "scale, pixelPerInch, diagonalScreenSize"
---------------------------------------------------------------------------------------------------
-- [[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/PixelDensityAndScale/commonPixelDensity')
local hmi_values = require('user_modules/hmi_values')

-- [[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local hmiValues = hmi_values.getDefaultHMITable()

local diagonalScreenSize = "abc"
local pixelPerInch = nil
local scale = nil

local function updateHMIValue(pDiagonalSize, pPixelPerInch, pScale)
    hmiValues.UI.GetCapabilities.params.systemCapabilities.videoStreamingCapability.diagonalScreenSize = pDiagonalSize
    hmiValues.UI.GetCapabilities.params.systemCapabilities.videoStreamingCapability.pixelPerInch = pPixelPerInch
    hmiValues.UI.GetCapabilities.params.systemCapabilities.videoStreamingCapability.scale = pScale
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Update HMI Capabilities", updateHMIValue, { diagonalScreenSize, pixelPerInch, scale })
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { hmiValues })
runner.Step("RAI", common.registerApp)
runner.Step("Activate App", common.activateApp)

-- [[ Test ]]
runner.Title("Test")
runner.Step("Get Capability", common.getSystemCapability,
    { common.defaultValue.diagonalScreenSize, common.defaultValue.pixelPerInch, common.defaultValue.scale })

-- [[ Postconditions ]]
runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
