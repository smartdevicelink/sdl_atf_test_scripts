---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/2468
---------------------------------------------------------------------------------------------------
-- Use case: AddCommand
-- Item: Failure from VR portion of request
--
-- Requirement summary:
-- [AddCommand] REJECTED: Getting REJECTED on VR.AddCommand
--
-- Description:
-- Mobile application sends valid AddCommand request with "vrCommands"
-- data and gets "REJECTED" for VR.AddCommand from HMI

-- Pre-conditions:
-- a. HMI and SDL are started
-- b. App is registered and activated on SDL

-- Steps:
-- 1. App requests AddCommand with vrCommands
-- 2. SDL transfers the VR part of request with allowed parameters to HMI
-- 3. SDL receives VR part of response from HMI with "REJECTED" result code

-- Expected:
-- SDL responds with (resultCode: REJECTED, success: false) to mobile application
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Defects/8_2/2468/common')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local vrResponseCode = "REJECTED"

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Update Preloaded PT", common.updatePreloadedPT)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Activate App", common.activateApp)
runner.Step("Upload icon file", common.putFile, { common.putFileParams })

runner.Title("Test")
runner.Step("AddCommand", common.addCommandFailure, { nil, vrResponseCode })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
