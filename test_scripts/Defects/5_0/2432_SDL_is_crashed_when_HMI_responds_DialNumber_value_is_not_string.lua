---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_core/issues/2432
--
-- Description:
-- SDL is crashed when HMI responds DialNumber(info value is not string)
-- Steps to reproduce:
-- 1) MOB -> SDL:DialNumber()
-- 2) SDL -> BC:DialNumber()
-- 3) BC -> SDL:DialNumber(SUCCESS, info = 1111)
-- Expected:
-- 1) SDL -> MOB:DialNumber(SUCCESS) without "info" parameter.
---------------------------------------------------------------------------------------------------
-- [[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('user_modules/sequences/actions')

-- [[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.ExitOnCrash = false

-- [[ Local variables ]]
local dialNumberParam = {
    number = "#0979801430*,;+"
}

-- [[ Local Functions ]]
local function dialNumber(pParam)
    local cid = common.getMobileSession():SendRPC("DialNumber", pParam)
    common.getHMIConnection():ExpectRequest("BasicCommunication.DialNumber", pParam)
    :Do(function(_, data)
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { info = 1111 })
    end)
    common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
    :ValidIf(function(_, data)
        if data.payload.info then
            return false, "Unexpected parameter 'info' in DialNumber response"
        end
        return true
    end)
end

-- [[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.registerApp)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("Send dial number", dialNumber, { dialNumberParam })

-- [[ Postconditions ]]
runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
