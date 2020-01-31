---------------------------------------------------------------------------------------------
-- Common functions for External_UCS test scripts
--
-- Note: Only EXTERNAL_PROPRIETARY mode is supported
---------------------------------------------------------------------------------------------
local mobile_session = require("mobile_session")
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local json = require("modules/json")
local sdl = require('SDL')
local utils = require ('user_modules/utils')

local m = { }

-- [[ Variables ]]

  m.HMIAppIds = { }
  m.pts = nil

-- [[ Functions ]]

--[[@createTableFromJsonFile: Create table from .json file
--! @parameters:
--! file - input file
--]]
  function m.createTableFromJsonFile(file)
    local f = io.open(file, "r")
    local content = f:read("*all")
    f:close()
    return json.decode(content)
  end

--[[@createJsonFileFromTable: Create .json file from table
--! @parameters:
--! table - input table
--! file - output file
--]]
  function m.createJsonFileFromTable(table, file)
    local f = io.open(file, "w")
    f:write(json.encode(table))
    f:close()
  end

--[[@checkSDLStatus: Checks SDL status against defined one
--! @parameters:
--! expStatus - expected status of SDL (0 - STOPPED, 1 - RUNNING)
--]]
  function m.checkSDLStatus(test, expStatus)
    local actStatus = sdl:CheckStatusSDL()
    print("SDL status: " .. tostring(actStatus))
    if actStatus ~= expStatus then
      local msg = "Expected SDL status: " .. expStatus .. ", actual: " .. actStatus
      test:FailTestCase(msg)
    end
  end

--[[@removeLPT: Delete Local Policy Table
--! @parameters: NO
--]]
  function m.removeLPT()
    local data = { "AppStorageFolder", "AppInfoStorage" }
    for _, v in pairs(data) do
      os.execute("rm -rf " .. commonPreconditions:GetPathToSDL()
        .. commonFunctions:read_parameter_from_smart_device_link_ini(v))
    end
  end

--[[@removePTS: Delete Policy Table Snapshot
--! @parameters: NO
--]]
  function m.removePTS()
    local filePath = commonFunctions:read_parameter_from_smart_device_link_ini("SystemFilesPath") ..
      "/" .. commonFunctions:read_parameter_from_smart_device_link_ini("PathToSnapshot")
    os.execute("rm -rf " .. filePath)
  end

--[[@updatePTU: Update Policy Table Snapshot (PTS) in the way it can be used as Policy Table Update (PTU)
--! @parameters: NO
--]]
  local function updatePTU()
    local appId = config.application1.registerAppInterfaceParams.fullAppID
    m.pts.policy_table.consumer_friendly_messages.messages = nil
    m.pts.policy_table.device_data = nil
    m.pts.policy_table.module_meta = nil
    m.pts.policy_table.usage_and_error_counts = nil
    m.pts.policy_table.app_policies[appId] = {
      keep_context = false,
      steal_focus = false,
      priority = "NONE",
      default_hmi = "NONE"
    }
    m.pts.policy_table.app_policies[appId]["groups"] = { "Base-4", "Base-6" }
    m.pts.policy_table.functional_groupings["DataConsent-2"].rpcs = json.null
    m.pts.policy_table.module_config.preloaded_pt = nil
    m.pts.policy_table.vehicle_data = nil
  end

--[[@ptu: Perform Policy Table Update process
--! @parameters:
--! status - expected final status ('UPDATE_NEEDED', 'UP_TO_DATE')
--]]
  local function ptu(test, status)
    local policy_file_name = "PolicyTableUpdate"
    local policy_file_path = commonFunctions:read_parameter_from_smart_device_link_ini("SystemFilesPath")
    local ptu_file_name = os.tmpname()
    local requestId = test.hmiConnection:SendRequest("SDL.GetPolicyConfigurationData",
        { policyType = "module_config", property = "endpoints" })
    EXPECT_HMIRESPONSE(requestId)
    :Do(function()
        test.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest",
          { requestType = "PROPRIETARY", fileName = policy_file_name })
        m.createJsonFileFromTable(m.pts, ptu_file_name)
        EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", { status = status })
        test.mobileSession1:ExpectNotification("OnSystemRequest", { requestType = "PROPRIETARY" })
        :Do(function()
            local corIdSystemRequest = test.mobileSession1:SendRPC("SystemRequest",
              { requestType = "PROPRIETARY", fileName = policy_file_name }, ptu_file_name)
            EXPECT_HMICALL("BasicCommunication.SystemRequest")
            :Do(function(_, d)
                test.hmiConnection:SendResponse(d.id, "BasicCommunication.SystemRequest", "SUCCESS", { })
                test.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate",
                  { policyfile = policy_file_path .. "/" .. policy_file_name })
              end)
              test.mobileSession1:ExpectResponse(corIdSystemRequest, { success = true, resultCode = "SUCCESS"})
          end)
      end)
    os.remove(ptu_file_name)
  end

--[[@startSession: Start mobile session
--! @parameters:
--! id - session number (1, 2 etc.) (mandatory)
--]]
  function m.startSession(test, id)
    test["mobileSession"..id] = mobile_session.MobileSession(test, test.mobileConnection)
    test["mobileSession"..id]:StartService(7)
  end

--[[@registerApp: Register application
--! @parameters:
--! id - application number (1, 2 etc.), equals to session number (mandatory)
--]]
  function m.registerApp(test, id)
    local RAIParams = config["application"..id].registerAppInterfaceParams
    local corId = test["mobileSession"..id]:SendRPC("RegisterAppInterface", RAIParams)
    EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
      { application = { appName = RAIParams.appName } })
    :Do(function(_, d)
        m.HMIAppIds[RAIParams.fullAppID] = d.params.application.appID
      end)
    test["mobileSession"..id]:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
    :Do(function()
        test["mobileSession"..id]:ExpectNotification("OnHMIStatus",
          { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
        test["mobileSession"..id]:ExpectNotification("OnPermissionsChange")
      end)
  end

--[[@activateApp: Activate application and start Local Policy Table update
--! Note: PTU will be done in 2 cases:
--! 1. Only one application is registered and it is not in NONE hmi level
--! 2. A few applications are registered: 1st - in FULL, others - in NONE hmi levels
--! @parameters:
--! id - application number (1, 2 etc.), equals to session number (mandatory)
--! status - expected final status ('UPDATE_NEEDED', 'UP_TO_DATE')
--! updateFunc - function to update specific sections in PTU file
--! that has to be passed as an input parameter
--]]
  function m.activateApp(test, id, status, updateFunc)
    local appId = config["application"..id].registerAppInterfaceParams.fullAppID
    local reqId = test.hmiConnection:SendRequest("SDL.ActivateApp", { appID = m.HMIAppIds[appId] })
    EXPECT_HMIRESPONSE(reqId)
    :Do(function(_, d1)
        if d1.result.isSDLAllowed ~= true then
          local reqId2 = test.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage",
            { language = "EN-US", messageCodes = { "DataConsent" } })
          EXPECT_HMIRESPONSE(reqId2)
          :Do(function()
              test.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality",
                { allowed = true, source = "GUI", device = { id = utils.getDeviceMAC(), name = utils.getDeviceName() } })
              EXPECT_HMICALL("BasicCommunication.ActivateApp")
              :Do(function(_, d2)
                  test.hmiConnection:SendResponse(d2.id,"BasicCommunication.ActivateApp", "SUCCESS", { })
                  test["mobileSession"..id]:ExpectNotification("OnHMIStatus",
                    { hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN" })
                end)
            end)
        end
      end)
    EXPECT_HMICALL("BasicCommunication.PolicyUpdate")
    :Do(function(exp, d)
      if(exp.occurences == 1) then
        test.hmiConnection:SendResponse(d.id, d.method, "SUCCESS", { })
        m.pts = m.createTableFromJsonFile(d.params.file)
        if status then
          updatePTU()
          if updateFunc then
            updateFunc(m.pts)
          end
          ptu(test, status)
        end
      end
    end)
    --TODO: Remove when issue "[GENIVI] SDL restarts PTU sequence with sending redundant BC.PolicyUpdate" is resolved
    :Times(AtLeast(1))
  end

--[[@updatePreloadedPT: Update PreloadedPT file
--! @parameters:
--! updateFunc - function to update specific sections in PreloadedPT file
--! that has to be passed as an input parameter
--]]
  function m.updatePreloadedPT(updateFunc)
    local preloadedFile = commonPreconditions:GetPathToSDL() .. "sdl_preloaded_pt.json"
    local preloadedTable = m.createTableFromJsonFile(preloadedFile)
    preloadedTable.policy_table.functional_groupings["DataConsent-2"].rpcs = json.null
    if updateFunc then
      updateFunc(preloadedTable)
    end
    m.createJsonFileFromTable(preloadedTable, preloadedFile)
  end

--[[@ignitionOff: Perform Igninition Off
--! @parameters: NO
--]]
  function m.ignitionOff(test)
    if sdl:CheckStatusSDL() == sdl.RUNNING then
      test.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications", { reason = "SUSPEND" })
      EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLPersistenceComplete")
      :Do(function()
          test.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications", { reason = "IGNITION_OFF" })
          StopSDL()
        end)
      end
  end

return m
