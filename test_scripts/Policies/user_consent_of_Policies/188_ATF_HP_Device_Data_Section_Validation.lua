---------------------------------------------------------------------------------------------
-- Requirement summary:
-- PT sections information
--
-- Description:
-- "device_data"
-- "device"->""time_stamp" section specifies time of obtaining User Consent for each of mobile device.
-- "device"->"input" section specifies the source of User Consent for current mobile device
-- <functional grouping> section specifies the policies groups the user consented for current mobile device
-- <app id> specifies user consents for permissions for application on current device to utilize rpc groups if applicable
-- "user_consent_records"
-- ""user_consent_records"- >"app id"->"input" specifies the source of User Consent for rpc groups for current application on device with root <device identifier>
-- "app id"->"time_stamp" specifies time of obtaining User Consent for rpc groups for current application on device with root <device identifier>
-- ""user_consent_records"- >"app id"- >"consent_groups"- ><functional grouping> specifies User Consent for rpc groups for current application on current mobile device
-- "app_policies"
-- "device" the section is used to specify permissions of any connecting device. For example, until User consents rpc groups listed under 'groups' section that are not in 'preconseted_groups' section, no apllication running on this device can have any policy other than pre_DataConsented and no Policy Exchange can take place using this device.
-- “usage_and_error_counts”
-- “usage_and_error_counts” must provide usage and error tracking to the backend upon a policy table exchange. Incrementing counters for different types of statistics in "usage_and_error_counts" section MUST NOT be dropped to 0 and restarted counting after each successful Policy Table Update. This section should contain cumulative usage and errors, which should be cleared on reflash. See Section preloaded_pt of Section module_config in Policy Table for related details.
-- “usage_and_error_counts”->"app_level" Specifies level of app for which statistics was gathered
-- 1. Used preconditions:
-- a) First SDL life cycle
-- b) App successfylly registered on consented device, activated and updated
-- c) User consent new group for app
-- 2. Performed steps
-- a) Check in Snapshot:
-- device_data -> <deviceHash> -> user_consent_records -> device -> time_stamp
-- device_data -> <deviceHash> -> user_consent_records -> device -> input
-- device_data -> <deviceHash> -> user_consent_records -> device -> consent_groups -> <consented_groups_for_device>
-- device_data -> <deviceHash> -> user_consent_records -> <appId> -> time_stamp
-- device_data -> <deviceHash> -> user_consent_records -> <appId> -> input
-- device_data -> <deviceHash> -> user_consent_records -> <appId> -> consent_groups -> <consented_groups_for_app>
--
-- Expected result:
-- a) PTS has correct values.
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ General configuration parameters ]]
--ToDo: shall be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')

--[[ Required Shared libraries ]]
local commonSteps = require ('user_modules/shared_testcases/commonSteps')
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonTestCases = require ('user_modules/shared_testcases/commonTestCases')
local utils = require ('user_modules/utils')
require('user_modules/AppTypes')

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFiles()
commonSteps:DeletePolicyTable()

--[[ Local Variables ]]
local pathToSnapshot
local consentDeviceSystemTimeStamp
local consentGroupSystemTimeStamp
local appID = config.application1.registerAppInterfaceParams["fullAppID"]

--[[ Local Functions ]]
local function dateToTimeStamp(date)
  local year, month, day, hour, min, sec = date:match("(%d+)-(%d+)-(%d+)T(%d+):(%d+):(%d+)Z")
  return os.time({year = year, month = month, day = day, hour = hour, min = min, sec = sec})
end

local function GetCurrentTimeStampDeviceConsent()
  consentDeviceSystemTimeStamp = os.time()
  return consentDeviceSystemTimeStamp
end

local function GetCurrentTimeStampGroupConsent()
  consentGroupSystemTimeStamp = os.time()
  return consentGroupSystemTimeStamp
end

local function GetDataFromSnapshot(pathToFile)
  local function getData(pTable, pKey)
    if pTable then
      return pTable[pKey]
    end
    return nil
  end
  local function getTableData(pTable, pKey)
    if pTable and pTable[pKey] then
      return next(pTable[pKey], nil)
    end
    return nil
  end
  local file = io.open(pathToFile, "r")
  local json_data = file:read("*all") -- may be abbreviated to "*a";
  file:close()
  local json = require("modules/json")
  local data = json.decode(json_data)
  local ucr = data.policy_table.device_data[utils.getDeviceMAC()].user_consent_records
  local res = {
    deviceConsentTimeStamp = dateToTimeStamp(getData(ucr.device, "time_stamp")),
    deviceInput = getData(ucr.device, "input"),
    deviceGroups = getTableData(ucr.device, "consent_groups"),
    inputOfAppIdConsent = getData(ucr[appID], "input"),
    groupUserconsentTimeStamp = dateToTimeStamp(getData(ucr[appID], "time_stamp")),
    userConsentGroup = getTableData(ucr[appID], "consent_groups")
  }
  return res
end

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")
function Test:Precondition_Get_List_Of_Connected_Devices()
  self.hmiConnection:SendNotification("BasicCommunication.OnStartDeviceDiscovery")
  if utils.getDeviceTransportType() == "WIFI" then
    EXPECT_HMICALL("BasicCommunication.UpdateDeviceList")
    :Do(function(_,data)
        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
      end)
  end
end

function Test:Precondition_Activate_App_Consent_Device_Make_PTU_Consent_Group()
  local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", {appID = self.applications["Test Application"]})
  EXPECT_HMIRESPONSE(RequestId, {result = {code = 0, isSDLAllowed = false}, method = "SDL.ActivateApp"})
  :Do(function(_,_)
      local RequestIdGetUserFriendlyMessage = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})
      EXPECT_HMIRESPONSE(RequestIdGetUserFriendlyMessage,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
      :Do(function(_,_)
          self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {allowed = true, source = "GUI", device = {id = utils.getDeviceMAC(), name = utils.getDeviceName()}})
          GetCurrentTimeStampDeviceConsent()
          EXPECT_HMICALL("BasicCommunication.ActivateApp")
          :Do(function(_,data1)
              self.hmiConnection:SendResponse(data1.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
            end)
          :Times(AtLeast(1))
        end)
    end)
  EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"})
  EXPECT_HMICALL("BasicCommunication.PolicyUpdate")
  :Do(function(_,_)
      local requestId = self.hmiConnection:SendRequest("SDL.GetPolicyConfigurationData",
          { policyType = "module_config", property = "endpoints" })
      EXPECT_HMIRESPONSE(requestId)
      :Do(function()
          self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest",{requestType = "PROPRIETARY", fileName = "filename"})
          EXPECT_NOTIFICATION("OnSystemRequest", { requestType = "PROPRIETARY" })
          :Do(function()
              local CorIdSystemRequest = self.mobileSession:SendRPC("SystemRequest", {fileName = "PolicyTableUpdate", requestType = "PROPRIETARY"}, "files/PTU_with_permissions_for_app_0000001.json")
              local systemRequestId
              EXPECT_HMICALL("BasicCommunication.SystemRequest")
              :Do(function(_,data)
                  self.HMIAppID = data.params.appID
                  systemRequestId = data.id
                  self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate",
                    {
                      policyfile = "/tmp/fs/mp/images/ivsu_cache/PolicyTableUpdate"
                    })
                  self.hmiConnection:SendResponse(systemRequestId, "BasicCommunication.SystemRequest", "SUCCESS", {})
                  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UP_TO_DATE"})
                  :Do(
                    function()
                      EXPECT_HMINOTIFICATION("SDL.OnAppPermissionChanged", {appID = self.HMIAppID, appPermissionsConsentNeeded = true})
                      :Do(function(_,_)
                          local RequestIdListOfPermissions = self.hmiConnection:SendRequest("SDL.GetListOfPermissions", { appID = self.applications["Test Application"] })
                          EXPECT_HMIRESPONSE(RequestIdListOfPermissions,
                            { result = {
                                code = 0,
                                allowedFunctions = {{name = "Location"}} },
                              method = "SDL.GetListOfPermissions"})
                          :Do(function(_,data1)
                              local RequestIdGetUserFriendlyMessage = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"Location"}})
                              EXPECT_HMIRESPONSE(RequestIdGetUserFriendlyMessage,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
                              :Do(function(_,_)
                                  local functionalGroupID = data1.result.allowedFunctions[1].id
                                  local function sendConsent()
                                    self.hmiConnection:SendNotification("SDL.OnAppPermissionConsent",
                                      { appID = self.applications["Test Application"], source = "GUI", consentedFunctions = {{name = "Location", allowed = true, id = functionalGroupID} }})
                                    GetCurrentTimeStampGroupConsent()
                                  end
                                  RUN_AFTER(sendConsent, 2000)
                                end)
                            end)
                        end)
                    end
                  )
                  :Timeout(500)
                  self.mobileSession:ExpectResponse(CorIdSystemRequest, {success = true, resultCode = "SUCCESS"})
                end)
            end)
        end)
    end)
  commonTestCases:DelayedExp(4000)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")
function Test:Validate_Snapshot_Values()
  self.hmiConnection:SendNotification("SDL.OnPolicyUpdate")
  EXPECT_HMICALL("BasicCommunication.PolicyUpdate")
  :ValidIf(function(_,data)
      pathToSnapshot = data.params.file
      local valuesFromPTS = GetDataFromSnapshot(pathToSnapshot)
      local verificationValues = {
        deviceConsentTimeStamp = consentDeviceSystemTimeStamp,
        deviceInput = "GUI",
        deviceGroups = "DataConsent-2",
        inputOfAppIdConsent = "GUI",
        groupUserconsentTimeStamp = consentGroupSystemTimeStamp,
        userConsentGroup = "Location-1"
      }
      local msg = ""
      local result = true
      for k, v in pairs(verificationValues) do
        if (type(v) == "number" and (valuesFromPTS[k] > v + 1 or valuesFromPTS[k] < v - 1))
          or (type(v) ~= "number" and v ~= valuesFromPTS[k]) then
            if string.len(msg) > 0 then msg = msg .. "\n" end
            msg = msg .. "Wrong value from snapshot " .. k .. "! Expected: " .. v .. " Actual: " .. tostring(valuesFromPTS[k])
            result = false
        end
      end
      return result, msg
    end)
end

--[[ Postcondition ]]
commonFunctions:newTestCasesGroup("Postcondition")
function Test.Postcondition_StopSDL()
  StopSDL()
end
