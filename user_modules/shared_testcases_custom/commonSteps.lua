--This script contains common steps that are used in many test cases:
--1. ActivationApp
--2. DeactivateAppToNoneHmiLevel
--3. ChangeHMIToLimited
--4. RegisterTheSecondMediaApp
--5. ActivateTheSecondMediaApp_TheFirstAppIsBACKGROUND
--6. PutFile
--7. Unregister application
--8. Register application
--9. StartSession
--10. DeleteLogsFileAndPolicyTable
--11. Check file existence
--12. Respore original .ini file from appMain
--13. Check SDL path
--14. delete PT
--15. Restoring file from appMain folder
--16. Check directory existence
--17. DB query
---------------------------------------------------------------------------------------------

local commonSteps = {}
local mobile_session = require('mobile_session')
local SDLConfig = require('user_modules/shared_testcases/SmartDeviceLinkConfigurations')

---------------------------------------------------------------------------------------------


--1. ActivationApp: Activate default application
--Parameter: AppNumber is optional
function commonSteps:ActivationApp(AppNumber, TestCaseName)	

	local TCName
	if TestCaseName ==nil then
		TCName = "Activation_App"
	else
		TCName = TestCaseName
	end
	
	Test[TCName] = function(self)
		
		local Input_AppId
		if AppNumber == nil then
			Input_AppId = self.applications[config.application1.registerAppInterfaceParams.appName]
		else
			Input_AppId = Apps[AppNumber].appID
		end
		
		local deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

		--hmi side: sending SDL.ActivateApp request
		local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = Input_AppId})
		EXPECT_HMIRESPONSE(RequestId)
		:Do(function(_,data)
			if
				data.result.isSDLAllowed ~= true then
				local RequestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})
				
				--hmi side: expect SDL.GetUserFriendlyMessage message response
				--TODO: update after resolving APPLINK-16094.
				--EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
				EXPECT_HMIRESPONSE(RequestId)
				:Do(function(_,data)						
					--hmi side: send request SDL.OnAllowSDLFunctionality
					--self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {allowed = true, source = "GUI", device = {id = config.deviceMAC, name = "127.0.0.1"}})
					self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {allowed = true, source = "GUI", device = {id = deviceMAC, name = "127.0.0.1"}})

					--hmi side: expect BasicCommunication.ActivateApp request
					EXPECT_HMICALL("BasicCommunication.ActivateApp")
					:Do(function(_,data)
						--hmi side: sending BasicCommunication.ActivateApp response
						self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
					end)
					:Times(AnyNumber())
				end)

			end
		end)
		
		--mobile side: expect notification
		EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"}) 
	end
end
---------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------


--1. ActivationApp: Activate default application
--Parameter: AppNumber is optional
function commonSteps:ActivationAppGenivi(AppId, TestCaseName)	

	local TCName
	if TestCaseName ==nil then
		TCName = "Activation_App"
	else
		TCName = TestCaseName
	end
	
	Test[TCName] = function(self)

		local Input_AppId
		
		if AppId ~= nil then
			Input_AppId = AppId
		else
			Input_AppId = self.applications[config.application1.registerAppInterfaceParams.appName]
		end

		--hmi side: sending SDL.ActivateApp request
		local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = Input_AppId})
		EXPECT_HMIRESPONSE(RequestId)
		
		--mobile side: expect notification
		EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"}) 
	end
end
---------------------------------------------------------------------------------------------

--2. DeactivateAppToNoneHmiLevel
function commonSteps:DeactivateAppToNoneHmiLevel(TestCaseName)
	local TCName
	if TestCaseName ==nil then
		TCName = "Deactivate_App_To_None_Hmi_Level"
	else
		TCName = TestCaseName
	end
	
	Test[TCName] = function(self)
	
		--hmi side: sending BasicCommunication.OnExitApplication notification
		self.hmiConnection:SendNotification("BasicCommunication.OnExitApplication", {appID = self.applications["Test Application"], reason = "USER_EXIT"})

		EXPECT_NOTIFICATION("OnHMIStatus", { systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
	end	
end


--3. ChangeHMIToLimited
function commonSteps:ChangeHMIToLimited(TestCaseName)
	local TCName
	if TestCaseName ==nil then
		TCName = "Change_App_To_Limited"
	else
		TCName = TestCaseName
	end
	
	Test[TCName] = function(self)

		--hmi side: sending BasicCommunication.OnAppDeactivated request
		local cid = self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated",
		{
			appID = self.applications["Test Application"],
			reason = "GENERAL"
		})

		--mobile side: expect OnHMIStatus notification
		EXPECT_NOTIFICATION("OnHMIStatus",{hmiLevel = "LIMITED", systemContext = "MAIN", audioStreamingState = "AUDIBLE"})
	end

end

--4. DeactivateToBackground
function commonSteps:DeactivateToBackground(TestCaseName)
	local TCName
	if TestCaseName ==nil then
		TCName = "Deactivate_App_To_Background"
	else
		TCName = TestCaseName
	end
	
	Test[TCName] = function(self)

		--hmi side: sending BasicCommunication.OnAppDeactivated notification
		self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", {appID = self.applications["Test Application"], reason = "GENERAL"})

		EXPECT_NOTIFICATION("OnHMIStatus",
			{ systemContext = "MAIN", hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE"})
	end
end
			

-- Precondition 1: Opening new session
function commonSteps:precondition_AddNewSession(TestCaseName)
	local TCName
	if TestCaseName ==nil then
		TCName = "Precondition_Add_New_Session"
	else
		TCName = TestCaseName
	end
	
	Test[TCName] = function(self)
	
	  -- Connected expectation
		Test.mobileSession2 = mobile_session.MobileSession(Test,Test.mobileConnection)
		
		Test.mobileSession2:StartService(7)
	end	
end	

--4. RegisterTheSecondMediaApp
function commonSteps:RegisterTheSecondMediaApp()		
	
	Test["Register_The_Second_Media_App"]  = function(self)

		--mobile side: RegisterAppInterface request 
		local CorIdRAI = self.mobileSession2:SendRPC("RegisterAppInterface",
													{
														syncMsgVersion = 
														{ 
															majorVersion = 3,
															minorVersion = 0,
														}, 
														appName ="SPT2",
														isMediaApplication = true,
														languageDesired ="EN-US",
														hmiDisplayLanguageDesired ="EN-US",
														appID ="2",
														ttsName = 
														{ 
															{ 
																text ="SyncProxyTester2",
																type ="TEXT",
															}, 
														}, 
														vrSynonyms = 
														{ 
															"vrSPT2",
														},
														appHMIType = {"NAVIGATION", "COMMUNICATION"}
					
													}) 
	 
		--hmi side: expect BasicCommunication.OnAppRegistered request
		EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
		{
			application = 
			{
				appName = "SPT2"
			}
		})
		:Do(function(_,data)
			appId2 = data.params.application.appID
		end)
		
		--mobile side: RegisterAppInterface response 
		self.mobileSession2:ExpectResponse(CorIdRAI, { success = true, resultCode = "SUCCESS"})
			:Timeout(2000)

		self.mobileSession2:ExpectNotification("OnHMIStatus",{hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
	end
end



--5. ActivateTheSecondMediaApp_TheFirstAppIsBACKGROUND
---------------------------------------------------------------------------------------------
function commonSteps:ActivateTheSecondMediaApp()		
	
	Test["Activate_The_Second_Media_App"]  = function(self)

		local deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
	
		--HMI send ActivateApp request			
		local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = appId2})
		EXPECT_HMIRESPONSE(RequestId)
		:Do(function(_,data)

			if data.result.isSDLAllowed ~= true then
				local RequestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})
				EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
				:Do(function(_,data)
					--hmi side: send request SDL.OnAllowSDLFunctionality
					self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {allowed = true, source = "GUI", device = {id = deviceMAC, name = "127.0.0.1"}})
				end)

				EXPECT_HMICALL("BasicCommunication.ActivateApp")
				:Do(function(_,data)
					self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
				end)
				:Times(AnyNumber())
			else
				self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
			end
		end)

		self.mobileSession2:ExpectNotification("OnHMIStatus", {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"}) 
		:Timeout(12000)
		
		self.mobileSession:ExpectNotification("OnHMIStatus", {hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"}) 
	end	
end


--6. PutFile
function commonSteps:PutFile(testCaseName, fileName)

	Test[testCaseName] = function(self)

		--mobile request
		local CorIdPutFile = self.mobileSession:SendRPC(
								"PutFile",
								{
									syncFileName = fileName,
									fileType = "GRAPHIC_PNG",
									persistentFile = false,
									systemFile = false,	
								}, "files/icon.png")

		--mobile response
		EXPECT_RESPONSE(CorIdPutFile, { success = true, resultCode = "SUCCESS"})
		:Timeout(12000)
		
	end
			
end		
---------------------------------------------------------------------------------------------


--7. Unregister application
function commonSteps:UnregisterApplication(TestCaseName)
	local TCName
	if TestCaseName ==nil then
		TCName = "Unregister_Application"
	else
		TCName = TestCaseName
	end
	
	Test[TCName] = function(self)		
	
		local cid = self.mobileSession:SendRPC("UnregisterAppInterface",{})

		EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
		:Timeout(2000)
	end 
end	

--8. Register application
function commonSteps:RegisterAppInterface(TestCaseName)
	local TCName
	if TestCaseName ==nil then
		TCName = "Register_App_Interface"
	else
		TCName = TestCaseName
	end
	
	Test[TCName] = function(self)		
			
		CorIdRegister = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
		strAppName = config.application1.registerAppInterfaceParams.appName

		--hmi side: expect BasicCommunication.OnAppRegistered request
		EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
		{
			application = 
			{
				appName = strAppName
			}
		})
		:Do(function(_,data)
			self.appName = data.params.application.appName
			self.applications[strAppName] = data.params.application.appID
		end)
		
		--mobile side: expect response
		self.mobileSession:ExpectResponse(CorIdRegister)
		:Timeout(12000)

		--mobile side: expect notification
		self.mobileSession:ExpectNotification("OnHMIStatus", 
		{ 
			systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"
		})
		:Timeout(12000)
	end
end	

--9. StartSession
function commonSteps:StartSession(TestCaseName)
	local TCName
	if TestCaseName ==nil then
		TCName = "StartSession"
	else
		TCName = TestCaseName
	end
	
	Test[TCName] = function(self)		
	
		self.mobileSession = mobile_session.MobileSession(
		self,
		self.mobileConnection)
	end
end


--10. DeleteLogsFileAndPolicyTable
function commonSteps:DeleteLogsFileAndPolicyTable(DeleteLogsFlags)

	self:DeletePolicyTable()

	if DeleteLogsFlags == nil then
		DeleteLogsFlags = true
	end

	if DeleteLogsFlags == true then
		--Delete app_info.dat and log files
		self:DeleteLogsFiles()
	end
	
end

--10. DeleteLogsFile
function commonSteps:DeleteLogsFiles()
	self:CheckSDLPath()

	--Delete app_info.dat and log files
	if self:file_exists(config.pathToSDL .. "app_info.dat") == true then
		os.remove(config.pathToSDL .. "app_info.dat")
	end

	if self:file_exists(config.pathToSDL .. "SmartDeviceLinkCore.log") == true then
		os.remove(config.pathToSDL .. "SmartDeviceLinkCore.log")
	end

	if self:file_exists(config.pathToSDL .. "TransportManager.log") == true then
		os.remove(config.pathToSDL .. "TransportManager.log")
	end

	if self:file_exists(config.pathToSDL .. "ProtocolFordHandling.log") == true then
		os.remove(config.pathToSDL .. "ProtocolFordHandling.log")
	end

	if self:file_exists(config.pathToSDL .. "HmiFrameworkPlugin.log") == true then
		os.remove(config.pathToSDL .. "HmiFrameworkPlugin.log")
	end
	
end

--11. Check file existence
function commonSteps:file_exists(name)
   	local f=io.open(name,"r")

   	if f ~= nil then 
   		io.close(f)
   		return true
   	else 
   		return false 
   	end
end

--12. Respore original .ini file
function commonSteps:RestoreIniFile()

	self:RestoreFileFromAppMainFolder("smartDeviceLink.ini")

end

--13. Check SDL path
function commonSteps:CheckSDLPath()
	--Verify config.pathToSDL
	findresultFirstCharacters = string.match (config.pathToSDL, '^%.%/')
	if findresultFirstCharacters == "./" then
		local CurrentFolder = assert( io.popen( "pwd" , 'r'))
		local CurrentFolderPath = CurrentFolder:read( '*l' )

		PathUsingCurrentFolder = string.match (config.pathToSDL, '[^%.]+')

		config.pathToSDL = CurrentFolderPath .. PathUsingCurrentFolder

	end

	findresultLastCharacters = string.find (config.pathToSDL, '.$')
	if string.sub(config.pathToSDL,findresultLastCharacters) ~= "/" then
		config.pathToSDL = config.pathToSDL..tostring("/")
	end
end

--14. delete PT 
function commonSteps:DeletePolicyTable()

	self:CheckSDLPath()

	if self:file_exists(config.pathToSDL .. SDLConfig:GetValue("AppStorageFolder") .. "/policy.sqlite") == true then
		--Delete policy table 
		os.remove(config.pathToSDL .. SDLConfig:GetValue("AppStorageFolder") .. "/policy.sqlite")
	elseif 
		self:file_exists(config.pathToSDL .. "policy.sqlite") == true then
		--Delete policy table 
		os.remove(config.pathToSDL .. "policy.sqlite")
	else
		print( " \27[33m commonSteps:DeletePolicyTable : policy.sqlite is not found \27[0m " )
	end
	
end

-- 15. Restoring file from appMain folder
function commonSteps:RestoreFileFromAppMainFolder(fileName)

	self:CheckSDLPath()

	str = tostring(config.pathToSDL)

	local PathToSDLWihoutBin =  string.gsub(str, "bin/", "")

	OriginalIniFile = PathToSDLWihoutBin .. "src/appMain/" .. tostring(fileName)

	os.execute( " cp " .. tostring(OriginalIniFile) .. " " .. tostring(config.pathToSDL) .. "" )
end

-- 16. Check directory existence 
function commonSteps:Directory_exist(DirectoryPath)
    if type( DirectoryPath ) ~= 'string' then
            error('Directory_exist : Input parameter is not string : ' .. type(DirectoryPath) )
            return false
    else
        local response = os.execute( 'cd ' .. DirectoryPath .. " 2> /dev/null" )
        -- ATf returns as result of 'os.execute' boolean value, lua interp returns code. if conditions process result as for lua enterp and for ATF.
        if response == nil or response == false then
            return false
        end
        if response == true then
            return true
        end
        return response == 0;
    end
end

-- 17. DB query
local function Exec(cmd) 
    local function trim(s)
      return s:gsub("^%s+", ""):gsub("%s+$", "")
    end
    local aHandle = assert(io.popen(cmd , 'r'))
    local output = aHandle:read( '*a' )
    return trim(output)
end

function commonSteps:DataBaseQuery(DBQueryV)

    self:CheckSDLPath()

    -- Storage path
	local StoragePath = SDLConfig:GetValue("AppStorageFolder")
	if 
		not StoragePath or
		StoragePath == "" then
		StoragePath = 'storage'
	end

    local function query_success(output)
        if output == "" or DBQueryValue == " " then return false end
        local f, l = string.find(output, "Error:")
        if f == 1 then return false end
        return true;
    end
    for i=1,10 do 
        local DBQuery = 'sqlite3 ' .. config.pathToSDL .. StoragePath .. '/policy.sqlite "' .. tostring(DBQueryV) .. '"'
        DBQueryValue = Exec(DBQuery)
        if query_success(DBQueryValue) then
            return DBQueryValue
        end
        os.execute(" sleep 1 ")
    end
    return false
end

return commonSteps

