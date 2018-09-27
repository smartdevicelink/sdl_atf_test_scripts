---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_core/issues/2467
--
-- Description:
-- Policy table corupted after first ign cycle.
-- Precondition:
-- 1) SDL and HMI are started.
-- Step to reproduce:
-- 1) Register and Activate app.
-- 2) Perform PTU.
-- 3) Make Ign_off-on cycle.
-- 4) Register app.
-- Expected result:
-- Permissions should not be lost.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('user_modules/sequences/actions')
local runner = require('user_modules/script_runner')
local utils = require("user_modules/utils")
local test = require("user_modules/dummy_connecttest")
local sdl = require("SDL")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function cleanSessions()
    test.mobileSession[1] = nil
    utils.wait()
end

local function pTUpdateFunc(tbl)
    tbl.policy_table.app_policies[config.application1.registerAppInterfaceParams.fullAppID].groups = { "Base-4", "SendLocation" }
end

local function sendLocation()
    local cid = common.getMobileSession():SendRPC("SendLocation", { 
        longitudeDegrees = 1.1,
        latitudeDegrees = 1.1
     })
    common.getHMIConnection():ExpectRequest("Navigation.SendLocation")
    :Do(function(_, data)
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS",{})
    end)
    common.getMobileSession():ExpectResponse(cid, { success = true , resultCode = "SUCCESS" })
end

local function ignitionOff()
    common.getHMIConnection():SendNotification("BasicCommunication.OnExitAllApplications", { reason = "SUSPEND" })
    common.getHMIConnection():ExpectNotification("BasicCommunication.OnSDLPersistenceComplete")
    :Do(function()
        sdl:DeleteFile()
        common.getHMIConnection():SendNotification("BasicCommunication.OnExitAllApplications", { reason = "IGNITION_OFF" })
        common.getMobileSession():ExpectNotification("OnAppInterfaceUnregistered", { reason = "IGNITION_OFF" })
        common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered", { unexpectedDisconnect = false })
        common.getHMIConnection():ExpectNotification("BasicCommunication.OnSDLClose")
        :Do(function()
            StopSDL()
        end)
    end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("PTU", common.policyTableUpdate, { pTUpdateFunc })
runner.Step("Activate App", common.activateApp)
runner.Step("Send Location", sendLocation)
runner.Step("IGNITION_OFF", ignitionOff)
runner.Step("Clean sessions", cleanSessions)

-- [[ Test ]]
runner.Step("IGNITION_ON", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Send Location after IGNITION_ON", sendLocation)


-- [[ Postconditions ]]
runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
