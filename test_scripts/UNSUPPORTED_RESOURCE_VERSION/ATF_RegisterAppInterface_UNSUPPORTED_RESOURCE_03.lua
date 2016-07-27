--------------------------------------------------------------------------------
-- Preconditions before ATF start
--------------------------------------------------------------------------------
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
--------------------------------------------------------------------------------
--Precondition: preparation connecttest_RAIttsUnavailable.lua
commonPreconditions:Connecttest_without_ExitBySDLDisconnect_WithoutOpenConnectionRegisterApp("connecttest_RAIttsUnavailable.lua")

f = assert(io.open('./user_modules/connecttest_RAIttsUnavailable.lua', "r"))

  fileContent = f:read("*all")
  f:close()

 -- update hmiCapabilities in UI.GetCapabilities
	local pattern1 = 'ExpectRequest%s-%(%s-"%s-TTS.GetLanguage%s-".-%{'
	local ResultPattern2 = fileContent:match(pattern1)

	if ResultPattern2 == nil then 
    	print(" \27[31m ExpectRequest TTS.GetLanguage call is not found in /user_modules/connecttest_RAIttsUnavailable.lua \27[0m ")
  	else
	    fileContent  =  string.gsub(fileContent, pattern1, 'ExpectRequest("TTS.GetLanguage", false, {')
  	end

 -- update hmiCapabilities in TTS.SetGlobalProperties
	local pattern1 = 'ExpectRequest%s-%(%s-"%s-TTS.SetGlobalProperties%s-".-%{'
	local ResultPattern2 = fileContent:match(pattern1)

	if ResultPattern2 == nil then 
    	print(" \27[31m ExpectRequest TTS.SetGlobalProperties call is not found in /user_modules/connecttest_RAIttsUnavailable.lua \27[0m ")
  	else
	    fileContent  =  string.gsub(fileContent, pattern1, 'ExpectRequest("TTS.SetGlobalProperties", false, {')
  	end

-- update hmiCapabilities in TTS.ChangeRegistration
	local pattern1 = 'ExpectRequest%s-%(%s-"%s-TTS.ChangeRegistration%s-".-%{'
	local ResultPattern2 = fileContent:match(pattern1)

	if ResultPattern2 == nil then 
    	print(" \27[31m ExpectRequest TTS.ChangeRegistration call is not found in /user_modules/connecttest_RAIttsUnavailable.lua \27[0m ")
  	else
	    fileContent  =  string.gsub(fileContent, pattern1, 'ExpectRequest("TTS.ChangeRegistration", false, {')
  	end

-- update hmiCapabilities in TTS.GetSupportedLanguages
	local pattern1 = 'ExpectRequest%s-%(%s-"%s-TTS.GetSupportedLanguages%s-".-%{'
	local ResultPattern2 = fileContent:match(pattern1)

	if ResultPattern2 == nil then 
    	print(" \27[31m ExpectRequest TTS.GetSupportedLanguages call is not found in /user_modules/connecttest_RAIttsUnavailable.lua \27[0m ")
  	else
	    fileContent  =  string.gsub(fileContent, pattern1, 'ExpectRequest("TTS.GetSupportedLanguages", false, {')
  	end

-- update hmiCapabilities in TTS.GetCapabilities
	local pattern1 = 'ExpectRequest%s-%(%s-"%s-TTS.GetCapabilities%s-".-%{'
	local ResultPattern2 = fileContent:match(pattern1)

	if ResultPattern2 == nil then 
    	print(" \27[31m ExpectRequest TTS.GetCapabilities call is not found in /user_modules/connecttest_RAIttsUnavailable.lua \27[0m ")
  	else
	    fileContent  =  string.gsub(fileContent, pattern1, 'ExpectRequest("TTS.GetCapabilities", false, {')
  	end

-- update hmiCapabilities in TTS.IsReady
	local pattern1 = 'ExpectRequest%s-%(%s-"%s-TTS.IsReady%s-".-%{.-%}%s-%)'
	local ResultPattern2 = fileContent:match(pattern1)

	if ResultPattern2 == nil then 
    	print(" \27[31m ExpectRequest TTS.IsReady call is not found in /user_modules/connecttest_RAIttsUnavailable.lua \27[0m ")
  	else
	    fileContent  =  string.gsub(fileContent, pattern1, 'EXPECT_HMICALL("TTS.IsReady"):Do(function(_,data) self.hmiConnection:SendError(data.id, data.method, "UNSUPPORTED_RESOURCE", "TTS is not available now") end)')
  	end


f = assert(io.open('./user_modules/connecttest_RAIttsUnavailable.lua', "w"))
f:write(fileContent)
f:close()
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

Test = require('user_modules/connecttest_RAIttsUnavailable')
require('cardinalities')
local events = require('events')
local mobile_session = require('mobile_session')



local hmi_connection = require('hmi_connection')
local websocket      = require('websocket_connection')
local module         = require('testbase')
local mobile  = require('mobile_connection')
local tcp = require('tcp_connection')
local file_connection  = require('file_connection')

	-- Precondition: removing user_modules/connecttest_RAIttsUnavailable.lua
	function Test:Precondition_remove_user_connecttest()
	 	os.execute( "rm -f ./user_modules/connecttest_RAIttsUnavailable.lua" )
	end

	--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-1328

	--Verification criteria: When ttsName is sent and TTS isn't avaliable at the moment on current HMI, UNSUPPORTED_RESOURCE is returned as a result of request. Info parameter provides additional information about the case. General request result success=true in case of no errors from other components.  

	--Begin Test case ResultCodeCheck
	--Description: Check UNSUPPORTED_RESOURCE resultCode in case TTS isn't avaliable at the moment on current HMI

		function module:ConnectMobileStartSession()
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

		function Test:RegisterAppInterface_ttsUnavailableUnsupportedResource() 

			--mobile side: RegisterAppInterface request 
			local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
														{
														  	 
															syncMsgVersion = 
															{ 
																majorVersion = 2,
																minorVersion = 2,
															}, 
															appName ="SyncProxyTester",
															ttsName = 
															{ 
																 
																{ 
																	text ="SyncProxyTester",
																	type ="TEXT",
																}, 
															}, 
															ngnMediaScreenAppName ="SPT",
															vrSynonyms = 
															{ 
																"VRSyncProxyTester",
															}, 
															isMediaApplication = true,
															languageDesired ="EN-US",
															hmiDisplayLanguageDesired ="EN-US",
															appHMIType = 
															{ 
																"DEFAULT",
															}, 
															appID ="123456",
															deviceInfo = 
															{
																hardware = "hardware",
																firmwareRev = "firmwareRev",
																os = "os",
																osVersion = "osVersion",
																carrier = "carrier",
																maxNumberRFCOMMPorts = 5
															}
														
														})
			

		 	--hmi side: expected  BasicCommunication.OnAppRegistered
				EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")

			--mobile side: RegisterAppInterface response 
			EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "UNSUPPORTED_RESOURCE"})
				:Timeout(2000)

		end

	--End Test case ResultCodeCheck