---------------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")
local runner = require('user_modules/script_runner')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.defaultProtocolVersion = 3

--[[ Shared Functions ]]
local common = {}
common.Title = runner.Title
common.Step = runner.Step
common.preconditions = actions.preconditions
common.postconditions = actions.postconditions
common.start = actions.start
common.stopSDL = actions.sdl.stop
common.getHMIConnection = actions.hmi.getConnection
common.registerApp = actions.registerApp
common.activateApp = actions.activateApp
common.getMobileSession = actions.getMobileSession
common.setSDLIniParameter = actions.sdl.setSDLIniParameter
common.getConfigAppParams = actions.getConfigAppParams

return common
