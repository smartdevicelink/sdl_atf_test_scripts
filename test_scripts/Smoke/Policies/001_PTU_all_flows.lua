---------------------------------------------------------------------------------------------
-- Script verifies PTU sequence
-- Supported PROPRIETARY, EXTERNAL_PROPRIETARY and HTTP flows
---------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Smoke/commonSmoke')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local flowType = {
  PROPRIETARY = 1,
  EXTERNAL_PROPRIETARY = 2,
  HTTP = 3
}

-- Creation policy table from snapshot
-- @tparam table ptu snapshot table
local function getPTUFromPTS(ptu)
  -- remove messages in consumer_friendly_messages
  ptu.policy_table.consumer_friendly_messages.messages = nil
  -- remove device_data
  ptu.policy_table.device_data = nil
  -- remove module_meta
  ptu.policy_table.module_meta = nil
  -- remove usage_and_error_counts
  ptu.policy_table.usage_and_error_counts = nil
  -- write empty struct in "DataConsent-2".rpcs
  ptu.policy_table.functional_groupings["DataConsent-2"].rpcs = common.json.null
  -- remove preloaded_pt
  ptu.policy_table.module_config.preloaded_pt = nil
  -- remove preloaded_date
  ptu.policy_table.module_config.preloaded_date = nil
  -- Create structure in app_policies related to registered application
  ptu.policy_table.app_policies[config.application1.registerAppInterfaceParams.fullAppID] = {
    keep_context = false,
    steal_focus = false,
    priority = "NONE",
    default_hmi = "NONE"
  }
  -- Added permissions for registered app from "Base-4", "Base-6" groups
  ptu.policy_table.app_policies[config.application1.registerAppInterfaceParams.fullAppID]["groups"] = {
    "Base-4", "Base-6"
  }
  ptu.policy_table.vehicle_data = nil
end

-- Check that PT is sent as binary data in OnSystem request
-- @tparam table bin_data binary data
-- @tparam number pFlow number of floe type from flowType
local function checkIfPTSIsSentAsBinary(bin_data, pFlow)
  -- decode binary data to table depending on policy flow
  local pt = nil
  if bin_data ~= nil and string.len(bin_data) > 0 then
    if flowType[pFlow] == flowType.PROPRIETARY then
      pt = common.json.decode(bin_data).HTTPRequest.body
    elseif flowType[pFlow] == flowType.EXTERNAL_PROPRIETARY or flowType[pFlow] == flowType.HTTP then
      pt = bin_data
    end
    pt = common.json.decode(pt)
  end
  -- Check presence of policy_table in decoded PT
  if pt == nil or not pt.policy_table then
    common.failTestCase("PTS was not sent to Mobile as binary data in payload of OnSystemRequest")
  end
end

-- Policy table update with Proprietary flow
-- @tparam table ptu_table PT table
-- @tparam string pFlow policy flow
local function ptuProprietary(ptu_table, pFlow)
  local mobileSession = common.getMobileSession()
  local hmi = common.getHMIConnection()
  -- Get path to snapshot
  local pts_file_name = common.readParameterFromSDLINI("SystemFilesPath") .. "/"
  .. common.readParameterFromSDLINI("PathToSnapshot")
  -- create ptu_file_name as tmp file
  local ptu_file_name = os.tmpname()
  -- Send GetPolicyConfigurationData request from HMI to SDL with service 7
  local requestId = hmi:SendRequest("SDL.GetPolicyConfigurationData",
      { policyType = "module_config", property = "endpoints" })
  common.log("HMI->SDL: RQ: SDL.GetPolicyConfigurationData")
  -- Expect response GetPolicyConfigurationData on HMI side
  EXPECT_HMIRESPONSE(requestId)
  :Do(function()
      common.log("SDL->HMI: RS: SDL.GetPolicyConfigurationData")
      -- After receiving GetPolicyConfigurationData response send OnSystemRequest notification from HMI
      hmi:SendNotification("BasicCommunication.OnSystemRequest",
        { requestType = "PROPRIETARY", fileName = pts_file_name })
      common.log("HMI->SDL: N: BC.OnSystemRequest")
      -- Prepare PT for update
      getPTUFromPTS(ptu_table)
      -- Save created PT for update in tmp file
      common.tableToJsonFile(ptu_table, ptu_file_name)
      -- Expect receiving of OnSystemRequest notification with snapshot on mobile side
      mobileSession:ExpectNotification("OnSystemRequest", { requestType = "PROPRIETARY" })
      :Do(function(_, d)
          -- After receiving OnSystemRequest notification on mobile side check that
          -- data in notification was sent as binary data
          checkIfPTSIsSentAsBinary(d.binaryData, pFlow)
          common.log("SDL->MOB: N: OnSystemRequest")
          -- Send SystemRequest request with PT for update from mobile side
          local corIdSystemRequest = mobileSession:SendRPC("SystemRequest",
            { requestType = "PROPRIETARY" }, ptu_file_name)
          common.log("MOB->SDL: RQ: SystemRequest")
          -- Expect SystemRequest request on HMI side
          hmi:ExpectRequest("BasicCommunication.SystemRequest")
          :Do(function(_, dd)
              common.log("SDL->HMI: RQ: BC.SystemRequest")
              -- Send SystemRequest response form HMI with resultCode SUCCESS
              hmi:SendResponse(dd.id, dd.method, "SUCCESS", { })
              common.log("HMI->SDL: RS: SUCCESS: BC.SystemRequest")
              -- Send OnReceivedPolicyUpdate notification from HMI
              hmi:SendNotification("SDL.OnReceivedPolicyUpdate",
                { policyfile = dd.params.fileName })
              common.log("HMI->SDL: N: SDL.OnReceivedPolicyUpdate")
            end)
          -- Expect SystemRequest response with resultCode SUCCESS on mobile side
          mobileSession:ExpectResponse(corIdSystemRequest, { success = true, resultCode = "SUCCESS"})
          -- remove tmp PT file after receiving SystemRequest response on mobile side
          :Do(function() os.remove(ptu_file_name) end)
          common.log("SDL->MOB: RS: SUCCESS: SystemRequest")
        end)
    end)
end

-- Policy table update with HTTP flow
-- @tparam table ptu_table PT table
local function ptuHttp(ptu_table)
  local mobileSession = common.getMobileSession()
  -- name for PT for SystemRequest
  local policy_file_name = "PolicyTableUpdate"
  -- tmp file name for PT file
  local ptu_file_name = os.tmpname()
  -- Prepare PT for update
  getPTUFromPTS(ptu_table)
  -- Save created PT for update in tmp file
  common.tableToJsonFile(ptu_table, ptu_file_name)
  -- Send SystemRequest form mobile app with created PT
  local corId = mobileSession:SendRPC("SystemRequest",
    { requestType = "HTTP", fileName = policy_file_name }, ptu_file_name)
  common.log("MOB->SDL: RQ: SystemRequest")
  -- Expect successful SystemRequest response on mobile side
  mobileSession:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
  :Do(function()
      common.log("SDL->MOB: RS: SUCCESS: SystemRequest")
    end)
  -- remove tmp PT file
  os.remove(ptu_file_name)
end

-- Expect 3 OnStatusUpdate notification on HMI side during PTU
local function expOnStatusUpdate()
  common.getHMIConnection():ExpectNotification("SDL.OnStatusUpdate",
    { status = "UPDATE_NEEDED" }, { status = "UPDATING" }, {status = "UP_TO_DATE" })
  :Do(function(_, d)
      common.log("SDL->HMI: N: SDL.OnStatusUpdate", d.params.status)
    end)
  :Times(3)
end

-- Fail test cases by incorrect PTU
-- @tparam string pRequestName request name of RPC that is failed expectations
local function failInCaseIncorrectPTU(pRequestName)
  common.failTestCase(pRequestName .. " was sent more than once (PTU update was incorrect)")
end

-- Registration of application with policy table update
local function raiPTU()
  local hmi = common.getHMIConnection()
  expOnStatusUpdate() -- temp solution due to issue in SDL:
  -- SDL.OnStatusUpdate(UPDATE_NEEDED) notification is sent before BC.OnAppRegistered (EXTERNAL_PROPRIETARY flow)
  common.mobile.allowSDL():Do(function()
  -- creation mobile session
  local mobileSession  = common.createMobileSession(1)
  -- open RPC service in created session
  mobileSession:StartService(7)
  :Do(function()
      -- Send RegisterAppInterface request from mobile application
      local corId = mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
      common.log("MOB->SDL: RQ: RegisterAppInterface")
      -- Expect OnAppRegistered on HMI side from SDL
      hmi:ExpectNotification("BasicCommunication.OnAppRegistered",
        { application = { appName = config.application1.registerAppInterfaceParams.appName } })
      :Do(function()
          common.log("SDL->HMI: N: BC.OnAppRegistered")
        end)
      -- Expect RegisterAppInterface response on mobile side with resultCode SUCCESS
      mobileSession:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
      :Do(function()
          common.log("SDL->MOB: RS: RegisterAppInterface")
          if common.SDL.buildOptions.extendedPolicy == "PROPRIETARY"
          or common.SDL.buildOptions.extendedPolicy == "EXTERNAL_PROPRIETARY" then
            -- Expect PolicyUpdate request on HMI side
            hmi:ExpectRequest("BasicCommunication.PolicyUpdate")
            :Do(function(e, d)
                if e.occurences == 1 then -- SDL send BC.PolicyUpdate more than once if PTU update was incorrect
                  common.log("SDL->HMI: RQ: BC.PolicyUpdate")
                  -- Create PT form snapshot
                  local ptu_table = common.SDL.PTS.get()
                  -- Sending PolicyUpdate request from HMI with resultCode SUCCESS
                  hmi:SendResponse(d.id, d.method, "SUCCESS", { })
                  common.log("HMI->SDL: RS: BC.PolicyUpdate")
                  -- PTU proprietary flow
                  ptuProprietary(ptu_table, common.SDL.buildOptions.extendedPolicy)
                else
                  failInCaseIncorrectPTU("BC.PolicyUpdate")
                end
              end)
          elseif common.SDL.buildOptions.extendedPolicy == "HTTP" then
            -- Expect OnSystemRequest notification on mobile side
            mobileSession:ExpectNotification("OnSystemRequest")
            :Do(function(e, d)
                common.log("SDL->MOB: N: OnSystemRequest", e.occurences, d.payload.requestType)
                if d.payload.requestType == "HTTP" then
                  if e.occurences <= 2 then -- SDL send OnSystemRequest more than once if PTU update was incorrect
                    -- Check data in receives OnSystemRequest notification on mobile side
                    checkIfPTSIsSentAsBinary(d.binaryData, common.SDL.buildOptions.extendedPolicy)
                    if d.binaryData then
                      -- Create PT form binary data
                      local ptu_table = common.json.decode(d.binaryData)
                      -- PTU HTTP flow
                      ptuHttp(ptu_table)
                    end
                  else
                    failInCaseIncorrectPTU("OnSystemRequest")
                  end
                end
              end)
            :Times(2)
          end
          -- Expect OnHMIStatus with hmiLevel NONE on mobile side form SDL
          mobileSession:ExpectNotification("OnHMIStatus",
            { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
          :Do(function(_, d)
              common.log("SDL->MOB: N: OnHMIStatus", d.payload.hmiLevel)
            end)
          -- Expect OnPermissionsChange on mobile side form SDL
          mobileSession:ExpectNotification("OnPermissionsChange")
          :Do(function()
              common.log("SDL->MOB: N: OnPermissionsChange")
            end)
          :Times(2)
        end)
    end)
  end)
end

-- Check update status
local function checkPTUStatus()
  local hmi = common.getHMIConnection()
  -- Send GetStatusUpdate form HMI to SDL
  local reqId = hmi:SendRequest("SDL.GetStatusUpdate")
  common.log("HMI->SDL: RQ: SDL.GetStatusUpdate")
  -- Expect GetStatusUpdate response from SDL to HMI with update status
  hmi:ExpectResponse(reqId, { result = { status = "UP_TO_DATE" }})
  :Do(function(_, d)
    common.log("HMI->SDL: RS: SDL.GetStatusUpdate", tostring(d.result.status))
    end)
end

-- Pring in terminal build options(RC status and policy slow)
local function printSDLConfig()
  print(common.tableToString(common.SDL.buildOptions))
end

--[[ Scenario ]]
runner.Title("Preconditions")
-- Stop SDL if process is still running, delete local policy table and log files
runner.Step("Clean environment", common.preconditions)
-- Start SDL and HMI, establish connection between SDL and HMI, open mobile connection via TCP
runner.Step("Start SDL, HMI, connect Mobile", common.start)
-- Pring in terminal build options(RC status and policy slow)
runner.Step("SDL Configuration", printSDLConfig)

runner.Title("Test")
-- create mobile session, register application, perform PTU wit PT
runner.Step("RAI, PTU", raiPTU)
-- Check that PTU is performed successful
runner.Step("Check Status", checkPTUStatus)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
