---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/3175
--
-- Description: SDL should successfully process VR.ChangeLanguage during PTU
--
-- Pre-conditions:
-- 1. Start SDL, HMI, connect Mobile device
-- 2. Register application which is new for SDL to trigger PTU
--
-- Steps:
-- 1. HMI sends VR.OnLanguageChange after sending of SDL.OnReceivedPolicyUpdate by HMI during PTU processing
-- SDL does:
--  - send OnLanguageChange notification to App
--  - send OnAppInterfaceUnregistered(reason = "LANGUAGE_CHANGE") notification to App
--  - send BasicCommunication.OnAppUnregistered(unexpectedDisconnect = false) to HMI
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local common = require('test_scripts/Defects/7_0/3175/common_3175')

--[[ Local Functions ]]
local function performPTUWithVrOnLanguageChange()
  local hmi = common.getHmiConnection()
  local mobile = common.getMobileSession()
  local ptuFileName = os.tmpname()
  local requestId = hmi:SendRequest("SDL.GetPolicyConfigurationData",
    { policyType = "module_config", property = "endpoints" })
  hmi:ExpectResponse(requestId)
  :Do(function()
      local ptuTable = common.getPTUFromPTS()
      ptuTable.policy_table.app_policies[common.getPolicyAppId()] = common.getAppDataForPTU()
      common.tableToJsonFile(ptuTable, ptuFileName)
      hmi:SendNotification("BasicCommunication.OnSystemRequest",
        { requestType = "PROPRIETARY", fileName = common.getPTSFilePath() })
      mobile:ExpectNotification("OnSystemRequest", { requestType = "PROPRIETARY" })
      :Do(function()
          hmi:ExpectRequest("BasicCommunication.SystemRequest")
          :Do(function(_, d3)
              hmi:SendResponse(d3.id, "BasicCommunication.SystemRequest", "SUCCESS", { })
              hmi:SendNotification("SDL.OnReceivedPolicyUpdate", { policyfile = d3.params.fileName })
              common.checkVrOnLanguageChangeProcessing()
            end)
          mobile:SendRPC("SystemRequest", { requestType = "PROPRIETARY" }, ptuFileName)
          os.remove(ptuFileName)
        end)
    end)
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)

common.Title("Test")
common.Step("VR.OnLanguageChange after sending of SDL.OnReceivedPolicyUpdate by HMI during PTU processing",
  performPTUWithVrOnLanguageChange)

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
