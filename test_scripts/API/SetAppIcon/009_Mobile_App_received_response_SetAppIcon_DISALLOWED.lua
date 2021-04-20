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
-- 2) SetAppIcon does not exist in app's assigned policies after PTU.
-- 3) Mobile app is registered. Sends  PutFile and valid SetAppIcon requests.
-- 4) Mobile app received response SetAppIcon(DISALLOWED)
-- 5) Mobile app is re-registered.
-- SDL does:
-- 1) Register an app successfully, respond to RAI with result code "SUCCESS", "iconResumed" = false.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/SetAppIcon/commonIconResumed')
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local requestParams = {
  syncFileName = "icon.png"
}

--[[ Local Functions ]]
local function setAppIcon_DISALLOWED(params)
  local mobSession = common.getMobileSession()
  local cid = mobSession:SendRPC("SetAppIcon", params)
  EXPECT_HMICALL("UI.SetAppIcon")
  :Times(0)
  mobSession:ExpectResponse(cid, { success = false, resultCode = "DISALLOWED" })
end

local function updatePTU(tbl)
  local CustomGroup = commonFunctions:cloneTable(tbl.policy_table.functional_groupings["Base-4"])
  CustomGroup.rpcs.SetAppIcon = nil
  tbl.policy_table.functional_groupings.GroupWithoutSetAppIcon = CustomGroup
  tbl.policy_table.app_policies[common.getConfigAppParams().fullAppID].groups = { "GroupWithoutSetAppIcon" }
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)

runner.Title("Test")
runner.Step("App registration", common.registerApp, { 1 })
runner.Step("PTU without permissions for SetAppIcon", common.policyTableUpdate, { updatePTU })
runner.Step("Upload icon file", common.putFile)
runner.Step("Mobile App received response SetAppIcon(DISALLOWED)", setAppIcon_DISALLOWED, { requestParams } )
runner.Step("App unregistration", common.unregisterAppInterface, { 1 })
runner.Step("App registration with iconResumed = false", common.registerAppWOPTU, { 1, false, true })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
