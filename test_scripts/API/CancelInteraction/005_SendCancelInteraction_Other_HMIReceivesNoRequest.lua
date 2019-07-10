---------------------------------------------------------------------------------------------------
--  Precondition: 
--  1) app1 is registered on SDL
--
--  Steps:
--  1) app1 sends a CancelInteraction Request for an invalid functionID (not one of the UI interactions)
--
--  Expected:
--  1) core replies to app1 with a failure message
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
    functionID = 11
  }
}

local invalidIdResponse = {
  success = false,
  resultCode = "INVALID_ID"
}

--[[ Local functions ]]
local function SendCancelInteracion()
  local mobileSession = common.getMobileSession(1)
  
  local cid = mobileSession:SendRPC(rpcRequest.name, rpcRequest.params)
  
  EXPECT_HMICALL(rpcRequest.hmi_name, rpcRequest.params):Times(0)

  mobileSession:ExpectResponse(cid, invalidIdResponse)
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
