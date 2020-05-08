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
-- Mobile application sends a PutFile "Multiple Frame" without parameter “crc” to the SDL.
-- SDL does:
-- Receive PutFile without parameter “crc”, upload data and respond with resultCode: "SUCCESS"
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/PutFile/commonPutFile')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local usedFile = "./files/icon.png"

local params = common.putFileParams()

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerApp)

runner.Title("Test")
runner.Step("Upload file without checksum", common.putFile, {params, usedFile})

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
