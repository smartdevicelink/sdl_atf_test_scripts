---------------------------------------------------------------------------------------------------
--  Precondition: 
--  1) app1 is registered on SDL
--
--  Steps:
--  1) app1 sends a sends an Alert RPC
--  2) app1 sends a CancelInteraction Request with the functionID of Alert
--  3) the HMI receives the CancelInteraction Request and replies
--
--  Expected:
--  1) app1 receives SUCCESS from the CancelInteraction
--  2) app1 receives ABORTED from the Alert
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
    functionID = 12,
    cancelID = 99
  }
}

local successResponse = {
  success = true,
  resultCode = "SUCCESS"
}

local abortedResponse = {
  success = false,
  resultCode = "ABORTED"
}

--[[ Local functions ]]
local function SendCancelInteraction()
  local mobileSession = common.getMobileSession(1)
  local hmiSession = common.getHMIConnection()
  
  local cid0 = mobileSession:SendRPC(rpcInteraction.name, rpcInteraction.params)

  EXPECT_HMICALL(rpcInteraction.hmi_name, rpcInteraction.hmi_params)
  :Do(function(_, data)
    local cid1 = mobileSession:SendRPC(rpcCancelInteraction.name, rpcCancelInteraction.params)

    EXPECT_HMICALL(rpcCancelInteraction.hmi_name, rpcCancelInteraction.params)
    :Do(function(_, data2)
      hmiSession:SendResponse(data.id, data.method, "ABORTED", {})
      hmiSession:SendResponse(data2.id, data2.method, "SUCCESS", {})
    end)

    mobileSession:ExpectResponse(cid1, successResponse)
  end)
  
  mobileSession:ExpectResponse(cid0, abortedResponse)
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
