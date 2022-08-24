---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/2468
---------------------------------------------------------------------------------------------------
-- Use case: AddCommand
-- Item: Timeout from VR portion of request
--
-- Requirement summary:
-- [AddCommand] GENERIC_ERROR: getting GENERIC_ERROR on VR.AddCommand timeout
--
-- Description:
-- Mobile application sends valid AddCommand request with both "vrCommands" and "menuParams" 
-- data and gets "SUCCESS" for UI.AddCommand and no response for VR.AddCommand from HMI

-- Pre-conditions:
-- a. HMI and SDL are started
-- b. appID is registered and activated on SDL

-- Steps:
-- 1. appID requests AddCommand with both vrCommands and menuParams
-- 2. SDL transfers the UI part of request with allowed parameters to HMI
-- 3. SDL transfers the VR part of request with allowed parameters to HMI
-- 4. SDL receives UI part of response from HMI with "SUCCESS" result code
-- 5. SDL does not receive VR part of response

-- Expected:
-- SDL responds with (resultCode: GENERIC_ERROR, success: false) to mobile application
-- SDL sends UI.DeleteCommand and VR.DeleteCommand based on the original request
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Defects/8_2/2468/common')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Update Preloaded PT", common.updatePreloadedPT)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Activate App", common.activateApp)
runner.Step("Upload icon file", common.putFile, { common.putFileParams })

runner.Title("Test")
runner.Step("AddCommand", common.addCommandTimeout, { true, false })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
