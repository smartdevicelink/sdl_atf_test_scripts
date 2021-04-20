---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [Policies]: Memory Allocation for PTU
--
-- Description:
-- In case PT Update/Snapshot can't be processed because Manager does not have enough memory allocated,
-- Policies Manager must discard the PolicyTableUpdate
--
-- Preconditions
-- 1. Preapre PTU file 1Mb size (exactly)
-- 2. Register new app
-- 3. Activate app
-- Steps:
-- 1. Perform PTU
-- 2. Verify whether it finished successfully and LPT is updated (check number of records in 'message' table)
--
-- Expected result:
-- PTU finished successfully and LPT is updated
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ Required Shared libraries ]]
  local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
  local commonSteps = require("user_modules/shared_testcases/commonSteps")
  local utils = require ('user_modules/utils')

--[[ Local Variables ]]
  local db_file = config.pathToSDL .. "/" .. commonFunctions:read_parameter_from_smart_device_link_ini("AppStorageFolder") .. "/policy.sqlite"
  local policy_file_path = commonFunctions:read_parameter_from_smart_device_link_ini("SystemFilesPath")
  local ptu_file = "files/jsons/Policies/Policy_Table_Update/ptu_22421_1Mb.json"

--[[ Local Functions ]]
  local function execute_sqlite_query(file_db, query)
    if not file_db then
      return nil
    end
    local res = { }
    local file = io.popen(table.concat({"sqlite3 ", file_db, " '", query, "'"}), 'r')
    if file then
      for line in file:lines() do
        res[#res + 1] = line
      end
      file:close()
      return res
    else
      return nil
    end
  end

--[[ General Precondition before ATF start ]]
  commonFunctions:SDLForceStop()
  commonSteps:DeleteLogsFileAndPolicyTable()

--[[ General Settings for configuration ]]
  Test = require("connecttest")
  require("user_modules/AppTypes")

--[[ Preconditions ]]
  commonFunctions:newTestCasesGroup("Preconditions")

  function Test.DeleteSnapshot()
    os.remove(policy_file_path .. "/sdl_snapshot.json")
  end

  function Test:ActivateApp()
    local requestId1 = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["Test Application"] })
    EXPECT_HMIRESPONSE(requestId1)
    :Do(function(_, data1)
      if data1.result.isSDLAllowed ~= true then
        local requestId2 = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage",
                    { language = "EN-US", messageCodes = { "DataConsent" } })
        EXPECT_HMIRESPONSE(requestId2)
        :Do(function(_, _)
          self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality",
                { allowed = true, source = "GUI", device = { id = utils.getDeviceMAC(), name = utils.getDeviceName() } })
          EXPECT_HMICALL("BasicCommunication.ActivateApp")
          :Do(function(_, data2)
            self.hmiConnection:SendResponse(data2.id,"BasicCommunication.ActivateApp", "SUCCESS", { })
          end)
          :Times(1)
        end)
      end
    end)
  end

--[[ Test ]]
  commonFunctions:newTestCasesGroup("Test")

  function Test:PTU()
    local policy_file_name = "PolicyTableUpdate"
    local requestId = self.hmiConnection:SendRequest("SDL.GetPolicyConfigurationData",
        { policyType = "module_config", property = "endpoints" })
    EXPECT_HMIRESPONSE(requestId)
    :Do(function(_, _)
      self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest", { requestType = "PROPRIETARY", fileName = policy_file_name })
      EXPECT_NOTIFICATION("OnSystemRequest", { requestType = "PROPRIETARY" })
      :Do(function(_, _)
        local corIdSystemRequest = self.mobileSession:SendRPC("SystemRequest", { requestType = "PROPRIETARY", fileName = policy_file_name }, ptu_file)
        EXPECT_HMICALL("BasicCommunication.SystemRequest")
        :Do(function(_, data)
          self.hmiConnection:SendResponse(data.id, "BasicCommunication.SystemRequest", "SUCCESS", { })
          self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate", { policyfile = policy_file_path .. "/" .. policy_file_name })
        end)
        EXPECT_RESPONSE(corIdSystemRequest, { success = true, resultCode = "SUCCESS" })
        :Do(function(_, _)
          requestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", { language = "EN-US", messageCodes = { "StatusUpToDate" } })
          EXPECT_HMIRESPONSE(requestId)
        end)
      end)
    end)
  end

  function Test:ValidateResult()
    self.mobileSession:ExpectAny()
    :ValidIf(function(_, _)
      local r_expected = "7"
      local query = "select count(*) from message"
      local r_actual = execute_sqlite_query(db_file, query)[1]
      if r_expected ~= r_actual then
        return false, "\nExpected:\n" .. r_expected .. "\nActual:\n" .. r_actual
      end
      return true
    end)
    :Times(1)
  end

--[[ Postconditions ]]
  commonFunctions:newTestCasesGroup("Postconditions")
  function Test.StopSDL()
    StopSDL()
  end

return Test
