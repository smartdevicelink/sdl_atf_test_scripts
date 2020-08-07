---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0152-driver-distraction-list-limits.md
-- Description:
-- In case:
-- 1) Mobile requests SystemCapability type DRIVER_DISTRACTION
-- SDL does:
-- 1) Send GetSystemCapability Response with submenuDepth and menuLength limitations
---------------------------------------------------------------------------------------------------
-- [[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Smoke/commonSmoke')

-- [[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local requestParams = {
    systemCapabilityType = "DRIVER_DISTRACTION"
}

local responseParams = {
    systemCapability = {
        systemCapabilityType="DRIVER_DISTRACTION",
        driverDistractionCapability = {
            subMenuDepth = 3,
            menuLength = 10
        }
    },
    success = true,
    resultCode = "SUCCESS"
}
 
local function GetDriverDistractionCapability()
    local cid = common.getMobileSession():SendRPC("GetSystemCapability", requestParams)
    common.getMobileSession():ExpectResponse(cid, responseParams)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerApp)

runner.Title("Test")
runner.Step("App activate, HMI SystemContext MAIN", common.activateApp)
runner.Step("Get Driver Distraction Capability", GetDriverDistractionCapability)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
