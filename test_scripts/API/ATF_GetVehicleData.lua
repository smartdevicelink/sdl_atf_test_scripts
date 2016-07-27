Test = require('connecttest')
require('cardinalities')
local events = require('events')
local mobile_session = require('mobile_session')

require('user_modules/AppTypes')
local policyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')

local compassDirectionValues = {"NORTH", "NORTHWEST", "WEST", "SOUTHWEST", "SOUTH", "SOUTHEAST", "EAST", "NORTHEAST"}
local dimensionValues = {"NO_FIX", "2D", "3D"}
local componentVolumeStatus = {"UNKNOWN", "NORMAL", "LOW", "FAULT", "ALERT", "NOT_SUPPORTED"}
local prndlValues = {"PARK","REVERSE","NEUTRAL","DRIVE","SPORT","LOWGEAR","FIRST","SECOND","THIRD","FOURTH","FIFTH","SIXTH", "SEVENTH", "EIGHTH", "FAULT"}
local warningLightStatus = {"OFF", "ON", "FLASH", "NOT_USED"}
local vehicleDataEventStatus = {"NO_EVENT", "NO", "YES", "NOT_SUPPORTED", "FAULT"}
local ignitionStableStatusValues = {"IGNITION_SWITCH_NOT_STABLE", "IGNITION_SWITCH_STABLE", "MISSING_FROM_TRANSMITTER"}
local ignitionStatusValues = {"UNKNOWN", "OFF", "ACCESSORY", "RUN", "START", "INVALID"}
local deviceLevelStatus = {"ZERO_LEVEL_BARS", "ONE_LEVEL_BARS", "TWO_LEVEL_BARS", "THREE_LEVEL_BARS", "FOUR_LEVEL_BARS", "NOT_PROVIDED"}
local primaryAudioSourceValues = {"NO_SOURCE_SELECTED", "USB", "USB2", "BLUETOOTH_STEREO_BTST", "LINE_IN", "IPOD", "MOBILE_APP"}
local wiperStatusValues = {"OFF", "AUTO_OFF", "OFF_MOVING", "MAN_INT_OFF", "MAN_INT_ON", "MAN_LOW", "MAN_HIGH", "MAN_FLICK", "WASH", "AUTO_LOW", "AUTO_HIGH", "COURTESYWIPE", "AUTO_ADJUST", "STALLED", "NO_DATA_EXISTS"}
local ambientLightStatus = {"NIGHT", "TWILIGHT_1", "TWILIGHT_2", "TWILIGHT_3", "TWILIGHT_4", "DAY", "UNKNOWN", "INVALID"}
local vehicleDataNotificationStatus = {"NOT_SUPPORTED", "NORMAL", "ACTIVE", "NOT_USED"}
local eCallConfirmationStatusValues = {"NORMAL", "CALL_IN_PROGRESS", "CALL_CANCELLED", "CALL_COMPLETED", "CALL_UNSUCCESSFUL", "ECALL_CONFIGURED_OFF", "CALL_COMPLETE_DTMF_TIMEOUT"}
local powerModeQualificationStatusValues = {"POWER_MODE_UNDEFINED", "POWER_MODE_EVALUATION_IN_PROGRESS", "NOT_DEFINED", "POWER_MODE_OK"}
local carModeStatusValues = {"NORMAL", "FACTORY", "TRANSPORT", "CRASH"}
local powerModeStatusValues = {"KEY_OUT", "KEY_RECENTLY_OUT", "KEY_APPROVED_0", "POST_ACCESORY_0", "ACCESORY_1", "POST_IGNITION_1", "IGNITION_ON_2", "RUNNING_2", "CRANK_3"}
local vehicleDataStatus = {"NO_DATA_EXISTS", "OFF", "ON"}
local emergencyEventTypeValues = {"NO_EVENT", "FRONTAL", "SIDE", "REAR", "ROLLOVER", "NOT_SUPPORTED", "FAULT"}
local fuelCutoffStatusValues = {"TERMINATE_FUEL", "NORMAL_OPERATION", "FAULT"}
local vehicleDataValues = {
						gps = {
								longitudeDegrees = 25.5, 
								latitudeDegrees = 45.5
							}, 
						speed = 100.5, 
						rpm = 1000, 
						fuelLevel= 50.5, 
						fuelLevel_State="NORMAL", 
						instantFuelConsumption=1000.5, 
						externalTemperature=55.5,
						vin = "123456",
						prndl="DRIVE", 
						tirePressure={
								pressureTelltale = "ON",								
							}, 
						odometer= 8888, 
						beltStatus={
								driverBeltDeployed = "NOT_SUPPORTED"
							}, 
						bodyInformation={
								parkBrakeActive = true,
								ignitionStableStatus = "MISSING_FROM_TRANSMITTER",
								ignitionStatus = "UNKNOWN"								
							}, 
						deviceStatus={
								voiceRecOn = true								
							}, 
						driverBraking="NOT_SUPPORTED", 
						wiperStatus="MAN_LOW", 
						headLampStatus={
							lowBeamsOn = true,
							highBeamsOn = true,
							ambientLightSensorStatus = "NIGHT"
						}, 
						engineTorque=555.5, 
						accPedalPosition=55.5, 
						steeringWheelAngle=555.5, 
						eCallInfo={
							eCallNotificationStatus = "NORMAL",
							auxECallNotificationStatus = "NORMAL",
							eCallConfirmationStatus = "NORMAL"
						}, 
						airbagStatus={
							driverAirbagDeployed = "NOT_SUPPORTED",
							driverSideAirbagDeployed = "NOT_SUPPORTED",
							driverCurtainAirbagDeployed = "NOT_SUPPORTED",
							passengerAirbagDeployed = "NOT_SUPPORTED",
							passengerCurtainAirbagDeployed = "NOT_SUPPORTED",
							driverKneeAirbagDeployed = "NOT_SUPPORTED",
							passengerSideAirbagDeployed = "NOT_SUPPORTED",
							passengerKneeAirbagDeployed = "NOT_SUPPORTED"
						}, 
						emergencyEvent={
							emergencyEventType = "NO_EVENT",
							fuelCutoffStatus = "NORMAL_OPERATION",
							rolloverEvent = "NO_EVENT",
							maximumChangeVelocity = 0,
							multipleEvents = "NO_EVENT"
						}, 
						clusterModeStatus={
							powerModeActive = true,
							powerModeQualificationStatus = "POWER_MODE_UNDEFINED",
							carModeStatus = "TRANSPORT",
							powerModeStatus = "KEY_OUT"
						}, 
						myKey={
							e911Override = "NO_DATA_EXISTS"
						}
					}
local allVehicleData = {"gps", "speed", "rpm", "fuelLevel", "fuelLevel_State", "instantFuelConsumption", "externalTemperature", "vin", "prndl", "tirePressure", "odometer", "beltStatus", "bodyInformation", "deviceStatus", "driverBraking", "wiperStatus", "headLampStatus", "engineTorque", "accPedalPosition", "steeringWheelAngle"}
local infoMessageValue = string.rep("a",1000)

function DelayedExp(time)
	local event = events.Event()
  event.matches = function(self, e) return self == e end
  EXPECT_EVENT(event, "Delayed event")
  :Timeout(time + 1000)
  RUN_AFTER(function()
              RAISE_EVENT(event, event)
            end, time)
end

--Description: A deep copy copies all levels (or a specific subset of levels).
function copyTable(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[copyTable(orig_key)] = copyTable(orig_value)
        end
        setmetatable(copy, copyTable(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

--Description: Set data for GetVehicleData request
	--paramsSend: vehicle data parameter name - table
function setGVDRequest(paramsSend)
	local temp = {}	
	for i = 1, #paramsSend do		
		temp[paramsSend[i]] = true
	end	
	return temp
end

--Description: Set data for GetVehicleData response
	--paramsSend: vehicle data parameter name - table
function setGVDResponse(paramsSend)
	local temp = {}	
	for i = 1, #paramsSend do		
		temp[paramsSend[i]] = copyTable(vehicleDataValues[paramsSend[i]])
	end	
	return temp
end

--Description: Create expected result for success result
	--response: response received from HMI
function createSuccessExpectedResult(response)
	local temp = response
	temp["success"] = true
	temp["resultCode"] = "SUCCESS"
	
	return temp
end

--Description: GetVehicleData is executed successfully
	--paramsSend: vehicle data parameter name - table
	--infoMessage: Provides additional human readable info regarding the result.
function Test:getVehicleDataSuccess(paramsSend, infoMessage)
	local request = setGVDRequest(paramsSend)
	local response = setGVDResponse(paramsSend)
	
	if infoMessage ~= nil then
		response["info"] = infoMessage
	end
	
	--mobile side: sending GetVehicleData request
	local cid = self.mobileSession:SendRPC("GetVehicleData",request)
	
	--hmi side: expect GetVehicleData request
	EXPECT_HMICALL("VehicleInfo.GetVehicleData",request)
	:Do(function(_,data)
		--hmi side: sending VehicleInfo.GetVehicleData response
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", response)	
	end)
	
	--mobile side: expect GetVehicleData response
	EXPECT_RESPONSE(cid, expectedResult)
	
	DelayedExp(300)
end

--Description: GetVehicleData is executed with invalid data
	--paramsSend: vehicle data parameter name - table
function Test:getVehicleDataInvalidData(paramsSend)
	--mobile side: sending GetVehicleData request
	local cid = self.mobileSession:SendRPC("GetVehicleData",paramsSend)
	
	--mobile side: expected GetVehicleData response
	EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
	
	DelayedExp(300)
end

--Description: Update policy from specific file
	--policyFileName: Name of policy file
	--bAllowed: true if want to allowed New group policy
	--          false if want to disallowed New group policy
function Test:policyUpdate(policyFileName, bAllowed)
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
				fileName = "filename"
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
			"files/"..policyFileName)
			
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
				:Do(function(_,data)
					--print("SDL.GetUserFriendlyMessage is received")
					
					--hmi side: sending SDL.GetListOfPermissions request to SDL
					local RequestIdGetListOfPermissions = self.hmiConnection:SendRequest("SDL.GetListOfPermissions", {appID = self.applications["Test Application"]})
					
					-- hmi side: expect SDL.GetListOfPermissions response
					EXPECT_HMIRESPONSE(RequestIdGetListOfPermissions,{result = {code = 0, method = "SDL.GetListOfPermissions", allowedFunctions = {{ id = 193465391, name = "New"}}}})
					:Do(function(_,data)
						--print("SDL.GetListOfPermissions response is received")
						
						--hmi side: sending SDL.OnAppPermissionConsent
						self.hmiConnection:SendNotification("SDL.OnAppPermissionConsent", { appID =  self.applications["Test Application"], consentedFunctions = {{ allowed = bAllowed, id = 193465391, name = "New"}}, source = "GUI"})
						end)
				end)
			end)
			
		end)
	end)
end

--Description: Checking GetVehicleData response with correct value
	--response: vehicle data response from HMI
	-- TODO: update after resolving APPLINK-1605
function Test:getVehicleData_ResponseSuccess(response)
	local request = setGVDRequest(allVehicleData)	
		
	--mobile side: sending GetVehicleData request
	local cid = self.mobileSession:SendRPC("GetVehicleData",request)
	
	--hmi side: expect GetVehicleData request
	EXPECT_HMICALL("VehicleInfo.GetVehicleData",request)
	:Do(function(_,data)
		--hmi side: sending VehicleInfo.GetVehicleData response
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", response)	
	end)
		
	if 
		response.tirePressure and
		(response.tirePressure.leftFront or
		response.tirePressure.rightFront or
		response.tirePressure.leftRear or
		response.tirePressure.rightRear or
		response.tirePressure.innerLeftRear or
		response.tirePressure.innerRightRear) then
			local expectedResult = createSuccessExpectedResult({})
	else
		local expectedResult = createSuccessExpectedResult(response)
	end
	
	--mobile side: expect GetVehicleData response
	EXPECT_RESPONSE(cid, expectedResult)
	
	DelayedExp(300)
end

--Description: Checking GetVehicleData response with invalid value
	--response: vehicle data response from HMI
function Test:getVehicleData_ResponseInvalidData(response)
	local request = setGVDRequest(allVehicleData)	
		
	--mobile side: sending GetVehicleData request
	local cid = self.mobileSession:SendRPC("GetVehicleData",request)
	
	--hmi side: expect GetVehicleData request
	EXPECT_HMICALL("VehicleInfo.GetVehicleData",request)
	:Do(function(_,data)
		--hmi side: sending VehicleInfo.GetVehicleData response
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", response)	
	end)		
	
	--mobile side: expect GetVehicleData response
	EXPECT_RESPONSE(cid, {success = false, resultCode = "INVALID_DATA"})
	
	DelayedExp(300)
end

---------------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------
	
	--Begin Precondition.1
	--Description: Allow GetVehicleData in all levels
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

	function Test:SetParameterInJson(pathToFile)
		-- body
		pathToFile = config.pathToSDL .. 'sdl_preloaded_pt.json'
		local file  = io.open(pathToFile, "r")
		local json_data = file:read("*all") -- may be abbreviated to "*a";
		file:close()

		local json = require("modules/json")
		 
		local data = json.decode(json_data)
		for k,v in pairs(data.policy_table.functional_groupings) do
			if (data.policy_table.functional_groupings[k].rpcs == nil) then
			    --do
			    data.policy_table.functional_groupings[k] = nil
			else
			    --do
			    local count = 0
			    for _ in pairs(data.policy_table.functional_groupings[k].rpcs) do count = count + 1 end
			    if (count < 30) then
			        --do
					data.policy_table.functional_groupings[k] = nil
			    end
			end
		end
		
		data.policy_table.functional_groupings.GetVehicleDataGroup = {}
		data.policy_table.functional_groupings.GetVehicleDataGroup.rpcs = {}
		data.policy_table.functional_groupings.GetVehicleDataGroup.rpcs.GetVehicleData = {}
		data.policy_table.functional_groupings.GetVehicleDataGroup.rpcs.GetVehicleData.hmi_levels = {'FULL', 'LIMITED', 'BACKGROUND', 'NONE'}
		data.policy_table.functional_groupings.GetVehicleDataGroup.rpcs.GetVehicleData.parameters = allVehicleData

		data.policy_table.app_policies.default.groups = {"Base-4", "GetVehicleDataGroup"}
		
		data = json.encode(data)
		-- print(data)
		-- for i=1, #data.policy_table.app_policies.default.groups do
		-- 	print(data.policy_table.app_policies.default.groups[i])
		-- end
		file = io.open(pathToFile, "w")
		file:write(data)
		file:close()
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
	--End Precondition.1

	--Begin Precondition.2
	--Description: Activation application			
	local GlobalVarAppID = 0
	function RegisterApplication(self)
		-- body
		local corrID = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)

		EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
		:Do(function (_, data)
			-- body
			GlobalVarAppID = data.params.application.appID
		end)

		EXPECT_RESPONSE(corrID, {success = true})

		-- delay - bug of ATF - it is not wait for UpdateAppList and later
		-- line appID = self.applications["Test Application"]} will not assign appID
		DelayedExp(1000)
	end

	function Test:RegisterApp()
		-- body
		self.mobileSession:StartService(7)
		:Do(function (_, data)
			-- body
			RegisterApplication(self)
		end)
	end
	--End Precondition.2

	--Begin Precondition.1
	--Description: Activation application		
		function Test:ActivationApp()			
			--hmi side: sending SDL.ActivateApp request
			-- local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["Test Application"]})
			local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = GlobalVarAppID})
			EXPECT_HMIRESPONSE(RequestId)
			:Do(function(_,data)
				if
					data.result.isSDLAllowed ~= true then
					local RequestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})
					
					--hmi side: expect SDL.GetUserFriendlyMessage message response
					 --TODO: Update after resolving APPLINK-16094 EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
					EXPECT_HMIRESPONSE(RequestId)
					:Do(function(_,data)						
						--hmi side: send request SDL.OnAllowSDLFunctionality
						self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {allowed = true, source = "GUI", device = {id = config.deviceMAC, name = "127.0.0.1"}})

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
			EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"}) 
		end
	--End Precondition.1

---------------------------------------------------------------------------------------------
-----------------------------------------I TEST BLOCK----------------------------------------
--CommonRequestCheck: Check of mandatory/conditional request's parameters (mobile protocol)--
---------------------------------------------------------------------------------------------

	--Begin Test suit CommonRequestCheck
	--Description:
		-- request with all parameters
        -- request with only mandatory parameters
        -- request with all combinations of conditional-mandatory parameters (if exist)
        -- request with one by one conditional parameters (each case - one conditional parameter)
        -- request with missing mandatory parameters one by one (each case - missing one mandatory parameter)
        -- request with all parameters are missing
        -- request with fake parameters (fake - not from protocol, from another request)
        -- request is sent with invalid JSON structure
        -- different conditions of correlationID parameter (invalid, several the same etc.)

    	--Begin Test case CommonRequestCheck.1
    	--Description: This test is intended to check request with all parameters

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-97

			--Verification criteria: GetVehicleData request allows to receive the current data values for any of the following listed items: gps, speed, rpm, fuelLevel, fuelLevel_State, instantFuelConsumption, externalTemperature, vin, prndl, tirePressure, odometer, beltStatus, bodyInformation, deviceStatus, driverBraking, wiperStatus, headLampStatus, engineTorque, accPedalPosition, steeringWheelAngle, eCallInfo, airbagStatus, emergencyEvent, clusterModeStatus, myKey.
									--The response contains data values for requested items.
									
			function Test:GetVehicleData_Positive() 				
				self:getVehicleDataSuccess(allVehicleData)				
			end
		--End Test case CommonRequestCheck.1
		
		-----------------------------------------------------------------------------------------
		
		--Begin Test case CommonRequestCheck.2
		--Description: This test is intended to check request with mandatory and with or without conditional parameters
			
			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-97

			--Verification criteria: GetVehicleData request allows to receive the current data values for any of the following listed items: gps, speed, rpm, fuelLevel, fuelLevel_State, instantFuelConsumption, externalTemperature, vin, prndl, tirePressure, odometer, beltStatus, bodyInformation, deviceStatus, driverBraking, wiperStatus, headLampStatus, engineTorque, accPedalPosition, steeringWheelAngle, eCallInfo, airbagStatus, emergencyEvent, clusterModeStatus, myKey.
									--The response contains data values for requested items.			
			
			--Not applicable
			
		--End Test case CommonRequestCheck.2
		
		-----------------------------------------------------------------------------------------
		
		--Begin Test case CommonRequestCheck.3
		--Description: This test is intended to check processing requests without mandatory parameters

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-609

			--Verification criteria:
				--The request sent with NO parameters receives INVALID_DATA response code.
				function Test:GetVehicleData_AllParamsMissing() 
					self:getVehicleDataInvalidData({})
				end			
		--End Test case CommonRequestCheck.3
		
		-----------------------------------------------------------------------------------------

		--Begin Test case CommonRequestCheck.4
		--Description: Check processing request with different fake parameters

			--Requirement id in JAMA/or Jira ID: APPLINK-4518

			--Verification criteria: According to xml tests by Ford team all fake params should be ignored by SDL

			--Begin Test case CommonRequestCheck4.1
			--Description: With fake parameters				
				function Test:GetVehicleData_FakeParams()										
					--mobile side: sending GetVehicleData request
					local cid = self.mobileSession:SendRPC("GetVehicleData",
																		{
																			speed = true,
																			fakeParam ="fakeParam"
																		})
					
					--hmi side: expect GetVehicleData request
					EXPECT_HMICALL("VehicleInfo.GetVehicleData",{speed = true})					
					:Do(function(_,data)
						--hmi side: sending VehicleInfo.GetVehicleData response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {speed = 80.5})	
					end)
					:ValidIf(function(_,data)
						if data.params.fakeParam then							
							print(" \27[36m SDL re-sends fakeParam parameters to HMI \27[0m")							
							return false
						else 
							return true
						end
					end)
					
					--mobile side: expect GetVehicleData response
					EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS", speed = 80.5})
					
					DelayedExp(300)
				end
			--End Test case CommonRequestCheck4.1
			
			-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.4.2
			--Description: Parameters from another request
				function Test:GetVehicleData_ParamsAnotherRequest()
					--mobile side: sending GetVehicleData request
					local cid = self.mobileSession:SendRPC("GetVehicleData",
																				{
																					speed = true,
																					ttsChunks = 
																						{	
																							{ 
																								text ="SpeakFirst",
																								type ="TEXT",
																							}
																						}
																				})
					
					--hmi side: expect GetVehicleData request
					EXPECT_HMICALL("VehicleInfo.GetVehicleData",{speed = true})					
					:Do(function(_,data)
						--hmi side: sending VehicleInfo.GetVehicleData response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {speed = 80.5})
					end)
					:ValidIf(function(_,data)
						if data.params.ttsChunks then							
							print(" \27[36m SDL re-sends fakeParam parameters to HMI \27[0m")							
							return false
						else 
							return true
						end
					end)
					
					--mobile side: expect GetVehicleData response
					EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS", speed = 80.5})
					
					DelayedExp(300)
				end
			--End Test case CommonRequestCheck4.2
		--End Test case CommonRequestCheck.4
		
		-----------------------------------------------------------------------------------------

		--Begin Test case CommonRequestCheck.5
		--Description: Check processing request with invalid JSON syntax 

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-609

			--Verification criteria:  The request with wrong JSON syntax is sent, the response with INVALID_DATA result code is returned.
			function Test:GetVehicleData_InvalidJSON()
				  self.mobileSession.correlationId = self.mobileSession.correlationId + 1

				  local msg = 
				  {
					serviceType      = 7,
					frameInfo        = 0,
					rpcType          = 0,
					rpcFunctionId    = 22,
					rpcCorrelationId = self.mobileSession.correlationId,
				--<<!-- missing ':'
					payload          = '{"gps"  true}'
				  }
				  
				  self.mobileSession:Send(msg)
				  self.mobileSession:ExpectResponse(self.mobileSession.correlationId, { success = false, resultCode = "INVALID_DATA" })
				  
				  DelayedExp(300)
			end
		--End Test case CommonRequestCheck.5

		-----------------------------------------------------------------------------------------
--TODO: Requirement and Verification criteria need to be updated.
		--Begin Test case CommonRequestCheck.6
		--Description: Check processing requests with duplicate correlationID value

			--Requirement id in JAMA/or Jira ID: 

			--Verification criteria: 
				--
			function Test:GetVehicleData_correlationIdDuplicateValue()
				--mobile side: send GetVehicleData request 
				local CorIdGetVehicleData = self.mobileSession:SendRPC("GetVehicleData", {speed = true})
				
				local msg = 
				  {
					serviceType      = 7,
					frameInfo        = 0,
					rpcType          = 0,
					rpcFunctionId    = 22,
					rpcCorrelationId = CorIdGetVehicleData,				
					payload          = '{"rpm" : true}'
				  }
				
				--hmi side: expect GetVehicleData request
				EXPECT_HMICALL("VehicleInfo.GetVehicleData",
					{speed = true},
					{rpm = true}
				)
				:Do(function(exp,data)
					if exp.occurences == 1 then 
						self.mobileSession:Send(msg)
						
						--hmi side: sending VehicleInfo.GetVehicleData response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {speed = 80.5})
					else
						--hmi side: sending VehicleInfo.GetVehicleData response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {rpm = 500})
					end				
				end)
				:Times(2)
								
				--mobile side: expect GetVehicleData response
				EXPECT_RESPONSE(CorIdGetVehicleData, 
						{success = true, resultCode = "SUCCESS", speed = 80.5},
						{success = true, resultCode = "SUCCESS", rpm = 500})       
				:Times(2)
				
				DelayedExp(300)
			end
		--End Test case CommonRequestCheck.6
	--End Test suit CommonRequestCheck

---------------------------------------------------------------------------------------------
----------------------------------------II TEST BLOCK----------------------------------------
----------------------------------------Positive cases---------------------------------------
---------------------------------------------------------------------------------------------

	--=================================================================================--
	--------------------------------Positive request check-------------------------------
	--=================================================================================--

		--Begin Test suit PositiveRequestCheck
		--Description: check of each request parameter value in bound and boundary conditions

			--Begin Test case PositiveRequestCheck.1
			--Description: Check processing request with lower and upper bound values

				--Requirement id in JAMA: 
					-- SDLAQ-CRS-97,
					-- SDLAQ-CRS-608
				
				--Verification criteria: 
					--Checking all VehicleData parameter. The request is executed successfully				
				for i=1, #allVehicleData do
					Test["GetVehicleData_"..allVehicleData[i]] = function(self)
						self:getVehicleDataSuccess({allVehicleData[i]})
					end
				end
			--End Test case PositiveRequestCheck.1
		--End Test suit PositiveRequestCheck

	--=================================================================================--
	--------------------------------Positive response check------------------------------
	--=================================================================================--
		
		--------Checks-----------
		-- parameters with values in boundary conditions

		--Begin Test suit PositiveResponseCheck
		--Description: Checking parameters boundary conditions

			--Begin Test case PositiveResponseCheck.1
			--Description: Checking info parameter boundary conditions

				--Requirement id in JAMA:
					--SDLAQ-CRS-98
					
				--Verification criteria:
					-- The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode. The appropriate parameters sent in the request are returned with the data about subscription. 
	
				--Begin Test case PositiveResponseCheck.1.1
				--Description: Response with info parameter lower bound
					function Test:GetVehicleData_ResponseInfoLowerBound()						
						self:getVehicleDataSuccess({"speed"}, "a")
					end
				--End Test case PositiveResponseCheck.1.1
				
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveResponseCheck.1.2
				--Description:  Response with info parameter upper bound
					function Test:GetVehicleData_ResponseInfoUpperBound()						
						self:getVehicleDataSuccess({"speed"}, infoMessageValue)
					end
				--End Test case PositiveResponseCheck.1.2				
			--End Test case PositiveResponseCheck.1
			
			-----------------------------------------------------------------------------------------

			--Begin Test case PositiveResponseCheck.2
			--Description: Checking parameters boundary conditions

				--Requirement id in JAMA:
					--SDLAQ-CRS-98
					
				--Verification criteria:
					-- The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode. The appropriate parameters sent in the request are returned with the data about subscription. 
				
				--Begin Test case PositiveResponseCheck.2.1
				--Description: Response with longitudeDegrees parameter lower bound
					function Test:GetVehicleData_ResponseLowerBound_longitudeDegrees()						
						local response = setGVDResponse({"gps"})						
						response.gps["longitudeDegrees"] = -179.9			
						self:getVehicleData_ResponseSuccess(response)
					end
				--End Test case PositiveResponseCheck.2.1
				
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveResponseCheck.2.2
				--Description: Response with longitudeDegrees parameter upper bound
					function Test:GetVehicleData_ResponseUpperBound_longitudeDegrees()						
						local response = setGVDResponse({"gps"})						
						response.gps["longitudeDegrees"] = 179.9			
						self:getVehicleData_ResponseSuccess(response)
					end
				--End Test case PositiveResponseCheck.2.2
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case PositiveResponseCheck.2.3
				--Description: Response with latitudeDegrees parameter lower bound
					function Test:GetVehicleData_ResponseLowerBound_latitudeDegrees()						
						local response = setGVDResponse({"gps"})						
						response.gps["latitudeDegrees"] = -89.9		
						self:getVehicleData_ResponseSuccess(response)
					end
				--End Test case PositiveResponseCheck.2.3
				
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveResponseCheck.2.4
				--Description: Response with latitudeDegrees parameter upper bound
					function Test:GetVehicleData_ResponseUpperBound_latitudeDegrees()						
						local response = setGVDResponse({"gps"})						
						response.gps["latitudeDegrees"] = 89.9
						self:getVehicleData_ResponseSuccess(response)
					end
				--End Test case PositiveResponseCheck.2.4
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case PositiveResponseCheck.2.5
				--Description: Response with utcYear parameter lower bound
					function Test:GetVehicleData_ResponseLowerBound_utcYear()						
						local response = setGVDResponse({"gps"})						
						response.gps["utcYear"] = 2010
						self:getVehicleData_ResponseSuccess(response)
					end
				--End Test case PositiveResponseCheck.2.5
				
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveResponseCheck.2.6
				--Description: Response with utcYear parameter upper bound
					function Test:GetVehicleData_ResponseUpperBound_utcYear()						
						local response = setGVDResponse({"gps"})						
						response.gps["utcYear"] = 2100
						self:getVehicleData_ResponseSuccess(response)
					end
				--End Test case PositiveResponseCheck.2.6
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case PositiveResponseCheck.2.7
				--Description: Response with utcMonth parameter lower bound
					function Test:GetVehicleData_ResponseLowerBound_utcMonth()						
						local response = setGVDResponse({"gps"})						
						response.gps["utcMonth"] = 1
						self:getVehicleData_ResponseSuccess(response)
					end
				--End Test case PositiveResponseCheck.2.7
				
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveResponseCheck.2.8
				--Description: Response with utcMonth parameter upper bound
					function Test:GetVehicleData_ResponseUpperBound_utcMonth()						
						local response = setGVDResponse({"gps"})						
						response.gps["utcMonth"] = 12
						self:getVehicleData_ResponseSuccess(response)
					end
				--End Test case PositiveResponseCheck.2.8
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case PositiveResponseCheck.2.9
				--Description: Response with utcDay parameter lower bound
					function Test:GetVehicleData_ResponseLowerBound_utcDay()						
						local response = setGVDResponse({"gps"})						
						response.gps["utcDay"] = 1
						self:getVehicleData_ResponseSuccess(response)
					end
				--End Test case PositiveResponseCheck.2.9
				
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveResponseCheck.2.10
				--Description: Response with utcDay parameter upper bound
					function Test:GetVehicleData_ResponseUpperBound_utcDay()						
						local response = setGVDResponse({"gps"})						
						response.gps["utcDay"] = 31
						self:getVehicleData_ResponseSuccess(response)
					end
				--End Test case PositiveResponseCheck.2.10
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case PositiveResponseCheck.2.11
				--Description: Response with utcHours parameter lower bound
					function Test:GetVehicleData_ResponseLowerBound_utcHours()						
						local response = setGVDResponse({"gps"})						
						response.gps["utcHours"] = 0
						self:getVehicleData_ResponseSuccess(response)
					end
				--End Test case PositiveResponseCheck.2.11
				
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveResponseCheck.2.12
				--Description: Response with utcHours parameter upper bound
					function Test:GetVehicleData_ResponseUpperBound_utcHours()						
						local response = setGVDResponse({"gps"})						
						response.gps["utcHours"] = 23
						self:getVehicleData_ResponseSuccess(response)
					end
				--End Test case PositiveResponseCheck.2.12
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case PositiveResponseCheck.2.13
				--Description: Response with utcMinutes parameter lower bound
					function Test:GetVehicleData_ResponseLowerBound_utcMinutes()						
						local response = setGVDResponse({"gps"})						
						response.gps["utcMinutes"] = 0
						self:getVehicleData_ResponseSuccess(response)
					end
				--End Test case PositiveResponseCheck.2.13
				
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveResponseCheck.2.14
				--Description: Response with utcMinutes parameter upper bound
					function Test:GetVehicleData_ResponseUpperBound_utcMinutes()						
						local response = setGVDResponse({"gps"})						
						response.gps["utcMinutes"] = 59
						self:getVehicleData_ResponseSuccess(response)
					end
				--End Test case PositiveResponseCheck.2.14
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case PositiveResponseCheck.2.15
				--Description: Response with utcSeconds parameter lower bound
					function Test:GetVehicleData_ResponseLowerBound_utcSeconds()						
						local response = setGVDResponse({"gps"})						
						response.gps["utcSeconds"] = 0
						self:getVehicleData_ResponseSuccess(response)
					end
				--End Test case PositiveResponseCheck.2.15
				
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveResponseCheck.2.16
				--Description: Response with utcSeconds parameter upper bound
					function Test:GetVehicleData_ResponseUpperBound_utcSeconds()						
						local response = setGVDResponse({"gps"})						
						response.gps["utcSeconds"] = 59
						self:getVehicleData_ResponseSuccess(response)
					end
				--End Test case PositiveResponseCheck.2.16
				
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveResponseCheck.2.17
				--Description: Response with compassDirection in bound
					for i=1, #compassDirectionValues do
						Test["GetVehicleData_compassDirection_"..compassDirectionValues[i]] = function(self)
							local response = setGVDResponse({"gps"})						
							response.gps["compassDirection"] = compassDirectionValues[i]
							self:getVehicleData_ResponseSuccess(response)							
						end
					end
				--End Test case PositiveResponseCheck.2.17
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case PositiveResponseCheck.2.18
				--Description: Response with pdop parameter lower bound
					function Test:GetVehicleData_ResponseLowerBound_pdop()						
						local response = setGVDResponse({"gps"})						
						response.gps["pdop"] = 0.1
						self:getVehicleData_ResponseSuccess(response)
					end
				--End Test case PositiveResponseCheck.2.18
				
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveResponseCheck.2.19
				--Description: Response with pdop parameter upper bound
					function Test:GetVehicleData_ResponseUpperBound_pdop()						
						local response = setGVDResponse({"gps"})						
						response.gps["pdop"] = 9.9
						self:getVehicleData_ResponseSuccess(response)
					end
				--End Test case PositiveResponseCheck.2.19
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case PositiveResponseCheck.2.20
				--Description: Response with hdop parameter lower bound
					function Test:GetVehicleData_ResponseLowerBound_hdop()						
						local response = setGVDResponse({"gps"})						
						response.gps["hdop"] = 0.1
						self:getVehicleData_ResponseSuccess(response)
					end
				--End Test case PositiveResponseCheck.2.20
				
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveResponseCheck.2.21
				--Description: Response with hdop parameter upper bound
					function Test:GetVehicleData_ResponseUpperBound_hdop()						
						local response = setGVDResponse({"gps"})						
						response.gps["hdop"] = 9.9
						self:getVehicleData_ResponseSuccess(response)
					end
				--End Test case PositiveResponseCheck.2.21
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case PositiveResponseCheck.2.22
				--Description: Response with vdop parameter lower bound
					function Test:GetVehicleData_ResponseLowerBound_vdop()						
						local response = setGVDResponse({"gps"})						
						response.gps["vdop"] = 0.1
						self:getVehicleData_ResponseSuccess(response)
					end
				--End Test case PositiveResponseCheck.2.22
				
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveResponseCheck.2.23
				--Description: Response with vdop parameter upper bound
					function Test:GetVehicleData_ResponseUpperBound_vdop()						
						local response = setGVDResponse({"gps"})						
						response.gps["vdop"] = 9.9
						self:getVehicleData_ResponseSuccess(response)
					end
				--End Test case PositiveResponseCheck.2.23
				
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveResponseCheck.2.24
				--Description: Response with actual parameter in bound
					function Test:GetVehicleData_ResponseInBound_actual()						
						local response = setGVDResponse({"gps"})						
						response.gps["actual"] = false
						self:getVehicleData_ResponseSuccess(response)
					end
				--End Test case PositiveResponseCheck.2.24
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case PositiveResponseCheck.2.25
				--Description: Response with satellites parameter lower bound
					function Test:GetVehicleData_ResponseLowerBound_satellites()						
						local response = setGVDResponse({"gps"})						
						response.gps["satellites"] = 0
						self:getVehicleData_ResponseSuccess(response)
					end
				--End Test case PositiveResponseCheck.2.25
				
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveResponseCheck.2.26
				--Description: Response with satellites parameter upper bound
					function Test:GetVehicleData_ResponseUpperBound_satellites()						
						local response = setGVDResponse({"gps"})						
						response.gps["satellites"] = 31
						self:getVehicleData_ResponseSuccess(response)
					end
				--End Test case PositiveResponseCheck.2.26
				
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveResponseCheck.2.27
				--Description: Response with dimension parameter in bound
					for i=1, #dimensionValues do
						Test["GetVehicleData_dimension"..dimensionValues[i]] = function(self)
							local response = setGVDResponse({"gps"})						
							response.gps["dimension"] = dimensionValues[i]
							self:getVehicleData_ResponseSuccess(response)							
						end
					end
				--End Test case PositiveResponseCheck.2.27
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case PositiveResponseCheck.2.28
				--Description: Response with altitude parameter lower bound
					function Test:GetVehicleData_ResponseLowerBound_altitude()						
						local response = setGVDResponse({"gps"})						
						response.gps["altitude"] = -9999.9
						self:getVehicleData_ResponseSuccess(response)
					end
				--End Test case PositiveResponseCheck.2.28
				
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveResponseCheck.2.29
				--Description: Response with altitude parameter upper bound
					function Test:GetVehicleData_ResponseUpperBound_altitude()						
						local response = setGVDResponse({"gps"})						
						response.gps["altitude"] = 9999.9
						self:getVehicleData_ResponseSuccess(response)
					end
				--End Test case PositiveResponseCheck.2.29
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case PositiveResponseCheck.2.30
				--Description: Response with heading parameter lower bound
					function Test:GetVehicleData_ResponseLowerBound_heading()						
						local response = setGVDResponse({"gps"})						
						response.gps["heading"] = 0.1
						self:getVehicleData_ResponseSuccess(response)
					end
				--End Test case PositiveResponseCheck.2.30
				
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveResponseCheck.2.31
				--Description: Response with heading parameter upper bound
					function Test:GetVehicleData_ResponseUpperBound_heading()						
						local response = setGVDResponse({"gps"})						
						response.gps["heading"] = 359.99
						self:getVehicleData_ResponseSuccess(response)
					end
				--End Test case PositiveResponseCheck.2.31
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case PositiveResponseCheck.2.32
				--Description: Response with gps.speed parameter lower bound
					function Test:GetVehicleData_ResponseLowerBound_gps_speed()						
						local response = setGVDResponse({"gps"})						
						response.gps["speed"] = 0.1
						self:getVehicleData_ResponseSuccess(response)
					end
				--End Test case PositiveResponseCheck.2.32
				
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveResponseCheck.2.33
				--Description: Response with gps.speed parameter upper bound
					function Test:GetVehicleData_ResponseUpperBound_gps_speed()						
						local response = setGVDResponse({"gps"})						
						response.gps["speed"] = 499.9
						self:getVehicleData_ResponseSuccess(response)
					end
				--End Test case PositiveResponseCheck.2.33
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case PositiveResponseCheck.2.34
				--Description: Response with speed parameter lower bound
					function Test:GetVehicleData_ResponseLowerBound_speed()						
						local response = setGVDResponse({"speed"})						
						response["speed"] = 0.1
						self:getVehicleData_ResponseSuccess(response)
					end
				--End Test case PositiveResponseCheck.2.34
				
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveResponseCheck.2.35
				--Description: Response with speed parameter upper bound
					function Test:GetVehicleData_ResponseUpperBound_speed()						
						local response = setGVDResponse({"speed"})						
						response["speed"] = 699.9
						self:getVehicleData_ResponseSuccess(response)
					end
				--End Test case PositiveResponseCheck.2.35
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case PositiveResponseCheck.2.36
				--Description: Response with rpm parameter lower bound
					function Test:GetVehicleData_ResponseLowerBound_rpm()						
						local response = setGVDResponse({"rpm"})						
						response["rpm"] = 0
						self:getVehicleData_ResponseSuccess(response)
					end
				--End Test case PositiveResponseCheck.2.36
				
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveResponseCheck.2.37
				--Description: Response with rpm parameter upper bound
					function Test:GetVehicleData_ResponseUpperBound_rpm()						
						local response = setGVDResponse({"rpm"})						
						response["rpm"] = 20000
						self:getVehicleData_ResponseSuccess(response)
					end
				--End Test case PositiveResponseCheck.2.37
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case PositiveResponseCheck.2.38
				--Description: Response with fuelLevel parameter lower bound
					function Test:GetVehicleData_ResponseLowerBound_fuelLevel()						
						local response = setGVDResponse({"fuelLevel"})						
						response["fuelLevel"] = -5.9
						self:getVehicleData_ResponseSuccess(response)
					end
				--End Test case PositiveResponseCheck.2.38
				
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveResponseCheck.2.39
				--Description: Response with fuelLevel parameter upper bound
					function Test:GetVehicleData_ResponseUpperBound_fuelLevel()						
						local response = setGVDResponse({"fuelLevel"})						
						response["fuelLevel"] = 105.9
						self:getVehicleData_ResponseSuccess(response)
					end
				--End Test case PositiveResponseCheck.2.39
				
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveResponseCheck.2.40
				--Description: Response with fuelLevel_State parameter in bound
					for i=1, #componentVolumeStatus do
						Test["GetVehicleData_fuelLevel_State_"..componentVolumeStatus[i]] = function(self)
							local response = setGVDResponse({"fuelLevel_State"})						
							response["fuelLevel_State"] = componentVolumeStatus[i]
							self:getVehicleData_ResponseSuccess(response)							
						end
					end
				--End Test case PositiveResponseCheck.2.40				
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case PositiveResponseCheck.2.41
				--Description: Response with instantFuelConsumption parameter lower bound
					function Test:GetVehicleData_ResponseLowerBound_instantFuelConsumption()						
						local response = setGVDResponse({"instantFuelConsumption"})						
						response["instantFuelConsumption"] = 0.1
						self:getVehicleData_ResponseSuccess(response)
					end
				--End Test case PositiveResponseCheck.2.41
				
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveResponseCheck.2.42
				--Description: Response with instantFuelConsumption parameter upper bound
					function Test:GetVehicleData_ResponseUpperBound_instantFuelConsumption()						
						local response = setGVDResponse({"instantFuelConsumption"})						
						response["instantFuelConsumption"] = 25574.9
						self:getVehicleData_ResponseSuccess(response)
					end
				--End Test case PositiveResponseCheck.2.42
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case PositiveResponseCheck.2.43
				--Description: Response with externalTemperature parameter lower bound
					function Test:GetVehicleData_ResponseLowerBound_externalTemperature()						
						local response = setGVDResponse({"externalTemperature"})						
						response["externalTemperature"] = -39.9
						self:getVehicleData_ResponseSuccess(response)
					end
				--End Test case PositiveResponseCheck.2.43
				
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveResponseCheck.2.44
				--Description: Response with externalTemperature parameter upper bound
					function Test:GetVehicleData_ResponseUpperBound_externalTemperature()						
						local response = setGVDResponse({"externalTemperature"})						
						response["externalTemperature"] = 99.9
						self:getVehicleData_ResponseSuccess(response)
					end
				--End Test case PositiveResponseCheck.2.44
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case PositiveResponseCheck.2.45
				--Description: Response with vin parameter lower bound
					function Test:GetVehicleData_ResponseLowerBound_vin()						
						local response = setGVDResponse({"vin"})						
						response["vin"] = "1"
						self:getVehicleData_ResponseSuccess(response)
					end
				--End Test case PositiveResponseCheck.2.45
				
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveResponseCheck.2.46
				--Description: Response with vin parameter upper bound
					function Test:GetVehicleData_ResponseUpperBound_vin()						
						local response = setGVDResponse({"vin"})						
						response["vin"] = "12345678912345678"
						self:getVehicleData_ResponseSuccess(response)
					end
				--End Test case PositiveResponseCheck.2.46
				
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveResponseCheck.2.47
				--Description: Response with prndl parameter in bound
					for i=1, #prndlValues do
						Test["GetVehicleData_prndl_"..prndlValues[i]] = function(self)
							local response = setGVDResponse({"prndl"})						
							response["prndl"] = prndlValues[i]
							self:getVehicleData_ResponseSuccess(response)							
						end
					end
				--End Test case PositiveResponseCheck.2.47
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case PositiveResponseCheck.2.48
				--Description: Response with pressureTelltale parameter in bound
					for i=1, #warningLightStatus do
						Test["GetVehicleData_pressureTelltale_"..warningLightStatus[i]] = function(self)
							local response = setGVDResponse({"tirePressure"})						
							response.tirePressure["pressureTelltale"] = warningLightStatus[i]
							self:getVehicleData_ResponseSuccess(response)							
						end
					end
				--End Test case PositiveResponseCheck.2.48
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case PositiveResponseCheck.2.49
				--Description: Response with leftFront parameter in bound
					for i=1, #componentVolumeStatus do
						Test["GetVehicleData_leftFront_"..componentVolumeStatus[i]] = function(self)
							local response = {tirePressure={leftFront = {}}}					
							response.tirePressure.leftFront["status"] = componentVolumeStatus[i]
							self:getVehicleData_ResponseSuccess(response)							
						end
					end
				--End Test case PositiveResponseCheck.2.49
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case PositiveResponseCheck.2.50
				--Description: Response with rightFront parameter in bound
					for i=1, #componentVolumeStatus do
						Test["GetVehicleData_rightFront_"..componentVolumeStatus[i]] = function(self)
							local response = {tirePressure={rightFront = {}}}					
							response.tirePressure.rightFront["status"] = componentVolumeStatus[i]
							self:getVehicleData_ResponseSuccess(response)							
						end
					end
				--End Test case PositiveResponseCheck.2.50
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case PositiveResponseCheck.2.51
				--Description: Response with leftRear parameter in bound
					for i=1, #componentVolumeStatus do
						Test["GetVehicleData_leftRear_"..componentVolumeStatus[i]] = function(self)
							local response = {tirePressure={leftRear = {}}}					
							response.tirePressure.leftRear["status"] = componentVolumeStatus[i]
							self:getVehicleData_ResponseSuccess(response)											
						end
					end
				--End Test case PositiveResponseCheck.2.51
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case PositiveResponseCheck.2.52
				--Description: Response with rightRear parameter in bound
					for i=1, #componentVolumeStatus do
						Test["GetVehicleData_rightRear_"..componentVolumeStatus[i]] = function(self)
							local response = {tirePressure={rightRear = {}}}					
							response.tirePressure.rightRear["status"] = componentVolumeStatus[i]
							self:getVehicleData_ResponseSuccess(response)							
						end
					end
				--End Test case PositiveResponseCheck.2.52
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case PositiveResponseCheck.2.53
				--Description: Response with innerLeftRear parameter in bound
					for i=1, #componentVolumeStatus do
						Test["GetVehicleData_innerLeftRear_"..componentVolumeStatus[i]] = function(self)
							local response = {tirePressure={innerLeftRear = {}}}					
							response.tirePressure.innerLeftRear["status"] = componentVolumeStatus[i]
							self:getVehicleData_ResponseSuccess(response)							
						end
					end
				--End Test case PositiveResponseCheck.2.53
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case PositiveResponseCheck.2.54
				--Description: Response with innerRightRear parameter in bound
					for i=1, #componentVolumeStatus do
						Test["GetVehicleData_innerRightRear_"..componentVolumeStatus[i]] = function(self)
							local response = {tirePressure={innerRightRear = {}}}					
							response.tirePressure.innerRightRear["status"] = componentVolumeStatus[i]
							self:getVehicleData_ResponseSuccess(response)							
						end
					end
				--End Test case PositiveResponseCheck.2.54
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case PositiveResponseCheck.2.55
				--Description: Response with odometer parameter lower bound
					function Test:GetVehicleData_ResponseLowerBound_odometer()						
						local response = setGVDResponse({"odometer"})						
						response["odometer"] = 0
						self:getVehicleData_ResponseSuccess(response)
					end
				--End Test case PositiveResponseCheck.2.55
				
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveResponseCheck.2.56
				--Description: Response with odometer parameter upper bound
					function Test:GetVehicleData_ResponseUpperBound_odometer()						
						local response = setGVDResponse({"odometer"})						
						response["odometer"] = 17000000
						self:getVehicleData_ResponseSuccess(response)
					end
				--End Test case PositiveResponseCheck.2.56
				
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveResponseCheck.2.57
				--Description: Response with beltStatus parameter in bound
					local beltStatusParams = {"driverBeltDeployed", "passengerBeltDeployed", "passengerBuckleBelted", "driverBuckleBelted", "leftRow2BuckleBelted", "passengerChildDetected", "rightRow2BuckleBelted", "middleRow2BuckleBelted", "middleRow3BuckleBelted", "leftRow3BuckleBelted", "rightRow3BuckleBelted", "leftRearInflatableBelted", "rightRearInflatableBelted", "middleRow1BeltDeployed", "middleRow1BuckleBelted"}
					for j=1, #beltStatusParams do
						for i=1, #vehicleDataEventStatus do
							Test["GetVehicleData_"..beltStatusParams[j].."_"..vehicleDataEventStatus[i]] = function(self)
								local response = {beltStatus={}}														
								response.beltStatus[beltStatusParams[j]] = vehicleDataEventStatus[i]
								self:getVehicleData_ResponseSuccess(response)								
							end
						end
					end
				--End Test case PositiveResponseCheck.2.57
				
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveResponseCheck.2.58
				--Description: Response with parkBrakeActive parameter in bound
					function Test:GetVehicleData_ResponseInBound_parkBrakeActive()						
						local response = setGVDResponse({"bodyInformation"})						
						response.bodyInformation["parkBrakeActive"] = false
						self:getVehicleData_ResponseSuccess(response)
					end
				--End Test case PositiveResponseCheck.2.58
				
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveResponseCheck.2.59
				--Description: Response with ignitionStableStatus parameter in bound
					for i=1, #ignitionStableStatusValues do
						Test["GetVehicleData_ignitionStableStatus_"..ignitionStableStatusValues[i]] = function(self)
							local response = setGVDResponse({"bodyInformation"})						
							response.bodyInformation["ignitionStableStatus"] = ignitionStableStatusValues[i]
							self:getVehicleData_ResponseSuccess(response)							
						end
					end
				--End Test case PositiveResponseCheck.2.59				
				
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveResponseCheck.2.60
				--Description: Response with ignitionStatus parameter in bound
					for i=1, #ignitionStatusValues do
						Test["GetVehicleData_ignitionStatus_"..ignitionStatusValues[i]] = function(self)
							local response = setGVDResponse({"bodyInformation"})						
							response.bodyInformation["ignitionStatus"] = ignitionStatusValues[i]
							self:getVehicleData_ResponseSuccess(response)							
						end
					end
				--End Test case PositiveResponseCheck.2.60
				
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveResponseCheck.2.61
				--Description: Response with driverDoorAjar parameter in bound
					function Test:GetVehicleData_ResponseInBound_driverDoorAjar()						
						local response = setGVDResponse({"bodyInformation"})						
						response.bodyInformation["driverDoorAjar"] = false
						self:getVehicleData_ResponseSuccess(response)
					end
				--End Test case PositiveResponseCheck.2.61
				
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveResponseCheck.2.62
				--Description: Response with passengerDoorAjar parameter in bound
					function Test:GetVehicleData_ResponseInBound_passengerDoorAjar()						
						local response = setGVDResponse({"bodyInformation"})						
						response.bodyInformation["passengerDoorAjar"] = false
						self:getVehicleData_ResponseSuccess(response)
					end
				--End Test case PositiveResponseCheck.2.62
				
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveResponseCheck.2.63
				--Description: Response with rearLeftDoorAjar parameter in bound
					function Test:GetVehicleData_ResponseInBound_rearLeftDoorAjar()						
						local response = setGVDResponse({"bodyInformation"})						
						response.bodyInformation["rearLeftDoorAjar"] = false
						self:getVehicleData_ResponseSuccess(response)
					end
				--End Test case PositiveResponseCheck.2.63
				
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveResponseCheck.2.64
				--Description: Response with rearRightDoorAjar parameter in bound
					function Test:GetVehicleData_ResponseInBound_rearRightDoorAjar()						
						local response = setGVDResponse({"bodyInformation"})						
						response.bodyInformation["rearRightDoorAjar"] = false
						self:getVehicleData_ResponseSuccess(response)
					end
				--End Test case PositiveResponseCheck.2.64
				
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveResponseCheck.2.65
				--Description: Response with voiceRecOn parameter in bound
					function Test:GetVehicleData_ResponseInBound_voiceRecOn()						
						local response = setGVDResponse({"deviceStatus"})						
						response.deviceStatus["voiceRecOn"] = false
						self:getVehicleData_ResponseSuccess(response)
					end
				--End Test case PositiveResponseCheck.2.65
				
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveResponseCheck.2.66
				--Description: Response with btIconOn parameter in bound
					function Test:GetVehicleData_ResponseInBound_btIconOn()						
						local response = setGVDResponse({"deviceStatus"})						
						response.deviceStatus["btIconOn"] = false
						self:getVehicleData_ResponseSuccess(response)
					end
				--End Test case PositiveResponseCheck.2.66
				
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveResponseCheck.2.67
				--Description: Response with callActive parameter in bound
					function Test:GetVehicleData_ResponseInBound_callActive()						
						local response = setGVDResponse({"deviceStatus"})						
						response.deviceStatus["callActive"] = false
						self:getVehicleData_ResponseSuccess(response)
					end
				--End Test case PositiveResponseCheck.2.67
				
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveResponseCheck.2.68
				--Description: Response with phoneRoaming parameter in bound
					function Test:GetVehicleData_ResponseInBound_phoneRoaming()						
						local response = setGVDResponse({"deviceStatus"})						
						response.deviceStatus["phoneRoaming"] = false
						self:getVehicleData_ResponseSuccess(response)
					end
				--End Test case PositiveResponseCheck.2.68
				
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveResponseCheck.2.69
				--Description: Response with textMsgAvailable parameter in bound
					function Test:GetVehicleData_ResponseInBound_textMsgAvailable()						
						local response = setGVDResponse({"deviceStatus"})						
						response.deviceStatus["textMsgAvailable"] = false
						self:getVehicleData_ResponseSuccess(response)
					end
				--End Test case PositiveResponseCheck.2.69
				
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveResponseCheck.2.70
				--Description: Response with battLevelStatus parameter in bound
					for i=1, #deviceLevelStatus do
						Test["GetVehicleData_battLevelStatus_"..deviceLevelStatus[i]] = function(self)
							local response = setGVDResponse({"deviceStatus"})						
							response.deviceStatus["battLevelStatus"] = deviceLevelStatus[i]
							self:getVehicleData_ResponseSuccess(response)							
						end
					end
				--End Test case PositiveResponseCheck.2.70
				
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveResponseCheck.2.71
				--Description: Response with monoAudioOutputMuted parameter in bound
					function Test:GetVehicleData_ResponseInBound_monoAudioOutputMuted()						
						local response = setGVDResponse({"deviceStatus"})						
						response.deviceStatus["monoAudioOutputMuted"] = false
						self:getVehicleData_ResponseSuccess(response)
					end
				--End Test case PositiveResponseCheck.2.71
				
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveResponseCheck.2.72
				--Description: Response with signalLevelStatus parameter in bound
					for i=1, #deviceLevelStatus do
						Test["GetVehicleData_signalLevelStatus_"..deviceLevelStatus[i]] = function(self)
							local response = setGVDResponse({"deviceStatus"})						
							response.deviceStatus["signalLevelStatus"] = deviceLevelStatus[i]
							self:getVehicleData_ResponseSuccess(response)							
						end
					end
				--End Test case PositiveResponseCheck.2.72
				
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveResponseCheck.2.73
				--Description: Response with primaryAudioSource parameter in bound
					for i=1, #primaryAudioSourceValues do
						Test["GetVehicleData_primaryAudioSource_"..primaryAudioSourceValues[i]] = function(self)
							local response = setGVDResponse({"deviceStatus"})						
							response.deviceStatus["primaryAudioSource"] = primaryAudioSourceValues[i]
							self:getVehicleData_ResponseSuccess(response)							
						end
					end
				--End Test case PositiveResponseCheck.2.73
				
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveResponseCheck.2.74
				--Description: Response with eCallEventActive parameter in bound
					function Test:GetVehicleData_ResponseInBound_eCallEventActive()						
						local response = setGVDResponse({"deviceStatus"})						
						response.deviceStatus["eCallEventActive"] = false
						self:getVehicleData_ResponseSuccess(response)
					end
				--End Test case PositiveResponseCheck.2.74
				
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveResponseCheck.2.75
				--Description: Response with driverBraking parameter in bound
					for i=1, #vehicleDataEventStatus do
						Test["GetVehicleData_driverBraking_"..vehicleDataEventStatus[i]] = function(self)
							local response = setGVDResponse({"driverBraking"})						
							response["driverBraking"] = vehicleDataEventStatus[i]
							self:getVehicleData_ResponseSuccess(response)							
						end
					end
				--End Test case PositiveResponseCheck.2.75
				
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveResponseCheck.2.76
				--Description: Response with wiperStatus parameter in bound
					for i=1, #wiperStatusValues do
						Test["GetVehicleData_wiperStatus_"..wiperStatusValues[i]] = function(self)
							local response = setGVDResponse({"wiperStatus"})						
							response["wiperStatus"] = wiperStatusValues[i]
							self:getVehicleData_ResponseSuccess(response)							
						end
					end
				--End Test case PositiveResponseCheck.2.76
				
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveResponseCheck.2.77
				--Description: Response with lowBeamsOn parameter in bound
					function Test:GetVehicleData_ResponseInBound_lowBeamsOn()						
						local response = setGVDResponse({"headLampStatus"})						
						response.headLampStatus["lowBeamsOn"] = false
						self:getVehicleData_ResponseSuccess(response)
					end
				--End Test case PositiveResponseCheck.2.77
				
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveResponseCheck.2.78
				--Description: Response with highBeamsOn parameter in bound
					function Test:GetVehicleData_ResponseInBound_highBeamsOn()						
						local response = setGVDResponse({"headLampStatus"})						
						response.headLampStatus["highBeamsOn"] = false
						self:getVehicleData_ResponseSuccess(response)
					end
				--End Test case PositiveResponseCheck.2.78
				
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveResponseCheck.2.79
				--Description: Response with ambientLightSensorStatus parameter in bound
					for i=1, #ambientLightStatus do
						Test["GetVehicleData_ambientLightSensorStatus_"..ambientLightStatus[i]] = function(self)
							local response = setGVDResponse({"headLampStatus"})						
							response.headLampStatus["ambientLightSensorStatus"] = ambientLightStatus[i]
							self:getVehicleData_ResponseSuccess(response)							
						end
					end
				--End Test case PositiveResponseCheck.2.79
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case PositiveResponseCheck.2.80
				--Description: Response with engineTorque parameter lower bound
					function Test:GetVehicleData_ResponseLowerBound_engineTorque()						
						local response = setGVDResponse({"engineTorque"})						
						response["engineTorque"] = -999.9
						self:getVehicleData_ResponseSuccess(response)
					end
				--End Test case PositiveResponseCheck.2.80
				
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveResponseCheck.2.81
				--Description: Response with engineTorque parameter upper bound
					function Test:GetVehicleData_ResponseUpperBound_engineTorque()						
						local response = setGVDResponse({"engineTorque"})						
						response["engineTorque"] = 1999.9
						self:getVehicleData_ResponseSuccess(response)
					end
				--End Test case PositiveResponseCheck.2.81
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case PositiveResponseCheck.2.82
				--Description: Response with accPedalPosition parameter lower bound
					function Test:GetVehicleData_ResponseLowerBound_accPedalPosition()						
						local response = setGVDResponse({"accPedalPosition"})						
						response["accPedalPosition"] = 0.1
						self:getVehicleData_ResponseSuccess(response)
					end
				--End Test case PositiveResponseCheck.2.82
				
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveResponseCheck.2.83
				--Description: Response with accPedalPosition parameter upper bound
					function Test:GetVehicleData_ResponseUpperBound_accPedalPosition()						
						local response = setGVDResponse({"accPedalPosition"})						
						response["accPedalPosition"] = 99.9
						self:getVehicleData_ResponseSuccess(response)
					end
				--End Test case PositiveResponseCheck.2.83
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case PositiveResponseCheck.2.84
				--Description: Response with steeringWheelAngle parameter lower bound
					function Test:GetVehicleData_ResponseLowerBound_steeringWheelAngle()						
						local response = setGVDResponse({"steeringWheelAngle"})						
						response["steeringWheelAngle"] = -1999.9
						self:getVehicleData_ResponseSuccess(response)
					end
				--End Test case PositiveResponseCheck.2.84
				
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveResponseCheck.2.85
				--Description: Response with steeringWheelAngle parameter upper bound
					function Test:GetVehicleData_ResponseUpperBound_steeringWheelAngle()						
						local response = setGVDResponse({"steeringWheelAngle"})						
						response["steeringWheelAngle"] = 1999.9
						self:getVehicleData_ResponseSuccess(response)
					end
				--End Test case PositiveResponseCheck.2.85
				
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveResponseCheck.2.86
				--Description: Response with eCallNotificationStatus parameter in bound
					for i=1, #vehicleDataNotificationStatus do
						Test["GetVehicleData_eCallNotificationStatus_"..vehicleDataNotificationStatus[i]] = function(self)
							local response = setGVDResponse({"eCallInfo"})						
							response.eCallInfo["eCallNotificationStatus"] = vehicleDataNotificationStatus[i]
							self:getVehicleData_ResponseSuccess(response)							
						end
					end					
				--End Test case PositiveResponseCheck.2.86
				
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveResponseCheck.2.87
				--Description: Response with auxECallNotificationStatus parameter in bound
					for i=1, #vehicleDataNotificationStatus do
						Test["GetVehicleData_auxECallNotificationStatus_"..vehicleDataNotificationStatus[i]] = function(self)
							local response = setGVDResponse({"eCallInfo"})						
							response.eCallInfo["auxECallNotificationStatus"] = vehicleDataNotificationStatus[i]
							self:getVehicleData_ResponseSuccess(response)							
						end
					end					
				--End Test case PositiveResponseCheck.2.87
				
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveResponseCheck.2.88
				--Description: Response with eCallConfirmationStatus parameter in bound
					for i=1, #eCallConfirmationStatusValues do
						Test["GetVehicleData_eCallConfirmationStatus_"..eCallConfirmationStatusValues[i]] = function(self)
							local response = setGVDResponse({"eCallInfo"})						
							response.eCallInfo["eCallConfirmationStatus"] = eCallConfirmationStatusValues[i]
							self:getVehicleData_ResponseSuccess(response)							
						end
					end					
				--End Test case PositiveResponseCheck.2.88
				
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveResponseCheck.2.89
				--Description: Response with airbagStatus parameter in bound
					local airbagStatusParams = {"driverAirbagDeployed", "driverSideAirbagDeployed", "driverCurtainAirbagDeployed", "passengerAirbagDeployed", "passengerCurtainAirbagDeployed", "driverKneeAirbagDeployed", "passengerSideAirbagDeployed", "passengerKneeAirbagDeployed"}
					for j=1, #airbagStatusParams do
						for i=1, #vehicleDataEventStatus do
							Test["GetVehicleData_"..airbagStatusParams[j].."_"..vehicleDataEventStatus[i]] = function(self)
								local response = setGVDResponse({"airbagStatus"})						
								response.airbagStatus[airbagStatusParams[j]] = vehicleDataEventStatus[i]
								self:getVehicleData_ResponseSuccess(response)								
							end
						end
					end					
				--End Test case PositiveResponseCheck.2.89
				
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveResponseCheck.2.90
				--Description: Response with emergencyEventType parameter in bound
					for i=1, #emergencyEventTypeValues do
						Test["GetVehicleData_emergencyEventType_"..emergencyEventTypeValues[i]] = function(self)
							local response = setGVDResponse({"emergencyEvent"})						
							response.emergencyEvent["emergencyEventType"] = emergencyEventTypeValues[i]
							self:getVehicleData_ResponseSuccess(response)							
						end
					end				
				--End Test case PositiveResponseCheck.2.90
				
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveResponseCheck.2.91
				--Description: Response with fuelCutoffStatus parameter in bound
					for i=1, #fuelCutoffStatusValues do
						Test["GetVehicleData_fuelCutoffStatus_"..fuelCutoffStatusValues[i]] = function(self)
							local response = setGVDResponse({"emergencyEvent"})						
							response.emergencyEvent["fuelCutoffStatus"] = fuelCutoffStatusValues[i]
							self:getVehicleData_ResponseSuccess(response)							
						end
					end				
				--End Test case PositiveResponseCheck.2.91
				
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveResponseCheck.2.92
				--Description: Response with rolloverEvent parameter in bound
					for i=1, #vehicleDataEventStatus do
						Test["GetVehicleData_rolloverEvent_"..vehicleDataEventStatus[i]] = function(self)
							local response = setGVDResponse({"emergencyEvent"})						
							response.emergencyEvent["rolloverEvent"] = vehicleDataEventStatus[i]
							self:getVehicleData_ResponseSuccess(response)							
						end
					end				
				--End Test case PositiveResponseCheck.2.92
				
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveResponseCheck.2.93
				--Description: Response with maximumChangeVelocity parameter in bound
					local inBound = {0, 255}
					for i=1, #inBound do
						Test["GetVehicleData_maximumChangeVelocity_"..inBound[i]] = function(self)
							local response = setGVDResponse({"emergencyEvent"})						
							response.emergencyEvent["maximumChangeVelocity"] = inBound[i]
							self:getVehicleData_ResponseSuccess(response)					
						end
					end				
				--End Test case PositiveResponseCheck.2.93
				
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveResponseCheck.2.94
				--Description: Response with multipleEvents parameter in bound
					for i=1, #vehicleDataEventStatus do
						Test["GetVehicleData_multipleEvents_"..vehicleDataEventStatus[i]] = function(self)
							local response = setGVDResponse({"emergencyEvent"})						
							response.emergencyEvent["multipleEvents"] = vehicleDataEventStatus[i]
							self:getVehicleData_ResponseSuccess(response)							
						end
					end				
				--End Test case PositiveResponseCheck.2.94
				
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveResponseCheck.2.95
				--Description: Response with powerModeActive parameter in bound
					function Test:GetVehicleData_ResponseInBound_powerModeActive()						
						local response = setGVDResponse({"clusterModeStatus"})						
						response.clusterModeStatus["powerModeActive"] = false
						self:getVehicleData_ResponseSuccess(response)
					end
				--End Test case PositiveResponseCheck.2.95
				
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveResponseCheck.2.96
				--Description: Response with powerModeQualificationStatus parameter in bound
					for i=1, #powerModeQualificationStatusValues do
						Test["GetVehicleData_powerModeQualificationStatus_"..powerModeQualificationStatusValues[i]] = function(self)
							local response = setGVDResponse({"clusterModeStatus"})						
							response.clusterModeStatus["powerModeQualificationStatus"] = powerModeQualificationStatusValues[i]
							self:getVehicleData_ResponseSuccess(response)							
						end
					end				
				--End Test case PositiveResponseCheck.2.96
				
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveResponseCheck.2.97
				--Description: Response with carModeStatus parameter in bound
					for i=1, #carModeStatusValues do
						Test["GetVehicleData_carModeStatus_"..carModeStatusValues[i]] = function(self)
							local response = setGVDResponse({"clusterModeStatus"})						
							response.clusterModeStatus["carModeStatus"] = carModeStatusValues[i]
							self:getVehicleData_ResponseSuccess(response)							
						end
					end				
				--End Test case PositiveResponseCheck.2.97
				
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveResponseCheck.2.98
				--Description: Response with powerModeStatus parameter in bound
					for i=1, #powerModeStatusValues do
						Test["GetVehicleData_powerModeStatus_"..powerModeStatusValues[i]] = function(self)
							local response = setGVDResponse({"clusterModeStatus"})						
							response.clusterModeStatus["powerModeStatus"] = powerModeStatusValues[i]
							self:getVehicleData_ResponseSuccess(response)							
						end
					end				
				--End Test case PositiveResponseCheck.2.98			
				
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveResponseCheck.2.99
				--Description: Response with monoAudioOutputMuted parameter in bound
					function Test:GetVehicleData_ResponseInBound_stereoAudioOutputMuted()						
						local response = setGVDResponse({"deviceStatus"})						
						response.deviceStatus["stereoAudioOutputMuted"] = false
						self:getVehicleData_ResponseSuccess(response)
					end
				--End Test case PositiveResponseCheck.2.99	
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case PositiveResponseCheck.2.100
				--Description: Response with e911Override parameter in bound
					for i=1, #vehicleDataStatus do
						Test["GetVehicleData_fuelLevel_State_"..vehicleDataStatus[i]] = function(self)
							local response = setGVDResponse({"myKey"})						
							response.myKey["e911Override"] = vehicleDataStatus[i]
							self:getVehicleData_ResponseSuccess(response)							
						end
					end
				--End Test case PositiveResponseCheck.2.100				
			--End Test case PositiveResponseCheck.2
			
			-----------------------------------------------------------------------------------------

			--Begin Test case PositiveResponseCheck.3
			--Description: Checking process response with only mandatory or with conditional parameter

				--Requirement id in JAMA:
					--SDLAQ-CRS-98
					
				--Verification criteria:
					-- The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode. The appropriate parameters sent in the request are returned with the data about subscription. 
	
				--Begin Test case PositiveResponseCheck.3.1
				--Description: Response with only mandatory in gps structure
					function Test:GetVehicleData_Response_OnlyMandatoryGPS()						
						local response = { 
											gps = {
												longitudeDegrees = 25.5,
												latitudeDegrees = 45.5
											}
										}
						self:getVehicleData_ResponseSuccess(response)
					end
				--End Test case PositiveResponseCheck.3.1
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case PositiveResponseCheck.3.2
				--Description: Response with only mandatory in bodyInformation structure
					function Test:GetVehicleData_Response_OnlyMandatoryBodyInformation()						
						local response = { 
											bodyInformation = {
												parkBrakeActive = true,
												ignitionStableStatus = "MISSING_FROM_TRANSMITTER",
												ignitionStatus = "UNKNOWN"
											}
										}
						self:getVehicleData_ResponseSuccess(response)
					end
				--End Test case PositiveResponseCheck.3.2
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case PositiveResponseCheck.3.3
				--Description: Response with one parameter in tirePressure structure
					local response = { 
								{param = "pressureTelltale", value = {tirePressure={ pressureTelltale = "ON"}}},
								{param = "leftFront",		value = {tirePressure={ leftFront = {status = "NORMAL"}}}},
								{param = "rightFront", 		value = {tirePressure={ rightFront = {status = "NORMAL"}}}},
								{param = "leftRear", 		value = {tirePressure={ leftRear = {status = "NORMAL"}}}},
								{param = "rightRear", 		value = {tirePressure={ rightRear = {status = "NORMAL"}}}},
								{param = "innerLeftRear", 	value = {tirePressure={ innerLeftRear = {status = "NORMAL"}}}},
								{param = "innerRightRear", 	value = {tirePressure={ innerRightRear = {status = "NORMAL"}}}},	
							}
					for i=1, #response do
						Test["GetVehicleData_Only_"..response[i].param.."InTirePressure"] = function(self)
							self:getVehicleData_ResponseSuccess(response[i].value)
						end
					end	
				--End Test case PositiveResponseCheck.3.3
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case PositiveResponseCheck.3.4
				--Description: Response with one parameter in beltStatusParams structure
					local beltStatusParams = {"driverBeltDeployed", "passengerBeltDeployed", "passengerBuckleBelted", "driverBuckleBelted", "leftRow2BuckleBelted", "passengerChildDetected", "rightRow2BuckleBelted", "middleRow2BuckleBelted", "middleRow3BuckleBelted", "leftRow3BuckleBelted", "rightRow3BuckleBelted", "leftRearInflatableBelted", "rightRearInflatableBelted", "middleRow1BeltDeployed", "middleRow1BuckleBelted"}
					for i=1, #beltStatusParams do
						Test["GetVehicleData_Only_"..beltStatusParams[i].."InBeltStatus"] = function(self)
							local response = {beltStatus = {}}
							response.beltStatus[beltStatusParams[i]] = "NOT_SUPPORTED"
							self:getVehicleData_ResponseSuccess(response)
						end
					end	
				--End Test case PositiveResponseCheck.3.4
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case PositiveResponseCheck.3.5
				--Description: Response with one parameter in deviceStatus structure
					local deviceStatusParams = {
												{param = "voiceRecOn",				value = true},
												{param = "btIconOn",				value = true},
												{param = "callActive",				value = true},
												{param = "phoneRoaming",			value = true},
												{param = "textMsgAvailable",		value = true},
												{param = "battLevelStatus",			value = "THREE_LEVEL_BARS"},
												{param = "stereoAudioOutputMuted",	value = true},
												{param = "monoAudioOutputMuted",	value = true},
												{param = "signalLevelStatus",		value = "THREE_LEVEL_BARS"},
												{param = "primaryAudioSource",		value = "BLUETOOTH_STEREO_BTST"},
												{param = "eCallEventActive",		value = true}}
					for i=1, #deviceStatusParams do
						Test["GetVehicleData_Only_"..deviceStatusParams[i].param.."InDeviceStatus"] = function(self)
							local response = {deviceStatus = {}}
							response.deviceStatus[deviceStatusParams[i].param] = deviceStatusParams[i].value
							self:getVehicleData_ResponseSuccess(response)
						end
					end
				--End Test case PositiveResponseCheck.3.5	
			--End Test case PositiveResponseCheck.3
		--End Test suit PositiveResponseCheck
		

----------------------------------------------------------------------------------------------
----------------------------------------III TEST BLOCK----------------------------------------
----------------------------------------Negative cases----------------------------------------
----------------------------------------------------------------------------------------------

	--=================================================================================--
	---------------------------------Negative request check------------------------------
	--=================================================================================--

	--Begin Test suit NegativeRequestCheck
		--Description: check of each request parameter value out of bound, missing, with wrong type, empty, duplicate etc.

			--Begin Test case NegativeRequestCheck.1
			--Description: Check processing requests with out of lower and upper bound values 
				
				--Not applicable
				
			--End Test case NegativeRequestCheck.1

			-----------------------------------------------------------------------------------------
			
			--Begin Test case NegativeRequestCheck.2
			--Description: Check processing requests with empty values

				--Requirement id in JAMA/or Jira ID: 
					--SDLAQ-CRS-609

				--Verification criteria: 
					--[[
						6.1 The request with empty "gps" parameter value is sent, the response with INVALID_DATA result code is returned.
						6.2 The request with empty "speed" parameter value is sent, the response with INVALID_DATA result code is returned.
						6.3 The request with empty "rpm" parameter value is sent, the response with INVALID_DATA result code is returned.
						6.4 The request with empty "fuelLevel" parameter value is sent, the response with INVALID_DATA result code is returned. 
						6.5 The request with empty "instantFuelConsumption" parameter value is sent, the response with INVALID_DATA result code is returned.
						6.6 The request with empty "externalTemperature" parameter value is sent, the response with INVALID_DATA result code is returned.
						6.7 The request with empty "prndl" parameter value is sent, the response with INVALID_DATA result code is returned.
						6.8 The request with empty "tirePressure" parameter value is sent, the response with INVALID_DATA result code is returned.
						6.9 The request with empty "odometer" parameter value is sent, the response with INVALID_DATA result code is returned. 
						6.10 The request with empty "beltStatus" parameter value is sent, the response with INVALID_DATA result code is returned. 
						6.11 The request with empty "bodyInformation" parameter value is sent, the response with INVALID_DATA result code is returned.
						6.12 The request with empty "deviceStatus" parameter value is sent, the response with INVALID_DATA result code is returned.
						6.13 The request with empty "driverBraking" parameter value is sent, the response with INVALID_DATA result code is returned.
						6.14 The request with empty "wiperStatus" parameter value is sent, the response with INVALID_DATA result code is returned.
						6.15 The request with empty "headLampStatus" parameter value is sent, the response with INVALID_DATA result code is returned.
						6.16 The request with empty "engineTorque" parameter value is sent, the response with INVALID_DATA result code is returned. 
						6.17 The request with empty "steeringWheelAngle" parameter value is sent, the response with INVALID_DATA result code is returned.
						6.18 The request with empty "eCallInfo" parameter value is sent, the response with INVALID_DATA result code is returned.
						6.19 The request with empty "airbagStatus" parameter value is sent, the response with INVALID_DATA result code is returned.
						6.20 The request with empty "emergencyEvent" parameter value is sent, the response with INVALID_DATA result code is returned.
						6.21 The request with empty "clusterModeStatus" parameter value is sent, the response with INVALID_DATA result code is returned.
						6.22 The request with empty "myKey" parameter value is sent, the response with INVALID_DATA result code is returned.
					--]]
					
				--Covered by INVALID_JSON case
					
			--End Test case NegativeRequestCheck.2
			
			-----------------------------------------------------------------------------------------
			
			--Begin Test case NegativeRequestCheck.3
			--Description: Check processing requests with wrong type of parameters

				--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-609

				--Verification criteria: 
					-- The request with wrong type of parameter value is sent, the response with INVALID_DATA result code is returned.
					for i=1, #allVehicleData do
						Test["GetVehicleData_WrongType_"..allVehicleData[i]] = function(self)
							local temp = {}
							temp[allVehicleData[i]] = 123
							self:getVehicleDataInvalidData(temp)
						end
					end											
			--End Test case NegativeRequestCheck.3

			-----------------------------------------------------------------------------------------
			
			--Begin Test case NegativeRequestCheck.4
			--Description: Check processing request with Special characters

				-- Not applicable
			
			--End Test case NegativeRequestCheck.4
			
			-----------------------------------------------------------------------------------------
			
			--Begin Test case NegativeRequestCheck.5
			--Description: Check processing request with wrong/correct name of parameters and with true/false value
			
				--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-608, SDLAQ-CRS-2287

				--Verification criteria: 
					-- The request with the wrong name parameter (the one that does not exist in the list of valid parameters for GetVehicleData) and with correctly named other parameters is processed by SDL the valid request (such parameter is ignored). The responseCode is "SUCCESS" if there are no other errors. General resultCode is success="true"
					-- Vehicle Data requested in GetVehicleData request with false attribute value receives the response with no data value for this VehicleData parameter. In case of no errors and getting data for other requested vehicle data attributes the response is returned with SUCCES resultCode and success="true".
					
				--Begin Test case NegativeRequestCheck.5.1
				--Description: Check processing request with wrong name parameter
					function Test:GetVehicleData_ParameterWrongName()
						self:getVehicleDataInvalidData({abc = true})
					end		
				--End Test case NegativeRequestCheck.5.1
				
				-----------------------------------------------------------------------------------------
					
				--Begin Test case NegativeRequestCheck.5.2
				--Description: Check processing request with wrong name and valid name parameter
					function Test:GetVehicleData_ParameterWrongAndValidName()
						--mobile side: sending GetVehicleData request
						local cid = self.mobileSession:SendRPC("GetVehicleData",{abc = true, speed = true})
						
						--hmi side: expect GetVehicleData request
						EXPECT_HMICALL("VehicleInfo.GetVehicleData",{speed = true})
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.GetVehicleData response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {speed = 50.5})	
						end)
						:ValidIf(function(_, data)
							if data.params.abc then
								print(" \27[36m SDL re-sends parameters with wrong name to HMI \27[0m")							
								return false
							else
								return true
							end
						end)
						
						--mobile side: expect GetVehicleData response
						EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS", speed = 50.5})
						
						DelayedExp(300)
					end		
				--End Test case NegativeRequestCheck.5.2
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeRequestCheck.5.3
				--Description: Check processing request with wrong value parameter
					for i=1, #allVehicleData do
						Test["GetVehicleData_"..allVehicleData[i].."_false"] = function(self)
							local temp = {}
							temp[allVehicleData[i]] = false
							--mobile side: sending GetVehicleData request
							local cid = self.mobileSession:SendRPC("GetVehicleData",temp)
							
							--hmi side: expect GetVehicleData request
							EXPECT_HMICALL("VehicleInfo.GetVehicleData",temp)
							:Times(0)
							
							--mobile side: expect GetVehicleData response
							EXPECT_RESPONSE(cid, {success = false, resultCode = "INVALID_DATA"})
							
							DelayedExp(300)
						end
					end		
				--End Test case NegativeRequestCheck.5.3
				
				-----------------------------------------------------------------------------------------
					
				--Begin Test case NegativeRequestCheck.5.4
				--Description: Check processing request with wrong value and valid value parameter
					function Test:GetVehicleData_ParameterWrongAndValidValue()
						--mobile side: sending GetVehicleData request
						local cid = self.mobileSession:SendRPC("GetVehicleData",{rpm = false, speed = true})
						
						--hmi side: expect GetVehicleData request
						EXPECT_HMICALL("VehicleInfo.GetVehicleData",{speed = true})
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.GetVehicleData response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {speed = 50.5})	
						end)
						:ValidIf(function(_, data)
							if data.params.rpm then
								print(" \27[36m SDL re-sends parameters with false value to HMI \27[0m")							
								return false
							else
								return true
							end
						end)
						
						--mobile side: expect GetVehicleData response
						EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS", speed = 50.5})
						
						DelayedExp(300)
					end		
				--End Test case NegativeRequestCheck.5.4				
			--End Test case NegativeRequestCheck.5			
		--End Test suit NegativeRequestCheck

	--=================================================================================--
	---------------------------------Negative response check-----------------------------
	--=================================================================================--

		--------Checks-----------
		-- outbound values
		-- invalid values(empty, missing, nonexistent, invalid characters)
		-- parameters with wrong type
		-- invalid json
		
		--Begin Test suit NegativeResponseCheck
		--Description: Check of each response parameter value out of bound, missing, with wrong type, empty, duplicate etc.
--[[TODO: Check after APPLINK-14765 is resolved
			--Begin Test case NegativeResponseCheck.1
			--Description: Check processing response with outbound values

				--Requirement id in JAMA:
					--SDLAQ-CRS-98
					
				--Verification criteria:
					-- The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode. The appropriate parameters sent in the request are returned with the data about subscription.

				--Begin Test case NegativeResponseCheck.1.1
				--Description: Check response with nonexistent resultCode 
					function Test:GetVehicleData_ResponseResultCodeNotExist()
						--mobile side: sending GetVehicleData request
						local cid = self.mobileSession:SendRPC("GetVehicleData",
																					{
																						speed = true
																					})
						
						--hmi side: expect GetVehicleData request
						EXPECT_HMICALL("VehicleInfo.GetVehicleData",{speed = true})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.GetVehicleData response
							self.hmiConnection:SendResponse(data.id, data.method, "ANY", {speed = 55.5})	
						end)
						
						--mobile side: expect GetVehicleData response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})		
					end
				--End Test case NegativeResponseCheck.1.1
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.1.2
				--Description: Check response with nonexistent VehicleData parameter 
					function Test:GetVehicleData_ResponseVehicleDataNotExist()
						--mobile side: sending GetVehicleData request
						local cid = self.mobileSession:SendRPC("GetVehicleData",
																					{
																						speed = true
																					})
						
						--hmi side: expect GetVehicleData request
						EXPECT_HMICALL("VehicleInfo.GetVehicleData",{speed = true})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.GetVehicleData response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {abc = 55.5})	
						end)
						
						--mobile side: expect GetVehicleData response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
					end
				--End Test case NegativeResponseCheck.1.2				
			--End Test case NegativeResponseCheck.1
			-----------------------------------------------------------------------------------------
			
			--Begin Test case NegativeResponseCheck.2
			--Description: Check processing responses with invalid values (empty, missing, nonexistent, invalid characters)

				--Requirement id in JAMA:
					--SDLAQ-CRS-98
					
					
				--Verification criteria:
					-- The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode. The appropriate parameters sent in the request are returned with the data about subscription.

				--Begin NegativeResponseCheck.2.1
				--Description: Check response with empty method
					function Test:GetVehicleData_ResponseEmptyMethod()					
						--mobile side: sending GetVehicleData request
						local cid = self.mobileSession:SendRPC("GetVehicleData",
																					{
																						speed = true
																					})
						
						--hmi side: expect GetVehicleData request
						EXPECT_HMICALL("VehicleInfo.GetVehicleData",{speed = true})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.GetVehicleData response
							self.hmiConnection:SendResponse(data.id, "", "SUCCESS", {speed = 55.5})	
						end)
						
						--mobile side: expect GetVehicleData response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})			
					end
				--End NegativeResponseCheck.2.1
				
				-----------------------------------------------------------------------------------------
				
				--Begin NegativeResponseCheck.2.2
				--Description: Check response with empty resultCode
					function Test:GetVehicleData_ResponseEmptyResultCode()					
						--mobile side: sending GetVehicleData request
						local cid = self.mobileSession:SendRPC("GetVehicleData",
																					{
																						speed = true
																					})
						
						--hmi side: expect GetVehicleData request
						EXPECT_HMICALL("VehicleInfo.GetVehicleData",{speed = true})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.GetVehicleData response
							self.hmiConnection:SendResponse(data.id, data.method, "", {speed = 55.5})	
						end)
						
						--mobile side: expect GetVehicleData response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})			
					end
				--End NegativeResponseCheck.2.2	
								
				-----------------------------------------------------------------------------------------
				
				--Begin NegativeResponseCheck.2.3
				--Description: Check response missing all parameter
					function Test:GetVehicleData_ResponseMissingAllParams()					
						--mobile side: sending GetVehicleData request
						local cid = self.mobileSession:SendRPC("GetVehicleData",
																					{
																						speed = true
																					})
						
						--hmi side: expect GetVehicleData request
						EXPECT_HMICALL("VehicleInfo.GetVehicleData",{speed = true})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.GetVehicleData response
							self.hmiConnection:Send({})
						end)
						
						--mobile side: expect GetVehicleData response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})			
					end
				--End NegativeResponseCheck.2.3
				
				-----------------------------------------------------------------------------------------
				
				--Begin NegativeResponseCheck.2.4
				--Description: Check response without method
					function Test:GetVehicleData_ResponseMissingMethod()					
						--mobile side: sending GetVehicleData request
						local cid = self.mobileSession:SendRPC("GetVehicleData",
																					{
																						speed = true
																					})
						
						--hmi side: expect GetVehicleData request
						EXPECT_HMICALL("VehicleInfo.GetVehicleData",{speed = true})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.GetVehicleData response
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"code":0,"speed":55.5}')							
						end)
						
						--mobile side: expect GetVehicleData response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})			
					end
				--End NegativeResponseCheck.2.4
				
				-----------------------------------------------------------------------------------------
				
				--Begin NegativeResponseCheck.2.5
				--Description: Check response without resultCode
					function Test:GetVehicleData_ResponseMissingResultCode()					
						--mobile side: sending GetVehicleData request
						local cid = self.mobileSession:SendRPC("GetVehicleData",
																					{
																						speed = true
																					})
						
						--hmi side: expect GetVehicleData request
						EXPECT_HMICALL("VehicleInfo.GetVehicleData",{speed = true})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.GetVehicleData response
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"speed":55.5,"method":"VehicleInfo.GetVehicleData"}}')
						end)
						
						--mobile side: expect GetVehicleData response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})			
					end
				--End NegativeResponseCheck.2.5
				
				-----------------------------------------------------------------------------------------
				
				--Begin NegativeResponseCheck.2.6
				--Description: Check response without vehicleData
					function Test:GetVehicleData_ResponseMissingVehicleDataResultCode()					
						--mobile side: sending GetVehicleData request
						local cid = self.mobileSession:SendRPC("GetVehicleData",
																					{
																						speed = true
																					})
						
						--hmi side: expect GetVehicleData request
						EXPECT_HMICALL("VehicleInfo.GetVehicleData",{speed = true})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.GetVehicleData response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
						
						--mobile side: expect GetVehicleData response
						EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS"})
						:ValidIf(function(_, data)
							if data.payload.speed then
								print(" \27[36m SDL re-sends parameters even though HMI not response this parameter \27[0m")							
								return false
							else
								return true
							end
						end)
					end
				--End NegativeResponseCheck.2.6
				
				-----------------------------------------------------------------------------------------
				
				--Begin NegativeResponseCheck.2.7
				--Description: Check response without mandatory parameter
					function Test:GetVehicleData_ResponseMissingMandatory()					
						--mobile side: sending GetVehicleData request
						local cid = self.mobileSession:SendRPC("GetVehicleData",
																					{
																						speed = true
																					})
						
						--hmi side: expect GetVehicleData request
						EXPECT_HMICALL("VehicleInfo.GetVehicleData",{speed = true})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.GetVehicleData response
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{info = "abc"}}')
						end)
						
						--mobile side: expect GetVehicleData response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})			
					end
				--End NegativeResponseCheck.2.7
			--End Test case NegativeResponseCheck.2

			-----------------------------------------------------------------------------------------
			
			--Begin Test case NegativeResponseCheck.3
			--Description: Check processing response with parameters with wrong data type 

				--Requirement id in JAMA:
					--SDLAQ-CRS-98					
					
				--Verification criteria:
					-- The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode. The appropriate parameters sent in the request are returned with the data about subscription.

				--Begin Test case NegativeResponseCheck.3.1
				--Description: Check response with wrong type of method
					function Test:GetVehicleData_ResponseWrongTypeMethod() 
						--mobile side: sending GetVehicleData request
						local cid = self.mobileSession:SendRPC("GetVehicleData",
																					{
																						speed = true
																					})
						
						--hmi side: expect GetVehicleData request
						EXPECT_HMICALL("VehicleInfo.GetVehicleData",{speed = true})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.GetVehicleData response
							self.hmiConnection:SendResponse(data.id, 1234, "SUCCESS", {speed = 55.5})	
						end)
						
						--mobile side: expect GetVehicleData response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
					end				
				--End Test case NegativeResponseCheck.3.1
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.3.2
				--Description: Check response with wrong type of resultCode
					function Test:GetVehicleData_ResponseWrongTypeResultCode() 
						--mobile side: sending GetVehicleData request
						local cid = self.mobileSession:SendRPC("GetVehicleData",
																					{
																						speed = true
																					})
						
						--hmi side: expect GetVehicleData request
						EXPECT_HMICALL("VehicleInfo.GetVehicleData",{speed = true})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.GetVehicleData response
							self.hmiConnection:SendResponse(data.id, data.method, 123, {speed = 55.5})	
						end)
						
						--mobile side: expect GetVehicleData response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
					end				
				--End Test case NegativeResponseCheck.3.2							
			--End Test case NegativeResponseCheck.3

			-----------------------------------------------------------------------------------------
			
			--Begin Test case NegativeResponseCheck.4
			--Description: Invalid JSON

				--Requirement id in JAMA:
					--SDLAQ-CRS-98
					
				--Verification criteria:
					-- The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode. The appropriate parameters sent in the request are returned with the data about subscription.
	
					function Test:GetVehicleData_ResponseInvalidJson()	
						--mobile side: sending GetVehicleData request
						local cid = self.mobileSession:SendRPC("GetVehicleData",
																		{
																			speed = true
																		})
						
						--hmi side: expect GetVehicleData request
						EXPECT_HMICALL("VehicleInfo.GetVehicleData",{speed = true})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.GetVehicleData response
							--<<!-- missing ':'
							self.hmiConnection:Send('{"id" '..tostring(data.id)..',"jsonrpc":"2.0","result":{"code":0,"speed" true,"method":"VehicleInfo.GetVehicleData"}}')
						end)
						
						--mobile side: expect GetVehicleData response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})						
					end								
			--End Test case NegativeResponseCheck.4
--]]			
			-----------------------------------------------------------------------------------------
			
			--Begin Test case NegativeResponseCheck.5
			--Description: SDL behaviour: cases when SDL must transfer "info" parameter via corresponding RPC to mobile app

				--Requirement id in JAMA/or Jira ID: 
					--SDLAQ-CRS-98
					--APPLINK-13276
					--APPLINK-14551
					
				--Description:
					-- In case "message" is empty - SDL should not transfer it as "info" to the app ("info" needs to be omitted)
					-- In case info out of upper bound it should truncate to 1000 symbols
					-- SDL should not send "info" to app if received "message" is invalid
					-- SDL should not send "info" to app if received "message" contains newline "\n" or tab "\t" symbols.
					
				--Begin Test Case NegativeResponseCheck.5.1
				--Description: Check response with empty info
					function Test:GetVehicleData_ResponseInfoOutLowerBound()	
						--mobile side: sending GetVehicleData request
						local cid = self.mobileSession:SendRPC("GetVehicleData",
																					{
																						speed = true
																					})
						
						--hmi side: expect GetVehicleData request
						EXPECT_HMICALL("VehicleInfo.GetVehicleData",{speed = true})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.GetVehicleData response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {message = "", speed = 55.5})	
						end)
						
						--mobile side: expect GetVehicleData response
						EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS", speed = 55.5})
						:ValidIf (function(_,data)
							if data.payload.info then
								print(" \27[36m SDL resend invalid info to mobile app \27[0m")
								return false
							else 
								return true
							end
						end)
						
						DelayedExp(300)
					end
				--End Test Case NegativeResponseCheck.5.1
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test Case NegativeResponseCheck.5.2
				--Description: Check response with info out upper bound
					function Test:GetVehicleData_ResponseInfoOutUpperBound()	
						--mobile side: sending GetVehicleData request
						local cid = self.mobileSession:SendRPC("GetVehicleData",
																					{
																						speed = true
																					})
						
						--hmi side: expect GetVehicleData request
						EXPECT_HMICALL("VehicleInfo.GetVehicleData",{speed = true})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.GetVehicleData response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {message = infoMessageValue.."a",speed = 55.5})	
						end)
						
						--mobile side: expect GetVehicleData response
						EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS", speed = 55.5, info = infoMessageValue})						
						
						DelayedExp(300)
					end
				--End Test Case NegativeResponseCheck.5.2
						
				-----------------------------------------------------------------------------------------
					
				--Begin Test Case NegativeResponseCheck.5.3
				--Description: Check response with wrong type info
					function Test:GetVehicleData_ResponseInfoWrongType()	
						--mobile side: sending GetVehicleData request
						local cid = self.mobileSession:SendRPC("GetVehicleData",
																					{
																						speed = true
																					})
						
						--hmi side: expect GetVehicleData request
						EXPECT_HMICALL("VehicleInfo.GetVehicleData",{speed = true})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.GetVehicleData response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {message = 1234, speed = 55.5})	
						end)
						
						--mobile side: expect GetVehicleData response
						EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS", speed = 55.5})
						:ValidIf (function(_,data)
							if data.payload.info then
								print(" \27[36m SDL resend invalid info to mobile app \27[0m")
								return false
							else 
								return true
							end
						end)
						
						DelayedExp(300)
					end
				--End Test Case NegativeResponseCheck.5.3
								
				-----------------------------------------------------------------------------------------
					
				--Begin Test Case NegativeResponseCheck.5.4
				--Description: Check response with info have escape sequence \n 
					function Test:GetVehicleData_ResponseInfoNewLineChar()	
						--mobile side: sending GetVehicleData request
						local cid = self.mobileSession:SendRPC("GetVehicleData",
																					{
																						speed = true
																					})
						
						--hmi side: expect GetVehicleData request
						EXPECT_HMICALL("VehicleInfo.GetVehicleData",{speed = true})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.GetVehicleData response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {message = "New line \n", speed = 55.5})	
						end)
						
						--mobile side: expect GetVehicleData response
						EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS", speed = 55.5})
						:ValidIf (function(_,data)
							if data.payload.info then
								print(" \27[36m SDL resend invalid info to mobile app \27[0m")
								return false
							else 
								return true
							end
						end)
						
						DelayedExp(300)						
					end
				--End Test Case NegativeResponseCheck.5.4
								
				-----------------------------------------------------------------------------------------
					
				--Begin Test Case NegativeResponseCheck.5.5
				--Description: Check response with info have escape sequence \t
					function Test:GetVehicleData_ResponseInfoNewTabChar()	
						--mobile side: sending GetVehicleData request
						local cid = self.mobileSession:SendRPC("GetVehicleData",
																					{
																						speed = true
																					})
						
						--hmi side: expect GetVehicleData request
						EXPECT_HMICALL("VehicleInfo.GetVehicleData",{speed = true})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.GetVehicleData response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {message = "New tab \t", speed = 55.5})	
						end)
						
						--mobile side: expect GetVehicleData response
						EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS", speed = 55.5})
						:ValidIf (function(_,data)
							if data.payload.info then
								print(" \27[36m SDL resend invalid info to mobile app \27[0m")
								return false
							else 
								return true
							end
						end)
						
						DelayedExp(300)
					end
				--End Test Case NegativeResponseCheck.5.5									
			--End Test case NegativeResponseCheck.5
			
			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeResponseCheck.6
			--Description: Check processing response with parameters have empty value

				--Requirement id in JAMA:
					--SDLAQ-CRS-98
					
				--Verification criteria:
					-- The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode. The appropriate parameters sent in the request are returned with the data about subscription.
				
				--Begin Test Case NegativeResponseCheck6.1
				--Description: Check response with gps empty
					function Test:GetVehicleData_GpsEmpty()						
						local response = setGVDResponse({"gps"})						
						response["gps"] = {}
					--TODO: update after resolving APPLINK-15241
						-- self:getVehicleData_ResponseInvalidData(response)
						self:getVehicleData_ResponseSuccess(response)
					end
				--End Test Case NegativeResponseCheck6.1
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test Case NegativeResponseCheck6.2
				--Description: Check response with compassDirection empty
					function Test:GetVehicleData_compassDirectionEmpty()						
						local response = setGVDResponse({"gps"})						
						response.gps["compassDirection"] = ""
						self:getVehicleData_ResponseInvalidData(response)
					end
				--End Test Case NegativeResponseCheck6.2
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test Case NegativeResponseCheck6.3
				--Description: Check response with dimension empty
					function Test:GetVehicleData_dimensionEmpty()						
						local response = setGVDResponse({"gps"})						
						response.gps["dimension"] = ""
						self:getVehicleData_ResponseInvalidData(response)
					end
				--End Test Case NegativeResponseCheck6.3
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test Case NegativeResponseCheck6.4
				--Description: Check response with fuelLevel_State empty
					function Test:GetVehicleData_fuelLevel_StateEmpty()						
						local response = setGVDResponse({"fuelLevel_State"})						
						response["fuelLevel_State"] = ""
						self:getVehicleData_ResponseInvalidData(response)
					end
				--End Test Case NegativeResponseCheck6.4
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test Case NegativeResponseCheck6.5
				--Description: Check response with vin empty
					function Test:GetVehicleData_vinEmpty()						
						local response = setGVDResponse({"vin"})						
						response["vin"] = ""
						self:getVehicleData_ResponseInvalidData(response)
					end
				--End Test Case NegativeResponseCheck6.5
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test Case NegativeResponseCheck6.6
				--Description: Check response with prndl empty
					function Test:GetVehicleData_prndlEmpty()						
						local response = setGVDResponse({"prndl"})						
						response["prndl"] = ""
						self:getVehicleData_ResponseInvalidData(response)
					end
				--End Test Case NegativeResponseCheck6.6
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test Case NegativeResponseCheck6.7
				--Description: Check response with tirePressure empty
					function Test:GetVehicleData_tirePressureEmpty()						
						local response = setGVDResponse({"tirePressure"})						
						response["tirePressure"] = {}
						self:getVehicleData_ResponseSuccess(response)
					end
				--End Test Case NegativeResponseCheck6.7
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test Case NegativeResponseCheck6.8
				--Description: Check response with pressureTelltale empty
					function Test:GetVehicleData_pressureTelltaleEmpty()						
						local response = setGVDResponse({"tirePressure"})						
						response.tirePressure["pressureTelltale"] = ""
						self:getVehicleData_ResponseInvalidData(response)
					end
				--End Test Case NegativeResponseCheck6.8
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test Case NegativeResponseCheck6.9
				--Description: Check response with parameters in tirePressure structure empty
					local tirePressureParams ={"leftFront", "rightFront", "leftRear", "rightRear", "innerLeftRear", "innerRightRear"}
					for i=1, #tirePressureParams do
						Test["GetVehicleData_"..tirePressureParams[i].."Empty"] = function(self)
							local response = setGVDResponse({"tirePressure"})						
							response.tirePressure[tirePressureParams[i]] = {}
							self:getVehicleData_ResponseInvalidData(response)
						end
					end
				--End Test Case NegativeResponseCheck6.9
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test Case NegativeResponseCheck6.10
				--Description: Check response with status of parameters in tirePressure structure empty					
					for i=1, #tirePressureParams do
						Test["GetVehicleData_"..tirePressureParams[i].."StatusEmpty"] = function(self)
							local response = {tirePressure = {}}
							response.tirePressure[tirePressureParams[i]] = {status = ""}
							self:getVehicleData_ResponseInvalidData(response)
						end
					end
				--End Test Case NegativeResponseCheck6.10
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test Case NegativeResponseCheck6.11
				--Description: Check response with beltStatus empty					
					function Test:GetVehicleData_beltStatusEmpty()						
						local response = setGVDResponse({"beltStatus"})						
						response["beltStatus"] = {}
						self:getVehicleData_ResponseSuccess(response)
					end
				--End Test Case NegativeResponseCheck6.11
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test Case NegativeResponseCheck6.12
				--Description: Check response with parameters in beltStatus structure empty									
					for i=1, #beltStatusParams do
						Test["GetVehicleData_"..beltStatusParams[i].."Empty"] = function(self)
							local response = setGVDResponse({"beltStatus"})			
							response.beltStatus[beltStatusParams[i]] = ""
							self:getVehicleData_ResponseInvalidData(response)
						end
					end
				--End Test Case NegativeResponseCheck6.12
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test Case NegativeResponseCheck6.13
				--Description: Check response with bodyInformation empty											
					function Test:GetVehicleData_bodyInformationEmpty()						
						local response = setGVDResponse({"bodyInformation"})						
						response["bodyInformation"] = {}
						self:getVehicleData_ResponseInvalidData(response)
					end
				--End Test Case NegativeResponseCheck6.13
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test Case NegativeResponseCheck6.14
				--Description: Check response with ignitionStableStatus empty											
					function Test:GetVehicleData_ignitionStableStatusEmpty()						
						local response = setGVDResponse({"bodyInformation"})						
						response.bodyInformation["ignitionStableStatus"] = ""
						self:getVehicleData_ResponseInvalidData(response)
					end
				--End Test Case NegativeResponseCheck6.14
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test Case NegativeResponseCheck6.15
				--Description: Check response with ignitionStatus empty											
					function Test:GetVehicleData_ignitionStatusEmpty()						
						local response = setGVDResponse({"bodyInformation"})						
						response.bodyInformation["ignitionStatus"] = ""
						self:getVehicleData_ResponseInvalidData(response)
					end
				--End Test Case NegativeResponseCheck6.15
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test Case NegativeResponseCheck6.16
				--Description: Check response with deviceStatus empty											
					function Test:GetVehicleData_deviceStatusEmpty()						
						local response = setGVDResponse({"deviceStatus"})						
						response["deviceStatus"] = {}
						self:getVehicleData_ResponseSuccess(response)
					end
				--End Test Case NegativeResponseCheck6.16
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test Case NegativeResponseCheck6.17
				--Description: Check response with battLevelStatus empty											
					function Test:GetVehicleData_battLevelStatusEmpty()						
						local response = setGVDResponse({"deviceStatus"})						
						response.deviceStatus["battLevelStatus"] = ""
						self:getVehicleData_ResponseInvalidData(response)
					end
				--End Test Case NegativeResponseCheck6.17
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test Case NegativeResponseCheck6.18
				--Description: Check response with signalLevelStatus empty											
					function Test:GetVehicleData_signalLevelStatusEmpty()						
						local response = setGVDResponse({"deviceStatus"})						
						response.deviceStatus["signalLevelStatus"] = ""
						self:getVehicleData_ResponseInvalidData(response)
					end
				--End Test Case NegativeResponseCheck6.18
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test Case NegativeResponseCheck6.19
				--Description: Check response with primaryAudioSource empty											
					function Test:GetVehicleData_primaryAudioSourceEmpty()						
						local response = setGVDResponse({"deviceStatus"})						
						response.deviceStatus["primaryAudioSource"] = ""
						self:getVehicleData_ResponseInvalidData(response)
					end
				--End Test Case NegativeResponseCheck6.19
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test Case NegativeResponseCheck6.20
				--Description: Check response with driverBraking empty											
					function Test:GetVehicleData_driverBrakingEmpty()						
						local response = setGVDResponse({"driverBraking"})						
						response["driverBraking"] = ""
						self:getVehicleData_ResponseInvalidData(response)
					end
				--End Test Case NegativeResponseCheck6.20
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test Case NegativeResponseCheck6.21
				--Description: Check response with wiperStatus empty											
					function Test:GetVehicleData_wiperStatusEmpty()						
						local response = setGVDResponse({"wiperStatus"})						
						response["wiperStatus"] = ""
						self:getVehicleData_ResponseInvalidData(response)
					end
				--End Test Case NegativeResponseCheck6.21
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test Case NegativeResponseCheck6.22
				--Description: Check response with headLampStatus empty											
					function Test:GetVehicleData_headLampStatusEmpty()						
						local response = setGVDResponse({"headLampStatus"})						
						response["headLampStatus"] = {}
						self:getVehicleData_ResponseInvalidData(response)
					end
				--End Test Case NegativeResponseCheck6.22
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test Case NegativeResponseCheck6.23
				--Description: Check response with ambientLightSensorStatus empty											
					function Test:GetVehicleData_ambientLightSensorStatusEmpty()						
						local response = setGVDResponse({"headLampStatus"})						
						response.headLampStatus["ambientLightSensorStatus"] = ""
						self:getVehicleData_ResponseInvalidData(response)
					end
				--End Test Case NegativeResponseCheck6.23
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test Case NegativeResponseCheck6.24
				--Description: Check response with eCallInfo empty											
					function Test:GetVehicleData_eCallInfoEmpty()						
						local response = setGVDResponse({"eCallInfo"})						
						response["eCallInfo"] = {}
						self:getVehicleData_ResponseInvalidData(response)
					end
				--End Test Case NegativeResponseCheck6.24
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test Case NegativeResponseCheck6.25
				--Description: Check response with parameters in beltStatus structure empty									
					local eCallInfoParams = {"eCallNotificationStatus", "auxECallNotificationStatus", "eCallConfirmationStatus"}
					for i=1, #eCallInfoParams do
						Test["GetVehicleData_"..eCallInfoParams[i].."Empty"] = function(self)
							local response = setGVDResponse({"eCallInfo"})						
							response.eCallInfo[eCallInfoParams[i]] = ""
							self:getVehicleData_ResponseInvalidData(response)
						end
					end
				--End Test Case NegativeResponseCheck6.26
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test Case NegativeResponseCheck6.27
				--Description: Check response with airbagStatus empty											
					function Test:GetVehicleData_airbagStatusEmpty()						
						local response = setGVDResponse({"airbagStatus"})						
						response["airbagStatus"] = {}
						self:getVehicleData_ResponseInvalidData(response)
					end
				--End Test Case NegativeResponseCheck6.27
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test Case NegativeResponseCheck6.28
				--Description: Check response with parameters in airbagStatus structure empty														
					for i=1, #airbagStatusParams do
						Test["GetVehicleData_"..airbagStatusParams[i].."Empty"] = function(self)
							local response = setGVDResponse({"airbagStatus"})						
							response.airbagStatus[airbagStatusParams[i]] = ""
							self:getVehicleData_ResponseInvalidData(response)
						end
					end
				--End Test Case NegativeResponseCheck6.28
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test Case NegativeResponseCheck6.29
				--Description: Check response with emergencyEvent empty											
					function Test:GetVehicleData_emergencyEventEmpty()						
						local response = setGVDResponse({"emergencyEvent"})						
						response["emergencyEvent"] = {}
						self:getVehicleData_ResponseInvalidData(response)
					end
				--End Test Case NegativeResponseCheck6.29
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test Case NegativeResponseCheck6.30
				--Description: Check response with parameters in airbagStatus structure empty
					local emergencyEventParams = {"emergencyEventType", "fuelCutoffStatus", "rolloverEvent", "multipleEvents"}
					for i=1, #emergencyEventParams do
						Test["GetVehicleData_"..emergencyEventParams[i].."Empty"] = function(self)
							local response = setGVDResponse({"emergencyEvent"})						
							response.emergencyEvent[emergencyEventParams[i]] = ""
							self:getVehicleData_ResponseInvalidData(response)
						end
					end
				--End Test Case NegativeResponseCheck6.30
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test Case NegativeResponseCheck6.31
				--Description: Check response with clusterModeStatus empty											
					function Test:GetVehicleData_clusterModeStatusEmpty()						
						local response = setGVDResponse({"clusterModeStatus"})						
						response["clusterModeStatus"] = {}
						self:getVehicleData_ResponseInvalidData(response)
					end
				--End Test Case NegativeResponseCheck6.31
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test Case NegativeResponseCheck6.32
				--Description: Check response with parameters in airbagStatus structure empty
					local clusterModeStatusParams = {"powerModeQualificationStatus", "carModeStatus", "powerModeStatus"}
					for i=1, #clusterModeStatusParams do
						Test["GetVehicleData_"..clusterModeStatusParams[i].."Empty"] = function(self)
							local response = setGVDResponse({"clusterModeStatus"})						
							response.clusterModeStatus[clusterModeStatusParams[i]] = ""
							self:getVehicleData_ResponseInvalidData(response)
						end
					end
				--End Test Case NegativeResponseCheck6.32
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test Case NegativeResponseCheck6.33
				--Description: Check response with myKey empty											
					function Test:GetVehicleData_myKeyEmpty()						
						local response = setGVDResponse({"myKey"})						
						response["myKey"] = {}
						self:getVehicleData_ResponseInvalidData(response)
					end
				--End Test Case NegativeResponseCheck6.33
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test Case NegativeResponseCheck6.34
				--Description: Check response with e911Override empty											
					function Test:GetVehicleData_e911OverrideEmpty()						
						local response = setGVDResponse({"myKey"})						
						response.myKey["e911Override"] = ""
						self:getVehicleData_ResponseInvalidData(response)
					end
				--End Test Case NegativeResponseCheck6.34				
			--End Test case NegativeResponseCheck.6
			
			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeResponseCheck.7
			--Description: Check processing response with parameters missing

				--Requirement id in JAMA:
					--SDLAQ-CRS-98
					
				--Verification criteria:
					-- The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode. The appropriate parameters sent in the request are returned with the data about subscription.
				
				--Begin Test Case NegativeResponseCheck.7.1
				--Description: Check response with parameters in gps structure missing
					local gpsParams = {"longitudeDegrees","latitudeDegrees","utcYear","utcMonth","utcDay","utcHours","utcMinutes","utcSeconds","compassDirection","pdop","hdop","vdop","actual","satellites","dimension","altitude","heading","speed"}
					for i=1, #gpsParams do
					--TODO: update after resolving APPLINK-15241 
						-- if gpsParams[i] == "longitudeDegrees" or gpsParams[i] == "latitudeDegrees" then
						-- 	Test["GetVehicleData_"..gpsParams[i].."Missing"] = function(self)
						-- 		local response = setGVDResponse({"gps"})						
						-- 		response.gps[gpsParams[i]] = nil
						-- 		self:getVehicleData_ResponseInvalidData(response)								
						-- 	end
						-- else
							Test["GetVehicleData_"..gpsParams[i].."Missing"] = function(self)
								local response = setGVDResponse({"gps"})						
								response.gps[gpsParams[i]] = nil
								self:getVehicleData_ResponseSuccess(response)								
							-- end
						end
					end
				--End Test Case NegativeResponseCheck.7.1
				
				-----------------------------------------------------------------------------------------

				--Begin Test Case NegativeResponseCheck.7.2
				--Description: Check response with parameters in tirePressure structure missing
					local tirePressureParams = {"pressureTelltale", "leftFront", "rightFront", "leftRear", "rightRear", "innerLeftRear", "innerRightRear"}
					for i=1, #tirePressureParams do						
						Test["GetVehicleData_"..tirePressureParams[i].."Missing"] = function(self)
							local response = setGVDResponse({"tirePressure"})						
							response.tirePressure[tirePressureParams[i]] = nil
							self:getVehicleData_ResponseSuccess(response)							
						end						
					end
				--End Test Case NegativeResponseCheck.7.2
				
				-----------------------------------------------------------------------------------------

				--Begin Test Case NegativeResponseCheck.7.3
				--Description: Check response with parameters in beltStatus structure missing					
					for i=1, #beltStatusParams do						
						Test["GetVehicleData_"..beltStatusParams[i].."Missing"] = function(self)
							local response = setGVDResponse({"beltStatus"})						
							response.beltStatus[beltStatusParams[i]] = nil
							self:getVehicleData_ResponseSuccess(response)							
						end						
					end
				--End Test Case NegativeResponseCheck.7.3
				
				-----------------------------------------------------------------------------------------

				--Begin Test Case NegativeResponseCheck.7.4
				--Description: Check response with parameters in bodyInformation structure missing
					local bodyInformationParams = {"parkBrakeActive", "ignitionStableStatus", "ignitionStatus", "driverDoorAjar", "passengerDoorAjar", "rearLeftDoorAjar", "rearRightDoorAjar"}
					for i=1, #bodyInformationParams do						
						if i<4 then
							Test["GetVehicleData_"..bodyInformationParams[i].."Missing"] = function(self)
								local response = setGVDResponse({"bodyInformation"})						
								response.bodyInformation[bodyInformationParams[i]] = nil								
								self:getVehicleData_ResponseInvalidData(response)								
							end			
						else
							Test["GetVehicleData_"..bodyInformationParams[i].."Missing"] = function(self)
								local response = setGVDResponse({"bodyInformation"})						
								response.bodyInformation[bodyInformationParams[i]] = nil
								self:getVehicleData_ResponseSuccess(response)								
							end
						end		
					end
				--End Test Case NegativeResponseCheck.7.4
				
				-----------------------------------------------------------------------------------------

				--Begin Test Case NegativeResponseCheck.7.5
				--Description: Check response with parameters in deviceStatus structure missing
					local deviceStatusParams = {"voiceRecOn", "btIconOn", "callActive", "phoneRoaming", "textMsgAvailable", "battLevelStatus", "stereoAudioOutputMuted", "monoAudioOutputMuted", "signalLevelStatus", "primaryAudioSource", "eCallEventActive"}
					for i=1, #deviceStatusParams do						
						Test["GetVehicleData_"..deviceStatusParams[i].."Missing"] = function(self)
							local response = setGVDResponse({"deviceStatus"})						
							response.deviceStatus[deviceStatusParams[i]] = nil
							self:getVehicleData_ResponseSuccess(response)
						end						
					end
				--End Test Case NegativeResponseCheck.7.5
				
				-----------------------------------------------------------------------------------------

				--Begin Test Case NegativeResponseCheck.7.6
				--Description: Check response with parameters in headLampStatus structure missing
					local headLampStatusParams = {"lowBeamsOn", "highBeamsOn", "ambientLightSensorStatus"}
					for i=1, #headLampStatusParams do						
						Test["GetVehicleData_"..headLampStatusParams[i].."Missing"] = function(self)
							local response = setGVDResponse({"headLampStatus"})						
							response.headLampStatus[headLampStatusParams[i]] = nil
							self:getVehicleData_ResponseInvalidData(response)
						end
					end
				--End Test Case NegativeResponseCheck.7.6
				
				-----------------------------------------------------------------------------------------

				--Begin Test Case NegativeResponseCheck.7.7
				--Description: Check response with parameters in eCallInfo structure missing					
					for i=1, #eCallInfoParams do						
						Test["GetVehicleData_"..eCallInfoParams[i].."Missing"] = function(self)
							local response = setGVDResponse({"eCallInfo"})						
							response.eCallInfo[eCallInfoParams[i]] = nil
							self:getVehicleData_ResponseInvalidData(response)
						end						
					end
				--End Test Case NegativeResponseCheck.7.7
				
				-----------------------------------------------------------------------------------------

				--Begin Test Case NegativeResponseCheck.7.8
				--Description: Check response with parameters in airbagStatus structure missing
					for i=1, #airbagStatusParams do						
						Test["GetVehicleData_"..airbagStatusParams[i].."Missing"] = function(self)
							local response = setGVDResponse({"airbagStatus"})						
							response.airbagStatus[airbagStatusParams[i]] = nil
							self:getVehicleData_ResponseInvalidData(response)
						end						
					end
				--End Test Case NegativeResponseCheck.7.8
				
				-----------------------------------------------------------------------------------------

				--Begin Test Case NegativeResponseCheck.7.9
				--Description: Check response with parameters in emergencyEvent structure missing					
					local emergencyEventParams = {"emergencyEventType", "fuelCutoffStatus", "rolloverEvent", "maximumChangeVelocity", "multipleEvents"}
					for i=1, #emergencyEventParams do						
						Test["GetVehicleData_"..emergencyEventParams[i].."Missing"] = function(self)
							local response = setGVDResponse({"emergencyEvent"})						
							response.emergencyEvent[emergencyEventParams[i]] = nil
							self:getVehicleData_ResponseInvalidData(response)
						end						
					end
				--End Test Case NegativeResponseCheck.7.9
				
				-----------------------------------------------------------------------------------------

				--Begin Test Case NegativeResponseCheck.7.10
				--Description: Check response with parameters in clusterModeStatus structure missing	
					local clusterModeStatusParams = {"powerModeActive", "powerModeQualificationStatus", "carModeStatus", "powerModeStatus"}
					for i=1, #clusterModeStatusParams do						
						Test["GetVehicleData_"..clusterModeStatusParams[i].."Missing"] = function(self)
							local response = setGVDResponse({"clusterModeStatus"})						
							response.clusterModeStatus[clusterModeStatusParams[i]] = nil
							self:getVehicleData_ResponseInvalidData(response)
						end						
					end
				--End Test Case NegativeResponseCheck.7.10
				
				-----------------------------------------------------------------------------------------

				--Begin Test Case NegativeResponseCheck.7.11
				--Description: Check response with parameters in myKey structure missing	
					function Test:GetVehicleData_e911OverrideMissing()						
						local response = setGVDResponse({"myKey"})						
						response.myKey["e911Override"] = nil
						self:getVehicleData_ResponseInvalidData(response)
					end
				--End Test Case NegativeResponseCheck.7.11			
			--End Test case NegativeResponseCheck.7
			
			-----------------------------------------------------------------------------------------
			
			--Begin Test case NegativeResponseCheck.8
			--Description: Check processing response with wrong type of parameters

				--Requirement id in JAMA:
					--SDLAQ-CRS-98
					
				--Verification criteria:
					-- The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode. The appropriate parameters sent in the request are returned with the data about subscription.
				
				--Begin Test Case NegativeResponseCheck.8.1
				--Description: Check response with parameters in gps structure WrongType
					local gpsParams = {
										{param = "longitudeDegrees", value = "25"},
										{param = "latitudeDegrees", value = "45"},
										{param = "utcYear", value = 2015.5},
										{param = "utcMonth", value = 10.5},
										{param = "utcDay", value = 10.5},
										{param = "utcHours", value = 10.5},
										{param = "utcMinutes", value = 10.5},
										{param = "utcSeconds", value = 10.5},
										{param = "compassDirection", value = 1234},
										{param = "pdop", value = "5"},
										{param = "hdop", value = "5"},
										{param = "vdop", value = "5"},
										{param = "actual", value = 123},
										{param = "satellites", value = 10.5},
										{param = "dimension", value = 1234},
										{param = "altitude", value = "10"},
										{param = "heading", value = "100"},
										{param = "speed", value = "250" }}
					for i=1, #gpsParams do						
						Test["GetVehicleData_"..gpsParams[i].param.."WrongType"] = function(self)
							local response = setGVDResponse({"gps"})						
							response.gps[gpsParams[i].param] = gpsParams[i].value
							self:getVehicleData_ResponseInvalidData(response)
						end						
					end
				--End Test Case NegativeResponseCheck.8.1
				
				-----------------------------------------------------------------------------------------

				--Begin Test Case NegativeResponseCheck.8.2
				--Description: Check response with parameters in tirePressure structure WrongType
					local tirePressureParams = {"pressureTelltale", "leftFront", "rightFront", "leftRear", "rightRear", "innerLeftRear", "innerRightRear"}
					for i=1, #tirePressureParams do						
						Test["GetVehicleData_"..tirePressureParams[i].."WrongType"] = function(self)
							local response = setGVDResponse({"tirePressure"})						
							response.tirePressure[tirePressureParams[i]] = 1234
							self:getVehicleData_ResponseInvalidData(response)
						end						
					end
				--End Test Case NegativeResponseCheck.8.2
				
				-----------------------------------------------------------------------------------------

				--Begin Test Case NegativeResponseCheck.8.3
				--Description: Check response with parameters in beltStatus structure WrongType					
					for i=1, #beltStatusParams do						
						Test["GetVehicleData_"..beltStatusParams[i].."WrongType"] = function(self)
							local response = setGVDResponse({"beltStatus"})						
							response.beltStatus[beltStatusParams[i]] = 1234
							self:getVehicleData_ResponseInvalidData(response)
						end						
					end
				--End Test Case NegativeResponseCheck.8.3
				
				-----------------------------------------------------------------------------------------

				--Begin Test Case NegativeResponseCheck.8.4
				--Description: Check response with parameters in bodyInformation structure WrongType
					local bodyInformationParams = {"parkBrakeActive", "ignitionStableStatus", "ignitionStatus", "driverDoorAjar", "passengerDoorAjar", "rearLeftDoorAjar", "rearRightDoorAjar"}
					for i=1, #bodyInformationParams do						
						Test["GetVehicleData_"..bodyInformationParams[i].."WrongType"] = function(self)
							local response = setGVDResponse({"bodyInformation"})						
							response.bodyInformation[bodyInformationParams[i]] = 1234
							self:getVehicleData_ResponseInvalidData(response)
						end						
					end
				--End Test Case NegativeResponseCheck.8.4
				
				-----------------------------------------------------------------------------------------

				--Begin Test Case NegativeResponseCheck.8.5
				--Description: Check response with parameters in deviceStatus structure WrongType
					local deviceStatusParams = {"voiceRecOn", "btIconOn", "callActive", "phoneRoaming", "textMsgAvailable", "battLevelStatus", "stereoAudioOutputMuted", "monoAudioOutputMuted", "signalLevelStatus", "primaryAudioSource", "eCallEventActive"}
					for i=1, #deviceStatusParams do						
						Test["GetVehicleData_"..deviceStatusParams[i].."WrongType"] = function(self)
							local response = setGVDResponse({"deviceStatus"})						
							response.deviceStatus[deviceStatusParams[i]] = 1234
							self:getVehicleData_ResponseInvalidData(response)
						end						
					end
				--End Test Case NegativeResponseCheck.8.5
				
				-----------------------------------------------------------------------------------------

				--Begin Test Case NegativeResponseCheck.8.6
				--Description: Check response with parameters in headLampStatus structure WrongType
					local headLampStatusParams = {"lowBeamsOn", "highBeamsOn", "ambientLightSensorStatus"}
					for i=1, #headLampStatusParams do						
						Test["GetVehicleData_"..headLampStatusParams[i].."WrongType"] = function(self)
							local response = setGVDResponse({"headLampStatus"})						
							response.headLampStatus[headLampStatusParams[i]] = 1234
							self:getVehicleData_ResponseInvalidData(response)
						end						
					end
				--End Test Case NegativeResponseCheck.8.6
				
				-----------------------------------------------------------------------------------------

				--Begin Test Case NegativeResponseCheck.8.7
				--Description: Check response with parameters in eCallInfo structure WrongType					
					for i=1, #eCallInfoParams do						
						Test["GetVehicleData_"..eCallInfoParams[i].."WrongType"] = function(self)
							local response = setGVDResponse({"eCallInfo"})						
							response.eCallInfo[eCallInfoParams[i]] = 1234
							self:getVehicleData_ResponseInvalidData(response)
						end						
					end
				--End Test Case NegativeResponseCheck.8.7
				
				-----------------------------------------------------------------------------------------

				--Begin Test Case NegativeResponseCheck.8.8
				--Description: Check response with parameters in airbagStatus structure WrongType
					for i=1, #airbagStatusParams do						
						Test["GetVehicleData_"..airbagStatusParams[i].."WrongType"] = function(self)
							local response = setGVDResponse({"airbagStatus"})						
							response.airbagStatus[airbagStatusParams[i]] = 1234
							self:getVehicleData_ResponseInvalidData(response)
						end						
					end
				--End Test Case NegativeResponseCheck.8.8
				
				-----------------------------------------------------------------------------------------

				--Begin Test Case NegativeResponseCheck.8.9
				--Description: Check response with parameters in emergencyEvent structure WrongType					
					for i=1, #emergencyEventParams do						
						Test["GetVehicleData_"..emergencyEventParams[i].."WrongType"] = function(self)
							local response = setGVDResponse({"emergencyEvent"})						
							response.emergencyEvent[emergencyEventParams[i]] = 1234
							self:getVehicleData_ResponseInvalidData(response)
						end						
					end
				--End Test Case NegativeResponseCheck.8.9
				
				-----------------------------------------------------------------------------------------

				--Begin Test Case NegativeResponseCheck.8.10
				--Description: Check response with parameters in clusterModeStatus structure WrongType	
					local clusterModeStatusParams = {"powerModeActive", "powerModeQualificationStatus", "carModeStatus", "powerModeStatus"}
					for i=1, #clusterModeStatusParams do						
						Test["GetVehicleData_"..clusterModeStatusParams[i].."WrongType"] = function(self)
							local response = setGVDResponse({"clusterModeStatus"})						
							response.clusterModeStatus[clusterModeStatusParams[i]] = 1234
							self:getVehicleData_ResponseInvalidData(response)
						end						
					end
				--End Test Case NegativeResponseCheck.8.10
				
				-----------------------------------------------------------------------------------------

				--Begin Test Case NegativeResponseCheck.8.11
				--Description: Check response with parameters in myKey structure WrongType	
					function Test:GetVehicleData_e911OverrideWrongType()						
						local response = setGVDResponse({"myKey"})						
						response.myKey["e911Override"] = 1234
						self:getVehicleData_ResponseInvalidData(response)
					end
				--End Test Case NegativeResponseCheck.8.11
				
				-----------------------------------------------------------------------------------------

				--Begin Test Case NegativeResponseCheck.8.12
				--Description: Check response with wrong type of vehicleData parameters
					for i=1, #allVehicleData do
						Test["GetVehicleData_Response"..allVehicleData[i].."WrongType"] = function(self)
							local response = setGVDResponse(allVehicleData)
							if 
								allVehicleData[i] == "rpm" or
								allVehicleData[i] == "instantFuelConsumption" or
								allVehicleData[i] == "engineTorque" or
								allVehicleData[i] == "steeringWheelAngle" or
								allVehicleData[i] == "odometer" then
									response[allVehicleData[i]] = "1234"
							else
								response[allVehicleData[i]] = 1234
							end
							
							self:getVehicleData_ResponseInvalidData(response)
						end
					end
				--End Test Case NegativeResponseCheck.8.12				
			--End Test case NegativeResponseCheck.8
			
			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeResponseCheck.9
			--Description: Check processing response with parameters with nonexistent value

				--Requirement id in JAMA:
					--SDLAQ-CRS-98
					
				--Verification criteria:
					-- The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode. The appropriate parameters sent in the request are returned with the data about subscription.
				
				--Begin Test Case NegativeResponseCheck.9.1
				--Description: Check response with nonexistent value for compassDirection parameters
					function Test:GetVehicleData_compassDirection_NotExist()						
						local response = setGVDResponse({"gps"})						
						response.gps["compassDirection"] = "ANY"
						self:getVehicleData_ResponseInvalidData(response)
					end
				--End Test Case NegativeResponseCheck.9.1
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test Case NegativeResponseCheck.9.2
				--Description: Check response with nonexistent value for fuelLevel_State parameters
					function Test:GetVehicleData_fuelLevel_State_NotExist()						
						local response = setGVDResponse({"fuelLevel_State"})						
						response["fuelLevel_State"] = "ANY"
						self:getVehicleData_ResponseInvalidData(response)
					end
				--End Test Case NegativeResponseCheck.9.2
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test Case NegativeResponseCheck.9.3
				--Description: Check response with nonexistent value for prndl parameters
					function Test:GetVehicleData_prndl_NotExist()						
						local response = setGVDResponse({"prndl"})						
						response["prndl"] = "ANY"
						self:getVehicleData_ResponseInvalidData(response)
					end
				--End Test Case NegativeResponseCheck.9.3
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test Case NegativeResponseCheck.9.4
				--Description:  Check response with nonexistent value for pressureTelltale parameters
					function Test:GetVehicleData_pressureTelltale_NotExist()						
						local response = setGVDResponse({"tirePressure"})						
						response.tirePressure["pressureTelltale"] = "ANY"
						self:getVehicleData_ResponseInvalidData(response)
					end
				--End Test Case NegativeResponseCheck.9.4
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test Case NegativeResponseCheck.9.5
				--Description: Check response with nonexistent value for tirePressure status
					local tirePressureParams ={"leftFront", "rightFront", "leftRear", "rightRear", "innerLeftRear", "innerRightRear"}
					for i=1, #tirePressureParams do
						Test["GetVehicleData_"..tirePressureParams[i].."_NotExist"] = function(self)
							local response = {tirePressure = {}}
							response.tirePressure[tirePressureParams[i]] = {status = "ANY"}
							self:getVehicleData_ResponseInvalidData(response)
						end
					end
				--End Test Case NegativeResponseCheck.9.5
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test Case NegativeResponseCheck.9.6
				--Description: Check response with nonexistent value for beltStatus status
					for i=1, #beltStatusParams do						
						Test["GetVehicleData_"..beltStatusParams[i].."_NotExist"] = function(self)
							local response = setGVDResponse({"beltStatus"})						
							response.beltStatus[beltStatusParams[i]] = "ANY"
							self:getVehicleData_ResponseInvalidData(response)
						end						
					end
				--End Test Case NegativeResponseCheck.9.6
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test Case NegativeResponseCheck.9.7
				--Description:  Check response with nonexistent value for ignitionStableStatus parameters
					function Test:GetVehicleData_ignitionStableStatus_NotExist()						
						local response = setGVDResponse({"bodyInformation"})						
						response.bodyInformation["ignitionStableStatus"] = "ANY"
						self:getVehicleData_ResponseInvalidData(response)
					end
				--End Test Case NegativeResponseCheck.9.7
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test Case NegativeResponseCheck.9.8
				--Description:  Check response with nonexistent value for ignitionStatus parameters
					function Test:GetVehicleData_ignitionStatus_NotExist()						
						local response = setGVDResponse({"bodyInformation"})						
						response.bodyInformation["ignitionStatus"] = "ANY"
						self:getVehicleData_ResponseInvalidData(response)
					end
				--End Test Case NegativeResponseCheck.9.8
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test Case NegativeResponseCheck.9.9
				--Description:  Check response with nonexistent value for battLevelStatus parameters
					function Test:GetVehicleData_battLevelStatus_NotExist()						
						local response = setGVDResponse({"deviceStatus"})						
						response.deviceStatus["battLevelStatus"] = "ANY"
						self:getVehicleData_ResponseInvalidData(response)
					end
				--End Test Case NegativeResponseCheck.9.9
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test Case NegativeResponseCheck.9.10
				--Description:  Check response with nonexistent value for signalLevelStatus parameters
					function Test:GetVehicleData_signalLevelStatus_NotExist()						
						local response = setGVDResponse({"deviceStatus"})						
						response.deviceStatus["signalLevelStatus"] = "ANY"
						self:getVehicleData_ResponseInvalidData(response)
					end
				--End Test Case NegativeResponseCheck.9.10
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test Case NegativeResponseCheck.9.11
				--Description:  Check response with nonexistent value for primaryAudioSource parameters
					function Test:GetVehicleData_primaryAudioSource_NotExist()						
						local response = setGVDResponse({"deviceStatus"})						
						response.deviceStatus["primaryAudioSource"] = "ANY"
						self:getVehicleData_ResponseInvalidData(response)
					end
				--End Test Case NegativeResponseCheck.9.11
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test Case NegativeResponseCheck.9.12
				--Description:  Check response with nonexistent value for driverBraking parameters
					function Test:GetVehicleData_driverBraking_NotExist()						
						local response = setGVDResponse({"driverBraking"})						
						response["driverBraking"] = "ANY"
						self:getVehicleData_ResponseInvalidData(response)
					end
				--End Test Case NegativeResponseCheck.9.12
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test Case NegativeResponseCheck.9.13
				--Description:  Check response with nonexistent value for wiperStatus parameters
					function Test:GetVehicleData_wiperStatus_NotExist()						
						local response = setGVDResponse({"wiperStatus"})						
						response["wiperStatus"] = "ANY"
						self:getVehicleData_ResponseInvalidData(response)
					end
				--End Test Case NegativeResponseCheck.9.13
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test Case NegativeResponseCheck.9.14
				--Description:  Check response with nonexistent value for ambientLightSensorStatus parameters
					function Test:GetVehicleData_ambientLightSensorStatus_NotExist()						
						local response = setGVDResponse({"headLampStatus"})						
						response.headLampStatus["ambientLightSensorStatus"] = "ANY"
						self:getVehicleData_ResponseInvalidData(response)
					end
				--End Test Case NegativeResponseCheck.9.14
				
				-----------------------------------------------------------------------------------------

				--Begin Test Case NegativeResponseCheck.9.15
				--Description: Check response with nonexistent value for parameters in eCallInfo structure
					for i=1, #eCallInfoParams do						
						Test["GetVehicleData_"..eCallInfoParams[i].."_NotExist"] = function(self)
							local response = setGVDResponse({"eCallInfo"})						
							response.eCallInfo[eCallInfoParams[i]] = "ANY"
							self:getVehicleData_ResponseInvalidData(response)
						end						
					end
				--End Test Case NegativeResponseCheck.9.15
				
				-----------------------------------------------------------------------------------------

				--Begin Test Case NegativeResponseCheck.9.16
				--Description: Check response with nonexistent value for parameters in airbagStatus structure
					for i=1, #airbagStatusParams do						
						Test["GetVehicleData_"..airbagStatusParams[i].."_NotExist"] = function(self)
							local response = setGVDResponse({"airbagStatus"})						
							response.airbagStatus[airbagStatusParams[i]] = "ANY"
							self:getVehicleData_ResponseInvalidData(response)
						end						
					end
				--End Test Case NegativeResponseCheck.9.16
				
				-----------------------------------------------------------------------------------------

				--Begin Test Case NegativeResponseCheck.9.17
				--Description: Check response with nonexistent value for parameters in emergencyEvent structure				
					local emergencyEventParams = {"emergencyEventType", "fuelCutoffStatus", "rolloverEvent", "multipleEvents"}
					for i=1, #emergencyEventParams do						
						Test["GetVehicleData_"..emergencyEventParams[i].."_NotExist"] = function(self)
							local response = setGVDResponse({"emergencyEvent"})						
							response.emergencyEvent[emergencyEventParams[i]] = "ANY"
							self:getVehicleData_ResponseInvalidData(response)
						end						
					end
				--End Test Case NegativeResponseCheck.9.17
				
				-----------------------------------------------------------------------------------------

				--Begin Test Case NegativeResponseCheck.9.18
				--Description: Check response with nonexistent value for parameters in clusterModeStatus structure				
					local clusterModeStatusParams = {"powerModeQualificationStatus", "carModeStatus", "powerModeStatus"}
					for i=1, #clusterModeStatusParams do						
						Test["GetVehicleData_"..clusterModeStatusParams[i].."_NotExist"] = function(self)
							local response = setGVDResponse({"clusterModeStatus"})						
							response.clusterModeStatus[clusterModeStatusParams[i]] = "ANY"
							self:getVehicleData_ResponseInvalidData(response)
						end						
					end
				--End Test Case NegativeResponseCheck.9.18
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test Case NegativeResponseCheck.9.19
				--Description:  Check response with nonexistent value for e911Override parameters
					function Test:GetVehicleData_e911Override_NotExist()						
						local response = setGVDResponse({"myKey"})						
						response.myKey["e911Override"] = "ANY"
						self:getVehicleData_ResponseInvalidData(response)
					end
				--End Test Case NegativeResponseCheck.9.19

				-----------------------------------------------------------------------------------------
				
				--Begin Test Case NegativeResponseCheck.9.20
				--Description: Check response with nonexistent value for dimension parameters
					function Test:GetVehicleData_dimension_NotExist()						
						local response = setGVDResponse({"gps"})						
						response.gps["dimension"] = "ANY"
						self:getVehicleData_ResponseInvalidData(response)
					end
				--End Test Case NegativeResponseCheck.9.20
			--End Test case NegativeResponseCheck.9
			
			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeResponseCheck.10
			--Description: Check processing response with parameters with invalid characters

				--Requirement id in JAMA:
					--SDLAQ-CRS-98
					
				--Verification criteria:
					-- The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode. The appropriate parameters sent in the request are returned with the data about subscription.
				
				--Begin Test Case NegativeResponseCheck.10.1
				--Description: Escape sequence \n in vin parameter 
					function Test:GetVehicleData_vinNewLineChar()						
						local response = setGVDResponse({"vin"})						
						response["vin"] = "123\n"
						self:getVehicleData_ResponseInvalidData(response)
					end
				--End Test Case NegativeResponseCheck.10.1
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test Case NegativeResponseCheck.10.2
				--Description: Escape sequence \t in vin parameter 
					function Test:GetVehicleData_vinNewTabChar()						
						local response = setGVDResponse({"vin"})						
						response["vin"] = "123\t"
						self:getVehicleData_ResponseInvalidData(response)
					end
				--End Test Case NegativeResponseCheck.10.2
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test Case NegativeResponseCheck.10.3
				--Description: White space only in vin parameter 
					function Test:GetVehicleData_vinWhiteSpacesOnly()						
						local response = setGVDResponse({"vin"})						
						response["vin"] = "      "
						self:getVehicleData_ResponseInvalidData(response)
					end
				--End Test Case NegativeResponseCheck.10.3				
			--Begin Test case NegativeResponseCheck.10
			
			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeResponseCheck.11
			--Description: Check processing response with parameters with out lower bound and upper bound value

				--Requirement id in JAMA:
					--SDLAQ-CRS-98
					
				--Verification criteria:
					-- The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode. The appropriate parameters sent in the request are returned with the data about subscription.
				
				--Begin Test case NegativeResponseCheck.11.1
				--Description: Response with longitudeDegrees parameter out of lower bound
					function Test:GetVehicleData_ResponseOutLowerBound_longitudeDegrees()						
						local response = setGVDResponse({"gps"})						
						response.gps["longitudeDegrees"] = -180.1
						self:getVehicleData_ResponseInvalidData(response)
					end
				--End Test case NegativeResponseCheck.11.1
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.11.2
				--Description: Response with longitudeDegrees parameter out of upper bound
					function Test:GetVehicleData_ResponseOutUpperBound_longitudeDegrees()						
						local response = setGVDResponse({"gps"})						
						response.gps["longitudeDegrees"] = 180.1			
						self:getVehicleData_ResponseInvalidData(response)
					end
				--End Test case NegativeResponseCheck.11.2
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.11.3
				--Description: Response with latitudeDegrees parameter out of lower bound
					function Test:GetVehicleData_ResponseOutLowerBound_latitudeDegrees()						
						local response = setGVDResponse({"gps"})						
						response.gps["latitudeDegrees"] = -90.1	
						self:getVehicleData_ResponseInvalidData(response)
					end
				--End Test case NegativeResponseCheck.11.3
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.11.4
				--Description: Response with latitudeDegrees parameter out of upper bound
					function Test:GetVehicleData_ResponseOutUpperBound_latitudeDegrees()						
						local response = setGVDResponse({"gps"})						
						response.gps["latitudeDegrees"] = 90.1
						self:getVehicleData_ResponseInvalidData(response)
					end
				--End Test case NegativeResponseCheck.11.4
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.11.5
				--Description: Response with utcYear parameter out of lower bound
					function Test:GetVehicleData_ResponseOutLowerBound_utcYear()						
						local response = setGVDResponse({"gps"})						
						response.gps["utcYear"] = 2009
						self:getVehicleData_ResponseInvalidData(response)
					end
				--End Test case NegativeResponseCheck.11.5
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.11.6
				--Description: Response with utcYear parameter out of upper bound
					function Test:GetVehicleData_ResponseOutUpperBound_utcYear()						
						local response = setGVDResponse({"gps"})						
						response.gps["utcYear"] = 2101
						self:getVehicleData_ResponseInvalidData(response)
					end
				--End Test case NegativeResponseCheck.11.6
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.11.7
				--Description: Response with utcMonth parameter out of lower bound
					function Test:GetVehicleData_ResponseOutLowerBound_utcMonth()						
						local response = setGVDResponse({"gps"})						
						response.gps["utcMonth"] = 0
						self:getVehicleData_ResponseInvalidData(response)
					end
				--End Test case NegativeResponseCheck.11.7
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.11.8
				--Description: Response with utcMonth parameter out of upper bound
					function Test:GetVehicleData_ResponseOutUpperBound_utcMonth()						
						local response = setGVDResponse({"gps"})						
						response.gps["utcMonth"] = 13
						self:getVehicleData_ResponseInvalidData(response)
					end
				--End Test case NegativeResponseCheck.11.8
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.11.9
				--Description: Response with utcDay parameter out of lower bound
					function Test:GetVehicleData_ResponseOutLowerBound_utcDay()						
						local response = setGVDResponse({"gps"})						
						response.gps["utcDay"] = 0
						self:getVehicleData_ResponseInvalidData(response)
					end
				--End Test case NegativeResponseCheck.11.9
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.11.10
				--Description: Response with utcDay parameter out of upper bound
					function Test:GetVehicleData_ResponseOutUpperBound_utcDay()						
						local response = setGVDResponse({"gps"})						
						response.gps["utcDay"] = 32
						self:getVehicleData_ResponseInvalidData(response)
					end
				--End Test case NegativeResponseCheck.11.10
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.11.11
				--Description: Response with utcHours parameter out of lower bound
					function Test:GetVehicleData_ResponseOutLowerBound_utcHours()						
						local response = setGVDResponse({"gps"})						
						response.gps["utcHours"] = -1
						self:getVehicleData_ResponseInvalidData(response)
					end
				--End Test case NegativeResponseCheck.11.11
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.11.12
				--Description: Response with utcHours parameter out of upper bound
					function Test:GetVehicleData_ResponseOutUpperBound_utcHours()						
						local response = setGVDResponse({"gps"})						
						response.gps["utcHours"] = 24
						self:getVehicleData_ResponseInvalidData(response)
					end
				--End Test case NegativeResponseCheck.11.12
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.11.13
				--Description: Response with utcMinutes parameter out of lower bound
					function Test:GetVehicleData_ResponseOutLowerBound_utcMinutes()						
						local response = setGVDResponse({"gps"})						
						response.gps["utcMinutes"] = -1
						self:getVehicleData_ResponseInvalidData(response)
					end
				--End Test case NegativeResponseCheck.11.13
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.11.14
				--Description: Response with utcMinutes parameter out of upper bound
					function Test:GetVehicleData_ResponseOutUpperBound_utcMinutes()						
						local response = setGVDResponse({"gps"})						
						response.gps["utcMinutes"] = 60
						self:getVehicleData_ResponseInvalidData(response)
					end
				--End Test case NegativeResponseCheck.11.14
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.11.15
				--Description: Response with utcSeconds parameter out of lower bound
					function Test:GetVehicleData_ResponseOutLowerBound_utcSeconds()						
						local response = setGVDResponse({"gps"})						
						response.gps["utcSeconds"] = -1
						self:getVehicleData_ResponseInvalidData(response)
					end
				--End Test case NegativeResponseCheck.11.15
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.11.16
				--Description: Response with utcSeconds parameter out of upper bound
					function Test:GetVehicleData_ResponseOutUpperBound_utcSeconds()						
						local response = setGVDResponse({"gps"})						
						response.gps["utcSeconds"] = 60
						self:getVehicleData_ResponseInvalidData(response)
					end
				--End Test case NegativeResponseCheck.11.16
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.11.17
				--Description: Response with pdop parameter out of lower bound
					function Test:GetVehicleData_ResponseOutLowerBound_pdop()						
						local response = setGVDResponse({"gps"})						
						response.gps["pdop"] = -0.1
						self:getVehicleData_ResponseInvalidData(response)
					end
				--End Test case NegativeResponseCheck.11.17
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.11.18
				--Description: Response with pdop parameter out of upper bound
					function Test:GetVehicleData_ResponseOutUpperBound_pdop()						
						local response = setGVDResponse({"gps"})						
						response.gps["pdop"] = 10.1
						self:getVehicleData_ResponseInvalidData(response)
					end
				--End Test case NegativeResponseCheck.11.18
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.11.19
				--Description: Response with hdop parameter out of lower bound
					function Test:GetVehicleData_ResponseOutLowerBound_hdop()						
						local response = setGVDResponse({"gps"})						
						response.gps["hdop"] = -0.1
						self:getVehicleData_ResponseInvalidData(response)
					end
				--End Test case NegativeResponseCheck.11.19
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.11.20
				--Description: Response with hdop parameter out of upper bound
					function Test:GetVehicleData_ResponseOutUpperBound_hdop()						
						local response = setGVDResponse({"gps"})						
						response.gps["hdop"] = 10.1
						self:getVehicleData_ResponseInvalidData(response)
					end
				--End Test case NegativeResponseCheck.11.20
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.11.21
				--Description: Response with vdop parameter out of lower bound
					function Test:GetVehicleData_ResponseOutLowerBound_vdop()						
						local response = setGVDResponse({"gps"})						
						response.gps["vdop"] = -0.1
						self:getVehicleData_ResponseInvalidData(response)
					end
				--End Test case NegativeResponseCheck.11.21
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.11.22
				--Description: Response with vdop parameter out of upper bound
					function Test:GetVehicleData_ResponseOutUpperBound_vdop()						
						local response = setGVDResponse({"gps"})						
						response.gps["vdop"] = 10.1
						self:getVehicleData_ResponseInvalidData(response)
					end
				--End Test case NegativeResponseCheck.11.22
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.11.23
				--Description: Response with satellites parameter out of lower bound
					function Test:GetVehicleData_ResponseOutLowerBound_satellites()						
						local response = setGVDResponse({"gps"})						
						response.gps["satellites"] = -1
						self:getVehicleData_ResponseInvalidData(response)
					end
				--End Test case NegativeResponseCheck.11.23
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.11.24
				--Description: Response with satellites parameter out of upper bound
					function Test:GetVehicleData_ResponseOutUpperBound_satellites()						
						local response = setGVDResponse({"gps"})						
						response.gps["satellites"] = 32
						self:getVehicleData_ResponseInvalidData(response)
					end
				--End Test case NegativeResponseCheck.11.24
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.11.25
				--Description: Response with altitude parameter out of lower bound
					function Test:GetVehicleData_ResponseOutLowerBound_altitude()						
						local response = setGVDResponse({"gps"})						
						response.gps["altitude"] = -10000.1
						self:getVehicleData_ResponseInvalidData(response)
					end
				--End Test case NegativeResponseCheck.11.25
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.11.26
				--Description: Response with altitude parameter out of upper bound
					function Test:GetVehicleData_ResponseOutUpperBound_altitude()						
						local response = setGVDResponse({"gps"})						
						response.gps["altitude"] = 10001
						self:getVehicleData_ResponseInvalidData(response)
					end
				--End Test case NegativeResponseCheck.11.26
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.11.27
				--Description: Response with heading parameter out of lower bound
					function Test:GetVehicleData_ResponseOutLowerBound_heading()						
						local response = setGVDResponse({"gps"})						
						response.gps["heading"] = -0.1
						self:getVehicleData_ResponseInvalidData(response)
					end
				--End Test case NegativeResponseCheck.11.27
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.11.28
				--Description: Response with heading parameter out of upper bound
					function Test:GetVehicleData_ResponseOutUpperBound_heading()						
						local response = setGVDResponse({"gps"})						
						response.gps["heading"] = 360.1
						self:getVehicleData_ResponseInvalidData(response)
					end
				--End Test case NegativeResponseCheck.11.28
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.11.29
				--Description: Response with gps.speed parameter out of lower bound
					function Test:GetVehicleData_ResponseOutLowerBound_gps_speed()						
						local response = setGVDResponse({"gps"})						
						response.gps["speed"] = -0.1
						self:getVehicleData_ResponseInvalidData(response)
					end
				--End Test case NegativeResponseCheck.11.29
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.11.30
				--Description: Response with gps.speed parameter out of upper bound
					function Test:GetVehicleData_ResponseOutUpperBound_gps_speed()						
						local response = setGVDResponse({"gps"})						
						response.gps["speed"] = 500.1
						self:getVehicleData_ResponseInvalidData(response)
					end
				--End Test case NegativeResponseCheck.11.30
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.11.31
				--Description: Response with speed parameter out of lower bound
					function Test:GetVehicleData_ResponseOutLowerBound_speed()						
						local response = setGVDResponse({"speed"})						
						response["speed"] = -0.1
						self:getVehicleData_ResponseInvalidData(response)
					end
				--End Test case NegativeResponseCheck.11.31
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.11.32
				--Description: Response with speed parameter out of upper bound
					function Test:GetVehicleData_ResponseOutUpperBound_speed()						
						local response = setGVDResponse({"speed"})						
						response["speed"] = 700.1
						self:getVehicleData_ResponseInvalidData(response)
					end
				--End Test case NegativeResponseCheck.11.32
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.11.33
				--Description: Response with rpm parameter out of lower bound
					function Test:GetVehicleData_ResponseOutLowerBound_rpm()						
						local response = setGVDResponse({"rpm"})						
						response["rpm"] = -1
						self:getVehicleData_ResponseInvalidData(response)
					end
				--End Test case NegativeResponseCheck.11.33
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.11.34
				--Description: Response with rpm parameter out of upper bound
					function Test:GetVehicleData_ResponseOutUpperBound_rpm()						
						local response = setGVDResponse({"rpm"})						
						response["rpm"] = 20001
						self:getVehicleData_ResponseInvalidData(response)
					end
				--End Test case NegativeResponseCheck.11.34
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.11.35
				--Description: Response with fuelLevel parameter out of lower bound
					function Test:GetVehicleData_ResponseOutLowerBound_fuelLevel()						
						local response = setGVDResponse({"fuelLevel"})						
						response["fuelLevel"] = -6.1
						self:getVehicleData_ResponseInvalidData(response)
					end
				--End Test case NegativeResponseCheck.11.35
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.11.36
				--Description: Response with fuelLevel parameter out of upper bound
					function Test:GetVehicleData_ResponseOutUpperBound_fuelLevel()						
						local response = setGVDResponse({"fuelLevel"})						
						response["fuelLevel"] = 106.1
						self:getVehicleData_ResponseInvalidData(response)
					end
				--End Test case NegativeResponseCheck.11.36
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.11.37
				--Description: Response with instantFuelConsumption parameter out of lower bound
					function Test:GetVehicleData_ResponseOutLowerBound_instantFuelConsumption()						
						local response = setGVDResponse({"instantFuelConsumption"})						
						response["instantFuelConsumption"] = -0.1
						self:getVehicleData_ResponseInvalidData(response)
					end
				--End Test case NegativeResponseCheck.11.37
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.11.38
				--Description: Response with instantFuelConsumption parameter out of upper bound
					function Test:GetVehicleData_ResponseOutUpperBound_instantFuelConsumption()						
						local response = setGVDResponse({"instantFuelConsumption"})						
						response["instantFuelConsumption"] = 25575.1
						self:getVehicleData_ResponseInvalidData(response)
					end
				--End Test case NegativeResponseCheck.11.38
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.11.39
				--Description: Response with externalTemperature parameter out of lower bound
					function Test:GetVehicleData_ResponseOutLowerBound_externalTemperature()						
						local response = setGVDResponse({"externalTemperature"})						
						response["externalTemperature"] = -40.1
						self:getVehicleData_ResponseInvalidData(response)
					end
				--End Test case NegativeResponseCheck.11.39
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.11.40
				--Description: Response with externalTemperature parameter out of upper bound
					function Test:GetVehicleData_ResponseOutUpperBound_externalTemperature()						
						local response = setGVDResponse({"externalTemperature"})						
						response["externalTemperature"] = 100.1
						self:getVehicleData_ResponseInvalidData(response)
					end
				--End Test case NegativeResponseCheck.11.40
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.11.41
				--Description: Response with vin parameter out of lower bound
					function Test:GetVehicleData_ResponseOutLowerBound_vin()						
						local response = setGVDResponse({"vin"})						
						response["vin"] = ""
						self:getVehicleData_ResponseInvalidData(response)
					end
				--End Test case NegativeResponseCheck.11.41
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.11.42
				--Description: Response with vin parameter out of upper bound
					function Test:GetVehicleData_ResponseOutUpperBound_vin()						
						local response = setGVDResponse({"vin"})						
						response["vin"] = "123456789123456789"
						self:getVehicleData_ResponseInvalidData(response)
					end
				--End Test case NegativeResponseCheck.11.42
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.11.43
				--Description: Response with odometer parameter out of lower bound
					function Test:GetVehicleData_ResponseOutLowerBound_odometer()						
						local response = setGVDResponse({"odometer"})						
						response["odometer"] = -1
						self:getVehicleData_ResponseInvalidData(response)
					end
				--End Test case NegativeResponseCheck.11.43
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.11.44
				--Description: Response with odometer parameter out of upper bound
					function Test:GetVehicleData_ResponseOutUpperBound_odometer()						
						local response = setGVDResponse({"odometer"})						
						response["odometer"] = 17000001
						self:getVehicleData_ResponseInvalidData(response)
					end
				--End Test case NegativeResponseCheck.11.44
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.11.45
				--Description: Response with engineTorque parameter out of lower bound
					function Test:GetVehicleData_ResponseOutLowerBound_engineTorque()						
						local response = setGVDResponse({"engineTorque"})						
						response["engineTorque"] = -1000.1
						self:getVehicleData_ResponseInvalidData(response)
					end
				--End Test case NegativeResponseCheck.11.45
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.11.46
				--Description: Response with engineTorque parameter out of upper bound
					function Test:GetVehicleData_ResponseOutUpperBound_engineTorque()						
						local response = setGVDResponse({"engineTorque"})						
						response["engineTorque"] = 2000.1
						self:getVehicleData_ResponseInvalidData(response)
					end
				--End Test case NegativeResponseCheck.11.46
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.11.47
				--Description: Response with accPedalPosition parameter out of lower bound
					function Test:GetVehicleData_ResponseOutLowerBound_accPedalPosition()						
						local response = setGVDResponse({"accPedalPosition"})						
						response["accPedalPosition"] = -0.1
						self:getVehicleData_ResponseInvalidData(response)
					end
				--End Test case NegativeResponseCheck.11.47
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.11.48
				--Description: Response with accPedalPosition parameter out of upper bound
					function Test:GetVehicleData_ResponseOutUpperBound_accPedalPosition()						
						local response = setGVDResponse({"accPedalPosition"})						
						response["accPedalPosition"] = 100.1
						self:getVehicleData_ResponseInvalidData(response)
					end
				--End Test case NegativeResponseCheck.11.48
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.11.49
				--Description: Response with steeringWheelAngle parameter out of lower bound
					function Test:GetVehicleData_ResponseOutLowerBound_steeringWheelAngle()						
						local response = setGVDResponse({"steeringWheelAngle"})						
						response["steeringWheelAngle"] = -2000.1
						self:getVehicleData_ResponseInvalidData(response)
					end
				--End Test case NegativeResponseCheck.11.49
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.11.50
				--Description: Response with steeringWheelAngle parameter out of upper bound
					function Test:GetVehicleData_ResponseOutUpperBound_steeringWheelAngle()						
						local response = setGVDResponse({"steeringWheelAngle"})						
						response["steeringWheelAngle"] = 2000.1
						self:getVehicleData_ResponseInvalidData(response)
					end
				--End Test case NegativeResponseCheck.11.50
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.11.51
				--Description: Response with maximumChangeVelocity parameter out of lower bound
					function Test:GetVehicleData_ResponseOutLowerBound_maximumChangeVelocity()						
						local response = setGVDResponse({"emergencyEvent"})						
						response.emergencyEvent["maximumChangeVelocity"] = -1
						self:getVehicleData_ResponseInvalidData(response)
					end
				--End Test case NegativeResponseCheck.11.51
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.11.52
				--Description: Response with maximumChangeVelocity parameter out of upper bound
					function Test:GetVehicleData_ResponseOutUpperBound_maximumChangeVelocity()						
						local response = setGVDResponse({"emergencyEvent"})						
						response.emergencyEvent["maximumChangeVelocity"] = 256
						self:getVehicleData_ResponseInvalidData(response)
					end
				--End Test case NegativeResponseCheck.11.52				
			--Begin Test case NegativeResponseCheck.11
			
			-----------------------------------------------------------------------------------------
--[[TODO: Check after APPLINK-14765 is resolved
			--Begin Test case NegativeResponseCheck.12
			--Description: Check processing response with correlationID

				--Requirement id in JAMA:
					--SDLAQ-CRS-98
					--APPLINK-14765 
					
				--Verification criteria:
					-- The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode. The appropriate parameters sent in the request are returned with the data about subscription.
					-- SDL must cut off the fake parameters from requests, responses and notifications received from HMI 
					
				--Begin Test case NegativeResponseCheck.12.1
				--Description: CorrelationID is missing
					function Test:GetVehicleData_Response_CorrelatioIDMissing()
						--mobile side: sending GetVehicleData request
						local cid = self.mobileSession:SendRPC("GetVehicleData",
																				{																			
																					speed = true
																				})
						
						--hmi side: expect GetVehicleData request
						EXPECT_HMICALL("VehicleInfo.GetVehicleData",{speed = true})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.GetVehicleData response
							self.hmiConnection:Send('{"jsonrpc":"2.0","result":{"code":0,"speed": 50.5,"method":"VehicleInfo.GetVehicleData"}}')
						end)
						
						--mobile side: expect GetVehicleData response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
					end
				--End Test case NegativeResponseCheck.12.1
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.12.2
				--Description: CorrelationID is wrong type
					function Test:GetVehicleData_Response_CorrelatioIDWrongType()
						--mobile side: sending GetVehicleData request
						local cid = self.mobileSession:SendRPC("GetVehicleData",
																				{																			
																					speed = true
																				})
						
						--hmi side: expect GetVehicleData request
						EXPECT_HMICALL("VehicleInfo.GetVehicleData",{speed = true})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.GetVehicleData response
							self.hmiConnection:SendResponse(tostring(data.id), data.method, "SUCCESS", {speed = 50.5})
						end)
						
						--mobile side: expect GetVehicleData response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
					end
				--End Test case NegativeResponseCheck.12.2
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.12.3
				--Description: CorrelationID is not existed
					function Test:GetVehicleData_Response_CorrelatioIDNotExisted()
						--mobile side: sending GetVehicleData request
						local cid = self.mobileSession:SendRPC("GetVehicleData",
																				{																			
																					speed = true
																				})
						
						--hmi side: expect GetVehicleData request
						EXPECT_HMICALL("VehicleInfo.GetVehicleData",{speed = true})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.GetVehicleData response
							self.hmiConnection:SendResponse(5555, data.method, "SUCCESS", {speed = 50.5})
						end)
						
						--mobile side: expect GetVehicleData response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
					end
				--End Test case NegativeResponseCheck.12.3	
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.12.4
				--Description: CorrelationID is negative
					function Test:GetVehicleData_Response_CorrelatioIDNegative()
						--mobile side: sending GetVehicleData request
						local cid = self.mobileSession:SendRPC("GetVehicleData",
																				{																			
																					speed = true
																				})
						
						--hmi side: expect GetVehicleData request
						EXPECT_HMICALL("VehicleInfo.GetVehicleData",{speed = true})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.GetVehicleData response
							self.hmiConnection:SendResponse(-1, data.method, "SUCCESS", {speed = 50.5})
						end)
						
						--mobile side: expect GetVehicleData response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
					end
				--End Test case NegativeResponseCheck.12.4
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.12.5
				--Description: CorrelationID is null
					function Test:GetVehicleData_Response_CorrelatioIDNull()
						--mobile side: sending GetVehicleData request
						local cid = self.mobileSession:SendRPC("GetVehicleData",
																				{																			
																					speed = true
																				})
						
						--hmi side: expect GetVehicleData request
						EXPECT_HMICALL("VehicleInfo.GetVehicleData",{speed = true})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.GetVehicleData response
							self.hmiConnection:Send('"id":null,"jsonrpc":"2.0","result":{"code":0,"method":"VehicleInfo.GetVehicleData"}}')							
						end)
						
						--mobile side: expect GetVehicleData response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
					end
				--End Test case NegativeResponseCheck.12.5
			--End Test case NegativeResponseCheck.12
--]]
		--End Test suit NegativeResponseCheck

----------------------------------------------------------------------------------------------
----------------------------------------IV TEST BLOCK-----------------------------------------
---------------------------------------Result codes check--------------------------------------
----------------------------------------------------------------------------------------------

		--------Checks-----------
		-- check all pairs resultCode+success
		-- check should be made sequentially (if it is possible):
		-- case resultCode + success true
		-- case resultCode + success false
			--For example:
				-- first case checks ABORTED + true
				-- second case checks ABORTED + false
			    -- third case checks REJECTED + true
				-- fourth case checks REJECTED + false

	--Begin Test suit ResultCodeCheck
	--Description:TC's check all resultCodes values in pair with success value

		--Begin Test case ResultCodeCheck.1
		--Description: Check OUT_OF_MEMORY result code

			--Requirement id in JAMA: SDLAQ-CRS-610

			--Verification criteria: 
				--A request GetVehicleData is sent under conditions of RAM deficit for executing it. The OUT_OF_MEMORY response code is returned. 
			
			--Not applicable
			
		--End Test case ResultCodeCheck.1
		
		-----------------------------------------------------------------------------------------
		
		--Begin Test case ResultCodeCheck.2
		--Description: Check of TOO_MANY_PENDING_REQUESTS result code

			--Requirement id in JAMA: SDLAQ-CRS-611

			--Verification criteria: 
				--The system has more than 1000 requests  at a time that haven't been responded yet.
				--The system sends the responses with TOO_MANY_PENDING_REQUESTS error code for all further requests until there are less than 1000 requests at a time that haven't been responded by the system yet.
			
			--Moved to ATF_GetVehicleData_TOO_MANY_PENDING_REQUESTS.lua
			
		--End Test case ResultCodeCheck.2

		-----------------------------------------------------------------------------------------
		
		--Begin Test case ResultCodeCheck.3
		--Description: Check APPLICATION_NOT_REGISTERED result code 

			--Requirement id in JAMA: SDLAQ-CRS-612

			--Verification criteria: 
				-- SDL returns APPLICATION_NOT_REGISTERED code for the request sent within the same connection before RegisterAppInterface has been performed yet.
			function Test:Precondition_CreationNewSession()
				-- Connected expectation
			  	self.mobileSession2 = mobile_session.MobileSession(
			    self,
			    self.mobileConnection)			   
			end
			for i=1, #allVehicleData do
				Test["GetVehicleData_ApplicationNotRegister_"..allVehicleData[i]] = function(self)					
					local temp = {}
					temp[allVehicleData[i]] = true
					--mobile side: sending GetVehicleData request					
					local cid = self.mobileSession2:SendRPC("GetVehicleData",temp)
					
					--mobile side: expected GetVehicleData response
					self.mobileSession2:ExpectResponse(cid, { success = false, resultCode = "APPLICATION_NOT_REGISTERED" })
					
					DelayedExp(300)
				end
			end					
		--End Test case ResultCodeCheck.3			
		
		-----------------------------------------------------------------------------------------
		
		--Begin Test case ResultCodeCheck.4
		--Description: Check VEHICLE_DATA_NOT_ALLOWED result code with success false

			--Requirement id in JAMA: SDLAQ-CRS-616

			--Verification criteria: 
			--[[
				1. To be defined for future implementation regarding Policies.
				
				1.2. User blocks the access to some vehicle data from HMI. These settings are stored in Policies table.
				When such vehicle data is requested by mobile app VEHICLE_DATA_NOT_ALLOWED resultCode is sent back to mobile app. General result code is success=false in case it's the only VD requested by the app.

				1.3. User blocks the access to some vehicle data from HMI. These settings are stored in Policies table. 
				When such vehicle data is requested by mobile app VEHICLE_DATA_NOT_ALLOWED resultCode is sent back to mobile app.
				General result code is success=true in case it's not the only VD requested and returned successfully to the app for the current request.
			--]]
			
			-- Not applicable
			
		--End Test case ResultCodeCheck.4

		-----------------------------------------------------------------------------------------
		--TODO: Update according to APPLINK-15825
		--Begin Test case ResultCodeCheck.5
		--Description: Check VEHICLE_DATA_NOT_AVAILABLE result code

			--Requirement id in JAMA: SDLAQ-CRS-617

			--Verification criteria:
				-- VEHICLE_DATA_NOT_AVAILABLE code is processed by SDL if received from HMI for some VD value not available or not published by vehicle component (in current HMI implementation), the response with VEHICLE_DATA_NOT_AVAILABLE resultCode is sent back to mobile app. General result code is success=false in case it's the only VD requested by the app.
				-- VEHICLE_DATA_NOT_AVAILABLE code is processed by SDL if received from HMI for some VD value not available or not published by vehicle component (in current HMI implementation), the response with VEHICLE_DATA_NOT_AVAILABLE resultCode is sent back to mobile app. General result code is success=true in case other VD requested by the app has been returned to the app successfully. 			
			
			--Begin Test Case ResultCodeCheck.5.1
			--Description: General result code is success=false in case it's the only VD requested by the app.
				function Test:GetVehicleData_VehicleDataNotAvailable_OnlyOneVD()
					--mobile side: sending GetVehicleData request
					local cid = self.mobileSession:SendRPC("GetVehicleData",
																			{																			
																				rpm = true
																			})
					
					--hmi side: expect GetVehicleData request
					EXPECT_HMICALL("VehicleInfo.GetVehicleData",{rpm = true})					
					:Do(function(_,data)
						--hmi side: sending VehicleInfo.GetVehicleData response
						self.hmiConnection:SendResponse(data.id, data.method, "VEHICLE_DATA_NOT_AVAILABLE", {})	
					end)
					
					--mobile side: expect GetVehicleData response
					EXPECT_RESPONSE(cid, {success = false, resultCode = "VEHICLE_DATA_NOT_AVAILABLE"})
				end
			--End Test Case ResultCodeCheck.5.1
			
			-----------------------------------------------------------------------------------------
			
			--Begin Test Case ResultCodeCheck.5.2
			--Description: General result code is success=true in case other VD requested by the app has been returned to the app successfully.
				function Test:GetVehicleData_VehicleDataNotAvailable_OtherVDAvailable()
					--mobile side: sending GetVehicleData request
					local cid = self.mobileSession:SendRPC("GetVehicleData",
																			{																			
																				rpm = true,
																				speed = true
																			})
					
					--hmi side: expect GetVehicleData request
					EXPECT_HMICALL("VehicleInfo.GetVehicleData",{rpm = true, speed = true})					
					:Do(function(_,data)
						--hmi side: sending VehicleInfo.GetVehicleData response
						self.hmiConnection:SendResponse(data.id, data.method, "VEHICLE_DATA_NOT_AVAILABLE", {speed = 50.5})	
					end)
					
					--mobile side: expect GetVehicleData response
					EXPECT_RESPONSE(cid, {success = true, resultCode = "VEHICLE_DATA_NOT_AVAILABLE", speed = 50.5})
				end
			--End Test Case ResultCodeCheck.5.2			
		--End Test case ResultCodeCheck.5	
		-----------------------------------------------------------------------------------------
--[[TODO: check after ATF defect APPLINK-13101 is resolved	
		--Begin Test case ResultCodeCheck.6
		--Description: Check DISALLOWED result code

			--Requirement id in JAMA: SDLAQ-CRS-2964, APPLINK-8673

			--Verification criteria:
				-- In case GetVehicleData RPC is allowed by policies with less than supported by protocol parameters AND the app assigned with such policies requests GetVehicleData with one and-or more NOT-allowed params only, SDL MUST NOT send anything to HMI, AND respond with "ResultCode:DISALLOWED, success: false" to mobile app.
				function Test:Precondition_PolicyUpdate()
					self:policyUpdate("PTU_ForGetVehicleData.json", true)
				end
				
				--Begin Test Case ResultCodeCheck.6.1
				--Description: Get vehicle data which is disallowed by policies
					function Test:GetVehicleData_Disallowed()
						--mobile side: sending GetVehicleData request
						local cid = self.mobileSession:SendRPC("GetVehicleData",{speed = true})
						
						--hmi side: expect GetVehicleData request
						EXPECT_HMICALL("VehicleInfo.GetVehicleData",{speed = true})						
						:Times(0)
						
						--mobile side: expected GetVehicleData response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED", info = "'speed' is disallowed by policies."})	
					end
				--Begin Test Case ResultCodeCheck.6.1
				
				-----------------------------------------------------------------------------------------
							
				--Begin Test Case ResultCodeCheck.6.2
				--Description: Get vehicle data which one is disallowed and another is allowed by policies
					function Test:GetVehicleData_DisallowedAndAllowed()
						--mobile side: sending GetVehicleData request
						local cid = self.mobileSession:SendRPC("GetVehicleData",
																				{
																					speed = true,
																					rpm = true
																				})
						
						--hmi side: expect GetVehicleData request
						EXPECT_HMICALL("VehicleInfo.GetVehicleData",{rpm = true})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.GetVehicleData response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {rpm = 1000})	
						end)
						:ValidIf (function(_,data)
							if data.params.speed then
								print(" \27[36m SDL resend disallowed vehicle data to mobile app \27[0m")
								return false
							else 
								return true
							end
						end)
						
						--mobile side: expect GetVehicleData response
						EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS", rpm = 1000, info = "'speed' is disallowed by policies."})
					end
				--Begin Test Case ResultCodeCheck.6.2
		--End Test case ResultCodeCheck.6
		
		-----------------------------------------------------------------------------------------
	
		--Begin Test case ResultCodeCheck.7
		--Description: Check USER_DISALLOWED result code with success false

			--Requirement id in JAMA: SDLAQ-CRS-615

			--Verification criteria: 
				--  SDL must return "resultCode: USER_DISALLOWED, success:false" to the RPC in case this RPC exists in the PolicyTable group disallowed by the user.
			
				function Test:Precondition_UserDisallowedVehicleData()					
					--hmi side: sending SDL.OnAppPermissionConsent
					self.hmiConnection:SendNotification("SDL.OnAppPermissionConsent", { appID =  self.applications["Test Application"], consentedFunctions = {{ allowed = false, id = 193465391, name = "New"}}, source = "GUI"})							
				end
								
				function Test:GetVehicleData_USER_DISALLOWED()
					--mobile side: sending GetVehicleData request
					local cid = self.mobileSession:SendRPC("GetVehicleData",
																			{
																				speed = true																			
																			})					
										
					--hmi side: expect GetVehicleData request
					EXPECT_HMICALL("VehicleInfo.GetVehicleData",{
																	speed = true
																})					
					:Times(0)
					
					--mobile side: expect GetVehicleData response
					EXPECT_RESPONSE(cid, {success = false, resultCode = "USER_DISALLOWED"})					
				end
				
				function Test:Postcondition_AllowedAllVehicleData()					
					self:policyUpdate("PTU_GVDAllowedAllVehicleData.json", true)
				end
		--End Test case ResultCodeCheck.7		
--]]		
		-----------------------------------------------------------------------------------------

		--Begin Test case ResultCodeCheck.8
		--Description: Check REJECTED result code

			--Requirement id in JAMA: SDLAQ-CRS-613

			--Verification criteria:
				--  In case SDL receives REJECTED result code for the RPC from HMI, SDL must transfer REJECTED resultCode with adding "success:false" to mobile app.
			function Test:GetVehicleData_REJECTED()
				--mobile side: sending GetVehicleData request
				local cid = self.mobileSession:SendRPC("GetVehicleData",
																		{																			
																			rpm = true
																		})
				
				--hmi side: expect GetVehicleData request
				EXPECT_HMICALL("VehicleInfo.GetVehicleData",{rpm = true})					
				:Do(function(_,data)
					--hmi side: sending VehicleInfo.GetVehicleData response
					self.hmiConnection:SendError(data.id, data.method, "REJECTED", "Error Message")	
				end)
				
				--mobile side: expect GetVehicleData response
				EXPECT_RESPONSE(cid, {success = false, resultCode = "REJECTED", info = "Error Message"})
			end
		--End Test case ResultCodeCheck.8
		
		-----------------------------------------------------------------------------------------

		--Begin Test case ResultCodeCheck.9
		--Description: Check GENERIC_ERROR result code with success false

			--Requirement id in JAMA: SDLAQ-CRS-614

			--Verification criteria: 
				-- In case SDL receives GENERIC_ERROR result code for the RPC from HMI, SDL must transfer GENERIC_ERROR resultCode with adding "success:false" to mobile app.				
			function Test:GetVehicleData_GENERIC_ERROR()
				--mobile side: sending GetVehicleData request
				local cid = self.mobileSession:SendRPC("GetVehicleData",
																		{																			
																			rpm = true
																		})
				
				--hmi side: expect GetVehicleData request
				EXPECT_HMICALL("VehicleInfo.GetVehicleData",{rpm = true})					
				:Do(function(_,data)
					--hmi side: sending VehicleInfo.GetVehicleData response
					self.hmiConnection:SendResponse(data.id, data.method, "GENERIC_ERROR", {})	
				end)
				
				--mobile side: expect GetVehicleData response
				EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR"})
			end
		--End Test case ResultCodeCheck.9		
	--End Test suit ResultCodeCheck

----------------------------------------------------------------------------------------------
-----------------------------------------V TEST BLOCK-----------------------------------------
---------------------------------------HMI negative cases-------------------------------------
----------------------------------------------------------------------------------------------
	--------Checks-----------
	-- requests without responses from HMI
	-- invalid structure of response
	-- several responses from HMI to one request
	-- fake parameters
	-- HMI correlation id check 
	-- wrong response with correct HMI id

	--Begin Test suit HMINegativeCheck
	--Description: Check processing responses with invalid structure, fake parameters, HMI correlation id check, wrong response with correct HMI correlation id, check sdl behaviour in case of absence the response from HMI

		--Begin Test case HMINegativeCheck.1
		--Description: 
			-- Check SDL behaviour in case of absence of responses from HMI

			--Requirement id in JAMA:
				--SDLAQ-CRS-614
				--APPLINK-8585				
			
			--Verification criteria:
				-- SDL must return GENERIC_ERROR result to mobile app in case one of HMI components does not respond being supported and active.
			function Test:GetVehicleData_NoResponseFromHMI()
				--mobile side: sending GetVehicleData request
				local cid = self.mobileSession:SendRPC("GetVehicleData",
																		{
																			speed = true
																		})
				
				--hmi side: expect GetVehicleData request
				EXPECT_HMICALL("VehicleInfo.GetVehicleData",{
																speed = true
															})					
				:Do(function(_,data)
					--hmi side: sending VehicleInfo.GetVehicleData response						
					
				end)
				
				--mobile side: expect GetVehicleData response
				EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR"})
				:Timeout(12000)
			end
		--End Test case HMINegativeCheck.1	
		
		-----------------------------------------------------------------------------------------
--[[TODO: update according to APPLINK-14765
		--Begin Test case HMINegativeCheck.2
		--Description: 
			-- Check processing responses with invalid structure

			--Requirement id in JAMA:
				--SDLAQ-CRS-98
				
			--Verification criteria:
				--The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode. The appropriate parameters sent in the request are returned with the data about subscription. 
			function Test:GetVehicleData_ResponseInvalidStructure()
				--mobile side: sending GetVehicleData request
				local cid = self.mobileSession:SendRPC("GetVehicleData",
																		{
																			speed = true
																		})					
									
				
				--hmi side: expect GetVehicleData request
				EXPECT_HMICALL("VehicleInfo.GetVehicleData",{
																speed = true
															})					
				:Do(function(_,data)
					--hmi side: sending VehicleInfo.GetVehicleData response						
					--Correct structure:self.hmiConnection:Send('"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"speed": 55.5,"code":0, "method":"VehicleInfo.GetVehicleData"}}')
					self.hmiConnection:Send('"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"speed" 55.5,"code":0, "method":"VehicleInfo.GetVehicleData"}}')
				end)
					
				--mobile side: expect GetVehicleData response
				EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
				:Timeout(12000)
			end						
		--End Test case HMINegativeCheck.2
--]]		
		-----------------------------------------------------------------------------------------
--[[TODO: check after APPLINK-15236 is resolved due to core dump	
		--Begin Test case HMINegativeCheck.3
		--Description: 
			-- Several response to one request

			--Requirement id in JAMA:
				--SDLAQ-CRS-98
				
			--Verification criteria:
				--The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.
			function Test:GetVehicleData_SeveralResponseToOneRequest()
				--mobile side: sending GetVehicleData request
				local cid = self.mobileSession:SendRPC("GetVehicleData",
																			{
																				speed = true
																			})
				
				--hmi side: expect GetVehicleData request
				EXPECT_HMICALL("VehicleInfo.GetVehicleData",{speed = true})					
				:Do(function(_,data)
					--hmi side: sending VehicleInfo.GetVehicleData response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {speed= 80.5})	
					self.hmiConnection:SendResponse(data.id, data.method, "REJECTED", {})	
					self.hmiConnection:SendResponse(data.id, data.method, "GENERIC_ERROR", {})	
				end)
				
				--mobile side: expect GetVehicleData response
				EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS", speed=80.5})				
			end
		--End Test case HMINegativeCheck.3
--]]		
		-----------------------------------------------------------------------------------------

		--Begin Test case HMINegativeCheck.4
		--Description: 
			-- Check processing response with fake parameters

			--Requirement id in JAMA:
				--SDLAQ-CRS-98
				
			--Verification criteria:
				--The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.
			
			--Begin Test case HMINegativeCheck.4.1
			--Description: Parameter not from API
				function Test:GetVehicleData_FakeParamsInResponse()
					--mobile side: sending GetVehicleData request
					local cid = self.mobileSession:SendRPC("GetVehicleData",
																			{
																				speed = true
																			})
					
					--hmi side: expect GetVehicleData request
					EXPECT_HMICALL("VehicleInfo.GetVehicleData",{speed = true})					
					:Do(function(_,data)
						--hmi side: sending VehicleInfo.GetVehicleData response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {fake = "fakeParams", speed = 55.5})							
					end)
					
					--mobile side: expect GetVehicleData response
					EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS", speed = 55.5})				
					:ValidIf (function(_,data)
			    		if data.payload.fake then
			    			print(" \27[36m SDL resend fake parameter to mobile app \27[0m ")
			    			return false
			    		else 
			    			return true
			    		end
			    	end)
				end
			--End Test case HMINegativeCheck.4.1
			
			-----------------------------------------------------------------------------------------
			
			--Begin Test case HMINegativeCheck.4.2
			--Description: Parameter from another API
				function Test:GetVehicleData_ParamsFromOtherAPIInResponse()
					--mobile side: sending GetVehicleData request
					local cid = self.mobileSession:SendRPC("GetVehicleData",
																			{
																				speed = true
																			})
				
					--hmi side: expect GetVehicleData request
					EXPECT_HMICALL("VehicleInfo.GetVehicleData",{speed = true})					
					:Do(function(_,data)
						--hmi side: sending VehicleInfo.GetVehicleData response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {sliderPosition = 5, speed = 55.5})							
					end)
					
					--mobile side: expect GetVehicleData response
					EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS", speed = 55.5})				
					:ValidIf (function(_,data)
			    		if data.payload.sliderPosition then
			    			print(" \27[36m SDL resend fake parameter to mobile app \27[0m ")
			    			return false
			    		else 
			    			return true
			    		end
			    	end)
				end
			--End Test case HMINegativeCheck.4.2			
		--End Test case HMINegativeCheck.4
		
		-----------------------------------------------------------------------------------------
	
		--Begin Test case HMINegativeCheck.5
		--Description: 
			-- Wrong response with correct HMI correlation id

			--Requirement id in JAMA:
				--SDLAQ-CRS-98
				
			--Verification criteria:
				--The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.			
			--TODO: remove Timeout(12000) after resolving APPLINK-14765.
			function Test:GetVehicleData_WrongResponseToCorrectID()
				--mobile side: sending GetVehicleData request
				local cid = self.mobileSession:SendRPC("GetVehicleData",
																			{
																				speed = true
																			})
				
				--hmi side: expect GetVehicleData request
				EXPECT_HMICALL("VehicleInfo.GetVehicleData",{speed = true})					
				:Do(function(_,data)
					--hmi side: sending VehicleInfo.GetVehicleData response
					self.hmiConnection:SendResponse(data.id, "UI.AddCommand", "SUCCESS", {speed = 55.5})							
				end)					
					
				--mobile side: expect GetVehicleData response
				EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
				:Timeout(12000)
			end
		--End Test case HMINegativeCheck.5		
	--End Test suit HMINegativeCheck		

----------------------------------------------------------------------------------------------
-----------------------------------------VI TEST BLOCK----------------------------------------
-------------------------Sequence with emulating of user's action(s)------------------------
----------------------------------------------------------------------------------------------

	--Begin Test suit SequenceCheck
	--Description: TC's checks SDL behaviour by processing
		-- different request sequence with timeout
		-- with emulating of user's actions
	
		--Begin Test case SequenceCheck.1
		--Description: Checking GetVehicleData frequency
		
			--Requirement id in JAMA: 
				-- APPLINK-7616 

			--Verification criteria:
				-- The System must not allow an application to request a single piece of data more frequently than once per second or what is allowed by the policy table.
--[[TODO: check after APPLINK-15236 is resolved
			local getVDRequest = 6
			local getVDRejectedCount = 0
			local getVDSuccessCount = 0
			function Test:GetVehicleData_FrequencyREJECTED() 
				for i=1, getVDRequest do
					--mobile side: sending GetVehicleData request
					local cid = self.mobileSession:SendRPC("GetVehicleData",{speed = true})
				end
				
				--hmi side: expect GetVehicleData request
				EXPECT_HMICALL("VehicleInfo.GetVehicleData",{speed = true})
				:Do(function(_,data)
					--hmi side: sending VehicleInfo.GetVehicleData response
					self.hmiConnection:SendResponse(data.id, data.method,"SUCCESS", {speed = 50.5})
				end)
				:Times(5)
				
				--mobile side: expect GetVehicleData response
				EXPECT_RESPONSE("GetVehicleData")
				:ValidIf(function(exp,data)					
					if 
						exp.occurences == getVDRequest and
						(data.payload.resultCode == "SUCCESS" or
						data.payload.resultCode == "REJECTED") then
							if 
								data.payload.resultCode == "SUCCESS" then
								getVDSuccessCount = getVDSuccessCount + 1
							else 
								getVDRejectedCount = getVDRejectedCount + 1	
							end

						if getVDRejectedCount ~= 1 or getVDSuccessCount ~= getVDRequest - 1 then 
							print(" \27[36m Expected GetVehicleData responses with resultCode  REJECTED 1 time, actual - "..tostring(getVDRejectedCount) .. ", expected with resultCodes SUCCESS " .. tostring(getVDRequest) .. " times, actual - " .. tostring(getVDSuccessCount) .. " \27[0m" )
							return false
						else
							return true
						end
					elseif
						data.payload.resultCode == "REJECTED" then
						getVDRejectedCount = getVDRejectedCount+1
						print(" \27[32m GetVehicleData response came with resultCode REJECTED \27[0m")
						return true

					elseif 
						exp.occurences == getVDRequest and getVDRejectedCount == 0 then 
						print(" \27[36m Response GetVehicleData with resultCode REJECTED did not came \27[0m")
						return false

					elseif 
						data.payload.resultCode == "SUCCESS" then
						getVDSuccessCount = getVDSuccessCount + 1
						print(" \27[32m GetVehicleData response came with resultCode SUCCESS \27[0m")
						return true	
					else
						print(" \27[36m GetVehicleData response came with resultCode "..tostring(data.payload.resultCode .. "\27[0m" ))
						return false
						end			
				end)
				:Times(6)
			end			
		--End Test case SequenceCheck.1
]]
	--End Test suit SequenceCheck
----------------------------------------------------------------------------------------------
-----------------------------------------VII TEST BLOCK----------------------------------------
--------------------------------------Different HMIStatus-------------------------------------
----------------------------------------------------------------------------------------------
	--Description: processing of request/response in different HMIlevels, SystemContext, AudioStreamingState

	--Begin Test suit DifferentHMIlevel
	--Description: processing API in different HMILevel
	
		--Begin Test case DifferentHMIlevel.1
		--Description: Check GetVehicleData when current HMI is NONE

			--Requirement id in JAMA:
				--SDLAQ-CRS-2964
				
			--Verification criteria: 
				-- SDL rejects GetVehicleData request with DISALLOWED resultCode when current HMI level is NONE.
			function Test:Precondition_DeactivateToNone()
				--hmi side: sending BasicCommunication.OnExitApplication notification
				self.hmiConnection:SendNotification("BasicCommunication.OnExitApplication", {appID = self.applications["Test Application"], reason = "USER_EXIT"})

				EXPECT_NOTIFICATION("OnHMIStatus",
					{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
			end

			-- TODO: need to edit in scope of APPLINK-25651
			-- TODO: uncomment after resolving APPLINK-25647
			-- for i=1, #allVehicleData do
			-- 	Test["GetVehicleData_HMILevelNone_"..allVehicleData[i]] = function(self)
			-- 		local request = setGVDRequest({allVehicleData[i]})
					
			-- 		--mobile side: sending GetVehicleData request
			-- 		local cid = self.mobileSession:SendRPC("GetVehicleData",request)
					
			-- 		--mobile side: expected GetVehicleData response
			-- 		EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR" })
					
			-- 		DelayedExp(300)
			-- 	end
			-- end
			
			function Test:Postcondition_ActivateApp()
				--hmi side: sending SDL.ActivateApp request
				local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["Test Application"]})
				
				--mobile side: expect notification
				self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = "FULL", systemContext = "MAIN"})										
			end
		--End Test case DifferentHMIlevel.1
		
		-----------------------------------------------------------------------------------------

		--Begin Test case DifferentHMIlevel.2
		--Description: Check GetVehicleData when current HMI is LIMITED

			--Requirement id in JAMA:
				--SDLAQ-CRS-800
				
			--Verification criteria: 
				-- SDL doesn't rejects GetVehicleData when current HMI level is LIMITED.				
			if 
				Test.isMediaApplication == true or
				Test.appHMITypes["NAVIGATION"] == true then	
									
					function Test:Precondition_DeactivateToLimited()
						--hmi side: sending BasicCommunication.OnAppDeactivated request
						local cid = self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated",
						{
							appID = self.applications["Test Application"],
							reason = "GENERAL"
						})
						
						--mobile side: expect OnHMIStatus notification
						EXPECT_NOTIFICATION("OnHMIStatus",{hmiLevel = "LIMITED", systemContext = "MAIN", audioStreamingState = "AUDIBLE"})
					end
					
					for i=1, #allVehicleData do
						Test["GetVehicleData_HMILevelLimited_"..allVehicleData[i]] = function(self)						
							self:getVehicleDataSuccess({allVehicleData[i]})
						end
					end
		--End Test case DifferentHMIlevel.2
		
		-----------------------------------------------------------------------------------------
		
		--Begin Test case DifferentHMIlevel.3
		--Description: Check GetVehicleData when current HMI is BACKGROUND

			--Requirement id in JAMA:
				--SDLAQ-CRS-800
				
			--Verification criteria: 
				-- SDL doesn't rejects GetVehicleData when current HMI level is BACKGROUND.
			function Test:Precondition_SecondSession()
				--mobile side: start new session
			  self.mobileSession1 = mobile_session.MobileSession(
				self,
				self.mobileConnection)
			end
					
			function Test:Precondition_AppRegistrationInSecondSession()
				--mobile side: start new 
				self.mobileSession1:StartService(7)
				:Do(function()
					local CorIdRegister = self.mobileSession1:SendRPC("RegisterAppInterface",
					{
					  syncMsgVersion =
					  {
						majorVersion = 3,
						minorVersion = 0
					  },
					  appName = "Test Application2",
					  isMediaApplication = true,
					  languageDesired = 'EN-US',
					  hmiDisplayLanguageDesired = 'EN-US',
					  appHMIType = { "NAVIGATION" },
					  appID = "456"
					})
					
					--hmi side: expect BasicCommunication.OnAppRegistered request
					EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
					{
					  application = 
					  {
						appName = "Test Application2"
					  }
					})
					:Do(function(_,data)
					  self.applications["Test Application2"] = data.params.application.appID
					end)
					
					--mobile side: expect response
					self.mobileSession1:ExpectResponse(CorIdRegister, { success = true, resultCode = "SUCCESS" })
					:Timeout(2000)

					self.mobileSession1:ExpectNotification("OnHMIStatus",{hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
				end)
			end
			
			function Test:Precondition_ActivateSecondApp()
				--hmi side: sending SDL.ActivateApp request
				local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["Test Application2"]})

				--hmi side: expect SDL.ActivateApp response
				EXPECT_HMIRESPONSE(RequestId)
				:Do(function(_,data)
					if
						data.result.isSDLAllowed ~= true then
						local RequestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})
						
						--hmi side: expect SDL.GetUserFriendlyMessage message response
						EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
						:Do(function(_,data)						
							--hmi side: send request SDL.OnAllowSDLFunctionality
							self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {allowed = true, source = "GUI", device = {id = config.deviceMAC, name = "127.0.0.1"}})

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
				
				--mobile side: expect notification from 2 app
				self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = "BACKGROUND", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE"})
				self.mobileSession1:ExpectNotification("OnHMIStatus",{hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "AUDIBLE"})					
			end
		elseif
				Test.isMediaApplication == false then
				-- Precondition for non-media app
					function Test:Precondition_DeactivateToBackground()
						--hmi side: sending BasicCommunication.OnAppDeactivated request
						local cid = self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated",
						{
							appID = self.applications["Test Application"],
							reason = "GENERAL"
						})
						
						--mobile side: expect OnHMIStatus notification
						EXPECT_NOTIFICATION("OnHMIStatus",{hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
					end
						
		end
			for i=1, #allVehicleData do
				Test["GetVehicleData_HMILevelBackground_"..allVehicleData[i]] = function(self)						
					self:getVehicleDataSuccess({allVehicleData[i]})
				end
			end
		--End Test case DifferentHMIlevel.3		
	--End Test suit DifferentHMIlevel