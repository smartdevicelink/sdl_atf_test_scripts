---------------------------------------------------------------------------------------------------
--  Precondition: 
--  1) app1 is registered on SDL
--
--  Steps:
--  1) app1 sends a sends an Alert RPC
--  2) app1 sends a CancelInteraction Request with an INVALID functionID
--
--  Expected:
--  1) the HMI does not receive the CancelInteraction request
--  2) app1 receives INVALID_ID CancelInteraction response
--  3) app1 receives SUCCESS from the Alert
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('user_modules/sequences/actions')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local variables ]]
local rpcInteraction = {
  name = "Alert",
  hmi_name = "UI.Alert",
  params = {
    alertText1 = "hello",
    cancelID = 99
  },
  hmi_params = {
    alertType = "UI",
    duration = 5000,
    cancelID = 99,
    alertStrings = {
      { fieldName = "alertText1", fieldText = "hello" }
    }
  }
}

local rpcCancelInteraction = {
  name = "CancelInteraction",
  hmi_name = "UI.CancelInteraction",
  params = {
    cancelID = 99,
    functionID = 5
  }
}

local successResponse = {
  success = true,
  resultCode = "SUCCESS"
}

local invalidIdResponse = {
  success = false,
  resultCode = "INVALID_ID"
}

--[[ Local functions ]]
local function SendCancelInteraction()
  local mobileSession = common.getMobileSession(1)
  local hmiSession = common.getHMIConnection()
  
  local cid0 = mobileSession:SendRPC(rpcInteraction.name, rpcInteraction.params)
  
  EXPECT_HMICALL(rpcInteraction.hmi_name, rpcInteraction.hmi_params)
  :Do(function(_, data)
    hmiSession:SendResponse(data.id, data.method, "SUCCESS", {})

    local cid1 = mobileSession:SendRPC(rpcCancelInteraction.name, rpcCancelInteraction.params)
  
    EXPECT_HMICALL(rpcCancelInteraction.hmi_name, rpcCancelInteraction.params)
    :Times(0)
  
    mobileSession:ExpectResponse(cid1, invalidIdResponse)
  end)

  mobileSession:ExpectResponse(cid0, successResponse)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI App 1", common.registerApp)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("Send CancelInteraction", SendCancelInteraction)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
