---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0041-appicon-resumption.md
-- User story:TBD
-- Use case:TBD
--
-- Requirement summary:
-- TBD
--
-- Description:
-- In case:
-- 1) SDL, HMI are started.
-- 2) Mobile app is registered. Sends  PutFile and invalid SetAppIcon requests.
-- 3) Mobile App received response SetAppIcon(INVALID_DATA). Custom Icon is not set.
-- 4) App is re-registered.
-- SDL does:
-- 1) Successfully register application.
-- 2) Register an app successfully, respond to RAI with result code "SUCCESS", "iconResumed" = false.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/SetAppIcon/commonIconResumed')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local requestParams = {
  syncFileName = "123" --invalid type of parameter
}

local function setAppIcon_INVALID_DATA(params)
  local mobSession = common.getMobileSession()
  local cid = mobSession:SendRPC("SetAppIcon", params)
  EXPECT_HMICALL("UI.SetAppIcon", params.requestUiParams)
  :Times(0)
  mobSession:ExpectResponse(cid, { success = false, resultCode = "INVALID_DATA" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)

runner.Title("Test")
runner.Step("App registration with iconResumed = false", common.registerAppWOPTU, { 1, false })
runner.Step("Upload icon file", common.putFile)
runner.Step("Gets_INVALID_DATA", setAppIcon_INVALID_DATA, { requestParams } )
runner.Step("App unregistration", common.unregisterAppInterface, { 1 })
runner.Step("App registration with iconResumed = false", common.registerAppWOPTU, { 1, false, true })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
