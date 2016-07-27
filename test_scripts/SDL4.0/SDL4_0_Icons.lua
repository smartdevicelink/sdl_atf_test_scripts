--------------------------------------------------------------------------------
-- Preconditions
--------------------------------------------------------------------------------
local Preconditions = require('user_modules/shared_testcases/commonPreconditions')

--------------------------------------------------------------------------------
-- Set 4 protocol as default for script
config.defaultProtocolVersion = 4

--------------------------------------------------------------------------------
--Precondition: preparation connecttest_icons.lua
Preconditions:Connecttest_without_ExitBySDLDisconnect_WithoutOpenConnectionRegisterApp("connecttest_icons.lua")

Test = require('user_modules/connecttest_icons')
require('cardinalities')

local tcp = require('tcp_connection')
local mobile_session = require('mobile_session')
local file_connection  = require('file_connection')
local mobile  = require('mobile_connection')
local events = require('events')

require('user_modules/AppTypes')

config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

local function userPrint( color, message)
  print ("\27[" .. tostring(color) .. "m " .. tostring(message) .. " \27[0m")
end

local PathToAppFolder
local SDLStoragePath

local function DelayedExp(time)
  local event = events.Event()
  event.matches = function(self, e) return self == e end
  EXPECT_EVENT(event, "Delayed event")
    :Timeout(time + 1000)
  RUN_AFTER(function()
              RAISE_EVENT(event, event)
            end, time)
end

-- Sending OnHMIStatus notification form mobile application
local function SendingOnHMIStatusFromMobile(self, level, audibleState, sessionName )
	
	level = level or "FULL"
	audibleState = audibleState or "NOT_AUDIBLE"
	sessionName = sessionName or self.mobileSession

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
local function AppRegistration(self, registerParams, sessionName, iconValue)

	local audibleStateRegister

	if sessionName == nil then
		sessionName = self.mobileSession
	end

    local CorIdRegister = sessionName:SendRPC("RegisterAppInterface", registerParams)

    EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
    {
      application = 
      {
      appName = registerParams.appName,
      icon = iconValue
      }
    })
    :Do(function(_,data)
        self.applications[registerParams.appName] = data.params.application.appID
    end)
    :ValidIf(function(_,data)
    	if iconValue == nil then
    		if data.params.application.icon then
    			userPrint(31, "BC.OnAppRegistered notification contains icon parameter with value '" .. tostring(data.params.application.icon) .. "'")
    			return false
    		end
    	else 
    		return true
    	end
    end)

    sessionName:ExpectResponse(CorIdRegister, { success = true, resultCode = "SUCCESS" })

end

-- Check file existence 
function file_exists(name, messages)
   	local f=io.open(name,"r")

   	if f ~= nil then 
   		io.close(f)
   		if messages == true then
   			userPrint(32, "File " .. tostring(name) .. " exists")
   		end
   		return true 
   	else 
   		if messages == true then
   			userPrint(31, "File " .. tostring(name) .. " does not exist")
   		end
   		return false 
   	end
end

--Check pathToSDL, in case last symbol is not'/' add '/' 
local function checkSDLPathValue()
	findresult = string.find (config.pathToSDL, '.$')

	if string.sub(config.pathToSDL,findresult) ~= "/" then
		config.pathToSDL = config.pathToSDL..tostring("/")
	end 
end

-- generating path to app folder
local function PathToAppFolderFunction(appID)
	checkSDLPathValue()
	
	local path = config.pathToSDL .. tostring("storage/") .. tostring(appID) .. "_" .. tostring(config.deviceMAC) .. "/"

	return path
end

-- Check direcrory existence 
local function Directory_exist(DirectoryPath)
	local returnValue

	local Command = assert( io.popen(  "[ -d " .. tostring(DirectoryPath) .. " ] && echo \"Exist\" || echo \"NotExist\"" , 'r'))
	os.execute("sleep 0.5")
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

-- Stop SDL, optionaly changing values of SDL4 feature params, optionaly deleting used AppIconsFolder folders,  start SDL, HMI initialization, create mobile connection
local function SetEnableProtocol4ValueInIniFileTotrue(self, prefix,  EnableProtocol4, AppIconsFolder, AppIconsFolderValueToReplace, AppIconsFolderMaxSize, AppIconsFolderMaxSizeValueToReplace, AppIconsAmountToRemove, AppIconsAmountToRemoveValueToReplace, RemoveAppIconsFolder )

	checkSDLPathValue()

	SDLStoragePath = config.pathToSDL .. "storage/"

	local SDLini = config.pathToSDL .. tostring("smartDeviceLink.ini")

	Test["StopSDL_" .. tostring(prefix)] = function(self)
		StopSDL()
	end

	if EnableProtocol4 == true then
		Test["Precondition_EnableSDL40FeatureValueInIniFile_" .. tostring(prefix)] = function(self)
			local StringToReplace = "EnableProtocol4 = true\n"
			f = assert(io.open(SDLini, "r"))
			if f then
				fileContent = f:read("*all")
					local MatchResult = string.match(fileContent, "EnableProtocol4%s-=%s-%a-%s-\n")
					if MatchResult ~= nil then
						fileContentUpdated  =  string.gsub(fileContent, MatchResult, StringToReplace)
						f = assert(io.open(SDLini, "w"))
						f:write(fileContentUpdated)
					else 
						userPrint(31, "Finding of 'EnableProtocol4 = value' is failed. Expect string finding and replacing of value to true")
					end
				f:close()
			end
		end
	end

	if AppIconsFolder == true then
		Test["Precondition_AppIconsFolderChange_" .. tostring(prefix)] = function(self)
			local StringToReplace = "AppIconsFolder = " .. tostring(AppIconsFolderValueToReplace) .. "\n"
			f = assert(io.open(SDLini, "r"))
			if f then
				fileContent = f:read("*all")
					local MatchResult = string.match(fileContent, "AppIconsFolder%s-=%s-.-%s-\n")
					if MatchResult ~= nil then
						fileContentUpdated  =  string.gsub(fileContent, MatchResult, StringToReplace)
						f = assert(io.open(SDLini, "w"))
						f:write(fileContentUpdated)
					else 
						userPrint(31, "Finding of 'AppIconsFolder = value' is failed. Expect string finding and replacing of value to " .. tostring(AppIconsFolderValueToReplace))
					end
				f:close()
			end
		end
	end

	if AppIconsFolderMaxSize == true then
		Test["Precondition_AppIconsFolderMaxSizeChange_" .. tostring(prefix)] = function(self)
			local StringToReplace = "AppIconsFolderMaxSize = " .. tostring(AppIconsFolderMaxSizeValueToReplace) .. "\n"
			f = assert(io.open(SDLini, "r"))
			if f then
				fileContent = f:read("*all")
					local MatchResult = string.match(fileContent, "AppIconsFolderMaxSize%s-=%s-.-%s-\n")
					if MatchResult ~= nil then
						fileContentUpdated  =  string.gsub(fileContent, MatchResult, StringToReplace)
						f = assert(io.open(SDLini, "w"))
						f:write(fileContentUpdated)
					else 
						userPrint(31, "Finding of 'AppIconsFolderMaxSize = value' is failed. Expect string finding and replacing of value to " .. tostring(AppIconsFolderMaxSizeValueToReplace))
					end
				f:close()
			end
		end
	end

	if AppIconsAmountToRemove == true then
		Test["Precondition_AppIconsAmountToRemoveChange_" .. tostring(prefix)] = function(self)
			local StringToReplace = "AppIconsAmountToRemove = " .. tostring(AppIconsAmountToRemoveValueToReplace) .. "\n"
			f = assert(io.open(SDLini, "r"))
			if f then
				fileContent = f:read("*all")
					local MatchResult = string.match(fileContent, "AppIconsAmountToRemove%s-=%s-.-%s-\n")
					if MatchResult ~= nil then
						fileContentUpdated  =  string.gsub(fileContent, MatchResult, StringToReplace)
						f = assert(io.open(SDLini, "w"))
						f:write(fileContentUpdated)
					else 
						userPrint(31, "Finding of 'AppIconsAmountToRemove = value' is failed. Expect string finding and replacing of value to " .. tostring(AppIconsAmountToRemoveValueToReplace))
					end
				f:close()
			end
		end
	end

	if RemoveAppIconsFolder == true then
		Test["Precondition_RemoveAppIconsFolders_" .. tostring(prefix)] = function(self)
			local AddedFolderInScript = {"storage/IconsFolder", "AnotherFolder", "Icons"}
			for i=1,#AddedFolderInScript do
				local ExistResult = Directory_exist( tostring(config.pathToSDL .. AddedFolderInScript[i]))
				if ExistResult == true then
					local RmAppIconsFolder  = assert( os.execute( "rm -rf " .. tostring(config.pathToSDL .. AddedFolderInScript[i] )))
					if RmAppIconsFolder ~= true then
						userPrint(31, tostring(AddedFolderInScript[i]) .. " folder is not deleted")
					end
				end
			end
			DelayedExp(1000)
		end
	end


	Test["StartSDL_" .. tostring(prefix)] = function(self)
		StartSDL(config.pathToSDL, config.ExitOnCrash)
		DelayedExp(1000)
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

-- Sending from mobile 'FULL' notification to SDL, expectation OnSystemRequest(QUERY_APPS), Sending SystemRequest (QUERY_APPS) with json file
local function OnSystemRequestQueryApps(self, sessionName, level, audibleState, jsonName)


	jsonName = jsonName or "correctJSON.json"

	SendingOnHMIStatusFromMobile(self, level, audibleState, sessionName)

	sessionName:ExpectNotification("OnSystemRequest")
		:Do(function(_,data)
			if data.payload.requestType == "QUERY_APPS" then

				local CorIdSystemRequest = sessionName:SendRPC("SystemRequest",
	          	{
	            	requestType = "QUERY_APPS", 
	            	fileName = jsonName
	          	},
	          	"files/jsons/QUERRY_jsons/" .. tostring(jsonName))

	          	-- mobile side: SystemRequest response
	          	sessionName:ExpectResponse(CorIdSystemRequest, { success = true, resultCode = "SUCCESS"})
	        end
		end)
		:ValidIf(function(_,data)
			if data.payload.requestType == "QUERY_APPS" then
	          	return true
	        elseif data.payload.requestType == "LOCK_SCREEN_ICON_URL" then
        		return true
	        else
	        	userPrint(31, " OnSystemRequest notificaton came with unexpected requestType ".. tostring(data.payload.requestType))
	        	return false
	        end
		end)
		:Times(Between(1,2))

end

-- Getting file size
function fsize (file)
	f = io.open(file,"r")
  	local current = f:seek()
  	local size = f:seek("end")
  	f:seek("set", current)
  	f:close()
  	return size
end

-- Getting folder size
local function DSize(PathToFolder)
	local aHandle = assert( io.popen( "du -sh " ..  tostring(PathToFolder), 'r'))
	local Buff = aHandle:read( '*l' )
	local SizeFolder, MeasurementUnits = Buff:match("([^%a]+)(%a)")

	if MeasurementUnits == "K" then
		SizeFolder  =  string.gsub(SizeFolder, ",", ".")
		SizeFolder = tonumber(SizeFolder)
		SizeFolderInBytes = SizeFolder * 1024
	elseif
		MeasurementUnits == "M" then
			SizeFolder  =  string.gsub(SizeFolder, ",", ".")
			SizeFolder = tonumber(SizeFolder)
			SizeFolderInBytes = SizeFolder * 1048576
	end
	return SizeFolderInBytes
end

-- Full AppIconsFolder
local function FullAppIconsFolder( AppIconsFolder )
	local SizeAppIconsFolderInBytes = DSize(config.pathToSDL .. tostring(AppIconsFolder))
	SizeToFull = 1048576 - SizeAppIconsFolderInBytes
	local i =1

	while SizeToFull > 326360 do
		os.execute("sleep " .. tonumber(10))
		local CopyFileToAppIconsFolder = assert( os.execute( "cp files/icon.png " .. tostring(config.pathToSDL) .. tostring(AppIconsFolder) .. "/icon" .. tostring(i) ..".png"))
		i = i + 1
		if CopyFileToAppIconsFolder ~= true then
			userPrint(31, " Files is not copied into " .. tostring(AppIconsFolder))
		end
		SizeAppIconsFolderInBytes = DSize(config.pathToSDL .. tostring(AppIconsFolder))		
		SizeToFull = 1048576 - SizeAppIconsFolderInBytes 
		if i > 50 then 
			userPrint(31, " Loop is breaked because of a lot of iterations ")
			break
		end

	end
end

-- Start session, register app, set icon for app
local function StartSessionRegisterAppSetIcon(self, RAIParameters , fileForIcon)

	if fileForIcon == nil then
		fileForIcon = "icon.png"
	end

	self.mobileSession= mobile_session.MobileSession(
    self,
    self.mobileConnection)

    self.mobileSession.version = 4

    self.mobileSession:StartService(7)
    :Do(function(_,data)
		AppRegistration(self, RAIParameters)

		EXPECT_NOTIFICATION("OnHMIStatus", { systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
			:DoOnce(function(_,data)
				OnSystemRequestQueryApps(self, self.mobileSession)

				local cidPutFile = self.mobileSession:SendRPC("PutFile",
				{
					syncFileName = "iconFirstApp.png",
					fileType = "GRAPHIC_PNG",
					persistentFile = false,
					systemFile = false
				}, "files/" .. tostring(fileForIcon))

				EXPECT_RESPONSE(cidPutFile, { success = true, resultCode = "SUCCESS" })
				:Do(function(_,data)
					local cidSetAppIcon = self.mobileSession:SendRPC("SetAppIcon",{ syncFileName = "iconFirstApp.png" })
					--hmi side: expect UI.SetAppIcon request

					PathToAppFolder = PathToAppFolderFunction(RAIParameters.appID)

					EXPECT_HMICALL("UI.SetAppIcon",
						{
							syncFileName = 
							{
								imageType = "DYNAMIC",
								value = PathToAppFolder .. "iconFirstApp.png"
							}				
						})
						:Do(function(_,data)
							--hmi side: sending UI.SetAppIcon response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
						
					--mobile side: expect SetAppIcon response
					EXPECT_RESPONSE(cidSetAppIcon, { resultCode = "SUCCESS", success = true })
						:ValidIf(function(_,data)

							CheckFunction()

						end)
				end)
			end)
		DelayedExp(2000)
	end)
end

userPrint(33, " Because of ATF defect APPLINK-16052 check of deviceInfo params in BC.UpdateAppList is commented ")

--Precondtion: Set EnableProtocol4 value to true, AppIconsFolder to storage in .ini file, remove isons folders
SetEnableProtocol4ValueInIniFileTotrue(self, "BringValuesInIniFileToRequired", true, true, "storage", true, "104857600", true, "1", true)

--===================================================================================--
-- Check that SDL find icons from AppIconsFolder
--===================================================================================--

local RAIParams
function Test:SaveIconInAppIconsFolderWithAppIdName()
	userPrint(34, "=================================== Test  Case ===================================")

	RAIParams = config.application1.registerAppInterfaceParams
	RAIParams.appName = "Awesome Music App"
	RAIParams.appID = "853426"

	PathToAppFolder = PathToAppFolderFunction(RAIParams.appID)

	self.mobileSession= mobile_session.MobileSession(
    self,
    self.mobileConnection)

    self.mobileSession.version = 4

    self.mobileSession:StartService(7)
    :Do(function(_,data)
		AppRegistration(self, RAIParams)

		EXPECT_NOTIFICATION("OnHMIStatus", { systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
		:DoOnce(function(_,data)

			OnSystemRequestQueryApps(self, self.mobileSession)

			local cidPutFile = self.mobileSession:SendRPC("PutFile",
				{
					syncFileName = "icon.png",
					fileType = "GRAPHIC_PNG",
					persistentFile = false,
					systemFile = false
				}, "files/icon.png")

			EXPECT_RESPONSE(cidPutFile, { success = true, resultCode = "SUCCESS" })
			:Do(function(_,data)
				local cidSetAppIcon = self.mobileSession:SendRPC("SetAppIcon",{ syncFileName = "icon.png" })
					--hmi side: expect UI.SetAppIcon request
					EXPECT_HMICALL("UI.SetAppIcon",
						{
							syncFileName = 
							{
								imageType = "DYNAMIC",
								value = PathToAppFolder .. "icon.png"
							}				
						})
						:Do(function(_,data)
							--hmi side: sending UI.SetAppIcon response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
					
					--mobile side: expect SetAppIcon response
					EXPECT_RESPONSE(cidSetAppIcon, { resultCode = "SUCCESS", success = true })
						:ValidIf(function(_,data)
							local FileToCheck = SDLStoragePath .. tostring(RAIParams.appID)
							local fileExistsResult = file_exists(FileToCheck, true)
							return fileExistsResult
						end)
			end)
		end)

	end)
end


function Test:SettingIconToAppAfterReregistration()
	userPrint(34, "=================================== Test  Case ===================================")

	--mobile side: UnregisterAppInterface request 
  	local CorIdURAI = self.mobileSession:SendRPC("UnregisterAppInterface", {})

  	--hmi side: expected  BasicCommunication.OnAppUnregistered
  	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = self.applications[RAIParams.appName], unexpectedDisconnect = false})

  	--mobile side: UnregisterAppInterface response 
  	self.mobileSession:ExpectResponse(CorIdURAI, {success = true , resultCode = "SUCCESS"})
  		:Do(function(_,data)
  			AppRegistration(self, RAIParams, self.mobileSession, SDLStoragePath .. tostring(RAIParams.appID))

  			EXPECT_NOTIFICATION("OnHMIStatus", { systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
  				:DoOnce(function()
  					OnSystemRequestQueryApps(self, self.mobileSession)
  				end)

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
				      	icon = SDLStoragePath .. tostring(RAIParams.appID)
				   	}
				}},
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
				      	icon = SDLStoragePath .. tostring(RAIParams.appID)
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
				:Times(2)
			 	:ValidIf(function(exp,data)
			 		if 
			 			exp.occurences == 1 then
			                if #data.params.applications == 1 then
			                  	return true
			              	else 
			                    userPrint( 31, "Application array in BasicCommunication.UpdateAppList contains "..tostring(#data.params.applications)..", expected 1" )
			                    return false
			              	end
			 		elseif
			 			exp.occurences == 2 then
			                if #data.params.applications == 3 then
			                  	return true
			              	else 
			                    userPrint( 31, "Application array in BasicCommunication.UpdateAppList contains "..tostring(#data.params.applications)..", expected 3" )
			                    return false
			              	end
			        end
			  	end)
				:Do(function(_,data)
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
					for i=1, #data.params.applications do
						self.applications[data.params.applications[i].appName] = data.params.applications[i].appID
			      	end
			  	end)
		end)
  		:ValidIf(function()
  			local IconToCheck = PathToAppFolder .. "icon.png"
  			local AppIdIconToCheck = SDLStoragePath .. tostring(RAIParams.appID)
			local IconExistsResult = file_exists(IconToCheck, false)
			local AppIdIconExistsResult = file_exists(AppIdIconToCheck, false)

			local errorValue = false 

			if IconExistsResult == true then
				userPrint(31, " 'icon.png' is not deleted after unregistration ")
				errorValue = true
			end
			if
				AppIdIconExistsResult == false then
				userPrint(31, " '" .. tostring(RAIParams.appID) .. "' is deleted after unregistration ")
				errorValue = true
			end

			if errorValue == true then
				return false
			else
				userPrint(32, " 'icon.png' is deleted, '" .. tostring(RAIParams.appID) .. "' is not deleted  after unregistration ")
				return true
			end

  		end)

  	DelayedExp(2000)

end

function Test:Postcondition_UnregisterApp_SettingIconToAppAfterReregistration()
	UnregisterAppInterface_Success(self, self.mobileSession, self.applications[RAIParams.appName])
end

--Precondition: Set AppIconsFolder value to storage/IconsFolder in .ini file
SetEnableProtocol4ValueInIniFileTotrue(self, "AppIconsFolderToIconsFolder", _, true, "storage/IconsFolder")

--===================================================================================--
-- Check that starting from SDL's first startup, SDL copy each registered app's icon to the predefined folder renaming the icon after app's string-valued appID
--===================================================================================--
function Test:RegisterFirstAppWithIconAppIconsFolderContainsOneIcon()
	userPrint(34, "=================================== Test  Case ===================================")
	self.mobileSession= mobile_session.MobileSession(
    self,
    self.mobileConnection)

    self.mobileSession.version = 4

    local RAIParameters = config.application2.registerAppInterfaceParams

    self.mobileSession:StartService(7)
    :Do(function(_,data)
		AppRegistration(self, RAIParameters)

		EXPECT_NOTIFICATION("OnHMIStatus", { systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
			:DoOnce(function(_,data)
				OnSystemRequestQueryApps(self, self.mobileSession)

				local cidPutFile = self.mobileSession:SendRPC("PutFile",
				{
					syncFileName = "iconFirstApp.png",
					fileType = "GRAPHIC_PNG",
					persistentFile = false,
					systemFile = false
				}, "files/icon.png")

				EXPECT_RESPONSE(cidPutFile, { success = true, resultCode = "SUCCESS" })
				:Do(function(_,data)
					local cidSetAppIcon = self.mobileSession:SendRPC("SetAppIcon",{ syncFileName = "iconFirstApp.png" })
					--hmi side: expect UI.SetAppIcon request

					PathToAppFolder = PathToAppFolderFunction(RAIParameters.appID)

					EXPECT_HMICALL("UI.SetAppIcon",
						{
							syncFileName = 
							{
								imageType = "DYNAMIC",
								value = PathToAppFolder .. "iconFirstApp.png"
							}				
						})
						:Do(function(_,data)
							--hmi side: sending UI.SetAppIcon response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
						
					--mobile side: expect SetAppIcon response
					EXPECT_RESPONSE(cidSetAppIcon, { resultCode = "SUCCESS", success = true })
						:ValidIf(function(_,data)
							local FileToCheck = SDLStoragePath .. tostring("IconsFolder/" .. RAIParameters.appID)
							local fileExistsResult = file_exists(FileToCheck, true)
							local aHandle = assert( io.popen( "ls " .. SDLStoragePath .. "IconsFolder/" , 'r'))
							local ListOfFilesInStorageFolder = aHandle:read( '*a' )
							userPrint(33, "Content of storage folder: " ..tostring("\n" ..ListOfFilesInStorageFolder) )


							return fileExistsResult
						end)
				end)
			end)
		DelayedExp(1000)
	end)
end

function Test:RegisterSecondAppWithIconAppIconsFolderContainsTwoIcons()
	userPrint(34, "=================================== Test  Case ===================================")
	self.mobileSession1= mobile_session.MobileSession(
    self,
    self.mobileConnection)

    self.mobileSession1.version = 4

    local RAIParameters = config.application3.registerAppInterfaceParams

    self.mobileSession1:StartService(7)
    :Do(function(_,data)
		AppRegistration(self, RAIParameters, self.mobileSession1)

		self.mobileSession1:ExpectNotification("OnHMIStatus", { systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
			:DoOnce(function(_,data)
				SendingOnHMIStatusFromMobile(self, "BACKGROUND", "NOT_AUDIBLE", self.mobileSession)

				SendingOnHMIStatusFromMobile(self, "FULL", "NOT_AUDIBLE", self.mobileSession1)

				self.mobileSession1:ExpectNotification("OnSystemRequest", 
					{ requestType = "LOCK_SCREEN_ICON_URL" })
					:Times(AtMost(1))

				local cidPutFile = self.mobileSession1:SendRPC("PutFile",
				{
					syncFileName = "iconSecondApp.png",
					fileType = "GRAPHIC_PNG",
					persistentFile = false,
					systemFile = false
				}, "files/icon.png")

				self.mobileSession1:ExpectResponse(cidPutFile, { success = true, resultCode = "SUCCESS" })
				:Do(function(_,data)
					local cidSetAppIcon = self.mobileSession1:SendRPC("SetAppIcon",{ syncFileName = "iconSecondApp.png" })
					--hmi side: expect UI.SetAppIcon request

					PathToAppFolder = PathToAppFolderFunction(RAIParameters.appID)

					EXPECT_HMICALL("UI.SetAppIcon",
						{
							syncFileName = 
							{
								imageType = "DYNAMIC",
								value = PathToAppFolder .. "iconSecondApp.png"
							}				
						})
						:Do(function(_,data)
							--hmi side: sending UI.SetAppIcon response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
						
					--mobile side: expect SetAppIcon response
					self.mobileSession1:ExpectResponse(cidSetAppIcon, { resultCode = "SUCCESS", success = true })
						:ValidIf(function(_,data)
							local FileToCheck = SDLStoragePath .. tostring("IconsFolder/" .. RAIParameters.appID)
							local fileExistsResult = file_exists(FileToCheck, true)
							local aHandle = assert( io.popen( "ls " .. SDLStoragePath .. "IconsFolder/" , 'r'))
							local ListOfFilesInStorageFolder = aHandle:read( '*a' )
							userPrint(33, "Content of storage folder: " ..tostring("\n" ..ListOfFilesInStorageFolder) )
							return fileExistsResult
						end)
				end)
			end)
		DelayedExp(1000)
	end)
end

function Test:RegisterThirdAppWithoutIconAppIconsFolderContainsTwoIcons()
	userPrint(34, "=================================== Test  Case ===================================")
	self.mobileSession2= mobile_session.MobileSession(
    self,
    self.mobileConnection)

    self.mobileSession2.version = 4

    local RAIParameters = config.application4.registerAppInterfaceParams

    self.mobileSession2:StartService(7)
    :Do(function(_,data)
		AppRegistration(self, RAIParameters, self.mobileSession2)

		self.mobileSession2:ExpectNotification("OnHMIStatus", { systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
			:DoOnce(function(_,data)
				SendingOnHMIStatusFromMobile(self, "BACKGROUND", "NOT_AUDIBLE", self.mobileSession1)

				SendingOnHMIStatusFromMobile(self, "FULL", "NOT_AUDIBLE", self.mobileSession2)

				self.mobileSession2:ExpectNotification("OnSystemRequest", 
					{ requestType = "LOCK_SCREEN_ICON_URL" })
					:Times(AtMost(1))
			end)
    		:ValidIf(function(_,data)
				local FileToCheck = SDLStoragePath .. tostring("IconsFolder/" .. RAIParameters.appID)
				local fileExistsResult = file_exists(FileToCheck)
				local aHandle = assert( io.popen( "ls " .. SDLStoragePath .. "IconsFolder/" , 'r'))
				local ListOfFilesInStorageFolder = aHandle:read( '*a' )
				userPrint(33, "Content of storage folder: " ..tostring("\n" ..ListOfFilesInStorageFolder) )
				if fileExistsResult ~= true then
					userPrint(32, tostring(RAIParameters.appID) .. " icon is absent")
					return true
				else
					userPrint(31, tostring(RAIParameters.appID) .. " icon is present in AppIconsFolder folder")
					return false
				end
			end)

    	DelayedExp(1000)

	end)
end

function Test:Postcondition_UnregisterFirstApp()
	UnregisterAppInterface_Success(self, self.mobileSession, self.applications[config.application2.registerAppInterfaceParams.appName])
end

function Test:Postcondition_UnregisterSecondApp()
	UnregisterAppInterface_Success(self, self.mobileSession1, self.applications[config.application3.registerAppInterfaceParams.appName])
end

function Test:Postcondition_UnregisterThirdApp()
	UnregisterAppInterface_Success(self, self.mobileSession2, self.applications[config.application4.registerAppInterfaceParams.appName])
end

--===================================================================================--
-- Check that SDL replace the older icon in the folder with the new app's icon if App changes its icon to the new one
--===================================================================================--

function Test:ReplaceIconInAppIconsFolderAfterSettingNewOne()
	userPrint(34, "=================================== Test  Case ===================================")
	local RAIParameters = config.application1.registerAppInterfaceParams
	RAIParameters.appID = "234"

	PathToAppFolder = PathToAppFolderFunction(RAIParameters.appID)

	self.mobileSession= mobile_session.MobileSession(
    self,
    self.mobileConnection)

    self.mobileSession.version = 4

    self.mobileSession:StartService(7)
    :Do(function(_,data)
		AppRegistration(self, RAIParameters)

		EXPECT_NOTIFICATION("OnHMIStatus", { systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
		:DoOnce(function(_,data)

			OnSystemRequestQueryApps(self, self.mobileSession)

			local cidPutFile = self.mobileSession:SendRPC("PutFile",
				{
					syncFileName = "icon.png",
					fileType = "GRAPHIC_PNG",
					persistentFile = false,
					systemFile = false
				}, "files/icon.png")

			EXPECT_RESPONSE(cidPutFile, { success = true, resultCode = "SUCCESS" })
			:Do(function(_,data)

				local FileSizeIcon = fsize(PathToAppFolder .. "icon.png")

				local cidSetAppIcon = self.mobileSession:SendRPC("SetAppIcon",{ syncFileName = "icon.png" })
				--hmi side: expect UI.SetAppIcon request
				EXPECT_HMICALL("UI.SetAppIcon",
					{
						syncFileName = 
						{
							imageType = "DYNAMIC",
							value = PathToAppFolder .. "icon.png"
						}				
					},
					{
						syncFileName = 
						{
							imageType = "DYNAMIC",
							value = PathToAppFolder .. "action.png"
						}				
					})
					:Times(2)
					:Do(function(_,data)
						--hmi side: sending UI.SetAppIcon response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)
					
				--mobile side: expect SetAppIcon response
				EXPECT_RESPONSE(cidSetAppIcon, { resultCode = "SUCCESS", success = true })
					:ValidIf(function(_,data)
						local FileToCheck = SDLStoragePath .. tostring("IconsFolder/" .. RAIParameters.appID)
						local fileExistsResult = file_exists(FileToCheck, true)
						if fileExistsResult == true then
							local FileSizeAppIcon = fsize(FileToCheck)
							if FileSizeAppIcon ~= FileSizeIcon then
								userPrint(31, "Size of " .. tostring(RAIParameters.appID) .. " is not match original icon.png file ")
								return false
							end
						end
						return fileExistsResult
					end)
					:Do(function()
						local cidPutFile2 = self.mobileSession:SendRPC("PutFile",
							{
								syncFileName = "action.png",
								fileType = "GRAPHIC_PNG",
								persistentFile = false,
								systemFile = false
							}, "files/action.png")

						EXPECT_RESPONSE(cidPutFile2, { success = true, resultCode = "SUCCESS" })
						:Do(function(_,data)

							local FileSizeActionIcon = fsize(PathToAppFolder .. "action.png")
							local cidSetAppIcon2 = self.mobileSession:SendRPC("SetAppIcon",{ syncFileName = "action.png" })

							--mobile side: expect SetAppIcon response
							EXPECT_RESPONSE(cidSetAppIcon2, { resultCode = "SUCCESS", success = true })
								:ValidIf(function(_,data)
									local FileToCheck = SDLStoragePath .. tostring("IconsFolder/" .. RAIParameters.appID)
									local fileExistsResult = file_exists(FileToCheck, true)
									local aHandle = assert( io.popen( "ls " .. SDLStoragePath .. "IconsFolder/" , 'r'))
									local ListOfFilesInStorageFolder = aHandle:read( '*a' )
									userPrint(33, "Content of storage folder: " ..tostring("\n" ..ListOfFilesInStorageFolder) )
									if fileExistsResult == true then
										local FileSizeAppActionIcon = fsize(FileToCheck)
										if FileSizeAppActionIcon ~= FileSizeActionIcon then
											userPrint(31, "Size of " .. tostring(RAIParameters.appID) .. " is not match original action.png file ")
											return false
										end
									end
									return fileExistsResult
								end)
						end)
					end)
			end)
		end)

	end)
end

function Test:Postcondition_UnregisterApp_ReplaceIconInAppIconsFolderAfterSettingNewOne()
	UnregisterAppInterface_Success(self, self.mobileSession, self.applications[config.application1.registerAppInterfaceParams.appName])
end

--===================================================================================--
-- Check that SDL delete oldest several icons if folder is overfull and add the new one
--===================================================================================--
SetEnableProtocol4ValueInIniFileTotrue(self, "AppIconsFolderMaxSizeTo1048576AppIconsAmountToRemoveTo1", _, _, _, true, "1048576", true, "1", true)

function Test:Precondition_FullAppIconsFolderMaxSize_DeletingOldestIconInCaseSpaceIsnotEnoughInAppIconsFolder()

	FullAppIconsFolder( "storage/IconsFolder" )

end

function Test:DeletingOldestIconInCaseSpaceIsnotEnoughInAppIconsFolder()
	userPrint(34, "=================================== Test  Case ===================================")

	local RAIParameters = config.application1.registerAppInterfaceParams

	function CheckFunction()
		local StatusValue = true
		
		local ApplicationFileToCheck = SDLStoragePath .. tostring("IconsFolder/" .. RAIParameters.appID)
		local OldFileToCheck = SDLStoragePath .. tostring("IconsFolder/icon1.png")

		local ApplicationFileExistsResult = file_exists(ApplicationFileToCheck)
		local OldFileExistResult = file_exists(OldFileToCheck)

		local aHandle = assert( io.popen( "ls " .. SDLStoragePath .. "IconsFolder/" , 'r'))
		local ListOfFilesInStorageFolder = aHandle:read( '*a' )
		userPrint(33, "Content of storage folder: " ..tostring("\n" ..ListOfFilesInStorageFolder) )

		if ApplicationFileExistsResult ~= true then
			userPrint(31, tostring(RAIParameters.appID) .. " icon is absent")
			StatusValue = false
		end

		if OldFileExistResult ~= false then
			userPrint(31,"The oldest icon1.png is not deleted from AppIconsFolder")
			StatusValue = false
		end

		return StatusValue
	end

	StartSessionRegisterAppSetIcon(self, RAIParameters)
end

function Test:Postcondition_UnregisterApp_DeletingOldestIconInCaseSpaceIsnotEnoughInAppIconsFolder()
	UnregisterAppInterface_Success(self, self.mobileSession, self.applications[config.application1.registerAppInterfaceParams.appName])
end


--===================================================================================--
-- Check that SDL uses location of the icons folder from ini file 
--===================================================================================--
SetEnableProtocol4ValueInIniFileTotrue(self, "AppIconsFolderToAnotherFolder", _, true, "AnotherFolder")

function Test:UsingAnotherFolderAppIconsFolderFromIniFile()
	userPrint(34, "=================================== Test  Case ===================================")

	local DirExistResult = Directory_exist(config.pathToSDL .. "AnotherFolder")
	
	if DirExistResult == false then
		--Create folder AnotherFolder in bin SDL folder
		local CreateAnotherFolder  = assert( os.execute( "mkdir " .. tostring(config.pathToSDL .. "AnotherFolder" )))
		if CreateAnotherFolder ~= true then
			userPrint(31, "AppIconsFolder folder is not created")
		end
	end

	local RAIParameters = config.application1.registerAppInterfaceParams

	function CheckFunction()
		local StatusValue = true

		DirExistResult = Directory_exist(config.pathToSDL .. "AnotherFolder")

		if DirExistResult == true then
			local ApplicationFileToCheck = config.pathToSDL .. tostring("AnotherFolder/" .. RAIParameters.appID)

			local ApplicationFileExistsResult = file_exists(ApplicationFileToCheck)

			local aHandle = assert( io.popen( "ls " .. config.pathToSDL .. "AnotherFolder/" , 'r'))
			os.execute("sleep 0.5")
			local ListOfFilesInStorageFolder = aHandle:read( '*a' )
			userPrint(33, "Content of AnotherFolder folder: " ..tostring("\n" .. tostring(ListOfFilesInStorageFolder)) )

			if ApplicationFileExistsResult ~= true then
				userPrint(31, tostring(RAIParameters.appID) .. " icon is absent")
				StatusValue = false
			end
		else 
			userPrint(31, "AnotherFolder folder is not exist in SDL bin folder " )
			StatusValue = false
		end

		return StatusValue
	end

	StartSessionRegisterAppSetIcon(self, RAIParameters)
end

function Test:Postcondition_UnregisterApp_UsingAnotherFolderAppIconsFolderFromIniFile()
	UnregisterAppInterface_Success(self, self.mobileSession, self.applications[config.application1.registerAppInterfaceParams.appName])
end

--===================================================================================--
-- Check that SDL create AppIconsFolder in case folder is not exits 
--===================================================================================--
SetEnableProtocol4ValueInIniFileTotrue(self, "AppIconsFolderToIcons", _, true, "Icons")

function Test:CreationAppIconsFolderInCaseFolderIsNotExist()
	userPrint(34, "=================================== Test  Case ===================================")

	local DirExistResult = Directory_exist(config.pathToSDL .. "Icons")
	
	if DirExistResult == true then
		--Delete Icons folder
		local RmAppIconsFolder  = assert( os.execute( "rm -rf " .. tostring(config.pathToSDL .. "Icons" )))
		if RmAppIconsFolder ~= true then
			userPrint(31, "AppIconsFolder folder is not deleted")
		end
	end

	local RAIParameters = config.application1.registerAppInterfaceParams

	function CheckFunction()
		local StatusValue = true

		DirExistResult = Directory_exist(config.pathToSDL .. "Icons")

		if DirExistResult == true then
		
			local ApplicationFileToCheck = config.pathToSDL .. tostring("Icons/" .. RAIParameters.appID)

			local ApplicationFileExistsResult = file_exists(ApplicationFileToCheck)

			local aHandle = assert( io.popen( "ls " .. config.pathToSDL .. "Icons/" , 'r'))
			local ListOfFilesInStorageFolder = aHandle:read( '*a' )
			userPrint(33, "Content of Icons folder: " ..tostring("\n" ..ListOfFilesInStorageFolder) )

			if ApplicationFileExistsResult ~= true then
				userPrint(31, tostring(RAIParameters.appID) .. " icon is absent")
				StatusValue = false
			end
		else 
			userPrint(31, "Icons folder is not exist in SDL bin folder " )
			StatusValue = false
		end

		return StatusValue
	end

	StartSessionRegisterAppSetIcon(self, RAIParameters)
end

function Test:Postcondition_UnregisterApp_CreationAppIconsFolder()
	UnregisterAppInterface_Success(self, self.mobileSession, self.applications[config.application1.registerAppInterfaceParams.appName])
end

--===================================================================================--
-- Check that SDL continue working if permissions of AppIconsfolder is not read/write
--===================================================================================--

SetEnableProtocol4ValueInIniFileTotrue(self, "AppIconsFolderToFolderWithoutPermissions", _, true, "FolderWithoutPermissions")

function Test:CorrectSDLWorkAppIconsFolderWithoutPermissions()
	userPrint(34, "=================================== Test  Case ===================================")

	local ChangePermissions  = assert(os.execute( "chmod 000 " .. tostring(config.pathToSDL .. "FolderWithoutPermissions" )))
	if ChangePermissions ~= true then
		userPrint(31, "Permissions for FolderWithoutPermissions are not changed")
	end


	local RAIParameters = config.application1.registerAppInterfaceParams

	function CheckFunction()
		local StatusValue = true

		DirExistResult = Directory_exist(config.pathToSDL .. "FolderWithoutPermissions")

		if DirExistResult == true then
		
			local ApplicationFileToCheck = config.pathToSDL .. tostring("FolderWithoutPermissions/" .. RAIParameters.appID)

			local ApplicationFileExistsResult = file_exists(ApplicationFileToCheck)

			if ApplicationFileExistsResult ~= false then
				userPrint(31, tostring(RAIParameters.appID) .. " icon is writen to folder without permissions")
				StatusValue = false
			end
		else 
			userPrint(31, "FolderWithoutPermissions folder is not exist in SDL bin folder " )
			StatusValue = false
		end

		return StatusValue
	end

	StartSessionRegisterAppSetIcon(self, RAIParameters)
end

function Test:Postcondition_UnregisterApp_RemoveFolderWithoutPermissions_CorrectSDLWorkAppIconsFolderWithoutPermissions()

	local RmAppIconsFolder  = assert( os.execute( "rm -rf " .. tostring(config.pathToSDL .. "FolderWithoutPermissions" )))
	if RmAppIconsFolder ~= true then
		userPrint(31, "FolderWithoutPermissions folder is not deleted")
	end

	UnregisterAppInterface_Success(self, self.mobileSession, self.applications[config.application1.registerAppInterfaceParams.appName])
end

--===================================================================================--
-- Check that SDL delete number of icons in case folder is full from parameter, specified in .ini file
--===================================================================================--
SetEnableProtocol4ValueInIniFileTotrue(self, "AppIconsFolderMaxSizeTo1048576AppIconsAmountToRemoveTo2", _, true, "Icons", true, "1048576", true, "2", true)

function Test:Precondition_FullAppIconsFolderMaxSize_DeletingOldestTwoIconInCaseSpaceIsnotEnoughInAppIconsFolder()

	FullAppIconsFolder( "Icons" )

end

function Test:DeletingOldestTwoIconInCaseSpaceIsnotEnoughInAppIconsFolder()
	userPrint(34, "=================================== Test  Case ===================================")

	local RAIParameters = config.application1.registerAppInterfaceParams

	function CheckFunction()
		local StatusValue = true
		
		local ApplicationFileToCheck = config.pathToSDL .. tostring("Icons/" .. RAIParameters.appID)
		local OldFirstFileToCheck = config.pathToSDL .. tostring("Icons/icon1.png")
		local OldSecondFileToCheck = config.pathToSDL .. tostring("Icons/icon2.png")

		local ApplicationFileExistsResult = file_exists(ApplicationFileToCheck)
		local OldFirstFileExistResult = file_exists(OldFirstFileToCheck)
		local OldSecondFileExistResult = file_exists(OldSecondFileToCheck)

		local aHandle = assert( io.popen( "ls " .. config.pathToSDL .. "Icons/" , 'r'))
		local ListOfFilesInStorageFolder = aHandle:read( '*a' )
		userPrint(33, "Content of storage folder: " ..tostring("\n" ..ListOfFilesInStorageFolder) )

		if ApplicationFileExistsResult ~= true then
			userPrint(31, tostring(RAIParameters.appID) .. " icon is absent")
			StatusValue = false
		end

		if OldFirstFileExistResult ~= false then
			userPrint(31,"The oldest icon1.png is not deleted from AppIconsFolder")
			StatusValue = false
		end

		if OldSecondFileExistResult ~= false then
			userPrint(31,"The oldest icon2.png is not deleted from AppIconsFolder")
			StatusValue = false
		end

		return StatusValue
	end

	StartSessionRegisterAppSetIcon(self, RAIParameters)
end

function Test:Postcondition_UnregisterApp_DeletingOldestTwoIconInCaseSpaceIsnotEnoughInAppIconsFolder()
	UnregisterAppInterface_Success(self, self.mobileSession, self.applications[config.application1.registerAppInterfaceParams.appName])
end

--===================================================================================--
-- Check that SDL send app icons with available appName to HMI after ignition cycle
--===================================================================================--
SetEnableProtocol4ValueInIniFileTotrue(self, "AppforIcons_Icons", _, true, "Icons", true, "104857600", _, _, true)

function Test:SaveIconInAppIconsFolderWithAppIdNameForFirstApp()
	userPrint(34, "=================================== Test  Case ===================================")

	RAIParameters = config.application2.registerAppInterfaceParams
	RAIParameters.appName = "Test application1"
	RAIParameters.appID = "1"

	PathToAppFolder = PathToAppFolderFunction(RAIParameters.appID)

	self.mobileSession2= mobile_session.MobileSession(
    self,
    self.mobileConnection)

    self.mobileSession2.version = 3

    self.mobileSession2:StartService(7)
    :Do(function(_,data)
		AppRegistration(self, RAIParameters, self.mobileSession2)

		EXPECT_HMICALL("BasicCommunication.UpdateAppList",
			{applications = {
			   	{
			      	appName = RAIParameters.appName,
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

		self.mobileSession2:ExpectNotification("OnHMIStatus", { systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
		:DoOnce(function(_,data)

			local cidPutFile = self.mobileSession2:SendRPC("PutFile",
				{
					syncFileName = "icon.png",
					fileType = "GRAPHIC_PNG",
					persistentFile = false,
					systemFile = false
				}, "files/icon.png")

			self.mobileSession2:ExpectResponse(cidPutFile, { success = true, resultCode = "SUCCESS" })
			:Do(function(_,data)
				local cidSetAppIcon = self.mobileSession2:SendRPC("SetAppIcon",{ syncFileName = "icon.png" })
					--hmi side: expect UI.SetAppIcon request
					EXPECT_HMICALL("UI.SetAppIcon",
						{
							syncFileName = 
							{
								imageType = "DYNAMIC",
								value = PathToAppFolder .. "icon.png"
							}				
						})
						:Do(function(_,data)
							--hmi side: sending UI.SetAppIcon response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
					
					--mobile side: expect SetAppIcon response
					self.mobileSession2:ExpectResponse(cidSetAppIcon, { resultCode = "SUCCESS", success = true })
						:ValidIf(function(_,data)
							local FileToCheck = config.pathToSDL .. "Icons/" .. tostring(RAIParameters.appID)
							local fileExistsResult = file_exists(FileToCheck, true)

							local aHandle = assert( io.popen( "ls " .. config.pathToSDL .. "Icons/" , 'r'))
							local ListOfFilesInStorageFolder = aHandle:read( '*a' )
							userPrint(33, "Content of storage folder: " ..tostring("\n" ..ListOfFilesInStorageFolder) )

							return fileExistsResult
						end)
			end)
		end)

	end)
end

function Test:SaveIconInAppIconsFolderWithAppIdNameForSecondApp()
	userPrint(34, "=================================== Test  Case ===================================")

	RAIParameters = config.application3.registerAppInterfaceParams
	RAIParameters.appName = "Test application2"
	RAIParameters.appID = "2"

	PathToAppFolder = PathToAppFolderFunction(RAIParameters.appID)

	self.mobileSession3= mobile_session.MobileSession(
    self,
    self.mobileConnection)

    self.mobileSession3.version = 3

    self.mobileSession3:StartService(7)
    :Do(function(_,data)
		AppRegistration(self, RAIParameters, self.mobileSession3)

		EXPECT_HMICALL("BasicCommunication.UpdateAppList",
			{applications = {
			   	{
			      	appName = "Test application1",
			      	--[=[TODO: remove after resolving APPLINK-16052
			      	deviceInfo = {
				        id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
				        isSDLAllowed = true,
				        name = "127.0.0.1",
				        transportType = "WIFI"
			      	}]=]
			   	},
			   	{
			      	appName = RAIParameters.appName,
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
                if #data.params.applications == 2 then
                  	return true
              	else 
                    userPrint( 31, "Application array in BasicCommunication.UpdateAppList contains "..tostring(#data.params.applications)..", expected 2" )
                    return false
              	end
          	end)
			:Do(function(_,data)
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
				for i=1, #data.params.applications do
					self.applications[data.params.applications[i].appName] = data.params.applications[i].appID
              	end
          	end)

		self.mobileSession3:ExpectNotification("OnHMIStatus", { systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
		:DoOnce(function(_,data)

			local cidPutFile = self.mobileSession3:SendRPC("PutFile",
				{
					syncFileName = "icon.png",
					fileType = "GRAPHIC_PNG",
					persistentFile = false,
					systemFile = false
				}, "files/icon.png")

			self.mobileSession3:ExpectResponse(cidPutFile, { success = true, resultCode = "SUCCESS" })
			:Do(function(_,data)
				local cidSetAppIcon = self.mobileSession3:SendRPC("SetAppIcon",{ syncFileName = "icon.png" })
					--hmi side: expect UI.SetAppIcon request
					EXPECT_HMICALL("UI.SetAppIcon",
						{
							syncFileName = 
							{
								imageType = "DYNAMIC",
								value = PathToAppFolder .. "icon.png"
							}				
						})
						:Do(function(_,data)
							--hmi side: sending UI.SetAppIcon response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
					
					--mobile side: expect SetAppIcon response
					self.mobileSession3:ExpectResponse(cidSetAppIcon, { resultCode = "SUCCESS", success = true })
						:ValidIf(function(_,data)
							local FileToCheck = config.pathToSDL .. "Icons/" .. tostring(RAIParameters.appID)
							local fileExistsResult = file_exists(FileToCheck, true)

							local aHandle = assert( io.popen( "ls " .. config.pathToSDL .. "Icons/" , 'r'))
							local ListOfFilesInStorageFolder = aHandle:read( '*a' )
							userPrint(33, "Content of storage folder: " ..tostring("\n" ..ListOfFilesInStorageFolder) )

							return fileExistsResult
						end)
			end)
		end)

	end)
end

function Test:SaveIconInAppIconsFolderWithAppIdNameForThirdApp()
	userPrint(34, "=================================== Test  Case ===================================")

	RAIParameters = config.application4.registerAppInterfaceParams
	RAIParameters.appName = "Test application3"
	RAIParameters.appID = "3"

	PathToAppFolder = PathToAppFolderFunction(RAIParameters.appID)

	self.mobileSession4= mobile_session.MobileSession(
    self,
    self.mobileConnection)

    self.mobileSession4.version = 3

    self.mobileSession4:StartService(7)
    :Do(function(_,data)
		AppRegistration(self, RAIParameters, self.mobileSession4)

		EXPECT_HMICALL("BasicCommunication.UpdateAppList",
			{applications = {
			   	{
			      	appName = "Test application1",
			      	--[=[TODO: remove after resolving APPLINK-16052
			      	deviceInfo = {
				        id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
				        isSDLAllowed = true,
				        name = "127.0.0.1",
				        transportType = "WIFI"
			      	}]=]
			   	},
			   	{
			      	appName = "Test application2",
			      	--[=[TODO: remove after resolving APPLINK-16052
			      	deviceInfo = {
				        id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
				        isSDLAllowed = true,
				        name = "127.0.0.1",
				        transportType = "WIFI"
			      	}]=]
			   	},
			   	{
			      	appName = RAIParameters.appName,
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

		self.mobileSession4:ExpectNotification("OnHMIStatus", { systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
		:DoOnce(function(_,data)

			local cidPutFile = self.mobileSession4:SendRPC("PutFile",
				{
					syncFileName = "icon.png",
					fileType = "GRAPHIC_PNG",
					persistentFile = false,
					systemFile = false
				}, "files/icon.png")

			self.mobileSession4:ExpectResponse(cidPutFile, { success = true, resultCode = "SUCCESS" })
			:Do(function(_,data)
				local cidSetAppIcon = self.mobileSession4:SendRPC("SetAppIcon",{ syncFileName = "icon.png" })
					--hmi side: expect UI.SetAppIcon request
					EXPECT_HMICALL("UI.SetAppIcon",
						{
							syncFileName = 
							{
								imageType = "DYNAMIC",
								value = PathToAppFolder .. "icon.png"
							}				
						})
						:Do(function(_,data)
							--hmi side: sending UI.SetAppIcon response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
					
					--mobile side: expect SetAppIcon response
					self.mobileSession4:ExpectResponse(cidSetAppIcon, { resultCode = "SUCCESS", success = true })
						:ValidIf(function(_,data)
							local FileToCheck = config.pathToSDL .. "Icons/" .. tostring(RAIParameters.appID)
							local fileExistsResult = file_exists(FileToCheck, true)

							local aHandle = assert( io.popen( "ls " .. config.pathToSDL .. "Icons/" , 'r'))
							local ListOfFilesInStorageFolder = aHandle:read( '*a' )
							userPrint(33, "Content of storage folder: " ..tostring("\n" ..ListOfFilesInStorageFolder) )

							return fileExistsResult
						end)
			end)
		end)

	end)
end

function Test:Precondition_UnregisterSecondApp_SDLSendsIconsInUpdateAppListAfterIGNOFF()
	UnregisterAppInterface_Success(self, self.mobileSession2, self.applications["Test application1"])
end

function Test:Precondition_UnregisterThirdApp_SDLSendsIconsInUpdateAppListAfterIGNOFF()
	UnregisterAppInterface_Success(self, self.mobileSession3, self.applications["Test application2"])
end

function Test:Precondition_UnregisterFourtsApp_SDLSendsIconsInUpdateAppListAfterIGNOFF()
	UnregisterAppInterface_Success(self, self.mobileSession4, self.applications["Test application3"])
end

SetEnableProtocol4ValueInIniFileTotrue(self, "RestartSDL")

function Test:SDLSendsIconsInUpdateAppListAfterIGNOFF()
	userPrint(34, "=================================== Test  Case ===================================")

	RAIParams = config.application1.registerAppInterfaceParams
	RAIParams.appName = "Test application"
	RAIParams.appID = "0000001"

	PathToAppFolder = PathToAppFolderFunction(RAIParams.appID)

	self.mobileSession= mobile_session.MobileSession(
    self,
    self.mobileConnection)

    self.mobileSession.version = 4

    self.mobileSession:StartService(7)
    :Do(function(_,data)
		AppRegistration(self, RAIParams)

		EXPECT_NOTIFICATION("OnHMIStatus", { systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
		:DoOnce(function(_,data)
			function to_run()
				OnSystemRequestQueryApps(self, self.mobileSession, "FULL", "NOT_AUDIBLE", "correctJSON_icons.json")
			end

			RUN_AFTER(to_run, 1000)
		end)

		EXPECT_HMICALL("BasicCommunication.UpdateAppList",
			{applications = {
			   	{
			      	appName = RAIParams.appName,
			      	--[=[TODO: remove after resolving APPLINK-16052
			      	deviceInfo = {
				        id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
				        isSDLAllowed = t rue,
				        name = "127.0.0.1",
				        transportType = "WIFI"
			      	}]=]
			   	}
			}},
			{applications = {
				{
			      	appName = RAIParams.appName,
			      	--[=[TODO: remove after resolving APPLINK-16052
			      	deviceInfo = {
				        id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
				        isSDLAllowed = true,
				        name = "127.0.0.1",
				        transportType = "WIFI"
			      	}]=]
			   	},
			   	{
			      	appName = "Test application1",
			      	icon = config.pathToSDL .. "Icons/1",
			      	--[=[TODO: remove after resolving APPLINK-16052
			      	deviceInfo = {
				        id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
				        isSDLAllowed = true,
				        name = "127.0.0.1",
				        transportType = "WIFI"
			      	}]=]
			   	},
			   	{
			      	appName = "Test application2",
			      	icon = config.pathToSDL .. "Icons/2",
			      	--[=[TODO: remove after resolving APPLINK-16052
			      	deviceInfo = {
				        id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
				        isSDLAllowed = true,
				        name = "127.0.0.1",
				        transportType = "WIFI"
			      	}]=]
			   	},
			   	{
			      	appName = "Test application3",
			      	icon = config.pathToSDL .. "Icons/3"
			      	--[=[TODO: remove after resolving APPLINK-16052
			      	deviceInfo = {
				        id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
				        isSDLAllowed = true,
				        name = "127.0.0.1",
				        transportType = "WIFI"
			      	}]=]
			   	}
			}})
		 	:Times(2)
		 	:ValidIf(function(exp,data)
		 		if exp.occurences  == 1 then
	                if #data.params.applications == 1 then
	                  	return true
	              	else 
	                    userPrint( 31, "Application array in BasicCommunication.UpdateAppList contains "..tostring(#data.params.applications)..", expected 1" )
	                    return false
	              	end
	            elseif exp.occurences  == 2 then
	            	if #data.params.applications == 4 then
	                  	return true
	              	else 
	                    userPrint( 31, "Application array in BasicCommunication.UpdateAppList contains "..tostring(#data.params.applications)..", expected 4" )
	                    return false
	              	end
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

function Test:Postcondition_UnregisterFirstApp_SDLSendsIconsInUpdateAppListAfterIGNOFF()
	UnregisterAppInterface_Success(self, self.mobileSession, self.applications[config.application1.registerAppInterfaceParams.appName])
end


--===================================================================================--
-- Check that SDL continue working if AppIconsAmountToRemove bigger then amount of icons in AppIconsFolder
--===================================================================================--

SetEnableProtocol4ValueInIniFileTotrue(self, "AppIconsFolderMaxSizeTo1048576AppIconsAmountToRemoveTo100", _, true, "Icons", true, "1048576", true, "100", true)

function Test:Precondition_FullAppIconsFolderMaxSize_DeletingOldestIconAppIconsAmountToRemoveIsBiggerThenIconsCountInAppIconsFolder()

	FullAppIconsFolder( "Icons" )

end

function Test:DeletingOldestIconAppIconsAmountToRemoveIsBiggerThenIconsCountInAppIconsFolder()
	userPrint(34, "=================================== Test  Case ===================================")

	local RAIParameters = config.application1.registerAppInterfaceParams

	function CheckFunction()
		local StatusValue = true
		
		local ApplicationFileToCheck = config.pathToSDL .. tostring("Icons/" .. RAIParameters.appID)
		local OldFirstFileToCheck = config.pathToSDL .. tostring("Icons/icon1.png")
		local OldSecondFileToCheck = config.pathToSDL .. tostring("Icons/icon2.png")
		local OldThirdFileToCheck = config.pathToSDL .. tostring("Icons/icon3.png")

		local ApplicationFileExistsResult = file_exists(ApplicationFileToCheck)
		local OldFirstFileExistResult = file_exists(OldFirstFileToCheck)
		local OldSecondFileExistResult = file_exists(OldSecondFileToCheck)
		local OldThirdFileExistResult = file_exists(OldThirdFileToCheck)

		local aHandle = assert( io.popen( "ls " .. config.pathToSDL .. "Icons/" , 'r'))
		local ListOfFilesInStorageFolder = aHandle:read( '*a' )
		userPrint(33, "Content of storage folder: " ..tostring("\n" ..ListOfFilesInStorageFolder) )

		if ApplicationFileExistsResult ~= true then
			userPrint(31, tostring(RAIParameters.appID) .. " icon is absent")
			StatusValue = false
		end

		if 
			OldFirstFileExistResult ~= false or
			OldSecondFileExistResult ~= false or
			OldThirdFileExistResult ~= false then
				userPrint(31,"The oldest icons are not deleted from AppIconsFolder")
				StatusValue = false
		end


		return StatusValue
	end

	StartSessionRegisterAppSetIcon(self, RAIParameters)
end

function Test:Postcondition_UnregisterApp_DeletingOldestIconAppIconsAmountToRemoveIsBiggerThenIconsCountInAppIconsFolder()
	UnregisterAppInterface_Success(self, self.mobileSession, self.applications[config.application1.registerAppInterfaceParams.appName])
end

--===================================================================================--
-- Check that SDL do not copy icon if size of icon larger then AppIconsFolderMaxSize
--===================================================================================--

SetEnableProtocol4ValueInIniFileTotrue(self, "RestartSDLDeletingCreatedAppIconsFolders", _, true, "Icons", true, "1048576", true, "1", true)

function Test:DeletingOldestIconAppIconsAmountToRemoveIsBiggerThenIconsCountInAppIconsFolder()
	userPrint(34, "=================================== Test  Case ===================================")

	local RAIParameters = config.application1.registerAppInterfaceParams

	function CheckFunction()
		local StatusValue = true
		
		local ApplicationFileToCheck = config.pathToSDL .. tostring("Icons/" .. RAIParameters.appID)

		local ApplicationFileExistsResult = file_exists(ApplicationFileToCheck)

		local aHandle = assert( io.popen( "ls " .. config.pathToSDL .. "Icons/" , 'r'))
		local ListOfFilesInStorageFolder = aHandle:read( '*a' )
		userPrint(33, "Content of storage folder: " ..tostring("\n" .. ListOfFilesInStorageFolder) )

		if ApplicationFileExistsResult ~= false then
			userPrint(31, tostring(RAIParameters.appID) .. " icon is added to AppIconsFolder in case size of file is larger then AppIconsFolderMaxSize.")
			StatusValue = false
		end

		return StatusValue
	end

	StartSessionRegisterAppSetIcon(self, RAIParameters, "png_1211kb.png")
end

function Test:Postcondition_UnregisterApp_DeletingOldestIconAppIconsAmountToRemoveIsBiggerThenIconsCountInAppIconsFolder()
	UnregisterAppInterface_Success(self, self.mobileSession, self.applications[config.application1.registerAppInterfaceParams.appName])
end

-- ===================================================================================--
-- Checks that SDL looks for an icon in SDL's icons folder in accordance with the string-valued appID for each and every app.
-- ===================================================================================--

SetEnableProtocol4ValueInIniFileTotrue(self, "IconsStringValuedAppIDForEachAndEveryApp", _, true, "Icons", true, "1048576", true, "1", true)

function Test:RegisterFirstAppViaFourthProtocol_IconsStringValuedAppIDForEachAndEveryApp()
	userPrint(34, "=================================== Test  Case ===================================")
	self.mobileSession= mobile_session.MobileSession(
    self,
    self.mobileConnection)

    self.mobileSession.version = 4

    local RAIParameters = config.application1.registerAppInterfaceParams

    self.mobileSession:StartService(7)
    :Do(function(_,data)
		AppRegistration(self, RAIParameters)

		EXPECT_NOTIFICATION("OnHMIStatus", { systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
			:DoOnce(function(_,data)
				OnSystemRequestQueryApps(self, self.mobileSession, "FULL", "NOT_AUDIBLE", "correctJSON_icons.json")
			end)

		EXPECT_HMICALL("BasicCommunication.UpdateAppList",
			{applications = {
			   	{
			      	appName = RAIParameters.appName,
			      	--[=[TODO: remove after resolving APPLINK-16052
			      	deviceInfo = {
				        id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
				        isSDLAllowed = t rue,
				        name = "127.0.0.1",
				        transportType = "WIFI"
			      	}]=]
			   	}
			}},
			{applications = {
				{
			      	appName = RAIParameters.appName,
			      	--[=[TODO: remove after resolving APPLINK-16052
			      	deviceInfo = {
				        id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
				        isSDLAllowed = true,
				        name = "127.0.0.1",
				        transportType = "WIFI"
			      	}]=]
			   	},
			   	{
			      	appName = "Test application1",
			      	--[=[TODO: remove after resolving APPLINK-16052
			      	deviceInfo = {
				        id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
				        isSDLAllowed = true,
				        name = "127.0.0.1",
				        transportType = "WIFI"
			      	}]=]
			   	},
			   	{
			      	appName = "Test application2",
			      	--[=[TODO: remove after resolving APPLINK-16052
			      	deviceInfo = {
				        id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
				        isSDLAllowed = true,
				        name = "127.0.0.1",
				        transportType = "WIFI"
			      	}]=]
			   	},
			   	{
			      	appName = "Test application3",
			      	--[=[TODO: remove after resolving APPLINK-16052
			      	deviceInfo = {
				        id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
				        isSDLAllowed = true,
				        name = "127.0.0.1",
				        transportType = "WIFI"
			      	}]=]
			   	}
			}})
			:Times(2)
		 	:ValidIf(function(exp,data)
		 		if exp.occurences  == 1 then
	                if #data.params.applications == 1 then
	                  	return true
	              	else 
	                    userPrint( 31, "Application array in BasicCommunication.UpdateAppList contains "..tostring(#data.params.applications)..", expected 1" )
	                    return false
	              	end
	            elseif exp.occurences  == 2 then
	            	if #data.params.applications == 4 then
	            		local statusValue = true
	                  	for i=1,#data.params.applications do
	                  		if data.params.applications[i].icon then
	                  			userPrint(31, "SDL sends icon value " .. tostring(data.params.applications[i].icon) .. " for first registered app " .. tostring(data.params.applications[i].appName))
	                  			statusValue = false

	                  		end
	                  	end
	                  	return statusValue
	              	else 
	                    userPrint( 31, "Application array in BasicCommunication.UpdateAppList contains "..tostring(#data.params.applications)..", expected 4" )
	                    return false
	              	end
	            end
          	end)
			:Do(function(_,data)
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
				for i=1, #data.params.applications do
					self.applications[data.params.applications[i].appName] = data.params.applications[i].appID
              	end
          	end)

		DelayedExp(1000)
	end)
end

function Test:RegiaterActivateFirstApp_IconsStringValuedAppIDForEachAndEveryApp()
	userPrint(34, "=================================== Test  Case ===================================")

	RAIParameters = config.application2.registerAppInterfaceParams
	RAIParameters.appName = "Test application1"
	RAIParameters.appID = "1"

	PathToAppFolder = PathToAppFolderFunction(RAIParameters.appID)

	self.mobileSession2 = mobile_session.MobileSession(
    self,
    self.mobileConnection)

    self.mobileSession2.version = 4

    SendingOnHMIStatusFromMobile(self, "FULL", "AUDIBLE", self.mobileSession)

	--hmi side: sending SDL.ActivateApp
	local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["Test application1"]})

	--hmi side: expect SDL.ActivateApp response
    --TODO: uncommented after resolving APPLINK-16094 EXPECT_HMIRESPONSE(RequestId, {code = 0})
    EXPECT_HMIRESPONSE(RequestId)
        :ValidIf(function(_,data)
          if 
            data.result.code ~= 0 then
              userPrint(32, "SDL.ActivateApp response came with wrong result code. Expected SUCCESS(0), actual " .. tostring(data.result.code))
              return false
          else return true
          end
        end)

      --mobile side: expect OnSystemRequest on mobile side
      self.mobileSession:ExpectNotification("OnSystemRequest", {requestType = "LAUNCH_APP", url = "com.testApp1.fake"})
        :Do(function(_,data)

          SendingOnHMIStatusFromMobile(self, "BACKGROUND", "NOT_AUDIBLE", self.mobileSession)
          SendingOnHMIStatusFromMobile(self, "FULL", "NOT_AUDIBLE", self.mobileSession2)

          self.mobileSession2:StartService(7)
            :Do(function()
              --RegisterApp through new session
              AppRegistration(self, RAIParameters, self.mobileSession2)
  
	          -- mobile side: expect OnHMIStatus on mobile side
	          self.mobileSession2:ExpectNotification("OnHMIStatus", 
	            {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"},
	            {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
	            :Times(2)
	            :Do(function(_,data)
	            	if data.payload.hmiLevel == "FULL" then

	            		local cidPutFile = self.mobileSession2:SendRPC("PutFile",
						{
							syncFileName = "icon.png",
							fileType = "GRAPHIC_PNG",
							persistentFile = false,
							systemFile = false
						}, "files/icon.png")

						self.mobileSession2:ExpectResponse(cidPutFile, { success = true, resultCode = "SUCCESS" })
						:Do(function(_,data)
							local cidSetAppIcon = self.mobileSession2:SendRPC("SetAppIcon",{ syncFileName = "icon.png" })
								--hmi side: expect UI.SetAppIcon request
								EXPECT_HMICALL("UI.SetAppIcon",
									{
										syncFileName = 
										{
											imageType = "DYNAMIC",
											value = PathToAppFolder .. "icon.png"
										}				
									})
									:Do(function(_,data)
										--hmi side: sending UI.SetAppIcon response
										self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
									end)
								
								--mobile side: expect SetAppIcon response
								self.mobileSession2:ExpectResponse(cidSetAppIcon, { resultCode = "SUCCESS", success = true })
									:ValidIf(function(_,data)
										local FileToCheck = config.pathToSDL .. "Icons/" .. tostring(RAIParameters.appID)
										local fileExistsResult = file_exists(FileToCheck, true)

										local aHandle = assert( io.popen( "ls " .. config.pathToSDL .. "Icons/" , 'r'))
										local ListOfFilesInStorageFolder = aHandle:read( '*a' )
										userPrint(33, "Content of storage folder: " ..tostring("\n" ..ListOfFilesInStorageFolder) )

										return fileExistsResult
									end)
						end)
	            	end
	            end)

	          self.mobileSession:ExpectNotification("OnHMIStatus", {})
	          	:Times(0)

            end)
            DelayedExp(1000)
        end)
end

function Test:RegiaterActivateSecondApp_IconsStringValuedAppIDForEachAndEveryApp()
	userPrint(34, "=================================== Test  Case ===================================")

	RAIParameters = config.application3.registerAppInterfaceParams
	RAIParameters.appName = "Test application2"
	RAIParameters.appID = "2"

	PathToAppFolder = PathToAppFolderFunction(RAIParameters.appID)

	self.mobileSession3 = mobile_session.MobileSession(
    self,
    self.mobileConnection)

    self.mobileSession3.version = 4

    SendingOnHMIStatusFromMobile(self, "FULL", "AUDIBLE", self.mobileSession2)

	--hmi side: sending SDL.ActivateApp
	local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["Test application2"]})

	--hmi side: expect SDL.ActivateApp response
    --TODO: uncommented after resolving APPLINK-16094 EXPECT_HMIRESPONSE(RequestId, {code = 0})
    EXPECT_HMIRESPONSE(RequestId)
        :ValidIf(function(_,data)
          if 
            data.result.code ~= 0 then
              userPrint(32, "SDL.ActivateApp response came with wrong result code. Expected SUCCESS(0), actual " .. tostring(data.result.code))
              return false
          else return true
          end
        end)

      --mobile side: expect OnSystemRequest on mobile side
      self.mobileSession2:ExpectNotification("OnSystemRequest", {requestType = "LAUNCH_APP", url = "com.testApp2.fake"})
        :Do(function(_,data)

          SendingOnHMIStatusFromMobile(self, "BACKGROUND", "NOT_AUDIBLE", self.mobileSession2)
          SendingOnHMIStatusFromMobile(self, "FULL", "NOT_AUDIBLE", self.mobileSession3)

          self.mobileSession3:StartService(7)
            :Do(function()
              --RegisterApp through new session
              AppRegistration(self, RAIParameters, self.mobileSession3)
  
	          -- mobile side: expect OnHMIStatus on mobile side
	          self.mobileSession3:ExpectNotification("OnHMIStatus", 
	            {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"},
	            {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
	            :Times(2)
	            :Do(function(_,data)
	            	if data.payload.hmiLevel == "FULL" then

	            		local cidPutFile = self.mobileSession3:SendRPC("PutFile",
						{
							syncFileName = "icon.png",
							fileType = "GRAPHIC_PNG",
							persistentFile = false,
							systemFile = false
						}, "files/icon.png")

						self.mobileSession3:ExpectResponse(cidPutFile, { success = true, resultCode = "SUCCESS" })
						:Do(function(_,data)
							local cidSetAppIcon = self.mobileSession3:SendRPC("SetAppIcon",{ syncFileName = "icon.png" })
								--hmi side: expect UI.SetAppIcon request
								EXPECT_HMICALL("UI.SetAppIcon",
									{
										syncFileName = 
										{
											imageType = "DYNAMIC",
											value = PathToAppFolder .. "icon.png"
										}				
									})
									:Do(function(_,data)
										--hmi side: sending UI.SetAppIcon response
										self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
									end)
								
								--mobile side: expect SetAppIcon response
								self.mobileSession3:ExpectResponse(cidSetAppIcon, { resultCode = "SUCCESS", success = true })
									:ValidIf(function(_,data)
										local FileToCheck = config.pathToSDL .. "Icons/" .. tostring(RAIParameters.appID)
										local fileExistsResult = file_exists(FileToCheck, true)

										local aHandle = assert( io.popen( "ls " .. config.pathToSDL .. "Icons/" , 'r'))
										local ListOfFilesInStorageFolder = aHandle:read( '*a' )
										userPrint(33, "Content of storage folder: " ..tostring("\n" ..ListOfFilesInStorageFolder) )

										return fileExistsResult
									end)
						end)
	            	end
	            end)

	          self.mobileSession:ExpectNotification("OnHMIStatus", {})
	          	:Times(0)

            end)

            DelayedExp(1000)

        end)
end

function Test:RegiaterActivateThirdApp_IconsStringValuedAppIDForEachAndEveryApp()
	userPrint(34, "=================================== Test  Case ===================================")

	RAIParameters = config.application4.registerAppInterfaceParams
	RAIParameters.appName = "Test application3"
	RAIParameters.appID = "3"

	PathToAppFolder = PathToAppFolderFunction(RAIParameters.appID)

	self.mobileSession4 = mobile_session.MobileSession(
    self,
    self.mobileConnection)

    self.mobileSession4.version = 4

    SendingOnHMIStatusFromMobile(self, "FULL", "AUDIBLE", self.mobileSession3)

	--hmi side: sending SDL.ActivateApp
	local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["Test application3"]})

	--hmi side: expect SDL.ActivateApp response
    --TODO: uncommented after resolving APPLINK-16094 EXPECT_HMIRESPONSE(RequestId, {code = 0})
    EXPECT_HMIRESPONSE(RequestId)
        :ValidIf(function(_,data)
          if 
            data.result.code ~= 0 then
              userPrint(32, "SDL.ActivateApp response came with wrong result code. Expected SUCCESS(0), actual " .. tostring(data.result.code))
              return false
          else return true
          end
        end)

      --mobile side: expect OnSystemRequest on mobile side
      self.mobileSession3:ExpectNotification("OnSystemRequest", {requestType = "LAUNCH_APP", url = "com.testApp2.fake"})
        :Do(function(_,data)

          SendingOnHMIStatusFromMobile(self, "BACKGROUND", "NOT_AUDIBLE", self.mobileSession3)
          SendingOnHMIStatusFromMobile(self, "FULL", "NOT_AUDIBLE", self.mobileSession4)

          self.mobileSession4:StartService(7)
            :Do(function()
              --RegisterApp through new session
              AppRegistration(self, RAIParameters, self.mobileSession4)
  
	          -- mobile side: expect OnHMIStatus on mobile side
	          self.mobileSession4:ExpectNotification("OnHMIStatus", 
	            {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"},
	            {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
	            :Times(2)
	            :Do(function(_,data)
	            	if data.payload.hmiLevel == "FULL" then

	            		local cidPutFile = self.mobileSession4:SendRPC("PutFile",
						{
							syncFileName = "icon.png",
							fileType = "GRAPHIC_PNG",
							persistentFile = false,
							systemFile = false
						}, "files/icon.png")

						self.mobileSession4:ExpectResponse(cidPutFile, { success = true, resultCode = "SUCCESS" })
						:Do(function(_,data)
							local cidSetAppIcon = self.mobileSession4:SendRPC("SetAppIcon",{ syncFileName = "icon.png" })
								--hmi side: expect UI.SetAppIcon request
								EXPECT_HMICALL("UI.SetAppIcon",
									{
										syncFileName = 
										{
											imageType = "DYNAMIC",
											value = PathToAppFolder .. "icon.png"
										}				
									})
									:Do(function(_,data)
										--hmi side: sending UI.SetAppIcon response
										self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
									end)
								
								--mobile side: expect SetAppIcon response
								self.mobileSession4:ExpectResponse(cidSetAppIcon, { resultCode = "SUCCESS", success = true })
									:ValidIf(function(_,data)
										local FileToCheck = config.pathToSDL .. "Icons/" .. tostring(RAIParameters.appID)
										local fileExistsResult = file_exists(FileToCheck, true)

										local aHandle = assert( io.popen( "ls " .. config.pathToSDL .. "Icons/" , 'r'))
										local ListOfFilesInStorageFolder = aHandle:read( '*a' )
										userPrint(33, "Content of storage folder: " ..tostring("\n" ..ListOfFilesInStorageFolder) )

										return fileExistsResult
									end)
						end)
	            	end
	            end)

	          self.mobileSession:ExpectNotification("OnHMIStatus", {})
	          	:Times(0)

            end)

            DelayedExp(1000)

        end)
end

function Test:CloseConnectionUnregisterApps()
	self.mobileConnection:Close()

	--hmi side: expected  BasicCommunication.OnAppUnregistered
    EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {unexpectedDisconnect = true})
      :Times(4)
      :Do(function(exp,data)
      	if exp.occurences == 4 then
      		local tcpConnection = tcp.Connection(config.mobileHost, config.mobilePort)
		    local fileConnection = file_connection.FileConnection("mobile.out", tcpConnection)
		    self.mobileConnection = mobile.MobileConnection(fileConnection)
		    self.mobileSession= mobile_session.MobileSession(
		    self,
		    self.mobileConnection)
		    event_dispatcher:AddConnection(self.mobileConnection)
		    self.mobileSession:ExpectEvent(events.connectedEvent, "Connection started")
		    self.mobileConnection:Connect()

      	end
      end)
end

function Test:IconsStringValuedAppIDForEachAndEveryApp()
	local RAIParameters = config.application1.registerAppInterfaceParams

	self.mobileSession.version = 4

	self.mobileSession:StartService(7)
	:Do(function()

	AppRegistration(self, RAIParameters)

	EXPECT_NOTIFICATION("OnHMIStatus", { systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
		:DoOnce(function(_,data)
			OnSystemRequestQueryApps(self, self.mobileSession, "FULL", "NOT_AUDIBLE", "correctJSON_icons.json")
		end)

	EXPECT_HMICALL("BasicCommunication.UpdateAppList",
		{applications = {
		   	{
		      	appName = RAIParameters.appName,
		      	--[=[TODO: remove after resolving APPLINK-16052
		      	deviceInfo = {
			        id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
			        isSDLAllowed = t rue,
			        name = "127.0.0.1",
			        transportType = "WIFI"
		      	}]=]
		   	}
		}},
		{applications = {
			{
		      	appName = RAIParameters.appName,
		      	--[=[TODO: remove after resolving APPLINK-16052
		      	deviceInfo = {
			        id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
			        isSDLAllowed = true,
			        name = "127.0.0.1",
			        transportType = "WIFI"
		      	}]=]
		   	},
		   	{
		      	appName = "Test application1",
		      	icon = config.pathToSDL .. "Icons/1",
		      	--[=[TODO: remove after resolving APPLINK-16052
		      	deviceInfo = {
			        id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
			        isSDLAllowed = true,
			        name = "127.0.0.1",
			        transportType = "WIFI"
		      	}]=]
		   	},
		   	{
		      	appName = "Test application2",
		      	icon = config.pathToSDL .. "Icons/2",
		      	--[=[TODO: remove after resolving APPLINK-16052
		      	deviceInfo = {
			        id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
			        isSDLAllowed = true,
			        name = "127.0.0.1",
			        transportType = "WIFI"
		      	}]=]
		   	},
		   	{
		      	appName = "Test application3",
		      	icon = config.pathToSDL .. "Icons/3",
		      	--[=[TODO: remove after resolving APPLINK-16052
		      	deviceInfo = {
			        id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0",
			        isSDLAllowed = true,
			        name = "127.0.0.1",
			        transportType = "WIFI"
		      	}]=]
		   	}
		}})
		:Times(2)
	 	:ValidIf(function(exp,data)
	 		if exp.occurences  == 1 then
                if #data.params.applications == 1 then
                  	return true
              	else 
                    userPrint( 31, "Application array in BasicCommunication.UpdateAppList contains "..tostring(#data.params.applications)..", expected 1" )
                    return false
              	end
            elseif exp.occurences  == 2 then
            	if #data.params.applications == 4 then
            		local statusValue = true
                  	for i=1,#data.params.applications do
                  		if data.params.applications[i].icon then
                  			userPrint(31, "SDL sends icon value " .. tostring(data.params.applications[i].icon) .. " for first registered app " .. tostring(data.params.applications[i].appName))
                  			statusValue = false

                  		end
                  	end
                  	return statusValue
              	else 
                    userPrint( 31, "Application array in BasicCommunication.UpdateAppList contains "..tostring(#data.params.applications)..", expected 4" )
                    return false
              	end
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

function Test:Postcondition_UnregisterApp_IconsStringValuedAppIDForEachAndEveryApp()
	UnregisterAppInterface_Success(self, self.mobileSession, self.applications[config.application1.registerAppInterfaceParams.appName])
end

--===================================================================================--
-- In case the .ini file defines "AppIconsAmountToRemove: 0" (zero), check that SDL never delete any of the icons in case the free space in "AppIconsFolder" is not enough to write a new icon, but log the appropriate error without writing this icon and continue normal operation as assigned by requirements
--===================================================================================--

SetEnableProtocol4ValueInIniFileTotrue(self, "NotDeletingOldestIconInCaseSpaceIsnotEnoughInAppIconsFolderAndAppIconsAmountToRemoveIsZero", _, true, "Icons", true, "1048576", true, "0", true)

function Test:Precondition_FullAppIconsFolderMaxSize_NotDeletingOldestIconInCaseSpaceIsnotEnoughInAppIconsFolderAndAppIconsAmountToRemoveIsZero()
	FullAppIconsFolder( "Icons" )
end

function Test:NotDeletingOldestIconInCaseSpaceIsnotEnoughInAppIconsFolderAndAppIconsAmountToRemoveIsZero()
	userPrint(34, "=================================== Test  Case ===================================")

	local RAIParameters = config.application1.registerAppInterfaceParams

	function CheckFunction()
		local StatusValue = true
		
		local ApplicationFileToCheck = config.pathToSDL .. tostring("Icons/" .. RAIParameters.appID)
		local OldFirstFileToCheck = config.pathToSDL .. tostring("Icons/icon1.png")
		local OldSecondFileToCheck = config.pathToSDL .. tostring("Icons/icon2.png")
		local OldThirdFileToCheck = config.pathToSDL .. tostring("Icons/icon3.png")

		local ApplicationFileExistsResult = file_exists(ApplicationFileToCheck)
		local OldFirstFileExistResult = file_exists(OldFirstFileToCheck)
		local OldSecondFileExistResult = file_exists(OldSecondFileToCheck)
		local OldThirdFileExistResult = file_exists(OldThirdFileToCheck)

		local aHandle = assert( io.popen( "ls " .. config.pathToSDL .. "Icons/" , 'r'))
		local ListOfFilesInStorageFolder = aHandle:read( '*a' )
		userPrint(33, "Content of storage folder: " ..tostring("\n" ..ListOfFilesInStorageFolder) )

		if ApplicationFileExistsResult ~= false then
			userPrint(31, tostring(RAIParameters.appID) .. " icon is added to AppIconsFolder in case free space is not enough")
			StatusValue = false
		end

		if 
			OldFirstFileExistResult ~= true or
			OldSecondFileExistResult ~= true or
			OldThirdFileExistResult ~= true then
				userPrint(31,"The oldest icons are deleted from AppIconsFolder")
				StatusValue = false
		end


		return StatusValue
	end

	StartSessionRegisterAppSetIcon(self, RAIParameters)
end

function Test:Postcondition_UnregisterApp_NotDeletingOldestIconInCaseSpaceIsnotEnoughInAppIconsFolderAndAppIconsAmountToRemoveIsZero()
	UnregisterAppInterface_Success(self, self.mobileSession, self.applications[config.application1.registerAppInterfaceParams.appName])
end

function Test:Postcondition_removeCreatedUserConnecttest()
  os.execute(" rm -f  ./user_modules/connecttest_icons.lua")
end











