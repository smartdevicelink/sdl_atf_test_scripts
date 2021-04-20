--------------------------------------------------------------------------------
-- Script verifies issue: 
-- https://github.com/smartdevicelink/sdl_core/issues/1035

-- Pre-conditions:
-- 1. SDL is started
-- 2. HMI is started
-- 3. App is in "FULL" HMI Level.

-- Steps to reproduce:
-- 1. Send "OnDeactivate notification send = true" from HMI
-- 2. send SDL.ActivateApp from HMI

-- Expected:
-- SDL should send "REJECTED" code to HMI when HMI is active;
-- SDL should send "SUCCESS" code to HMI when HMI isn't active.
--------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Defects/commonDefects')

--[[ Test Configuration ]]
runner.testSettings.restrictions.sdlBuildOptions = { { extendedPolicy = { "PROPRIETARY", "EXTERNAL_PROPRIETARY" } } }

--[[ Local Variables ]]
local kRejected = 4
local kSuccess = 0

--[[ Local Functions ]]
local function deactivateHmi(state, self)
    self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged", 
        {eventName="DEACTIVATE_HMI",isActive = state})
end

local function activateApp(expectedCode, self)
    local requestId = self.hmiConnection:SendRequest("SDL.ActivateApp", 
        { appID = common.getHMIAppId(1) })
    EXPECT_HMIRESPONSE(requestId)
    :ValidIf(function(_, data)
        local actualCode = 
            (data.error ~= nil and data.error.code or data.result.code)
        if(expectedCode == actualCode) then
            return true
        end
        return false, "Expected value:" .. tostring(expectedCode) .. 
            "\nActual value: " .. tostring(actualCode)
    end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI, PTU", common.rai_ptu)
runner.Step("Activate App", activateApp, { kSuccess })

runner.Title("Test")
runner.Step("Deactivate HMI", deactivateHmi, { true })
runner.Step("Rejected activation", activateApp, { kRejected })
runner.Step("Activate HMI", deactivateHmi, { false })
runner.Step("ActivateApp", activateApp, { kSuccess })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
