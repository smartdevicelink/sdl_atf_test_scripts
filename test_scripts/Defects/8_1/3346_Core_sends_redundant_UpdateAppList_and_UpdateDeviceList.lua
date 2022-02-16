---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/3346
---------------------------------------------------------------------------------------------------
-- Description: SDL Core sends redundant UpdateAppList and UpdateDeviceList
--
-- Steps:
-- 1. Connect TCP app while bluetooth transport is available
--
-- SDL does:
--  - Send UpdateAppList only when a new app is connected
---------------------------------------------------------------------------------------------------

require('atf.util')

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("user_modules/sequences/actions")
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
local utils = require("user_modules/utils")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function checkAppListUpdates()
    utils.cprint(35, "Watching for app/device list updates...")

    local previousAppList = nil
    local duplicateAppUpdates = 0
    common.getHMIConnection():ExpectRequest("BasicCommunication.UpdateAppList"):Times(AnyNumber())
        :ValidIf(function(_, data)
            local appList = data.params.applications

            local isDifferent = true
            if previousAppList ~= nil then
                isDifferent = not compareValues(appList, previousAppList, "applications")
            end

            if isDifferent then duplicateAppUpdates = duplicateAppUpdates + 1 else duplicateAppUpdates = 0 end
            previousAppList = appList
            local info = "Duplicate app list updates were received"
            local isValid = duplicateAppUpdates <= 1 --Workaround, sometimes a single duplicate app list update 
                                                     --can happen when a new app connects

            return isValid, (not isValid) and info or nil
        end)

    local previousDeviceList = nil
    common.getHMIConnection():ExpectRequest("BasicCommunication.UpdateDeviceList"):Times(AnyNumber())
        :ValidIf(function(_, data)
            local deviceList = data.params.deviceList

            local isValid = true
            if previousDeviceList ~= nil then
                isValid = not compareValues(deviceList, previousDeviceList, "deviceList")
            end
            previousDeviceList = deviceList

            local info = "Duplicate device list updates were received"
            return isValid, (not isValid) and info or nil
        end)

    commonTestCases:DelayedExp(60000)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerAppWOPTU)

runner.Title("Test")
runner.Step("Check for redundant app or device list updates", checkAppListUpdates)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
