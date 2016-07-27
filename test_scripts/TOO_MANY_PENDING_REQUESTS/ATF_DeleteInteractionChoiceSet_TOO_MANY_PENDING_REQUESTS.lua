Test = require('connecttest')
require('cardinalities')
local events = require('events')
local mobile_session = require('mobile_session')
local mobile  = require('mobile_connection')
local tcp = require('tcp_connection')
local file_connection  = require('file_connection')

---------------------------------------------------------------------------------------------
-----------------------------Required Shared Libraries---------------------------------------
---------------------------------------------------------------------------------------------
require('user_modules/AppTypes')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local policyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
---------------------------------------------------------------------------------------------

APIName = "DeleteInteractionChoiceSet" -- use for above required scripts.

local n=0
function DelayedExp()
	local event = events.Event()
	event.matches = function(self, e) return self == e end
		EXPECT_EVENT(event, "Delayed event")
		RUN_AFTER(function()
			RAISE_EVENT(event, event)
	end, 2000)
end
function setChoiseSet(startID, size)
	if (size ~= nil) then
		temp = {}
		for i = 1, size do
		temp[i] = {
				choiceID =startID+i-1,
				menuName ="Choice" .. startID+i-1,
				vrCommands =
				{
					"Choice" .. startID+i-1,
				},
				image =
				{
					value ="icon.png",
					imageType ="STATIC",
				},
		  }
		end
	else
		temp =  {{
					choiceID =startID,
					menuName ="Choice" .. startID,
					vrCommands =
					{
						"Choice" .. startID,
					},
					image =
					{
						value ="icon.png",
						imageType ="STATIC",
					},
		}}
	end
	return temp
end
function Test:createInteractionChoiceSet(choiceSetID)
	local choiceID
	if choiceSetID == 2000000000 then
		choiceID = 65535
	else
		choiceID = choiceSetID
	end
	--mobile side: sending CreateInteractionChoiceSet request
	local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
											{
												interactionChoiceSetID = choiceSetID,
												choiceSet = setChoiseSet(choiceID),
												})

	--hmi side: expect VR.AddCommand
	EXPECT_HMICALL("VR.AddCommand",{
									cmdID = choiceID,
									type = "Choice",
									vrCommands =
									{
										"Choice" .. tostring(choiceID),
									}
								})
	:Do(function(_,data)
		--hmi side: sending VR.AddCommand response
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
	end)

	--mobile side: expect CreateInteractionChoiceSet response
	EXPECT_RESPONSE(cid, { resultCode = "SUCCESS", success = true  })
end


---------------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------

	--Print new line to separate Preconditions
	commonFunctions:newTestCasesGroup("Preconditions")

	--1. Delete app_info.dat, logs and policy table
	commonSteps:DeleteLogsFileAndPolicyTable()

	--2. Backup smartDeviceLink.ini file
	commonPreconditions:BackupFile("smartDeviceLink.ini")

	--3. Update smartDeviceLink.ini file: PendingRequestsAmount = 3
	commonFunctions:SetValuesInIniFile_PendingRequestsAmount(3)

	--4. Activation App by sending SDL.ActivateApp
		commonSteps:ActivationApp()

	--5. PutFile
		function Test:PutFile()
			local cid = self.mobileSession:SendRPC("PutFile",
					{
						syncFileName = "icon.png",
						fileType	= "GRAPHIC_PNG",
						persistentFile = false,
						systemFile = false
					}, "files/icon.png")
					EXPECT_RESPONSE(cid, { success = true})
		end

	--5. Add 20 Choice set
		for i=1, 20 do
			Test["CreateInteractionChoiceSet" .. i] = function(self)
					self:createInteractionChoiceSet(i)
			end
		end

----------------------------------------------------------------------------------------------
----------------------------------------IV TEST BLOCK-----------------------------------------
---------------------------------------Result codes check-------------------------------------
----------------------------------------------------------------------------------------------

--Begin Test suit ResultCodeCheck

--Print new line to separate test suite
commonFunctions:newTestCasesGroup("Test suit For ResultCodeChecks")

--Description:TC check TOO_MANY_PENDING_REQUESTS resultCode

	--Requirement id in JAMA: SDLAQ-CRS-474

    --Verification criteria: The system has more than M (M defined in smartDeviceLink.ini) requests  at a timethat haven't been responded yet.

	function Test:DeleteInteractionChoiceSet_TooManyPendingRequests()
		local numberOfRequest = 10
		for i = 1, numberOfRequest do
			--mobile side: send DeleteInteractionChoiceSet request
			self.mobileSession:SendRPC("DeleteInteractionChoiceSet",
			{
				interactionChoiceSetID = i
			})
		end

		EXPECT_RESPONSE("DeleteInteractionChoiceSet")
		:ValidIf(function(exp,data)
      	if
      		data.payload.resultCode == "TOO_MANY_PENDING_REQUESTS" then
            n = n+1
				print("DeleteInteractionChoiceSet response came with resultCode TOO_MANY_PENDING_REQUESTS")
				return true
        elseif
			exp.occurences == numberOfRequest and n == 0 then
			print("Response DeleteInteractionChoiceSet with resultCode TOO_MANY_PENDING_REQUESTS did not came")
			return false
        elseif
			data.payload.resultCode == "SUCCESS" then
				print("DeleteInteractionChoiceSet response came with resultCode SUCCESS")
            return true
        else
				print("DeleteInteractionChoiceSet response came with resultCode "..tostring(data.payload.resultCode))
            return false
        end
      end)
      :Times(AtLeast(numberOfRequest))

		--expect absence of OnAppInterfaceUnregistered
		EXPECT_NOTIFICATION("OnAppInterfaceUnregistered")
		:Times(0)

		--expect absence of BasicCommunication.OnAppUnregistered
		EXPECT_HMICALL("BasicCommunication.OnAppUnregistered")
		:Times(0)

		DelayedExp()
	end
--End Test suit ResultCodeCheck

---------------------------------------------------------------------------------------------
-------------------------------------------Postcondition-------------------------------------
---------------------------------------------------------------------------------------------

	--Print new line to separate Postconditions
	commonFunctions:newTestCasesGroup("Postconditions")


	--Restore sdl_preloaded_pt.json
	policyTable:Restore_preloaded_pt()



 return Test















