Test = require('connecttest')
require('cardinalities')
local events = require('events')
local mobile_session = require('mobile_session')

require('user_modules/AppTypes')
local commonPreconditions = require ('/user_modules/shared_testcases/commonPreconditions')
local commonSteps = require ('/user_modules/shared_testcases/commonSteps')

local SVDValues = {gps="VEHICLEDATA_GPS", speed="VEHICLEDATA_SPEED", rpm="VEHICLEDATA_RPM", fuelLevel="VEHICLEDATA_FUELLEVEL", fuelLevel_State="VEHICLEDATA_FUELLEVEL_STATE", instantFuelConsumption="VEHICLEDATA_FUELCONSUMPTION", externalTemperature="VEHICLEDATA_EXTERNTEMP", prndl="VEHICLEDATA_PRNDL", tirePressure="VEHICLEDATA_TIREPRESSURE", odometer="VEHICLEDATA_ODOMETER", beltStatus="VEHICLEDATA_BELTSTATUS", bodyInformation="VEHICLEDATA_BODYINFO", deviceStatus="VEHICLEDATA_DEVICESTATUS", driverBraking="VEHICLEDATA_BRAKING", wiperStatus="VEHICLEDATA_WIPERSTATUS", headLampStatus="VEHICLEDATA_HEADLAMPSTATUS", engineTorque="VEHICLEDATA_ENGINETORQUE", accPedalPosition="VEHICLEDATA_ACCPEDAL", steeringWheelAngle="VEHICLEDATA_STEERINGWHEEL", eCallInfo="VEHICLEDATA_ECALLINFO", airbagStatus="VEHICLEDATA_AIRBAGSTATUS", emergencyEvent="VEHICLEDATA_EMERGENCYEVENT", clusterModeStatus="VEHICLEDATA_CLUSTERMODESTATUS", myKey="VEHICLEDATA_MYKEY"}
local allVehicleData = {"gps", "speed", "rpm", "fuelLevel", "fuelLevel_State", "instantFuelConsumption", "externalTemperature", "prndl", "tirePressure", "odometer", "beltStatus", "bodyInformation", "deviceStatus", "driverBraking", "wiperStatus", "headLampStatus", "engineTorque", "accPedalPosition", "steeringWheelAngle", "eCallInfo", "airbagStatus", "emergencyEvent", "clusterModeStatus", "myKey"}
local vehicleData = {"gps"}
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


function setSVDRequest(paramsSend)
	local temp = {}	
	for i = 1, #paramsSend do		
		temp[paramsSend[i]] = true
	end	
	return temp
end
function setSVDResponse(paramsSend, vehicleDataResultCode)
	local temp = {}
	local vehicleDataResultCodeValue = ""
	
	if vehicleDataResultCode ~= nil then
		vehicleDataResultCodeValue = vehicleDataResultCode
	else
		vehicleDataResultCodeValue = "SUCCESS"
	end
	
	for i = 1, #paramsSend do
		if  paramsSend[i] == "clusterModeStatus" then
			temp["clusterModes"] = {					
						resultCode = vehicleDataResultCodeValue, 
						dataType = SVDValues[paramsSend[i]]
				}
		else
			temp[paramsSend[i]] = {					
						resultCode = vehicleDataResultCodeValue, 
						dataType = SVDValues[paramsSend[i]]
				}
		end
	end	
	return temp
end
function createSuccessExpectedResult(response, infoMessage)
	response["success"] = true
	response["resultCode"] = "SUCCESS"
	
	if info ~= nil then
		response["info"] = infoMessage
	end
	
	return response
end
function createExpectedResult(bSuccess, sResultCode, infoMessage, response)
	response["success"] = bSuccess
	response["resultCode"] = sResultCode
	
	if infoMessage ~= nil then
		response["info"] = infoMessage
	end
	
	return response
end
function Test:subscribeVehicleDataSuccess(paramsSend, infoMessage)
	local request = setSVDRequest(paramsSend)
	local response = setSVDResponse(paramsSend)
	
	if infoMessage ~= nil then
		response["info"] = infoMessage
	end
	
	--mobile side: sending SubscribeVehicleData request
	local cid = self.mobileSession:SendRPC("SubscribeVehicleData",request)
	
	--hmi side: expect SubscribeVehicleData request
	EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData",request)
	:Do(function(_,data)
		--hmi side: sending VehicleInfo.SubscribeVehicleData response
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", response)	
	end)
	
	
	local expectedResult = createSuccessExpectedResult(response, infoMessage)
	
	--mobile side: expect SubscribeVehicleData response
	EXPECT_RESPONSE(cid, expectedResult)
	
	--mobile side: expect OnHashChange notification
	EXPECT_NOTIFICATION("OnHashChange")
end
function Test:subscribeVehicleDataInvalidData(paramsSend)
	--mobile side: sending SubscribeVehicleData request
	local cid = self.mobileSession:SendRPC("SubscribeVehicleData",paramsSend)
	
	--mobile side: expected SubscribeVehicleData response
	EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
	
	--mobile side: expect OnHashChange notification
	EXPECT_NOTIFICATION("OnHashChange",{})
	:Times(0)
end
function Test:unSubscribeVehicleDataSuccess(paramsSend)
	local request = setSVDRequest(paramsSend)
	local response = setSVDResponse(paramsSend)
		
	--mobile side: sending UnsubscribeVehicleData request
	local cid = self.mobileSession:SendRPC("UnsubscribeVehicleData",request)
	
	--hmi side: expect UnsubscribeVehicleData request
	EXPECT_HMICALL("VehicleInfo.UnsubscribeVehicleData",request)
	:Do(function(_,data)
		--hmi side: sending VehicleInfo.UnsubscribeVehicleData response
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", response)	
	end)
	
	local expectedResult = createSuccessExpectedResult(response)
	
	--mobile side: expect UnsubscribeVehicleData response
	--EXPECT_RESPONSE(cid, expectedResult)
	self.mobileSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
	
	--mobile side: expect OnHashChange notification
	EXPECT_NOTIFICATION("OnHashChange")
end
function Test:subscribeVehicleDataIgnored(paramsSend)	
	-- SubscribeVehicleData previously subscribed
	local request = setSVDRequest(paramsSend)
	local response = setSVDResponse(paramsSend, "DATA_ALREADY_SUBSCRIBED")						
	local messageValue = "Already subscribed on some provided VehicleData."
	
	--mobile side: sending SubscribeVehicleData request
	local cid = self.mobileSession:SendRPC("SubscribeVehicleData",request)
	
	local expectedResult = createExpectedResult(false, "IGNORED", messageValue, response)
	
	--mobile side: expect SubscribeVehicleData response
	EXPECT_RESPONSE(cid, expectedResult)
	
	--mobile side: expect OnHashChange notification
	EXPECT_NOTIFICATION("OnHashChange")
end

---------------------------------------------------------------------------------------------
------------------------- General Precondition before ATF start -----------------------------
---------------------------------------------------------------------------------------------
--make backup copy of file sdl_preloaded_pt.json
commonPreconditions:BackupFile("sdl_preloaded_pt.json")
-- TODO: Remove after implementation policy update
-- Precondition: remove policy table
commonSteps:DeletePolicyTable()

-- TODO: Remove after implementation policy update
-- Precondition: replace preloaded file with new one
os.execute('cp ./files/PTU_AllowedAndUserDisallowedSVD.json ' .. tostring(config.pathToSDL) .. "sdl_preloaded_pt.json")


---------------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------
	--Begin Precondition.1
	--Description: Activation application		
		function Test:ActivationApp()			
			--hmi side: sending SDL.ActivateApp request
			local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["Test Application"]})
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
						:Times(AnyNumber())
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

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-89

			--Verification criteria: SubsribeVehicleData request subscribes application for specific published vehicle data items. The data is sent upon being changed on HMI. The application is notified by the onVehicleData notification whenever the new data is available.
			function Test:SubscribeVehicleData_Positive() 				
				self:subscribeVehicleDataSuccess(allVehicleData)				
			end
			
			function Test:PostCondition_UnSubscribeVehicleData()				
				self:unSubscribeVehicleDataSuccess(allVehicleData)
			end
		--End Test case CommonRequestCheck.1
		
		-----------------------------------------------------------------------------------------
		
		--Begin Test case CommonRequestCheck.2
		--Description: This test is intended to check request with mandatory and conditional parameters
			--Not applicable
		--End Test case CommonRequestCheck.2
		
		-----------------------------------------------------------------------------------------
		
		--Begin Test case CommonRequestCheck.3
		--Description: This test is intended to check processing requests without mandatory parameters

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-576

			--Verification criteria:
				--The request sent with NO parameters receives INVALID_DATA response code.
				function Test:SubscribeVehicleData_AllParamsMissing() 
					self:subscribeVehicleDataInvalidData({})
				end			
		--End Test case CommonRequestCheck.3
		
		-----------------------------------------------------------------------------------------

		--Begin Test case CommonRequestCheck.4
		--Description: Check processing request with different fake parameters

			--Requirement id in JAMA/or Jira ID: APPLINK-4518

			--Verification criteria: According to xml tests by Ford team all fake params should be ignored by SDL

			--Begin Test case CommonRequestCheck4.1
			--Description: With fake parameters				
				function Test:SubscribeVehicleData_FakeParams()										
					--mobile side: sending SubscribeVehicleData request
					local cid = self.mobileSession:SendRPC("SubscribeVehicleData",
																				{
																					gps = true,
																					fakeParam ="fakeParam"
																				})
					
					--hmi side: expect SubscribeVehicleData request
					EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData",{gps = true})					
					:Do(function(_,data)
						--hmi side: sending VehicleInfo.SubscribeVehicleData response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {gps= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_GPS"}})	
					end)
					:ValidIf(function(_,data)
						if data.params.fakeParam then							
							print(" \27[36m SDL re-sends fakeParam parameters to HMI \27[0m")							
							return false
						else 
							return true
						end
					end)
					
					--mobile side: expect SubscribeVehicleData response
					EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS", gps= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_GPS"}})														
			
					--mobile side: expect OnHashChange notification
					EXPECT_NOTIFICATION("OnHashChange")
				end
				function Test:PostCondition_UnSubscribeVehicleData()				
					self:unSubscribeVehicleDataSuccess(vehicleData)
				end
			--End Test case CommonRequestCheck4.1
			
			-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.4.2
			--Description: Parameters from another request
				function Test:SubscribeVehicleData_ParamsAnotherRequest()
					--mobile side: sending SubscribeVehicleData request
					local cid = self.mobileSession:SendRPC("SubscribeVehicleData",
																				{
																					gps = true,
																					ttsChunks = 
																					{	
																						{ 
																							text = "TTSChunk",
																							type = "TEXT",
																						} 
																					}
																				})
					
					--hmi side: expect SubscribeVehicleData request
					EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData",{gps = true})					
					:Do(function(_,data)
						--hmi side: sending VehicleInfo.SubscribeVehicleData response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {gps= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_GPS"}})	
					end)
					:ValidIf(function(_,data)
						if data.params.ttsChunks then							
							print(" \27[36m SDL re-sends fakeParam parameters to HMI \27[0m")							
							return false
						else 
							return true
						end
					end)
					
					--mobile side: expect SubscribeVehicleData response
					EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS", gps= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_GPS"}})									
			
					--mobile side: expect OnHashChange notification
					EXPECT_NOTIFICATION("OnHashChange")
				end
				function Test:PostCondition_UnSubscribeVehicleData()				
					self:unSubscribeVehicleDataSuccess(vehicleData)
				end
			--End Test case CommonRequestCheck4.2
		--End Test case CommonRequestCheck.4
		
		-----------------------------------------------------------------------------------------

		--Begin Test case CommonRequestCheck.5
		--Description: Check processing request with invalid JSON syntax 

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-576

			--Verification criteria:  The request with wrong JSON syntax is sent, the response with INVALID_DATA result code is returned.
			function Test:SubscribeVehicleData_InvalidJSON()
				  self.mobileSession.correlationId = self.mobileSession.correlationId + 1

				  local msg = 
				  {
					serviceType      = 7,
					frameInfo        = 0,
					rpcType          = 0,
					rpcFunctionId    = 20,
					rpcCorrelationId = self.mobileSession.correlationId,
				--<<!-- missing ':'
					payload          = '"gps"  true'
				  }
				  
				  self.mobileSession:Send(msg)
				  self.mobileSession:ExpectResponse(self.mobileSession.correlationId, { success = false, resultCode = "INVALID_DATA" })
						
				--mobile side: expect OnHashChange notification is not send to mobile
				EXPECT_NOTIFICATION("OnHashChange",{})
				:Times(0)
			end
		--End Test case CommonRequestCheck.5

		-----------------------------------------------------------------------------------------
--TODO: Requirement and Verification criteria need to be updated.
		--Begin Test case CommonRequestCheck.6
		--Description: Check processing requests with duplicate correlationID value

			--Requirement id in JAMA/or Jira ID: 

			--Verification criteria: 
				--
			function Test:SubscribeVehicleData_correlationIdDuplicateValue()
				--mobile side: send SubscribeVehicleData request 
				local CorIdSubscribeVehicleData = self.mobileSession:SendRPC("SubscribeVehicleData", {gps = true})
				
				local msg = 
				  {
					serviceType      = 7,
					frameInfo        = 0,
					rpcType          = 0,
					rpcFunctionId    = 20,
					rpcCorrelationId = CorIdSubscribeVehicleData,				
					payload          = '{"speed" : true}'
				  }
				
				--hmi side: expect SubscribeVehicleData request
				EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData",
					{gps = true},
					{speed = true}
				)
				:Do(function(exp,data)
					if exp.occurences == 1 then 
						self.mobileSession:Send(msg)
						
						--hmi side: sending VehicleInfo.SubscribeVehicleData response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {gps= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_GPS"}})
					else
						--hmi side: sending VehicleInfo.SubscribeVehicleData response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {speed= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_SPEED"}})
					end				
				end)
				:Times(2)
								
				--mobile side: expect SubscribeVehicleData response
				EXPECT_RESPONSE(CorIdSubscribeVehicleData, 
						{success = true, resultCode = "SUCCESS", gps= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_GPS"}},
						{success = true, resultCode = "SUCCESS", speed= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_SPEED"}})       
				:Times(2)
						
				--mobile side: expect OnHashChange notification
				EXPECT_NOTIFICATION("OnHashChange")
				:Times(2)
			end
			function Test:PostCondition_UnSubscribeVehicleData()				
				self:unSubscribeVehicleDataSuccess({"gps", "speed"})		
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
					-- SDLAQ-CRS-89,
					-- SDLAQ-CRS-575
				
				--Verification criteria: 
					--Checking all VehicleData parameter. The request is executed successfully				
				for i=1, #allVehicleData do
					Test["SubscribeVehicleData_"..allVehicleData[i]] = function(self)
						self:subscribeVehicleDataSuccess({allVehicleData[i]})					
					end
				end
				function Test:PostCondition_UnSubscribeVehicleData()				
					self:unSubscribeVehicleDataSuccess(allVehicleData)	
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
					--SDLAQ-CRS-90
					
				--Verification criteria:
					-- The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode. The appropriate parameters sent in the request are returned with the data about subscription. 
	
				--Begin Test case PositiveResponseCheck.1.1
				--Description: Response with info parameter lower bound
					function Test: SubscribeVehicleData_ResponseInfoLowerBound()						
						self:subscribeVehicleDataSuccess(vehicleData, "a")
					end
					function Test:PostCondition_UnSubscribeVehicleData()				
						self:unSubscribeVehicleDataSuccess(vehicleData)
					end
				--End Test case PositiveResponseCheck.1.1
				
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveResponseCheck.1.2
				--Description:  Response with info parameter upper bound
					function Test: SubscribeVehicleData_ResponseInfoLowerBound()						
						self:subscribeVehicleDataSuccess(vehicleData, string.rep("a",1000))						
					end
					function Test:PostCondition_UnSubscribeVehicleData()				
						self:unSubscribeVehicleDataSuccess(vehicleData)
						DelayedExp(2000)
					end
				--End Test case PositiveResponseCheck.1.2				
			--End Test case PositiveResponseCheck.1
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
					--SDLAQ-CRS-576

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

				--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-576

				--Verification criteria: 
					-- The request with wrong type of parameter value is sent, the response with INVALID_DATA result code is returned.
					for i=1, #allVehicleData do
						Test["SubscribeVehicleData_WrongType_"..allVehicleData[i]] = function(self)
							local temp = {}
							temp[allVehicleData[i]] = 123
							self:subscribeVehicleDataInvalidData(temp)
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
			--Description: Check processing request with value not existed
			
				--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-576

				--Verification criteria: 
					--The request with the wrong name parameter (the one that does not exist in the list of valid parameters for SubscribeVehicleData) is processed by SDL as the invalid request even if such parameter is the only one in. The response returned contains the INVALID_DATA code. General result is "success"=false.
				function Test:SubscribeVehicleData_DataNotExisted()
					self:subscribeVehicleDataInvalidData({abc = true})
				end								
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
					--SDLAQ-CRS-90
					--SDLAQ-CRS-1097
					
				--Verification criteria:
					-- The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode. The appropriate parameters sent in the request are returned with the data about subscription.
					-- SDL re-sends vehicleDataResult received from HMI for every of parameters being subscribed (that is, parameters that are present in corresponding SubscribeVehicleData request).

				--Begin Test case NegativeResponseCheck.1.1
				--Description: Check response with nonexistent resultCode 
					function Test: SubscribeVehicleData_ResponseResultCodeNotExist()
						--mobile side: sending SubscribeVehicleData request
						local cid = self.mobileSession:SendRPC("SubscribeVehicleData",
																					{
																						gps = true
																					})
						
						--hmi side: expect SubscribeVehicleData request
						EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData",{gps = true})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.SubscribeVehicleData response
							self.hmiConnection:SendResponse(data.id, data.method, "ANY", {gps= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_GPS"}})	
						end)
						
						--mobile side: expect SubscribeVehicleData response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})		
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange",{})
						:Times(0)
					end
				--End Test case NegativeResponseCheck.1.1
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.1.2
				--Description: Check response with nonexistent VehicleData parameter 
					function Test: SubscribeVehicleData_ResponseVehicleDataNotExist()
						--mobile side: sending SubscribeVehicleData request
						local cid = self.mobileSession:SendRPC("SubscribeVehicleData",
																					{
																						gps = true
																					})
						
						--hmi side: expect SubscribeVehicleData request
						EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData",{gps = true})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.SubscribeVehicleData response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {abc= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_GPS"}})	
						end)
						
						--mobile side: expect SubscribeVehicleData response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange",{})
						:Times(0)
					end
				--End Test case NegativeResponseCheck.1.2
								
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.1.3
				--Description: Check response with nonexistent VehicleDataResultCode 
					function Test: SubscribeVehicleData_ResponseVehicleDataResultCodeNotExist()
						--mobile side: sending SubscribeVehicleData request
						local cid = self.mobileSession:SendRPC("SubscribeVehicleData",
																					{
																						gps = true
																					})
						
						--hmi side: expect SubscribeVehicleData request
						EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData",{gps = true})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.SubscribeVehicleData response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {gps= {resultCode = "ANY", dataType = "VEHICLEDATA_GPS"}})	
						end)
						
						--mobile side: expect SubscribeVehicleData response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange",{})
						:Times(0)
					end
				--End Test case NegativeResponseCheck.1.3
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.1.4
				--Description: Check response with nonexistent VehicleDataType 
					function Test: SubscribeVehicleData_ResponseVehicleDataTypeNotExist()
						--mobile side: sending SubscribeVehicleData request
						local cid = self.mobileSession:SendRPC("SubscribeVehicleData",
																					{
																						gps = true
																					})
						
						--hmi side: expect SubscribeVehicleData request
						EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData",{gps = true})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.SubscribeVehicleData response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {gps= {resultCode = "SUCCESS", dataType = "ANY"}})	
						end)
						
						--mobile side: expect SubscribeVehicleData response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange",{})
						:Times(0)
					end
				--End Test case NegativeResponseCheck.1.4
				
				-----------------------------------------------------------------------------------------
				
				--Begin NegativeResponseCheck.1.5
				--Description: Check response out bound of vehicleData
					function Test: SubscribeVehicleData_ResponseVehicleDataOutLowerBound()					
						--mobile side: sending SubscribeVehicleData request
						local cid = self.mobileSession:SendRPC("SubscribeVehicleData",
																					{
																						gps = true
																					})
						
						--hmi side: expect SubscribeVehicleData request
						EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData",{gps = true})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.SubscribeVehicleData response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {gps= {}})	
						end)
						
						--mobile side: expect SubscribeVehicleData response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})	
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange",{})
						:Times(0)		
					end
				--End NegativeResponseCheck.1.5
			--End Test case NegativeResponseCheck.1
			-----------------------------------------------------------------------------------------
			
			--Begin Test case NegativeResponseCheck.2
			--Description: Check processing responses with invalid values (empty, missing, nonexistent, invalid characters)

				--Requirement id in JAMA:
					--SDLAQ-CRS-90
					--SDLAQ-CRS-1097
					
				--Verification criteria:
					-- The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode. The appropriate parameters sent in the request are returned with the data about subscription.
					-- SDL re-sends vehicleDataResult received from HMI for every of parameters being subscribed (that is, parameters that are present in corresponding SubscribeVehicleData request).

				--Begin NegativeResponseCheck.2.1
				--Description: Check response with empty method
					function Test: SubscribeVehicleData_ResponseEmptyMethodEmpty()					
						--mobile side: sending SubscribeVehicleData request
						local cid = self.mobileSession:SendRPC("SubscribeVehicleData",
																					{
																						gps = true
																					})
						
						--hmi side: expect SubscribeVehicleData request
						EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData",{gps = true})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.SubscribeVehicleData response
							self.hmiConnection:SendResponse(data.id, "", "SUCCESS", {gps= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_GPS"}})	
						end)
						
						--mobile side: expect SubscribeVehicleData response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange",{})
						:Times(0)			
					end
				--End NegativeResponseCheck.2.1
				
				-----------------------------------------------------------------------------------------
				
				--Begin NegativeResponseCheck.2.2
				--Description: Check response with empty resultCode
					function Test: SubscribeVehicleData_ResponseEmptyResultCode()					
						--mobile side: sending SubscribeVehicleData request
						local cid = self.mobileSession:SendRPC("SubscribeVehicleData",
																					{
																						gps = true
																					})
						
						--hmi side: expect SubscribeVehicleData request
						EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData",{gps = true})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.SubscribeVehicleData response
							self.hmiConnection:SendResponse(data.id, data.method, "", {gps= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_GPS"}})	
						end)
						
						--mobile side: expect SubscribeVehicleData response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})	
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange",{})
						:Times(0)		
					end
				--End NegativeResponseCheck.2.2	
				
				-----------------------------------------------------------------------------------------
				
				--Begin NegativeResponseCheck.2.3
				--Description: Check response with empty VehicleDataResultCode
					function Test: SubscribeVehicleData_ResponseEmptyVehicleDataResultCode()					
						--mobile side: sending SubscribeVehicleData request
						local cid = self.mobileSession:SendRPC("SubscribeVehicleData",
																					{
																						gps = true
																					})
						
						--hmi side: expect SubscribeVehicleData request
						EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData",{gps = true})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.SubscribeVehicleData response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {gps= {resultCode = "", dataType = "VEHICLEDATA_GPS"}})	
						end)
						
						--mobile side: expect SubscribeVehicleData response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange",{})
						:Times(0)			
					end
				--End NegativeResponseCheck.2.3
				
				-----------------------------------------------------------------------------------------
				
				--Begin NegativeResponseCheck.2.4
				--Description: Check response with empty VehicleDataType
					function Test: SubscribeVehicleData_ResponseEmptyVehicleDataType()					
						--mobile side: sending SubscribeVehicleData request
						local cid = self.mobileSession:SendRPC("SubscribeVehicleData",
																					{
																						gps = true
																					})
						
						--hmi side: expect SubscribeVehicleData request
						EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData",{gps = true})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.SubscribeVehicleData response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {gps= {resultCode = "SUCCESS", dataType = ""}})	
						end)
						
						--mobile side: expect SubscribeVehicleData response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange",{})
						:Times(0)			
					end
				--End NegativeResponseCheck.2.4
				
				-----------------------------------------------------------------------------------------
				
				--Begin NegativeResponseCheck.2.5
				--Description: Check response missing all parameter
					function Test: SubscribeVehicleData_ResponseMissingAllParams()					
						--mobile side: sending SubscribeVehicleData request
						local cid = self.mobileSession:SendRPC("SubscribeVehicleData",
																					{
																						gps = true
																					})
						
						--hmi side: expect SubscribeVehicleData request
						EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData",{gps = true})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.SubscribeVehicleData response
							self.hmiConnection:Send({})
						end)
						
						--mobile side: expect SubscribeVehicleData response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})	
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange",{})
						:Times(0)		
					end
				--End NegativeResponseCheck.2.5
				
				-----------------------------------------------------------------------------------------
				
				--Begin NegativeResponseCheck.2.6
				--Description: Check response without method
					function Test: SubscribeVehicleData_ResponseMissingMethod()					
						--mobile side: sending SubscribeVehicleData request
						local cid = self.mobileSession:SendRPC("SubscribeVehicleData",
																					{
																						gps = true
																					})
						
						--hmi side: expect SubscribeVehicleData request
						EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData",{gps = true})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.SubscribeVehicleData response
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"code":0,"gps":{"dataType":"VEHICLEDATA_GPS","resultCode":"SUCCESS"}}')							
						end)
						
						--mobile side: expect SubscribeVehicleData response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange",{})
						:Times(0)			
					end
				--End NegativeResponseCheck.2.6
				
				-----------------------------------------------------------------------------------------
				
				--Begin NegativeResponseCheck.2.7
				--Description: Check response without resultCode
					function Test: SubscribeVehicleData_ResponseMissingResultCode()					
						--mobile side: sending SubscribeVehicleData request
						local cid = self.mobileSession:SendRPC("SubscribeVehicleData",
																					{
																						gps = true
																					})
						
						--hmi side: expect SubscribeVehicleData request
						EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData",{gps = true})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.SubscribeVehicleData response
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"gps":{"dataType":"VEHICLEDATA_GPS","resultCode":"SUCCESS"},"method":"VehicleInfo.SubscribeVehicleData"}}')
						end)
						
						--mobile side: expect SubscribeVehicleData response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange",{})
						:Times(0)			
					end
				--End NegativeResponseCheck.2.7
				
				-----------------------------------------------------------------------------------------
				
				--Begin NegativeResponseCheck.2.8
				--Description: Check response without VehicleDataResultCode
					function Test: SubscribeVehicleData_ResponseMissingVehicleDataResultCode()					
						--mobile side: sending SubscribeVehicleData request
						local cid = self.mobileSession:SendRPC("SubscribeVehicleData",
																					{
																						gps = true
																					})
						
						--hmi side: expect SubscribeVehicleData request
						EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData",{gps = true})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.SubscribeVehicleData response
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"code":0,"gps":{"dataType":"VEHICLEDATA_GPS"},"method":"VehicleInfo.SubscribeVehicleData"}}')
						end)
						
						--mobile side: expect SubscribeVehicleData response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange",{})
						:Times(0)			
					end
				--End NegativeResponseCheck.2.8
				
				-----------------------------------------------------------------------------------------
				
				--Begin NegativeResponseCheck.2.9
				--Description: Check response without VehicleDataType
					function Test: SubscribeVehicleData_ResponseMissingVehicleDataType()					
						--mobile side: sending SubscribeVehicleData request
						local cid = self.mobileSession:SendRPC("SubscribeVehicleData",
																					{
																						gps = true
																					})
						
						--hmi side: expect SubscribeVehicleData request
						EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData",{gps = true})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.SubscribeVehicleData response
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"code":0,"gps":{"resultCode":"SUCCESS"},"method":"VehicleInfo.SubscribeVehicleData"}}')
						end)
						
						--mobile side: expect SubscribeVehicleData response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange",{})
						:Times(0)			
					end
				--End NegativeResponseCheck.2.9				
				
				-----------------------------------------------------------------------------------------
				
				--Begin NegativeResponseCheck.2.10
				--Description: Check response without mandatory parameter
					function Test: SubscribeVehicleData_ResponseMissingMandatory()					
						--mobile side: sending SubscribeVehicleData request
						local cid = self.mobileSession:SendRPC("SubscribeVehicleData",
																					{
																						gps = true
																					})
						
						--hmi side: expect SubscribeVehicleData request
						EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData",{gps = true})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.SubscribeVehicleData response
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{info = "abc"}}')
						end)
						
						--mobile side: expect SubscribeVehicleData response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange",{})
						:Times(0)			
					end
				--End NegativeResponseCheck.2.10
			--End Test case NegativeResponseCheck.2

			-----------------------------------------------------------------------------------------
			
			--Begin Test case NegativeResponseCheck.3
			--Description: Check processing response with parameters with wrong data type 

				--Requirement id in JAMA:
					--SDLAQ-CRS-90
					--SDLAQ-CRS-1097
					
				--Verification criteria:
					-- The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode. The appropriate parameters sent in the request are returned with the data about subscription.
					-- SDL re-sends vehicleDataResult received from HMI for every of parameters being subscribed (that is, parameters that are present in corresponding SubscribeVehicleData request).

				--Begin Test case NegativeResponseCheck.3.1
				--Description: Check response with wrong type of method
					function Test:SubscribeVehicleData_ResponseWrongTypeMethod() 
						--mobile side: sending SubscribeVehicleData request
						local cid = self.mobileSession:SendRPC("SubscribeVehicleData",
																					{
																						gps = true
																					})
						
						--hmi side: expect SubscribeVehicleData request
						EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData",{gps = true})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.SubscribeVehicleData response
							self.hmiConnection:SendResponse(data.id, 1234, "SUCCESS", {gps= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_GPS"}})	
						end)
						
						--mobile side: expect SubscribeVehicleData response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange",{})
						:Times(0)
					end				
				--End Test case NegativeResponseCheck.3.1
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.3.2
				--Description: Check response with wrong type of resultCode
					function Test:SubscribeVehicleData_ResponseWrongTypeResultCode() 
						--mobile side: sending SubscribeVehicleData request
						local cid = self.mobileSession:SendRPC("SubscribeVehicleData",
																					{
																						gps = true
																					})
						
						--hmi side: expect SubscribeVehicleData request
						EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData",{gps = true})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.SubscribeVehicleData response
							self.hmiConnection:SendResponse(data.id, data.method, 123, {gps= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_GPS"}})	
						end)
						
						--mobile side: expect SubscribeVehicleData response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange",{})
						:Times(0)
					end				
				--End Test case NegativeResponseCheck.3.2
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.3.3
				--Description: Check response with wrong type of vehicleData
					function Test:SubscribeVehicleData_ResponseWrongTypeVehicleData() 
						--mobile side: sending SubscribeVehicleData request
						local cid = self.mobileSession:SendRPC("SubscribeVehicleData",
																					{
																						gps = true
																					})
						
						--hmi side: expect SubscribeVehicleData request
						EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData",{gps = true})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.SubscribeVehicleData response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {gps= 123})	
						end)
						
						--mobile side: expect SubscribeVehicleData response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange",{})
						:Times(0)
					end				
				--End Test case NegativeResponseCheck.3.3
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.3.4
				--Description: Check response with wrong type of VehicleDataResultCode
					function Test:SubscribeVehicleData_ResponseWrongTypeVehicleDataResultCode() 
						--mobile side: sending SubscribeVehicleData request
						local cid = self.mobileSession:SendRPC("SubscribeVehicleData",
																					{
																						gps = true
																					})
						
						--hmi side: expect SubscribeVehicleData request
						EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData",{gps = true})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.SubscribeVehicleData response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {gps= {resultCode = 123, dataType = "VEHICLEDATA_GPS"}})	
						end)
						
						--mobile side: expect SubscribeVehicleData response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange",{})
						:Times(0)
					end				
				--End Test case NegativeResponseCheck.3.4
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.3.5
				--Description: Check response with wrong type of VehicleDataType
					function Test:SubscribeVehicleData_ResponseWrongTypeVehicleDataType() 
						--mobile side: sending SubscribeVehicleData request
						local cid = self.mobileSession:SendRPC("SubscribeVehicleData",
																					{
																						gps = true
																					})
						
						--hmi side: expect SubscribeVehicleData request
						EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData",{gps = true})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.SubscribeVehicleData response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {gps= {resultCode = "SUCCESS", dataType = 123}})	
						end)
						
						--mobile side: expect SubscribeVehicleData response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange",{})
						:Times(0)
					end				
				--End Test case NegativeResponseCheck.3.5				
			--End Test case NegativeResponseCheck.3

			-----------------------------------------------------------------------------------------
			
			--Begin Test case NegativeResponseCheck.4
			--Description: Invalid JSON

				--Requirement id in JAMA:
					--SDLAQ-CRS-90
					--SDLAQ-CRS-1097
					
				--Verification criteria:
					-- The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode. The appropriate parameters sent in the request are returned with the data about subscription.
					-- SDL re-sends vehicleDataResult received from HMI for every of parameters being subscribed (that is, parameters that are present in corresponding SubscribeVehicleData request).
	
					function Test: SubscribeVehicleData_ResponseInvalidJson()	
						--mobile side: sending SubscribeVehicleData request
						local cid = self.mobileSession:SendRPC("SubscribeVehicleData",
																					{
																						gps = true
																					})
						
						--hmi side: expect SubscribeVehicleData request
						EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData",{gps = true})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.SubscribeVehicleData response
							--<<!-- missing ':'
							self.hmiConnection:Send('{"id" '..tostring(data.id)..',"jsonrpc":"2.0","result":{"code":0,"gps":{"dataType":"VEHICLEDATA_GPS","resultCode":"SUCCESS"},"method":"VehicleInfo.SubscribeVehicleData"}}')
						end)
						
						--mobile side: expect SubscribeVehicleData response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange",{})
						:Times(0)						
					end				
				
			--End Test case NegativeResponseCheck.4
--]]			
			-----------------------------------------------------------------------------------------
			
			--Begin Test case NegativeResponseCheck.5
			--Description: SDL behaviour: cases when SDL must transfer "info" parameter via corresponding RPC to mobile app

				--Requirement id in JAMA/or Jira ID: 
					--SDLAQ-CRS-90
					--APPLINK-13276
					--APPLINK-14551
					
				--Description:
					-- In case "message" is empty - SDL should not transfer it as "info" to the app ("info" needs to be omitted)
					-- In case info out of upper bound it should truncate to 1000 symbols
					-- SDL should not send "info" to app if received "message" is invalid
					-- SDL should not send "info" to app if received "message" contains newline "\n" or tab "\t" symbols.
					
				--Begin Test Case NegativeResponseCheck5.1
				--Description: Check response with empty info
					function Test: SubscribeVehicleData_ResponseInfoOutLowerBound()	
						--mobile side: sending SubscribeVehicleData request
						local cid = self.mobileSession:SendRPC("SubscribeVehicleData",
																					{
																						gps = true
																					})
						
						--hmi side: expect SubscribeVehicleData request
						EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData",{gps = true})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.SubscribeVehicleData response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {message = "", gps= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_GPS"}})	
						end)
						
						--mobile side: expect SubscribeVehicleData response
						EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS", gps= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_GPS"}})
						:ValidIf (function(_,data)
							if data.payload.info then
								print(" \27[36m SDL resend invalid info to mobile app \27[0m")
								return false
							else 
								return true
							end
						end)
						
						--mobile side: expect OnHashChange notification
						EXPECT_NOTIFICATION("OnHashChange")
					end
					function Test:PostCondition_UnSubscribeVehicleData()				
						self:unSubscribeVehicleDataSuccess(vehicleData)
					end
				--End Test Case NegativeResponseCheck5.1
				
				-----------------------------------------------------------------------------------------
			--TODO: update after resolving APPLINK-14551
				-- --Begin Test Case NegativeResponseCheck5.2
				-- --Description: Check response with info out upper bound
				-- 	function Test: SubscribeVehicleData_ResponseInfoOutUpperBound()	
				-- 		--mobile side: sending SubscribeVehicleData request
				-- 		local cid = self.mobileSession:SendRPC("SubscribeVehicleData",
				-- 																	{
				-- 																		gps = true
				-- 																	})
						
				-- 		--hmi side: expect SubscribeVehicleData request
				-- 		EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData",{gps = true})					
				-- 		:Do(function(_,data)
				-- 			--hmi side: sending VehicleInfo.SubscribeVehicleData response
				-- 			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {message = infoMessageValue.."a",gps= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_GPS"}})	
				-- 		end)
						
				-- 		--mobile side: expect SubscribeVehicleData response
				-- 		EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS", gps= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_GPS"}, info = infoMessageValue})						
												
				-- 		--mobile side: expect OnHashChange notification
				-- 		EXPECT_NOTIFICATION("OnHashChange")
				-- 	end
				-- 	function Test:PostCondition_UnSubscribeVehicleData()				
				-- 		self:unSubscribeVehicleDataSuccess(vehicleData)
				-- 	end
				-- --End Test Case NegativeResponseCheck5.2
						
				-----------------------------------------------------------------------------------------
					
				--Begin Test Case NegativeResponseCheck5.3
				--Description: Check response with wrong type info
					function Test: SubscribeVehicleData_ResponseInfoWrongType()	
						--mobile side: sending SubscribeVehicleData request
						local cid = self.mobileSession:SendRPC("SubscribeVehicleData",
																					{
																						gps = true
																					})
						
						--hmi side: expect SubscribeVehicleData request
						EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData",{gps = true})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.SubscribeVehicleData response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {message = 1234, gps= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_GPS"}})	
						end)
						
						--mobile side: expect SubscribeVehicleData response
						EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS", gps= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_GPS"}})
						:ValidIf (function(_,data)
							if data.payload.info then
								print(" \27[36m SDL resend invalid info to mobile app \27[0m")
								return false
							else 
								return true
							end
						end)
						
						--mobile side: expect OnHashChange notification
						EXPECT_NOTIFICATION("OnHashChange")
					end
					function Test:PostCondition_UnSubscribeVehicleData()				
						self:unSubscribeVehicleDataSuccess(vehicleData)
					end
				--End Test Case NegativeResponseCheck5.3
								
				-----------------------------------------------------------------------------------------
					
				--Begin Test Case NegativeResponseCheck5.4
				--Description: Check response with info have escape sequence \n 
					function Test: SubscribeVehicleData_ResponseInfoNewLineChar()	
						--mobile side: sending SubscribeVehicleData request
						local cid = self.mobileSession:SendRPC("SubscribeVehicleData",
																					{
																						gps = true
																					})
						
						--hmi side: expect SubscribeVehicleData request
						EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData",{gps = true})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.SubscribeVehicleData response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {message = "New line \n", gps= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_GPS"}})	
						end)
						
						--mobile side: expect SubscribeVehicleData response
						EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS", gps= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_GPS"}})
						:ValidIf (function(_,data)
							if data.payload.info then
								print(" \27[36m SDL resend invalid info to mobile app \27[0m")
								return false
							else 
								return true
							end
						end)
						
						--mobile side: expect OnHashChange notification
						EXPECT_NOTIFICATION("OnHashChange")
					end
					function Test:PostCondition_UnSubscribeVehicleData()				
						self:unSubscribeVehicleDataSuccess(vehicleData)
					end
				--End Test Case NegativeResponseCheck5.4
								
				-----------------------------------------------------------------------------------------
					
				--Begin Test Case NegativeResponseCheck5.5
				--Description: Check response with info have escape sequence \t
					function Test: SubscribeVehicleData_ResponseInfoNewTabChar()	
						--mobile side: sending SubscribeVehicleData request
						local cid = self.mobileSession:SendRPC("SubscribeVehicleData",
																					{
																						gps = true
																					})
						
						--hmi side: expect SubscribeVehicleData request
						EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData",{gps = true})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.SubscribeVehicleData response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {message = "New tab \t", gps= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_GPS"}})	
						end)
						
						--mobile side: expect SubscribeVehicleData response
						EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS", gps= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_GPS"}})
						:ValidIf (function(_,data)
							if data.payload.info then
								print(" \27[36m SDL resend invalid info to mobile app \27[0m")
								return false
							else 
								return true
							end
						end)
						
						--mobile side: expect OnHashChange notification
						EXPECT_NOTIFICATION("OnHashChange")
					end
					function Test:PostCondition_UnSubscribeVehicleData()				
						self:unSubscribeVehicleDataSuccess(vehicleData)
					end
				--End Test Case NegativeResponseCheck5.5									
			--End Test case NegativeResponseCheck.5
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

			--Requirement id in JAMA: SDLAQ-CRS-577

			--Verification criteria: 
				--A request SubscribeVehicleData is sent under conditions of RAM deficit for executing it. The OUT_OF_MEMORY response code is returned. 
			
			--Not applicable
			
		--End Test case ResultCodeCheck.1
		
		-----------------------------------------------------------------------------------------
		
		--Begin Test case ResultCodeCheck.2
		--Description: Check of TOO_MANY_PENDING_REQUESTS result code

			--Requirement id in JAMA: SDLAQ-CRS-578

			--Verification criteria: 
				--The system has more than 1000 requests  at a time that haven't been responded yet.
				--The system sends the responses with TOO_MANY_PENDING_REQUESTS error code for all further requests until there are less than 1000 requests at a time that haven't been responded by the system yet.
			
			--Moved to ATF_SubscribeVehicleData_TOO_MANY_PENDING_REQUESTS.lua
			
		--End Test case ResultCodeCheck.2

		-----------------------------------------------------------------------------------------
		
		--Begin Test case ResultCodeCheck.3
		--Description: Check APPLICATION_NOT_REGISTERED result code 

			--Requirement id in JAMA: SDLAQ-CRS-579

			--Verification criteria: 
				-- SDL returns APPLICATION_NOT_REGISTERED code for the request sent within the same connection before RegisterAppInterface has been performed yet.
			function Test:Precondition_CreationNewSession()
				-- Connected expectation
			  	self.mobileSession2 = mobile_session.MobileSession(
			    self,
			    self.mobileConnection)			   
			end
			for i=1, #allVehicleData do
				Test["SubscribeVehicleData_ApplicationNotRegister_"..allVehicleData[i]] = function(self)					
					local temp = {}
					temp[allVehicleData[i]] = true
					--mobile side: sending SubscribeVehicleData request					
					local cid = self.mobileSession2:SendRPC("SubscribeVehicleData",temp)
					
					--mobile side: expected SubscribeVehicleData response
					self.mobileSession2:ExpectResponse(cid, { success = false, resultCode = "APPLICATION_NOT_REGISTERED" })
						
					--mobile side: expect OnHashChange notification is not send to mobile
					self.mobileSession2:ExpectNotification("OnHashChange", {})
					:Times(0)
				end
			end					
		--End Test case ResultCodeCheck.3			
		
		-----------------------------------------------------------------------------------------
--[==[TODO: check after ATF defect APPLINK-13101 resolved		
		--Begin Test case ResultCodeCheck.4
		--Description: Check IGNORED result code with success false

			--Requirement id in JAMA: SDLAQ-CRS-581, APPLINK-8673

			--Verification criteria: 
			--[[
				1. In case an application sends SubscribeVehicleData request for previously subscribed VehicleData, SDL returns the IGNORED resultCode to mobile side. General result is success=false.

				2.
				Pre-conditions:
				a) HMI and SDL are started.
				b) Device is consented by the User.
				c) App (running on this device) is registered.
				d) "<appID>" section in Local PT has "DrivingCharacteristics-3" in "groups" section.
				e) "DrivingCharacteristics-3" has "SubscribeVehicleData":sub-section with the following parameters (meaning only these params are allowed by Policies):
				"parameters": ["accPedalPosition", "beltStatus", "driverBraking", "myKey", "prndl", "rpm", "steeringWheelAngle"]

				app->SDL: SubscribeVehicleData("prndl", "speed") //prndl is subscribed already
				SDL->app: SubscribeVehicleData (speed: (dataType: VEHICLEDATA_PRNDL, resultCode: DATA_ALREADY_SUBSCRIBED), gps: (dataType: VEHICLEDATA_SPEED, resultCode: DISALLOWED), resultCode: IGNORED, success: false, info: "'prndl' is subscribed already, 'speed' is disallowed by policies")
			--]]
			--Begin Test Case ResultCodeCheck.4.1
			--Description: SubscribeVehicleData request for previously subscribed VehicleData
				for i=1, #allVehicleData do
					Test["Precondition_Subscribe"..allVehicleData[i]] = function(self)						
						self:subscribeVehicleDataSuccess({allVehicleData[i]})
					end				
					Test["SubscribeVehicleData_PreviouslySubscribed_"..allVehicleData[i]] = function(self)					
						self:subscribeVehicleDataIgnored({allVehicleData[i]})
					end
				end
				function Test:PostCondition_UnSubscribeVehicleData()				
					self:unSubscribeVehicleDataSuccess(allVehicleData)
				end
			--End Test Case ResultCodeCheck.4.1
			
			-----------------------------------------------------------------------------------------
			
			--Begin Test Case ResultCodeCheck.4.2
			--Description: SubscribeVehicleData request for previously subscribed VehicleData and non-subscribed 				
				function Test: Precondition_SubscribeGPS()
					--SubscribeVehicleData gps
					self:subscribeVehicleDataSuccess({"gps"})
				end				
				function Test: SubscribeVehicleData_SubscribedAndNonSubscribed()
					--mobile side: sending SubscribeVehicleData request
					local cid = self.mobileSession:SendRPC("SubscribeVehicleData",
																				{
																					gps = true,
																					speed = true
																				})					
					
					--hmi side: expect SubscribeVehicleData request
					EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData",{
																		speed = true
																	})					
					:Do(function(_,data)
						--hmi side: sending VehicleInfo.SubscribeVehicleData response						
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {speed= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_SPEED"}})	
					end)
					:ValidIf (function(_,data)
			    		if data.params.gps then
			    			print(" \27[36m SDL send subscribed vehicleData to HMI \27[0m")
			    			return false
			    		else 
			    			return true
			    		end
			    	end)
										
					--mobile side: expect SubscribeVehicleData response
					EXPECT_RESPONSE(cid, {success = false, resultCode = "IGNORED", 
											gps= {resultCode = "DATA_ALREADY_SUBSCRIBED", dataType = "VEHICLEDATA_GPS"},
											speed= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_SPEED"},
											info = "Already subscribed on some provided VehicleData."})
						
					--mobile side: expect OnHashChange notification is not send to mobile
					EXPECT_NOTIFICATION("OnHashChange",{})
					:Times(0)
				end
				function Test:PostCondition_UnSubscribeVehicleData()				
					self:unSubscribeVehicleDataSuccess({"speed"},{"gps"})
				end
			--End Test Case ResultCodeCheck.4.2
			
			-----------------------------------------------------------------------------------------
			
			--Begin Test Case ResultCodeCheck.4.3
			--Description: SubscribeVehicleData request for previously subscribed VehicleData and disallowed by policies
				function Test:Precondition_PolicyUpdate()
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
							"files/PTU_ForSubscribeVehicleData.json")
							
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
										self.hmiConnection:SendNotification("SDL.OnAppPermissionConsent", { appID =  self.applications["Test Application"], consentedFunctions = {{ allowed = true, id = 193465391, name = "New"}}, source = "GUI"})
										end)
								end)
							end)
							
						end)
					end)
				end
				
				function Test: Precondition_Subscribe_prndl()
					--SubscribeVehicleData prndl
					self:subscribeVehicleDataSuccess({"prndl"})
				end
				
				function Test: SubscribeVehicleData_SubscribedAndDisallowed()
					--mobile side: sending SubscribeVehicleData request
					local cid = self.mobileSession:SendRPC("SubscribeVehicleData",
																				{
																					prndl = true,
																					speed = true
																				})					
										
					--hmi side: expect SubscribeVehicleData request
					EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData",{
																		prndl = true,
																		speed = true
																	})					
					:Times(0)
					
					--mobile side: expect SubscribeVehicleData response
					EXPECT_RESPONSE(cid, {success = false, resultCode = "IGNORED", 
											prndl= {resultCode = "DATA_ALREADY_SUBSCRIBED", dataType = "VEHICLEDATA_PRNDL"},
											speed= {resultCode = "DISALLOWED", dataType = "VEHICLEDATA_SPEED"},
											info = "'prndl' is subscribed already, 'speed' is disallowed by policies"})	
						
					--mobile side: expect OnHashChange notification is not send to mobile
					EXPECT_NOTIFICATION("OnHashChange",{})
					:Times(0)
				end
				function Test:PostCondition_UnSubscribeVehicleData()				
					self:unSubscribeVehicleDataSuccess({"prndl"})
				end
			--End Test Case ResultCodeCheck.4.3
		--End Test case ResultCodeCheck.4		
--]==]
		-----------------------------------------------------------------------------------------
		
		--Begin Test case ResultCodeCheck.5
		--Description: Check GENERIC_ERROR result code with success false

			--Requirement id in JAMA: SDLAQ-CRS-583

			--Verification criteria: 
				-- GENERIC_ERROR comes as a result code in response when all other codes aren't applicable or the unknown issue occurred.
				-- In case SubbscribeVehicleData is allowed by policies with less than supported by protocol parameters AND the app assigned with such policies requests SubscribeVehicleData with one and-or more allowed params and with one and-or more NOT-allowed params, SDL must process the allowed params of SubscribeVehicleData and return appropriate error code AND add the individual results of DISALLOWED for NOT-allowed params of SubscribeVehicleData to response to mobile app + "ResultCode: <applicable-result-code>, success: <applicable flag>" + "info" parameter listing the params disallowed by policies and the information about allowed params processing.
				
			--Begin Test Case ResultCodeCheck.5.1
			--Description: Check GENERIC_ERROR result code for the RPC from HMI
				function Test: SubscribeVehicleData_GENERIC_ERROR_FromHMI()
					--mobile side: sending SubscribeVehicleData request
					local cid = self.mobileSession:SendRPC("SubscribeVehicleData",
																				{
																					myKey = true
																				})					
					
					
					--hmi side: expect SubscribeVehicleData request
					EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData",{
																		myKey = true
																	})					
					:Do(function(_,data)
						--hmi side: sending VehicleInfo.SubscribeVehicleData response						
						self.hmiConnection:SendResponse(data.id, data.method, "GENERIC_ERROR", {myKey= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_MYKEY"}})	
					end)					
					
					--mobile side: expect SubscribeVehicleData response
					EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", 
						myKey= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_MYKEY"}})
					
					--mobile side: expect OnHashChange notification
					EXPECT_NOTIFICATION("OnHashChange",{})
					:Times(0)
				end			
			--End Test Case ResultCodeCheck.5.1

			--TODO: remove postcondition after resolving APPLINK-15019
			function Test:PostCondition_UnSubscribeVehicleData()				
				self:unSubscribeVehicleDataSuccess({"myKey"})
			end
			
			-----------------------------------------------------------------------------------------
--[[TODO: check after ATF defect APPLINK-13101 resolved				
			--Begin Test Case ResultCodeCheck.5.2
			--Description: Check GENERIC_ERROR result code for the RPC from HMI with individual results of DISALLOWED 
				function Test: SubscribeVehicleData_GENERIC_ERROR()
					--mobile side: sending SubscribeVehicleData request
					local cid = self.mobileSession:SendRPC("SubscribeVehicleData",
																				{																					
																					speed = true,
																					myKey = true
																				})					
					
					
					--hmi side: expect SubscribeVehicleData request
					EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData",{
																		myKey = true
																	})					
					:Do(function(_,data)
						--hmi side: sending VehicleInfo.SubscribeVehicleData response						
						self.hmiConnection:SendResponse(data.id, data.method, "GENERIC_ERROR", {myKey= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_MYKEY"}})	
					end)
					:ValidIf (function(_,data)
			    		if data.params.speed then
			    			print(" \27[36m SDL send disallowed vehicleData to HMI \27[0m")
			    			return false
			    		else 
			    			return true
			    		end
			    	end)
					
					--mobile side: expect SubscribeVehicleData response
					EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", 
						myKey= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_MYKEY"},
						speed= {resultCode = "DISALLOWED", dataType = "VEHICLEDATA_SPEED"},
						info = "'speed' is disallowed by policies."})
					:Timeout(5000)
					
					--mobile side: expect OnHashChange notification
					EXPECT_NOTIFICATION("OnHashChange",{})
					:Times(0)
				end
			--End Test Case ResultCodeCheck.5.2	
		--End Test case ResultCodeCheck.5
		
		-----------------------------------------------------------------------------------------
	
		--Begin Test case ResultCodeCheck.6
		--Description: Check DISALLOWED, USER_DISALLOWED result code with success false

			--Requirement id in JAMA: SDLAQ-CRS-582, SDLAQ-CRS-2396, SDLAQ-CRS-2397, APPLINK-8673, SDLAQ-CRS-594

			--Verification criteria: 
				--  SDL must return "resultCode: DISALLOWED, success:false" to the RPC in case this RPC is omitted in the PolicyTable group(s) assigned to the app that requests this RPC.
				--  SDL must return "resultCode: DISALLOWED, success:false" to the RPC in case this RPC is included to the PolicyTable group(s) assigned to the app that requests this RPC and the group has not yet received user's consents.
				--  In case SubscribeVehicleData RPC is allowed by policies with less than supported by protocol parameters AND the app assigned with such policies requests SubscribeVehicleData with one and-or more NOT-allowed params only, SDL must NOT send anything to HMI, AND return the individual results of DISALLOWED to response to mobile app + "ResultCode:DISALLOWED, success: false".
			--Begin Test Case ResultCodeCheck.6.1
			--Description: SubscribeVehicleData is omitted in the PolicyTable group(s) assigned to the app that requests this RPC.
				function Test:Precondition_PolicyUpdate()
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
							"files/PTU_OmittedSubscribeVehicleData.json")
							
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
										self.hmiConnection:SendNotification("SDL.OnAppPermissionConsent", { appID =  self.applications["Test Application"], consentedFunctions = {{ allowed = true, id = 193465391, name = "New"}}, source = "GUI"})
										end)
								end)
							end)
							
						end)
					end)
				end
								
				function Test:SubscribeVehicleData_RPCOmitted()
					--mobile side: sending SubscribeVehicleData request
					local cid = self.mobileSession:SendRPC("SubscribeVehicleData",
																				{
																					speed = true,
																					gps = true
																				})					
										
					--hmi side: expect SubscribeVehicleData request
					EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData",{
																		speed = true,
																		gps = true
																		
																	})					
					:Times(0)
					
					--mobile side: expect SubscribeVehicleData response
					EXPECT_RESPONSE(cid, {success = false, resultCode = "DISALLOWED"})	
						
					--mobile side: expect OnHashChange notification is not send to mobile
					EXPECT_NOTIFICATION("OnHashChange",{})
					:Times(0)				
				end				
			--End Test Case ResultCodeCheck.6.1
			
			-----------------------------------------------------------------------------------------

			--Begin Test Case ResultCodeCheck.6.2
			--Description: SubscribeVehicleData has not yet received user's consents
				function Test:Precondition_PolicyUpdate()
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
							"files/PTU_ForSubscribeVehicleData.json")
							
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
										self.hmiConnection:SendNotification("SDL.OnAppPermissionConsent", { appID =  self.applications["Test Application"], consentedFunctions = {{ allowed = false, id = 193465391, name = "New"}}, source = "GUI"})
										end)
								end)
							end)
							
						end)
					end)
				end
								
				function Test:SubscribeVehicleData_UserDisallowed()
					--mobile side: sending SubscribeVehicleData request
					local cid = self.mobileSession:SendRPC("SubscribeVehicleData",
																				{
																					prndl = true,
																					myKey = true
																				})					
										
					--hmi side: expect SubscribeVehicleData request
					EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData",{
																		prndl = true
																	})					
					:Times(0)
					
					--hmi side: expect SubscribeVehicleData request
					EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData",{
																		myKey = true
																	})					
					:Times(0)
					
					--mobile side: expect SubscribeVehicleData response
					EXPECT_RESPONSE(cid, {success = false, resultCode = "USER_DISALLOWED"})	
					
					--mobile side: expect OnHashChange notification
					EXPECT_NOTIFICATION("OnHashChange", {})
					:Times(0)
				end				
			--End Test Case ResultCodeCheck.6.2		
			
			-----------------------------------------------------------------------------------------

			--Begin Test Case ResultCodeCheck.6.3
			--Description: Two vehicleData is disallowed
				function Test:Precondition_EnableSubscribeVehicleData()					
					self.hmiConnection:SendNotification("SDL.OnAppPermissionConsent", { appID =  self.applications["Test Application"], consentedFunctions = {{ allowed = true, id = 193465391, name = "New"}}, source = "GUI"})		  
				end
								
				function Test:SubscribeVehicleData_Disallowed()
					--mobile side: sending SubscribeVehicleData request
					local cid = self.mobileSession:SendRPC("SubscribeVehicleData",
																				{
																					speed = true,
																					gps = true
																				})					
										
					--hmi side: expect SubscribeVehicleData request
					EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData",{
																		speed = true
																	})					
					:Times(0)
					
					--hmi side: expect SubscribeVehicleData request
					EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData",{
																		gps = true
																	})					
					:Times(0)
					
					--mobile side: expect SubscribeVehicleData response
					EXPECT_RESPONSE(cid, {success = false, resultCode = "DISALLOWED",
										speed= {resultCode = "DISALLOWED", dataType = "VEHICLEDATA_SPEED"},
										gps= {resultCode = "DISALLOWED", dataType = "VEHICLEDATA_GPS"},
										info = "'speed' is disallowed by policies.'gps' is disallowed by policies."})
										
					--mobile side: expect OnHashChange notification
					EXPECT_NOTIFICATION("OnHashChange", {})
					:Times(0)
				end				
			--End Test Case ResultCodeCheck.6.3
			
			-----------------------------------------------------------------------------------------
			
			--Begin Test Case ResultCodeCheck.6.4
			--Description: One vehicleData is disallowed and one vehicleData is user disallowed
				function Test:Precondition_UserDissallowedSubscribeVehicleData()					
					self.hmiConnection:SendNotification("SDL.OnAppPermissionConsent", { appID =  self.applications["Test Application"], consentedFunctions = {{ allowed = false, id = 193465391, name = "New"}}, source = "GUI"})					
				end				
				
				function Test:SubscribeVehicleData_DisallowedAndUserDisallowed()
					--mobile side: sending SubscribeVehicleData request
					local cid = self.mobileSession:SendRPC("SubscribeVehicleData",
																				{
																					speed = true,
																					myKey = true
																				})					
										
					--hmi side: expect SubscribeVehicleData request
					EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData",{
																		speed = true,
																		myKey = true
																	})					
					:Times(0)
					
					--mobile side: expect SubscribeVehicleData response
					EXPECT_RESPONSE(cid, {success = false, resultCode = "DISALLOWED",
										speed= {resultCode = "DISALLOWED", dataType = "VEHICLEDATA_SPEED"},
										myKey= {resultCode = "USER_DISALLOWED", dataType = "VEHICLEDATA_MYKEY"},
										info = "'speed' is disallowed by policies.'myKey' is disallowed by policies."})
										
					--mobile side: expect OnHashChange notification
					EXPECT_NOTIFICATION("OnHashChange",{})
					:Times(0)
				end				
			--End Test Case ResultCodeCheck.6.4
			
			-----------------------------------------------------------------------------------------
			
			--Begin Test Case ResultCodeCheck.6.5
			--Description: One vehicleData is SUCCESS and one vehicleData is user disallowed
				function Test:Precondition_AllowedAndUserDisallowedSVD()					
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
							"files/PTU_AllowedAndUserDisallowedSVD.json")
							
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
										self.hmiConnection:SendNotification("SDL.OnAppPermissionConsent", { appID =  self.applications["Test Application"], consentedFunctions = {{ allowed = false, id = 193465391, name = "New"}}, source = "GUI"})
										end)
								end)
							end)
							
						end)
					end)
				end				
				
				function Test:SubscribeVehicleData_SuccessAndUserDisallowed()
					--mobile side: sending SubscribeVehicleData request
					local cid = self.mobileSession:SendRPC("SubscribeVehicleData",
																				{
																					speed = true,
																					myKey = true
																				})					
					
					--hmi side: expect SubscribeVehicleData request
					EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData",{
																		speed = true
																	})					
					:Do(function(_,data)
						--hmi side: sending VehicleInfo.SubscribeVehicleData response						
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {speed= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_SPEED"}})	
					end)
					:ValidIf (function(_,data)
			    		if data.params.myKey then
			    			print(" \27[36m SDL send USER_DISALLOWED vehicleData to HMI \27[0m")
			    			return false
			    		else 
			    			return true
			    		end
			    	end)
					
					--mobile side: expect SubscribeVehicleData response
					EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS",
										speed= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_SPEED"},
										myKey= {resultCode = "USER_DISALLOWED", dataType = "VEHICLEDATA_MYKEY"},
										info = "'myKey' is disallowed by policies."})
					
					--mobile side: expect OnHashChange notification
					EXPECT_NOTIFICATION("OnHashChange",{})					
				end				
			--End Test Case ResultCodeCheck.6.5
		--End Test case ResultCodeCheck.6
		
		-----------------------------------------------------------------------------------------
		
		--Begin Test case ResultCodeCheck.7
		--Description: Check REJECTED result code with success false

			--Requirement id in JAMA: SDLAQ-CRS-9079

			--Verification criteria: 
				-- In case SDL receives REJECTED result code for the RPC from HMI, SDL must transfer REJECTED resultCode with adding "success:false" to mobile app.
				-- In case SubbscribeVehicleData is allowed by policies with less than supported by protocol parameters AND the app assigned with such policies requests SubscribeVehicleData with one and-or more allowed params and with one and-or more NOT-allowed params, SDL must process the allowed params of SubscribeVehicleData and return appropriate error code AND add the individual results of DISALLOWED for NOT-allowed params of SubscribeVehicleData to response to mobile app + "ResultCode: <applicable-result-code>, success: <applicable flag>" + "info" parameter listing the params disallowed by policies and the information about allowed params processing.
				
			--Begin Test Case ResultCodeCheck.7.1
			--Description: Check REJECTED result code for the RPC from HMI
				function Test:Precondition_UserAllowedSubscribeVehicleData()					
					self.hmiConnection:SendNotification("SDL.OnAppPermissionConsent", { appID =  self.applications["Test Application"], consentedFunctions = {{ allowed = true, id = 193465391, name = "New"}}, source = "GUI"})					
				end
	--]]
				function Test: SubscribeVehicleData_REJECTED_FromHMI()
					--mobile side: sending SubscribeVehicleData request
					local cid = self.mobileSession:SendRPC("SubscribeVehicleData",
																				{
																					myKey = true
																				})					
					
					
					--hmi side: expect SubscribeVehicleData request
					EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData",{
																		myKey = true
																	})					
					:Do(function(_,data)
						--hmi side: sending VehicleInfo.SubscribeVehicleData response						
						self.hmiConnection:SendResponse(data.id, data.method, "REJECTED", {myKey= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_MYKEY"}})	
					end)					
					
					--mobile side: expect SubscribeVehicleData response
					EXPECT_RESPONSE(cid, {success = false, resultCode = "REJECTED", 
								myKey= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_MYKEY"}})
					
					--mobile side: expect OnHashChange notification
					EXPECT_NOTIFICATION("OnHashChange",{})
					:Times(0)
				end
			--End Test Case ResultCodeCheck.7.1

			--TODO: remove postcondition after resolving APPLINK-15019
			function Test:PostCondition_UnSubscribeVehicleData()				
				self:unSubscribeVehicleDataSuccess({"myKey"})
			end
			
			-----------------------------------------------------------------------------------------
--[[TODO: Check after APPLINK-14765 is resolved
			--Begin Test Case ResultCodeCheck.7.2
			--Description: Check REJECTED result code for the RPC from HMI with individual results of DISALLOWED 		
				function Test: SubscribeVehicleData_REJECTED()
					--mobile side: sending SubscribeVehicleData request
					local cid = self.mobileSession:SendRPC("SubscribeVehicleData",
																				{																					
																					odometer = true,
																					myKey = true
																				})					
					
					
					--hmi side: expect SubscribeVehicleData request
					EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData",{
																		myKey = true
																	})					
					:Do(function(_,data)
						--hmi side: sending VehicleInfo.SubscribeVehicleData response						
						self.hmiConnection:SendResponse(data.id, data.method, "REJECTED", {myKey= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_MYKEY"}})	
					end)
					
					--hmi side: expect SubscribeVehicleData request
					EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData",{
																		odometer = true
																	})
					:Times(0)
					
					--mobile side: expect SubscribeVehicleData response
					EXPECT_RESPONSE(cid, {success = false, resultCode = "REJECTED", 
						myKey= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_MYKEY"},
						odometer= {resultCode = "DISALLOWED", dataType = "VEHICLEDATA_ODOMETER"},
						info = "'odometer' disallowed by policies."})
					:Timeout(5000)
					
					--mobile side: expect OnHashChange notification
					EXPECT_NOTIFICATION("OnHashChange",{})	
					:Times(0)
				end
			--End Test Case ResultCodeCheck.7.2
--]]
		--End Test case ResultCodeCheck.7		

			-----------------------------------------------------------------------------------------
			
	local function Task_APPLINK_15934()
			--Begin Test Case ResultCodeCheck.8
			--Description: Check SUCCESS result code 
				--Precondition: Update Policy
				function Test:Precondition_PolicyUpdate()
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
							"files/PTU_ForSubscribeVehicleData.json")
							
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
										self.hmiConnection:SendNotification("SDL.OnAppPermissionConsent", { appID =  self.applications["Test Application"], consentedFunctions = {{ allowed = true, id = 193465391, name = "New"}}, source = "GUI"})
										end)
								end)
							end)
							
						end)
					end)
				end
				--End Precondition
				
				--Begin Test Case ResultCodeCheck.8.1
				--Description: General resultCode is SUCCESS if one of personal resultCode of parameter is SUCCESS and another is DISALLOWED by policy
				function Test: SubscribeVehicleData_SucessAndDisallowed()
					--mobile side: sending SubscribeVehicleData request
					local cid = self.mobileSession:SendRPC("SubscribeVehicleData",
																				{
																					prndl = true,
																					speed = true
																				})					
										
					--hmi side: expect SubscribeVehicleData request
					EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData",{
																		prndl = true																		
																	})					

					--mobile side: expect SubscribeVehicleData response
					EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS", 
											prndl= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_PRNDL"},
											speed= {resultCode = "DISALLOWED", dataType = "VEHICLEDATA_SPEED"},
											info = "'speed' is disallowed by policies"})	
						
					--mobile side: expect OnHashChange notification is sent to mobile
					EXPECT_NOTIFICATION("OnHashChange",{})
				end
				function Test:PostCondition_UnSubscribeVehicleData()				
					self:unSubscribeVehicleDataSuccess({"prndl"})
				end
				--End Test Case ResultCodeCheck.8.1
				------------------------------------------------------------------------------------------------------
				--Begin Test Case ResultCodeCheck.8.2
				--Description: General resultCode is SUCCESS if one personal resultCode of parameter is "DATA_ALREADY_SUBSCRIBED" and another is "SUCCESS".
				
				function Test: Precondition_Subscribe_prndl()
					--SubscribeVehicleData prndl
					self:subscribeVehicleDataSuccess({"prndl"})
				end
				
				function Test: SubscribeVehicleData_SuccessAndDataAreadySubscribed()
					--mobile side: sending SubscribeVehicleData request
					local cid = self.mobileSession:SendRPC("SubscribeVehicleData",
																				{
																					rpm = true,
																					prndl = true
																				})					
										
					--hmi side: expect SubscribeVehicleData request
					EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData",{
																		rpm = true,
																		prndl = true
																	})					

					--mobile side: expect SubscribeVehicleData response
					EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS", 
											rpm= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_RPM"},
											prndl= {resultCode = "DATA_ALREADY_SUBSCRIBED", dataType = "VEHICLEDATA_PRNDL"},
											info = "'prndl' is subscribed already"})	
						
					--mobile side: expect OnHashChange notification is sent to mobile
					EXPECT_NOTIFICATION("OnHashChange",{})
				end
				
				function Test:PostCondition_UnSubscribeVehicleData()				
					self:unSubscribeVehicleDataSuccess({"prndl", "rpm"})
				end
				--End Test Case ResultCodeCheck.8.2
			--End Test case ResultCodeCheck.8		
	end
	Task_APPLINK_15934()
	-------------------------------------------------------------------------------------------------------------------------
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
				--SDLAQ-CRS-583
				--APPLINK-8585				
			
			--Verification criteria:
				-- SDL must return GENERIC_ERROR result to mobile app in case one of HMI components does not respond being supported and active.
			function Test:SubscribeVehicleData_NoResponseFromHMI()
				--mobile side: sending SubscribeVehicleData request
				local cid = self.mobileSession:SendRPC("SubscribeVehicleData",
																			{
																				gps = true
																			})					
									
				
				--hmi side: expect SubscribeVehicleData request
				EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData",{
																	gps = true
																})					
				:Do(function(_,data)
					--hmi side: sending VehicleInfo.SubscribeVehicleData response						
					
				end)
				
				--mobile side: expect SubscribeVehicleData response
				EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR"})
				:Timeout(12000)
				
				--mobile side: expect OnHashChange notification
				EXPECT_NOTIFICATION("OnHashChange",{})
				:Times(0)
			end
		--End Test case HMINegativeCheck.1	

		--TODO: remove postcondition after resolving APPLINK-15019
			function Test:PostCondition_UnSubscribeVehicleData()				
				self:unSubscribeVehicleDataSuccess({"gps"})
			end
		
		-----------------------------------------------------------------------------------------
--[[TODO: update according to APPLINK-14765
		--Begin Test case HMINegativeCheck.2
		--Description: 
			-- Check processing responses with invalid structure

			--Requirement id in JAMA:
				--SDLAQ-CRS-90
				
			--Verification criteria:
				--The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode. The appropriate parameters sent in the request are returned with the data about subscription. 
			function Test: SubscribeVehicleData_ResponseInvalidStructure()
				--mobile side: sending SubscribeVehicleData request
				local cid = self.mobileSession:SendRPC("SubscribeVehicleData",
																			{
																				speed = true
																			})					
									
				
				--hmi side: expect SubscribeVehicleData request
				EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData",{
																	speed = true
																})					
				:Do(function(_,data)
					--hmi side: sending VehicleInfo.SubscribeVehicleData response						
					--Correct structure:self.hmiConnection:Send('"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"speed":{"dataType":"VEHICLEDATA_SPEED","resultCode":"SUCCESS"},"code":0, "method":"VehicleInfo.SubscribeVehicleData"}}')
					self.hmiConnection:Send('"id":'..tostring(data.id)..',"jsonrpc":"2.0","code":0,"result":{"speed":{"dataType":"VEHICLEDATA_SPEED","resultCode":"SUCCESS"},"method":"VehicleInfo.SubscribeVehicleData"}}')					
				end)
					
				--mobile side: expect SubscribeVehicleData response
				EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
				:Timeout(12000)
				
				--mobile side: expect OnHashChange notification
				EXPECT_NOTIFICATION("OnHashChange",{})
				:Times(0)
			end						
		--End Test case HMINegativeCheck.2
--]]		
		-----------------------------------------------------------------------------------------
	
		--Begin Test case HMINegativeCheck.3
		--Description: 
			-- Several response to one request

			--Requirement id in JAMA:
				--SDLAQ-CRS-90
				
			--Verification criteria:
				--The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.
			function Test:SubscribeVehicleData_SeveralResponseToOneRequest()
				--mobile side: sending SubscribeVehicleData request
				local cid = self.mobileSession:SendRPC("SubscribeVehicleData",
																			{
																				speed = true
																			})
				
				--hmi side: expect SubscribeVehicleData request
				EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData",{speed = true})					
				:Do(function(_,data)
					--hmi side: sending VehicleInfo.SubscribeVehicleData response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {speed= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_SPEED"}})	
					self.hmiConnection:SendResponse(data.id, data.method, "REJECTED", {speed= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_SPEED"}})	
					self.hmiConnection:SendResponse(data.id, data.method, "GENERIC_ERROR", {speed= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_SPEED"}})	
				end)
				
				--mobile side: expect SubscribeVehicleData response
				EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS", speed= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_SPEED"}})
				
				--mobile side: expect OnHashChange notification
				EXPECT_NOTIFICATION("OnHashChange")
			end
			function Test:PostCondition_UnSubscribeVehicleData()				
				self:unSubscribeVehicleDataSuccess({"speed"})
			end
		--End Test case HMINegativeCheck.3
		
		-----------------------------------------------------------------------------------------

		--Begin Test case HMINegativeCheck.4
		--Description: 
			-- Check processing response with fake parameters

			--Requirement id in JAMA:
				--SDLAQ-CRS-90
				
			--Verification criteria:
				--The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.
			
			--Begin Test case HMINegativeCheck.4.1
			--Description: Parameter not from API
				function Test:SubscribeVehicleData_FakeParamsInResponse()
					--mobile side: sending SubscribeVehicleData request
					local cid = self.mobileSession:SendRPC("SubscribeVehicleData",
																				{
																					gps = true
																				})
					
					--hmi side: expect SubscribeVehicleData request
					EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData",{gps = true})					
					:Do(function(_,data)
						--hmi side: sending VehicleInfo.SubscribeVehicleData response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {fake = "fakeParams", gps= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_GPS"}})							
					end)
					
					--mobile side: expect SubscribeVehicleData response
					EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS", gps= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_GPS"}})				
					:ValidIf (function(_,data)
			    		if data.payload.fake then
			    			print(" SDL resend fake parameter to mobile app ")
			    			return false
			    		else 
			    			return true
			    		end
			    	end)
					
					--mobile side: expect OnHashChange notification
					EXPECT_NOTIFICATION("OnHashChange")
				end
				function Test:PostCondition_UnSubscribeVehicleData()				
					self:unSubscribeVehicleDataSuccess(vehicleData)
				end
			--End Test case HMINegativeCheck.4.1
			
			-----------------------------------------------------------------------------------------
			
			--Begin Test case HMINegativeCheck.4.2
			--Description: Parameter from another API
				function Test:SubscribeVehicleData_ParamsFromOtherAPIInResponse()
					--mobile side: sending SubscribeVehicleData request
					local cid = self.mobileSession:SendRPC("SubscribeVehicleData",
																				{
																					gps = true
																				})
					
					--hmi side: expect SubscribeVehicleData request
					EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData",{gps = true})					
					:Do(function(_,data)
						--hmi side: sending VehicleInfo.SubscribeVehicleData response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {sliderPosition = 5, gps= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_GPS"}})							
					end)
					
					--mobile side: expect SubscribeVehicleData response
					EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS", gps= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_GPS"}})				
					:ValidIf (function(_,data)
			    		if data.payload.sliderPosition then
			    			print(" SDL resend fake parameter to mobile app ")
			    			return false
			    		else 
			    			return true
			    		end
			    	end)
					
					--mobile side: expect OnHashChange notification
					EXPECT_NOTIFICATION("OnHashChange")
				end
				function Test:PostCondition_UnSubscribeVehicleData()				
					self:unSubscribeVehicleDataSuccess(vehicleData)
				end
			--End Test case HMINegativeCheck.4.2			
		--End Test case HMINegativeCheck.4
		
		-----------------------------------------------------------------------------------------
	
		--Begin Test case HMINegativeCheck.5
		--Description: 
			-- Wrong response with correct HMI correlation id

			--Requirement id in JAMA:
				--SDLAQ-CRS-90
				
			--Verification criteria:
				--The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.			
			function Test:SubscribeVehicleData_WrongResponseToCorrectID()
				--mobile side: sending SubscribeVehicleData request
				local cid = self.mobileSession:SendRPC("SubscribeVehicleData",
																			{
																				gps = true
																			})
				
				--hmi side: expect SubscribeVehicleData request
				EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData",{gps = true})					
				:Do(function(_,data)
					--hmi side: sending VehicleInfo.SubscribeVehicleData response
					self.hmiConnection:SendResponse(data.id, "UI.AddCommand", "SUCCESS", {gps= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_GPS"}})							
				end)					
					
				--mobile side: expect SubscribeVehicleData response
				EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
				:Timeout(12000)
				
				--mobile side: expect OnHashChange notification
				EXPECT_NOTIFICATION("OnHashChange",{})
				:Times(0)
			end

			--TODO: remove postcondition after resolving APPLINK-15019
			function Test:PostCondition_UnSubscribeVehicleData()				
				self:unSubscribeVehicleDataSuccess({"gps"})
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
		--Description: Checking VEHICLE_DATA_NOT_AVAILABLE of VehicleDataResultCode
		
			--Requirement id in JAMA: 
				-- SDLAQ-CRS-1099

			--Verification criteria:
				--VEHICLE_DATA_NOT_AVAILABLE Should be returned by HMI to SDL in case the requested VehicleData cannot be subscribed because it is not available on the bus or via whatever appropriate channel. SDL must re-send this value to the corresponding app.
			function Test:SubscribeVehicleData_VehicleDataNotAvailable()
				--mobile side: sending SubscribeVehicleData request
				local cid = self.mobileSession:SendRPC("SubscribeVehicleData",
																			{
																				prndl = true
																			})
				
				--hmi side: expect SubscribeVehicleData request
				EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData",{prndl = true})					
				:Do(function(_,data)
					--hmi side: sending VehicleInfo.SubscribeVehicleData response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {prndl= {resultCode = "VEHICLE_DATA_NOT_AVAILABLE", dataType = "VEHICLEDATA_PRNDL"}})							
				end)					
					
				--mobile side: expect SubscribeVehicleData response
				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", prndl= {resultCode = "VEHICLE_DATA_NOT_AVAILABLE", dataType = "VEHICLEDATA_PRNDL"}})
				
				--mobile side: expect OnHashChange notification
				EXPECT_NOTIFICATION("OnHashChange",{})
				:Times(0)
			end	
		--End Test case SequenceCheck.1

		-----------------------------------------------------------------------------------------

		--Begin Test case SequenceCheck.2
		--Description: Subscription to the parameter already subscribed by other application
		
			--Requirement id in JAMA: 
				-- SDLAQ-CRS-3127
				-- APPLINK-13345
				-- SDLAQ-CRS-3128
				-- SDLAQ-CRS-3129
				-- SDLAQ-CRS-3130

			--Verification criteria:
				--[[ In case app_2 sends SubscribeVehicleData (param_1, param_2) to SDL AND SDL has successfully already subscribed param_1 and param_2 via SubscribeVehicleData to app_1 SDL must:
						1)  NOT send SubscribeVehicleData(param_1, param_2) to HMI.
						2) respond via SubscribeVehicleData (SUCCESS) to app_2
					In case app_1 sends SubscribeVehicleData (param_1) to SDL AND SDL does not have this param_1 in list of stored successfully subscribing params SDL must:
						transfer SubscribeVehicleData(param_1) to HMI
						in case SDL receives SUCCESS from HMI for param_1 SDL must store this param in list AND respond SubscribeVehicleData (SUCCESS) to app_1						
						respond corresponding result SUCCESS received from HMI to app_1
					In case app_2 sends SubscribeVehicleData (param_1, param_3) to SDL AND SDL already subscribes param_1 viaSubscribeVehicleData to app_1 SDL must send SubscribeVehicleData ONLY with param_3 to HMI.
					In case app_1 sends SubscribeVehicleData (param_1) to SDL AND SDL does not have this param_1 in list of stored successfully subscribing params SDL must:
						transfer SubscribeVehicleData(param_1) to HMI
						NOT store the parameter in SDL list in case SDL receives erroneous result for param_1
						respond SubscribeVehicleData (Result Code, success:false) to app_1
				--]]
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

					self.mobileSession1:ExpectNotification("OnHMIStatus",{hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE",systemContext = "MAIN"})	
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
							:Times(AnyNumber())
						end)

					end
				end)
				
				--mobile side: expect notification from 2 app
				self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
				self.mobileSession1:ExpectNotification("OnHMIStatus",{hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})					
			end
		
			--Begin Test case SequenceCheck.2.1
			--Description: App1 and App2 subscribe the same parameter
				function Test:SubscribeVehicleData_SameParamsApp1()
					--mobile side: sending SubscribeVehicleData request
					local cid = self.mobileSession:SendRPC("SubscribeVehicleData",
																				{
																					prndl = true,
																					myKey = true
																				})
					
					--hmi side: expect SubscribeVehicleData request
					EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData",{prndl = true, myKey = true})					
					:Do(function(_,data)
						--hmi side: sending VehicleInfo.SubscribeVehicleData response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
									prndl= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_PRNDL"},
									myKey= {resultCode = "VEHICLE_DATA_NOT_AVAILABLE", dataType = "VEHICLEDATA_MYKEY"}})							
					end)					
						
					--mobile side: expect SubscribeVehicleData response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", 
						prndl= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_PRNDL"},
						myKey= {resultCode = "VEHICLE_DATA_NOT_AVAILABLE", dataType = "VEHICLEDATA_MYKEY"}})
					
					--mobile side: expect OnHashChange notification
					EXPECT_NOTIFICATION("OnHashChange")
				end	
		
				function Test:SubscribeVehicleData_SameParamsApp2()
					--mobile side: sending SubscribeVehicleData request
					local cid = self.mobileSession1:SendRPC("SubscribeVehicleData",
																				{
																					prndl = true,
																					myKey = true
																				})
					
					--hmi side: expect SubscribeVehicleData request
					EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData",{myKey = true})
					:Do(function(_,data)
						--hmi side: sending VehicleInfo.SubscribeVehicleData response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {										
									myKey= {resultCode = "VEHICLE_DATA_NOT_AVAILABLE", dataType = "VEHICLEDATA_MYKEY"}})							
					end)
					:ValidIf(function(_,data)
						if data.params.prndl then
							print(" \27[36m SDL send prndl parameter to HMI \27[0m")
							return false
						else
							return true
						end
					end)					
					
					--mobile side: expect SubscribeVehicleData response
					self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS",
						prndl= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_PRNDL"},
						myKey= {resultCode = "VEHICLE_DATA_NOT_AVAILABLE", dataType = "VEHICLEDATA_MYKEY"}})						
											
					--mobile side: expect OnHashChange notification
					self.mobileSession1:ExpectNotification("OnHashChange",{})
				end
				
				function Test:PostCondition_UnSubscribeVehicleData()				
					--mobile side: sending UnsubscribeVehicleData request
					local cid1 = self.mobileSession:SendRPC("UnsubscribeVehicleData",{prndl = true})
					local cid2 = self.mobileSession1:SendRPC("UnsubscribeVehicleData",{prndl = true})
					
					--hmi side: expect UnsubscribeVehicleData request
					EXPECT_HMICALL("VehicleInfo.UnsubscribeVehicleData",{prndl = true})
					:Do(function(_,data)
						--hmi side: sending VehicleInfo.UnsubscribeVehicleData response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {prndl= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_PRNDL"}})	
					end)
					:Times(1)
					
					--mobile side: expect UnsubscribeVehicleData response
					self.mobileSession:ExpectResponse(cid1, { success = true, resultCode = "SUCCESS", prndl= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_PRNDL"}})
					self.mobileSession1:ExpectResponse(cid2, { success = true, resultCode = "SUCCESS", prndl= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_PRNDL"}})

					--mobile side: expect OnHashChange notification
					self.mobileSession:ExpectNotification("OnHashChange",{})
					self.mobileSession1:ExpectNotification("OnHashChange",{})

				end			
			--End Test case SequenceCheck.2.1
			
			-----------------------------------------------------------------------------------------

			--Begin Test case SequenceCheck.2.2
			--Description: App1 and App2 subscribe different parameter
				function Test:SubscribeVehicleData_DiffParamsApp1()
					--mobile side: sending SubscribeVehicleData request
					local cid = self.mobileSession:SendRPC("SubscribeVehicleData",
																				{
																					gps = true,
																					speed = true
																				})
					
					--hmi side: expect SubscribeVehicleData request
					EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData",{gps = true, speed = true})					
					:Do(function(_,data)
						--hmi side: sending VehicleInfo.SubscribeVehicleData response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
									gps= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_GPS"},
									speed= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_SPEED"}})							
					end)					
						
					--mobile side: expect SubscribeVehicleData response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", 
									gps= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_GPS"},
									speed= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_SPEED"}})		
					
					--mobile side: expect OnHashChange notification
					EXPECT_NOTIFICATION("OnHashChange")
				end	
				
				function Test:SubscribeVehicleData_DiffParamsApp2()
					--mobile side: sending SubscribeVehicleData request
					local cid = self.mobileSession1:SendRPC("SubscribeVehicleData",
																				{
																					prndl = true,
																					myKey = true,
																					speed = true
																				})
										
					--hmi side: expect SubscribeVehicleData request
					EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData",{myKey = true, prndl = true})					
					:Do(function(_,data)
						--hmi side: sending VehicleInfo.SubscribeVehicleData response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
									prndl= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_PRNDL"},
									myKey= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_MYKEY"}})							
					end)
					:ValidIf(function(_,data)
						if data.params.speed then
							print(" \27[36m SDL send speed parameter to HMI \27[0m")
							return false
						else
							return true
						end
					end)
					
					--mobile side: expect SubscribeVehicleData response
					self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS",							
									prndl= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_PRNDL"},
									myKey= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_MYKEY"},
									speed= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_SPEED"}})
					
					--mobile side: expect OnHashChange notification
					self.mobileSession1:ExpectNotification("OnHashChange", {})
				end
				
				function Test:PostCondition_UnSubscribeVehicleDataApp1()				
					--mobile side: sending UnsubscribeVehicleData request
					local cid1 = self.mobileSession:SendRPC("UnsubscribeVehicleData",{gps = true, speed = true})
					
					
					--hmi side: expect UnsubscribeVehicleData request
					EXPECT_HMICALL("VehicleInfo.UnsubscribeVehicleData",{gps = true})
					:Do(function(_,data)
						--hmi side: sending VehicleInfo.UnsubscribeVehicleData response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {gps= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_GPS"}})	
					end)
					:ValidIf(function(_,data)
						if data.params.speed then
							print(" \27[36m SDL send speed parameter to HMI \27[0m")
							return false
						else
							return true
						end
					end)
					
					
					--mobile side: expect UnsubscribeVehicleData response
					self.mobileSession:ExpectResponse(cid1, { success = true, resultCode = "SUCCESS", 
													gps= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_GPS"}})
					
					--mobile side: expect OnHashChange notification
					self.mobileSession:ExpectNotification("OnHashChange",{})
				end
				
				function Test:PostCondition_UnSubscribeVehicleDataApp2()				
					--mobile side: sending UnsubscribeVehicleData request					
					local cid2 = self.mobileSession1:SendRPC("UnsubscribeVehicleData",{prndl = true, myKey = true, speed = true})
				
					--hmi side: expect UnsubscribeVehicleData request
					EXPECT_HMICALL("VehicleInfo.UnsubscribeVehicleData",{prndl = true, myKey = true, speed = true})
					:Do(function(_,data)
						--hmi side: sending VehicleInfo.UnsubscribeVehicleData response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {prndl= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_PRNDL"},
																						myKey= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_MYKEY"},
																						speed= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_SPEED"}})	
					end)
													
					self.mobileSession1:ExpectResponse(cid2, { success = true, resultCode = "SUCCESS", 
													prndl= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_PRNDL"},
													myKey= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_MYKEY"},
													speed= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_SPEED"}})
					
					--mobile side: expect OnHashChange notification
					self.mobileSession1:ExpectNotification("OnHashChange", {})
				end			
		--End Test case SequenceCheck.2
		
		-----------------------------------------------------------------------------------------
		
		--Begin Test case SequenceCheck.3
		--Description: Check Subscribe on PRNDL vehicle data
		
			--Requirement id in JAMA: 
				-- SDLAQ-CRS-89

			--Verification criteria:
				-- OnVehicleData will be send to mobile after subscribed
				local prndlValue = {"PARK","REVERSE","NEUTRAL","DRIVE","SPORT","LOWGEAR","FIRST","SECOND","THIRD","FOURTH","FIFTH","SIXTH"}
				for i=1, #prndlValue do
					Test["SubbscribeVehicleData_NotSubcribedChangingPRNDL_"..prndlValue[i]] = function(self)											
						--hmi side: sending VehicleInfo.OnVehicleData notification					
						self.hmiConnection:SendNotification("VehicleInfo.OnVehicleData", {prndl = prndlValue[i]})	  
						
						--mobile side: expected SubscribeVehicleData response
						EXPECT_NOTIFICATION("OnVehicleData", {prndl = prndlValue[i]})
						:Times(0)
					end
				end	
				function Test:SubbscribeVehicleData_SubcribePRNDL()				
					self:subscribeVehicleDataSuccess({"prndl"})
				end
				for i=1, #prndlValue do
					Test["SubbscribeVehicleData_SubcribedChangingPRNDL_"..prndlValue[i]] = function(self)											
						--hmi side: sending VehicleInfo.OnVehicleData notification					
						self.hmiConnection:SendNotification("VehicleInfo.OnVehicleData", {prndl = prndlValue[i]})	  
						
						--mobile side: expected SubscribeVehicleData response
						EXPECT_NOTIFICATION("OnVehicleData", {prndl = prndlValue[i]})						
					end
				end
				function Test:PostCondition_UnSubscribeVehicleData()				
					self:unSubscribeVehicleDataSuccess({"prndl"})
				end
		--End Test case SequenceCheck.3
		
	--End Test suit SequenceCheck
----------------------------------------------------------------------------------------------
-----------------------------------------VII TEST BLOCK----------------------------------------
--------------------------------------Different HMIStatus-------------------------------------
----------------------------------------------------------------------------------------------
	--Description: processing of request/response in different HMIlevels, SystemContext, AudioStreamingState

	--Begin Test suit DifferentHMIlevel
	--Description: processing API in different HMILevel
	
		--Begin Test case DifferentHMIlevel.1
		--Description: Check SubscribeVehicleData when current HMI is NONE

			--Requirement id in JAMA:
				-- SDLAQ-CRS-798
				
			--Verification criteria: 
				-- SDL rejects SubscribeVehicleData request with REJECTED resultCode when current HMI level is NONE.				

--[==[TODO: check after ATF defect APPLINK-13101 is resolved
				function Test:Precondition_PolicyUpdate()
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
							"files/PTU_AllowedAllVehicleData.json")
							
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
										self.hmiConnection:SendNotification("SDL.OnAppPermissionConsent", { appID =  self.applications["Test Application"], consentedFunctions = {{ allowed = false, id = 193465391, name = "New"}}, source = "GUI"})
										end)
								end)
							end)
							:Timeout(2000)
							
						end)
					end)
				end
					
				
				function Test:Precondition_DeactivateToNone()
					--hmi side: sending BasicCommunication.OnExitApplication notification
					self.hmiConnection:SendNotification("BasicCommunication.OnExitApplication", {appID = self.applications["Test Application"], reason = "USER_EXIT"})

					EXPECT_NOTIFICATION("OnHMIStatus",
						{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
				end
				
				for i=1, #allVehicleData do
					Test["SubscribeVehicleData_HMILevelNone_"..allVehicleData[i]] = function(self)
						--mobile side: sending SubscribeVehicleData request
						local cid = self.mobileSession:SendRPC("SubscribeVehicleData",{allVehicleData[i]})
						
						--mobile side: expected SubscribeVehicleData response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED" })
						
						--mobile side: expect OnHashChange notification
						EXPECT_NOTIFICATION("OnHashChange",{})
						:Times(0)
					end
				end
				
				function Test:PostCondition_ActivateApp()				
					--hmi side: sending SDL.ActivateApp request
					local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["Test Application"]})

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
												{allowed = true, source = "GUI", device = {id = 1, name = "127.0.0.1"}})

										end)

									--hmi side: expect BasicCommunication.ActivateApp request
									EXPECT_HMICALL("BasicCommunication.ActivateApp")
									:Do(function(_,data)

										--hmi side: sending BasicCommunication.ActivateApp response
										self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})

									end)
									:Times(AnyNumber())
							end
						  end)

					--mobile side: expect OnHMIStatus notification
					EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"})	
				end	
				
		--End Test case DifferentHMIlevel.1
--]==]			
		-----------------------------------------------------------------------------------------

		--Begin Test case DifferentHMIlevel.2
		--Description: Check SubscribeVehicleData when current HMI is LIMITED(only for media)

			--Requirement id in JAMA:
				-- SDLAQ-CRS-798
				
			--Verification criteria: 
				-- SDL doesn't rejects SubscribeVehicleData when current HMI level is LIMITED.				
			function Test:Precondition_ActivateFirstApp()
				--hmi side: sending SDL.ActivateApp request
				local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["Test Application"]})
				
				--mobile side: expect notification
				self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = "FULL", systemContext = "MAIN"})										
			end

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
				EXPECT_NOTIFICATION("OnHMIStatus",{hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
			end
			
			for i=1, #allVehicleData do
				Test["SubscribeVehicleData_HMILevelLimited_"..allVehicleData[i]] = function(self)						
					self:subscribeVehicleDataSuccess({allVehicleData[i]})						
				end
			end
			function Test:PostCondition_UnSubscribeVehicleData()				
				self:unSubscribeVehicleDataSuccess(allVehicleData)
			end
		--End Test case DifferentHMIlevel.2
		
		-----------------------------------------------------------------------------------------
		
		--Begin Test case DifferentHMIlevel.3
		--Description: Check SubscribeVehicleData when current HMI is BACKGROUND

			--Requirement id in JAMA:
				-- SDLAQ-CRS-798
				
			--Verification criteria: 
				-- SDL doesn't rejects SubscribeVehicleData when current HMI level is BACKGROUND.
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
							:Times(AnyNumber())
						end)

					end
				end)
				
				--mobile side: expect notification from 2 app
				self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
				self.mobileSession1:ExpectNotification("OnHMIStatus",{hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})					
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
				Test["SubscribeVehicleData_HMILevelBackground_"..allVehicleData[i]] = function(self)						
					self:subscribeVehicleDataSuccess({allVehicleData[i]})
				end
			end

			function Test:PostCondition_UnSubscribeVehicleData()				
				self:unSubscribeVehicleDataSuccess(allVehicleData)
			end

			-- Postcondition: restoring sdl_preloaded_pt file
			-- TODO: Remove after implementation policy update
			function Test:Postcondition_Preloadedfile()
			  print ("restoring sdl_preloaded_pt.json")
			  commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
			end
		--End Test case DifferentHMIlevel.3		
	--End Test suit DifferentHMIlevel