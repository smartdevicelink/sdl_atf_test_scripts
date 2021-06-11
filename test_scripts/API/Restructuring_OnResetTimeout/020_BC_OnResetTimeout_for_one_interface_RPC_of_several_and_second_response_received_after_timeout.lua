------------------------------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0189-Restructuring-OnResetTimeout.md
------------------------------------------------------------------------------------------------------------------------
-- Description: Check SDL is able to reset timeout for Mobile app response to defined period
--  and to respond with SUCCESS:true in case:
--  - App sends request which is being split into 2 interfaces
--  - and HMI provides 'OnResetTimeout()' for only one request with 'resetPeriod' > 'default timeout'
--  - and HMI responded successfully after default timeout
-- Applicable RPCs: 'AddCommand'
------------------------------------------------------------------------------------------------------------------------
-- Preconditions:
-- 1) Default SDL timeout is 10s (defined in .INI by 'DefaultTimeout' parameter)
--
-- In case:
-- 1) App sends RPC which is being split into 2 interfaces
-- 2) SDL sends 2 requests to HMI
-- 3) HMI sends 'BC.OnResetTimeout' notification to SDL for one request right after receiving it with 'resetPeriod=15s'
-- 4) HMI sends response within 12s for both requests
-- SDL does:
--  - wait for both responses from HMI within 'reset period' (15s)
--  - respond with SUCCESS:true to Mobile app once both responses are received within the timeout
------------------------------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/Restructuring_OnResetTimeout/common_OnResetTimeout')

--[[ Local Variables ]]
local paramsForRespFunction = {
  respTime = 12000,
  notificationTime = 0,
  resetPeriod = 15000
}

--[[ Local Functions ]]
local function addCommand()
  local params = {
    cmdID = 11,
    vrCommands = {
      "VRCommandonepositive",
      "VRCommandonepositivedouble"
    },
    menuParams = {
      position = 1,
      menuName = "Command_1"
    }
  }
  local corId = common.getMobileSession():SendRPC("AddCommand", params)

  common.getHMIConnection():ExpectRequest("UI.AddCommand")
  :Do(function(_, data)
      local function Response()
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
      end
      RUN_AFTER(Response, 12000)
    end)

  common.getHMIConnection():ExpectRequest("VR.AddCommand")
  :Do(function(_, data)
      common.responseWithOnResetTimeout(data, paramsForRespFunction)
    end)

  common.getMobileSession():ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
  :Timeout(13000)
  :ValidIf(function()
      return common.responseTimeCalculationFromNotif(12000)
    end)
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("App registration", common.registerAppWOPTU)
common.Step("App activation", common.activateApp)

common.Title("Test")
common.Step("Send AddCommand" , addCommand)

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
