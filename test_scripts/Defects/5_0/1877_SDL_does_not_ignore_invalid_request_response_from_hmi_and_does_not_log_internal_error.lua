---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_core/issues/1877
--
-- Description:
-- SDL does not ignore invalid request/response from HMI and does not log internal error
-- In case:
-- 1) HMI sends ActivateApp with fake param and invalid appID param
-- Expected result:
-- 1) SDL cuts off fake parameters, log the corresponding error and respond with 'INVALID_DATA' to HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('user_modules/sequences/actions')
local runner = require('user_modules/script_runner')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function activateApp()
    local requestId = common.getHMIConnection():SendRequest("SDL.ActivateApp", { appID = "12345", fakeParam = "fakeParam" })
    common.getHMIConnection():ExpectResponse(requestId, { error = { code = 11 } })

    common.getMobileSession():ExpectNotification("OnHMIStatus")
    :Times(0)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)

-- [[ Test ]]
runner.Step("ActivateApp with fake param and invalid appID", activateApp)

-- [[ Postconditions ]]
runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
