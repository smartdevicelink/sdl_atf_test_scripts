-- Script is developed by Byanova Irina
-- for ATF version 2.2
--------------------------------------------------------------------------------
-- Preconditions before ATF start
--------------------------------------------------------------------------------
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
--------------------------------------------------------------------------------
--Precondition: preparation connecttest_QDB_initial.lua
commonPreconditions:Connecttest_without_ExitBySDLDisconnect_WithoutOpenConnectionRegisterApp("connecttest_QDB_initial.lua", true)

f = assert(io.open('./user_modules/connecttest_QDB_initial.lua', "r"))

fileContent = f:read("*all")
f:close()

local pattern1 = "require%s-%(%s-'%s-testbase%s-'%s-%)"
local pattern1Result = fileContent:match(pattern1)

if pattern1Result == nil then
  print(" \27[31m require('testbase') is not found in /user_modules/connecttest_QDB_initial.lua \27[0m ")
else
  fileContent = string.gsub(fileContent, pattern1, "require('user_modules/testbase_QDB_initial')")
end

f = assert(io.open('./user_modules/connecttest_QDB_initial.lua', "w"))
f:write(fileContent)
f:close()

-- update testbase
os.execute( 'cp ./modules/testbase.lua ./user_modules/testbase_QDB_initial.lua')

f_test = assert(io.open('./user_modules/testbase_QDB_initial.lua', "r"))

fileContent_test = f_test:read("*all")
f_test:close()

local pattern1 = "critical%(SDL.exitOnCrash%)"
local pattern1Result = fileContent_test:match(pattern1)

if pattern1Result == nil then
  print(" \27[31m critical(SDL.exitOnCrash) is not found in /user_modules/testbase_QDB_initial.lua \27[0m ")
else
  fileContent_test = string.gsub(fileContent_test, pattern1, "")
end
f_test = assert(io.open('./user_modules/testbase_QDB_initial.lua', "w"))
f_test:write(fileContent_test)
f_test:close()

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

Test = require('user_modules/connecttest_QDB_initial')
require('cardinalities')
require('user_modules/AppTypes')
local SDL = require('SDL')
----------------------------------------------------------------------------
-- User required files

require('user_modules/AppTypes')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')

function DelayedExp(time)
  local event = events.Event()
  event.matches = function(self, e) return self == e end
  EXPECT_EVENT(event, "Delayed event")
  :Timeout(time+1000)
  RUN_AFTER(function()
      RAISE_EVENT(event, event)
      end, time)
  end

  -- Check direcrory existence
  local function Directory_exist(DirectoryPath)
    local returnValue

    local Command = assert( io.popen( "[ -d " .. tostring(DirectoryPath) .. " ] && echo \"Exist\" || echo \"NotExist\"" , 'r'))
    local CommandResult = tostring(Command:read( '*l' ))

    if
    CommandResult == "NotExist" then
      returnValue = false
    elseif
      CommandResult == "Exist" then
        returnValue = true
      else
        commonFunctions:userPrint(31," Some unexpected result in Directory_exist function, CommandResult = " .. tostring(CommandResult))
        returnValue = false
      end

      return returnValue
    end

    local function SetNewValuesInIniFile(self, paramName, value)

      commonPreconditions:BackupFile("smartDeviceLink.ini")
      local SDLini = config.pathToSDL .. tostring("smartDeviceLink.ini")
      f = assert(io.open(SDLini, "r"))
      if f then
        fileContent = f:read("*all")

        if value == ";" then
          fileContentUpdated = string.gsub(fileContent, "%p?" .. tostring(paramName) .. "%s-=%s?[%d;-]-\n", ";" .. tostring(paramName) .. " = \n")
        else
          fileContentUpdated = string.gsub(fileContent, "%p?" .. tostring(paramName) .. "%s-=%s?[%d;-]-\n", "" .. tostring(paramName) .. " = " .. tostring(value) .. "\n")
        end

        if fileContentUpdated then
          f = assert(io.open(SDLini, "w"))
          f:write(fileContentUpdated)
        else
          commonFunctions:userPrint(31, "Finding of 'ApplicationResumingTimeout = value' is failed. Expect string finding and replacing of value to true")
        end
        f:close()
      else
        commonFunctions:userPrint(31, "File smartDeviceLink.ini is not opened.")
      end
    end

    local function WaitForStopSDL(self)
      local status = SDL:CheckStatusSDL()
      local timer =0
      while status == SDL.RUNNING and timer < 5 do
        sleep(1)
        timer = timer+1
        status = SDL:CheckStatusSDL()
      end
      status = SDL:CheckStatusSDL()
      if status == SDL.RUNNING then
        self:FailTestCase("SDL didn't finish correctly")
        StopSDL()
      end
    end

    -- Precondition: removing user connecttest ant testbase
    function Test:Precondition_remove_user_connecttest_testbase()
      os.execute( "rm -f ./user_modules/connecttest_QDB_initial.lua" )
      os.execute( "rm -f ./user_modules/testbase_QDB_initial.lua" )
    end

    function Test:StopSDL()
      commonFunctions:userPrint(35, "\n================= Precondition ==================")
      StopSDL()
    end

    ----------------------------------------------------------------------------
    --======================================================================================--
    -- SDL shuts down after 5 attemps to open PT with interval 500 ms in case SDL can not open PT
    --======================================================================================--

    function Test:RemovePermissionsFromPT()

      local RemovePermissionsFromPT = assert(os.execute("chmod 000 " .. tostring(config.pathToSDL) .. "storage/policy.sqlite"))

      if not RemovePermissionsFromPT then
        self:FailTestCase(" Command of removing permissions for policy.sqlite is not success")
      end

    end

    function Test:StartSDL()
      StartSDL(config.pathToSDL, false)
    end

    function Test:SDL_shuts_down_after_5Attemps_toOpenPT()
      commonFunctions:userPrint(34, "=================== Test Case ===================")
      commonFunctions:userPrint(33, " Check SDL log. Must contain 5 atteps of connection to PT with the interval of 500ms between retries ")
      commonFunctions:userPrint(33, "Status of test case can be 'FAIL' in case using ATF2.2 because SDL is shuted down. Please ignore this ATF issue ")

      os.execute(" sleep 2 ")

      local GetPIDsmartDeviceLinkCore = assert(io.popen("pidof smartDeviceLinkCore"))

      local Result = GetPIDsmartDeviceLinkCore:read( '*l' )

      if
      Result and
      Result ~= "" then
        self:FailTestCase(" smartDeviceLinkCore process is not stopped ")
      end
    end

    --======================================================================================--
    -- SDL continues work in case opens PT after some unsuccessful attempts
    --======================================================================================--

    function Test:SetOpenAttemptTimeoutMs_6000()
      commonFunctions:userPrint(35, "\n================= Precondition ==================")
      SetNewValuesInIniFile(self, "OpenAttemptTimeoutMs", "6000")
    end

    function Test:StartSDL_GivePermissionsToPTAfterSDLStart()
      commonFunctions:userPrint(34, "=================== Test Case ===================")

      WaitForStopSDL(self)
      StartSDL(config.pathToSDL, false)

      local GivePermissionsToPT = assert(os.execute("chmod 600 " .. tostring(config.pathToSDL) .. "storage/policy.sqlite"))
      os.execute("date")
      commonFunctions:userPrint(33, " Check the printed time of command execution and time of attemps to open PT. Time of command execution must be between attemps. ")

      if not GivePermissionsToPT then
        self:FailTestCase(" Command of adding permissions for policy.sqlite is not success")
      end

    end

    function Test:CheckProcess_smartDeviceLinkCore_StilLive_GivePermissionsToPTAfterSDLStart()
      function GetPID()
        local GetPIDsmartDeviceLinkCore = assert(io.popen("pidof smartDeviceLinkCore"))

        local Result = GetPIDsmartDeviceLinkCore:read( '*l' )

        print(" Result " .. tostring(Result) )
        if
        not Result or
        Result == nil or
        (Result and
          Result == "") then
          self:FailTestCase(" smartDeviceLinkCore process is stopped ")
        end
      end

      RUN_AFTER(GetPID, 30000)

      DelayedExp(35000)
      commonPreconditions:RestoreFile("smartDeviceLink.ini")

    end

    -- ======================================================================================--
    -- SDL continues work in case opens PT during last attempt
    -- ======================================================================================--

    function Test:StopSDL_GetPermissions_before_last_attempt()
      commonFunctions:userPrint(35, "\n================= Precondition ==================")
      StopSDL()
    end

    function Test:SetOpenAttemptTimeoutMs_60000_AttemptsToOpenPolicyDB_2_Remove_permissions()

      local RemovePermissionsFromPT = assert(os.execute("chmod 000 " .. tostring(config.pathToSDL) .. "storage/policy.sqlite"))

      if not RemovePermissionsFromPT then
        self:FailTestCase(" Command of removing permissions for policy.sqlite is not success")
      end

      SetNewValuesInIniFile(self, "OpenAttemptTimeoutMs", "50000")
      SetNewValuesInIniFile(self, "AttemptsToOpenPolicyDB", "2")
    end

    function Test:StartSDL_GivePermissionsToPTBeforeLastAttempt()
      commonFunctions:userPrint(34, "=================== Test Case ===================")
      commonFunctions:userPrint(33, "Test case is executing about 2 min. Please wait.")
      WaitForStopSDL(self)
      StartSDL(config.pathToSDL, false)

      function to_run()

        local GivePermissionsToPT = assert(os.execute("chmod 600 " .. tostring(config.pathToSDL) .. "storage/policy.sqlite"))
        os.execute("date")
        commonFunctions:userPrint(33, " Check the printed time of command execution and time of attemps to open PT. Time of command execution must be between attemps. ")

        if not GivePermissionsToPT then
          self:FailTestCase(" Command of adding permissions for policy.sqlite is not success")
        end
      end

      RUN_AFTER(to_run, 50000)

      DelayedExp(52000)

    end

    function Test:CheckProcess_smartDeviceLinkCore_StilLive_GivePermissionsToPTBeforeLastAttempt()
      function GetPID()
        local GetPIDsmartDeviceLinkCore = assert(io.popen("pidof smartDeviceLinkCore"))

        local Result = GetPIDsmartDeviceLinkCore:read( '*l' )

        print(" Result " .. tostring(Result) )
        if
        not Result or
        Result == nil or
        (Result and
          Result == "") then
          self:FailTestCase(" smartDeviceLinkCore process is stopped ")
        end
      end

      RUN_AFTER(GetPID, 50000)

      DelayedExp(55000)
      commonPreconditions:RestoreFile("smartDeviceLink.ini")

    end

    --======================================================================================--
    -- SDL applies custom values of AttemptsToOpenPolicyDB, OpenAttemptTimeoutMs from .ini file
    --======================================================================================--

    function Test:StopSDL_CustomValuesOf_AttemptsToOpenPolicyDBTo10_OpenAttemptTimeoutMsTo1500()
      commonFunctions:userPrint(35, "\n================= Precondition ==================")
      StopSDL()
    end

    function Test:RemovePermissionsFromPT_SetAttemptsToOpenPolicyDBTo10_OpenAttemptTimeoutMs1500()

      local RemovePermissionsFromPT = assert(os.execute("chmod 000 " .. tostring(config.pathToSDL) .. "storage/policy.sqlite"))

      if not RemovePermissionsFromPT then
        self:FailTestCase(" Command of removing permissions for policy.sqlite is not success")
      end

      SetNewValuesInIniFile(self, "AttemptsToOpenPolicyDB", "10")
      SetNewValuesInIniFile(self, "OpenAttemptTimeoutMs", "1500")
    end

    function Test:StartSDL_CustomValuesOf_AttemptsToOpenPolicyDBTo10_OpenAttemptTimeoutMs()
      WaitForStopSDL(self)
      StartSDL(config.pathToSDL, false)
    end

    function Test:SDL_shuts_down_after_10AttempsWithInterval1500_toOpenPT()
      commonFunctions:userPrint(34, "=================== Test Case ===================")
      commonFunctions:userPrint(33, " Check SDL log. Must contain 10 atteps of connection to PT with the interval of 1500ms between retries ")
      commonFunctions:userPrint(33, "Status of test case can be 'FAIL' in case using ATF2.2 because SDL is shuted down. Please ignore this ATF issue ")

      os.execute(" sleep 15 ")

      local GetPIDsmartDeviceLinkCore = assert(io.popen("pidof smartDeviceLinkCore"))

      local Result = GetPIDsmartDeviceLinkCore:read( '*l' )
      if
      Result and
      Result ~= "" then
        self:FailTestCase(" smartDeviceLinkCore process is not stopped ")
      end
      commonPreconditions:RestoreFile("smartDeviceLink.ini")
    end

    --======================================================================================--
    -- SDL applies lower value of AttemptsToOpenPolicyDB from .ini file
    --======================================================================================--

    function Test:StopSDL_AttemptsToOpenPolicyDB_lowerBound()
      commonFunctions:userPrint(35, "\n================= Precondition ==================")
      StopSDL()
    end

    function Test:RemovePermissionsFromPT_SetAttemptsToOpenPolicyDBTo_lowerBound()

      local RemovePermissionsFromPT = assert(os.execute("chmod 000 " .. tostring(config.pathToSDL) .. "storage/policy.sqlite"))

      if not RemovePermissionsFromPT then
        self:FailTestCase(" Command of removing permissions for policy.sqlite is not success")
      end

      SetNewValuesInIniFile(self, "AttemptsToOpenPolicyDB", "0")
      SetNewValuesInIniFile(self, "OpenAttemptTimeoutMs", "500")
    end

    function Test:StartSDL_AttemptsToOpenPolicyDB_lowerBound()
      WaitForStopSDL(self)
      StartSDL(config.pathToSDL, false)
    end

    function Test:SDL_shuts_down_after_0Attemps_toOpenPT()
      commonFunctions:userPrint(34, "=================== Test Case ===================")
      commonFunctions:userPrint(33, " Check SDL log. Must contain 0 atteps of connection to PT ")
      commonFunctions:userPrint(33, "Status of test case can be 'FAIL' in case using ATF2.2 because SDL is shuted down. Please ignore this ATF issue ")

      os.execute(" sleep 0.5 ")

      local GetPIDsmartDeviceLinkCore = assert(io.popen("pidof smartDeviceLinkCore"))

      local Result = GetPIDsmartDeviceLinkCore:read( '*l' )
      if
      Result and
      Result ~= "" then
        self:FailTestCase(" smartDeviceLinkCore process is not stopped ")
      end
      commonPreconditions:RestoreFile("smartDeviceLink.ini")
    end

    --======================================================================================--
    -- SDL applies lower value of OpenAttemptTimeoutMs from .ini file
    --======================================================================================--

    function Test:StopSDL_OpenAttemptTimeoutMs_lowerBound()
      commonFunctions:userPrint(35, "\n================= Precondition ==================")
      StopSDL()
    end

    function Test:RemovePermissionsFromPT_SetOpenAttemptTimeoutMsTo_lowerBound()

      local RemovePermissionsFromPT = assert(os.execute("chmod 000 " .. tostring(config.pathToSDL) .. "storage/policy.sqlite"))

      if not RemovePermissionsFromPT then
        self:FailTestCase(" Command of removing permissions for policy.sqlite is not success")
      end

      SetNewValuesInIniFile(self, "AttemptsToOpenPolicyDB", "5")
      SetNewValuesInIniFile(self, "OpenAttemptTimeoutMs", "0")
    end

    function Test:StartSDL_OpenAttemptTimeoutMs_lowerBound()
      WaitForStopSDL(self)
      StartSDL(config.pathToSDL, false)
    end

    function Test:SDL_shuts_down_after_5AttempsWithInterval_0_toOpenPT()
      commonFunctions:userPrint(34, "=================== Test Case ===================")
      commonFunctions:userPrint(33, " Check SDL log. Must contain 5 atteps of connection to PT with the interval of 0ms between retries ")
      commonFunctions:userPrint(33, "Status of test case can be 'FAIL' in case using ATF2.2 because SDL is shuted down. Please ignore this ATF issue ")

      os.execute(" sleep 15 ")

      local GetPIDsmartDeviceLinkCore = assert(io.popen("pidof smartDeviceLinkCore"))

      local Result = GetPIDsmartDeviceLinkCore:read( '*l' )
      if
      Result and
      Result ~= "" then
        self:FailTestCase(" smartDeviceLinkCore process is not stopped ")
      end
      commonPreconditions:RestoreFile("smartDeviceLink.ini")
    end

    --======================================================================================--
    -- SDL applies big value of AttemptsToOpenPolicyDB from .ini file
    --======================================================================================--

    function Test:StopSDL_AttemptsToOpenPolicyDB_60000()
      commonFunctions:userPrint(35, "\n================= Precondition ==================")
      StopSDL()
    end

    function Test:RemovePermissionsFromPT_SetAttemptsToOpenPolicyDBTo_60000()

      local RemovePermissionsFromPT = assert(os.execute("chmod 000 " .. tostring(config.pathToSDL) .. "storage/policy.sqlite"))

      if not RemovePermissionsFromPT then
        self:FailTestCase(" Command of removing permissions for policy.sqlite is not success")
      end

      --TODO: update value of AttemptsToOpenPolicyDB to upper bound after resolving APPLINK-22644
      SetNewValuesInIniFile(self, "AttemptsToOpenPolicyDB", "60000")
      SetNewValuesInIniFile(self, "OpenAttemptTimeoutMs", "1")
    end

    function Test:StartSDL_AttemptsToOpenPolicyDB_60000()
      WaitForStopSDL(self)
      StartSDL(config.pathToSDL, false)
    end

    function Test:SDL_shuts_down_after_60000AttempsWithInterval1ms_toOpenPT()
      commonFunctions:userPrint(34, "=================== Test Case ===================")
      commonFunctions:userPrint(33, " Check SDL log. Must contain 60000 atteps of connection to PT with the interval of 1ms between retries ")
      commonFunctions:userPrint(33, " Status of test case can be 'FAIL' because SDL is shuted down. Please ignore this ATF issue ")
      commonFunctions:userPrint(33, " Test case is executing about 60 secs. Please wait. ")

      os.execute(" sleep 65 ")

      local GetPIDsmartDeviceLinkCore = assert(io.popen("pidof smartDeviceLinkCore"))

      local Result = GetPIDsmartDeviceLinkCore:read( '*l' )
      if
      Result and
      Result ~= "" then
        self:FailTestCase(" smartDeviceLinkCore process is not stopped ")
      end
      commonPreconditions:RestoreFile("smartDeviceLink.ini")
    end

    -- ======================================================================================--
    -- SDL applies big value of OpenAttemptTimeoutMs from .ini file
    -- ======================================================================================--

    function Test:StopSDL_OpenAttemptTimeoutMs_60000()
      commonFunctions:userPrint(35, "\n================= Precondition ==================")
      StopSDL()
    end

    function Test:RemovePermissionsFromPT_SetOpenAttemptTimeoutMsTo_60000()

      local RemovePermissionsFromPT = assert(os.execute("chmod 000 " .. tostring(config.pathToSDL) .. "storage/policy.sqlite"))

      if not RemovePermissionsFromPT then
        self:FailTestCase(" Command of removing permissions for policy.sqlite is not success")
      end

      SetNewValuesInIniFile(self, "AttemptsToOpenPolicyDB", "2")
      --TODO: update value of AttemptsToOpenPolicyDB to upper bound after resolving APPLINK-22644
      SetNewValuesInIniFile(self, "OpenAttemptTimeoutMs", "60000")
    end

    function Test:StartSDL_OpenAttemptTimeoutMs_60000()
      WaitForStopSDL(self)
      StartSDL(config.pathToSDL, false)
    end

    function Test:SDL_shuts_down_after_2AttempsWithInterval_60000_toOpenPT()
      commonFunctions:userPrint(34, "=================== Test Case ===================")
      commonFunctions:userPrint(33, " Check SDL log. Must contain 1 atteps of connection to PT with the interval of 60000ms between retries ")
      commonFunctions:userPrint(33, "Status of test case can be 'FAIL' because SDL is shuted down. Please ignore this ATF issue ")
      commonFunctions:userPrint(33, " Test case is executing about 2 min. Please wait. ")

      os.execute(" sleep 120 ")

      local GetPIDsmartDeviceLinkCore = assert(io.popen("pidof smartDeviceLinkCore"))

      local Result = GetPIDsmartDeviceLinkCore:read( '*l' )
      if
      Result and
      Result ~= "" then
        self:FailTestCase(" smartDeviceLinkCore process is not stopped ")
      end
      commonPreconditions:RestoreFile("smartDeviceLink.ini")
    end

    --======================================================================================--
    -- SDL applies default values for AttemptsToOpenPolicyDB, OpenAttemptTimeoutMs in case .ini file values are empty
    --======================================================================================--

    function Test:StopSDL_DefaultValuesOf_AttemptsToOpenPolicyDBTo10_OpenAttemptTimeoutMs()
      commonFunctions:userPrint(35, "\n================= Precondition ==================")
      local GetPIDsmartDeviceLinkCore = assert(io.popen("pidof smartDeviceLinkCore"))

      local Result = GetPIDsmartDeviceLinkCore:read( '*l' )
      if
      Result and
      Result ~= "" then
        StopSDL()
      end

    end

    function Test:RemovePermissionsFromPT_SetEmptyValuesToAttemptsToOpenPolicyDBTo_OpenAttemptTimeoutMs()

      local RemovePermissionsFromPT = assert(os.execute("chmod 000 " .. tostring(config.pathToSDL) .. "storage/policy.sqlite"))

      if not RemovePermissionsFromPT then
        self:FailTestCase(" Command of removing permissions for policy.sqlite is not success")
      end

      SetNewValuesInIniFile(self, "AttemptsToOpenPolicyDB", "")
      SetNewValuesInIniFile(self, "OpenAttemptTimeoutMs", "")
    end

    function Test:StartSDL_DefaultValuesOf_AttemptsToOpenPolicyDB_5_OpenAttemptTimeoutMs_500()
      WaitForStopSDL(self)
      StartSDL(config.pathToSDL, false)
    end

    function Test:SDL_shuts_down_after_5AttempsWithInterval500_toOpenPT_DefaultValues()
      commonFunctions:userPrint(34, "=================== Test Case ===================")
      commonFunctions:userPrint(33, " Check SDL log. Must contain 5 atteps of connection to PT with the interval of 500ms between retries ")
      commonFunctions:userPrint(33, "Status of test case can be 'FAIL' in case using ATF2.2 because SDL is shuted down. Please ignore this ATF issue ")

      os.execute(" sleep 5 ")

      local GetPIDsmartDeviceLinkCore = assert(io.popen("pidof smartDeviceLinkCore"))

      local Result = GetPIDsmartDeviceLinkCore:read( '*l' )
      if
      Result and
      Result ~= "" then
        self:FailTestCase(" smartDeviceLinkCore process is not stopped ")
      end
      commonPreconditions:RestoreFile("smartDeviceLink.ini")
    end

    --======================================================================================--
    -- SDL applies default values for AttemptsToOpenPolicyDB in case .ini file value is negative
    --======================================================================================--

    function Test:StopSDL_DefaultValuesOf_AttemptsToOpenPolicyDB_5_InCaseInIniFileValueIsNegative()
      commonFunctions:userPrint(35, "\n================= Precondition ==================")
      local GetPIDsmartDeviceLinkCore = assert(io.popen("pidof smartDeviceLinkCore"))

      local Result = GetPIDsmartDeviceLinkCore:read( '*l' )
      if
      Result and
      Result ~= "" then
        StopSDL()
      end

    end

    function Test:RemovePermissionsFromPT_SetNegativeValueToAttemptsToOpenPolicyDB()

      local RemovePermissionsFromPT = assert(os.execute("chmod 000 " .. tostring(config.pathToSDL) .. "storage/policy.sqlite"))

      if not RemovePermissionsFromPT then
        self:FailTestCase(" Command of removing permissions for policy.sqlite is not success")
      end

      SetNewValuesInIniFile(self, "AttemptsToOpenPolicyDB", "-2")
      SetNewValuesInIniFile(self, "OpenAttemptTimeoutMs", "1000")
    end

    function Test:StartSDL_DefaultValuesOf_AttemptsToOpenPolicyDB_5_InCaseInIniFileValueIsNegative()
      WaitForStopSDL(self)
      StartSDL(config.pathToSDL, false)
    end

    function Test:SDL_shuts_down_after_5AttempsWithInterval1000_toOpenPT_AttemptsToOpenPolicyDB_DefaultValue()
      commonFunctions:userPrint(34, "=================== Test Case ===================")
      commonFunctions:userPrint(33, " Check SDL log. Must contain 5 atteps of connection to PT with the interval of 1000ms between retries ")
      commonFunctions:userPrint(33, "Status of test case can be 'FAIL' in case using ATF2.2 because SDL is shuted down. Please ignore this ATF issue ")

      os.execute(" sleep 5 ")

      local GetPIDsmartDeviceLinkCore = assert(io.popen("pidof smartDeviceLinkCore"))

      local Result = GetPIDsmartDeviceLinkCore:read( '*l' )
      if
      Result and
      Result ~= "" then
        self:FailTestCase(" smartDeviceLinkCore process is not stopped ")
      end
      commonPreconditions:RestoreFile("smartDeviceLink.ini")
    end

    -- ======================================================================================--
    -- SDL applies default values for OpenAttemptTimeoutMs in case .ini file value is negative
    -- ======================================================================================--

    function Test:StopSDL_DefaultValuesOf_OpenAttemptTimeoutMs_500_InCaseInIniFileValueIsNegative()
      commonFunctions:userPrint(35, "\n================= Precondition ==================")
      local GetPIDsmartDeviceLinkCore = assert(io.popen("pidof smartDeviceLinkCore"))

      local Result = GetPIDsmartDeviceLinkCore:read( '*l' )
      if
      Result and
      Result ~= "" then
        StopSDL()
      end

    end

    function Test:RemovePermissionsFromPT_SetNegativeValueToOpenAttemptTimeoutMs()

      local RemovePermissionsFromPT = assert(os.execute("chmod 000 " .. tostring(config.pathToSDL) .. "storage/policy.sqlite"))

      if not RemovePermissionsFromPT then
        self:FailTestCase(" Command of removing permissions for policy.sqlite is not success")
      end

      SetNewValuesInIniFile(self, "AttemptsToOpenPolicyDB", "7")
      SetNewValuesInIniFile(self, "OpenAttemptTimeoutMs", "-1000")
    end

    function Test:StartSDL_DefaultValuesOf_OpenAttemptTimeoutMs_500_InCaseInIniFileValueIsNegative()
      WaitForStopSDL(self)
      StartSDL(config.pathToSDL, false)
    end

    function Test:SDL_shuts_down_after_7AttempsWithInterval500_toOpenPT_OpenAttemptTimeoutMs_DefaultValue()
      commonFunctions:userPrint(34, "=================== Test Case ===================")
      commonFunctions:userPrint(33, " Check SDL log. Must contain 7 atteps of connection to PT with the interval of 500ms between retries ")
      commonFunctions:userPrint(33, "Status of test case can be 'FAIL' in case using ATF2.2 because SDL is shuted down. Please ignore this ATF issue ")

      os.execute(" sleep 4 ")

      local GetPIDsmartDeviceLinkCore = assert(io.popen("pidof smartDeviceLinkCore"))

      local Result = GetPIDsmartDeviceLinkCore:read( '*l' )
      if
      Result and
      Result ~= "" then
        self:FailTestCase(" smartDeviceLinkCore process is not stopped ")
      end
      commonPreconditions:RestoreFile("smartDeviceLink.ini")
    end

    --======================================================================================--
    -- SDL applies default values for AttemptsToOpenPolicyDB in case .ini file parameter is absent
    --======================================================================================--

    function Test:StopSDL_DefaultValuesOf_AttemptsToOpenPolicyDB_5_InCaseInIniFileParamIsAbsent()
      commonFunctions:userPrint(35, "\n================= Precondition ==================")
      local GetPIDsmartDeviceLinkCore = assert(io.popen("pidof smartDeviceLinkCore"))

      local Result = GetPIDsmartDeviceLinkCore:read( '*l' )
      if
      Result and
      Result ~= "" then
        StopSDL()
      end

    end

    function Test:RemovePermissionsFromPT_CommentAttemptsToOpenPolicyDB()

      local RemovePermissionsFromPT = assert(os.execute("chmod 000 " .. tostring(config.pathToSDL) .. "storage/policy.sqlite"))

      if not RemovePermissionsFromPT then
        self:FailTestCase(" Command of removing permissions for policy.sqlite is not success")
      end

      SetNewValuesInIniFile(self, "AttemptsToOpenPolicyDB", ";")
      SetNewValuesInIniFile(self, "OpenAttemptTimeoutMs", "1000")
    end

    function Test:StartSDL_DefaultValuesOf_AttemptsToOpenPolicyDB_5_InCaseInIniFileParamIsAbsent()
      WaitForStopSDL(self)
      StartSDL(config.pathToSDL, false)
    end

    function Test:SDL_shuts_down_after_5AttempsWithInterval1000_toOpenPT_AttemptsToOpenPolicyDB_DefaultValue_InCaseInIniFileParamIsAbsen()
      commonFunctions:userPrint(34, "=================== Test Case ===================")
      commonFunctions:userPrint(33, " Check SDL log. Must contain 5 atteps of connection to PT with the interval of 1000ms between retries ")
      commonFunctions:userPrint(33, "Status of test case can be 'FAIL' in case using ATF2.2 because SDL is shuted down. Please ignore this ATF issue ")

      os.execute(" sleep 5 ")

      local GetPIDsmartDeviceLinkCore = assert(io.popen("pidof smartDeviceLinkCore"))

      local Result = GetPIDsmartDeviceLinkCore:read( '*l' )
      if
      Result and
      Result ~= "" then
        self:FailTestCase(" smartDeviceLinkCore process is not stopped ")
      end
      commonPreconditions:RestoreFile("smartDeviceLink.ini")
    end

    -- ======================================================================================--
    -- SDL applies default values for OpenAttemptTimeoutMs in case .ini file parameter is absent
    -- ======================================================================================--

    function Test:StopSDL_DefaultValuesOf_OpenAttemptTimeoutMs_500_InCaseInIniFileParamIsAbsen()
      commonFunctions:userPrint(35, "\n================= Precondition ==================")
      local GetPIDsmartDeviceLinkCore = assert(io.popen("pidof smartDeviceLinkCore"))

      local Result = GetPIDsmartDeviceLinkCore:read( '*l' )
      if
      Result and
      Result ~= "" then
        StopSDL()
      end

    end

    function Test:RemovePermissionsFromPT_CommentToOpenAttemptTimeoutMs()

      local RemovePermissionsFromPT = assert(os.execute("chmod 000 " .. tostring(config.pathToSDL) .. "storage/policy.sqlite"))

      if not RemovePermissionsFromPT then
        self:FailTestCase(" Command of removing permissions for policy.sqlite is not success")
      end

      SetNewValuesInIniFile(self, "AttemptsToOpenPolicyDB", "7")
      SetNewValuesInIniFile(self, "OpenAttemptTimeoutMs", ";")
    end

    function Test:StartSDL_DefaultValuesOf_OpenAttemptTimeoutMs_500_InCaseInIniFileParamIsAbsen()
      WaitForStopSDL(self)
      StartSDL(config.pathToSDL, false)
    end

    function Test:SDL_shuts_down_after_7AttempsWithInterval500_toOpenPT_OpenAttemptTimeoutMs_DefaultValue_InCaseInIniFileParamIsAbsen()
      commonFunctions:userPrint(34, "=================== Test Case ===================")
      commonFunctions:userPrint(33, " Check SDL log. Must contain 7 atteps of connection to PT with the interval of 500ms between retries ")
      commonFunctions:userPrint(33, "Status of test case can be 'FAIL' in case using ATF2.2 because SDL is shuted down. Please ignore this ATF issue ")

      os.execute(" sleep 4 ")

      local GetPIDsmartDeviceLinkCore = assert(io.popen("pidof smartDeviceLinkCore"))

      local Result = GetPIDsmartDeviceLinkCore:read( '*l' )
      if
      Result and
      Result ~= "" then
        self:FailTestCase(" smartDeviceLinkCore process is not stopped ")
      end
      commonPreconditions:RestoreFile("smartDeviceLink.ini")
    end

    -- ======================================================================================--
    -- Postcondition: Set defaut values of SetAttemptsToOpenPolicyDB and OpenAttemptTimeoutMs, remove Storage folder
    -- ======================================================================================--

    function Test:ResporeIniFileToOriginal_DeleteStorageFolder()
      commonFunctions:userPrint(35, "\n================ Postcondition ==================")
      commonSteps:RestoreIniFile()

      local ExistDirectoryResult = Directory_exist( tostring(config.pathToSDL .. "storage"))
      if ExistDirectoryResult == true then
        local RmFolder = assert( os.execute( "rm -rf " .. tostring(config.pathToSDL .. "storage" )))
        if RmFolder ~= true then
          userPrint(31, "Folder 'storage' is not deleted")
        end
      else
        userPrint(33, "Folder 'storage' is absent")
      end

    end

