--------------------------------------------------------------------------------
-- Preconditions
--------------------------------------------------------------------------------
local Preconditions = require('user_modules/shared_testcases/commonPreconditions')

--------------------------------------------------------------------------------
-- Set 4 protocol as default for script
config.defaultProtocolVersion = 4


--------------------------------------------------------------------------------
--Precondition: preparation connecttest_without_ExitBySDLDisconnect_WithoutOpenConnectionRegisterApp.lua
Preconditions:Connecttest_without_ExitBySDLDisconnect_WithoutOpenConnectionRegisterApp("connecttest_without_ExitBySDLDisconnect_OpenConnectionRegisterApp.lua")



Test = require('user_modules/connecttest_without_ExitBySDLDisconnect_OpenConnectionRegisterApp')
require('cardinalities')
local mobile_session = require('mobile_session')

local mobile  = require('mobile_connection')
local tcp = require('tcp_connection')
local file_connection  = require('file_connection')
require('user_modules/AppTypes')

config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

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

	self.mobileSession.correlationId = self.mobileSession.correlationId + 1

  	local msg = 
        {
          serviceType      = 7,
          frameInfo        = 0,
          rpcType          = 2,
          rpcFunctionId    = 32768,
          rpcCorrelationId = self.mobileSession.correlationId,
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
local function AppRegistration(self, registerParams, sessionName)

	local audibleStateRegister

	if sessionName == nil then
		sessionName = self.mobileSession
	end

    local CorIdRegister = sessionName:SendRPC("RegisterAppInterface", registerParams)

    EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
    {
      application = 
      {
      appName = registerParams.appName
      }
    })
    :Do(function(_,data)
        self.applications[registerParams.appName] = data.params.application.appID
    end)

    sessionName:ExpectResponse(CorIdRegister, { success = true, resultCode = "SUCCESS" })

end

local function StartSDLInitializationHMI(self, prefix)
	Test["StartSDL_" .. tostring(prefix)] = function(self)
		StartSDL(config.pathToSDL, config.ExitOnCrash)
	end

	Test["InitHMI_" .. tostring(prefix)] = function(self)
		self:initHMI()
	end

	Test["InitHMIonReady_" .. tostring(prefix)] = function(self)
		self:initHMI_onReady()
	end

	Test["ConnectMobile_" .. tostring(prefix)] = function(self)
		self:connectMobile()
	end
end

--Check pathToSDL, in case last symbol is not'/' add '/' 
local function checkSDLPathValue()
	findresult = string.find (config.pathToSDL, '.$')

	if string.sub(config.pathToSDL,findresult) ~= "/" then
		config.pathToSDL = config.pathToSDL..tostring("/")
	end 
end

local function StopSDLChangeEnableProtocol4ValueInIniFile(sefl, EnableProtocol4Value, EnableProtocol4ValueUpdateTo, prefix)
	Test["StopSDL_" .. tostring(prefix)] = function(self)
		StopSDL()
	end

	Test[ tostring(EnableProtocol4Value) .. "EnableProtocol4InIniFile_" .. tostring(prefix)] = function(self)
		checkSDLPathValue()

		local SDLini = config.pathToSDL .. tostring("smartDeviceLink.ini")

		local StringToReplace = "EnableProtocol4 = "..tostring(EnableProtocol4ValueUpdateTo) .. "\n"

		f = assert(io.open(SDLini, "r"))

		if f then
			fileContent = f:read("*all")

				local MatchResult = string.match(fileContent, "EnableProtocol4%s-=%s-[^%a]-%s-\n") or string.match(fileContent, "EnableProtocol4%s-=%s-true%s-\n") or string.match(fileContent, "EnableProtocol4%s-=%s-false%s-\n")

				if MatchResult ~= nil then
					fileContentUpdated  =  string.gsub(fileContent, MatchResult, StringToReplace)
					f = assert(io.open(SDLini, "w"))
					f:write(fileContentUpdated)
				else 
					userPrint(31, "Finding of 'EnableProtocol4 = value' is failed. Expect string finding is true and replacing of value to " .. tostring(EnableProtocol4ValueUpdateTo))
				end
			f:close()
		end
	end
end

local function AddCommandOnCommand(self)
	local cid = self.mobileSession1:SendRPC("AddCommand",
	{
		cmdID = 1,
		menuParams = 	
		{
			position = 1,
			menuName ="Command"
		}
	})
	
	--hmi side: expect UI.AddCommand request 
	EXPECT_HMICALL("UI.AddCommand", 
	{ 
		cmdID = 1,		
		menuParams = 
		{
			position = 1,
			menuName ="Command"
		},
		appID = self.applications["Awesome Music App"]
	})
	:Do(function(_,data)
		--hmi side: sending UI.AddCommand response 
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
	end)	
	
	--mobile side: expect AddCommand response 
	self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
		:Do(function()

			self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Awesome Music App"], systemContext = "MENU" })

			self.hmiConnection:SendNotification("UI.OnCommand",
				{
					cmdID = 1,
					appID = self.applications["Awesome Music App"]
				})

			self.mobileSession1:ExpectNotification("OnCommand",
				{
					cmdID = 1,
					triggerSource = "MENU"
				})
				:Do(function()
					self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Awesome Music App"], systemContext = "MAIN" })
				end)

			self.mobileSession:ExpectNotification("OnCommand", {})
				:Times(0)

			self.mobileSession1:ExpectNotification("OnHashChange", {})
		end)
end

function Test:Postcondition_removeCreatedUserConnecttest()
	os.execute(" rm -f  ./user_modules/connecttest_without_ExitBySDLDisconnect_OpenConnectionRegisterApp.lua")
end

userPrint(33, " Because of ATF defect APPLINK-16052 check of deviceInfo params in BC.UpdateAppList is commented ")

--===================================================================================--
-- Check that mobile app supporting protocol v.1-4 is registered via v.3 and SDL doesn't send OnSystemRequest(QUERY_APPS) in case of disabled SDL4.0 feature
--===================================================================================--
-- Stop SDL,in case EnableProtocol4=true in .ini file change value to false
StopSDLChangeEnableProtocol4ValueInIniFile(self, "Disable", "false", "AbsenceOnSystemRequestQueryAppsFeatureDisabledInIniFile")

--Start SDL, HMI initialization, open connection
StartSDLInitializationHMI(self, "AbsenceOnSystemRequestQueryAppsFeatureDisabledInIniFile")

function Test:AbsenceOnSystemRequestQueryAppsFeatureDesabledInIniFile()
	userPrint(34, "=================================== Test  Case ===================================")

	local RAIparams = config.application1.registerAppInterfaceParams

	RAIparams.syncMsgVersion.majorVersion = 4
	RAIparams.syncMsgVersion.minorVersion = 1

	self.mobileSession= mobile_session.MobileSession(
    self,
    self.mobileConnection)

    self.mobileSession.version = 3

    self.mobileSession:StartService(7)
    :Do(function()

		AppRegistration(self, RAIparams)

		EXPECT_NOTIFICATION("OnHMIStatus",
			{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
			:DoOnce(function()
				SendingOnHMIStatusFromMobile(self)
			end)

			-- Out of scope, added expectation, because can affect script execution
			EXPECT_NOTIFICATION("OnSystemRequest", { requestType = "LOCK_SCREEN_ICON_URL" })
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

		DelayedExp(2000)
	end)
end


--===================================================================================--
-- Test case: APPLINK-17964: 07[N][MAN]_TC_SDL_ignores_OnHMIStatus_from_app_v4_if_SDL4.0_disabled
-- Description: Check that mobile app supporting v.4 is registered via v.4 and SDL ignores OnHMIStatus from mobile in case of disabled SDL4.0 feature

-- AND

-- Test case: APPLINK-17893: 02[N][MAN]_TC_SDL_doesn't_send_OnSystemRequest_if_SDL4.0_disabled
-- Description: Check that SDL does not send OnSystemRequest(QUERY_APPS) to application of v4 protocol after registering and switching it to foreground on mobile if SDL4.0 functionality is disabled in .ini file.
--===================================================================================--

function Test:Precondition_UnregisterAppInterface_IgnoringOnHMIStatusNotificationsViaFourthProtocol()
	UnregisterAppInterface_Success(self)
end


function Test:IgnoringOnHMIStatusNotificationsViaFourthProtocol()

	userPrint(34, "=================================== Test  Case ===================================")

	local RAIparams = config.application1.registerAppInterfaceParams

	RAIparams.syncMsgVersion.majorVersion = 4
	RAIparams.syncMsgVersion.minorVersion = 1

	self.mobileSession= mobile_session.MobileSession(
    self,
    self.mobileConnection)

    self.mobileSession.version = 4
    self.mobileSession:StartService(7)
    :Do(function()

		AppRegistration(self, RAIparams)

		EXPECT_NOTIFICATION("OnHMIStatus",
			{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
			:DoOnce(function()
				SendingOnHMIStatusFromMobile(self, "BACKGROUND")

				local function to_run()
					SendingOnHMIStatusFromMobile(self)
				end

				RUN_AFTER(to_run, 1000)
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
			   	}
			}})
		 	:ValidIf(function(exp,data)
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

			-- Out of scope, added expectation, because can affect script execution
			EXPECT_NOTIFICATION("OnSystemRequest", { requestType = "LOCK_SCREEN_ICON_URL" })
				:Times(AtMost(1))

	end)

	DelayedExp(2000)

end

function Test:Postcondition_UnregisterAppInterface_IgnoringOnHMIStatusNotificationsViaFourthProtocol()
	UnregisterAppInterface_Success(self)
end

-- ===================================================================================--
-- Check that mobile app supporting protocol v.1-4 is registered via v.3 and SDL doesn't send OnSystemRequest(QUERY_APPS) in case of not defined SDL4.0 featue(EnableProtocol4 is omitted in .ini file)
-- ===================================================================================--
-- Stop SDL,in case EnableProtocol4=true in .ini file change value to empty
StopSDLChangeEnableProtocol4ValueInIniFile(self, "Omit", " ", "AbsenceOnSystemRequestQueryAppsThirdProtocolFeatureOmittedInIniFile")

--Start SDL, HMI initialization, open connection
StartSDLInitializationHMI(self, "AbsenceOnSystemRequestQueryAppsThirdProtocolFeatureOmittedInIniFile")

function Test:AbsenceOnSystemRequestQueryAppsThirdProtocolFeatureOmittedInIniFile()

	userPrint(34, "=================================== Test  Case ===================================")

	local RAIparams = config.application1.registerAppInterfaceParams

	RAIparams.syncMsgVersion.majorVersion = 4
	RAIparams.syncMsgVersion.minorVersion = 1

	self.mobileSession= mobile_session.MobileSession(
    self,
    self.mobileConnection)

    self.mobileSession.version = 3
    self.mobileSession:StartService(7)
    :Do(function()

		AppRegistration(self, RAIparams)

		EXPECT_NOTIFICATION("OnHMIStatus",
			{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
			:DoOnce(function()
				SendingOnHMIStatusFromMobile(self)
			end)

		-- Out of scope, added expectation, because can affect script execution
		EXPECT_NOTIFICATION("OnSystemRequest", { requestType = "LOCK_SCREEN_ICON_URL" })
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
			   	}
			}})
		 	:ValidIf(function(exp,data)
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

		DelayedExp(2000)
	end)
end

function Test:Postcondition_UnregisterAppInterface_AbsenceOnSystemRequestQueryAppsThirdProtocolFeatureOmittedInIniFile()
	UnregisterAppInterface_Success(self)
end


--===================================================================================--
-- Check that mobile app supporting protocol v.1-4 is registered via v.4 and SDL doesn't send OnSystemRequest(QUERY_APPS) in case of not defined SDL4.0 featue(EnableProtocol4 is omitted in .ini file)
--===================================================================================--

function Test:AbsenceOnSystemRequestQueryAppsFourthProtocolFeatureOmittedInIniFile()

	userPrint(34, "=================================== Test  Case ===================================")

	local RAIparams = config.application1.registerAppInterfaceParams

	RAIparams.syncMsgVersion.majorVersion = 4
	RAIparams.syncMsgVersion.minorVersion = 1

	self.mobileSession= mobile_session.MobileSession(
    self,
    self.mobileConnection)

    self.mobileSession.version = 4
    self.mobileSession:StartService(7)
    :Do(function()

		AppRegistration(self, RAIparams)

		EXPECT_NOTIFICATION("OnHMIStatus",
			{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
			:DoOnce(function()
				SendingOnHMIStatusFromMobile(self)
			end)

		-- Out of scope, added expectation, because can affect script execution
		EXPECT_NOTIFICATION("OnSystemRequest", { requestType = "LOCK_SCREEN_ICON_URL" })
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
			   	}
			}})
		 	:ValidIf(function(exp,data)
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

	DelayedExp(2000)

end

function Test:Postcondition_UnregisterAppInterface_AbsenceOnSystemRequestQueryAppsFourthProtocolFeatureOmittedInIniFile()
	UnregisterAppInterface_Success(self)
end

--===================================================================================--
-- Check that mobile app supporting protocol v.1-3 is registered via v.3 and SDL doesn't send OnSystemRequest(QUERY_APPS) in case of enabled SDL4.0 featue
--===================================================================================--
-- Stop SDL,in case EnableProtocol4=true in .ini file change value to true
StopSDLChangeEnableProtocol4ValueInIniFile(self, "Enable", "true", "AbsenceOnSystemRequestQueryAppsThirdProtocolFeatureEnabledInIniFile")

--Start SDL, HMI initialization, open connection
StartSDLInitializationHMI(self, "AbsenceOnSystemRequestQueryAppsThirdProtocolFeatureEnabledInIniFile")

function Test:AbsenceOnSystemRequestQueryAppsThirdProtocolFeatureEnabledInIniFile()

	userPrint(34, "=================================== Test  Case ===================================")

	local RAIparams = config.application1.registerAppInterfaceParams

	RAIparams.syncMsgVersion.majorVersion = 3
	RAIparams.syncMsgVersion.minorVersion = 1

	self.mobileSession= mobile_session.MobileSession(
    self,
    self.mobileConnection)

    self.mobileSession.version = 3
    self.mobileSession:StartService(7)
    :Do(function()

		AppRegistration(self, RAIparams)

		EXPECT_NOTIFICATION("OnHMIStatus",
			{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
			:DoOnce(function()
				SendingOnHMIStatusFromMobile(self)
			end)

		-- Out of scope, added expectation, because can affect script execution
		EXPECT_NOTIFICATION("OnSystemRequest", { requestType = "LOCK_SCREEN_ICON_URL" })
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
			   	}
			}})
		 	:ValidIf(function(exp,data)
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

		DelayedExp(2000)
	end)
end

function Test:Postcondition_UnregisterAppInterface_AbsenceOnSystemRequestQueryAppsThirdProtocolFeatureEnabledInIniFile()
	UnregisterAppInterface_Success(self)
end

--===================================================================================--
-- Check that mobile app supporting protocol v.4 is registered via v.4 and SDL sends OnSystemRequest(QUERY_APPS) in case of enabled SDL4.0 featue
--===================================================================================--

function Test:OnSystemRequestQueryAppsFourthProtocolFeatureEnabledInIniFile()

	userPrint(34, "=================================== Test  Case ===================================")

	local RAIparams = config.application1.registerAppInterfaceParams

	RAIparams.syncMsgVersion.majorVersion = 4
	RAIparams.syncMsgVersion.minorVersion = 1

	self.mobileSession= mobile_session.MobileSession(
    self,
    self.mobileConnection)

    self.mobileSession.version = 4

    self.mobileSession.sendHeartbeatToSDL = false
    self.mobileSession.answerHeartbeatFromSDL = true

    self.mobileSession:StartHeartbeat()

    self.mobileSession:StartService(7)
    :Do(function()

		AppRegistration(self, RAIparams)

		EXPECT_NOTIFICATION("OnHMIStatus",
			{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
			:DoOnce(function()
				SendingOnHMIStatusFromMobile(self)
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

		EXPECT_NOTIFICATION("OnSystemRequest")
			:ValidIf(function(_,data)
				if data.payload.requestType == "QUERY_APPS" then

					local CorIdSystemRequest = self.mobileSession:SendRPC("SystemRequest",
		          	{
		            	requestType = "QUERY_APPS", 
		            	fileName = "correctJSON.json"
		          	},
		          	"files/jsons/QUERRY_jsons/correctJSON.json")

		          	-- mobile side: SystemRequest response
		          	self.mobileSession:ExpectResponse(CorIdSystemRequest, { success = true, resultCode = "SUCCESS"})
		          	return true
		        elseif data.payload.requestType == "LOCK_SCREEN_ICON_URL" then
	        		-- ignore notification
	        		return true
		        else
		        	userPrint(31, " OnSystemRequest notificaton came with unexpected requestType ".. tostring(data.payload.requestType))
		        	return false
		        end
	    	end)
	    	:Times(Between(1,2))

	end)

	DelayedExp(2000)
end

--===================================================================================--
-- Checks that application registers and activates properly if user start on device application which present on HMI.
--===================================================================================--

function Test:ProperlyRegistrationActivationAppPresentHMI()

	userPrint(34, "=================================== Test  Case ===================================")

	local RAIparams = 
	{
	    syncMsgVersion =
		    {
		      majorVersion = 4,
		      minorVersion = 0
		    },
	    appName = "Awesome Music App",
	    isMediaApplication = true,
	    languageDesired = 'EN-US',
	    hmiDisplayLanguageDesired = 'EN-US',
	    appHMIType = { "DEFAULT" },
	    appID = "853426",
	    deviceInfo =
	    {
	      os = "Android",
	      carrier = "Megafon",
	      firmwareRev = "Name: Linux, Version: 3.4.0-perf",
	      osVersion = "4.4.2",
	      maxNumberRFCOMMPorts = 1
	    }
  	}

	self.mobileSession1= mobile_session.MobileSession(
    self,
    self.mobileConnection)

    self.mobileSession1.version = 3

    self.mobileSession1.sendHeartbeatToSDL = false
    self.mobileSession1.answerHeartbeatFromSDL = true

    self.mobileSession1:StartHeartbeat()

    self.mobileSession1:StartService(7)
    :Do(function()

		AppRegistration(self, RAIparams, self.mobileSession1)

		-- Out of scope, added expectation, because can affect script execution
		self.mobileSession1:ExpectNotification("OnSystemRequest", { requestType = "LOCK_SCREEN_ICON_URL" })
			:Times(AtMost(1))

		self.mobileSession:ExpectNotification("OnSystemRequest")
			:Times(0)

		self.mobileSession1:ExpectNotification("OnHMIStatus",
			{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"},
			{ systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "AUDIBLE"},
			{ systemContext = "MENU", hmiLevel = "FULL", audioStreamingState = "AUDIBLE"},
			{ systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "AUDIBLE"})
			:Times(4)
			:Do(function(exp,data)
				if 
					exp.occurences == 1 then
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
							      	appName = "Awesome Music App",
							      	--[=[TODO: remove after resolving APPLINK-16052
			 				      	deviceInfo = {
							        	id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
							        	isSDLAllowed = true,
							        	name = "127.0.0.1",
							        	transportType = "WIFI"
							      	},]=]
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
							:DoOnce(function(_,data)
			 					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
								for i=1, #data.params.applications do
									self.applications[data.params.applications[i].appName] = data.params.applications[i].appID
			                  	end

			                  	-- hmi side: sending SDL.ActivateApp request
								local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["Awesome Music App"]})

								-- hmi side: expect SDL.ActivateApp response
								EXPECT_HMIRESPONSE(RequestId)

			              	end)
			    elseif
			    	exp.occurences == 2 then

			    	AddCommandOnCommand(self)
						
			    end
			end)

		DelayedExp(2000)
	end)

end

function Test:Postcondition_UnregisterFirstApp_ProperlyRegistrationAppPresentHMI()
	UnregisterAppInterface_Success(self)

	EXPECT_HMICALL("BasicCommunication.UpdateAppList")
end

function Test:Postcondition_UnregisterSecondApp_ProperlyRegistrationAppPresentHMI()
	UnregisterAppInterface_Success(self, self.mobileSession1, self.applications["Awesome Music App"] )

	EXPECT_HMICALL("BasicCommunication.UpdateAppList")
end

--===================================================================================--
-- Checks that application activates properly when user activate application on HMI if this app was registered before receiving list of app thru SystemRequest(QUERY_APPS).
--===================================================================================--

function Test:ProperlyRegistrationBeforeOnSystemRequestQueryApps()

	userPrint(34, "=================================== Test  Case ===================================")

	local RAIparams = 
	{
	    syncMsgVersion =
		    {
		      majorVersion = 4,
		      minorVersion = 0
		    },
	    appName = "Awesome Music App",
	    isMediaApplication = true,
	    languageDesired = 'EN-US',
	    hmiDisplayLanguageDesired = 'EN-US',
	    appHMIType = { "DEFAULT" },
	    appID = "853426",
	    deviceInfo =
	    {
	      os = "Android",
	      carrier = "Megafon",
	      firmwareRev = "Name: Linux, Version: 3.4.0-perf",
	      osVersion = "4.4.2",
	      maxNumberRFCOMMPorts = 1
	    }
  	}

	self.mobileSession1= mobile_session.MobileSession(
    self,
    self.mobileConnection)

    self.mobileSession1.version = 3

    self.mobileSession1:StartService(7)
    :Do(function()

		AppRegistration(self, RAIparams, self.mobileSession1)

		-- Out of scope, added expectation, because can affect script execution
		self.mobileSession1:ExpectNotification("OnSystemRequest", { requestType = "LOCK_SCREEN_ICON_URL" })
			:Times(AtMost(1))

		self.mobileSession1:ExpectNotification("OnHMIStatus",
			{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
			:DoOnce(function(_,data)

			 	EXPECT_HMICALL("BasicCommunication.UpdateAppList",
		          	{applications = {
					   	{
					      	appName = "Awesome Music App",
					      	--[=[TODO: remove after resolving APPLINK-16052
	 				      	deviceInfo = {
					        	id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
					        	isSDLAllowed = true,
					        	name = "127.0.0.1",
					        	transportType = "WIFI"
					      	},]=]
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
			end)

		DelayedExp(2000)
	end)

end

function Test:RegisterAppViaFourthProtocolProperlyActivationAppViaThirdProtocol()

	userPrint(34, "=================================== Test  Case ===================================")

	local RAIparams = config.application1.registerAppInterfaceParams

	RAIparams.syncMsgVersion.majorVersion = 4
	RAIparams.syncMsgVersion.minorVersion = 1

	self.mobileSession= mobile_session.MobileSession(
    self,
    self.mobileConnection)

    self.mobileSession.sendHeartbeatToSDL = false

    self.mobileSession.version = 4
    self.mobileSession:StartService(7)
    :Do(function()

		AppRegistration(self, RAIparams)

		EXPECT_NOTIFICATION("OnHMIStatus",
			{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
			:DoOnce(function()
				SendingOnHMIStatusFromMobile(self)
			end)

		self.mobileSession1:ExpectNotification("OnSystemRequest")
			:Times(0)

		EXPECT_NOTIFICATION("OnSystemRequest")
			:ValidIf(function(_,data)
				if data.payload.requestType == "QUERY_APPS" then
					local CorIdSystemRequest = self.mobileSession:SendRPC("SystemRequest",
		          	{
		            	requestType = "QUERY_APPS", 
		            	fileName = "correctJSON.json"
		          	},
		          	"files/jsons/QUERRY_jsons/correctJSON.json")

		          	-- mobile side: SystemRequest response
		          	self.mobileSession:ExpectResponse(CorIdSystemRequest, { success = true, resultCode = "SUCCESS"})
		          	return true
		        elseif data.payload.requestType == "LOCK_SCREEN_ICON_URL" then
	        		-- ignore notification
	        		return true
		        else
		        	userPrint(31, " OnSystemRequest notificaton came with unexpected requestType ".. tostring(data.payload.requestType))
		        	return false
		        end
	    	end)
	    	:Times(Between(1,2))

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
			      	appName = "Awesome Music App",
			      	--[=[TODO: remove after resolving APPLINK-16052
			      	deviceInfo = {
			        	id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
			        	isSDLAllowed = true,
			        	name = "127.0.0.1",
			        	transportType = "WIFI"
			      	},]=]
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
			:Do(function(exp,data)
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
				for i=1, #data.params.applications do
					self.applications[data.params.applications[i].appName] = data.params.applications[i].appID
              	end

              	if
              		exp.occurences == 2 then
	                  	-- hmi side: sending SDL.ActivateApp request
						local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["Awesome Music App"]})

						-- hmi side: expect SDL.ActivateApp response
						EXPECT_HMIRESPONSE(RequestId)

						self.mobileSession1:ExpectNotification("OnHMIStatus",
							{ systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "AUDIBLE"},
							{ systemContext = "MENU", hmiLevel = "FULL", audioStreamingState = "AUDIBLE"},
							{ systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "AUDIBLE"})
							:Times(3)
							:DoOnce(function()
								AddCommandOnCommand(self)
							end)
				end
          	end)
	end)

	DelayedExp(2000)
end

