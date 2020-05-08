---------------------------------------------------------------------------------------------
--ATF version: 2.2
--Created date: 12/Nov/2015
--Author: Ta Thanh Dong
---------------------------------------------------------------------------------------------
Test = require('connecttest')
require('cardinalities')
local events = require('events')
local mobile_session = require('mobile_session')

---------------------------------------------------------------------------------------------
-----------------------------Required Shared Libraries---------------------------------------
---------------------------------------------------------------------------------------------
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
local integerParameterInNotification = require('user_modules/shared_testcases/testCasesForIntegerParameterInNotification')
local floatParameterInNotification = require('user_modules/shared_testcases/testCasesForFloatParameterInNotification')
local stringParameterInNotification = require('user_modules/shared_testcases/testCasesForStringParameterInNotification')
local enumParameterInNotification = require('user_modules/shared_testcases/testCasesForEnumerationParameterInNotification')
local booleanParameterInNotification = require('user_modules/shared_testcases/testCasesForBooleanParameterInNotification')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local SDLConfig = require('user_modules/shared_testcases/SmartDeviceLinkConfigurations')
local functionId = require('function_id')
require('user_modules/AppTypes')

APIName = "OnVehicleData" -- set API name
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
Apps = {}
Apps[1] = {}
Apps[1].storagePath = config.pathToSDL .. SDLConfig:GetValue("AppStorageFolder") .. "/"..config.application1.registerAppInterfaceParams.fullAppID.. "_" .. config.deviceMAC.. "/"
Apps[1].appName = config.application1.registerAppInterfaceParams.appName 


---------------------------------------------------------------------------------------------
------------------------------------------Common functions-----------------------------------
---------------------------------------------------------------------------------------------

local SVDValues = {		gps						= "VEHICLEDATA_GPS", 
						speed					= "VEHICLEDATA_SPEED", 
						rpm						= "VEHICLEDATA_RPM", 
						fuelLevel				= "VEHICLEDATA_FUELLEVEL", 
						fuelLevel_State			= "VEHICLEDATA_FUELLEVEL_STATE", 
						instantFuelConsumption	= "VEHICLEDATA_FUELCONSUMPTION", 
						externalTemperature		= "VEHICLEDATA_EXTERNTEMP", 
						prndl					= "VEHICLEDATA_PRNDL", 
						tirePressure			= "VEHICLEDATA_TIREPRESSURE", 
						odometer				= "VEHICLEDATA_ODOMETER", 
						beltStatus				= "VEHICLEDATA_BELTSTATUS", 
						bodyInformation			= "VEHICLEDATA_BODYINFO", 
						deviceStatus			= "VEHICLEDATA_DEVICESTATUS", 
						driverBraking			= "VEHICLEDATA_BRAKING", 
						wiperStatus				= "VEHICLEDATA_WIPERSTATUS", 
						headLampStatus			= "VEHICLEDATA_HEADLAMPSTATUS", 
						engineTorque			= "VEHICLEDATA_ENGINETORQUE", 
						accPedalPosition		= "VEHICLEDATA_ACCPEDAL", 
						steeringWheelAngle		= "VEHICLEDATA_STEERINGWHEEL",
						vin						= "VEHICLEDATA_VIN"
					}
						

local allVehicleData = {	"gps", 
							"speed", 
							"rpm", 
							"fuelLevel", 
							"fuelLevel_State", 
							"instantFuelConsumption", 
							"externalTemperature", 
							"prndl", 
							"tirePressure", 
							"odometer", 
							"beltStatus", 
							"bodyInformation", 
							"deviceStatus", 
							"driverBraking", 
							"wiperStatus", 
							"headLampStatus", 
							"engineTorque", 
							"accPedalPosition", 
							"steeringWheelAngle",
							"vin"
						}
							

function Test:subscribeVehicleDataSuccess(paramsSend)
	
	local function setSVDRequest(paramsSend)
		local temp = {}	
		for i = 1, #paramsSend do		
			temp[paramsSend[i]] = true
		end	
		return temp
	end
	
	local function setSVDResponse(paramsSend, vehicleDataResultCode)
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
	
	local function createSuccessExpectedResult(response)
		response["success"] = true
		response["resultCode"] = "SUCCESS"
		
		return response
	end

	local request = setSVDRequest(paramsSend)
	local response = setSVDResponse(paramsSend)
	
	
	--mobile side: sending SubscribeVehicleData request
	local cid = self.mobileSession:SendRPC("SubscribeVehicleData",request)
	
	--hmi side: expect SubscribeVehicleData request
	EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData",request)
	:Do(function(_,data)
		--hmi side: sending VehicleInfo.SubscribeVehicleData response
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", response)	
	end)
	
	
	local expectedResult = createSuccessExpectedResult(response)
	
	--mobile side: expect SubscribeVehicleData response
	EXPECT_RESPONSE(cid, expectedResult)
	
	--mobile side: expect OnHashChange notification
	EXPECT_NOTIFICATION("OnHashChange")
end


---------------------------------------------------------------------------------------------
-------------------------- Overwrite These Functions For This Script-------------------------
---------------------------------------------------------------------------------------------
--Specific functions for this script
--1. verify_SUCCESS_Notification_Case(Notification)
--2. verify_Notification_IsIgnored_Case(Notification)
---------------------------------------------------------------------------------------------


--This function is used to send default request and response with specific valid data and verify SUCCESS resultCode
function Test:verify_SUCCESS_Notification_Case(Notification)
	
	self.hmiConnection:SendNotification("VehicleInfo.OnVehicleData", Notification)	  		
	
	--mobile side: expected SubscribeVehicleData response
	EXPECT_NOTIFICATION("OnVehicleData", Notification)	
		
end


function Test:verify_Notification_IsIgnored_Case(Notification)
	
	commonTestCases:DelayedExp(1000)
	
	self.hmiConnection:SendNotification("VehicleInfo.OnVehicleData", Notification)	  		
	
	--mobile side: expected Notification
	EXPECT_NOTIFICATION("OnVehicleData", Notification)	
	:Times(0)
			
end


---------------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------

	commonSteps:DeleteLogsFileAndPolicyTable()

	--Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup("Preconditions")
	
	--1. Activate application
	commonSteps:ActivationApp()

	local PermissionLines_SubscribeVehicleData = 
[[					"SubscribeVehicleData": {
						"hmi_levels": [
						  "BACKGROUND",
						  "FULL",
						  "LIMITED"
						],
						"parameters": [
							"gps", 
							"speed", 
							"rpm", 
							"fuelLevel", 
							"fuelLevel_State", 
							"instantFuelConsumption", 
							"externalTemperature", 
							"prndl", 
							"tirePressure", 
							"odometer", 
							"beltStatus", 
							"bodyInformation", 
							"deviceStatus", 
							"driverBraking", 
							"wiperStatus", 
							"headLampStatus", 
							"engineTorque", 
							"accPedalPosition", 
							"steeringWheelAngle"
					   ]
					  }]]


	local PermissionLines_OnVehicleData = 
[[					"OnVehicleData": {
						"hmi_levels": [
						  "BACKGROUND",
						  "FULL",
						  "LIMITED"
						],
						"parameters": [
							"gps", 
							"speed",  
							"rpm", 
							"fuelLevel", 
							"fuelLevel_State", 
							"instantFuelConsumption", 
							"externalTemperature", 
							"prndl", 
							"tirePressure", 
							"odometer", 
							"beltStatus", 
							"bodyInformation", 
							"deviceStatus", 
							"driverBraking", 
							"wiperStatus", 
							"headLampStatus", 
							"engineTorque", 
							"accPedalPosition", 
							"steeringWheelAngle"
					   ]
					  }]]
		

	local PermissionLinesForBase4 = PermissionLines_SubscribeVehicleData .. ", \n" .. PermissionLines_OnVehicleData ..", \n"
	local PermissionLinesForGroup1 = nil
	local PermissionLinesForApplication = nil
	--TODO: PT is blocked by ATF defect APPLINK-19188
	--local PTName = testCasesForPolicyTable:createPolicyTableFile(PermissionLinesForBase4, PermissionLinesForGroup1, PermissionLinesForApplication)	
	--testCasesForPolicyTable:updatePolicy(PTName)		

	local function backUpPreloadedPt_AndUpdate()

		--Backup sdl_preloaded_pt.json file 
		os.execute('cp ' .. config.pathToSDL .. 'sdl_preloaded_pt.json' .. ' ' .. config.pathToSDL .. 'backup_sdl_preloaded_pt.json')
		os.execute('rm ' .. config.pathToSDL .. 'policy.sqlite')


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
		

		data.policy_table.functional_groupings["Base-4"].rpcs.OnVehicleData = {
						hmi_levels =  {
						  "BACKGROUND",
						  "FULL",
						  "LIMITED"
						},
						parameters = {
							"gps", 
							"speed",  
							"rpm", 
							"fuelLevel", 
							"fuelLevel_State", 
							"instantFuelConsumption", 
							"externalTemperature", 
							"prndl", 
							"tirePressure", 
							"odometer", 
							"beltStatus", 
							"bodyInformation", 
							"deviceStatus", 
							"driverBraking", 
							"wiperStatus", 
							"headLampStatus", 
							"engineTorque", 
							"accPedalPosition", 
							"steeringWheelAngle",
							"vin"
					   }
					  }
					  
		data.policy_table.functional_groupings["Base-4"].rpcs.SubscribeVehicleData = {
						hmi_levels = {
						  "BACKGROUND",
						  "FULL",
						  "LIMITED"
						},
						parameters = {
							"gps", 
							"speed", 
							"rpm", 
							"fuelLevel", 
							"fuelLevel_State", 
							"instantFuelConsumption", 
							"externalTemperature", 
							"prndl", 
							"tirePressure", 
							"odometer", 
							"beltStatus", 
							"bodyInformation", 
							"deviceStatus", 
							"driverBraking", 
							"wiperStatus", 
							"headLampStatus", 
							"engineTorque", 
							"accPedalPosition", 
							"steeringWheelAngle",
							"vin"
					   }
					  }

		
		data = json.encode(data)

		file = io.open(pathToFile, "w")
		file:write(data)
		file:close()
	end

	--This function is not a test so it will execute before executing tests and does not show in report as a test.
	backUpPreloadedPt_AndUpdate()
	
	function Test:RestorePreloadedPt()
		-- body
		os.execute('cp ' .. config.pathToSDL .. 'backup_sdl_preloaded_pt.json' .. ' ' .. config.pathToSDL .. 'sdl_preloaded_pt.json')
		os.execute('rm ' .. config.pathToSDL .. 'backup_sdl_preloaded_pt.json')
	end
	
	----Get appID Value on HMI side
	function Test:GetAppID()
		Apps[1].appID = self.applications[Apps[1].appName]
	end

	function Test:SubscribeVehicleData_Positive() 				
		self:subscribeVehicleDataSuccess(allVehicleData)				
	end
	
	
-----------------------------------------------------------------------------------------------
-------------------------------------------TEST BLOCK I----------------------------------------
--------------------------------Check normal cases of Mobile request---------------------------
-----------------------------------------------------------------------------------------------

--Not Applicable

----------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK II----------------------------------------
-----------------------------Check special cases of Mobile request----------------------------
----------------------------------------------------------------------------------------------

--Not Applicable

-----------------------------------------------------------------------------------------------
-------------------------------------------TEST BLOCK III--------------------------------------
----------------------------------Check normal cases of HMI notification---------------------------
-----------------------------------------------------------------------------------------------
--Requirement id in JAMA or JIRA: 	
	--SDLAQ-CRS-1052: OnVehicleData
        -- APPLINK-16076: SDL must treat integer value for params of float type as valid
	
	--Verification criteria: The application is notified by the onVehicleData notification whenever new data is available and the app is subscribed for this data type.
        --Verification criteria: "Integer" value for "float" param should not be treated as an invalid_data by SDL

----------------------------------------------------------------------------------------------
	--List of parameters:
		--1.speed: type=Float minvalue=0 maxvalue=700 mandatory=false
		--2.fuelLevel: type=Float minvalue=-6 maxvalue=106 mandatory=false
		--3.instantFuelConsumption: type=Float minvalue=0 maxvalue=25575 mandatory=false
		--4.externalTemperature: type=Float minvalue=-40 maxvalue=100 mandatory=false
		--5.engineTorque: type=Float minvalue=-1000 maxvalue=2000 mandatory=false
		--6.accPedalPosition: type=Float minvalue=0 maxvalue=100 mandatory=false
		--7.steeringWheelAngle: type=Float minvalue=-2000 maxvalue=2000 mandatory=false	
		--8.rpm: type=Integer minvalue=0 maxvalue=20000 mandatory=false
		--9.odometer: type=Integer minvalue=0 maxvalue=17000000 mandatory=false
		--10.vin: type=String maxlength=17 mandatory=false
		--11.prndl: type=Common.PRNDL mandatory=false
		--12.fuelLevel_State: type=Common.ComponentVolumeStatus mandatory=false
		--13.driverBraking: type=Common.VehicleDataEventStatus mandatory=false
		--14.wiperStatus: type=Common.WiperStatus mandatory=false
		--15.headLampStatus: type=Common.HeadLampStatus mandatory=false
		--20.bodyInformation: type=Common.BodyInformation mandatory=false	
		--22.beltStatus: type=Common.BeltStatus mandatory=false
		--24.gps: type=Common.GPSData mandatory=false
		--25.tirePressure: type=Common.TireStatus mandatory=false
---------------------------------------------------------------------------------------------------------------------------------
	
	--This test case is used in some places such as verify all parameters are low bound, notification in different HMI levels
	local function OnVehicleData_AllParametersLowerBound_SUCCESS(TestCaseName)

		Test[TestCaseName] = function(self)
		
			
			local Notification = 
			{
				speed = 0.0,
				fuelLevel = -6.000000,
				instantFuelConsumption = 0.000000,
				externalTemperature = -40.000000,
				engineTorque = -1000.000000,
				accPedalPosition = 0.000000,
				steeringWheelAngle = -2000.000000,
				rpm = 0,
				odometer = 0,
				vin = "a",
				prndl = "PARK",
				fuelLevel_State = "UNKNOWN",
				driverBraking = "NO_EVENT",
				wiperStatus = "OFF",
				headLampStatus = {	lowBeamsOn = false, 
									highBeamsOn = false, 
									ambientLightSensorStatus = "NIGHT"
								},
				deviceStatus = 	{	voiceRecOn = true,
									btIconOn = true,
									callActive = true,
									phoneRoaming = true,
									textMsgAvailable = true,
									stereoAudioOutputMuted = true,
									monoAudioOutputMuted = true,
									eCallEventActive = true,
									primaryAudioSource = "USB",
									battLevelStatus = "ZERO_LEVEL_BARS",
									signalLevelStatus = "ZERO_LEVEL_BARS"
								},
				
				bodyInformation={	parkBrakeActive = true, 
									driverDoorAjar = true,
									passengerDoorAjar = true,
									rearLeftDoorAjar = true,
									rearRightDoorAjar = true,
									ignitionStableStatus = "IGNITION_SWITCH_NOT_STABLE", 
									ignitionStatus = "UNKNOWN"
								},
				beltStatus = 	{	driverBeltDeployed = "NO_EVENT",
									passengerBeltDeployed = "NO_EVENT",
									passengerBuckleBelted = "NO_EVENT",
									driverBuckleBelted = "NO_EVENT",
									leftRow2BuckleBelted = "NO_EVENT",
									passengerChildDetected = "NO_EVENT",
									rightRow2BuckleBelted = "NO_EVENT",
									middleRow2BuckleBelted = "NO_EVENT",
									middleRow3BuckleBelted = "NO_EVENT",
									leftRow3BuckleBelted = "NO_EVENT",
									rightRow3BuckleBelted = "NO_EVENT",
									leftRearInflatableBelted = "NO_EVENT",
									rightRearInflatableBelted = "NO_EVENT",
									middleRow1BeltDeployed = "NO_EVENT",
									middleRow1BuckleBelted = "NO_EVENT"
								},
				gps = 			{	longitudeDegrees = -180.0,
									latitudeDegrees = -90.0,
									pdop = 0.0,
									hdop = 0.0,
									vdop = 0.0,
									altitude = -10000.0,
									heading = 0.0,
									speed = 0.0,
									utcYear = 2010,
									utcMonth = 1,
									utcDay = 1,
									utcHours = 0,
									utcMinutes = 0,
									utcSeconds = 0,
									satellites = 0,
									compassDirection = "NORTH",
									dimension = "NO_FIX",
									actual = true
								},
				tirePressure = 	{	pressureTelltale = "OFF",
									leftFront = {status = "UNKNOWN"},
									rightFront = {status = "UNKNOWN"},
									leftRear = {status = "UNKNOWN"},
									rightRear = {status = "UNKNOWN"},
									innerLeftRear = {status = "UNKNOWN"},
									innerRightRear = {status = "UNKNOWN"}
								}
			}
			
			
			
			self:verify_SUCCESS_Notification_Case(Notification)
			
		end
	end

---------------------------------------------------------------------------------------------------------------------------------
	
	--This test case is used to verify all parameters are low bound when integer values for next params of float type are sent:
         -- speed
		 -- fuelLevel
		 -- instantFuelConsumption
		 -- externalTemperature
		 -- engineTorque
		 -- accPedalPosition
		 -- steeringWheelAngle
	     -- gps params

       
	local function OnVehicleData_AllParametersLowerBoundand_IntForFloat_SUCCESS(TestCaseName2)

		Test[TestCaseName2] = function(self)
		
			
			local Notification = 
			{
				speed = 0,
				fuelLevel = -6,
				instantFuelConsumption = 0,
				externalTemperature = -40,
				engineTorque = -1000,
				accPedalPosition = 0,
				steeringWheelAngle = -2000,
				rpm = 0,
				odometer = 0,
				vin = "a",
				prndl = "PARK",
				fuelLevel_State = "UNKNOWN",
				driverBraking = "NO_EVENT",
				wiperStatus = "OFF",
				headLampStatus = {	lowBeamsOn = false, 
									highBeamsOn = false, 
									ambientLightSensorStatus = "NIGHT"
								},
				deviceStatus = 	{	voiceRecOn = true,
									btIconOn = true,
									callActive = true,
									phoneRoaming = true,
									textMsgAvailable = true,
									stereoAudioOutputMuted = true,
									monoAudioOutputMuted = true,
									eCallEventActive = true,
									primaryAudioSource = "USB",
									battLevelStatus = "ZERO_LEVEL_BARS",
									signalLevelStatus = "ZERO_LEVEL_BARS"
								},
				bodyInformation={	parkBrakeActive = true, 
									driverDoorAjar = true,
									passengerDoorAjar = true,
									rearLeftDoorAjar = true,
									rearRightDoorAjar = true,
									ignitionStableStatus = "IGNITION_SWITCH_NOT_STABLE", 
									ignitionStatus = "UNKNOWN"
								},
				beltStatus = 	{	driverBeltDeployed = "NO_EVENT",
									passengerBeltDeployed = "NO_EVENT",
									passengerBuckleBelted = "NO_EVENT",
									driverBuckleBelted = "NO_EVENT",
									leftRow2BuckleBelted = "NO_EVENT",
									passengerChildDetected = "NO_EVENT",
									rightRow2BuckleBelted = "NO_EVENT",
									middleRow2BuckleBelted = "NO_EVENT",
									middleRow3BuckleBelted = "NO_EVENT",
									leftRow3BuckleBelted = "NO_EVENT",
									rightRow3BuckleBelted = "NO_EVENT",
									leftRearInflatableBelted = "NO_EVENT",
									rightRearInflatableBelted = "NO_EVENT",
									middleRow1BeltDeployed = "NO_EVENT",
									middleRow1BuckleBelted = "NO_EVENT"
								},
				gps = 			{	longitudeDegrees = -180,
									latitudeDegrees = -90,
									pdop = 0,
									hdop = 0,
									vdop = 0,
									altitude = -10000.0,
									heading = 0,
									speed = 0,									
									utcYear = 2010,
									utcMonth = 1,
									utcDay = 1,
									utcHours = 0,
									utcMinutes = 0,
									utcSeconds = 0,
									satellites = 0,									
									compassDirection = "NORTH",
									dimension = "NO_FIX",
									actual = true
								},
				tirePressure = 	{	pressureTelltale = "OFF",
									leftFront = {status = "UNKNOWN"},
									rightFront = {status = "UNKNOWN"},
									leftRear = {status = "UNKNOWN"},
									rightRear = {status = "UNKNOWN"},
									innerLeftRear = {status = "UNKNOWN"},
									innerRightRear = {status = "UNKNOWN"}
								}
			}
			
					
			self:verify_SUCCESS_Notification_Case(Notification)
			
		end
	end

-------------------------------------------------------------------------------------------------------------------------------	
	
	local function common_Test_Cases_For_Notification()
		--Print new line to separate new test cases group
		commonFunctions:newTestCasesGroup("Test suite: Common test cases of HMI notification")
                -------------------------------------------------------------------------------------------------------------
		--Common Test cases for Notification
		--1. PositiveNotification
		--2. Only mandatory parameters
		--3. All parameters are lower bound
		--4. All parameters are upper bound
-----------------------------------------------------------------------------------------------------------------------------

		Test["OnVehicleData_PositiveNotification_SUCCESS"] = function(self)
		
			
			local Notification = 
			{
				speed = 1.1,
				fuelLevel = 1.1,
				instantFuelConsumption = 1.1,
				externalTemperature = 1.1,
				engineTorque = 1.1,
				accPedalPosition = 1.1,
				steeringWheelAngle = 1.1,
				rpm = 1,
				odometer = 1,
				vin = "a",
				prndl = "PARK",
				fuelLevel_State = "UNKNOWN",
				driverBraking = "NO_EVENT",
				wiperStatus = "OFF",
				headLampStatus = {	lowBeamsOn = false, 
									highBeamsOn = false, 
									ambientLightSensorStatus = "NIGHT"
								},
				deviceStatus = 	{	voiceRecOn = true,
									btIconOn = true,
									callActive = true,
									phoneRoaming = true,
									textMsgAvailable = true,
									stereoAudioOutputMuted = true,
									monoAudioOutputMuted = true,
									eCallEventActive = true,
									primaryAudioSource = "USB",
									battLevelStatus = "ZERO_LEVEL_BARS",
									signalLevelStatus = "ZERO_LEVEL_BARS"
								},
				bodyInformation={	parkBrakeActive = true, 
									driverDoorAjar = true,
									passengerDoorAjar = true,
									rearLeftDoorAjar = true,
									rearRightDoorAjar = true,
									ignitionStableStatus = "IGNITION_SWITCH_NOT_STABLE", 
									ignitionStatus = "UNKNOWN"
								},
				beltStatus = 	{	driverBeltDeployed = "NO_EVENT",
									passengerBeltDeployed = "NO_EVENT",
									passengerBuckleBelted = "NO_EVENT",
									driverBuckleBelted = "NO_EVENT",
									leftRow2BuckleBelted = "NO_EVENT",
									passengerChildDetected = "NO_EVENT",
									rightRow2BuckleBelted = "NO_EVENT",
									middleRow2BuckleBelted = "NO_EVENT",
									middleRow3BuckleBelted = "NO_EVENT",
									leftRow3BuckleBelted = "NO_EVENT",
									rightRow3BuckleBelted = "NO_EVENT",
									leftRearInflatableBelted = "NO_EVENT",
									rightRearInflatableBelted = "NO_EVENT",
									middleRow1BeltDeployed = "NO_EVENT",
									middleRow1BuckleBelted = "NO_EVENT"
								},
				gps = 			{   longitudeDegrees = 1.1,
									latitudeDegrees = 1.1,
									pdop = 1.1,
									hdop = 1.1,
									vdop = 1.1,
									altitude = 1.1,
									heading = 1.1,
									speed = 1.1,
									utcYear = 2011,
									utcMonth = 1,
									utcDay = 1,
									utcHours = 1,
									utcMinutes = 1,
									utcSeconds = 1,
									satellites = 1,
									compassDirection = "NORTH",
									dimension = "NO_FIX",
									actual = true
								},
				tirePressure = 	{	pressureTelltale = "OFF",
									leftFront = {status = "UNKNOWN"},
									rightFront = {status = "UNKNOWN"},
									leftRear = {status = "UNKNOWN"},
									rightRear = {status = "UNKNOWN"},
									innerLeftRear = {status = "UNKNOWN"},
									innerRightRear = {status = "UNKNOWN"}
								}
			}
						
			self:verify_SUCCESS_Notification_Case(Notification)
			
		end
		
-----------------------------------------------------------------------------------------------------------------------------

   --This test case is used to verify positive response to notification when integer values for next params of float type are sent:
         -- speed
		 -- fuelLevel
		 -- instantFuelConsumption
		 -- externalTemperature
		 -- engineTorque
		 -- accPedalPosition
		 -- steeringWheelAngle
         -- gps params


		Test["OnVehicleData_PositiveNotification_IntForFloat_SUCCESS"] = function(self)
		
			
			local Notification = 
			{
				speed = 1,
				fuelLevel = 1,
				instantFuelConsumption = 1,
				externalTemperature = 1,
				engineTorque = 1,
				accPedalPosition = 1,
				steeringWheelAngle = 1,
				rpm = 1,
				odometer = 1,
				vin = "a",
				prndl = "PARK",
				fuelLevel_State = "UNKNOWN",
				driverBraking = "NO_EVENT",
				wiperStatus = "OFF",
				
				headLampStatus = {	lowBeamsOn = false, 
									highBeamsOn = false, 
									ambientLightSensorStatus = "NIGHT"
								},
				deviceStatus = 	{	voiceRecOn = true,
									btIconOn = true,
									callActive = true,
									phoneRoaming = true,
									textMsgAvailable = true,
									stereoAudioOutputMuted = true,
									monoAudioOutputMuted = true,
									eCallEventActive = true,
									primaryAudioSource = "USB",
									battLevelStatus = "ZERO_LEVEL_BARS",
									signalLevelStatus = "ZERO_LEVEL_BARS"
								},
				bodyInformation={	parkBrakeActive = true, 
									driverDoorAjar = true,
									passengerDoorAjar = true,
									rearLeftDoorAjar = true,
									rearRightDoorAjar = true,
									ignitionStableStatus = "IGNITION_SWITCH_NOT_STABLE", 
									ignitionStatus = "UNKNOWN"
								},
				beltStatus = 	{	                driverBeltDeployed = "NO_EVENT",
									passengerBeltDeployed = "NO_EVENT",
									passengerBuckleBelted = "NO_EVENT",
									driverBuckleBelted = "NO_EVENT",
									leftRow2BuckleBelted = "NO_EVENT",
									passengerChildDetected = "NO_EVENT",
									rightRow2BuckleBelted = "NO_EVENT",
									middleRow2BuckleBelted = "NO_EVENT",
									middleRow3BuckleBelted = "NO_EVENT",
									leftRow3BuckleBelted = "NO_EVENT",
									rightRow3BuckleBelted = "NO_EVENT",
									leftRearInflatableBelted = "NO_EVENT",
									rightRearInflatableBelted = "NO_EVENT",
									middleRow1BeltDeployed = "NO_EVENT",
									middleRow1BuckleBelted = "NO_EVENT"
								},
				gps = 			{   longitudeDegrees = 1,
									latitudeDegrees = 1,
									pdop = 1,
									hdop = 1,
									vdop = 1,
									altitude = 1.1,
									heading = 1,
									speed = 1,
									utcYear = 2011,
									utcMonth = 1,
									utcDay = 1,
									utcHours = 1,
									utcMinutes = 1,
									utcSeconds = 1,
									satellites = 1,
									compassDirection = "NORTH",
									dimension = "NO_FIX",
									actual = true
								},
				tirePressure = 	{	pressureTelltale = "OFF",
									leftFront = {status = "UNKNOWN"},
									rightFront = {status = "UNKNOWN"},
									leftRear = {status = "UNKNOWN"},
									rightRear = {status = "UNKNOWN"},
									innerLeftRear = {status = "UNKNOWN"},
									innerRightRear = {status = "UNKNOWN"}
								}
			}
			
			
			self:verify_SUCCESS_Notification_Case(Notification)
			
		end

  --------------------------------------------------------------------------------------------------------------
		
		OnVehicleData_AllParametersLowerBound_SUCCESS("OnVehicleData_AllParametersLowerBound_SUCCESS")
  ----------------------------------------------------------------------------------------------------------------
		
		OnVehicleData_AllParametersLowerBoundand_IntForFloat_SUCCESS("OnVehicleData_AllParametersLowerBoundand_IntForFloat_SUCCESS")
  ----------------------------------------------------------------------------------------------------------------
		
		Test["OnVehicleData_AllParametersUpperBound_SUCCESS"] = function(self)
		
			local Notification = 
			{
				speed = 700.0,
				fuelLevel = 106.000000,
				instantFuelConsumption = 25575.000000,
				externalTemperature = 100.000000,
				engineTorque = 2000.000000,
				accPedalPosition = 100.000000,
				steeringWheelAngle = 2000.000000,
				rpm = 20000,
				odometer = 17000000,
				vin = "aaaaaaaaaaaaaaaaa",
				prndl = "PARK",
				fuelLevel_State = "UNKNOWN",
				driverBraking = "NO_EVENT",
				wiperStatus = "OFF",
				headLampStatus = {	lowBeamsOn = false, 
									highBeamsOn = false, 
									ambientLightSensorStatus = "NIGHT"
								},
				deviceStatus = 	{	voiceRecOn = true,
									btIconOn = true,
									callActive = true,
									phoneRoaming = true,
									textMsgAvailable = true,
									stereoAudioOutputMuted = true,
									monoAudioOutputMuted = true,
									eCallEventActive = true,
									primaryAudioSource = "USB",
									battLevelStatus = "ZERO_LEVEL_BARS",
									signalLevelStatus = "ZERO_LEVEL_BARS"
								},
				bodyInformation={	parkBrakeActive = true, 
									driverDoorAjar = true,
									passengerDoorAjar = true,
									rearLeftDoorAjar = true,
									rearRightDoorAjar = true,
									ignitionStableStatus = "IGNITION_SWITCH_NOT_STABLE", 
									ignitionStatus = "UNKNOWN"
								},
				beltStatus = 	{	driverBeltDeployed = "NO_EVENT",
									passengerBeltDeployed = "NO_EVENT",
									passengerBuckleBelted = "NO_EVENT",
									driverBuckleBelted = "NO_EVENT",
									leftRow2BuckleBelted = "NO_EVENT",
									passengerChildDetected = "NO_EVENT",
									rightRow2BuckleBelted = "NO_EVENT",
									middleRow2BuckleBelted = "NO_EVENT",
									middleRow3BuckleBelted = "NO_EVENT",
									leftRow3BuckleBelted = "NO_EVENT",
									rightRow3BuckleBelted = "NO_EVENT",
									leftRearInflatableBelted = "NO_EVENT",
									rightRearInflatableBelted = "NO_EVENT",
									middleRow1BeltDeployed = "NO_EVENT",
									middleRow1BuckleBelted = "NO_EVENT"
								},
				gps = 			{	longitudeDegrees = 180.0,
									latitudeDegrees = 90.0,
									pdop = 10.0,
									hdop = 10.0,
									vdop = 10.0,
									altitude = 10000.0,
									heading = 359.99,
									speed = 500.0,
									utcYear = 2100,
									utcMonth = 12,
									utcDay = 31,
									utcHours = 23,
									utcMinutes = 59,
									utcSeconds = 59,
									satellites = 31,
									compassDirection = "NORTH",
									dimension = "NO_FIX",
									actual = true
								},
				tirePressure = 	{	pressureTelltale = "OFF",
									leftFront = {status = "UNKNOWN"},
									rightFront = {status = "UNKNOWN"},
									leftRear = {status = "UNKNOWN"},
									rightRear = {status = "UNKNOWN"},
									innerLeftRear = {status = "UNKNOWN"},
									innerRightRear = {status = "UNKNOWN"}
								}
			}
						
			self:verify_SUCCESS_Notification_Case(Notification)
			
		end

  ----------------------------------------------------------------------------------------------------------------
			
	--This test case is used to verify all parameters are upper bound when integer values for next params of float type are sent:
         -- speed
		 -- fuelLevel
		 -- instantFuelConsumption
		 -- externalTemperature
		 -- engineTorque
		 -- accPedalPosition
		 -- steeringWheelAngle
         -- gps params

		Test["OnVehicleData_AllParametersUpperBound_IntForFloat_SUCCESS"] = function(self)
		
			local Notification = 
			{
				speed = 700,
				fuelLevel = 106,
				instantFuelConsumption = 25575,
				externalTemperature = 100,
				engineTorque = 2000,
				accPedalPosition = 100,
				steeringWheelAngle = 2000,
				rpm = 20000,
				odometer = 17000000,
				vin = "aaaaaaaaaaaaaaaaa",
				prndl = "PARK",
				fuelLevel_State = "UNKNOWN",
				driverBraking = "NO_EVENT",
				wiperStatus = "OFF",
				headLampStatus = {	lowBeamsOn = false, 
									highBeamsOn = false, 
									ambientLightSensorStatus = "NIGHT"
								},
				deviceStatus = 	{	voiceRecOn = true,
									btIconOn = true,
									callActive = true,
									phoneRoaming = true,
									textMsgAvailable = true,
									stereoAudioOutputMuted = true,
									monoAudioOutputMuted = true,
									eCallEventActive = true,
									primaryAudioSource = "USB",
									battLevelStatus = "ZERO_LEVEL_BARS",
									signalLevelStatus = "ZERO_LEVEL_BARS"
								},
				bodyInformation={	parkBrakeActive = true, 
									driverDoorAjar = true,
									passengerDoorAjar = true,
									rearLeftDoorAjar = true,
									rearRightDoorAjar = true,
									ignitionStableStatus = "IGNITION_SWITCH_NOT_STABLE", 
									ignitionStatus = "UNKNOWN"
								},
				beltStatus = 	{	driverBeltDeployed = "NO_EVENT",
									passengerBeltDeployed = "NO_EVENT",
									passengerBuckleBelted = "NO_EVENT",
									driverBuckleBelted = "NO_EVENT",
									leftRow2BuckleBelted = "NO_EVENT",
									passengerChildDetected = "NO_EVENT",
									rightRow2BuckleBelted = "NO_EVENT",
									middleRow2BuckleBelted = "NO_EVENT",
									middleRow3BuckleBelted = "NO_EVENT",
									leftRow3BuckleBelted = "NO_EVENT",
									rightRow3BuckleBelted = "NO_EVENT",
									leftRearInflatableBelted = "NO_EVENT",
									rightRearInflatableBelted = "NO_EVENT",
									middleRow1BeltDeployed = "NO_EVENT",
									middleRow1BuckleBelted = "NO_EVENT"
								},
				gps = 			{	longitudeDegrees = 180,
									latitudeDegrees = 90,
									pdop = 10,
									hdop = 10,
									vdop = 10,
									altitude = 10000.0,
									heading = 400,
									speed = 500,
									utcYear = 2100,
									utcMonth = 12,
									utcDay = 31,
									utcHours = 23,
									utcMinutes = 59,
									utcSeconds = 59,
									satellites = 31,
									compassDirection = "NORTH",
									dimension = "NO_FIX",
									actual = true
								},
				tirePressure = 	{	pressureTelltale = "OFF",
									leftFront = {status = "UNKNOWN"},
									rightFront = {status = "UNKNOWN"},
									leftRear = {status = "UNKNOWN"},
									rightRear = {status = "UNKNOWN"},
									innerLeftRear = {status = "UNKNOWN"},
									innerRightRear = {status = "UNKNOWN"}
								}
			}
			
			self:verify_SUCCESS_Notification_Case(Notification)
			
		end
	
  --------------------------------------------------------------------------------------------------------------------
		
		Test["OnVehicleData_OnlyMandatoryParameters_SUCCESS"] = function(self)
		
			local Notification = 
			{
				bodyInformation={	parkBrakeActive = true, 
									ignitionStableStatus = "IGNITION_SWITCH_NOT_STABLE", 
									ignitionStatus = "UNKNOWN"
								},	
				headLampStatus = {	lowBeamsOn = false, 
									highBeamsOn = false, 
									ambientLightSensorStatus = "NIGHT"
								},
				tirePressure = 	{	leftFront = {status = "UNKNOWN"},
									rightFront = {status = "UNKNOWN"},
									leftRear = {status = "UNKNOWN"},
									rightRear = {status = "UNKNOWN"},
									innerLeftRear = {status = "UNKNOWN"},
									innerRightRear = {status = "UNKNOWN"}
								}
			}
			
			self:verify_SUCCESS_Notification_Case(Notification)
			
			
		end
		-----------------------------------------------------------------------------------------
		
		Test["OnVehicleData_OnlyMandatoryParameters_SUCCESS_bodyInformation"] = function(self)
		
			local Notification = 
			{
				bodyInformation={	parkBrakeActive = true, 
									ignitionStableStatus = "IGNITION_SWITCH_NOT_STABLE", 
									ignitionStatus = "UNKNOWN"
								}
			}
			
			self:verify_SUCCESS_Notification_Case(Notification)
		end
		-----------------------------------------------------------------------------------------
		
		Test["OnVehicleData_OnlyMandatoryParameters_SUCCESS_headLampStatus"] = function(self)
		
			local Notification = 
			{
				headLampStatus = {	lowBeamsOn = false, 
									highBeamsOn = false, 
									ambientLightSensorStatus = "NIGHT"
								}
			}
			
			self:verify_SUCCESS_Notification_Case(Notification)
		end
		
		-----------------------------------------------------------------------------------------
		
		Test["OnVehicleData_OnlyMandatoryParameters_SUCCESS_tirePressure"] = function(self)
		
			local Notification = 
			{ 
				tirePressure = 	{	leftFront = {status = "UNKNOWN"},
									rightFront = {status = "UNKNOWN"},
									leftRear = {status = "UNKNOWN"},
									rightRear = {status = "UNKNOWN"},
									innerLeftRear = {status = "UNKNOWN"},
									innerRightRear = {status = "UNKNOWN"}
								}
			}
			
			self:verify_SUCCESS_Notification_Case(Notification)
		end
		-----------------------------------------------------------------------------------------
		
		--OnVehicleData_OnlyMandatoryParameters_SUCCESS_tirePressure: sub-parameters
		local TestData = 	{	leftFront = {status = "UNKNOWN"},
								rightFront = {status = "UNKNOWN"},
								leftRear = {status = "UNKNOWN"},
								rightRear = {status = "UNKNOWN"},
								innerLeftRear = {status = "UNKNOWN"},
								innerRightRear = {status = "UNKNOWN"}
							}
		for ParameterName,value in pairs(TestData) do
			Test["OnVehicleData_OnlyMandatoryParameters_SUCCESS_tirePressure_" .. tostring(ParameterName)] = function(self)
			
				local tirePressure_value = {}
				tirePressure_value[ParameterName] = value
				
				local Notification = {tirePressure = tirePressure_value}
				
				self:verify_SUCCESS_Notification_Case(Notification)
			end
		end
		
		-----------------------------------------------------------------------------------------
	end
	common_Test_Cases_For_Notification()


	--1.speed: type=Float minvalue=0 maxvalue=700 mandatory=false
	--2.fuelLevel: type=Float minvalue=-6 maxvalue=106 mandatory=false
	--3.instantFuelConsumption: type=Float minvalue=0 maxvalue=25575 mandatory=false
	--4.externalTemperature: type=Float minvalue=-40 maxvalue=100 mandatory=false
	--5.engineTorque: type=Float minvalue=-1000 maxvalue=2000 mandatory=false
	--6.accPedalPosition: type=Float minvalue=0 maxvalue=100 mandatory=false
	--7.steeringWheelAngle: type=Float minvalue=-2000 maxvalue=2000 mandatory=false	
			
	local Notification = {rpm = 1}		
	floatParameterInNotification:verify_Float_Parameter(Notification, {"speed"}, {0.000000, 700.000000}, false)
	floatParameterInNotification:verify_Float_Parameter(Notification, {"fuelLevel"}, {-6.000000, 106.000000}, false)
	floatParameterInNotification:verify_Float_Parameter(Notification, {"instantFuelConsumption"}, {0.000000, 25575.000000}, false)
	floatParameterInNotification:verify_Float_Parameter(Notification, {"externalTemperature"}, {-40.000000, 100.000000}, false)
	floatParameterInNotification:verify_Float_Parameter(Notification, {"engineTorque"}, {-1000.000000, 2000.000000}, false)
	floatParameterInNotification:verify_Float_Parameter(Notification, {"accPedalPosition"}, {0.000000, 100.000000}, false)
	floatParameterInNotification:verify_Float_Parameter(Notification, {"steeringWheelAngle"}, {-2000.000000, 2000.000000}, false)
----------------------------------------------------------------------------------------------

	--8.rpm: type=Integer minvalue=0 maxvalue=20000 mandatory=false
	--9.odometer: type=Integer minvalue=0 maxvalue=17000000 mandatory=false
	local Notification = {speed = 1}
	integerParameterInNotification:verify_Integer_Parameter(Notification, {"rpm"}, {0, 20000}, false)
	integerParameterInNotification:verify_Integer_Parameter(Notification, {"odometer"}, {0, 17000000}, false)
----------------------------------------------------------------------------------------------

	--10.vin: type=String maxlength=17 mandatory=false
	local Notification = {rpm = 1}		
	stringParameterInNotification:verify_String_Parameter(Notification, {"vin"}, {1, 17}, false, true)
----------------------------------------------------------------------------------------------
	
	--11.prndl: type=Common.PRNDL mandatory=false
	--12.fuelLevel_State: type=Common.ComponentVolumeStatus mandatory=false
	--13.driverBraking: type=Common.VehicleDataEventStatus mandatory=false
	--14.wiperStatus: type=Common.WiperStatus mandatory=false
	--Enumerations:
	local PRNDL = {"PARK", "REVERSE", "NEUTRAL", "DRIVE", "SPORT", "LOWGEAR", "FIRST", "SECOND", "THIRD", "FOURTH", "FIFTH", "SIXTH", "SEVENTH", "EIGHTH", "FAULT"}
	local ComponentVolumeStatus = {"UNKNOWN", "NORMAL", "LOW", "FAULT", "ALERT", "NOT_SUPPORTED"}
	local VehicleDataEventStatus = {"NO_EVENT", "NO", "YES", "NOT_SUPPORTED", "FAULT"}	
	local WiperStatus = {"OFF","AUTO_OFF","OFF_MOVING","MAN_INT_OFF","MAN_INT_ON","MAN_LOW","MAN_HIGH", "MAN_FLICK","WASH","AUTO_LOW","AUTO_HIGH","COURTESYWIPE","AUTO_ADJUST","STALLED","NO_DATA_EXISTS"}
	
	local Notification = {rpm = 1}
	enumParameterInNotification:verify_Enumeration_Parameter(Notification, {"prndl"}, PRNDL, false)
	enumParameterInNotification:verify_Enumeration_Parameter(Notification, {"fuelLevel_State"}, ComponentVolumeStatus, false)
	enumParameterInNotification:verify_Enumeration_Parameter(Notification, {"driverBraking"}, VehicleDataEventStatus, false)
	enumParameterInNotification:verify_Enumeration_Parameter(Notification, {"wiperStatus"}, WiperStatus, false)
----------------------------------------------------------------------------------------------

	--15.headLampStatus: type=Common.HeadLampStatus mandatory=false
	--17.deviceStatus: type=Common.DeviceStatus mandatory=false
	--20.bodyInformation: type=Common.BodyInformation mandatory=false	

	local function verify_headLampStatus_parameter()
		--[[headLampStatus: type=Common.HeadLampStatus mandatory=false
			--name="lowBeamsOn" type="Boolean" mandatory="true"
			--name="highBeamsOn" type="Boolean" mandatory="true"
			--name="ambientLightSensorStatus" type="Common.AmbientLightStatus" mandatory="true"]]
			
		--Enumerations:
		local AmbientLightStatus = {"NIGHT", "TWILIGHT_1", "TWILIGHT_2", "TWILIGHT_3", "TWILIGHT_4", "DAY", "UNKNOWN", "INVALID"}
		
		
		local Notification = {instantFuelConsumption = 0, headLampStatus = {}}
		
		--1. IsMissed
		commonFunctions:TestCaseForNotification(self, Notification, {"headLampStatus"}, "IsMissed", nil, true)
		
		--2. IsWrongDataType
		commonFunctions:TestCaseForNotification(self, Notification, {"headLampStatus"}, "IsWrongDataType", 123, false)
								
		local Notification = {rpm = 1, headLampStatus = {lowBeamsOn = false, highBeamsOn = false, ambientLightSensorStatus = AmbientLightStatus[1]}}
		
		--3. TCs for parameter: lowBeamsOn, highBeamsOn
		booleanParameterInNotification:verify_Boolean_Parameter(Notification, {"headLampStatus", "lowBeamsOn"}, true)
		booleanParameterInNotification:verify_Boolean_Parameter(Notification, {"headLampStatus", "highBeamsOn"}, true)
			
		--4. TCs for parameter: ambientLightSensorStatus
		enumParameterInNotification:verify_Enumeration_Parameter(Notification, {"headLampStatus", "ambientLightSensorStatus"}, AmbientLightStatus, true)	
	end
	verify_headLampStatus_parameter()

	

	local function verify_bodyInformation_parameter()
		--[[bodyInformation: type=Common.BodyInformation mandatory=false
			--name="parkBrakeActive" type="Boolean" mandatory="true"
			--name="driverDoorAjar" type="Boolean" mandatory="false"
			--name="passengerDoorAjar" type="Boolean" mandatory="false"
			--name="rearLeftDoorAjar" type="Boolean" mandatory="false"
			--name="rearRightDoorAjar" type="Boolean" mandatory="false"
			--name="ignitionStableStatus" type="Common.IgnitionStableStatus" mandatory="true"
			--name="ignitionStatus" type="Common.IgnitionStatus" mandatory="true"]]

		--Print new line to separate new test cases group
		commonFunctions:newTestCasesGroup("Test suite For Parameter: bodyInformation")
		
		--Enumerations:
		local IgnitionStableStatus = {"IGNITION_SWITCH_NOT_STABLE", "IGNITION_SWITCH_STABLE", "MISSING_FROM_TRANSMITTER"}
		local IgnitionStatus = {"UNKNOWN", "OFF", "ACCESSORY", "RUN", "START", "INVALID"}
		
		
		local Notification = {rpm = 1, bodyInformation = {}}
		
		--1. IsMissed
		commonFunctions:TestCaseForNotification(self, Notification, {"bodyInformation"}, "IsMissed", nil, true)
		
		--2. IsWrongDataType
		commonFunctions:TestCaseForNotification(self, Notification, {"bodyInformation"}, "IsWrongDataType", 123, false)

		
		local Notification = 	{	rpm = 1, 
									bodyInformation = 	{	parkBrakeActive = true, 
															ignitionStableStatus = "IGNITION_SWITCH_NOT_STABLE", 
															ignitionStatus = "UNKNOWN"}}
								
		--3. TCs for parameter: parkBrakeActive														
			booleanParameterInNotification:verify_Boolean_Parameter(Notification, {"bodyInformation", "parkBrakeActive"}, true)
		
		--4. TCs for parameters: driverDoorAjar, passengerDoorAjar, rearLeftDoorAjar, rearRightDoorAjar
			booleanParameterInNotification:verify_Boolean_Parameter(Notification, {"bodyInformation", "driverDoorAjar"}, false)
			booleanParameterInNotification:verify_Boolean_Parameter(Notification, {"bodyInformation", "passengerDoorAjar"}, false)
			booleanParameterInNotification:verify_Boolean_Parameter(Notification, {"bodyInformation", "rearLeftDoorAjar"}, false)
			booleanParameterInNotification:verify_Boolean_Parameter(Notification, {"bodyInformation", "rearRightDoorAjar"}, false)

		--5. TCs for parameter: ignitionStableStatus, ignitionStatus
			enumParameterInNotification:verify_Enumeration_Parameter(Notification, {"bodyInformation", "ignitionStableStatus"}, IgnitionStableStatus, true)
			enumParameterInNotification:verify_Enumeration_Parameter(Notification, {"bodyInformation", "ignitionStatus"}, IgnitionStatus, true)

	end
	verify_bodyInformation_parameter()	

	
----------------------------------------------------------------------------------------------


	--22.beltStatus: type=Common.BeltStatus mandatory=false
	--24.gps: type=Common.GPSData mandatory=false
	--25.tirePressure: type=Common.TireStatus mandatory=false

	local function verify_beltStatus_parameter()
		--[[beltStatus: type=Common.BeltStatus mandatory=false	
			--name="driverBeltDeployed" type="Common.VehicleDataEventStatus" mandatory="false"
			--name="passengerBeltDeployed" type="Common.VehicleDataEventStatus" mandatory="false"
			--name="passengerBuckleBelted" type="Common.VehicleDataEventStatus" mandatory="false"
			--name="driverBuckleBelted" type="Common.VehicleDataEventStatus" mandatory="false"
			--name="leftRow2BuckleBelted" type="Common.VehicleDataEventStatus" mandatory="false"
			--name="passengerChildDetected" type="Common.VehicleDataEventStatus" mandatory="false"
			--name="rightRow2BuckleBelted" type="Common.VehicleDataEventStatus" mandatory="false"
			--name="middleRow2BuckleBelted" type="Common.VehicleDataEventStatus" mandatory="false"
			--name="middleRow3BuckleBelted" type="Common.VehicleDataEventStatus" mandatory="false"
			--name="leftRow3BuckleBelted" type="Common.VehicleDataEventStatus" mandatory="false"	
			--name="rightRow3BuckleBelted" type="Common.VehicleDataEventStatus" mandatory="false"
			--name="leftRearInflatableBelted" type="Common.VehicleDataEventStatus" mandatory="false"
			--name="rightRearInflatableBelted" type="Common.VehicleDataEventStatus" mandatory="false"
			--name="middleRow1BeltDeployed" type="Common.VehicleDataEventStatus" mandatory="false"
			--name="middleRow1BuckleBelted" type="Common.VehicleDataEventStatus" mandatory="false"]]
		
		local Notification = {rpm = 1, beltStatus = {}}
		
		--1. IsMissed
		commonFunctions:TestCaseForNotification(self, Notification, {"beltStatus"}, "IsMissed", nil, true)
		
		--2. IsEmptyTable
		--TODO: Update when APPLINK-15241 is resolved
		--commonFunctions:TestCaseForNotification(self, Notification, {"beltStatus"}, "IsEmptyTable", {}, false)
		commonFunctions:TestCaseForNotification(self, Notification, {"beltStatus"}, "IsEmptyTable", {}, true)
		
		--3. IsWrongDataType
		commonFunctions:TestCaseForNotification(self, Notification, {"beltStatus"}, "IsWrongDataType", 123, false)
		
		--4. TCs for parameters
		local Notification = {rpm = 1, beltStatus = {passengerBeltDeployed = "NO_EVENT"}}
		enumParameterInNotification:verify_Enumeration_Parameter(Notification, {"beltStatus", "driverBeltDeployed"}, VehicleDataEventStatus, false)
		
		local Notification = {rpm = 1, beltStatus = {driverBeltDeployed = "NO_EVENT"}}
		enumParameterInNotification:verify_Enumeration_Parameter(Notification, {"beltStatus", "passengerBeltDeployed"}, VehicleDataEventStatus, false)
		enumParameterInNotification:verify_Enumeration_Parameter(Notification, {"beltStatus", "passengerBuckleBelted"}, VehicleDataEventStatus, false)
		enumParameterInNotification:verify_Enumeration_Parameter(Notification, {"beltStatus", "driverBuckleBelted"}, VehicleDataEventStatus, false)
		enumParameterInNotification:verify_Enumeration_Parameter(Notification, {"beltStatus", "leftRow2BuckleBelted"}, VehicleDataEventStatus, false)
		enumParameterInNotification:verify_Enumeration_Parameter(Notification, {"beltStatus", "passengerChildDetected"}, VehicleDataEventStatus, false)
		enumParameterInNotification:verify_Enumeration_Parameter(Notification, {"beltStatus", "rightRow2BuckleBelted"}, VehicleDataEventStatus, false)
		enumParameterInNotification:verify_Enumeration_Parameter(Notification, {"beltStatus", "middleRow2BuckleBelted"}, VehicleDataEventStatus, false)
		enumParameterInNotification:verify_Enumeration_Parameter(Notification, {"beltStatus", "middleRow3BuckleBelted"}, VehicleDataEventStatus, false)
		enumParameterInNotification:verify_Enumeration_Parameter(Notification, {"beltStatus", "leftRow3BuckleBelted"}, VehicleDataEventStatus, false)	
		enumParameterInNotification:verify_Enumeration_Parameter(Notification, {"beltStatus", "rightRow3BuckleBelted"}, VehicleDataEventStatus, false)
		enumParameterInNotification:verify_Enumeration_Parameter(Notification, {"beltStatus", "leftRearInflatableBelted"}, VehicleDataEventStatus, false)
		enumParameterInNotification:verify_Enumeration_Parameter(Notification, {"beltStatus", "rightRearInflatableBelted"}, VehicleDataEventStatus, false)
		enumParameterInNotification:verify_Enumeration_Parameter(Notification, {"beltStatus", "middleRow1BeltDeployed"}, VehicleDataEventStatus, false)
		enumParameterInNotification:verify_Enumeration_Parameter(Notification, {"beltStatus", "middleRow1BuckleBelted"}, VehicleDataEventStatus, false)
	end
	verify_beltStatus_parameter()	

	
	
	local function verify_gps_parameter()

		--[[gps: type=Common.GPSData mandatory=false	
			--name="longitudeDegrees" type="Float" minvalue="-180" maxvalue="180" mandatory="false", 
			--name="latitudeDegrees" type="Float" minvalue="-90" maxvalue="90" mandatory="false", 
			--name=pdop type=Float minvalue=0 maxvalue=10 mandatory=false
			--name=hdop type=Float minvalue=0 maxvalue=10 mandatory=false
			--name=vdop type=Float minvalue=0 maxvalue=10 mandatory=false
			--name=altitude type=Float minvalue=-10000 maxvalue=10000 mandatory=false
			--name=heading type=Float minvalue=0 maxvalue=359.99 mandatory=false
			--name=speed type=Float minvalue=0 maxvalue=500 mandatory=false

			--name="utcYear" type="Integer" minvalue="2010" maxvalue="2100" mandatory="false", 
			--name="utcMonth" type="Integer" minvalue="1" maxvalue="12" mandatory="false", 
			--name="utcDay" type="Integer" minvalue="1" maxvalue="31" mandatory="false", 
			--name="utcHours" type="Integer" minvalue="0" maxvalue="23" mandatory="false", 
			--name=utcMinutes type=Integer minvalue=0 maxvalue=59 mandatory=false
			--name=utcSeconds type=Integer minvalue=0 maxvalue=59 mandatory=false
			--name=satellites type=Integer minvalue=0 maxvalue=31 mandatory=false

			--name=actual type=Boolean mandatory=false
			
			--name=compassDirection type=Common.CompassDirection mandatory=false
			--name=dimension type=Common.Dimension mandatory=false
			]]
		
		local Notification = {rpm = 1, gps = {}}
		
		--1. IsMissed
		commonFunctions:TestCaseForNotification(self, Notification, {"gps"}, "IsMissed", nil, true)
		
		--2. IsEmptyTable
		--TODO: Update when APPLINK-15241 is resolved
		--commonFunctions:TestCaseForNotification(self, Notification, {"gps"}, "IsEmptyTable", {}, false)
		commonFunctions:TestCaseForNotification(self, Notification, {"gps"}, "IsEmptyTable", {}, true)
		
		--3. IsWrongDataType
		commonFunctions:TestCaseForNotification(self, Notification, {"gps"}, "IsWrongDataType", 123, false)
		
		--4. TCs for parameters
		local Notification = {rpm = 1, gps = {actual = true}}		
		floatParameterInNotification:verify_Float_Parameter(Notification, {"gps", "longitudeDegrees"}, {-180.000000, 180.000000}, false)
		floatParameterInNotification:verify_Float_Parameter(Notification, {"gps", "latitudeDegrees"}, {-90.000000, 90.000000}, false)
		floatParameterInNotification:verify_Float_Parameter(Notification, {"gps", "pdop"}, {0.000000, 10.000000}, false)
		floatParameterInNotification:verify_Float_Parameter(Notification, {"gps", "hdop"}, {0.000000, 10.000000}, false)	
		floatParameterInNotification:verify_Float_Parameter(Notification, {"gps", "vdop"}, {0.000000, 10.000000}, false)
		floatParameterInNotification:verify_Float_Parameter(Notification, {"gps", "altitude"}, {-10000.000000, 10000.000000}, false)
		floatParameterInNotification:verify_Float_Parameter(Notification, {"gps", "heading"}, {0.000000, 359.99}, false)
		floatParameterInNotification:verify_Float_Parameter(Notification, {"gps", "speed"}, {0.000000, 500.000000}, false)	
		
		integerParameterInNotification:verify_Integer_Parameter(Notification, {"gps", "utcYear"}, {2010, 2100}, false)
		integerParameterInNotification:verify_Integer_Parameter(Notification, {"gps", "utcMonth"}, {1, 12}, false)
		integerParameterInNotification:verify_Integer_Parameter(Notification, {"gps", "utcDay"}, {1, 31}, false)	
		integerParameterInNotification:verify_Integer_Parameter(Notification, {"gps", "utcHours"}, {0, 23}, false)	
		integerParameterInNotification:verify_Integer_Parameter(Notification, {"gps", "utcMinutes"}, {0, 59}, false)
		integerParameterInNotification:verify_Integer_Parameter(Notification, {"gps", "utcSeconds"}, {0, 59}, false)
		integerParameterInNotification:verify_Integer_Parameter(Notification, {"gps", "satellites"}, {0, 31}, false)

		local CompassDirection = {"NORTH", "NORTHWEST", "WEST", "SOUTHWEST", "SOUTH", "SOUTHEAST", "EAST", "NORTHEAST"}	
		enumParameterInNotification:verify_Enumeration_Parameter(Notification, {"gps", "compassDirection"}, CompassDirection, false)
		
		local Dimension = {"NO_FIX", "2D", "3D"}
		enumParameterInNotification:verify_Enumeration_Parameter(Notification, {"gps", "dimension"}, Dimension, false)
		
		local Notification = {rpm = 1, gps = {satellites = 1}}
		booleanParameterInNotification:verify_Boolean_Parameter(Notification, {"gps", "actual"}, false)
		
	end
	verify_gps_parameter()

	local function verify_tirePressure_parameter()
		--[[tirePressure: type=Common.TireStatus mandatory=false
			--name="pressureTelltale" type="Common.WarningLightStatus" mandatory="false"
			--name="leftFront" type="Common.SingleTireStatus" mandatory="false"
			--name="rightFront" type="Common.SingleTireStatus" mandatory="false"
			--name="leftRear" type="Common.SingleTireStatus" mandatory="false"
			--name="rightRear" type="Common.SingleTireStatus" mandatory="false"
			--name="innerLeftRear" type="Common.SingleTireStatus" mandatory="false"
			--name="innerRightRear" type="Common.SingleTireStatus" mandatory="false"]]

		--struct name="SingleTireStatus">
			--name="status" type="Common.ComponentVolumeStatus" mandatory="true": ComponentVolumeStatus = {"UNKNOWN", "NORMAL", "LOW", "FAULT", "ALERT", "NOT_SUPPORTED"}
		
		local Notification = {rpm = 1, tirePressure = {}}
		
		--1. IsMissed
		commonFunctions:TestCaseForNotification(self, Notification, {"tirePressure"}, "IsMissed", nil, true)
		
		--2. IsEmptyTable {}
		--TODO: Update when APPLINK-15241 is resolved
		--commonFunctions:TestCaseForNotification(self, Notification, {"tirePressure"}, "IsEmptyTable", {}, false)
		commonFunctions:TestCaseForNotification(self, Notification, {"tirePressure"}, "IsEmptyTable", {}, true)
		
		--3. IsWrongDataType
		commonFunctions:TestCaseForNotification(self, Notification, {"tirePressure"}, "IsWrongDataType", 123, false)
		
		
		--4. TCs for parameter: pressureTelltale
			local Notification = {rpm = 1, tirePressure = {leftFront = {status = "UNKNOWN"}}}
			local WarningLightStatus = {"OFF", "ON", "FLASH", "NOT_USED"}
			enumParameterInNotification:verify_Enumeration_Parameter(Notification, {"tirePressure", "pressureTelltale"}, WarningLightStatus, false)

		
		--5. TCs for parameters: "leftFront", "rightFront", "leftRear", "rightRear", "innerLeftRear", "innerRightRear"
			local function verify_SingleTireStatus_parameter_type(Parameter, Notification)
				
				--name="parameterName" type="Common.SingleTireStatus" mandatory="false"
					--struct name="SingleTireStatus">
						--name="status" type="Common.ComponentVolumeStatus" mandatory="true": 
				
				--1. IsMissed
				commonFunctions:TestCaseForNotification(self, Notification, Parameter, "IsMissed", nil, true)
				
				--2. IsWrongDataType
				commonFunctions:TestCaseForNotification(self, Notification, Parameter, "IsWrongDataType", 123, false)	
				
				--3. name="status" type="Common.ComponentVolumeStatus" mandatory="true"
				local Parameter_status = commonFunctions:BuildChildParameter(Parameter, "status")
				enumParameterInNotification:verify_Enumeration_Parameter(Notification, Parameter_status, ComponentVolumeStatus, true)
				
			end
			
			local Notification = {rpm = 1, tirePressure = {pressureTelltale = "OFF", leftFront = {} }}
			verify_SingleTireStatus_parameter_type({"tirePressure", "leftFront"}, Notification)
			
			local Notification = {rpm = 1, tirePressure = {pressureTelltale = "OFF", rightFront = {} }}
			verify_SingleTireStatus_parameter_type({"tirePressure", "rightFront"}, Notification)
			
			local Notification = {rpm = 1, tirePressure = {pressureTelltale = "OFF", leftRear = {} }}
			verify_SingleTireStatus_parameter_type({"tirePressure", "leftRear"}, Notification)
			
			local Notification = {rpm = 1, tirePressure = {pressureTelltale = "OFF", rightRear = {} }}
			verify_SingleTireStatus_parameter_type({"tirePressure", "rightRear"}, Notification)
			
			local Notification = {rpm = 1, tirePressure = {pressureTelltale = "OFF", innerLeftRear = {} }}
			verify_SingleTireStatus_parameter_type({"tirePressure", "innerLeftRear"}, Notification)
			
			local Notification = {rpm = 1, tirePressure = {pressureTelltale = "OFF", innerRightRear = {} }}
			verify_SingleTireStatus_parameter_type({"tirePressure", "innerRightRear"}, Notification)
		
	end
	verify_tirePressure_parameter()
	----------------------------------------------------------------------------------------------


----------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK IV----------------------------------------
----------------------------Check special cases of HMI notification---------------------------
----------------------------------------------------------------------------------------------
--Requirement id in JAMA or JIRA: 	
	--APPLINK-14765: SDL must cut off the fake parameters from requests, responses and notifications received from HMI
	
	--Verification criteria: 
		--Refer to list of test case below.
-----------------------------------------------------------------------------------------------

--List of test cases for special cases of HMI notification:
	--1. InvalidJsonSyntax
	--2. InvalidStructure
	--3. FakeParams 
	--4. FakeParameterIsFromAnotherAPI
	--5. MissedmandatoryParameters
	--6. MissedAllPArameters
	--7. SeveralNotifications with the same values
	--8. SeveralNotifications with different values
----------------------------------------------------------------------------------------------

	local function SpecialNotificationChecks()

		--Print new line to separate new test cases group
		commonFunctions:newTestCasesGroup("Test suite: Check special cases of HMI notification")

		
		--1. Verify OnVehicleData with invalid Json syntax
		----------------------------------------------------------------------------------------------
		function Test:OnVehicleData_InvalidJsonSyntax()
		
			commonTestCases:DelayedExp(1000)
			
			--hmi side: send OnVehicleData 
			--":" is changed by ";" after "jsonrpc"
			self.hmiConnection:Send('{"params":{"rpm":1},"jsonrpc";"2.0","method":"VehicleInfo.OnVehicleData"}')
		
			--mobile side: expected Notification
			EXPECT_NOTIFICATION("OnVehicleData", {})	
			:Times(0)
		end
		
		--2. Verify OnVehicleData with invalid structure
		----------------------------------------------------------------------------------------------
		function Test:OnVehicleData_InvalidJsonStructure()
			
			commonTestCases:DelayedExp(1000)
			
			--hmi side: send OnVehicleData 
			--method is moved into params parameter
			self.hmiConnection:Send('{"params":{"rpm":1,"method":"VehicleInfo.OnVehicleData"},"jsonrpc":"2.0"}')
		
			--mobile side: expected Notification
			EXPECT_NOTIFICATION("OnVehicleData", {})	
			:Times(0)
		end
		
		--3. Verify OnVehicleData with FakeParams
		----------------------------------------------------------------------------------------------
		function Test:OnVehicleData_FakeParams()
		
			local NotificationWithFakeParameters = 
			{
				fake = 123,
				speed = 0.0,
				fuelLevel = -6.000000,
				instantFuelConsumption = 0.000000,
				externalTemperature = -40.000000,
				engineTorque = -1000.000000,
				accPedalPosition = 0.000000,
				steeringWheelAngle = -2000.000000,
				rpm = 0,
				odometer = 0,
				vin = "a",
				prndl = "PARK",
				fuelLevel_State = "UNKNOWN",
				driverBraking = "NO_EVENT",
				wiperStatus = "OFF",
				headLampStatus = {	fake = 123,
									lowBeamsOn = false, 
									highBeamsOn = false, 
									ambientLightSensorStatus = "NIGHT"
								},
				deviceStatus = 	{	fake = 123,
									voiceRecOn = true,
									btIconOn = true,
									callActive = true,
									phoneRoaming = true,
									textMsgAvailable = true,
									stereoAudioOutputMuted = true,
									monoAudioOutputMuted = true,
									eCallEventActive = true,
									primaryAudioSource = "USB",
									battLevelStatus = "ZERO_LEVEL_BARS",
									signalLevelStatus = "ZERO_LEVEL_BARS"
								},
				bodyInformation={	fake = 123,
									parkBrakeActive = true, 
									driverDoorAjar = true,
									passengerDoorAjar = true,
									rearLeftDoorAjar = true,
									rearRightDoorAjar = true,
									ignitionStableStatus = "IGNITION_SWITCH_NOT_STABLE", 
									ignitionStatus = "UNKNOWN"
								},
				beltStatus = 	{	fake = 123,
									driverBeltDeployed = "NO_EVENT",
									passengerBeltDeployed = "NO_EVENT",
									passengerBuckleBelted = "NO_EVENT",
									driverBuckleBelted = "NO_EVENT",
									leftRow2BuckleBelted = "NO_EVENT",
									passengerChildDetected = "NO_EVENT",
									rightRow2BuckleBelted = "NO_EVENT",
									middleRow2BuckleBelted = "NO_EVENT",
									middleRow3BuckleBelted = "NO_EVENT",
									leftRow3BuckleBelted = "NO_EVENT",
									rightRow3BuckleBelted = "NO_EVENT",
									leftRearInflatableBelted = "NO_EVENT",
									rightRearInflatableBelted = "NO_EVENT",
									middleRow1BeltDeployed = "NO_EVENT",
									middleRow1BuckleBelted = "NO_EVENT"
								},
				gps = 			{	fake = 123,
									longitudeDegrees = -180.0,
									latitudeDegrees = -90.0,
									pdop = 0.0,
									hdop = 0.0,
									vdop = 0.0,
									altitude = -10000.0,
									heading = 0.0,
									speed = 0.0,
									
									utcYear = 2010,
									utcMonth = 1,
									utcDay = 1,
									utcHours = 0,
									utcMinutes = 0,
									utcSeconds = 0,
									satellites = 0,
									
									compassDirection = "NORTH",
									dimension = "NO_FIX",
									actual = true
								},
				tirePressure = 	{	fake = 123,
									pressureTelltale = "OFF",
									leftFront = {status = "UNKNOWN"},
									rightFront = {status = "UNKNOWN"},
									leftRear = {status = "UNKNOWN"},
									rightRear = {status = "UNKNOWN"},
									innerLeftRear = {status = "UNKNOWN"},
									innerRightRear = {status = "UNKNOWN"}
								}
			}
			
			local Notification_ExpectedResultOnMobileWithoutFakeParameters = 
			{
				speed = 0.0,
				fuelLevel = -6.000000,
				instantFuelConsumption = 0.000000,
				externalTemperature = -40.000000,
				engineTorque = -1000.000000,
				accPedalPosition = 0.000000,
				steeringWheelAngle = -2000.000000,
				rpm = 0,
				odometer = 0,
				vin = "a",
				prndl = "PARK",
				fuelLevel_State = "UNKNOWN",
				driverBraking = "NO_EVENT",
				wiperStatus = "OFF",
				headLampStatus = {	lowBeamsOn = false, 
									highBeamsOn = false, 
									ambientLightSensorStatus = "NIGHT"
								},
				deviceStatus = 	{	voiceRecOn = true,
									btIconOn = true,
									callActive = true,
									phoneRoaming = true,
									textMsgAvailable = true,
									stereoAudioOutputMuted = true,
									monoAudioOutputMuted = true,
									eCallEventActive = true,
									primaryAudioSource = "USB",
									battLevelStatus = "ZERO_LEVEL_BARS",
									signalLevelStatus = "ZERO_LEVEL_BARS"
								},
				bodyInformation={	parkBrakeActive = true, 
									driverDoorAjar = true,
									passengerDoorAjar = true,
									rearLeftDoorAjar = true,
									rearRightDoorAjar = true,
									ignitionStableStatus = "IGNITION_SWITCH_NOT_STABLE", 
									ignitionStatus = "UNKNOWN"
								},
				beltStatus = 	{	driverBeltDeployed = "NO_EVENT",
									passengerBeltDeployed = "NO_EVENT",
									passengerBuckleBelted = "NO_EVENT",
									driverBuckleBelted = "NO_EVENT",
									leftRow2BuckleBelted = "NO_EVENT",
									passengerChildDetected = "NO_EVENT",
									rightRow2BuckleBelted = "NO_EVENT",
									middleRow2BuckleBelted = "NO_EVENT",
									middleRow3BuckleBelted = "NO_EVENT",
									leftRow3BuckleBelted = "NO_EVENT",
									rightRow3BuckleBelted = "NO_EVENT",
									leftRearInflatableBelted = "NO_EVENT",
									rightRearInflatableBelted = "NO_EVENT",
									middleRow1BeltDeployed = "NO_EVENT",
									middleRow1BuckleBelted = "NO_EVENT"
								},
				gps = 			{	longitudeDegrees = -180.0,
									latitudeDegrees = -90.0,
									pdop = 0.0,
									hdop = 0.0,
									vdop = 0.0,
									altitude = -10000.0,
									heading = 0.0,
									speed = 0.0,
									utcYear = 2010,
									utcMonth = 1,
									utcDay = 1,
									utcHours = 0,
									utcMinutes = 0,
									utcSeconds = 0,
									satellites = 0,
									compassDirection = "NORTH",
									dimension = "NO_FIX",
									actual = true
								},
				tirePressure = 	{	pressureTelltale = "OFF",
									leftFront = {status = "UNKNOWN"},
									rightFront = {status = "UNKNOWN"},
									leftRear = {status = "UNKNOWN"},
									rightRear = {status = "UNKNOWN"},
									innerLeftRear = {status = "UNKNOWN"},
									innerRightRear = {status = "UNKNOWN"}
								}
			}
			
			
			
			--hmi side: sending OnVehicleData notification			
			self.hmiConnection:SendNotification("VehicleInfo.OnVehicleData", NotificationWithFakeParameters)
			
			--mobile side: expected Notification
			EXPECT_NOTIFICATION("OnVehicleData", Notification_ExpectedResultOnMobileWithoutFakeParameters)	
			:ValidIf (function(_,data)
				if data.payload.fake or
					data.payload.headLampStatus.fake or				
					data.payload.deviceStatus.fake or
					data.payload.bodyInformation.fake or
					--data.payload.beltStatus.fake or
					data.payload.gps.fake or
					data.payload.tirePressure.fake				
				then
					commonFunctions:printError(" SDL resends fake parameter to mobile app ")
					return false
				else 
					return true
				end
			end)		
		end
		
		
		--4. Verify OnVehicleData with FakeParameterIsFromAnotherAPI	
		function Test:OnVehicleData_FakeParameterIsFromAnotherAPI()
		
			local NotificationWithFakeParameters = 
			{
				sliderPosition = 123,
				speed = 0.0,
				fuelLevel = -6.000000,
				instantFuelConsumption = 0.000000,
				externalTemperature = -40.000000,
				engineTorque = -1000.000000,
				accPedalPosition = 0.000000,
				steeringWheelAngle = -2000.000000,
				rpm = 0,
				odometer = 0,
				vin = "a",
				prndl = "PARK",
				fuelLevel_State = "UNKNOWN",
				driverBraking = "NO_EVENT",
				wiperStatus = "OFF",
				headLampStatus = {	sliderPosition = 123,
									lowBeamsOn = false, 
									highBeamsOn = false, 
									ambientLightSensorStatus = "NIGHT"
								},
				deviceStatus = 	{	sliderPosition = 123,
									voiceRecOn = true,
									btIconOn = true,
									callActive = true,
									phoneRoaming = true,
									textMsgAvailable = true,
									stereoAudioOutputMuted = true,
									monoAudioOutputMuted = true,
									eCallEventActive = true,
									primaryAudioSource = "USB",
									battLevelStatus = "ZERO_LEVEL_BARS",
									signalLevelStatus = "ZERO_LEVEL_BARS"
								},
				bodyInformation={	sliderPosition = 123,
									parkBrakeActive = true, 
									driverDoorAjar = true,
									passengerDoorAjar = true,
									rearLeftDoorAjar = true,
									rearRightDoorAjar = true,
									ignitionStableStatus = "IGNITION_SWITCH_NOT_STABLE", 
									ignitionStatus = "UNKNOWN"
								},
				beltStatus = 	{	sliderPosition = 123,
									driverBeltDeployed = "NO_EVENT",
									passengerBeltDeployed = "NO_EVENT",
									passengerBuckleBelted = "NO_EVENT",
									driverBuckleBelted = "NO_EVENT",
									leftRow2BuckleBelted = "NO_EVENT",
									passengerChildDetected = "NO_EVENT",
									rightRow2BuckleBelted = "NO_EVENT",
									middleRow2BuckleBelted = "NO_EVENT",
									middleRow3BuckleBelted = "NO_EVENT",
									leftRow3BuckleBelted = "NO_EVENT",
									rightRow3BuckleBelted = "NO_EVENT",
									leftRearInflatableBelted = "NO_EVENT",
									rightRearInflatableBelted = "NO_EVENT",
									middleRow1BeltDeployed = "NO_EVENT",
									middleRow1BuckleBelted = "NO_EVENT"
								},
				gps = 			{	sliderPosition = 123,
									longitudeDegrees = -180.0,
									latitudeDegrees = -90.0,
									pdop = 0.0,
									hdop = 0.0,
									vdop = 0.0,
									altitude = -10000.0,
									heading = 0.0,
									speed = 0.0,
									utcYear = 2010,
									utcMonth = 1,
									utcDay = 1,
									utcHours = 0,
									utcMinutes = 0,
									utcSeconds = 0,
									satellites = 0,
									compassDirection = "NORTH",
									dimension = "NO_FIX",
									actual = true
								},
				tirePressure = 	{	sliderPosition = 123,
									pressureTelltale = "OFF",
									leftFront = {status = "UNKNOWN"},
									rightFront = {status = "UNKNOWN"},
									leftRear = {status = "UNKNOWN"},
									rightRear = {status = "UNKNOWN"},
									innerLeftRear = {status = "UNKNOWN"},
									innerRightRear = {status = "UNKNOWN"}
								}
			}
			
			local Notification_ExpectedResultOnMobileWithoutFakeParameters = 
			{
				speed = 0.0,
				fuelLevel = -6.000000,
				instantFuelConsumption = 0.000000,
				externalTemperature = -40.000000,
				engineTorque = -1000.000000,
				accPedalPosition = 0.000000,
				steeringWheelAngle = -2000.000000,
				rpm = 0,
				odometer = 0,
				vin = "a",
				prndl = "PARK",
				fuelLevel_State = "UNKNOWN",
				driverBraking = "NO_EVENT",
				wiperStatus = "OFF",
				headLampStatus = {	lowBeamsOn = false, 
									highBeamsOn = false, 
									ambientLightSensorStatus = "NIGHT"
								},
				deviceStatus = 	{	voiceRecOn = true,
									btIconOn = true,
									callActive = true,
									phoneRoaming = true,
									textMsgAvailable = true,
									stereoAudioOutputMuted = true,
									monoAudioOutputMuted = true,
									eCallEventActive = true,
									primaryAudioSource = "USB",
									battLevelStatus = "ZERO_LEVEL_BARS",
									signalLevelStatus = "ZERO_LEVEL_BARS"
								},
				bodyInformation={	parkBrakeActive = true, 
									driverDoorAjar = true,
									passengerDoorAjar = true,
									rearLeftDoorAjar = true,
									rearRightDoorAjar = true,
									ignitionStableStatus = "IGNITION_SWITCH_NOT_STABLE", 
									ignitionStatus = "UNKNOWN"
								},
				beltStatus = 	{	driverBeltDeployed = "NO_EVENT",
									passengerBeltDeployed = "NO_EVENT",
									passengerBuckleBelted = "NO_EVENT",
									driverBuckleBelted = "NO_EVENT",
									leftRow2BuckleBelted = "NO_EVENT",
									passengerChildDetected = "NO_EVENT",
									rightRow2BuckleBelted = "NO_EVENT",
									middleRow2BuckleBelted = "NO_EVENT",
									middleRow3BuckleBelted = "NO_EVENT",
									leftRow3BuckleBelted = "NO_EVENT",
									rightRow3BuckleBelted = "NO_EVENT",
									leftRearInflatableBelted = "NO_EVENT",
									rightRearInflatableBelted = "NO_EVENT",
									middleRow1BeltDeployed = "NO_EVENT",
									middleRow1BuckleBelted = "NO_EVENT"
								},
				gps = 			{	longitudeDegrees = -180.0,
									latitudeDegrees = -90.0,
									pdop = 0.0,
									hdop = 0.0,
									vdop = 0.0,
									altitude = -10000.0,
									heading = 0.0,
									speed = 0.0,
									utcYear = 2010,
									utcMonth = 1,
									utcDay = 1,
									utcHours = 0,
									utcMinutes = 0,
									utcSeconds = 0,
									satellites = 0,
									compassDirection = "NORTH",
									dimension = "NO_FIX",
									actual = true
								},
				tirePressure = 	{	pressureTelltale = "OFF",
									leftFront = {status = "UNKNOWN"},
									rightFront = {status = "UNKNOWN"},
									leftRear = {status = "UNKNOWN"},
									rightRear = {status = "UNKNOWN"},
									innerLeftRear = {status = "UNKNOWN"},
									innerRightRear = {status = "UNKNOWN"}
								}
			}
			
			
			
			--hmi side: sending OnVehicleData notification			
			self.hmiConnection:SendNotification("VehicleInfo.OnVehicleData", NotificationWithFakeParameters)
			
			--mobile side: expected Notification
			EXPECT_NOTIFICATION("OnVehicleData", Notification_ExpectedResultOnMobileWithoutFakeParameters)	
			:ValidIf (function(_,data)
				if data.payload.sliderPosition or
					data.payload.headLampStatus.sliderPosition or
					data.payload.deviceStatus.sliderPosition or
					data.payload.bodyInformation.sliderPosition or
					--data.payload.beltStatus.sliderPosition or
					data.payload.gps.sliderPosition or
					data.payload.tirePressure.sliderPosition				
				then
					commonFunctions:printError(" SDL resends fake parameter to mobile app ")
					return false
				else 
					return true
				end
			end)		
		end
		
		
		--5. Verify OnVehicleData misses mandatory parameter
		----------------------------------------------------------------------------------------------
		function Test:OnVehicleData_MissedmandatoryParameters()
			
			commonTestCases:DelayedExp(1000)
			
			--hmi side: sending OnVehicleData notification			
			self.hmiConnection:SendNotification("VehicleInfo.OnVehicleData", {})
			
			--mobile side: expected Notification
			EXPECT_NOTIFICATION("OnVehicleData", {})	
			:Times(0)	
		end
		
		

		--6. Verify OnVehicleData MissedAllPArameters: Covered by case 5.
		----------------------------------------------------------------------------------------------
			
		
		--7. Verify OnVehicleData with SeveralNotifications_WithTheSameValues
		----------------------------------------------------------------------------------------------
		function Test:OnVehicleData_SeveralNotifications_WithTheSameValues()

			--hmi side: sending OnVehicleData notification			
			self.hmiConnection:SendNotification("VehicleInfo.OnVehicleData", {rpm = 1})
			self.hmiConnection:SendNotification("VehicleInfo.OnVehicleData", {rpm = 1})
			self.hmiConnection:SendNotification("VehicleInfo.OnVehicleData", {rpm = 1})
			
			--mobile side: expected Notification
			EXPECT_NOTIFICATION("OnVehicleData", {rpm = 1},
												{rpm = 1},
												{rpm = 1})
				:Times(3)
		end
		
		
		
		--8. Verify OnVehicleData with SeveralNotifications_WithDifferentValues
		----------------------------------------------------------------------------------------------	
		function Test:OnVehicleData_SeveralNotifications_WithDifferentValues()

			--hmi side: sending OnVehicleData notification			
			self.hmiConnection:SendNotification("VehicleInfo.OnVehicleData", {rpm = 1})
			self.hmiConnection:SendNotification("VehicleInfo.OnVehicleData", {speed = 2})
			
			--mobile side: expected Notification
			EXPECT_NOTIFICATION("OnVehicleData", {rpm = 1},
												{speed = 2})
				:Times(2)
			
		end
		
	end

	SpecialNotificationChecks()	



-----------------------------------------------------------------------------------------------
-------------------------------------------TEST BLOCK V----------------------------------------
-------------------------------------Checks All Result Codes-----------------------------------
-----------------------------------------------------------------------------------------------

--Description: Check all resultCodes

--Not Applicable

	
----------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK VI----------------------------------------
-------------------------Sequence with emulating of user's action(s)--------------------------
----------------------------------------------------------------------------------------------

--Description: TC's checks SDL behavior by processing
	-- different request sequence with timeout
	-- with emulating of user's actions	

--Requirement id in JAMA: 
	--N/A
	
	--Verification criteria: Verify SDL behaviors in different states of policy table: 
		--1. Notification is not exist in PT => DISALLOWED in policy table, SDL ignores the notification
		--2. Notification is exist in PT but it has not consented yet by user => DISALLOWED in policy table, SDL ignores the notification
		--3. Notification is exist in PT but user does not allow function group that contains this notification => USER_DISALLOWED in policy table, SDL ignores the notification
		--4. Notification is exist in PT and user allow function group that contains this notification
----------------------------------------------------------------------------------------------

	local function SequenceChecks()

		--Print new line to separate new test cases group
		commonFunctions:newTestCasesGroup("Test suite: Sequence with emulating of user's action(s)")

		
	--1. Notification is not exist in PT => DISALLOWED in policy table, SDL ignores the notification
	----------------------------------------------------------------------------------------------
		--Precondition: Build policy table file
		local PTName = testCasesForPolicyTable:createPolicyTableWithoutAPI("OnVehicleData")
		
		--Precondition: Update policy table
		testCasesForPolicyTable:updatePolicy(PTName)
			
		--Send notification and check it is ignored
		function Test:OnVehicleData_IsNotExistInPT_Disallowed()
		
			commonTestCases:DelayedExp(1000)
			
			--hmi side: send notification
			self.hmiConnection:SendNotification("VehicleInfo.OnVehicleData", {speed = 1})	  		
			
			--mobile side: expected Notification
			EXPECT_NOTIFICATION("OnVehicleData", Notification)	
			:Times(0)				
		end
	----------------------------------------------------------------------------------------------
		
		
		
	--2. Notification is allowed but parameters are not allowed => DISALLOWED in policy table, SDL ignores the notification
	----------------------------------------------------------------------------------------------
		--Precondition: Build policy table file
		local PermissionLines_OnVehicleData_NotAllowParameters = 
[[					"OnVehicleData": {
						"hmi_levels": [
						  "BACKGROUND",
						  "FULL",
						  "LIMITED"
						],
						"parameters": [
							"rpm", 
							"fuelLevel", 
							"fuelLevel_State", 
							"instantFuelConsumption", 
							"externalTemperature", 
							"prndl", 
							"tirePressure", 
							"odometer"						
					   ]
					  }]]
					  
		local PermissionLinesForBase4 = PermissionLines_OnVehicleData_NotAllowParameters .. ", \n"
		local PermissionLinesForGroup1 = nil
		local PermissionLinesForApplication = nil
		local PTName = testCasesForPolicyTable:createPolicyTableFile(PermissionLinesForBase4, PermissionLinesForGroup1, PermissionLinesForApplication, {"OnVehicleData"})	
		
		testCasesForPolicyTable:updatePolicy(PTName)
			
		--Send notification and check it is ignored
		function Test:OnVehicleData_IsAllowedButParameterIsNotAllowed_Disallowed()
		
			commonTestCases:DelayedExp(1000)
			
			--hmi side: send notification
			self.hmiConnection:SendNotification("VehicleInfo.OnVehicleData", {speed = 1})	  		
			
			--mobile side: expected Notification
			EXPECT_NOTIFICATION("OnVehicleData", Notification)	
			:Times(0)				
		end
	----------------------------------------------------------------------------------------------
		
		
			
		
		
	--3. Notification is exist in PT but it has not consented yet by user => DISALLOWED in policy table, SDL ignores the notification
	----------------------------------------------------------------------------------------------
		--Precondition: Build policy table file
		local PermissionLinesForBase4 = PermissionLines_SubscribeVehicleData .. ", \n"
		local PermissionLinesForGroup1 = PermissionLines_OnVehicleData .. "\n"
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
		function Test:OnVehicleData_UserHasNotConsentedYet_Disallowed()
			
			commonTestCases:DelayedExp(1000)
			
			--hmi side: send notification
			self.hmiConnection:SendNotification("VehicleInfo.OnVehicleData", {speed = 1})	  		
			
			--mobile side: expected Notification
			EXPECT_NOTIFICATION("OnVehicleData", Notification)	
			:Times(0)				
		end
	----------------------------------------------------------------------------------------------
		
		
	--4. Notification is exist in PT but user does not allow function group that contains this notification => USER_DISALLOWED in policy table, SDL ignores the notification
	----------------------------------------------------------------------------------------------	
		--Precondition: User does not allow function group
		testCasesForPolicyTable:userConsent(false, "group1")		
		
		function Test:OnVehicleData_UserDisallowed()
		
			commonTestCases:DelayedExp(1000)
			
			--hmi side: send notification
			self.hmiConnection:SendNotification("VehicleInfo.OnVehicleData", {speed = 1})	  		
			
			--mobile side: expected Notification
			EXPECT_NOTIFICATION("OnVehicleData", Notification)	
			:Times(0)	
		end
	----------------------------------------------------------------------------------------------
		
	
	--5. Notification is exist in PT and user allow function group that contains this notification
	----------------------------------------------------------------------------------------------
		--Precondition: User allows function group
		testCasesForPolicyTable:userConsent(true, "group1")		
		
		function Test:OnVehicleData_SUCCESS()
			--hmi side: send notification
			self.hmiConnection:SendNotification("VehicleInfo.OnVehicleData", {speed = 1})	  		
			
			--mobile side: expected Notification
			EXPECT_NOTIFICATION("OnVehicleData", Notification)	
		end
	----------------------------------------------------------------------------------------------	
	end
	
	--TODO: PT is blocked by ATF defect APPLINK-19188
	--SequenceChecks()

	
----------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK VII---------------------------------------
--------------------------------------Different HMIStatus-------------------------------------
----------------------------------------------------------------------------------------------

--Description: Check different HMIStatus

--Requirement id in JAMA: 	
	--SDLAQ-CRS-1304: HMI Status Requirements for OnVehicleData (FULL, LIMITED, BACKGROUND)
	
	--Verification criteria: 
		--None of the applications in HMI NONE receives OnVehicleData request.
		--The applications in HMI FULL don't reject OnVehicleData request.
		--The applications in HMI LIMITED don't reject OnVehicleData request.
		--The applications in HMI BACKGROUND don't reject OnVehicleData request.

	local function DifferentHMIlevelChecks()

		--Print new line to separate new test cases group
		commonFunctions:newTestCasesGroup("Test suite: Different HMI Level Checks")
		----------------------------------------------------------------------------------------------

		--1. HMI level is NONE
		----------------------------------------------------------------------------------------------
			--Precondition: Deactivate app to NONE HMI level	
			commonSteps:DeactivateAppToNoneHmiLevel()

			function Test:OnVehicleData_Notification_InNoneHmiLevel()
			
				commonTestCases:DelayedExp(1000)
				
				
				local Notification_AllParametersLowBound = 
				{
					speed = 0.0,
					fuelLevel = -6.000000,
					instantFuelConsumption = 0.000000,
					externalTemperature = -40.000000,
					engineTorque = -1000.000000,
					accPedalPosition = 0.000000,
					steeringWheelAngle = -2000.000000,
					rpm = 0,
					odometer = 0,
					vin = "a",
					prndl = "PARK",
					fuelLevel_State = "UNKNOWN",
					driverBraking = "NO_EVENT",
					wiperStatus = "OFF",
					headLampStatus = {	lowBeamsOn = false, 
										highBeamsOn = false, 
										ambientLightSensorStatus = "NIGHT"
									},
					deviceStatus = 	{	voiceRecOn = true,
										btIconOn = true,
										callActive = true,
										phoneRoaming = true,
										textMsgAvailable = true,
										stereoAudioOutputMuted = true,
										monoAudioOutputMuted = true,
										eCallEventActive = true,
										primaryAudioSource = "USB",
										battLevelStatus = "ZERO_LEVEL_BARS",
										signalLevelStatus = "ZERO_LEVEL_BARS"
									},
					bodyInformation={	parkBrakeActive = true, 
										driverDoorAjar = true,
										passengerDoorAjar = true,
										rearLeftDoorAjar = true,
										rearRightDoorAjar = true,
										ignitionStableStatus = "IGNITION_SWITCH_NOT_STABLE", 
										ignitionStatus = "UNKNOWN"
									},
					beltStatus = 	{	driverBeltDeployed = "NO_EVENT",
										passengerBeltDeployed = "NO_EVENT",
										passengerBuckleBelted = "NO_EVENT",
										driverBuckleBelted = "NO_EVENT",
										leftRow2BuckleBelted = "NO_EVENT",
										passengerChildDetected = "NO_EVENT",
										rightRow2BuckleBelted = "NO_EVENT",
										middleRow2BuckleBelted = "NO_EVENT",
										middleRow3BuckleBelted = "NO_EVENT",
										leftRow3BuckleBelted = "NO_EVENT",
										rightRow3BuckleBelted = "NO_EVENT",
										leftRearInflatableBelted = "NO_EVENT",
										rightRearInflatableBelted = "NO_EVENT",
										middleRow1BeltDeployed = "NO_EVENT",
										middleRow1BuckleBelted = "NO_EVENT"
									},
					gps = 			{	longitudeDegrees = -180.0,
										latitudeDegrees = -90.0,
										pdop = 0.0,
										hdop = 0.0,
										vdop = 0.0,
										altitude = -10000.0,
										heading = 0.0,
										speed = 0.0,
										utcYear = 2010,
										utcMonth = 1,
										utcDay = 1,
										utcHours = 0,
										utcMinutes = 0,
										utcSeconds = 0,
										satellites = 0,
										compassDirection = "NORTH",
										dimension = "NO_FIX",
										actual = true
									},
					tirePressure = 	{	pressureTelltale = "OFF",
										leftFront = {status = "UNKNOWN"},
										rightFront = {status = "UNKNOWN"},
										leftRear = {status = "UNKNOWN"},
										rightRear = {status = "UNKNOWN"},
										innerLeftRear = {status = "UNKNOWN"},
										innerRightRear = {status = "UNKNOWN"}
									}
				}
				
				
				--hmi side: send notification
				self.hmiConnection:SendNotification("VehicleInfo.OnVehicleData", Notification_AllParametersLowBound)	  		
				
				--mobile side: expected Notification
				EXPECT_NOTIFICATION("OnVehicleData", {})	
				:Times(0)				
			end			
						
			--Postcondition: Activate app
			commonSteps:ActivationApp()	
		----------------------------------------------------------------------------------------------


		--2. HMI level is LIMITED
		----------------------------------------------------------------------------------------------
			if commonFunctions:isMediaApp() then
				-- Precondition: Change app to LIMITED
				commonSteps:ChangeHMIToLimited()

				OnVehicleData_AllParametersLowerBound_SUCCESS("OnVehicleData_Notification_InLimitedHmiLevel")
				
				--Postcondition: Activate app
				commonSteps:ActivationApp()	
			end
		----------------------------------------------------------------------------------------------

		
		--3. HMI level is BACKGROUND
		----------------------------------------------------------------------------------------------
			--Precondition:
			commonTestCases:ChangeAppToBackgroundHmiLevel()
			
			OnVehicleData_AllParametersLowerBound_SUCCESS("OnVehicleData_Notification_InBackgroundHmiLevel")
		----------------------------------------------------------------------------------------------
	end
	DifferentHMIlevelChecks()

	
	
return Test	
