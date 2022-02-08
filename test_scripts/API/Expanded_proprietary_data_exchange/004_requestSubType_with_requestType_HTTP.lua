---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0083-Expandable-design-for-proprietary-data-exchange.md
-- User story:TBD
-- Use case:TBD
--
-- Requirement summary:
-- TBD
--
-- Description:
-- 1. In case: SDL receives SystemRequest and on SystemRequest with requestType = HTTP and requestSubType
-- SDL does:
-- 1. ignore requestSubType in SystemRequest and process messages as usual,
-- 2. transfer OnSystemRequest to mobile app as usual
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/Expanded_proprietary_data_exchange/commonDataExchange')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local usedFile = "./files/action.png"
local params = {
  requestType = "HTTP",
  requestSubType = "SomeSubType",
  fileName = "action.png"
}

local function systemRequest(pParams, pFile)
  local mobSession = common.getMobileSession()
  local cid = mobSession:SendRPC("SystemRequest", pParams, pFile)
  if pParams.fileName then pParams.fileName = "/tmp/fs/mp/images/ivsu_cache/" .. pParams.fileName end
  EXPECT_HMICALL("BasicCommunication.SystemRequest",pParams)
  :Times(0)
  -- will be rejected because not UPDATING
  mobSession:ExpectResponse(cid, { success = false, resultCode = "REJECTED" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerApp)

runner.Title("Test")
runner.Step("SystemRequest with request type HTTP", systemRequest, {params, usedFile})
runner.Step("OnSystemRequest with request type HTTP", common.onSystemRequest, {params})

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
