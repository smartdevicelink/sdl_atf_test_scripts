
Test = require('connecttest')
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
require('user_modules/AppTypes')
local SDLConfig = require('user_modules/shared_testcases/SmartDeviceLinkConfigurations')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local stringParameter = require('user_modules/shared_testcases/testCasesForStringParameter')
local enumerationParameter = require('user_modules/shared_testcases/testCasesForEnumerationParameter')
local imageParameter = require('user_modules/shared_testcases/testCasesForImageParameter')
local arraySoftButtonsParameter = require('user_modules/shared_testcases/testCasesForArraySoftButtonsParameter')
local arrayStringParameter = require('user_modules/shared_testcases/testCasesForArrayStringParameter')
local integerParameter = require('user_modules/shared_testcases/testCasesForIntegerParameter')
local floatParameter = require('user_modules/shared_testcases/testCasesForFloatParameter')
local booleanParameter = require('user_modules/shared_testcases/testCasesForBooleanParameter')
local policyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')

---------------------------------------------------------------------------------------------
------------------------------------ Common Variables ---------------------------------------
--------------------------------------------------------------------------------------------

APIName = "ShowConstantTBT" -- set request name
strMaxLengthFileName255 = string.rep("a", 251)  .. ".png" -- set max length file name
local storagePath = config.pathToSDL .. SDLConfig:GetValue("AppStorageFolder") .. "/" .. tostring(config.application1.registerAppInterfaceParams.fullAppID .. "_" .. tostring(config.deviceMAC) .. "/")

--Debug = {"graphic", "value"} --use to print request before sending to SDL.
Debug = {} -- empty {}: script will do not print request on console screen.

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
function createRequest()

	return {
		navigationText1 = "NavigationText1"
	}

end
---------------------------------------------------------------------------------------------

--Create UI expected result based on parameters from the request
function Test:createUIParameters(RequestParams)

	local param =  {}

	--maneuverComplete
	param["maneuverComplete"] =  RequestParams["maneuverComplete"]

	--distanceToManeuver
	param["distanceToManeuver"] =  RequestParams["distanceToManeuver"]

	--distanceToManeuverScale
	param["distanceToManeuverScale"] =  RequestParams["distanceToManeuverScale"]

	--Convert navigationTexts parameter
	local j = 0

	--navigationText1
	if RequestParams["navigationText1"] ~= nil then
		j = j + 1
		if param["navigationTexts"] == nil then
			param["navigationTexts"] = {}
		end
		param["navigationTexts"][j] = {
			fieldName = "navigationText1",
			fieldText = RequestParams["navigationText1"]
		}
	end


	--navigationText2
	if RequestParams["navigationText2"] ~= nil then
		j = j + 1
		if param["navigationTexts"] == nil then
			param["navigationTexts"] = {}
		end
		param["navigationTexts"][j] = {
			fieldName = "navigationText2",
			fieldText = RequestParams["navigationText2"]
		}
	end

	--eta
	if RequestParams["eta"] ~= nil then
		j = j + 1
		if param["navigationTexts"] == nil then
			param["navigationTexts"] = {}
		end
		param["navigationTexts"][j] = {
			fieldName = "ETA",
			fieldText = RequestParams["eta"]
		}
	end

	--totalDistance
	if RequestParams["totalDistance"] ~= nil then
		j = j + 1
		if param["navigationTexts"] == nil then
			param["navigationTexts"] = {}
		end
		param["navigationTexts"][j] = {
			fieldName = "totalDistance",
			fieldText = RequestParams["totalDistance"]
		}
	end

	--timeToDestination
	if RequestParams["timeToDestination"] ~= nil then
		j = j + 1
		if param["navigationTexts"] == nil then
			param["navigationTexts"] = {}
		end
		param["navigationTexts"][j] = {
			fieldName = "timeToDestination",
			fieldText = RequestParams["timeToDestination"]
		}
	end

	--nextTurnIcon
	param["nextTurnIcon"] =  RequestParams["nextTurnIcon"]
	if param["nextTurnIcon"] ~= nil and
		param["nextTurnIcon"].imageType ~= "STATIC" and
		param["nextTurnIcon"].value ~= nil and
		param["nextTurnIcon"].value ~= "" then
			param["nextTurnIcon"].value = storagePath ..param["nextTurnIcon"].value
	end

	--turnIcon
	param["turnIcon"] =  RequestParams["turnIcon"]
	if param["turnIcon"] ~= nil and
		param["turnIcon"].imageType ~= "STATIC" and
		param["turnIcon"].value ~= nil and
		param["turnIcon"].value ~= "" then
			param["turnIcon"].value = storagePath ..param["turnIcon"].value
	end

	if RequestParams["softButtons"]  ~= nil then
		if next(RequestParams["softButtons"]) == nil then
			RequestParams["softButtons"] = nil
		else
			param["softButtons"] =  RequestParams["softButtons"]
			for i = 1, #param["softButtons"] do

				--if type = TEXT, image = nil, else type = IMAGE, text = nil
				if param["softButtons"][i].type == "TEXT" then
					param["softButtons"][i].image =  nil

				elseif param["softButtons"][i].type == "IMAGE" then
					param["softButtons"][i].text =  nil
				end

				--if image.imageType ~=STATIC, add app folder to image value
				if param["softButtons"][i].image ~= nil and
					param["softButtons"][i].image.imageType ~= "STATIC" then

					param["softButtons"][i].image.value = storagePath ..param["softButtons"][i].image.value
				end

				--if SystemAction is missed then default value will be DEFAULT_ACTION
				if param["softButtons"][i].systemAction == nil then
					param["softButtons"][i].systemAction =  "DEFAULT_ACTION"
				end
			end
		end
	end

	return param
end
---------------------------------------------------------------------------------------------

--This function sends a request from mobile and verify result on HMI and mobile for SUCCESS resultCode cases.
function Test:verify_SUCCESS_Case(RequestParams)
	--Check if send any empty array or empty struct
	local temp = json.encode(RequestParams)
	local cid = 0
	if string.find(temp, "{}") ~= nil or string.find(temp, "{{}}") ~= nil then
		temp = string.gsub(temp, "{}", "[]")
		temp = string.gsub(temp, "{{}}", "[{}]")

		self.mobileSession.correlationId = self.mobileSession.correlationId + 1

		local msg =
		{
			serviceType      = 7,
			frameInfo        = 0,
			rpcType          = 0,
			rpcFunctionId    = 27,
			rpcCorrelationId = self.mobileSession.correlationId,
			payload          = temp
		}

		cid = self.mobileSession.correlationId

		self.mobileSession:Send(msg)

	else
		--mobile side: sending ShowConstantTBT request
		cid = self.mobileSession:SendRPC("ShowConstantTBT", RequestParams)
	end

	-- TODO: remove after resolving APPLINK-16094
	---------------------------------------------

	if
		(RequestParams.softButtons and
		#RequestParams.softButtons == 0) then
			RequestParams.softButtons = nil
	end

	if RequestParams.softButtons then
		for i=1,#RequestParams.softButtons do
			if RequestParams.softButtons[i].image then
				RequestParams.softButtons[i].image = nil
			end
		end

	end
	---------------------------------------------

	UIParams = self:createUIParameters(RequestParams)

	--hmi side: expect Navigation.ShowConstantTBT request
	EXPECT_HMICALL("Navigation.ShowConstantTBT", UIParams)
	:Do(function(_,data)
		--hmi side: sending Navigation.ShowConstantTBT response
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
	end)

	--mobile side: expect SetGlobalProperties response
	EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
end

---------------------------------------------------------------------------------------------


--This function sends a request from mobile and verify result on HMI and mobile for WARNINGS resultCode cases.
function Test:verify_WARNINGS_Case(RequestParams)
  --Check if send any empty array or empty struct
  local temp = json.encode(RequestParams)
  local cid = 0
  if string.find(temp, "{}") ~= nil or string.find(temp, "{{}}") ~= nil then
    temp = string.gsub(temp, "{}", "[]")
    temp = string.gsub(temp, "{{}}", "[{}]")

    self.mobileSession.correlationId = self.mobileSession.correlationId + 1

    local msg =
    {
      serviceType      = 7,
      frameInfo        = 0,
      rpcType          = 0,
      rpcFunctionId    = 27,
      rpcCorrelationId = self.mobileSession.correlationId,
      payload          = temp
    }

    cid = self.mobileSession.correlationId

    self.mobileSession:Send(msg)

  else
    --mobile side: sending ShowConstantTBT request
    cid = self.mobileSession:SendRPC("ShowConstantTBT", RequestParams)
  end

  -- TODO: remove after resolving APPLINK-16094
  ---------------------------------------------

  if
    (RequestParams.softButtons and
    #RequestParams.softButtons == 0) then
      RequestParams.softButtons = nil
  end

  if RequestParams.softButtons then
    for i=1,#RequestParams.softButtons do
      if RequestParams.softButtons[i].image then
        RequestParams.softButtons[i].image = nil
      end
    end

  end
  ---------------------------------------------

  UIParams = self:createUIParameters(RequestParams)

  --hmi side: expect Navigation.ShowConstantTBT request
  EXPECT_HMICALL("Navigation.ShowConstantTBT", UIParams)
  :Do(function(_,data)
    --hmi side: sending Navigation.ShowConstantTBT response
    self.hmiConnection:SendResponse(data.id, data.method, "WARNINGS", {info = "Requested image(s) not found."})
  end)

  --mobile side: expect SetGlobalProperties response
  EXPECT_RESPONSE(cid, { success = true, resultCode = "WARNINGS",info = "Requested image(s) not found." })
end

---------------------------------------------------------------------------------------------
--
--This function sends a request from mobile with INVALID_DATA and verify result on mobile.
function Test:verify_INVALID_DATA_Case(RequestParams)
	--Check if send any empty array or empty struct
	local temp = json.encode(RequestParams)
	local cid = 0
	if string.find(temp, "{}") ~= nil or string.find(temp, "{{}}") ~= nil then
		temp = string.gsub(temp, "{}", "[]")
		temp = string.gsub(temp, "{{}}", "[{}]")

		self.mobileSession.correlationId = self.mobileSession.correlationId + 1

		local msg =
		{
			serviceType      = 7,
			frameInfo        = 0,
			rpcType          = 0,
			rpcFunctionId    = 27,
			rpcCorrelationId = self.mobileSession.correlationId,
			payload          = temp
		}
		cid = self.mobileSession.correlationId
		self.mobileSession:Send(msg)
	else
		--mobile side: sending ShowConstantTBT request
		cid = self.mobileSession:SendRPC("ShowConstantTBT", RequestParams)
	end

	--mobile side: expect ShowConstantTBT response
	EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
	:Timeout(50)

end

---------------------------------------------------------------------------------------------

--Description: Update policy from specific file
	--policyFileName: Name of policy file
	--bAllowed: true if want to allowed New group policy
	--          false if want to disallowed New group policy
local groupID
local groupName = "New"
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
					EXPECT_HMIRESPONSE(RequestIdGetListOfPermissions,{result = {code = 0, method = "SDL.GetListOfPermissions", allowedFunctions = {{name = groupName}}}})
					:Do(function(_,data)
						groupID = data.result.allowedFunctions[1].id
						--print("SDL.GetListOfPermissions response is received")

						--hmi side: sending SDL.OnAppPermissionConsent
						self.hmiConnection:SendNotification("SDL.OnAppPermissionConsent", { appID =  self.applications["Test Application"], consentedFunctions = {{ allowed = bAllowed, id = groupID, name = groupName}}, source = "GUI"})
						end)
				end)
			end)

		end)
	end)
end

---------------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------

	--Print new line to separate Preconditions
	commonFunctions:newTestCasesGroup("Preconditions")

	--Delete app_info.dat, logs and policy table
	commonSteps:DeleteLogsFileAndPolicyTable()

	--Configure app params in config.lua to navigation application
	config.application1.registerAppInterfaceParams.appHMIType = {"NAVIGATION"}

	--1. Activate application
	commonSteps:ActivationApp()

	--2. Update policy to allow request
	policyTable:precondition_updatePolicy_AllowFunctionInHmiLeves({"BACKGROUND", "FULL", "LIMITED"})


	--List of state
	local TBTState =
	{
		"ROUTE_UPDATE_REQUEST",
		"ROUTE_ACCEPTED",
		"ROUTE_REFUSED",
		"ROUTE_CANCELLED",
		"ETA_REQUEST",
		"NEXT_TURN_REQUEST",
		"ROUTE_STATUS_REQUEST",
		"ROUTE_SUMMARY_REQUEST",
		"TRIP_STATUS_REQUEST",
		"ROUTE_UPDATE_REQUEST_TIMEOUT"
	}


	--4. PutFiles ("a", "icon.png", "action.png", strMaxLengthFileName255)
	commonSteps:PutFile( "PutFile_MinLength", "a")
	commonSteps:PutFile( "PutFile_icon.png", "icon.png")
	commonSteps:PutFile( "PutFile_action.png", "action.png")
	commonSteps:PutFile( "PutFile_MaxLength_255Characters", strMaxLengthFileName255)
-----------------------------------------------------------------------------------------


-----------------------------------------------------------------------------------------------
-------------------------------------------TEST BLOCK I----------------------------------------
--------------------------------Check normal cases of Mobile request---------------------------
-----------------------------------------------------------------------------------------------

--Print new line to separate test suite
 commonFunctions:newTestCasesGroup("Test Suite For Normal cases of Mobile request")

--Requirement id in JAMA or JIRA:
	--SDLAQ-CRS-121: ShowConstantTBT_Request_v2_0
	--SDLAQ-CRS-663: SUCCESS
	--SDLAQ-CRS-664: INVALID_DATA

--Verification criteria: Verify request with valid and invalid values of parameters.
-----------------------------------------------------------------------------------------------

	--List of parameters in the request:
	--1. navigationText1: type=String, maxlength=500, mandatory=false
	--2. navigationText2, type=String, maxlength=500, mandatory=false
	--3. eta, type=String, maxlength=500, mandatory=false
	--4. totalDistance, type=String, maxlength=500, mandatory=false
	--5. timeToDestination, type=String, maxlength=500, mandatory=false
	--6. turnIcon, type=Image, mandatory=false
	--7. nextTurnIcon, type=Image, mandatory=false
	--8. distanceToManeuver, type = Float, minvalue=0, maxvalue=1000000000, mandatory=false
	--9. distanceToManeuverScale, type = Float, minvalue=0, maxvalue=1000000000, mandatory=false
	--10. maneuverComplete, type=Boolean, mandatory=false
	--11. softButtons, type=SoftButton, mandatory=false, minsize=0, array=true, maxsize=3

	-----------------------------------------------------------------------------------------------


-----------------------------------------------------------------------------------------------
--Common Test cases:
--1. Positive case and in boundary conditions
--2. All parameters are lower bound
--3. All parameters are upper bound

--1.2, 2.2, 3.2, 4.2 distanceToManeuver  and distanceToManeuverScale are integer
-----------------------------------------------------------------------------------------------
      --1. All params in boundary conditions
	local Request = {
						navigationText1 ="navigationText1",
						navigationText2 ="navigationText2",
						eta ="12:34",
						totalDistance ="100miles",
						turnIcon =
						{
							value ="icon.png",
							imageType ="DYNAMIC",
						},
						nextTurnIcon =
						{
							value ="action.png",
							imageType ="DYNAMIC",
						},
						distanceToManeuver = 50.5,
						distanceToManeuverScale = 100.5,
						maneuverComplete = false,
						softButtons =
						{

							{
								type ="BOTH",
								text ="Close",
								image =
								{
									value ="icon.png",
									imageType ="DYNAMIC",
								},
								isHighlighted = true,
								softButtonID = 44,
								systemAction ="DEFAULT_ACTION",
							},
						},
					}
	function Test:ShowConstantTBT_Positive()
		self:verify_SUCCESS_Case(Request)
	end
	
	 local Request = {
            navigationText1 ="navigationText1",
            navigationText2 ="navigationText2",
            eta ="12:34",
            totalDistance ="100miles",
            turnIcon =
            {
              value ="notavailable.png",
              imageType ="DYNAMIC",
            },
            nextTurnIcon =
            {
              value ="notavailable.png",
              imageType ="DYNAMIC",
            },
            distanceToManeuver = 50.5,
            distanceToManeuverScale = 100.5,
            maneuverComplete = false,
            softButtons =
            {

              {
                type ="BOTH",
                text ="Close",
                image =
                {
                  value ="notavailable.png",
                  imageType ="DYNAMIC",
                },
                isHighlighted = true,
                softButtonID = 44,
                systemAction ="DEFAULT_ACTION",
              },
            },
          }
  function Test:ShowConstantTBT_Positive_InvalidImage()
    self:verify_WARNINGS_Case(Request)
  end
  
     local Request = {
            navigationText1 ="navigationText1",
            navigationText2 ="navigationText2",
            eta ="12:34",
            totalDistance ="100miles",
            turnIcon =
            {
              value ="notavailable.png",
              imageType ="DYNAMIC",
            },
            nextTurnIcon =
            {
              value ="icon.png",
              imageType ="DYNAMIC",
            },
            distanceToManeuver = 50.5,
            distanceToManeuverScale = 100.5,
            maneuverComplete = false,
            softButtons =
            {

              {
                type ="BOTH",
                text ="Close",
                image =
                {
                  value ="icon.png",
                  imageType ="DYNAMIC",
                },
                isHighlighted = true,
                softButtonID = 44,
                systemAction ="DEFAULT_ACTION",
              },
            },
          }
  function Test:ShowConstantTBT_Positive_InvalidImage_TurnIcon()
    self:verify_WARNINGS_Case(Request)
  end
  
       local Request = {
            navigationText1 ="navigationText1",
            navigationText2 ="navigationText2",
            eta ="12:34",
            totalDistance ="100miles",
            turnIcon =
            {
              value ="icon.png",
              imageType ="DYNAMIC",
            },
            nextTurnIcon =
            {
              value ="icon.png",
              imageType ="DYNAMIC",
            },
            distanceToManeuver = 50.5,
            distanceToManeuverScale = 100.5,
            maneuverComplete = false,
            softButtons =
            {

              {
                type ="BOTH",
                text ="Close",
                image =
                {
                  value ="notavailable.png",
                  imageType ="DYNAMIC",
                },
                isHighlighted = true,
                softButtonID = 44,
                systemAction ="DEFAULT_ACTION",
              },
            },
          }
  function Test:ShowConstantTBT_Positive_InvalidImage_SoftButton()
    self:verify_WARNINGS_Case(Request)
  end
  
         local Request = {
            navigationText1 ="navigationText1",
            navigationText2 ="navigationText2",
            eta ="12:34",
            totalDistance ="100miles",
            turnIcon =
            {
              value ="icon.png",
              imageType ="DYNAMIC",
            },
            nextTurnIcon =
            {
              value ="notavailable.png",
              imageType ="DYNAMIC",
            },
            distanceToManeuver = 50.5,
            distanceToManeuverScale = 100.5,
            maneuverComplete = false,
            softButtons =
            {

              {
                type ="BOTH",
                text ="Close",
                image =
                {
                  value ="icon.png",
                  imageType ="DYNAMIC",
                },
                isHighlighted = true,
                softButtonID = 44,
                systemAction ="DEFAULT_ACTION",
              },
            },
          }
  function Test:ShowConstantTBT_Positive_InvalidImage_NextTurnIcon()
    self:verify_WARNINGS_Case(Request)
  end

	local Request = {
						navigationText1 ="navigationText1",
						navigationText2 ="navigationText2",
						eta ="12:34",
						totalDistance ="100miles",
						turnIcon =
						{
							value ="icon.png",
							imageType ="DYNAMIC",
						},
						nextTurnIcon =
						{
							value ="action.png",
							imageType ="DYNAMIC",
						},
						distanceToManeuver = 51,
						distanceToManeuverScale = 101,
						maneuverComplete = false,
						softButtons =
						{

							{
								type ="BOTH",
								text ="Close",
								image =
								{
									value ="icon.png",
									imageType ="DYNAMIC",
								},
								isHighlighted = true,
								softButtonID = 44,
								systemAction ="DEFAULT_ACTION",
							},
						},
					}
	function Test:ShowConstantTBT_Positive_2IntParams()
		self:verify_SUCCESS_Case(Request)
	end


       --2. All parameters are lower bound
       --Check 2.1
	local Request = {
					navigationText1 = "1",
					navigationText2 = "2",
					eta = "3",
					totalDistance = "D",
					timeToDestination = "E",
					maneuverComplete = false,
					nextTurnIcon = {
						value = "a",
						imageType = "DYNAMIC"
					},
					softButtons = {
					},
					turnIcon = {
						value = "a",
						imageType = "DYNAMIC"
					},
					distanceToManeuver = 0.1,
					distanceToManeuverScale = 0.1
				}
	function Test:ShowConstantTBT_LowerBound()
		self:verify_SUCCESS_Case(Request)
	end
        --- End check 2.1
        -- Check 2.2
        local Request = {
					navigationText1 = "1",
					navigationText2 = "2",
					eta = "3",
					totalDistance = "D",
					timeToDestination = "E",
					maneuverComplete = false,
					nextTurnIcon = {
						value = "a",
						imageType = "DYNAMIC"
					},
					softButtons = {
					},
					turnIcon = {
						value = "a",
						imageType = "DYNAMIC"
					},
					distanceToManeuver = 0,
					distanceToManeuverScale = 0
				}
	function Test:ShowConstantTBT_LowerBound_2IntParams()
		self:verify_SUCCESS_Case(Request)
	end
       ---End check 2.2


      --3. All parameters are upper bound
      -- Check 3.1
	local Request = {
					navigationText1 = string.rep("a", 500),
					navigationText2 = string.rep("a", 500),
					eta = string.rep("a", 500),
					totalDistance = string.rep("a", 500),
					timeToDestination = string.rep("a", 500),
					maneuverComplete = false,
					nextTurnIcon = {
						value = strMaxLengthFileName255,
						imageType = "DYNAMIC"
					},
					softButtons = {
						{
							softButtonID = 65535,
							text = string.rep("e", 500),
							type = "TEXT",
							isHighlighted = false,
							systemAction = "DEFAULT_ACTION"
						},
						{
							softButtonID = 65534,
							text = string.rep("e", 500),
							type = "TEXT",
							isHighlighted = false,
							systemAction = "STEAL_FOCUS"
						},
						{
							softButtonID = 65533,
							text = string.rep("e", 500),
							type = "TEXT",
							isHighlighted = false,
							systemAction = "KEEP_CONTEXT"
						}
					},
					turnIcon = {
						value = strMaxLengthFileName255,
						imageType = "DYNAMIC"
					},
					distanceToManeuver = 999999999.9,
					distanceToManeuverScale = 999999999.9
				}
	function Test:ShowConstantTBT_UpperBound()
		self:verify_SUCCESS_Case(Request)
	end
	---End check 3.1
        -- Check 3.2
	local Request = {
					navigationText1 = string.rep("a", 500),
					navigationText2 = string.rep("a", 500),
					eta = string.rep("a", 500),
					totalDistance = string.rep("a", 500),
					timeToDestination = string.rep("a", 500),
					maneuverComplete = false,
					nextTurnIcon = {
						value = strMaxLengthFileName255,
						imageType = "DYNAMIC"
					},
					softButtons = {
						{
							softButtonID = 65535,
							text = string.rep("e", 500),
							type = "TEXT",
							isHighlighted = false,
							systemAction = "DEFAULT_ACTION"
						},
						{
							softButtonID = 65534,
							text = string.rep("e", 500),
							type = "TEXT",
							isHighlighted = false,
							systemAction = "STEAL_FOCUS"
						},
						{
							softButtonID = 65533,
							text = string.rep("e", 500),
							type = "TEXT",
							isHighlighted = false,
							systemAction = "KEEP_CONTEXT"
						}
					},
					turnIcon = {
						value = strMaxLengthFileName255,
						imageType = "DYNAMIC"
					},
					distanceToManeuver = 1000000000,
					distanceToManeuverScale = 1000000000
				}
	function Test:ShowConstantTBT_UpperBound_2IntParams()
		self:verify_SUCCESS_Case(Request)
	end
	---End check 3.2
-----------------------------------------------------------------------------------------------
--4. Request with one parameter only
-----------------------------------------------------------------------------------------------
        -- Check 4.1

	local Request = {
						{param = "navigationText1", value = {navigationText1 ="navigationText1"}},
						{param = "navigationText2", value = {navigationText2 ="navigationText2"}},
						{param = "eta", value = {eta ="12:34"}},
						{param = "totalDistance", value = {totalDistance ="100miles"}},
						{param = "turnIcon", value = {turnIcon =
														{
															value ="icon.png",
															imageType ="DYNAMIC",
														}}},
						{param = "timeToDestination", value = {timeToDestination = "100"}},
						{param = "nextTurnIcon", value = {nextTurnIcon =
															{
																value ="action.png",
																imageType ="DYNAMIC",
															}}},
						{param = "distanceToManeuver", value = {distanceToManeuver = 50.5}},
						{param = "distanceToManeuverScale", value = {distanceToManeuverScale = 100.5}},
						{param = "maneuverComplete", value = {maneuverComplete = false}},
						{param = "softButton", value = {softButtons =
															{

																{
																	type ="BOTH",
																	text ="Close",
																	image =
																	{
																		value ="icon.png",
																		imageType ="DYNAMIC",
																	},
																	isHighlighted = true,
																	softButtonID = 44,
																	systemAction ="DEFAULT_ACTION",
																},
															}}},
					}

	for i=1, #Request do
		Test["ShowConstantTBT_Only_"..Request[i].param] = function(self)
			self:verify_SUCCESS_Case(Request[i].value)
		end
	end

  ---End check 4.1

  -- Check 4.2:  distanceToManeuver and distanceToManeuverScale are integer
      local Request = {
						{param = "navigationText1", value = {navigationText1 ="navigationText1"}},
						{param = "navigationText2", value = {navigationText2 ="navigationText2"}},
						{param = "eta", value = {eta ="12:34"}},
						{param = "totalDistance", value = {totalDistance ="100miles"}},
						{param = "turnIcon", value = {turnIcon =
														{
															value ="icon.png",
															imageType ="DYNAMIC",
														}}},
						{param = "timeToDestination", value = {timeToDestination = "100"}},
						{param = "nextTurnIcon", value = {nextTurnIcon =
															{
																value ="action.png",
																imageType ="DYNAMIC",
															}}},
						{param = "distanceToManeuver", value = {distanceToManeuver = 51}},
						{param = "distanceToManeuverScale", value = {distanceToManeuverScale = 101}},
						{param = "maneuverComplete", value = {maneuverComplete = false}},
						{param = "softButton", value = {softButtons =
															{

																{
																	type ="BOTH",
																	text ="Close",
																	image =
																	{
																		value ="icon.png",
																		imageType ="DYNAMIC",
																	},
																	isHighlighted = true,
																	softButtonID = 44,
																	systemAction ="DEFAULT_ACTION",
																},
															}}},
					}

	for i=1, #Request do
		Test["ShowConstantTBT_Only_2Int_"..Request[i].param] = function(self)
			self:verify_SUCCESS_Case(Request[i].value)
		end
	end

  ---End check 4.2
-----------------------------------------------------------------------------------------------
--Test cases for parameters: navigationText1,  navigationText2, eta, totalDistance, timeToDestination : type=String, maxlength=500, mandatory=false
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

	local Boundary = {0, 500}

	local Request = {navigationText2 = "NavigationText2"}
	stringParameter:verify_String_Parameter(Request, {"navigationText1"}, Boundary, false)
	local Request = createRequest()
	stringParameter:verify_String_Parameter(Request, {"navigationText2"}, Boundary, false)
	stringParameter:verify_String_Parameter(Request, {"eta"}, Boundary, false)
	stringParameter:verify_String_Parameter(Request, {"totalDistance"}, Boundary, false)
	stringParameter:verify_String_Parameter(Request, {"timeToDestination"}, Boundary, false)


-----------------------------------------------------------------------------------------------
--List of test cases for parameters: turnIcon, nextTurnIcon: type=Image, mandatory=false
-----------------------------------------------------------------------------------------------
--List of test cases for Image type parameter:
	--1. IsMissed
	--2. IsEmpty
	--3. IsWrongType
	--4. ContainsWrongValues
	--5. image.imageType: type=ImageType ("STATIC", "DYNAMIC")
	--6. image.value: type=String, minlength=0 maxlength=65535
-----------------------------------------------------------------------------------------------

	local Request = createRequest()
	imageParameter:verify_Image_Parameter(Request, {"turnIcon"}, {"a", strMaxLengthFileName255}, false)
	imageParameter:verify_Image_Parameter(Request, {"nextTurnIcon"}, {"a", strMaxLengthFileName255}, false)



-----------------------------------------------------------------------------------------------
--List of test cases for parameters: softButtons, type=SoftButton, mandatory=false, minsize=0, array=true, maxsize=3
-----------------------------------------------------------------------------------------------
--List of test cases for softButtons type parameter:
	--1. IsMissed
	--2. IsEmpty
	--3. IsWrongType
	--4. IsLowerBound
	--5. IsUpperBound
	--6. IsOutLowerBound
	--7. IsOutUpperBound
	--8. Check parameters in side a button
		--"type" type="SoftButtonType">
		--"text" minlength="0" maxlength="500" type="String" mandatory="false"
		--"image" type="Image" mandatory="false"
		--"isHighlighted" type="Boolean" defvalue="false" mandatory="false"
		--"softButtonID" type="Integer" minvalue="0" maxvalue="65535"
		--"systemAction" type="SystemAction" defvalue="DEFAULT_ACTION" mandatory="false"
-----------------------------------------------------------------------------------------------

	local Request = createRequest()
	local Boundary = {0, 3}
	arraySoftButtonsParameter:verify_softButtons_Parameter(Request, {"softButtons"}, Boundary, {"a", strMaxLengthFileName255}, false)


-----------------------------------------------------------------------------------------------
--List of test cases for parameters: distanceToManeuver, distanceToManeuverScale, type=Float, minvalue=0, maxvalue=1000000000, mandatory=false
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

	local Request = createRequest()
	local Boundary = {0, 1000000000}
	floatParameter:verify_Float_Parameter(Request, {"distanceToManeuver"}, Boundary, false)
	floatParameter:verify_Float_Parameter(Request, {"distanceToManeuverScale"}, Boundary, false)


-----------------------------------------------------------------------------------------------
--List of test cases for parameters: maneuverComplete
-----------------------------------------------------------------------------------------------
--List of test cases for Boolean type parameter:
	--1. IsMissed
	--2. IsExistentValues
	--3. IsWrongType
	--4. Check with values: True, False
-----------------------------------------------------------------------------------------------

	local Request = createRequest()
	local Boundary = {true, false}
	booleanParameter:verify_boolean_Parameter(Request, {"maneuverComplete"}, Boundary, false)

	function Test: ShowConstantTBT_maneuverComplete_True()
		self.mobileSession.correlationId = self.mobileSession.correlationId + 1

		local msg =
		{
			serviceType      = 7,
			frameInfo        = 0,
			rpcType          = 0,
			rpcFunctionId    = 27,
			rpcCorrelationId = self.mobileSession.correlationId,
			payload          = '{"maneuverComplete":True}'
		}
		cid = self.mobileSession.correlationId
		self.mobileSession:Send(msg)

		--hmi side: expect Navigation.ShowConstantTBT request
		EXPECT_HMICALL("Navigation.ShowConstantTBT", {maneuverComplete = True})
		:Do(function(_,data)
			--hmi side: sending Navigation.ShowConstantTBT response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)

		--mobile side: expect ShowConstantTBT response
		EXPECT_RESPONSE(self.mobileSession.correlationId, { success = true, resultCode = "SUCCESS" })
	end

	function Test: ShowConstantTBT_maneuverComplete_False()
		self.mobileSession.correlationId = self.mobileSession.correlationId + 1

		local msg =
		{
			serviceType      = 7,
			frameInfo        = 0,
			rpcType          = 0,
			rpcFunctionId    = 27,
			rpcCorrelationId = self.mobileSession.correlationId,
			payload          = '{"maneuverComplete":False}'
		}
		cid = self.mobileSession.correlationId
		self.mobileSession:Send(msg)

		--hmi side: expect Navigation.ShowConstantTBT request
		EXPECT_HMICALL("Navigation.ShowConstantTBT", {maneuverComplete = False})
		:Do(function(_,data)
			--hmi side: sending Navigation.ShowConstantTBT response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)

		--mobile side: expect ShowConstantTBT response
		EXPECT_RESPONSE(self.mobileSession.correlationId, { success = true, resultCode = "SUCCESS" })
	end
----------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK II----------------------------------------
-----------------------------Check special cases of Mobile request----------------------------
----------------------------------------------------------------------------------------------

--Requirement id in JAMA or JIRA:
	--SDLAQ-CRS-121: ShowConstantTBT_Request_v2_0
	--SDLAQ-CRS-664: INVALID_DATA
	--SDLAQ-CRS-663: SUCCESS

-----------------------------------------------------------------------------------------------

--List of test cases for softButtons type parameter:
	--1. InvalidJSON (SDLAQ-CRS-664: INVALID_DATA)
	--2. CorrelationIdIsDuplicated (SDLAQ-CRS-663: SUCCESS)
	--3. FakeParams and FakeParameterIsFromAnotherAPI (APPLINK-14765: SDL must cut off the fake parameters from requests, responses and notifications received from HMI)
	--4. MissedAllParameters (SDLAQ-CRS-664: INVALID_DATA)
-----------------------------------------------------------------------------------------------

local function SpecialRequestChecks()

--Begin Test case NegativeRequestCheck
--Description: Check negative request


	--Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup("TestCaseGroupForAbnormal")

	--Begin Test case NegativeRequestCheck.1
	--Description: Invalid JSON

		function Test:ShowConstantTBT_InvalidJSON()

			  self.mobileSession.correlationId = self.mobileSession.correlationId + 1

			  local msg =
			  {
				serviceType      = 7,
				frameInfo        = 0,
				rpcType          = 0,
				rpcFunctionId    = 27,
				rpcCorrelationId = self.mobileSession.correlationId,
				--<<-- Missing :
				payload          = '{"navigationText1" "NavigationText1"}'
			  }
			  cid = self.mobileSession.correlationId
			  self.mobileSession:Send(msg)

			  self.mobileSession:ExpectResponse(self.mobileSession.correlationId, { success = false, resultCode = "INVALID_DATA" })

		end

	--End Test case NegativeRequestCheck.1


	--Begin Test case NegativeRequestCheck.2
	--Description: Check CorrelationId duplicate value
		--[[ToDo: APPLINK-13892 ATF: Send(msg) convert parameter in quote ("xxx") to \"
		--
		function Test:ShowConstantTBT_CorrelationIdIsDuplicated()

			--mobile side: sending ShowConstantTBT request
			local cid = self.mobileSession:SendRPC("ShowConstantTBT",
			{
				navigationText1 = "ShowConstantTBT1"
			})

			--request from mobile side
			local msg =
			{
			  serviceType      = 7,
			  frameInfo        = 0,
			  rpcType          = 0,
			  rpcFunctionId    = 27,
			  rpcCorrelationId = cid,
			  payload          = '{"navigationText2":"ShowConstantTBT2"}'
			}


			--hmi side: expect Navigation.ShowConstantTBT request
			EXPECT_HMICALL("Navigation.ShowConstantTBT",
							{
								navigationTexts =
								{
									{
										fieldName = "navigationText1",
										fieldText = "ShowConstantTBT1"
									}
								}
							},
							{
								navigationTexts =
								{
									{
										fieldName = "navigationText2",
										fieldText = "ShowConstantTBT2"
									}
								}
							}
							)
			:Do(function(exp,data)
				if exp.occurences == 1 then
					self.mobileSession:Send(msg)
				end

				--hmi side: sending Navigation.ShowConstantTBT response
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end)
			:Times(2)

			--response on mobile side
			EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
			:Times(2)

		end
	]]
	--End Test case NegativeRequestCheck.2

	-----------------------------------------------------------------------------------------

	--Begin Test case NegativeRequestCheck.3
	--Description: Fake parameters check

		--Requirement id in JAMA: APPLINK-14765, APPLINK-16076
		--Verification criteria: SDL must cut off the fake parameters from requests, responses and notifications received from HMI; SDL must treat integer value for params of float type as valid

		--Begin Test case NegativeRequestCheck.3.1
		--Description: Fake parameters are not from any API

		function Test:ShowConstantTBT_FakeParams_IsNotFromAnyAPI()

			--mobile side: sending ShowConstantTBT request
			local param  = 	{
								navigationText1 = "1",
								navigationText2 = "2",
								eta = "3",
								totalDistance = "D",
								timeToDestination = "E",
								maneuverComplete = false,
								fakeParam = "fakeParam",
								nextTurnIcon = {
									value = "a",
									imageType = "DYNAMIC",
									fakeParam = "fakeParam"
								},
								softButtons = {
									{
										softButtonID = 1,
										text = "ABC",
										type = "TEXT",
										isHighlighted = false,
										systemAction = "DEFAULT_ACTION",
										fakeParam = "fakeParam"
									}
								},
								turnIcon = {
									value = "a",
									imageType = "DYNAMIC",
									fakeParam = "fakeParam"
								},
								distanceToManeuver = 0.1,
								distanceToManeuverScale = 0.1
							}


			local cid = self.mobileSession:SendRPC("ShowConstantTBT", param)

			param.fakeParam = nil
			param.nextTurnIcon.fakeParam = nil
			param.turnIcon.fakeParam = nil
			param.softButtons[1].fakeParam = nil

			--hmi side: expect the request
			UIParams = self:createUIParameters(param)
			EXPECT_HMICALL("Navigation.ShowConstantTBT", UIParams)
			:ValidIf(function(_,data)
				if data.params.fakeParam or
					data.params.nextTurnIcon.fakeParam or
					data.params.softButtons.fakeParam or
					data.params.softButtons[1].fakeParam or
					data.params.turnIcon.fakeParam then
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
		--Description: Fake parameters are not from any API; integer value for distanceToManeuver, distanceToManeuverScale params of float type

		function Test:ShowConstantTBT_FakeParams_2IntParams_IsNotFromAnyAPI()

			--mobile side: sending ShowConstantTBT request
			local param  = 	{
								navigationText1 = "1",
								navigationText2 = "2",
								eta = "3",
								totalDistance = "D",
								timeToDestination = "E",
								maneuverComplete = false,
								fakeParam = "fakeParam",
								nextTurnIcon = {
									value = "a",
									imageType = "DYNAMIC",
									fakeParam = "fakeParam"
								},
								softButtons = {
									{
										softButtonID = 1,
										text = "ABC",
										type = "TEXT",
										isHighlighted = false,
										systemAction = "DEFAULT_ACTION",
										fakeParam = "fakeParam"
									}
								},
								turnIcon = {
									value = "a",
									imageType = "DYNAMIC",
									fakeParam = "fakeParam"
								},
								distanceToManeuver = 1,
								distanceToManeuverScale = 1
							}


			local cid = self.mobileSession:SendRPC("ShowConstantTBT", param)

			param.fakeParam = nil
			param.nextTurnIcon.fakeParam = nil
			param.turnIcon.fakeParam = nil
			param.softButtons[1].fakeParam = nil

			--hmi side: expect the request
			UIParams = self:createUIParameters(param)
			EXPECT_HMICALL("Navigation.ShowConstantTBT", UIParams)
			:ValidIf(function(_,data)
				if data.params.fakeParam or
					data.params.nextTurnIcon.fakeParam or
					data.params.softButtons.fakeParam or
					data.params.softButtons[1].fakeParam or
					data.params.turnIcon.fakeParam then
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

		--End Test case NegativeRequestCheck.3.2


		-----------------------------------------------------------------------------------------

		--Begin Test case NegativeRequestCheck.3.3
		--Description: Fake parameters is not from another API

		function Test:ShowConstantTBT_FakeParameterIsFromAnotherAPI()

			--mobile side: sending ShowConstantTBT request
			local param  = 	{
								navigationText1 = "1",
								navigationText2 = "2",
								eta = "3",
								totalDistance = "D",
								timeToDestination = "E",
								maneuverComplete = false,
								syncFileName = "icon.png",
								nextTurnIcon = {
									value = "a",
									imageType = "DYNAMIC",
									syncFileName = "icon.png",
								},
								softButtons = {
									{
										softButtonID = 1,
										text = "ABC",
										type = "TEXT",
										isHighlighted = false,
										systemAction = "DEFAULT_ACTION",
										syncFileName = "icon.png",
									}
								},
								turnIcon = {
									value = "a",
									imageType = "DYNAMIC",
									syncFileName = "icon.png",
								},
								distanceToManeuver = 0.1,
								distanceToManeuverScale = 0.1
							}

			local cid = self.mobileSession:SendRPC("ShowConstantTBT", param)

			param.syncFileName = nil
			param.nextTurnIcon.syncFileName = nil
			param.turnIcon.syncFileName = nil
			param.softButtons[1].syncFileName = nil

			--hmi side: expect the request
			UIParams = self:createUIParameters(param)
			EXPECT_HMICALL("Navigation.ShowConstantTBT", UIParams)
			:ValidIf(function(_,data)
				if data.params.nextTurnIcon.syncFileName or
					data.params.softButtons.syncFileName or
					data.params.softButtons[1].syncFileName or
					data.params.turnIcon.syncFileName then
						print(" \27[36m SDL re-sends syncFileName parameters of SetAppIcon request to HMI \27[0m")
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

		--End Test case NegativeRequestCheck.3.3
	--End Test case NegativeRequestCheck.3

	-----------------------------------------------------------------------------------------

	--Begin Test case NegativeRequestCheck.4
	--Description: All parameters missing

		--Requirement id in JAMA: SDLAQ-CRS-664
		--Verification criteria: "3.1. The request with no parameters is sent, the response with INVALID_DATA result code is returned."

		function Test:ShowConstantTBT_MissedAllParameters()

			--mobile side: sending ShowConstantTBT request
			local cid = self.mobileSession:SendRPC("ShowConstantTBT", {} )


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

--Requirement id in JAMA: SDLAQ-CRS-122: ShowConstantTBT_Response
--Verification Criteria: The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode

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
	commonFunctions:newTestCasesGroup("TestCaseGroupForResultCodeParameter")
	-----------------------------------------------------------------------------------------
--[[TODO: check after APPLINK-14765 is resolved
	--1. IsMissed
	Test[APIName.."_Response_resultCode_IsMissed_INVALID_DATA"] = function(self)

		--mobile side: sending the request
		local RequestParams = createRequest()
		local cid = self.mobileSession:SendRPC("ShowConstantTBT", RequestParams)


		--hmi side: expect the request
		UIParams = self:createUIParameters(RequestParams)

		EXPECT_HMICALL("Navigation.ShowConstantTBT", UIParams)
		:Do(function(_,data)
			--hmi side: sending the response
			--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"Navigation.ShowConstantTBT", "code":0}}')
			  self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"Navigation.ShowConstantTBT"}}')
		end)


		--mobile side: expect the response
		EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR",  info = "Invalid message received from vehicle"})
	end
	-----------------------------------------------------------------------------------------
--]]

	--2. IsValidValue
	local resultCodes = {
		{resultCode = "SUCCESS", success =  true},
		{resultCode = "INVALID_DATA", success =  false},
		{resultCode = "OUT_OF_MEMORY", success =  false},
		{resultCode = "TOO_MANY_PENDING_REQUESTS", success =  false},
		{resultCode = "APPLICATION_NOT_REGISTERED", success =  false},
		{resultCode = "GENERIC_ERROR", success =  false},
		{resultCode = "REJECTED", success =  false},
		{resultCode = "DISALLOWED", success =  false},
		{resultCode = "UNSUPPORTED_RESOURCE", success =  true},
		{resultCode = "UNSUPPORTED_REQUEST", success =  false}
	}

	for i =1, #resultCodes do

		Test[APIName.."_resultCode_IsValidValues_" .. resultCodes[i].resultCode .."_SendResponse"] = function(self)

			--mobile side: sending the request
			local RequestParams = createRequest()
			local cid = self.mobileSession:SendRPC("ShowConstantTBT", RequestParams)

			--hmi side: expect the request
			UIParams = self:createUIParameters(RequestParams)

			EXPECT_HMICALL("Navigation.ShowConstantTBT", UIParams)
			:Do(function(_,data)
				--hmi side: sending the response
				if resultCodes[i] == "SUCCESS" then
					self.hmiConnection:SendResponse(data.id, data.method, resultCodes[i].resultCode, {})
				else
					self.hmiConnection:SendError(data.id, data.method, resultCodes[i].resultCode, "")
				end
			end)

			--mobile side: expect ShowConstantTBT response
			EXPECT_RESPONSE(cid, { success = resultCodes[i].success, resultCode = resultCodes[i].resultCode})
		end
	end

	-----------------------------------------------------------------------------------------
--[[TODO: check after APPLINK-14765 is resolved
	--3. IsNotExist
	--4. IsEmpty
	--5. IsWrongType
	--6. IsInvalidCharacter - \n, \t
	local testData = {
		{value = "ANY", name = "IsNotExist"},
		{value = "", name = "IsEmpty"},
		{value = 123, name = "IsWrongType"}
	}

	for i =1, #testData do

		Test[APIName.."_resultCode_" .. testData[i].name .."_SendResponse"] = function(self)

			--mobile side: sending the request
			local RequestParams = createRequest()
			local cid = self.mobileSession:SendRPC("ShowConstantTBT", RequestParams)

			--hmi side: expect the request
			UIParams = self:createUIParameters(RequestParams)

			EXPECT_HMICALL("Navigation.ShowConstantTBT", UIParams)
			:Do(function(_,data)
				--hmi side: sending the response
				self.hmiConnection:SendResponse(data.id, data.method, testData[i].value, {})
			end)

			--mobile side: expect ShowConstantTBT response
			EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR",  info = "Invalid message received from vehicle"})
		end
		-----------------------------------------------------------------------------------------

		Test[APIName.."_resultCode_" .. testData[i].name .."_SendError"] = function(self)

			--mobile side: sending the request
			local RequestParams = createRequest()
			local cid = self.mobileSession:SendRPC("ShowConstantTBT", RequestParams)

			--hmi side: expect the request
			UIParams = self:createUIParameters(RequestParams)

			EXPECT_HMICALL("Navigation.ShowConstantTBT", UIParams)
			:Do(function(_,data)
				--hmi side: sending the response
				self.hmiConnection:SendError(data.id, data.method, testData[i].value)
			end)

			--mobile side: expect ShowConstantTBT response
			EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR",  info = "Invalid message received from vehicle"})
		end
	end
]]
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
	commonFunctions:newTestCasesGroup("TestCaseGroupForMethodParameter")
	-----------------------------------------------------------------------------------------
--[[TODO: check after APPLINK-14765 is resolved
	--1. IsMissed
	Test[APIName.."_Response_method_IsMissed_GENERIC_ERROR"] = function(self)

		--mobile side: sending the request
		local RequestParams = createRequest()
		local cid = self.mobileSession:SendRPC("ShowConstantTBT", RequestParams)


		--hmi side: expect the request
		UIParams = self:createUIParameters(RequestParams)

		EXPECT_HMICALL("Navigation.ShowConstantTBT", UIParams)
		:Do(function(_,data)
			--hmi side: sending the response
			--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"Navigation.ShowConstantTBT", "code":0}}')
			  self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"code":0}}')
		end)

		--mobile side: expect the response
		EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR",  info = "Invalid message received from vehicle"})
	end
	-----------------------------------------------------------------------------------------
--]]
	--2. IsValidValue
	Test[APIName.."_Response_method_IsValidValue_SendResponse"] = function(self)

		--mobile side: sending the request
		local RequestParams = createRequest()
		local cid = self.mobileSession:SendRPC("ShowConstantTBT", RequestParams)

		--hmi side: expect the request
		UIParams = self:createUIParameters(RequestParams)

		EXPECT_HMICALL("Navigation.ShowConstantTBT", UIParams)
		:Do(function(_,data)
			--hmi side: sending the response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)

		--mobile side: expect ShowConstantTBT response
		EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})

	end
	-----------------------------------------------------------------------------------------

	Test[APIName.."_Response_method_IsValidValue_SendError"] = function(self)

		--mobile side: sending the request
		local RequestParams = createRequest()
		local cid = self.mobileSession:SendRPC("ShowConstantTBT", RequestParams)

		--hmi side: expect the request
		UIParams = self:createUIParameters(RequestParams)

		EXPECT_HMICALL("Navigation.ShowConstantTBT", UIParams)
		:Do(function(_,data)
			--hmi side: sending the response
			self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "info")
		end)

		--mobile side: expect ShowConstantTBT response
		EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "info"})
	end
	-----------------------------------------------------------------------------------------
--[[TODO: check after APPLINK-14765 is resolved
	--3. IsNotExist
	--4. IsEmpty
	--5. IsWrongType
	--6. IsInvalidCharacter - \n, \t
	local Methods = {
		{method = "ANY", name = "IsNotExist"},
		{method = "", name = "IsEmpty"},
		{method = 123, name = "IsWrongType"},
		{method = "a\nb", name = "IsInvalidCharacter_NewLine"},
		{method = "a\tb", name = "IsInvalidCharacter_Tab"},
		{method = "     ", name = "WhiteSpacesOnly"},}

	for i =1, #Methods do

		Test[APIName.."_Response_method_" .. Methods[i].name .."_GENERIC_ERROR_SendResponse"] = function(self)

			--mobile side: sending the request
			local RequestParams = createRequest()
			local cid = self.mobileSession:SendRPC("ShowConstantTBT", RequestParams)

			--hmi side: expect the request
			UIParams = self:createUIParameters(RequestParams)

			EXPECT_HMICALL("Navigation.ShowConstantTBT", UIParams)
			:Do(function(_,data)
				--hmi side: sending the response
				--self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				self.hmiConnection:SendResponse(data.id, Methods[i].method, "SUCCESS", {})

			end)

			--mobile side: expect ShowConstantTBT response
			EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR",  info = "Invalid message received from vehicle"})
		end
		-----------------------------------------------------------------------------------------

		Test[APIName.."_Response_method_" .. Methods[i].name .."_GENERIC_ERROR_SendError"] = function(self)

			--mobile side: sending the request
			local RequestParams = createRequest()
			local cid = self.mobileSession:SendRPC("ShowConstantTBT", RequestParams)

			--hmi side: expect the request
			UIParams = self:createUIParameters(RequestParams)

			EXPECT_HMICALL("Navigation.ShowConstantTBT", UIParams)
			:Do(function(_,data)
				--hmi side: sending the response
				--self.hmiConnection:SendError(data.id, data.method, "UNSUPPORTED_RESOURCE", "info")
				  self.hmiConnection:SendError(data.id, Methods[i].method, "UNSUPPORTED_RESOURCE", "info")

			end)

			--mobile side: expect ShowConstantTBT response
			EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR",  info = "Invalid message received from vehicle"})
		end
	end
--]]
end

verify_method_parameter()


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
	commonFunctions:newTestCasesGroup("TestCaseGroupForInfoParameter")

	-----------------------------------------------------------------------------------------

	--1. IsMissed
	Test[APIName.."_info_IsMissed_SendResponse"] = function(self)

		--mobile side: sending the request
		local RequestParams = createRequest()
		local cid = self.mobileSession:SendRPC("ShowConstantTBT", RequestParams)


		--hmi side: expect the request
		UIParams = self:createUIParameters(RequestParams)

		EXPECT_HMICALL("Navigation.ShowConstantTBT", UIParams)
		:Do(function(_,data)
			--hmi side: sending the response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)


		--mobile side: expect the response
		EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
		:ValidIf (function(_,data)
			if data.payload.info then
				print(" \27[36m SDL resends invalid info parameter to mobile app. \27[0m")
				return false
			else
				return true
			end
		end)
	end
	-----------------------------------------------------------------------------------------

	Test[APIName.."_info_IsMissed_SendError"] = function(self)

		--mobile side: sending the request
		local RequestParams = createRequest()
		local cid = self.mobileSession:SendRPC("ShowConstantTBT", RequestParams)


		--hmi side: expect the request
		UIParams = self:createUIParameters(RequestParams)

		EXPECT_HMICALL("Navigation.ShowConstantTBT", UIParams)
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
	local testData = {
		{value = "a", name = "IsLowerBound"},
		{value = commonFunctions:createString(1000), name = "IsUpperBound"}}

	for i =1, #testData do
		Test[APIName.."_info_" .. testData[i].name .."_SendResponse"] = function(self)

			--mobile side: sending the request
			local RequestParams = createRequest()
			local cid = self.mobileSession:SendRPC("ShowConstantTBT", RequestParams)

			--hmi side: expect the request
			UIParams = self:createUIParameters(RequestParams)

			EXPECT_HMICALL("Navigation.ShowConstantTBT", UIParams)
			:Do(function(_,data)
				--hmi side: sending the response
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {message = testData[i].value})
			end)

			--mobile side: expect ShowConstantTBT response
			EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", info = testData[i].value})
		end
		-----------------------------------------------------------------------------------------

		Test[APIName.."_info_" .. testData[i].name .."_SendError"] = function(self)

			--mobile side: sending the request
			local RequestParams = createRequest()
			local cid = self.mobileSession:SendRPC("ShowConstantTBT", RequestParams)

			--hmi side: expect the request
			UIParams = self:createUIParameters(RequestParams)

			EXPECT_HMICALL("Navigation.ShowConstantTBT", UIParams)
			:Do(function(_,data)
				--hmi side: sending the response
				self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", testData[i].value)
			end)

			--mobile side: expect ShowConstantTBT response
			EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = testData[i].value})

		end
	end
	-----------------------------------------------------------------------------------------


	--4. IsOutUpperBound
	Test[APIName.."_info_IsOutUpperBound_SendResponse"] = function(self)

		local infoMaxLength = commonFunctions:createString(1000)

		--mobile side: sending the request
		local RequestParams = createRequest()
		local cid = self.mobileSession:SendRPC("ShowConstantTBT", RequestParams)

		--hmi side: expect the request
		UIParams = self:createUIParameters(RequestParams)

		EXPECT_HMICALL("Navigation.ShowConstantTBT", UIParams)
		:Do(function(_,data)
			--hmi side: sending the response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {message = infoMaxLength .. "1"})
		end)

		--mobile side: expect ShowConstantTBT response
		EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", info = infoMaxLength})
	end
	-----------------------------------------------------------------------------------------

	Test[APIName.."_info_IsOutUpperBound_SendError"] = function(self)

		local infoMaxLength = commonFunctions:createString(1000)

		--mobile side: sending the request
		local RequestParams = createRequest()
		local cid = self.mobileSession:SendRPC("ShowConstantTBT", RequestParams)

		--hmi side: expect the request
		UIParams = self:createUIParameters(RequestParams)

		EXPECT_HMICALL("Navigation.ShowConstantTBT", UIParams)
		:Do(function(_,data)
			--hmi side: sending the response
			self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", infoMaxLength .."1")
		end)

		--mobile side: expect ShowConstantTBT response
		EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = infoMaxLength})
	end
	-----------------------------------------------------------------------------------------
	-- TODO: update after resolving APPLINK-14551

	--5. IsEmpty/IsOutLowerBound
	--6. IsWrongType
	--7. InvalidCharacter - \n, \t, white spaces only

	-- local testData = {
	-- 	{value = "", name = "IsEmpty_IsOutLowerBound"},
	-- 	{value = 123, name = "IsWrongType"},
	-- 	{value = "a\nb", name = "IsInvalidCharacter_NewLine"},
	-- 	{value = "a\tb", name = "IsInvalidCharacter_Tab"},
	-- 	{value = "      ", name = "WhiteSpacesOnly"}}

	-- for i =1, #testData do

	-- 	Test[APIName.."_info_" .. testData[i].name .."_SendResponse"] = function(self)

	-- 		--mobile side: sending the request
	-- 		local RequestParams = createRequest()
	-- 		local cid = self.mobileSession:SendRPC("ShowConstantTBT", RequestParams)

	-- 		--hmi side: expect the request
	-- 		UIParams = self:createUIParameters(RequestParams)

	-- 		EXPECT_HMICALL("Navigation.ShowConstantTBT", UIParams)
	-- 		:Do(function(_,data)
	-- 			--hmi side: sending the response
	-- 			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {message = testData[i].value})
	-- 		end)

	-- 		--mobile side: expect ShowConstantTBT response
	-- 		EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
	-- 		:ValidIf (function(_,data)
	-- 			if data.payload.info then
	-- 				print(" \27[36m  SDL resends info parameter to mobile app. info = \"" .. data.payload.info .. "\" \27[0m")
	-- 				return false
	-- 			else
	-- 				return true
	-- 			end
	-- 		end)
	-- 	end
	-- 	-----------------------------------------------------------------------------------------

	-- 	Test[APIName.."_info_" .. testData[i].name .."_SendError"] = function(self)

	-- 		--mobile side: sending the request
	-- 		local RequestParams = createRequest()
	-- 		local cid = self.mobileSession:SendRPC("ShowConstantTBT", RequestParams)

	-- 		--hmi side: expect the request
	-- 		UIParams = self:createUIParameters(RequestParams)

	-- 		EXPECT_HMICALL("Navigation.ShowConstantTBT", UIParams)
	-- 		:Do(function(_,data)
	-- 			--hmi side: sending the response
	-- 			self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", testData[i].value)
	-- 		end)

	-- 		--mobile side: expect ShowConstantTBT response
	-- 		EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
	-- 		:ValidIf (function(_,data)
	-- 			if data.payload.info then
	-- 				print(" \27[36m SDL resends info parameter to mobile app. info = \"" .. data.payload.info .. "\" \27[0m")
	-- 				return false
	-- 			else
	-- 				return true
	-- 			end
	-- 		end)
	-- 	end
	-- end
end

verify_info_parameter()


-----------------------------------------------------------------------------------------------
--Parameter 4: correlationID
-----------------------------------------------------------------------------------------------
--List of test cases:
	--1. CorrelationIDMissing
	--2. CorrelationIDWrongType
	--3. CorrelationIDNotExisted
	--4. CorrelationIDNegative
-----------------------------------------------------------------------------------------------
--[[TODO: check after APPLINK-14765 is resolved
local function verify_correlationID_parameter()


	--Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup("TestCaseGroupForCorrelationIDParameter")

	-----------------------------------------------------------------------------------------

	--1. CorrelationIDMissing
	function Test:ReadDID_Response_CorrelationIDMissing()

		--mobile side: sending the request
		local RequestParams = createRequest()
		local cid = self.mobileSession:SendRPC("ShowConstantTBT", RequestParams)


		--hmi side: expect the request
		UIParams = self:createUIParameters(RequestParams)

		EXPECT_HMICALL("Navigation.ShowConstantTBT", UIParams)
		:Do(function(_,data)
			--hmi side: sending the response
			--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"Navigation.ShowConstantTBT", "code":0}}')
			self.hmiConnection:Send('{"jsonrpc":"2.0","result":{"method":"Navigation.ShowConstantTBT", "code":0}}')
		end)

		--mobile side: expect the response
		EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR",  info = "Invalid message received from vehicle"})
	end
	-----------------------------------------------------------------------------------------

	--2. CorrelationIDWrongType
	function Test:ReadDID_Response_CorrelationIDWrongType()
		--mobile side: sending the request
		local RequestParams = createRequest()
		local cid = self.mobileSession:SendRPC("ShowConstantTBT", RequestParams)


		--hmi side: expect the request
		UIParams = self:createUIParameters(RequestParams)

		EXPECT_HMICALL("Navigation.ShowConstantTBT", UIParams)
		:Do(function(_,data)
			--hmi side: sending the response
			self.hmiConnection:SendResponse(tostring(data.id), data.method, "SUCCESS", {})
		end)

		--mobile side: expect the response
		EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR",  info = "Invalid message received from vehicle"})
	end
	-----------------------------------------------------------------------------------------

	--3. CorrelationIDNotExisted
	function Test:ReadDID_Response_CorrelationIDNotExisted()

		--mobile side: sending the request
		local RequestParams = createRequest()
		local cid = self.mobileSession:SendRPC("ShowConstantTBT", RequestParams)


		--hmi side: expect the request
		UIParams = self:createUIParameters(RequestParams)

		EXPECT_HMICALL("Navigation.ShowConstantTBT", UIParams)
		:Do(function(_,data)
			--hmi side: sending the response
			self.hmiConnection:SendResponse(9999, data.method, "SUCCESS", {})
		end)

		--mobile side: expect the response
		EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR",  info = "Invalid message received from vehicle"})
	end
	-----------------------------------------------------------------------------------------

	--4. CorrelationIDNegative
	function Test:ReadDID_Response_CorrelationIDNegative()

		--mobile side: sending the request
		local RequestParams = createRequest()
		local cid = self.mobileSession:SendRPC("ShowConstantTBT", RequestParams)


		--hmi side: expect the request
		UIParams = self:createUIParameters(RequestParams)

		EXPECT_HMICALL("Navigation.ShowConstantTBT", UIParams)
		:Do(function(_,data)
			--hmi side: sending the response
			self.hmiConnection:SendResponse(-1, data.method, "SUCCESS", {})
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
--Requirement id in JAMA or JIRA:
	--SDLAQ-CRS-121: ShowConstantTBT_Request_v2_0
	--SDLAQ-CRS-122: ShowConstantTBT_Response
	--SDLAQ-CRS-663: SUCCESS
	--SDLAQ-CRS-670: GENERIC_ERROR

-----------------------------------------------------------------------------------------------

--List of test cases for softButtons type parameter:
	--1. InvalidJsonSyntax (SDLAQ-CRS-670: GENERIC_ERROR)
	--2. InvalidStructure (SDLAQ-CRS-670: GENERIC_ERROR)
	--2. DuplicatedCorrelationId (SDLAQ-CRS-663: SUCCESS)
	--3. FakeParams and FakeParameterIsFromAnotherAPI (APPLINK-14765: SDL must cut off the fake parameters from requests, responses and notifications received from HMI)
	--4. MissedAllPArameters (SDLAQ-CRS-670: GENERIC_ERROR)
	--5. NoResponse (SDLAQ-CRS-670: GENERIC_ERROR)
	--6. SeveralResponsesToOneRequest with the same and different resultCode
-----------------------------------------------------------------------------------------------

local function SpecialResponseChecks()

--Begin Test case NegativeResponseCheck
--Description: Check all negative response cases


	--Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup("NewTestCasesGroupForNegativeResponseCheck")

	--Begin Test case NegativeResponseCheck.1
	--Description: Invalid JSON

		--Requirement id in JAMA: SDLAQ-CRS-122
		--Verification criteria: The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.

		--[[ToDo: Check after APPLINK-14765 is resolved

		function Test:ShowConstantTBT_InvalidJsonSyntaxResponse()

			--mobile side: sending the request
			local RequestParams = createRequest()
			local cid = self.mobileSession:SendRPC("ShowConstantTBT", RequestParams)

			--hmi side: expect the request
			local UIParams = self:createUIParameters(RequestParams)
			EXPECT_HMICALL("Navigation.ShowConstantTBT", UIParams)
			:Do(function(_,data)
				--hmi side: sending the response
				--":" is changed by ";" after {"id"
				--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"Navigation.ShowConstantTBT", "code":0}}')
				  self.hmiConnection:Send('{"id";'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"Navigation.ShowConstantTBT", "code":0}}')
			end)

			--mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR",  info = "Invalid message received from vehicle"})
		end
	--End Test case NegativeResponseCheck.1

	-----------------------------------------------------------------------------------------

	--Begin Test case NegativeResponseCheck.2
	--Description: Invalid structure of response

		--Requirement id in JAMA: SDLAQ-CRS-122
		--Verification criteria: The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode

		function Test:ShowConstantTBT_InvalidStructureResponse()

			--mobile side: sending the request
			local RequestParams = createRequest()
			local cid = self.mobileSession:SendRPC("ShowConstantTBT", RequestParams)

			--hmi side: expect the request
			local UIParams = self:createUIParameters(RequestParams)
			EXPECT_HMICALL("Navigation.ShowConstantTBT", UIParams)
			:Do(function(_,data)
				--hmi side: sending the response
				--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"Navigation.ShowConstantTBT", "code":0}}')
				self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0", "code":0, "result":{"method":"Navigation.ShowConstantTBT"}}')
			end)

			--mobile side: expect response
			EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR",  info = "Invalid message received from vehicle"})
		end
	--End Test case NegativeResponseCheck.2
]]

	-----------------------------------------------------------------------------------------

	--Begin Test case NegativeResponseCheck.3
	--Description: Check processing response with fake parameters

		--Verification criteria: When expected HMI function is received, send responses from HMI with fake parameter

		--Begin Test case NegativeResponseCheck.3.1
		--Description: Parameter is not from API
			function Test:ShowConstantTBT_FakeParamsInResponse()

				--mobile side: sending the request
				local RequestParams = createRequest()
				local cid = self.mobileSession:SendRPC("ShowConstantTBT", RequestParams)

				--hmi side: expect the request
				local UIParams = self:createUIParameters(RequestParams)
				EXPECT_HMICALL("Navigation.ShowConstantTBT", UIParams)
				:Do(function(exp,data)
					--hmi side: sending the response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {fake = "fake"})
				end)


				--mobile side: expect the response
				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
				:ValidIf (function(_,data)
					if data.payload.fake then
						print(" \27[36m SDL resend fake parameter to mobile app \27[0m")
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
			function Test:ShowConstantTBT_AnotherParameterInResponse()
				--mobile side: sending the request
				local RequestParams = createRequest()
				local cid = self.mobileSession:SendRPC("ShowConstantTBT", RequestParams)

				--hmi side: expect the request
				local UIParams = self:createUIParameters(RequestParams)
				EXPECT_HMICALL("Navigation.ShowConstantTBT", UIParams)
				:Do(function(exp,data)
					--hmi side: sending the response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {sliderPosition = 5})
				end)

				--mobile side: expect the response
				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
				:ValidIf (function(_,data)
					if data.payload.sliderPosition then
						print(" \27[36m SDL resend fake parameter to mobile app \27[0m")
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
		function Test:ShowConstantTBT_Response_MissedAllPArameters()
			--mobile side: sending the request
			local RequestParams = createRequest()
			local cid = self.mobileSession:SendRPC("ShowConstantTBT", RequestParams)


			--hmi side: expect the request
			UIParams = self:createUIParameters(RequestParams)

			EXPECT_HMICALL("Navigation.ShowConstantTBT", UIParams)
			:Do(function(_,data)
				--hmi side: sending Navigation.ShowConstantTBT response
				--self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"Navigation.ShowConstantTBT", "code":0}}')
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

		--Requirement id in JAMA: SDLAQ-CRS-670
		--Verification criteria: GENERIC_ERROR comes as a result code in response when all other codes aren't applicable or the unknown issue occurred.

		function Test:ShowConstantTBT_NoResponse()
			--mobile side: sending the request
			local RequestParams = createRequest()
			local cid = self.mobileSession:SendRPC("ShowConstantTBT", RequestParams)

			--hmi side: expect the request
			local UIParams = self:createUIParameters(RequestParams)
			EXPECT_HMICALL("Navigation.ShowConstantTBT", UIParams)


			--mobile side: expect ShowConstantTBT response
			EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
			:Timeout(12000)
		end
	--End NegativeResponseCheck.5

	-----------------------------------------------------------------------------------------

	--Begin Test case NegativeResponseCheck.6
	--Description: Several response to one request

		--Requirement id in JAMA: SDLAQ-CRS-122

		--Verification criteria: The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.


		--Begin Test case NegativeResponseCheck.6.1
		--Description: Several response to one request
			function Test:ShowConstantTBT_SeveralResponsesToOneRequest()
				--mobile side: sending the request
				local RequestParams = createRequest()
				local cid = self.mobileSession:SendRPC("ShowConstantTBT", RequestParams)

				--hmi side: expect the request
				local UIParams = self:createUIParameters(RequestParams)
				EXPECT_HMICALL("Navigation.ShowConstantTBT", UIParams)
				:Do(function(exp,data)
					--hmi side: sending the response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				end)

				--mobile side: expect response
				EXPECT_RESPONSE(cid, {  success = true, resultCode = "SUCCESS"})
			end
		--End Test case NegativeResponseCheck.6.1

		-----------------------------------------------------------------------------------------

		--Begin Test case NegativeResponseCheck.6.2
		--Description: Several response to one request
			function Test:ShowConstantTBT_SeveralResponsesToOneRequestWithConstractionsOfResultCode()

				--mobile side: sending the request
				local RequestParams = createRequest()
				local cid = self.mobileSession:SendRPC("ShowConstantTBT", RequestParams)

				--hmi side: expect the request
				local UIParams = self:createUIParameters(RequestParams)
				EXPECT_HMICALL("Navigation.ShowConstantTBT", UIParams)
				:Do(function(exp,data)
					--hmi side: sending the response
					self.hmiConnection:SendResponse(data.id, data.method, "INVALID_DATA", {})
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				end)

				--mobile side: expect response
				EXPECT_RESPONSE(cid, {  success = false, resultCode = "INVALID_DATA"})
			end
		--End Test case NegativeResponseCheck.6.2
	--End Test case NegativeResponseCheck.6

	-----------------------------------------------------------------------------------------
--[[TODO: Check if APPLINK-14765 is resolved
	--Begin Test case NegativeResponseCheck.7
	--Description: Wrong response ( two contractions of result in response) with correct HMI id

		--Requirement id in JAMA: SDLAQ-CRS-122, APPLINK-14765

		--Verification criteria:
			-- The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.
			-- In case SDL cuts off fake parameters from response (request) that SDL should transfer to mobile app AND this response (request) is invalid SDL must respond GENERIC_ERROR (success:false, info: "Invalid message received from vehicle") to mobile app
			function Test:ShowConstantTBT_WrongResponse()
				--mobile side: sending the request
				local RequestParams = createRequest()
				local cid = self.mobileSession:SendRPC("ShowConstantTBT", RequestParams)

				--hmi side: expect the request
				local UIParams = self:createUIParameters(RequestParams)
				EXPECT_HMICALL("Navigation.ShowConstantTBT", UIParams)
				:Do(function(exp,data)
					--hmi side: sending the response
					self.hmiConnection:Send('{"error":{"code":4,"message":"ShowConstantTBT is REJECTED"},"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"code":0,"method":"Navigation.ShowConstantTBT"}}')
				end)

				--mobile side: expect response
				EXPECT_RESPONSE(cid, {  success = false, resultCode = "GENERIC_ERROR"})
			end
	--Begin Test case NegativeResponseCheck.7
--]]
--End Test case NegativeResponseCheck

end

SpecialResponseChecks()


-----------------------------------------------------------------------------------------------
-------------------------------------------TEST BLOCK V----------------------------------------
-------------------------------------Checks All Result Codes-----------------------------------
-----------------------------------------------------------------------------------------------

--Description: Check all resultCodes

--Requirement id in JAMA:
	--SDLAQ-CRS-663: SUCCESS
	--SDLAQ-CRS-664: INVALID_DATA
	--SDLAQ-CRS-665: OUT_OF_MEMORY
	--SDLAQ-CRS-666: TOO_MANY_PENDING_REQUESTS
	--SDLAQ-CRS-670: GENERIC_ERROR
	--SDLAQ-CRS-667: APPLICATION_NOT_REGISTERED
	--SDLAQ-CRS-668: REJECTED
	--SDLAQ-CRS-671: DISALLOWED
	--SDLAQ-CRS-1033: UNSUPPORTED_RESOURCE
	--SDLAQ-CRS-1037: UNSUPPORTED_REQUEST


local function ResultCodeChecks()

	--Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup("NewTestCasesGroupForResultCodeChecks")


	--Check resultCode SUCCESS. It is checked by other test cases.
	--Check resultCode INVALID_DATA. It is checked by other test cases.
	--Check resultCode GENERIC_ERROR. It is covered in Test:ShowConstantTBT_NoResponse
	--Check resultCode OUT_OF_MEMORY. -- Not applicable
	--Check resultCode TOO_MANY_PENDING_REQUESTS. It is moved to other script.
	-----------------------------------------------------------------------------------------

	--Begin Test case ResultCodeChecks.1
	--Description: Check resultCode APPLICATION_NOT_REGISTERED

		--Requirement id in JAMA: SDLAQ-CRS-667
		--Verification criteria: SDL sends APPLICATION_NOT_REGISTERED code when the app sends a request within the same connection before RegisterAppInterface has been performed yet.


		--Precondition
		function Test:Precondition_CreationNewSession()
			-- Connected expectation
			self.mobileSession2 = mobile_session.MobileSession(
																	self,
																	self.mobileConnection
																)
		end

		function Test:ShowConstantTBT_resultCode_APPLICATION_NOT_REGISTERED()

			--mobile side: sending the request
			local RequestParams = createRequest()
			local cid = self.mobileSession2:SendRPC("ShowConstantTBT", RequestParams)

			--mobile side: expect response
			self.mobileSession2:ExpectResponse(cid, {  success = false, resultCode = "APPLICATION_NOT_REGISTERED"})
		end
	--End Test case ResultCodeChecks.1

	-----------------------------------------------------------------------------------------

	--Begin Test case ResultCodeChecks.2
	--Description: Check resultCode DISALLOWED

		--Requirement id in JAMA: SDLAQ-CRS-671
		--Verification criteria:
			--1. SDL must return "DISALLOWED, success:false" for Alert RPC to mobile app IN CASE Alert RPC is not included to policies assigned to this mobile app.
			--2. SDL must return "DISALLOWED, success:false" for Alert RPC to mobile app IN CASE Alert RPC contains softButton with SystemAction disallowed by policies assigned to this mobile app.

		--Begin Test case ResultCodeChecks.2.1
		--Description: Check resultCode DISALLOWED when HMI level is NONE

			--Covered by test case ShowConstantTBT_HMIStatus_NONE

		--End Test case ResultCodeChecks.2.1

		-----------------------------------------------------------------------------------------

--[[TODO debug after resolving APPLINK-13101

		--Begin Test case ResultCodeChecks.2.2
		--Description: Check resultCode DISALLOWED when request is not assigned to app

			function Test:Precondition_PolicyUpdate()
				self:policyUpdate("PTU_OmittedShowConstantTBT", false)
			end

			function Test:ShowConstantTBT_resultCode_DISALLOWED_RPCOmitted()

				--mobile side: sending the request
				local RequestParams = createRequest()
				local cid = self.mobileSession:SendRPC("ShowConstantTBT", RequestParams)

				--mobile side: expect response
				EXPECT_RESPONSE(cid, {  success = false, resultCode = "DISALLOWED"})
			end
		--End Test case ResultCodeChecks.2.2

		-----------------------------------------------------------------------------------------

		--Begin Test case ResultCodeChecks.2.3
		--Description: Check resultCode DISALLOWED when request is assigned to app but user does not allow

			function Test:Precondition_PolicyUpdate()
				self:policyUpdate("PTU_ForShowConstantTBTSoftButtonFalse", false)
			end

			function Test:ShowConstantTBT_resultCode_SoftButtonDISALLOWED()

				--mobile side: sending the request
				local RequestParams = createRequest()
				local cid = self.mobileSession:SendRPC("ShowConstantTBT", RequestParams)

				--mobile side: expect response
				EXPECT_RESPONSE(cid, {  success = false, resultCode = "DISALLOWED"})
			end

		--End Test case ResultCodeChecks.2.3

		-----------------------------------------------------------------------------------------

		--Begin Test case ResultCodeChecks.2.4
		--Description: Check resultCode DISALLOWED when request is assigned to app, user allows but "keep_context" : false, "steal_focus" : false

			function Test:Precondition_UserAllowsFunctionGroup_Disallowed_softButtons()
				--hmi side: sending SDL.OnAppPermissionConsent
				self.hmiConnection:SendNotification("SDL.OnAppPermissionConsent", { appID =  self.applications["Test Application"], consentedFunctions = {{ allowed = true, id = groupID, name = groupName}}, source = "GUI"})

				EXPECT_NOTIFICATION("OnPermissionsChange")
			end

			function Test:ShowConstantTBT_resultCode_DISALLOWED_systemAction_Is_KEEP_CONTEXT()

				--mobile side: send the request
				local cid = self.mobileSession:SendRPC("ShowConstantTBT",
									{
										navigationText1 = "NavigationText1",
										softButtons =
										{
											{
												type = "TEXT",
												text = "Keep",
												isHighlighted = true,
												softButtonID = 4,
												systemAction = "KEEP_CONTEXT",
											}
										}

									})

			    --mobile side: expect the response
			    EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED" })
			end

			function Test:ShowConstantTBT_resultCode_DISALLOWED_systemAction_Is_STEAL_FOCUS()

				--mobile side: send the request
				local cid = self.mobileSession:SendRPC("ShowConstantTBT",
									{
										navigationText1 = "NavigationText1",
										softButtons =
										{
											{
												type = "TEXT",
												text = "Keep",
												isHighlighted = true,
												softButtonID = 4,
												systemAction = "STEAL_FOCUS",
											}
										}
									})

			    --mobile side: expect the response
			    EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED" })
			end

			--Postcondition: Update PT to allow ShowConstantTBT request
			function Test:Postcondition_PolicyUpdate()
				self:policyUpdate("PTU_ForShowConstantTBTSoftButtonTrue", true)
			end
		--End Test case ResultCodeChecks.2.4
	--]]

	--End Test case ResultCodeChecks.2

	-----------------------------------------------------------------------------------------

	--Begin Test case ResultCodeChecks.3
	--Description: Check resultCode UNSUPPORTED_RESOURCE

		--Requirement id in JAMA: SDLAQ-CRS-1033
		--Verification criteria:
			-- When images aren't supported on HMI at all, UNSUPPORTED_RESOURCE is returned by HMI to SDL and then by SDL to mobile as a result of request. Info parameter provides additional information about the case. General request result success=true in case of no errors from other components.
			-- When "STATIC" image type isn't supported on HMI, UNSUPPORTED_RESOURCE is returned by HMI to SDL and then by SDL to mobile as a result of request. Info parameter provides additional information about the case. General request result success=true in case of no errors from other components.
			-- When "DYNAMIC" image type isn't supported on HMI, UNSUPPORTED_RESOURCE is returned by HMI to SDL and then by SDL to mobile as a result of request. Info parameter provides additional information about the case. General request result success=true in case of no errors from other components.

		function Test:ShowConstantTBT_resultCode_UNSUPPORTED_RESOURCE()
			--mobile side: sending the request
			local RequestParams = createRequest()
			local cid = self.mobileSession:SendRPC("ShowConstantTBT", RequestParams)

			--hmi side: expect the request
			local UIParams = self:createUIParameters(RequestParams)
			EXPECT_HMICALL("Navigation.ShowConstantTBT", UIParams)
			:Do(function(exp,data)
				--hmi side: sending the response
				self.hmiConnection:SendError(data.id, data.method, "UNSUPPORTED_RESOURCE", "HMI doesn't support STATIC, DYNAMIC or any image types which exist in request data")
			end)

			--mobile side: expect response
			EXPECT_RESPONSE(cid, {  success = true, resultCode = "UNSUPPORTED_RESOURCE", info = "HMI doesn't support STATIC, DYNAMIC or any image types which exist in request data"})
		end

	--End Test case ResultCodeChecks.3
end

ResultCodeChecks()

----------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK VI----------------------------------------
-------------------------Sequence with emulating of user's action(s)--------------------------
----------------------------------------------------------------------------------------------

--Description: TC's checks SDL behaviour by processing
	-- different request sequence with timeout
	-- with emulating of user's actions

--Requirement id in JAMA: Mentions in each test case

local function SequenceChecks()

	--Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup("NewTestCasesGroupForSequenceCheck")

	--Begin Test case SequenceChecks.1
	--Description: Check behaviour when clicked on softButton

		--Requirement id in JAMA:
			--SDLAQ-CRS-934

		--Verification criteria:
			-- If supported on current HMI, DEFAULT_ACTION is applicable for ShowConstantTBT request processing. For current implementation DEFAULT_ACTION is supported on HMI. OnButtonPress/OnButtonEvent is sent if the application is subscribed to CUSTOM_BUTTON.
			-- For current implementation STEAL_FOCUS and KEEP_CONTEXT  are NOT supported for ShowConstantTBT on HMI. As a reaction on SoftButton press with STEAL_FOCUS or KEEP_CONTEXT SystemAction HMI makes no action except sending OnButtonPress/OnButtonEvent.

		local softButtonSystemAction = {"DEFAULT_ACTION","KEEP_CONTEXT","STEAL_FOCUS"}
		for i=1, #softButtonSystemAction do
			Test["ShowConstantTBT_ClickOn_SB_"..softButtonSystemAction[i]] = function(self)
				local RequestParams = {
											navigationText1 = "NavigationText1",
											softButtons =
											{
												{
													systemAction = softButtonSystemAction[i],
													type = "BOTH",
													isHighlighted = true,
													text = "Text",
													image =
													{
													   imageType = "DYNAMIC",
													   value = "icon.png"
													},
													softButtonID = 1
												}
											}
										}
				--mobile side: sending ShowConstantTBT request
				local cid = self.mobileSession:SendRPC("ShowConstantTBT", RequestParams)

				-- TODO: remove after resolving APPLINK-16052
				RequestParams.softButtons[1].image = nil

				UIParams = self:createUIParameters(RequestParams)

				--hmi side: expect Navigation.ShowConstantTBT request
				EXPECT_HMICALL("Navigation.ShowConstantTBT", UIParams)
				:Do(function(_,data)
					--hmi side: send request to short click on softButton
					self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONDOWN", customButtonID = 1, appID = self.applications["Test Application"]})
					self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONUP", customButtonID = 1, appID = self.applications["Test Application"]})
					self.hmiConnection:SendNotification("Buttons.OnButtonPress", {name = "CUSTOM_BUTTON", mode = "SHORT", customButtonID = 1, appID = self.applications["Test Application"]})

					--hmi side: send request to long click on softButton
					self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONDOWN", customButtonID = 1, appID = self.applications["Test Application"]})
					self.hmiConnection:SendNotification("Buttons.OnButtonPress", {name = "CUSTOM_BUTTON", mode = "LONG", customButtonID = 1, appID = self.applications["Test Application"]})
					self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONUP", customButtonID = 1, appID = self.applications["Test Application"]})

					--hmi side: sending Navigation.ShowConstantTBT response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				end)

				--mobile side: expect ShowConstantTBT response
				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

				--mobile side: notifications are not sent to mobile app
				EXPECT_NOTIFICATION("OnButtonEvent",{ customButtonID = 1, buttonEventMode = "BUTTONDOWN", buttonName = "CUSTOM_BUTTON"},
													{ customButtonID = 1, buttonEventMode = "BUTTONUP", buttonName = "CUSTOM_BUTTON"},
													{ customButtonID = 1, buttonEventMode = "BUTTONDOWN", buttonName = "CUSTOM_BUTTON"},
													{ customButtonID = 1, buttonEventMode = "BUTTONUP", buttonName = "CUSTOM_BUTTON"})
				:Times(4)

				EXPECT_NOTIFICATION("OnButtonPress",{ customButtonID = 1, buttonPressMode = "SHORT", buttonName = "CUSTOM_BUTTON"},
													{ customButtonID = 1, buttonPressMode = "LONG", buttonName = "CUSTOM_BUTTON"})
				:Times(2)
			end
		end
end

--End Test case SequenceCheck.1

--------------------------------------------------------------------------------------------------------------------------------------------

        --Begin Test case SequenceCheck.2
	--Description: Check test case TC_SoftButtons_01(SDLAQ-TC-68)

		--Requirement id in JAMA: SDLAQ-CRS-869

		--Verification criteria: Checking short click on TEXT soft button

            function Test:SCT_TEXTSoftButtons_ShortClick()
				local RequestParams = {
											navigationText1 = "NavigationText",
											softButtons =
											{
												{
													systemAction = "KEEP_CONTEXT",
													type = "TEXT",
													isHighlighted = false,
													text = "First",
													softButtonID = 1
												},
                                                                                                {
													systemAction = "DEFAULT_ACTION",
													type = "TEXT",
													isHighlighted = true,
													text = "Second",
													softButtonID = 2
												},
                                                                                                 {
													systemAction = "DEFAULT_ACTION",
													type = "TEXT",
													isHighlighted = true,
													text = "Third",
													image =
													{
													   imageType = "DYNAMIC",
													   value = "icon.png"
													},
													softButtonID = 3
												}
											}
										}
				--mobile side: sending ShowConstantTBT request
				local cid = self.mobileSession:SendRPC("ShowConstantTBT", RequestParams)

				-- TODO: remove after resolving APPLINK-16052
				RequestParams.image = nil

				UIParams = self:createUIParameters(RequestParams)

				--hmi side: expect Navigation.ShowConstantTBT request
				EXPECT_HMICALL("Navigation.ShowConstantTBT", UIParams)
				:Do(function(_,data)

					--hmi side: send request to short click on "Second" softButton
					self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONDOWN", customButtonID = 2, appID = self.applications["Test Application"]})
					self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONUP", customButtonID = 2, appID = self.applications["Test Application"]})
					self.hmiConnection:SendNotification("Buttons.OnButtonPress", {name = "CUSTOM_BUTTON", mode = "SHORT", customButtonID = 2, appID = self.applications["Test Application"]})


					--hmi side: sending Navigation.ShowConstantTBT response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				end)

				--mobile side: expect ShowConstantTBT response
				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

				--mobile side: notifications are sent to mobile app
				EXPECT_NOTIFICATION("OnButtonEvent",{ customButtonID = 2, buttonEventMode = "BUTTONDOWN", buttonName = "CUSTOM_BUTTON"},
								    { customButtonID = 2, buttonEventMode = "BUTTONUP", buttonName = "CUSTOM_BUTTON"})
				:Times(2)

				EXPECT_NOTIFICATION("OnButtonPress",{ customButtonID = 2, buttonPressMode = "SHORT", buttonName = "CUSTOM_BUTTON"})
				:Times(1)

			end


         --End Test case SequenceCheck.2
	-----------------------------------------------------------------------------------------

	--Begin Test case SequenceCheck.3
	--Description: Check test case TC_SoftButtons_01(SDLAQ-TC-68)

		--Requirement id in JAMA: SDLAQ-CRS-200

		--Verification criteria: Checking TEXT soft button reflecting on UI only if text is defined

                    function Test:SCT_TEXTSoftButtonsAndTextMissing()
				local RequestParams = {
											navigationText1 = "NavigationText",
											softButtons =
											{

                                                                                                 {
													systemAction = "DEFAULT_ACTION",
													type = "TEXT",
													isHighlighted = false,
													image =
													{
													   imageType = "DYNAMIC",
													   value = "action.png"
													},
													softButtonID = 1
												}
											}
										}
				--mobile side: sending ShowConstantTBT request
				local cid = self.mobileSession:SendRPC("ShowConstantTBT", RequestParams)

				-- TODO: remove after resolving APPLINK-16052
				RequestParams.image = nil

				UIParams = self:createUIParameters(RequestParams)

				--hmi side: expect Navigation.ShowConstantTBT request
				EXPECT_HMICALL("Navigation.ShowConstantTBT", UIParams)
				:Times(0)

				--mobile side: expect ShowConstantTBT response
				EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })


			end



         --End Test case SequenceCheck.3
	-----------------------------------------------------------------------------------------

	--Begin Test case SequenceCheck.4
	--Description: Check test case TC_SoftButtons_01(SDLAQ-TC-68)

		--Requirement id in JAMA: SDLAQ-CRS-870

		--Verification criteria: Checking long click on TEXT soft button

                             function Test:SCT_TEXTSoftButtons_LongClick()
				local RequestParams = {
											navigationText1 = "NavigationText",
											softButtons =
											{
												{
													systemAction = "KEEP_CONTEXT",
													type = "TEXT",
													isHighlighted = false,
													text = "First",
													softButtonID = 1
												},
                                                                                                {
													systemAction = "STEAL_FOCUS",
													type = "TEXT",
													isHighlighted = true,
													text = "Second",
													softButtonID = 2
												},
                                                                                                 {
													systemAction = "DEFAULT_ACTION",
													type = "TEXT",
													isHighlighted = true,
													text = "Third",
													softButtonID = 3
												}
											}
										}
				--mobile side: sending ShowConstantTBT request
				local cid = self.mobileSession:SendRPC("ShowConstantTBT", RequestParams)

				-- TODO: remove after resolving APPLINK-16052
				RequestParams.image = nil

				UIParams = self:createUIParameters(RequestParams)

				--hmi side: expect Navigation.ShowConstantTBT request
				EXPECT_HMICALL("Navigation.ShowConstantTBT", UIParams)
				:Do(function(_,data)

					--hmi side: send request to long click on "Third" softButton
					self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONDOWN", customButtonID = 3, appID = self.applications["Test Application"]})
					self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONUP", customButtonID = 3, appID = self.applications["Test Application"]})
					self.hmiConnection:SendNotification("Buttons.OnButtonPress", {name = "CUSTOM_BUTTON", mode = "LONG", customButtonID = 3, appID = self.applications["Test Application"]})


					--hmi side: sending Navigation.ShowConstantTBT response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				end)

				--mobile side: expect ShowConstantTBT response
				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

				--mobile side: notifications are sent to mobile app
				EXPECT_NOTIFICATION("OnButtonEvent",{ customButtonID = 3, buttonEventMode = "BUTTONDOWN", buttonName = "CUSTOM_BUTTON"},
								    { customButtonID = 3, buttonEventMode = "BUTTONUP", buttonName = "CUSTOM_BUTTON"})
				:Times(2)

				EXPECT_NOTIFICATION("OnButtonPress",{ customButtonID = 3, buttonPressMode = "LONG", buttonName = "CUSTOM_BUTTON"})
				:Times(1)

			end


      --End Test case SequenceCheck.4
   -------------------------------------------------------------------------------------------

 --Begin Test case SequenceCheck.5
	--Description: Check test case TC_SoftButtons_01(SDLAQ-TC-68)

		--Requirement id in JAMA: SDLAQ-CRS-200

		--Verification criteria: Checking TEXT soft button reflecting on UI only if text is defined

 			     function Test:SCT_TEXTSoftButtonsAndTextWithWhiteSpaces()
				local RequestParams = {
											navigationText1 = "NavigationText",
											softButtons =
											{

                                                                                                 {
													systemAction = "DEFAULT_ACTION",
													type = "TEXT",
                                                                                                        text = " ",
													isHighlighted = false,
													image =
													{
													   imageType = "DYNAMIC",
													   value = "action.png"
													},
													softButtonID = 1
												}
											}
										}
				--mobile side: sending ShowConstantTBT request
				local cid = self.mobileSession:SendRPC("ShowConstantTBT", RequestParams)

				-- TODO: remove after resolving APPLINK-16052
				RequestParams.image = nil

				UIParams = self:createUIParameters(RequestParams)

				--hmi side: expect Navigation.ShowConstantTBT request
				EXPECT_HMICALL("Navigation.ShowConstantTBT", UIParams)
				:Times(0)

				--mobile side: expect ShowConstantTBT response
				EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })


			end


       --End Test case SequenceCheck.5
	-----------------------------------------------------------------------------------------

 	--Begin Test case SequenceCheck.6
	--Description: Check test case TC_SoftButtons_02(SDLAQ-TC-75)
	--Info: This TC will be failing till resolving APPLINK-16052

		--Requirement id in JAMA: SDLAQ-CRS-869

		--Verification criteria: Checking short click on IMAGE soft button


 		function Test:SCT_IMAGESoftButtons_ShortClick()
				local RequestParams = {
											navigationText1 = "NavigationText",
											softButtons =
											{
												{
													systemAction = "KEEP_CONTEXT",
													type = "IMAGE",
													isHighlighted = true,
													image =
													{
													   imageType = "DYNAMIC",
													   value = "icon.png"
													},
													softButtonID = 1
												},
                                                                                             {
													systemAction = "DEFAULT_ACTION",
													type = "IMAGE",
													isHighlighted = true,
													text = "Second",
													image =
													{
													   imageType = "DYNAMIC",
													   value = "action.png"
													},
													softButtonID = 2
												}
											}
										}
				--mobile side: sending ShowConstantTBT request
				local cid = self.mobileSession:SendRPC("ShowConstantTBT", RequestParams)

				UIParams = self:createUIParameters(RequestParams)

				--hmi side: expect Navigation.ShowConstantTBT request
				EXPECT_HMICALL("Navigation.ShowConstantTBT", UIParams)
				:Do(function(_,data)

					--hmi side: send request to short click on "Action.png" softButton
					self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONDOWN", customButtonID = 2, appID = self.applications["Test Application"]})
					self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONUP", customButtonID = 2, appID = self.applications["Test Application"]})
					self.hmiConnection:SendNotification("Buttons.OnButtonPress", {name = "CUSTOM_BUTTON", mode = "SHORT", customButtonID = 2, appID = self.applications["Test Application"]})


					--hmi side: sending Navigation.ShowConstantTBT response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				end)

				--mobile side: expect ShowConstantTBT response
				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

				--mobile side: notifications are sent to mobile app
				EXPECT_NOTIFICATION("OnButtonEvent",{ customButtonID = 2, buttonEventMode = "BUTTONDOWN", buttonName = "CUSTOM_BUTTON"},
								    { customButtonID = 2, buttonEventMode = "BUTTONUP", buttonName = "CUSTOM_BUTTON"})
				:Times(2)

				EXPECT_NOTIFICATION("OnButtonPress",{ customButtonID = 2, buttonPressMode = "SHORT", buttonName = "CUSTOM_BUTTON"})
				:Times(1)

			end


  	 --End Test case SequenceCheck.6
	-----------------------------------------------------------------------------------------

	--Begin Test case SequenceCheck.7
	--Description: Check test case TC_SoftButtons_02(SDLAQ-TC-75)
	--Info: This TC will be failing till resolving APPLINK-16052

		--Requirement id in JAMA: SDLAQ-CRS-200

		--Verification criteria: Checking IMAGE soft button reflecting on UI only if image is defined

		function Test:SCT_IMAGESoftButtonsAndImageNotExist()
				local RequestParams = {
											navigationText1 = "NavigationText",
											softButtons =
											{

                                                                                                 {
													systemAction = "KEEP_CONTEXT",
													type = "IMAGE",
                                                                                                        text = "First",
													isHighlighted = false,
													softButtonID = 1
												},
												{
													systemAction = "KEEP_CONTEXT",
													type = "IMAGE",
													isHighlighted = true,
													image =
													{
													   imageType = "DYNAMIC",
													   value = "aaa"                    --such image doesn't exist
													},
													softButtonID = 1
												},
											}
										}
				--mobile side: sending ShowConstantTBT request
				local cid = self.mobileSession:SendRPC("ShowConstantTBT", RequestParams)

				UIParams = self:createUIParameters(RequestParams)

				--hmi side: expect Navigation.ShowConstantTBT request
				EXPECT_HMICALL("Navigation.ShowConstantTBT", UIParams)
				:Times(0)

				--mobile side: expect ShowConstantTBT response
				EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })


			end


         --End Test case SequenceCheck.7
       ----------------------------------------------------------------------------------------------

	--Begin Test case SequenceCheck.8
	--Description: Check test case TC_SoftButtons_02(SDLAQ-TC-75)
	--Info: This TC will be failing till resolving APPLINK-16052

		--Requirement id in JAMA: SDLAQ-CRS-870

		--Verification criteria: Checking long click on IMAGE soft button

 		function Test:SCT_IMAGESoftButtons_LongClick()
				local RequestParams = {
											navigationText1 = "NavigationText",
											softButtons =
											{
												{
													systemAction = "KEEP_CONTEXT",
													type = "IMAGE",
													isHighlighted = true,
													image =
													{
													   imageType = "DYNAMIC",
													   value = "icon.png"
													},
													softButtonID = 1
												},
                                                                                             {
													systemAction = "DEFAULT_ACTION",
													type = "IMAGE",
													isHighlighted = false,
													image =
													{
													   imageType = "DYNAMIC",
													   value = "action.png"
													},
													softButtonID = 2
												}
											}
										}
				--mobile side: sending ShowConstantTBT request
				local cid = self.mobileSession:SendRPC("ShowConstantTBT", RequestParams)

				UIParams = self:createUIParameters(RequestParams)

				--hmi side: expect Navigation.ShowConstantTBT request
				EXPECT_HMICALL("Navigation.ShowConstantTBT", UIParams)
				:Do(function(_,data)

					--hmi side: send request to long click on "Action.png" softButton
					self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONDOWN", customButtonID = 2, appID = self.applications["Test Application"]})
					self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONUP", customButtonID = 2, appID = self.applications["Test Application"]})
					self.hmiConnection:SendNotification("Buttons.OnButtonPress", {name = "CUSTOM_BUTTON", mode = "LONG", customButtonID = 2, appID = self.applications["Test Application"]})


					--hmi side: sending Navigation.ShowConstantTBT response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				end)

				--mobile side: expect ShowConstantTBT response
				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

				--mobile side: notifications are sent to mobile app
				EXPECT_NOTIFICATION("OnButtonEvent",{ customButtonID = 2, buttonEventMode = "BUTTONDOWN", buttonName = "CUSTOM_BUTTON"},
								    { customButtonID = 2, buttonEventMode = "BUTTONUP", buttonName = "CUSTOM_BUTTON"})
				:Times(2)

				EXPECT_NOTIFICATION("OnButtonPress",{ customButtonID = 2, buttonPressMode = "LONG", buttonName = "CUSTOM_BUTTON"})
				:Times(1)

			end



         --End Test case SequenceCheck.8

	-----------------------------------------------------------------------------------------
	--Begin Test case SequenceCheck.9
	--Description: Check test case TC_SoftButtons_03(SDLAQ-TC-156)
	--Info: This TC will be failing till resolving APPLINK-16052

		--Requirement id in JAMA: SDLAQ-CRS-869

		--Verification criteria: Checking short click on BOTH soft button

 		function Test:SCT_BOTHSoftButtons_ShortClick()
				local RequestParams = {
											navigationText1 = "NavigationText",
											softButtons =
											{
												{
													systemAction = "DEFAULT_ACTION",
													type = "BOTH",
													isHighlighted = false,
													text = "First",
													image =
													{
													   imageType = "DYNAMIC",
													   value = "icon.png"
													},
													softButtonID = 1
												},
                                                                                                {
													systemAction = "KEEP_CONTEXT",
													type = "BOTH",
													text = "Second",
													isHighlighted = true,
													image =
													{
													   imageType = "DYNAMIC",
													   value = "icon.png"
													},
													softButtonID = 2
												},
                                                                                                 {
													systemAction = "DEFAULT_ACTION",
													type = "BOTH",
                                                                                                        text = "Third",
													isHighlighted = true,
													image =
													{
													   imageType = "DYNAMIC",
													   value = "action.png"
													},
													softButtonID = 3
												}
											}
										}
				--mobile side: sending ShowConstantTBT request
				local cid = self.mobileSession:SendRPC("ShowConstantTBT", RequestParams)

				UIParams = self:createUIParameters(RequestParams)

				--hmi side: expect Navigation.ShowConstantTBT request
				EXPECT_HMICALL("Navigation.ShowConstantTBT", UIParams)
				:Do(function(_,data)

					--hmi side: send request to short click on "Action.png" softButton
					self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONDOWN", customButtonID = 3, appID = self.applications["Test Application"]})
					self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONUP", customButtonID = 3, appID = self.applications["Test Application"]})
					self.hmiConnection:SendNotification("Buttons.OnButtonPress", {name = "CUSTOM_BUTTON", mode = "SHORT", customButtonID = 3, appID = self.applications["Test Application"]})


					--hmi side: sending Navigation.ShowConstantTBT response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				end)

				--mobile side: expect ShowConstantTBT response
				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

				--mobile side: notifications are sent to mobile app
				EXPECT_NOTIFICATION("OnButtonEvent",{ customButtonID = 3, buttonEventMode = "BUTTONDOWN", buttonName = "CUSTOM_BUTTON"},
								    { customButtonID = 3, buttonEventMode = "BUTTONUP", buttonName = "CUSTOM_BUTTON"})
				:Times(2)

				EXPECT_NOTIFICATION("OnButtonPress",{ customButtonID = 3, buttonPressMode = "SHORT", buttonName = "CUSTOM_BUTTON"})
				:Times(1)

			end

	 --End Test case SequenceCheck.9
	-----------------------------------------------------------------------------------------

	--Begin Test case SequenceCheck.10
	--Description: Check test case TC_SoftButtons_03(SDLAQ-TC-156)

		--Requirement id in JAMA: SDLAQ-CRS-200

		--Verification criteria: Checking BOTH soft button reflecting on UI only if image and text are defined

			function Test:SCT_BOTHSoftButtonsAndTextEmpty()
				local RequestParams = {
											navigationText1 = "NavigationText",
											softButtons =
											{

												{
													systemAction = "DEFAULT_ACTION",
													type = "BOTH",
													isHighlighted = false,
													text = "",
													image =
													{
													   imageType = "DYNAMIC",
													   value = "icon.png"
													},
													softButtonID = 1
												},
											}
										}
				--mobile side: sending ShowConstantTBT request
				local cid = self.mobileSession:SendRPC("ShowConstantTBT", RequestParams)

				UIParams = self:createUIParameters(RequestParams)

				--hmi side: expect Navigation.ShowConstantTBT request
				EXPECT_HMICALL("Navigation.ShowConstantTBT", UIParams)
				:Times(0)

				--mobile side: expect ShowConstantTBT response
				EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })


			end

	 --End Test case SequenceCheck.10
       ----------------------------------------------------------------------------------------------

	--Begin Test case SequenceCheck.11
	--Description: Check test case TC_SoftButtons_03(SDLAQ-TC-156)
	--Info: This TC will be failing till resolving APPLINK-16052

		--Requirement id in JAMA: SDLAQ-CRS-2912

		--Verification criteria: Check that On.ButtonEvent(CUSTOM_BUTTON) notification is not transferred from HMI to mobile app by SDL if CUSTOM_BUTTON is not subscribed


         function Test:UnsubscribeButton_CUSTOM_BUTTON_SUCCESS()

		--mobile side: send UnsubscribeButton request
		local cid = self.mobileSession:SendRPC("UnsubscribeButton",
			{
				buttonName = "CUSTOM_BUTTON"
			})

			--hmi side: expect OnButtonSubscription notification
			EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription", {name = "CUSTOM_BUTTON", isSubscribed = false})
			:Timeout(5000)

			-- Mobile side: expects SubscribeButton response
			-- Mobile side: expects EXPECT_NOTIFICATION("OnHashChange") if SUCCESS
			EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
	                --:Timeout(13000)

	end

		function Test:SCT_BOTHSoftButtons_AfterUnsubscribe()
				local RequestParams = {
											navigationText1 = "NavigationText",
											softButtons =
											{
												{
													systemAction = "DEFAULT_ACTION",
													type = "BOTH",
													isHighlighted = true,
													text = "First",
													image =
													{
													   imageType = "DYNAMIC",
													   value = "action.png"
													},
													softButtonID = 1
												}
											}
										}
				--mobile side: sending ShowConstantTBT request
				local cid = self.mobileSession:SendRPC("ShowConstantTBT", RequestParams)

				UIParams = self:createUIParameters(RequestParams)

				--hmi side: expect Navigation.ShowConstantTBT request
				EXPECT_HMICALL("Navigation.ShowConstantTBT", UIParams)
				:Do(function(_,data)

					--hmi side: send request to short click on "First" softButton
					self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONDOWN", customButtonID = 1, appID = self.applications["Test Application"]})
					self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONUP", customButtonID = 1, appID = self.applications["Test Application"]})
					self.hmiConnection:SendNotification("Buttons.OnButtonPress", {name = "CUSTOM_BUTTON", mode = "SHORT", customButtonID = 1, appID = self.applications["Test Application"]})


					--hmi side: sending Navigation.ShowConstantTBT response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				end)

				--mobile side: expect ShowConstantTBT response
				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

				--mobile side: notifications are sent to mobile app
				EXPECT_NOTIFICATION("OnButtonEvent",{ customButtonID = 1, buttonEventMode = "BUTTONDOWN", buttonName = "CUSTOM_BUTTON"},
								    { customButtonID = 1, buttonEventMode = "BUTTONUP", buttonName = "CUSTOM_BUTTON"})
				:Times(0)

				EXPECT_NOTIFICATION("OnButtonPress",{ customButtonID = 1, buttonPressMode = "SHORT", buttonName = "CUSTOM_BUTTON"})
				:Times(0)

			end

 	--End Test case SequenceCheck.11

       ----------------------------------------------------------------------------------------------

	--Begin Test case SequenceCheck.12
	--Description: Check test case TC_SoftButtons_03(SDLAQ-TC-156)

		--Requirement id in JAMA: SDLAQ-CRS-200

		--Verification criteria: Checking BOTH soft button reflecting on UI only if image and text are defined


			function Test:SCT_BOTHSoftButtonsAndNoImage()
				local RequestParams = {
											navigationText1 = "NavigationText",
											softButtons =
											{

												{
													systemAction = "DEFAULT_ACTION",
													type = "BOTH",
													isHighlighted = false,
													text = "First",
													softButtonID = 1
												},
											}
										}
				--mobile side: sending ShowConstantTBT request
				local cid = self.mobileSession:SendRPC("ShowConstantTBT", RequestParams)

				UIParams = self:createUIParameters(RequestParams)

				--hmi side: expect Navigation.ShowConstantTBT request
				EXPECT_HMICALL("Navigation.ShowConstantTBT", UIParams)
				:Times(0)

				--mobile side: expect ShowConstantTBT response
				EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })


			end


        --End Test case SequenceCheck.12

-----------------------------------------------------------------------------------------------

        --Begin Test case SequenceCheck.13
	--Description: Check test case TC_SoftButtons_04(SDLAQ-TC-157)
	--Info: This TC will be failing till resolving APPLINK-16052

		--Requirement id in JAMA: SDLAQ-CRS-870

		--Verification criteria: Checking long click on BOTH soft button

		function Test:SCT_BOTHSoftButtons_LongClick()

				local RequestParams = {
											navigationText1 = "NavigationText",
											softButtons =
											{
												{
													type = "BOTH",
													isHighlighted = true,
													text = "First",
													image =
													{
													   imageType = "DYNAMIC",
													   value = "icon.png"
													},
													softButtonID = 1
												}
											}
										}
				--mobile side: sending ShowConstantTBT request
				local cid = self.mobileSession:SendRPC("ShowConstantTBT", RequestParams)

				UIParams = self:createUIParameters(RequestParams)

				--hmi side: expect Navigation.ShowConstantTBT request
				EXPECT_HMICALL("Navigation.ShowConstantTBT", UIParams)
				:Do(function(_,data)

					--hmi side: send request to long click on "First" softButton
					self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONDOWN", customButtonID = 1, appID = self.applications["Test Application"]})
					self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONUP", customButtonID = 1, appID = self.applications["Test Application"]})
					self.hmiConnection:SendNotification("Buttons.OnButtonPress", {name = "CUSTOM_BUTTON", mode = "LONG", customButtonID = 1, appID = self.applications["Test Application"]})


					--hmi side: sending Navigation.ShowConstantTBT response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				end)

				--mobile side: expect ShowConstantTBT response
				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

				--mobile side: notifications are sent to mobile app
				EXPECT_NOTIFICATION("OnButtonEvent",{ customButtonID = 1, buttonEventMode = "BUTTONDOWN", buttonName = "CUSTOM_BUTTON"},
								    { customButtonID = 1, buttonEventMode = "BUTTONUP", buttonName = "CUSTOM_BUTTON"})
				:Times(2)

				EXPECT_NOTIFICATION("OnButtonPress",{ customButtonID = 1, buttonPressMode = "LONG", buttonName = "CUSTOM_BUTTON"})
				:Times(1)

			end

        --End Test case SequenceCheck.13


	--Begin Test case SequenceCheck.14
	--Description: Check test case TC_SoftButtons_01(SDLAQ-TC-68)

		--Requirement id in JAMA: SDLAQ-CRS-200

		--Verification criteria: Checking TEXT soft button reflecting on UI only if text is defined

 			     function Test:SCT_TEXTSoftButtonsAndTextEmpty()
				local RequestParams = {
											navigationText1 = "NavigationText",
											softButtons =
											{

                                                                                                 {
													systemAction = "DEFAULT_ACTION",
													type = "TEXT",
                                                                                                        text = "",
													isHighlighted = false,
													image =
													{
													   imageType = "DYNAMIC",
													   value = "action.png"
													},
													softButtonID = 1
												}
											}
										}
				--mobile side: sending ShowConstantTBT request
				local cid = self.mobileSession:SendRPC("ShowConstantTBT", RequestParams)

				-- TODO: remove after resolving APPLINK-16052
				RequestParams.image = nil

				UIParams = self:createUIParameters(RequestParams)

				--hmi side: expect Navigation.ShowConstantTBT request
				EXPECT_HMICALL("Navigation.ShowConstantTBT", UIParams)
				:Times(0)

				--mobile side: expect ShowConstantTBT response
				EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })


			end


       --End Test case SequenceCheck.14

	-----------------------------------------------------------------------------------------

	--Begin Test case SequenceCheck.15
	--Description: Check test case TC_SoftButtons_02(SDLAQ-TC-75)
	--Info: This TC will be failing till resolving APPLINK-16052

		--Requirement id in JAMA: SDLAQ-CRS-200

		--Verification criteria: Checking IMAGE soft button reflecting on UI only if image is defined

		function Test:SCT_IMAGESoftButtonsAndImageNotDefined()
				local RequestParams = {
											navigationText1 = "NavigationText",
											softButtons =
											{
												{
													systemAction = "KEEP_CONTEXT",
													type = "IMAGE",
													isHighlighted = true,
													softButtonID = 1
												},
											}
										}
				--mobile side: sending ShowConstantTBT request
				local cid = self.mobileSession:SendRPC("ShowConstantTBT", RequestParams)

				UIParams = self:createUIParameters(RequestParams)

				--hmi side: expect Navigation.ShowConstantTBT request
				EXPECT_HMICALL("Navigation.ShowConstantTBT", UIParams)
				:Times(0)

				--mobile side: expect ShowConstantTBT response
				EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })


			end

         --End Test case SequenceCheck.15

        --Begin Test case SequenceCheck.16
	--Description: Check test case TC_SoftButtons_03(SDLAQ-TC-156)

		--Requirement id in JAMA: SDLAQ-CRS-200

		--Verification criteria: Checking BOTH soft button reflecting on UI only if image and text are defined


			function Test:SCT_BOTHSoftButtonTextNotDefined()
				local RequestParams = {
											navigationText1 = "NavigationText",
											softButtons =
											{

												{
													systemAction = "DEFAULT_ACTION",
													type = "BOTH",
													isHighlighted = false,
													image =
													{
													   imageType = "DYNAMIC",
													   value = "action.png"
													},
													softButtonID = 1
												},
											}
										}
				--mobile side: sending ShowConstantTBT request
				local cid = self.mobileSession:SendRPC("ShowConstantTBT", RequestParams)

				UIParams = self:createUIParameters(RequestParams)

				--hmi side: expect Navigation.ShowConstantTBT request
				EXPECT_HMICALL("Navigation.ShowConstantTBT", UIParams)
				:Times(0)

				--mobile side: expect ShowConstantTBT response
				EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })


			end

        --End Test case SequenceCheck.16


	--Begin Test case SequenceCheck.17
	--Description: Check test case TC_SoftButtons_03(SDLAQ-TC-156)

		--Requirement id in JAMA: SDLAQ-CRS-200

		--Verification criteria: Checking BOTH soft button reflecting on UI only if image and text are defined


			function Test:SCT_BOTHSoftButtonImageAndTextNotDefined()
				local RequestParams = {
											navigationText1 = "NavigationText",
											softButtons =
											{

												{
													systemAction = "DEFAULT_ACTION",
													type = "BOTH",
													isHighlighted = false,
													softButtonID = 1
												},
											}
										}
				--mobile side: sending ShowConstantTBT request
				local cid = self.mobileSession:SendRPC("ShowConstantTBT", RequestParams)

				UIParams = self:createUIParameters(RequestParams)

				--hmi side: expect Navigation.ShowConstantTBT request
				EXPECT_HMICALL("Navigation.ShowConstantTBT", UIParams)
				:Times(0)

				--mobile side: expect ShowConstantTBT response
				EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })


			end

        --End Test case SequenceCheck.17

SequenceChecks()


----------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK VII---------------------------------------
--------------------------------------Different HMIStatus-------------------------------------
----------------------------------------------------------------------------------------------

--Description: Check different HMIStatus

--Requirement id in JAMA:
	--SDLAQ-CRS-805: HMI Status Requirement for ShowConstantTBT
	--Verification criteria: ShowConstantTBT request is allowed in FULL, LIMITED, BACKGROUND HMI level

local function DifferentHMIlevelChecks()

	--Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup("NewTestCasesGroupForSequenceChecks")
	-----------------------------------------------------------------------------------------

	--Begin Test case DifferentHMIlevelChecks.1
	--Description: Check request is disallowed in NONE HMI level
		commonSteps:DeactivateAppToNoneHmiLevel()

		function Test:ShowConstantTBT_HMIStatus_NONE()

			--mobile side: sending the request
			local RequestParams = createRequest()
			local cid = self.mobileSession:SendRPC("ShowConstantTBT", RequestParams)

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
		appHMITypes["NAVIGATION"] == true then

			--Precondition: Deactivate app to LIMITED HMI level
			commonSteps:ChangeHMIToLimited(self)

			function Test:ShowConstantTBT_HMIStatus_LIMITED()
				local RequestParams = createRequest()
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
				appId2 = data.params.application.appID
			end)

			--mobile side: RegisterAppInterface response
			self.mobileSession2:ExpectResponse(CorIdRAI, { success = true, resultCode = "SUCCESS"})
				:Timeout(2000)

			self.mobileSession2:ExpectNotification("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
		end

		-- Precondition 3: Activate an other media app to change app to BACKGROUND
		function Test:Activate_Media_App2()
			--HMI send ActivateApp request
			local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = appId2})
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
	function Test:ShowConstantTBT_HMIStatus_BACKGOUND()
		local RequestParams = createRequest()
		self:verify_SUCCESS_Case(RequestParams)
	end
	--End Test case DifferentHMIlevelChecks.4
end

DifferentHMIlevelChecks()

---------------------------------------------------------------------------------------------
-------------------------------------------Postcondition-------------------------------------
---------------------------------------------------------------------------------------------

	--Print new line to separate Postconditions
	commonFunctions:newTestCasesGroup("Postconditions")


	--Restore sdl_preloaded_pt.json
	policyTable:Restore_preloaded_pt()



 return Test
