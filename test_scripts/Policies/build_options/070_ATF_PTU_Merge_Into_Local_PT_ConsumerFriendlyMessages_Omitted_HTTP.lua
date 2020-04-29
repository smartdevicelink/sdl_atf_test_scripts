-- Requirements summary:
-- [Policies] Merge: PTU into LocalPT (PTU omits "consumer_friendly_messages" section)
--
-- Description:
-- In case the Updated PT omits "consumer_friendly_messages" section,
-- PoliciesManager must maintain the current "consumer_friendly_messages"
-- section in Local PT.
-- 1. Used preconditions
-- SDL is built with "-DEXTENDED_POLICY: HTTP" flag
-- Application is registered.
-- PTU is requested.
-- PTU to be received satisfies data dictionary requirements
-- PTU omits "consumer_friendly_messages" section
-- SDL->HMI: SDL.OnStatusUpdate(UPDATE_NEEDED)
-- SDL->HMI:SDL.PolicyUpdate(file, timeout, retry[])
-- HMI -> SDL: SDL.GetURLs (<service>)
-- HMI->SDL: BasicCommunication.OnSystemRequest ('url', requestType:HTTP)
-- SDL->app: OnSystemRequest ('url', requestType:HTTP, fileType="JSON")
-- app->SDL: SystemRequest(requestType=HTTP)
-- SDL->HMI: SystemRequest(requestType=HTTP, fileName)
-- HMI->SDL: SystemRequest(SUCCESS)
-- 2. Performed steps
-- HMI->SDL: OnReceivedPolicyUpdate(policy_file) according to data dictionary
-- SDL->HMI: OnStatusUpdate(UP_TO_DATE)
-- Expected result:
-- SDL maintains the current "consumer_friendly_messages" section in Local PT
--(no updates on merge)
-- SDL replaces the following sections of the Local Policy Table with the
--corresponding sections from PTU: module_config, functional_groupings and app_policies
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "HTTP" } } })

--[[ General Settings for configuration ]]
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local mobile_session = require("mobile_session")
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local commonSteps = require("user_modules/shared_testcases/commonSteps")
local json = require("modules/json")
local utils = require ('user_modules/utils')

--[[ Local Variables ]]
local db_file = config.pathToSDL .. "/" .. commonFunctions:read_parameter_from_smart_device_link_ini("AppStorageFolder") .. "/policy.sqlite"
local ptu_file = os.tmpname()
local ptu = nil
local r_expected
local r_actual

--[[ Local Functions ]]
local function get_num_records()
  return commonFunctions:get_data_policy_sql(db_file, "select count(*) from message")[1]
end

--[[ General Precondition before ATF start ]]
commonFunctions:SDLForceStop()
commonSteps:DeleteLogsFileAndPolicyTable()

--[[ General Settings for configuration ]]
Test = require("user_modules/connecttest_resumption")
require("user_modules/AppTypes")

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

function Test:ConnectMobile()
  self:connectMobile()
  if utils.getDeviceTransportType() == "WIFI" then
    EXPECT_HMICALL("BasicCommunication.UpdateDeviceList")
    :Do(function(_,data)
        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
      end)
  end
end

function Test:StartMobileSession()
  self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
  self.mobileSession:StartService(7)
end

function Test:RegisterApp()
  local reqId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
    {
      application =
      {
        deviceInfo =
        {
          id = utils.getDeviceMAC(),
          name = utils.getDeviceName(),
          transportType = utils.getDeviceTransportType()
        }
      }
    })
  self.mobileSession:ExpectResponse(reqId, { success = true, resultCode = "SUCCESS" })
  self.mobileSession:ExpectNotification("OnSystemRequest"):Times(2)
  :Do(function(_, d)
      if d.payload.requestType == "HTTP" then
        ptu = json.decode(d.binaryData)
      end
    end)
end

function Test:ValidatePTS()
  if not ptu then
    self:FailTestCase("Expected PTS is not received")
    return
  end
  if ptu.policy_table.consumer_friendly_messages.messages then
    self:FailTestCase("Expected absence of 'consumer_friendly_messages.messages' section in PTS")
  end
end

function Test:UpdatePTS()
  if not ptu then
    self:FailTestCase("Expected PTS is not received")
    return
  end
  ptu.policy_table.device_data = nil
  ptu.policy_table.vehicle_data = nil
  ptu.policy_table.usage_and_error_counts = nil
  ptu.policy_table.app_policies["0000001"] = { keep_context = false, steal_focus = false, priority = "NONE", default_hmi = "NONE" }
  ptu.policy_table.app_policies["0000001"]["groups"] = { "Base-4", "Base-6" }
  ptu.policy_table.app_policies["0000001"]["RequestType"] = { "HTTP" }
  ptu.policy_table.functional_groupings["DataConsent-2"].rpcs = json.null
end

function Test.StorePTSInFile()
  local f = io.open(ptu_file, "w")
  f:write(json.encode(ptu))
  f:close()
end

function Test.Wait()
  os.execute("sleep 3")
end

function Test.NoteNumOfRecords()
  r_expected = get_num_records()
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:PerformPTUSuccess()
  local policy_file_name = "PolicyTableUpdate"
  local corId = self.mobileSession:SendRPC("SystemRequest", { requestType = "HTTP", fileName = policy_file_name }, ptu_file)
  EXPECT_RESPONSE(corId, { success = true, resultCode = "SUCCESS" })
  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", { status = "UP_TO_DATE" })
end

function Test:ValidateNumberMessages()
  r_actual = get_num_records()
  if r_expected ~= r_actual then
    self:FailTestCase("Expected number of records: " .. r_expected .. ", got: " .. r_actual)
  end
  print("Number of records: " .. r_actual)
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")

function Test.Clean()
  os.remove(ptu_file)
end

function Test.StopSDL()
  StopSDL()
end

return Test
