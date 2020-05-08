---------------------------------------------------------------------------------------------
--ATF version: 2.2
--Created date: 17/Dec/2015
--Author: Ta Thanh Dong
---------------------------------------------------------------------------------------------
Test = require('connecttest')
require('cardinalities')
local events = require('events')
local mobile_session = require('mobile_session')
local functionId = require('function_id')
--UPDATED:
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
--ToDo: shall be removed when APPLINK-16610 is fixed
config.defaultProtocolVersion = 2
local storagePath = config.pathToSDL .. "storage/" ..config.application1.registerAppInterfaceParams.fullAppID.. "_" .. config.deviceMAC.. "/"
---------------------------------------------------------------------------------------------
-----------------------------Required Shared Libraries---------------------------------------
---------------------------------------------------------------------------------------------
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local SDLConfig = require('user_modules/shared_testcases/SmartDeviceLinkConfigurations')
local enumerationParameter = require('user_modules/shared_testcases/testCasesForEnumerationParameter')
local stringParameter = require('user_modules/shared_testcases/testCasesForStringParameter')
require('user_modules/AppTypes')

local appIDAndDeviceMac = config.application1.registerAppInterfaceParams.fullAppID.. "_" .. config.deviceMAC.. "/"
local strIvsu_cacheFolder = "/tmp/fs/mp/images/ivsu_cache/"

APIName = "SystemRequest" -- set API name
local AppStorageFolder = SDLConfig:GetValue("AppStorageFolder")
local PTFile = "./files/PTU_ForSystemRequest.json"

Apps = {}
Apps[1] = {}
Apps[1].storagePath = config.pathToSDL .. "storage/" .. "/"..config.application1.registerAppInterfaceParams.fullAppID.. "_" .. config.deviceMAC.. "/"
Apps[1].appName = config.application1.registerAppInterfaceParams.appName
local SystemFilesPath = SDLConfig:GetValue("SystemFilesPath")

---------------------------------------------------------------------------------------------
------------------------------------------Common functions-----------------------------------
---------------------------------------------------------------------------------------------
--Process different audio states for media and non-media application
local audibleState

if commonFunctions:isMediaApp() then
	audibleState = "AUDIBLE"
else
	audibleState = "NOT_AUDIBLE"
end

function DelayedExp()
  local event = events.Event()
  event.matches = function(self, e) return self == e end
  EXPECT_EVENT(event, "Delayed event")
  RUN_AFTER(function()
              RAISE_EVENT(event, event)
            end, 2000)
end

function RegisterApplication(self)
		-- body
		local corrID = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)

		EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
		:Do(function (_, data)
			-- body
			applicationID = data.params.application.appID
		end)

		EXPECT_RESPONSE(corrID, {success = true})

		-- delay - bug of ATF - it is not wait for UpdateAppList and later
		-- line appID = self.applications["Test Application"]} will not assign appID
		DelayedExp(1000)
	end
---------------------------------------------------------------------------------------------
-------------------------- Overwrite These Functions For This Script-------------------------
---------------------------------------------------------------------------------------------
--Specific functions for this script
--1. createRequest()
--2. verify_SUCCESS_Case(Request)
---------------------------------------------------------------------------------------------

--Create default request
function Test:createRequest()

	return 	{
				fileName = "PolicyTableUpdate",
				requestType = "HTTP"
			}

end

function Test:createExpectedResultOnHMI(Request)

	local FileName
	if Request.fileName == nil then
		FileName = nil
	else
		FileName = SystemFilesPath .. "/"  .. Request.fileName
	end

	return 	{
				fileName = FileName,
				requestType = Request.requestType,
				appID = Apps[1].appID
			}
end


--This function sends a request from mobile and verify result on HMI and mobile for SUCCESS resultCode cases.
function Test:verify_SUCCESS_Case(Request)

	--mobile side: sending the request
	local cid = self.mobileSession:SendRPC("SystemRequest", Request, PTFile)


	--hmi side: expect the request
	local HMIExpectedResult = self:createExpectedResultOnHMI(Request)
	EXPECT_HMICALL("BasicCommunication.SystemRequest", HMIExpectedResult)
	:Do(function(_,data)
		--hmi side: sending SystemRequest response
		self.hmiConnection:SendResponse(data.id,"BasicCommunication.SystemRequest", "SUCCESS", {})
	end)

	--mobile side: expect SystemRequest response
	EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})

end

local function userPrint( color, message)
  print ("\27[" .. tostring(color) .. "m " .. tostring(message) .. " \27[0m")
end
---------------------------------------------------------------------------------------------
-------------------------------------------Automated Preconditions-------------------------------------
---------------------------------------------------------------------------------------------
--Updated--

function Test:StopSDLToBackUpPreloadedPt( ... )
		-- body
		StopSDL()
		DelayedExp(1000)
	end

	function Test:BackUpPreloadedPt()
		-- body
		os.execute('cp ' .. config.pathToSDL .. 'sdl_preloaded_pt.json' .. ' ' .. config.pathToSDL .. 'backup_sdl_preloaded_pt.json')
		os.execute('rm ' .. config.pathToSDL .. 'policy.sqlite')
	end

	function Test:UpdatePreloadedJson(pathToFile)
		local src_preloaded_json = config.pathToSDL .."sdl_preloaded_pt.json"
    	local dest               = "files/PTU_ForSystemRequest.json"
    	local filecopy = "cp " .. src_preloaded_json .."  " .. dest
		
	end

local function StartSDLAfterChangePreloaded()
		-- body

		Test["Precondition_StartSDL"] = function(self)
			StartSDL(config.pathToSDL, config.ExitOnCrash)
			DelayedExp(1000)
		end

		Test["Precondition_InitHMI_1"] = function(self)
			self:initHMI()
		end

		Test["Precondition_InitHMI_onReady_1"] = function(self)
			self:initHMI_onReady()
		end

		Test["Precondition_ConnectMobile_1"] = function(self)
			self:connectMobile()
		end

		Test["Precondition_StartSession_1"] = function(self)
			self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
		end

	end

	StartSDLAfterChangePreloaded()

	function Test:RestorePreloadedPt()
		-- body
		os.execute('cp ' .. config.pathToSDL .. 'backup_sdl_preloaded_pt.json' .. ' ' .. config.pathToSDL .. 'sdl_preloaded_pt.json')
		os.execute('rm ' .. config.pathToSDL .. 'backup_sdl_preloaded_pt.json')
	end

	function Test:RegisterApp()
		-- body
		self.mobileSession:StartService(7)
		:Do(function (_, data)
			-- body
			RegisterApplication(self)
		end)
	end

		function Test:ActivationApp()
			--hmi side: sending SDL.ActivateApp request
			-- applicationID = self.applications[ config.application1.registerAppInterfaceParams.appName]
			self:activationApp(applicationID)
			
			--mobile side: expect notification
			EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"}) 
		end
--End Updated--	

	--Get appID Value on HMI side
	
	function Test:GetAppID()
		Apps[1].appID = self.applications[Apps[1].appName]
	end

function Test:activationApp(appIDValue)
			--hmi side: sending SDL.ActivateApp request			
			local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = appIDValue})
			
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
							EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
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
		end
	-- Update policy table
	local PermissionLines_SystemRequest =
[[					"SystemRequest": {
						"hmi_levels": [
						  "BACKGROUND",
						  "FULL",
						  "LIMITED",
						  "NONE"
						]
					  }]]


	local PermissionLinesForBase4 = PermissionLines_SystemRequest .. ",\n"
	local PermissionLinesForGroup1 = nil
	local PermissionLinesForApplication = nil
	--TODO: PT is blocked by ATF defect APPLINK-19188
	--local PTName = testCasesForPolicyTable:createPolicyTableFile(PermissionLinesForBase4, PermissionLinesForGroup1, PermissionLinesForApplication, {"SystemRequest"})
	--testCasesForPolicyTable:updatePolicy(PTName)


	local function APPLINK_21366()

	--Requirements:
		--APPLINK-21366->req_3: SDL behaviour when app sends SystemRequest (requestType = NAVIGATION, <fileName>) and requested <fileName> exists in app sub-directory
		--Verification criteria:
		--SDL transfers SystemRequest(NAVIGATION) to HMI and responds with <resultCode_received_from_HMI> to mobile app

		---------------------------------------------------------------------------------------------------------------------------------------

		-- SDL receives SystemRequest(NAVIGATION) with systemFile = false and <fileName> existent in app sub-directory, transfers request to HMI and responds "SUCCESS" to mobile app

				function Test:Precond_PutFileSystemFileFalse()

				local temp = {
						syncFileName ="icon.png",
						fileType ="GRAPHIC_PNG",
						systemFile = false,
						offset = 0,
						length = 11600
					}

					local cid = self.mobileSession:SendRPC("PutFile", temp, "files/icon.png")
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })


				 --hmi side: expect OnPutFile notification
                                 EXPECT_HMINOTIFICATION("BasicCommunication.OnPutFile", { syncFileName = storagePath.."icon.png" })

				end

				function Test:SystemRequest_NAVIGATION_FileExists()

					--mobile side: sending SystemRequest request
					local Request  = 	{
											requestType = "NAVIGATION",
											fileName = "icon.png"
										}

					--mobile side: sending the request
					local cid = self.mobileSession:SendRPC("SystemRequest", Request)


					--hmi side: expect the request
					EXPECT_HMICALL("BasicCommunication.SystemRequest")
					:Do(function(_,data)
						--hmi side: sending SystemRequest response
						self.hmiConnection:SendResponse(data.id,"BasicCommunication.SystemRequest", "SUCCESS", {})
					end)


					--mobile side: expect SystemRequest response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
				end


		---------------------------------------------------------------------------------------------------------

	--SDL transfers SystemRequest(NAVIGATION) to HMI and responds with "ABORTED" to mobile app

			function Test:PreconditionForABORTED_PutFile()

				local temp = {
						syncFileName ="icon.png",
						fileType ="GRAPHIC_PNG",
						persistentFile =false,
						systemFile = false,
						offset = 0,
						length = 11600
					}

					local cid = self.mobileSession:SendRPC("PutFile", temp, "files/icon.png")
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

				--hmi side: expect OnPutFile notification
                                 EXPECT_HMINOTIFICATION("BasicCommunication.OnPutFile", { syncFileName = storagePath.."icon.png" })

			end

				function Test:SystemRequest_NAVI_ABORTED()

					--mobile side: sending SystemRequest request
					local Request  = 	{
											requestType = "NAVIGATION",
											fileName = "icon.png"
										}

					--mobile side: sending the request
					local cid = self.mobileSession:SendRPC("SystemRequest", Request)


					--hmi side: expect the request
					EXPECT_HMICALL("BasicCommunication.SystemRequest")
					:Do(function(_,data)
						--hmi side: sending SystemRequest response
						self.hmiConnection:SendResponse(data.id,"BasicCommunication.SystemRequest", "ABORTED", {})
					end)


					--mobile side: expect SystemRequest response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "ABORTED"})


				end

---------------------------------------------------------------------------------------------------

	--SDL transfers SystemRequest(NAVIGATION) to HMI and responds with "WARNINGS" to mobile app


				function Test:PreconditionForWARNINGS_PutFile()

				local temp = {
						syncFileName ="icon.png",
						fileType ="GRAPHIC_PNG",
						persistentFile =false,
						systemFile = false,
						offset = 0,
						length = 11600
					}

					local cid = self.mobileSession:SendRPC("PutFile", temp, "files/icon.png")
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

					--hmi side: expect OnPutFile notification
                                        EXPECT_HMINOTIFICATION("BasicCommunication.OnPutFile", { syncFileName = storagePath.."icon.png" })

				end

				function Test:SystemRequest_NAVI_WARNINGS()

					--mobile side: sending SystemRequest request
					local Request  = 	{
											requestType = "NAVIGATION",
											fileName = "icon.png"
										}

					--mobile side: sending the request
					local cid = self.mobileSession:SendRPC("SystemRequest", Request)


					--hmi side: expect the request
					EXPECT_HMICALL("BasicCommunication.SystemRequest")
					:Do(function(_,data)
						--hmi side: sending SystemRequest response
						self.hmiConnection:SendResponse(data.id,"BasicCommunication.SystemRequest", "WARNINGS", {})
					end)


					--mobile side: expect SystemRequest response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "WARNINGS"})


				end

-------------------------------------------------------------------------------------------------------------

	--SDL transfers SystemRequest(NAVIGATION) to HMI and responds with "TIMED_OUT" to mobile app


			function Test:PreconditionForTIMED_OUT_PutFile()

				local temp = {
						syncFileName ="icon.png",
						fileType ="GRAPHIC_PNG",
						persistentFile =false,
						systemFile = false,
						offset = 0,
						length = 11600
					}

					local cid = self.mobileSession:SendRPC("PutFile", temp, "files/icon.png")
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

					--hmi side: expect OnPutFile notification
                                        EXPECT_HMINOTIFICATION("BasicCommunication.OnPutFile", { syncFileName = storagePath.."icon.png" })
			end

				function Test:SystemRequest_NAVI_TIMED_OUT()

					--mobile side: sending SystemRequest request
					local Request  = 	{
											requestType = "NAVIGATION",
											fileName = "icon.png"
										}

					--mobile side: sending the request
					local cid = self.mobileSession:SendRPC("SystemRequest", Request)


					--hmi side: expect the request
					EXPECT_HMICALL("BasicCommunication.SystemRequest")
					:Do(function(_,data)
						--hmi side: sending SystemRequest response
						self.hmiConnection:SendResponse(data.id,"BasicCommunication.SystemRequest", "TIMED_OUT", {})
					end)


					--mobile side: expect SystemRequest response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "TIMED_OUT"})


				end

----------------------------------------------------------------------------------------------------------

	--SDL transfers SystemRequest(NAVIGATION) to HMI and responds with "IGNORED" to mobile app


			function Test:PreconditionForIGNORED_PutFile()

				local temp = {
						syncFileName ="icon.png",
						fileType ="GRAPHIC_PNG",
						persistentFile =false,
						systemFile = false,
						offset = 0,
						length = 11600
					}

					local cid = self.mobileSession:SendRPC("PutFile", temp, "files/icon.png")
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

					--hmi side: expect OnPutFile notification
                                        EXPECT_HMINOTIFICATION("BasicCommunication.OnPutFile", { syncFileName = storagePath.."icon.png" })

			end

			function Test:SystemRequest_NAVI_IGNORED()

					--mobile side: sending SystemRequest request
					local Request  = 	{
											requestType = "NAVIGATION",
											fileName = "icon.png"
										}

					--mobile side: sending the request
					local cid = self.mobileSession:SendRPC("SystemRequest", Request)


					--hmi side: expect the request
					EXPECT_HMICALL("BasicCommunication.SystemRequest")
					:Do(function(_,data)
						--hmi side: sending SystemRequest response
						self.hmiConnection:SendResponse(data.id,"BasicCommunication.SystemRequest", "IGNORED", {})
					end)


					--mobile side: expect SystemRequest response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "IGNORED"})


			end

----------------------------------------------------------------------------------------------------------------

		--APPLINK-21366->req_4: SDL behaviour when app sends SystemRequest (requestType = NAVIGATION, <fileName>) and requested <fileName> doesn't exist in app sub-directory
		--Verification criteria:
		--SDL responds REJECTED to mobile app

		-- SDL receives SystemRequest(NAVIGATION) with <fileName> not existent in app sub-directory so rejects such SystemRequest


			function Test:SystemRequest_NAVIGATION_NotExistentFile()

					--mobile side: sending SystemRequest request
					local Request  = 	{
											requestType = "NAVIGATION",
											fileName = "NotExistentFile.png"
										}

					--mobile side: sending the request
					local cid = self.mobileSession:SendRPC("SystemRequest", Request)


					--hmi side: expect the request
					EXPECT_HMICALL("BasicCommunication.SystemRequest")
					:Do(function(_,data)
						--hmi side: sending SystemRequest response
						self.hmiConnection:SendResponse(data.id,"BasicCommunication.SystemRequest", "SUCCESS", {})
					end)
                                        :Times(0)


					--mobile side: expect SystemRequest response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "REJECTED"})
			end


	APPLINK_21366()
end

-----------------------------------------------------------------------------------------------
-------------------------------------------TEST BLOCK I----------------------------------------
--------------------------------Check normal cases of Mobile request---------------------------
-----------------------------------------------------------------------------------------------

--Requirements:
  	--SDLAQ-CRS-2638: SystemRequest_request
  		--1. SDL re-sends the request to HMI via BC.SystemRequest adding the appID string value (which is the app`s ID that it registered with) IN CASE SDL receives SystemRequest RPC with valid params from mobile app
  		--2. SDL stores 'fileName' file in the predefined directory and then re-sends request to HMI including 'fileName' name IN CASE mobile app provides hybrid data within request.

  	--SDLAQ-CRS-2640: SystemRequest_response: The response contains 2 mandatory parameters "success" and "resultCode".

--------------------------------------------------------------------------------------------------------------------------

--List of parameters:
    --1. requestType: type="RequestType" mandatory="true"
    --2. fileName: type="String" maxlength="255" mandatory="false"
--------------------------------------------------------------------------------------------------------------------------

	local RequestType = {
							"HTTP",
							"FILE_RESUME",
							"AUTH_REQUEST",
							"AUTH_CHALLENGE",
							"AUTH_ACK",
							"PROPRIETARY",
							--"QUERY_APPS", --It is covered by test case APPLINK-18301: 01[ATF]_TC_OnSystemRequest_QUERY_APPS
							--"LAUNCH_APP", -> applicable to OnSystemRequest only
							--"LOCK_SCREEN_ICON_URL", -> applicable to OnSystemRequest only
							"TRAFFIC_MESSAGE_CHANNEL", --SDL transfer these types to HMI and then wait for response
							"DRIVER_PROFILE",
							"VOICE_SEARCH",
							"NAVIGATION",
							"PHONE",
							"CLIMATE",
							"SETTINGS",
							"VEHICLE_DIAGNOSTICS",
							"EMERGENCY",
							"MEDIA",
							"FOTA"
						}


	--Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup("Test suite: Check normal cases of Mobile request")

-----------------------------------------------------------------------------------------------
--Parameter 1: requestType: type="RequestType" mandatory="true"
-----------------------------------------------------------------------------------------------
--List of test cases for String enumeration parameter:
	--1. IsMissed
	--2. IsWrongDataType
	--3. IsExistentValues
	--4. IsNonExistentValue
	--5. IsEmpty
-----------------------------------------------------------------------------------------------

	local Request = {fileName = "PolicyTableUpdate", requestType = "HTTP"}
	enumerationParameter:verify_Enum_String_Parameter(Request, {"requestType"}, RequestType, true)

-----------------------------------------------------------------------------------------------
--Parameter 2: fileName: type="String" maxlength="255" mandatory="false"
-----------------------------------------------------------------------------------------------
--List of test cases for String type parameter:
	--1. IsMissed
	--2. IsWrongType
	--3. IsLowerBound/IsEmpty
	--4. IsOutLowerBound/IsEmpty
	--5. IsUpperBound
	--6. IsOutUpperBound
	--7. IsInvalidCharacters
-----------------------------------------------------------------------------------------------
--TODO: Update script according to answer on APPLINK-20419
	local TestData = 	{
							{RequestType = "HTTP", 						Is_fileName_mandatory = true},
							{RequestType = "FILE_RESUME", 				Is_fileName_mandatory = true},
							{RequestType = "AUTH_REQUEST", 				Is_fileName_mandatory = true},
							{RequestType = "AUTH_CHALLENGE", 			Is_fileName_mandatory = true},
							{RequestType = "AUTH_ACK", 					Is_fileName_mandatory = true},
							{RequestType = "PROPRIETARY", 				Is_fileName_mandatory = false},
							--{RequestType = "QUERY_APPS",  				Is_fileName_mandatory = true}, --It is covered by test case APPLINK-18301: 01[ATF]_TC_OnSystemRequest_QUERY_APPS
							{RequestType = "TRAFFIC_MESSAGE_CHANNEL", 	Is_fileName_mandatory = true},
							{RequestType = "DRIVER_PROFILE", 			Is_fileName_mandatory = true},
							{RequestType = "VOICE_SEARCH",  			Is_fileName_mandatory = true},
							{RequestType = "NAVIGATION", 				Is_fileName_mandatory = true},
							{RequestType = "PHONE", 					Is_fileName_mandatory = true},
							{RequestType = "CLIMATE", 					Is_fileName_mandatory = true},
							{RequestType = "SETTINGS", 					Is_fileName_mandatory = true},
							{RequestType = "VEHICLE_DIAGNOSTICS", 		Is_fileName_mandatory = true},
							{RequestType = "EMERGENCY", 				Is_fileName_mandatory = true},
							{RequestType = "MEDIA",   					Is_fileName_mandatory = true},
							{RequestType = "FOTA",						Is_fileName_mandatory = true}
						}


	for i =1, #TestData do

		local Request = {fileName = "PolicyTableUpdate", requestType = TestData[i].RequestType}
		TestCaseNamePrefix = "requestType_"..TestData[i].RequestType
		stringParameter:verify_String_Parameter(Request, {"fileName"}, {1, 255}, TestData[i].Is_fileName_mandatory)

	end

----------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK II----------------------------------------
-----------------------------Check special cases of Mobile request----------------------------
----------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------------
--List of test cases for special cases of Mobile request:
	--1. InvalidJsonSyntax
	--2. InvalidStructure
	--3. FakeParams_IsNotFromAnyAPI (APPLINK-14765 SDL must cut off the fake parameters from requests, responses and notifications received from HMI)
	--4. FakeParameter_IsFromAnotherAPI
	--5. MissedAllPArameters
	--6. CorrelationId_IsDuplicated
-----------------------------------------------------------------------------------------------

	local function SpecialRequestChecks()


		--Print new line to separate new test cases group
		commonFunctions:newTestCasesGroup("Test suite: Check special cases of Mobile request")

		--1. InvalidJsonSyntax
		----------------------------------------------------------------------------------------------
			--replace ":' by ";"
			local Payload = '{"fileName";"PolicyTableUpdate","requestType":"HTTP"}'
			commonTestCases:VerifyInvalidJsonRequest(functionId[APIName], Payload, "SystemRequest_InvalidJsonSyntax_INVALID_DATA")


		--2. InvalidStructure
		----------------------------------------------------------------------------------------------
			--move fileName into an array
			local Payload = '{{"fileName":"PolicyTableUpdate"},"requestType":"HTTP"}'
			commonTestCases:VerifyInvalidJsonRequest(functionId[APIName], Payload, "SystemRequest_InvalidStructure_INVALID_DATA")


		--3. FakeParams_IsNotFromAnyAPI (APPLINK-14765 SDL must cut off the fake parameters from requests, responses and notifications received from HMI)
		----------------------------------------------------------------------------------------------
			function Test:SystemRequest_FakeParams_IsNotFromAnyAPI()

					--mobile side: sending SystemRequest request
					local Request  = 	{
											requestType = "HTTP",
											fileName = "PolicyTableUpdate",
											fakeParam = "icon.png"
										}

					--mobile side: sending the request
					local cid = self.mobileSession:SendRPC("SystemRequest", Request, PTFile)


					--hmi side: expect the request
					EXPECT_HMICALL("BasicCommunication.SystemRequest")
					:Do(function(_,data)
						--hmi side: sending SystemRequest response
						self.hmiConnection:SendResponse(data.id,"BasicCommunication.SystemRequest", "SUCCESS", {})
					end)
					:ValidIf(function(_,data)
						if data.params.fakeParam then
							commonFunctions:printError(" SDL re-sends fakeParam parameters to HMI")
							return false
						else
							return true
						end
					end)

					--mobile side: expect SystemRequest response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
				end


		--4. FakeParameter_IsFromAnotherAPI
		----------------------------------------------------------------------------------------------
			function Test:SystemRequest_FakeParameter_IsFromAnotherAPI()

					--mobile side: sending SystemRequest request
					local Request  = 	{
											requestType = "HTTP",
											fileName = "PolicyTableUpdate",
											syncFileName = "icon.png"
										}

					--mobile side: sending the request
					local cid = self.mobileSession:SendRPC("SystemRequest", Request, PTFile)


					--hmi side: expect the request
					EXPECT_HMICALL("BasicCommunication.SystemRequest")
					:Do(function(_,data)
						--hmi side: sending SystemRequest response
						self.hmiConnection:SendResponse(data.id,"BasicCommunication.SystemRequest", "SUCCESS", {})
					end)
					:ValidIf(function(_,data)
						if data.params.syncFileName then
							commonFunctions:printError(" SDL re-sends fakeParam parameters to HMI")
							return false
						else
							return true
						end
					end)

					--mobile side: expect SystemRequest response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
				end


		--5. MissedAllPArameters
		----------------------------------------------------------------------------------------------
			commonTestCases:VerifyRequestIsMissedAllParameters()


		--6. CorrelationId_IsDuplicated
		----------------------------------------------------------------------------------------------
			function Test:SystemRequest_CorrelationId_IsDuplicated()

				--mobile side: sending SystemRequest request
				local Request  = 	{
										requestType = "HTTP",
										fileName = "PolicyTableUpdate"
									}

				--mobile side: sending the request
				local cid = self.mobileSession:SendRPC("SystemRequest", Request, PTFile)

				--request from mobile side
				local msg =
				{
				  serviceType      = 7,
				  frameInfo        = 0,
				  rpcType          = 0,
				  rpcFunctionId    = functionId[APIName],
				  rpcCorrelationId = cid,
				  payload          = '{"fileName":"PolicyTableUpdate","requestType":"HTTP"}'
				}

				--Read binary data from file and set to binaryData parameter of msg
				local f = assert(io.open(PTFile))
				msg.binaryData = f:read("*all")

				--hmi side: expect the request
				EXPECT_HMICALL("BasicCommunication.SystemRequest")
				:Do(function(exp,data)
					if exp.occurences == 1 then

						self.mobileSession:Send(msg)
					end

					--hmi side: sending SystemRequest response
					self.hmiConnection:SendResponse(data.id,"BasicCommunication.SystemRequest", "SUCCESS", {})
				end)
				:Times(2)

				--mobile side: expect SystemRequest response
				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
				:Times(2)

			end

	end

	SpecialRequestChecks()


-----------------------------------------------------------------------------------------------
-------------------------------------------TEST BLOCK III--------------------------------------
----------------------------------Check normal cases of HMI response---------------------------
-----------------------------------------------------------------------------------------------
--Requirement id in JAMA or JIRA:
	--SDLAQ-CRS-2640: SystemRequest_response
		--Verification criteria:
			--1. The response contains 2 mandatory parameters "success" and "resultCode".
----------------------------------------------------------------------------------------------
--List of parameters:
	--1. success: type="Boolean" true if successful; false, if failed
    --2. resultCode: type="Result"
		--SUCCESS
		--INVALID_DATA
		--OUT_OF_MEMORY
		--TOO_MANY_PENDING_REQUESTS
		--APPLICATION_NOT_REGISTERED
		--GENERIC_ERROR
		--REJECTED
		--WARNINGS
		--DISALLOWED
		--UNSUPPORTED_RESOURCE
-----------------------------------------------------------------------------------------------

	--Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup("Test suite: Check normal cases of HMI response")



-----------------------------------------------------------------------------------------------
--Parameter 1: resultCode
-----------------------------------------------------------------------------------------------
--List of test cases:
	--1. IsMissed
	--2. IsValidValues
	--3. IsNotExist
	--4. IsEmpty
	--5. IsWrongType
	--6. IsInvalidCharacter - \n, \t
-----------------------------------------------------------------------------------------------

	local function verify_resultCode_parameter()


		--Print new line to separate new test cases group
		commonFunctions:newTestCasesGroup("Test suite: Check resultCode parameter")
		-----------------------------------------------------------------------------------------

		--1. IsMissed
		Test[APIName.."_Response_resultCode_IsMissed_SendResponse"] = function(self)

			--mobile side: sending the request
			local Request = Test:createRequest()
			local cid = self.mobileSession:SendRPC("SystemRequest", Request, PTFile)

			--hmi side: expect the request
			local HMIExpectedResult = self:createExpectedResultOnHMI(Request)
			EXPECT_HMICALL("BasicCommunication.SystemRequest", HMIExpectedResult)
			:Do(function(_,data)
				--hmi side: sending SystemRequest response
				--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"BasicCommunication.SystemRequest", "code":0}}')
				  self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"BasicCommunication.SystemRequest"}}')
			end)

			--mobile side: expect the response
			-- TODO: update after resolving APPLINK-14765
			-- EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
			EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})

		end
		-----------------------------------------------------------------------------------------

		Test[APIName.."_Response_resultCode_IsMissed_SendError"] = function(self)

			--mobile side: sending the request
			local Request = Test:createRequest()
			local cid = self.mobileSession:SendRPC("SystemRequest", Request, PTFile)

			--hmi side: expect the request
			local HMIExpectedResult = self:createExpectedResultOnHMI(Request)
			EXPECT_HMICALL("BasicCommunication.SystemRequest", HMIExpectedResult)
			:Do(function(_,data)
				--hmi side: sending the response
				--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"BasicCommunication.SystemRequest","code":0}}')
				  self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"BasicCommunication.SystemRequest"}}')
			end)


			--mobile side: expect the response
			-- TODO: update after resolving APPLINK-14765
			-- EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
			EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})

		end
		-----------------------------------------------------------------------------------------



		--2. IsValidValue
		local resultCodes = {
								{resultCode = "SUCCESS", 					success =  true},
								{resultCode = "INVALID_DATA", 				success =  false},
								{resultCode = "OUT_OF_MEMORY", 				success =  false},
								{resultCode = "TOO_MANY_PENDING_REQUESTS", 	success =  false},
								{resultCode = "APPLICATION_NOT_REGISTERED", success =  false},
								{resultCode = "GENERIC_ERROR", 				success =  false},
								{resultCode = "REJECTED", 					success =  false},
								{resultCode = "DISALLOWED", 				success =  false},
								{resultCode = "USER_DISALLOWED", 			success =  false},
								{resultCode = "UNSUPPORTED_RESOURCE",		success =  false},
								{resultCode = "WARNINGS", 					success =  true}
							}

		for i =1, #resultCodes do

			Test[APIName.."_resultCode_IsValidValues_" .. resultCodes[i].resultCode .."_SendResponse"] = function(self)

				--mobile side: sending the request
				local Request = Test:createRequest()
				local cid = self.mobileSession:SendRPC("SystemRequest", Request, PTFile)

				--hmi side: expect the request
				local HMIExpectedResult = self:createExpectedResultOnHMI(Request)
				EXPECT_HMICALL("BasicCommunication.SystemRequest", HMIExpectedResult)
				:Do(function(_,data)
					--hmi side: sending the response
					self.hmiConnection:SendResponse(data.id, data.method, resultCodes[i].resultCode, {})
				end)

				--mobile side: expect the response
				EXPECT_RESPONSE(cid, { success = resultCodes[i].success, resultCode = resultCodes[i].resultCode})

			end
			-----------------------------------------------------------------------------------------

			Test[APIName.."_resultCode_IsValidValues_" .. resultCodes[i].resultCode .."_SendError"] = function(self)

				--mobile side: sending the request
				local Request = Test:createRequest()
				local cid = self.mobileSession:SendRPC("SystemRequest", Request, PTFile)

				--hmi side: expect the request
				local HMIExpectedResult = self:createExpectedResultOnHMI(Request)
				EXPECT_HMICALL("BasicCommunication.SystemRequest", HMIExpectedResult)
				:Do(function(_,data)
					--hmi side: sending the response
					self.hmiConnection:SendError(data.id, data.method, resultCodes[i].resultCode, "info")
				end)

				--mobile side: expect the response
				EXPECT_RESPONSE(cid, { success = resultCodes[i].success, resultCode = resultCodes[i].resultCode, info = "info"})

			end
			-----------------------------------------------------------------------------------------

		end
		-----------------------------------------------------------------------------------------



		--3. IsNotExist
		--4. IsEmpty
		--5. IsWrongType
		--6. IsInvalidCharacter - \n, \t
		local testData = 	{
								{value = "ANY", 	name = "IsNotExist"},
								{value = "", 		name = "IsEmpty"},
								{value = 123, 		name = "IsWrongType"},
								{value = "a\nb", 	name = "IsInvalidCharacter_NewLine"},
								{value = "a\tb", 	name = "IsInvalidCharacter_Tab"}
							}

		for i =1, #testData do

			Test[APIName.."_resultCode_" .. testData[i].name .."_SendResponse"] = function(self)

				--mobile side: sending the request
				local Request = Test:createRequest()
				local cid = self.mobileSession:SendRPC("SystemRequest", Request, PTFile)

				--hmi side: expect the request
				local HMIExpectedResult = self:createExpectedResultOnHMI(Request)
				EXPECT_HMICALL("BasicCommunication.SystemRequest", HMIExpectedResult)
				:Do(function(_,data)
					--hmi side: sending the response
					self.hmiConnection:SendResponse(data.id, data.method, testData[i].value, {})
				end)

				--mobile side: expect the response
				-- TODO: update after resolving APPLINK-14765
				-- EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
				EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})

			end
			-----------------------------------------------------------------------------------------

			Test[APIName.."_resultCode_" .. testData[i].name .."_SendError"] = function(self)

				--mobile side: sending the request
				local Request = Test:createRequest()
				local cid = self.mobileSession:SendRPC("SystemRequest", Request, PTFile)

				--hmi side: expect the request
				local HMIExpectedResult = self:createExpectedResultOnHMI(Request)
				EXPECT_HMICALL("BasicCommunication.SystemRequest", HMIExpectedResult)
				:Do(function(_,data)
					--hmi side: sending the response
					self.hmiConnection:SendError(data.id, data.method, testData[i].value)
				end)

				--mobile side: expect the response
				-- TODO: update after resolving APPLINK-14765
				-- EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
				EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})


			end
			-----------------------------------------------------------------------------------------

		end
		-----------------------------------------------------------------------------------------

	end

	verify_resultCode_parameter()



-----------------------------------------------------------------------------------------------
--Parameter 2: method
-----------------------------------------------------------------------------------------------
--List of test cases:
	--1. IsMissed
	--2. IsValidValue
	--3. IsNotExist
	--4. IsEmpty
	--5. IsWrongType
	--6. IsInvalidCharacter - \n, \t
-----------------------------------------------------------------------------------------------

	local function verify_method_parameter()


		--Print new line to separate new test cases group
		commonFunctions:newTestCasesGroup("Test suite: Check method parameter")
		-----------------------------------------------------------------------------------------

		--1. IsMissed
		Test[APIName.."_Response_method_IsMissed_GENERIC_ERROR_SendResponse"] = function(self)

			--mobile side: sending the request
			local Request = Test:createRequest()
			local cid = self.mobileSession:SendRPC("SystemRequest", Request, PTFile)

			--hmi side: expect the request
			local HMIExpectedResult = self:createExpectedResultOnHMI(Request)
			EXPECT_HMICALL("BasicCommunication.SystemRequest", HMIExpectedResult)
			:Do(function(_,data)
				--hmi side: sending the response
				--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"BasicCommunication.SystemRequest","code":0}}')
				  self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"code":0}}')

			end)


			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
			:Timeout(13000)

		end

		Test[APIName.."_Response_method_IsMissed_GENERIC_ERROR_SendError"] = function(self)

			--mobile side: sending the request
			local Request = Test:createRequest()
			local cid = self.mobileSession:SendRPC("SystemRequest", Request, PTFile)

			--hmi side: expect the request
			local HMIExpectedResult = self:createExpectedResultOnHMI(Request)
			EXPECT_HMICALL("BasicCommunication.SystemRequest", HMIExpectedResult)
			:Do(function(_,data)
				--hmi side: sending the response
				--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"BasicCommunication.SystemRequest"},"code":22,"message":"The unknown issue occurred"}}')
				  self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{},"code":22,"message":"The unknown issue occurred"}}')

			end)


			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
			:Timeout(13000)

		end
		-----------------------------------------------------------------------------------------

		--2. IsValidValue: Covered by many test cases

		--3. IsNotExist
		--4. IsEmpty
		--5. IsWrongType
		--6. IsInvalidCharacter - \n, \t
		local Methods = {
							{method = "ANY", 	name = "IsNotExist"},
							{method = "", 		name = "IsEmpty"},
							{method = 123, 		name = "IsWrongType"},
							{method = "a\nb", 	name = "IsInvalidCharacter_NewLine"},
							{method = "a\tb", 	name = "IsInvalidCharacter_Tab"}
						}

		for i =1, #Methods do

			Test[APIName.."_Response_method_" .. Methods[i].name .."_GENERIC_ERROR_SendResponse"] = function(self)

				--mobile side: sending the request
				local Request = Test:createRequest()
				local cid = self.mobileSession:SendRPC("SystemRequest", Request, PTFile)

				--hmi side: expect the request
				local HMIExpectedResult = self:createExpectedResultOnHMI(Request)
				EXPECT_HMICALL("BasicCommunication.SystemRequest", HMIExpectedResult)
				:Do(function(_,data)
					--hmi side: sending the response
					--self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					  self.hmiConnection:SendResponse(data.id, Methods[i].method, "SUCCESS", {})

				end)

				--mobile side: expect the response
				EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
				:Timeout(13000)

			end
			-----------------------------------------------------------------------------------------

			Test[APIName.."_Response_method_" .. Methods[i].name .."_GENERIC_ERROR_SendError"] = function(self)

				--mobile side: sending the request
				local Request = Test:createRequest()
				local cid = self.mobileSession:SendRPC("SystemRequest", Request, PTFile)

				--hmi side: expect the request
				local HMIExpectedResult = self:createExpectedResultOnHMI(Request)
				EXPECT_HMICALL("BasicCommunication.SystemRequest", HMIExpectedResult)
				:Do(function(_,data)
					--hmi side: sending the response
					--self.hmiConnection:SendError(data.id, data.method, "TOO_MANY_PENDING_REQUESTS", "info")
					  self.hmiConnection:SendError(data.id, Methods[i].method, "TOO_MANY_PENDING_REQUESTS", "info")

				end)

				--mobile side: expect the response
				EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
				:Timeout(13000)


			end
			-----------------------------------------------------------------------------------------

		end
		-----------------------------------------------------------------------------------------

	end

	verify_method_parameter()



-----------------------------------------------------------------------------------------------
--Parameter 3: info
-----------------------------------------------------------------------------------------------
--Requirement id in JAMA: APPLINK-14551: SDL behavior: cases when SDL must transfer "info" parameter via corresponding RPC to mobile app
--List of test cases:
	--1. IsMissed
	--2. IsLowerBound
	--3. IsUpperBound
	--4. IsOutUpperBound
	--5. IsEmpty/IsOutLowerBound
	--6. IsWrongType
	--7. InvalidCharacter - \n, \t
-----------------------------------------------------------------------------------------------

	local function verify_info_parameter()


		--Print new line to separate new test cases group
		commonFunctions:newTestCasesGroup("Test suite: Check info parameter")

		-----------------------------------------------------------------------------------------

		--1. IsMissed
		Test[APIName.."_info_IsMissed_SendResponse"] = function(self)

			--mobile side: sending the request
			local Request = Test:createRequest()
			local cid = self.mobileSession:SendRPC("SystemRequest", Request, PTFile)

			--hmi side: expect the request
			local HMIExpectedResult = self:createExpectedResultOnHMI(Request)
			EXPECT_HMICALL("BasicCommunication.SystemRequest", HMIExpectedResult)
			:Do(function(_,data)
				--hmi side: sending the response
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end)


			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
			:ValidIf (function(_,data)
							if data.payload.info then
								commonFunctions:printError(" SDL resends info parameter to mobile app. info = \"" .. data.payload.info .. "\"")
								return false
							else
								return true
							end
						end)
		end
		-----------------------------------------------------------------------------------------

		Test[APIName.."_info_IsMissed_SendError"] = function(self)

			--mobile side: sending the request
			local Request = Test:createRequest()
			local cid = self.mobileSession:SendRPC("SystemRequest", Request, PTFile)

			--hmi side: expect the request
			local HMIExpectedResult = self:createExpectedResultOnHMI(Request)
			EXPECT_HMICALL("BasicCommunication.SystemRequest", HMIExpectedResult)
			:Do(function(_,data)
				--hmi side: sending the response
				self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR")
			end)


			--mobile side: expect the response
			-- TODO: Update after resolving APPLINK-14765
			-- EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
			EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response"})
		end
		-----------------------------------------------------------------------------------------

		--2. IsLowerBound
		--3. IsUpperBound
		local testData = 	{
								{value = "a", 									name = "IsLowerBound"},
								{value = commonFunctions:createString(1000), 	name = "IsUpperBound"}
							}

		for i =1, #testData do

			Test[APIName.."_info_" .. testData[i].name .."_SendResponse"] = function(self)

				--mobile side: sending the request
				local Request = Test:createRequest()
				local cid = self.mobileSession:SendRPC("SystemRequest", Request, PTFile)

				--hmi side: expect the request
				local HMIExpectedResult = self:createExpectedResultOnHMI(Request)
				EXPECT_HMICALL("BasicCommunication.SystemRequest", HMIExpectedResult)
				:Do(function(_,data)
					--hmi side: sending the response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {message = testData[i].value})
				end)

				--mobile side: expect the response
				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", info = testData[i].value})

			end
			-----------------------------------------------------------------------------------------

			Test[APIName.."_info_" .. testData[i].name .."_SendError"] = function(self)

				--mobile side: sending the request
				local Request = Test:createRequest()
				local cid = self.mobileSession:SendRPC("SystemRequest", Request, PTFile)

				--hmi side: expect the request
				local HMIExpectedResult = self:createExpectedResultOnHMI(Request)
				EXPECT_HMICALL("BasicCommunication.SystemRequest", HMIExpectedResult)
				:Do(function(_,data)
					--hmi side: sending the response
					self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", testData[i].value)
				end)

				--mobile side: expect the response
				EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = testData[i].value})

			end
			-----------------------------------------------------------------------------------------

		end
		-----------------------------------------------------------------------------------------


		--4. IsOutUpperBound
		Test[APIName.."_info_IsOutUpperBound_SendResponse"] = function(self)

			local infoMaxLength = commonFunctions:createString(1000)

			--mobile side: sending the request
			local Request = Test:createRequest()
			local cid = self.mobileSession:SendRPC("SystemRequest", Request, PTFile)

			--hmi side: expect the request
			local HMIExpectedResult = self:createExpectedResultOnHMI(Request)
			EXPECT_HMICALL("BasicCommunication.SystemRequest", HMIExpectedResult)
			:Do(function(_,data)
				--hmi side: sending the response
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {message = infoMaxLength .. "1"})
			end)

			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", info = infoMaxLength})

		end
		-----------------------------------------------------------------------------------------

		Test[APIName.."_info_IsOutUpperBound_SendError"] = function(self)

			local infoMaxLength = commonFunctions:createString(1000)

			--mobile side: sending the request
			local Request = Test:createRequest()
			local cid = self.mobileSession:SendRPC("SystemRequest", Request, PTFile)

			--hmi side: expect the request
			local HMIExpectedResult = self:createExpectedResultOnHMI(Request)
			EXPECT_HMICALL("BasicCommunication.SystemRequest", HMIExpectedResult)
			:Do(function(_,data)
				--hmi side: sending the response
				self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", infoMaxLength .."1")
			end)

			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = infoMaxLength})

		end
		-----------------------------------------------------------------------------------------

		-- TODO: update after resolving APPLINK-14551

		--5. IsEmpty/IsOutLowerBound
		--6. IsWrongType
		--7. InvalidCharacter - \n, \t

		local testData = 	{
								{value = "", 		name = "IsEmpty_IsOutLowerBound"},
								{value = 123, 		name = "IsWrongType"},
								{value = "a\nb",	name = "IsInvalidCharacter_NewLine"},
								{value = "a\tb", 	name = "IsInvalidCharacter_Tab"}
							}

		for i =1, #testData do

			Test[APIName.."_info_" .. testData[i].name .."_SendResponse"] = function(self)

				--mobile side: sending the request
				local Request = Test:createRequest()
				local cid = self.mobileSession:SendRPC("SystemRequest", Request, PTFile)

				--hmi side: expect the request
				local HMIExpectedResult = self:createExpectedResultOnHMI(Request)
				EXPECT_HMICALL("BasicCommunication.SystemRequest", HMIExpectedResult)
				:Do(function(_,data)
					--hmi side: sending the response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {message = testData[i].value})
				end)

				--mobile side: expect the response
				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
				:ValidIf (function(_,data)
								if data.payload.info then
									commonFunctions:printError(" SDL resends info parameter to mobile app. info = \"" .. data.payload.info .. "\"")
									return false
								else
									return true
								end
							end)

			end
			-----------------------------------------------------------------------------------------

			Test[APIName.."_info_" .. testData[i].name .."_SendError"] = function(self)

				--mobile side: sending the request
				local Request = Test:createRequest()
				local cid = self.mobileSession:SendRPC("SystemRequest", Request, PTFile)

				--hmi side: expect the request
				local HMIExpectedResult = self:createExpectedResultOnHMI(Request)
				EXPECT_HMICALL("BasicCommunication.SystemRequest", HMIExpectedResult)
				:Do(function(_,data)
					--hmi side: sending the response
					self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", testData[i].value)
				end)


				-- TODO: Update after resolving APPLINK-14765
				--mobile side: expect response
				 EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
				--EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})
				:ValidIf (function(_,data)
					if data.payload.info then
						commonFunctions:printError(" SDL resends info parameter to mobile app. info = \"" .. data.payload.info .. "\"")
						return false
					else
						return true
					end

				end)

			end
			---------------------------------------------------------------------------------------

		end
		-----------------------------------------------------------------------------------------

	end

	verify_info_parameter()



-----------------------------------------------------------------------------------------------
--Parameter 4: correlationID
-----------------------------------------------------------------------------------------------
--List of test cases:
	--1. IsMissed
	--2. IsNonexistent
	--3. IsWrongType
	--4. IsNegative
-----------------------------------------------------------------------------------------------

	local function verify_correlationID_parameter()


		--Print new line to separate new test cases group
		commonFunctions:newTestCasesGroup("Test suite: Check correlationID parameter")

		-----------------------------------------------------------------------------------------

		--1. IsMissed
		Test[APIName.."_Response_CorrelationID_IsMissed_SendResponse"] = function(self)

			--mobile side: sending the request
			local Request = Test:createRequest()
			local cid = self.mobileSession:SendRPC("SystemRequest", Request, PTFile)

			--hmi side: expect the request
			local HMIExpectedResult = self:createExpectedResultOnHMI(Request)
			EXPECT_HMICALL("BasicCommunication.SystemRequest", HMIExpectedResult)
			:Do(function(_,data)
				--hmi side: sending the response
				--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"BasicCommunication.SystemRequest","code":0}}')
				  self.hmiConnection:Send('{"jsonrpc":"2.0","result":{"method":"BasicCommunication.SystemRequest", "code":0}}')

			end)


			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
			:Timeout(13000)

		end
		-----------------------------------------------------------------------------------------

		Test[APIName.."_Response_CorrelationID_IsMissed_SendError"] = function(self)

			--mobile side: sending the request
			local Request = Test:createRequest()
			local cid = self.mobileSession:SendRPC("SystemRequest", Request, PTFile)

			--hmi side: expect the request
			local HMIExpectedResult = self:createExpectedResultOnHMI(Request)
			EXPECT_HMICALL("BasicCommunication.SystemRequest", HMIExpectedResult)
			:Do(function(_,data)
				--hmi side: sending the response
				--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"BasicCommunication.SystemRequest"},"code":22,"message":"The unknown issue occurred"}}')
				self.hmiConnection:Send('{"jsonrpc":"2.0","error":{"data":{"method":"BasicCommunication.SystemRequest"},"code":22,"message":"The unknown issue occurred"}}')

			end)


			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
			:Timeout(13000)

		end
		-----------------------------------------------------------------------------------------


		--2. IsNonexistent
		Test[APIName.."_Response_CorrelationID_IsNonexistent_SendResponse"] = function(self)

			--mobile side: sending the request
			local Request = Test:createRequest()
			local cid = self.mobileSession:SendRPC("SystemRequest", Request, PTFile)

			--hmi side: expect the request
			local HMIExpectedResult = self:createExpectedResultOnHMI(Request)
			EXPECT_HMICALL("BasicCommunication.SystemRequest", HMIExpectedResult)
			:Do(function(_,data)
				--hmi side: sending the response
				--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"BasicCommunication.SystemRequest","code":0}}')
				  self.hmiConnection:Send('{"id":'..tostring(5555)..',"jsonrpc":"2.0","result":{"method":"BasicCommunication.SystemRequest","code":0}}')

			end)


			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
			:Timeout(13000)

		end
		-----------------------------------------------------------------------------------------

		Test[APIName.."_Response_CorrelationID_IsNonexistent_SendError"] = function(self)

			--mobile side: sending the request
			local Request = Test:createRequest()
			local cid = self.mobileSession:SendRPC("SystemRequest", Request, PTFile)

			--hmi side: expect the request
			local HMIExpectedResult = self:createExpectedResultOnHMI(Request)
			EXPECT_HMICALL("BasicCommunication.SystemRequest", HMIExpectedResult)
			:Do(function(_,data)
				--hmi side: sending the response
				--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"BasicCommunication.SystemRequest"},"code":22,"message":"The unknown issue occurred"}}')
				self.hmiConnection:Send('{"id":'..tostring(5555)..',"jsonrpc":"2.0","error":{"data":{"method":"BasicCommunication.SystemRequest"},"code":22,"message":"The unknown issue occurred"}}')

			end)


			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
			:Timeout(13000)

		end
		-----------------------------------------------------------------------------------------


		--3. IsWrongType
		Test[APIName.."_Response_CorrelationID_IsWrongType_SendResponse"] = function(self)

			--mobile side: sending the request
			local Request = Test:createRequest()
			local cid = self.mobileSession:SendRPC("SystemRequest", Request, PTFile)

			--hmi side: expect the request
			local HMIExpectedResult = self:createExpectedResultOnHMI(Request)
			EXPECT_HMICALL("BasicCommunication.SystemRequest", HMIExpectedResult)
			:Do(function(_,data)
				--hmi side: sending the response
				--self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {message = "info message"})
				  self.hmiConnection:SendResponse(tostring(data.id), data.method, "SUCCESS", {message = "info message"})

			end)


			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
			:Timeout(13000)

		end
		-----------------------------------------------------------------------------------------

		Test[APIName.."_Response_CorrelationID_IsWrongType_SendError"] = function(self)

			--mobile side: sending the request
			local Request = Test:createRequest()
			local cid = self.mobileSession:SendRPC("SystemRequest", Request, PTFile)

			--hmi side: expect the request
			local HMIExpectedResult = self:createExpectedResultOnHMI(Request)
			EXPECT_HMICALL("BasicCommunication.SystemRequest", HMIExpectedResult)
			:Do(function(_,data)
				--hmi side: sending the response
				--self.hmiConnection:SendError(data.id, data.method, "REJECTED", "error message")
				  self.hmiConnection:SendError(tostring(data.id), data.method, "REJECTED", "error message")

			end)


			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
			:Timeout(13000)

		end
		-----------------------------------------------------------------------------------------

		--4. IsNegative
		Test[APIName.."_Response_CorrelationID_IsNegative_SendResponse"] = function(self)

			--mobile side: sending the request
			local Request = Test:createRequest()
			local cid = self.mobileSession:SendRPC("SystemRequest", Request, PTFile)

			--hmi side: expect the request
			local HMIExpectedResult = self:createExpectedResultOnHMI(Request)
			EXPECT_HMICALL("BasicCommunication.SystemRequest", HMIExpectedResult)
			:Do(function(_,data)
				--hmi side: sending the response
				--self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {message = "info message"})
				  self.hmiConnection:SendResponse(-1, data.method, "SUCCESS", {message = "info message"})

			end)


			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
			:Timeout(13000)

		end
		-----------------------------------------------------------------------------------------

		Test[APIName.."_Response_CorrelationID_IsNegative_SendError"] = function(self)

			--mobile side: sending the request
			local Request = Test:createRequest()
			local cid = self.mobileSession:SendRPC("SystemRequest", Request, PTFile)

			--hmi side: expect the request
			local HMIExpectedResult = self:createExpectedResultOnHMI(Request)
			EXPECT_HMICALL("BasicCommunication.SystemRequest", HMIExpectedResult)
			:Do(function(_,data)
				--hmi side: sending the response
				--self.hmiConnection:SendError(data.id, data.method, "REJECTED", "error message")
				  self.hmiConnection:SendError(-1, data.method, "REJECTED", "error message")

			end)


			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
			:Timeout(13000)

		end
		-----------------------------------------------------------------------------------------

	end

	verify_correlationID_parameter()

----------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK IV----------------------------------------
------------------------------Check special cases of HMI response-----------------------------
----------------------------------------------------------------------------------------------
--Requirement id in JAMA or JIRA:
	--APPLINK-14765: SDL must cut off the fake parameters from requests, responses and notifications received from HMI

-----------------------------------------------------------------------------------------------

--List of test cases for special cases of HMI notification:
	--1. InvalidJsonSyntax
	--2. InvalidStructure
	--3. NoResponse
	--4. FakeParams
	--5. FakeParameterIsFromAnotherAPI
	--6. MissedmandatoryParameters
	--7. MissedAllPArameters
	--8. SeveralResponsesWithTheSameResultCode
	--9. SeveralResponsesWithDifferentResultCode
----------------------------------------------------------------------------------------------

	local function SpecialResponseChecks()

		--Print new line to separate new test cases group
		commonFunctions:newTestCasesGroup("Test suite: Check special cases of HMI response")

		--1. InvalidJsonSyntax
		function Test:SystemRequest_InvalidJsonSyntax_SendResponse()

			--mobile side: sending the request
			local Request = Test:createRequest()
			local cid = self.mobileSession:SendRPC("SystemRequest", Request, PTFile)

			--hmi side: expect the request
			local HMIExpectedResult = self:createExpectedResultOnHMI(Request)
			EXPECT_HMICALL("BasicCommunication.SystemRequest", HMIExpectedResult)
			:Do(function(_,data)
				--hmi side: sending the response
				--":" is changed by ";" after {"id"
				--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"BasicCommunication.SystemRequest", "code":0}}')
				  self.hmiConnection:Send('{"id";'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"BasicCommunication.SystemRequest", "code":0}}')
			end)

			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR" })
			:Timeout(12000)

		end

		function Test:SystemRequest_InvalidJsonSyntax_SendError()

			--mobile side: sending the request
			local Request = Test:createRequest()
			local cid = self.mobileSession:SendRPC("SystemRequest", Request, PTFile)

			--hmi side: expect the request
			local HMIExpectedResult = self:createExpectedResultOnHMI(Request)
			EXPECT_HMICALL("BasicCommunication.SystemRequest", HMIExpectedResult)
			:Do(function(_,data)
				--hmi side: sending the response
				--":" is changed by ";" after {"id"
				--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"code":11,"message":"Invalid data","data":{"method":"BasicCommunication.SystemRequest"}}}')
				  self.hmiConnection:Send('{"id";'..tostring(data.id)..',"jsonrpc":"2.0","error":{"code":11,"message":"Invalid data","data":{"method":"BasicCommunication.SystemRequest"}}}')

			end)

			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR" })
			:Timeout(12000)

		end

		--2. InvalidStructure
		function Test:SystemRequest_InvalidStructure_SendResponse()

			--mobile side: sending the request
			local Request = Test:createRequest()
			local cid = self.mobileSession:SendRPC("SystemRequest", Request, PTFile)

			--hmi side: expect the request
			local HMIExpectedResult = self:createExpectedResultOnHMI(Request)
			EXPECT_HMICALL("BasicCommunication.SystemRequest", HMIExpectedResult)
			:Do(function(_,data)
				--hmi side: sending the response
				--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"BasicCommunication.SystemRequest", "code":0}}')
				self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0", "code":0, "result":{"method":"BasicCommunication.SystemRequest"}}')
			end)

			--mobile side: expect response
			EXPECT_RESPONSE(cid, {  success = false, resultCode = "GENERIC_ERROR"})
			:Timeout(12000)

		end

		function Test:SystemRequest_InvalidStructure_SendError()

			--mobile side: sending the request
			local Request = Test:createRequest()
			local cid = self.mobileSession:SendRPC("SystemRequest", Request, PTFile)

			--hmi side: expect the request
			local HMIExpectedResult = self:createExpectedResultOnHMI(Request)
			EXPECT_HMICALL("BasicCommunication.SystemRequest", HMIExpectedResult)
			:Do(function(_,data)
				--hmi side: sending the response
				--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"code":11,"message":"Invalid data","data":{"method":"BasicCommunication.SystemRequest"}}}')
				self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","code":11,"error":{"message":"Invalid data","data":{"method":"BasicCommunication.SystemRequest"}}}')

			end)

			--mobile side: expect response
			EXPECT_RESPONSE(cid, {  success = false, resultCode = "GENERIC_ERROR"})
			:Timeout(12000)

		end

		--3. NoResponse
		function Test:SystemRequest_NoResponse()

			--mobile side: sending the request
			local Request = Test:createRequest()
			local cid = self.mobileSession:SendRPC("SystemRequest", Request, PTFile)

			--hmi side: expect the request
			local HMIExpectedResult = self:createExpectedResultOnHMI(Request)
			EXPECT_HMICALL("BasicCommunication.SystemRequest", HMIExpectedResult)

			--mobile side: expect response
			EXPECT_RESPONSE(cid, {  success = false, resultCode = "GENERIC_ERROR"})
			:Timeout(12000)
		end


		--4. FakeParams
		function Test:SystemRequest_FakeParamsInResponse()

			--mobile side: sending the request
			local Request = Test:createRequest()
			local cid = self.mobileSession:SendRPC("SystemRequest", Request, PTFile)

			--hmi side: expect the request
			local HMIExpectedResult = self:createExpectedResultOnHMI(Request)
			EXPECT_HMICALL("BasicCommunication.SystemRequest", HMIExpectedResult)
			:Do(function(exp,data)
				--hmi side: sending the response
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {fake = "fake"})
			end)


			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
			:ValidIf (function(_,data)
				if data.payload.fake then
					commonFunctions:printError(" SDL resend fake parameter to mobile app ")
					return false
				else
					return true
				end
			end)

		end


		--5. FakeParameterIsFromAnotherAPI
		function Test:SystemRequest_AnotherParameterInResponse()

			--mobile side: sending the request
			local Request = Test:createRequest()
			local cid = self.mobileSession:SendRPC("SystemRequest", Request, PTFile)

			--hmi side: expect the request
			local HMIExpectedResult = self:createExpectedResultOnHMI(Request)
			EXPECT_HMICALL("BasicCommunication.SystemRequest", HMIExpectedResult)
			:Do(function(exp,data)
				--hmi side: sending the response
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {sliderPosition = 5})
			end)


			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
			:ValidIf (function(_,data)
				if data.payload.sliderPosition then
					commonFunctions:printError(" SDL resend fake parameter to mobile app ")
					return false
				else
					return true
				end
			end)

		end


		--6. MissedmandatoryParameters
		function Test:SystemRequest_Response_MissedmandatoryParameters()

			--mobile side: sending the request
			local Request = Test:createRequest()
			local cid = self.mobileSession:SendRPC("SystemRequest", Request, PTFile)

			--hmi side: expect the request
			local HMIExpectedResult = self:createExpectedResultOnHMI(Request)
			EXPECT_HMICALL("BasicCommunication.SystemRequest", HMIExpectedResult)
			:Do(function(_,data)
				--hmi side: sending BasicCommunication.SystemRequest response
				--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"BasicCommunication.SystemRequest", "code":0}}')
				self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{}}')
			end)

			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
			:Timeout(13000)

		end


		--7. MissedAllPArameters
		function Test:SystemRequest_Response_MissedAllPArameters()

			--mobile side: sending the request
			local Request = Test:createRequest()
			local cid = self.mobileSession:SendRPC("SystemRequest", Request, PTFile)

			--hmi side: expect the request
			local HMIExpectedResult = self:createExpectedResultOnHMI(Request)
			EXPECT_HMICALL("BasicCommunication.SystemRequest", HMIExpectedResult)
			:Do(function(_,data)
				--hmi side: sending BasicCommunication.SystemRequest response
				--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"BasicCommunication.SystemRequest", "code":0}}')
				self.hmiConnection:Send('{}')
			end)

			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
			:Timeout(13000)

		end


		--8. SeveralResponsesWithTheSameResultCode
		function Test:SystemRequest_SeveralResponsesWithTheSameResultCode()

			--mobile side: sending the request
			local Request = Test:createRequest()
			local cid = self.mobileSession:SendRPC("SystemRequest", Request, PTFile)

			--hmi side: expect the request
			local HMIExpectedResult = self:createExpectedResultOnHMI(Request)
			EXPECT_HMICALL("BasicCommunication.SystemRequest", HMIExpectedResult)
			:Do(function(exp,data)
				--hmi side: sending the response
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})

			end)


			--mobile side: expect response
			EXPECT_RESPONSE(cid, {  success = true, resultCode = "SUCCESS"})

		end

		--9. SeveralResponsesWithDifferentResultCode
		function Test:SystemRequest_SeveralResponsesWithDifferentResultCode()

			--mobile side: sending the request
			local Request = Test:createRequest()
			local cid = self.mobileSession:SendRPC("SystemRequest", Request, PTFile)

			--hmi side: expect the request
			local HMIExpectedResult = self:createExpectedResultOnHMI(Request)
			EXPECT_HMICALL("BasicCommunication.SystemRequest", HMIExpectedResult)
			:Do(function(exp,data)
				--hmi side: sending the response
				self.hmiConnection:SendResponse(data.id, data.method, "INVALID_DATA", {})
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end)


			--mobile side: expect response
			EXPECT_RESPONSE(cid, {  success = false, resultCode = "INVALID_DATA"})

		end


	end

	SpecialResponseChecks()



-----------------------------------------------------------------------------------------------
-------------------------------------------TEST BLOCK V----------------------------------------
-------------------------------------Checks All Result Codes-----------------------------------
-----------------------------------------------------------------------------------------------

--Description: Check all resultCodes


--Requirement id in JAMA:
	--N/A

--Verification criteria: Verify SDL behaviors in different states of policy table:
	--1. Request is not exist in PT => DISALLOWED in policy table, SDL responses DISALLOWED
	--2. Request is exist in PT but it has not consented yet by user => DISALLOWED in policy table, SDL responses DISALLOWED
	--3. Request is exist in PT but user does not allow function group that contains this request => USER_DISALLOWED in policy table, SDL responses USER_DISALLOWED
	--4. Request is exist in PT and user allow function group that contains this request
----------------------------------------------------------------------------------------------

	local function StopSDL_StartSDLAgain_StartHMI_StartMobile_Delete_PT(TestCaseSuffix)

		Test["StopSDL_" .. TestCaseSuffix] = function(self)
			print()
			StopSDL()
		end

		Test["RemovePT_" .. TestCaseSuffix] = function(self)
			--Delete policy table
			os.remove(config.pathToSDL .. AppStorageFolder .. "/policy.sqlite")
		end

		Test["StartSDL_" .. TestCaseSuffix] = function(self)
		  StartSDL(config.pathToSDL, config.ExitOnCrash)
		end

		Test["InitHMI_" .. TestCaseSuffix] = function(self)
		  self:initHMI()
		end

		Test["InitHMI_onReady_" .. TestCaseSuffix] = function(self)
		  self:initHMI_onReady()
		end

		Test["ConnectMobile_" .. TestCaseSuffix] = function(self)
		  self:connectMobile()
		end

		Test["StartSession_" .. TestCaseSuffix] = function(self)
		  self:startSession()
		end

	end


	--Check resultCode SUCCESS. It is checked by other test cases.
	--Check resultCode INVALID_DATA. It is checked by other test cases.
	--Check resultCode OUT_OF_MEMORY. ToDo: Wait until requirement is clarified (APPLINK-13411).
	--Check resultCode TOO_MANY_PENDING_REQUESTS. It is moved to other script.
	--Check resultCode APPLICATION_NOT_REGISTERED
	--Check resultCode REJECTED
	--Check resultCode WARNINGS
	--Check resultCode UNSUPPORTED_RESOURCE
	local function ResultCodeChecks()

		--Print new line to separate new test cases group
		commonFunctions:newTestCasesGroup("Test suite: Checks All Result Codes")

		commonTestCases:verifyResultCode_APPLICATION_NOT_REGISTERED()



		-- GENERIC_ERROR
			-- a. in case of SystemRequest (query_apps) - if the app-provided json file is invalid (see req. APPLINK-19421)
			-- b. in case SDL receives this resultCode from HMI: Covered by _resultCode_IsValidValues_
			-- c. in case SDL receives does not receive response from HMI. It is covered in Test:SystemRequest_NoResponse

			--APPLINK-19421: [SDL4.0]: SDL must validate the syntax of json file received from mobile app via SystemRequest
			--It is coverted by APPLINK-18301: 01[ATF]_TC_OnSystemRequest_QUERY_APPS


		-- REJECTED
		-- TODO: update according to APPLINK-11264
			-- a. HMI processes SystemRequest received from SDL AND app sends second SystemRequest
			-- b. The data file was uploaded to sub-directory of \91AppStorageFolder\92 AND SDL receives SystemRequest from this app AND there is no space left in sharedMemory sub-directory
			-- To get details, please use 6 and 14 req-s in APPLINK-11264

			--[=[
			function Test:SystemRequest_REJECTED_HMI_IsBusy()F

				--mobile side: sending the request
				local Request = Test:createRequest()
				local cid = self.mobileSession:SendRPC("SystemRequest", Request, PTFile)

				--hmi side: expect the request
				local HMIExpectedResult = self:createExpectedResultOnHMI(Request)
				EXPECT_HMICALL("BasicCommunication.SystemRequest", HMIExpectedResult)
				:Do(function(exp,data)

					local ID1
					if exp.occurences == 1 then

						ID1 = data.id

						--mobile side: send second request
						local Request2 = Test:createRequest()
						local cid2 = self.mobileSession:SendRPC("SystemRequest", Request2, PTFile)

						--mobile side: expect the second response
						EXPECT_RESPONSE(cid2, { success = false, resultCode = "REJECTED"})


						local function SendFirstResponse()
							--hmi side: sending SystemRequest response
							self.hmiConnection:SendResponse(ID1,"BasicCommunication.SystemRequest", "SUCCESS", {})
						end
						RUN_AFTER(SendFirstResponse, 1000)

					elseif exp.occurences == 2 then

						--hmi side: sending SystemRequest response
						self.hmiConnection:SendResponse(data.id,"BasicCommunication.SystemRequest", "REJECTED", {})

					end

				end)

				--mobile side: expect the first SystemRequest response
				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})

			end
			]=]

		-- WARNINGS: APPLINK-15051: SDL must transfer WARNINGS result code received from HMI with (success:true) to mobile app (single HMI RPC)
		-- Covered by _resultCode_IsValidValues_

		--5. Check resultCode UNSUPPORTED_RESOURCE
		--APPLINK-14499: [APPLINK-14479]: 3. SDL must respond UNSUPPORTED_RESOURCE to mobile app in case SDL 4.0 feature is required to be ommited in implementation
		----------------------------------------------------------------------------------------------
                        local EnableProtocol4 = SDLConfig:GetValue("EnableProtocol4")
			if EnableProtocol4 =="" then
				--This test case is used on Genivi/SDL4.0
				function Test:SystemRequest_requestType_QUERY_APPS_UNSUPPORTED_RESOURCE()

					userPrint(33, "===This test case is used on Genivi/SDL4.0 build ===")

					--mobile side: sending the request
					local Request = {
										requestType = "QUERY_APPS",
										fileName = "PolicyTableUpdate"
									}

					local cid = self.mobileSession:SendRPC("SystemRequest", Request, PTFile)


					--mobile side: expect SystemRequest response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "UNSUPPORTED_RESOURCE"})
				end

			end

	end

	ResultCodeChecks()

	--Check resultCode DISALLOWED
	local function ResultCodeChecks_DISALLOWED()

		--Print new line to separate new test cases group
		commonFunctions:newTestCasesGroup("Test suite: Checks All Result Codes")


	--1. Request is not exist in PT => DISALLOWED in policy table, SDL responses DISALLOWED
	----------------------------------------------------------------------------------------------
		--Precondition: Build policy table file
		local PTName = testCasesForPolicyTable:createPolicyTableWithoutAPI("SystemRequest")

		--Precondition: Update policy table
		testCasesForPolicyTable:updatePolicy(PTName)

		--Send request and check
		function Test:SystemRequest_IsNotExistInPT_Disallowed()

			--mobile side: sending the request
			local Request = Test:createRequest()
			local cid = self.mobileSession:SendRPC("SystemRequest", Request, PTFile)

			--mobile side: expected response
			EXPECT_RESPONSE(cid, {  success = false, resultCode = "DISALLOWED"})
		end

		--Postcondition:
		StopSDL_StartSDLAgain_StartHMI_StartMobile_Delete_PT("Postcondition_For_DISALLOWED_Case_NotExistInPT")
	----------------------------------------------------------------------------------------------


	--2. Notification is exist in PT but it has not consented yet by user => DISALLOWED in policy table, SDL ignores the notification
	----------------------------------------------------------------------------------------------
		--Precondition: Build policy table file
		local PermissionLinesForBase4 = nil
		local PermissionLinesForGroup1 = PermissionLines_SystemRequest .. "\n"
		local appID = config.application1.registerAppInterfaceParams.fullAppID
		local PermissionLinesForApplication =
		[[			"]]..appID ..[[" : {
						"keep_context" : false,
						"steal_focus" : false,
						"priority" : "NONE",
						"default_hmi" : "NONE",
						"groups" : ["Base-4", "group1"]
					},
		]]

		local PTName = testCasesForPolicyTable:createPolicyTableFile(PermissionLinesForBase4, PermissionLinesForGroup1, PermissionLinesForApplication)
		testCasesForPolicyTable:updatePolicy(PTName)

		--Send notification and check it is ignored
		function Test:SystemRequest_UserHasNotConsentedYet_Disallowed()

			--mobile side: sending the request
			local Request = Test:createRequest()
			local cid = self.mobileSession:SendRPC("SystemRequest", Request, PTFile)

			--mobile side: expected response
			EXPECT_RESPONSE(cid, {  success = false, resultCode = "DISALLOWED"})
		end

		--Postcondition:
		StopSDL_StartSDLAgain_StartHMI_StartMobile_Delete_PT("Postcondition_For_DISALLOWED_Case_NotConsented")

	----------------------------------------------------------------------------------------------


	--3. Notification is exist in PT but user does not allow function group that contains this notification => USER_DISALLOWED in policy table, SDL ignores the notification
	----------------------------------------------------------------------------------------------
		local PermissionLinesForBase4 = nil
		local PermissionLinesForGroup1 = PermissionLines_SystemRequest .. "\n"
		local appID = config.application1.registerAppInterfaceParams.fullAppID
		local PermissionLinesForApplication =
		[[			"]]..appID ..[[" : {
						"keep_context" : false,
						"steal_focus" : false,
						"priority" : "NONE",
						"default_hmi" : "NONE",
						"groups" : ["Base-4", "group1"]
					},
		]]

		local PTName = testCasesForPolicyTable:createPolicyTableFile(PermissionLinesForBase4, PermissionLinesForGroup1, PermissionLinesForApplication)
		testCasesForPolicyTable:updatePolicy(PTName)


		--Precondition: User does not allow function group
		testCasesForPolicyTable:userConsent(false, "group1")

		function Test:SystemRequest_UserDisallowed()
			--mobile side: sending the request
			local Request = Test:createRequest()
			local cid = self.mobileSession:SendRPC("SystemRequest", Request, PTFile)

			--mobile side: expected response
			EXPECT_RESPONSE(cid, {  success = false, resultCode = "USER_DISALLOWED"})
		end
	----------------------------------------------------------------------------------------------

	--4. Notification is exist in PT and user allow function group that contains this notification
	----------------------------------------------------------------------------------------------
		--Precondition: User allows function group
		testCasesForPolicyTable:userConsent(true, "group1")

		function Test:SystemRequest_SUCCESS()
			--mobile side: sending the request
			local Request = Test:createRequest()
			local cid = self.mobileSession:SendRPC("SystemRequest", Request, PTFile)

			--hmi side: expect the request
			local HMIExpectedResult = self:createExpectedResultOnHMI(Request)
			EXPECT_HMICALL("BasicCommunication.SystemRequest", HMIExpectedResult)
			:Do(function(_,data)
				--hmi side: sending SystemRequest response
				self.hmiConnection:SendResponse(data.id,"BasicCommunication.SystemRequest", "SUCCESS", {})
			end)

			--mobile side: expect SystemRequest response
			EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
		end
	----------------------------------------------------------------------------------------------




	end
	--TODO: PT is blocked by ATF defect APPLINK-19188
	--ResultCodeChecks_DISALLOWED()


----------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK VI----------------------------------------
-------------------------Sequence with emulating of user's action(s)--------------------------
----------------------------------------------------------------------------------------------

--RequestType = "QUERY_APPS": This is covered by TC: APPLINK-18301: 01[ATF]_TC_OnSystemRequest_QUERY_APPS



----------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK VII---------------------------------------
--------------------------------------Different HMIStatus-------------------------------------
----------------------------------------------------------------------------------------------

--Description: Check different HMIStatus

--Requirement id in JAMA:
	--APPLINK-19988: Clarify HMI levels for SystemRequest

	--Verification criteria:
		--SDL allows SystemRequest on NONE, LIMITED, BACKGROUND and FULL HMI levels

	--Verify resultCode in NONE, LIMITED, BACKGROUND HMI level
	commonTestCases:verifyDifferentHMIStatus("SUCCESS", "SUCCESS", "SUCCESS")


	--Update policy table to allow SystemRequest only in FULL, LIMITED, BACKGROUND
	local PermissionLines_SystemRequest =
[[					"SystemRequest": {
						"hmi_levels": [
						  "BACKGROUND",
						  "FULL",
						  "LIMITED"
						]
					  }]]


	local PermissionLinesForBase4 = PermissionLines_SystemRequest .. ",\n"
	local PermissionLinesForGroup1 = nil
	local PermissionLinesForApplication = nil
	--TODO: PT is blocked by ATF defect APPLINK-19188
	--[[local PTName = testCasesForPolicyTable:createPolicyTableFile(PermissionLinesForBase4, PermissionLinesForGroup1, PermissionLinesForApplication, {"SystemRequest"})
	testCasesForPolicyTable:updatePolicy(PTName)


	Test["UnregisterTheSecondMediaApp"]  = function(self)

		--mobile side: RegisterAppInterface request
		local CorIdRAI = self.mobileSession2:SendRPC("UnregisterAppInterface", {})


		--mobile side: UnregisterAppInterface response
		self.mobileSession2:ExpectResponse(CorIdRAI, { success = true, resultCode = "SUCCESS"})
			:Timeout(2000)
	end


	--Verify resultCode in NONE, LIMITED, BACKGROUND HMI level
	commonTestCases:verifyDifferentHMIStatus("DISALLOWED", "SUCCESS", "SUCCESS")
	]]





-------------------------------------------------------------------------------------------------------------------------
------------------------------------VIII FROM NEW TEST CASES-------------------------------------------------------------
--------57[ATF]_TC_SystemRequest: Check that SDL does't allow SystemRequest with the name of binary data /<filename>.----
-------------------------------------------------------------------------------------------------------------------------
--Requirement id in JAMA or JIRA:
	--APPLINK-16768: -- Check that SDL does't allow SystemRequest with the name of binary data /<filename>.
	--APPLINK-16769: -- Check that SDL does't allow SystemRequest with the name of binary data ./<filename>.
	--APPLINK-16770: -- Check that SDL does't allow SystemRequest with the name of binary data ../<filename>.
	--APPLINK-16771: -- Check that SDL does't allow SystemRequest with the name of binary data \<filename>.
	--APPLINK-16772: -- Check that SDL does't allow SystemRequest with the name of binary data \\<filename>.
	--APPLINK-16773: -- Check that SDL does't allow SystemRequest with the name of binary data .\\<filename>.
	--APPLINK-16774: -- Check that SDL does't allow SystemRequest with the name of binary data ..\\<filename>.
	--APPLINK-16776: -- Check that SDL does't allow SystemRequest with the name of binary data ..<filename>.
	--APPLINK-16777: -- Check that SDL does't allow SystemRequest with the name of binary data ...<filename>.
-----------------------------------------------------------------------------------------------


local function SequenceNewTCs()


---------------------------------------------------------------------------------------------
-------------------------------------------Common function-----------------------------------
---------------------------------------------------------------------------------------------
--Description: Delete draft file
function DeleteDraftFile(imageFile)
	os.remove(imageFile)
end
--Description: SystemRequest invalid with default image file
	--imageFile: FileName
function Test:systemRequestInvalid(imageFile)

	DeleteDraftFile(strIvsu_cacheFolder .. imageFile)

	--mobile side: sending SetAppIcon request
	local cid = self.mobileSession:SendRPC("SystemRequest",{ fileName = imageFile, requestType = "PROPRIETARY" })

	--mobile side: expect SystemRequest response
	EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
	:ValidIf (function(_,data)
		if file_check(strIvsu_cacheFolder .. imageFile) == true then
			print(" \27[36m File is copied to ivsu_cache folder: [" .. strIvsu_cacheFolder .. imageFile .. "] \27[0m ")
			return false
		else
			return true
		end
	end)

end
--Description: SystemRequest success with default image file
	--imageFile: FileName
function Test:systemRequestSuccess(imageFile)

	DeleteDraftFile(strIvsu_cacheFolder .. imageFile)

	--mobile side: sending SystemRequest request
	local cidSystemReq = self.mobileSession:SendRPC("SystemRequest",
																	{
																		fileName = imageFile,
																		requestType= "PROPRIETARY"
																	}, "./files/icon.png")

	--hmi side: expect BC.SystemRequest request
	EXPECT_HMICALL("BasicCommunication.SystemRequest",
												{
													fileName = strIvsu_cacheFolder .. imageFile,
													requestType= "PROPRIETARY"
												})

	:Do(function(_,data)
		--hmi side: sending UI.Show response
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
	end)

	--mobile side: expected SystemRequest response
	EXPECT_RESPONSE(cidSystemReq, { success = true, resultCode = "SUCCESS" })
	:ValidIf (function(_,data)
		if file_check(strIvsu_cacheFolder .. imageFile) == true then
			return true
		else
			print(" \27[36m File is not copied to ivsu_cache folder: [" .. strIvsu_cacheFolder .. imageFile .. "] \27[0m ")
			return false
		end
	end)

end
--Description: Function used to check file is existed on expected path
	--file_name: file want to check
function file_check(file_name)
  local file_found=io.open(file_name, "r")

  if file_found==nil then
    return false
  else
    return true
  end
end

---------------------------------------------------------------------------------------------
---------------------------------------End Common function-----------------------------------
---------------------------------------------------------------------------------------------

	--Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup("-----------------------VIII FROM NEW TEST CASES------------------------------")

	--Description: APPLINK-16768: TC_Path_vulnerabilty_SystemRequest_01
					--Check that SDL does't allow SystemRequest with the name of binary data /<filename>.
				    --TCID: APPLINK-16768
					--Requirement id in JAMA/or Jira ID:
					-- APPLINK-11936
					-- SDLAQ-TC-1331

	local function APPLINK_16768()
		-------------------------------------------------------------------------------------------------------------

		--Description: --Check that SDL does't allow SystemRequest with the name of binary data /<filename>.
		function Test:APPLINK_16768_SystemRequest_FileNameSlashSymbol()

			self:systemRequestInvalid("/icon.png")
		end

		-------------------------------------------------------------------------------------------------------------

	end
	-----------------------------------------------------------------------------------------------------------------

	--Description: APPLINK-16769: TC_Path_vulnerabilty_SystemRequest_02
					--Check that SDL does't allow SystemRequest with the name of binary data ./<filename>.
				    --TCID: APPLINK-16769
					--Requirement id in JAMA/or Jira ID:
					-- APPLINK-11936
					-- SDLAQ-TC-1332

	local function APPLINK_16769()
		-------------------------------------------------------------------------------------------------------------

		--Description: --Check that SDL does't allow SystemRequest with the name of binary data ./<filename>.
		function Test:APPLINK_16769_SystemRequest_FileNameDotSlashSymbol()

			self:systemRequestInvalid("./icon.png")
		end

		-------------------------------------------------------------------------------------------------------------

	end
	-----------------------------------------------------------------------------------------------------------------

	--Description: APPLINK-16770: TC_Path_vulnerabilty_SystemRequest_03
					--Check that SDL does't allow SystemRequest with the name of binary data ../<filename>.
				    --TCID: APPLINK-16770
					--Requirement id in JAMA/or Jira ID:
					-- APPLINK-11936
					-- SDLAQ-TC-1333

	local function APPLINK_16770()
		-------------------------------------------------------------------------------------------------------------

		--Description: --Check that SDL does't allow SystemRequest with the name of binary data ./<filename>.
		function Test:APPLINK_16770_SystemRequest_FileNameDoubleDotSlashSymbol()

			self:systemRequestInvalid("../icon.png")
		end

		-------------------------------------------------------------------------------------------------------------

	end
	-----------------------------------------------------------------------------------------------------------------

	--Description: APPLINK-16771: TC_Path_vulnerabilty_SystemRequest_04
					--Check that SDL does't allow SystemRequest with the name of binary data \<filename>.
				    --TCID: APPLINK-16771
					--Requirement id in JAMA/or Jira ID:
					-- APPLINK-11936, APPLINK-12256
					-- SDLAQ-TC-1334

	local function APPLINK_16771()
		-------------------------------------------------------------------------------------------------------------

		--Description: --Check that SDL does't allow SystemRequest with the name of binary data \<filename>.
		function Test:APPLINK_16771_SystemRequest_FileNameBackSlashSymbol()

			self:systemRequestSuccess("\\icon.png")
		end

		-------------------------------------------------------------------------------------------------------------

	end
	-----------------------------------------------------------------------------------------------------------------

	--Description: APPLINK-16772: TC_Path_vulnerabilty_SystemRequest_05
					--Check that SDL does't allow SystemRequest with the name of binary data \\<filename>.
				    --TCID: APPLINK-16772
					--Requirement id in JAMA/or Jira ID:
					-- APPLINK-11936, APPLINK-12256
					-- SDLAQ-TC-1335

	local function APPLINK_16772()
		-------------------------------------------------------------------------------------------------------------

		--Description: --Check that SDL does't allow SystemRequest with the name of binary data \\<filename>.
		function Test:APPLINK_16772_SystemRequest_FileNameDoubleBackSlashSymbol()

			self:systemRequestSuccess("\\\\icon.png")
		end

		-------------------------------------------------------------------------------------------------------------

	end
	-----------------------------------------------------------------------------------------------------------------

	--Description: APPLINK-16773: TC_Path_vulnerabilty_SystemRequest_06
					--Check that SDL does't allow SystemRequest with the name of binary data .\\<filename>.
				    --TCID: APPLINK-16773
					--Requirement id in JAMA/or Jira ID:
					-- APPLINK-11936, APPLINK-12256
					-- SDLAQ-TC-1336

	local function APPLINK_16773()
		-------------------------------------------------------------------------------------------------------------

		--Description: --Check that SDL does't allow SystemRequest with the name of binary data .\\<filename>.
		function Test:APPLINK_16773_SystemRequest_FileNameDotDoubleBackSlashSymbol()

			self:systemRequestSuccess(".\\\\icon.png")
		end

		-------------------------------------------------------------------------------------------------------------

	end
	-----------------------------------------------------------------------------------------------------------------

	--Description: APPLINK-16774: TC_Path_vulnerabilty_SystemRequest_07
					--Check that SDL does't allow SystemRequest with the name of binary data ..\\<filename>.
				    --TCID: APPLINK-16774
					--Requirement id in JAMA/or Jira ID:
					-- APPLINK-11936, APPLINK-12256
					-- SDLAQ-TC-1337

	local function APPLINK_16774()
		-------------------------------------------------------------------------------------------------------------

		--Description: --Check that SDL does't allow SystemRequest with the name of binary data ..\\<filename>.
		function Test:APPLINK_16774_SystemRequest_FileNameDoubleDotDoubleBackSlashSymbol()

			self:systemRequestSuccess("..\\\\icon.png")
		end

		-------------------------------------------------------------------------------------------------------------

	end
	-----------------------------------------------------------------------------------------------------------------

	--Description: APPLINK-16776: TC_Path_vulnerabilty_SystemRequest_08
					--Check that SDL does't allow SystemRequest with the name of binary data ..<filename>.
				    --TCID: APPLINK-16776
					--Requirement id in JAMA/or Jira ID:
					-- APPLINK-11936, APPLINK-12256
					-- SDLAQ-TC-1338

	local function APPLINK_16776()
		-------------------------------------------------------------------------------------------------------------

		--Description: --Check that SDL does't allow SystemRequest with the name of binary data ..<filename>.
		function Test:APPLINK_16776_SystemRequest_FileNameDoubleDotSymbol()

			self:systemRequestSuccess("..icon.png")
		end

		-------------------------------------------------------------------------------------------------------------

	end
	-----------------------------------------------------------------------------------------------------------------

	--Description: APPLINK-16777: TC_Path_vulnerabilty_SystemRequest_09
					--Check that SDL does't allow SystemRequest with the name of binary data ...<filename>.
				    --TCID: APPLINK-16777
					--Requirement id in JAMA/or Jira ID:
					-- APPLINK-11936, APPLINK-12256
					-- SDLAQ-TC-1339

	local function APPLINK_16777()
		-------------------------------------------------------------------------------------------------------------

		--Description: --Check that SDL does't allow SystemRequest with the name of binary data ...<filename>.
		function Test:APPLINK_16777_SystemRequest_FileNameThreeDotSymbol()

			self:systemRequestSuccess("...icon.png")
		end

		-------------------------------------------------------------------------------------------------------------

	end
	-----------------------------------------------------------------------------------------------------------------


	--Main to execute test cases
	APPLINK_16768()
	APPLINK_16769()
	APPLINK_16770()
	APPLINK_16771()
	APPLINK_16772()
	APPLINK_16773()
	APPLINK_16774()
	APPLINK_16776()
	APPLINK_16777()
	-------------------------------------------------------------------------------------------------------------
end

SequenceNewTCs()


--return Test


--Postcondition 
function Test:Postcondition_RestorePreloadedPt()
    local function RestorePreloadedPt ()
	end
end 