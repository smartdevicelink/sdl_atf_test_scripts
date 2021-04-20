---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0037-Expand-Mobile-putfile-RPC.md
-- User story:TBD
-- Use case:TBD
--
-- Requirement summary:
-- TBD
--
-- Description:
-- In case:
-- 1. The mobile application sends a putfile “Single Frame” with a more than maxvalue (not valid) checksum to the SDL.
-- 2. The mobile application sends a putfile “Multiple Frame” with a more than maxvalue (not valid) checksum to the SDL.
-- SDL does:
-- 1. SDL receives putfile “Single Frame” and counted checksum from the Mobile app and respond with result code "INVALID_DATA"
-- 2. SDL receives putfile “Multiple Frame” and counted checksum from the Mobile app and respond with result code "INVALID_DATA"
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/PutFile/commonPutFile')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local usedFileSingleFrame = "./files/binaryFile"
local usedFileMultiFrame = "./files/png_1211kb.png"

local paramsIncorrSum = common.putFileParams()
paramsIncorrSum.crc = 4294967296

local invalidDataResult = {
  success = false,
  resultCode = "INVALID_DATA"
}

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration with iconResumed = false", common.registerApp)

runner.Title("Test")
runner.Step("Upload file as single frame with with crc more than maxvalue", common.putFile,
  {paramsIncorrSum, usedFileSingleFrame, invalidDataResult})
runner.Step("Upload file as multiple frame with with crc more than maxvalue", common.putFile,
  {paramsIncorrSum, usedFileMultiFrame, invalidDataResult})

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
