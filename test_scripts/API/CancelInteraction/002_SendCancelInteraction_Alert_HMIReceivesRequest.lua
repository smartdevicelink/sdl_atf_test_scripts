---------------------------------------------------------------------------------------------------
--  Precondition: 
--  1) app1 is registered on SDL
--
--  Steps:
--  1) app1 sends a CancelInteraction Request with the functionID of Alert
--  2) the HMI receives the CancelInteraction Requests and replies
--
--  Expected:
--  1) app1 receives a successful response from the HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('user_modules/sequences/actions')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local variables ]]
local rpcRequest = {
  name = "CancelInteraction",
  hmi_name = "UI.CancelInteraction",
  params = {
    cancelID = -1,
    functionID = 12
  }
}

local successResponse = {
  success = true,
  resultCode = "SUCCESS"
}

--[[ Local functions ]]
local function SendCancelInteracion()
  local mobileSession = common.getMobileSession(1)
  local hmiSession = common.getHMIConnection()
  
  local cid = mobileSession:SendRPC(rpcRequest.name, rpcRequest.params)
  
  EXPECT_HMICALL(rpcRequest.hmi_name, rpcRequest.params):Do(function(_, data)
    hmiSession:SendResponse(data.id, data.method, "SUCCESS", {})
  end)

  mobileSession:ExpectResponse(cid, successResponse)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI App 1", common.registerApp)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("SendCancelInteracion", SendCancelInteracion)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
