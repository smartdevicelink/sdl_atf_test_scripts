local commonSteps   = require('user_modules/shared_testcases/commonSteps')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')

 
function DeleteLog_app_info_dat_policy()
    commonSteps:CheckSDLPath()
    local SDLStoragePath = config.pathToSDL .. "storage/"

    --Delete app_info.dat and log files and storage
    if commonSteps:file_exists(config.pathToSDL .. "app_info.dat") == true then
      os.remove(config.pathToSDL .. "app_info.dat")
    end

    if commonSteps:file_exists(config.pathToSDL .. "SmartDeviceLinkCore.log") == true then
      os.remove(config.pathToSDL .. "SmartDeviceLinkCore.log")
    end

    if commonSteps:file_exists(SDLStoragePath .. "policy.sqlite") == true then
      os.remove(SDLStoragePath .. "policy.sqlite")
    end

    if commonSteps:file_exists(config.pathToSDL .. "policy.sqlite") == true then
      os.remove(config.pathToSDL .. "policy.sqlite")
    end

    os.execute("rm -r " ..config.pathToSDL .. "storage")
end

-- Function will delete all needed files and folders => SDL will start very first ignition cycle.
DeleteLog_app_info_dat_policy()

--UPDATED
local default_HelpPromt = "Default Help Prompt"
	
-- Requirement id in JIRA: APPLINK-19475
-- Read default value of HelpPromt in .ini file
f = assert(io.open(config.pathToSDL.. "/smartDeviceLink.ini", "r"))
 
fileContent = f:read("*all")
DefaultContant = fileContent:match('HelpPromt.?=.?([^\n]*)')
 	
if not DefaultContant then
	print ( " \27[31m HelpPromt is not found in smartDeviceLink.ini \27[0m " )
else
	default_HelpPromt = DefaultContant
	print(default_HelpPromt)
end
f:close()


Test = require('connecttest')
require('cardinalities')

local mobile_session = require('mobile_session')
local custom = require('user_modules/custom')
local mobileResponseTimeout = 10000
local indexOfTests = 1
local HMIAppID = nil
local actualVrHelpItem = nil
local actualVrHelpTitle = nil
local appid

config.deviceMAC              = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
--ToDo: shall be removed when APPLINK-16610 is fixed
config.defaultProtocolVersion = 2

local function sleep(sec)
  -- body
  os.execute("sleep " .. sec)
end




-- ///////////////////////////////////////////////////////////////////////////////////////////////////
-- App sends the very first SetGlobalProperties_request in current ignition cycle WITH <VRHelp> and <VRHelpTitle> params
-- ///////////////////////////////////////////////////////////////////////////////////////////////////

-- function Test:PreconditionUploadingAppsFiles(...)
-- 	-- body
-- 	custom.testHead()
-- 	local cid = self.mobileSession:SendRPC("PutFile",
-- 		{			
-- 			syncFileName = "action.png",
-- 			fileType	= "GRAPHIC_PNG",
-- 			persistentFile = true
-- 		}, "user_modules/icon.png")

-- 		EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
-- end

Test["PreconditionRegisterApp" .. tostring(indexOfTests)] = function (self)
	-- body
	custom.preconditionHead()
	custom.preconditionMessage("Registration of App")
end
indexOfTests = indexOfTests + 1

function Test:AppSendsFirstSGPWithVrHelpItems(...)
	-- body
	custom.testHead()
	custom.testMessage("App sends the very first SetGlobalProperties_request in current ignition cycle WITH <VRHelp> and <VRHelpTitle> params")
	custom.info("Expected: SDL transfers vrHelp and vrHelpTitle via UI.SetGlobalProperties")


	-- custom.userPrint(33, custom.SGP_with_vr_help_start)
	local cid = self.mobileSession:SendRPC("SetGlobalProperties", custom.SGP_with_vr_help_start)
	
	EXPECT_HMICALL("UI.SetGlobalProperties", {
		vrHelp = custom.SGP_with_vr_help_start.vrHelp, 
		vrHelpTitle = custom.SGP_with_vr_help_start.vrHelpTitle},
		--UPDATED
		appID = self.applications[config.application1.registerAppInterfaceParams.appName]
		)
	:Do(function(_,data)
		--hmi side: sending UI.SetGlobalProperties response
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		actualVrHelpItem = custom.SGP_with_vr_help_start.vrHelp
		actualVrHelpTitle = custom.SGP_with_vr_help_start.vrHelpTitle
	end)

	--UPDATED
	EXPECT_HMICALL("TTS.SetGlobalProperties",
						{
							helpPrompt = 
										{
											{
												text = default_HelpPromt,
												type = "TEXT"
										}	},																		
							appID = self.applications[config.application1.registerAppInterfaceParams.appName]
						})
	:Do(function(_,data)
		--hmi side: sending UI.SetGlobalProperties response
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
	end)		

	--mobile side: expect SetGlobalProperties response
	EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
	:Timeout(mobileResponseTimeout)
end


-- ///////////////////////////////////////////////////////////////////////////////////////////////////
-- App sends the very first SetGlobalProperties_request in current ignition cycle WITHOUT <VRHelp> and <VRHelpTitle> params
-- ///////////////////////////////////////////////////////////////////////////////////////////////////

-- Begin Precondition.1
-- Description: RestartSDL

function Test:UnregisterApp(...)
	-- body
	custom.preconditionHead()
	custom.preconditionMessage("Graceful unregister of Application")

	local cid = self.mobileSession:SendRPC("UnregisterAppInterface",{})

	EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
	:Timeout(2000)

end

Test["Stub"..tostring(indexOfTests)] = function (self)
	-- body
	custom.preconditionHead()
	custom.preconditionMessage("RestartSDL")
end
  
Test["StopSDL"..tostring(indexOfTests)] = function (self)
	StopSDL()
end

Test["StartSDL" .. tostring(indexOfTests)] = function (self)
	StartSDL(config.pathToSDL, config.ExitOnCrash)
end

Test["TestInitHMI" .. tostring(indexOfTests)] = function (self)
	self:initHMI()
end

Test["TestInitHMIOnReady" .. tostring(indexOfTests)] = function (self)
	self:initHMI_onReady()
end

Test["ConnectMobile" .. tostring(indexOfTests)] = function (self)
	self:connectMobile()
end

Test["StartSession" .. tostring(indexOfTests)] = function (self)
	self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
end
-- End Precondition.1

-- Begin Precondition.2
-- Description: ResgisterApp
Test["PreconditionRegisterApp" .. tostring(indexOfTests)] = function (self)
	-- body
	custom.preconditionHead()

	-- Register App
	custom.preconditionMessage("Register Application without vrSynonyms and commands")
	self.mobileSession:StartService(7)
	:Do(function (_,data)
		local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)

		EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
		:Do(function(_,data)
			HMIAppID = data.params.application.appID
		end)

		-- self.mobileSession:ExpectResponse(correlationId, { success = true })
		EXPECT_RESPONSE(correlationId, { success = true })

		EXPECT_NOTIFICATION("OnHMIStatus")
		:Timeout(mobileResponseTimeout)

		EXPECT_NOTIFICATION("OnPermissionsChange")
		:Timeout(mobileResponseTimeout)
  	end)
end
indexOfTests = indexOfTests + 1
-- End Precondition.2

function Test:AppSendsFirstSGPWithoutVrHelpItems1(...)
	-- body
	custom.testHead()
	custom.testMessage("App sends the very first SetGlobalProperties_request in current ignition cycle WITHOUT <VRHelp> and <VRHelpTitle> params")
	custom.info("Expected: SDL sends UI.SetGlobalProperties with DEFAULT vrHelpTitle constructed from appName")

	local cid = self.mobileSession:SendRPC("SetGlobalProperties", custom.SGP_without_vr_help_start)
	
	EXPECT_HMICALL("UI.SetGlobalProperties",
	{
		vrHelpTitle = tostring(config.application1.registerAppInterfaceParams.appName),
		--UPDATED
		vrHelp ={ 
					{
						text = config.application1.registerAppInterfaceParams.appName,
						position = 1
				}	},
		appID = self.applications[config.application1.registerAppInterfaceParams.appName]
	})
	:Do(function(_,data)
		--hmi side: sending UI.SetGlobalProperties response
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		actualVrHelpItem = nil
		actualVrHelpTitle = tostring(config.application1.registerAppInterfaceParams.appName)
		if data.params.vrHelp then
			self:FailTestCase("vrHelp is present")
		end
	end)

	--UPDATED
	EXPECT_HMICALL("TTS.SetGlobalProperties",
					{
						helpPrompt = {
										{
											text = default_HelpPromt,
											type = "TEXT"
									}	},																		
						appID = self.applications[config.application1.registerAppInterfaceParams.appName]
					})
	:Do(function(_,data)
		--hmi side: sending UI.SetGlobalProperties response
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
	end)		

	--mobile side: expect SetGlobalProperties response
	EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
	:Timeout(mobileResponseTimeout)

end


-- ///////////////////////////////////////////////////////////////////////////////////////////////////
-- App sends the very first SetGlobalProperties_request in current ignition cycle WITHOUT <VRHelp> and <VRHelpTitle> params
-- ///////////////////////////////////////////////////////////////////////////////////////////////////

-- Begin Precondition.1
-- Description: RestartSDL

function Test:UnregisterApp(...)
	-- body
	custom.preconditionHead()
	custom.preconditionMessage("Graceful unregister of Application")

	local cid = self.mobileSession:SendRPC("UnregisterAppInterface",{})

	EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
	:Timeout(2000)

end

Test["Stub"..tostring(indexOfTests)] = function (self)
	-- body
	custom.preconditionHead()
	custom.preconditionMessage("RestartSDL")
end
  
Test["StopSDL"..tostring(indexOfTests)] = function (self)
	StopSDL()
end

Test["StartSDL" .. tostring(indexOfTests)] = function (self)
	StartSDL(config.pathToSDL, config.ExitOnCrash)
end

Test["TestInitHMI" .. tostring(indexOfTests)] = function (self)
	self:initHMI()
end

Test["TestInitHMIOnReady" .. tostring(indexOfTests)] = function (self)
	self:initHMI_onReady()
end

Test["ConnectMobile" .. tostring(indexOfTests)] = function (self)
	self:connectMobile()
end

Test["StartSession" .. tostring(indexOfTests)] = function (self)
	self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
end
-- End Precondition.1

-- Begin Precondition.2
-- Description: ResgisterApp
Test["PreconditionRegisterApp" .. tostring(indexOfTests)] = function (self)
	-- body
	custom.preconditionHead()
	-- Register App
	custom.preconditionMessage("Register Application with vrSynonyms but without commands")

	local appWithvrSynonyms = {
	    syncMsgVersion =
	    {
	      majorVersion = 3,
	      minorVersion = 0
	    },
	    appName = "Test Application",
	    isMediaApplication = true,
	    languageDesired = 'EN-US',
	    hmiDisplayLanguageDesired = 'EN-US',
	    appHMIType = { "NAVIGATION" },
	    appID = "0000001",
	    deviceInfo =
	    {
	      os = "Android",
	      carrier = "Megafon",
	      firmwareRev = "Name: Linux, Version: 3.4.0-perf",
	      osVersion = "4.4.2",
	      maxNumberRFCOMMPorts = 1
	    },
	    vrSynonyms = {"Test", "Tester"}
	}

	self.mobileSession:StartService(7)
	:Do(function (_,data)
		local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", appWithvrSynonyms)

		EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
		:Do(function(_,data)
			HMIAppID = data.params.application.appID
		end)

		-- self.mobileSession:ExpectResponse(correlationId, { success = true })
		EXPECT_RESPONSE(correlationId, { success = true })

		EXPECT_NOTIFICATION("OnHMIStatus")
		:Timeout(mobileResponseTimeout)

		EXPECT_NOTIFICATION("OnPermissionsChange")
		:Timeout(mobileResponseTimeout)
  	end)
end
indexOfTests = indexOfTests + 1
-- End Precondition.2

function Test:AppSendsFirstSGPWithoutVrHelpItems2(...)
	-- body
	custom.testHead()
	custom.testMessage("App sends the very first SetGlobalProperties_request in current ignition cycle WITHOUT <VRHelp> and <VRHelpTitle> params")
	custom.info("Expected: SDL sends DEFAULT vrHelp constructed from App's synonyms and DEFAULT vrHelpTitle constructed from appName")

	local cid = self.mobileSession:SendRPC("SetGlobalProperties", custom.SGP_without_vr_help_start)
	
	EXPECT_HMICALL("UI.SetGlobalProperties",
	{
		vrHelpTitle = tostring(config.application1.registerAppInterfaceParams.appName),
		--UPDATED
		vrHelp = { 
					{
						text = config.application1.registerAppInterfaceParams.appName,
						position = 1
				}	},
		appID = self.applications[config.application1.registerAppInterfaceParams.appName]
	})
	:Do(function(_,data)
		--hmi side: sending UI.SetGlobalProperties response
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		actualVrHelpTitle = tostring(config.application1.registerAppInterfaceParams.appName)
		if data.params.vrHelp then
			if (data.params.vrHelp[1].text == "Test") and (data.params.vrHelp[2].text == "Tester") then
				return true
			end
		else
			self:FailTestCase("vrHelp is absent")
		end
	end)

	--UPDATED
	--hmi side: expect TTS.SetGlobalProperties request
	EXPECT_HMICALL("TTS.SetGlobalProperties",
										{
											helpPrompt = 
														{
															{
																text = default_HelpPromt,
																type = "TEXT"
														}	},																		
											appID = self.applications[config.application1.registerAppInterfaceParams.appName]
										})
	:Do(function(_,data)
		--hmi side: sending UI.SetGlobalProperties response
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
	end)		

	--mobile side: expect SetGlobalProperties response
	EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
	:Timeout(mobileResponseTimeout)

end


-- ///////////////////////////////////////////////////////////////////////////////////////////////////
-- App sends the very first SetGlobalProperties_request in current ignition cycle WITHOUT <VRHelp> and <VRHelpTitle> params
-- ///////////////////////////////////////////////////////////////////////////////////////////////////

-- Begin Precondition.1
-- Description: RestartSDL

function Test:UnregisterApp(...)
	-- body
	custom.preconditionHead()
	custom.preconditionMessage("Graceful unregister of Application")

	local cid = self.mobileSession:SendRPC("UnregisterAppInterface",{})

	EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
	:Timeout(2000)

end

Test["Stub"..tostring(indexOfTests)] = function (self)
	-- body
	custom.preconditionHead()
	custom.preconditionMessage("RestartSDL")
end
  
Test["StopSDL"..tostring(indexOfTests)] = function (self)
	StopSDL()
end

Test["StartSDL" .. tostring(indexOfTests)] = function (self)
	StartSDL(config.pathToSDL, config.ExitOnCrash)
end

Test["TestInitHMI" .. tostring(indexOfTests)] = function (self)
	self:initHMI()
end

Test["TestInitHMIOnReady" .. tostring(indexOfTests)] = function (self)
	self:initHMI_onReady()
end

Test["ConnectMobile" .. tostring(indexOfTests)] = function (self)
	self:connectMobile()
end

Test["StartSession" .. tostring(indexOfTests)] = function (self)
	self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
end
-- End Precondition.1

-- Begin Precondition.2
-- Description: ResgisterApp
Test["PreconditionRegisterApp" .. tostring(indexOfTests)] = function (self)
	-- body
	custom.preconditionHead()
	-- Register App
	custom.preconditionMessage("Register Application with vrSynonyms and commands containing vrSynonyms")

	local appWithvrSynonyms = {
	    syncMsgVersion =
	    {
	      majorVersion = 3,
	      minorVersion = 0
	    },
	    appName = "Test Application",
	    isMediaApplication = true,
	    languageDesired = 'EN-US',
	    hmiDisplayLanguageDesired = 'EN-US',
	    appHMIType = { "NAVIGATION" },
	    appID = "0000001",
	    deviceInfo =
	    {
	      os = "Android",
	      carrier = "Megafon",
	      firmwareRev = "Name: Linux, Version: 3.4.0-perf",
	      osVersion = "4.4.2",
	      maxNumberRFCOMMPorts = 1
	    },
	    vrSynonyms = {"Test", "Tester"}
	}

	self.mobileSession:StartService(7)
	:Do(function (_,data)
		local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", appWithvrSynonyms)

		EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
		:Do(function(_,data)
			HMIAppID = data.params.application.appID
		end)

		-- self.mobileSession:ExpectResponse(correlationId, { success = true })
		EXPECT_RESPONSE(correlationId, { success = true })

		EXPECT_NOTIFICATION("OnHMIStatus")
		:Timeout(mobileResponseTimeout)

		EXPECT_NOTIFICATION("OnPermissionsChange")
		:Timeout(mobileResponseTimeout)
  	end)
print ("HMIAppID = " ..HMIAppID)
end

indexOfTests = indexOfTests + 1
-- End Precondition.2

-- UPDATED: To Have AddCommand SUCCESS shall be allowed by policy, in NONE has DISALLOWED; Will be activated.
-- Description: Activation App by sending SDL.ActivateApp	
function Test:ActivateApp()
	--hmi side: sending SDL.ActivateApp request
	local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = HMIAppID})

	--hmi side: expect SDL.ActivateApp response
	EXPECT_HMIRESPONSE(RequestId)
	:Do(function(_,data)
		--In case when app is not allowed, it is needed to allow app
		if data.result.isSDLAllowed ~= true then
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

		end
	end)
			
	--mobile side: expect notification
	EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN" }) 
end

-- Begin Precondition.3	
-- Description: Adding Commands
function Test:PreconditionAddCommand(...)
	-- body
	--mobile side: sending AddCommand request
	local cid = self.mobileSession:SendRPC("AddCommand",
		{
			cmdID = 1,
			menuParams = 	
			{ 																
				menuName ="Options"
			}, 
			vrCommands = {"Options", "Settings"}
		})
	--hmi side: expect UI.AddCommand request
	EXPECT_HMICALL("UI.AddCommand", 
		{ 
			cmdID = 1,
			menuParams = 
			{ 											
				menuName ="Options"
			}
		})
	:Do(function(exp,data)
		--hmi side: send UI.AddCommand response
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
	end)
	
	--hmi side: expect VR.AddCommand request
	EXPECT_HMICALL("VR.AddCommand", 
		{ 
			cmdID = 1,							
			type = "Command",
			vrCommands = {"Options", "Settings"}
		})
	:Do(function(exp,data)
		--hmi side: sending VR.AddCommand response
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
	end)

	EXPECT_RESPONSE(cid, { success = true})			
	:Timeout(mobileResponseTimeout)
end
-- End Precondition.3	

function Test:AppSendsFirstSGPWithoutVrHelpItems3(...)
	-- body
	custom.testHead()
	custom.testMessage("App sends the very first SetGlobalProperties_request in current ignition cycle WITHOUT <VRHelp> and <VRHelpTitle> params")
	custom.info("Expected: SDL sends DEFAULT vrHelp constructed from App's synonyms and 1st synonyms of commands and DEFAULT vrHelpTitle")

	local cid = self.mobileSession:SendRPC("SetGlobalProperties", custom.SGP_without_vr_help_start)
	
	EXPECT_HMICALL("UI.SetGlobalProperties",
	{
		vrHelpTitle = tostring(config.application1.registerAppInterfaceParams.appName),
		--UPDATED
		vrHelp = { 
					{
						text = config.application1.registerAppInterfaceParams.appName,
						position = 1
				}	},
		appID = self.applications[config.application1.registerAppInterfaceParams.appName]
	})
	:Do(function(_,data)
		--hmi side: sending UI.SetGlobalProperties response
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		actualVrHelpTitle = tostring(config.application1.registerAppInterfaceParams.appName)
		if data.params.vrHelp then
			custom.info("Point0") 
			if 	(data.params.vrHelp[1].text == "Test") and 
				(data.params.vrHelp[2].text == "Tester") and 
				(data.params.vrHelp[3].text == "Options") 
				then
					custom.info("Point1") 
					custom.info(data.params.vrHelp[1].text)
					custom.info(data.params.vrHelp[2].text)
					custom.info(data.params.vrHelp[3].text)
					return true
				else
					self:FailTestCase("one or more from expected vrHelp items is(are) absent")
			end
		else
			self:FailTestCase("vrHelp is absent")
		end
	end)

	--UPDATED
	--hmi side: expect TTS.SetGlobalProperties request
	EXPECT_HMICALL("TTS.SetGlobalProperties",
						{
							helpPrompt = 
										{
											{
												text = default_HelpPromt,
												type = "TEXT"
											}			
										},																		
							appID = self.applications[config.application1.registerAppInterfaceParams.appName]
						})
	:Do(function(_,data)
		--hmi side: sending UI.SetGlobalProperties response
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
	end)		

	--mobile side: expect SetGlobalProperties response
	EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
	:Timeout(mobileResponseTimeout)

end

function Test:Sleep(...)
	-- body
	sleep(2)
end

-- ///////////////////////////////////////////////////////////////////////////////////////////////////
-- App sends next (not first) SetGlobalProperties_request in current ignition cycle WITH <VRHelp> and <VRHelpTitle> params
-- ///////////////////////////////////////////////////////////////////////////////////////////////////

function Test:AppSendsNextSGPWithVrHelpItemsAfterDefaultProperties(...)
	-- body
	custom.testHead()
	custom.testMessage("App sends next (not first) SetGlobalProperties_request in current ignition cycle WITH <VRHelp> and <VRHelpTitle> params")
	custom.info("Expected: SDL sends UI.SetGlobalProperties with vrHelp and vrHelpTitle from last SetGlobalProperties")

	local cid = self.mobileSession:SendRPC("SetGlobalProperties", custom.SGP_with_vr_help_next)
	
	-- custom.info(custom.SGP_with_vr_help_next.vrHelp)
	-- custom.info(custom.SGP_with_vr_help_next.vrHelpTitle)

	EXPECT_HMICALL("UI.SetGlobalProperties",
	{
		vrHelp = custom.SGP_with_vr_help_next.vrHelp,
		vrHelpTitle = custom.SGP_with_vr_help_next.vrHelpTitle,
		--UPDATED
		appID = self.applications[config.application1.registerAppInterfaceParams.appName]
	})
	:Do(function(_,data)
		--hmi side: sending UI.SetGlobalProperties response
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		actualVrHelpItem = custom.SGP_with_vr_help_next.vrHelp
		actualVrHelpTitle = custom.SGP_with_vr_help_next.vrHelpTitle
	end)

	--UPDATED
	--hmi side: expect TTS.SetGlobalProperties request
	EXPECT_HMICALL("TTS.SetGlobalProperties",
						{
							helpPrompt = 
										{
											{
												text = default_HelpPromt,
												type = "TEXT"
											}			
										},																		
							appID = self.applications[config.application1.registerAppInterfaceParams.appName]
						})
	:Do(function(_,data)
		--hmi side: sending UI.SetGlobalProperties response
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
	end)		

	--mobile side: expect SetGlobalProperties response
	EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
	:Timeout(mobileResponseTimeout)
end


function Test:Sleep(...)
	-- body
	sleep(2)
end

-- ///////////////////////////////////////////////////////////////////////////////////////////////////
-- App sends next (not first) SetGlobalProperties_request in current ignition cycle WITHOUT <VRHelp> and <VRHelpTitle> params
-- ///////////////////////////////////////////////////////////////////////////////////////////////////

function Test:AppSendsNextSGPWithoutVrHelpItems(...)
	-- body
	custom.testHead()
	custom.testMessage("App sends next (not first) SetGlobalProperties_request in current ignition cycle WITHOUT <VRHelp> and <VRHelpTitle> params")
	custom.info("Expected: SDL sends UI.SetGlobalProperties WITHOUT vrHelp and vrHelpTitle")

	local cid = self.mobileSession:SendRPC("SetGlobalProperties", custom.SGP_without_vr_help_next)
	
	-- custom.info(custom.SGP_without_vr_help_next.vrHelp)
	-- custom.info(custom.SGP_without_vr_help_next.vrHelpTitle)

	EXPECT_HMICALL("UI.SetGlobalProperties",
	{
		--UPDATED
		vrHelpTitle = config.application1.registerAppInterfaceParams.appName,
		
		-- Clarification is done: APPLINK-26638
		vrHelp = { 
					{
						text = config.application1.registerAppInterfaceParams.appName,
						position = 1
				}	},
		appID = self.applications[config.application1.registerAppInterfaceParams.appName]
	})
	:Do(function(_,data)
		--hmi side: sending UI.SetGlobalProperties response
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		
		--UPDATED
		--[[if data.params.vrHelp then
			self:FailTestCase("vrHelp is present")
		end
		if data.params.vrHelpTitle then
			custom.info("vrHelpTitle is: " .. tostring(data.params.vrHelpTitle))
			self:FailTestCase("vrHelpTitle is present")
		end]]
	end)

	--UPDATED
	--hmi side: expect TTS.SetGlobalProperties request
	EXPECT_HMICALL("TTS.SetGlobalProperties",
						{
							helpPrompt = 
										{
											{
												text = default_HelpPromt,
												type = "TEXT"
											}			
										},																		
							appID = self.applications[config.application1.registerAppInterfaceParams.appName]
						})
	:Do(function(_,data)
		--hmi side: sending UI.SetGlobalProperties response
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
	end)		

	--mobile side: expect SetGlobalProperties response
	EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
	:Timeout(mobileResponseTimeout)
end


-- ///////////////////////////////////////////////////////////////////////////////////////////////////
-- App successfully registers and satisfies all conditions for resumption
-- ///////////////////////////////////////////////////////////////////////////////////////////////////

-- Begin Precondition.1
-- Description: RestartSDL

Test["Stub"..tostring(indexOfTests)] = function (self)
	-- body
	custom.preconditionHead()
	custom.preconditionMessage("RestartSDL")
end

Test["SUSPEND"..tostring(indexOfTests)] = function (self)
	self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications", {reason = "SUSPEND"})
	EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLPersistenceComplete")
end
  
Test["StopSDL"..tostring(indexOfTests)] = function (self)
	
	StopSDL()
	
	self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications",{reason = "IGNITION_OFF"})

	-- hmi side: expect OnSDLClose notification
	EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLClose")

	-- hmi side: expect OnAppUnregistered notification
	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered")
	:Times(1)

end

Test["StartSDL" .. tostring(indexOfTests)] = function (self)
	StartSDL(config.pathToSDL, config.ExitOnCrash)
end

Test["TestInitHMI" .. tostring(indexOfTests)] = function (self)
	self:initHMI()
end

Test["TestInitHMIOnReady" .. tostring(indexOfTests)] = function (self)
	self:initHMI_onReady()
end

Test["ConnectMobile" .. tostring(indexOfTests)] = function (self)
	self:connectMobile()
end

Test["StartSession" .. tostring(indexOfTests)] = function (self)
	self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
end
indexOfTests = indexOfTests + 1
-- End Precondition.1

-- Begin Precondition.2
-- Description: ResgisterApp
function Test:GlobalPropertiesAfterResumption(...)
	-- body
	custom.testHead()

	-- Register App
	custom.testMessage("App successfully registers and satisfies all conditions for resumption")
	custom.info("Expected: SDL sends UI.SetGlobalProperties with stored App's global properties")

	self.mobileSession:StartService(7)
	:Do(function (_,data)
		local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)

		EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
		:Do(function(_,data)
			HMIAppID = data.params.application.appID
		end)

		-- self.mobileSession:ExpectResponse(correlationId, { success = true })
		EXPECT_RESPONSE(correlationId, { success = true })

		EXPECT_NOTIFICATION("OnHMIStatus")
		:Timeout(mobileResponseTimeout)
		:Times(2)

		EXPECT_NOTIFICATION("OnPermissionsChange")
		:Timeout(mobileResponseTimeout)

		EXPECT_HMICALL("UI.SetGlobalProperties",
		{
			vrHelp = actualVrHelpItem,
			vrHelpTitle = actualVrHelpTitle
		})
  	end)
end
-- End Precondition.2

-- ///////////////////////////////////////////////////////////////////////////////////////////////////
-- After resumption App sends next SetGlobalProperties WITHOUT vrHelp and vrHelpTitle
-- ///////////////////////////////////////////////////////////////////////////////////////////////////

function Test:AfterResumptionNextSGPWithoutVrHelpItems(...)
	-- body
	custom.testHead()
	custom.testMessage("After resumption App sends next SetGlobalProperties WITHOUT vrHelp and vrHelpTitle")
	custom.info("Expected: SDL omit vrHelp and vrHelpTitle in UI.SetGlobalProperties")

	local cid = self.mobileSession:SendRPC("SetGlobalProperties", custom.SGP_without_vr_help_next)

	EXPECT_HMICALL("UI.SetGlobalProperties",
	{
		vrHelpTitle = config.application1.registerAppInterfaceParams.appName,
		-- Clarification is done: APPLINK-26638
		vrHelp = { 
					{
						text = config.application1.registerAppInterfaceParams.appName,
						position = 1
				}	},
		appID = self.applications[config.application1.registerAppInterfaceParams.appName]
	})
	:Do(function(_,data)
		--hmi side: sending UI.SetGlobalProperties response
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		
		--UPDATED
		--[[if (data.params.vrHelp) or (data.params.vrHelpTitle) then
			self:FailTestCase("vrHelp or vrHelpTitle is present")
		end]]
	end)

	--UPDATED
	--hmi side: expect TTS.SetGlobalProperties request
	EXPECT_HMICALL("TTS.SetGlobalProperties",
						{
							helpPrompt = 
										{
											{
												text = default_HelpPromt,
												type = "TEXT"
											}			
										},																		
							appID = self.applications[config.application1.registerAppInterfaceParams.appName]
						})
	:Do(function(_,data)
		--hmi side: sending UI.SetGlobalProperties response
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
	end)		

	--mobile side: expect SetGlobalProperties response
	EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
	:Timeout(mobileResponseTimeout)
end


function Test:Sleep(...)
	-- body
	sleep(2)
end

-- ///////////////////////////////////////////////////////////////////////////////////////////////////
-- After resumption App sends next SetGlobalProperties WITH vrHelp and vrHelpTitle
-- ///////////////////////////////////////////////////////////////////////////////////////////////////

function Test:AfterResumptionNextSGPWithVrHelpItems(...)
	-- body
	custom.testHead()
	custom.testMessage("After resumption App sends next SetGlobalProperties WITH vrHelp and vrHelpTitle")
	custom.info("SDL sends UI.SetGlobalProperties with vrHelp and vrHelpTitle from last SetGlobalProperties")

	local cid = self.mobileSession:SendRPC("SetGlobalProperties", custom.SGP_with_vr_help_next)
	

	EXPECT_HMICALL("UI.SetGlobalProperties",
	{
		vrHelp = custom.SGP_with_vr_help_next.vrHelp,
		vrHelpTitle = custom.SGP_with_vr_help_next.vrHelpTitle,
		appID = self.applications[config.application1.registerAppInterfaceParams.appName]
	})
	:Do(function(_,data)
		--hmi side: sending UI.SetGlobalProperties response
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		actualVrHelpItem = custom.SGP_with_vr_help_next.vrHelp
		actualVrHelpTitle = custom.SGP_with_vr_help_next.vrHelpTitle
	end)

	--UPDATED
	--hmi side: expect TTS.SetGlobalProperties request
	EXPECT_HMICALL("TTS.SetGlobalProperties",
						{
							helpPrompt = 
										{
											{
												text = default_HelpPromt,
												type = "TEXT"
											}			
										},																		
							appID = self.applications[config.application1.registerAppInterfaceParams.appName]
						})
	:Do(function(_,data)
		--hmi side: sending UI.SetGlobalProperties response
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
	end)		

	--mobile side: expect SetGlobalProperties response
	EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
	:Timeout(mobileResponseTimeout)

end