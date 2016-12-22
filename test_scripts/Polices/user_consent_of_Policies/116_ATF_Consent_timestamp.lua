---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [Policies] SDL must add a timestamp of the consent in a specific format
--
-- Description:
-- Format of user consent timestamp added to Local PolicyTable.
-- 1. Used preconditions:
-- Start SDL and init HMI
-- Close default connection
-- Overwrite preloaded file to make device not consented
-- Connect device
-- Register app
-- Consent device on HMI
-- 2. Performed steps
-- Check timestamp format is "<yyyy-mm-dd>T<hh:mm:ss>Z" in LPT
--
-- Expected result:
-- PoliciesManager must add a timestamp of user consent for the current mobile device into “time_stamp” field in the format of "<yyyy-mm-dd>T<hh:mm:ss>Z".
---------------------------------------------------------------------------------------------

--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--[[ Required Shared libraries ]]
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local testCasesForPolicyTableSnapshot = require('user_modules/shared_testcases/testCasesForPolicyTableSnapshot')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
require('user_modules/AppTypes')

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")
function Test:Precondition_trigger_getting_device_consent()
  testCasesForPolicyTable:trigger_getting_device_consent(self, config.application1.registerAppInterfaceParams.appName, config.deviceMAC)
end

function Test:Precondition_PoliciesManager_changes_UP_TO_DATE()
  testCasesForPolicyTable:flow_SUCCEESS_EXTERNAL_PROPRIETARY(self)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:TimeStamp_in_userConsentRecords_table()
  local errorFlag = false
  local ErrorMessage = ""
  local TimeStamp_InUserConsentRecordsTable = testCasesForPolicyTableSnapshot:get_data_from_PTS("device_data."..config.deviceMAC..".user_consent_records.device.time_stamp")
  if type(TimeStamp_InUserConsentRecordsTable) ~= 'string' then
    self:FailTestCase("TimeStamp in user_consent_records came wrong")
  end
  if (TimeStamp_InUserConsentRecordsTable ~= nil ) then

    commonFunctions:userPrint(33, "TimeStamp in user_consent_records " .. tostring(TimeStamp_InUserConsentRecordsTable))

    local Date, separatorFirst, Time, separatorSecond = TimeStamp_InUserConsentRecordsTable:match("([%d-]-)([T])([%d:]-)([Z])")
    -- Get current date
    local CurrentDateCommand = assert( io.popen( "date +%Y-%m-%d " , 'r'))
    local CurrentDate = CurrentDateCommand:read( '*l' )
    if Date then
      if Date ~= CurrentDate then
        ErrorMessage = ErrorMessage .. "Date in user_consent_records is not equal to current date. Date from user_consent_records is " .. tostring(Date) .. ", current date is " .. tostring(CurrentDate) .. ". \n"
        errorFlag = true
      end
    else
      ErrorMessage = ErrorMessage .."Date in user_consent_records is wrong or absent. \n"
      errorFlag = true
    end

    -- Get current time
    if Time then
      local CurrentTimeCommand = assert( io.popen( "date +%H:%M" , 'r'))
      local TimeForPermissionConsentValue = CurrentTimeCommand:read( '*l' )
      local CurrentTimeSeconds = assert( io.popen( "date +%H:%M:%S" , 'r'))
      local TimeToCheckSeconds = CurrentTimeSeconds:read( '*l' )

      --TODO(istoimenova): Should be taken in account difference of ~2sec. In case time SDL: 12:21:59 and local time 12:22:01 will return error
      if( string.sub(Time,1,string.len(TimeForPermissionConsentValue)) ~= TimeForPermissionConsentValue ) then
        ErrorMessage = ErrorMessage .. "Time in user_consent_records is not equal to time of device consent. Time from user_consent_records is " .. tostring(Time) .. ", time to check is " .. tostring(TimeToCheckSeconds) .. " +- 1 second. \n"
        errorFlag = true
      end
    else
      ErrorMessage = ErrorMessage .."Time in user_consent_records is wrong or absent. \n"
      errorFlag = true
    end

    if separatorFirst then
      if separatorFirst ~= "T" then
        ErrorMessage = ErrorMessage .. "Separator 'T' between date and time in user_consent_records is not equal to 'T'. Separator from user_consent_records is " .. tostring(separatorFirst) .. ". \n"
        errorFlag = true
      end
    else
      ErrorMessage = ErrorMessage .."Separator 'T' between date and time in user_consent_records is wrong or absent. \n"
      errorFlag = true
    end
    if separatorSecond then
      if separatorSecond ~= "Z" then
        ErrorMessage = ErrorMessage .. "Separator 'Z' after date and time in user_consent_records is not equal to 'Z'. Separator from user_consent_records is " .. tostring(separatorSecond) .. ". \n"
        errorFlag = true
      end
    else
      ErrorMessage = ErrorMessage .."Separator 'Z' after date and time in user_consent_records is wrong or absent. \n"
      errorFlag = true
    end
  else
    ErrorMessage = ErrorMessage .. "TimeStamp is absent or empty in user_consent_records. \n"
    errorFlag = true
  end
  if errorFlag == true then
    self:FailTestCase(ErrorMessage)
  end
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_StopSDL()
  StopSDL()
end

return Test
