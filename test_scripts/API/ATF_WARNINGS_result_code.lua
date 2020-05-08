Test = require('connecttest')
require('cardinalities')
local events = require('events')
local mobile_session = require('mobile_session')
local mobile  = require('mobile_connection')
local tcp = require('tcp_connection')
local file_connection  = require('file_connection')

local module = require('testbase')

---------------------------------------------------------------------------------------------
-----------------------------Required Shared Libraries---------------------------------------
---------------------------------------------------------------------------------------------
require('user_modules/AppTypes')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
local policyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local integerParameter = require('user_modules/shared_testcases/testCasesForIntegerParameter')
local stringParameterInResponse = require('user_modules/shared_testcases/testCasesForStringParameterInResponse')
local integerParameterInResponse = require('user_modules/shared_testcases/testCasesForIntegerParameterInResponse')
local arrayStringParameterInResponse = require('user_modules/shared_testcases/testCasesForArrayStringParameterInResponse')
---------------------------------------------------------------------------------------------
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"


local storagePath = config.pathToSDL .. "storage/" .. config.application1.registerAppInterfaceParams.fullAppID .. "_" .. config.deviceMAC .. "/"
local imageValues = {"i", "icon.png", "qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=QWERTYUIOPASDFGHJKLZXCVBNM{}|?>:<qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=QWERTY"}
local grammarIDValue
local appId2
local infoMessage = "qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=QWERTYUIOPASDFGHJKLZXCVBNM{}|?>:<qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=QWERTYqwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=QWERTYUIOPASDFGHJKLZXCVBNM{}|?>:<qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=QWERTYqwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=QWERTYUIOPASDFGHJKLZXCVBNM{}|?>:<qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=QWERTYqwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=QWERTYUIOPASDFGHJKLZXCVBNM{}|?>:<qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=qwertyuiopasdfghjklzxcvbnm1234567890[]'"


local function SendOnSystemContext(self, ctx)
  self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = ctx })
end
function DelayedExp()
  local event = events.Event()
  event.matches = function(self, e) return self == e end
  EXPECT_EVENT(event, "Delayed event")
  RUN_AFTER(function()
              RAISE_EVENT(event, event)
            end, 2000)
end

local function ExpectOnHMIStatusWithAudioStateChanged_Alert(self, request, timeout, level)

        if request == nil then  request = "BOTH" end
        if level == nil then  level = "FULL" end
        if timeout == nil then timeout = 10000 end

        if
                self.isMediaApplication == true or
                appHMITypes["NAVIGATION"] == true then

                        if request == "BOTH" then
                                --mobile side: OnHMIStatus notifications
                                EXPECT_NOTIFICATION("OnHMIStatus",
                                            { systemContext = "ALERT", hmiLevel = level, audioStreamingState = "AUDIBLE"    },
                                            { systemContext = "ALERT", hmiLevel = level, audioStreamingState = "ATTENUATED" },
                                            { systemContext = "ALERT", hmiLevel = level, audioStreamingState = "AUDIBLE"    },
                                            { systemContext = "MAIN",  hmiLevel = level, audioStreamingState = "AUDIBLE"    })
                                    :Times(4)
                                    :Timeout(timeout)
                        elseif request == "speak" then
                                --mobile side: OnHMIStatus notification
                                EXPECT_NOTIFICATION("OnHMIStatus",
                                                    { systemContext = "MAIN", hmiLevel = level, audioStreamingState = "ATTENUATED"    },
                                                    { systemContext = "MAIN",  hmiLevel = level, audioStreamingState = "AUDIBLE"    })
                                    :Times(2)
                                    :Timeout(timeout)
                        elseif request == "alert" then
                                --mobile side: OnHMIStatus notification
                                EXPECT_NOTIFICATION("OnHMIStatus",
                                                    { systemContext = "ALERT", hmiLevel = level, audioStreamingState = "AUDIBLE"    },
                                                    { systemContext = "MAIN",  hmiLevel = level, audioStreamingState = "AUDIBLE"    })
                                    :Times(2)
                                    :Timeout(timeout)
                        end
        elseif
                self.isMediaApplication == false then

                        if request == "BOTH" then
                                --mobile side: OnHMIStatus notifications
                                EXPECT_NOTIFICATION("OnHMIStatus",
                                            { systemContext = "ALERT", hmiLevel = level, audioStreamingState = "NOT_AUDIBLE"},
                                            { systemContext = "MAIN",  hmiLevel = level, audioStreamingState = "NOT_AUDIBLE"})
                                    :Times(2)
                                    :Timeout(timeout)
                        elseif request == "speak" then
                                --any OnHMIStatusNotifications
                                EXPECT_NOTIFICATION("OnHMIStatus")
                                        :Times(0)
                                        :Timeout(timeout)
                        elseif request == "alert" then
                                --mobile side: OnHMIStatus notification
                                EXPECT_NOTIFICATION("OnHMIStatus",
                                                    { systemContext = "ALERT", hmiLevel = level, audioStreamingState = "NOT_AUDIBLE"    },
                                                    { systemContext = "MAIN",  hmiLevel = level, audioStreamingState = "NOT_AUDIBLE"    })
                                    :Times(2)
                                    :Timeout(timeout)
                        end
        end

end
local function UnregisterApplicationSessionOne(self)
        --mobile side: UnregisterAppInterface request
        local CorIdUAI = self.mobileSession:SendRPC("UnregisterAppInterface",{})

        --hmi side: expect OnAppUnregistered notification
                EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = self.applications["SyncProxyTester"], unexpectedDisconnect = false})


         --mobile side: UnregisterAppInterface response
        EXPECT_RESPONSE(CorIdUAI, { success = true, resultCode = "SUCCESS"})
                :Timeout(2000)
end


function GetParamValue(parameterName)

	local iniFilePath = config.pathToSDL .. "smartDeviceLink.ini"
		local iniFile = io.open(iniFilePath)
		  if iniFile then
			for line in iniFile:lines() do
				if line:match(parameterName) then
				local version = line:match("=.*")
					version = string.gsub(version, "=", "")
					version = string.gsub(version, "% ", "")
				return version
				end
			end
			else
			return nil
		end
	end



---------------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------

	--Print new line to separate Preconditions
	commonFunctions:newTestCasesGroup("Preconditions")

	--Delete app_info.dat, logs and policy table
	commonSteps:DeleteLogsFileAndPolicyTable()

	--1.Activation App by sending SDL.ActivateApp
                function Test:ActivationApp()

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

                        --mobile side: expect notification
                        EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL"})
                end


	--2. Update policy to allow request
	--TODO: Will be updated after policy flow implementation
    policyTable:Precondition_updatePolicy_By_overwriting_preloaded_pt("files/ptu_general.json")


	--3. Put file
	function Test:PutFile()
		for i=1,#imageValues do
			local cid = self.mobileSession:SendRPC("PutFile",
				{
					syncFileName = imageValues[i],
					fileType	= "GRAPHIC_PNG",
					persistentFile = false,
					systemFile = false
				}, "files/icon.png")
		EXPECT_RESPONSE(cid, { success = true})
	end


             ----------------------------------------------------------------------------------------------
                ----------------------------------------1 TEST BLOCK------------------------------------------
                -------------------------Check "WARNINGS" result code for AddCommand RPC-------------------
                ----------------------------------------------------------------------------------------------


				--Print new line to separate test suite
	            commonFunctions:newTestCasesGroup("Test Suite For WARNINGS result code for AddCommand RPC")


                -- сheck all possible combinations of "WARNINGS" result code from HMI

                --Description: check UI response with "WARNINGS"

                --Requirement in JIRA: APPLINK-15051, APPLINK-10501

                --Verification criteria: In case SDL receives WARNINGS result code from HMI -> SDL must transfer WARNINGS (success:true) to mobile app



                function Test:AddCommand_UI_WARNINGS_Response ()

                        --mobile side: sending AddCommand request
                                local cid = self.mobileSession:SendRPC("AddCommand",
                                        {
                                                                                                                cmdID = 1,
                                                                                                                menuParams =
                                                                                                                {
                                                                                                                        menuName ="Command1"
                                                                                                                },
                                                                                                                vrCommands =
                                                                                                                {
                                                                                                                       "synonym1","synonym2"
                                                                                                                }
                                                                                                        })
                        --hmi side: expect UI.AddCommand request
                        EXPECT_HMICALL("UI.AddCommand",
                                                        {
                                                                cmdID = 1,
                                                                menuParams =
                                                                {
                                                                        menuName ="Command1"
                                                                }
                                                        })
                        :Do(function(exp,data)
                                --hmi side: send UI.AddCommand response
                                self.hmiConnection:SendError(data.id, "UI.AddCommand", "WARNINGS", "Error Messages")
                        end)

                        --hmi side: expect VR.AddCommand request
                        EXPECT_HMICALL("VR.AddCommand",
                                                        {
                                                                cmdID = 1,
                                                                type = "Command",
                                                                vrCommands =
                                                                {
                                                                        "synonym1","synonym2"
                                                                }
                                                        })
                        :Do(function(exp,data)
                                --hmi side: sending VR.AddCommand response
                                self.hmiConnection:SendResponse(data.id, "VR.AddCommand", "SUCCESS", {})
                        end)


                                --mobile side: expect notification
                                EXPECT_NOTIFICATION("OnHashChange")
                                :Times(1)



                        --mobile side: expect response
                        EXPECT_RESPONSE(cid, { success = true, resultCode = "WARNINGS"})
                        :Timeout(12000)

                        DelayedExp()

end


                --Description: check VR response with "WARNINGS"

                --Requirement in JIRA: APPLINK-15051, APPLINK-10501

                --Verification criteria: In case SDL receives WARNINGS result code from HMI -> SDL must transfer WARNINGS (success:true) to mobile app



                function Test:AddCommand_VR_WARNINGS_Response ()

                        --mobile side: sending AddCommand request
                                local cid = self.mobileSession:SendRPC("AddCommand",
                                        {
                                                                                                                cmdID = 2,
                                                                                                                menuParams =
                                                                                                                {
                                                                                                                        menuName ="Command2"
                                                                                                                },
                                                                                                                vrCommands =
                                                                                                                {
                                                                                                                       "synonym3","synonym4"
                                                                                                                }
                                                                                                        })
                        --hmi side: expect UI.AddCommand request
                        EXPECT_HMICALL("UI.AddCommand",
                                                        {
                                                                cmdID = 2,
                                                                menuParams =
                                                                {
                                                                        menuName ="Command2"
                                                                }
                                                        })
                        :Do(function(exp,data)
                                --hmi side: send UI.AddCommand response
                                self.hmiConnection:SendResponse(data.id, "UI.AddCommand", "SUCCESS", {})
                        end)

                        --hmi side: expect VR.AddCommand request
                        EXPECT_HMICALL("VR.AddCommand",
                                                        {
                                                                cmdID = 2,
                                                                type = "Command",
                                                                vrCommands =
                                                                {
                                                                        "synonym3","synonym4"
                                                                }
                                                        })
                        :Do(function(exp,data)
                                --hmi side: sending VR.AddCommand response
                                self.hmiConnection:SendError(data.id, "VR.AddCommand", "WARNINGS", "Error")
                        end)


                                --mobile side: expect notification
                                EXPECT_NOTIFICATION("OnHashChange")
                                :Times(1)



                        --mobile side: expect response
                        EXPECT_RESPONSE(cid, { success = true, resultCode = "WARNINGS"})
                        :Timeout(12000)

                        DelayedExp()

end



                --Description: check VR and UI response with "WARNINGS"

                --Requirement in JIRA: APPLINK-15051, APPLINK-10501

                --Verification criteria: In case SDL receives WARNINGS result code from HMI -> SDL must transfer WARNINGS (success:true) to mobile app


                function Test:AddCommand_UI_VR_WARNINGS_Response ()

                        --mobile side: sending AddCommand request
                                local cid = self.mobileSession:SendRPC("AddCommand",
                                        {
                                                                                                                cmdID = 3,
                                                                                                                menuParams =
                                                                                                                {
                                                                                                                        menuName ="Command3"
                                                                                                                },
                                                                                                                vrCommands =
                                                                                                                {
                                                                                                                       "synonym5","synonym6"
                                                                                                                }
                                                                                                        })
                        --hmi side: expect UI.AddCommand request
                        EXPECT_HMICALL("UI.AddCommand",
                                                        {
                                                                cmdID = 3,
                                                                menuParams =
                                                                {
                                                                        menuName ="Command3"
                                                                }
                                                        })
                        :Do(function(exp,data)
                                --hmi side: send UI.AddCommand response
                                self.hmiConnection:SendError(data.id, "UI.AddCommand", "WARNINGS", "Error Messages")
                        end)

                        --hmi side: expect VR.AddCommand request
                        EXPECT_HMICALL("VR.AddCommand",
                                                        {
                                                                cmdID = 3,
                                                                type = "Command",
                                                                vrCommands =
                                                                {
                                                                        "synonym5","synonym6"
                                                                }
                                                        })
                        :Do(function(exp,data)
                                --hmi side: sending VR.AddCommand response
                                self.hmiConnection:SendError(data.id, "VR.AddCommand", "WARNINGS", "Error")
                        end)


                                --mobile side: expect notification
                                EXPECT_NOTIFICATION("OnHashChange")
                                :Times(1)



                        --mobile side: expect response
                        EXPECT_RESPONSE(cid, { success = true, resultCode = "WARNINGS"})
                        :Timeout(12000)

                        DelayedExp()

end


                --Description: check only UI sent and respond with "WARNINGS"

                --Requirement in JIRA: APPLINK-15051, APPLINK-10501

                --Verification criteria: In case SDL receives WARNINGS result code from HMI -> SDL must transfer WARNINGS (success:true) to mobile app


                function Test:AddCommand_only_UI_WARNINGS_Response ()

                        --mobile side: sending AddCommand request
                                local cid = self.mobileSession:SendRPC("AddCommand",
                                        {
                                                                                                                cmdID = 4,
                                                                                                                menuParams =
                                                                                                                {
                                                                                                                        menuName ="Command4"
                                                                                                                }
                                                                                                        })
                        --hmi side: expect UI.AddCommand request
                        EXPECT_HMICALL("UI.AddCommand",
                                                        {
                                                                cmdID = 4,
                                                                menuParams =
                                                                {
                                                                        menuName ="Command4"
                                                                }
                                                        })
                        :Do(function(exp,data)
                                --hmi side: send UI.AddCommand response
                                self.hmiConnection:SendError(data.id, "UI.AddCommand", "WARNINGS", "Error Messages")
                        end)


                                --mobile side: expect notification
                                EXPECT_NOTIFICATION("OnHashChange")
                                :Times(1)



                        --mobile side: expect response
                        EXPECT_RESPONSE(cid, { success = true, resultCode = "WARNINGS", info = "Error Messages"})
                        :Timeout(12000)

                        DelayedExp()

end


                --Description: check only VR sent and respond with "WARNINGS"

                --Requirement in JIRA: APPLINK-15051, APPLINK-10501

                --Verification criteria: In case SDL receives WARNINGS result code from HMI -> SDL must transfer WARNINGS (success:true) to mobile app


                function Test:AddCommand_only_VR_WARNINGS_Response ()

                        --mobile side: sending AddCommand request
                                local cid = self.mobileSession:SendRPC("AddCommand",
                                        {
                                                                                                                cmdID = 5,
                                                                                                                vrCommands =
                                                                                                                {
                                                                                                                       "synonym7","synonym8"
                                                                                                                }
                                        })

                        --hmi side: expect VR.AddCommand request
                        EXPECT_HMICALL("VR.AddCommand",
                                                        {
                                                                cmdID = 5,
                                                                type = "Command",
                                                                vrCommands =
                                                                {
                                                                        "synonym7","synonym8"
                                                                }
                                                        })
                        :Do(function(exp,data)
                                --hmi side: sending VR.AddCommand response
                                self.hmiConnection:SendError(data.id, "VR.AddCommand", "WARNINGS", "Error")
                        end)


                                --mobile side: expect notification
                                EXPECT_NOTIFICATION("OnHashChange")
                                :Times(1)



                        --mobile side: expect response
                        EXPECT_RESPONSE(cid, { success = true, resultCode = "WARNINGS", info = "Error"})
                        :Timeout(12000)

                        DelayedExp()

end

                ----------------------------------------------------------------------------------------------
                ----------------------------------------2 TEST BLOCK------------------------------------------
                -------------------------Check "WARNINGS" result code for DeleteCommand RPC----------------------
                ----------------------------------------------------------------------------------------------

                --------Checks-----------
                -- сheck all possible combinations of "WARNINGS" result code from HMI

                --Description: check UI response with "WARNINGS"

                --Requirement in JIRA: APPLINK-15036, APPLINK-15210

                --Verification criteria: In case SDL receives WARNINGS result code from HMI -> SDL must transfer WARNINGS (success:true) to mobile app



                --Precondition send AddCommand rpc

                          function Test:AddCommand_Precondition()

                        --mobile side: sending AddCommand request
                                local cid = self.mobileSession:SendRPC("AddCommand",
                                        {
                                                                                                                cmdID = 6,
                                                                                                                menuParams =
                                                                                                                {
                                                                                                                        menuName ="Command6"
                                                                                                                },
                                                                                                                vrCommands =
                                                                                                                {
                                                                                                                       "synonym9","synonym10"
                                                                                                                }
                                                                                                        })
                        --hmi side: expect UI.AddCommand request
                        EXPECT_HMICALL("UI.AddCommand",
                                                        {
                                                                cmdID = 6,
                                                                menuParams =
                                                                {
                                                                        menuName ="Command6"
                                                                }
                                                        })
                        :Do(function(exp,data)
                                --hmi side: send UI.AddCommand response
                                self.hmiConnection:SendResponse(data.id, "UI.AddCommand", "SUCCESS", {})
                        end)

                        --hmi side: expect VR.AddCommand request
                        EXPECT_HMICALL("VR.AddCommand",
                                                        {
                                                                cmdID = 6,
                                                                type = "Command",
                                                                vrCommands =
                                                                {
                                                                        "synonym9","synonym10"
                                                                }
                                                        })
                        :Do(function(exp,data)
                                --hmi side: sending VR.AddCommand response
                                self.hmiConnection:SendResponse(data.id, "VR.AddCommand", "SUCCESS", {})
                        end)


                                --mobile side: expect notification
                                EXPECT_NOTIFICATION("OnHashChange")
                                :Times(1)



                        --mobile side: expect response
                        EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
                        :Timeout(12000)

                        DelayedExp()

end

                       --Start test case:

                                        function Test:DeleteCommand_UI_WARNINGS()
                                                --mobile side: sending DeleteCommand request
                                                local cid = self.mobileSession:SendRPC("DeleteCommand",
                                                {
                                                        cmdID = 6
                                                })

                                                --hmi side: expect UI.DeleteCommand request
                                                EXPECT_HMICALL("UI.DeleteCommand",
                                                {
                                                        cmdID = 6
                                                })
                                                :Do(function(_,data)
                                                        --hmi side: sending UI.DeleteCommand response
                                                        self.hmiConnection:SendError(data.id, data.method, "WARNINGS", "ERROR")
                                                end)

                                                --hmi side: expect VR.DeleteCommand request
                                                EXPECT_HMICALL("VR.DeleteCommand",
                                                {
                                                        cmdID = 6
                                                })
                                                :Do(function(_,data)
                                                        --hmi side: sending VR.DeleteCommand response
                                                        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
                                                end)

                                                --mobile side: expect notification
                                                EXPECT_NOTIFICATION("OnHashChange")
                                                :Times(1)

                                                --mobile side: expect DeleteCommand response
                                                EXPECT_RESPONSE(cid, { success = true, resultCode = "WARNINGS" })
                                        end






                --Description: check VR response with "WARNINGS"

                --Requirement in JIRA: APPLINK-15036, APPLINK-15210

                --Verification criteria: In case SDL receives WARNINGS result code from HMI -> SDL must transfer WARNINGS (success:true) to mobile app



                --Precondition send AddCommand rpc

                          function Test:AddCommand_Precondition()

                        --mobile side: sending AddCommand request
                                local cid = self.mobileSession:SendRPC("AddCommand",
                                        {
                                                                                                                cmdID = 7,
                                                                                                                menuParams =
                                                                                                                {
                                                                                                                        menuName ="Command7"
                                                                                                                },
                                                                                                                vrCommands =
                                                                                                                {
                                                                                                                       "synonym11","synonym12"
                                                                                                                }
                                                                                                        })
                        --hmi side: expect UI.AddCommand request
                        EXPECT_HMICALL("UI.AddCommand",
                                                        {
                                                                cmdID = 7,
                                                                menuParams =
                                                                {
                                                                        menuName ="Command7"
                                                                }
                                                        })
                        :Do(function(exp,data)
                                --hmi side: send UI.AddCommand response
                                self.hmiConnection:SendResponse(data.id, "UI.AddCommand", "SUCCESS", {})
                        end)

                        --hmi side: expect VR.AddCommand request
                        EXPECT_HMICALL("VR.AddCommand",
                                                        {
                                                                cmdID = 7,
                                                                type = "Command",
                                                                vrCommands =
                                                                {
                                                                        "synonym11","synonym12"
                                                                }
                                                        })
                        :Do(function(exp,data)
                                --hmi side: sending VR.AddCommand response
                                self.hmiConnection:SendResponse(data.id, "VR.AddCommand", "SUCCESS", {})
                        end)


                                --mobile side: expect notification
                                EXPECT_NOTIFICATION("OnHashChange")
                                :Times(1)



                        --mobile side: expect response
                        EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
                        :Timeout(12000)

                        DelayedExp()

end

                       --Start test case:

                                        function Test:DeleteCommand_VR_WARNINGS()
                                                --mobile side: sending DeleteCommand request
                                                local cid = self.mobileSession:SendRPC("DeleteCommand",
                                                {
                                                        cmdID = 7
                                                })

                                                --hmi side: expect UI.DeleteCommand request
                                                EXPECT_HMICALL("UI.DeleteCommand",
                                                {
                                                        cmdID = 7
                                                })
                                                :Do(function(_,data)
                                                        --hmi side: sending UI.DeleteCommand response
                                                        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
                                                end)

                                                --hmi side: expect VR.DeleteCommand request
                                                EXPECT_HMICALL("VR.DeleteCommand",
                                                {
                                                        cmdID = 7
                                                })
                                                :Do(function(_,data)
                                                        --hmi side: sending VR.DeleteCommand response
                                                        self.hmiConnection:SendError(data.id, data.method, "WARNINGS", "OOOPS")
                                                end)

                                               --mobile side: expect notification
                                               EXPECT_NOTIFICATION("OnHashChange")
                                               :Times(1)

                                                --mobile side: expect DeleteCommand response
                                                EXPECT_RESPONSE(cid, { success = true, resultCode = "WARNINGS", info = "OOPS" })
                                        end

                --Description: check VR and UI response with "WARNINGS"

                --Requirement in JIRA: APPLINK-15036, APPLINK-15210

                --Verification criteria: In case SDL receives WARNINGS result code from HMI -> SDL must transfer WARNINGS (success:true) to mobile app


                --Precondition send AddCommand rpc

                          function Test:AddCommand_Precondition()

                        --mobile side: sending AddCommand request
                                local cid = self.mobileSession:SendRPC("AddCommand",
                                        {
                                                                                                                cmdID = 8,
                                                                                                                menuParams =
                                                                                                                {
                                                                                                                        menuName ="Command8"
                                                                                                                },
                                                                                                                vrCommands =
                                                                                                                {
                                                                                                                       "synonym13","synonym14"
                                                                                                                }
                                                                                                        })
                        --hmi side: expect UI.AddCommand request
                        EXPECT_HMICALL("UI.AddCommand",
                                                        {
                                                                cmdID = 8,
                                                                menuParams =
                                                                {
                                                                        menuName ="Command8"
                                                                }
                                                        })
                        :Do(function(exp,data)
                                --hmi side: send UI.AddCommand response
                                self.hmiConnection:SendResponse(data.id, "UI.AddCommand", "SUCCESS", {})
                        end)

                        --hmi side: expect VR.AddCommand request
                        EXPECT_HMICALL("VR.AddCommand",
                                                        {
                                                                cmdID = 8,
                                                                type = "Command",
                                                                vrCommands =
                                                                {
                                                                        "synonym13","synonym14"
                                                                }
                                                        })
                        :Do(function(exp,data)
                                --hmi side: sending VR.AddCommand response
                                self.hmiConnection:SendResponse(data.id, "VR.AddCommand", "SUCCESS", {})
                        end)


                                --mobile side: expect notification
                                EXPECT_NOTIFICATION("OnHashChange")
                                :Times(1)



                        --mobile side: expect response
                        EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
                        :Timeout(12000)

                        DelayedExp()

end

                       --Start test case:
                       function Test:DeleteCommand_VR_UI_WARNINGS()
                               --mobile side: sending DeleteCommand request
                               local cid = self.mobileSession:SendRPC("DeleteCommand",
                               {
                                       cmdID = 8
                               })

                               --hmi side: expect UI.DeleteCommand request
                               EXPECT_HMICALL("UI.DeleteCommand",
                               {
                                       cmdID = 8
                               })
                               :Do(function(_,data)
                                       --hmi side: sending UI.DeleteCommand response
                                       self.hmiConnection:SendError(data.id, data.method, "WARNINGS", "UUUUPS")
                               end)

                               --hmi side: expect VR.DeleteCommand request
                               EXPECT_HMICALL("VR.DeleteCommand",
                               {
                                       cmdID = 8
                               })
                               :Do(function(_,data)
                                       --hmi side: sending VR.DeleteCommand response
                                       self.hmiConnection:SendError(data.id, data.method, "WARNINGS", "OOOPS")
                               end)


                               --mobile side: expect notification
                               EXPECT_NOTIFICATION("OnHashChange")
                               :Times(1)


                               --mobile side: expect DeleteCommand response
                               EXPECT_RESPONSE(cid, { success = true, resultCode = "WARNINGS" })
                       end



                --Description: check only UI send and respond with "WARNINGS"

                --Requirement in JIRA: APPLINK-15036, APPLINK-15210

                --Verification criteria: In case SDL receives WARNINGS result code from HMI -> SDL must transfer WARNINGS (success:true) to mobile app


                --Precondition send AddCommand rpc

                          function Test:AddCommand_Precondition()

                        --mobile side: sending AddCommand request
                                local cid = self.mobileSession:SendRPC("AddCommand",
                                        {
                                                                                                                cmdID = 9,
                                                                                                                menuParams =
                                                                                                                {
                                                                                                                        menuName ="Command9"
                                                                                                                }
                                                                                                        })
                        --hmi side: expect UI.AddCommand request
                        EXPECT_HMICALL("UI.AddCommand",
                                                        {
                                                                cmdID = 9,
                                                                menuParams =
                                                                {
                                                                        menuName ="Command9"
                                                                }
                                                        })
                        :Do(function(exp,data)
                                --hmi side: send UI.AddCommand response
                                self.hmiConnection:SendResponse(data.id, "UI.AddCommand", "SUCCESS", {})
                        end)


                                --mobile side: expect notification
                                EXPECT_NOTIFICATION("OnHashChange")
                                :Times(1)



                        --mobile side: expect response
                        EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
                        :Timeout(12000)

                        DelayedExp()

end

                       --Start test case:
                       function Test:DeleteCommand_only_UI_WARNINGS()
                               --mobile side: sending DeleteCommand request
                               local cid = self.mobileSession:SendRPC("DeleteCommand",
                               {
                                       cmdID = 9
                               })

                               --hmi side: expect UI.DeleteCommand request
                               EXPECT_HMICALL("UI.DeleteCommand",
                               {
                                       cmdID = 9
                               })
                               :Do(function(_,data)
                                       --hmi side: sending UI.DeleteCommand response
                                       self.hmiConnection:SendError(data.id, data.method, "WARNINGS", "ui error")
                               end)

                               --mobile side: expect notification
                               EXPECT_NOTIFICATION("OnHashChange")
                               :Times(1)


                               --mobile side: expect DeleteCommand response
                               EXPECT_RESPONSE(cid, { success = true, resultCode = "WARNINGS", info = "ui error"})
                       end


                --Description: check only VR send and respond with "WARNINGS"

                --Requirement in JIRA: APPLINK-15036, APPLINK-15210

                --Verification criteria: In case SDL receives WARNINGS result code from HMI -> SDL must transfer WARNINGS (success:true) to mobile app


                          function Test:AddCommand_Precondition()

                        --mobile side: sending AddCommand request
                                local cid = self.mobileSession:SendRPC("AddCommand",
                                        {
                                                                                                                cmdID = 10,
                                                                                                                vrCommands =
                                                                                                                {
                                                                                                                       "synonym15","synonym16"
                                                                                                                }
                                                                                                        })

                        --hmi side: expect VR.AddCommand request
                        EXPECT_HMICALL("VR.AddCommand",
                                                        {
                                                                cmdID = 10,
                                                                type = "Command",
                                                                vrCommands =
                                                                {
                                                                        "synonym15","synonym16"
                                                                }
                                                        })
                        :Do(function(exp,data)
                                --hmi side: sending VR.AddCommand response
                                self.hmiConnection:SendResponse(data.id, "VR.AddCommand", "SUCCESS", {})
                        end)


                                --mobile side: expect notification
                                EXPECT_NOTIFICATION("OnHashChange")
                                :Times(1)


                        --mobile side: expect response
                        EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
                        :Timeout(12000)

                        DelayedExp()

end

                       --Start test case:
                       function Test:DeleteCommand_only_VR_WARNINGS()
                               --mobile side: sending DeleteCommand request
                               local cid = self.mobileSession:SendRPC("DeleteCommand",
                               {
                                       cmdID = 10
                               })


                               --hmi side: expect VR.DeleteCommand request
                               EXPECT_HMICALL("VR.DeleteCommand",
                               {
                                       cmdID = 10
                               })
                               :Do(function(_,data)
                                       --hmi side: sending VR.DeleteCommand response
                                       self.hmiConnection:SendError(data.id, data.method, "WARNINGS", "some warnings")
                               end)


                               --mobile side: expect notification
                               EXPECT_NOTIFICATION("OnHashChange")
                               :Times(1)


                               --mobile side: expect DeleteCommand response
                               EXPECT_RESPONSE(cid, { success = true, resultCode = "WARNINGS", info = "some warnings" })
                       end

                ----------------------------------------------------------------------------------------------
                ----------------------------------------3 TEST BLOCK------------------------------------------
                ----------------Check "WARNINGS" result code for CreateInteractionChoiceSet RPC--------------
                ----------------------------------------------------------------------------------------------

                --------Checks-----------

                --Description: check only one VR.AddCommands (VR-related choices) were sent and respond with "WARNINGS"

                --Requirement in JIRA: APPLINK-15261, APPLINK-15036

                --Verification criteria: In case app sends CreateInteractionChoiceSet AND SDL gets WARNINGS at least to one or more of corresponding VR.AddCommands (VR-related choices) from HMI -> SDL must respond WARNINGS (success:true) to mobile app


                        function Test:CreateInteractionChoiceSet_1_VR_in_choice()
                                        --mobile side: sending CreateInteractionChoiceSet request
                                        local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
                                                                                                                        {
                                                                                                                                interactionChoiceSetID = 1001,
                                                                                                                                choiceSet =
                                                                                                                                {

                                                                                                                                        {
                                                                                                                                                choiceID = 1001,
                                                                                                                                                menuName ="Choice1001",
                                                                                                                                                vrCommands =
                                                                                                                                                {
                                                                                                                                                        "Choice1001",
                                                                                                                                                },
                                                                                                                                                image =
                                                                                                                                                {
                                                                                                                                                        value ="icon.png",
                                                                                                                                                        imageType ="DYNAMIC",
                                                                                                                                                },
                                                                                                                                        }
                                                                                                                                }
                                                                                                                        })


                                        --hmi side: expect VR.AddCommand request
                                        EXPECT_HMICALL("VR.AddCommand",
                                                                        {
                                                                                cmdID = 1001,
                                                                                appID = applicationID,
                                                                                type = "Choice",
                                                                                vrCommands = {"Choice1001" }
                                                                        })
                                        :Do(function(_,data)
                                                --hmi side: sending VR.AddCommand response
                                                grammarIDValue = data.params.grammarID
                                                self.hmiConnection:SendError(data.id, data.method, "WARNINGS", "blabla")
                                        end)

                                        --mobile side: expect CreateInteractionChoiceSet response
                                        EXPECT_RESPONSE(cid, { success = true, resultCode = "WARNINGS" })

                                        --mobile side: expect OnHashChange notification
                                        EXPECT_NOTIFICATION("OnHashChange")
                                end


                --Description: check one of VR.AddCommands (VR-related choices) respond with "WARNINGS" when 1 choiceSet with numerous VR-related choices were sent

                --Requirement in JIRA: APPLINK-15261, APPLINK-15036

                --Verification criteria: In case app sends CreateInteractionChoiceSet AND SDL gets WARNINGS at least to one or more of corresponding VR.AddCommands (VR-related choices) from HMI -> SDL m

                        function Test:CreateInteractionChoiceSet_several_VR_in_choice()
                                        --mobile side: sending CreateInteractionChoiceSet request
                                        local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
                                                                                                                        {
                                                                                                                                interactionChoiceSetID = 1002,
                                                                                                                                choiceSet =
                                                                                                                                {

                                                                                                                                        {
                                                                                                                                                choiceID = 1002,
                                                                                                                                                menuName ="Choice1002",
                                                                                                                                                vrCommands =
                                                                                                                                                {
                                                                                                                                                        "Choice1002"
                                                                                                                                                },
                                                                                                                                                image =
                                                                                                                                                {
                                                                                                                                                        value ="icon.png",
                                                                                                                                                        imageType ="DYNAMIC"
                                                                                                                                                }
                                                                                                                                        },
                                                                                                                                        {
                                                                                                                                                 choiceID = 1003,
                                                                                                                                                 menuName ="Choice1003",
                                                                                                                                                 vrCommands =
                                                                                                                                                 {
                                                                                                                                                          "Choice1003"
                                                                                                                                                 },
                                                                                                                                                 image =
                                                                                                                                                 {
                                                                                                                                                           value ="icon.png",
                                                                                                                                                           imageType ="DYNAMIC"
                                                                                                                                                 }
                                                                                                                                        },
                                                                                                                                        {
                                                                                                                                                  choiceID = 1004,
                                                                                                                                                  menuName ="Choice1004",
                                                                                                                                                  vrCommands =
                                                                                                                                                      {
                                                                                                                                                              "Choice1004"
                                                                                                                                                      },
                                                                                                                                                  image =
                                                                                                                                                      {
                                                                                                                                                          value ="icon.png",
                                                                                                                                                          imageType ="DYNAMIC"
                                                                                                                                                      }
                                                                                                                                         },
                                                                                                                                         {
                                                                                                                                                  choiceID = 1005,
                                                                                                                                                  menuName ="Choice1005",
                                                                                                                                                  vrCommands =
                                                                                                                                                      {
                                                                                                                                                         "Choice1005"
                                                                                                                                                      },
                                                                                                                                                  image =
                                                                                                                                                      {
                                                                                                                                                          value ="icon.png",
                                                                                                                                                          imageType ="DYNAMIC"
                                                                                                                                                      }
                                                                                                                                         }
                                                                                                                                }
                                                                                                                        })


                                        --hmi side: expect VR.AddCommand request
                                        EXPECT_HMICALL("VR.AddCommand",
                                                                        {
                                                                                cmdID = 1002,
                                                                                appID = applicationID,
                                                                                type = "Choice",
                                                                                vrCommands = {"Choice1002" }
                                                                        },
                                                                        {
                                                                                cmdID = 1003,
                                                                                appID = applicationID,
                                                                                type = "Choice",
                                                                                vrCommands = {"Choice1003" }
                                                                        },
                                                                        {
                                                                                cmdID = 1004,
                                                                                appID = applicationID,
                                                                                type = "Choice",
                                                                                vrCommands = {"Choice1004" }
                                                                        },
                                                                        {
                                                                                cmdID = 1005,
                                                                                appID = applicationID,
                                                                                type = "Choice",
                                                                                vrCommands = {"Choice1005" }
                                                                        })
                                                                        :Times(4)

                                        :Do(function(exp,data)
                                                --hmi side: sending VR.AddCommand response

                                                if exp.occurences == 1 or exp.occurences == 2 or exp.occurences == 3 then
                                                              self.hmiConnection:SendResponse(data.id,"VR.AddCommand", "SUCCESS", {})

                                                elseif exp.occurences == 4 then
                                                        self.hmiConnection:SendError(data.id,"VR.AddCommand", "WARNINGS", "blablaus")

                                             end
                                        end)

                                        --mobile side: expect CreateInteractionChoiceSet response
                                        EXPECT_RESPONSE(cid, { success = true, resultCode = "WARNINGS" })

                                        --mobile side: expect OnHashChange notification
                                        EXPECT_NOTIFICATION("OnHashChange")
                                end



                ----------------------------------------------------------------------------------------------
                ----------------------------------------4 TEST BLOCK------------------------------------------
                ----------------Check "WARNINGS" result code for DeleteInteractionChoiceSet RPC--------------
                ----------------------------------------------------------------------------------------------

                --------Checks-----------

                --Description: Check that SDL respond with DeleteInteractionChoiceSet(WARNINGS, success:true) when HMI respond with WARNINGS (only one VR command present in ChoiceSet)

                --Requirement in JIRA: APPLINK-14600, APPLINK-15036

                --Verification criteria: In case SDL receives WARNINGS result code from HMI -> SDL must transfer WARNINGS (success:true) to mobile app


                --Precondition: send CreateInteractionChoiceSet with 1 VR in Choice

                        function Test:CreateInteractionChoiceSet_Precondition_1_VR_in_choice()
                                        --mobile side: sending CreateInteractionChoiceSet request
                                        local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
                                                                                                                        {
                                                                                                                                interactionChoiceSetID = 1006,
                                                                                                                                choiceSet =
                                                                                                                                {

                                                                                                                                        {
                                                                                                                                                choiceID = 1006,
                                                                                                                                                menuName ="Choice1006",
                                                                                                                                                vrCommands =
                                                                                                                                                {
                                                                                                                                                        "Choice1006",
                                                                                                                                                },
                                                                                                                                                image =
                                                                                                                                                {
                                                                                                                                                        value ="icon.png",
                                                                                                                                                        imageType ="DYNAMIC",
                                                                                                                                                },
                                                                                                                                        }
                                                                                                                                }
                                                                                                                        })


                                        --hmi side: expect VR.AddCommand request
                                        EXPECT_HMICALL("VR.AddCommand",
                                                                        {
                                                                                cmdID = 1006,
                                                                                appID = applicationID,
                                                                                type = "Choice",
                                                                                vrCommands = {"Choice1006" }
                                                                        })
                                        :Do(function(_,data)
                                                --hmi side: sending VR.AddCommand response
                                                grammarIDValue = data.params.grammarID
                                                self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
                                        end)

                                        --mobile side: expect CreateInteractionChoiceSet response
                                        EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

                                        --mobile side: expect OnHashChange notification
                                        EXPECT_NOTIFICATION("OnHashChange")
                                end


                        -- Start Test case:
                                function Test:DeleteInteractionChoiceSet_1_VR_in_Choice()
                                --mobile side: sending DeleteInteractionChoiceSet request
                                local cid = self.mobileSession:SendRPC("DeleteInteractionChoiceSet",
                                                                                                {
                                                                                                interactionChoiceSetID = 1006
                                                                                                })

                                --hmi side: expect VR.DeleteCommand request
                                EXPECT_HMICALL("VR.DeleteCommand",
                                                        {cmdID = 1006, type = "Choice"})
                                :Times(1)
                                :Do(function(_,data)
                                        --hmi side: sending VR.DeleteCommand response
                                        self.hmiConnection:SendError(data.id, data.method, "WARNINGS", "Some error occurs")
                                end)

                                --mobile side: expect DeleteInteractionChoiceSet response
                                EXPECT_RESPONSE(cid, { success = true, resultCode = "WARNINGS", info = "Some error occurs" })
                        end


                --Description: Check that SDL respond with DeleteInteractionChoiceSet(WARNINGS, success:true) when HMI respond with WARNINGS (several VR commands present in ChoiceSet)

                --Requirement in JIRA: APPLINK-14600, APPLINK-15036

                --Verification criteria: In case SDL receives WARNINGS result code from HMI -> SDL must transfer WARNINGS (success:true) to mobile app


                --Precondition: send CreateInteractionChoiceSet with several VR in Choice

                       function Test:CreateInteractionChoiceSet_Precondition_several_VR_in_choice()
                                        --mobile side: sending CreateInteractionChoiceSet request
                                        local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
                                                                                                                        {
                                                                                                                                interactionChoiceSetID = 1007,
                                                                                                                                choiceSet =
                                                                                                                                {

                                                                                                                                        {
                                                                                                                                                choiceID = 1007,
                                                                                                                                                menuName ="Choice1007",
                                                                                                                                                vrCommands =
                                                                                                                                                {
                                                                                                                                                        "Choice1007"
                                                                                                                                                },
                                                                                                                                                image =
                                                                                                                                                {
                                                                                                                                                        value ="icon.png",
                                                                                                                                                        imageType ="DYNAMIC"
                                                                                                                                                }
                                                                                                                                        },
                                                                                                                                        {
                                                                                                                                                 choiceID = 1008,
                                                                                                                                                 menuName ="Choice1008",
                                                                                                                                                 vrCommands =
                                                                                                                                                 {
                                                                                                                                                          "Choice1008"
                                                                                                                                                 },
                                                                                                                                                 image =
                                                                                                                                                 {
                                                                                                                                                           value ="icon.png",
                                                                                                                                                           imageType ="DYNAMIC"
                                                                                                                                                 }
                                                                                                                                        },
                                                                                                                                        {
                                                                                                                                                  choiceID = 1009,
                                                                                                                                                  menuName ="Choice1009",
                                                                                                                                                  vrCommands =
                                                                                                                                                      {
                                                                                                                                                              "Choice1009"
                                                                                                                                                      },
                                                                                                                                                  image =
                                                                                                                                                      {
                                                                                                                                                          value ="icon.png",
                                                                                                                                                          imageType ="DYNAMIC"
                                                                                                                                                      }
                                                                                                                                         },
                                                                                                                                         {
                                                                                                                                                  choiceID = 1010,
                                                                                                                                                  menuName ="Choice1010",
                                                                                                                                                  vrCommands =
                                                                                                                                                      {
                                                                                                                                                         "Choice1010"
                                                                                                                                                      },
                                                                                                                                                  image =
                                                                                                                                                      {
                                                                                                                                                          value ="icon.png",
                                                                                                                                                          imageType ="DYNAMIC"
                                                                                                                                                      }
                                                                                                                                         }
                                                                                                                                }
                                                                                                                        })


                                        --hmi side: expect VR.AddCommand request
                                        EXPECT_HMICALL("VR.AddCommand",
                                                                        {
                                                                                cmdID = 1007,
                                                                                appID = applicationID,
                                                                                type = "Choice",
                                                                                vrCommands = {"Choice1007" }
                                                                        },
                                                                        {
                                                                                cmdID = 1008,
                                                                                appID = applicationID,
                                                                                type = "Choice",
                                                                                vrCommands = {"Choice1008" }
                                                                        },
                                                                        {
                                                                                cmdID = 1009,
                                                                                appID = applicationID,
                                                                                type = "Choice",
                                                                                vrCommands = {"Choice1009" }
                                                                        },
                                                                        {
                                                                                cmdID = 1010,
                                                                                appID = applicationID,
                                                                                type = "Choice",
                                                                                vrCommands = {"Choice1010" }
                                                                        })
                                                                        :Times(4)

                                        :Do(function(exp,data)
                                                --hmi side: sending VR.AddCommand response

                                                if exp.occurences == 1 or exp.occurences == 2 or exp.occurences == 3 or exp.occurences == 4 then
                                                              self.hmiConnection:SendResponse(data.id,"VR.AddCommand", "SUCCESS", {})

                                             end
                                        end)

                                        --mobile side: expect CreateInteractionChoiceSet response
                                        EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

                                        --mobile side: expect OnHashChange notification
                                        EXPECT_NOTIFICATION("OnHashChange")
                                end

                              --Start test case:

                           function Test:DeleteInteractionChoiceSet_several_VR_in_choice()
                                      --mobile side: sending DeleteInteractionChoiceSet request
                                      local cid = self.mobileSession:SendRPC("DeleteInteractionChoiceSet",
                                                                                                                          {
                                                                                                                          interactionChoiceSetID = 1007
                                                                                                                          })

                                      --hmi side: expect VR.DeleteCommand request
                                      EXPECT_HMICALL("VR.DeleteCommand",
                                                              {cmdID = 1007, type = "Choice"},
                                                              {cmdID = 1008, type = "Choice"},
                                                              {cmdID = 1009, type = "Choice"},
                                                              {cmdID = 1010, type = "Choice"}
                                                    )
                                    :Times(4)
                                    :Do(function(exp,data)
                                                   --hmi side: sending VR.AddCommand response

                                                      if exp.occurences == 1 or exp.occurences == 2 or exp.occurences == 3 then
                                                                    self.hmiConnection:SendResponse(data.id,data.method, "SUCCESS", {})

                                                      elseif exp.occurences == 4 then
                                                              self.hmiConnection:SendError(data.id,data.method, "WARNINGS", "Another one petite error")

                                                   end


                                      end)

                                      --mobile side: expect DeleteInteractionChoiceSet response
                                      EXPECT_RESPONSE(cid, { success = true, resultCode = "WARNINGS", info = "Another one petite error" })
                              end


                ----------------------------------------------------------------------------------------------
                ----------------------------------------5 TEST BLOCK------------------------------------------
                ---------------------------Check "WARNINGS" result code for Show RPC--------------------------
                ----------------------------------------------------------------------------------------------

                --------Checks-----------

                --Description: Check that SDL respond with Show(WARNINGS, success:true) when HMI respond with WARNINGS

                --Requirement in JIRA: APPLINK-15036

                --Verification criteria: In case SDL receives WARNINGS result code from HMI -> SDL must transfer WARNINGS (success:true) to mobile app


                function Test:Show_resultCode_WARNINGS()

                        --mobile side: sending Show request
                        local cid = self.mobileSession:SendRPC("Show",
                                                                                                        {
                                                                                                                mediaClock = "22:22",
                                                                                                                mainField1 = "Text1",
                                                                                                                graphic =
                                                                                                                {
                                                                                                                        value = "icon.png",
                                                                                                                        imageType = "STATIC"
                                                                                                                },
                                                                                                                statusBar = "new status bar",
                                                                                                                mediaTrack = "Track1"
                                                                                                        })
                        --hmi side: expect UI.Show request
                        EXPECT_HMICALL("UI.Show",
                                                        {
                                                                showStrings =
                                                                {
                                                                        {
                                                                        fieldName = "mainField1",
                                                                        fieldText = "Text1"
                                                                        },
                                                                        {
                                                                        fieldName = "mediaClock",
                                                                        fieldText = "22:22"
                                                                        },
                                                                        {
                                                                                fieldName = "mediaTrack",
                                                                                fieldText = "Track1"
                                                                        },
                                                                        {
                                                                                fieldName = "statusBar",
                                                                                fieldText = "new status bar"
                                                                        }
                                                                }
                                                        })
                                :Do(function(_,data)
                                        --hmi side: sending UI.Show response
                                        self.hmiConnection:SendError(data.id, data.method, "WARNINGS", "Unsupported STATIC type. Available data in request was processed.")
                                end)

                        --mobile side: expect Show response
                        EXPECT_RESPONSE(cid, { success = true, resultCode = "WARNINGS", info = "Unsupported STATIC type. Available data in request was processed."})

                end



                ----------------------------------------------------------------------------------------------
                ----------------------------------------6 TEST BLOCK------------------------------------------
                ---------------------------Check "WARNINGS" result code for Speak RPC--------------------------
                ----------------------------------------------------------------------------------------------

                --------Checks-----------

                --Description: Check that SDL respond with Speak(WARNINGS, success:true) when HMI respond with WARNINGS

                --Requirement in JIRA: APPLINK-15036

                --Verification criteria: In case SDL receives WARNINGS result code from HMI -> SDL must transfer WARNINGS (success:true) to mobile app

--[[ Under clarifying for speak rpc: Question APPLINK-18454

                    function Test:Speak_resultCode_WARNINGS()

                        --mobile side: sending the request
                        local RequestParams = {
                                        ttsChunks =
                                        {
                                                {
                                                        text ="a",
                                                        type ="LHPLUS_PHONEMES"
                                                }
                                        }
                                }
                        local cid = self.mobileSession:SendRPC("Speak", RequestParams)

                        --hmi side: expect the request
                        local TTSParams = self:createTTSParameters(RequestParams)
                        EXPECT_HMICALL("TTS.Speak", TTSParams)
                        :Do(function(exp,data)
                                --hmi side: sending the response
                                self.hmiConnection:SendResponse(data.id, data.method, "WARNINGS", {info = "LHPLUS_PHONEMES"})
                        end)

                        --mobile side: expect response
                        EXPECT_RESPONSE(cid, { success = false, resultCode = "WARNINGS", info = "LHPLUS_PHONEMES"})

                end

--]]



                ----------------------------------------------------------------------------------------------
                ----------------------------------------7 TEST BLOCK------------------------------------------
                --------------------------Check "WARNINGS" result code for AddSubMenu RPC---------------------
                ----------------------------------------------------------------------------------------------

                --------Checks-----------

                --Description: Check that SDL respond with AddSubMenu(WARNINGS, success:true) when HMI respond with WARNINGS

                --Requirement in JIRA: APPLINK-15036

                --Verification criteria: In case SDL receives WARNINGS result code from HMI -> SDL must transfer WARNINGS (success:true) to mobile app

                                function Test:AddSubMenu_WARNINGS()
                                        --mobile side: sending AddSubMenu request
                                        local cid = self.mobileSession:SendRPC("AddSubMenu",
                                                                                                                        {
                                                                                                                                menuID = 1000,
                                                                                                                                position = 500,
                                                                                                                                menuName ="SubMenuWARNINGS"
                                                                                                                        })
                                        --hmi side: expect UI.AddSubMenu request
                                        EXPECT_HMICALL("UI.AddSubMenu",
                                                                        {
                                                                                menuID = 1000,
                                                                                menuParams = {
                                                                                        position = 500,
                                                                                        menuName ="SubMenuWARNINGS"
                                                                                }
                                                                        })
                                        :Do(function(_,data)
                                                --hmi side: sending UI.AddSubMenu response
                                                self.hmiConnection:SendError(data.id, data.method, "WARNINGS", "Another one error")
                                        end)

                                        --mobile side: expect AddSubMenu response
                                        EXPECT_RESPONSE(cid, { success = true, resultCode = "WARNINGS" })

                                        --mobile side: expect OnHashChange notification
                                        EXPECT_NOTIFICATION("OnHashChange")
                                end


                ----------------------------------------------------------------------------------------------
                ----------------------------------------8 TEST BLOCK------------------------------------------
                --------------------------Check "WARNINGS" result code for DeleteSubMenu RPC---------------------
                ----------------------------------------------------------------------------------------------

                --------Checks-----------

                --Description: Check that SDL respond with DeleteSubMenu(WARNINGS, success:true) when HMI respond with WARNINGS

                --Requirement in JIRA: APPLINK-15036

                --Verification criteria: In case SDL receives WARNINGS result code from HMI -> SDL must transfer WARNINGS (success:true) to mobile app


                   --Precondition AddSubMenu rpc
                        function Test:AddSubMenu_Precondition()
                                        --mobile side: sending AddSubMenu request
                                        local cid = self.mobileSession:SendRPC("AddSubMenu",
                                                                                                                        {
                                                                                                                                menuID = 1001,
                                                                                                                                position = 500,
                                                                                                                                menuName ="SubMenuPrecondition"
                                                                                                                        })
                                        --hmi side: expect UI.AddSubMenu request
                                        EXPECT_HMICALL("UI.AddSubMenu",
                                                                        {
                                                                                menuID = 1001,
                                                                                menuParams = {
                                                                                        position = 500,
                                                                                        menuName ="SubMenuPrecondition"
                                                                                }
                                                                        })
                                        :Do(function(_,data)
                                                --hmi side: sending UI.AddSubMenu response
                                                self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {} )
                                        end)

                                        --mobile side: expect AddSubMenu response
                                        EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

                                        --mobile side: expect OnHashChange notification
                                        EXPECT_NOTIFICATION("OnHashChange")
                                end

                           -- Start Test case:
                           function Test:DeleteSubMenu_WARNINGS()
                                           --mobile side: sending DeleteSubMenu request
                                           local cid = self.mobileSession:SendRPC("DeleteSubMenu",
                                                                                                                           {
                                                                                                                                   menuID = 1001
                                                                                                                           })
                                           --hmi side: expect UI.DeleteSubMenu request
                                           EXPECT_HMICALL("UI.DeleteSubMenu",
                                                                           {
                                                                                   menuID = 1001
                                                                           })
                                           :Do(function(_,data)
                                                   --hmi side: sending UI.DeleteSubMenu response
                                                   self.hmiConnection:SendError(data.id, data.method, "WARNINGS", "Oh, God, another one")
                                           end)

                                           --mobile side: expect DeleteSubMenu response
                                           EXPECT_RESPONSE(cid, { success = true, resultCode = "WARNINGS" })

                                           --mobile side: expect OnHashChange notification
                                           EXPECT_NOTIFICATION("OnHashChange")
                                   end

                ----------------------------------------------------------------------------------------------
                ----------------------------------------9 TEST BLOCK------------------------------------------
                --------------------------Check "WARNINGS" result code for SetAppIcon---------------------
                ----------------------------------------------------------------------------------------------

                --------Checks-----------

                --Description: Check that SDL respond with SetAppIcon(WARNINGS, success:true) when HMI respond with WARNINGS

                --Requirement in JIRA: APPLINK-15036

                --Verification criteria: In case SDL receives WARNINGS result code from HMI -> SDL must transfer WARNINGS (success:true) to mobile app

                                function Test:SetAppIcon_Warnings()

                                        --mobile side: sending SetAppIcon request
                                        local cid = self.mobileSession:SendRPC("SetAppIcon",
                                                {
                                                        syncFileName = "icon.png"
                                                }
                                        )

                                        --hmi side: expect UI.SetAppIcon request
                                        EXPECT_HMICALL("UI.SetAppIcon",
                                        {
                                                syncFileName =
                                                {
                                                        imageType = "DYNAMIC",
                                                        value = config.pathToSDL .. GetParamValue("AppStorageFolder").."/" .."0000001".. "_" .. config.deviceMAC.. "/" .. "icon.png"
                                                }
                                        })
                                        :Timeout(1000)
                                        :Do(function(_,data)
                                                --hmi side: sending UI.SetAppIcon response
                                                self.hmiConnection:SendError(data.id, data.method, "WARNINGS", "error")
                                        end)


                                        --mobile side: expect SetAppIcon response
                                        EXPECT_RESPONSE(cid, {success = true, resultCode = "WARNINGS"})

                                  end

                ----------------------------------------------------------------------------------------------
                ----------------------------------------10 TEST BLOCK------------------------------------------
                --------------------------Check "WARNINGS" result code for Slider-----------------------------
                ----------------------------------------------------------------------------------------------

                --------Checks-----------

                --Description: Check that SDL respond with Slider(WARNINGS, success:true) when HMI respond with WARNINGS

                --Requirement in JIRA: APPLINK-15036

                --Verification criteria: In case SDL receives WARNINGS result code from HMI -> SDL must transfer WARNINGS (success:true) to mobile app

                        function Test:Slider_Warnings()
                                local cid = self.mobileSession:SendRPC ("Slider",
                                {
                                        numTicks = 7,
                                        position = 6,
                                        sliderHeader ="sliderHeader"
                                }
                                )

                        --hmi side: Slider request
                        EXPECT_HMICALL("UI.Slider",
                        {
                                numTicks = 7,
                                position = 6,
                                sliderHeader ="sliderHeader"
                        }
                        )
                        :Do(function(_,data)
                        --hmi side: sending UI.Slider response
                        self.hmiConnection:SendError(data.id, data.method, "WARNINGS", "Small error")
                        end)

                       --mobile side: expect Slider response
                        EXPECT_RESPONSE(cid, { success = true, resultCode = "WARNINGS" })

                       --[[mobile side: expect OnHMIStatus notification
                        EXPECT_NOTIFICATION("OnHMIStatus",
                                { systemContext = "HMI_OBSCURED", hmiLevel = "FULL", audioStreamingState = "AUDIBLE" },
                                { systemContext = "MAIN",  hmiLevel = "FULL", audioStreamingState = "AUDIBLE" })

                                :Times(2)
                        --Note: Issue - currently, there is no response regarding this notification on SDL log--]]


                        end

                ----------------------------------------------------------------------------------------------
                ---------------------------------------11 TEST BLOCK------------------------------------------
                --------------------------Check "WARNINGS" result code for ScrollableMessage------------------
                ----------------------------------------------------------------------------------------------

                --------Checks-----------

                --Description: Check that SDL respond with ScrollableMessage(WARNINGS, success:true) when HMI respond with WARNINGS

                --Requirement in JIRA: APPLINK-15036

                --Verification criteria: In case SDL receives WARNINGS result code from HMI -> SDL must transfer WARNINGS (success:true) to mobile app

  function Test:ScrollableMessage_Warnings()

        --mobile side: sending the request
        local cid = self.mobileSession:SendRPC("ScrollableMessage",
                                                    { scrollableMessageBody = "MessageBody1"
                                                    }
                                              )

        --hmi side: expect UI.ScrollableMessage request
        EXPECT_HMICALL("UI.ScrollableMessage", {messageText={fieldName="scrollableMessageBody",fieldText="MessageBody1"}}
                      )
        :Do(function(_,data)

                --HMI sends UI.OnSystemContext
                self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "HMI_OBSCURED" })
                scrollableMessageId = data.id

                local function scrollableMessageResponse()

                        --hmi sends response
                        self.hmiConnection:SendError(data.id, "UI.ScrollableMessage", "WARNINGS", "WARNING_ERROR")

                        --HMI sends UI.OnSystemContext
                        self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })
                end
                RUN_AFTER(scrollableMessageResponse, 1000)

        end)


        --mobile side: expect OnHMIStatus notification
        EXPECT_NOTIFICATION("OnHMIStatus",
                        {systemContext = "HMI_OBSCURED", hmiLevel = "FULL", audioStreamingState = "AUDIBLE"},
                        {systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "AUDIBLE"}
        )
        :Times(2)

        --mobile side: expect the response
        EXPECT_RESPONSE(cid, { success = true, resultCode = "WARNINGS" })

end


                ----------------------------------------------------------------------------------------------
                ---------------------------------------12 TEST BLOCK------------------------------------------
                --------------------------Check "WARNINGS" result code for SystemRequest rpc------------------
                ----------------------------------------------------------------------------------------------

                --------Checks-----------

                --Description: Check that SDL respond with SystemRequest(WARNINGS, success:true) when HMI respond with WARNINGS

                --Requirement in JIRA: APPLINK-15036

                --Verification criteria: In case SDL receives WARNINGS result code from HMI -> SDL must transfer WARNINGS (success:true) to mobile app

                function Test:SystemRequest_WARNINGS()

                                local CorIdSystemRequest = self.mobileSession:SendRPC("SystemRequest",
                                        {
                                                fileName = "PolicyTableUpdate",
                                                requestType = "PROPRIETARY"
                                        },
                                "files/ptu_RAI.json")

                                local systemRequestId
                                --hmi side: expect SystemRequest request
                                EXPECT_HMICALL("BasicCommunication.SystemRequest")
                                :Do(function(_,data)
                                        systemRequestId = data.id
                                        print("BasicCommunication.SystemRequest is received")

                                        -- hmi side: sending BasicCommunication.OnSystemRequest request to SDL
                                        self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate",
                                                {
                                                        policyfile = "/tmp/fs/mp/images/ivsu_cache/PolicyTableUpdate"
                                                }
                                        )
                                        function to_run()
                                                --hmi side: sending SystemRequest response
                                                self.hmiConnection:SendError(systemRequestId,"BasicCommunication.SystemRequest", "WARNINGS", "SystemReq Warnings")
                                        end

                                        RUN_AFTER(to_run, 500)
                                end)

                                --[[hmi side: expect SDL.OnStatusUpdate
                                EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", { status =  "UP_TO_DATE"})
                                :Do(function(_,data)
                                        print("SDL.OnStatusUpdate is received")
                                end)
                                :Timeout(4000)--]]

                                --mobile side: expect SystemRequest response
                                EXPECT_RESPONSE(CorIdSystemRequest, { success = true, resultCode = "WARNINGS"})
                                :Do(function(_,data)
                                        print("SystemRequest is received")
                                        --hmi side: sending SDL.GetUserFriendlyMessage request to SDL
                                        local RequestIdGetUserFriendlyMessage = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"StatusUpToDate"}})

                                        --hmi side: expect SDL.GetUserFriendlyMessage response
                                        EXPECT_HMIRESPONSE(RequestIdGetUserFriendlyMessage,{result = {code = 0, method = "SDL.GetUserFriendlyMessage", messages = {{line1 = "Up-To-Date", messageCode = "StatusUpToDate", textBody = "Up-To-Date"}}}})
                                        :Do(function(_,data)
                                                print("SDL.GetUserFriendlyMessage is received")
                                        end)
                                end)
                                :Timeout(2000)


                end


                ----------------------------------------------------------------------------------------------
                ---------------------------------------13 TEST BLOCK------------------------------------------
                --------------------------Check "WARNINGS" result code for AlertManeuer rpc------------------
                ----------------------------------------------------------------------------------------------

                --------Checks-----------

                --Precondition:

                local function ExpectOnHMIStatusWithAudioStateChanged_AlertManeuver(self, request, timeout, level)

    if request == nil then  request = "TTS" end
    if level == nil then  level = "FULL" end
    if timeout == nil then timeout = 10000 end

    if
        self.isMediaApplication == true or
        Test.appHMITypes["NAVIGATION"] == true then
            if request == "TTS" then
                --mobile side: OnHMIStatus notification
                EXPECT_NOTIFICATION("OnHMIStatus",
                            { systemContext = "MAIN", hmiLevel = level, audioStreamingState = "ATTENUATED"    },
                            { systemContext = "MAIN",  hmiLevel = level, audioStreamingState = "AUDIBLE"    })
                    :Times(2)
                    :Timeout(timeout)
            elseif request == "VR" then
                --mobile side: OnHMIStatus notification
                EXPECT_NOTIFICATION("OnHMIStatus",
                            { systemContext = "MAIN", hmiLevel = level, audioStreamingState = "NOT_AUDIBLE"    },
                            { systemContext = "MAIN",  hmiLevel = level, audioStreamingState = "AUDIBLE"    })
                    :Times(2)
                    :Timeout(timeout)
            end
    elseif
        self.isMediaApplication == false then

            --any OnHMIStatusNotifications
            EXPECT_NOTIFICATION("OnHMIStatus")
                :Times(0)
                :Timeout(timeout)

            DelayedExp(1000)
    end

end

-- End Test case

                --Description: check TTS.Speak respond with WARNINGS

                --Requirement in JIRA: APPLINK-15051

                --Verification criteria: In case SDL receives WARNINGS result code from HMI -> SDL must transfer WARNINGS (success:true) to mobile app



                                                function Test:AlertManeuver_TTS_WARNINGS()

                                                        --mobile side: AlertManeuver request
                                                        local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
                                                                                                                                                        {

                                                                                                                                                                ttsChunks =
                                                                                                                                                                {

                                                                                                                                                                        {
                                                                                                                                                                                text ="FirstAlert",
                                                                                                                                                                                type ="TEXT",
                                                                                                                                                                        },

                                                                                                                                                                        {
                                                                                                                                                                                text ="SecondAlert",
                                                                                                                                                                                type ="TEXT",
                                                                                                                                                                        },
                                                                                                                                                                },
                                                                                                                                                                softButtons =
                                                                                                                                                                {

                                                                                                                                                                        {
                                                                                                                                                                                type = "BOTH",
                                                                                                                                                                                text = "Close",
                                                                                                                                                                                 image =

                                                                                                                                                                                {
                                                                                                                                                                                        value = "icon.png",
                                                                                                                                                                                        imageType = "DYNAMIC",
                                                                                                                                                                                },
                                                                                                                                                                                isHighlighted = true,
                                                                                                                                                                                softButtonID = 1,
                                                                                                                                                                                systemAction = "DEFAULT_ACTION",
                                                                                                                                                                        }
                                                                                                                                                                }

                                                                                                                                                        })

                                                        local AlertId
                                                        --hmi side: Navigation.AlertManeuver request
                                                        EXPECT_HMICALL("Navigation.AlertManeuver",
                                                                                        {
                                                                                                softButtons =
                                                                                                {

                                                                                                        {
                                                                                                                type = "BOTH",
                                                                                                                text = "Close",
                                                                                                                 image =

                                                                                                                {
                                                                                                                        value = config.pathToSDL .. "icon.png",
                                                                                                                        imageType = "DYNAMIC",
                                                                                                                },
                                                                                                                isHighlighted = true,
                                                                                                                softButtonID = 1,
                                                                                                                systemAction = "DEFAULT_ACTION",
                                                                                                        }
                                                                                                }
                                                                                        })
                                                                :Do(function(_,data)
                                                                        AlertId = data.id
                                                                        local function alertResponse()
                                                                                self.hmiConnection:SendResponse(AlertId, "Navigation.AlertManeuver", "SUCCESS", { })

                                                                        end

                                                                        RUN_AFTER(alertResponse, 2000)
                                                                end)

                                                        local SpeakId
                                                        --hmi side: TTS.Speak request
                                                        EXPECT_HMICALL("TTS.Speak",
                                                                                        {
                                                                                                ttsChunks =
                                                                                                        {

                                                                                                                {
                                                                                                                        text ="FirstAlert",
                                                                                                                        type ="TEXT",
                                                                                                                },

                                                                                                                {
                                                                                                                        text ="SecondAlert",
                                                                                                                        type ="TEXT",
                                                                                                                }
                                                                                                        },
                                                                                                speakType = "ALERT_MANEUVER",

                                                                                        })
                                                                :Do(function(_,data)
                                                                        SpeakId = data.id

                                                                        local function speakResponse()
                                                                                self.hmiConnection:SendError(SpeakId, "TTS.Speak", "WARNINGS", "Unsupported phoneme type sent in a prompt")

                                                                        end

                                                                        RUN_AFTER(speakResponse, 1000)

                                                                end)


                                                    --mobile side: expect AlertManeuver response
                                                    EXPECT_RESPONSE(CorIdAlertM, { success = true, resultCode = "WARNINGS", info = "Unsupported phoneme type sent in a prompt" })
                                                        :Timeout(11000)

                                                end

                                --End Test case TTS.Speak respond with WARNINGS


                                --Description: check Navigation.AlertManevuer respond with "WARNINGS"


                                                function Test:AlertManeuver_Navigation_Alert_maneuver_WARNINGS()

                                                        --mobile side: AlertManeuver request
                                                        local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
                                                                                                                                                        {

                                                                                                                                                                ttsChunks =
                                                                                                                                                                {

                                                                                                                                                                        {
                                                                                                                                                                                text ="FirstAlert",
                                                                                                                                                                                type ="TEXT",
                                                                                                                                                                        },

                                                                                                                                                                        {
                                                                                                                                                                                text ="SecondAlert",
                                                                                                                                                                                type ="TEXT",
                                                                                                                                                                        },
                                                                                                                                                                },
                                                                                                                                                                softButtons =
                                                                                                                                                                {

                                                                                                                                                                        {
                                                                                                                                                                                type = "BOTH",
                                                                                                                                                                                text = "Close",
                                                                                                                                                                                 image =

                                                                                                                                                                                {
                                                                                                                                                                                        value = "icon.png",
                                                                                                                                                                                        imageType = "DYNAMIC",
                                                                                                                                                                                },
                                                                                                                                                                                isHighlighted = true,
                                                                                                                                                                                softButtonID = 2,
                                                                                                                                                                                systemAction = "DEFAULT_ACTION",
                                                                                                                                                                        }
                                                                                                                                                                }

                                                                                                                                                        })

                                                        local AlertId
                                                        --hmi side: Navigation.AlertManeuver request
                                                        EXPECT_HMICALL("Navigation.AlertManeuver",
                                                                                        {
                                                                                                softButtons =
                                                                                                {

                                                                                                        {
                                                                                                                type = "BOTH",
                                                                                                                text = "Close",
                                                                                                                 image =

                                                                                                                {
                                                                                                                        value = config.pathToSDL .. "icon.png",
                                                                                                                        imageType = "DYNAMIC",
                                                                                                                },
                                                                                                                isHighlighted = true,
                                                                                                                softButtonID = 2,
                                                                                                                systemAction = "DEFAULT_ACTION",
                                                                                                        }
                                                                                                }
                                                                                        })
                                                                :Do(function(_,data)
                                                                        AlertId = data.id
                                                                        local function alertResponse()
                                                                                self.hmiConnection:SendError(AlertId, "Navigation.AlertManeuver", "WARNINGS", "Navigation error")

                                                                        end

                                                                        RUN_AFTER(alertResponse, 2000)
                                                                end)

                                                        local SpeakId
                                                        --hmi side: TTS.Speak request
                                                        EXPECT_HMICALL("TTS.Speak",
                                                                                        {
                                                                                                ttsChunks =
                                                                                                        {

                                                                                                                {
                                                                                                                        text ="FirstAlert",
                                                                                                                        type ="TEXT",
                                                                                                                },

                                                                                                                {
                                                                                                                        text ="SecondAlert",
                                                                                                                        type ="TEXT",
                                                                                                                }
                                                                                                        },
                                                                                                speakType = "ALERT_MANEUVER",

                                                                                        })
                                                                :Do(function(_,data)
                                                                        SpeakId = data.id

                                                                        local function speakResponse()
                                                                                self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })

                                                                        end

                                                                        RUN_AFTER(speakResponse, 1000)

                                                                end)


                                                    --mobile side: expect AlertManeuver response
                                                    EXPECT_RESPONSE(CorIdAlertM, { success = true, resultCode = "WARNINGS"})
                                                        :Timeout(11000)

                                                end
                            --End Test case


                                --Description: check Navigation.AlertManevuer and TTS respond with "WARNINGS"


                                                function Test:AlertManeuver_Navigation_and_TTS_WARNINGS()

                                                        --mobile side: AlertManeuver request
                                                        local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
                                                                                                                                                        {

                                                                                                                                                                ttsChunks =
                                                                                                                                                                {

                                                                                                                                                                        {
                                                                                                                                                                                text ="FirstAlert",
                                                                                                                                                                                type ="TEXT",
                                                                                                                                                                        },

                                                                                                                                                                        {
                                                                                                                                                                                text ="SecondAlert",
                                                                                                                                                                                type ="TEXT",
                                                                                                                                                                        },
                                                                                                                                                                },
                                                                                                                                                                softButtons =
                                                                                                                                                                {

                                                                                                                                                                        {
                                                                                                                                                                                type = "BOTH",
                                                                                                                                                                                text = "Close",
                                                                                                                                                                                 image =

                                                                                                                                                                                {
                                                                                                                                                                                        value = "icon.png",
                                                                                                                                                                                        imageType = "DYNAMIC",
                                                                                                                                                                                },
                                                                                                                                                                                isHighlighted = true,
                                                                                                                                                                                softButtonID = 2,
                                                                                                                                                                                systemAction = "DEFAULT_ACTION",
                                                                                                                                                                        }
                                                                                                                                                                }

                                                                                                                                                        })

                                                        local AlertId
                                                        --hmi side: Navigation.AlertManeuver request
                                                        EXPECT_HMICALL("Navigation.AlertManeuver",
                                                                                        {
                                                                                                softButtons =
                                                                                                {

                                                                                                        {
                                                                                                                type = "BOTH",
                                                                                                                text = "Close",
                                                                                                                 image =

                                                                                                                {
                                                                                                                        value = config.pathToSDL .. "icon.png",
                                                                                                                        imageType = "DYNAMIC",
                                                                                                                },
                                                                                                                isHighlighted = true,
                                                                                                                softButtonID = 2,
                                                                                                                systemAction = "DEFAULT_ACTION",
                                                                                                        }
                                                                                                }
                                                                                        })
                                                                :Do(function(_,data)
                                                                        AlertId = data.id
                                                                        local function alertResponse()
                                                                                self.hmiConnection:SendError(AlertId, "Navigation.AlertManeuver", "WARNINGS", "Navigation error")

                                                                        end

                                                                        RUN_AFTER(alertResponse, 2000)
                                                                end)

                                                        local SpeakId
                                                        --hmi side: TTS.Speak request
                                                        EXPECT_HMICALL("TTS.Speak",
                                                                                        {
                                                                                                ttsChunks =
                                                                                                        {

                                                                                                                {
                                                                                                                        text ="FirstAlert",
                                                                                                                        type ="TEXT",
                                                                                                                },

                                                                                                                {
                                                                                                                        text ="SecondAlert",
                                                                                                                        type ="TEXT",
                                                                                                                }
                                                                                                        },
                                                                                                speakType = "ALERT_MANEUVER",

                                                                                        })
                                                                :Do(function(_,data)
                                                                        SpeakId = data.id

                                                                        local function speakResponse()
                                                                                self.hmiConnection:SendError(SpeakId, "TTS.Speak", "WARNINGS", "")

                                                                        end

                                                                        RUN_AFTER(speakResponse, 1000)

                                                                end)


                                                    --mobile side: expect AlertManeuver response
                                                    EXPECT_RESPONSE(CorIdAlertM, { success = true, resultCode = "WARNINGS"})
                                                        :Timeout(11000)

                                                end
                            --End Test case



                            --Description: check only TTS.Speak is send and respond with WARNINGS:

                             function Test:AlertManeuver_Only_TTS_WARNINGS()

                                                        --mobile side: AlertManeuver request
                                                        local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
                                                                                                                                                        {

                                                                                                                                                                ttsChunks =
                                                                                                                                                                {

                                                                                                                                                                        {
                                                                                                                                                                                text ="FirstAlert",
                                                                                                                                                                                type ="TEXT",
                                                                                                                                                                        },

                                                                                                                                                                        {
                                                                                                                                                                                text ="SecondAlert",
                                                                                                                                                                                type ="TEXT",
                                                                                                                                                                        },
                                                                                                                                                                }

                                                                                                                                                        })

                                                        local SpeakId
                                                        --hmi side: TTS.Speak request
                                                        EXPECT_HMICALL("TTS.Speak",
                                                                                        {
                                                                                                ttsChunks =
                                                                                                        {

                                                                                                                {
                                                                                                                        text ="FirstAlert",
                                                                                                                        type ="TEXT",
                                                                                                                },

                                                                                                                {
                                                                                                                        text ="SecondAlert",
                                                                                                                        type ="TEXT",
                                                                                                                }
                                                                                                        },
                                                                                                speakType = "ALERT_MANEUVER",

                                                                                        })
                                                                :Do(function(_,data)
                                                                        SpeakId = data.id

                                                                        local function speakResponse()
                                                                                self.hmiConnection:SendError(SpeakId, "TTS.Speak", "WARNINGS", "Unsupported phoneme type sent in a prompt")

                                                                        end

                                                                        RUN_AFTER(speakResponse, 1000)

                                                                end)


                                                    --mobile side: expect AlertManeuver response
                                                    EXPECT_RESPONSE(CorIdAlertM, { success = true, resultCode = "WARNINGS", info = "Unsupported phoneme type sent in a prompt" })
                                                        :Timeout(11000)

                                                end


                            --End Test case



                            --Description: check only Navigation.AlertManevuer is send and respond with WARNINGS:

                            function Test:AlertManeuver_Only_Navigation_Alert_maneuver_WARNINGS()

                                                        --mobile side: AlertManeuver request
                                                        local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
                                                                                                                                                        {
                                                                                                                                                                softButtons =
                                                                                                                                                                {

                                                                                                                                                                        {
                                                                                                                                                                                type = "BOTH",
                                                                                                                                                                                text = "Close",
                                                                                                                                                                                 image =

                                                                                                                                                                                {
                                                                                                                                                                                        value = "icon.png",
                                                                                                                                                                                        imageType = "DYNAMIC",
                                                                                                                                                                                },
                                                                                                                                                                                isHighlighted = true,
                                                                                                                                                                                softButtonID = 2,
                                                                                                                                                                                systemAction = "DEFAULT_ACTION",
                                                                                                                                                                        }
                                                                                                                                                                }

                                                                                                                                                        })

                                                        local AlertId
                                                        --hmi side: Navigation.AlertManeuver request
                                                        EXPECT_HMICALL("Navigation.AlertManeuver",
                                                                                        {
                                                                                                softButtons =
                                                                                                {

                                                                                                        {
                                                                                                                type = "BOTH",
                                                                                                                text = "Close",
                                                                                                                 image =

                                                                                                                {
                                                                                                                        value = config.pathToSDL .. "icon.png",
                                                                                                                        imageType = "DYNAMIC",
                                                                                                                },
                                                                                                                isHighlighted = true,
                                                                                                                softButtonID = 2,
                                                                                                                systemAction = "DEFAULT_ACTION",
                                                                                                        }
                                                                                                }
                                                                                        })
                                                                :Do(function(_,data)
                                                                        AlertId = data.id
                                                                        local function alertResponse()
                                                                                self.hmiConnection:SendError(AlertId, "Navigation.AlertManeuver", "WARNINGS", "Navigation error")

                                                                        end

                                                                        RUN_AFTER(alertResponse, 2000)
                                                                end)


                                                    --mobile side: expect AlertManeuver response
                                                    EXPECT_RESPONSE(CorIdAlertM, { success = true, resultCode = "WARNINGS", info = "Navigation error"})
                                                        :Timeout(11000)

                                                end
                            --End Test case







                ----------------------------------------------------------------------------------------------
                ---------------------------------------14 TEST BLOCK------------------------------------------
                --------------------------Check "WARNINGS" result code for SetGlobalProperties rpc------------------
                ----------------------------------------------------------------------------------------------

                --------Checks-----------

                --Description: check TTS.Speak respond with WARNINGS

                --Requirement in JIRA: APPLINK-15261, APPLINK-15036

                --Verification criteria: In case SDL receives WARNINGS result code from HMI -> SDL must transfer WARNINGS (success:true) to mobile app

                function Test:SetGlobalProperties_TTS_WARNINGS()

                        --mobile side: sending SetGlobalProperties request
                        local cid = self.mobileSession:SendRPC("SetGlobalProperties",
                        {
                                menuTitle = "Menu Title",
                                timeoutPrompt =
                                {
                                        {
                                                text = "Timeout prompt",
                                                type = "TEXT"
                                        }
                                },
                                vrHelp =
                                {
                                        {
                                                position = 1,
                                                text = "VR help item"
                                        }
                                },
                                helpPrompt =
                                {
                                        {
                                                text = "Help prompt",
                                                type = "TEXT"
                                        }
                                },
                                vrHelpTitle = "VR help title",
                                keyboardProperties =
                                {
                                        keyboardLayout = "QWERTY",
                                        keypressMode = "SINGLE_KEYPRESS",
                                        limitedCharacterList =
                                        {
                                                "a"
                                        },
                                        language = "EN-US",
                                        autoCompleteText = "Daemon, Freedom"
                                }
                        })


                        --hmi side: expect TTS.SetGlobalProperties request
                        EXPECT_HMICALL("TTS.SetGlobalProperties",
                        {
                                timeoutPrompt =
                                {
                                        {
                                                text = "Timeout prompt",
                                                type = "TEXT"
                                        }
                                },
                                helpPrompt =
                                {
                                        {
                                                text = "Help prompt",
                                                type = "TEXT"
                                        }
                                }
                        })
                        :Timeout(10000)
                        :Do(function(_,data)
                                --hmi side: sending TTS.SetGlobalProperties response
                                self.hmiConnection:SendError(data.id, "TTS.SetGlobalProperties", "WARNINGS", "")
                        end)



                        --hmi side: expect UI.SetGlobalProperties request
                        EXPECT_HMICALL("UI.SetGlobalProperties",
                        {
                                menuTitle = "Menu Title",
                                vrHelp =
                                {
                                        {
                                                position = 1,
                                                text = "VR help item"
                                        }
                                },
                                vrHelpTitle = "VR help title",
                                keyboardProperties =
                                {
                                        keyboardLayout = "QWERTY",
                                        keypressMode = "SINGLE_KEYPRESS",
                                        limitedCharacterList =
                                        {
                                                "a"
                                        },
                                        language = "EN-US",
                                        autoCompleteText = "Daemon, Freedom"
                                }
                        })
                        :Timeout(10000)
                        :Do(function(_,data)
                                --hmi side: sending UI.SetGlobalProperties response
                                self.hmiConnection:SendResponse(data.id, "UI.SetGlobalProperties", "SUCCESS", {})
                        end)



                        --mobile side: expect SetGlobalProperties response
                        EXPECT_RESPONSE(cid, { success = true, resultCode = "WARNINGS"})
                        :Timeout(10000)
                end


                --Description: check UI respond with WARNINGS

                function Test:SetGlobalProperties_UI_WARNINGS()

                        --mobile side: sending SetGlobalProperties request
                        local cid = self.mobileSession:SendRPC("SetGlobalProperties",
                        {
                                menuTitle = "Menu Title",
                                timeoutPrompt =
                                {
                                        {
                                                text = "Timeout prompt",
                                                type = "TEXT"
                                        }
                                },
                                vrHelp =
                                {
                                        {
                                                position = 1,
                                                text = "VR help item"
                                        }
                                },
                                helpPrompt =
                                {
                                        {
                                                text = "Help prompt",
                                                type = "TEXT"
                                        }
                                },
                                vrHelpTitle = "VR help title",
                                keyboardProperties =
                                {
                                        keyboardLayout = "QWERTY",
                                        keypressMode = "SINGLE_KEYPRESS",
                                        limitedCharacterList =
                                        {
                                                "a"
                                        },
                                        language = "EN-US",
                                        autoCompleteText = "Daemon, Freedom"
                                }
                        })


                        --hmi side: expect TTS.SetGlobalProperties request
                        EXPECT_HMICALL("TTS.SetGlobalProperties",
                        {
                                timeoutPrompt =
                                {
                                        {
                                                text = "Timeout prompt",
                                                type = "TEXT"
                                        }
                                },
                                helpPrompt =
                                {
                                        {
                                                text = "Help prompt",
                                                type = "TEXT"
                                        }
                                }
                        })
                        :Timeout(10000)
                        :Do(function(_,data)
                                --hmi side: sending TTS.SetGlobalProperties response
                                self.hmiConnection:SendResponse(data.id, "TTS.SetGlobalProperties", "SUCCESS", {})
                        end)



                        --hmi side: expect UI.SetGlobalProperties request
                        EXPECT_HMICALL("UI.SetGlobalProperties",
                        {
                                menuTitle = "Menu Title",
                                vrHelp =
                                {
                                        {
                                                position = 1,
                                                text = "VR help item"
                                        }
                                },
                                vrHelpTitle = "VR help title",
                                keyboardProperties =
                                {
                                        keyboardLayout = "QWERTY",
                                        keypressMode = "SINGLE_KEYPRESS",
                                        limitedCharacterList =
                                        {
                                                "a"
                                        },
                                        language = "EN-US",
                                        autoCompleteText = "Daemon, Freedom"
                                }
                        })
                        :Timeout(10000)
                        :Do(function(_,data)
                                --hmi side: sending UI.SetGlobalProperties response
                                self.hmiConnection:SendError(data.id, "UI.SetGlobalProperties", "WARNINGS", "")
                        end)



                        --mobile side: expect SetGlobalProperties response
                        EXPECT_RESPONSE(cid, { success = true, resultCode = "WARNINGS"})
                        :Timeout(10000)
                end


                --Description: check UI and TTS respond with WARNINGS

                function Test:SetGlobalProperties_UI_and_TTS_WARNINGS()

                        --mobile side: sending SetGlobalProperties request
                        local cid = self.mobileSession:SendRPC("SetGlobalProperties",
                        {
                                menuTitle = "Menu Title",
                                timeoutPrompt =
                                {
                                        {
                                                text = "Timeout prompt",
                                                type = "TEXT"
                                        }
                                },
                                vrHelp =
                                {
                                        {
                                                position = 1,
                                                text = "VR help item"
                                        }
                                },
                                helpPrompt =
                                {
                                        {
                                                text = "Help prompt",
                                                type = "TEXT"
                                        }
                                },
                                vrHelpTitle = "VR help title",
                                keyboardProperties =
                                {
                                        keyboardLayout = "QWERTY",
                                        keypressMode = "SINGLE_KEYPRESS",
                                        limitedCharacterList =
                                        {
                                                "a"
                                        },
                                        language = "EN-US",
                                        autoCompleteText = "Daemon, Freedom"
                                }
                        })


                        --hmi side: expect TTS.SetGlobalProperties request
                        EXPECT_HMICALL("TTS.SetGlobalProperties",
                        {
                                timeoutPrompt =
                                {
                                        {
                                                text = "Timeout prompt",
                                                type = "TEXT"
                                        }
                                },
                                helpPrompt =
                                {
                                        {
                                                text = "Help prompt",
                                                type = "TEXT"
                                        }
                                }
                        })
                        :Timeout(10000)
                        :Do(function(_,data)
                                --hmi side: sending TTS.SetGlobalProperties response
                                self.hmiConnection:SendError(data.id, "TTS.SetGlobalProperties", "WARNINGS", "")
                        end)



                        --hmi side: expect UI.SetGlobalProperties request
                        EXPECT_HMICALL("UI.SetGlobalProperties",
                        {
                                menuTitle = "Menu Title",
                                vrHelp =
                                {
                                        {
                                                position = 1,
                                                text = "VR help item"
                                        }
                                },
                                vrHelpTitle = "VR help title",
                                keyboardProperties =
                                {
                                        keyboardLayout = "QWERTY",
                                        keypressMode = "SINGLE_KEYPRESS",
                                        limitedCharacterList =
                                        {
                                                "a"
                                        },
                                        language = "EN-US",
                                        autoCompleteText = "Daemon, Freedom"
                                }
                        })
                        :Timeout(10000)
                        :Do(function(_,data)
                                --hmi side: sending UI.SetGlobalProperties response
                                self.hmiConnection:SendError(data.id, "UI.SetGlobalProperties", "WARNINGS", "")
                        end)



                        --mobile side: expect SetGlobalProperties response
                        EXPECT_RESPONSE(cid, { success = true, resultCode = "WARNINGS"})
                        :Timeout(10000)
                end



                --Description: check only TTS were sent and respond with WARNINGS

              --[[  Not actual due to SDLAQ-CRS-11: if vrHelpTitle is missed, SDL has to send UI.SetGlobalProperties with vrHelpTitile is application name

                function Test:SetGlobalProperties_only_TTS_WARNINGS()

                        --mobile side: sending SetGlobalProperties request
                        local cid = self.mobileSession:SendRPC("SetGlobalProperties",
                        {
                                timeoutPrompt =
                                {
                                        {
                                                text = "Timeout prompt",
                                                type = "TEXT"
                                        }
                                },
                                helpPrompt =
                                {
                                        {
                                                text = "Help prompt",
                                                type = "TEXT"
                                        }
                                },

                        })


                        --hmi side: expect TTS.SetGlobalProperties request
                        EXPECT_HMICALL("TTS.SetGlobalProperties",
                        {
                                timeoutPrompt =
                                {
                                        {
                                                text = "Timeout prompt",
                                                type = "TEXT"
                                        }
                                },
                                helpPrompt =
                                {
                                        {
                                                text = "Help prompt",
                                                type = "TEXT"
                                        }
                                }
                        })
                        :Timeout(10000)
                        :Do(function(_,data)
                                --hmi side: sending TTS.SetGlobalProperties response
                                self.hmiConnection:SendError(data.id, "TTS.SetGlobalProperties", "WARNINGS", "")
                        end)

                        --mobile side: expect SetGlobalProperties response
                        EXPECT_RESPONSE(cid, { success = true, resultCode = "WARNINGS"})
                        :Timeout(10000)
                end
]]



                --Description: check only UI were sent and respond with WARNINGS

                function Test:SetGlobalProperties_only_UI_WARNINGS()

                        --mobile side: sending SetGlobalProperties request
                        local cid = self.mobileSession:SendRPC("SetGlobalProperties",
                        {
                                menuTitle = "Menu Title",
                                vrHelp =
                                {
                                        {
                                                position = 1,
                                                text = "VR help item"
                                        }
                                },
                                vrHelpTitle = "VR help title",
                                keyboardProperties =
                                {
                                        keyboardLayout = "QWERTY",
                                        keypressMode = "SINGLE_KEYPRESS",
                                        limitedCharacterList =
                                        {
                                                "a"
                                        },
                                        language = "EN-US",
                                        autoCompleteText = "Daemon, Freedom"
                                }
                        })


                        --hmi side: expect UI.SetGlobalProperties request
                        EXPECT_HMICALL("UI.SetGlobalProperties",
                        {
                                menuTitle = "Menu Title",
                                vrHelp =
                                {
                                        {
                                                position = 1,
                                                text = "VR help item"
                                        }
                                },
                                vrHelpTitle = "VR help title",
                                keyboardProperties =
                                {
                                        keyboardLayout = "QWERTY",
                                        keypressMode = "SINGLE_KEYPRESS",
                                        limitedCharacterList =
                                        {
                                                "a"
                                        },
                                        language = "EN-US",
                                        autoCompleteText = "Daemon, Freedom"
                                }
                        })
                        :Timeout(10000)
                        :Do(function(_,data)
                                --hmi side: sending UI.SetGlobalProperties response
                                self.hmiConnection:SendError(data.id, "UI.SetGlobalProperties", "WARNINGS", "")
                        end)



                        --mobile side: expect SetGlobalProperties response
                        EXPECT_RESPONSE(cid, { success = true, resultCode = "WARNINGS"})
                        :Timeout(10000)
                end






                ----------------------------------------------------------------------------------------------
                ---------------------------------------15 TEST BLOCK------------------------------------------
                --------------------------Check "WARNINGS" result code for Alert rpc--------------------------
                ----------------------------------------------------------------------------------------------

                --------Checks-----------

                --Description: check TTS.Speak respond with WARNINGS

                --Requirement in JIRA: APPLINK-15261, APPLINK-15036

                --Verification criteria: In case SDL receives WARNINGS result code from HMI -> SDL must transfer WARNINGS (success:true) to mobile app

                        function Test:Alert_TTS_WARNINGS()

                                --mobile side: Alert request
                                local CorIdAlert = self.mobileSession:SendRPC("Alert",
                                                                        {

                                                                                alertText1 = "alertText1",
                                                                                alertText2 = "alertText2",
                                                                                alertText3 = "alertText3",
                                                                                ttsChunks =
                                                                                {

                                                                                        {
                                                                                                text = "TTSChunk",
                                                                                                type = "TEXT"
                                                                                        }
                                                                                },
                                                                                duration = 3000,
                                                                                playTone = true,
                                                                                progressIndicator = true,
                                                                                softButtons =
                                                                                {

                                                                                        {
                                                                                                type = "BOTH",
                                                                                                text = "Close",
                                                                                                 image =

                                                                                                {
                                                                                                        value = "icon.png",
                                                                                                        imageType = "DYNAMIC"
                                                                                                },
                                                                                                isHighlighted = true,
                                                                                                softButtonID = 3,
                                                                                                systemAction = "DEFAULT_ACTION"
                                                                                        },

                                                                                        {
                                                                                                type = "TEXT",
                                                                                                text = "Keep",
                                                                                                isHighlighted = true,
                                                                                                softButtonID = 4,
                                                                                                systemAction = "KEEP_CONTEXT"
                                                                                        },

                                                                                        {
                                                                                                type = "IMAGE",
                                                                                                 image =

                                                                                                {
                                                                                                        value = "icon.png",
                                                                                                        imageType = "DYNAMIC"
                                                                                                },
                                                                                                softButtonID = 5,
                                                                                                systemAction = "STEAL_FOCUS"
                                                                                        },
                                                                                }

                                                                        })

                                local AlertId
                                --hmi side: UI.Alert request
                                EXPECT_HMICALL("UI.Alert",
                                                        {
                                                                alertStrings =
                                                                {
                                                                        {fieldName = "alertText1", fieldText = "alertText1"},
                                                                {fieldName = "alertText2", fieldText = "alertText2"},
                                                                {fieldName = "alertText3", fieldText = "alertText3"}
                                                            },
                                                            alertType = "BOTH",
                                                                duration = 0,
                                                                progressIndicator = true,
                                                                softButtons =
                                                                {

                                                                        {
                                                                                type = "BOTH",
                                                                                text = "Close",
                                                                                 image =

                                                                                {
                                                                                        value = config.pathToSDL .. "icon.png",
                                                                                        imageType = "DYNAMIC"
                                                                                },
                                                                                isHighlighted = true,
                                                                                softButtonID = 3,
                                                                                systemAction = "DEFAULT_ACTION"
                                                                        },

                                                                        {
                                                                                type = "TEXT",
                                                                                text = "Keep",
                                                                                isHighlighted = true,
                                                                                softButtonID = 4,
                                                                                systemAction = "KEEP_CONTEXT"
                                                                        },

                                                                        {
                                                                                type = "IMAGE",
                                                                                 image =

                                                                                {
                                                                                        value =  config.pathToSDL .. "icon.png",
                                                                                        imageType = "DYNAMIC"
                                                                                },
                                                                                softButtonID = 5,
                                                                                systemAction = "STEAL_FOCUS"
                                                                        },
                                                                }
                                                        })
                                        :Do(function(_,data)
                                                SendOnSystemContext(self,"ALERT")
                                                AlertId = data.id

                                                local function alertResponse()
                                                        self.hmiConnection:SendResponse(AlertId, "UI.Alert", "SUCCESS", { })

                                                        SendOnSystemContext(self,"MAIN")
                                                end

                                                RUN_AFTER(alertResponse, 3000)
                                        end)

                                local SpeakId
                                --hmi side: TTS.Speak request
                                EXPECT_HMICALL("TTS.Speak",
                                                        {
                                                                ttsChunks =
                                                                {

                                                                        {
                                                                                text = "TTSChunk",
                                                                                type = "TEXT"
                                                                        }
                                                                },
                                                                playTone = true,
                                                                speakType = "ALERT"
                                                        })
                                        :Do(function(_,data)
                                                self.hmiConnection:SendNotification("TTS.Started")
                                                SpeakId = data.id

                                                local function speakResponse()
                                                        self.hmiConnection:SendError(SpeakId, "TTS.Speak", "WARNINGS", "")

                                                        self.hmiConnection:SendNotification("TTS.Stopped")
                                                end

                                                RUN_AFTER(speakResponse, 2000)

                                        end)
                                        :ValidIf(function(_,data)
                                                if #data.params.ttsChunks == 1 then
                                                        return true
                                                else
                                                        print("ttsChunks array in TTS.Speak request has wrong element number. Expected 1, actual "..tostring(#data.params.ttsChunks))
                                                        return false
                                                end
                                        end)


                                ExpectOnHMIStatusWithAudioStateChanged_Alert(self)

                            --mobile side: Alert response
                            EXPECT_RESPONSE(CorIdAlert, { success = true, resultCode = "WARNINGS" })


                end


            --Description: check UI respond with WARNINGS


                        function Test:Alert_UI_WARNINGS()

                                --mobile side: Alert request
                                local CorIdAlert = self.mobileSession:SendRPC("Alert",
                                                                        {

                                                                                alertText1 = "alertText1",
                                                                                alertText2 = "alertText2",
                                                                                alertText3 = "alertText3",
                                                                                ttsChunks =
                                                                                {

                                                                                        {
                                                                                                text = "TTSChunk",
                                                                                                type = "TEXT"
                                                                                        }
                                                                                },
                                                                                duration = 3000,
                                                                                playTone = true,
                                                                                progressIndicator = true,
                                                                                softButtons =
                                                                                {

                                                                                        {
                                                                                                type = "BOTH",
                                                                                                text = "Close",
                                                                                                 image =

                                                                                                {
                                                                                                        value = "icon.png",
                                                                                                        imageType = "DYNAMIC"
                                                                                                },
                                                                                                isHighlighted = true,
                                                                                                softButtonID = 3,
                                                                                                systemAction = "DEFAULT_ACTION"
                                                                                        },

                                                                                        {
                                                                                                type = "TEXT",
                                                                                                text = "Keep",
                                                                                                isHighlighted = true,
                                                                                                softButtonID = 4,
                                                                                                systemAction = "KEEP_CONTEXT"
                                                                                        },

                                                                                        {
                                                                                                type = "IMAGE",
                                                                                                 image =

                                                                                                {
                                                                                                        value = "icon.png",
                                                                                                        imageType = "DYNAMIC"
                                                                                                },
                                                                                                softButtonID = 5,
                                                                                                systemAction = "STEAL_FOCUS"
                                                                                        },
                                                                                }

                                                                        })

                                local AlertId
                                --hmi side: UI.Alert request
                                EXPECT_HMICALL("UI.Alert",
                                                        {
                                                                alertStrings =
                                                                {
                                                                        {fieldName = "alertText1", fieldText = "alertText1"},
                                                                {fieldName = "alertText2", fieldText = "alertText2"},
                                                                {fieldName = "alertText3", fieldText = "alertText3"}
                                                            },
                                                            alertType = "BOTH",
                                                                duration = 0,
                                                                progressIndicator = true,
                                                                softButtons =
                                                                {

                                                                        {
                                                                                type = "BOTH",
                                                                                text = "Close",
                                                                                 image =

                                                                                {
                                                                                        value = config.pathToSDL .. "icon.png",
                                                                                        imageType = "DYNAMIC"
                                                                                },
                                                                                isHighlighted = true,
                                                                                softButtonID = 3,
                                                                                systemAction = "DEFAULT_ACTION"
                                                                        },

                                                                        {
                                                                                type = "TEXT",
                                                                                text = "Keep",
                                                                                isHighlighted = true,
                                                                                softButtonID = 4,
                                                                                systemAction = "KEEP_CONTEXT"
                                                                        },

                                                                        {
                                                                                type = "IMAGE",
                                                                                 image =

                                                                                {
                                                                                        value =  config.pathToSDL .. "icon.png",
                                                                                        imageType = "DYNAMIC"
                                                                                },
                                                                                softButtonID = 5,
                                                                                systemAction = "STEAL_FOCUS"
                                                                        },
                                                                }
                                                        })
                                        :Do(function(_,data)
                                                SendOnSystemContext(self,"ALERT")
                                                AlertId = data.id

                                                local function alertResponse()
                                                        self.hmiConnection:SendError(AlertId, "UI.Alert", "WARNINGS", "")

                                                        SendOnSystemContext(self,"MAIN")
                                                end

                                                RUN_AFTER(alertResponse, 3000)
                                        end)

                                local SpeakId
                                --hmi side: TTS.Speak request
                                EXPECT_HMICALL("TTS.Speak",
                                                        {
                                                                ttsChunks =
                                                                {

                                                                        {
                                                                                text = "TTSChunk",
                                                                                type = "TEXT"
                                                                        }
                                                                },
                                                                playTone = true,
                                                                speakType = "ALERT"
                                                        })
                                        :Do(function(_,data)
                                                self.hmiConnection:SendNotification("TTS.Started")
                                                SpeakId = data.id

                                                local function speakResponse()
                                                        self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })

                                                        self.hmiConnection:SendNotification("TTS.Stopped")
                                                end

                                                RUN_AFTER(speakResponse, 2000)

                                        end)
                                        :ValidIf(function(_,data)
                                                if #data.params.ttsChunks == 1 then
                                                        return true
                                                else
                                                        print("ttsChunks array in TTS.Speak request has wrong element number. Expected 1, actual "..tostring(#data.params.ttsChunks))
                                                        return false
                                                end
                                        end)


                                ExpectOnHMIStatusWithAudioStateChanged_Alert(self)

                            --mobile side: Alert response
                            EXPECT_RESPONSE(CorIdAlert, { success = true, resultCode = "WARNINGS" })


                end


            --Description: check TTS and UI respond with WARNINGS


                        function Test:Alert_TTS_UI_WARNINGS()

                                --mobile side: Alert request
                                local CorIdAlert = self.mobileSession:SendRPC("Alert",
                                                                        {

                                                                                alertText1 = "alertText1",
                                                                                alertText2 = "alertText2",
                                                                                alertText3 = "alertText3",
                                                                                ttsChunks =
                                                                                {

                                                                                        {
                                                                                                text = "TTSChunk",
                                                                                                type = "TEXT"
                                                                                        }
                                                                                },
                                                                                duration = 3000,
                                                                                playTone = true,
                                                                                progressIndicator = true,
                                                                                softButtons =
                                                                                {

                                                                                        {
                                                                                                type = "BOTH",
                                                                                                text = "Close",
                                                                                                 image =

                                                                                                {
                                                                                                        value = "icon.png",
                                                                                                        imageType = "DYNAMIC"
                                                                                                },
                                                                                                isHighlighted = true,
                                                                                                softButtonID = 3,
                                                                                                systemAction = "DEFAULT_ACTION"
                                                                                        },

                                                                                        {
                                                                                                type = "TEXT",
                                                                                                text = "Keep",
                                                                                                isHighlighted = true,
                                                                                                softButtonID = 4,
                                                                                                systemAction = "KEEP_CONTEXT"
                                                                                        },

                                                                                        {
                                                                                                type = "IMAGE",
                                                                                                 image =

                                                                                                {
                                                                                                        value = "icon.png",
                                                                                                        imageType = "DYNAMIC"
                                                                                                },
                                                                                                softButtonID = 5,
                                                                                                systemAction = "STEAL_FOCUS"
                                                                                        },
                                                                                }

                                                                        })

                                local AlertId
                                --hmi side: UI.Alert request
                                EXPECT_HMICALL("UI.Alert",
                                                        {
                                                                alertStrings =
                                                                {
                                                                        {fieldName = "alertText1", fieldText = "alertText1"},
                                                                {fieldName = "alertText2", fieldText = "alertText2"},
                                                                {fieldName = "alertText3", fieldText = "alertText3"}
                                                            },
                                                            alertType = "BOTH",
                                                                duration = 0,
                                                                progressIndicator = true,
                                                                softButtons =
                                                                {

                                                                        {
                                                                                type = "BOTH",
                                                                                text = "Close",
                                                                                 image =

                                                                                {
                                                                                        value = config.pathToSDL .. "icon.png",
                                                                                        imageType = "DYNAMIC"
                                                                                },
                                                                                isHighlighted = true,
                                                                                softButtonID = 3,
                                                                                systemAction = "DEFAULT_ACTION"
                                                                        },

                                                                        {
                                                                                type = "TEXT",
                                                                                text = "Keep",
                                                                                isHighlighted = true,
                                                                                softButtonID = 4,
                                                                                systemAction = "KEEP_CONTEXT"
                                                                        },

                                                                        {
                                                                                type = "IMAGE",
                                                                                 image =

                                                                                {
                                                                                        value =  config.pathToSDL .. "icon.png",
                                                                                        imageType = "DYNAMIC"
                                                                                },
                                                                                softButtonID = 5,
                                                                                systemAction = "STEAL_FOCUS"
                                                                        },
                                                                }
                                                        })
                                        :Do(function(_,data)
                                                SendOnSystemContext(self,"ALERT")
                                                AlertId = data.id

                                                local function alertResponse()
                                                        self.hmiConnection:SendError(AlertId, "UI.Alert", "WARNINGS", "")

                                                        SendOnSystemContext(self,"MAIN")
                                                end

                                                RUN_AFTER(alertResponse, 3000)
                                        end)

                                local SpeakId
                                --hmi side: TTS.Speak request
                                EXPECT_HMICALL("TTS.Speak",
                                                        {
                                                                ttsChunks =
                                                                {

                                                                        {
                                                                                text = "TTSChunk",
                                                                                type = "TEXT"
                                                                        }
                                                                },
                                                                playTone = true,
                                                                speakType = "ALERT"
                                                        })
                                        :Do(function(_,data)
                                                self.hmiConnection:SendNotification("TTS.Started")
                                                SpeakId = data.id

                                                local function speakResponse()
                                                        self.hmiConnection:SendError(SpeakId, "TTS.Speak", "WARNINGS", "")

                                                        self.hmiConnection:SendNotification("TTS.Stopped")
                                                end

                                                RUN_AFTER(speakResponse, 2000)

                                        end)
                                        :ValidIf(function(_,data)
                                                if #data.params.ttsChunks == 1 then
                                                        return true
                                                else
                                                        print("ttsChunks array in TTS.Speak request has wrong element number. Expected 1, actual "..tostring(#data.params.ttsChunks))
                                                        return false
                                                end
                                        end)


                                ExpectOnHMIStatusWithAudioStateChanged_Alert(self)

                            --mobile side: Alert response
                            EXPECT_RESPONSE(CorIdAlert, { success = true, resultCode = "WARNINGS" })


                end


                            --Description:  Only TTS sent and respond with WARNINGS


                            function Test:Alert_Only_TTS()

                --mobile side: Alert request
                local CorIdAlert = self.mobileSession:SendRPC("Alert",
                                                                {

                                                                    ttsChunks =
                                                                    {

                                                                        {
                                                                            text = "TTSChunkOnly",
                                                                            type = "TEXT",
                                                                        },
                                                                    },

                                                                })


                local SpeakId
                --hmi side: TTS.Speak request
                EXPECT_HMICALL("TTS.Speak",
                                {
                                    ttsChunks =
                                    {

                                        {
                                            text = "TTSChunkOnly",
                                            type = "TEXT",
                                        },
                                    },
                                    speakType = "ALERT"
                                })
                    :Do(function(_,data)
                        self.hmiConnection:SendNotification("TTS.Started")
                        SpeakId = data.id

                        local function speakResponse()
                            self.hmiConnection:SendError(SpeakId, "TTS.Speak", "WARNINGS", "TTS_ERROR")

                            self.hmiConnection:SendNotification("TTS.Stopped")
                        end

                        RUN_AFTER(speakResponse, 2000)

                    end)
                    :ValidIf(function(_,data)
                        if #data.params.ttsChunks == 1 then
                            return true
                        else
                            print("ttsChunks array in TTS.Speak request has wrong element number. Expected 1, actual "..tostring(#data.params.ttsChunks))
                            return false
                        end
                    end)


                --mobile side: OnHMIStatus notifications
                ExpectOnHMIStatusWithAudioStateChanged_Alert(self, "speak")

                --mobile side: Alert response
                EXPECT_RESPONSE(CorIdAlert, { success = true, resultCode = "WARNINGS", info = "TTS_ERROR" })

            end

                    --End Test case



                          --Description: Only UI sent and respond with WARNINGS

                    function Test:Alert_Only_UI()

                    --mobile side: Alert request
                    local CorIdAlert = self.mobileSession:SendRPC("Alert",
                                                                    {

                                                                        alertText1 = "alertText1",

                                                                    })

                    local AlertId
                    --hmi side: UI.Alert request
                    EXPECT_HMICALL("UI.Alert",
                                    {
                                        alertStrings = {{fieldName = "alertText1", fieldText = "alertText1"}}

                                    })
                        :Do(function(_,data)
                            SendOnSystemContext(self,"ALERT")
                            AlertId = data.id

                            local function alertResponse()
                                self.hmiConnection:SendError(AlertId, "UI.Alert", "WARNINGS", "UI_ERROR")

                                SendOnSystemContext(self,"MAIN")
                            end

                            RUN_AFTER(alertResponse, 3000)
                        end)


                    --mobile side: OnHMIStatus notifications
                    ExpectOnHMIStatusWithAudioStateChanged_Alert(self, "alert")

                    --mobile side: Alert response
                    EXPECT_RESPONSE(CorIdAlert, { success = true, resultCode = "WARNINGS", info = "UI_ERROR" })

                end

                --End Test case



                ----------------------------------------------------------------------------------------------
                ---------------------------------------16 TEST BLOCK------------------------------------------
                ---------------------Check "WARNINGS" result code for PerformInteraction rpc------------------
                ----------------------------------------------------------------------------------------------

                --------Checks-----------

                --Description: check VR respond with WARNINGS

                --Requirement in JIRA: APPLINK-15261, APPLINK-15036

                --Verification criteria: In case SDL receives WARNINGS result code from HMI -> SDL must transfer WARNINGS (success:true) to mobile app


               --Precondition: send CreateInteractionChoiceSet with VR and UI:

                       function Test:CreateInteractionChoiceSet_Global_Precondition()
                                        --mobile side: sending CreateInteractionChoiceSet request
                                        local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
                                                                                                                        {
                                                                                                                                interactionChoiceSetID = 1011,
                                                                                                                                choiceSet =
                                                                                                                                {

                                                                                                                                        {
                                                                                                                                                choiceID = 1011,
                                                                                                                                                menuName ="Choice1011",
                                                                                                                                                vrCommands =
                                                                                                                                                {
                                                                                                                                                        "Choice1011"
                                                                                                                                                },
                                                                                                                                                image =
                                                                                                                                                {
                                                                                                                                                        value ="icon.png",
                                                                                                                                                        imageType ="DYNAMIC"
                                                                                                                                                }
                                                                                                                                        },
                                                                                                                                        {
                                                                                                                                                 choiceID = 1012,
                                                                                                                                                 menuName ="Choice1012",
                                                                                                                                                 vrCommands =
                                                                                                                                                 {
                                                                                                                                                          "Choice1012"
                                                                                                                                                 },
                                                                                                                                                 image =
                                                                                                                                                 {
                                                                                                                                                           value ="icon.png",
                                                                                                                                                           imageType ="DYNAMIC"
                                                                                                                                                 }
                                                                                                                                        },
                                                                                                                                        {
                                                                                                                                                  choiceID = 1013,
                                                                                                                                                  menuName ="Choice1013",
                                                                                                                                                  vrCommands =
                                                                                                                                                      {
                                                                                                                                                              "Choice1013"
                                                                                                                                                      },
                                                                                                                                                  image =
                                                                                                                                                      {
                                                                                                                                                          value ="icon.png",
                                                                                                                                                          imageType ="DYNAMIC"
                                                                                                                                                      }
                                                                                                                                         },
                                                                                                                                         {
                                                                                                                                                  choiceID = 1014,
                                                                                                                                                  menuName ="Choice1014",
                                                                                                                                                  vrCommands =
                                                                                                                                                      {
                                                                                                                                                         "Choice1014"
                                                                                                                                                      },
                                                                                                                                                  image =
                                                                                                                                                      {
                                                                                                                                                          value ="icon.png",
                                                                                                                                                          imageType ="DYNAMIC"
                                                                                                                                                      }
                                                                                                                                         }
                                                                                                                                }
                                                                                                                        })


                                        --hmi side: expect VR.AddCommand request
                                        EXPECT_HMICALL("VR.AddCommand",
                                                                        {
                                                                                cmdID = 1011,
                                                                                appID = applicationID,
                                                                                type = "Choice",
                                                                                vrCommands = {"Choice1011" }
                                                                        },
                                                                        {
                                                                                cmdID = 1012,
                                                                                appID = applicationID,
                                                                                type = "Choice",
                                                                                vrCommands = {"Choice1012" }
                                                                        },
                                                                        {
                                                                                cmdID = 1013,
                                                                                appID = applicationID,
                                                                                type = "Choice",
                                                                                vrCommands = {"Choice1013" }
                                                                        },
                                                                        {
                                                                                cmdID = 1014,
                                                                                appID = applicationID,
                                                                                type = "Choice",
                                                                                vrCommands = {"Choice1014" }
                                                                        })
                                                                        :Times(4)

                                        :Do(function(exp,data)
                                                --hmi side: sending VR.AddCommand response

                                                if exp.occurences == 1 or exp.occurences == 2 or exp.occurences == 3 or exp.occurences == 4 then
                                                              self.hmiConnection:SendResponse(data.id,"VR.AddCommand", "SUCCESS", {})

                                             end
                                        end)

                                        --mobile side: expect CreateInteractionChoiceSet response
                                        EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

                                        --mobile side: expect OnHashChange notification
                                        EXPECT_NOTIFICATION("OnHashChange")
                                end

                          --Start Test case

                                function Test:PI_VR_WARNINGS()
                                --mobile side: sending PerformInteraction request
                                local cid = self.mobileSession:SendRPC("PerformInteraction",
                                                                                            {
                                                                                             initialText = "StartPerformInteraction",
                                                                                             initialPrompt = {{
                                                                                                              text = "T",
                                                                                                              type = "TEXT"
                                                                                                             }},
                                                                                             interactionMode = "BOTH",
                                                                                             interactionChoiceSetIDList = {1011}
                                                                                             }
                                                                      )

                                --hmi side: expect VR.PerformInteraction request
                                EXPECT_HMICALL("VR.PerformInteraction",
                                {
                                       initialPromp = {{
                                                      text = "T",
                                                      type = "TEXT"
                                                      }},
                                        timeout = 10000
                                })
                                :Do(function(_,data)
                                        --Send notification to start TTS & VR
                                        self.hmiConnection:SendNotification("VR.Started")
                                        self.hmiConnection:SendNotification("TTS.Started")
                                        SendOnSystemContext(self,"VRSESSION")

                                        --First speak timeout and second speak started
                                        local function firstSpeakTimeOut()
                                                self.hmiConnection:SendNotification("TTS.Stopped")
                                                self.hmiConnection:SendNotification("TTS.Started")
                                        end
                                        RUN_AFTER(firstSpeakTimeOut, 50)

                                        local function vrResponse()
                                                --hmi side: send VR.PerformInteraction response
                                                self.hmiConnection:SendError(data.id, data.method, "WARNINGS","VR_ERROR")
                                                self.hmiConnection:SendNotification("VR.Stopped")
                                        end
                                        RUN_AFTER(vrResponse, 50)
                                end)

                                --hmi side: expect UI.PerformInteraction request
                                EXPECT_HMICALL("UI.PerformInteraction",
                                {
                                        timeout = 10000,
                                        choiceSet = {  {
                                                       choiceID = 1011,

                                                       }
                                                     }
                                })
                                :Do(function(_,data)
                                        --Choice icon list is displayed
                                        local function choiceIconDisplayed()
                                                SendOnSystemContext(self,"HMI_OBSCURED")
                                        end
                                        RUN_AFTER(choiceIconDisplayed, 15)

                                        --hmi side: send UI.PerformInteraction response
                                        local function uiResponse()
                                                self.hmiConnection:SendNotification("TTS.Stopped")
                                                self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
                                                SendOnSystemContext(self,"MAIN")
                                        end
                                        RUN_AFTER(uiResponse, 20)
                                end)

                                --mobile side: OnHMIStatus notifications
                                EXPECT_NOTIFICATION("OnHMIStatus",
                                        { hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"},
                                        { hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "VRSESSION"},
                                        { hmiLevel = "FULL", audioStreamingState = "ATTENUATED", systemContext = "VRSESSION"},
                                        { hmiLevel = "FULL", audioStreamingState = "ATTENUATED", systemContext = "HMI_OBSCURED"},
                                        { hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "HMI_OBSCURED"},
                                        { hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
                                :Times(6)

                                --mobile side: expect PerformInteraction response
                                EXPECT_RESPONSE(cid, { success = true, resultCode = "WARNINGS", info = "VR_ERROR"})
                        end
                --End Test case


                --Description: check UI respond with WARNINGS:


                                function Test:PI_UI_WARNINGS()
                                --mobile side: sending PerformInteraction request
                                local cid = self.mobileSession:SendRPC("PerformInteraction",
                                                                                            {
                                                                                             initialText = "StartPerformInteraction",
                                                                                             initialPrompt = {{
                                                                                                              text = "T",
                                                                                                              type = "TEXT"
                                                                                                             }},
                                                                                             interactionMode = "BOTH",
                                                                                             interactionChoiceSetIDList = {1011}
                                                                                             }
                                                                      )

                                --hmi side: expect VR.PerformInteraction request
                                EXPECT_HMICALL("VR.PerformInteraction",
                                {
                                      initialPrompt = {{
                                                      text = "T",
                                                      type = "TEXT"
                                                      }},
                                        timeout = 10000
                                })
                                :Do(function(_,data)
                                        --Send notification to start TTS & VR
                                        self.hmiConnection:SendNotification("VR.Started")
                                        self.hmiConnection:SendNotification("TTS.Started")
                                        SendOnSystemContext(self,"VRSESSION")

                                        --First speak timeout and second speak started
                                        local function firstSpeakTimeOut()
                                                self.hmiConnection:SendNotification("TTS.Stopped")
                                                self.hmiConnection:SendNotification("TTS.Started")
                                        end
                                        RUN_AFTER(firstSpeakTimeOut, 50)

                                        local function vrResponse()
                                                --hmi side: send VR.PerformInteraction response
                                                self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
                                                self.hmiConnection:SendNotification("VR.Stopped")
                                        end
                                        RUN_AFTER(vrResponse, 50)
                                end)

                                --hmi side: expect UI.PerformInteraction request
                                EXPECT_HMICALL("UI.PerformInteraction",
                                {
                                        timeout = 10000,
                                        choiceSet = {  {
                                                       choiceID = 1011,
                                                       menuName ="Choice1011",
                                                       image =
                                                              {
                                                               value = config.pathToSDL .. "icon.png",
                                                               imageType ="DYNAMIC"
                                                              }
                                                       }
                                                     }
                                })
                                :Do(function(_,data)
                                        --Choice icon list is displayed
                                        local function choiceIconDisplayed()
                                                SendOnSystemContext(self,"HMI_OBSCURED")
                                        end
                                        RUN_AFTER(choiceIconDisplayed, 15)

                                        --hmi side: send UI.PerformInteraction response
                                        local function uiResponse()
                                                self.hmiConnection:SendNotification("TTS.Stopped")
                                                self.hmiConnection:SendError(data.id, data.method, "WARNINGS", "UI_ERROR")
                                                SendOnSystemContext(self,"MAIN")
                                        end
                                        RUN_AFTER(uiResponse, 20)
                                end)

                                --mobile side: expect PerformInteraction response
                                EXPECT_RESPONSE(cid, { success = true, resultCode = "WARNINGS", info = "UI_ERROR"})
                        end



                --End Test case


                --Description: check VR and UI respond with WARNINGS:


                                function Test:PI_VR_UI_WARNINGS()
                                --mobile side: sending PerformInteraction request
                                local cid = self.mobileSession:SendRPC("PerformInteraction",
                                                                                            {
                                                                                             initialText = "StartPerformInteraction",
                                                                                             initialPrompt = {{
                                                                                                              text = "T",
                                                                                                              type = "TEXT"
                                                                                                             }},
                                                                                             interactionMode = "BOTH",
                                                                                             interactionChoiceSetIDList = {1011}
                                                                                             }
                                                                      )

                                --hmi side: expect VR.PerformInteraction request
                                EXPECT_HMICALL("VR.PerformInteraction",
                                {
                                      initialPrompt = {{
                                                      text = "T",
                                                      type = "TEXT"
                                                      }},
                                        timeout = 10000
                                })
                                :Do(function(_,data)
                                        --Send notification to start TTS & VR
                                        self.hmiConnection:SendNotification("VR.Started")
                                        self.hmiConnection:SendNotification("TTS.Started")
                                        SendOnSystemContext(self,"VRSESSION")

                                        --First speak timeout and second speak started
                                        local function firstSpeakTimeOut()
                                                self.hmiConnection:SendNotification("TTS.Stopped")
                                                self.hmiConnection:SendNotification("TTS.Started")
                                        end
                                        RUN_AFTER(firstSpeakTimeOut, 50)

                                        local function vrResponse()
                                                --hmi side: send VR.PerformInteraction response
                                                self.hmiConnection:SendError(data.id, data.method, "WARNINGS","VR_ERROR")
                                                self.hmiConnection:SendNotification("VR.Stopped")
                                        end
                                        RUN_AFTER(vrResponse, 50)
                                end)

                                --hmi side: expect UI.PerformInteraction request
                                EXPECT_HMICALL("UI.PerformInteraction",
                                {
                                        timeout = 10000,
                                        choiceSet = {  {
                                                       choiceID = 1011,
                                                       menuName ="Choice1011",
                                                       image =
                                                              {
                                                               value = config.pathToSDL .. "icon.png",
                                                               imageType ="DYNAMIC"
                                                              }
                                                       }
                                                     }
                                })
                                :Do(function(_,data)
                                        --Choice icon list is displayed
                                        local function choiceIconDisplayed()
                                                SendOnSystemContext(self,"HMI_OBSCURED")
                                        end
                                        RUN_AFTER(choiceIconDisplayed, 15)

                                        --hmi side: send UI.PerformInteraction response
                                        local function uiResponse()
                                                self.hmiConnection:SendNotification("TTS.Stopped")
                                                self.hmiConnection:SendError(data.id, data.method, "WARNINGS", "UI_ERROR")
                                                SendOnSystemContext(self,"MAIN")
                                        end
                                        RUN_AFTER(uiResponse, 20)
                                end)


                                --mobile side: expect PerformInteraction response
                                EXPECT_RESPONSE(cid, { success = true, resultCode = "WARNINGS"--[[,info = "UI_ERROR.VR_ERROR"--]]})
                        end

                 --End Test case





                ----------------------------------------------------------------------------------------------
                ---------------------------------------17 TEST BLOCK------------------------------------------
                ---------------------Check "WARNINGS" result code for PerformAudioPassThru rpc------------------
                ----------------------------------------------------------------------------------------------

                --------Checks-----------


                --Requirement in JIRA: APPLINK-15261, APPLINK-15036

                --Verification criteria: In case SDL receives WARNINGS result code from HMI -> SDL must transfer WARNINGS (success:true) to mobile app

                --Precinditions:

function Test:createTTSSpeakParameters(RequestParams)
    local param =  {}

    param["speakType"] =  "AUDIO_PASS_THRU"

    --initialPrompt
    if RequestParams["initialPrompt"]  ~= nil then
        param["ttsChunks"] =  {
                                {
                                    text = RequestParams.initialPrompt[1].text,
                                    type = RequestParams.initialPrompt[1].type,
                                },
                            }
    end

    return param
end

--Create UI expected result based on parameters from the request
function Test:createUIParameters(Request)
    local param =  {}

    param["muteAudio"] =  Request["muteAudio"]
    param["maxDuration"] =  Request["maxDuration"]

    local j = 0
    --audioPassThruDisplayText1
    if Request["audioPassThruDisplayText1"] ~= nil then
        j = j + 1
        if param["audioPassThruDisplayTexts"] == nil then
            param["audioPassThruDisplayTexts"] = {}
        end
        param["audioPassThruDisplayTexts"][j] = {
            fieldName = "audioPassThruDisplayText1",
            fieldText = Request["audioPassThruDisplayText1"]
        }
    end

    --audioPassThruDisplayText2
    if Request["audioPassThruDisplayText2"] ~= nil then
        j = j + 1
        if param["audioPassThruDisplayTexts"] == nil then
            param["audioPassThruDisplayTexts"] = {}
        end
        param["audioPassThruDisplayTexts"][j] = {
            fieldName = "audioPassThruDisplayText2",
            fieldText = Request["audioPassThruDisplayText2"]
        }
    end

    return param
end



local function ExpectOnHMIStatusWithAudioStateChanged_PerformAudioPassThru(self, level, isInitialPrompt,timeout)
    if timeout == nil then timeout = 20000 end
    if level == nil then  level = "FULL" end

    if
        level == "FULL" then
            if
                self.isMediaApplication == true or
                Test.appHMITypes["NAVIGATION"] == true then
                if isInitialPrompt == true then
                    EXPECT_NOTIFICATION("OnHMIStatus",
                            { hmiLevel = level, audioStreamingState = "ATTENUATED", systemContext = "MAIN"},
                            { hmiLevel = level, audioStreamingState = "ATTENUATED", systemContext = "HMI_OBSCURED"},
                            { hmiLevel = level, audioStreamingState = "AUDIBLE", systemContext = "HMI_OBSCURED"},
                            { hmiLevel = level, audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
                    :Times(4)
                    :Timeout(timeout)
                else
                    EXPECT_NOTIFICATION("OnHMIStatus",
                            { hmiLevel = level, audioStreamingState = "AUDIBLE", systemContext = "HMI_OBSCURED"},
                            { hmiLevel = level, audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
                    :Times(2)
                    :Timeout(timeout)
                end
            elseif
                self.isMediaApplication == false then
                    EXPECT_NOTIFICATION("OnHMIStatus",
                                { hmiLevel = level, audioStreamingState = "NOT_AUDIBLE", systemContext = "HMI_OBSCURED"},
                                { hmiLevel = level, audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
                    :Times(2)
                    :Timeout(timeout)
            end
    elseif
        level == "LIMITED" then

            if
                self.isMediaApplication == true or
                Test.appHMITypes["NAVIGATION"] == true then
                    if isInitialPrompt == true then
                        EXPECT_NOTIFICATION("OnHMIStatus",
                                { hmiLevel = level, audioStreamingState = "ATTENUATED", systemContext = "MAIN"},
                                { hmiLevel = level, audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
                        :Times(2)
                        :Timeout(timeout)
                    else
                        EXPECT_NOTIFICATION("OnHMIStatus")
                        :Times(0)
                        :Timeout(timeout)
                    end
            elseif
                self.isMediaApplication == false then

                    EXPECT_NOTIFICATION("OnHMIStatus")
                    :Times(0)

                    EXPECT_NOTIFICATION("OnAudioPassThru")
                    :Times(0)

                    DelayedExp(1000)
            end
    elseif
        level == "BACKGROUND" then

            EXPECT_NOTIFICATION("OnHMIStatus")
            :Times(0)

            EXPECT_NOTIFICATION("OnAudioPassThru")
            :Times(0)

            DelayedExp(1000)
    end
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



function Test:verify_Warnings_TTS_Case_PerformAudioPathThru(RequestParams, level)
    if level == nil then  level = "FULL" end

    --mobile side: sending PerformAudioPassThru request
    local cid = self.mobileSession:SendRPC("PerformAudioPassThru", RequestParams)

    --commonFunctions:printTable(RequestParams)

    UIParams = self:createUIParameters(RequestParams)
    TTSSpeakParams = self:createTTSSpeakParameters(RequestParams)

    if RequestParams["initialPrompt"]  ~= nil then
        --hmi side: expect TTS.Speak request
        EXPECT_HMICALL("TTS.Speak", TTSSpeakParams)
        :Do(function(_,data)
            --Send notification to start TTS
            self.hmiConnection:SendNotification("TTS.Started")

            local function ttsSpeakResponse()
                --hmi side: sending TTS.Speak response
                self.hmiConnection:SendError(data.id, data.method, "WARNINGS", "TTS_Error")

                --Send notification to stop TTS
                self.hmiConnection:SendNotification("TTS.Stopped")

                --hmi side: expect UI.OnRecordStart
                EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})
            end

            RUN_AFTER(ttsSpeakResponse, 50)
        end)
    end

    --hmi side: expect UI.PerformAudioPassThru request
    EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
    :Do(function(_,data)
        SendOnSystemContext(self,"HMI_OBSCURED")


        local function uiResponse()
            --hmi side: sending UI.PerformAudioPassThru response
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})

            SendOnSystemContext(self,"MAIN")
        end

        RUN_AFTER(uiResponse, 1500)
    end)

    ExpectOnHMIStatusWithAudioStateChanged_PerformAudioPassThru(self, level, RequestParams["initialPrompt"]  ~= nil)

    --mobile side: expect OnAudioPassThru response
    EXPECT_NOTIFICATION("OnAudioPassThru")
    :Times(1)
    :Timeout(10000)

    --mobile side: expect PerformAudioPassThru response
    EXPECT_RESPONSE(cid, { success = true, resultCode = "WARNINGS", info = "TTS_ERROR" })
    :ValidIf (function(_,data)
        if file_check(config.pathToSDL .. "storage/" .. "audio.wav") ~= true then
            print(" \27[36m Can not found file: audio.wav \27[0m ")
            return false
        else
            return true
        end
    end)

    DelayedExp(1000)
end


function Test:PerformAudioPassThru_WARNINGS_TTS()
                local params = {
                                    initialPrompt =
                                    {
                                        {
                                            text ="Makeyourchoice",
                                            type ="TEXT",
                                        },
                                    },
                                    audioPassThruDisplayText1 ="DisplayText1",
                                    audioPassThruDisplayText2 ="DisplayText2",
                                    samplingRate ="8KHZ",
                                    maxDuration = 2000,
                                    bitsPerSample ="8_BIT",
                                    audioType ="PCM",
                                    muteAudio = true,
                                  }
                self:verify_Warnings_TTS_Case_PerformAudioPathThru(params)
            end


-- End Test case




 --[[ Question: APPLINK-18612

            -- Description: only TTS send and respond with WARNINGS:



            function Test:verify_Warnings_Only_TTS_Case_PerformAudioPathThru(RequestParams, level)
    if level == nil then  level = "FULL" end

    --mobile side: sending PerformAudioPassThru request
    local cid = self.mobileSession:SendRPC("PerformAudioPassThru", RequestParams)

    --commonFunctions:printTable(RequestParams)


    TTSSpeakParams = self:createTTSSpeakParameters(RequestParams)

    if RequestParams["initialPrompt"]  ~= nil then
        --hmi side: expect TTS.Speak request
        EXPECT_HMICALL("TTS.Speak", TTSSpeakParams)
        :Do(function(_,data)
            --Send notification to start TTS
            self.hmiConnection:SendNotification("TTS.Started")

            local function ttsSpeakResponse()
                --hmi side: sending TTS.Speak response
                self.hmiConnection:SendError(data.id, data.method, "WARNINGS", "TTS_Error")

                --Send notification to stop TTS
                self.hmiConnection:SendNotification("TTS.Stopped")

                --hmi side: expect UI.OnRecordStart
                EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})
            end

            RUN_AFTER(ttsSpeakResponse, 50)
        end)
    end

    ExpectOnHMIStatusWithAudioStateChanged_PerformAudioPassThru(self, level, RequestParams["initialPrompt"]  ~= nil)

    --mobile side: expect OnAudioPassThru response
    EXPECT_NOTIFICATION("OnAudioPassThru")
    :Times(1)
    :Timeout(10000)

    --mobile side: expect PerformAudioPassThru response
    EXPECT_RESPONSE(cid, { success = true, resultCode = "WARNINGS", info = "TTS_ERROR" })
    :ValidIf (function(_,data)
        if file_check(config.SDLStoragePath.."/".."audio.wav") ~= true then
            print(" \27[36m Can not found file: audio.wav \27[0m ")
            return false
        else
            return true
        end
    end)

    DelayedExp(1000)
end


function Test:PerformAudioPassThru_WARNINGS_Only_TTS()
                local params = {
                                    initialPrompt =
                                    {
                                        {
                                            text ="Makeyourchoice",
                                            type ="TEXT",
                                        },
                                    },
                                    audioPassThruDisplayText1 ="DisplayText1",
                                    audioPassThruDisplayText2 ="DisplayText2",
                                    samplingRate ="8KHZ",
                                    maxDuration = 2000,
                                    bitsPerSample ="8_BIT",
                                    audioType ="PCM",
                                    muteAudio = true,
                                  }
                self:verify_Warnings_Only_TTS_Case_PerformAudioPathThru(params)
            end
--]]

-- End Test case

                --Description: check UI respond with WARNINGS

            function Test:verify_Warnings_UI_Case_PerformAudioPathThru(RequestParams, level)
            if level == nil then  level = "FULL" end

    --mobile side: sending PerformAudioPassThru request
    local cid = self.mobileSession:SendRPC("PerformAudioPassThru", RequestParams)

    --commonFunctions:printTable(RequestParams)

    UIParams = self:createUIParameters(RequestParams)
    TTSSpeakParams = self:createTTSSpeakParameters(RequestParams)

    if RequestParams["initialPrompt"]  ~= nil then
        --hmi side: expect TTS.Speak request
        EXPECT_HMICALL("TTS.Speak", TTSSpeakParams)
        :Do(function(_,data)
            --Send notification to start TTS
            self.hmiConnection:SendNotification("TTS.Started")

            local function ttsSpeakResponse()
                --hmi side: sending TTS.Speak response
                self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})

                --Send notification to stop TTS
                self.hmiConnection:SendNotification("TTS.Stopped")

                --hmi side: expect UI.OnRecordStart
                EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})
            end

            RUN_AFTER(ttsSpeakResponse, 50)
        end)
    end

    --hmi side: expect UI.PerformAudioPassThru request
    EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
    :Do(function(_,data)
        SendOnSystemContext(self,"HMI_OBSCURED")


        local function uiResponse()
            --hmi side: sending UI.PerformAudioPassThru response
            self.hmiConnection:SendError(data.id, data.method, "WARNINGS", "UI_ERROR")

            SendOnSystemContext(self,"MAIN")
        end

        RUN_AFTER(uiResponse, 1500)
    end)

    ExpectOnHMIStatusWithAudioStateChanged_PerformAudioPassThru(self, level, RequestParams["initialPrompt"]  ~= nil)

    --mobile side: expect OnAudioPassThru response
    EXPECT_NOTIFICATION("OnAudioPassThru")
    :Times(1)
    :Timeout(10000)

    --mobile side: expect PerformAudioPassThru response
    EXPECT_RESPONSE(cid, { success = true, resultCode = "WARNINGS", info = "UI_ERROR" })
    :ValidIf (function(_,data)
        if file_check(storagePath .."/".."audio.wav") ~= true then
            print(" \27[36m Can not found file: audio.wav \27[0m ")
            return false
        else
            return true
        end
    end)

    DelayedExp(1000)
end


function Test:PerformAudioPassThru_WARNINGS_UI()
                local params = {
                                    initialPrompt =
                                    {
                                        {
                                            text ="Makeyourchoice",
                                            type ="TEXT",
                                        },
                                    },
                                    audioPassThruDisplayText1 ="DisplayText1",
                                    audioPassThruDisplayText2 ="DisplayText2",
                                    samplingRate ="8KHZ",
                                    maxDuration = 2000,
                                    bitsPerSample ="8_BIT",
                                    audioType ="PCM",
                                    muteAudio = true,
                                  }
                self:verify_Warnings_UI_Case_PerformAudioPathThru(params)
            end

-- End Test case

                --Description: check TTS and UI respond with WARNINGS


            function Test:verify_Warnings_UI_TTS_Case_PerformAudioPathThru(RequestParams, level)
            if level == nil then  level = "FULL" end

    --mobile side: sending PerformAudioPassThru request
    local cid = self.mobileSession:SendRPC("PerformAudioPassThru", RequestParams)

    --commonFunctions:printTable(RequestParams)

    UIParams = self:createUIParameters(RequestParams)
    TTSSpeakParams = self:createTTSSpeakParameters(RequestParams)

    if RequestParams["initialPrompt"]  ~= nil then
        --hmi side: expect TTS.Speak request
        EXPECT_HMICALL("TTS.Speak", TTSSpeakParams)
        :Do(function(_,data)
            --Send notification to start TTS
            self.hmiConnection:SendNotification("TTS.Started")

            local function ttsSpeakResponse()
                --hmi side: sending TTS.Speak response
                self.hmiConnection:SendError(data.id, data.method, "WARNINGS", "TTS_ERROR")

                --Send notification to stop TTS
                self.hmiConnection:SendNotification("TTS.Stopped")

                --hmi side: expect UI.OnRecordStart
                EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})
            end

            RUN_AFTER(ttsSpeakResponse, 50)
        end)
    end

    --hmi side: expect UI.PerformAudioPassThru request
    EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
    :Do(function(_,data)
        SendOnSystemContext(self,"HMI_OBSCURED")


        local function uiResponse()
            --hmi side: sending UI.PerformAudioPassThru response
            self.hmiConnection:SendError(data.id, data.method, "WARNINGS", "UI_ERROR")

            SendOnSystemContext(self,"MAIN")
        end

        RUN_AFTER(uiResponse, 1500)
    end)

    ExpectOnHMIStatusWithAudioStateChanged_PerformAudioPassThru(self, level, RequestParams["initialPrompt"]  ~= nil)

    --mobile side: expect OnAudioPassThru response
    EXPECT_NOTIFICATION("OnAudioPassThru")
    :Times(1)
    :Timeout(10000)

    --mobile side: expect PerformAudioPassThru response
    EXPECT_RESPONSE(cid, { success = true, resultCode = "WARNINGS", info = "" })
    :ValidIf (function(_,data)
        if file_check(storagePath .."/".."audio.wav") ~= true then
            print(" \27[36m Can not found file: audio.wav \27[0m ")
            return false
        else
            return true
        end
    end)

    DelayedExp(1000)
end


function Test:PerformAudioPassThru_WARNINGS_UI_TTS()
                local params = {
                                    initialPrompt =
                                    {
                                        {
                                            text ="Makeyourchoice",
                                            type ="TEXT",
                                        },
                                    },
                                    audioPassThruDisplayText1 ="DisplayText1",
                                    audioPassThruDisplayText2 ="DisplayText2",
                                    samplingRate ="8KHZ",
                                    maxDuration = 2000,
                                    bitsPerSample ="8_BIT",
                                    audioType ="PCM",
                                    muteAudio = true,
                                  }
                self:verify_Warnings_UI_TTS_Case_PerformAudioPathThru(params)
            end


-- End Test case



                ----------------------------------------------------------------------------------------------
                ---------------------------------------18 TEST BLOCK------------------------------------------
                -------------------Check "WARNINGS" result code for SubscribeVehicleData rpc------------------
                ----------------------------------------------------------------------------------------------

                --------Checks-----------

                --Description: check SubscribeVehicleData respond with WARNINGS

                --Requirement in JIRA: APPLINK-15261, APPLINK-15036

                --Verification criteria: In case SDL receives WARNINGS result code from HMI -> SDL must transfer WARNINGS (success:true) to mobile app

        function Test:SubscribeVehicleData_WARNINGS()

       --mobile side: sending SubscribeVehicleData request
        local cid = self.mobileSession:SendRPC("SubscribeVehicleData",
                                               { gps = true,
                                                 speed = true
                                               }
                                              )

        --hmi side: expect SubscribeVehicleData request
        EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData",
                              { gps = true,
                                speed = true
                              }
                      )
        :Do(function(_,data)
                --hmi side: sending VehicleInfo.SubscribeVehicleData response
                self.hmiConnection:SendError(data.id, data.method, "WARNINGS", "Small error")
        end)


        --mobile side: expect SubscribeVehicleData response
         EXPECT_RESPONSE(cid, { success = true, resultCode = "WARNINGS", info = "Small error"})

        --mobile side: expect OnHashChange notification
        EXPECT_NOTIFICATION("OnHashChange")
end





                ----------------------------------------------------------------------------------------------
                ---------------------------------------19 TEST BLOCK------------------------------------------
                -------------------Check "WARNINGS" result code for UnsubscribeVehicleData rpc------------------
                ----------------------------------------------------------------------------------------------

                --------Checks-----------

                --Description: check UnsubscribeVehicleData respond with WARNINGS

                --Requirement in JIRA: APPLINK-15261, APPLINK-15036

                --Verification criteria: In case SDL receives WARNINGS result code from HMI -> SDL must transfer WARNINGS (success:true) to mobile app

        function Test:UnsubscribeVehicleData_WARNINGS()

       --mobile side: sending UnsubscribeVehicleData request
        local cid = self.mobileSession:SendRPC("UnsubscribeVehicleData",
                                               { gps = true,
                                                 speed = true
                                               }
                                              )

        --hmi side: expect UnsubscribeVehicleData request
        EXPECT_HMICALL("VehicleInfo.UnsubscribeVehicleData",
                              { gps = true,
                                speed = true
                              }
                      )
        :Do(function(_,data)

                --hmi side: sending VehicleInfo.UnsubscribeVehicleData response
                self.hmiConnection:SendError(data.id, data.method, "WARNINGS", "Small error")
        end)


        --mobile side: expect UnsubscribeVehicleData response
         EXPECT_RESPONSE(cid, { success = true, resultCode = "WARNINGS", info = "Small error"})

        --mobile side: expect OnHashChange notification
        EXPECT_NOTIFICATION("OnHashChange")
end



                ----------------------------------------------------------------------------------------------
                ---------------------------------------20 TEST BLOCK------------------------------------------
                ---------------------Check "WARNINGS" result code for RegisterAppInterface rpc------------------
                ----------------------------------------------------------------------------------------------

                --------Checks-----------

                --Description: check RAI respond with WARNINGS

                --Requirement in JIRA: APPLINK-15261, APPLINK-15036

                --Verification criteria: In case SDL receives WARNINGS result code from HMI -> SDL must transfer WARNINGS (success:true) to mobile app


                                        -- Precondition: The application should be unregistered before next test.

                                        function Test:UnregisterAppInterface_Success()

                                                UnregisterApplicationSessionOne(self)
                                        end



                        function Test:RAI_WARNINGS()

                                --mobile side: RegisterAppInterface request

                                --  type ="PRE_RECORDED" is not supported (absent in capabilities)

                                local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
                                                                                                                        {

                                                                                                                                syncMsgVersion =
                                                                                                                                {
                                                                                                                                        majorVersion = 2,
                                                                                                                                        minorVersion = 2,
                                                                                                                                },
                                                                                                                                appName ="SyncProxyTester",
                                                                                                                                ttsName =
                                                                                                                                {

                                                                                                                                        {
                                                                                                                                                text ="4005",
                                                                                                                                                type ="PRE_RECORDED",
                                                                                                                                        },
                                                                                                                                },
                                                                                                                                isMediaApplication = true,
                                                                                                                                languageDesired ="EN-US",
                                                                                                                                hmiDisplayLanguageDesired ="EN-US",
                                                                                                                                appID ="123456",

                                                                                                                        })

                                --mobile side: RegisterAppInterface response
                                self.mobileSession:ExpectResponse(CorIdRAI, { success = true, resultCode = "WARNINGS"})

                        end
end
---------------------------------------------------------------------------------------------
-------------------------------------------Postcondition-------------------------------------
---------------------------------------------------------------------------------------------

	--Print new line to separate Postconditions
	commonFunctions:newTestCasesGroup("Postconditions")


	--Restore sdl_preloaded_pt.json
	policyTable:Restore_preloaded_pt()


 return Test

