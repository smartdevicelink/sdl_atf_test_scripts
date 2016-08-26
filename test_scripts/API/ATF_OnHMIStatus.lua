-- Preconditions before ATF start
--------------------------------------------------------------------------------
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
commonPreconditions:Connecttest_without_ExitBySDLDisconnect("connecttest_OnHMIStatus.lua")

  f = assert(io.open('./user_modules/connecttest_OnHMIStatus.lua', "r"))

  fileContent = f:read("*all")
  f:close()

  -- update initHMI_onReady
  local pattern1 = "function .?module%.?:.?initHMI%_onReady%(.?%)"
  local ResultPattern1 = fileContent:match(pattern1)

  if ResultPattern1 == nil then 
    print(" \27[31m initHMI_onReady function is not found in /user_modules/connecttest_OnHMIStatus.lua \27[0m ")
  else
    fileContent  =  string.gsub(fileContent, pattern1, "function module:initHMI_onReady(MixingAudioValue)")
  end

  -- update attenuatedSupported value
  local pattern2 = "%{%s-attenuatedSupported%s-=.-%}"
  local ResultPattern2 = fileContent:match(pattern2)

  if ResultPattern2 == nil then 
    print(" \27[31m attenuatedSupported is not found in /user_modules/connecttest_OnHMIStatus.lua \27[0m ")
  else
    fileContent  =  string.gsub(fileContent, pattern2, "{ attenuatedSupported = MixingAudioValue }")
  end 

f = assert(io.open('./user_modules/connecttest_OnHMIStatus.lua', "w"))
f:write(fileContent)
f:close()

Test = require('user_modules/connecttest_OnHMIStatus')
require('cardinalities')

require('user_modules/AppTypes')
local mobile_session = require('mobile_session')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')

local MediaApp = false
local NaviComApp = false
local audioState

----------------------------------------------------------------------------
--Set audio state according to app type 
if 
	Test.isMediaApplication == true then
		MediaApp = true
		audioState = "AUDIBLE"
elseif
	Test.appHMITypes["COMMUNICATION"] == true or
	Test.appHMITypes["NAVIGATION"] == true then
		NaviComApp = true
		audioState = "AUDIBLE"
else
	audioState = "NOT_AUDIBLE"
end
----------------------------------------------------------------------------

----------------------------------------------------------------------------
--Set deactivated notification for app according to app type
local expectedNotification

if MediaApp or NaviComApp then
	expectedNotification = {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"}
else
	expectedNotification = {hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"}
end
----------------------------------------------------------------------------


----------------------------------------------------------------------------
-- User functions
function DelayedExp(time)
  local event = events.Event()
  event.matches = function(self, e) return self == e end
  EXPECT_EVENT(event, "Delayed event")
  	:Timeout(time+1000)
  RUN_AFTER(function()
              RAISE_EVENT(event, event)
            end, time)
end

local function userPrint( color, message)
  print ("\27[" .. tostring(color) .. "m " .. tostring(message) .. " \27[0m")
end

-- Unregistration of one app
local function UnregisterApplication_Success(self, session, appId)
	--mobile side: UnregisterAppInterface request 
	local CorIdUAI = session:SendRPC("UnregisterAppInterface",{}) 

	--hmi side: expect OnAppUnregistered notification 
	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = appId, unexpectedDisconnect = false})
 

	--mobile side: UnregisterAppInterface response 
	session:ExpectResponse(CorIdUAI, { success = true, resultCode = "SUCCESS"})
		:Do(function()
			session:Stop()
		end)
end

-- Unregistration of two apps
local function UnregisterTwoApplication_Success(self, prefix)

	Test["Postcondition_UnregisterFirstApp_" .. tostring(prefix) ] = function(self)
		UnregisterApplication_Success(self,self.mobileSession)
	end

	Test["Postcondition_UnregisterSecondApp_" .. tostring(prefix) ] = function(self)
		UnregisterApplication_Success(self, self.mobileSession1)
	end

end

-- Activation of application
function ActivationApp(self, appId)

	--hmi side: sending SDL.ActivateApp request
  	local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = appId})

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
						        :Times(2)
		              	end)
		    else 
		    	-- hmi side: expect of absence BasicCommunication.ActivateApp
		    	EXPECT_HMICALL("BasicCommunication.ActivateApp")
		    	:Times(0)
			end
	      end)

	DelayedExp(500)

end

-- Registration of application
function RegisterAppInterface_Success(self, session, RAIParameters, RAIParamsToCheck) 

	--mobile side: RegisterAppInterface request 
	local CorIdRAI = session:SendRPC("RegisterAppInterface", RAIParameters)
	

 	--hmi side: expected  BasicCommunication.OnAppRegistered
	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", RAIParamsToCheck)
		:Do(function(_,data)
			self.applications[data.params.application.appName] = data.params.application.appID
		end)

	--mobile side: RegisterAppInterface response 
	session:ExpectResponse(CorIdRAI, { success = true, resultCode = "SUCCESS"})

end

-- Sending UI.OnSystemContext from HMI
local function SendOnSystemContext(self, ctx, appIDValue)
	if not appIDValue then
		self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications[config.application2.registerAppInterfaceParams.appName], systemContext = ctx })
	elseif
		appIDValue == "empty" then
		self.hmiConnection:SendNotification("UI.OnSystemContext",{ systemContext = ctx })
	else
		self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = appIDValue, systemContext = ctx })
	end
end

-- Update policy
function UpdatePolicy(self, PTName)
			
	--hmi side: sending SDL.GetURLS request
	local RequestIdGetURLS = self.hmiConnection:SendRequest("SDL.GetURLS", { service = 7 })

	--hmi side: expect SDL.GetURLS response from HMI
	EXPECT_HMIRESPONSE(RequestIdGetURLS,{result = {code = 0, method = "SDL.GetURLS", urls = {{url = "http://policies.telematics.ford.com/api/policies"}}}})
	:Do(function(_,data)
		--print("SDL.GetURLS response is received")
		--hmi side: sending BasicCommunication.OnSystemRequest request to SDL
		self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest",
			{
				requestType = "PROPRIETARY",
				fileName = "filename",
				appID = self.applications[config.application2.registerAppInterfaceParams.appName]
			}
		)
		--mobile side: expect OnSystemRequest notification 
		EXPECT_NOTIFICATION("OnSystemRequest", { requestType = "PROPRIETARY" })
		:Do(function(_,data)
			--print("OnSystemRequest notification is received")
			--mobile side: sending SystemRequest request 
			local CorIdSystemRequest = self.mobileSession:SendRPC("SystemRequest",
				{
					fileName = "PolicyTableUpdate",
					requestType = "PROPRIETARY"
				},
			PTName)
			
			local systemRequestId
			--hmi side: expect SystemRequest request
			EXPECT_HMICALL("BasicCommunication.SystemRequest")
			:Do(function(_,data)
				systemRequestId = data.id
				--print("BasicCommunication.SystemRequest is received")
				
				--hmi side: sending BasicCommunication.OnSystemRequest request to SDL
				self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate",
					{
						policyfile = "/tmp/fs/mp/images/ivsu_cache/PolicyTableUpdate"
					}
				)
				function to_run()
					--hmi side: sending SystemRequest response
					self.hmiConnection:SendResponse(systemRequestId,"BasicCommunication.SystemRequest", "SUCCESS", {})
				end
				
				RUN_AFTER(to_run, 500)
			end)
			
			--hmi side: expect SDL.OnStatusUpdate
			EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate")
				:ValidIf(function(exp,data)
					if 
						exp.occurences == 1 and
						data.params.status == "UP_TO_DATE" then
							return true
					elseif
						exp.occurences == 1 and
						data.params.status == "UPDATING" then
							return true
					elseif
						exp.occurences == 2 and
						data.params.status == "UP_TO_DATE" then
							return true
					else 
						if 
							exp.occurences == 1 then
								print ("\27[31m SDL.OnStatusUpdate came with wrong values. Expected in first occurrences status 'UP_TO_DATE' or 'UPDATING', got '" .. tostring(data.params.status) .. "' \27[0m")
						elseif exp.occurences == 2 then
								print ("\27[31m SDL.OnStatusUpdate came with wrong values. Expected in second occurrences status 'UP_TO_DATE', got '" .. tostring(data.params.status) .. "' \27[0m")
						end
						return false
					end
				end)
				:Times(Between(1,2))
			
			--mobile side: expect SystemRequest response
			EXPECT_RESPONSE(CorIdSystemRequest, { success = true, resultCode = "SUCCESS"})
			:Do(function(_,data)
				--print("SystemRequest is received")
				--hmi side: sending SDL.GetUserFriendlyMessage request to SDL
				local RequestIdGetUserFriendlyMessage = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"StatusUpToDate"}})
				
				--hmi side: expect SDL.GetUserFriendlyMessage response
				EXPECT_HMIRESPONSE(RequestIdGetUserFriendlyMessage,{result = {code = 0, method = "SDL.GetUserFriendlyMessage", messages = {{line1 = "Up-To-Date", messageCode = "StatusUpToDate", textBody = "Up-To-Date"}}}})
			end)
			
		end)
	end)		
		
			
end

--Check pathToSDL, in case last symbol is not'/' add '/' 
local function checkSDLPathValue()
	findresult = string.find (config.pathToSDL, '.$')

	if string.sub(config.pathToSDL,findresult) ~= "/" then
		config.pathToSDL = config.pathToSDL..tostring("/")
	end 
end

-- Check direcrory existence 
local function Directory_exist(DirectoryPath)
	local returnValue

	local Command = assert( io.popen(  "[ -d " .. tostring(DirectoryPath) .. " ] && echo \"Exist\" || echo \"NotExist\"" , 'r'))
	local CommandResult = tostring(Command:read( '*l' ))

	if 
		CommandResult == "NotExist" then
			returnValue = false
	elseif 
		CommandResult == "Exist" then
		returnValue =  true
	else 
		userPrint(31," Some unexpected result in Directory_exist function, CommandResult = " .. tostring(CommandResult))
		returnValue = false
	end

	return returnValue
end

-- Stop SDL, delete storage folder, start SDL and HMI
function DeletingDatabase_RestartSDL(prefix, MixingAudioValue)
	checkSDLPathValue()

	SDLStoragePath = config.pathToSDL .. "storage/"

	local SDLini = config.pathToSDL .. tostring("smartDeviceLink.ini")

	Test["StopSDL_" .. tostring(prefix)] = function(self)
		StopSDL()
	end

	Test["Precondition_DeletingDatabase_" .. tostring(prefix)] = function(self)
		local ExistResult = Directory_exist( tostring(config.pathToSDL .. "storage"))
		if ExistResult == true then
			local RmDB  = assert( os.execute( "rm -rf " .. tostring(config.pathToSDL .. "storage" )))
			if RmDB ~= true then
				userPrint(31,"Storage folder is not deleted")
			end
		end
		DelayedExp(1000)
	end


	Test["StartSDL_" .. tostring(prefix)] = function(self)
		StartSDL(config.pathToSDL, config.ExitOnCrash)
		DelayedExp(1000)
	end

	Test["InitHMI_" .. tostring(prefix)] = function(self)
		self:initHMI()
	end

	Test["InitHMIonReady_" .. tostring(prefix)] = function(self)
		self:initHMI_onReady(MixingAudioValue)
	end

	Test["ConnectMobile_" .. tostring(prefix)] = function(self)
		self:connectMobile()
	end
end

----------------------------------------------------------------------------

-- Precondition: removing user_modules/connecttest_OnHMIStatus.lua
function Test:Precondition_remove_user_connecttest()
  os.execute( "rm -f ./user_modules/connecttest_OnHMIStatus.lua" )
end

function Test:Precondition_UnregisterRegisteredApp()
	UnregisterApplication_Success(self, self.mobileSession, self.applications[config.application2.registerAppInterfaceParams.appName])
end

-- Remove storage folder, restart SDL
DeletingDatabase_RestartSDL("GeneralPreconditiion", true)

-- 29[P][MAN]_TC_HMILevel_FULL_activating_app_by_user_via_VR_synonym
--===================================================================================--
-- HMI level to FULL by dint of activating app by user via VR synonym (from VR menu) and the receiving onHMIStatus notification in mobile application
--===================================================================================--

function Test:ActivationApp_viaVR()
	userPrint(34, "=================================== Test  Case ===================================")

	local RAIParams = config.application1.registerAppInterfaceParams
	RAIParams.vrSynonyms = {"ApplicationVrSynonym"}

	self.mobileSession = mobile_session.MobileSession(
	self,
	self.mobileConnection)

	self.mobileSession:StartService(7)
		:Do(function(_,data)

			RegisterAppInterface_Success(self, self.mobileSession, RAIParams, {application = {appName = RAIParams.appName}, vrSynonyms = {"ApplicationVrSynonym"}})

			EXPECT_NOTIFICATION("OnHMIStatus",
				{hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"},
				{hmiLevel = "FULL", audioStreamingState = audioState, systemContext = "MAIN"})
				:Do(function(exp,data)
					if exp.occurences == 1 then

						-- Openning VR menu
						self.hmiConnection:SendNotification("VR.Started",{})

						SendOnSystemContext(self, "VRSESSION")

						function to_run()
							--activate app
		  					ActivationApp(self, self.applications[RAIParams.appName])

		  					--Closing VR menu
		  					self.hmiConnection:SendNotification("VR.Stopped",{})

							SendOnSystemContext(self, "MAIN")
						end

						RUN_AFTER(to_run, 1000)
					end
				end)
				:Times(2)
	end)

	DelayedExp(1000)

end

function Test:Postcondition_UnregisteApp_ActivatedViaVR()
	UnregisterApplication_Success(self, self.mobileSession, self.applications[config.application1.registerAppInterfaceParams.appName])
end

--[==[ uncomment after resolving APPLINK-18854
-- 29[P][MAN]_TC_HMILevel_FULL_activating_app_by_user_via_VR_synonym
--===================================================================================--
-- SDL sets level from FULL/LIMITED to BACKGROUND when receives BC.OnEventChanged (isActive: true, eventName: PHONE_CALL) and the receiving onHMIStatus notification in mobile application
-- SDL restores HMI level to FULL/LIMITED from BACKGROUND when SDL receives BC.OnEventChanged (isActive: false, eventName: PHONE_CALL) and the receiving onHMIStatus notification in mobile application
--===================================================================================--

function Test:DeactivationAppDuringPhoneCall_RestoreLevelAfterPhoneCall()
	userPrint(34, "=================================== Test  Case ===================================")

	local RAIParams = config.application1.registerAppInterfaceParams

	local NaviApp = false

	for i=1,#RAIParams.appHMIType do
		if RAIParams.appHMIType[i] == "NAVIGATION" then
			NaviApp = true
		end
	end

	self.mobileSession = mobile_session.MobileSession(
	self,
	self.mobileConnection)

	self.mobileSession:StartService(7)
		:Do(function(_,data)

			RegisterAppInterface_Success(self, self.mobileSession, RAIParams)

			if NaviApp then
				EXPECT_NOTIFICATION("OnHMIStatus",
					{hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"},
					{hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"},
					{hmiLevel = "LIMITED", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"},
					{hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
					:Do(function(exp,data)
						if exp.occurences == 1 then
							--activate app
		  					ActivationApp(self, self.applications[RAIParams.appName])
		  				elseif
		  					exp.occurences == 2 then
		  					-- phone call is active
		  					self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",
		  						{
		  							eventName = "PHONE_CALL",
		  							isActive = true
		  						})
					self.hmiConnection:SendNotification("BasicCommunication.OnPhoneCall", {isActive = true})
		  				elseif
		  					exp.occurences == 3 then
		  					-- phone call is not active
		  					self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",
		  						{
		  							eventName = "PHONE_CALL",
		  							isActive = false
		  						})
				self.hmiConnection:SendNotification("BasicCommunication.OnPhoneCall", {isActive = false})
						end
					end)
					:Times(4)
			else
				EXPECT_NOTIFICATION("OnHMIStatus",
					{hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"},
					{hmiLevel = "FULL", audioStreamingState = audioState, systemContext = "MAIN"},
					{hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"},
					{hmiLevel = "FULL", audioStreamingState = audioState, systemContext = "MAIN"})
					:Do(function(exp,data)
						if exp.occurences == 1 then
							--activate app
		  					ActivationApp(self, self.applications[RAIParams.appName])
		  				elseif
		  					exp.occurences == 2 then
		  					-- phone call is active
		  					self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",
		  						{
		  							eventName = "PHONE_CALL",
		  							isActive = true
		  						})
		  				elseif
		  					exp.occurences == 3 then
		  					-- phone call is not active
		  					self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",
		  						{
		  							eventName = "PHONE_CALL",
		  							isActive = false
		  						})
						end
					end)
					:Times(4)
			end
	end)

	DelayedExp(1000)

end

function Test:Postcondition_UnregisteApp_DeactivationAppDuringPhoneCall_ResporeLevelAfterPhoneCall()
	UnregisterApplication_Success(self, self.mobileSession, self.applications[config.application1.registerAppInterfaceParams.appName])
end

-- 35[P][MAN]_TC_Change_HMIlevel_ when_SDL_receives_BC.OnPhoneCall
-- 34[P][MAN]_TC_Change_HMIlevel_from_FULL/LIMITED_to_BACKGROUND
--===================================================================================--
-- Changing HMI level of navifation app FULL, AUDIBLE->LIMITED, NOT_AUDIBLE, of communication app LIMITED, AUDIBLE->BACKGROUND, NOT_AUDIBLE , media app BACKGROUND-> without changes and the receiving onHMIStatus notification in mobile application when SDL receives BC.OnEventChanged (isActive: true, eventName: PHONE_CALL) and BC.OnEventChanged (isActive: false, eventName: PHONE_CALL) 
--===================================================================================--

function Test:Precondition_RegisterMediaApplication_ChangingLevelDuringPhoneCall()
	userPrint(34, "=================================== Test  Case ===================================")
	self.mobileSession = mobile_session.MobileSession(
		self,
		self.mobileConnection)

	self.mobileSession:StartService(7)
		:Do(function(_,data)
			local RAIParams = config.application2.registerAppInterfaceParams
			RAIParams.isMediaApplication = true
			RAIParams.appHMIType = {"MEDIA"}

			--mobile side: RegisterAppInterface request 
			local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface", RAIParams)

			--hmi side: expected  BasicCommunication.OnAppRegistered
			EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
				:Do(function(_,data)
					self.applications[data.params.application.appName] = data.params.application.appID
				end)

			--mobile side: RegisterAppInterface response 
			self.mobileSession:ExpectResponse(CorIdRAI, { success = true, resultCode = "SUCCESS"})

			self.mobileSession:ExpectNotification("OnHMIStatus", 
				{hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"}) 
		end)
end

function Test:Precondition_RegisterNavigationApplication_ChangingLevelDuringPhoneCall()

	self.mobileSession1 = mobile_session.MobileSession(
		self,
		self.mobileConnection)

	self.mobileSession1:StartService(7)
		:Do(function(_,data)
			local RAIParams = config.application3.registerAppInterfaceParams
			RAIParams.isMediaApplication = false
			RAIParams.appHMIType = {"NAVIGATION"}

			--mobile side: RegisterAppInterface request 
			local CorIdRAI = self.mobileSession1:SendRPC("RegisterAppInterface", RAIParams)

			--hmi side: expected  BasicCommunication.OnAppRegistered
			EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
				:Do(function(_,data)
					self.applications[data.params.application.appName] = data.params.application.appID
				end)

			--mobile side: RegisterAppInterface response 
			self.mobileSession1:ExpectResponse(CorIdRAI, { success = true, resultCode = "SUCCESS"})

			self.mobileSession1:ExpectNotification("OnHMIStatus", 
				{hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
		end)

end

function Test:Precondition_RegisterCommunicationApplication_ChangingLevelDuringPhoneCall()

	self.mobileSession2 = mobile_session.MobileSession(
		self,
		self.mobileConnection)

	self.mobileSession2:StartService(7)
		:Do(function(_,data)
			local RAIParams = config.application4.registerAppInterfaceParams
			RAIParams.isMediaApplication = false
			RAIParams.appHMIType = {"COMMUNICATION"}

			--mobile side: RegisterAppInterface request 
			local CorIdRAI = self.mobileSession2:SendRPC("RegisterAppInterface", RAIParams)

			--hmi side: expected  BasicCommunication.OnAppRegistered
			EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
				:Do(function(_,data)
					self.applications[data.params.application.appName] = data.params.application.appID
				end)

			--mobile side: RegisterAppInterface response 
			self.mobileSession2:ExpectResponse(CorIdRAI, { success = true, resultCode = "SUCCESS"})

			self.mobileSession2:ExpectNotification("OnHMIStatus", 
				{hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
		end)
end

function Test:DeactivationAppFromFULLToLIMITED_LIMITEDToBACKGROUND_App_BACKGROUND_StaysWithoutChanges_DuringPhoneCall_RestoreLevelAfterPhoneCall()

	-- Activate media app
	ActivationApp(self, self.applications[config.application2.registerAppInterfaceParams.appName])

	--mobile side: expect OnHMIStatus notification on media app
	self.mobileSession:ExpectNotification("OnHMIStatus", 
		{hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"},
		{hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"}, 
		{hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"}) 
		:Do(function(exp,data)
			if exp.occurences == 1 or
			exp.occurences == 3 then
				-- Activate navigation app
				ActivationApp(self, self.applications[config.application3.registerAppInterfaceParams.appName])
			end
		end)
		:Times(3)

	--mobile side: expect OnHMIStatus notification on navigation app
	self.mobileSession1:ExpectNotification("OnHMIStatus", 
		{hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"},
		{hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"},
		{hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"},
		{hmiLevel = "LIMITED", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"},
		{hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"}) 
		:Do(function(exp,data)
			if exp.occurences == 1 then
				-- Activate communication app
				ActivationApp(self, self.applications[config.application4.registerAppInterfaceParams.appName])
			elseif
				exp.occurences == 3 then
				-- phone call is active
				self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",
					{
						eventName = "PHONE_CALL",
						isActive = true
					})
			elseif
				exp.occurences == 4 then
				-- phone call is not active
				self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",
					{
						eventName = "PHONE_CALL",
						isActive = false
					})
			end
		end)
		:Times(5)

	--mobile side: expect OnHMIStatus notification on communication app
	self.mobileSession2:ExpectNotification("OnHMIStatus", 
		{hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"},
		{hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"},
		{hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"},
		{hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"}) 
		:Do(function(exp,data)
			print (" third session " .. tostring(data.payload.hmiLevel, data.payload.audioStreamingState, data.payload.systemContext ) )
			if exp.occurences == 1 then
					-- audio sorce is not active
  					self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",
  						{
  							eventName = "AUDIO_SOURCE",
  							isActive = true
  						})
			end
		end)
		:Times(4)
end

function Test:Postcondition_UnregisterMediaApp_ChangingLevelDuringPhoneCall()
	UnregisterApplication_Success(self, self.mobileSession, self.applications[config.application2.registerAppInterfaceParams.appName])
end

function Test:Postcondition_UnregisterNavigationApp_ChangingLevelDuringPhoneCall()
	UnregisterApplication_Success(self, self.mobileSession1, self.applications[config.application3.registerAppInterfaceParams.appName])
end

function Test:Postcondition_UnregisterCommunicationApp_ChangingLevelDuringPhoneCall()
	UnregisterApplication_Success(self, self.mobileSession2, self.applications[config.application4.registerAppInterfaceParams.appName])
end

-- 34[P][MAN]_TC_Change_HMIlevel_from_FULL/LIMITED_to_BACKGROUND
--===================================================================================--
-- Changing HMI level of navifation app LIMITED, AUDIBLE->LIMITED, NOT_AUDIBLE, of media app FULL, AUDIBLE->BACKGROUND, NOT_AUDIBLE , non-media app BACKGROUND-> without changes and the receiving onHMIStatus notification in mobile application when SDL receives BC.OnEventChanged (isActive: true, eventName: PHONE_CALL) and BC.OnEventChanged (isActive: false, eventName: PHONE_CALL) 
--===================================================================================--

function Test:Precondition_RegisterMediaApplication_ChangingLevelDuringPhoneCall_2()
	userPrint(34, "=================================== Test  Case ===================================")
	self.mobileSession = mobile_session.MobileSession(
		self,
		self.mobileConnection)

	self.mobileSession:StartService(7)
		:Do(function(_,data)
			local RAIParams = config.application2.registerAppInterfaceParams
			RAIParams.isMediaApplication = true
			RAIParams.appHMIType = {"MEDIA"}

			--mobile side: RegisterAppInterface request 
			local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface", RAIParams)

			--hmi side: expected  BasicCommunication.OnAppRegistered
			EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
				:Do(function(_,data)
					self.applications[data.params.application.appName] = data.params.application.appID
				end)

			--mobile side: RegisterAppInterface response 
			self.mobileSession:ExpectResponse(CorIdRAI, { success = true, resultCode = "SUCCESS"})

			self.mobileSession:ExpectNotification("OnHMIStatus", 
				{hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"}) 
		end)
end

function Test:Precondition_RegisterNavigationApplication_ChangingLevelDuringPhoneCall_2()

	self.mobileSession1 = mobile_session.MobileSession(
		self,
		self.mobileConnection)

	self.mobileSession1:StartService(7)
		:Do(function(_,data)
			local RAIParams = config.application3.registerAppInterfaceParams
			RAIParams.isMediaApplication = false
			RAIParams.appHMIType = {"NAVIGATION"}

			--mobile side: RegisterAppInterface request 
			local CorIdRAI = self.mobileSession1:SendRPC("RegisterAppInterface", RAIParams)

			--hmi side: expected  BasicCommunication.OnAppRegistered
			EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
				:Do(function(_,data)
					self.applications[data.params.application.appName] = data.params.application.appID
				end)

			--mobile side: RegisterAppInterface response 
			self.mobileSession1:ExpectResponse(CorIdRAI, { success = true, resultCode = "SUCCESS"})

			self.mobileSession1:ExpectNotification("OnHMIStatus", 
				{hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
		end)

end

function Test:Precondition_RegisterNonMediaApplication_ChangingLevelDuringPhoneCall()

	self.mobileSession2 = mobile_session.MobileSession(
		self,
		self.mobileConnection)

	self.mobileSession2:StartService(7)
		:Do(function(_,data)
			local RAIParams = config.application4.registerAppInterfaceParams
			RAIParams.isMediaApplication = false
			RAIParams.appHMIType = {"DEFAULT"}

			--mobile side: RegisterAppInterface request 
			local CorIdRAI = self.mobileSession2:SendRPC("RegisterAppInterface", RAIParams)

			--hmi side: expected  BasicCommunication.OnAppRegistered
			EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
				:Do(function(_,data)
					self.applications[data.params.application.appName] = data.params.application.appID
				end)

			--mobile side: RegisterAppInterface response 
			self.mobileSession2:ExpectResponse(CorIdRAI, { success = true, resultCode = "SUCCESS"})

			self.mobileSession2:ExpectNotification("OnHMIStatus", 
				{hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
		end)
end

function Test:DeactivationAppFromFULLToBACKGROUND_LIMITEDToNOT_AUDIBLE_App_BACKGROUND_StaysWithoutChanges_DuringPhoneCall_RestoreLevelAfterPhoneCall()

	-- Activate non-media app
	ActivationApp(self, self.applications[config.application4.registerAppInterfaceParams.appName])

	--mobile side: expect OnHMIStatus notification on non-media app
	self.mobileSession2:ExpectNotification("OnHMIStatus", 
		{hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"},
		{hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"}) 
		:Do(function(exp,data)
			if exp.occurences == 1 then
				-- Activate navigation app
				ActivationApp(self, self.applications[config.application3.registerAppInterfaceParams.appName])
			end
		end)
		:Times(2)

	--mobile side: expect OnHMIStatus notification on navigation app
	self.mobileSession1:ExpectNotification("OnHMIStatus", 
		{hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"},
		{hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"},
		{hmiLevel = "LIMITED", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"},
		{hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"}) 
		:Do(function(exp,data)
			if exp.occurences == 1 then
				-- Activate media app
				ActivationApp(self, self.applications[config.application2.registerAppInterfaceParams.appName])
			end
		end)
		:Times(4)

	--mobile side: expect OnHMIStatus notification on non-media app
	self.mobileSession:ExpectNotification("OnHMIStatus", 
		{hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"},
		{hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"},
		{hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"}) 
		:Do(function(exp,data)
			if exp.occurences == 1 then
				-- phone call is active
				self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",
					{
						eventName = "PHONE_CALL",
						isActive = true
					})
			elseif
				exp.occurences == 2 then
				-- phone call is not active
				self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",
					{
						eventName = "PHONE_CALL",
						isActive = false
					})
			end
		end)
		:Times(3)
end

function Test:Postcondition_UnregisterMediaApp_ChangingLevelDuringPhoneCall_2()
	UnregisterApplication_Success(self, self.mobileSession, self.applications[config.application2.registerAppInterfaceParams.appName])
end

function Test:Postcondition_UnregisterNavigationApp_ChangingLevelDuringPhoneCall_2()
	UnregisterApplication_Success(self, self.mobileSession1, self.applications[config.application3.registerAppInterfaceParams.appName])
end

function Test:Postcondition_UnregisterNonMediaApp_ChangingLevelDuringPhoneCall()
	UnregisterApplication_Success(self, self.mobileSession2, self.applications[config.application4.registerAppInterfaceParams.appName])
end
]==]

-- 30[P][MAN]_TC_Change_HMIlevel_from_FULL_to_LIMITED
--===================================================================================--
-- Changing HMI level from FULL to LIMITED (BACKGROUND for non-media app) when user switches to any non-media SDL app and the receiving onHMIStatus notification in mobile application.
--===================================================================================--

function Test:Precondition_RegisterActivateApp_ChangingHMILevel_ByAcvivationNonMedia()
	userPrint(34, "=================================== Test  Case ===================================")
	local RAIParams = config.application1.registerAppInterfaceParams

	self.mobileSession = mobile_session.MobileSession(
	self,
	self.mobileConnection)

	self.mobileSession:StartService(7)
		:Do(function(_,data)

			RegisterAppInterface_Success(self, self.mobileSession, RAIParams)

			function to_run()
				ActivationApp(self, self.applications[config.application1.registerAppInterfaceParams.appName])
			end

			RUN_AFTER(to_run, 500)

			EXPECT_NOTIFICATION("OnHMIStatus",
						{hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"},
						{hmiLevel = "FULL", audioStreamingState = audioState , systemContext = "MAIN"})
				:Times(2)
		end)

	DelayedExp(1000)

end 

function Test:ChangingHMILevel_ByAcvivationNonMedia()
	self.mobileSession1 = mobile_session.MobileSession(
	self,
	self.mobileConnection)

	local RAIParams = config.application2.registerAppInterfaceParams
	RAIParams.isMediaApplication = false
	RAIParams.appHMIType = {"DEFAULT"}
	
	self.mobileSession1:StartService(7)
		:Do(function(_,data)
			RegisterAppInterface_Success(self, self.mobileSession1, RAIParams)

			self.mobileSession1:ExpectNotification("OnHMIStatus",
				{hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"},
				{hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
				:Times(2)
				:Do(function(exp,data)
					if exp.occurences == 1 then 
						-- Openning VR menu
						self.hmiConnection:SendNotification("VR.Started",{})

						SendOnSystemContext(self, "VRSESSION")
					end
				end)

			if MediaApp or NaviComApp then

				EXPECT_NOTIFICATION("OnHMIStatus",
				{hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"},
				{hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "VRSESSION"},
				{hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "VRSESSION"},
				{hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"},
				expectedNotification)
				:Do(function(exp,data)
					if exp.occurences == 2 then

						--Closing VR menu
  						self.hmiConnection:SendNotification("VR.Stopped",{})

						SendOnSystemContext(self, "MAIN")

						--activate app
  						ActivationApp(self, self.applications[RAIParams.appName])

					end
				end)
				:Times(5)
			else

				EXPECT_NOTIFICATION("OnHMIStatus",
				{hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "VRSESSION"},
				{hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"},
				expectedNotification)
				:Do(function(exp,data)
					if exp.occurences == 1 then

						--Closing VR menu
  						self.hmiConnection:SendNotification("VR.Stopped",{})

						SendOnSystemContext(self, "MAIN")

						--activate app
  						ActivationApp(self, self.applications[RAIParams.appName])

					end
				end)
				:Times(3)
			end

			DelayedExp(1000)

		end)
end

UnregisterTwoApplication_Success(self, "ChangingHMILevel_ByAcvivationNonMedia")

--33[P][MAN]_TC_Change_HMIlevel_from_FULL_to_BACKGROUND
--===================================================================================--
-- Changing HMI level from FULL to BACKGROUND when user activates other SDL media app and the receiving onHMIStatus notification in mobile application.
--===================================================================================--

function Test:Precondition_RegisterActivateApp_ChangingHMILevel_ByAcvivationMedia()
	userPrint(34, "=================================== Test  Case ===================================")
	local RAIParams = config.application1.registerAppInterfaceParams

	self.mobileSession = mobile_session.MobileSession(
	self,
	self.mobileConnection)

	self.mobileSession:StartService(7)
		:Do(function(_,data)

			RegisterAppInterface_Success(self, self.mobileSession, RAIParams)

			function to_run()
				ActivationApp(self, self.applications[config.application1.registerAppInterfaceParams.appName])
			end

			RUN_AFTER(to_run, 500)

			EXPECT_NOTIFICATION("OnHMIStatus",
						{hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"},
						{hmiLevel = "FULL", audioStreamingState = audioState , systemContext = "MAIN"})
				:Times(2)

		end)

	DelayedExp(1000)

end 

function Test:ChangingHMILevel_ByAcvivationMedia()
	self.mobileSession1 = mobile_session.MobileSession(
	self,
	self.mobileConnection)

	local RAIParams = config.application2.registerAppInterfaceParams
	RAIParams.isMediaApplication = true
	RAIParams.appHMIType = {"DEFAULT"}
	
	self.mobileSession1:StartService(7)
		:Do(function(_,data)
			RegisterAppInterface_Success(self, self.mobileSession1, RAIParams)

			self.mobileSession1:ExpectNotification("OnHMIStatus",
				{hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"},
				{hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
				:Times(2)
				:Do(function(exp,data)
					if exp.occurences == 1 then 
						-- Openning VR menu
						self.hmiConnection:SendNotification("VR.Started",{})

						SendOnSystemContext(self, "VRSESSION")
					end
				end)

			if MediaApp then
				EXPECT_NOTIFICATION("OnHMIStatus",
					{hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"},
					{hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "VRSESSION"},
					{hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
					:Do(function(exp,data)
						if exp.occurences == 2 then
							--activate app
	  						ActivationApp(self, self.applications[RAIParams.appName])

							--Closing VR menu
	  						self.hmiConnection:SendNotification("VR.Stopped",{})

							SendOnSystemContext(self, "MAIN")

						end
					end)
					:Times(3)
			elseif NaviComApp then
				EXPECT_NOTIFICATION("OnHMIStatus",
					{hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"},
					{hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "VRSESSION"},
					{hmiLevel = "LIMITED", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"},
					{hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
					:Do(function(exp,data)
						if exp.occurences == 2 then
							--activate app
	  						ActivationApp(self, self.applications[RAIParams.appName])

							--Closing VR menu
	  						self.hmiConnection:SendNotification("VR.Stopped",{})

							SendOnSystemContext(self, "MAIN")

						end
					end)
					:Times(3)
			else
				EXPECT_NOTIFICATION("OnHMIStatus",
					{hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "VRSESSION"},
					{hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})					
					:Do(function(exp,data)
						if exp.occurences == 1 then
							--activate app
	  						ActivationApp(self, self.applications[RAIParams.appName])

							--Closing VR menu
	  						self.hmiConnection:SendNotification("VR.Stopped",{})

							SendOnSystemContext(self, "MAIN")
						end
					end)
					:Times(2)
			end

			DelayedExp(1000)
		end)
end

UnregisterTwoApplication_Success(self, "ChangingHMILevel_ByAcvivationMedia")

--31[P][MAN]_TC_Change_HMIlevel_from_LIMITED_to_BACKGROUND
--===================================================================================--
-- Returning the app from HMI Level LIMITED (BACKGROUND for non-media app) to FULL when 
-- selects an app in applicaton menu or via VR command and the receiving onHMIStatus notification in mobile application.
--===================================================================================--

if MediaApp or NaviComApp then

	function Test:Precondition_RegisterActivateApp_DeactivationAppFromLimitedToBackground_ByAcvivationMedia()
		userPrint(34, "=================================== Test  Case ===================================")
		local RAIParams = config.application1.registerAppInterfaceParams

		self.mobileSession = mobile_session.MobileSession(
		self,
		self.mobileConnection)

		self.mobileSession:StartService(7)
			:Do(function(_,data)

				RegisterAppInterface_Success(self, self.mobileSession, RAIParams)

				function to_run()
					ActivationApp(self, self.applications[config.application1.registerAppInterfaceParams.appName])
				end

				RUN_AFTER(to_run, 500)

				EXPECT_NOTIFICATION("OnHMIStatus",
							{hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"},
							{hmiLevel = "FULL", audioStreamingState = "AUDIBLE" , systemContext = "MAIN"},
							{hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE" , systemContext = "MAIN"})
					:Times(3)
					:Do(function(exp,data)
						if exp.occurences == 2 then
							self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated",
								{
									appID = self.applications[RAIParams.appName],
								})
						end
					end)
			end)

		DelayedExp(1000)

	end 

	function Test:DeactivationAppFromLimitedToBackground_ByAcvivationMedia()
		self.mobileSession1 = mobile_session.MobileSession(
		self,
		self.mobileConnection)

		local RAIParams = config.application2.registerAppInterfaceParams
		RAIParams.isMediaApplication = true
		RAIParams.appHMIType = {"DEFAULT"}
		
		self.mobileSession1:StartService(7)
			:Do(function(_,data)
				RegisterAppInterface_Success(self, self.mobileSession1, RAIParams)

				self.mobileSession1:ExpectNotification("OnHMIStatus",
					{hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"},
					{hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
					:Times(2)
					:Do(function(exp,data)
						if exp.occurences == 1 then 
							-- Openning VR menu
							self.hmiConnection:SendNotification("VR.Started",{})

							SendOnSystemContext(self, "VRSESSION")
						end
					end)

				if MediaApp then 
					EXPECT_NOTIFICATION("OnHMIStatus",
						{hmiLevel = "LIMITED", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"},
						{hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
						:Do(function(exp,data)
							if exp.occurences == 1 then
								--activate app
	  							ActivationApp(self, self.applications[RAIParams.appName])

								--Closing VR menu
		  						self.hmiConnection:SendNotification("VR.Stopped",{})

								SendOnSystemContext(self, "MAIN")

								self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated",
								{
									appID = self.applications[config.application1.registerAppInterfaceParams.appName]								
								})
							end
						end)
						:Times(2)
				else
					EXPECT_NOTIFICATION("OnHMIStatus",
						{hmiLevel = "LIMITED", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"},
						{hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
						:Do(function(exp,data)
							if exp.occurences == 1 then
								--activate app
	  							ActivationApp(self, self.applications[RAIParams.appName])

								--Closing VR menu
		  						self.hmiConnection:SendNotification("VR.Stopped",{})

								SendOnSystemContext(self, "MAIN")

								self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated",
								{
									appID = self.applications[config.application1.registerAppInterfaceParams.appName]
								})
							end
						end)
						:Times(2)
				end

			end)

		DelayedExp(1000)
	end

	UnregisterTwoApplication_Success(self, "DeactivationAppFromLimitedToBackground_ByAcvivationMedia")

end

-- 32[P][MAN]_TC_Change_HMIlevel_from_LIMITED/BACKGROUND_to_FULL
-- 36[P][MAN]_TC_LIMITED_HMI_level_to_media_application
--===================================================================================--
-- Returning the app from HMI Level LIMITED (BACKGROUND for non-media app) to FULL when 
-- selects an app in applicaton menu or via VR command and the receiving onHMIStatus notification in mobile application.
--===================================================================================--



function Test:Precondition_RegisterActivateDeactivateApp()
	userPrint(34, "=================================== Test  Case ===================================")

	local RAIParams = config.application1.registerAppInterfaceParams

	self.mobileSession = mobile_session.MobileSession(
		self,
		self.mobileConnection)

	self.mobileSession:StartService(7)
	:Do(function()
		RegisterAppInterface_Success(self, self.mobileSession, RAIParams)

		EXPECT_NOTIFICATION("OnHMIStatus",
					{hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"},
					{hmiLevel = "FULL", audioStreamingState = audioState , systemContext = "MAIN"},
					expectedNotification)
			:Times(3)
			:Do(function(exp,data)
				if
					exp.occurences == 1 then 
					ActivationApp(self, self.applications[config.application1.registerAppInterfaceParams.appName])
				elseif
				 	exp.occurences == 2 then
					self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated",
						{
							appID = self.applications[RAIParams.appName]						
						})
				end
			end)
	end)
end 

function Test:ActivateDeactivatedAppToFULL()
	ActivationApp(self, self.applications[config.application1.registerAppInterfaceParams.appName])

	EXPECT_NOTIFICATION("OnHMIStatus",
				{hmiLevel = "FULL", audioStreamingState = audioState, systemContext = "MAIN"})
end

function Test:Precondition_DeactivateActivatedApp()
	self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated",
		{
			appID = self.applications[config.application1.registerAppInterfaceParams.appName]
		})

	EXPECT_NOTIFICATION("OnHMIStatus", expectedNotification )

end

function Test:ActivateDeactivatedAppToFULL_ByVR()

	-- Openning VR menu
	self.hmiConnection:SendNotification("VR.Started",{})

	SendOnSystemContext(self, "VRSESSION")

	ActivationApp(self, self.applications[config.application1.registerAppInterfaceParams.appName])

	--Closing VR menu
	self.hmiConnection:SendNotification("VR.Stopped",{})

	SendOnSystemContext(self, "MAIN")

	if MediaApp or NaviComApp then

		EXPECT_NOTIFICATION("OnHMIStatus",
			{hmiLevel = "LIMITED", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"},
			{hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
			:Times(2)
	else
		EXPECT_NOTIFICATION("OnHMIStatus",
			{hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
	end


end

function Test:Postcondition_UnregisterRegisteredApp()
	UnregisterApplication_Success(self, self.mobileSession, self.applications[config.application1.registerAppInterfaceParams.appName])
end

-- 37[P][MAN]_TC_LIMITED_and_MEDIA_media/NAVIGATION_non-media/COMMUNICATION_non-media
--===================================================================================--
--  SDL support the apps of the following AppHMIType to be in LIMITED at one and the same time: MEDIA media, NAVIGATION non-media, COMMUNICATION non-media
--===================================================================================--

function Test:Precondition_RegisterMediaApplication()
	userPrint(34, "=================================== Test  Case ===================================")
	self.mobileSession = mobile_session.MobileSession(
		self,
		self.mobileConnection)

	self.mobileSession:StartService(7)
		:Do(function(_,data)
			local RAIParams = config.application2.registerAppInterfaceParams
			RAIParams.isMediaApplication = true
			RAIParams.appHMIType = {"MEDIA"}

			--mobile side: RegisterAppInterface request 
			local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface", RAIParams)

			--hmi side: expected  BasicCommunication.OnAppRegistered
			EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
				:Do(function(_,data)
					self.applications[data.params.application.appName] = data.params.application.appID
				end)

			--mobile side: RegisterAppInterface response 
			self.mobileSession:ExpectResponse(CorIdRAI, { success = true, resultCode = "SUCCESS"})

			self.mobileSession:ExpectNotification("OnHMIStatus", 
				{hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"}) 
		end)
end

function Test:Precondition_RegisterNavigationApplication()

	self.mobileSession1 = mobile_session.MobileSession(
		self,
		self.mobileConnection)

	self.mobileSession1:StartService(7)
		:Do(function(_,data)
			local RAIParams = config.application3.registerAppInterfaceParams
			RAIParams.isMediaApplication = false
			RAIParams.appHMIType = {"NAVIGATION"}

			--mobile side: RegisterAppInterface request 
			local CorIdRAI = self.mobileSession1:SendRPC("RegisterAppInterface", RAIParams)

			--hmi side: expected  BasicCommunication.OnAppRegistered
			EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
				:Do(function(_,data)
					self.applications[data.params.application.appName] = data.params.application.appID
				end)

			--mobile side: RegisterAppInterface response 
			self.mobileSession1:ExpectResponse(CorIdRAI, { success = true, resultCode = "SUCCESS"})

			self.mobileSession1:ExpectNotification("OnHMIStatus", 
				{hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
		end)

end

function Test:Precondition_RegisterCommunicationApplication()

	self.mobileSession2 = mobile_session.MobileSession(
		self,
		self.mobileConnection)

	self.mobileSession2:StartService(7)
		:Do(function(_,data)
			local RAIParams = config.application4.registerAppInterfaceParams
			RAIParams.isMediaApplication = false
			RAIParams.appHMIType = {"COMMUNICATION"}

			--mobile side: RegisterAppInterface request 
			local CorIdRAI = self.mobileSession2:SendRPC("RegisterAppInterface", RAIParams)

			--hmi side: expected  BasicCommunication.OnAppRegistered
			EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
				:Do(function(_,data)
					self.applications[data.params.application.appName] = data.params.application.appID
				end)

			--mobile side: RegisterAppInterface response 
			self.mobileSession2:ExpectResponse(CorIdRAI, { success = true, resultCode = "SUCCESS"})

			self.mobileSession2:ExpectNotification("OnHMIStatus", 
				{hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
		end)
end

function Test:SDLallows_MediaFULL_NavigationLIMITED_CommunicationLIMITED()

	-- Activate media app
	ActivationApp(self, self.applications[config.application2.registerAppInterfaceParams.appName])

	--mobile side: expect OnHMIStatus notification on media app
	self.mobileSession:ExpectNotification("OnHMIStatus", 
		{hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"},
		{hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"}, 
		{hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"}) 
		:Do(function(exp,data)
			if exp.occurences == 1 then
				-- Activate navigation app
				ActivationApp(self, self.applications[config.application3.registerAppInterfaceParams.appName])
			end
		end)
		:Times(3)

	--mobile side: expect OnHMIStatus notification on navigation app
	self.mobileSession1:ExpectNotification("OnHMIStatus", 
		{hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"},
		{hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"}) 
		:Do(function(exp,data)
			if exp.occurences == 1 then
				-- Activate communication app
				ActivationApp(self, self.applications[config.application4.registerAppInterfaceParams.appName])
			end
		end)
		:Times(2)

	--mobile side: expect OnHMIStatus notification on communication app
	self.mobileSession2:ExpectNotification("OnHMIStatus", 
		{hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"},
		{hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"}) 
		:Do(function(exp,data)
			if exp.occurences == 1 then
				-- audio sorce is not active
  					self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",
  						{
  							eventName = "AUDIO_SOURCE",
  							isActive = true
  						})
			end
		end)
		:Times(2)
end

function Test:Postcondition_UnregisterMediaApp()
	UnregisterApplication_Success(self, self.mobileSession, self.applications[config.application2.registerAppInterfaceParams.appName])
end

function Test:Postcondition_UnregisterNavigationApp()
	UnregisterApplication_Success(self, self.mobileSession1, self.applications[config.application3.registerAppInterfaceParams.appName])
end

function Test:Postcondition_UnregisterCommunicationApp()
	UnregisterApplication_Success(self, self.mobileSession2, self.applications[config.application4.registerAppInterfaceParams.appName])
end

-- 38[P][MAN]_TC_Only_one_level_FULL_or_LIMITED_is_allowed
--===================================================================================--
-- SDL allow only one level: either FULL or LIMITED at the given moment of time for two apps of one and the same AppHMIType (MEDIA, media).
--===================================================================================--

function Test:Precondition_RegisterActivateMEDIAApp()
	userPrint(34, "=================================== Test  Case ===================================")
	local RAIParams = config.application2.registerAppInterfaceParams
	RAIParams.isMediaApplication = true
	RAIParams.appHMIType = {"MEDIA"}

	self.mobileSession = mobile_session.MobileSession(
	self,
	self.mobileConnection)

	self.mobileSession:StartService(7)
		:Do(function(_,data)

			RegisterAppInterface_Success(self, self.mobileSession, RAIParams)

			EXPECT_NOTIFICATION("OnHMIStatus",
						{hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"},
						{hmiLevel = "FULL", audioStreamingState = "AUDIBLE" , systemContext = "MAIN"})
				:Times(2)
				:Do(function(exp,data)
					if exp.occurences == 1 then
						ActivationApp(self, self.applications[config.application2.registerAppInterfaceParams.appName])
					end
				end)
		end)

end 

function Test:SDLSets_MEDIAApp_ToBACKGROUND_ByAcvivationAnotherMEDIA()
	self.mobileSession1 = mobile_session.MobileSession(
	self,
	self.mobileConnection)

	local RAIParams = config.application3.registerAppInterfaceParams
	RAIParams.isMediaApplication = true
	RAIParams.appHMIType = {"MEDIA"}
	
	self.mobileSession1:StartService(7)
		:Do(function(_,data)
			RegisterAppInterface_Success(self, self.mobileSession1, RAIParams)

			self.mobileSession1:ExpectNotification("OnHMIStatus",
				{hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"},
				{hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
				:Times(2)
				:Do(function(exp,data)
					if exp.occurences == 1 then 
						--activate registered not activated app
  						ActivationApp(self, self.applications[RAIParams.appName])

					end
				end)


				EXPECT_NOTIFICATION("OnHMIStatus",
				{hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

			DelayedExp(1000)

		end)
end

UnregisterTwoApplication_Success(self, "SDLSetsMEDIAAppToBACKGROUND_ByAcvivationAnotherMEDIA")

-- 39[P][MAN]_TC_Only_one_level_FULL_or_BACKGROUND_is_allowed
--===================================================================================--
-- SDL allow only one level: either FULL or BACKGROUND at the given moment of time for two apps of one and the same AppHMIType (NAVIGATION non-media)
--===================================================================================--

function Test:Precondition_RegisterActivateNAVIGATIONApp()
	userPrint(34, "=================================== Test  Case ===================================")
	local RAIParams = config.application2.registerAppInterfaceParams
	RAIParams.isMediaApplication = false
	RAIParams.appHMIType = {"NAVIGATION"}

	self.mobileSession = mobile_session.MobileSession(
	self,
	self.mobileConnection)

	self.mobileSession:StartService(7)
		:Do(function(_,data)

			RegisterAppInterface_Success(self, self.mobileSession, RAIParams)

			EXPECT_NOTIFICATION("OnHMIStatus",
						{hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"},
						{hmiLevel = "FULL", audioStreamingState = "AUDIBLE" , systemContext = "MAIN"})
				:Times(2)
				:Do(function(exp,data)
					if exp.occurences == 1 then
						ActivationApp(self, self.applications[config.application2.registerAppInterfaceParams.appName])
					end
				end)
		end)

end 

function Test:SDLSets_NAVIGATIONApp_ToBACKGROUND_ByAcvivationAnotherNAVIGATION()

	self.mobileSession1 = mobile_session.MobileSession(
	self,
	self.mobileConnection)

	local RAIParams = config.application3.registerAppInterfaceParams
	RAIParams.isMediaApplication = false
	RAIParams.appHMIType = {"NAVIGATION"}
	
	self.mobileSession1:StartService(7)
		:Do(function(_,data)
			RegisterAppInterface_Success(self, self.mobileSession1, RAIParams)

			self.mobileSession1:ExpectNotification("OnHMIStatus",
				{hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"},
				{hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
				:Times(2)
				:Do(function(exp,data)
					if exp.occurences == 1 then 
						--activate registered not activated app
  						ActivationApp(self, self.applications[RAIParams.appName])

					end
				end)


				EXPECT_NOTIFICATION("OnHMIStatus",
				{hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

			DelayedExp(1000)

		end)
end

UnregisterTwoApplication_Success(self, "DeactivationNAVIGATIONApp_ByAcvivationAnotherNAVIGATION")


-- 41[P][MAN]_TC_Only_one_level_FULL_or_LIMITED_for_COMMUNICATION_app
--===================================================================================--
-- SDL allow only one level: either FULL or LIMITED at the given moment of time for two apps of one and the same AppHMIType (COMMUNICATION, non-media).
--===================================================================================--

function Test:Precondition_RegisterActivateCOMMUNICATIONApp()
	userPrint(34, "=================================== Test  Case ===================================")
	local RAIParams = config.application2.registerAppInterfaceParams
	RAIParams.isMediaApplication = false
	RAIParams.appHMIType = {"COMMUNICATION"}

	self.mobileSession = mobile_session.MobileSession(
	self,
	self.mobileConnection)

	self.mobileSession:StartService(7)
		:Do(function(_,data)

			RegisterAppInterface_Success(self, self.mobileSession, RAIParams)

			EXPECT_NOTIFICATION("OnHMIStatus",
						{hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"},
						{hmiLevel = "FULL", audioStreamingState = "AUDIBLE" , systemContext = "MAIN"})
				:Times(2)
				:Do(function(exp,data)
					if exp.occurences == 1 then
						ActivationApp(self, self.applications[config.application2.registerAppInterfaceParams.appName])
					end
				end)
		end)

end 

function Test:SDLSets_COMMUNICATIONApp_ToBACKGROUND_ByAcvivationAnotherCOMMUNICATION()

	self.mobileSession1 = mobile_session.MobileSession(
	self,
	self.mobileConnection)

	local RAIParams = config.application3.registerAppInterfaceParams
	RAIParams.isMediaApplication = false
	RAIParams.appHMIType = {"COMMUNICATION"}
	
	self.mobileSession1:StartService(7)
		:Do(function(_,data)
			RegisterAppInterface_Success(self, self.mobileSession1, RAIParams)

			self.mobileSession1:ExpectNotification("OnHMIStatus",
				{hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"},
				{hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
				:Times(2)
				:Do(function(exp,data)
					if exp.occurences == 1 then 
						--activate registered not activated app
  						ActivationApp(self, self.applications[RAIParams.appName])

					end
				end)


				EXPECT_NOTIFICATION("OnHMIStatus",
				{hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

			DelayedExp(1000)

		end)
end

UnregisterTwoApplication_Success(self, "DeactivationCOMMUNICATIONApp_ByAcvivationAnotherCOMMUNICATION")

-- 40[P][MAN]_TC_Only_one_level_FULL_or_LIMITED_for_Navigation_app
--===================================================================================--
-- Presence of Navigation Application HMI Type doesn't affect rule that 2 media Apps can't have FULL and LIMITED at the same time (APPLINK-9482)
--===================================================================================--

function Test:Precondition_RegisterActivateMediaApplicationWithoutHMIType()
	userPrint(34, "=================================== Test  Case ===================================")

	local RAIParams = config.application2.registerAppInterfaceParams
	RAIParams.isMediaApplication = true
	RAIParams.appHMIType = nil

	self.mobileSession = mobile_session.MobileSession(
	self,
	self.mobileConnection)

	self.mobileSession:StartService(7)
		:Do(function(_,data)

			RegisterAppInterface_Success(self, self.mobileSession, RAIParams)

			EXPECT_NOTIFICATION("OnHMIStatus",
						{hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"},
						{hmiLevel = "FULL", audioStreamingState = "AUDIBLE" , systemContext = "MAIN"})
				:Times(2)
				:Do(function(exp,data)
					if exp.occurences == 1 then
						ActivationApp(self, self.applications[config.application2.registerAppInterfaceParams.appName])
					end
				end)
		end)

end 

function Test:SDLAllowOnlyOneApp_WithisMediaApplicationFlagTrue_DespiteHMIType()

	self.mobileSession1 = mobile_session.MobileSession(
	self,
	self.mobileConnection)

	local RAIParams = config.application3.registerAppInterfaceParams
	RAIParams.isMediaApplication = true
	RAIParams.appHMIType = {"NAVIGATION"}
	
	self.mobileSession1:StartService(7)
		:Do(function(_,data)
			RegisterAppInterface_Success(self, self.mobileSession1, RAIParams)

			self.mobileSession1:ExpectNotification("OnHMIStatus",
				{hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"},
				{hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"},
				{hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
				:Times(3)
				:Do(function(exp,data)
					if exp.occurences == 1 then 
						--activate registered not activated app
  						ActivationApp(self, self.applications[RAIParams.appName])

					end
				end)

			EXPECT_NOTIFICATION("OnHMIStatus",
				{hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"},
				{hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
				:Do(function(exp,data)
					if exp.occurences == 1 then
						ActivationApp(self, self.applications[config.application2.registerAppInterfaceParams.appName])
					end
				end)
				:Times(2)


			DelayedExp(1000)

		end)
end

UnregisterTwoApplication_Success(self, "SDLAllowOnlyOneApp_WithisMediaApplicationFlagTrue_DespiteHMIType")


-- 42[P][MAN]_TC_Only_one_level_FULL_or_LIMITED_for_COMMUNICATION_and_NAVIGATION_app
--===================================================================================--
-- SDL allow only one level: either FULL or LIMITED at the given moment of time for two apps of one and the same AppHMIType with mixed apps type (COMMUNICATION and NAVIGATION, non-media).
--===================================================================================--

function Test:Precondition_RegisterActivateCommunicationApplicationWithisMediaApplicationFlagFalse()
	userPrint(34, "=================================== Test  Case ===================================")

	local RAIParams = config.application2.registerAppInterfaceParams
	RAIParams.isMediaApplication = false
	RAIParams.appHMIType = {"COMMUNICATION"}

	self.mobileSession = mobile_session.MobileSession(
	self,
	self.mobileConnection)

	self.mobileSession:StartService(7)
		:Do(function(_,data)

			RegisterAppInterface_Success(self, self.mobileSession, RAIParams)

			EXPECT_NOTIFICATION("OnHMIStatus",
						{hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"},
						{hmiLevel = "FULL", audioStreamingState = "AUDIBLE" , systemContext = "MAIN"})
				:Times(2)
				:Do(function(exp,data)
					if exp.occurences == 1 then
						ActivationApp(self, self.applications[config.application2.registerAppInterfaceParams.appName])
					end
				end)
		end)

end 

function Test:SDLAllowOnlyOneApp_WithisMediaApplicationFlagFalse_WithMixedHMIType()

	self.mobileSession1 = mobile_session.MobileSession(
	self,
	self.mobileConnection)

	local RAIParams = config.application3.registerAppInterfaceParams
	RAIParams.isMediaApplication = false
	RAIParams.appHMIType = {"NAVIGATION", "COMMUNICATION"}
	
	self.mobileSession1:StartService(7)
		:Do(function(_,data)
			RegisterAppInterface_Success(self, self.mobileSession1, RAIParams)

			self.mobileSession1:ExpectNotification("OnHMIStatus",
				{hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"},
				{hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"},
				{hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
				:Times(3)
				:Do(function(exp,data)
					if exp.occurences == 1 then 
						--activate registered not activated app
  						ActivationApp(self, self.applications[RAIParams.appName])

					end
				end)

			EXPECT_NOTIFICATION("OnHMIStatus",
				{hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"},
				{hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
				:Do(function(exp,data)
					if exp.occurences == 1 then
						ActivationApp(self, self.applications[config.application2.registerAppInterfaceParams.appName])
					end
				end)
				:Times(2)


			DelayedExp(1000)

		end)
end

UnregisterTwoApplication_Success(self, "SDLAllowOnlyOneApp_WithisMediaApplicationFlagFalse_WithMixedHMIType")


-- 46[P][MAN]_TC_SDL_allows_only_FULL_or_LIMITED_if_app_registered_with_several_appHMITypes
--===================================================================================--
-- SDL allow only one level: either FULL or LIMITED if app registered with several "appHMITypes" 
--===================================================================================--

function Test:Precondition_RegisterActivateCommunicationNavigationAppWithisMediaApplicationFlagFalse()
	userPrint(34, "=================================== Test  Case ===================================")

	local RAIParams = config.application2.registerAppInterfaceParams
	RAIParams.isMediaApplication = false
	RAIParams.appHMIType = {"COMMUNICATION", "NAVIGATION"}

	self.mobileSession = mobile_session.MobileSession(
	self,
	self.mobileConnection)

	self.mobileSession:StartService(7)
		:Do(function(_,data)

			RegisterAppInterface_Success(self, self.mobileSession, RAIParams)

			EXPECT_NOTIFICATION("OnHMIStatus",
						{hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"},
						{hmiLevel = "FULL", audioStreamingState = "AUDIBLE" , systemContext = "MAIN"})
				:Times(2)
				:Do(function(exp,data)
					if exp.occurences == 1 then
						ActivationApp(self, self.applications[config.application2.registerAppInterfaceParams.appName])
					end
				end)
		end)

end 

function Test:SDLAllowOnlyOneApp_WithisMediaApplicationFlagFalse_WithseveralHMIType()

	self.mobileSession1 = mobile_session.MobileSession(
	self,
	self.mobileConnection)

	local RAIParams = config.application3.registerAppInterfaceParams
	RAIParams.isMediaApplication = false
	RAIParams.appHMIType = {"COMMUNICATION"}
	
	self.mobileSession1:StartService(7)
		:Do(function(_,data)
			RegisterAppInterface_Success(self, self.mobileSession1, RAIParams)

			self.mobileSession1:ExpectNotification("OnHMIStatus",
				{hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"},
				{hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"},
				{hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
				:Times(3)
				:Do(function(exp,data)
					if exp.occurences == 1 then 
						--activate registered not activated app
  						ActivationApp(self, self.applications[RAIParams.appName])

					end
				end)

			EXPECT_NOTIFICATION("OnHMIStatus",
				{hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"},
				{hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
				:Do(function(exp,data)
					if exp.occurences == 1 then
						ActivationApp(self, self.applications[config.application2.registerAppInterfaceParams.appName])
					end
				end)
				:Times(2)


			DelayedExp(1000)

		end)
end

UnregisterTwoApplication_Success(self, "SDLAllowOnlyOneApp_WithisMediaApplicationFlagFalse_WithseveralHMIType")

-- 43[P][MAN]_TC_FULL_or_LIMITED_app_to_BACKGROUND_after_update
-- 44[P][MAN]_TC_SDL_sends_app's_allowed_AppHMITypes_via_UI.ChangeRegistration
--===================================================================================--
-- After the app's AppHMIType received due to Policies update is different from app's AppHMIType requested during registration, SDL put such FULL or LIMITED app to BACKGROUND.
-- SDL send the updated list of app's allowed AppHMITypes via UI.ChangeRegistration(appID, AppHMIType) to HMI in case the app's AppHMIType received due to Policies update is different from app's AppHMIType requested during registration.
--===================================================================================--
--[==[TODO: TC is disables until resolving ATF issue APPLINK-19188
function Test:Precondition_RegisterActivateCommunicationNavigationAppWithisMediaApplicationFlagFalse()
	userPrint(34, "=================================== Test  Case ===================================")

	local RAIParams = config.application2.registerAppInterfaceParams
	RAIParams.isMediaApplication = false
	RAIParams.appHMIType = {"NAVIGATION"}
	RAIParams.appID = "584421907"
	RAIParams.appName = "SyncProxyTester"

	self.mobileSession = mobile_session.MobileSession(
	self,
	self.mobileConnection)

	self.mobileSession:StartService(7)
		:Do(function(_,data)

			RegisterAppInterface_Success(self, self.mobileSession, RAIParams)

			EXPECT_NOTIFICATION("OnHMIStatus",
						{hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"},
						{hmiLevel = "FULL", audioStreamingState = "AUDIBLE" , systemContext = "MAIN"})
				:Times(2)
				:Do(function(exp,data)
					if exp.occurences == 1 then
						ActivationApp(self, self.applications["SyncProxyTester"])
					end
				end)
		end)

end 

function Test:SDLsetsAppToBackgroundLevel_AfterPerformingPTUwithAnotherHMIType()

	userPrint(33, " Because of ATF defect APPLINK-16052 check of deviceInfo params in BC.UpdateAppList is commented ")

	self.mobileSession1 = mobile_session.MobileSession(
	self,
	self.mobileConnection)

	local RAIParams = config.application3.registerAppInterfaceParams
	RAIParams.isMediaApplication = false
	RAIParams.appHMIType = {"COMMUNICATION"}
	
	self.mobileSession1:StartService(7)
		:Do(function(_,data)
			RegisterAppInterface_Success(self, self.mobileSession1, RAIParams)

			self.mobileSession1:ExpectNotification("OnHMIStatus",
				{hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"},
				{hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
				:Times(2)
				:Do(function(exp,data)
					if exp.occurences == 1 then 
						--activate registered not activated app
  						local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[RAIParams.appName]})

					  	--hmi side: expect SDL.ActivateApp response
						--TODO: Update after resolving APPLINK-16094 EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.ActivateApp"}})
						EXPECT_HMIRESPONSE(RequestId)
  					elseif
  						exp.occurences == 2 then 
  						UpdatePolicy(self, "files/PTU_AppHMIType.json")

  						EXPECT_HMICALL("BasicCommunication.ActivateApp", { appID = self.applications["SyncProxyTester"],level = "BACKGROUND" })
						EXPECT_HMICALL("UI.ChangeRegistration", { appHMIType = {"COMMUNICATION"}, appID = self.applications["SyncProxyTester"] , language = "EN-US" })

						EXPECT_HMICALL("BasicCommunication.UpdateAppList",
							{applications = {
							   	{
							      	appName = "SyncProxyTester",
							      	--[=[TODO: remove after resolving APPLINK-16052
							      	deviceInfo = {
								        id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
								        isSDLAllowed = true,
								        name = "127.0.0.1",
								        transportType = "WIFI"
							      	},]=]
							      	appType = {"COMMUNICATION"}
							   	},
							   	{
							      	appName = RAIParams.appName,
							      	--[=[TODO: remove after resolving APPLINK-16052
							      	deviceInfo = {
								        id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
								        isSDLAllowed = true,
								        name = "127.0.0.1",
								        transportType = "WIFI"
							      	},]=]
							      	appType = {"COMMUNICATION"}
							   	}
							}})
							:Do(function(_,data)
								self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
						  	end)
					end
				end)

			EXPECT_NOTIFICATION("OnHMIStatus",
				{hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"},
				{hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
				:Times(2)

			DelayedExp(1000)

		end)
end

UnregisterTwoApplication_Success(self, "SDLsetsAppToBackgroundLevel_AfterPerformingPTUwithAnotherHMIType")
]==]
--===================================================================================--
-- SDL sets app to NOT_AUDIBLE state in case VR session is active, to ATTENUATED state during speak is active when mixing audio is supported
--===================================================================================--

function Test:AudioStreaming_NOT_AUDIBLE_ATTENUATED_inFULL_MixingAudio_is_supported()
	userPrint(34, "=================================== Test  Case ===================================")

	local RAIParams = config.application1.registerAppInterfaceParams

	self.mobileSession = mobile_session.MobileSession(
	self,
	self.mobileConnection)

	self.mobileSession:StartService(7)
		:Do(function(_,data)

			RegisterAppInterface_Success(self, self.mobileSession, RAIParams)
			if MediaApp or NaviComApp then

				EXPECT_NOTIFICATION("OnHMIStatus", 
							{hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"},
							{hmiLevel = "FULL", audioStreamingState = "AUDIBLE" , systemContext = "MAIN"},
							{hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE" , systemContext = "MAIN"},
							{hmiLevel = "FULL", audioStreamingState = "AUDIBLE" , systemContext = "MAIN"},
							{hmiLevel = "FULL", audioStreamingState = "ATTENUATED" , systemContext = "MAIN"},
							{hmiLevel = "FULL", audioStreamingState = "AUDIBLE" , systemContext = "MAIN"})
					:Times(6)
					:Do(function(exp,data)
						if exp.occurences == 1 then
							ActivationApp(self, self.applications[RAIParams.appName])
						elseif
							exp.occurences == 2 then

							-- Openning VR menu
							self.hmiConnection:SendNotification("VR.Started",{})

							function StopVRSession()
								--Closing VR menu
		  						self.hmiConnection:SendNotification("VR.Stopped",{})
		  					end

		  					RUN_AFTER(StopVRSession, 500)
		  				elseif
		  					exp.occurences == 4 then

		  					--mobile side: sending the request
							local cid = self.mobileSession:SendRPC("Speak", {
									ttsChunks = 
									{ 
										{
											text ="Speak request",
											type ="TEXT"
										}
									}})

							--hmi side: expect TTS.Speak request
							EXPECT_HMICALL("TTS.Speak", {
								ttsChunks = 
								{ 
									{
										text ="Speak request",
										type ="TEXT"
									}
								}})
							:Do(function(_,data)
								self.hmiConnection:SendNotification("TTS.Started")

								local function speakResponse()
									self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })

									self.hmiConnection:SendNotification("TTS.Stopped")
								end
								RUN_AFTER(speakResponse, 500)
							end)

							--mobile side: expect the response
							EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

						end
					end)
			else
				EXPECT_NOTIFICATION("OnHMIStatus",
					{hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"},
					{hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE" , systemContext = "MAIN"})
					:Times(2)
					:Do(function(exp,data)
						if exp.occurences == 1 then
							ActivationApp(self, self.applications[RAIParams.appName])
						elseif
							exp.occurences == 2 then

							-- Openning VR menu
							self.hmiConnection:SendNotification("VR.Started",{})

							function StopVRSession()
								--Closing VR menu
		  						self.hmiConnection:SendNotification("VR.Stopped",{})
		  					end

		  					RUN_AFTER(StopVRSession, 500)

		  					function Speak()
			  					--mobile side: sending the request
								local cid = self.mobileSession:SendRPC("Speak", {
										ttsChunks = 
										{ 
											{
												text ="Speak request",
												type ="TEXT"
											}
										}})

								--hmi side: expect TTS.Speak request
								EXPECT_HMICALL("TTS.Speak", {
									ttsChunks = 
									{ 
										{
											text ="Speak request",
											type ="TEXT"
										}
									}})
								:Do(function(_,data)
									self.hmiConnection:SendNotification("TTS.Started")

									local function speakResponse()
										self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })

										self.hmiConnection:SendNotification("TTS.Stopped")
									end
									RUN_AFTER(speakResponse, 500)
								end)

								--mobile side: expect the response
								EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
							end

							RUN_AFTER(Speak,1500)

						end
					end)

			end
		end)
end 

function Test:Postcondition_UnregisteApp_AudioStreaming_NOT_AUDIBLE_ATTENUATED_inFULL_MixingAudio_is_supported()
	UnregisterApplication_Success(self, self.mobileSession, self.applications[config.application1.registerAppInterfaceParams.appName])
end

if MediaApp or NaviComApp then

	function Test:AudioStreaming_NOT_AUDIBLE_ATTENUATED_inLIMITED_MixingAudio_is_supported()
		local RAIParams = config.application1.registerAppInterfaceParams

		self.mobileSession = mobile_session.MobileSession(
		self,
		self.mobileConnection)

		self.mobileSession:StartService(7)
			:Do(function(_,data)

				RegisterAppInterface_Success(self, self.mobileSession, RAIParams)

					EXPECT_NOTIFICATION("OnHMIStatus", 
								{hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"},
								{hmiLevel = "FULL", audioStreamingState = "AUDIBLE" , systemContext = "MAIN"},
								{hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE" , systemContext = "MAIN"},
								{hmiLevel = "LIMITED", audioStreamingState = "NOT_AUDIBLE" , systemContext = "MAIN"},
								{hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE" , systemContext = "MAIN"},
								{hmiLevel = "LIMITED", audioStreamingState = "ATTENUATED" , systemContext = "MAIN"},
								{hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE" , systemContext = "MAIN"})
						:Times(7)
						:Do(function(exp,data)
							if exp.occurences == 1 then
									ActivationApp(self, self.applications[RAIParams.appName])
							elseif
								exp.occurences == 2 then
									-- Deactivate app ti LIMITED level
									self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated",
									{
										appID = self.applications[RAIParams.appName]
									})
							elseif
								exp.occurences == 3 then

								-- Openning VR menu
								self.hmiConnection:SendNotification("VR.Started",{})

								function StopVRSession()
									--Closing VR menu
			  						self.hmiConnection:SendNotification("VR.Stopped",{})
			  					end

			  					RUN_AFTER(StopVRSession, 500)
			  				elseif
			  					exp.occurences == 5 then

			  					--mobile side: sending the request
								local cid = self.mobileSession:SendRPC("Speak", {
										ttsChunks = 
										{ 
											{
												text ="Speak request",
												type ="TEXT"
											}
										}})

								--hmi side: expect TTS.Speak request
								EXPECT_HMICALL("TTS.Speak", {
									ttsChunks = 
									{ 
										{
											text ="Speak request",
											type ="TEXT"
										}
									}})
								:Do(function(_,data)
									self.hmiConnection:SendNotification("TTS.Started")

									local function speakResponse()
										self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })

										self.hmiConnection:SendNotification("TTS.Stopped")
									end
									RUN_AFTER(speakResponse, 500)
								end)

								--mobile side: expect the response
								EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

							end
						end)
			end)
	end 

	function Test:Postcondition_UnregisteApp_AudioStreaming_NOT_AUDIBLE_ATTENUATED_inLIMITED_MixingAudio_is_supported()
		UnregisterApplication_Success(self, self.mobileSession, self.applications[config.application1.registerAppInterfaceParams.appName])
	end

end

-- 45[P][MAN]_TC_AudioStreaming_status_if_mixing_audio_not_supported
--===================================================================================--
-- SDL sets app to NOT_AUDIBLE state in case VR session is active, to ATTENUATED state during speak is active when mixing audio is not supported
--===================================================================================--

DeletingDatabase_RestartSDL("MixingAudioIsNotSupported", false)

function Test:AudioStreaming_NOT_AUDIBLE_inFULL_MixingAudio_is_not_supported()
	userPrint(34, "=================================== Test  Case ===================================")

	local RAIParams = config.application1.registerAppInterfaceParams

	self.mobileSession = mobile_session.MobileSession(
	self,
	self.mobileConnection)

	self.mobileSession:StartService(7)
		:Do(function(_,data)

			RegisterAppInterface_Success(self, self.mobileSession, RAIParams)
			if MediaApp or NaviComApp then

				EXPECT_NOTIFICATION("OnHMIStatus", 
							{hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"},
							{hmiLevel = "FULL", audioStreamingState = "AUDIBLE" , systemContext = "MAIN"},
							{hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE" , systemContext = "MAIN"},
							{hmiLevel = "FULL", audioStreamingState = "AUDIBLE" , systemContext = "MAIN"},
							{hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE" , systemContext = "MAIN"},
							{hmiLevel = "FULL", audioStreamingState = "AUDIBLE" , systemContext = "MAIN"})
					:Times(6)
					:Do(function(exp,data)
						if exp.occurences == 1 then
							function Activate()
								ActivationApp(self, self.applications[RAIParams.appName])
							end
							RUN_AFTER(Activate, 500)
						elseif
							exp.occurences == 2 then

							-- Openning VR menu
							self.hmiConnection:SendNotification("VR.Started",{})

							function StopVRSession()
								--Closing VR menu
		  						self.hmiConnection:SendNotification("VR.Stopped",{})
		  					end

		  					RUN_AFTER(StopVRSession, 500)
		  				elseif
		  					exp.occurences == 4 then

		  					--mobile side: sending the request
							local cid = self.mobileSession:SendRPC("Speak", {
									ttsChunks = 
									{ 
										{
											text ="Speak request",
											type ="TEXT"
										}
									}})

							--hmi side: expect TTS.Speak request
							EXPECT_HMICALL("TTS.Speak", {
								ttsChunks = 
								{ 
									{
										text ="Speak request",
										type ="TEXT"
									}
								}})
							:Do(function(_,data)
								self.hmiConnection:SendNotification("TTS.Started")

								local function speakResponse()
									self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })

									self.hmiConnection:SendNotification("TTS.Stopped")
								end
								RUN_AFTER(speakResponse, 500)
							end)

							--mobile side: expect the response
							EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

						end
					end)
			else
				EXPECT_NOTIFICATION("OnHMIStatus",
					{hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"},
					{hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE" , systemContext = "MAIN"})
					:Times(2)
					:Do(function(exp,data)
						if exp.occurences == 1 then
							ActivationApp(self, self.applications[RAIParams.appName])
						elseif
							exp.occurences == 2 then

							-- Openning VR menu
							self.hmiConnection:SendNotification("VR.Started",{})

							function StopVRSession()
								--Closing VR menu
		  						self.hmiConnection:SendNotification("VR.Stopped",{})
		  					end

		  					RUN_AFTER(StopVRSession, 500)

		  					function Speak()
			  					--mobile side: sending the request
								local cid = self.mobileSession:SendRPC("Speak", {
										ttsChunks = 
										{ 
											{
												text ="Speak request",
												type ="TEXT"
											}
										}})

								--hmi side: expect TTS.Speak request
								EXPECT_HMICALL("TTS.Speak", {
									ttsChunks = 
									{ 
										{
											text ="Speak request",
											type ="TEXT"
										}
									}})
								:Do(function(_,data)
									self.hmiConnection:SendNotification("TTS.Started")

									local function speakResponse()
										self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })

										self.hmiConnection:SendNotification("TTS.Stopped")
									end
									RUN_AFTER(speakResponse, 500)
								end)

								--mobile side: expect the response
								EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
							end

							RUN_AFTER(Speak,1500)

						end
					end)

			end
		end)
end 

function Test:Postcondition_UnregisteApp_AudioStreaming_NOT_AUDIBLE_inFULL_MixingAudio_is_not_supported()
	UnregisterApplication_Success(self, self.mobileSession, self.applications[config.application1.registerAppInterfaceParams.appName])
end

if MediaApp or NaviComApp then

	function Test:AudioStreaming_NOT_AUDIBLE_inLIMITED_MixingAudio_is_not_supported()
		local RAIParams = config.application1.registerAppInterfaceParams

		self.mobileSession = mobile_session.MobileSession(
		self,
		self.mobileConnection)

		self.mobileSession:StartService(7)
			:Do(function(_,data)

				RegisterAppInterface_Success(self, self.mobileSession, RAIParams)

					EXPECT_NOTIFICATION("OnHMIStatus", 
								{hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"},
								{hmiLevel = "FULL", audioStreamingState = "AUDIBLE" , systemContext = "MAIN"},
								{hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE" , systemContext = "MAIN"},
								{hmiLevel = "LIMITED", audioStreamingState = "NOT_AUDIBLE" , systemContext = "MAIN"},
								{hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE" , systemContext = "MAIN"},
								{hmiLevel = "LIMITED", audioStreamingState = "NOT_AUDIBLE" , systemContext = "MAIN"},
								{hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE" , systemContext = "MAIN"})
						:Times(7)
						:Do(function(exp,data)
							if exp.occurences == 1 then
								ActivationApp(self, self.applications[RAIParams.appName])
							elseif
								exp.occurences == 2 then
									-- Deactivate app ti LIMITED level
									self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated",
									{
										appID = self.applications[RAIParams.appName]
									})
							elseif
								exp.occurences == 3 then

								-- Openning VR menu
								self.hmiConnection:SendNotification("VR.Started",{})

								function StopVRSession()
									--Closing VR menu
			  						self.hmiConnection:SendNotification("VR.Stopped",{})
			  					end

			  					RUN_AFTER(StopVRSession, 500)
			  				elseif
			  					exp.occurences == 5 then

			  					--mobile side: sending the request
								local cid = self.mobileSession:SendRPC("Speak", {
										ttsChunks = 
										{ 
											{
												text ="Speak request",
												type ="TEXT"
											}
										}})

								--hmi side: expect TTS.Speak request
								EXPECT_HMICALL("TTS.Speak", {
									ttsChunks = 
									{ 
										{
											text ="Speak request",
											type ="TEXT"
										}
									}})
								:Do(function(_,data)
									self.hmiConnection:SendNotification("TTS.Started")

									local function speakResponse()
										self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })

										self.hmiConnection:SendNotification("TTS.Stopped")
									end
									RUN_AFTER(speakResponse, 500)
								end)

								--mobile side: expect the response
								EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

							end
						end)
			end)
	end 

	function Test:Postcondition_UnregisteApp_AudioStreaming_NOT_AUDIBLE_inLIMITED_MixingAudio_is_not_supported()
		UnregisterApplication_Success(self, self.mobileSession, self.applications[config.application1.registerAppInterfaceParams.appName])
	end

end

-- 08[P][MAN]_TC_Change_systemContext_to_VRSESSION
-- 09[P][MAN]_TC_Change_systemContext_to_HMI_OBSCURED
-- 10[P][MAN]_TC_Change_systemContext_for_both_Apps
--===================================================================================--
-- SDL sends OnHMIStatus notification to mobile app about change of systemContext only for FULL App
--===================================================================================--

function Test:Precondition_RegisterNonMediaApplication_SystemContextToFullApp()
	userPrint(34, "=================================== Test  Case ===================================")
	self.mobileSession = mobile_session.MobileSession(
		self,
		self.mobileConnection)

	self.mobileSession:StartService(7)
		:Do(function(_,data)
			local RAIParams = config.application2.registerAppInterfaceParams
			RAIParams.isMediaApplication = false
			RAIParams.appHMIType = {"DEFAULT"}

			--mobile side: RegisterAppInterface request 
			local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface", RAIParams)

			--hmi side: expected  BasicCommunication.OnAppRegistered
			EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
				:Do(function(_,data)
					self.applications[data.params.application.appName] = data.params.application.appID
				end)

			--mobile side: RegisterAppInterface response 
			self.mobileSession:ExpectResponse(CorIdRAI, { success = true, resultCode = "SUCCESS"})

			self.mobileSession:ExpectNotification("OnHMIStatus", 
				{hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"}) 
		end)
end

function Test:Precondition_RegisterNavigationApplication_SystemContextToFullApp()

	self.mobileSession1 = mobile_session.MobileSession(
		self,
		self.mobileConnection)

	self.mobileSession1:StartService(7)
		:Do(function(_,data)
			local RAIParams = config.application3.registerAppInterfaceParams
			RAIParams.isMediaApplication = false
			RAIParams.appHMIType = {"NAVIGATION"}

			--mobile side: RegisterAppInterface request 
			local CorIdRAI = self.mobileSession1:SendRPC("RegisterAppInterface", RAIParams)

			--hmi side: expected  BasicCommunication.OnAppRegistered
			EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
				:Do(function(_,data)
					self.applications[data.params.application.appName] = data.params.application.appID
				end)

			--mobile side: RegisterAppInterface response 
			self.mobileSession1:ExpectResponse(CorIdRAI, { success = true, resultCode = "SUCCESS"})

			self.mobileSession1:ExpectNotification("OnHMIStatus", 
				{hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
		end)

end

function Test:Precondition_RegisterCommunicationApplication_SystemContextToFullApp()

	self.mobileSession2 = mobile_session.MobileSession(
		self,
		self.mobileConnection)

	self.mobileSession2:StartService(7)
		:Do(function(_,data)
			local RAIParams = config.application4.registerAppInterfaceParams
			RAIParams.isMediaApplication = false
			RAIParams.appHMIType = {"COMMUNICATION"}

			--mobile side: RegisterAppInterface request 
			local CorIdRAI = self.mobileSession2:SendRPC("RegisterAppInterface", RAIParams)

			--hmi side: expected  BasicCommunication.OnAppRegistered
			EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
				:Do(function(_,data)
					self.applications[data.params.application.appName] = data.params.application.appID
				end)

			--mobile side: RegisterAppInterface response 
			self.mobileSession2:ExpectResponse(CorIdRAI, { success = true, resultCode = "SUCCESS"})

			self.mobileSession2:ExpectNotification("OnHMIStatus", 
				{hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
		end)
end

function Test:SetAppsTo_FULL_LIMITED_BACKGROUND()

	-- Activate non-media app
	ActivationApp(self, self.applications[config.application2.registerAppInterfaceParams.appName])

	--mobile side: expect OnHMIStatus notification on non-media app
	self.mobileSession:ExpectNotification("OnHMIStatus", 
		{hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"}, 
		{hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"}) 
		:Do(function(exp,data)
			if exp.occurences == 1 then
				-- Activate navigation app
				ActivationApp(self, self.applications[config.application3.registerAppInterfaceParams.appName])
			end
		end)
		:Times(2)

	--mobile side: expect OnHMIStatus notification on navigation app
	self.mobileSession1:ExpectNotification("OnHMIStatus", 
		{hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"},
		{hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"}) 
		:Do(function(exp,data)
			if exp.occurences == 1 then
				-- Activate communication app
				ActivationApp(self, self.applications[config.application4.registerAppInterfaceParams.appName])
			end
		end)
		:Times(2)

	--mobile side: expect OnHMIStatus notification on communication app
	self.mobileSession2:ExpectNotification("OnHMIStatus", 
		{hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"}) 
end

local SystemContext =  {"VRSESSION", "MENU", "HMI_OBSCURED"}
for i=1, #SystemContext do
	Test["SystemContextTo" .. tostring(SystemContext[i]) .. "WithoutAppIDOnHMIStatusOnlyToFullApp"] = function(self)
		SendOnSystemContext(self, SystemContext[i], "empty")

		--mobile side: expect OnHMIStatus notification on non-media app
			self.mobileSession:ExpectNotification("OnHMIStatus", {})
				:Times(0)

		--mobile side: expect OnHMIStatus notification on navigation app
			self.mobileSession1:ExpectNotification("OnHMIStatus", {})
				:Times(0)

		--mobile side: expect OnHMIStatus notification on communication app
			self.mobileSession2:ExpectNotification("OnHMIStatus", 
				{hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = SystemContext[i]},
				{hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
				:Times(2)

		function SystemReq() 
			SendOnSystemContext(self, "MAIN", "empty")
		end

		RUN_AFTER(SystemReq, 1000)

		DelayedExp(2000)
	end
end

for i=1, #SystemContext do
	Test["SystemContextTo" .. tostring(SystemContext[i]) .. "WithAppIDOnHMIStatusOnlyToFullApp"] = function(self)

		SendOnSystemContext(self, SystemContext[i], self.applications[config.application3.registerAppInterfaceParams.appName])

		--mobile side: expect OnHMIStatus notification on non-media app
			self.mobileSession:ExpectNotification("OnHMIStatus", {})
				:Times(0)

		--mobile side: expect OnHMIStatus notification on navigation app
			self.mobileSession1:ExpectNotification("OnHMIStatus", {})
				:Times(0)

		--mobile side: expect OnHMIStatus notification on communication app
			self.mobileSession2:ExpectNotification("OnHMIStatus", 
				{hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = SystemContext[i]},
				{hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
				:Times(2)

		function SystemReq() 
			SendOnSystemContext(self, "MAIN", self.applications[config.application3.registerAppInterfaceParams.appName])
		end

		RUN_AFTER(SystemReq, 1000)

		DelayedExp(2000)
	end
end

function Test:Postcondition_UnregisterNonMediaApp_WithAppIDOnHMIStatusOnlyToFullApp()
	UnregisterApplication_Success(self, self.mobileSession, self.applications[config.application2.registerAppInterfaceParams.appName])
end

function Test:Postcondition_UnregisterNavigationApp_WithAppIDOnHMIStatusOnlyToFullApp()
	UnregisterApplication_Success(self, self.mobileSession1, self.applications[config.application3.registerAppInterfaceParams.appName])
end

function Test:Postcondition_UnregisterCommunicationApp_WithAppIDOnHMIStatusOnlyToFullApp()
	UnregisterApplication_Success(self, self.mobileSession2, self.applications[config.application4.registerAppInterfaceParams.appName])
end

local function APPLINK_10706()

--SDL must send OnHMIStatus notification with "AudioStreamingState: NOT_AUDIBLE" to mobile app in case VR session is active for the system that can audio-mix ("MixingAudioSupported = true" in .ini file)
--===================================================================================--

	--Precondition: Make sure that MixingAudioSupported = true in ini file
	function Test:Precondition_SetMixingAudioSupported()
		local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
		commonFunctions:SetValuesInIniFile("%p?MixingAudioSupported%s?=%s-[%w%d,-]-%s-\n", "MixingAudioSupported", true)
	end

	--Precondition: Restart SDL after updating ini file
	local function RestartSDL_InitHMI_ConnectMobile(self, Note)

		--Stop SDL
		Test[tostring(Note) .. "_StopSDL"] = function(self)
			StopSDL()
		end
		--Start SDL
		Test[tostring(Note) .. "_StartSDL"] = function(self)
			StartSDL(config.pathToSDL, config.ExitOnCrash)
		end
		--InitHMI
		Test[tostring(Note) .. "_InitHMI"] = function(self)
			self:initHMI()
		end
		--InitHMIonReady
		Test[tostring(Note) .. "_InitHMIonReady"] = function(self)
			self:initHMI_onReady()
		end
		--ConnectMobile
		Test[tostring(Note) .. "_ConnectMobile"] = function(self)
			self:connectMobile()
		end
		
	end
	
	RestartSDL_InitHMI_ConnectMobile(self, "Precondition")
	
	--Case: HMILevel = FULL
	function Test:AudioStreaming_NOT_AUDIBLE_inFULL_MixingAudio_is_supported()
		userPrint(34, "=================================== Test  Case ===================================")
		
		--Precondition: Add new session  
		local RAIParams = config.application1.registerAppInterfaceParams

		self.mobileSession = mobile_session.MobileSession(
		self,
		self.mobileConnection)
		
		self.mobileSession:StartService(7)
			:Do(function(_,data)
		
		--Precondition: Register App  
				RegisterAppInterface_Success(self, self.mobileSession, RAIParams)
				if MediaApp or NaviComApp then

					EXPECT_NOTIFICATION("OnHMIStatus", 
								{hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"},
								{hmiLevel = "FULL", audioStreamingState = "AUDIBLE" , systemContext = "MAIN"},
								{hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE" , systemContext = "MAIN"},
								{hmiLevel = "FULL", audioStreamingState = "AUDIBLE" , systemContext = "MAIN"})
						:Times(4)
						
						--Precondition: Activate app
						:Do(function(exp,data)
							if exp.occurences == 1 then
								ActivationApp(self, self.applications[RAIParams.appName])
							elseif
								exp.occurences == 2 then

								-- Openning VR menu
								self.hmiConnection:SendNotification("VR.Started",{})

								function StopVRSession()
									--Closing VR menu
									self.hmiConnection:SendNotification("VR.Stopped",{})
								end

								RUN_AFTER(StopVRSession, 500)

							end
						end)
				else
					EXPECT_NOTIFICATION("OnHMIStatus",
						{hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"},
						{hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE" , systemContext = "MAIN"})
						:Times(2)
						:Do(function(exp,data)
							if exp.occurences == 1 then
								ActivationApp(self, self.applications[RAIParams.appName])
							elseif
								exp.occurences == 2 then

								-- Openning VR menu
								self.hmiConnection:SendNotification("VR.Started",{})

								function StopVRSession()
									--Closing VR menu
									self.hmiConnection:SendNotification("VR.Stopped",{})
								end

								RUN_AFTER(StopVRSession, 500)

							end
						end)

				end
			end)
	end 

	--Postcondition: Unregister App
	function Test:Postcondition_UnregisteApp_AudioStreaming_NOT_AUDIBLE_inFULL_MixingAudio_is_supported()
		UnregisterApplication_Success(self, self.mobileSession, self.applications[config.application1.registerAppInterfaceParams.appName])
	end

	--Case: HMILevel = LIMITED
	if MediaApp or NaviComApp then

		function Test:AudioStreaming_NOT_AUDIBLE_inLIMITED_MixingAudio_is_supported()
			local RAIParams = config.application1.registerAppInterfaceParams
			--Precondition: Add new session
			self.mobileSession = mobile_session.MobileSession(
			self,
			self.mobileConnection)

			self.mobileSession:StartService(7)
				:Do(function(_,data)
					--Precondition: Register App  
					RegisterAppInterface_Success(self, self.mobileSession, RAIParams)

						EXPECT_NOTIFICATION("OnHMIStatus", 
									{hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"},
									{hmiLevel = "FULL", audioStreamingState = "AUDIBLE" , systemContext = "MAIN"},
									{hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE" , systemContext = "MAIN"},
									{hmiLevel = "LIMITED", audioStreamingState = "NOT_AUDIBLE" , systemContext = "MAIN"},
									{hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE" , systemContext = "MAIN"})
							:Times(5)
							--Precondition: Activate app
							:Do(function(exp,data)
								if exp.occurences == 1 then
										ActivationApp(self, self.applications[RAIParams.appName])
										
								elseif
									exp.occurences == 2 then
										-- Deactivate app ti LIMITED level
										self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated",
										{
											appID = self.applications[RAIParams.appName]
										})
								elseif
									exp.occurences == 3 then

									-- Openning VR menu
									self.hmiConnection:SendNotification("VR.Started",{})

									function StopVRSession()
										--Closing VR menu
										self.hmiConnection:SendNotification("VR.Stopped",{})
									end

									RUN_AFTER(StopVRSession, 500)

								end
							end)
				end)
		end 
		
	--Postcondition: Unregister App
		function Test:Postcondition_UnregisteApp_AudioStreaming_NOT_AUDIBLE_inLIMITED_MixingAudio_is_supported()
			UnregisterApplication_Success(self, self.mobileSession, self.applications[config.application1.registerAppInterfaceParams.appName])
		end

	end
	
end

APPLINK_10706()
