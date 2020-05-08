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
-- 1. Mobile application sends a PutFile "Single Frame" with a known counted checksum to the SDL.
-- 2. Mobile application sends a PutFile "Single Frame" with a incorrect counted checksum to the SDL.
-- SDL does:
-- 1. Receive PutFile "Single Frame" and verify the counted checksum from the Mobile app and respond with result code "SUCCESS".
-- 2. Receive PutFile "Single Frame" and verify the counted checksum from the Mobile app and respond with result code "CORRUPTED_DATA".
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/PutFile/commonPutFile')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local usedFile = "./files/binaryFile"

local paramsCorrSum = common.putFileParams()
paramsCorrSum.crc = common.getCheckSum(usedFile)

local paramsIncorrSum = common.putFileParams()
paramsIncorrSum.crc = common.getCheckSum(usedFile) - 100

local corrDataResult = {
  success = false,
  resultCode = "CORRUPTED_DATA",
  info = "CRC Check on file failed. File upload has been cancelled, please retry."
}

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerApp)

runner.Title("Test")
runner.Step("Upload file with correct checksum", common.putFile, {paramsCorrSum, usedFile})
runner.Step("Upload file with incorrect checksum", common.putFile, {paramsIncorrSum, usedFile, corrDataResult})

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
