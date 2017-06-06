local commonSteps = require("user_modules/shared_testcases/commonSteps")
commonSteps:CheckSDLPath()
commonSteps:DeleteLogsFileAndPolicyTable()

local commonPreconditions = require("user_modules/shared_testcases/commonPreconditions")
commonPreconditions:BackupFile("sdl_preloaded_pt.json")
commonPreconditions:ReplaceFile("sdl_preloaded_pt.json", "./files/jsons/RC/rc_sdl_preloaded_pt.json")

local revsdl = require("user_modules/revsdl")

revsdl.AddUnknownFunctionIDs()
revsdl.SubscribeToRcInterface()
config.ValidateSchema = false
config.application1.registerAppInterfaceParams.appHMIType = { "REMOTE_CONTROL" }
config.application1.registerAppInterfaceParams.appID = "8675311"

Test = require('connecttest')
require('cardinalities')

local device1mac = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
--======================================Requirement========================================--
---------------------------------------------------------------------------------------------
--------------Requirement: Policies: "equipment" permissions must be checked-----------------
-------------------------- against location provided from HMI--------------------------------
---------------------------------------------------------------------------------------------
--=========================================================================================--


--=================================================BEGIN TEST CASES 17==========================================================--
	--Begin Test suit CommonRequestCheck.17 for Req.#17

	--Description: 17. In case RSDL has received an RPC from RC-application from <deviceID> device and started processing it with the currently known <interiorZone> (either 'app-provided' if no OnDeviceLocationChanged received, or 'HMI-provided' if OnDeviceLocationChanged is obtained from HMI)
							-- and RSDL gets OnDeviceLocationChanged for this <deviceID> with different <interiorZone> \ RSDL must:
							-- finish processing RPC
							-- only then apply rules of req. 16.

	--Begin Test case CommonRequestCheck.17.1
	--Description: 	-- RSDL must:
							-- finish processing RPC
							-- only then apply rules of req. 16.

		--Requirement/Diagrams id in jira:
				--Requirement
				--Requirement

		--Verification criteria:
				--RSDL must:
						-- finish processing RPC
						-- only then apply rules of req. 16.

		-----------------------------------------------------------------------------------------
		-------------------------FOR FRONT PASSENGER ZONE----------------------------------------

			--Begin Precondition.1. HMI sends notification RC.OnDeviceLocationChanged(<deviceID>) to RSDL (zone:Front Passenger)
			--Description: HMI sends notification RC.OnDeviceLocationChanged(<deviceID>) to RSDL

				function Test:ChangedLocation_Front()
					--hmi side: HMI sends notification RC.OnDeviceLocationChanged(<deviceID>) to RSDL
					self.hmiConnection:SendNotification("RC.OnDeviceLocationChanged",
						{device = {name = "127.0.0.1", id = device1mac, isSDLAllowed = true},
							deviceLocation =
								{
									colspan = 2,
									row = 0,
									rowspan = 2,
									col = 1,
									levelspan = 1,
									level = 0
								}
						})
				end
			--End Precondition.1

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.17.1.1
			--Description: application sends ButtonPress as Front Passenger (col=1, row=0, level=0) and ModuleType = RADIO
				function Test:ButtonPress_FrontRADIO_Time1()
					--mobile side: In case the application sends a valid rc-RPC with <interiorZone>, <moduleType> and <params> allowed by app's assigned policies
					local cid = self.mobileSession:SendRPC("ButtonPress",
					{
						zone =
						{
							colspan = 2,
							row = 2,
							rowspan = 2,
							col = 2,
							levelspan = 1,
							level = 0
						},
						moduleType = "RADIO",
						buttonPressMode = "LONG",
						buttonName = "VOLUME_UP"
					})

					--hmi side: expect RC.GetInteriorVehicleDataConsent request from HMI
					EXPECT_HMICALL("RC.GetInteriorVehicleDataConsent",
								{
									appID = self.applications["Test Application"],
									moduleType = "RADIO",
									zone =
									{
										colspan = 2,
										row = 0,
										rowspan = 2,
										col = 1,
										levelspan = 1,
										level = 0
									}
								})
						:Do(function(_,data)
							--hmi side: sending RC.GetInteriorVehicleDataConsent response to RSDL
							self.hmiConnection:SendResponse(data.id, "RC.GetInteriorVehicleDataConsent", "SUCCESS", {allowed = true})

							--hmi side: expect Buttons.ButtonPress request
							EXPECT_HMICALL("Buttons.ButtonPress",
											{
												zone =
												{
													colspan = 2,
													row = 2,
													rowspan = 2,
													col = 2,
													levelspan = 1,
													level = 0
												},
												moduleType = "RADIO",
												buttonPressMode = "LONG",
												buttonName = "VOLUME_UP"
											})
								:Do(function(_,data)
									--hmi side: sending Buttons.ButtonPress response
									self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
								end)
					end)

					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
				end
			--End Test case CommonRequestCheck.17.1.1

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.17.1.2
			--Description: application sends ButtonPress as Front Passenger and HMI sends RC.OnDeviceLocationChanged zone:BACK LEFT Passenger)
				function Test:ButtonPress_FrontRADIO_Time2AndChangedLocation()
					--mobile side: In case the application sends a valid rc-RPC with <interiorZone>, <moduleType> and <params> allowed by app's assigned policies
					local cid = self.mobileSession:SendRPC("ButtonPress",
					{
						zone =
						{
							colspan = 2,
							row = 2,
							rowspan = 2,
							col = 2,
							levelspan = 1,
							level = 0
						},
						moduleType = "RADIO",
						buttonPressMode = "LONG",
						buttonName = "VOLUME_UP"
					})

					--hmi side: expect Buttons.ButtonPress request
					EXPECT_HMICALL("Buttons.ButtonPress",
									{
										zone =
										{
											colspan = 2,
											row = 2,
											rowspan = 2,
											col = 2,
											levelspan = 1,
											level = 0
										},
										moduleType = "RADIO",
										buttonPressMode = "LONG",
										buttonName = "VOLUME_UP"
									})
						:Do(function(_,data)
							--hmi side: sending Buttons.ButtonPress response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})

							--hmi side: HMI sends notification RC.OnDeviceLocationChanged(<deviceID>) to RSDL
							self.hmiConnection:SendNotification("RC.OnDeviceLocationChanged",
							{device = {name = "127.0.0.1", id = device1mac, isSDLAllowed = true},
								deviceLocation =
									{
										colspan = 2,
										row = 1,
										rowspan = 2,
										col = 0,
										levelspan = 1,
										level = 0
									}
							})

						end)

					-- finish processing RPC
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

					--Send OnHMIStatus (NONE) to such app
					EXPECT_NOTIFICATION("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE" })

				end
			--End Test case CommonRequestCheck.17.1.2

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.17.1.3
			--Description: application sends ButtonPress as Left Rare Passenger (col=0, row=1, level=0) and ModuleType = CLIMATE (asking permision again)
				function Test:ButtonPress_LeftCLIMATE_Time1()
					--mobile side: In case the application sends a valid rc-RPC with <interiorZone>, <moduleType> and <params> allowed by app's assigned policies
					local cid = self.mobileSession:SendRPC("ButtonPress",
					{
						zone =
						{
							colspan = 2,
							row = 2,
							rowspan = 2,
							col = 2,
							levelspan = 1,
							level = 0
						},
						moduleType = "CLIMATE",
						buttonPressMode = "SHORT",
						buttonName = "LOWER_VENT"
					})

					--hmi side: expect RC.GetInteriorVehicleDataConsent request from HMI
					EXPECT_HMICALL("RC.GetInteriorVehicleDataConsent",
								{
									appID = self.applications["Test Application"],
									moduleType = "CLIMATE",
									zone =
									{
										colspan = 2,
										row = 1,
										rowspan = 2,
										col = 0,
										levelspan = 1,
										level = 0
									}
								})
						:Do(function(_,data)
							--hmi side: sending RC.GetInteriorVehicleDataConsent response to RSDL
							self.hmiConnection:SendResponse(data.id, "RC.GetInteriorVehicleDataConsent", "SUCCESS", {allowed = true})

							--hmi side: expect Buttons.ButtonPress request
							EXPECT_HMICALL("Buttons.ButtonPress",
											{
												zone =
												{
													colspan = 2,
													row = 2,
													rowspan = 2,
													col = 2,
													levelspan = 1,
													level = 0
												},
												moduleType = "CLIMATE",
												buttonPressMode = "SHORT",
												buttonName = "LOWER_VENT"
											})
								:Do(function(_,data)
									--hmi side: sending Buttons.ButtonPress response
									self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
								end)
					end)

					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
				end
			--End Test case CommonRequestCheck.17.1.3

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.17.1.4
			--Description: application sends ButtonPress as Left Rare Passenger (col=0, row=1, level=0) and ModuleType = CLIMATE (time2 doesn't ask permission)
				function Test:ButtonPress_LeftCLIMATE_Time2()
					--mobile side: In case the application sends a valid rc-RPC with <interiorZone>, <moduleType> and <params> allowed by app's assigned policies
					local cid = self.mobileSession:SendRPC("ButtonPress",
					{
						zone =
						{
							colspan = 2,
							row = 2,
							rowspan = 2,
							col = 0,
							levelspan = 1,
							level = 0
						},
						moduleType = "CLIMATE",
						buttonPressMode = "SHORT",
						buttonName = "LOWER_VENT"
					})

					--hmi side: expect Buttons.ButtonPress request
					EXPECT_HMICALL("Buttons.ButtonPress",
									{
										zone =
										{
											colspan = 2,
											row = 2,
											rowspan = 2,
											col = 0,
											levelspan = 1,
											level = 0
										},
										moduleType = "CLIMATE",
										buttonPressMode = "SHORT",
										buttonName = "LOWER_VENT"
									})
						:Do(function(_,data)
							--hmi side: sending Buttons.ButtonPress response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)

					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
				end
			--End Test case CommonRequestCheck.17.1.4

		-----------------------------------------------------------------------------------------
	--End Test case CommonRequestCheck.17.1


--=================================================END TEST CASES 17==========================================================--

function Test.PostconditionsRestoreFile()
  commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
end
