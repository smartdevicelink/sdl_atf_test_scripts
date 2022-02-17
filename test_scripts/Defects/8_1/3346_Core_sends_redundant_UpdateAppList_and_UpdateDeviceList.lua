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

            --Workaround, sometimes a single duplicate app list update can happen when a new app connects
            if duplicateAppUpdates > 1 then
                return false, "Duplicate app list updates were received"
            else
                return true
            end
        end)

    local previousDeviceList = nil
    common.getHMIConnection():ExpectRequest("BasicCommunication.UpdateDeviceList"):Times(AnyNumber())
        :ValidIf(function(_, data)
            local deviceList = data.params.deviceList

            local isDifferent = true
            if previousDeviceList ~= nil then
                isDifferent = not compareValues(deviceList, previousDeviceList, "deviceList")
            end
            previousDeviceList = deviceList

            if isDifferent then
                return true
            else
                return false, "Duplicate device list updates were received"
            end
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
