-- ATF version: 2.2

--------------------------------------------------------------------------------
-- Preconditions
--------------------------------------------------------------------------------
local Preconditions = require('user_modules/shared_testcases/commonPreconditions')

--------------------------------------------------------------------------------
--Precondition: preparation connecttest_sendLocation.lua
Preconditions:Connecttest_without_ExitBySDLDisconnect("connecttest_sendLocation.lua")

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

Test = require('user_modules/connecttest_sendLocation')
require('cardinalities')
local events = require('events')
local mobile_session = require('mobile_session')
local mobile  = require('mobile_connection')
local tcp = require('tcp_connection')
local file_connection  = require('file_connection')
local json  = require('json')
local module = require('testbase')

---------------------------------------------------------------------------------------------
-----------------------------Required Shared Libraries---------------------------------------
---------------------------------------------------------------------------------------------
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local stringParameter = require('user_modules/shared_testcases/testCasesForStringParameter')
local enumerationParameter = require('user_modules/shared_testcases/testCasesForEnumerationParameter')
local imageParameter = require('user_modules/shared_testcases/testCasesForImageParameter')
local arraySoftButtonsParameter = require('user_modules/shared_testcases/testCasesForArraySoftButtonsParameter')
local arrayStringParameter = require('user_modules/shared_testcases/testCasesForArrayStringParameter')
local integerParameter = require('user_modules/shared_testcases/testCasesForIntegerParameter')
local floatParamter = require('user_modules/shared_testcases/testCasesForFloatParameter')
local doubleParamter = require('user_modules/shared_testcases/testCasesForDoubleParameter')
local policyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
----------------------------------------------------------------------------
-- User required files
require('user_modules/AppTypes')
local SDLConfig = require('user_modules/shared_testcases/SmartDeviceLinkConfigurations')

---------------------------------------------------------------------------------------------
------------------------------------ Common Variables ---------------------------------------
---------------------------------------------------------------------------------------------
APIName = "SendLocation" -- set request name
strMaxLengthFileName255 = string.rep("a", 251)  .. ".png" -- set max length file name

config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

local storagePath = config.pathToSDL .. SDLConfig:GetValue("AppStorageFolder") .. "/" .. tostring(config.application1.registerAppInterfaceParams.fullAppID .. "_" .. tostring(config.deviceMAC) .. "/")

---------------------------------------------------------------------------------------------
-------------------------- Overwrite These Functions For This Script-------------------------
---------------------------------------------------------------------------------------------
--Specific functions for this script
--1. createRequest()
--2. createUIParameters(RequestParams)
--3. verify_SUCCESS_Case(RequestParams)
--4. verify_INVALID_DATA_Case(RequestParams)
---------------------------------------------------------------------------------------------

--Create default request parameters
function Test:createRequest()

	return {		
		longitudeDegrees = 1.1,
		latitudeDegrees = 1.1
	}
	
end

---------------------------------------------------------------------------------------------

--Create UI expected result based on parameters from the request
function Test:createUIParameters(RequestParams)
	local param =  {}
	
	if RequestParams["locationImage"]  ~= nil then
		param["locationImage"] =  RequestParams["locationImage"]
		if param["locationImage"].imageType == "DYNAMIC" then			
			param["locationImage"].value = storagePath .. param["locationImage"].value
		end	
	end	

	if RequestParams["longitudeDegrees"] ~= nil then
		param["longitudeDegrees"] = RequestParams["longitudeDegrees"]
	end

	if RequestParams["latitudeDegrees"] ~= nil then
		param["latitudeDegrees"] = RequestParams["latitudeDegrees"]
	end

	if RequestParams["locationName"] ~= nil then
		param["locationName"] = RequestParams["locationName"]
	end

	if RequestParams["locationDescription"] ~= nil then
		param["locationDescription"] = RequestParams["locationDescription"]
	end

	if RequestParams["addressLines"] ~= nil then
		param["addressLines"] = RequestParams["addressLines"]
	end
	
	if RequestParams["deliveryMode"] ~= nil then
		param["deliveryMode"] = RequestParams["deliveryMode"]
	end
	
	if RequestParams["phoneNumber"] ~= nil then
		param["phoneNumber"] = RequestParams["phoneNumber"]
	end

	if RequestParams["address"] ~= nil then
		local addressParams = {"countryName", "countryCode", "postalCode", "administrativeArea", "subAdministrativeArea", "locality", "subLocality", "thoroughfare", "subThoroughfare"}
		local parameterFind = false
		param.address = {}
		for i=1, #addressParams do
			if RequestParams.address[addressParams[i]] ~= nil then
				param.address[addressParams[i]] = RequestParams.address[addressParams[i]]
				parameterFind = true
			end
		end
		if
			parameterFind == false then
			param.address = nil
		end

	end

	if RequestParams["timeStamp"] ~= nil then
		param.timeStamp = {}
		local timeStampParams = {"second", "minute", "hour", "day", "month", "year", "tz_hour", "tz_minute"}

		for i=1, #timeStampParams do
			if 
				RequestParams.timeStamp[timeStampParams[i]] ~= nil then
					param.timeStamp[timeStampParams[i]] = RequestParams.timeStamp[timeStampParams[i]]
			else
				if RequestParams.timeStamp["tz_hour"] == nil then
					param.timeStamp["tz_hour"] = 0
				end

				if RequestParams.timeStamp["tz_minute"] == nil then
					param.timeStamp["tz_minute"] = 0
				end
			end
		end
	end
		
	return param
end
---------------------------------------------------------------------------------------------

--This function sends a request from mobile and verify result on HMI and mobile for SUCCESS resultCode cases.
function Test:verify_SUCCESS_Case(RequestParams)

	local temp = json.encode(RequestParams)

	local cid = 0
	if string.find(temp, "{}") ~= nil or string.find(temp, "{{}}") ~= nil then						
		temp = string.gsub(temp, "{}", "[]")
		temp = string.gsub(temp, "{{}}", "[{}]")

		if string.find(temp, "\"address\":%[%]") ~= nil then
			temp = string.gsub(temp, "\"address\":%[%]", "\"address\":{}")
		end

		if string.find(temp, "\"timeStamp\":%[%]") ~= nil then
			temp = string.gsub(temp, "\"timeStamp\":%[%]", "\"timeStamp\":{}")
		end

		self.mobileSession.correlationId = self.mobileSession.correlationId + 1

		cid = self.mobileSession.correlationId

		local msg = 
		{
			serviceType      = 7,
			frameInfo        = 0,
			rpcType          = 0,
			rpcFunctionId    = 39,
			rpcCorrelationId = cid,				
			payload          = temp
		}
		self.mobileSession:Send(msg)
	else
		--mobile side: sending SendLocation request
		cid = self.mobileSession:SendRPC("SendLocation", RequestParams)
	end
	
	UIParams = self:createUIParameters(RequestParams)
	
	if 
		RequestParams.longitudeDegrees and
		RequestParams.latitudeDegrees and 
		RequestParams.address == {} then
			--hmi side: expect Navigation.SendLocation request
			EXPECT_HMICALL("Navigation.SendLocation", UIParams)
			:Do(function(_,data)
				--hmi side: sending Navigation.SendLocation response
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end)
			:ValidIf(function(_,data)
				if data.params.address then
					commonFunctions:userPrint(31,"Navigation.SendLocation contain address parameter in request when should be omitted")
					return false
				else
					return true
				end
			end)
	else
		--hmi side: expect Navigation.SendLocation request
		EXPECT_HMICALL("Navigation.SendLocation", UIParams)
		:Do(function(_,data)
			--hmi side: sending Navigation.SendLocation response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)
	end

	--mobile side: expect SendLocation response
	EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })			
end

---------------------------------------------------------------------------------------------

--This function sends a request from mobile with INVALID_DATA and verify result on mobile.
function Test:verify_INVALID_DATA_Case(RequestParams)
	local temp = json.encode(RequestParams)
	local cid = 0
	if string.find(temp, "{}") ~= nil or string.find(temp, "{{}}") ~= nil then						
		temp = string.gsub(temp, "{}", "[]")
		temp = string.gsub(temp, "{{}}", "[{}]")

		if string.find(temp, "\"address\":%[%]") ~= nil then
			temp = string.gsub(temp, "\"address\":%[%]", "\"address\":{}")
		end
		
		self.mobileSession.correlationId = self.mobileSession.correlationId + 1

		cid = self.mobileSession.correlationId

		local msg = 
		{
			serviceType      = 7,
			frameInfo        = 0,
			rpcType          = 0,
			rpcFunctionId    = 39,
			rpcCorrelationId = cid,	
			payload          = temp
		}
		self.mobileSession:Send(msg)
	else
		--mobile side: sending SendLocation request
		cid = self.mobileSession:SendRPC("SendLocation", RequestParams)
	end

	--mobile side: expect SendLocation response
	EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
	
end

---------------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------
	--------------------------------------------------------------------------------------------------------
	-- Precondition for SendLocation script execution: Because of APPLINK-17511 SDL defect hmi_capabilities.json need to be updated : added textfields locationName, locationDescription, addressLines, phoneNumber.
	--------------------------------------------------------------------------------------------------------
	-- Precondition function is added needed fields.
	-- TODO: need to be removed after resolving APPLINK-17511

	-- Verify config.pathToSDL
	commonSteps:CheckSDLPath()

	-- Update hmi_capabilities.json
	local HmiCapabilities = config.pathToSDL .. "hmi_capabilities.json"

	Preconditions:BackupFile("hmi_capabilities.json")

	f = assert(io.open(HmiCapabilities, "r"))

	fileContent = f:read("*all")

	fileContentTextFields = fileContent:match("%s-\"%s?textFields%s?\"%s-:%s-%[[%w%d%s,:%{%}\"]+%]%s-,?")

		if not fileContentTextFields then
			print ( " \27[31m  textFields is not found in hmi_capabilities.json \27[0m " )
		else

			fileContentTextFieldsContant = fileContent:match("%s-\"%s?textFields%s?\"%s-:%s-%[([%w%d%s,:%{%}\"]+)%]%s-,?")

			if not fileContentTextFieldsContant then
				print ( " \27[31m  textFields contant is not found in hmi_capabilities.json \27[0m " )
			else

				fileContentTextFieldsContantTab = fileContent:match("%s-\"%s?textFields%s?\"%s-:%s-%[.+%{\n([^\n]+)(\"name\")")

				local StringToReplace = fileContentTextFieldsContant

				fileContentLocationNameFind = fileContent:match("locationName")
				if not fileContentLocationNameFind then
					local ContantToAdd = ",\n " .. tostring(fileContentTextFieldsContantTab)  .. "  { \"name\": \"locationName\",\"characterSet\": \"UTF_8\",\"width\": 500,\"rows\": 1 }"
					StringToReplace = StringToReplace .. ContantToAdd
				end

				fileContentLocationDescriptionFind = fileContent:match("locationDescription")
				if not fileContentLocationDescriptionFind then
					local ContantToAdd = ",\n " .. tostring(fileContentTextFieldsContantTab)  .. "  { \"name\": \"locationDescription\",\"characterSet\": \"UTF_8\",\"width\": 500,\"rows\": 1 }"
					StringToReplace = StringToReplace .. ContantToAdd
				end

				fileContentAddressLinesFind = fileContent:match("addressLines")
				if not fileContentAddressLinesFind then
					local ContantToAdd = ",\n " .. tostring(fileContentTextFieldsContantTab)  .. "  { \"name\": \"addressLines\",\"characterSet\": \"UTF_8\",\"width\": 500,\"rows\": 1 }"
					StringToReplace = StringToReplace .. ContantToAdd
				end

				fileContentPhoneNumberFind = fileContent:match("phoneNumber")
				if not fileContentPhoneNumberFind then
					local ContantToAdd = ",\n " .. tostring(fileContentTextFieldsContantTab)  .. "  { \"name\": \"phoneNumber\",\"characterSet\": \"UTF_8\",\"width\": 500,\"rows\": 1 }"
					StringToReplace = StringToReplace .. ContantToAdd
				end

				fileContentUpdated  =  string.gsub(fileContent, fileContentTextFieldsContant, StringToReplace)
				f = assert(io.open(HmiCapabilities, "w"))
				f:write(fileContentUpdated)
				f:close()

			end
		end
        --------------------------------------------------------------------------------------------------------
		-- Postcondition: removing user_modules/connecttest_sendLocation.lua, restore hmi_capabilities
		function Test:Postcondition_remove_user_connecttest_restore_hmi_capabilities()
		 	os.execute( "rm -f ./user_modules/connecttest_sendLocation.lua" )
		 	Preconditions:RestoreFile("hmi_capabilities.json")
		end
	--------------------------------------------------------------------------------------------------------
	-- Precondition: deleting logs, policy table
	commonSteps:DeleteLogsFileAndPolicyTable()

	--------------------------------------------------------------------------------------------------------

	-- 1. Update policy to allow request
	policyTable:precondition_updatePolicy_AllowFunctionInHmiLeves({"BACKGROUND", "FULL", "LIMITED", "NONE"})

	-- 2. Restore preloaded_pt
	--policyTable:Restore_preloaded_pt()

	-- 3. Activate application
	commonSteps:ActivationAppGenivi()

	-- 4. PutFiles ("a", "icon.png", "action.png", strMaxLengthFileName255)
	commonSteps:PutFile( "PutFile_MinLength", "a")
	commonSteps:PutFile( "PutFile_icon.png", "icon.png")
	commonSteps:PutFile( "PutFile_action.png", "action.png")
	commonSteps:PutFile( "PutFile_MaxLength_255Characters", strMaxLengthFileName255)

-------------------------------------------------------------------------------------------
	

-----------------------------------------------------------------------------------------------
-------------------------------------------TEST BLOCK I----------------------------------------
--------------------------------Check normal cases of Mobile request---------------------------
-----------------------------------------------------------------------------------------------

--Requirement id in JAMA or JIRA: 	
	-- APPLINK-9735
    -- APPLINK-16076
    -- APPLINK-21923
    -- APPLINK-21924 
    -- APPLINK-16133
    -- APPLINK-16118
    -- APPLINK-16115
    -- APPLINK-16110
    -- APPLINK-21925
    -- APPLINK-16109
	-- APPLINK-21909
	-- APPLINK-21910
	-- APPLINK-24180
	-- APPLINK-24215
	
--Verification criteria: 
	-- Verify request with valid and invalid values of parameters; 
	-- SDL must treat integer value for params of float type as valid
	-- In case mobile app sends SendLocation_request to SDL with "address" parameter and without both "longtitudeDegrees" and "latitudeDegrees" parameters with any others params related to request SDL must: consider such request as valid transfer SendLocation_request to HMI respond with <resultCode_received_from_HMI> to mobile app
	-- In case mobile app sends SendLocation_request to SDL  with "address" parameter and without both "longtitudeDegrees" and "latitudeDegrees" parameters with any others params related to request SDL must: consider such request as valid transfer SendLocation_request to HMI respond with <resultCode_received_from_HMI> to mobile app
	-- In case the request comes to SDL with empty value"" in "String" type parameters (including parameters of the structures), SDL must respond with resultCode "INVALID_DATA" and success:"false" value.
	-- In case the request comes to SDL with wrong type parameters (including parameters of the structures), SDL must respond with resultCode "INVALID_DATA" and success:"false" value.
	-- In case the request comes without parameters defined as mandatory in mobile API, SDL must respond with resultCode "INVALID_DATA" and success:"false" value.
	-- In case the request comes to SDL with out-of-bounds array ranges or out-of-bounds parameters values (including parameters of the structures) of any type, SDL must respond with resultCode "INVALID_DATA" and success:"false" value.
	-- In case mobile app sends SendLocation_request to SDL  with OR without "address" parameter and with just "longtitudeDegrees" OR with just "latitudeDegrees" parameters with any others params related to request SDL must: respond "INVALID_DATA, success:false" to mobile app
	-- In case the request comes with '\n' and-or '\t' and-or 'whitespace'-as-the-only-symbol(s) at any "String" type parameter in the request structure, SDL must respond with resultCode "INVALID_DATA" and success:"false" value.
-----------------------------------------------------------------------------------------------

	--List of parameters in the request:
	--1. name="longitudeDegrees" type="Float" minvalue="-180" maxvalue="180" mandatory="false"
	--2. name="latitudeDegrees" type="Float" minvalue="-90" maxvalue="90" mandatory="false"
	--3. name="locationName" type="String" maxlength="500" mandatory="false"
	--4. name="locationDescription" type="String" maxlength="500" mandatory="false"
	--5. name="addressLines" type="String" maxlength="500" minsize="0" maxsize="4" array="true" mandatory="false"
	--6. name="phoneNumber" type="String" maxlength="500" mandatory="false"
	--7. name="locationImage" type="Image" mandatory="false"
	--8. name="timeStamp" type="DateTime" mandatory="false"
	--9. name="address" type="OASISAddress" mandatory="false"
	
-----------------------------------------------------------------------------------------------
--Common Test cases:
--1. Positive cases
--2. All parameters are lower bound
--3. All parameters are upper bound
--4. Mandatory only
--5. Check allowance of deliveryMode

--1.2, 2.2, 3.2, 4.2 longitudeDegrees and latitudeDegrees are integer values
-----------------------------------------------------------------------------------------------

    --Check 1.1
     local Request = {
        longitudeDegrees = 1.1,
		latitudeDegrees = 1.1,
		address = {
			countryName = "countryName",
			countryCode = "countryName",
			postalCode = "postalCode",
			administrativeArea = "administrativeArea",
			subAdministrativeArea = "subAdministrativeArea",
			locality = "locality",
			subLocality = "subLocality",
			thoroughfare = "thoroughfare",
			subThoroughfare = "subThoroughfare"
		},
		timestamp = {
			second = 40,
			minute = 30,
			hour = 14,
			day = 25,
			month = 5,
			year = 2017,
			tz_hour = 5,
			tz_minute = 30
		},
		locationName = "location Name",
		locationDescription = "location Description",
		addressLines = 
		{ 
			"line1",
			"line2",
		}, 
		phoneNumber = "phone Number",
		deliveryMode = "PROMPT",
		locationImage =	
		{ 
			value = "icon.png",
			imageType = "DYNAMIC",
		}
    }
	function Test:SendLocation_PositiveAllParams()
		self:verify_SUCCESS_Case(Request)
	end

   --- End check 1.1
-------------------------------------------------------------------------------------------------
   --Check 1.2

	local Request = {
      	longitudeDegrees = 1,
		latitudeDegrees = 1,
		address = {
			countryName = "countryName",
			countryCode = "countryName",
			postalCode = "postalCode",
			administrativeArea = "administrativeArea",
			subAdministrativeArea = "subAdministrativeArea",
			locality = "locality",
			subLocality = "subLocality",
			thoroughfare = "thoroughfare",
			subThoroughfare = "subThoroughfare"
		},
		timestamp = {
			second = 40,
			minute = 30,
			hour = 14,
			day = 25,
			month = 5,
			year = 2017,
			tz_hour = 5,
			tz_minute = 30
		},
		locationName = "location Name",
		locationDescription = "location Description",
		addressLines = 
		{ 
			"line1",
			"line2",
		}, 
		phoneNumber = "phone Number",
		deliveryMode = "PROMPT",
		locationImage =	
		{ 
			value = "icon.png",
			imageType = "DYNAMIC",
		}
    }
	function Test:SendLocation_Positive_IntDeegrees()
		self:verify_SUCCESS_Case(Request)
	end

   --- End check 1.2
-----------------------------------------------------------------------------------------------------

 --Check 2.1	

    local Request = {
      	longitudeDegrees = -179.9,
		latitudeDegrees = -89.9,
		address = {
			countryName = "c",
			countryCode = "c",
			postalCode = "p",
			administrativeArea = "a",
			subAdministrativeArea = "s",
			locality = "l",
			subLocality = "s",
			thoroughfare = "t",
			subThoroughfare = "s"
		},
		timestamp = {
			second = 0,
			minute = 0,
			hour = 0,
			day = 25,
			month = 5,
			year = 0,
			tz_hour = -12,
			tz_minute = 0
		},
		locationName ="a",
		locationDescription ="a",
		addressLines = {}, 
		phoneNumber ="a",
		deliveryMode = "PROMPT",
		locationImage =	
		{ 
			value ="a",
			imageType ="DYNAMIC",
		}
    }
	function Test:SendLocation_LowerBound()
		self:verify_SUCCESS_Case(Request)
	end
	

 --- End check 2.1

-----------------------------------------------------------------------------------------------------

 --Check 2.2	

    local Request = {
      	longitudeDegrees = -180,
		latitudeDegrees = -90,
		address = {
			countryName = "c",
			countryCode = "c",
			postalCode = "p",
			administrativeArea = "a",
			subAdministrativeArea = "s",
			locality = "l",
			subLocality = "s",
			thoroughfare = "t",
			subThoroughfare = "s"
		},
		timestamp = {
			second = 0,
			minute = 0,
			hour = 0,
			day = 25,
			month = 5,
			year = 0,
			tz_hour = -12,
			tz_minute = 0
		},
		locationName ="a",
		locationDescription ="a",
		addressLines = {}, 
		phoneNumber ="a",
		deliveryMode = "PROMPT",
		locationImage =	
		{ 
			value ="a",
			imageType ="DYNAMIC",
		}
    }
	function Test:SendLocation_LowerBound_IntDeegrees()
		self:verify_SUCCESS_Case(Request)
	end
	

 --- End check 2.2

--------------------------------------------------------------------------------------------------------

 --Check 3.1	

	local Request = {
		longitudeDegrees = 179.9,
		latitudeDegrees = 89.9,
		address = {
			countryName = string.rep("a", 200),
			countryCode = string.rep("a", 50),
			postalCode = string.rep("a", 16),
			administrativeArea = string.rep("a", 200),
			subAdministrativeArea = string.rep("a", 200),
			locality = string.rep("a", 200),
			subLocality = string.rep("a", 200),
			thoroughfare = string.rep("a", 200),
			subThoroughfare = string.rep("a", 200)
		},
		timestamp = {
			second = 60,
			minute = 59,
			hour = 23,
			day = 31,
			month = 12,
			year = 4095,
			tz_hour = 14,
			tz_minute = 59
		},
		locationName =string.rep("a", 500),
		locationDescription = string.rep("a", 500),
		addressLines = 
		{ 
			string.rep("a", 500),
			string.rep("a", 500),
			string.rep("a", 500),
			string.rep("a", 500)
		}, 
		phoneNumber =string.rep("a", 500),
		deliveryMode = "PROMPT",
		locationImage =	
		{ 
			value =strMaxLengthFileName255,
			imageType ="DYNAMIC",
		}					
	}
	function Test:SendLocation_UpperBound()
		self:verify_SUCCESS_Case(Request)
	end

 --- End check 3.1

--------------------------------------------------------------------------------------------------------

 --Check 3.2	

	local Request = {
		longitudeDegrees = 180,
		latitudeDegrees = 90,
		address = {
			countryName = string.rep("a", 200),
			countryCode = string.rep("a", 50),
			postalCode = string.rep("a", 16),
			administrativeArea = string.rep("a", 200),
			subAdministrativeArea = string.rep("a", 200),
			locality = string.rep("a", 200),
			subLocality = string.rep("a", 200),
			thoroughfare = string.rep("a", 200),
			subThoroughfare = string.rep("a", 200)
		},
		timestamp = {
			second = 60,
			minute = 59,
			hour = 23,
			day = 31,
			month = 12,
			year = 4095,
			tz_hour = 14,
			tz_minute = 59
		},
		locationName =string.rep("a", 500),
		locationDescription = string.rep("a", 500),
		addressLines = 
		{ 
			string.rep("a", 500),
			string.rep("a", 500),
			string.rep("a", 500),
			string.rep("a", 500)
		}, 
		phoneNumber =string.rep("a", 500),
		deliveryMode = "PROMPT",
		locationImage =	
		{ 
			value =strMaxLengthFileName255,
			imageType ="DYNAMIC",
		}					
	}
	function Test:SendLocation_UpperBound_IntDeegrees()
		self:verify_SUCCESS_Case(Request)
	end

 --- End check 3.2

--------------------------------------------------------------------------------------------------------

 --Check 4.1
	
	local Request = {
					longitudeDegrees = 1.1,
					latitudeDegrees = 1.1		
				}
	function Test:SendLocation_MandatoryOnly_Degrees()
		self:verify_SUCCESS_Case(Request)
	end

 --- End check 4.1

--------------------------------------------------------------------------------------------------------

 --Check 4.2
	
	local Request = {
					longitudeDegrees = 1,
					latitudeDegrees = 1		
				}
	function Test:SendLocation_MandatoryOnly_IntDeegrees()
		self:verify_SUCCESS_Case(Request)
	end

 --- End check 4.2

--------------------------------------------------------------------------------------------------------

 --Check 4.3
	
	local Request = {
					address = {
						countryName = "countryName"
					}	
				}

	function Test:SendLocation_MandatoryOnly_address()
		self:verify_SUCCESS_Case(Request)
	end

 --- End check 4.3

--------------------------------------------------------------------------------------------------------

 --Check 4.4
	
	local Request = {
					address = {
						countryName = "countryName"
					},
					longitudeDegrees = 1.1,
					latitudeDegrees = 1.1	
				}

	function Test:SendLocation_MandatoryOnly_address_Degrees()
		self:verify_SUCCESS_Case(Request)
	end

 --- End check 4.4

 --------------------------------------------------------------------------------------------------------

 --Check 4.4
	
	local Request = {
					address = {
						countryName = "countryName"
					},
					longitudeDegrees = 1,
					latitudeDegrees = 1	
				}

	function Test:SendLocation_MandatoryOnly_address_IntDegrees()
		self:verify_SUCCESS_Case(Request)
	end

 --- End check 4.4
 ----------------------------------------------------------------
 --Check 4.5
	
	local Request = {
					deliveryMode = "PROMPT"
				}

	function Test:SendLocation_MandatoryOnly_deliveryMode()
		self:verify_SUCCESS_Case(Request)
	end
 --- End check 4.5
 -------------------------------------------------------------------------
 
 --5.1: This TC is created following APPLINK-21910: SDL should transfer other params to HMI without deliverMode in case this param is not allowed by Policy

	local function SendLocation_DeliverModeIsNotAllowed()

		--Update Policy > SendLocation doesn't allow deliveryMode and allows other params
		policyTable:updatePolicy("files/PTU_ForSendLocation1.json")

		function Test:SendLocation_DeliverModeIsNotAllowed_Success()
			local Request = {
				longitudeDegrees = 1,
				latitudeDegrees = 1,
				locationName = "location Name",
				locationDescription = "location Description",
				addressLines =
				{
					"line1",
					"line2",
				},
				phoneNumber = "phone Number",
				deliveryMode = "PROMPT",
				locationImage =
				{
					value = "icon.png",
					imageType = "DYNAMIC",
				}
			}
			cid = self.mobileSession:SendRPC("SendLocation", Request)

			EXPECT_HMICALL("Navigation.SendLocation", {		addressLines={"line1", "line2"},
															latitudeDegrees=1,
															longitudeDegrees = 1,
															phoneNumber = "phone Number",
															locationName = "location Name",
															locationDescription = "location Description",
															locationImage =	{imageType="DYNAMIC",value= storagePath .. "icon.png"}
													})
			:Do(function(_,data)
				--hmi side: sending Navigation.SendLocation response
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end)

			--mobile side: expect SetGlobalProperties response
			EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
		end
	end

	--NOTE: Bellow line should be uncomment when defect APPLINK-25834 is fixed 
	--SendLocation_DeliverModeIsNotAllowed()
	-----------------------------------------------------------------------------------------------------------
	--5.2: This TC is created following APPLINK-24215: SDL should responds SUCCESS with infor to app when only deliverMode is allowed, others are disallowed by Policy

	local function SendLocation_DeliverModeIsAllowed_OthersAreNotAllowed()

		--Update Policy > SendLocation allows deliveryMode and doesn't allow other params
		policyTable:updatePolicy("files/PTU_ForSendLocation2.json")

		function Test:SendLocation_CaseDeliverModeIsAllowed_OthersAreNotAllowed_Disallowed()
			local Request = {
				longitudeDegrees = 1,
				latitudeDegrees = 1,
				locationName = "location Name",
				locationDescription = "location Description",
				addressLines =
				{
					"line1",
					"line2",
				},
				phoneNumber = "phone Number",
				deliveryMode = "PROMPT",
				locationImage =
				{
					value = "icon.png",
					imageType = "DYNAMIC",
				}
			}
			cid = self.mobileSession:SendRPC("SendLocation", Request)
			EXPECT_HMICALL("Navigation.SendLocation", {	deliveryMode = "PROMPT"})
			:Do(function(_,data)
				--hmi side: sending Navigation.SendLocation response
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end)
			--mobile side: expect response
			EXPECT_RESPONSE(cid, {  success = false, resultCode = "SUCESS", info="Several of requested parameters are disallowed by Policies"})

		end
	end

	--NOTE: Bellow line should be uncomment when APPLINK-24202 is DONE
	--SendLocation_DeliverModeIsAllowed_OthersAreNotAllowed()
	--------------------------------------------------------------------------------------------------------------------------------
	--5.3: This TC is created following APPLINK-24180: SDL should respond DISALLOWED to app when all params are disallowed by Policy

	local function SendLocation_AllParamsAreNotAllowed()

		--Update Policy > SendLocation doesn't allow all params when "parameters" field is empty
		policyTable:updatePolicy("files/PTU_ForSendLocation3.json")

		function Test:SendLocation_AllParamsAreNotAllowed_Disallowed()
			local Request = {
				longitudeDegrees = 1,
				latitudeDegrees = 1,
				locationName = "location Name",
				locationDescription = "location Description",
				addressLines =
				{
					"line1",
					"line2",
				},
				phoneNumber = "phone Number",
				deliveryMode = "PROMPT",
				locationImage =
				{
					value = "icon.png",
					imageType = "DYNAMIC",
				}
			}
			cid = self.mobileSession:SendRPC("SendLocation", Request)

			--mobile side: expect response
			EXPECT_RESPONSE(cid, {  success = false, resultCode = "DISALLOWED", info={}})

		end
	end

	--NOTE: Bellow line should be uncomment when APPLINK-24202 is DONE
	--SendLocation_AllParamsAreNotAllowed()
	----------------------------------------------------------------------
	
	--NOTE: Bellow line should be uncomment when defect APPLINK-25834 is fixed 
	-- function Test:PostCondition_UpdatePolicy()
		-- policyTable:updatePolicy("files/PTU_ForSendLocation4.json")
	-- end
	
-----------------------------------------------------------------------------------------------
--Test cases for parameters: locationName, locationDescription, phoneNumber
-----------------------------------------------------------------------------------------------
--List of test cases for String type parameter:
	--1. IsMissed
	--2. LowerBound
	--3. UpperBound
	--4. OutLowerBound/IsEmpty
	--5. OutUpperBound
	--6. IsWrongType
	--7. IsInvalidCharacters
-----------------------------------------------------------------------------------------------
	
	local Boundary = {1, 500}
	
	stringParameter:verify_String_Parameter(Request, {"locationName"}, Boundary, false)	
	stringParameter:verify_String_Parameter(Request, {"locationDescription"}, Boundary, false)	
	stringParameter:verify_String_Parameter(Request, {"phoneNumber"}, Boundary, false)		


-----------------------------------------------------------------------------------------------
--List of test cases for parameters: locationImage
-----------------------------------------------------------------------------------------------
--List of test cases for Image type parameter:
	--1. IsMissed
	--2. IsEmpty
	--3. IsWrongType
	--4. image.imageType: type=ImageType ("STATIC", "DYNAMIC")
	--5. image.value: type=String, minlength=0 maxlength=65535
-----------------------------------------------------------------------------------------------	

	local Request = Test:createRequest()
	imageParameter:verify_Image_Parameter(Request, {"locationImage"}, {"a", strMaxLengthFileName255}, false)


-----------------------------------------------------------------------------------------------
--List of test cases for parameters: longitudeDegrees, latitudeDegrees
-----------------------------------------------------------------------------------------------
--List of test cases for float type parameter:
	--1. IsMissed
	--2. IsEmpty
	--3. IsWrongType
	--4. IsLowerBound
	--5. IsUpperBound
	--6. IsOutLowerBound
	--7. IsOutUpperBound  
-----------------------------------------------------------------------------------------------
	--request without address 
	local Request = Test:createRequest()
	local Boundary_longitudeDegrees = {-180, 180}
	local Boundary_latitudeDegrees = {-90, 90}
	doubleParamter:verify_Double_Parameter(Request, {"longitudeDegrees"}, Boundary_longitudeDegrees, true)
	doubleParamter:verify_Double_Parameter(Request, {"latitudeDegrees"}, Boundary_latitudeDegrees, true)

	--request with address 
	local Request = {
		longitudeDegrees = 1.1,
		latitudeDegrees = 1.1,
		address = {
			countryName = "countryName"
		}
	}

	doubleParamter:verify_Double_Parameter(Request, {"longitudeDegrees"}, Boundary_longitudeDegrees, true, "withAddress_")
	doubleParamter:verify_Double_Parameter(Request, {"latitudeDegrees"}, Boundary_latitudeDegrees, true, "withAddress_")

	-- request without mandatory longitudeDegrees, latitudeDegrees, address
	local Request = 
				{
					timestamp = {
						second = 40,
						minute = 30,
						hour = 14,
						day = 25,
						month = 5,
						year = 2017,
						tz_hour = 5,
						tz_minute = 30
					},
					locationName = "location Name",
					locationDescription = "location Description",
					addressLines = 
					{ 
						"line1",
						"line2",
					}, 
					phoneNumber = "phone Number",
					locationImage =	
					{ 
						value = "icon.png",
						imageType = "DYNAMIC",
					}
				}

	function Test:SendLocation_Without_Mandatory_longitudeDegrees_latitudeDegrees_address()
		self:verify_INVALID_DATA_Case(Request)
	end

-----------------------------------------------------------------------------------------------
--List of test cases for parameters: addressLines
-----------------------------------------------------------------------------------------------
--List of test cases for String type parameter:
	--1. IsMissed
	--2. IsEmpty
	--3. IsWrongType
	--4. IsLowerBound
	--5. IsUpperBound
	--6. IsOutLowerBound
	--7. IsOutUpperBound    
-----------------------------------------------------------------------------------------------
	
	local Request = Test:createRequest()
	local ArrayBoundary = {0, 4}
	local ElementBoundary = {1, 500}
	arrayStringParameter:verify_Array_String_Parameter(Request, {"addressLines"}, ArrayBoundary, ElementBoundary, false)


-----------------------------------------------------------------------------------------------
--List of test cases for parameters: 
	-- address
-----------------------------------------------------------------------------------------------
--List of test cases for Struct type parameter:
	--1. IsMissed
	--2. IsEmpty
	--3. IsWrongType    
-----------------------------------------------------------------------------------------------
	--Requirement id in JAMA or JIRA: APPLINK-21926, APPLINK-22014
	--Verification criteria: 
		-- In case mobile app sends SendLocation_request to SDL  without "address" parameter and without both "longtitudeDegrees" and "latitudeDegrees" parameters with any others params related to request SDL must: respond "INVALID_DATA, success:false" to mobile app
		-- In case mobile app sends SendLocation_request to SDL  with both "longtitudeDegrees" and "latitudeDegrees" parameters and with "address" parameter and with any others params related to request and the "address" param is empty SDL must: consider such request as valid transfer SendLocation_request without "address" param to HMI

	--1. IsMissed: with longitudeDegrees, latitudeDegrees 
	commonFunctions:newTestCasesGroup({"address"})

	local Request = Test:createRequest()
	commonFunctions:TestCase(self, Request, {"address"}, "IsMissed_With_longitudeDegrees_latitudeDegrees", nil, "SUCCESS")

	--2. IsEmpty: with longitudeDegrees, latitudeDegrees
	local Request = Test:createRequest()
	commonFunctions:TestCase(self, Request, {"address"}, "IsEmpty_With_longitudeDegrees_latitudeDegrees", {}, "SUCCESS")

	--2. IsEmpty: without longitudeDegrees, latitudeDegrees
	local Request = {locationName = "locationName"}
	commonFunctions:TestCase(self, Request, {"address"}, "IsEmpty", {}, "INVALID_DATA")

	--3. IsWrongType
	local Request = Test:createRequest()
	commonFunctions:TestCase(self, Request, {"address"}, "IsWrongType", "123", "INVALID_DATA")


-----------------------------------------------------------------------------------------------
--List of test cases for parameters: 
	-- countryName
	-- countryCode
	-- postalCode
	-- administrativeArea
	-- subAdministrativeArea
	-- locality
	-- subLocality
	-- thoroughfare
	-- subThoroughfare
-----------------------------------------------------------------------------------------------
--List of test cases for String type parameter:
	--1. IsMissed
	--2. IsEmpty
	--3. IsWrongType
	--4. IsLowerBound
	--5. IsUpperBound
	--6. IsOutLowerBound
	--7. IsOutUpperBound    
-----------------------------------------------------------------------------------------------
	
	local Request = {
		address = {
			countryName = "countryName",
			subThoroughfare = "subThoroughfare"
		}
	}
	local ElementBoundary = {0, 200}
	stringParameter:verify_String_Parameter(Request, {"address", "countryName"}, ElementBoundary, false)

	local ElementBoundary = {0, 50}
	stringParameter:verify_String_Parameter(Request, {"address", "countryCode"}, ElementBoundary, false)

	local ElementBoundary = {0, 16}
	stringParameter:verify_String_Parameter(Request, {"address", "postalCode"}, ElementBoundary, false)

	local ElementBoundary = {0, 200}
	stringParameter:verify_String_Parameter(Request, {"address", "administrativeArea"}, ElementBoundary, false)
	stringParameter:verify_String_Parameter(Request, {"address", "subAdministrativeArea"}, ElementBoundary, false)
	stringParameter:verify_String_Parameter(Request, {"address", "locality"}, ElementBoundary, false)
	stringParameter:verify_String_Parameter(Request, {"address", "subLocality"}, ElementBoundary, false)
	stringParameter:verify_String_Parameter(Request, {"address", "thoroughfare"}, ElementBoundary, false)
	stringParameter:verify_String_Parameter(Request, {"address", "subThoroughfare"}, ElementBoundary, false)

	function Test:SendLocation_address_allParams_without_longitudeDegrees_latitudeDegrees()

		local RequestParams = {
			address = {
				countryName = "countryName",
				countryCode = "countryName",
				postalCode = "postalCode",
				administrativeArea = "administrativeArea",
				subAdministrativeArea = "subAdministrativeArea",
				locality = "locality",
				subLocality = "subLocality",
				thoroughfare = "thoroughfare",
				subThoroughfare = "subThoroughfare"
			}
		}

		self:verify_SUCCESS_Case(RequestParams)
	end

	function Test:SendLocation_address_allParams_with_longitudeDegrees_latitudeDegrees()

		local RequestParams = {
			longitudeDegrees = 1.1,
			latitudeDegrees = 1.1,
			address = {
				countryName = "countryName",
				countryCode = "countryName",
				postalCode = "postalCode",
				administrativeArea = "administrativeArea",
				subAdministrativeArea = "subAdministrativeArea",
				locality = "locality",
				subLocality = "subLocality",
				thoroughfare = "thoroughfare",
				subThoroughfare = "subThoroughfare"
			}
		}

		self:verify_SUCCESS_Case(RequestParams)
	end

-----------------------------------------------------------------------------------------------
--List of test cases for parameters: 
	-- timeStamp
-----------------------------------------------------------------------------------------------
--List of test cases for Struct type parameter:
	--1. IsMissed
	--2. IsEmpty
	--3. IsWrongType    
-----------------------------------------------------------------------------------------------
	--1. IsMissed
	commonFunctions:newTestCasesGroup({"timeStamp"})

	local Request = Test:createRequest()
	commonFunctions:TestCase(self, Request, {"timeStamp"}, "IsMissed", nil, "SUCCESS")

	--2. IsEmpty
	commonFunctions:TestCase(self, Request, {"timeStamp"}, "IsEmpty", {}, "INVALID_DATA")

	--3. IsWrongType
	commonFunctions:TestCase(self, Request, {"timeStamp"}, "IsWrongType", "123", "INVALID_DATA")

-----------------------------------------------------------------------------------------------
--List of test cases for parameters: 
	-- second
	-- minute
	-- hour
	-- day
	-- month
	-- year
	-- tz_hour
	-- tz_minute
-----------------------------------------------------------------------------------------------
--List of test cases for Integer type parameter:
	--1. IsMissed
	--2. IsEmpty
	--3. IsWrongType
	--4. IsLowerBound
	--5. IsUpperBound
	--6. IsOutLowerBound
	--7. IsOutUpperBound    
-----------------------------------------------------------------------------------------------
	
	local Request = Test:createRequest()
	Request.address = { countryName = "countryName" }
	Request.timeStamp = {
			second = 40,
			minute = 30,
			hour = 14,
			day = 25,
			month = 5,
			year = 2017,
			tz_hour = 5,
			tz_minute = 30
		}

	-- second parameter
	local ElementBoundary = {0, 60}
	integerParameter:verify_Integer_Parameter(Request, {"timeStamp", "second"}, ElementBoundary, true)

	-- minute parameter
	local ElementBoundary = {0, 59}
	integerParameter:verify_Integer_Parameter(Request, {"timeStamp", "minute"}, ElementBoundary, true)

	-- hour parameter
	local ElementBoundary = {0, 23}
	integerParameter:verify_Integer_Parameter(Request, {"timeStamp", "hour"}, ElementBoundary, true)

	-- day parameter
	local ElementBoundary = {1, 31}
	integerParameter:verify_Integer_Parameter(Request, {"timeStamp", "day"}, ElementBoundary, true)

	-- month parameter
	local ElementBoundary = {1, 12}
	integerParameter:verify_Integer_Parameter(Request, {"timeStamp", "month"}, ElementBoundary, true)

	-- year parameter
	local ElementBoundary = {0, 4095}
	integerParameter:verify_Integer_Parameter(Request, {"timeStamp", "year"}, ElementBoundary, true)

	-- tz_hour parameter
	local ElementBoundary = {-12, 14}
	integerParameter:verify_Integer_Parameter(Request, {"timeStamp", "tz_hour"}, ElementBoundary, true)

	-- tz_minute parameter
	local ElementBoundary = {0, 59}
	integerParameter:verify_Integer_Parameter(Request, {"timeStamp", "tz_minute"}, ElementBoundary, true)

	----------------------------------------------------------------------------------------------
	--List of test cases for parameters: deliveryMode, mandatory = false
	-----------------------------------------------------------------------------------------------
	--List of test cases for softButtons type parameter:
		--1. IsMissed
		--2. IsEmpty
		--3. IsWrongType
		--4. IsLowerBound
		--5. IsUpperBound
		--6. IsOutLowerBound
		--7. IsOutUpperBound
	-----------------------------------------------------------------------------------------------
	local DeliveryMode = {
							"PROMPT",
							"DESTINATION",
							"QUEUE"
						}

 	local Request = Test:createRequest()
	enumerationParameter:verify_Enum_String_Parameter(Request, {"deliveryMode"}, DeliveryMode, false)

----------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK II----------------------------------------
-----------------------------Check special cases of Mobile request----------------------------
----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------
--Requirement id in JAMA or JIRA: 	
	-- APPLINK-14765
	-- APPLINK-16739
	
--Verification criteria: 
	-- SDL must cut off the fake parameters from requests, responses and notifications received from HMI
	-- In case the request comes to SDL with wrong json syntax, SDL must respond with resultCode "INVALID_DATA" and success:"false" value.

-----------------------------------------------------------------------------------------
--List of test cases for softButtons type parameter:
	--1. InvalidJSON 
	--2. CorrelationIdIsDuplicated
	--3. FakeParams and FakeParameterIsFromAnotherAPI
	--4. MissedAllParameters 
-----------------------------------------------------------------------------------------------

local function SpecialRequestChecks()

--Begin Test case NegativeRequestCheck
--Description: Check negative request


	--Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup(self, "TestCaseGroupForAbnormal")
	
	--Begin Test case NegativeRequestCheck.1
	--Description: Invalid JSON

		function Test:SendLocation_InvalidJSON()

			  self.mobileSession.correlationId = self.mobileSession.correlationId + 1

			  local msg = 
			  {
				serviceType      = 7,
				frameInfo        = 0,
				rpcType          = 0,
				rpcFunctionId    = 39,
				rpcCorrelationId = self.mobileSession.correlationId,	
				--<<-- Missing :
				payload          = '{"longitudeDegrees" 1.1, "latitudeDegrees":1.1}'
			  }
			  self.mobileSession:Send(msg)
			  
			  self.mobileSession:ExpectResponse(self.mobileSession.correlationId, { success = false, resultCode = "INVALID_DATA" })
				
		end	

	--End Test case NegativeRequestCheck.1

	-----------------------------------------------------------------------------------------
	
	--Begin Test case NegativeRequestCheck.2
	--Description: Check CorrelationId duplicate value
		
		function Test:SendLocation_CorrelationIdIsDuplicated()
		
			--mobile side: sending SendLocation request
			local cid = self.mobileSession:SendRPC("SendLocation",
			{
				longitudeDegrees = 1.1,
				latitudeDegrees = 1.1
			})
			
			--request from mobile side
			local msg = 
			{
			  serviceType      = 7,
			  frameInfo        = 0,
			  rpcType          = 0,
			  rpcFunctionId    = 39,
			  rpcCorrelationId = cid,
			  payload          = '{"longitudeDegrees":1.1, "latitudeDegrees":1.1}'
			}
			
			
			--hmi side: expect Navigation.SendLocation request
			EXPECT_HMICALL("Navigation.SendLocation",
							{
								longitudeDegrees = 1.1,
								latitudeDegrees = 1.1
							})
			:Do(function(exp,data)
				if exp.occurences == 1 then
					self.mobileSession:Send(msg)
				end
				--hmi side: sending Navigation.SendLocation response
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end)
			:Times(2)
			
			--response on mobile side
			EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
			:Times(2)			
		end
	--End Test case NegativeRequestCheck.2

	-----------------------------------------------------------------------------------------
	
	--Begin Test case NegativeRequestCheck.3
	--Description: Fake parameters check
	
		--Begin Test case NegativeRequestCheck.3.1
		--Description: With fake parameters (SUCCESS) 	
			function Test:SendLocation_WithFakeParam()
				
				local param  = 	{
									longitudeDegrees = 1.1,
									latitudeDegrees = 1.1,
									locationName ="location Name",
									locationDescription ="location Description",
									addressLines = 
									{ 
										"line1",
										"line2"										
									}, 
									phoneNumber ="phone Number",
									locationImage =	
									{ 
										value ="icon.png",
										imageType ="DYNAMIC",
										fakeParam ="fakeParam"
									}, 
									fakeParam ="fakeParam"
								}	
								
				--mobile side: sending SendLocation request					
				local cid = self.mobileSession:SendRPC("SendLocation", param)
							
				param.fakeParam = nil
				param.locationImage.fakeParam = nil
				--hmi side: expect the request
				UIParams = self:createUIParameters(param)
				EXPECT_HMICALL("Navigation.SendLocation", UIParams)
				:ValidIf(function(_,data)
					if data.params.fakeParam or 						
						data.params.locationImage.fakeParam then
							print(" \27[36m SDL re-sends fakeParam parameters to HMI \27[0m")
							return false
					else 
						return true
					end
				end)
				:Do(function(_,data)
					--hmi side: sending the response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				end)
				
				--mobile side: expect the response
				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })			
			end						
		--End Test case NegativeRequestCheck.3.1
		
		-----------------------------------------------------------------------------------------

		--Begin Test case NegativeRequestCheck.3.2
		--Description: Check processing response with fake parameters from another API
			function Test:SendLocation_ParamsAnotherRequest()
				--mobile side: sending SendLocation request		
				local param  = 	{
									longitudeDegrees = 1.1,
									latitudeDegrees = 1.1,
									locationName ="location Name",
									locationDescription ="location Description",
									addressLines = 
									{ 
										"line1",
										"line2"										
									}, 
									phoneNumber ="phone Number",
									locationImage =	
									{ 
										value ="icon.png",
										imageType ="DYNAMIC",
										cmdID = 1005,
									}, 
									cmdID = 1005,
								}
								
				local cid = self.mobileSession:SendRPC("SendLocation", param)
				
				param.cmdID = nil
				param.locationImage.cmdID = nil
				
				--hmi side: expect the request
				UIParams = self:createUIParameters(param)
				EXPECT_HMICALL("Navigation.SendLocation", UIParams)
				:ValidIf(function(_,data)
					if data.params.cmdID or 						
						data.params.locationImage.cmdID then
							print(" \27[36m SDL re-sends cmdID parameters to HMI \27[0m")
							return false
					else 
						return true
					end
				end)
				:Do(function(_,data)
					--hmi side: sending the response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				end)
				
				--mobile side: expect the response
				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })			
			end	
		--End Test case NegativeRequestCheck.3.2
	--End Test case NegativeRequestCheck.3

	-----------------------------------------------------------------------------------------

	--Begin Test case NegativeRequestCheck.4
	--Description: All parameters missing
	
		function Test:SendLocation_MissedAllParameters()
			--mobile side: sending SendLocation request		
			local cid = self.mobileSession:SendRPC("SendLocation", {} )			
			
			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
			
		end
	--End Test case NegativeRequestCheck.4
--End Test case NegativeRequestCheck

end	

SpecialRequestChecks()


-----------------------------------------------------------------------------------------------
-------------------------------------------TEST BLOCK III--------------------------------------
----------------------------------Check normal cases of HMI response---------------------------
-----------------------------------------------------------------------------------------------
--Requirement id in Jira: APPLINK-14551, APPLINK-8083, APPLINK-14765, APPLINK-21930
--Verification criteria: 
		-- SDL behavior: cases when SDL must transfer "info" parameter via corresponding RPC to mobile app
		-- SDL must return INVALID_DATA success:false to mobile app IN CASE any of the above requests comes with '\n' and '\t' symbols in param of 'string' type.
		-- In case SDL cuts off fake parameters from response (request) that SDL should transfer to mobile app AND this response (request) is invalid SDL must respond GENERIC_ERROR (success:false, info: "Invalid message received from vehicle") to mobile app 
		-- The new "SAVED" resultCode must be added to "Result" enum of HMI_API

-----------------------------------------------------------------------------------------

--[[TODO: check after APPLINK-14765 is resolved	
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
	commonFunctions:newTestCasesGroup(self, "TestCaseGroupForResultCodeParameter")
	-----------------------------------------------------------------------------------------
	
	--1. IsMissed
	Test[APIName.."_Response_resultCode_IsMissed"] = function(self)
	
		--mobile side: sending the request
		local RequestParams = Test:createRequest()
		local cid = self.mobileSession:SendRPC("SendLocation", RequestParams)

		
		--hmi side: expect the request
		UIParams = self:createUIParameters(RequestParams)
		
		EXPECT_HMICALL("Navigation.SendLocation", UIParams)
		:Do(function(_,data)
			--hmi side: sending the response
			--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"Navigation.SendLocation", "code":0}}')
			  self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"Navigation.SendLocation"}}')
		end)


		--mobile side: expect the response
		EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR",  info = "Invalid message received from vehicle"})
	end
	-----------------------------------------------------------------------------------------
	]]
	
	--2. IsValidValue
	local resultCodes = {		
		{resultCode = "INVALID_DATA", success =  false},
		{resultCode = "OUT_OF_MEMORY", success =  false},
		{resultCode = "TOO_MANY_PENDING_REQUESTS", success =  false},
		{resultCode = "APPLICATION_NOT_REGISTERED", success =  false},
		{resultCode = "GENERIC_ERROR", success =  false},
		{resultCode = "REJECTED", success =  false},
		{resultCode = "DISALLOWED", success =  false},
		{resultCode = "SAVED", success = true},			
		{resultCode = "UNSUPPORTED_REQUEST", success = false},			
		{resultCode = "WARNINGS", success = true},			
	}
		
	for i =1, #resultCodes do
	
		Test[APIName.."_resultCode_IsValidValues_" .. resultCodes[i].resultCode .."_SendResponse"] = function(self)
			
			--mobile side: sending the request
			local RequestParams = Test:createRequest()
			local cid = self.mobileSession:SendRPC("SendLocation", RequestParams)
			
			--hmi side: expect the request
			UIParams = self:createUIParameters(RequestParams)
			
			EXPECT_HMICALL("Navigation.SendLocation", UIParams)
			:Do(function(_,data)
				--hmi side: sending the response
				self.hmiConnection:SendResponse(data.id, data.method, resultCodes[i].resultCode, {})
			end)

			--mobile side: expect SetGlobalProperties response
			EXPECT_RESPONSE(cid, { success = resultCodes[i].success, resultCode = resultCodes[i].resultCode})							

		end		
		-----------------------------------------------------------------------------------------
		
		Test[APIName.."_resultCode_IsValidValues_" .. resultCodes[i].resultCode .."_SendError"] = function(self)
			
			--mobile side: sending the request
			local RequestParams = Test:createRequest()
			local cid = self.mobileSession:SendRPC("SendLocation", RequestParams)
			
			--hmi side: expect the request
			UIParams = self:createUIParameters(RequestParams)
			
			EXPECT_HMICALL("Navigation.SendLocation", UIParams)
			:Do(function(_,data)
				--hmi side: sending the response
				self.hmiConnection:SendError(data.id, data.method, resultCodes[i].resultCode, "info")
			end)

			--mobile side: expect SetGlobalProperties response
			EXPECT_RESPONSE(cid, { success = resultCodes[i].success, resultCode = resultCodes[i].resultCode})							

		end	
	end
	
	-----------------------------------------------------------------------------------------
--[[TODO: check after APPLINK-14765 is resolved	
	--3. IsNotExist
	--4. IsEmpty
	--5. IsWrongType
	
	local testData = {	
		{value = "ANY", name = "IsNotExist"},
		{value = "", name = "IsEmpty"},
		{value = 123, name = "IsWrongType"},		
		}
	
	for i =1, #testData do
	
		Test[APIName.."_resultCode_" .. testData[i].name .."_SendResponse"] = function(self)
			
			--mobile side: sending the request
			local RequestParams = Test:createRequest()
			local cid = self.mobileSession:SendRPC("SendLocation", RequestParams)
			
			--hmi side: expect the request
			UIParams = self:createUIParameters(RequestParams)
			
			EXPECT_HMICALL("Navigation.SendLocation", UIParams)
			:Do(function(_,data)
				--hmi side: sending the response
				self.hmiConnection:SendResponse(data.id, data.method, testData[i].value, {})
			end)

			--mobile side: expect SetGlobalProperties response
			EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR",  info = "Invalid message received from vehicle"})
		end
		-----------------------------------------------------------------------------------------
		
		Test[APIName.."_resultCode_" .. testData[i].name .."_SendError"] = function(self)
			
			--mobile side: sending the request
			local RequestParams = Test:createRequest()
			local cid = self.mobileSession:SendRPC("SendLocation", RequestParams)
			
			--hmi side: expect the request
			UIParams = self:createUIParameters(RequestParams)
			
			EXPECT_HMICALL("Navigation.SendLocation", UIParams)
			:Do(function(_,data)
				--hmi side: sending the response
				self.hmiConnection:SendError(data.id, data.method, testData[i].value)
			end)

			--mobile side: expect SetGlobalProperties response
			EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR",  info = "Invalid message received from vehicle"})
		end
	end
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
	commonFunctions:newTestCasesGroup(self, "TestCaseGroupForMethodParameter")
	-----------------------------------------------------------------------------------------
	
	--1. IsMissed
	Test[APIName.."_Response_method_IsMissed_GENERIC_ERROR"] = function(self)
	
		--mobile side: sending the request
		local RequestParams = Test:createRequest()
		local cid = self.mobileSession:SendRPC("SendLocation", RequestParams)

		
		--hmi side: expect the request
		UIParams = self:createUIParameters(RequestParams)
		
		EXPECT_HMICALL("Navigation.SendLocation", UIParams)
		:Do(function(_,data)
			--hmi side: sending the response
			--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"Navigation.SendLocation", "code":0}}')
			  self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"code":0}}')
			  
		end)


		--mobile side: expect the response
		EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR",  info = "Invalid message received from vehicle"})		
	end
	-----------------------------------------------------------------------------------------
	
	--2. IsValidValue	
	Test[APIName.."_Response_method_IsValidValue_SendResponse"] = function(self)
		
		--mobile side: sending the request
		local RequestParams = Test:createRequest()
		local cid = self.mobileSession:SendRPC("SendLocation", RequestParams)
		
		--hmi side: expect the request
		UIParams = self:createUIParameters(RequestParams)
		
		EXPECT_HMICALL("Navigation.SendLocation", UIParams)
		:Do(function(_,data)
			--hmi side: sending the response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)

		--mobile side: expect SetGlobalProperties response
		EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})							

	end		
	-----------------------------------------------------------------------------------------
	
	Test[APIName.."_Response_method_IsValidValue_SendError"] = function(self)
		
		--mobile side: sending the request
		local RequestParams = Test:createRequest()
		local cid = self.mobileSession:SendRPC("SendLocation", RequestParams)
		
		--hmi side: expect the request
		UIParams = self:createUIParameters(RequestParams)
		
		EXPECT_HMICALL("Navigation.SendLocation", UIParams)
		:Do(function(_,data)
			--hmi side: sending the response
			self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "info")
		end)

		--mobile side: expect SetGlobalProperties response
		EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "info"})
	end	
	-----------------------------------------------------------------------------------------
	
	--3. IsNotExist
	--4. IsEmpty
	--5. IsWrongType
	--6. IsInvalidCharacter - \n, \t		
	local Methods = {	
		{method = "ANY", name = "IsNotExist"},
		{method = "", name = "IsEmpty"},
		{method = 123, name = "IsWrongType"},
		{method = "a\nb", name = "IsInvalidCharacter_NewLine"},
		{method = "a\tb", name = "IsInvalidCharacter_Tab"}}
	
	for i =1, #Methods do
	
		Test[APIName.."_Response_method_" .. Methods[i].name .."_GENERIC_ERROR_SendResponse"] = function(self)
			
			--mobile side: sending the request
			local RequestParams = Test:createRequest()
			local cid = self.mobileSession:SendRPC("SendLocation", RequestParams)
			
			--hmi side: expect the request
			UIParams = self:createUIParameters(RequestParams)
			
			EXPECT_HMICALL("Navigation.SendLocation", UIParams)
			:Do(function(_,data)
				--hmi side: sending the response
				--self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				self.hmiConnection:SendResponse(data.id, Methods[i].method, "SUCCESS", {})
				
			end)

			--mobile side: expect SetGlobalProperties response
			EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR",  info = "Invalid message received from vehicle"})			
		end
		-----------------------------------------------------------------------------------------
		
		Test[APIName.."_Response_method_" .. Methods[i].name .."_GENERIC_ERROR_SendError"] = function(self)
			
			--mobile side: sending the request
			local RequestParams = Test:createRequest()
			local cid = self.mobileSession:SendRPC("SendLocation", RequestParams)
			
			--hmi side: expect the request
			UIParams = self:createUIParameters(RequestParams)
			
			EXPECT_HMICALL("Navigation.SendLocation", UIParams)
			:Do(function(_,data)
				--hmi side: sending the response
				--self.hmiConnection:SendError(data.id, data.method, "UNSUPPORTED_RESOURCE", "info")
				  self.hmiConnection:SendError(data.id, Methods[i].method, "UNSUPPORTED_RESOURCE", "info")
				
			end)

			--mobile side: expect SetGlobalProperties response
			EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR",  info = "Invalid message received from vehicle"})
		end
	end
end	

verify_method_parameter()
--]]


-----------------------------------------------------------------------------------------------
--Parameter 3: info
-----------------------------------------------------------------------------------------------
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
	commonFunctions:newTestCasesGroup(self, "TestCaseGroupForInfoParameter")
	
	-----------------------------------------------------------------------------------------
	
	--1. IsMissed
	Test[APIName.."_info_IsMissed_SendResponse"] = function(self)
	
		--mobile side: sending the request
		local RequestParams = Test:createRequest()
		local cid = self.mobileSession:SendRPC("SendLocation", RequestParams)

		
		--hmi side: expect the request
		UIParams = self:createUIParameters(RequestParams)
		
		EXPECT_HMICALL("Navigation.SendLocation", UIParams)
		:Do(function(_,data)
			--hmi side: sending the response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)


		--mobile side: expect the response
		EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
		:ValidIf (function(_,data)
			if data.payload.info then
				print(" \27[32m SDL resends invalid info parameter to mobile app. \27[0m")
				return false
			else 
				return true
			end
		end)
	end
	-----------------------------------------------------------------------------------------
	
	Test[APIName.."_info_IsMissed_SendError"] = function(self)
	
		--mobile side: sending the request
		local RequestParams = Test:createRequest()
		local cid = self.mobileSession:SendRPC("SendLocation", RequestParams)

		
		--hmi side: expect the request
		UIParams = self:createUIParameters(RequestParams)
		
		EXPECT_HMICALL("Navigation.SendLocation", UIParams)
		:Do(function(_,data)
			--hmi side: sending the response
			self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR")
		end)


		--mobile side: expect the response
		-- TODO: update after resolving APPLINK-14765
		-- EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
		EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})
		:ValidIf (function(_,data)
			if data.payload.info then
				print(" \27[32m SDL resends info parameter to mobile app. info = \"" .. data.payload.info .. "\" \27[0m")
				return false
			else 
				return true
			end
		end)
	end
	-----------------------------------------------------------------------------------------

	--2. IsLowerBound
	--3. IsUpperBound
	local testData = {	
		{value = "a", name = "IsLowerBound"},
		{value = commonFunctions:createString(1000), name = "IsUpperBound"}}
	
	for i =1, #testData do	
		Test[APIName.."_info_" .. testData[i].name .."_SendResponse"] = function(self)
			
			--mobile side: sending the request
			local RequestParams = Test:createRequest()
			local cid = self.mobileSession:SendRPC("SendLocation", RequestParams)
			
			--hmi side: expect the request
			UIParams = self:createUIParameters(RequestParams)
			
			EXPECT_HMICALL("Navigation.SendLocation", UIParams)
			:Do(function(_,data)
				--hmi side: sending the response
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {message = testData[i].value})
			end)

			--mobile side: expect SetGlobalProperties response
			EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", info = testData[i].value})
		end
		-----------------------------------------------------------------------------------------
		
		Test[APIName.."_info_" .. testData[i].name .."_SendError"] = function(self)
			
			--mobile side: sending the request
			local RequestParams = Test:createRequest()
			local cid = self.mobileSession:SendRPC("SendLocation", RequestParams)
			
			--hmi side: expect the request
			UIParams = self:createUIParameters(RequestParams)
			
			EXPECT_HMICALL("Navigation.SendLocation", UIParams)
			:Do(function(_,data)
				--hmi side: sending the response
				self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", testData[i].value)
			end)

			--mobile side: expect SetGlobalProperties response
			EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = testData[i].value})
		end
	end
	-----------------------------------------------------------------------------------------
	
	
	--4. IsOutUpperBound
	Test[APIName.."_info_IsOutUpperBound_SendResponse"] = function(self)
	
		local infoMaxLength = commonFunctions:createString(1000)
		
		--mobile side: sending the request
		local RequestParams = Test:createRequest()
		local cid = self.mobileSession:SendRPC("SendLocation", RequestParams)
		
		--hmi side: expect the request
		UIParams = self:createUIParameters(RequestParams)
		
		EXPECT_HMICALL("Navigation.SendLocation", UIParams)
		:Do(function(_,data)
			--hmi side: sending the response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {message = infoMaxLength .. "1"})
		end)

		--mobile side: expect SetGlobalProperties response
		EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", info = infoMaxLength})		
	end
	-----------------------------------------------------------------------------------------
	
	Test[APIName.."_info_IsOutUpperBound_SendError"] = function(self)
	
		local infoMaxLength = commonFunctions:createString(1000)
		
		--mobile side: sending the request
		local RequestParams = Test:createRequest()
		local cid = self.mobileSession:SendRPC("SendLocation", RequestParams)
		
		--hmi side: expect the request
		UIParams = self:createUIParameters(RequestParams)
		
		EXPECT_HMICALL("Navigation.SendLocation", UIParams)
		:Do(function(_,data)
			--hmi side: sending the response
			self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", infoMaxLength .."1")
		end)

		--mobile side: expect SetGlobalProperties response
		EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = infoMaxLength})		
	end
	-----------------------------------------------------------------------------------------
	
	--5. IsEmpty/IsOutLowerBound	
	--6. IsWrongType
	--7. InvalidCharacter - \n, \t, white spaces only
	
	local testData = {	
		{value = "", name = "IsEmpty_IsOutLowerBound"},
		{value = 123, name = "IsWrongType"},
		{value = "a\nb", name = "IsInvalidCharacter_NewLine"},
		{value = "a\tb", name = "IsInvalidCharacter_Tab"},
		{value = "    ", name = "WhiteSpacesOnly"}}
	
	for i =1, #testData do
	
		Test[APIName.."_info_" .. testData[i].name .."_SendResponse"] = function(self)
			
			--mobile side: sending the request
			local RequestParams = Test:createRequest()
			local cid = self.mobileSession:SendRPC("SendLocation", RequestParams)
			
			--hmi side: expect the request
			UIParams = self:createUIParameters(RequestParams)
			
			EXPECT_HMICALL("Navigation.SendLocation", UIParams)
			:Do(function(_,data)
				--hmi side: sending the response
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {message = testData[i].value})
			end)

			--mobile side: expect SetGlobalProperties response
			EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
			:ValidIf (function(_,data)
				if data.payload.info then
					print(" \27[32m  SDL resends info parameter to mobile app. info = \"" .. data.payload.info .. "\" \27[0m")
					return false
				else 
					return true
				end
			end)
		end
		-----------------------------------------------------------------------------------------
		
		Test[APIName.."_info_" .. testData[i].name .."_SendError"] = function(self)
			
			--mobile side: sending the request
			local RequestParams = Test:createRequest()
			local cid = self.mobileSession:SendRPC("SendLocation", RequestParams)
			
			--hmi side: expect the request
			UIParams = self:createUIParameters(RequestParams)
			
			EXPECT_HMICALL("Navigation.SendLocation", UIParams)
			:Do(function(_,data)
				--hmi side: sending the response
				self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", testData[i].value)
			end)

			--mobile side: expect SetGlobalProperties response
			EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
			:ValidIf (function(_,data)
				if data.payload.info then
					print(" \27[32m SDL resends info parameter to mobile app. info = \"" .. data.payload.info .. "\" \27[0m")
					return false
				else 
					return true
				end				
			end)	
		end
	end
end	

verify_info_parameter()

--[[TODO: check after APPLINK-14765 is resolved	
-----------------------------------------------------------------------------------------------
--Parameter 4: correlationID 
-----------------------------------------------------------------------------------------------
--List of test cases: 
	--1. CorrelationIDMissing
	--2. CorrelationIDWrongType
	--3. CorrelationIDNotExisted
	--4. CorrelationIDNegative
	--5. CorrelationIDNull
-----------------------------------------------------------------------------------------------

local function verify_correlationID_parameter()


	--Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup("TestCaseGroupForCorrelationIDParameter")
	
	-----------------------------------------------------------------------------------------
	
	--1. CorrelationIDMissing	
	Test[APIName.."_Response_CorrelationIDMissing"] = function(self)
	
		--mobile side: sending the request
		local RequestParams = Test:createRequest()
		local cid = self.mobileSession:SendRPC("SendLocation", RequestParams)

		
		--hmi side: expect the request
		UIParams = self:createUIParameters(RequestParams)
		
		EXPECT_HMICALL("Navigation.SendLocation", UIParams)
		:Do(function(_,data)
			--hmi side: sending the response
			--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"Navigation.SendLocation", "code":0}}')
			self.hmiConnection:Send('{"jsonrpc":"2.0","result":{"method":"Navigation.SendLocation", "code":0}}')
		end)

		--mobile side: expect the response
		EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR",  info = "Invalid message received from vehicle"})		
	end
	-----------------------------------------------------------------------------------------
	
	--2. CorrelatioIDWrongType
	Test[APIName.."_Response_CorrelationIDWrongType"] = function(self)	
		--mobile side: sending the request
		local RequestParams = Test:createRequest()
		local cid = self.mobileSession:SendRPC("SendLocation", RequestParams)

		
		--hmi side: expect the request
		UIParams = self:createUIParameters(RequestParams)
		
		EXPECT_HMICALL("Navigation.SendLocation", UIParams)
		:Do(function(_,data)
			--hmi side: sending the response
			self.hmiConnection:SendResponse(tostring(data.id), data.method, "SUCCESS", {})
		end)

		--mobile side: expect the response
		EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR",  info = "Invalid message received from vehicle"})		
	end
	-----------------------------------------------------------------------------------------
	
	--3. CorrelationIDNotExisted
	Test[APIName.."_Response_CorrelationIDNotExisted"] = function(self)
		
		--mobile side: sending the request
		local RequestParams = Test:createRequest()
		local cid = self.mobileSession:SendRPC("SendLocation", RequestParams)

		
		--hmi side: expect the request
		UIParams = self:createUIParameters(RequestParams)
		
		EXPECT_HMICALL("Navigation.SendLocation", UIParams)
		:Do(function(_,data)
			--hmi side: sending the response
			self.hmiConnection:SendResponse(9999, data.method, "SUCCESS", {})
		end)

		--mobile side: expect the response
		EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR",  info = "Invalid message received from vehicle"})				
	end
	-----------------------------------------------------------------------------------------
	
	--4. CorrelationIDNegative
	Test[APIName.."_Response_CorrelationIDNegative"] = function(self)
	
		--mobile side: sending the request
		local RequestParams = Test:createRequest()
		local cid = self.mobileSession:SendRPC("SendLocation", RequestParams)

		
		--hmi side: expect the request
		UIParams = self:createUIParameters(RequestParams)
		
		EXPECT_HMICALL("Navigation.SendLocation", UIParams)
		:Do(function(_,data)
			--hmi side: sending the response
			self.hmiConnection:SendResponse(-1, data.method, "SUCCESS", {})
		end)

		--mobile side: expect the response
		EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR",  info = "Invalid message received from vehicle"})		
	end
	
	-----------------------------------------------------------------------------------------
	--5. CorrelationIDNull	
	Test[APIName.."_Response_CorrelationIDNull"] = function(self)
	
		--mobile side: sending the request
		local RequestParams = Test:createRequest()
		local cid = self.mobileSession:SendRPC("SendLocation", RequestParams)

		
		--hmi side: expect the request
		UIParams = self:createUIParameters(RequestParams)
		
		EXPECT_HMICALL("Navigation.SendLocation", UIParams)
		:Do(function(_,data)
			--hmi side: sending the response
			self.hmiConnection:Send('"id":null,"jsonrpc":"2.0","result":{"code":0,"method":"Navigation.SendLocation"}}')
		end)

		--mobile side: expect the response
		EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR",  info = "Invalid message received from vehicle"})		
	end
end	

verify_correlationID_parameter()

--]]	

----------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK IV----------------------------------------
------------------------------Check special cases of HMI response-----------------------------
----------------------------------------------------------------------------------------------

--Requirement id in JAMA: APPLINK-14765
--Verification criteria:  	In case SDL cuts off fake parameters from response (request) that SDL should transfer to mobile app AND this response (request) is invalid SDL must respond GENERIC_ERROR (success:false, info: "Invalid message received from vehicle") to mobile app 

-----------------------------------------------------------------------------------------------

--List of test cases for softButtons type parameter:
	--1. InvalidJsonSyntax
	--2. InvalidStructure
	--2. DuplicatedCorrelationId
	--3. FakeParams and FakeParameterIsFromAnotherAPI
	--4. MissedAllPArameters
	--5. NoResponse
	--6. SeveralResponsesToOneRequest with the same and different resultCode
-----------------------------------------------------------------------------------------------

local function SpecialResponseChecks()

--Begin Test case NegativeResponseCheck
--Description: Check all negative response cases
	
	--Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup(self, "NewTestCasesGroupForNegativeResponseCheck")

	--Begin Test case NegativeResponseCheck.1
	--Description: Invalid JSON
		
		--[[ToDo: Check after APPLINK-14765 is resolved
		
		function Test:SendLocation_InvalidJsonSyntaxResponse()
		
			--mobile side: sending the request
			local RequestParams = Test:createRequest()
			local cid = self.mobileSession:SendRPC("SendLocation", RequestParams)
			
			--hmi side: expect the request
			local UIParams = self:createUIParameters(RequestParams)
			EXPECT_HMICALL("Navigation.SendLocation", UIParams)
			:Do(function(_,data)
				--hmi side: sending the response
				--":" is changed by ";" after {"id"
				--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"Navigation.SendLocation", "code":0}}')
				  self.hmiConnection:Send('{"id";'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"Navigation.SendLocation", "code":0}}')
			end)
				
			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR",  info = "Invalid message received from vehicle"})						
		end			
	--End Test case NegativeResponseCheck.1
	
	-----------------------------------------------------------------------------------------
	
	--Begin Test case NegativeResponseCheck.2
	--Description: Invalid structure of response
			
		function Test:SendLocation_InvalidStructureResponse()

			--mobile side: sending the request
			local RequestParams = Test:createRequest()
			local cid = self.mobileSession:SendRPC("SendLocation", RequestParams)
								
			--hmi side: expect the request
			local UIParams = self:createUIParameters(RequestParams)
			EXPECT_HMICALL("Navigation.SendLocation", UIParams)		
			:Do(function(_,data)
				--hmi side: sending the response
				--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"Navigation.SendLocation", "code":0}}')
				self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0", "code":0, "result":{"method":"Navigation.SendLocation"}}')
			end)							
		
			--mobile side: expect response 
			EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR",  info = "Invalid message received from vehicle"})
		end		
	--End Test case NegativeResponseCheck.2
]]

	-----------------------------------------------------------------------------------------
	
	--Begin Test case NegativeResponseCheck.3
	--Description: Check processing response with fake parameters
		
		--Requirement id in JAMA/or Jira ID: APPLINK-14765
		--Verification criteria: SDL must cut off the fake parameters from requests, responses and notifications received from HMI
		
		--Begin Test case NegativeResponseCheck.3.1
		--Description: Parameter is not from API		
			function Test:SendLocation_FakeParamsInResponse()
			
				--mobile side: sending the request
				local RequestParams = Test:createRequest()
				local cid = self.mobileSession:SendRPC("SendLocation", RequestParams)
									
				--hmi side: expect the request
				local UIParams = self:createUIParameters(RequestParams)
				EXPECT_HMICALL("Navigation.SendLocation", UIParams)		
				:Do(function(exp,data)
					--hmi side: sending the response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {fake = "fake"})
				end)
				
							
				--mobile side: expect the response
				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
				:ValidIf (function(_,data)
					if data.payload.fake then
						print(" \27[32m SDL resend fake parameter to mobile app \27[0m")
						return false
					else 
						return true
					end
				end)						
			end
		--End Test case NegativeResponseCheck.3.1
		
		-----------------------------------------------------------------------------------------
		
		--Begin Test case NegativeResponseCheck.3.2
		--Description: Parameter is not from another API
			function Test:SendLocation_AnotherParameterInResponse()			
				--mobile side: sending the request
				local RequestParams = Test:createRequest()
				local cid = self.mobileSession:SendRPC("SendLocation", RequestParams)
									
				--hmi side: expect the request
				local UIParams = self:createUIParameters(RequestParams)
				EXPECT_HMICALL("Navigation.SendLocation", UIParams)		
				:Do(function(exp,data)
					--hmi side: sending the response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {sliderPosition = 5})
				end)
							
				--mobile side: expect the response
				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
				:ValidIf (function(_,data)
					if data.payload.sliderPosition then
						print(" \27[32m SDL resend fake parameter to mobile app \27[0m")
						return false
					else 
						return true
					end
				end)							
			end			
		--End Test case NegativeResponseCheck.3.2		
	--End Test case NegativeResponseCheck.3

	-----------------------------------------------------------------------------------------
	
	--Begin NegativeResponseCheck.4
	--Description: Check processing response without all parameters		
	--[[TODO: Check after APPLINK-14765 is resolved
		function Test:SendLocation_Response_MissedAllPArameters()
			--mobile side: sending the request
			local RequestParams = Test:createRequest()
			local cid = self.mobileSession:SendRPC("SendLocation", RequestParams)

			
			--hmi side: expect the request
			UIParams = self:createUIParameters(RequestParams)
			
			EXPECT_HMICALL("Navigation.SendLocation", UIParams)
			:Do(function(_,data)
				--hmi side: sending Navigation.SendLocation response
				--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"Navigation.SendLocation", "code":0}}')
				self.hmiConnection:Send('{}')
			end)
			
			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR",  info = "Invalid message received from vehicle"})			
		end
	]]
	--End NegativeResponseCheck.4

	-----------------------------------------------------------------------------------------
	
	--Begin Test case NegativeResponseCheck.5
	--Description: Request without responses from HMI
	
		function Test:SendLocation_NoResponse()
			--mobile side: sending the request
			local RequestParams = Test:createRequest()
			local cid = self.mobileSession:SendRPC("SendLocation", RequestParams)
								
			--hmi side: expect the request
			local UIParams = self:createUIParameters(RequestParams)
			EXPECT_HMICALL("Navigation.SendLocation", UIParams)		
			
			
			--mobile side: expect SetGlobalProperties response
			EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
			:Timeout(12000)
		end		
	--End NegativeResponseCheck.5
		
	-----------------------------------------------------------------------------------------
	
	--Begin Test case NegativeResponseCheck.6
	--Description: Several response to one request
			
		function Test:SendLocation_SeveralResponsesToOneRequest()
			--mobile side: sending the request
			local RequestParams = Test:createRequest()
			local cid = self.mobileSession:SendRPC("SendLocation", RequestParams)
								
			--hmi side: expect the request
			local UIParams = self:createUIParameters(RequestParams)
			EXPECT_HMICALL("Navigation.SendLocation", UIParams)		
			:Do(function(exp,data)
				--hmi side: sending the response
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "")
				self.hmiConnection:SendError(data.id, data.method, "REJECTED", "")					
			end)
										
			--mobile side: expect response 
			EXPECT_RESPONSE(cid, {  success = true, resultCode = "SUCCESS"})				
		end
	--End Test case NegativeResponseCheck.6
	
	-----------------------------------------------------------------------------------------
--[[TODO: Check after APPLINK-14765 is resolved	
	--Begin Test case NegativeResponseCheck.7
	--Description: Wrong response to correct correlationID
		function Test:SendLocation_WrongResponse()
			--mobile side: sending the request
			local RequestParams = Test:createRequest()
			local cid = self.mobileSession:SendRPC("SendLocation", RequestParams)
								
			--hmi side: expect the request
			local UIParams = self:createUIParameters(RequestParams)
			EXPECT_HMICALL("Navigation.SendLocation", UIParams)		
			:Do(function(exp,data)
				--hmi side: sending the response
				self.hmiConnection:Send('{"error":{"code":4,"message":"SendLocation is REJECTED"},"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"code":0,"method":"Navigation.SendLocation"}}')			
			end)
										
			--mobile side: expect response 
			EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})	
		end
	--End Test case NegativeResponseCheck.7	
--]]
--End Test case NegativeResponseCheck	

end	

SpecialResponseChecks()


-----------------------------------------------------------------------------------------------
-------------------------------------------TEST BLOCK V----------------------------------------
-------------------------------------Checks All Result Codes-----------------------------------
-----------------------------------------------------------------------------------------------

--Requirement id in JAMA: APPLINK-9735, SDLAQ-CRS-2396
--Verification criteria: 
	--An RPC request is not allowed by the backend. Policies Manager validates it as "disallowed".

local function ResultCodeChecks()

	--Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup(self, "NewTestCasesGroupForResultCodeChecks")
	
	--Begin Test case ResultCodeChecks.1
	--Description: Check resultCode APPLICATION_NOT_REGISTERED

		--Precondition
		function Test:Precondition_CreationNewSession()
			-- Connected expectation
			self.mobileSession2 = mobile_session.MobileSession(
																	self,
																	self.mobileConnection,
																	config.application2.registerAppInterfaceParams
																)			   
		end
		
		function Test:SendLocation_resultCode_APPLICATION_NOT_REGISTERED()

			--mobile side: sending the request
			local RequestParams = Test:createRequest()
			local cid = self.mobileSession2:SendRPC("SendLocation", RequestParams)
														
			--mobile side: expect response 
			self.mobileSession2:ExpectResponse(cid, {  success = false, resultCode = "APPLICATION_NOT_REGISTERED"})			
		end
	--End Test case ResultCodeChecks.1

	-----------------------------------------------------------------------------------------

	--Begin Test case ResultCodeChecks.2
	--Description: Check resultCode DISALLOWED
			
		--Begin Test case ResultCodeChecks.2.1
		--Description: Check resultCode DISALLOWED when HMI level is NONE
	
			--Covered by test case SendLocation_HMIStatus_NONE
			
		--End Test case ResultCodeChecks.2.1
		
		-----------------------------------------------------------------------------------------


		
		--Begin Test case ResultCodeChecks.2.2
		--Description: Check resultCode DISALLOWED when request is not assigned to app

			local AppIDsession2

			function Test:Precondition_Register_app()
				self.mobileSession2:Start()

				EXPECT_HMICALL("BasicCommunication.OnAppRegistered")
					:Do(function(_,data)
						AppIDsession2 = data.params.application.appID
					end)

				self.mobileSession2:ExpectNotification("OnHMIStatus", {hmiLevel = "NONE", systemContext = "MAIN"})
			end

			function Test:Precondition_Activation_app()
				--hmi side: sending SDL.ActivateApp request
				local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = AppIDsession2})
				EXPECT_HMIRESPONSE(RequestId)
				
				--mobile side: expect notification
				self.mobileSession2:ExpectNotification("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"})
			end

			
			function Test:SendLocation_resultCode_DISALLOWED()
				--mobile side: sending the request
				local RequestParams = Test:createRequest()
				local cid = self.mobileSession2:SendRPC("SendLocation", RequestParams)
															
				--mobile side: expect response 
				self.mobileSession2:ExpectResponse(cid, {  success = false, resultCode = "DISALLOWED"})			
			end
			

			function Test:Postcondition_UnregisterApp()
				local cid = self.mobileSession2:SendRPC("UnregisterAppInterface", {})
															
				--mobile side: expect response 
				self.mobileSession2:ExpectResponse(cid, {  success = true, resultCode = "SUCCESS"})
					:Do(function()
						self.mobileSession2:Stop()
					end)
			end

			--Postcondition: Activation app on first session 
			commonSteps:ActivationAppGenivi(_, "Postcondition_Activate_first_app")

		--End Test case ResultCodeChecks.2.2	
	
	--End Test case ResultCodeChecks.2

	-----------------------------------------------------------------------------------------

end

ResultCodeChecks()

----------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK VI----------------------------------------
-------------------------Sequence with emulating of user's action(s)--------------------------
----------------------------------------------------------------------------------------------

--Description: TC's checks SDL behaviour by processing
	-- different request sequence with timeout
	-- with emulating of user's actions	

-- Not Applicable


----------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK VII---------------------------------------
--------------------------------------Different HMIStatus-------------------------------------
----------------------------------------------------------------------------------------------

--Description: Check different HMIStatus
	
local function DifferentHMIlevelChecks()

	--Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup(self, "NewTestCasesGroupForSequenceChecks")
	-----------------------------------------------------------------------------------------
	
	--Begin Test case DifferentHMIlevelChecks.1
	--Description: Check request is disallowed in NONE HMI level
		function Test:Precondition_DeactivateToNone()
			--hmi side: sending BasicCommunication.OnExitApplication notification
			self.hmiConnection:SendNotification("BasicCommunication.OnExitApplication", {appID = self.applications["Test Application"], reason = "USER_EXIT"})

			EXPECT_NOTIFICATION("OnHMIStatus",
				{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
		end	
		
		function Test:SendLocation_HMIStatus_NONE()
			
			--mobile side: sending the request
			local RequestParams = Test:createRequest()
			local cid = self.mobileSession:SendRPC("SendLocation", RequestParams)
																			
			--mobile side: expect response 
			EXPECT_RESPONSE(cid, {  success = false, resultCode = "DISALLOWED"})
		end				
							
		--Postcondition: Activate app
		commonSteps:ActivationApp(self)

	--End Test case DifferentHMIlevelChecks.1
	-----------------------------------------------------------------------------------------
			
	--Begin Test case DifferentHMIlevelChecks.2
	--Description: Check HMI level Full
	
		--It is covered by above test cases

	--End Test case DifferentHMIlevelChecks.2
	-----------------------------------------------------------------------------------------
	
	--Begin Test case DifferentHMIlevelChecks.3
	--Description: Check HMI level LIMITED
	if 
		Test.isMediaApplication == true or
		Test.appHMITypes["NAVIGATION"] == true then
		
			--Precondition: Deactivate app to LIMITED HMI level				
			commonSteps:ChangeHMIToLimited(self)

			function Test:SendLocation_HMIStatus_LIMITED()
				local RequestParams = Test:createRequest()
				self:verify_SUCCESS_Case(RequestParams)
			end
	
	--End Test case DifferentHMIlevelChecks.3
	
		-- Precondition 1: Opening new session	
		function Test:AddNewSession()
		  -- Connected expectation
			self.mobileSession2 = mobile_session.MobileSession(
			self,
			self.mobileConnection)
			
			self.mobileSession2:StartService(7)
		end	

		-- Precondition 2: Register app2	

	local AppIDOfSecondApp
		function Test:RegisterAppInterface_App2() 

			--mobile side: RegisterAppInterface request 
			local CorIdRAI = self.mobileSession2:SendRPC("RegisterAppInterface",
														{
															syncMsgVersion = 
															{ 
																majorVersion = 2,
																minorVersion = 2,
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
															}
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
				AppIDOfSecondApp = data.params.application.appID
			end)
			
			--mobile side: RegisterAppInterface response 
			self.mobileSession2:ExpectResponse(CorIdRAI, { success = true, resultCode = "SUCCESS"})
				:Timeout(2000)

			self.mobileSession2:ExpectNotification("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
		end

		-- Precondition 3: Activate an other media app to change app to BACKGROUND
		function Test:Activate_Media_App2()
			--HMI send ActivateApp request			
			local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = AppIDOfSecondApp})
			EXPECT_HMIRESPONSE(RequestId)
			:Do(function(_,data)

				if data.result.isSDLAllowed ~= true then
					local RequestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})
					EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
					:Do(function(_,data)
						--hmi side: send request SDL.OnAllowSDLFunctionality
						self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {allowed = true, source = "GUI", device = {id = 1, name = "127.0.0.1"}})
					end)

					EXPECT_HMICALL("BasicCommunication.ActivateApp")
					:Do(function(_,data)
						self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
					end)
					:Times(2)
				end
			end)

			self.mobileSession2:ExpectNotification("OnHMIStatus", {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"}) 
			:Timeout(12000)
			
			self.mobileSession:ExpectNotification("OnHMIStatus", {hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"}) 
			
		end	
	
	elseif Test.isMediaApplication == false then
		--Precondition: Deactivate app to BACKGOUND HMI level				
		commonSteps:DeactivateToBackground(self)
	end
	
	-----------------------------------------------------------------------------------------
	
	--Begin Test case DifferentHMIlevelChecks.4
	--Description: Check HMI level BACKGOUND
		function Test:SendLocation_HMIStatus_BACKGOUND()
			local RequestParams = Test:createRequest()
			self:verify_SUCCESS_Case(RequestParams)
		end
	--End Test case DifferentHMIlevelChecks.4
end

DifferentHMIlevelChecks()

--------------------------------------------------------------------------------------------------------
-- Postcondition: restoring hmi_capabilities.json to original
-- TODO: need to be removed after resolving APPLINK-17511

function Test:Postcondition_RestoringHmiCapabilitiesFile()
	str = tostring(config.pathToSDL)

	local PathToSDLWihoutBin =  string.gsub(str, "bin/", "")

	OriginalHmiCapabilitiesFile = PathToSDLWihoutBin .. "src/appMain/hmi_capabilities.json"

	os.execute( " cp " .. tostring(OriginalHmiCapabilitiesFile) .. " " .. tostring(config.pathToSDL) .. "" )
end
--------------------------------------------------------------------------------------------------------

return Test
