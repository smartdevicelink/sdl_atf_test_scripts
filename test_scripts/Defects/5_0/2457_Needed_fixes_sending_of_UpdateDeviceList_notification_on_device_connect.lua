---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_core/issues/2381
--
-- Precondition:
-- SDL Core and HMI are started. App is registered, HMI level = FULL
-- Description:
-- Steps to reproduce:
-- 1) SDL currently notifies system by using another transport listener API - OnDeviceAdded/OnDeviceRemoved.
-- Expected:
-- 1) SDL has to notify system with BC.UpdateDeviceList on device connect even if device does not have any SDL-enabled applications running.
---------------------------------------------------------------------------------------------------
-- [[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('user_modules/sequences/actions')
local utils = require("user_modules/utils")
local events = require("events")
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local test = require("user_modules/dummy_connecttest")

-- [[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

-- [[ Local function ]]
local function allowSDL(self)
    common.getHMIConnection():SendNotification("SDL.OnAllowSDLFunctionality", {
        allowed = true,
        source = "GUI",
        device = {
        id = utils.getDeviceMAC(),
        name = utils.getDeviceName()
        }
    })
end

local function start(pHMIParams)
    local event = events.Event()
    event.matches = function(e1, e2) return e1 == e2 end
    test:runSDL()
    commonFunctions:waitForSDLStart(test)
    :Do(function()
        test:initHMI()
        :Do(function()
            utils.cprint(35, "HMI initialized")
            test:initHMI_onReady(pHMIParams)
            :Do(function()
                utils.cprint(35, "HMI is ready")
                common.getHMIConnection():ExpectNotification("BasicCommunication.UpdateDeviceList")
                common.getHMIConnection():ExpectNotification("OnDeviceAdded")
                :Times(0)
                test:connectMobile()
                :Do(function()
                    utils.cprint(35, "Mobile connected")
                    allowSDL(test)
                    common.getHMIConnection():RaiseEvent(event, "Start event")
                end)
            end)
        end)
    end)
    return common.getHMIConnection():ExpectEvent(event, "Start event")
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)

-- [[ Test ]]
runner.Title("Test")
runner.Step("Start SDL, HMI, connect Mobile, start Session", start)

-- [[ Postconditions ]]
runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)