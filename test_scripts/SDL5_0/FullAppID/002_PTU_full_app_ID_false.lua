---------------------------------------------------------------------------------------------
-- Script verifies that a PT snapshot contains the correct full_app_id_supported flag
-- Supports PROPRIETARY
---------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local actions = require("user_modules/sequences/actions")

local common = require("test_scripts/SDL5_0/FullAppID/common")

local full_app_id_supported = "false"

-- This is the id in the policy table
common.policy_app_id = config.application1.registerAppInterfaceParams.fullAppID

-- copy the fullAppID field to appID and remove full app id
config.application1.registerAppInterfaceParams.appID = config.application1.registerAppInterfaceParams.fullAppID
config.application1.registerAppInterfaceParams.fullAppID = nil


runner.Title("Preconditions " .. full_app_id_supported)
-- Stop SDL if process is still running, delete local policy table and log files
runner.Step("Clean environment", common.preconditions)
runner.Step("Set UseFullAppID to true", actions.setSDLIniParameter, {"UseFullAppID", full_app_id_supported})
-- Start SDL and HMI, establish connection between SDL and HMI, open mobile connection via TCP
runner.Step("Start SDL, HMI, connect Mobile", common.start)
-- Pring in terminal build options(RC status and policy slow)
runner.Step("SDL Configuration", common.printSDLConfig)

runner.Title("Test " .. full_app_id_supported)
-- create mobile session, register application, perform PTU wit PT
runner.Step("RAI, PTU", common.raiPTU)
-- Check that PTU is performed successful
runner.Step("Check Status", common.checkPTUStatus)

runner.Title("Postconditions " .. full_app_id_supported)
runner.Step("Restore ini and stop SDL", common.postconditions)
