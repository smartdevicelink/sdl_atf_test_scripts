---------------------------------------------------------------------------------------------
--ATF version: 2.2
--Last modified date: 25/Oct/2015
--Author: Ta Thanh Dong
---------------------------------------------------------------------------------------------
Test = require('connecttest')
require('cardinalities')
local events = require('events')
local mobile_session = require('mobile_session')

--ToDo: Remove below line when heartbeat function work well on protocol 3.
config.defaultProtocolVersion = 2 -- to avoid error with heartbeat function

---------------------------------------------------------------------------------------------
-----------------------------Required Shared Libraries---------------------------------------
---------------------------------------------------------------------------------------------
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
require('user_modules/AppTypes')

APIName = "OnTouchEvent" -- set API name

Apps = {}
Apps[1] = {}
Apps[2] = {}

function DelayedExp(time)
  local event = events.Event()
  event.matches = function(self, e) return self == e end
  EXPECT_EVENT(event, "Delayed event")
  	:Timeout(time+1000)
  RUN_AFTER(function()
              RAISE_EVENT(event, event)
            end, time)
end

local function OnTouchEvent_Notification_IsIgnored(TestCaseName)
	Test[TestCaseName]  = function(self)
	
		DelayedExp(2000)
		local parameter = {
						type = "BEGIN", 
						event = { {c = {{x = 1, y = 1}}, id = 0, ts = {900} } }
					}
					
		--hmi side: send OnTouchEvent
		self.hmiConnection:SendNotification("UI.OnTouchEvent",	parameter)

		--mobile side: expected OnTouchEvent notification
		--EXPECT_NOTIFICATION("OnTouchEvent", parameter)
		EXPECT_NOTIFICATION("OnTouchEvent", {})
		:Times(0)
	end
end
			
---------------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------

	commonSteps:DeleteLogsFileAndPolicyTable()


	--Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup("Preconditions")
	
		
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
		
		data.policy_table.functional_groupings.OnTouchEventGroup = {}
		data.policy_table.functional_groupings.OnTouchEventGroup.rpcs = {}
		data.policy_table.functional_groupings.OnTouchEventGroup.rpcs.OnTouchEvent = {}
		data.policy_table.functional_groupings.OnTouchEventGroup.rpcs.OnTouchEvent.hmi_levels = {'FULL'}

		data.policy_table.app_policies.default.groups = {"Base-4", "OnTouchEventGroup"}
		
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
		config.application1.registerAppInterfaceParams.appHMIType = {'NAVIGATION'}
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

	--1. Activate application
		--Begin Precondition.1
		--Description: Activation application		
			function Test:ActivationApp()			
				--hmi side: sending SDL.ActivateApp request
				-- local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["Test Application"]})
				local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = GlobalVarAppID})
				EXPECT_HMIRESPONSE(RequestId)	
				
				--mobile side: expect notification
				EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"}) 
			end
		--End Precondition.1

	--2. Create PT that allowed OnTouchEvent in Base-4 group and update PT
	local PermissionLines_OnTouchEvent = 
[[					"OnTouchEvent": {
						"hmi_levels": [
						  "BACKGROUND",
						  "LIMITED",
						  "NONE",
						  "FULL"
						]
					  }]] .. ", \n"



	local PermissionLinesForBase4 = PermissionLines_OnTouchEvent 
	local PermissionLinesForGroup1 = nil
	local PermissionLinesForApplication = nil
	--TODO: PT is blocked by ATF defect APPLINK-19188
	--local PTName = testCasesForPolicyTable:createPolicyTableFile(PermissionLinesForBase4, PermissionLinesForGroup1, PermissionLinesForApplication)	
	--testCasesForPolicyTable:updatePolicy(PTName)
	-- PAY ATTENTION - now sdl_preloaded is used, may be this TODO is not required	
	
	
				
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
	--SDLAQ-N_CRS-5: OnTouchEvent
		--SDLAQ-N_CRS-155: TouchType
		--SDLAQ-N_CRS-149: TouchEvent 
			--SDLAQ-N_CRS-154: TouchCoord
	
--Verification criteria: 
	--1. Notifies about touch events on the screen's prescribed area

--TODO: Update this script according to answer on APPLINK-17560
----------------------------------------------------------------------------------------------

	--List of parameters:
	--1. type: type=TouchType(BEGIN, MOVE, END), mandatory=true
	--2. event: type=TouchEvent, mandatory="true" minsize="1" maxsize="10" array="true"
		--TouchEvent:
			--id: Integer, minvalue=0, maxvalue=9, mandatory=true
			--ts: Integer, mandatory=true, array=true, minvalue=0, maxvalue=2147483647 minsize=1, maxsize=1000
			--c: TouchCoord, mandatory=true, array=true, minsize=1, maxsize=1000
				--TouchCoord: 
					--x: Integer, minvalue=0, maxvalue=10000, mandatory=true
					--y: Integer, minvalue=0, maxvalue=10000, mandatory=true
----------------------------------------------------------------------------------------------

	local function TCs_verify_normal_cases()	
		
		--Print new line to separate new test cases group
		commonFunctions:newTestCasesGroup("Test suite: Check normal cases of HMI notification")

	----------------------------------------------------------------------------------------------
	--Parameter #1: Checks type parameter: type=TouchType(BEGIN, MOVE, END), mandatory=true
	----------------------------------------------------------------------------------------------
		local function TCs_verify_type_parameter()
		
			--Print new line to separate new test cases group
			commonFunctions:newTestCasesGroup("Test suite: Check type parameter")
			
			--1. IsInBoundValues
			local types = {"BEGIN", "MOVE", "END", "CANCEL"}
			for i = 1, #types  do
				Test["OnTouchEvent_type_" .. types[i]] = function(self)
				
				
					local parameter = {
									type = types[i], 
									event = { {c = {{x = 1, y = 1}}, id = 1, ts = {9908} } }
								}
								
					--hmi side: send OnTouchEvent
					self.hmiConnection:SendNotification("UI.OnTouchEvent",	parameter)

					--mobile side: expected OnTouchEvent notification
					EXPECT_NOTIFICATION("OnTouchEvent", parameter)
					
				end
			end
			
			
			--2. IsMissed
			--3. IsEmtpy
			--4. NonExist
			--5. WrongDataType
			local InvalidType = {	{value = nil, name = "IsMissed"},
									{value = "", name = "IsEmtpy"},
									{value = "ANY", name = "NonExist"},
									{value = 123, name = "WrongDataType"}}
			
			for i = 1, #InvalidType  do
				Test["OnTouchEvent_type_" .. InvalidType[i].name] = function(self)
				
					DelayedExp(2000)
					
					local parameter = {
									type = InvalidType[i].value, 
									event = { {c = {{x = 1, y = 1}}, id = 1, ts = {9908} } }
								}
					
					--hmi side: send OnTouchEvent
					self.hmiConnection:SendNotification("UI.OnTouchEvent", parameter)

					--mobile side: expected OnTouchEvent notification
					EXPECT_NOTIFICATION("OnTouchEvent")
					:Times(0)
				end
			end
			
		end
		
		TCs_verify_type_parameter()


		
	----------------------------------------------------------------------------------------------
	--Parameter #2: Checks event.c.x parameter: type=Integer, minvalue=0, maxvalue=10000, mandatory=true
	----------------------------------------------------------------------------------------------
		local function TCs_verify_event_c_x_parameter()

			--Print new line to separate new test cases group
			commonFunctions:newTestCasesGroup("Test suite: Check event.c.x parameter")
			
			--1. IsLowerBound
			--2. IsMiddle
			--3. IsUpperBound
			local ValidValues = {	{value = 0, name = "IsLowerBound"},
						{value = 5000, name = "IsMiddle"},
						{value = 10000, name = "IsUpperBound"}}
								
			for i = 1, #ValidValues  do
				Test["OnTouchEvent_event_c_x_" .. ValidValues[i].name] = function(self)
				
					local parameter = {
										type = "BEGIN", 
										event = { {c = {{x = ValidValues[i].value, y = 1}}, id = 1, ts = {9908} } }
									}
									
					--hmi side: send OnTouchEvent
					self.hmiConnection:SendNotification("UI.OnTouchEvent", parameter)

					--mobile side: expected OnTouchEvent notification
					EXPECT_NOTIFICATION("OnTouchEvent", parameter)
					
				end
			end
			
			
			--4. IsMissed
			--5. IsOutLowerBound
			--6. IsOutUpperBound
			--7. IsWrongType
			local InvalidValues = {	{value = nil, name = "IsMissed"},
									{value = -1, name = "IsOutLowerBound"},
									{value = 10001, name = "IsOutUpperBound"},
									{value = "2", name = "WrongDataType"}}
			
			for i = 1, #InvalidValues  do
				Test["OnTouchEvent_event_c_x_" .. InvalidValues[i].name] = function(self)
					DelayedExp(2000)
					local parameter = {
										type = "BEGIN", 
										event = { {c = {{x = InvalidValues[i].value, y = 1}}, id = 1, ts = {9908} } }
									}
									
					--hmi side: send OnTouchEvent
					self.hmiConnection:SendNotification("UI.OnTouchEvent", parameter)

					--mobile side: expected OnTouchEvent notification
					EXPECT_NOTIFICATION("OnTouchEvent")
					:Times(0)
				end
			end
			

		end

		TCs_verify_event_c_x_parameter()


		
	----------------------------------------------------------------------------------------------
	--Parameter #3: Checks event.c.y parameter: type=Integer, minvalue=0, maxvalue=10000, mandatory=true
	----------------------------------------------------------------------------------------------
		local function TCs_verify_event_c_y_parameter()

			--Print new line to separate new test cases group
			commonFunctions:newTestCasesGroup("Test suite: Check event.c.y parameter")
			
			--1. IsLowerBound
			--2. IsMiddle
			--3. IsUpperBound
			local ValidValues = {	{value = 0, name = "IsLowerBound"},
						{value = 5000, name = "IsMiddle"},
						{value = 10000, name = "IsUpperBound"}}
								
			for i = 1, #ValidValues  do
				Test["OnTouchEvent_event_c_y_" .. ValidValues[i].name] = function(self)
				
					local parameter = {
										type = "BEGIN", 
										event = { {c = {{x = 1, y = ValidValues[i].value}}, id = 1, ts = {9908} } }
									}
									
					--hmi side: send OnTouchEvent
					self.hmiConnection:SendNotification("UI.OnTouchEvent", parameter)

					--mobile side: expected OnTouchEvent notification
					EXPECT_NOTIFICATION("OnTouchEvent", parameter)
					
				end
			end
			
			
			--4. IsMissed
			--5. IsOutLowerBound
			--6. IsOutUpperBound
			--7. IsWrongType
			local InvalidValues = {	{value = nil, name = "IsMissed"},
									{value = -1, name = "IsOutLowerBound"},
									{value = 10001, name = "IsOutUpperBound"},
									{value = "2", name = "WrongDataType"}}
			
			for i = 1, #InvalidValues  do
				Test["OnTouchEvent_event_c_y_" .. InvalidValues[i].name] = function(self)
					DelayedExp(2000)
					local parameter = {
										type = "BEGIN", 
										event = { {c = {{x = 1, y = InvalidValues[i].value}}, id = 1, ts = {9908} } }
									}
									
					--hmi side: send OnTouchEvent
					self.hmiConnection:SendNotification("UI.OnTouchEvent", parameter)

					--mobile side: expected OnTouchEvent notification
					EXPECT_NOTIFICATION("OnTouchEvent")
					:Times(0)
				end
			end
			
		end

		TCs_verify_event_c_y_parameter()


		
	----------------------------------------------------------------------------------------------
	--Parameter #4 Checks event.c parameter: type=TouchCoord, mandatory=true, array=true, minsize=1, maxsize=1000
	----------------------------------------------------------------------------------------------
		local function TCs_verify_event_c_parameter()

			--Print new line to separate new test cases group
			commonFunctions:newTestCasesGroup("Test suite: Check event.c parameter")
			
			--1. IsLowerBound
			--2. IsUpperBound

			--Create array 1000 items.
			local c_upperbound = {}
			for i = 1, 1000 do
				table.insert(c_upperbound, {x = i, y = 1})
			end


			local ValidValues = {
						{name = "IsLowerBound", value = {{x = 1, y = 1}}},
						{name = "IsUpperBound", value = c_upperbound}}
								
			for i = 1, #ValidValues  do
				Test["OnTouchEvent_event_c_" .. ValidValues[i].name] = function(self)
				
					local parameter = {
										type = "BEGIN", 
										event = { {c = ValidValues[i].value, id = 1, ts = {9908} } }
									}
									
					--hmi side: send OnTouchEvent
					self.hmiConnection:SendNotification("UI.OnTouchEvent", parameter)

					--mobile side: expected OnTouchEvent notification
					EXPECT_NOTIFICATION("OnTouchEvent", parameter)
					
				end
			end
			
			

			--3. IsMissed
			--4. IsOutLowerBound
			--5. IsOutUpperBound
			--6. IsWrongType
			
			--Create array 1001 items
			local c_outupperbound = {}
			for i = 1, 1001 do
				table.insert(c_outupperbound, {x = i, y = 1})
			end
			
			local InvalidValues = {	{name = "IsMissed", value = nil},
									{name = "IsOutLowerBound", value = {}},
									{name = "IsOutUpperBound", value = c_outupperbound},
									{name = "WrongDataType", value = 123}}
			
			for i = 1, #InvalidValues  do
				Test["OnTouchEvent_event_c_" .. InvalidValues[i].name] = function(self)
					DelayedExp(2000)
					local parameter = {
										type = "BEGIN", 
										event = { {c = InvalidValues[i].value, id = 1, ts = {9908} } }
									}
									
					--hmi side: send OnTouchEvent
					self.hmiConnection:SendNotification("UI.OnTouchEvent", parameter)

					--mobile side: expected OnTouchEvent notification
					EXPECT_NOTIFICATION("OnTouchEvent")
					:Times(0)
				end
			end
			
		end

		TCs_verify_event_c_parameter()


		
	----------------------------------------------------------------------------------------------
	--Parameter #5: Checks event.ts parameter: type=Integer, mandatory=true, array=true, minvalue=0, maxvalue=2147483647 minsize=1, maxsize=1000
	----------------------------------------------------------------------------------------------
		local function TCs_verify_event_ts_parameter()

			--Print new line to separate new test cases group
			commonFunctions:newTestCasesGroup("Test suite: Check event.ts element parameter")
			
			--1. IsLowerBound
			--2. IsMiddle
			--2. IsUpperBound

			local ValidValues = {
						{name = "IsLowerBound", value = 0},
						{name = "IsMiddle", value = 1147483647},
						{name = "IsUpperBound", value = 2147483647}}
								
			for i = 1, #ValidValues  do
				Test["OnTouchEvent_event_ts_" .. ValidValues[i].name] = function(self)
				
					local parameter = {
										type = "BEGIN", 
										event = { {c = {{x = 1, y = 1}}, id = 1, ts = {ValidValues[i].value} } }
									}
									
					--hmi side: send OnTouchEvent
					self.hmiConnection:SendNotification("UI.OnTouchEvent", parameter)

					--mobile side: expected OnTouchEvent notification
					EXPECT_NOTIFICATION("OnTouchEvent", parameter)
					
				end
			end
			
			

			--4. IsMissed
			--5. IsOutLowerBound
			--6. IsOutUpperBound
			--7. IsWrongType
			
			local InvalidValues = {	{name = "IsMissed", value = nil},
									{name = "IsOutLowerBound", value = -1},
									{name = "IsOutUpperBound", value = 2147483648},
									{name = "WrongDataType", value = "123"}}
			
			for i = 1, #InvalidValues  do
				Test["OnTouchEvent_event_ts_" .. InvalidValues[i].name] = function(self)
					DelayedExp(2000)
					local parameter = {
										type = "BEGIN", 
										event = { {c = {{x = 1, y = 1}}, id = 1, ts = {InvalidValues[i].value} } }
									}
									
					--hmi side: send OnTouchEvent
					self.hmiConnection:SendNotification("UI.OnTouchEvent", parameter)

					--mobile side: expected OnTouchEvent notification
					EXPECT_NOTIFICATION("OnTouchEvent")
					:Times(0)
				end
			end
			
			

			--Print new line to separate new test cases group
			commonFunctions:newTestCasesGroup("Test suite: Check event.ts array parameter")

			
			--1. IsLowerBound: covered by above TCs OnTouchEvent_event_ts_IsLowerBound/IsMiddle/IsUpperBound
			--2. IsUpperBound

			--Create array 1000 items.
			local ts_upperbound = {}
			for i = 1, 1000 do
				table.insert(ts_upperbound, i)
			end


			local ValidValues = {
						--{name = "IsLowerBound", value = {1}}, --1. IsLowerBound: covered by above TCs OnTouchEvent_event_ts_IsLowerBound/IsMiddle/IsUpperBound
						{name = "IsUpperBound", value = ts_upperbound}}
								
			for i = 1, #ValidValues  do
				Test["OnTouchEvent_event_ts_array_" .. ValidValues[i].name] = function(self)
				
					local parameter = {
										type = "BEGIN", 
										event = { {c = {{x =1, y = 1}}, id = 1, ts = ValidValues[i].value } }
									}
									
					--hmi side: send OnTouchEvent
					self.hmiConnection:SendNotification("UI.OnTouchEvent", parameter)

					--mobile side: expected OnTouchEvent notification
					EXPECT_NOTIFICATION("OnTouchEvent", parameter)
					
				end
			end
			
			

			--3. IsMissed
			--4. IsOutLowerBound
			--5. IsOutUpperBound
			--6. IsWrongType
			
			--Create array 1001 items
			local ts_outupperbound = {}
			for i = 1, 1001 do
				table.insert(ts_outupperbound, i)
			end
			
			local InvalidValues = {	{name = "IsMissed", value = nil},
									{name = "IsOutLowerBound", value = {}},
									{name = "IsOutUpperBound", value = ts_outupperbound},
									{name = "WrongDataType", value = 123}}
			
			for i = 1, #InvalidValues  do
				Test["OnTouchEvent_event_ts_array_" .. InvalidValues[i].name] = function(self)
					DelayedExp(2000)
					local parameter = {
										type = "BEGIN", 
										event = { {c = {{x =1, y = 1}}, id = 1, ts = InvalidValues[i].value } }
									}
									
					--hmi side: send OnTouchEvent
					self.hmiConnection:SendNotification("UI.OnTouchEvent", parameter)

					--mobile side: expected OnTouchEvent notification
					EXPECT_NOTIFICATION("OnTouchEvent")
					:Times(0)
				end
			end
			
			
		end

		TCs_verify_event_ts_parameter()

		
		
	----------------------------------------------------------------------------------------------
	--Parameter #5: Checks event.id parameter: type=Integer, minvalue=0, maxvalue=9, mandatory=true
	----------------------------------------------------------------------------------------------
		local function TCs_verify_event_id_parameter()

			--Print new line to separate new test cases group
			commonFunctions:newTestCasesGroup("Test suite: Check event.id parameter")
			
			--1. IsLowerBound
			--2. IsMiddle
			--2. IsUpperBound

			local ValidValues = {
						{name = "IsLowerBound", value = 0},
						{name = "IsMiddle", value = 5},
						{name = "IsUpperBound", value = 9}}
								
			for i = 1, #ValidValues  do
				Test["OnTouchEvent_event_id_" .. ValidValues[i].name] = function(self)
				
					local parameter = {
										type = "BEGIN", 
										event = { {c = {{x = 1, y = 1}}, id = ValidValues[i].value, ts = {1} } }
									}
									
					--hmi side: send OnTouchEvent
					self.hmiConnection:SendNotification("UI.OnTouchEvent", parameter)

					--mobile side: expected OnTouchEvent notification
					EXPECT_NOTIFICATION("OnTouchEvent", parameter)
					
				end
			end
			
			

			--4. IsMissed
			--5. IsOutLowerBound
			--6. IsOutUpperBound
			--7. IsWrongType
			
			local InvalidValues = {	{name = "IsMissed", value = nil},
									{name = "IsOutLowerBound", value = -1},
									{name = "IsOutUpperBound", value = 10},
									{name = "WrongDataType", value = "2"}}
			
			for i = 1, #InvalidValues  do
				Test["OnTouchEvent_event_ts_" .. InvalidValues[i].name] = function(self)
					DelayedExp(2000)
					local parameter = {
										type = "BEGIN", 
										event = { {c = {{x = 1, y = 1}}, id = InvalidValues[i].value, ts = {1} } }
									}
									
					--hmi side: send OnTouchEvent
					self.hmiConnection:SendNotification("UI.OnTouchEvent", parameter)

					--mobile side: expected OnTouchEvent notification
					EXPECT_NOTIFICATION("OnTouchEvent")
					:Times(0)
				end
			end
			
		end

		TCs_verify_event_id_parameter()


		
	----------------------------------------------------------------------------------------------
	--Parameter #6: Checks event parameter: type=TouchEvent, mandatory="true" minsize="1" maxsize="10" array="true"
	----------------------------------------------------------------------------------------------
		local function TCs_verify_event_parameter()

			--Print new line to separate new test cases group
			commonFunctions:newTestCasesGroup("Test suite: Check event array parameter")

			
			--1. IsLowerBound: covered by above TCs
			--2. IsUpperBound

			--Create array 10 items.
			local event_upperbound = {}
			for i = 0, 9 do
				table.insert(event_upperbound, {c = {{x = i + 1, y = 1}}, id = i, ts = {9908} })			
			end


			local ValidValues = {
						{name = "IsUpperBound", value = event_upperbound}}
								
			for i = 1, #ValidValues  do
				Test["OnTouchEvent_event_array_" .. ValidValues[i].name] = function(self)
				
					local parameter = {
										type = "BEGIN", 
										event = ValidValues[i].value
									}
									
					--hmi side: send OnTouchEvent
					self.hmiConnection:SendNotification("UI.OnTouchEvent", parameter)

					--mobile side: expected OnTouchEvent notification
					EXPECT_NOTIFICATION("OnTouchEvent", parameter)
					
				end
			end
			
			

			--3. IsMissed
			--4. IsOutLowerBound
			--5. IsOutUpperBound
			--6. IsWrongType
			
			--Create array 11 items
			local event_outupperbound = {}
			for i = 0, 9 do
				table.insert(event_outupperbound, {c = {{x = i+1, y = 1}}, id = i, ts = {9908}} )			
			end
			table.insert(event_outupperbound, {c = {{x = 1, y = 1}}, id = 1, ts = {9908} })			
			
			local InvalidValues = {	{name = "IsMissed", value = nil},
									{name = "IsOutLowerBound", value = {}},
									{name = "IsOutUpperBound", value = event_outupperbound},
									{name = "WrongDataType", value = 123}}
			
			for i = 1, #InvalidValues  do
				Test["OnTouchEvent_event_array_" .. InvalidValues[i].name] = function(self)
					DelayedExp(2000)
					local parameter = {
										type = "BEGIN", 
										event = InvalidValues[i].value
									}
									
					--hmi side: send OnTouchEvent
					self.hmiConnection:SendNotification("UI.OnTouchEvent", parameter)

					--mobile side: expected OnTouchEvent notification
					EXPECT_NOTIFICATION("OnTouchEvent")
					:Times(0)
				end
			end
			
			
		end

		TCs_verify_event_parameter()
		
	end
		
	TCs_verify_normal_cases()

----------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK IV----------------------------------------
----------------------------Check special cases of HMI notification---------------------------
----------------------------------------------------------------------------------------------
--Requirement id in JAMA or JIRA: 	
	--APPLINK-14765: SDL must cut off the fake parameters from requests, responses and notifications received from HMI

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

	local function SpecialResponseChecks()

		--Print new line to separate new test cases group
		commonFunctions:newTestCasesGroup("Test suite: Check special cases of HMI notification")


		
		--1. Verify OnTouchEvent with invalid Json syntax
		----------------------------------------------------------------------------------------------
		function Test:OnTouchEvent_InvalidJsonSyntax()
			DelayedExp(2000)
			--hmi side: send OnTouchEvent 
			--":" is changed by ";" after "jsonrpc"
			self.hmiConnection:Send('{"jsonrpc";"2.0","method":"UI.OnTouchEvent","params":{"type":"BEGIN","event":[{"c":[{"x":251,"y":194}],"id":0,"ts":[9908]}]}}')
		
			EXPECT_NOTIFICATION("OnTouchEvent")
			:Times(0)
						
		end
		
		
		--2. Verify OnTouchEvent with invalid structure
		----------------------------------------------------------------------------------------------	
		function Test:OnTouchEvent_InvalidStructure()
			DelayedExp(2000)
			--hmi side: send OnTouchEvent 
			--method is moved into params parameter
			self.hmiConnection:Send('{"jsonrpc":"2.0","params":{"method":"UI.OnTouchEvent","type":"BEGIN","event":[{"c":[{"x":251,"y":194}],"id":0,"ts":[9908]}]}}')
		
			EXPECT_NOTIFICATION("OnTouchEvent")
			:Times(0)
		end
		
		
		
		--3. Verify OnTouchEvent with FakeParams
		----------------------------------------------------------------------------------------------
		function Test:OnTouchEvent_FakeParams()

		
			--hmi side: send OnTouchEvent
			self.hmiConnection:SendNotification("UI.OnTouchEvent",	
						{
							type = "BEGIN", 
							fake = 123,
							event = {{fake = 123, c = {{fake = 123, x = 1, y = 1}}, id = 1, ts = {9908} } }
						})

			--mobile side: expected OnTouchEvent notification
			EXPECT_NOTIFICATION("OnTouchEvent", 
						{
							type = "BEGIN", 
							event = {{c = {{x = 1, y = 1}}, id = 1, ts = {9908} } }
						})
			:ValidIf(function(_,data)
									
				if data.payload.fake or
					data.payload.event[1].fake or 
					data.payload.event[1].c[1].fake then
						print(" SDL forwards fake parameter to mobile ")
						return false
				else 
						return true
				end
			end)
					
		end
		
		
		--4. Verify OnTouchEvent with FakeParameterIsFromAnotherAPI
		function Test:OnTouchEvent_FakeParameterIsFromAnotherAPI()
		
		
			--hmi side: send OnTouchEvent
			self.hmiConnection:SendNotification("UI.OnTouchEvent",	
						{
							type = "BEGIN", 
							sliderPosition = 123,
							event = {{sliderPosition = 123, c = {{sliderPosition = 123, x = 1, y = 1}}, id = 1, ts = {9908} } }
						})

			--mobile side: expected OnTouchEvent notification
			EXPECT_NOTIFICATION("OnTouchEvent", 
						{
							type = "BEGIN", 
							event = {{c = {{x = 1, y = 1}}, id = 1, ts = {9908} } }
						})
			:ValidIf(function(_,data)
									
				if data.payload.sliderPosition or
					data.payload.event[1].sliderPosition or 
					data.payload.event[1].c[1].sliderPosition then
						print(" SDL forwards fake parameter to mobile ")
						return false
				else 
						return true
				end
			end)
			
		end
		
			
		
		--5. Verify OnTouchEvent misses mandatory parameter
		----------------------------------------------------------------------------------------------
		--It is covered when verifying each parameter
		
		
		--6. Verify OnTouchEvent MissedAllPArameters
		----------------------------------------------------------------------------------------------
		function Test:OnTouchEvent_AllParameters_AreMissed()
			DelayedExp(2000)
			--hmi side: send OnTouchEvent
			self.hmiConnection:SendNotification("UI.OnTouchEvent",{})

			
			--mobile side: expected OnTouchEvent notification
			EXPECT_NOTIFICATION("OnTouchEvent")
			:Times(0)
					
		end
		
		--7. Verify OnTouchEvent with SeveralNotifications_WithTheSameValues
		----------------------------------------------------------------------------------------------	
		function Test:OnTouchEvent_SeveralNotifications_WithTheSameValues()
		
			--hmi side: send OnTouchEvent
			local parameter = {
									type = "BEGIN", 
									event = { {c = {{x = 1, y = 1}}, id = 1, ts = {9908} } }
								}
						
			--hmi side: send OnTouchEvent
			self.hmiConnection:SendNotification("UI.OnTouchEvent",	parameter)
			self.hmiConnection:SendNotification("UI.OnTouchEvent",	parameter)
			self.hmiConnection:SendNotification("UI.OnTouchEvent",	parameter)

			--mobile side: expected OnTouchEvent notification
			EXPECT_NOTIFICATION("OnTouchEvent", parameter)
			:Times(3)
			
		end
		
			
		--8. Verify OnTouchEvent with SeveralNotifications_WithDifferentValues
		----------------------------------------------------------------------------------------------
		function Test:OnTouchEvent_SeveralNotifications_WithDifferentValues()
		
			--hmi side: send OnTouchEvent
			local parameter1 = 	{
									type = "BEGIN", 
									event = { {c = {{x = 1, y = 1}}, id = 1, ts = {9908} } }
								}
								
			local parameter2 = 	{
									type = "BEGIN", 
									event = { {c = {{x = 2, y = 1}}, id = 1, ts = {9908} } }
								}
								
			local parameter3 = 	{
									type = "BEGIN", 
									event = { {c = {{x = 3, y = 1}}, id = 1, ts = {9908} } }
								}
								
			--hmi side: send OnTouchEvent
			self.hmiConnection:SendNotification("UI.OnTouchEvent",	parameter1)
			self.hmiConnection:SendNotification("UI.OnTouchEvent",	parameter2)
			self.hmiConnection:SendNotification("UI.OnTouchEvent",	parameter3)

			--mobile side: expected OnTouchEvent notification
			EXPECT_NOTIFICATION("OnTouchEvent", parameter1, parameter2, parameter3)
			:Times(3)
			
		end
		
		
	end

	SpecialResponseChecks()	
		
	
	
	
-----------------------------------------------------------------------------------------------
-------------------------------------------TEST BLOCK V----------------------------------------
-------------------------------------Checks All Result Codes-----------------------------------
-----------------------------------------------------------------------------------------------

--Description: Check all resultCodes

--TODO: Update this script according to answer on APPLINK-17560

--Requirement id in JAMA: 
	--N/A
	
--Verification criteria: Verify SDL behaviors in different states of policy table: 
	--1. Notification is not exist in PT => DISALLOWED in policy table, SDL ignores the notification
	--2. Notification is exist in PT but it has not consented yet by user => DISALLOWED in policy table, SDL ignores the notification
	--3. Notification is exist in PT but user does not allow function group that contains this notification => USER_DISALLOWED in policy table, SDL ignores the notification
	--4. Notification is exist in PT and user allow function group that contains this notification
----------------------------------------------------------------------------------------------

	local function ResultCodeChecks()

		--Print new line to separate new test cases group
		commonFunctions:newTestCasesGroup("Test suite: Checks All Result Codes")

		
	--1. Notification is not exist in PT => DISALLOWED in policy table, SDL ignores the notification
	----------------------------------------------------------------------------------------------
		--Precondition: Build policy table file
		local PTFileName = testCasesForPolicyTable:createPolicyTableWithoutAPI("OnTouchEvent")
		
		--Precondition: Update policy table
		testCasesForPolicyTable:updatePolicy(PTFileName)
		
		OnTouchEvent_Notification_IsIgnored("OnTouchEvent_IsNotExistInPT_IsIgnored")
	----------------------------------------------------------------------------------------------
		
		
	--2. Notification is exist in PT but it has not consented yet by user => DISALLOWED in policy table, SDL ignores the notification
	----------------------------------------------------------------------------------------------
		--Precondition: Build policy table file
		local PermissionLinesForBase4 = nil
		local PermissionLinesForGroup1 = 	
[[					"OnTouchEvent": {
						"hmi_levels": [
						  "FULL"
						]
					  }]] .. "\n"
					  
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
		OnTouchEvent_Notification_IsIgnored("OnTouchEvent_UserHasNotConsentedYet_IsIgnored")
	----------------------------------------------------------------------------------------------
	
		
	--3. Notification is exist in PT but user does not allow function group that contains this notification => USER_DISALLOWED in policy table, SDL ignores the notification
	----------------------------------------------------------------------------------------------	
		--Precondition: User does not allow function group
		testCasesForPolicyTable:userConsent(false, "group1")		
		
		--Send notification and check it is ignored
		OnTouchEvent_Notification_IsIgnored("OnTouchEvent_UserDisallowed_IsIgnored")
	----------------------------------------------------------------------------------------------
	
	--4. Notification is exist in PT and user allow function group that contains this notification
	----------------------------------------------------------------------------------------------
		--Precondition: User allows function group
		testCasesForPolicyTable:userConsent(true, "group1")		
		
		function Test:OnTouchEvent_Notification_IsAllowed()
			local parameter = {
							type = "BEGIN", 
							event = { {c = {{x = 1, y = 1}}, id = 0, ts = {900} } }
						}
						
			--hmi side: send OnTouchEvent
			self.hmiConnection:SendNotification("UI.OnTouchEvent",	parameter)

			--mobile side: expected OnTouchEvent notification
			EXPECT_NOTIFICATION("OnTouchEvent", parameter)
		end

	----------------------------------------------------------------------------------------------	
	end
	--TODO: PT is blocked by ATF defect APPLINK-19188
	--ResultCodeChecks()
	
----------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK VI----------------------------------------
-------------------------Sequence with emulating of user's action(s)--------------------------
----------------------------------------------------------------------------------------------	

--Requirement id in JAMA or JIRA: 	
	--SDLAQ-TC-218: TC_OnTouchEvent_navi_01
	--APPLINK-18023: 04[P][MAN]_TC_OnTouchEvent
	
--Verification criteria: 
	--1. Click on navigation area
	--2. Click on navigation area with 2 fingers at the same time
	--3. Move on navigation area with 1 finger
	--4. Move on navigation area with 2 fingers at the same time
----------------------------------------------------------------------------------------------
	local function SequenceCheck1()


		--Print new line to separate new test cases group
		commonFunctions:newTestCasesGroup("Test suite: Sequence with emulating of user's action(s)")

		
		--1. Click on navigation area
		function Test:OnTouchEvent_type_BEGIN()
			print()
			print("Step 1. Click on navigation area")	
			
			local parameter = {
							type = "BEGIN", 
							event = { {c = {{x = 1, y = 1}}, id = 0, ts = {900} } }
						}
						
			--hmi side: send OnTouchEvent
			self.hmiConnection:SendNotification("UI.OnTouchEvent",	parameter)

			--mobile side: expected OnTouchEvent notification
			EXPECT_NOTIFICATION("OnTouchEvent", parameter)
			
		end

		function Test:OnTouchEvent_type_END()
					
			local parameter = {
							type = "END", 
							event = { {c = {{x = 1, y = 1}}, id = 0, ts = {1000} } }
						}
						
			--hmi side: send OnTouchEvent
			self.hmiConnection:SendNotification("UI.OnTouchEvent",	parameter)

			--mobile side: expected OnTouchEvent notification
			EXPECT_NOTIFICATION("OnTouchEvent", parameter)
			
		end		

		--1.1. Click and cancel on navigation
		function Test:OnTouchEvent_type_BEGIN()
			print()
			print("Step 1.1. Click and cancel on navigation area")

			local parameter = {
							type = "BEGIN",
							event = { {c = {{x = 1, y = 1}}, id = 0, ts = {900} } }
						}

			--hmi side: send OnTouchEvent
			self.hmiConnection:SendNotification("UI.OnTouchEvent",	parameter)

			--mobile side: expected OnTouchEvent notification
			EXPECT_NOTIFICATION("OnTouchEvent", parameter)

		end

		function Test:OnTouchEvent_type_CANCEL()

			local parameter = {
							type = "CANCEL",
							event = { {c = {{x = 1, y = 1}}, id = 0, ts = {1000} } }
						}

			--hmi side: send OnTouchEvent
			self.hmiConnection:SendNotification("UI.OnTouchEvent",	parameter)

			--mobile side: expected OnTouchEvent notification
			EXPECT_NOTIFICATION("OnTouchEvent", parameter)

		end


		--2. Click on navigation area with 2 fingers at the same time
		function Test:OnTouchEvent_type_BEGIN_2Fingers()
			print()
			print("Step 2. Click on navigation area with 2 fingers at the same time")	
			
			local parameter1 = {
							type = "BEGIN", 
							event = { {c = {{x = 1, y = 1}}, id = 0, ts = {900} } }
						}
						
			local parameter2 = {
							type = "BEGIN", 
							event = { {c = {{x = 2, y = 1}}, id = 1, ts = {900} } }
						}			
						
			--hmi side: send OnTouchEvent
			self.hmiConnection:SendNotification("UI.OnTouchEvent",	parameter1)
			self.hmiConnection:SendNotification("UI.OnTouchEvent",	parameter2)
			

			--mobile side: expected OnTouchEvent notification
			EXPECT_NOTIFICATION("OnTouchEvent", parameter1, parameter2)
			:Times(2)
			
		end

		function Test:OnTouchEvent_type_END_2Fingers()
					
			local parameter1 = {
							type = "END", 
							event = { {c = {{x = 1, y = 1}}, id = 0, ts = {900} } }
						}
						
			local parameter2 = {
							type = "END", 
							event = { {c = {{x = 2, y = 1}}, id = 1, ts = {900} } }
						}			
						
			--hmi side: send OnTouchEvent
			self.hmiConnection:SendNotification("UI.OnTouchEvent",	parameter1)
			self.hmiConnection:SendNotification("UI.OnTouchEvent",	parameter2)
			

			--mobile side: expected OnTouchEvent notification
			EXPECT_NOTIFICATION("OnTouchEvent", parameter1, parameter2)
			:Times(2)
			
		end		

		--2.1. Click and cancel on navigation area with 2 fingers at the same time
		function Test:OnTouchEvent_type_BEGIN_2Fingers()
			print()
			print("Step 2.1. Click and cancel on navigation area with 2 fingers at the same time")

			local parameter1 = {
							type = "BEGIN",
							event = { {c = {{x = 1, y = 1}}, id = 0, ts = {900} } }
						}

			local parameter2 = {
							type = "BEGIN",
							event = { {c = {{x = 2, y = 1}}, id = 1, ts = {900} } }
						}

			--hmi side: send OnTouchEvent
			self.hmiConnection:SendNotification("UI.OnTouchEvent",	parameter1)
			self.hmiConnection:SendNotification("UI.OnTouchEvent",	parameter2)


			--mobile side: expected OnTouchEvent notification
			EXPECT_NOTIFICATION("OnTouchEvent", parameter1, parameter2)
			:Times(2)

		end

		function Test:OnTouchEvent_type_CANCEL_2Fingers()

			local parameter1 = {
							type = "CANCEL",
							event = { {c = {{x = 1, y = 1}}, id = 0, ts = {900} } }
						}

			local parameter2 = {
							type = "CANCEL",
							event = { {c = {{x = 2, y = 1}}, id = 1, ts = {900} } }
						}

			--hmi side: send OnTouchEvent
			self.hmiConnection:SendNotification("UI.OnTouchEvent",	parameter1)
			self.hmiConnection:SendNotification("UI.OnTouchEvent",	parameter2)


			--mobile side: expected OnTouchEvent notification
			EXPECT_NOTIFICATION("OnTouchEvent", parameter1, parameter2)
			:Times(2)

		end

		--3. Move on navigation area with 1 finger
		function Test:OnTouchEvent_type_BEGIN()
			print()
			print("Step 3. Move on navigation area with 1 finger")		
			
			local parameter = {
							type = "BEGIN", 
							event = { {c = {{x = 1, y = 1}}, id = 0, ts = {900} } }
						}
						
			--hmi side: send OnTouchEvent
			self.hmiConnection:SendNotification("UI.OnTouchEvent",	parameter)

			--mobile side: expected OnTouchEvent notification
			EXPECT_NOTIFICATION("OnTouchEvent", parameter)
			
		end

		for i = 2, 100 do
			Test["OnTouchEvent_type_MOVE_x_" .. i .. "_y_" .. i - 1 ] = function(self)
						
				local parameter = {
								type = "MOVE", 
								event = { {c = {{x = i, y = i - 1}}, id = 0, ts = {900 + i} } }
							}
							
				--hmi side: send OnTouchEvent
				self.hmiConnection:SendNotification("UI.OnTouchEvent",	parameter)

				--mobile side: expected OnTouchEvent notification
				EXPECT_NOTIFICATION("OnTouchEvent", parameter)
				
			end
		end
		

		function Test:OnTouchEvent_type_END()
					
			local parameter = {
							type = "END", 
							event = { {c = {{x = 2, y = 1}}, id = 0, ts = {1000} } }
						}
						
			--hmi side: send OnTouchEvent
			self.hmiConnection:SendNotification("UI.OnTouchEvent",	parameter)

			--mobile side: expected OnTouchEvent notification
			EXPECT_NOTIFICATION("OnTouchEvent", parameter)
			
		end		


		--4. Move on navigation area with 2 fingers
		function Test:OnTouchEvent_type_BEGIN_2Fingers()
			print()
			print("Step 4. Move on navigation area with 2 fingers")		
			local parameter1 = {
							type = "BEGIN", 
							event = { {c = {{x = 1, y = 1}}, id = 0, ts = {900} } }
						}
						
			local parameter2 = {
							type = "BEGIN", 
							event = { {c = {{x = 2, y = 1}}, id = 1, ts = {900} } }
						}			
						
			--hmi side: send OnTouchEvent
			self.hmiConnection:SendNotification("UI.OnTouchEvent",	parameter1)
			self.hmiConnection:SendNotification("UI.OnTouchEvent",	parameter2)
			

			--mobile side: expected OnTouchEvent notification
			EXPECT_NOTIFICATION("OnTouchEvent", parameter1, parameter2)
			:Times(2)
			
		end

		for i = 1, 100 do
			Test["OnTouchEvent_type_MOVE_2Fingers_Time_" .. i ] = function(self)
						
				local parameter1 = {
								type = "MOVE", 
								event = { {c = {{x = 1 + i, y = 1 + i }}, id = 0, ts = {900 + i} } }
							}
							
				local parameter2 = {
								type = "MOVE", 
								event = { {c = {{x = 2 + i, y = 1 + i}}, id = 1, ts = {900 + i} } }
							}			
							
				--hmi side: send OnTouchEvent
				self.hmiConnection:SendNotification("UI.OnTouchEvent",	parameter1)
				self.hmiConnection:SendNotification("UI.OnTouchEvent",	parameter2)
				

				--mobile side: expected OnTouchEvent notification
				EXPECT_NOTIFICATION("OnTouchEvent", parameter1, parameter2)
				:Times(2)
				
			end
		end
		


		function Test:OnTouchEvent_type_END_2Fingers()
					
			local parameter1 = {
							type = "END", 
							event = { {c = {{x = 101, y = 101}}, id = 0, ts = {900 + 101} } }
						}
						
			local parameter2 = {
							type = "END", 
							event = { {c = {{x = 102, y = 102}}, id = 1, ts = {900 + 101} } }
						}			
						
			--hmi side: send OnTouchEvent
			self.hmiConnection:SendNotification("UI.OnTouchEvent",	parameter1)
			self.hmiConnection:SendNotification("UI.OnTouchEvent",	parameter2)
			

			--mobile side: expected OnTouchEvent notification
			EXPECT_NOTIFICATION("OnTouchEvent", parameter1, parameter2)
			:Times(2)
			
		end		

	end

	SequenceCheck1()


----------------------------------------------------------------------------------------------
--Checks of absence notifications in case of not navi app and processing in case of navi app.
----------------------------------------------------------------------------------------------
	local function SequenceCheck2()	
		

		function Test:Precondition_Add_New_Session()
		
		  -- Connected expectation
			Test.mobileSession2 = mobile_session.MobileSession(Test, Test.mobileConnection)
			
			Test.mobileSession2:StartService(7)
		end	
		
		function Test:Register_Second_App_Non_Nav()

			config.application2.registerAppInterfaceParams.appHMIType = {"DEFAULT"}
			CorIdRegister = self.mobileSession2:SendRPC("RegisterAppInterface", config.application2.registerAppInterfaceParams)
			strAppName = config.application2.registerAppInterfaceParams.appName

			--hmi side: expect BasicCommunication.OnAppRegistered request
			EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
			{
				application = 
				{
					appName = strAppName
				}
			})
			:Do(function(_,data)
				--self.appName = data.params.application.appName
				self.applications[strAppName] = data.params.application.appID
				Apps[2].appID = data.params.application.appID
			end)
			
			--mobile side: expect response
			self.mobileSession2:ExpectResponse(CorIdRegister, 
			{
				resultCode = 'SUCCESS'
			})
			:Timeout(12000)

			--mobile side: expect notification
			self.mobileSession2:ExpectNotification("OnHMIStatus", 
			{ 
				systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"
			})
			:Timeout(12000)
		end
			
		
		function Test_Activation_App2()
			
			--hmi side: sending SDL.ActivateApp request
			local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = Apps[2].appID})
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
			self.mobileSession2:ExpectNotification("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"}) 
			EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"}) 
		end
		
		function Test:OnTouchEvent_Non_Navi_BEGIN()
			print()
			DelayedExp(2000)
			local parameter = {
							type = "BEGIN", 
							event = { {c = {{x = 1, y = 1}}, id = 0, ts = {900} } }
						}
						
			--hmi side: send OnTouchEvent
			self.hmiConnection:SendNotification("UI.OnTouchEvent",	parameter)

			--mobile side: expected OnTouchEvent notification
			EXPECT_NOTIFICATION("OnTouchEvent", parameter)
			
			--mobile side: app2 expects notification
			self.mobileSession2:ExpectNotification("OnTouchEvent", parameter)
			:Times(0)
		end

		function Test:OnTouchEvent_Non_Navi_MOVE()
			DelayedExp(2000)		
			local parameter = {
							type = "MOVE", 
							event = { {c = {{x = 2, y = 2}}, id = 0, ts = {901} } }
						}
						
			--hmi side: send OnTouchEvent
			self.hmiConnection:SendNotification("UI.OnTouchEvent",	parameter)

			--mobile side: expected OnTouchEvent notification
			EXPECT_NOTIFICATION("OnTouchEvent", parameter)
			
			--mobile side: app2 expects notification
			self.mobileSession2:ExpectNotification("OnTouchEvent", parameter)
			:Times(0)
			
		end

		function Test:OnTouchEvent_Non_Navi_END()
			DelayedExp(2000)		
			local parameter = {
							type = "END", 
							event = { {c = {{x = 2, y = 2}}, id = 0, ts = {902} } }
						}
						
			--hmi side: send OnTouchEvent
			self.hmiConnection:SendNotification("UI.OnTouchEvent",	parameter)

			--mobile side: expected OnTouchEvent notification
			EXPECT_NOTIFICATION("OnTouchEvent", parameter)

			--mobile side: app2 expects notification
			self.mobileSession2:ExpectNotification("OnTouchEvent", parameter)
			:Times(0)
			
		end		

		function Test:OnTouchEvent_Non_Navi_CANCEL()
			DelayedExp(2000)
			local parameter = {
							type = "CANCEL",
							event = { {c = {{x = 2, y = 2}}, id = 0, ts = {903} } }
						}

			--hmi side: send OnTouchEvent
			self.hmiConnection:SendNotification("UI.OnTouchEvent",	parameter)

			--mobile side: expected OnTouchEvent notification
			EXPECT_NOTIFICATION("OnTouchEvent", parameter)

			--mobile side: app2 expects notification
			self.mobileSession2:ExpectNotification("OnTouchEvent", parameter)
			:Times(0)

		end

		--Postcondition:
		function Test:Unregister_App2()

			local cid = self.mobileSession2:SendRPC("UnregisterAppInterface",{})

			self.mobileSession2:ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
			:Timeout(2000)
		end 
		
		
	end

	SequenceCheck2()


----------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK VII---------------------------------------
--------------------------------------Different HMIStatus-------------------------------------
----------------------------------------------------------------------------------------------

--Description: Check different HMIStatus

--Requirement id in JAMA: 	
	--N/A
	
	--Verification criteria: 
		--The applications in HMI FULL don't reject OnTouchEvent request.
		--None of the applications in HMI NONE receives OnTouchEvent request.
		--The applications in HMI LIMITED rejects OnTouchEvent request.
		--The applications in HMI BACKGROUND rejects OnTouchEvent request.

	local function DifferentHMIlevelChecks()

		--Print new line to separate new test cases group
		commonFunctions:newTestCasesGroup("Test suite: Different HMI Level Checks")
		----------------------------------------------------------------------------------------------

		--1. HMI level is NONE
		----------------------------------------------------------------------------------------------
			--Precondition: Deactivate app to NONE HMI level	
			commonSteps:DeactivateAppToNoneHmiLevel()
		
			OnTouchEvent_Notification_IsIgnored("OnTouchEvent_Notification_InNoneHmiLevel")
						
			--Postcondition: Activate app
			commonSteps:ActivationApp()	
		----------------------------------------------------------------------------------------------


		--2. HMI level is LIMITED
		----------------------------------------------------------------------------------------------
			if commonFunctions:isMediaApp() then 
				-- Precondition: Change app to LIMITED
				commonSteps:ChangeHMIToLimited()
				
				OnTouchEvent_Notification_IsIgnored("OnTouchEvent_Notification_InLimitedHmiLevel")
				
				--Postcondition: Activate app
				commonSteps:ActivationApp()	
			end
		----------------------------------------------------------------------------------------------


		--3. HMI level is BACKGROUND
		----------------------------------------------------------------------------------------------

			if config.application1.registerAppInterfaceParams.isMediaApplication == true then
			
				commonTestCases:ChangeAppToBackgroundHmiLevel()
				
				OnTouchEvent_Notification_IsIgnored("OnTouchEvent_Notification_InBackgroundHmiLevel")
			
			else
				--APPLINK-8531
				--2. SDL must allow only one level: either FULL or LIMITED at the given moment of time for two apps of one and the same AppHMIType for the following AppHMITypes: MEDIA media, NAVIGATION non-media, COMMUNICATION non-media (per APPLINK-9802).
		
				-- Precondition 1: Opening new session
				commonSteps:precondition_AddNewSession()

				-- Precondition 2: Register app2
				function Test:Register_The_Second_NAVIGATION_non_media()

					--mobile side: RegisterAppInterface request 
					local CorIdRAI = self.mobileSession2:SendRPC("RegisterAppInterface",
																{
																	syncMsgVersion = 
																	{ 
																		majorVersion = 3,
																		minorVersion = 1,
																	}, 
																	appName ="SPT2",
																	isMediaApplication = false,
																	appHMIType = { "NAVIGATION" },
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
						--appId2 = data.params.application.appID
						Apps[2].appID = data.params.application.appID
					end)
					
					--mobile side: RegisterAppInterface response 
					self.mobileSession2:ExpectResponse(CorIdRAI, { success = true, resultCode = "SUCCESS"})
						:Timeout(2000)

					self.mobileSession2:ExpectNotification("OnHMIStatus",{hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
				end
				
				-- Precondition 3: Activate an other media app to change app to BACKGROUND
				function Test:Activate_The_Second_Media_App()
	
					--HMI send ActivateApp request			
					local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = Apps[2].appID})
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
				

				OnTouchEvent_Notification_IsIgnored("OnTouchEvent_Notification_InBackgroundHmiLevel")
			
			end
		----------------------------------------------------------------------------------------------
	end
	DifferentHMIlevelChecks()


return Test	
	
	
