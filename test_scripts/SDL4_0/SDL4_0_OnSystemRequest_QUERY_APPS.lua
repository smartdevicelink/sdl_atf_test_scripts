--------------------------------------------------------------------------------
-- Preconditions
--------------------------------------------------------------------------------
local Preconditions = require('user_modules/shared_testcases/commonPreconditions')

--------------------------------------------------------------------------------
-- Set 4 protocol as default for script
config.defaultProtocolVersion = 4

--------------------------------------------------------------------------------
--Precondition: preparation connecttest_without_ExitBySDLDisconnect_regApp.lua
Preconditions:Connecttest_without_ExitBySDLDisconnect_OpenConnection("connecttest_without_ExitBySDLDisconnect_regApp.lua")

--------------------------------------------------------------------------------
-- creation dummy connection for new device
os.execute("ifconfig lo:1 1.0.0.1")


Test = require('user_modules/connecttest_without_ExitBySDLDisconnect_regApp')
require('cardinalities')
local events = require('events')
local mobile_session = require('mobile_session')
local mobile  = require('mobile_connection')
local tcp = require('tcp_connection')
local file_connection  = require('file_connection')
local json = require("json")
require('user_modules/AppTypes')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')

-- Set EnableProtocol4 to true
commonFunctions:SetValuesInIniFile("EnableProtocol4%s-=%s-[%w]-%s-\n", "EnableProtocol4", "true" )


local function userPrint( color, message)
  print ("\27[" .. tostring(color) .. "m " .. tostring(message) .. " \27[0m")
end

local function DelayedExp(time)
  local event = events.Event()
  event.matches = function(self, e) return self == e end
  EXPECT_EVENT(event, "Delayed event")
    :Timeout(time + 1000)
  RUN_AFTER(function()
              RAISE_EVENT(event, event)
            end, time)
end

--Sending OnHMIStatus notification form mobile application
local function SendingOnHMIStatusFromMobile(self, level, audibleState, sessionName )
	
	if level == nil then
		level = "FULL"
	end

	if audibleState == nil then
		audibleState = "NOT_AUDIBLE"
	end

	if sessionName == nil then
		sessionName = self.mobileSession
	end

	sessionName.correlationId = sessionName.correlationId + 1

  	local msg = 
        {
          serviceType      = 7,
          frameInfo        = 0,
          rpcType          = 2,
          rpcFunctionId    = 32768,
          rpcCorrelationId = sessionName.correlationId,
          payload          = '{"hmiLevel" :"' .. tostring(level) .. '", "audioStreamingState" : "' .. tostring(audibleState) .. '", "systemContext" : "MAIN"}'
        }

    sessionName:Send(msg)

    if 
    	sessionName == self.mobileSession then
      		sessionDesc = "first session"
  	elseif
	    sessionName == self.mobileSession1 then
	      	sessionDesc = "second session"
  	elseif
	    sessionName == self.mobileSession2 then
	      	sessionDesc = "third session"
  	elseif
	    sessionName == self.mobileSession3 then
	      	sessionDesc = "fourth session"
  	elseif
	    sessionName == self.mobileSession4 then
	      	sessionDesc = "fifth session"
  	elseif
	    sessionName == self.mobileSession5 then
	      	sessionDesc = "sixth session"
  	elseif
	    sessionName == self.mobileSession6 then
	      	sessionDesc = "sixth session"
  	end

  	userPrint(33, "Sending OnHMIStatus from mobile app with level ".. tostring(level) .. " in " .. tostring(sessionDesc) )

end

--Precondition: Unregister registered app
local function UnregisterAppInterface_Success(self, sessionName, iappName)
	if sessionName == nil then
		sessionName = self.mobileSession
	end

	if iappName == nil then
		iappName = config.application1.registerAppInterfaceParams.appName
	end

  	--mobile side: UnregisterAppInterface request 
  	local CorIdURAI = sessionName:SendRPC("UnregisterAppInterface", {})

  	--hmi side: expected  BasicCommunication.OnAppUnregistered
  	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = self.applications[iappName], unexpectedDisconnect = false})

  	--mobile side: UnregisterAppInterface response 
  	sessionName:ExpectResponse(CorIdURAI, {success = true , resultCode = "SUCCESS"})

end


--Precondition: "Register app"
local function AppRegistration(self, sessionName , iappName , iappID, isMediaFlag)

	local audibleStateRegister

	if sessionName == nil then
		sessionName = self.mobileSession
	end

	if iappName == nil then
		iappName = config.application1.registerAppInterfaceParams.appName
	end
	if iappID == nil then
		iappID = config.application1.registerAppInterfaceParams.fullAppID
	end
	if isMediaFlag == nil then
		isMediaFlag = config.application1.registerAppInterfaceParams.isMediaApplication
	end

    local CorIdRegister = sessionName:SendRPC("RegisterAppInterface",
    {
      syncMsgVersion =
      {
      majorVersion = 4,
      minorVersion = 3
      },
      appName = iappName,
      isMediaApplication = isMediaFlag,
      languageDesired = 'EN-US',
      hmiDisplayLanguageDesired = 'EN-US',
      appHMIType = { "DEFAULT" },
      appID = iappID
    })

    EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
    {
      application = 
      {
      appName = iappName
      }
    })
    :Do(function(_,data)
        self.applications[iappName] = data.params.application.appID
    end)

    sessionName:ExpectResponse(CorIdRegister, { success = true, resultCode = "SUCCESS" })

end

--Unregister and register application
local function Precondition_UnregisterRegisterApp(prefix)

	Test["Precondition_UnregisterApp_" .. tostring(prefix)] = function(self)
		UnregisterAppInterface_Success(self)
	end

	Test["Precondition_RegisterApp_" .. tostring(prefix)] = function(self)
		AppRegistration(self)

		EXPECT_NOTIFICATION("OnHMIStatus",
			{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})

		EXPECT_NOTIFICATION("OnSystemRequest", { requestType = "LOCK_SCREEN_ICON_URL" })
			:Times(AtMost(1))

		DelayedExp(500)

	end
end

--Check values in OnSystemRequest header
local function HeaderValuesCheck(binaryData, Table)

	local errorFlag = true

	local PolicyDBPath

	if commonSteps:file_exists(tostring(config.pathToSDL) .. "storage/policy.sqlite") == true then 
		PolicyDBPath = tostring(config.pathToSDL) .. "storage/policy.sqlite"
	elseif commonSteps:file_exists(tostring(config.pathToSDL) .. "policy.sqlite") == true then 
		PolicyDBPath = tostring(config.pathToSDL) .. "policy.sqlite"
	else
		userPrint(31, "policy.sqlite file is not found")
		errorFlag = false
	end

	os.execute(" sleep 2 ")

	local timeout_after_x_seconds = "sqlite3 " .. tostring(PolicyDBPath) .. " \"SELECT timeout_after_x_seconds FROM module_config WHERE rowid = 1\""

	local aHandle = assert( io.popen( timeout_after_x_seconds , 'r'))
		local timeout_after_x_secondsValue = aHandle:read( '*l' ) 

	if timeout_after_x_secondsValue then

		local ExpectParamsValues = { 
			{paramName = "ContentType", paramValue = "application/json"}, 
			{paramName = "ConnectTimeout", paramValue = timeout_after_x_secondsValue}, 
			{paramName = "DoOutput", paramValue = true}, 
			{paramName = "DoInput", paramValue = true}, 
			{paramName = "UseCaches", paramValue = false}, 
			{paramName = "RequestMethod", paramValue = "GET"}, 
			{paramName = "ReadTimeout", paramValue = tonumber(timeout_after_x_secondsValue)}, 
			{paramName = "InstanceFollowRedirects", paramValue = false}, 
			{paramName = "charset", paramValue = "utf-8"}, 
			{paramName = "Content_Length", paramValue = 0}
		}

		if
			not Table then
			userPrint(31, "Transfered table is empty ")
				errorFlag = false
		elseif
			not Table.HTTPRequest then
				userPrint(31, "OnSystemRequest header does not contain HTTPRequest struct, received struct " ..tostring(binaryData))
				errorFlag = false

			print ("\27[31m \n Received header: ")
			print_table( Table)
			print ("\27[0m" )


		elseif
			not Table.HTTPRequest.headers then
				userPrint(31, "OnSystemRequest header does not contain HTTPRequest.headers struct, received struct " ..tostring(binaryData))
				errorFlag = false

			print ("\27[31m \n Received header: ")
			print_table( Table)
			print ("\27[0m" )

		else
			for i=1, #ExpectParamsValues do
				if Table.HTTPRequest.headers[ExpectParamsValues[i].paramName] ~= ExpectParamsValues[i].paramValue then
					userPrint(31, tostring(ExpectParamsValues[i].paramName) .. " in OnSystemRequest header has value " .. tostring(Table.HTTPRequest.headers[ExpectParamsValues[i].paramName]) .. ", instead of '" .. tostring(ExpectParamsValues[i].paramValue) .. "'")
					errorFlag = false
				end
			end

			print ("\27[31m \n Received header: ")
			print_table( Table)
			print ("\27[0m" )

		end

	else
		userPrint(31, "Query to policy.sqlite is failed")
		errorFlag = false
	end

	return errorFlag

end

userPrint(33, " Because of ATF defect APPLINK-16052 check of deviceInfo params in BC.UpdateAppList is commented ")

--Precondition: Openning first session
function Test:Openning1Session()
  self.mobileSession = mobile_session.MobileSession(
  self,
  self.mobileConnection)

  self.mobileSession.sendHeartbeatToSDL = false
  self.mobileSession.answerHeartbeatFromSDL = true

  self.mobileSession:StartService(7)
end

--Precondition: Openning second session
function Test:Openning2Session()
  self.mobileSession1 = mobile_session.MobileSession(
  	self,
  	self.mobileConnection)

  self.mobileSession1.sendHeartbeatToSDL = false
  self.mobileSession1.answerHeartbeatFromSDL = true

  self.mobileSession1:StartService(7)
end

-- ===================================================================================--
-- APPLINK-17892: 01[P][MAN]_TC_SDL_sends_OnSystemRequest_to_registered_app
-- Description: Check that SDL sends OnSystemRequest(QUERY_APPS) to application of v4 protocol after registering and switching it to foreground on mobile.
-- ===================================================================================--

function Test:OnSystemRequestQueryAppsAfterAppIsRegisteredForegroundOnMobile()
	userPrint(34, "=================================== Test  Case ===================================")

	AppRegistration(self)

	EXPECT_NOTIFICATION("OnHMIStatus",
			{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
		:Do(function()
			SendingOnHMIStatusFromMobile(self)
		end)

	EXPECT_NOTIFICATION("OnSystemRequest", {requestType = "QUERY_APPS"})
		:ValidIf(function(_,data)
			if 
				not data.binaryData then
					userPrint(31, "OnSystemRequest notification came without header in data")
					return false
			elseif
				data.binaryData then
				local binaryDataTable = json.decode(data.binaryData)
				local HeaderValuesCheckResult = HeaderValuesCheck(data.binaryData, binaryDataTable)
				return HeaderValuesCheckResult
			end
		end)
	    :Do(function(_,data)
	        local CorIdSystemRequest = self.mobileSession:SendRPC("SystemRequest",
	          {
	            requestType = "QUERY_APPS", 
	            fileName = "correctJSON.json"
	          },
	          "files/jsons/QUERRY_jsons/correctJSON.json")

	          -- mobile side: SystemRequest response
	          self.mobileSession:ExpectResponse(CorIdSystemRequest, { success = true, resultCode = "SUCCESS"})

	          EXPECT_HMICALL("BasicCommunication.UpdateAppList",
	          	{applications = {
				   	{
				      	appName = config.application1.registerAppInterfaceParams.appName,
				      	--[=[TODO: remove after resolving APPLINK-16052
				      	deviceInfo = {
					        id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
					        isSDLAllowed = true,
					        name = "127.0.0.1",
					        transportType = "WIFI"
				      	}]=]
				   	},
				   	{
				      	appName = "Rock music App",
				      	--[=[TODO: remove after resolving APPLINK-16052
				      	deviceInfo = {
					        id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
					        isSDLAllowed = true,
					        name = "127.0.0.1",
					        transportType = "WIFI"
				      	},]=]
				      	greyOut = false
				   },
				   {
				      	appName = "Awesome Music App",
				      	--[=[TODO: remove after resolving APPLINK-16052
				      	deviceInfo = {
				        	id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
				        	isSDLAllowed = true,
				        	name = "127.0.0.1",
				        	transportType = "WIFI"
				      	},]=]
				      	greyOut = false
				   }
				}})
			 	:ValidIf(function(_,data)
                    if #data.params.applications == 3 then
                      	return true
                  	else 
                        userPrint( 31, "Application array in BasicCommunication.UpdateAppList contains "..tostring(#data.params.applications)..", expected 3" )
                        return false
                  	end
              	end)
				:Do(function(_,data)
 					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
					for i=1, #data.params.applications do
						self.applications[data.params.applications[i].appName] = data.params.applications[i].appID
                  	end
              	end)
	    end)

end



--===================================================================================--
-- Test case: APPLINK-17893: 02[N][MAN]_TC_SDL_doesn't_send_OnSystemRequest_if_SDL4.0_disabled
-- Description: Check that SDL does not send OnSystemRequest(QUERY_APPS) to application of v4 protocol after registering and switching it to foreground on mobile if SDL4.0 functionality is disabled in .ini file.
--===================================================================================--

-- It is covered in APPLINK-19305: 01[ATF]_TC_Common_cases (Script: https://adc.luxoft.com/svn/APPLINK/doc/technical/testing/TestCases/lua/tests/SDL_4.0/SDL4_0_Common_cases.lua)


--===================================================================================--
-- APPLINK-17900: 04[P][MAN]_TC_SDL_sends_OnSystemRequest_to_foreground_app
-- Description: Check that SDL sends OnSystemRequest(QUERY_APPS) to application which in foreground on mobile and does not send to second application which in background
--===================================================================================--

-- Precondition: Unregister application, register application with parameters form config.lua
Precondition_UnregisterRegisterApp("OnSystemRequestQueryAppsOnlyToForegroundApp")

function Test:Precondition_RegisterSecondApp()

	AppRegistration(self, self.mobileSession1, config.application2.registerAppInterfaceParams.appName , config.application2.registerAppInterfaceParams.fullAppID, config.application2.registerAppInterfaceParams.isMediaApplication)

	self.mobileSession1:ExpectNotification("OnHMIStatus",
		{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})

		self.mobileSession1:ExpectNotification("OnSystemRequest", { requestType = "LOCK_SCREEN_ICON_URL" })
			:Times(AtMost(1))

		 EXPECT_HMICALL("BasicCommunication.UpdateAppList",
      	{applications = {
		   	{
		      	appName = config.application1.registerAppInterfaceParams.appName,
		      	--[=[TODO: remove after resolving APPLINK-16052
		      	deviceInfo = {
			        id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
			        isSDLAllowed = true,
			        name = "127.0.0.1",
			        transportType = "WIFI"
		      	}]=]
		   	},
		   	{
		      	appName = config.application2.registerAppInterfaceParams.appName,
		      	--[=[TODO: remove after resolving APPLINK-16052
		      	deviceInfo = {
			        id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
			        isSDLAllowed = true,
			        name = "127.0.0.1",
			        transportType = "WIFI"
		      	}]=]
		   	}
		}})

		 DelayedExp(3000)

end

function Test:OnSystemRequestQueryAppsOnlyToForegroundApp()
	userPrint(34, "=================================== Test  Case ===================================")
	SendingOnHMIStatusFromMobile(self)

	SendingOnHMIStatusFromMobile(self, "BACKGROUND", "NOT_AUDIBLE", self.mobileSession1 )

	self.mobileSession1:ExpectNotification("OnSystemRequest", {requestType = "QUERY_APPS"})
		:Times(0)

	self.mobileSession:ExpectNotification("OnSystemRequest", {requestType = "QUERY_APPS"})
		:ValidIf(function(_,data)
			if 
				not data.binaryData then
					userPrint(31, "OnSystemRequest notification came without header in data")
					return false
			elseif
				data.binaryData then

				local binaryDataTable = json.decode(data.binaryData )

				local HeaderValuesCheckResult = HeaderValuesCheck(data.binaryData, binaryDataTable)
				return HeaderValuesCheckResult
			end
		end)
	    :Do(function(_,data)
	        local CorIdSystemRequest = self.mobileSession:SendRPC("SystemRequest",
	          {
	            requestType = "QUERY_APPS", 
	            fileName = "correctJSON.json"
	          },
	          "files/jsons/QUERRY_jsons/correctJSON.json")

	          -- mobile side: SystemRequest response
	          self.mobileSession:ExpectResponse(CorIdSystemRequest, { success = true, resultCode = "SUCCESS"})

	          EXPECT_HMICALL("BasicCommunication.UpdateAppList",
	          	{applications = {
				   	{
				      	appName = config.application1.registerAppInterfaceParams.appName,
				      	--[=[TODO: remove after resolving APPLINK-16052
				      	deviceInfo = {
					        id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
					        isSDLAllowed = true,
					        name = "127.0.0.1",
					        transportType = "WIFI"
				      	}]=]
				   	},
				   	{
				      	appName = config.application2.registerAppInterfaceParams.appName,
				      	--[=[TODO: remove after resolving APPLINK-16052
				      	deviceInfo = {
					        id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
					        isSDLAllowed = true,
					        name = "127.0.0.1",
					        transportType = "WIFI"
				      	}]=]
				   	},
				   	{
				      	appName = "Rock music App",
				      	--[=[TODO: remove after resolving APPLINK-16052
				      	deviceInfo = {
					        id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
					        isSDLAllowed = true,
					        name = "127.0.0.1",
					        transportType = "WIFI"
				      	},]=]
				      	greyOut = false
				   },
				   {
				      	appName = "Awesome Music App",
				      	--[=[TODO: remove after resolving APPLINK-16052
				      	deviceInfo = {
				        	id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
				        	isSDLAllowed = true,
				        	name = "127.0.0.1",
				        	transportType = "WIFI"
				      	},]=]
				      	greyOut = false
				   }
				}})
			 	:ValidIf(function(_,data)
                    if #data.params.applications == 4 then
                      	return true
                  	else 
                        userPrint( 31, "Application array in BasicCommunication.UpdateAppList contains "..tostring(#data.params.applications)..", expected 4" )
                        return false
                  	end
              	end)
				:Do(function(_,data)
 					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
					for i=1, #data.params.applications do
						self.applications[data.params.applications[i].appName] = data.params.applications[i].appID
                  	end
              	end)
	    end)

	DelayedExp(1000)

end

function Test:Postcondition_UnregisterTwoReqisteredApps()

	local CorIdURAI = self.mobileSession:SendRPC("UnregisterAppInterface", {})

	local CorIdURAI2 = self.mobileSession1:SendRPC("UnregisterAppInterface", {})

  	--hmi side: expected  BasicCommunication.OnAppUnregistered
  	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", 
  		{appID = self.applications[config.application1.registerAppInterfaceParams.appName], unexpectedDisconnect = false},
  		{appID = self.applications[config.application2.registerAppInterfaceParams.appName], unexpectedDisconnect = false})
  		:Times(2)

  	self.mobileSession:ExpectResponse(CorIdURAI, {success = true , resultCode = "SUCCESS"})
  	self.mobileSession1:ExpectResponse(CorIdURAI2, {success = true , resultCode = "SUCCESS"})

end


--===================================================================================--
-- Test case: APPLINK-17902: 06[N][MAN]_TC_SDL_doesn't_send_OnSystemRequest_to_new_foreground_app
-- Description: Checks that SDL does not send OnSystemRequest(QUERY_APPS) to the new registered App which in foreground on phone
--===================================================================================--

function Test:Precondition_RegisterFirstApplication_AbsenceOnSystemRequestQueryAppsNewRegisteredAppInForeground()
	AppRegistration(self)

	EXPECT_NOTIFICATION("OnHMIStatus",
		{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
		:DoOnce(function(_,data)
			SendingOnHMIStatusFromMobile(self)
		end)

	EXPECT_NOTIFICATION("OnSystemRequest")
		:Times(Between(1,2))
		:ValidIf(function(_,data)
			if data.payload.requestType == "QUERY_APPS" then
				if 
					not data.binaryData then
						userPrint(31, "OnSystemRequest notification came without header in data")
						return false
				elseif
					data.binaryData then

					local binaryDataTable = json.decode(data.binaryData )

					local HeaderValuesCheckResult = HeaderValuesCheck(data.binaryData, binaryDataTable)
					return HeaderValuesCheckResult
				end
			elseif data.payload.requestType == "LOCK_SCREEN_ICON_URL" then
				return true
			else
				userPrint(31, "OnSystemRequest notification came without unexpected requestType " .. tostring(data.payload.requestType))
				return false
			end
		end)
		:Do(function(_,data)
			if data.payload.requestType == "QUERY_APPS" then
		        local CorIdSystemRequest = self.mobileSession:SendRPC("SystemRequest",
		          {
		            requestType = "QUERY_APPS", 
		            fileName = "correctJSON.json"
		          },
		          "files/jsons/QUERRY_jsons/correctJSON.json")

		          -- mobile side: SystemRequest response
		          self.mobileSession:ExpectResponse(CorIdSystemRequest, { success = true, resultCode = "SUCCESS"})
		    end
	    end)

	EXPECT_HMICALL("BasicCommunication.UpdateAppList",
      	{applications = {
		   	{
		      	appName = config.application1.registerAppInterfaceParams.appName,
		      	--[=[TODO: remove after resolving APPLINK-16052
		      	deviceInfo = {
			        id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
			        isSDLAllowed = true,
			        name = "127.0.0.1",
			        transportType = "WIFI"
		      	}]=]
		   	},
		   	{
		      	appName = "Rock music App",
		      	--[=[TODO: remove after resolving APPLINK-16052
		      	deviceInfo = {
			        id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
			        isSDLAllowed = true,
			        name = "127.0.0.1",
			        transportType = "WIFI"
		      	},]=]
		      	greyOut = false
		   },
		   {
		      	appName = "Awesome Music App",
		      	--[=[TODO: remove after resolving APPLINK-16052
		      	deviceInfo = {
		        	id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
		        	isSDLAllowed = true,
		        	name = "127.0.0.1",
		        	transportType = "WIFI"
		      	},]=]
		      	greyOut = false
		   }
		}})
	 	:ValidIf(function(exp,data)
            if #data.params.applications == 3 then
              	return true
          	else 
                userPrint( 31, "Application array in BasicCommunication.UpdateAppList contains "..tostring(#data.params.applications)..", expected 3" )
                return false
          	end
      	end)
		:Do(function(_,data)
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
			for i=1, #data.params.applications do
				self.applications[data.params.applications[i].appName] = data.params.applications[i].appID
          	end
      	end)
end

function Test:AbsenceOnSystemRequestQueryAppsNewRegisteredAppInForeground()
	userPrint(34, "=================================== Test  Case ===================================")

	SendingOnHMIStatusFromMobile(self, "BACKGROUND", _, _)

	AppRegistration(self, self.mobileSession1, config.application2.registerAppInterfaceParams.appName , config.application2.registerAppInterfaceParams.fullAppID, config.application2.registerAppInterfaceParams.isMediaApplication)

	self.mobileSession1:ExpectNotification("OnHMIStatus",
		{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
		:DoOnce(function(_,data)
			SendingOnHMIStatusFromMobile(self, "FULL", "NOT_AUDIBLE", self.mobileSession1) 
		end)

	self.mobileSession:ExpectNotification("OnHMIStatus", {})
		:Times(0)

	self.mobileSession:ExpectNotification("OnSystemRequest", {})
		:Times(0)

	self.mobileSession1:ExpectNotification("OnSystemRequest", 
		{ requestType = "LOCK_SCREEN_ICON_URL" })
		:Times(AtMost(1))

	DelayedExp(2000)

end

function Test:Postcondition_UnregisterTwoReqisteredApps()

	local CorIdURAI = self.mobileSession:SendRPC("UnregisterAppInterface", {})

	local CorIdURAI2 = self.mobileSession1:SendRPC("UnregisterAppInterface", {})

  	--hmi side: expected  BasicCommunication.OnAppUnregistered
  	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", 
  		{appID = self.applications[config.application1.registerAppInterfaceParams.appName], unexpectedDisconnect = false},
  		{appID = self.applications[config.application2.registerAppInterfaceParams.appName], unexpectedDisconnect = false})
  		:Times(2)

  	self.mobileSession:ExpectResponse(CorIdURAI, {success = true , resultCode = "SUCCESS"})
  	self.mobileSession1:ExpectResponse(CorIdURAI2, {success = true , resultCode = "SUCCESS"})

end


--===================================================================================--
-- Test case: APPLINK-17901: 05[N][MAN]_TC_SDL_doesn't_send_OnSystemRequest_to_background_apps
-- Description: Check that SDL does not send OnSystemRequest(QUERY_APPS) to any from two applications which in background on mobile.
--===================================================================================--

function Test:AbsenceOnSystemRequestQueryAppsToBackgroundApp_FirstApp()
	userPrint(34, "=================================== Test  Case ===================================")
	AppRegistration(self)

	self.mobileSession:ExpectNotification("OnHMIStatus",
		{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
		:Do(function()
			SendingOnHMIStatusFromMobile(self, "BACKGROUND", "NOT_AUDIBLE", self.mobileSession)
		end)

	self.mobileSession:ExpectNotification("OnSystemRequest", { requestType = "LOCK_SCREEN_ICON_URL" })
		:Times(AtMost(1))

	DelayedExp(1000)
end

function Test:AbsenceOnSystemRequestQueryAppsToBackgroundApp_SecondApp()
	userPrint(34, "=================================== Test  Case ===================================")

	AppRegistration(self, self.mobileSession1, config.application2.registerAppInterfaceParams.appName , config.application2.registerAppInterfaceParams.fullAppID, config.application2.registerAppInterfaceParams.isMediaApplication)

	self.mobileSession1:ExpectNotification("OnHMIStatus",
		{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
	:Do(function()
		SendingOnHMIStatusFromMobile(self, "BACKGROUND", "NOT_AUDIBLE", self.mobileSession1)
	end)

	self.mobileSession:ExpectNotification("OnSystemRequest", { requestType = "LOCK_SCREEN_ICON_URL" })
		:Times(AtMost(1))

	self.mobileSession:ExpectNotification("OnSystemRequest", {})
		:Times(0)

	DelayedExp(2000)

end


function Test:Postcondition_UnregisterTwoReqisteredApps()

	local CorIdURAI = self.mobileSession:SendRPC("UnregisterAppInterface", {})

	local CorIdURAI2 = self.mobileSession1:SendRPC("UnregisterAppInterface", {})

  	--hmi side: expected  BasicCommunication.OnAppUnregistered
  	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", 
  		{appID = self.applications[config.application1.registerAppInterfaceParams.appName], unexpectedDisconnect = false},
  		{appID = self.applications[config.application2.registerAppInterfaceParams.appName], unexpectedDisconnect = false})
  		:Times(2)

  	self.mobileSession:ExpectResponse(CorIdURAI, {success = true , resultCode = "SUCCESS"})
  	self.mobileSession1:ExpectResponse(CorIdURAI2, {success = true , resultCode = "SUCCESS"})
  		:Do(function ()
  			self.mobileConnection:Close()
  		end)

end


-- ===================================================================================--
-- Test case: APPLINK-17898: 03[P][MAN]_TC_SDL_sends_OnSystemRequest_to_different_devices 
-- Description: Check that SDL sends OnSystemRequest(QUERY_APPS) to both applications of v4 protocol on different devices after registering and switching them to foreground on mobiles.
-- ===================================================================================--

function Test:Precondition_OpenFirstConnectionCreateSession()
    local tcpConnection = tcp.Connection(config.mobileHost, config.mobilePort)
    local fileConnection = file_connection.FileConnection("mobile.out", tcpConnection)
    self.mobileConnection = mobile.MobileConnection(fileConnection)
    self.mobileSession= mobile_session.MobileSession(
    self,
    self.mobileConnection)
    event_dispatcher:AddConnection(self.mobileConnection)
    self.mobileSession:ExpectEvent(events.connectedEvent, "Connection started")
    self.mobileConnection:Connect()
    self.mobileSession:StartService(7)
  end

  function Test:Precondition_OpenSecondConnectionCreateSession()
    local tcpConnection = tcp.Connection("1.0.0.1", config.mobilePort)
    local fileConnection = file_connection.FileConnection("mobile.out", tcpConnection)
    self.mobileConnection2 = mobile.MobileConnection(fileConnection)
    self.mobileSession2= mobile_session.MobileSession(
    self,
    self.mobileConnection2)
    event_dispatcher:AddConnection(self.mobileConnection2)
    self.mobileSession2:ExpectEvent(events.connectedEvent, "Connection started")
    self.mobileConnection2:Connect()
    self.mobileSession2:StartService(7)
  end


  function Test:OnSystemRequestQueryAppsOnFirstDevice()
  	userPrint(34, "=================================== Test  Case ===================================")

  	AppRegistration(self)

	EXPECT_NOTIFICATION("OnHMIStatus",
		{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
		:Do(function()
			SendingOnHMIStatusFromMobile(self)
		end)

	EXPECT_NOTIFICATION("OnSystemRequest")
		:Times(Between(1,2))
		:ValidIf(function(_,data)
			if data.payload.requestType == "QUERY_APPS" then
				if 
					not data.binaryData then
						userPrint(31, "OnSystemRequest notification came without header in data")
						return false
				elseif
					data.binaryData then

					local binaryDataTable = json.decode(data.binaryData )

					local HeaderValuesCheckResult = HeaderValuesCheck(data.binaryData, binaryDataTable)
					return HeaderValuesCheckResult
				end
			elseif data.payload.requestType == "LOCK_SCREEN_ICON_URL" then
				return true
			else 
				userPrint(31, "OnSystemRequest notification came without unexpected requestType " .. tostring(data.payload.requestType))
				return false
			end
		end)
	    :Do(function(_,data)
	    	if 
	    		data.payload.requestType == "QUERY_APPS" then

		        	local CorIdSystemRequest = self.mobileSession:SendRPC("SystemRequest",
		          	{
			            requestType = "QUERY_APPS", 
			            fileName = "correctJSON.json"
		          	},
		          	"files/jsons/QUERRY_jsons/correctJSON.json")

		          	-- mobile side: SystemRequest response
		          	self.mobileSession:ExpectResponse(CorIdSystemRequest, { success = true, resultCode = "SUCCESS"})

		          	EXPECT_HMICALL("BasicCommunication.UpdateAppList",
		          		{applications = {
						   	{
						      	appName = config.application1.registerAppInterfaceParams.appName,
						      	--[=[TODO: remove after resolving APPLINK-16052
						      	deviceInfo = {
							        id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
							        isSDLAllowed = true,
							        name = "127.0.0.1",
							        transportType = "WIFI"
						      	}]=]
						   	}
						}},
			          	{applications = {
						   	{
						      	appName = config.application1.registerAppInterfaceParams.appName,
						      	--[=[TODO: remove after resolving APPLINK-16052
						      	deviceInfo = {
							        id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
							        isSDLAllowed = true,
							        name = "127.0.0.1",
							        transportType = "WIFI"
						      	}]=]
						   	},
						   	{
						      	appName = "Rock music App",
						      	--[=[TODO: remove after resolving APPLINK-16052
						      	deviceInfo = {
							        id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
							        isSDLAllowed = true,
							        name = "127.0.0.1",
							        transportType = "WIFI"
						      	},]=]
						      	greyOut = false
						   },
						   {
						      	appName = "Awesome Music App",
						      	--[=[TODO: remove after resolving APPLINK-16052
						      	deviceInfo = {
						        	id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
						        	isSDLAllowed = true,
						        	name = "127.0.0.1",
						        	transportType = "WIFI"
						      	},]=]
						      	greyOut = false
						   }
						}})
						:Times(2)
					 	:ValidIf(function(exp,data)
					 		if exp.occurences == 2 then
			                    if #data.params.applications == 3 then
			                      	return true
			                  	else 
			                        userPrint( 31, "Application array in BasicCommunication.UpdateAppList contains "..tostring(#data.params.applications)..", expected 3" )
			                        return false
			                  	end
			                else
			                	return true
			                end
		              	end)
						:Do(function(_,data)
		 					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
		              	end)
	        end
	    end)

	DelayedExp(2000)

  end

  function Test:OnSystemRequestQueryAppsOnSecondDevice()
  	userPrint(34, "=================================== Test  Case ===================================")

  	AppRegistration(self, self.mobileSession2 , config.application2.registerAppInterfaceParams.appName , config.application2.registerAppInterfaceParams.fullAppID)

	self.mobileSession2:ExpectNotification("OnHMIStatus",
		{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
		:Do(function()
			SendingOnHMIStatusFromMobile(self, _, _, self.mobileSession2)
		end)

  	EXPECT_NOTIFICATION("OnSystemRequest", {requestType = "QUERY_APPS"})
  		:Times(0)

	-- self.mobileSession2:ExpectNotification("OnSystemRequest", {requestType = "QUERY_APPS"})
	self.mobileSession2:ExpectNotification("OnSystemRequest")
		:Times(Between(1,2))
		:ValidIf(function(_,data)
			if data.payload.requestType == "QUERY_APPS"then
				if 
					not data.binaryData then
						userPrint(31, "OnSystemRequest notification came without header in data")
						return false
				elseif
					data.binaryData then

					local binaryDataTable = json.decode(data.binaryData )

					local HeaderValuesCheckResult = HeaderValuesCheck(data.binaryData, binaryDataTable)
					return HeaderValuesCheckResult
				end
			elseif data.payload.requestType == "LOCK_SCREEN_ICON_URL" then
				return true
			else 
				userPrint(31, "OnSystemRequest notification came without unexpected requestType " .. tostring(data.payload.requestType))
				return false
			end
		end)
	    :Do(function(_,data)
	    	if 
	    		data.payload.requestType == "QUERY_APPS" then

	    			local CorIdSystemRequest = self.mobileSession2:SendRPC("SystemRequest",
			          {
			            requestType = "QUERY_APPS", 
			            fileName = "correctJSON.json"
			          },
			          "files/jsons/QUERRY_jsons/correctJSON.json")

	          		-- mobile side: SystemRequest response
	          		self.mobileSession2:ExpectResponse(CorIdSystemRequest, { success = true, resultCode = "SUCCESS"})

		          	EXPECT_HMICALL("BasicCommunication.UpdateAppList",
		          	{applications = {
					   	{
					      	appName = config.application1.registerAppInterfaceParams.appName,
					      	--[=[TODO: remove after resolving APPLINK-16052
					      	deviceInfo = {
						        id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
						        isSDLAllowed = true,
						        name = "127.0.0.1",
						        transportType = "WIFI"
					      	}]=]
					   	},
					   	{
					      	appName = config.application2.registerAppInterfaceParams.appName,
					      	--[=[TODO: remove after resolving APPLINK-16052
					      	deviceInfo = {
						        id = "54286cb92365be544aa7008b92854b9648072cf8d8b17b372fd0786bef69d7a2",
						        isSDLAllowed = true,
						        name = "1.0.0.1",
						        transportType = "WIFI"
					      	}]=]
					   	},
					   	{
					      	appName = "Rock music App",
					      	--[=[TODO: remove after resolving APPLINK-16052
					      	deviceInfo = {
						        id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
						        isSDLAllowed = true,
						        name = "127.0.0.1",
						        transportType = "WIFI"
					      	},]=]
					      	greyOut = false
					   },
					   	{
					      	appName = "Rock music App",
					      	--[=[TODO: remove after resolving APPLINK-16052
					      	deviceInfo = {
						        id = "54286cb92365be544aa7008b92854b9648072cf8d8b17b372fd0786bef69d7a2",
						        isSDLAllowed = true,
						        name = "1.0.0.1",
						        transportType = "WIFI"
					      	},]=]
					      	greyOut = false
					   },
					   {
					      	appName = "Awesome Music App",
					      	--[=[TODO: remove after resolving APPLINK-16052
					      	deviceInfo = {
					        	id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
					        	isSDLAllowed = true,
					        	name = "127.0.0.1",
					        	transportType = "WIFI"
					      	},]=]
					      	greyOut = false
					   },
					   {
					      	appName = "Awesome Music App",
					      	--[=[TODO: remove after resolving APPLINK-16052
					      	deviceInfo = {
					        	id = "54286cb92365be544aa7008b92854b9648072cf8d8b17b372fd0786bef69d7a2",
					        	isSDLAllowed = true,
					        	name = "1.0.0.1",
					        	transportType = "WIFI"
					      	},]=]
					      	greyOut = false
					   }

					}})
				 	:ValidIf(function(_,data)
	                    if #data.params.applications == 6 then
	                      	return true
	                  	else 
	                        userPrint( 31, "Application array in BasicCommunication.UpdateAppList contains "..tostring(#data.params.applications)..", expected 6" )
	                        return false
	                  	end
	              	end)
					:Do(function(_,data)
	 					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
	              	end)
	        end

	    end)

	DelayedExp(2000)

  end


-- ===================================================================================--
-- Test case: APPLINK-17903: 07[P][MAN]_TC_SDL_doesn't_send_OnSystemRequest_after_unsuccessful_attempt
-- Description: SDL does NOT send OnSystemRequest(QUERY APPS) after unsuccessful attempt
-- ===================================================================================--

local function TC_APPLINK_17903()

	--Precondition: Unregister application, register application with parameters form config.lua
	Precondition_UnregisterRegisterApp("APPLINK_17903_Precondition_Unregister_And_Register_Again")

	function Test:APPLINK_17903_Step1_OnSystemRequest_QueryApps_IsError()
		userPrint(34, "=================================== Test  Case ===================================")

		SendingOnHMIStatusFromMobile(self)

		EXPECT_NOTIFICATION("OnSystemRequest", {requestType = "QUERY_APPS"})
			:ValidIf(function(_,data)
				if 
					not data.binaryData then
						userPrint(31, "OnSystemRequest notification came without header in data")
						return false
				elseif
					data.binaryData then
					local binaryDataTable = json.decode(data.binaryData)
					local HeaderValuesCheckResult = HeaderValuesCheck(data.binaryData, binaryDataTable)
					return HeaderValuesCheckResult
				end
			end)
			:Do(function(_,data)
				local CorIdSystemRequest = self.mobileSession:SendRPC("SystemRequest",
				  {
					requestType = "QUERY_APPS", 
					fileName = "incorrectJSON.json"
				  },
				  "files/jsons/QUERRY_jsons/incorrectJSON.json"
				  )

				  -- mobile side: SystemRequest response
				  self.mobileSession:ExpectResponse(CorIdSystemRequest, { success = false, resultCode = "GENERIC_ERROR"})

				  EXPECT_HMICALL("BasicCommunication.UpdateAppList",
					{applications = {
						{
							appName = config.application1.registerAppInterfaceParams.appName,
							--[=[TODO: remove after resolving APPLINK-16052
							deviceInfo = {
								id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
								isSDLAllowed = true,
								name = "127.0.0.1",
								transportType = "WIFI"
							}]=]
						}
					}})
					:ValidIf(function(_,data)
						if #data.params.applications == 1 then
							return true
						else 
							userPrint( 31, "Application array in BasicCommunication.UpdateAppList contains "..tostring(#data.params.applications)..", expected 1" )
							return false
						end
					end)
					:Do(function(_,data)
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
						for i=1, #data.params.applications do
							self.applications[data.params.applications[i].appName] = data.params.applications[i].appID
						end
					end)
			end)

	end

	function Test:APPLINK_17903_Step2_RegisterSecondApp()

		AppRegistration(self, self.mobileSession1, config.application2.registerAppInterfaceParams.appName , config.application2.registerAppInterfaceParams.fullAppID, config.application2.registerAppInterfaceParams.isMediaApplication)

		self.mobileSession1:ExpectNotification("OnHMIStatus",
			{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})

		self.mobileSession1:ExpectNotification("OnSystemRequest", { requestType = "LOCK_SCREEN_ICON_URL" })
			:Times(AtMost(1))

		DelayedExp(500)

	end

	function Test:APPLINK_17903_Step2_OnSystemRequest_QueryApps_IsNotSentToNewRegisteredApp()
		userPrint(34, "=================================== Test  Case ===================================")

		SendingOnHMIStatusFromMobile(self, "BACKGROUND", "NOT_AUDIBLE", self.mobileSession )
		
		SendingOnHMIStatusFromMobile(self, "FULL", "NOT_AUDIBLE", self.mobileSession1 )

		self.mobileSession1:ExpectNotification("OnSystemRequest", {requestType = "QUERY_APPS"})
			:Times(0)

		self.mobileSession:ExpectNotification("OnSystemRequest", {requestType = "QUERY_APPS"})
			:Times(0)
			
		DelayedExp(1000)

	end

	function Test:APPLINK_17903_Step3_OnSystemRequest_QueryApps_IsNotSentToTheSameAppInForeground()
		userPrint(34, "=================================== Test  Case ===================================")

		SendingOnHMIStatusFromMobile(self, "BACKGROUND", "NOT_AUDIBLE", self.mobileSession1 )
		
		SendingOnHMIStatusFromMobile(self, "FULL", "NOT_AUDIBLE", self.mobileSession )

		self.mobileSession1:ExpectNotification("OnSystemRequest", {requestType = "QUERY_APPS"})
			:Times(0)

		self.mobileSession:ExpectNotification("OnSystemRequest", {requestType = "QUERY_APPS"})
			:Times(0)
			
		DelayedExp(1000)

	end

	function Test:APPLINK_17903_Postcondition_UnregisterTwoReqisteredApps_AndCloseTheSecondSession()

		local CorIdURAI = self.mobileSession:SendRPC("UnregisterAppInterface", {})

		local CorIdURAI2 = self.mobileSession1:SendRPC("UnregisterAppInterface", {})

		--hmi side: expected  BasicCommunication.OnAppUnregistered
		EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", 
			{appID = self.applications[config.application1.registerAppInterfaceParams.appName], unexpectedDisconnect = false},
			{appID = self.applications[config.application2.registerAppInterfaceParams.appName], unexpectedDisconnect = false})
			:Times(2)

		self.mobileSession:ExpectResponse(CorIdURAI, {success = true , resultCode = "SUCCESS"})
		self.mobileSession1:ExpectResponse(CorIdURAI2, {success = true , resultCode = "SUCCESS"})

	end

end

TC_APPLINK_17903()

function Test:Postcondition_removeCreatedUserConnecttest()
	os.execute(" rm -f  ./user_modules/connecttest_without_ExitBySDLDisconnect_regApp.lua")
end

function Test:Postcondition_DeleteDummyConnectionForSecondDevice()
  os.execute("ifconfig lo:1 down")
end