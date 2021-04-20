---------------------------------------------------------------------------------------------------
-- Script verifies issue https://github.com/SmartDeviceLink/sdl_core/issues/1225
-- Flow: EXTERNAL_PROPRIETARY
-- Preconditions:
-- SDL and HMI are started. First ignition cycle.
-- Connect device.
-- App registered, consented on device.
-- App has consented groups.
-- Steps to reproduce:
-- Send OnExitAllApplications ("reason":"FACTORY_DEFAULTS") fron HMI.
-- Or run script ATF_Factory_reset.lua
-- Actual result:
-- SDL not clear all user consent records in "user_consent_records" section of the LocalPT after FACTORY_DEFAULTS.
-- Scenario is failed.
-- Expected result:
-- On FACTORY_DEFAULTS, Policy Manager must clear all user consent records in "user_consent_records" section
-- of the LocalPT, other content of the LocalPT must be unchanged.
-- Scenario is passed.
---------------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
-- config.ExitOnCrash = false means that in case of SDL stop through script execution ATF will not stop execution
config.ExitOnCrash = false

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonDefects = require('test_scripts/Defects/4_5/commonDefects')
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require ('user_modules/shared_testcases/commonSteps')
local sdl = require("SDL")
local events = require('events')
local json = require("modules/json")

--[[ General configuration parameters ]]
runner.testSettings.restrictions.sdlBuildOptions = { { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } }

--[[ Local Variables ]]
-- Path to policy table snapshot
local pathToPTS = commonFunctions:read_parameter_from_smart_device_link_ini("SystemFilesPath") .. "/"
.. commonFunctions:read_parameter_from_smart_device_link_ini("PathToSnapshot")
-- Path to local policy table
local pathToLPT = config.pathToSDL .. "/storage/policy.sqlite"

--[[ Local Functions ]]
-- Start SDL and HMI, establish connection between SDL and HMI, open mobile connection via TCP
local function start(self)
  self:runSDL()
  commonFunctions:waitForSDLStart(self)
  :Do(function()
      self:initHMI(self)
      :Do(function()
          commonFunctions:userPrint(35, "HMI initialized")
          self:initHMI_onReady()
          :Do(function()
              commonFunctions:userPrint(35, "HMI is ready")
              self:connectMobile()
              :Do(function()
                  commonFunctions:userPrint(35, "Mobile connected")
                end)
            end)
        end)
    end)
end

-- Delay without expectation
-- @tparam number pTime time to wait
local function delayedExp(pTime, self)
  local event = events.Event()
  event.matches = function(e1, e2) return e1 == e2 end
  EXPECT_HMIEVENT(event, "Delayed event")
  :Timeout(pTime + 5000)
  local function toRun()
    event_dispatcher:RaiseEvent(self.hmiConnection, event)
  end
  RUN_AFTER(toRun, pTime)
end

-- decode snapshot from json to table
local function ptsToTable(pts_f)
  local f = io.open(pts_f, "r")
  local content = f:read("*all")
  f:close()
  return json.decode(content)
end

-- Prepare policy table for policy table update
-- @tparam table tbl table to update
local function ptUpdateFunc(pTbl)
  local appId = config.application1.registerAppInterfaceParams.fullAppID
  -- add to table in app_policies section record for appId with group "Location-1"
  table.insert(pTbl.policy_table.app_policies[appId].groups, "Location-1")
end

-- Remove snapshot and trigger PTU from HMI
local function removeSnapshotAndTriggerPTUFromHMI(self)
  -- remove Snapshot
  os.execute("rm -f " .. pathToPTS)
  -- expect PolicyUpdate request on HMI side
  EXPECT_HMICALL("BasicCommunication.PolicyUpdate", { file = pathToPTS })
  -- Sending OnPolicyUpdate notification form HMI
  self.hmiConnection:SendNotification("SDL.OnPolicyUpdate", { })
end

-- Perform user consent of "Location" group
local function makeConsent(self)
  -- Send GetListOfPermissions request from HMI side
  local request_id = self.hmiConnection:SendRequest("SDL.GetListOfPermissions")
  -- expect GetListOfPermissions response on HMI side with "Location" group
  EXPECT_HMIRESPONSE(request_id,{
      result = {
        code = 0,
        method = "SDL.GetListOfPermissions",
        allowedFunctions = {{name = "Location", allowed = nil}},
        externalConsentStatus = {}
      }
    })
  :Do(function(_,data)
      -- after receiving GetListOfPermissions response on HMI side get id of "Location" group
      local groupId
      for i = 1, #data.result.allowedFunctions do
        if(data.result.allowedFunctions[i].name == "Location") then
          groupId = data.result.allowedFunctions[i].id
        end
      end
      if groupId then
        -- Sending OnAppPermissionConsent notification from HMI to SDL wit info about allowed group
        self.hmiConnection:SendNotification("SDL.OnAppPermissionConsent", {
            appID = commonDefects.getHMIAppId(),
            source = "GUI",
            consentedFunctions = {{name = "Location", id = groupId, allowed = true}}
          })
      else
        -- Fail test case in case GetListOfPermissions response from SDL does not contain id of group
        self:FailTestCase("GroupId for Location was not found")
      end
    end)
  -- delay in 1 sec
  delayedExp(1000, self)
end

local function Check_user_consent_records_in_LPT(self)
  local is_test_fail = false
  -- Check existence of local policy table
  if (commonSteps:file_exists(pathToLPT) == false) then
    self:FailTestCase(config.pathToSDL .. pathToLPT .. " is not created")
  else
    -- check presence record of device_id in table consent_group, must be created after consent "Location" group
    local queryCG = "select device_id from consent_group"
    local r_actual_CG = commonFunctions:get_data_policy_sql(pathToLPT, queryCG)
    if #r_actual_CG ~= 1 then
      commonFunctions:printError("Error: consent_group does not contain 1 required records in LPT")
      is_test_fail = true
    end
    -- check presence record of device_id in table device_consent_group, must be created after device consent
    local queryDCG = "select device_id from device_consent_group"
    local r_actualDCG = commonFunctions:get_data_policy_sql(pathToLPT, queryDCG)
    if #r_actualDCG ~= 1 then
      commonFunctions:printError("Error: device_consent_group does not contain 1 required record in LPT")
      is_test_fail = true
    end
  end
  if(is_test_fail == true) then
    self:FailTestCase("Test is FAILED.")
  end
end

local function Check_user_consent_records_in_Snapshot(self)
  local is_test_fail = false
  -- Check existence of policy table snapshot
  if (commonSteps:file_exists(pathToPTS) == false) then
    self:FailTestCase(pathToPTS .. " is not created")
  else
    -- Check presence of consented group for registered appID
    local pts = ptsToTable(pathToPTS)
    local ucr = pts.policy_table.device_data[commonDefects.getDeviceMAC()].user_consent_records
    if not (ucr[config.application1.registerAppInterfaceParams.fullAppID]) then
      commonFunctions:printError("Error: user_consent_records.consent_groups.Location is not present in Snapshot")
      is_test_fail = true
    end
  end
  if (is_test_fail == true) then
    self:FailTestCase("Test is FAILED.")
  end
end

local function performFACTORY_DEFAULTS(self)
  -- Send notification OnExitAllApplications(FACTORY_DEFAULTS) from HMI
  self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications", { reason = "FACTORY_DEFAULTS" })
  -- Expect notification OnAppInterfaceUnregistered(FACTORY_DEFAULTS) on mobile app
  self.mobileSession1:ExpectNotification("OnAppInterfaceUnregistered", { reason = "FACTORY_DEFAULTS" })
  EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLClose")
  :Do(function()
      sdl:DeleteFile()
      sdl:StopSDL()
    end)
end

local function Wait_SDL_stop(self)
  -- Delay for SDL stop
  delayedExp(5000, self)
end

local function Check_no_user_consent_records_in_LPT(self)
  local is_test_fail = false
  -- Check existence of local policy table
  if (commonSteps:file_exists(pathToLPT) == false) then
    self:FailTestCase(config.pathToSDL .. pathToLPT .. " is not created")
  else
    -- check absence of record device_id in table consent_group,
    -- must be absent because of device consent is not performed
    local queryCG = "select count(*) from consent_group"
    local r_actual_CG = commonFunctions:get_data_policy_sql(pathToLPT, queryCG)
    if r_actual_CG[1] ~= "0" then
      commonFunctions:printError("Error: consent_group contains redundant records in LPT")
      is_test_fail = true
    end
    -- check absence of record device_id in table device_consent_group,
    -- must be absent because of group consent is not performed
    local queryDCG = "select count(*) from device_consent_group"
    local r_actualDCG = commonFunctions:get_data_policy_sql(pathToLPT, queryDCG)
    if r_actualDCG[1] ~= "0" then
      commonFunctions:printError("Error: device_consent_group contains redundant record in LPT")
      is_test_fail = true
    end
  end
  if(is_test_fail == true) then
    self:FailTestCase("Test is FAILED.")
  end
end

local function Check_no_user_consent_records_in_Snapshot(self)
  local is_test_fail = false
  -- Check existence of policy table snapshot
  if (commonSteps:file_exists(pathToPTS) == false) then
    self:FailTestCase(pathToPTS .. " is not created")
  else
    -- Check absence of consented group for registered appID
    local pts = ptsToTable(pathToPTS)
    local ucr = pts.policy_table.device_data[commonDefects.getDeviceMAC()].user_consent_records
    if (ucr[config.application1.registerAppInterfaceParams.fullAppID]) then
      commonFunctions:printError("Error: user_consent_records.consent_groups.Location was not reset in Snapshot")
      is_test_fail = true
    end
  end
  if (is_test_fail == true) then
    self:FailTestCase("Test is FAILED.")
  end
end

--[[ Scenario ]]
runner.Title("Preconditions")
-- Stop SDL if process is still running, delete local policy table and log files
runner.Step("Clean environment", commonDefects.preconditions)
-- Start SDL and HMI, establish connection between SDL and HMI, open mobile connection via TCP
runner.Step("Start SDL, HMI, connect Mobile", start)
-- Allow connected device on HMI
runner.Step("Allow SDL for device", commonDefects.allow_sdl)
-- create mobile session, register application, perform PTU wit PT from ptUpdateFunc
-- with "Location" group for registered application
runner.Step("RAI, PTU", commonDefects.rai_ptu, { ptUpdateFunc})
-- Consent of "Location" group
runner.Step("Make consent for Location group", makeConsent)

runner.Title("Test")
-- Remove snapshot to make sure that SDL creates new one during PTU, trigger PTU to initiation of snapshot creation
runner.Step("Remove Snapshot and Trigger PTU", removeSnapshotAndTriggerPTUFromHMI)
-- Check records related to consent group and device in LPT
runner.Step("Check_presence_of_user_consent_records_in_LPT", Check_user_consent_records_in_LPT)
-- Check records related to consent group and device in snapshot
runner.Step("Check_presence_of_user_consent_records_in_Snapshot", Check_user_consent_records_in_Snapshot)
-- Perform FACTORY_DEFAULTS
runner.Step("FACTORY_DEFAULTS", performFACTORY_DEFAULTS)
runner.Step("Wait_SDL_stop", Wait_SDL_stop)
-- Start SDL and HMI, establish connection between SDL and HMI, open mobile connection via TCP
runner.Step("Start SDL, HMI, connect Mobile", start)
-- Check absence of records related to consent group and device in LPT after FACTORY_DEFAULTS
runner.Step("Check_absence_of_user_consent_records_in_LPT", Check_no_user_consent_records_in_LPT)
-- Make device consent
runner.Step("Allow SDL for device", commonDefects.allow_sdl)
-- Create session, register application
runner.Step("RAI", commonDefects.rai_n)
-- Remove snapshot to make sure that SDL creates new one during PTU, trigger PTU to initiation of snapshot creation
runner.Step("Remove Snapshot and Trigger PTU", removeSnapshotAndTriggerPTUFromHMI)
-- Check absence of records related to consent group in Snapshot after FACTORY_DEFAULTS
runner.Step("Check_absence_of_user_consent_records_in_Snapshot", Check_no_user_consent_records_in_Snapshot)

runner.Title("Postconditions")
runner.Step("Stop SDL", commonDefects.postconditions)
