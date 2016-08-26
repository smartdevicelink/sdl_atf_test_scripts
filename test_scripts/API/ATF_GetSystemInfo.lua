--------------------------------------------------------------------------------
-- Preconditions before ATF start
--------------------------------------------------------------------------------
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')

--------------------------------------------------------------------------------
--Precondition: preparation connecttest_getSystemInfo.lua
commonPreconditions:Connecttest_without_ExitBySDLDisconnect_WithoutOpenConnectionRegisterApp("connecttest_getSystemInfo.lua")

-- read file
f = assert(io.open('./user_modules/connecttest_getSystemInfo.lua', "r"))

fileContent = f:read("*all")
f:close()

-- remove InitHMI_onReady from ATF start 
local pattern1 = "function .?module%:InitHMI_onReady.-initHMI_onReady.-end"
local pattern1Result = fileContent:match(pattern1)
  if pattern1Result == nil then 
    print(" \27[31m InitHMI_onReady functions is not found in /user_modules/connecttest_getSystemInfo.lua \27[0m ")
  else
    fileContent  =  string.gsub(fileContent, pattern1, "")
  end

-- update initHMI_onReady function
  local pattern2 = "function .?module%.?:.?initHMI%_onReady%(.?%)"
  local ResultPattern2 = fileContent:match(pattern2)

  if ResultPattern2 == nil then 
    print(" \27[31m initHMI_onReady function is not found in /user_modules/connecttest_getSystemInfo.lua.lua \27[0m ")
  else
    fileContent  =  string.gsub(fileContent, pattern2, 'function module:initHMI_onReady(ccpu, success) \n ccpu = ccpu or "ccpu_version" \n if ccpu == "absent" then ccpu = nil end \n print(ccpu) \n print("Start of InitHMI") \n success = success or "SUCCESS"')
  end

-- update resultCode value in EXPECT_HMIEVENT in ExpectRequest function
local pattern3 = "local%s-function%s-ExpectRequest.-end%)%s-end"
local pattern3Result = fileContent:match(pattern3)
  if pattern3Result == nil then 
    print(" \27[31m local function ExpectRequest is not found in /user_modules/connecttest_getSystemInfo.lua \27[0m ")
  else
    local pattern3_1 = 'self%s-.%s-hmiConnection%s-:%s-SendResponse%s-%(%s-data.id%s-,%s-data.method%s-,%s-"SUCCESS"%s-,%s-params%s-%)'
    local pattern3_1Result = pattern3Result:match(pattern3_1)
    if pattern3_1Result == nil then 
        print(" \27[31m SendResponse sending is not found in ExpectRequest function \27[0m ")
    else
      pattern3Result  =  string.gsub(pattern3Result, pattern3_1, 'self.hmiConnection:SendResponse(data.id, data.method, success, params)')
      fileContent = string.gsub(fileContent, pattern3,pattern3Result)
    end
  end

-- update BasicCommunication.GetSystemInfo expectation
local pattern4 = 'ExpectRequest%s-%(%s-"BasicCommunication.GetSystemInfo".-%{.-%}%s-%)'
  ResultPattern4 =  fileContent:match(pattern4)

  if ResultPattern4 == nil then 
    print(" \27[31m ExpectRequest(\"BasicCommunication.GetSystemInfo\" struct is not found in /user_modules/connecttest_getSystemInfo.lua \27[0m ")
  else
    -- update false valur to true
    local pattern4_1 = '"BasicCommunication.GetSystemInfo".-%{'
    local pattern4_1Result = ResultPattern4:match(pattern4_1)
    if pattern4_1Result == nil then 
        print(" \27[31m BasicCommunication.GetSystemInfo part is not found in ExpectRequest GetSystemInfo function call\27[0m ")
    else
      ResultPattern4  =  string.gsub(ResultPattern4, pattern4_1, '"BasicCommunication.GetSystemInfo", true ,{')
      fileContent = string.gsub(fileContent, pattern4,ResultPattern4)
    end
    -- update ccpu_version value
    local pattern4_2 = 'ccpu%_version%s-=%s-.-,'
    local pattern4_2Result = ResultPattern4:match(pattern4_2)
    if ResultPattern4 == nil then 
        print(" \27[31m ccpu_version is not found in ExpectRequest GetSystemInfo function call \27[0m ")
    else
      ResultPattern4  =  string.gsub(ResultPattern4, pattern4_2, 'ccpu_version = ccpu,')
      fileContent = string.gsub(fileContent, pattern4,ResultPattern4)
    end
  end


  f = assert(io.open('./user_modules/connecttest_getSystemInfo.lua', "w+"))
  f:write(fileContent)
  f:close()

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

Test = require('user_modules/connecttest_getSystemInfo')
require('cardinalities')
-- local events = require('events')
local mobile_session = require('mobile_session')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
require('user_modules/AppTypes')

---------------------------------------------------------------------------------------------
-------------------------------------------Functions-------------------------------------
---------------------------------------------------------------------------------------------

local function CreateSession( self)
  self.mobileSession = mobile_session.MobileSession(
        self,
        self.mobileConnection)
end

local function userPrint( color, message)
  print ("\27[" .. tostring(color) .. "m " .. tostring(message) .. " \27[0m")
end

local function sleep(sec)
  -- body
  os.execute("sleep " .. sec)
end

local function RegisterApp(self, passCriteria)
  local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)

  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
    :Do(function(_,data)
      HMIAppID = data.params.application.appID
      self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
    end)

  self.mobileSession:ExpectResponse(correlationId, { success = true })
  :ValidIf(function (_,data)
    if  passCriteria == nil then
      if data.payload.systemSoftwareVersion then
        userPrint( 31, "RAI response contains systemSoftwareVersion parameter, expected absence of parameter")
        return false
      else
        return true
      end
    elseif data.payload.systemSoftwareVersion == passCriteria then
      return true
    else
      userPrint( 31, "systemSoftwareVersion value in RAI response is unexpected '" .. tostring(data.payload.systemSoftwareVersion) .. "', expected value is '" .. tostring(passCriteria) .. "'")
      return false
    end
  end)

end

function RestartSDL(self, suffix, ccpu)
  -- body
  
  Test["StopSDL"..tostring(suffix)] = function (self)
    StopSDL()
  end

  Test["StartSDL" .. tostring(suffix)] = function (self)
    StartSDL(config.pathToSDL, config.ExitOnCrash)
  end

  Test["TestInitHMI" .. tostring(suffix)] = function (self)
    self:initHMI()
  end

  Test["TestInitHMIOnReady" .. tostring(suffix)] = function (self)
    self:initHMI_onReady(ccpu)
  end

end


function Check_ccpu_version(self, suffix, ccpu)
  
  -- Test to check ccpu_version parameter in policy DB
  Test["CheckPolicyDB"..tostring(suffix)] = function (self)

    local query

    if commonSteps:file_exists(config.pathToSDL .. "storage/policy.sqlite") then
      query = "sqlite3 " .. config.pathToSDL .. "storage/policy.sqlite".. " \"select ccpu_version from module_meta;\""
    elseif commonSteps:file_exists(config.pathToSDL .. "policy.sqlite") then
      query = "sqlite3 " .. config.pathToSDL .. "policy.sqlite".. " \"select ccpu_version from module_meta;\""
    else userPrint( 31, "policy.sqlite is not found" )
    end

    if query ~= nil then

      os.execute("sleep 3")
      local handler = io.popen(query, 'r')
      os.execute("sleep 1")
      local result = handler:read( '*l' )
      handler:close()

      print(result)

      if result == ccpu then
        --do
        return true
      else
        self:FailTestCase("ccpu value in DB is unexpected value " .. tostring(result))
        return false    
      end
    end
  end

end

-- Precondition: removing user_modules/connecttest_getSystemInfo.lua
function Test:Precondition_remove_user_connecttest()
  os.execute( "rm -f ./user_modules/connecttest_getSystemInfo.lua" )
end
	
---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------

--Check that SDL request ccpu_version on start of each ignition cycle
local version = ''
local indexOfTests = 1
for i=indexOfTests, indexOfTests + 2 do
  version = tostring(i) .. '.0'
  RestartSDL(self, i, version)
  Check_ccpu_version(self, i, nil)
end

indexOfTests = indexOfTests + 1

function Test:ConnectMobile()
  self:connectMobile()
end

function Test:StartSession()
   CreateSession(self)
end

function Test:RegisterApp()
  self.mobileSession:StartService(7)
  :Do(function (_,data)
    RegisterApp(self, "3.0")
  end)
end

--ccpu_version is empty in response
RestartSDL(self, indexOfTests, "")
Test["ConnectMobile" .. tostring(indexOfTests)] = function (self)
  self:connectMobile()
end
Test["StartSession" .. tostring(indexOfTests)] = function (self)
  CreateSession(self)
end
Test["RegisterApp" .. tostring(indexOfTests)] = function (self)
  userPrint(33, "===Test - ccpu_version is empty in response===")
  self.mobileSession:StartService(7)
  :Do(function (_,data)
    RegisterApp(self, nil)
  end)
end
indexOfTests = indexOfTests + 1

--ccpu_version is not valid in response
RestartSDL(self, indexOfTests, 123)
Test["ConnectMobile" .. tostring(indexOfTests)] = function (self)
  self:connectMobile()
end
Test["StartSession" .. tostring(indexOfTests)] = function (self)
  CreateSession(self)
end
Test["RegisterApp" .. tostring(indexOfTests)] = function (self)
  userPrint(33, "===Test - ccpu_version is not valid in response===")
  self.mobileSession:StartService(7)
  :Do(function (_,data)
    RegisterApp(self, nil)
  end)
end
indexOfTests = indexOfTests + 1

--ccpu_version is absent in response
RestartSDL(self, indexOfTests, "absent")
Test["ConnectMobile" .. tostring(indexOfTests)] = function (self)
  self:connectMobile()
end
Test["StartSession" .. tostring(indexOfTests)] = function (self)
  CreateSession(self)
end
Test["RegisterApp" .. tostring(indexOfTests)] = function (self)
  userPrint(33, "===Test - ccpu_version is absent in response===")
  self.mobileSession:StartService(7)
  :Do(function (_,data)
    RegisterApp(self, nil)
  end)
end
indexOfTests = indexOfTests + 1

--ccpu_version is empty in Policy DB

Test["StopSDL"..tostring(indexOfTests)] = function (self)
  StopSDL()
end

function Test:PreconditionRemoveDB(...)
  -- body
  local result = os.execute("rm " .. config.pathToSDL .. "storage/policy.sqlite") 
  return result
end

Test["StartSDL" .. tostring(indexOfTests)] = function (self)
  StartSDL(config.pathToSDL, config.ExitOnCrash)
  sleep(2)
end

Test["TestInitHMI" .. tostring(indexOfTests)] = function (self)
  self:initHMI()
end

Test["TestInitHMIOnReady" .. tostring(indexOfTests)] = function (self)
  self:initHMI_onReady("absent")
end

Test["ConnectMobile" .. tostring(indexOfTests)] = function (self)
  self:connectMobile()
end
Test["StartSession" .. tostring(indexOfTests)] = function (self)
  CreateSession(self)
end
Test["RegisterApp" .. tostring(indexOfTests)] = function (self)
  userPrint(33, "===Test - ccpu_version is absent in Policy DB===")
  self.mobileSession:StartService(7)
  :Do(function (_,data)
    RegisterApp(self, nil)
  end)
end
indexOfTests = indexOfTests + 1

local errorneousCodes = { "UNSUPPORTED_REQUEST", "UNSUPPORTED_RESOURCE", "DISALLOWED", "REJECTED", "ABORTED", 
                          "IGNORED", "RETRY", "IN_USE", "DATA_NOT_AVAILABLE", "TIMED_OUT", "INVALID_DATA", 
                          "CHAR_LIMIT_EXCEEDED", "INVALID_ID", "DUPLICATE_NAME", "APPLICATION_NOT_REGISTERED", 
                          "WRONG_LANGUAGE", "OUT_OF_MEMORY", "TOO_MANY_PENDING_REQUESTS", "NO_APPS_REGISTERED", 
                          "NO_DEVICES_CONNECTED", "WARNINGS", "GENERIC_ERROR", "USER_DISALLOWED", "TRUNCATED_DATA"}

for key,value in ipairs(errorneousCodes) do
  Test["StopSDL"..tostring(indexOfTests)] = function (self)
    StopSDL()
  end

  function Test:PreconditionRemoveDB(...)
    -- body
    local result = os.execute("rm " .. config.pathToSDL .. "storage/policy.sqlite") 
    return result
  end

  Test["StartSDL" .. tostring(indexOfTests)] = function (self)
    StartSDL(config.pathToSDL, config.ExitOnCrash)
    sleep(4)
  end

  Test["TestInitHMI" .. tostring(indexOfTests)] = function (self)
    self:initHMI()
  end

  Test["TestInitHMIOnReady" .. tostring(indexOfTests)] = function (self)
    self:initHMI_onReady("3.0", value)
  end

  Test["ConnectMobile" .. tostring(indexOfTests)] = function (self)
    self:connectMobile()
  end
  Test["StartSession" .. tostring(indexOfTests)] = function (self)
    CreateSession(self)
  end
  Test["RegisterApp" .. tostring(indexOfTests)] = function (self)
    userPrint(33, "===Test - GetSystemInfo error code: " .. tostring(value) .. "===")
    self.mobileSession:StartService(7)
    :Do(function (_,data)
      RegisterApp(self, nil)
    end)
  end
  indexOfTests = indexOfTests + 1
end
