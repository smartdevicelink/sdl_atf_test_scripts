-- Uncomment TODO in script after fixing APPLINK-20884

-- Related test is https://adc.luxoft.com/jira/browse/APPLINK-20898
Test = require('connecttest')
require('cardinalities')

local mobile_session = require('mobile_session')
local mobile  = require('mobile_connection')
local tcp = require('tcp_connection')
local file_connection  = require('file_connection') 

config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
--ToDo: shall be removed when APPLINK-16610 is fixed
config.defaultProtocolVersion = 2
config.preloaded = config.pathToSDL .. 'sdl_preloaded_pt.json'
local defaultSection = "\t\"default\": {\n\t\"keep_context\": false,\n\t\"steal_focus\": false,\n\t\"priority\": \"NONE\",\n\t\"default_hmi\": \"NONE\",\n\t\"groups\": [\"Base-4\", \"Location-1\"]\n\t}"
local preDataSection = "\t\"pre_DataConsent\": {\n\t\"keep_context\": false,\n\t\"steal_focus\": false,\n\t\"priority\": \"NONE\",\n\t\"default_hmi\": \"NONE\",\n\t\"groups\": [\"BaseBeforeDataConsent\", \"Location-1\"]\n\t}"
local policiesParentSection = tostring("app_policies")

local mobileResponseTimeout = 10000
local indexOfTests = 1
Test.HMIappId = nil
Test.HMIappIdTwo = nil
Test.HMIappIdThree = nil

local applicationData = 
{
  mediaApp = {
    syncMsgVersion =
    {
      majorVersion = 3,
      minorVersion = 3
    },
    appName = "TestAppMedia",
    isMediaApplication = true,
    languageDesired = 'EN-US',
    hmiDisplayLanguageDesired = 'EN-US',
    appHMIType = { "DEFAULT" },
    appID = "0000002",
    deviceInfo =
    {
      os = "Android",
      carrier = "Megafon",
      firmwareRev = "Name: Linux, Version: 3.4.0-perf",
      osVersion = "4.4.2",
      maxNumberRFCOMMPorts = 1
    }
  },
  nonmediaApp = {
    syncMsgVersion =
    {
      majorVersion = 3,
      minorVersion = 3
    },
    appName = "TestAppNonMedia",
    isMediaApplication = false,
    languageDesired = 'EN-US',
    hmiDisplayLanguageDesired = 'EN-US',
    appHMIType = { "DEFAULT" },
    appID = "0000003",
    deviceInfo =
    {
      os = "Android",
      carrier = "Megafon",
      firmwareRev = "Name: Linux, Version: 3.4.0-perf",
      osVersion = "4.4.2",
      maxNumberRFCOMMPorts = 1
    }
  },
  navigationAppOne = {
    syncMsgVersion =
    {
      majorVersion = 3,
      minorVersion = 3
    },
    appName = "NavigationApp1",
    isMediaApplication = false,
    languageDesired = 'EN-US',
    hmiDisplayLanguageDesired = 'EN-US',
    appHMIType = { "NAVIGATION" },
    appID = "0000004",
    deviceInfo =
    {
      os = "Android",
      carrier = "Megafon",
      firmwareRev = "Name: Linux, Version: 3.4.0-perf",
      osVersion = "4.4.2",
      maxNumberRFCOMMPorts = 1
    }
  },
  navigationAppTwo = {
    syncMsgVersion =
    {
      majorVersion = 3,
      minorVersion = 3
    },
    appName = "NavigationApp2",
    isMediaApplication = false,
    languageDesired = 'EN-US',
    hmiDisplayLanguageDesired = 'EN-US',
    appHMIType = { "NAVIGATION" },
    appID = "0000005",
    deviceInfo =
    {
      os = "Android",
      carrier = "Megafon",
      firmwareRev = "Name: Linux, Version: 3.4.0-perf",
      osVersion = "4.4.2",
      maxNumberRFCOMMPorts = 1
    }
  }
}

---------------------------------------------------------------------------------------------
-------------------------------------------Common function-----------------------------------
---------------------------------------------------------------------------------------------


local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local policyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
require('user_modules/AppTypes')



local function sleep(sec)
  -- body
  os.execute("sleep " .. sec)
end

local function userPrint( color, message)
  print ("\27[" .. tostring(color) .. "m " .. tostring(message) .. " \27[0m")
end

local function info(message)
  -- body
  userPrint(33, message)
end

local function preconditionHead()
  -- body
  userPrint(35, "================= Precondition ==================")
end

local function preconditionMessage(message)
  -- body
  userPrint(35, message)
end

local function testHead()
  -- body
  userPrint(34, "=================== Test Case ===================")
end

local function testMessage(message)
  -- body
  userPrint(34, message)
end

function DelayedExp(time)
  time = time or 2000

  local event = events.Event()
  event.matches = function(self, e) return self == e end
  EXPECT_EVENT(event, "Delayed event")
  :Timeout(time+500)
  RUN_AFTER(function()
              RAISE_EVENT(event, event)
            end, time)
end

local function IsStringInAppInfoDat(str)
  -- body
  local iniFilePath = config.pathToSDL .. "app_info.dat"
  local iniFile = io.open(iniFilePath)
  if iniFile then
    for line in iniFile:lines() do
      if line:match(str) then
        return true
      end
    end
  else
      return false
  end
end

---------------------------------------------------------------------------------------------
--------------------------------------End Common function------------------------------------
---------------------------------------------------------------------------------------------


---------------------------------------------------------------------------------------------
-------------------------------------Test Common function------------------------------------
---------------------------------------------------------------------------------------------

function Test:replaceSection(parentSection, dest_section, src_section)
  -- body
  local preloadedFilePath = config.preloaded
  local preloadedFile = io.open(preloadedFilePath, "r")
  sContent = ""
  local continue = false
  local appPoliciesFlag = false
  if preloadedFile then
      for line in preloadedFile:lines() do
      if continue == false then
        if line:match(parentSection) then
            -- we are at app_policies section
            appPoliciesFlag = true
        end
        if line:match(dest_section) and appPoliciesFlag == true then
          if line:match("},") then
            -- we are at the end of the section located in the middle of parent section
            sContent = sContent .. src_section .. ',\n'
            continue = false
          elseif line:match("}") then
            -- we are at the end of the section located in the end of parent section
            sContent = sContent .. src_section .. '\n'
            continue = false
          else
            continue = true
          end
        else
          sContent = sContent .. line .. '\n'
        end
      -- section is located in several strings
      else
        if line:match("},") then
          -- we are at the end of the section located in the middle of parent section
          sContent = sContent .. src_section .. ',\n'
          continue = false
        elseif line:match("}") then
          -- we are at the end of the section located in the end of parent section
          sContent = sContent .. src_section .. '\n'
          continue = false
        else
          continue = true
        end
      end
    end
  end
  preloadedFile:close()

  preloadedFile = io.open(preloadedFilePath, "w")
  preloadedFile:write(sContent)
  preloadedFile:close()
end

function Test:registerApp(session, params, expNumOfApps)
  preconditionHead()
  preconditionMessage("Register Application")  

  -- session = session or self.mobileSession
  params = params or config.application1.registerAppInterfaceParams
  expNumOfApps = expNumOfApps or 1

  --mobile side: sending request 
  local cidRAI = session:SendRPC("RegisterAppInterface", params)
  
  --hmi side: expect BasicCommunication.OnAppRegistered request
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
  :Do(function(_,data)
    local appId = data.params.application.appID
    if session == self.mobileSession then
      self.HMIappId = appId
      info("Test.HMIappId: " .. self.HMIappId)
    elseif session == self.mobileSession2 then
      self.HMIappIdTwo = appId
      info("Test.HMIappIdTwo: " .. self.HMIappIdTwo)
    else
      self.HMIappIdThree = appId
      info("Test.HMIappIdThree: " .. self.HMIappIdThree)
    end
  end)

  --hmi side: BasicCommunication.UpdateAppList
  EXPECT_HMICALL("BasicCommunication.UpdateAppList")
  :ValidIf(function(_,data)
    if #data.params.applications == expNumOfApps then
    return true
    else 
      print(" \27[36m Application array in BasicCommunication.UpdateAppList contains " .. 
        tostring(#data.params.applications)..", expected " .. expNumOfApps .. "\27[0m")
      return false
    end
  end)
  :Do(function(_,data)
    --hmi side: sending BasicCommunication.UpdateAppList response 
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {}) 
  end)
  
  --mobile side: expect response
  session:ExpectResponse(cidRAI, 
  {
    hmiDisplayLanguage = config.application1.hmiDisplayLanguageDesired,
    language = config.application1.languageDesired,
    resultCode = "SUCCESS",
    success = true
  })
  :Timeout(2000)

  --mobile side: expect notification
  session:ExpectNotification("OnHMIStatus", 
  { 
    systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"
  })
  :Timeout(2000)
  :Times(1)

  -- --mobile side: expect notification
  -- session:ExpectNotification("OnPermissionsChange")
  -- :Timeout(2000)
  -- :Times(1)

  DelayedExp()
end

function Test:sendUnsupportedHMIResource(session, applicationID, timeToWait)
  -- body
  -- session = session or self.mobileSession
  timeToWait = timeToWait or 1500
  -- applicationID = applicationID or tostring(self.HMIappId)
  info(applicationID)

  --hmi side: sending BasicCommunication.OnExitApplication notification
  self.hmiConnection:SendNotification("BasicCommunication.OnExitApplication",{ appID = applicationID, reason = "UNSUPPORTED_HMI_RESOURCE" })

  --mobile side: expect notification
  session:ExpectNotification("OnAppInterfaceUnregistered", 
    { 
      reason = "UNSUPPORTED_HMI_RESOURCE"
    })
    :Timeout(2000)
    :Times(1)

  --mobile side: expect notification
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = applicationID, unexpectedDisconnect = false})
  :Times(1)

  -- TODO start: uncommment after fixing bug APPLINK-20884
  --req. APPLINK-20647
  --hmi side: BasicCommunication.UpdateAppList
  -- EXPECT_HMICALL("BasicCommunication.UpdateAppList")
  -- :ValidIf(function(_,data)
  --   if #data.params.applications == 0 then
  --   return true
  --   else 
  --     print(" \27[36m Application array in BasicCommunication.UpdateAppList contains "..tostring(#data.params.applications)..", expected 0 \27[0m")
  --     return false
  --   end
  -- end)
  -- :Do(function(_,data)
  --   --hmi side: sending BasicCommunication.UpdateAppList response 
  --   self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {}) 
  -- end)
  -- TODO end: uncommment after fixing bug APPLINK-20884

  DelayedExp(timeToWait)
end

function Test:activateApplication(applicationID)

  preconditionHead()
  preconditionMessage("App activation")
      
  --hmi side: sending SDL.ActivateApp request
  RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = applicationID})

  --hmi side: expect SDL.ActivateApp response
  EXPECT_HMIRESPONSE(RequestId)
    :Do(function(_,data)
      --In case when app is not allowed, it is needed to allow app
      if
        data.result.isSDLAllowed ~= true then

          --hmi side: sending SDL.GetUserFriendlyMessage request
          local RequestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", 
                    {language = "EN-US", messageCodes = {"DataConsent"}})

          --hmi side: expect SDL.GetUserFriendlyMessage response
          --TODO: Update after resolving APPLINK-16094 EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
          EXPECT_HMIRESPONSE(RequestId)
            :Do(function(_,data)

              --hmi side: send request SDL.OnAllowSDLFunctionality
              self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", 
                {allowed = true, source = "GUI", device = {id = config.deviceMAC, name = "127.0.0.1"}})


              --hmi side: expect BasicCommunication.ActivateApp request
              EXPECT_HMICALL("BasicCommunication.ActivateApp")
                :Do(function(_,data)

                  --hmi side: sending BasicCommunication.ActivateApp response
                  self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})

                end)
                -- according APPLINK-9283 we send "device" parameter, so expect "BasicCommunication.ActivateApp" one time
                :Times(1)


            end)

    end
  end)
  
  --mobile side: expect notification
  EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"}) 
end

function Test:secondConnect()
    local tcpConnection = tcp.Connection(config.mobileHost, config.mobilePort)
    local fileConnection = file_connection.FileConnection("mobile2.out", tcpConnection)
    self.mobileConnection2 = mobile.MobileConnection(fileConnection)
    self.mobileSession2 = mobile_session.MobileSession(
      self, self.mobileConnection2, config.application2.registerAppInterfaceParams)
    event_dispatcher:AddConnection(self.mobileConnection2)
    self.mobileSession2:ExpectEvent(events.connectedEvent, "Connection started")
    self.mobileConnection2:Connect()

    self.mobileSession2:StartService(7)
end

function Test:thirdConnect()
    local tcpConnection = tcp.Connection(config.mobileHost, config.mobilePort)
    local fileConnection = file_connection.FileConnection("mobile3.out", tcpConnection)
    self.mobileConnection3 = mobile.MobileConnection(fileConnection)
    self.mobileSession3 = mobile_session.MobileSession(
      self, self.mobileConnection3, config.application2.registerAppInterfaceParams)
    event_dispatcher:AddConnection(self.mobileConnection3)
    self.mobileSession3:ExpectEvent(events.connectedEvent, "Connection started")
    self.mobileConnection3:Connect()

    self.mobileSession3:StartService(7)
end

function Test:tenPendingRequestsFromTwoApps()
  -- body
  testHead()
  testMessage("HMI respond to <appID> requests after UNSUPPORTED_HMI_RESOURCE was sent")
  info("Expected: SDL unregister App, ignore HMI responses")

  for i=1,10 do
    local cid = self.mobileSession:SendRPC("AddCommand",{cmdID = i, menuParams = {menuName = "Play" .. tostring(i)} })
  end

  for i=1,10 do
    local cid = self.mobileSession2:SendRPC("AddCommand",{cmdID = i, menuParams = {menuName = "Mustang" .. tostring(i)} })
  end

  local cmdCID = {}
  arrayIndex = 1

  --hmi side: UI.AddCommand
  EXPECT_HMICALL("UI.AddCommand")
  :Times(20)
  :Do(function(exp,data)
    local cmdMethod = data.method 
    info("Occur: " .. exp.occurences)
    if exp.occurences < 20 then
        --do
        cmdCID[arrayIndex] = data.id
        arrayIndex = arrayIndex + 1
    else
        --do
        cmdCID[arrayIndex] = data.id
        arrayIndex = arrayIndex + 1

        info("SENDING UNSUPPORTED_HMI_RESOURCE")
        
        --hmi side: sending BasicCommunication.OnExitApplication notification
        self.hmiConnection:SendNotification("BasicCommunication.OnExitApplication",{ appID = self.HMIappId, reason = "UNSUPPORTED_HMI_RESOURCE" })
        self.hmiConnection:SendNotification("BasicCommunication.OnExitApplication",{ appID = self.HMIappIdTwo, reason = "UNSUPPORTED_HMI_RESOURCE" })

        --mobile side: expect notification
        self.mobileSession:ExpectNotification("OnAppInterfaceUnregistered", 
          { 
            reason = "UNSUPPORTED_HMI_RESOURCE"
          })
          :Timeout(2000)
          :Times(1)

        --mobile side: expect notification
        self.mobileSession2:ExpectNotification("OnAppInterfaceUnregistered", 
          { 
            reason = "UNSUPPORTED_HMI_RESOURCE"
          })
          :Timeout(2000)
          :Times(1)

        --mobile side: expect notification
        EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered")
        :Times(2)
        :Do(function (_,data)
          -- body
          for i=1,20 do
            self.hmiConnection:SendResponse(cmdCID[i], cmdMethod, "SUCCESS", {})
          end
        end)
    end

    -- TODO: uncommment after fixing bug APPLINK-20884

    -- --req. APPLINK-20647
    -- --hmi side: BasicCommunication.UpdateAppList
    -- EXPECT_HMICALL("BasicCommunication.UpdateAppList")
    -- :ValidIf(function(_,data)
    --   if #data.params.applications == 0 then
    --   return true
    --   else 
    --     print(" \27[36m Application array in BasicCommunication.UpdateAppList contains "..tostring(#data.params.applications)..", expected 0 \27[0m")
    --     return false
    --   end
    -- end)
    -- :Do(function(_,data)
    --   --hmi side: sending BasicCommunication.UpdateAppList response 
    --   self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {}) 
    -- end)
    DelayedExp(2500)
  end)
end

---------------------------------------------------------------------------------------------
-----------------------------------Test Common function END----------------------------------
---------------------------------------------------------------------------------------------


---------------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------
	
	commonSteps:DeleteLogsFileAndPolicyTable()
	
	--Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup("Preconditions")

	--Update policy to allow request
	--TODO: Will be updated after policy flow implementation
	policyTable:Precondition_updatePolicy_By_overwriting_preloaded_pt("files/sdl_preloaded_pt.json")



---------------------------------------------------------------------------------------------
-----------------------------------------I TEST BLOCK----------------------------------------
--------App registered 1st time: Checks for one App when UNSUPPORTED_HMI_RESOURCE come-------
---------------------------------------------------------------------------------------------

-- Begin Test suit OneAppDuringFirstRegistration

-- Description: TC's checks processing 
-- HMI respond UNSUPPORTED_HMI_RESOURCE immediately
-- HMI respond UNSUPPORTED_HMI_RESOURCE in 500ms
-- HMI respond UNSUPPORTED_HMI_RESOURCE during work
-- HMI respond to <appID> requests after UNSUPPORTED_HMI_RESOURCE was sent
-- HMI respond UNSUPPORTED_HMI_RESOURCE while 10 <appID> requests are pending for responses

-- //////////////////////////////////////////////////////////////////////////////////////////
-- HMI respond UNSUPPORTED_HMI_RESOURCE immediately
-- //////////////////////////////////////////////////////////////////////////////////////////

-- Precondition to entire test - backup sdl_preloaded_pt.json, update original for API passing i needed HMI levels
function Test:StopSDLForPermissionsChange(self)
  preconditionHead()
  preconditionMessage("StopSDL")
  StopSDL()
end

function Test:BackupPreloadedFile(...)
  -- body
  os.execute('cp ' .. config.preloaded .. " " .. config.pathToSDL .."~sdl_preloaded_pt.json")
end

function Test:AddLocationToDefaultAndPreDataConsent()
  self:replaceSection(policiesParentSection, tostring("default\""), defaultSection)
  self:replaceSection(policiesParentSection, tostring("pre_DataConsent\""), preDataSection)
end

function Test:StartFromScratch(...)
  -- body
  os.execute('rm -rf ' .. config.pathToSDL .. '/storage app_info.dat')
end

function Test:StartSDL()
  StartSDL(config.pathToSDL, config.ExitOnCrash)
  sleep(2)
end

function Test:InitializeTheHMI()
  self:initHMI()
end

function Test:TheHMIisReady()
  self:initHMI_onReady()
end

function Test:ConnectMobile()
  self:connectMobile()
end
function Test:StartSession()
  self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
end

function Test:RegisterApp()
  self.mobileSession:StartService(7)
  :Do(function (_,data)
    self:registerApp(self.mobileSession)
  end)
end

function Test:UnregisterApplication()
  preconditionHead()
  preconditionMessage("Precondition: unregister Application")
  local cid = self.mobileSession:SendRPC("UnregisterAppInterface",{})

  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered")
  :Times(1)

  EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
  :Timeout(2000)
  
    --hmi side: BasicCommunication.UpdateAppList
  EXPECT_HMICALL("BasicCommunication.UpdateAppList")
   :ValidIf(function(_,data)
    if #data.params.applications == 0 then
    return true
    else 
      print(" \27[36m Application array in BasicCommunication.UpdateAppList contains "..tostring(#data.params.applications)..", expected 0 \27[0m")
      return false
    end
  end)
  :Do(function(_,data)
    --hmi side: sending BasicCommunication.UpdateAppList response 
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {}) 
  end)
  
   DelayedExp(5000)
  
end

function Test:SDLUnregisterAfterUHR()
  testHead()
  testMessage("HMI respond UNSUPPORTED_HMI_RESOURCE immediately")  
  info("Expected: SDL unregister Application")
        
  --mobile side: sending request 
  local cidRAI = self.mobileSession:SendRPC("RegisterAppInterface", applicationData.mediaApp)
  
  --hmi side: expect BasicCommunication.OnAppRegistered request
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
  {
    application = 
    {
      appName = applicationData.mediaApp.appName
    }
  })
  :Do(function(_,data)
    self.HMIappId = data.params.application.appID
    info("HMI AppID: " .. self.HMIappId)

    --hmi side: sending BasicCommunication.OnExitApplication notification
    self.hmiConnection:SendNotification("BasicCommunication.OnExitApplication",
      { appID = self.HMIappId, reason = "UNSUPPORTED_HMI_RESOURCE" })
    
    --mobile side: expect notification
    self.mobileSession:ExpectNotification("OnAppInterfaceUnregistered", 
      { reason = "UNSUPPORTED_HMI_RESOURCE"})
    :Timeout(2000)
    :Times(1)

    --hmi side: expect BasicCommunication.OnAppUnregistered
    EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = self.HMIappId, unexpectedDisconnect = false})
    :Times(1)
  end)
  
  --mobile side: expect response
  self.mobileSession:ExpectResponse(cidRAI, 
  {
    hmiDisplayLanguage = config.application1.hmiDisplayLanguageDesired,
    language = config.application1.languageDesired,
    resultCode = "SUCCESS",
    success = true
  })
  :Timeout(2000)

  --mobile side: expect notification
  self.mobileSession:ExpectNotification("OnHMIStatus", 
  { 
    systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"
  })
  :Timeout(2000)
  :Times(1)

  --hmi side: BasicCommunication.UpdateAppList
  EXPECT_HMICALL("BasicCommunication.UpdateAppList")
  :ValidIf(function(_,data)
    if #data.params.applications == 0 then
    return true
    else 
      print(" \27[36m Application array in BasicCommunication.UpdateAppList contains "..tostring(#data.params.applications)..", expected 0 \27[0m")
      return false
    end
  end)
  :Do(function(_,data)
    --hmi side: sending BasicCommunication.UpdateAppList response 
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {}) 
  end)

  DelayedExp(5000)
end
-- //////////////////////////////////////////////////////////////////////////////////////////
-- HMI respond UNSUPPORTED_HMI_RESOURCE in 500ms
-- //////////////////////////////////////////////////////////////////////////////////////////

-- -- restore connection
-- function Test:ConnectMobile()
--   self:connectMobile()
-- end

-- function Test:StartSession()
--   CreateSession(self)
-- end

function Test:PrecondRegisterApp()
  self:registerApp(self.mobileSession)
end

function Test:Wait500ms(...)
  -- body
  DelayedExp()
end

function Test:SDLUnregisterAfterUHRin500ms(...)
  testHead()
  testMessage("HMI respond UNSUPPORTED_HMI_RESOURCE in 500ms")
  info("Expected: SDL unregister Application")
  
  self:sendUnsupportedHMIResource(self.mobileSession, Test.HMIappId)
end

-- //////////////////////////////////////////////////////////////////////////////////////////
-- HMI respond UNSUPPORTED_HMI_RESOURCE during work
-- //////////////////////////////////////////////////////////////////////////////////////////

-- Begin Precondition.1
-- Description: Register Application
function Test:PrecondRegisterApp()
  self:registerApp(self.mobileSession, applicationData.mediaApp)
end
-- End Precondition.1

-- Begin Precondition.2
-- Description: Activation
function Test:PrecondActivation()
  self:activateApplication(Test.HMIappId)
end
-- End Precondition.2

-- Begin Precondition.3
-- Description: wait 10 seconds
function Test:PrecondWait10Sec(...)
  -- body
  preconditionHead()
  preconditionMessage("Precondition: Wait 10 seconds.")

  DelayedExp(9500)
end
-- End Precondition.3

-- BEGIN TEST CASE
-- Description: HMI respond UNSUPPORTED_HMI_RESOURCE during work
function Test:UHRduringwork(...)
  -- body
  testHead()
  testMessage("HMI respond UNSUPPORTED_HMI_RESOURCE during work")
  info("Expected: SDL unregister App.")

  --hmi side: sending BasicCommunication.OnExitApplication notification
  self.hmiConnection:SendNotification("BasicCommunication.OnExitApplication",{ appID = self.HMIappId, reason = "UNSUPPORTED_HMI_RESOURCE" })

  --mobile side: expect notification
  self.mobileSession:ExpectNotification("OnAppInterfaceUnregistered", 
    { 
      reason = "UNSUPPORTED_HMI_RESOURCE"
    })
    :Timeout(2000)
    :Times(1)

  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = self.HMIappId, unexpectedDisconnect = false})
  :Times(1)--mobile side: expect notification

  -- TODO: uncommment after fixing bug APPLINK-20884
  -- --req. APPLINK-20647
  -- --hmi side: BasicCommunication.UpdateAppList
  -- EXPECT_HMICALL("BasicCommunication.UpdateAppList")
  -- :ValidIf(function(_,data)
  --   if #data.params.applications == 0 then
  --   return true
  --   else 
  --     print(" \27[36m Application array in BasicCommunication.UpdateAppList contains "..tostring(#data.params.applications)..", expected 0 \27[0m")
  --     return false
  --   end
  -- end)
  -- :Do(function(_,data)
  --   --hmi side: sending BasicCommunication.UpdateAppList response 
  --   self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {}) 
  -- end)

  DelayedExp(500)
end
-- END TESTCASE 


-- //////////////////////////////////////////////////////////////////////////////////////////
-- HMI respond to <appID> requests after UNSUPPORTED_HMI_RESOURCE was sent
-- //////////////////////////////////////////////////////////////////////////////////////////

-- Begin Precondition.1
-- Description: App's registration
function Test:PrecondRegisterApp(...)
  -- body
  self:registerApp(self.mobileSession, applicationData.mediaApp)
end
-- End Precondition.1

-- Begin Precondition.2
-- Description: Actiation App
function Test:PrecondActivation(...)
  -- body
  self:activateApplication(Test.HMIappId)
end
-- End Precondition.2

function Test:UHRsentWhileOneReqPendingResp(...)
  -- body
  testHead()
  testMessage("HMI respond to <appID> requests after UNSUPPORTED_HMI_RESOURCE was sent")
  info("Expected: SDL unregister App, ignore HMI responses")

  local cid = self.mobileSession:SendRPC("AddCommand",{cmdID = 1, menuParams = {menuName = "Play"}})

  --hmi side: UI.AddCommand
  EXPECT_HMICALL("UI.AddCommand")
  :Timeout(2000)
  :Do(function(_,data)
    local cmdCID = data.id
    local cmdMethod = data.method
    --hmi side: sending BasicCommunication.OnExitApplication notification
    self.hmiConnection:SendNotification("BasicCommunication.OnExitApplication",{ appID = self.HMIappId, reason = "UNSUPPORTED_HMI_RESOURCE" })

    --mobile side: expect notification
    self.mobileSession:ExpectNotification("OnAppInterfaceUnregistered", 
      { 
        reason = "UNSUPPORTED_HMI_RESOURCE"
      })
      :Timeout(2000)
      :Times(1)

    --mobile side: expect notification
    EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = self.HMIappId, unexpectedDisconnect = false})
    :Times(1)
    :Do(function (_,data)
      -- body
      self.hmiConnection:SendResponse(cmdCID, cmdMethod, "SUCCESS", {})
    end)

    -- TODO: uncommment after fixing bug APPLINK-20884

    -- --req. APPLINK-20647
    -- --hmi side: BasicCommunication.UpdateAppList
    -- EXPECT_HMICALL("BasicCommunication.UpdateAppList")
    -- :ValidIf(function(_,data)
    --   if #data.params.applications == 0 then
    --   return true
    --   else 
    --     print(" \27[36m Application array in BasicCommunication.UpdateAppList contains "..tostring(#data.params.applications)..", expected 0 \27[0m")
    --     return false
    --   end
    -- end)
    -- :Do(function(_,data)
    --   --hmi side: sending BasicCommunication.UpdateAppList response 
    --   self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {}) 
    -- end)
  end)
end


-- //////////////////////////////////////////////////////////////////////////////////////////
-- HMI respond UNSUPPORTED_HMI_RESOURCE while 10 <appID> requests are pending for responses
-- //////////////////////////////////////////////////////////////////////////////////////////


-- Begin Precondition.1
-- Description: App's registration
function Test:PrecondRegisterApp(...)
  -- body
  self:registerApp(self.mobileSession, applicationData.mediaApp)
end
-- End Precondition.1

-- Begin Precondition.2
-- Description: Actiation App
function Test:PrecondActivation(...)
  -- body
  self:activateApplication(Test.HMIappId)
end
-- End Precondition.2

function Test:UHRsentWhileTenReqPendingResp(...)
  -- body
  testHead()
  testMessage("HMI respond to <appID> requests after UNSUPPORTED_HMI_RESOURCE was sent")
  info("Expected: SDL unregister App, ignore HMI responses")

  for i=1,10 do
    local cid = self.mobileSession:SendRPC("AddCommand",{cmdID = i, menuParams = {menuName = "Play" .. tostring(i)} })
  end

  local cmdCID = {}
  arrayIndex = 1

  --hmi side: UI.AddCommand
  EXPECT_HMICALL("UI.AddCommand")
  :Times(10)
  :Do(function(exp,data)
    local cmdMethod = data.method 
    info("Occur: " .. exp.occurences)
    if exp.occurences < 10 then
        --do
        cmdCID[arrayIndex] = data.id
        arrayIndex = arrayIndex + 1
    else
        --do
        cmdCID[arrayIndex] = data.id
        arrayIndex = arrayIndex + 1

        info("SENDING UNSUPPORTED_HMI_RESOURCE")
        --hmi side: sending BasicCommunication.OnExitApplication notification
        self.hmiConnection:SendNotification("BasicCommunication.OnExitApplication",{ appID = self.HMIappId, reason = "UNSUPPORTED_HMI_RESOURCE" })

        --mobile side: expect notification
        self.mobileSession:ExpectNotification("OnAppInterfaceUnregistered", 
          { 
            reason = "UNSUPPORTED_HMI_RESOURCE"
          })
          :Timeout(2000)
          :Times(1)

        --mobile side: expect notification
        EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = self.HMIappId, unexpectedDisconnect = false})
        :Times(1)
        :Do(function (_,data)
          -- body
          for i=1,10 do
            self.hmiConnection:SendResponse(cmdCID[i], cmdMethod, "SUCCESS", {})
          end
        end)
    end

    -- TODO: uncommment after fixing bug APPLINK-20884

    -- --req. APPLINK-20647
    -- --hmi side: BasicCommunication.UpdateAppList
    -- EXPECT_HMICALL("BasicCommunication.UpdateAppList")
    -- :ValidIf(function(_,data)
    --   if #data.params.applications == 0 then
    --   return true
    --   else 
    --     print(" \27[36m Application array in BasicCommunication.UpdateAppList contains "..tostring(#data.params.applications)..", expected 0 \27[0m")
    --     return false
    --   end
    -- end)
    -- :Do(function(_,data)
    --   --hmi side: sending BasicCommunication.UpdateAppList response 
    --   self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {}) 
    -- end)
    DelayedExp(6000)
  end)
end

---------------------------------------------------------------------------------------------
--------------------------------------I TEST BLOCK - END-------------------------------------
---------------------------------------------------------------------------------------------






---------------------------------------------------------------------------------------------
----------------------------------------II TEST BLOCK----------------------------------------
--App with persistent data: Checks for one App with data when UNSUPPORTED_HMI_RESOURCE come--
---------------------------------------------------------------------------------------------

-- Begin Test suit OneAppWithPersistentData

-- Description: TC's checks processing 
-- SDL clears all App's data after HMI's UNSUPPORTED_HMI_RESOURCE 
-- No resumption after UNSUPPORTED_HMI_RESOURCE


-- //////////////////////////////////////////////////////////////////////////////////////////
-- SDL clears all App's data after HMI's UNSUPPORTED_HMI_RESOURCE 
-- //////////////////////////////////////////////////////////////////////////////////////////

-- Begin Precondition.1
-- Description: App's registration
function Test:PrecondRegisterApp()
  self:registerApp(self.mobileSession, applicationData.mediaApp)
end
-- End Precondition.1

function Test:PrecondActivation(...)
  -- body
  self:activateApplication(Test.HMIappId)
end

-- Begin Precondition.2
-- Description: App adds persistan data
function Test:PrecondAddData(...)
  -- body
  local cidCmd1 = self.mobileSession:SendRPC("AddCommand", {cmdID = 1, menuParams = {menuName = "Play"} })
  local cidCmd2 = self.mobileSession:SendRPC("AddCommand", {cmdID = 2, vrCommands = {"Stop"} })
  local cidMenu = self.mobileSession:SendRPC("AddSubMenu", {menuID = 1, menuName = "Main"})
  local cidChoice = self.mobileSession:SendRPC("CreateInteractionChoiceSet", {interactionChoiceSetID = 1, 
    choiceSet = { {choiceID = 101, menuName = "Stations", vrCommands = {"Stations"} } } })
  local cidProperties = self.mobileSession:SendRPC("SetGlobalProperties",
    { helpPrompt = {{text = "Speak", type = "TEXT"}}, 
      timeoutPrompt = {{text = "Hello", type = "TEXT"}}, 
      vrHelpTitle = "Options", 
      vrHelp = {{position = 1, text = "OK"}} })
  local cidButton = self.mobileSession:SendRPC("SubscribeButton", {buttonName = "PRESET_1"})
  local cid = self.mobileSession:SendRPC("SubscribeVehicleData", {speed = true})


  --hmi side: UI.AddCommand
  EXPECT_HMICALL("UI.AddCommand", {appID = self.HMIappId, cmdID = 1, menuParams = {menuName = "Play"} })
  :Do(function(_,data)
    -- body
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
  end)

  --hmi side: VR.AddCommand
  EXPECT_HMICALL("VR.AddCommand")
  :Times(2)
  :Do(function(exp,data)
    -- body
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
  end)

  --hmi side: UI.AddSubMenu
  EXPECT_HMICALL("UI.AddSubMenu")
  :Times(1)
  :Do(function(_,data)
    -- body
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
  end)

  --hmi side: UI.SetGlobalProperties
  EXPECT_HMICALL("UI.SetGlobalProperties")
  :Do(function(_,data)
    -- body
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
  end)

  --hmi side: TTS.SetGlobalProperties
  EXPECT_HMICALL("TTS.SetGlobalProperties")
  :Do(function(_,data)
    -- body
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
  end)

  --hmi side: VehicleInfo.SubscribeVehicleData
  EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData")
  :Do(function(_,data)
    -- body
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
  end)

  --hmi side: Buttons.OnButtonSubscription
  EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription", {isSubscribed = true, name = "PRESET_1"})
  :Times(AtMost(1))

  --mobile side: expect notification
  EXPECT_NOTIFICATION("OnHashChange")
  :Times(7)

end
-- End Precondition.2


-- Begin Precondition.3
-- Description: wait 10 seconds
function Test:PrecondCheckAppInfoDat(...)
  -- body
  preconditionHead()
  preconditionMessage("Precondition: Wait for app_info.dat")

  local iniFilePath = config.pathToSDL .. "app_info.dat"
  print("Path to app_info.dat: " ..iniFilePath)
  local cond = true
  local Timeout = 100
  repeat
	Timeout = Timeout - 1
    --do
    --if IsStringInAppInfoDat("appID\" : " .. "\"" .. config.application1.registerAppInterfaceParams.fullAppID) then
	if IsStringInAppInfoDat("appID\" : " .. "\"" .. applicationData.mediaApp.appID) then
	
      cond = false
    else
      info(".")
      sleep(1)
    end
  until cond or Timeout > 0 

  cond = true
  Timeout = 100
  repeat
    --do
	Timeout = Timeout - 1
	
    if IsStringInAppInfoDat("menuName\" : \"Stations") then
      cond = false
    else
      info(".")
      sleep(1)
    end
  until cond  or Timeout > 0 

end
-- End Precondition.3

function Test:UHRFromHMI(...)
  testHead()
  testMessage("SDL clears all App's data after HMI's UNSUPPORTED_HMI_RESOURCE")
  info("Expected: SDL clears all App's data after HMI's UNSUPPORTED_HMI_RESOURCE")
  
  self:sendUnsupportedHMIResource(self.mobileSession, Test.HMIappId)
end

function Test:CheckAppInfoDatAfterUHR(...)
  -- body
  if IsStringInAppInfoDat("appID\" : " .. "\"" .. config.application1.registerAppInterfaceParams.fullAppID) then
    self:FailTestCase("App's data is present")
  end
end


-- //////////////////////////////////////////////////////////////////////////////////////////
-- No resumption after UNSUPPORTED_HMI_RESOURCE
-- //////////////////////////////////////////////////////////////////////////////////////////


function Test:NoResumptionAfterUHR(...)
  -- body
  testHead()
  testMessage("No resumption occurs after UNSUPPORTED_HMI_RESOURCE")
  info("Expected: SDL do not resume App that was unregistered by SDL due to UNSUPPORTED_HMI_RESOURCE")

  self:registerApp(self.mobileSession, applicationData.mediaApp)
end

---------------------------------------------------------------------------------------------
-------------------------------------II TEST BLOCK - END-------------------------------------
---------------------------------------------------------------------------------------------


---------------------------------------------------------------------------------------------
---------------------------------------III TEST BLOCK----------------------------------------
-------------------------------2 Apps on different connections-------------------------------
---------------------------------------------------------------------------------------------

-- Begin Test suit TwoAppsOnDifferentConnections

-- Description: TC's checks processing 
-- HMI sends UNSUPPORTED_HMI_RESOURCE to App1 (+ requests from another App)
-- HMI sends UNSUPPORTED_HMI_RESOURCE to both Apps
-- 2 connections just added - UNSUPPORTED_HMI_RESOURCE to both Apps
-- HMI sends UNSUPPORTED_HMI_RESOURCE to both Apps while 10 requests are pending for responses
-- HMI sends UNSUPPORTED_HMI_RESOURCE to App1 2 times


-- //////////////////////////////////////////////////////////////////////////////////////////
-- HMI sends UNSUPPORTED_HMI_RESOURCE to App1 (+ requests from another App)
-- //////////////////////////////////////////////////////////////////////////////////////////

-- Begin Precondition.1
-- Description: Start 2nd connection
function Test:PrecondStartSecondConnection(...)
  -- body
  preconditionHead()
  preconditionMessage("Start 2nd connection")
  self:secondConnect()
end
-- End Precondition.1

-- Begin Precondition.2
-- Description: Register Application on 2nd connection
function Test:PrecondRegisterAppOnSecondConnection(...)
  -- body
  preconditionHead()
  preconditionMessage("Register Application on 2nd connection")
  self:registerApp(self.mobileSession2, applicationData.nonmediaApp, 2)
end
-- End Precondition.2

function Test:SendUHRToAppOne(...)
  -- body
  testHead()
  testMessage("HMI sends UNSUPPORTED_HMI_RESOURCE to App1")
  info("Expected: SDL unregister App1")

  self:sendUnsupportedHMIResource(self.mobileSession, Test.HMIappId)  
end

function Test:SecondAppIsStillAlive_1(...)
  -- body
  info("Expected: App2 still alive and SDL processes all messages from App2")

  local cid = self.mobileSession2:SendRPC("ListFiles", {})
  --mobile side: expect ListFiles response 
  self.mobileSession2:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end


-- //////////////////////////////////////////////////////////////////////////////////////////
-- HMI sends UNSUPPORTED_HMI_RESOURCE to both Apps
-- //////////////////////////////////////////////////////////////////////////////////////////

-- Begin Precondition.1
-- Description: Start Session1
function Test:StartSession()
  preconditionHead()
  preconditionMessage("Start Session1")
  self.mobileSession = mobile_session.MobileSession(
    self, self.mobileConnection, applicationData.mediaApp)
  self.mobileSession:StartService(7)
end
-- End Precondition.1

-- Begin Precondition.2
-- Description: Register Application on connection 1
function Test:PrecondRegisterAppOne_1(...)
  -- body
  self:registerApp(self.mobileSession, applicationData.mediaApp, 2)
end
-- End Precondition.2

function Test:UhrToBothAppsStepOne(...)
  -- body
  testHead()
  testMessage("HMI sends UNSUPPORTED_HMI_RESOURCE to both Apps")
  info("Expected: SDL unregister both Apps")

  self:sendUnsupportedHMIResource(self.mobileSession, Test.HMIappId)
end

function Test:UhrToBothAppsStepTwo(...)
  -- body
  self:sendUnsupportedHMIResource(self.mobileSession2, Test.HMIappIdTwo)
end

-- //////////////////////////////////////////////////////////////////////////////////////////
-- 2 connections just added - UNSUPPORTED_HMI_RESOURCE to both Apps
-- //////////////////////////////////////////////////////////////////////////////////////////

-- Begin Precondition.1
-- Description: Close connections of App2
function Test:CloseConnectionTwo(...)
  -- body
  preconditionHead()
  preconditionMessage("Close connection of App2")
  self.mobileConnection2:Close()
end
-- End Precondition.1

-- Begin Precondition.5
-- Description: Open connection 2
function Test:OpenConnectionOne(...)
  -- body
  preconditionHead()
  preconditionMessage("Open connection1, start session on connection1")
  self:secondConnect()
end
-- End Precondition.5

-- Begin Precondition.5
-- Description: Open connection 3
function Test:OpenConnectionTwo(...)
  -- body
  preconditionHead()
  preconditionMessage("Open connection2, start session on connection2")
  self:thirdConnect()
end
-- End Precondition.5

-- Begin Precondition.6
-- Description: Register Apps on both connections
function Test:RegisterAppOnConnOne(...)
  -- body
  preconditionHead()
  preconditionMessage("Register Apps on both connections")

  self:registerApp(self.mobileSession2, applicationData.mediaApp, 1)
end
-- End Precondition.6

-- Begin Precondition.7
-- Description: Register Apps on both connections
function Test:RegisterAppsOnConnTwo(...)
  -- body
  self:registerApp(self.mobileSession3, applicationData.nonmediaApp, 2)
end
-- End Precondition.7

function Test:UHRtoJustAddedConnectionsStepOne(...)
  -- body
  testHead()
  testMessage("2 connections just added - UNSUPPORTED_HMI_RESOURCE to both Apps")
  self:sendUnsupportedHMIResource(self.mobileSession2, Test.HMIappIdTwo)
end

function Test:UHRtoJustAddedConnectionsStepTwo(...)
  -- body
  self:sendUnsupportedHMIResource(self.mobileSession3, Test.HMIappIdThree)
end

-- postcondition: Close connection3
function Test:Postcondition(...)
  -- body
  self.mobileConnection3:Close()
end

-- //////////////////////////////////////////////////////////////////////////////////////////
-- HMI sends UNSUPPORTED_HMI_RESOURCE to both Apps while 10 requests are pending for responses
-- //////////////////////////////////////////////////////////////////////////////////////////

-- Begin Precondition.1
-- Description: Register Apps on both connections
function Test:RegisterAppOnConnOne_1(...)
  -- body
  preconditionHead()
  preconditionMessage("Register Apps on both connections")

  self:registerApp(self.mobileSession, applicationData.mediaApp, 1)
end
-- End Precondition.1

-- Begin Precondition.2
-- Description: Register Apps on both connections
function Test:RegisterAppOnConnTwo_1(...)
  -- body
  self:registerApp(self.mobileSession2, applicationData.nonmediaApp, 2)
end
-- End Precondition.2

function Test:PrecondActivation_App1(...)
  -- body
  self:activateApplication(Test.HMIappId)
end

function Test:PrecondActivation_App2(...)
  -- body
  self:activateApplication(Test.HMIappIdTwo)
end

function Test:UHRsentWhileTenReqPendingResp(...)
  -- body
  self:tenPendingRequestsFromTwoApps()
end

-- //////////////////////////////////////////////////////////////////////////////////////////
-- HMI sends UNSUPPORTED_HMI_RESOURCE to App1 2 times
-- //////////////////////////////////////////////////////////////////////////////////////////

-- Begin Precondition.1
-- Description: Register Apps on both connections
function Test:RegisterAppOnConnOne_2(...)
  -- body
  preconditionHead()
  preconditionMessage("Register Apps on both connections")

  self:registerApp(self.mobileSession, applicationData.mediaApp, 1)
end
-- End Precondition.1

-- Begin Precondition.2
-- Description: Register Apps on both connections
function Test:RegisterAppOnConnTwo_2(...)
  -- body
  self:registerApp(self.mobileSession2, applicationData.nonmediaApp, 2)
end
-- End Precondition.2

function Test:UHRtoAppOneTwoTimesStepOne(...)
  -- body
  self:sendUnsupportedHMIResource(self.mobileSession, Test.HMIappId)
end

function Test:UHRtoAppOneTwoTimesStepTwo(...)
  -- body
  self.hmiConnection:SendNotification("BasicCommunication.OnExitApplication",{ appID = self.HMIappId, reason = "UNSUPPORTED_HMI_RESOURCE" })

  --mobile side: expect notification
  self.mobileSession:ExpectNotification("OnAppInterfaceUnregistered", 
    { 
      reason = "UNSUPPORTED_HMI_RESOURCE"
    })
    :Times(0)

  --mobile side: expect notification
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = applicationID, unexpectedDisconnect = false})
  :Times(0)

  DelayedExp(1500)
end

function Test:RegisterAppOnConnOneAgain(...)
  -- body
  testHead()
  testMessage("App1 could be registered successfully again")

  self:registerApp(self.mobileSession, applicationData.mediaApp, 2)
end

function Test:SDLProcessesApp1Requests(...)
  -- body
  info("Expected: App2 still alive and SDL processes all messages from App2")

  local cid = self.mobileSession:SendRPC("ListFiles", {})
  --mobile side: expect ListFiles response 
  self.mobileSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

function Test:SDLProcessesApp2Requests(...)
  -- body
  info("Expected: App2 still alive and SDL processes all messages from App2")

  local cid = self.mobileSession2:SendRPC("ListFiles", {})
  --mobile side: expect ListFiles response 
  self.mobileSession2:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

function Test:Postcondition(...)
  -- body
  preconditionHead()
  preconditionMessage("Close 2nd conection")
  self.mobileConnection2:Close()
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered")
  :Times(1)
  :Timeout(2000)

end

---------------------------------------------------------------------------------------------
------------------------------------III TEST BLOCK - END-------------------------------------
---------------------------------------------------------------------------------------------


---------------------------------------------------------------------------------------------
----------------------------------------IV TEST BLOCK----------------------------------------
--------------------------------2 Apps on the same connection--------------------------------
---------------------------------------------------------------------------------------------

-- Begin Test suit OneAppWithPersistentData

-- Description: TC's checks processing 
-- HMI sends UNSUPPORTED_HMI_RESOURCE to App1 (+ requests from App1)
-- HMI sends UNSUPPORTED_HMI_RESOURCE to both Apps
-- HMI sends UNSUPPORTED_HMI_RESOURCE to both Apps while 10 requests are pending for responses
-- HMI sends UNSUPPORTED_HMI_RESOURCE to App1 2 times


-- //////////////////////////////////////////////////////////////////////////////////////////
-- HMI sends UNSUPPORTED_HMI_RESOURCE to App1 (+ requests from App1)
-- //////////////////////////////////////////////////////////////////////////////////////////

-- Begin Precondition.1
-- Description: Register new App
function Test:StartSession2TheSameConnection()
  preconditionHead()
  preconditionMessage("Start new session on the same connection")
  self.mobileSession2 = mobile_session.MobileSession(self, self.mobileConnection, applicationData.nonmediaApp)
end
-- End Precondition.1

-- Begin Precondition.2
-- Description: Register App on 2nd session
function Test:RegisterMediaApp()
  preconditionHead()
  preconditionMessage("Register App on 2nd session")

  info("StartPoint")
  self.mobileSession2:StartService(7)
  :Do(function(_,data)
    -- body
    self:registerApp(self.mobileSession2, applicationData.nonmediaApp, 2)
  end)
end
-- End Precondition.2

function Test:SendUHRToAppOne(...)
  -- body
  testHead()
  testMessage("HMI sends UNSUPPORTED_HMI_RESOURCE to App1")
  info("Expected: SDL unregister App1")

  self:sendUnsupportedHMIResource(self.mobileSession, Test.HMIappId)  
end

function Test:SecondAppIsStillAlive_2(...)
  -- body
  info("Expected: App2 still alive and SDL processes all messages from App2")

  local cid = self.mobileSession2:SendRPC("ListFiles", {})
  --mobile side: expect ListFiles response 
  self.mobileSession2:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

-- //////////////////////////////////////////////////////////////////////////////////////////
-- HMI sends UNSUPPORTED_HMI_RESOURCE to both Apps
-- //////////////////////////////////////////////////////////////////////////////////////////

-- Begin Precondition.1
-- Description: Start Session1
function Test:StartSession()
  preconditionHead()
  preconditionMessage("Start Session1")
  self.mobileSession = mobile_session.MobileSession(
    self, self.mobileConnection, applicationData.mediaApp)
  self.mobileSession:StartService(7)
end
-- End Precondition.1

-- Begin Precondition.2
-- Description: Register Application on connection 1
function Test:PrecondRegisterAppOne_2(...)
  -- body
  self:registerApp(self.mobileSession, applicationData.mediaApp, 1)
end
-- End Precondition.2
function Test:PrecondRegisterAppOne_3(...)
  -- body
  self:registerApp(self.mobileSession, applicationData.mediaApp, 1)
end
function Test:UhrToBothAppsStep1(...)
  -- body
  testHead()
  testMessage("HMI sends UNSUPPORTED_HMI_RESOURCE to both Apps")
  info("Expected: SDL unregister both Apps")

  self:sendUnsupportedHMIResource(self.mobileSession, Test.HMIappId)
end

function Test:UhrToBothAppsStep2(...)
  -- body
  self:sendUnsupportedHMIResource(self.mobileSession2, Test.HMIappIdTwo)
end

-- //////////////////////////////////////////////////////////////////////////////////////////
-- HMI sends UNSUPPORTED_HMI_RESOURCE to both Apps while 10 requests are pending for responses
-- //////////////////////////////////////////////////////////////////////////////////////////

-- Begin Precondition.1
-- Description: Register Apps on both connections
function Test:RegisterApp1(...)
  -- body
  preconditionHead()
  preconditionMessage("Register Apps on both connections")

  self:registerApp(self.mobileSession, applicationData.mediaApp, 1)
end
-- End Precondition.1

-- Begin Precondition.2
-- Description: Register Apps on both connections
function Test:RegisterApp2(...)
  -- body
  self:registerApp(self.mobileSession2, applicationData.nonmediaApp, 2)
end
-- End Precondition.2

function Test:UHRsentWhileTenReqPendingResp(...)
  -- body
  self:tenPendingRequestsFromTwoApps()
end

-- //////////////////////////////////////////////////////////////////////////////////////////
-- HMI sends UNSUPPORTED_HMI_RESOURCE to App1 2 times
-- //////////////////////////////////////////////////////////////////////////////////////////

-- Begin Precondition.1
-- Description: Register Apps 
function Test:RegisterApp1(...)
  -- body
  preconditionHead()
  preconditionMessage("Register Apps on both connections")

  self:registerApp(self.mobileSession, applicationData.mediaApp, 1)
end
-- End Precondition.1

-- Begin Precondition.2
-- Description: Register Apps on both connections
function Test:RegisterApp2(...)
  -- body
  self:registerApp(self.mobileSession2, applicationData.nonmediaApp, 2)
end
-- End Precondition.2

function Test:UHRtoAppOneTwoTimesStepOne(...)
  -- body
  self:sendUnsupportedHMIResource(self.mobileSession, Test.HMIappId)
end

function Test:UHRtoAppOneTwoTimesStepTwo(...)
  -- body
  self:sendUnsupportedHMIResource(self.mobileSession, Test.HMIappId)

  self.hmiConnection:SendNotification("BasicCommunication.OnExitApplication",{ appID = self.HMIappId, reason = "UNSUPPORTED_HMI_RESOURCE" })

  --mobile side: expect notification
  self.mobileSession:ExpectNotification("OnAppInterfaceUnregistered", 
    { 
      reason = "UNSUPPORTED_HMI_RESOURCE"
    })
    :Times(0)

  --mobile side: expect notification
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered")
  :Times(0)

  DelayedExp(1500)
end

function Test:RegisterApp1Again(...)
  -- body
  testHead()
  testMessage("App1 could be registered successfully again")

  self:registerApp(self.mobileSession, applicationData.mediaApp, 2)
end

function Test:SDLProcessesApp1Requests(...)
  -- body
  info("Expected: App2 still alive and SDL processes all messages from App2")

  local cid = self.mobileSession:SendRPC("ListFiles", {})
  --mobile side: expect ListFiles response 
  self.mobileSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

function Test:SDLProcessesApp2Requests(...)
  -- body
  info("Expected: App2 still alive and SDL processes all messages from App2")

  local cid = self.mobileSession2:SendRPC("ListFiles", {})
  --mobile side: expect ListFiles response 
  self.mobileSession2:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

function Test:Postcondition(...)
  -- body
  self.mobileSession2:Stop()
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered")
  :Times(1)
  :Timeout(2000)
end

---------------------------------------------------------------------------------------------
------------------------------------IV TEST BLOCK - END--------------------------------------
---------------------------------------------------------------------------------------------


---------------------------------------------------------------------------------------------
----------------------------------------V TEST BLOCK-----------------------------------------
---------------------------------------Negative checks---------------------------------------
---------------------------------------------------------------------------------------------

-- Begin Test suit OneAppWithPersistentData

-- Description: TC's checks processing 
-- UNSUPPORTED_HMI_RESOURCE with unknown <appID>
-- UNSUPPORTED_HMI_RESOURCE with policy <appID>
-- UNSUPPORTED_HMI_RESOURCE two times in a row
-- UNSUPPORTED_HMI_RESOURCE ten times in a row
-- HMI sends notifications to <appID> after UNSUPPORTED_HMI_RESOURCE
-- HMI sends UNSUPPORTED_HMI_RESOURCE when there are no registered Apps
-- HMI sends UNSUPPORTED_HMI_RESOURCE to only one Navi App from 2 registered Navi Apps


-- //////////////////////////////////////////////////////////////////////////////////////////
-- UNSUPPORTED_HMI_RESOURCE with unknown <appID>
-- //////////////////////////////////////////////////////////////////////////////////////////

function Test:UhrWithUnknownAppID(...)
  -- body
  testHead()
  testMessage("UNSUPPORTED_HMI_RESOURCE with unknown <appID>")
  info("Expected: SDL ignores notification")

  --hmi side: sending BasicCommunication.OnExitApplication notification
  self.hmiConnection:SendNotification("BasicCommunication.OnExitApplication",{ appID = "Igor", reason = "UNSUPPORTED_HMI_RESOURCE" })

  --mobile side: expect notification
  self.mobileSession:ExpectNotification("OnAppInterfaceUnregistered", 
    { 
      reason = "UNSUPPORTED_HMI_RESOURCE"
    })
    :Times(0)

  --mobile side: expect notification
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = "applicationID", unexpectedDisconnect = false})
  :Times(0)

  -- TODO: uncommment after fixing bug APPLINK-20884
  --req. APPLINK-20647
  --hmi side: BasicCommunication.UpdateAppList
  -- EXPECT_HMICALL("BasicCommunication.UpdateAppList")
  -- :ValidIf(function(_,data)
  --   if #data.params.applications == 0 then
  --   return true
  --   else 
  --     print(" \27[36m Application array in BasicCommunication.UpdateAppList contains "..tostring(#data.params.applications)..", expected 0 \27[0m")
  --     return false
  --   end
  -- end)
  -- :Do(function(_,data)
  --   --hmi side: sending BasicCommunication.UpdateAppList response 
  --   self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {}) 
  -- end)

  DelayedExp(1500)
end

function Test:SDLProcessesAppRequests(...)
  -- body
  info("Expected: App still alive and SDL processes all messages from it")

  local cid = self.mobileSession:SendRPC("ListFiles", {})
  --mobile side: expect ListFiles response 
  self.mobileSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

-- //////////////////////////////////////////////////////////////////////////////////////////
-- UNSUPPORTED_HMI_RESOURCE with policy <appID>
-- //////////////////////////////////////////////////////////////////////////////////////////

function Test:UhrWithUnknownAppID(...)
  -- body
  testHead()
  testMessage("UNSUPPORTED_HMI_RESOURCE with policy <appID>")
  info("Expected: SDL ignores notification")

  --hmi side: sending BasicCommunication.OnExitApplication notification
  self.hmiConnection:SendNotification("BasicCommunication.OnExitApplication",
    { appID = applicationData.mediaApp.appId, reason = "UNSUPPORTED_HMI_RESOURCE" })

  --mobile side: expect notification
  self.mobileSession:ExpectNotification("OnAppInterfaceUnregistered", 
    { 
      reason = "UNSUPPORTED_HMI_RESOURCE"
    })
    :Times(0)

  --mobile side: expect notification
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered")
  :Times(0)

  DelayedExp(1000)
end

function Test:SDLProcessesAppRequests(...)
  -- body
  info("Expected: App still alive and SDL processes all messages from it")

  local cid = self.mobileSession:SendRPC("ListFiles", {})
  --mobile side: expect ListFiles response 
  self.mobileSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

-- //////////////////////////////////////////////////////////////////////////////////////////
-- UNSUPPORTED_HMI_RESOURCE two times in a row
-- //////////////////////////////////////////////////////////////////////////////////////////

function Test:UhrTwoTimesInARowStep1(...)
  -- body
  testHead()
  testMessage("UNSUPPORTED_HMI_RESOURCE two times in a row")
  info("Expected: SDL 2nd notification")

  self:sendUnsupportedHMIResource(self.mobileSession, Test.HMIappId)
end

function Test:UhrTwoTimesInARowStep2(...)
  -- body
  self.hmiConnection:SendNotification("BasicCommunication.OnExitApplication",{ appID = self.HMIappId, reason = "UNSUPPORTED_HMI_RESOURCE" })

  --mobile side: expect notification
  self.mobileSession:ExpectNotification("OnAppInterfaceUnregistered", 
    { 
      reason = "UNSUPPORTED_HMI_RESOURCE"
    })
    :Times(0)

  --mobile side: expect notification
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = applicationID, unexpectedDisconnect = false})
  :Times(0)

  DelayedExp(1000)
end

-- //////////////////////////////////////////////////////////////////////////////////////////
-- UNSUPPORTED_HMI_RESOURCE ten times in a row
-- //////////////////////////////////////////////////////////////////////////////////////////

function Test:PrecondRegisterApp()
  preconditionHead()
  preconditionMessage("App's registration")
  self:registerApp(self.mobileSession)
end

function Test:UhrTwoTimesInARowStep1(...)
  -- body
  testHead()
  testMessage("UNSUPPORTED_HMI_RESOURCE ten times in a row")
  info("Expected: SDL unregister App and ignores all next notifications")

  self:sendUnsupportedHMIResource(self.mobileSession, Test.HMIappId)
end

function Test:UhrTwoTimesInARowStep2(...)
  -- body
  for i=1,9 do
    self.hmiConnection:SendNotification("BasicCommunication.OnExitApplication",{ appID = self.HMIappId, reason = "UNSUPPORTED_HMI_RESOURCE" })
  end

  --mobile side: expect notification
  self.mobileSession:ExpectNotification("OnAppInterfaceUnregistered", 
    { 
      reason = "UNSUPPORTED_HMI_RESOURCE"
    })
    :Times(0)

  --mobile side: expect notification
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = applicationID, unexpectedDisconnect = false})
  :Times(0)

  DelayedExp(1000)
end

function Test:AbleToRegisterApp()
  self:registerApp(self.mobileSession)
end

-- //////////////////////////////////////////////////////////////////////////////////////////
-- HMI sends notifications to <appID> after UNSUPPORTED_HMI_RESOURCE
-- //////////////////////////////////////////////////////////////////////////////////////////

-- Begin Precondition.1
-- Description: Activation
function Test:PrecondActivation(...)
  -- body
  self:activateApplication(Test.HMIappId)
end
-- End Precondition.1


-- Begin Precondition.2
-- Description: Addind data
function Test:PrecondAddData(...)
  -- body
  preconditionHead()
  preconditionMessage("Addind data")

  local cidCmd = self.mobileSession:SendRPC("AddCommand", {cmdID = 1, menuParams = {menuName = "Play"} })
  local cidButton = self.mobileSession:SendRPC("SubscribeButton", {buttonName = "PRESET_1"})
  local cidVehicle = self.mobileSession:SendRPC("SubscribeVehicleData", {speed = true})


  --hmi side: UI.AddCommand
  EXPECT_HMICALL("UI.AddCommand", {appID = self.HMIappId, cmdID = 1, menuParams = {menuName = "Play"} })
  :Do(function(_,data)
    -- body
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
  end)

  --hmi side: VehicleInfo.SubscribeVehicleData
  EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData")
  :Do(function(_,data)
    -- body
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
  end)

  --hmi side: Buttons.OnButtonSubscription
  EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription", {isSubscribed = true, name = "PRESET_1"})
  :Times(AtMost(1))

  --mobile side: expect notification
  EXPECT_NOTIFICATION("OnHashChange")
  :Times(3)

  --mobile side: expect AddCommand response 
  EXPECT_RESPONSE(cidCmd, { success = true, resultCode = "SUCCESS" })

  --mobile side: expect SubscribeButton response 
  EXPECT_RESPONSE(cidButton, { success = true, resultCode = "SUCCESS" })

  --mobile side: expect SubscribeVehicleData response 
  EXPECT_RESPONSE(cidVehicle, { success = true, resultCode = "SUCCESS" })

  DelayedExp(5000)

end
-- End Precondition.2

function Test:UhrTwoTimesInARowStep1(...)
  -- body
  testHead()
  testMessage("HMI sends notifications to <appID> after UNSUPPORTED_HMI_RESOURCE")
  info("Expected: SDL ignores all such notifications")

  self:sendUnsupportedHMIResource(self.mobileSession, Test.HMIappId)
end

function Test:UhrTwoTimesInARowStep2(...)
  -- body
  --hmi side: sending Buttons.OnButtonPress notification
  self.hmiConnection:SendNotification("Buttons.OnButtonPress",{ appID = self.HMIappId, name = "PRESET_1" })

  EXPECT_NOTIFICATION("OnButtonPress")
  :Times(0)

  DelayedExp(500)
end

function Test:UhrTwoTimesInARowStep3(...)
  -- body
  --hmi side: sending Buttons.OnButtonEvent notification
  self.hmiConnection:SendNotification("Buttons.OnButtonEvent",{ appID = self.HMIappId, name = "PRESET_1" })

  EXPECT_NOTIFICATION("OnButtonEvent")
  :Times(0)

  DelayedExp(500)
end

function Test:UhrTwoTimesInARowStep4(...)
  -- body
  --hmi side: sending VehicleInfo.OnVehicleData notification
  self.hmiConnection:SendNotification("VehicleInfo.OnVehicleData",{ speed = 60.1 })

  EXPECT_NOTIFICATION("OnVehicleData")
  :Times(0)

  DelayedExp(500)
end

function Test:UhrTwoTimesInARowStep5(...)
  -- body
  --hmi side: sending UI.OnCommand notification
  self.hmiConnection:SendNotification("UI.OnCommand",{ appID = self.HMIappId, cmdID = 1 })

  EXPECT_NOTIFICATION("OnCommand")
  :Times(0)

  DelayedExp(500)
end

-- //////////////////////////////////////////////////////////////////////////////////////////
-- HMI sends UNSUPPORTED_HMI_RESOURCE when there are no registered Apps
-- //////////////////////////////////////////////////////////////////////////////////////////

function Test:UhrNoApps(...)
  -- body
  testHead()
  testMessage("HMI sends UNSUPPORTED_HMI_RESOURCE when there are no registered Apps")
  info("Expected: SDL ignores it")

  self.hmiConnection:SendNotification("BasicCommunication.OnExitApplication",{ appID = self.HMIappId, reason = "UNSUPPORTED_HMI_RESOURCE" })

  --mobile side: expect notification
  self.mobileSession:ExpectNotification("OnAppInterfaceUnregistered", 
    { 
      reason = "UNSUPPORTED_HMI_RESOURCE"
    })
    :Times(0)

  --mobile side: expect notification
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = applicationID, unexpectedDisconnect = false})
  :Times(0)

  DelayedExp(1000)
end

-- //////////////////////////////////////////////////////////////////////////////////////////
-- HMI sends UNSUPPORTED_HMI_RESOURCE to only one Navi App from 2 registered Navi Apps
-- //////////////////////////////////////////////////////////////////////////////////////////

-- Begin Precondition.1
-- Description: Register Navi App1
function Test:PrecondRegisterNaviApp1()
  preconditionHead()
  preconditionMessage("Register Navi App1")
  self:registerApp(self.mobileSession, applicationData.navigationAppOne)
end
-- End Precondition.1

-- Begin Precondition.2
-- Description: Register new App
function Test:StartSession2()
  preconditionHead()
  preconditionMessage("Start new session on the same connection")
  self.mobileSession2 = mobile_session.MobileSession(self, self.mobileConnection, applicationData.navigationAppTwo)
end
-- End Precondition.2

-- Begin Precondition.3
-- Description: Register App on 2nd session
function Test:PrecondRegisterNaviApp2()
  preconditionHead()
  preconditionMessage("Register App on 2nd session")

  info("StartPoint")
  self.mobileSession2:StartService(7)
  :Do(function(_,data)
    -- body
    self:registerApp(self.mobileSession2, applicationData.navigationAppTwo, 2)
  end)
end
-- End Precondition.3

function Test:SendUHRToNaviAppOne(...)
  -- body
  testHead()
  testMessage("HMI sends UNSUPPORTED_HMI_RESOURCE to only one Navi App from 2 registered Navi Apps")
  info("Expected: SDL unregisters only specified App")

  self:sendUnsupportedHMIResource(self.mobileSession, Test.HMIappId)  
end

function Test:SecondAppIsStillAlive_3(...)
  -- body
  info("Expected: App2 still alive and SDL processes all messages from App2")

  local cid = self.mobileSession2:SendRPC("ListFiles", {})
  --mobile side: expect ListFiles response 
  self.mobileSession2:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

function Test:Postcondition(...)
  -- body
  self.mobileSession2:Stop()
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered")
  :Times(1)
  :Timeout(2000)
end

---------------------------------------------------------------------------------------------
---------------------------------------VI TEST BLOCK-----------------------------------------
--------------------------------------Endurance checks---------------------------------------
---------------------------------------------------------------------------------------------

-- Begin Test suit Endurace_UNSUPPORTED_HMI_RESOURCE

-- Description: TC's checks processing 
-- Repeated registration-unregistration of one App by reason UNSUPPORTED_HMI_RESOURCE (25 times)
-- Repeated registration-unregistration of two Apps by reason UNSUPPORTED_HMI_RESOURCE (25 times)


-- //////////////////////////////////////////////////////////////////////////////////////////
-- Repeated registration-unregistration of one App by reason UNSUPPORTED_HMI_RESOURCE (25 times)
-- //////////////////////////////////////////////////////////////////////////////////////////

for i=1,10 do

  function Test:SendUnsupportedHmiResource(...)
    -- body
    self:sendUnsupportedHMIResource(self.mobileSession, Test.HMIappId, 100)
  end

  function Test:RegisterApp(...)
    self:registerApp(self.mobileSession, applicationData.mediaApp)
  end
end

function Test:Postcondition(...)
  -- body
  local cid = self.mobileSession:SendRPC("UnregisterAppInterface",{})

  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered")
  :Times(1)

  EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
  :Timeout(500)
end

-- //////////////////////////////////////////////////////////////////////////////////////////
-- Repeated registration-unregistration of two Apps by reason UNSUPPORTED_HMI_RESOURCE (25 times)
-- //////////////////////////////////////////////////////////////////////////////////////////

---------------------------------------------------------------------------------------------
-----------------------------------VI TEST BLOCK - END---------------------------------------
---------------------------------------------------------------------------------------------


-- Postcondition to entire test - restore sdl_preloaded_pt.json from backup, delete backup file
function Test:StopSDLForPermissionsChange()
  preconditionHead()
  preconditionMessage("Stop SDL for restore original sdl_preloaded_pt.json")
  StopSDL()
end

function Test:PostConditionRestoreBackUpPreloaded(...)
  -- body
  os.execute('cp ' .. config.pathToSDL .. "~sdl_preloaded_pt.json" .. " " .. config.preloaded)
  os.execute('rm ' .. config.pathToSDL .. "~sdl_preloaded_pt.json")
end



---------------------------------------------------------------------------------------------
-------------------------------------------Postcondition-------------------------------------
---------------------------------------------------------------------------------------------

--TODO: Will be updated after policy flow implementation
-- Postcondition: restore sdl_preloaded_pt.json
policyTable:Restore_preloaded_pt()
	
return Test 

