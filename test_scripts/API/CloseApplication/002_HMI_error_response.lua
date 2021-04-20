---------------------------------------------------------------------------------------------------
--  Precondition: 
--  1) Application with <appID> is registered on SDL.
--  2) Specific permissions are assigned for <appID> with CloseApplication
--
--  Steps:
--  1) Application sends a CloseApplication RPC request
--
--  Expected:
--  1) SDL sends BasicCommunication.CloseApplication to the HMI with the appropriate appID, 
--     HMI responds with IGNORED
--  2) SDL responds to mobile app with "resultCode: IGNORED, success: false"
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/CloseApplication/commonCloseApplication')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]

local rpc = {
  name = "CloseApplication",
  hmiName = "BasicCommunication.CloseApplication",
  params = {}
}

local expectedResponse = {
  success = false,
  resultCode = "IGNORED"
}

--[[ Local Functions ]]
local function processRPCIgnored()
  local mobileSession = common.getMobileSession(1)
  local cid = mobileSession:SendRPC(rpc.name, rpc.params)
  EXPECT_HMICALL(rpc.hmiName, {
    appID = common.getHMIAppId(1)
  })
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "IGNORED", {})
    end)

  mobileSession:ExpectNotification("OnHMIStatus", { hmiLevel = "NONE" }):Times(0)
  mobileSession:ExpectResponse(cid, expectedResponse)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.registerApp)
runner.Step("PTU", common.policyTableUpdate)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("RPC " .. rpc.name .. "_resultCode_IGNORED", processRPCIgnored)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)