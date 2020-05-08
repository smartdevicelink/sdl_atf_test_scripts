--TODO:  update test later
Test = require('connecttest')
local mobile_session = require('mobile_session')
local mobile = require("mobile_connection")
local tcp = require("tcp_connection")
local file_connection = require("file_connection")
require('cardinalities')
local events = require('events')

local srcPath = config.pathToSDL .. "sdl_preloaded_pt.json"
local dstPath = config.pathToSDL .. "sdl_preloaded_pt.json.origin"
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
--ToDo: shall be removed when APPLINK-16610 is fixed
config.defaultProtocolVersion = 2
---------------------------------------------------------------------------------------------
-----------------------------Required Shared Libraries---------------------------------------
---------------------------------------------------------------------------------------------
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')

local floatParameterInNotification = require('user_modules/shared_testcases/testCasesForFloatParameterInNotification')
local stringParameterInNotification = require('user_modules/shared_testcases/testCasesForStringParameterInNotification')
local stringArrayParameterInNotification = require('user_modules/shared_testcases/testCasesForArrayStringParameterInNotification')
local imageParameterInNotification = require('user_modules/shared_testcases/testCasesForImageParameterInNotification')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local commonPreconditions = require ('/user_modules/shared_testcases/commonPreconditions')
local SDLConfig = require('user_modules/shared_testcases/SmartDeviceLinkConfigurations')
require('user_modules/AppTypes')
---------------------------------------------------------------------------------------------
------------------------------------ Common Variables ---------------------------------------
---------------------------------------------------------------------------------------------
APIName="OnWayPointChange"
strMaxLengthFileName255 = string.rep("a", 251)  .. ".png" -- set max length file name
local SDLConfig = require ('user_modules/shared_testcases/SmartDeviceLinkConfigurations')
local storagePath = config.pathToSDL .. SDLConfig:GetValue("AppStorageFolder") .. "/" .. tostring(config.application1.registerAppInterfaceParams.fullAppID .. "_" .. tostring(config.deviceMAC) .. "/")

---------------------------------------------------------------------------------------------
------------------------------------ Common Functions ---------------------------------------
---------------------------------------------------------------------------------------------

function Test:subcribleWayPoints()
	--mobile side: send SubscribeWayPoints request
    local CorIdSWP = self.mobileSession:SendRPC("SubscribeWayPoints",{})

    --hmi side: expected SubscribeWayPoints request
    EXPECT_HMICALL("Navigation.SubscribeWayPoints")

    :Do(function(_,data)
        --hmi side: sending Navigation.SubscribeWayPoints response
        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
      end)

    --mobile side: SubscribeWayPoints response
    EXPECT_RESPONSE("SubscribeWayPoints", {success = true , resultCode = "SUCCESS"})

    EXPECT_NOTIFICATION("OnHashChange")
end


function Test:unSubcribeWayPoints()
	--mobile side: sending UnsubscribeWayPoints request
	local cid = self.mobileSession:SendRPC("UnsubscribeWayPoints",{})
	
	--hmi side: expect UnsubscribeWayPoints request
	EXPECT_HMICALL("Navigation.UnsubscribeWayPoints")
	:Do(function(_,data)
		--hmi side: sending Navigation.UnsubscribeWayPoints response
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})	
	end)
	
	--mobile side: expect UnsubscribeWayPoints response
	EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
	
	--mobile side: expect OnHashChange notification
	EXPECT_NOTIFICATION("OnHashChange")
end

function Test:verify_SUCCESS_Notification_Case(notifications)
	
	self.hmiConnection:SendNotification("Navigation.OnWayPointChange", notifications)	  		
	
	--mobile side: expected SubscribeVehicleData response
	EXPECT_NOTIFICATION("OnWayPointChange", notifications)	
		
end

function Test:verify_Notification_IsIgnored_Case(notifications)
	
	commonTestCases:DelayedExp(1000)
	
	self.hmiConnection:SendNotification("Navigation.OnWayPointChange", notifications)	  		
	
	--mobile side: expected Notification
	EXPECT_NOTIFICATION("OnWayPointChange", notifications)	
	:Times(0)
			
end

function Test:registerAppInterface2()

	config.application2.registerAppInterfaceParams.isMediaApplication=false
	config.application2.registerAppInterfaceParams.appHMIType={"DEFAULT"}
	
	--mobile side: sending request 
	local CorIdRegister = self.mobileSession1:SendRPC("RegisterAppInterface", config.application2.registerAppInterfaceParams)

	--hmi side: expect BasicCommunication.OnAppRegistered request
	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
		{
			application = 
			{
				appName = config.application2.registerAppInterfaceParams.appName
			}
		})
		:Do(function(_,data)
			self.applications[config.application2.registerAppInterfaceParams.appName] = data.params.application.appID					
		end)

	--mobile side: expect response
	self.mobileSession1:ExpectResponse(CorIdRegister, 
		{
			syncMsgVersion = config.syncMsgVersion
		})
		:Timeout(2000)

	--mobile side: expect notification
	self.mobileSession1:ExpectNotification("OnHMIStatus", {systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
	:Timeout(2000)
end	

function Test:registerAppInterface3()
	--mobile side: sending request 
	local CorIdRegister = self.mobileSession2:SendRPC("RegisterAppInterface", config.application3.registerAppInterfaceParams)

	--hmi side: expect BasicCommunication.OnAppRegistered request
	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
		{
			application = 
				{
					appName = config.application3.registerAppInterfaceParams.appName
				}
		})
		:Do(function(_,data)
			self.applications[config.application3.registerAppInterfaceParams.appName] = data.params.application.appID					
	end)

	--mobile side: expect response
	self.mobileSession2:ExpectResponse(CorIdRegister, 
		{
			syncMsgVersion = config.syncMsgVersion
		})
		:Timeout(2000)

	--mobile side: expect notification
	self.mobileSession2:ExpectNotification("OnHMIStatus", { systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
		:Timeout(2000)
end		
------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------
	--Activation App
	commonSteps:ActivationApp()

	--PutFiles
	commonSteps:PutFile( "PutFile_MinLength", "a")
	commonSteps:PutFile( "PutFile_icon.png", "icon.png")
	commonSteps:PutFile( "PutFile_action.png", "action.png")
	commonSteps:PutFile( "PutFile_MaxLength_255Characters", strMaxLengthFileName255)
	
	local PermissionLines_SubcribeWayPoints = 
[[					"SubscribeWayPoints": {
						"hmi_levels": [
						  "BACKGROUND",
						  "FULL",
						  "LIMITED"
						]
					  }]]

	local PermissionLines_OnWayPointChange = 
[[					"OnWayPointChange": {
						"hmi_levels": [
						  "BACKGROUND",
						  "FULL",
						  "LIMITED"
						]
					  }]]

	local PermissionLinesForBase4 = PermissionLines_SubcribeWayPoints .. ", \n" .. PermissionLines_OnWayPointChange ..", \n"
	local PermissionLinesForGroup1 = nil
	local PermissionLinesForApplication = nil
	
	--NOTE: This TC is blocked on ATF 2.2 by defect APPLINK-19188. Please try ATF on commit f86f26112e660914b3836c8d79002e50c7219f29
	-- local PTName = testCasesForPolicyTable:createPolicyTableFile(PermissionLinesForBase4, PermissionLinesForGroup1, PermissionLinesForApplication)	
	-- testCasesForPolicyTable:updatePolicy(PTName)	
	
	-- TODO: Remove after implementation policy update
	--make backup copy of file sdl_preloaded_pt.json
	commonPreconditions:BackupFile("sdl_preloaded_pt.json")
	-- TODO: Remove after implementation policy update
	-- Precondition: remove policy table
	commonSteps:DeletePolicyTable()
	-- TODO: Remove after implementation policy update
	-- Precondition: replace preloaded file with new one
	os.execute('cp ./files/ptu_general.json ' .. tostring(config.pathToSDL) .. "sdl_preloaded_pt.json")
	--SubscribleWayPoints 
	function Test:Precondition_SubscribleWayPoints()
		self:subcribleWayPoints()
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
----------------------------------Check normal cases of HMI Response--------------------------
-----------------------------------------------------------------------------------------------
commonFunctions:newTestCasesGroup("****************************** Test suite III: HMIResponseCheck ******************************")	

--Param: name="wayPoints" type="LocationDetails" mandatory="true" array="true" minsize="1" maxsize="10"
--[[ 	name="coordinate" type="Coordinate" mandatory="false"
		name="locationName" type="String" maxlength="500" mandatory="false"
		name="addressLines" type="String" maxlength="500" minsize="0" maxsize="4" array="true" mandatory="false"
		name="locationDescription" type="String" maxlength="500" mandatory="false"
		name="phoneNumber" type="String" maxlength="500" mandatory="false"
		name="locationImage" type="Image" mandatory="false"
		name="searchAddress" type="OASISAddress" mandatory="false"
		name="countryName" minlength="0" maxlength="200" type="String" mandatory="false"
--]]
----------------------------------------------------------------------------------------

--Coordinate structure:
--[[ 	name="latitudeDegrees" minvalue="-90" maxvalue="90" type="Double" mandatory="true"
		name="longitudeDegrees" minvalue="-180" maxvalue="180" type="Double" mandatory="true" 
--]]
-----------------------------------------------------------------------------------------

--OASISAddress stucture:
--[[ 	name="countryCode" minlength="0" maxlength="50" type="String" mandatory="false"
		name="countryCode" minlength="0" maxlength="50" type="String" mandatory="false"
		name="postalCode" minlength="0" maxlength="16" type="String" mandatory="false"
		name="administrativeArea" minlength="0" maxlength="200" type="String" mandatory="false"
		name="subAdministrativeArea" minlength="0" maxlength="200" type="String" mandatory="false"
		name="locality" minlength="0" maxlength="200" type="String" mandatory="false"
		name="subLocality" minlength="0" maxlength="200" type="String" mandatory="false"
		name="thoroughfare" minlength="0" maxlength="200" type="String" mandatory="false
		name="subThoroughfare" minlength="0" maxlength="200" type="String" mandatory="false" 
--]]
--------------------------------------------------------------------------------------------

--Verification criteria
--[[
	1. Only Mandatory param
	2. Mandatory param is missed
	2. All parameters are lower bound
	3. All parameters are upper bound
	4. Verify each params 
--]]
------------------------------------------------------------------------------------------------

--Related Requirement: APPLINK-21351, APPLINK-9736
------------------------------------------------------------------------------------------------

	local function common_Test_Cases_For_OnWayPointChange()
	
		--This TC intends to check when all params are valid, SDL should send OnWayPointChange notitifcation to mobile app
		function Test:OnWayPointChange_ParamsAreValid()
		local notifications= 
		{
			wayPoints =
			{
				{
					coordinate={
						latitudeDegrees = -90,
						longitudeDegrees = -180
					 },
					locationName="Ho Chi Minh",
					addressLines={"182 Le Dai Hanh"},
					locationDescription="Toa nha Flemington",
					phoneNumber="1231414",
					locationImage={
						value = storagePath .."icon.png",
						imageType = "DYNAMIC"
					},
					searchAddress={
						countryName="aaa",
						countryCode="084",
						postalCode="test",
						administrativeArea="aa",
						subAdministrativeArea="a",
						locality="a",
						subLocality="a",
						thoroughfare="a",
						subThoroughfare="a"
					}
				}
			}
		}
		self:verify_SUCCESS_Notification_Case(notifications)
		end
		
		--This TC intends to check when mandatory param is missed, SDL shouldn't send OnWayPointChange notitifcation to mobile app
		function Test:OnWayPointChange_Mandatory_IsMissed()
			local param ={wayPoints ={{}}}
			self:verify_Notification_IsIgnored_Case(wayPoints)
		end
		
		--This TC intends to check when all params are lower bound value
		function Test:OnWayPointChange_AllParametersAreLowerBound()
			local  notifications = 
			{
			    wayPoints =
				{
					{
						coordinate={
							longitudeDegrees = -180.0,
							latitudeDegrees = -90.0
						},
						locationName="a",
						addressLines={"a"},
						locationDescription="a",
						phoneNumber="a",
						locationImage={
							value = storagePath .."a.png",
							imageType = "DYNAMIC",
						},
						searchAddress={
							countryName="a",
							countryCode="a",
							postalCode="a",
							administrativeArea="a",
							subAdministrativeArea="a",
							locality="a",
							subLocality="a",
							thoroughfare="a",
							subThoroughfare="a"
						}
					}
				}
			}
			self:verify_SUCCESS_Notification_Case(notifications)
		end
		
		--This TC intends to check when all params are upper bound value
		function Test:OnWayPointChange_AllParametersAreUpperBound()
			local strMaxLength500= string.rep("a", 500)
			local strMaxLength200= string.rep("b", 200)
			local strMaxLength50= string.rep("c", 50)
			local strMaxLength16= string.rep("d", 16)
			local notifications =
			{
				wayPoints =
				{
					{
						coordinate={
							longitudeDegrees = 180.0,
							latitudeDegrees = 90.0
						},
						locationName=strMaxLength500,
						addressLines={strMaxLength500},
						locationDescription=strMaxLength500,
						phoneNumber=strMaxLength500,
						locationImage={
							value = storagePath ..strMaxLengthFileName255,
							imageType = "DYNAMIC"
						},
						searchAddress={
							countryName=strMaxLength200,
							countryCode=strMaxLength50,
							postalCode=strMaxLength16,
							administrativeArea=strMaxLength200,
							subAdministrativeArea=strMaxLength200,
							locality=strMaxLength200,
							subLocality=strMaxLength200,
							thoroughfare=strMaxLength200,
							subThoroughfare=strMaxLength200
						}
					}
				}
			}
			self:verify_SUCCESS_Notification_Case(notifications)
		end
		
		--This TCs intends to check when only coordinate parameter
		function Test:OnWayPointChange_OnlyMandatoryParameters_SUCCESS_coordinate()
			local notifications =
			{
				wayPoints =
				{
					{
						coordinate={
							longitudeDegrees = 180.0,
							latitudeDegrees = 90.0
						}
					}
				}
			}
			self:verify_SUCCESS_Notification_Case(notifications)
		end
		
		--This TCs intends to check when only locationName parameter
		function Test:OnWayPointChange_OnlyMandatoryParameters_SUCCESS_locationName()
			local notifications =
			{
				wayPoints =
				{
					{
						locationName="HCM"
					}
				}
			}
			self:verify_SUCCESS_Notification_Case(notifications)
		end
		
		--This TCs intends to check when only addressLines parameter
		function Test:OnWayPointChange_OnlyMandatoryParameters_SUCCESS_addressLines()
			local notifications =
			{
				wayPoints =
				{
					{
						addressLines={"HCM"}
					}
				}
			}
			self:verify_SUCCESS_Notification_Case(notifications)
		end
		
		--This TCs intends to check when only locationDescription parameter
		function Test:OnWayPointChange_OnlyMandatoryParameters_SUCCESS_locationDescription()
			local notifications =
			{
				wayPoints =
				{
					{
						locationDescription="HCM"
					}
				}
			}
			self:verify_SUCCESS_Notification_Case(notifications)
		end
		
		--This TCs intends to check when only phoneNumber parameter
		function Test:OnWayPointChange_OnlyMandatoryParameters_SUCCESS_phoneNumber()
			local notifications =
			{
				wayPoints =
				{
					{
						phoneNumber="HCM"
					}
				}
			}
			self:verify_SUCCESS_Notification_Case(notifications)
		end
		
		--This TCs intends to check when only locationImage parameter
		function Test:OnWayPointChange_OnlyMandatoryParameters_SUCCESS_locationImage()
			local notifications =
			{	
				wayPoints =
				{
					{	
						locationImage={
							value = storagePath .."a",
							imageType = "DYNAMIC"
						}
					}
				}
			}
			self:verify_SUCCESS_Notification_Case(notifications)
		end
		
		--This TCs intends to check when only searchAddress parameter
		function Test:OnWayPointChange_OnlyMandatoryParameters_SUCCESS_searchAddress()
			local notifications =
			{
				wayPoints=
				{
					{
						searchAddress={
							countryName="aaa",
							countryCode="084",
							postalCode="test",
							administrativeArea="aa",
							subAdministrativeArea="a",
							locality="a",
							subLocality="a",
							thoroughfare="a",
							subThoroughfare="a"
						}
					}
				}
			}
			self:verify_SUCCESS_Notification_Case(notifications)
		end
		
	end
	common_Test_Cases_For_OnWayPointChange()
	
	--1.name="locationName" type="String" maxlength="500" mandatory="false"
	local notifications =
	{
		wayPoints=
		{
			{
				locationName="a"
			}
		}
	}
	stringParameterInNotification:verify_String_Parameter(notifications, {"wayPoints", 1,"locationName"}, {1, 500}, false, true)
	
	--2. name="coordinate" type="Coordinate" mandatory="false"
	local function verify_Cordinate_Paramerter()
		local notifications =
		{
			wayPoints=
			{
				{	
					coordinate={
						latitudeDegrees = -90,
						longitudeDegrees = -180
					}
				}
			}
		}
		
		floatParameterInNotification:verify_Float_Parameter(notifications, {"wayPoints", 1, "coordinate", "longitudeDegrees"}, {-180, 180}, true)
		floatParameterInNotification:verify_Float_Parameter(notifications, {"wayPoints", 1, "coordinate", "latitudeDegrees"}, {-90, 90}, true)
	end
	verify_Cordinate_Paramerter()
	
	--3. name="addressLines" type="String" maxlength="500" minsize="0" maxsize="4" array="true" mandatory="false"
	local notifications =
	{
		wayPoints=
		{
			{
				addressLines={"a"}
			}
		}
	}
	stringArrayParameterInNotification:verify_Array_String_Parameter(notifications, {"wayPoints", 1, "addressLines"}, {1,4},{1,500},false,true)
	
	--4. name="locationDescription" type="String" maxlength="500" mandatory="false"
	local notifications =
	{
		wayPoints=
		{
			{
				locationName="a"
			}
		}
	}
	stringParameterInNotification:verify_String_Parameter(notifications, { "wayPoints", 1,"locationDescription"}, {1, 500}, false, true)
	
	--5. name="phoneNumber" type="String" maxlength="500" mandatory="false"
	local notifications =
	{
		wayPoints=
		{
			{
				locationName="a"
			}
		}
	}
	stringParameterInNotification:verify_String_Parameter(notifications, {"wayPoints", 1,"phoneNumber"}, {1, 500}, false, true)
	
	--6. name="searchAddress" type="OASISAddress" mandatory="false"
	local function verify_sreach_address()
		local notifications =
		{	
			wayPoints=
			{
				{
					searchAddress={
								countryName="a",
								countryCode="a",
								postalCode="a",
								administrativeArea="a",
								subAdministrativeArea="a",
								locality="a",
								subLocality="a",
								thoroughfare="a",
								subThoroughfare="a"
							},
					locationName="a"
				}
			}
		}
		stringParameterInNotification:verify_String_Parameter(notifications, {"wayPoints", 1, "searchAddress", "countryName" }, {0, 200}, false, true)
		stringParameterInNotification:verify_String_Parameter(notifications, {"wayPoints", 1, "searchAddress","countryCode" }, {0, 50}, false, true)
		stringParameterInNotification:verify_String_Parameter(notifications, {"wayPoints", 1, "searchAddress","postalCode" }, {0, 16}, false, true)
		stringParameterInNotification:verify_String_Parameter(notifications, {"wayPoints", 1, "searchAddress","administrativeArea" }, {0, 200}, false, true)
		stringParameterInNotification:verify_String_Parameter(notifications, {"wayPoints", 1, "searchAddress","subAdministrativeArea" }, {0, 200}, false, true)
		stringParameterInNotification:verify_String_Parameter(notifications, {"wayPoints", 1, "searchAddress","locality" }, {0, 200}, false, true)
		stringParameterInNotification:verify_String_Parameter(notifications, {"wayPoints", 1, "searchAddress","subLocality" }, {0, 200}, false, true)
		stringParameterInNotification:verify_String_Parameter(notifications, {"wayPoints", 1, "searchAddress","thoroughfare" }, {0, 200}, false, true)
		stringParameterInNotification:verify_String_Parameter(notifications, {"wayPoints", 1, "searchAddress","subThoroughfare" }, {0, 200}, false, true)
	end 
	verify_sreach_address()
	--7. name="locationImage" type="Image" mandatory="false"
	local notifications =
	{
		wayPoints=
		{
			{		
				locationImage={
					value = storagePath .."a",
					imageType = "DYNAMIC"
				},
				locationName="a"
			}
		}
	}
	imageParameterInNotification:verify_Image_Parameter(notifications, {"wayPoints", 1,"locationImage"}, {"", strMaxLengthFileName255}, false)
	
commonFunctions:newTestCasesGroup("****************************** End Test suite III: HMIResponseCheck ******************************")	

----------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK IV----------------------------------------
----------------------------Check special cases of HMI notification---------------------------
----------------------------------------------------------------------------------------------
--Related requirements: APPLINK-14765

--Verification criteria
--[[ 
	1.InvalidJsonSyntax
	2. InvalidStructure
	3. FakeParams 
	4. FakeParameterIsFromAnotherAPI
	5. SeveralNotifications with the same values
	6. SeveralNotifications with different values
--]]
commonFunctions:newTestCasesGroup("****************************** Begin Test suite IV: SpecialHMIResponseCheck ******************************")	

local function SpecialNotificationChecks()

	--1. Verify OnWayPointChange with invalid Json syntax
	----------------------------------------------------------------------------------------------
	function Test:OnWayPointChange_InvalidJsonSyntax()
	
		commonTestCases:DelayedExp(1000)
		
		--hmi side: send OnWayPointChange 
		--":" is changed by ";" after "jsonrpc"
		self.hmiConnection:Send('{"params":{"wayPoints":{locationName;"test"}},"jsonrpc";"2.0","method":"Navigation.OnWayPointChange"}')
	
		--mobile side: expected Notification
		EXPECT_NOTIFICATION("OnWayPointChange", {})	
		:Times(0)
	end
	
	--2. Verify OnWayPointChange with invalid structure
	----------------------------------------------------------------------------------------------
	function Test:OnWayPointChange_InvalidJsonStructure()
		
		commonTestCases:DelayedExp(1000)
		
		--hmi side: send OnWayPointChange 
		--method is moved into params parameter
		self.hmiConnection:Send('{"params":{"wayPoints":{locationName;"test"},"method":"Navigation.OnWayPointChange"},"jsonrpc":"2.0"}')
	
		--mobile side: expected Notification
		EXPECT_NOTIFICATION("OnWayPointChange", {})	
		:Times(0)
	end
	
	--3. Verify OnWayPointChange with FakeParams
	----------------------------------------------------------------------------------------------
	function Test:OnWayPointChange_FakeParams()
	
		local NotificationWithFakeParameters = 
		{
			wayPoints=
			{
				{
					coordinate={
						longitudeDegrees = -180.0,
						latitudeDegrees = -90.0,
						fake="a"
					},
					locationName="Ho Chi Minh",
					addressLines={"182 Le Dai Hanh"},
					locationDescription="Toa nha Flemington",
					phoneNumber="1231414",
					locationImage={
						value = storagePath .."icon.png",
						imageType = "DYNAMIC",
						fake="a"
					},
					searchAddress={
						countryName="aaa",
						countryCode="084",
						postalCode="test",
						administrativeArea="aa",
						subAdministrativeArea="a",
						locality="a",
						subLocality="a",
						thoroughfare="a",
						subThoroughfare="a",
						fake="a"
					},
					fake="fakeparam"
				}
			}
		}
		
		local Notification_ExpectedResultOnMobileWithoutFakeParameters = 
		{
			wayPoints=
			{
				{
					coordinate={
						longitudeDegrees = -180.0,
						latitudeDegrees = -90.0
					},
					locationName="Ho Chi Minh",
					addressLines={"182 Le Dai Hanh"},
					locationDescription="Toa nha Flemington",
					phoneNumber="1231414",
					locationImage={
						value = storagePath .."icon.png",
						imageType = "DYNAMIC"
					},
					searchAddress={
						countryName="aaa",
						countryCode="084",
						postalCode="test",
						administrativeArea="aa",
						subAdministrativeArea="a",
						locality="a",
						subLocality="a",
						thoroughfare="a",
						subThoroughfare="a"
					}
				}
			}
		}
		
		--hmi side: sending OnWayPointChange notification			
		self.hmiConnection:SendNotification("Navigation.OnWayPointChange", NotificationWithFakeParameters)
		
		--mobile side: expected OnWayPointChange Notification
		EXPECT_NOTIFICATION("OnWayPointChange", Notification_ExpectedResultOnMobileWithoutFakeParameters)	
		:ValidIf (function(_,data)
			if data.payload.fake or
				data.payload.coordinate.fake or				
				data.payload.searchAddress.fake or
				data.payload.locationImage.fake	
			then
				commonFunctions:printError(" SDL resends fake parameter to mobile app ")
				return false
			else 
				return true
			end
		end)		
	end
	
	--4. Verify OnWayPointChange with FakeParameterIsFromAnotherAPI	
	function Test:OnWayPointChange_FakeParameterIsFromAnotherAPI()
	
		local NotificationWithFakeParameters = 
		{
			wayPoints=
			{
				{
					coordinate={
						longitudeDegrees = -180.0,
						latitudeDegrees = -90.0,
						sliderPosition=4
					},
					locationName="Ho Chi Minh",
					addressLines={"182 Le Dai Hanh"},
					locationDescription="Flemington building",
					phoneNumber="1231414",
					locationImage={
						value = storagePath .."icon.png",
						imageType = "DYNAMIC",
						sliderPosition=4
					},
					searchAddress={
						countryName="aaa",
						countryCode="084",
						postalCode="test",
						administrativeArea="aa",
						subAdministrativeArea="a",
						locality="a",
						subLocality="a",
						thoroughfare="a",
						subThoroughfare="a",
						sliderPosition=4
					},
					sliderPosition=4
				}
			}
		}
		
		local Notification_ExpectedResultOnMobileWithoutFakeParameters = 
		{
			wayPoints=
			{
				{
					coordinate={
						longitudeDegrees = -180.0,
						latitudeDegrees = -90.0
					},
					locationName="Ho Chi Minh",
					addressLines={"182 Le Dai Hanh"},
					locationDescription="Toa nha Flemington",
					phoneNumber="1231414",
					locationImage={
						value = storagePath .."icon.png",
						imageType = "DYNAMIC"
					},
					searchAddress={
						countryName="aaa",
						countryCode="084",
						postalCode="test",
						administrativeArea="aa",
						subAdministrativeArea="a",
						locality="a",
						subLocality="a",
						thoroughfare="a",
						subThoroughfare="a"
					}
				}
			}
		}
		
		--hmi side: sending OnWayPointChange notification			
		self.hmiConnection:SendNotification("Navigation.OnWayPointChange", NotificationWithFakeParameters)
		
		--mobile side: expected OnWayPointChange Notification
		EXPECT_NOTIFICATION("OnWayPointChange", Notification_ExpectedResultOnMobileWithoutFakeParameters)	
		:ValidIf (function(_,data)
			if data.payload.sliderPosition or
				data.payload.coordinate.sliderPosition or				
				data.payload.searchAddress.sliderPosition or
				data.payload.locationImage.sliderPosition			
			then
				commonFunctions:printError(" SDL resends sliderPosition to mobile app ")
				return false
			else 
				return true
			end
		end)		
	end
		
	--5. Verify OnWayPointChange with SeveralNotifications_WithTheSameValues
	----------------------------------------------------------------------------------------------
	function Test:OnWayPointChange_SeveralNotifications_WithTheSameValues()

		--hmi side: sending OnWayPointChange notification			
		self.hmiConnection:SendNotification("Navigation.OnWayPointChange",{wayPoints={{locationName="a"}}})
		self.hmiConnection:SendNotification("Navigation.OnWayPointChange",{wayPoints={{locationName="a"}}})
		self.hmiConnection:SendNotification("Navigation.OnWayPointChange",{wayPoints={{locationName="a"}}})
		
		--mobile side: expected Notification
		EXPECT_NOTIFICATION("OnWayPointChange", 
			{wayPoints={{locationName="a"}}},
			{wayPoints={{locationName="a"}}},
			{wayPoints={{locationName="a"}}}
		)
		:Times(3)
	end
	
	--6. Verify OnWayPointChange with SeveralNotifications_WithDifferentValues
	----------------------------------------------------------------------------------------------	
	function Test:OnWayPointChange_SeveralNotifications_WithDifferentValues()

		--hmi side: sending OnWayPointChange notification			
		self.hmiConnection:SendNotification("Navigation.OnWayPointChange", {wayPoints={{locationName="a"}}})
		self.hmiConnection:SendNotification("Navigation.OnWayPointChange", {wayPoints={{locationDescription="Toa nha Flemington"}}})
		
		--mobile side: expected OnWayPointChange Notification
		EXPECT_NOTIFICATION("OnWayPointChange", 
			{wayPoints={{locationName="a"}}},
			{wayPoints={{locationDescription="Toa nha Flemington"}}})
			:Times(2)
	end
	
end

-- SpecialNotificationChecks()	
	
commonFunctions:newTestCasesGroup("****************************** End Test suite IV: SpecialHMIResponseCheck ******************************")	
--------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK V---------------------------------------
--------------------------------------Check All Result Codes--------------------------------
--------------------------------------------------------------------------------------------

--Not Applicable

----------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK VI----------------------------------------
-------------------------Sequence with emulating of user's action(s)--------------------------
----------------------------------------------------------------------------------------------	
-- Verification criteria
--[[ 
	--1. Notification only be sent to app that already SubscribeWayPoints
	--2. Notification is not exist in PT => SDL ignores the notification
	--3. Notification is exist in PT but it has not consented yet by user => SDL ignores the notification
	--4. Notification is exist in PT but user does not allow function group that contains this notification => SDL ignores the notification
	--5. Notification is exist in PT and user allow function group that contains this notification => SDL sends notification to mobile app
--]]
commonFunctions:newTestCasesGroup("****************************** Begin Test suite VI: Sequence with emulation of user's action ******************************")	

-- local function SequenceChecks()
	----------------------------------------------------------------------------------------------
	--1. Notification only be sent to app that already SubscribeWayPoints
	----------------------------------------------------------------------------------------------
	commonFunctions:newTestCasesGroup("Notification only be sent to app that already SubscribeWayPoints")
	
	local function Case_3Apps()
		function Test:AddTheSecondSession()
			self.mobileSession1 = mobile_session.MobileSession(
			self,
			self.mobileConnection)
			self.mobileSession1:StartService(7)
		end	
			
		function Test:Case_3Apps_Register_SecondApp()
			config.application2.registerAppInterfaceParams.appHMIType = {"COMMUNICATION"}
			config.application2.registerAppInterfaceParams.isMediaApplication = false
			self:registerAppInterface2()
		end
		
		function Test:AddTheThirdSession()
			self.mobileSession2 = mobile_session.MobileSession(
			self,
			self.mobileConnection)
			self.mobileSession2:StartService(7)
		end	
		
		function Test:Case_3Apps_Register_ThirdApp()
			config.application3.registerAppInterfaceParams.appHMIType = {"NAVIGATION"}
			config.application3.registerAppInterfaceParams.isMediaApplication = false
			self:registerAppInterface3()
		end
		
		function Test:Case_3Apps_Activate_SecondApp()
		
			local rid = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[config.application2.registerAppInterfaceParams.appName]})
			
			EXPECT_HMIRESPONSE(rid)
				:Do(function(_,data)
						if data.result.code ~= 0 then
						quit()
						end
				end)
			
			self.mobileSession1:ExpectNotification("OnHMIStatus",{hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
		end
		
		function Test:Case_3Apps_Activate_ThirdApp()
		
			local rid = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[config.application3.registerAppInterfaceParams.appName]})
			
			EXPECT_HMIRESPONSE(rid)
				:Do(function(_,data)
						if data.result.code ~= 0 then
						quit()
						end
				end)
			
			self.mobileSession1:ExpectNotification("OnHMIStatus",{hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
			self.mobileSession2:ExpectNotification("OnHMIStatus",{hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
		
		end
		
		function Test:Case_3Apps_OnlySend_OnWayPointChange_ToApp1()
		
			--hmi side: send notification
			self.hmiConnection:SendNotification("Navigation.OnWayPointChange", {wayPoints={{locationName="a"}}})	  		  		
			
			--mobile side: expected Notification
			EXPECT_NOTIFICATION("OnWayPointChange", {locationName = "a"})	
			
			self.mobileSession1:ExpectNotification("OnWayPointChange", {wayPoints={{locationName="a"}}})
			:Times(0)
			self.mobileSession2:ExpectNotification("OnWayPointChange", {wayPoints={{locationName="a"}}})
			:Times(0)
			
			commonTestCases:DelayedExp(1000)
		end
		
		function Test:Case_3Apps_SubscribleWayPoints_App2()
		
			--mobile side: send SubscribeWayPoints request
			local cid = self.mobileSession1:SendRPC("SubscribeWayPoints",{})

			--mobile side: expect SubscribeWayPoints response
			self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
			
			--mobile side: expect OnHashChange notification
			self.mobileSession1:ExpectNotification("OnHashChange",{})
			
		end
		
		function Test:Case_3Apps_Send_OnWayPointChange_ToApp1AndApp2()
			--hmi side: send notification
			self.hmiConnection:SendNotification("Navigation.OnWayPointChange", {wayPoints={{locationName="a"}}})	  		  		
			
			--mobile side: expected Notification
			EXPECT_NOTIFICATION("OnWayPointChange", {wayPoints={{locationName="a"}}})	
			
			self.mobileSession1:ExpectNotification("OnWayPointChange", {wayPoints={{locationName="a"}}})
			
			self.mobileSession2:ExpectNotification("OnWayPointChange", {wayPoints={{locationName="a"}}})
			:Times(0)
			
			commonTestCases:DelayedExp(1000)
		end
		
		function Test:Case_3Apps_SubscribleWayPoints_App3()
		
			--mobile side: send SubscribeWayPoints request
			local cid = self.mobileSession2:SendRPC("SubscribeWayPoints",{})			
			--mobile side: expect SubscribeWayPoints response
			self.mobileSession2:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
			
			--mobile side: expect OnHashChange notification
			self.mobileSession2:ExpectNotification("OnHashChange",{})
		end
		
		function Test:Case_3Apps_Send_OnWayPointChange_To3Apps()
			--hmi side: send notification
			self.hmiConnection:SendNotification("Navigation.OnWayPointChange", {wayPoints={{locationName="a"}}})	  		  		
			
			--mobile side: expected Notification
			EXPECT_NOTIFICATION("OnWayPointChange", {wayPoints={{locationName="a"}}})	
			self.mobileSession1:ExpectNotification("OnWayPointChange", {wayPoints={{locationName="a"}}})
			self.mobileSession2:ExpectNotification("OnWayPointChange", {wayPoints={{locationName="a"}}})
		end
		
		function Test:Case_3Apps_PostCondition_Unregister_App2_App3()
		
			local cid1 = self.mobileSession1:SendRPC("UnregisterAppInterface",{})
			self.mobileSession1:ExpectResponse(cid1, { success = true, resultCode = "SUCCESS"})
			:Timeout(2000)
			
			local cid2 = self.mobileSession2:SendRPC("UnregisterAppInterface",{})
			self.mobileSession2:ExpectResponse(cid2, { success = true, resultCode = "SUCCESS"})
			:Timeout(2000)
		end 

		commonSteps:ActivationApp(_,"Case_3Apps_Postcondition_ActivateApp1")
	end 
	Case_3Apps()
	----------------------------------------------------------------------------------------------
	--2. Notification is not exist in PT => SDL ignores the notification
	----------------------------------------------------------------------------------------------
	commonFunctions:newTestCasesGroup("Notification is not exist in PT => SDL ignores the notification")
	
	--Precondition: Build policy table file
	local PTName = testCasesForPolicyTable:createPolicyTableWithoutAPI("OnWayPointChange")
	
	--Precondition: Update policy table
	testCasesForPolicyTable:updatePolicy(PTName)
		
	--Send notification and check it is ignored
	function Test:OnWayPointChange_IsNotExistInPT_Ignored()
	
		commonTestCases:DelayedExp(1000)
		
		--hmi side: send notification
		self.hmiConnection:SendNotification("Navigation.OnWayPointChange", {wayPoints={{locationName="a"}}})	  		
		
		--mobile side: expected Notification
		EXPECT_NOTIFICATION("OnWayPointChange", {wayPoints={{locationName="a"}}})	
		:Times(0)				
	end	
	
	--Postcondition: Update policy table to allow OnWayPointChange
	testCasesForPolicyTable:updatePolicy("./files/ptu_general.json")
	
	----------------------------------------------------------------------------------------------

commonFunctions:newTestCasesGroup("****************************** End Test suite VI: Sequence with emulation of user's action ******************************")	
---------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK VII---------------------------------------
--------------------------------------Different HMIStatus-------------------------------------
----------------------------------------------------------------------------------------------
-- Verification criteria
--[[
	1. One app is None
	2. One app is Limited
	3. One app is Background
	
--]]

commonFunctions:newTestCasesGroup("****************************** Begin Test suite VII: Different HMI Level Checks ******************************")

local function DifferentHMIlevelChecks()

	--1. HMI level is NONE
	----------------------------------------------------------------------------------------------
	--Precondition: Deactivate app to NONE HMI level	
	commonSteps:DeactivateAppToNoneHmiLevel()

	function Test:OnWayPointChange_Notification_InNoneHmiLevel()
	
		commonTestCases:DelayedExp(1000)
		local notifications =
		{
			wayPoints = 
			{
				{
					coordinate={
						longitudeDegrees = -180.0,
						latitudeDegrees = -90.0
					},
					locationName="Ho Chi Minh",
					addressLines={"182 Le Dai Hanh"},
					locationDescription="Toa nha Flemington",
					phoneNumber="1231414",
					locationImage={
						value = storagePath .."icon.png",
						imageType = "DYNAMIC"
					},
					searchAddress={
						countryName="aaa",
						countryCode="084",
						postalCode="test",
						administrativeArea="aa",
						subAdministrativeArea="a",
						locality="a",
						subLocality="a",
						thoroughfare="a",
						subThoroughfare="a"
					}
				}
			}
		}			
		--hmi side: send notification
		self.hmiConnection:SendNotification("Navigation.OnWayPointChange", notifications)	  		
		
		--mobile side: expected Notification
		EXPECT_NOTIFICATION("OnWayPointChange", notifications)	
		:Times(0)				
	end			
				
	--Postcondition: Activate app
	commonSteps:ActivationApp(_,"Postcondition_OnWayPointChange_CaseAppIsNone")	

	--2. HMI level is LIMITED
	----------------------------------------------------------------------------------------------
	if commonFunctions:isMediaApp() then
		commonSteps:ChangeHMIToLimited()
		function Test:OnWayPointChange_Notification_InLimitedHmiLevel()
			local notifications =
			{
				wayPoints = 
				{
					{
						coordinate={
							longitudeDegrees = -180.0,
							latitudeDegrees = -90.0
						},
						locationName="Ho Chi Minh",
						addressLines={"182 Le Dai Hanh"},
						locationDescription="Toa nha Flemington",
						phoneNumber="1231414",
						locationImage={
							value = storagePath .."icon.png",
							imageType = "DYNAMIC"
						},
						searchAddress={
							countryName="aaa",
							countryCode="084",
							postalCode="test",
							administrativeArea="aa",
							subAdministrativeArea="a",
							locality="a",
							subLocality="a",
							thoroughfare="a",
							subThoroughfare="a"
						}
					}
				}
			}			
			--hmi side: send notification
			self.hmiConnection:SendNotification("Navigation.OnWayPointChange", notifications)	  		
			
			--mobile side: expected Notification
			EXPECT_NOTIFICATION("OnWayPointChange", notifications)	
			
		end
	
	end
	--Postcondition: Activate app
	commonSteps:ActivationApp(_,"Postcondition_OnWayPointChange_Notification_InLimitedHmiLevel_ActivateApp")	
	
	--3. HMI level is BACKGROUND
	----------------------------------------------------------------------------------------------
	commonTestCases:ChangeAppToBackgroundHmiLevel()
	
	function Test:OnWayPointChange_Notification_InBackgroundHmiLevel()
		local notifications =
		{
			wayPoints = 
			{
				{
					coordinate={
						longitudeDegrees = -180.0,
						latitudeDegrees = -90.0
					},
					locationName="Ho Chi Minh",
					addressLines={"182 Le Dai Hanh"},
					locationDescription="Toa nha Flemington",
					phoneNumber="1231414",
					locationImage={
						value = storagePath .."icon.png",
						imageType = "DYNAMIC"
					},
					searchAddress={
						countryName="aaa",
						countryCode="084",
						postalCode="test",
						administrativeArea="aa",
						subAdministrativeArea="a",
						locality="a",
						subLocality="a",
						thoroughfare="a",
						subThoroughfare="a"
					}
				}
			}
		}			
		--hmi side: send notification
		self.hmiConnection:SendNotification("Navigation.OnWayPointChange", notifications)	  		
		
		--mobile side: expected Notification
		EXPECT_NOTIFICATION("OnWayPointChange", notifications)	
			
	end
	
end

DifferentHMIlevelChecks()

commonFunctions:newTestCasesGroup("****************************** End Test suite VII: Different HMI Level Checks ******************************")

-- Postcondition: restoring sdl_preloaded_pt file
-- TODO: Remove after implementation policy update
function Test:Postcondition_Preloadedfile()
  print ("restoring sdl_preloaded_pt.json")
  commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
end

return Test
