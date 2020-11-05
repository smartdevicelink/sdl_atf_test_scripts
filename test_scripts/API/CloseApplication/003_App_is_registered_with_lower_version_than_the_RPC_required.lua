---------------------------------------------------------------------------------------------------
--  Issue: https://github.com/smartdevicelink/sdl_core/issues/3466
--
--  Precondition: 
--  1) Application with <appID> is registered on SDL with majorVersion = 5 and minorVersion = 0
--  2) Specific permissions are assigned for <appID> with CloseApplication
--  3) CloseApplication RPC available since 6.0 API version 
--
--  Steps:
--  1) Application sends a CloseApplication RPC request
--
--  SDL does:
--  - a. not send CloseApplication RPC to the HMI and respond with INVALID_DATA to the Application
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/CloseApplication/commonCloseApplication')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.application1.registerAppInterfaceParams.syncMsgVersion.majorVersion = 5
config.application1.registerAppInterfaceParams.syncMsgVersion.minorVersion = 0

--[[ Local Variables ]]
local rpc = {
  name = "CloseApplication",
  hmiName = "BasicCommunication.CloseApplication",
  params = {}
}

local expectedResponse = {
  success = false,
  resultCode = "INVALID_DATA"
}

--[[ Local Functions ]]
local function processRPCInvalidData()
  local mobileSession = common.getMobileSession(1)
  local cid = mobileSession:SendRPC(rpc.name, rpc.params)
  common.getHMIConnection():ExpectRequest(rpc.hmiName)
  :Times(0)
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
runner.Step("RPC " .. rpc.name .. "_resultCode_INVALID_DATA", processRPCInvalidData)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
