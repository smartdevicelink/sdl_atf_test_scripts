---------------------------------------------------------------------------------------------
-- Requirements summary:
-- [PolicyTableUpdate] Restarting Policy Table Exchange
--
-- Description:
--Policy Manager must restart retry sequence within the same ignition cycle only if
--anything triggers Policy Table Update request.

-- Build SDL with flag above
-- 1. Used preconditions:
-- SDL is built with "-DEXTENDED_POLICY: HTTP" flag
-- First SDL life cycle
-- App is registered
-- PTU is not finished after retry
-- 2. Performed steps
-- New application is registered and PTU is triggered
-- Expected result:
-- SDL: Starts PTU sequence
-- SDL->HMI: OnStatusUpdate("UPDATE_NEEDED")
-- PTS is created by SDL.....//PTU started
-- SDL->app: OnSystemRequest()

---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "HTTP" } } })

--[[ General configuration parameters ]]
--ToDo: shall be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local commonSteps = require ('user_modules/shared_testcases/commonSteps')
local commonTestCases = require ('user_modules/shared_testcases/commonTestCases')

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()

--[[ Local Variables ]]
local seconds_between_retries = {1, 1, 1, 1, 1} -- in min
local timeout_after_x_seconds = 8 -- in sec
local timeout = {} -- in sec
timeout[1] = timeout_after_x_seconds -- 8
timeout[2] = timeout_after_x_seconds + seconds_between_retries[1] -- 8 + 1 = 9
timeout[3] = timeout_after_x_seconds + seconds_between_retries[2] + timeout[2] -- 8 + 1 + 9 = 18
timeout[4] = timeout_after_x_seconds + seconds_between_retries[3] + timeout[3] -- 8 + 1 + 18 = 27
timeout[5] = timeout_after_x_seconds + seconds_between_retries[4] + timeout[4] -- 8 + 1 + 27 = 36
timeout[6] = timeout_after_x_seconds + seconds_between_retries[5] + timeout[5] -- 8 + 1 + 36 = 45

local onsysrequest_app1 = false
local onsysrequest_app2 = false

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
local mobile_session = require('mobile_session')

--[[ Local Functions ]]
local function BackupPreloaded()
  os.execute('cp ' .. config.pathToSDL .. 'sdl_preloaded_pt.json' .. ' ' .. config.pathToSDL .. 'backup_sdl_preloaded_pt.json')
  os.execute('rm ' .. config.pathToSDL .. 'policy.sqlite')
end

local function RestorePreloadedPT()
  os.execute('rm ' .. config.pathToSDL .. 'sdl_preloaded_pt.json')
  os.execute('cp ' .. config.pathToSDL .. 'backup_sdl_preloaded_pt.json' .. ' ' .. config.pathToSDL .. 'sdl_preloaded_pt.json')
end

local function SetRetryValuesInPreloadedFile()
  local pathToFile = config.pathToSDL .. 'sdl_preloaded_pt.json'
  local file = io.open(pathToFile, "r")
  local json_data = file:read("*all") -- may be abbreviated to "*a";
  file:close()
  local json = require("modules/json")
  local data = json.decode(json_data)

  if data.policy_table.functional_groupings["DataConsent-2"] then
    data.policy_table.functional_groupings["DataConsent-2"] = nil
  end
  data.policy_table.module_config.seconds_between_retries = seconds_between_retries
  data.policy_table.module_config.timeout_after_x_seconds = timeout_after_x_seconds
  data = json.encode(data)
  file = io.open(pathToFile, "w")
  file:write(data)
  file:close()
end

  --[[ Preconditions ]]
  function Test.Precondition_StopSDL()
    StopSDL()
  end

  function Test.Precondition_DeleteLogsAndPolicyTable()
    commonSteps:DeleteLogsFiles()
    commonSteps:DeletePolicyTable()
  end

  function Test.Precondition_Backup_sdl_preloaded_pt()
    BackupPreloaded()
  end

  function Test.Precondition_Set_Retry_Values_In_Preloaded_File()
    SetRetryValuesInPreloadedFile()
  end

  function Test.Precondition_StartSDL_FirstLifeCycle()
    StartSDL(config.pathToSDL, config.ExitOnCrash)
  end

  function Test:Precondition_InitHMI_FirstLifeCycle()
    self:initHMI()
  end

  function Test:Precondition_InitHMI_onReady_FirstLifeCycle()
    self:initHMI_onReady()
  end

  function Test:Precondition_ConnectMobile_FirstLifeCycle()
    self:connectMobile()
  end

  function Test:Precondition_StartSession()
    self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
    self.mobileSession:StartService(7)
  end

  function Test.Precondition_RestorePreloadedPT()
    RestorePreloadedPT()
  end

  --[[ Test ]]
  function Test:TestStep_Register_App_And_Check_Retry_Timeouts()
    local totalTimeout = timeout[1] + timeout[2] + timeout[3] + timeout[4] + timeout[5] + timeout[6] + 30
    print("Wait retry sequence to elapse: " .. totalTimeout .. "sec.")
    local startPTUtime = 0
    local firstTryTime = 0
    local secondTryTime = 0
    local thirdTryTime = 0
    local fourthTryTime = 0

    local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
      {
        syncMsgVersion =
        {
          majorVersion = 3,
          minorVersion = 0
        },
        appName = "AppName",
        isMediaApplication = true,
        languageDesired = "EN-US",
        hmiDisplayLanguageDesired = "EN-US",
        appID = "1234567",
        deviceInfo =
        {
          os = "Android",
          carrier = "Megafon",
          firmwareRev = "Name: Linux, Version: 3.4.0-perf",
          osVersion = "4.4.2",
          maxNumberRFCOMMPorts = 1
        }
      })
    EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
    EXPECT_NOTIFICATION("OnSystemRequest")
    :ValidIf(function(exp,data)

        if(data.payload.requestType == "HTTP") then

          if exp.occurences == 2 then
            startPTUtime = os.time()
            return true
          end

          if exp.occurences == 3 and (os.time() - startPTUtime) >= timeout[1] - 1 and (os.time() - startPTUtime) <= timeout[1] + 1 then
            firstTryTime = os.time()
            print ("first retry time: " .. timeout[1])
            return true
          elseif exp.occurences == 3 and timeout[1] ~= (os.time() - startPTUtime) then
            firstTryTime = os.time()
            print ("Wrong first retry time! Expected: " .. timeout[1] .. " Actual: " .. (os.time() - startPTUtime) )
            return false
          end

          if exp.occurences == 4 and (os.time() - firstTryTime) >= timeout[2] - 1 and (os.time() - firstTryTime) <= timeout[2] + 1 then
            secondTryTime = os.time()
            print ("second retry time: " .. timeout[2])
            return true
          elseif exp.occurences == 4 and timeout[2] ~= (os.time() - firstTryTime) then
            secondTryTime = os.time()
            print ("Wrong second retry time! Expected: " .. timeout[2] .. " Actual: " .. (os.time() - firstTryTime) )
            return false
          end

          if exp.occurences == 5 and (os.time() - secondTryTime) >= timeout[3] - 1 and (os.time() - secondTryTime) <= timeout[3] + 1 then
            thirdTryTime = os.time()
            print ("third retry time: " .. timeout[3])
            return true
          elseif exp.occurences == 5 and timeout[3] ~= (os.time() - secondTryTime) then
            thirdTryTime = os.time()
            print ("Wrong third retry time! Expected: " .. timeout[3] .. " Actual: " .. (os.time() - secondTryTime) )
            return false
          end

          if exp.occurences == 6 and (os.time() - thirdTryTime) >= timeout[4] - 1 and (os.time() - thirdTryTime) <= timeout[4] + 1 then
            fourthTryTime = os.time()
            print ("fourth retry time: " .. timeout[4])
            return true
          elseif exp.occurences == 6 and timeout[4] ~= (os.time() - thirdTryTime) then
            fourthTryTime = os.time()
            print ("Wrong fourth retry time! Expected: " .. timeout[4] .. " Actual: " .. (os.time() - thirdTryTime) )
            return false
          end

          if exp.occurences == 7 and (os.time() - fourthTryTime) >= timeout[5] - 1 and (os.time() - fourthTryTime) <= timeout[5] + 1 then
            print ("fifth retry time: " .. timeout[5])
            return true
          elseif exp.occurences == 7 and timeout[5] ~= (os.time() - fourthTryTime) then
            print ("Wrong fifth retry time! Expected: " .. timeout[5] .. " Actual: " .. (os.time() - fourthTryTime) )
            return false
          end

        end

        return true

      end)
    :Times(#seconds_between_retries + 2) -- 6 HTTP, 1 LOCK_SCREEN_ICON_URL
    :Timeout(totalTimeout * 1000)
    commonTestCases:DelayedExp(totalTimeout * 1000)
  end

  function Test:TestStep_StartSession2()
    self.mobileSession2 = mobile_session.MobileSession(self, self.mobileConnection)
    self.mobileSession2:StartService(7)
  end

  function Test:TestStep_Register_New_App_And_Check_New_PTU_Starting()
    local CorIdRAI2 = self.mobileSession2:SendRPC("RegisterAppInterface",
      {
        syncMsgVersion =
        {
          majorVersion = 3,
          minorVersion = 0
        },
        appName = "AnotherAppName",
        isMediaApplication = true,
        languageDesired = "EN-US",
        hmiDisplayLanguageDesired = "EN-US",
        appID = "7654321",
        deviceInfo =
        {
          os = "Android",
          carrier = "Megafon",
          firmwareRev = "Name: Linux, Version: 3.4.0-perf",
          osVersion = "4.4.2",
          maxNumberRFCOMMPorts = 1
        }
      })

    self.mobileSession2:ExpectNotification("OnSystemRequest"):Times(Between(1,2))
    :Do(function(_,data)
        print("SDL->MOB2: OnSystemRequest, requestType: " .. data.payload.requestType)
        if(data.payload.requestType == "HTTP") then
          onsysrequest_app2 = true
          if(onsysrequest_app1 == true) then self:FailTestCase("OnSystemRequest(HTTP) for application 1 already received") end
        end
      end)

    self.mobileSession:ExpectNotification("OnSystemRequest"):Times(Between(0,1))
    :Do(function(_,data)
        print("SDL->MOB1: OnSystemRequest, requestType: " .. data.payload.requestType)
        if(data.payload.requestType == "HTTP") then
          onsysrequest_app1 = true
          if(onsysrequest_app2 == true) then self:FailTestCase("OnSystemRequest(HTTP) for application 2 already received") end
        end
      end)

    EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UPDATE_NEEDED"}, {status = "UPDATING"}):Times(2)
    self.mobileSession2:ExpectResponse(CorIdRAI2, {success = true, resultCode = "SUCCESS"})

    commonTestCases:DelayedExp(5000)
  end

  function Test:TestStep_CheckHTTP_Received()
    if (onsysrequest_app1 == false and onsysrequest_app2 == false) then
      self:FailTestCase("OnSystemRequest(HTTP) is not received at new trigger")
    end
  end

  --[[ Postconditions ]]
  function Test.Postcondition_SDLStop()
    StopSDL()
  end

  return Test
