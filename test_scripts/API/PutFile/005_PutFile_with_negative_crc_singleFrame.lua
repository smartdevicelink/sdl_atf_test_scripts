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
-- 1. Mobile application sends a PutFile "Single Frame" with a negative (not valid) checksum to the SDL.
-- SDL does:
-- 1. SDL receive putfile “Single Frame” and counted checksum from the Mobile app and respond with result code "INVALID_DATA"
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/PutFile/commonPutFile')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local usedFile = "./files/binaryFile"

local paramsIncorrSum = common.putFileParams()
paramsIncorrSum.crc = - common.getCheckSum(usedFile)

local corrDataResult = {
  success = false,
  resultCode = "INVALID_DATA",
}

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration with iconResumed = false", common.registerApp)

runner.Title("Test")
runner.Step("Upload file with negative checksum", common.putFile, {paramsIncorrSum, usedFile, corrDataResult})

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
