Test = require('connecttest')
require('cardinalities')
local events = require('events')
local mobile_session = require('mobile_session')

---------------------------------------------------------------------------------------------
-------------------------------------------Common function-----------------------------------
---------------------------------------------------------------------------------------------

local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local policyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
require('user_modules/AppTypes')


local config2 = require('user_modules/config_on_input_keyboard')
config.application1 = config2.application1
config.application2 = config2.application2
config.application3 = config2.application3
config.application4 = config2.application4
config.application5 = config2.application5


APIName = "OnKeyboardInput"

function DelayedExp()
        local event = events.Event()
        event.matches = function(self, e) return self == e end
        EXPECT_EVENT(event, "Delayed event")
        RUN_AFTER(function()
                RAISE_EVENT(event, event)
        end, 2000)
end

local function userPrint(color, message)
  print ("\27[" .. tostring(color) .. "m " .. tostring(message) .. " \27[0m")
end

local function testName(name, testType)
        if testType == "test" then
           testType = "=== Test - "
        elseif testType == "pre" then
            testType = "=== Precondition - "
        else
                testType = "=== Test - "
        end
        userPrint(33, testType .. name .. " ===")
end

local function removePolicyDB()
        os.execute("rm -rf " .. config.pathToSDL .. "storage/")
end

local function setInitialPrompt()
        local temp = {{
                text = "Make a choice",
                type = "TEXT",
        }}

        return temp
end

local function setHelpPrompt()
        local temp = {{
                text = "say yes or no",
                type = "TEXT",
        }}

        return temp
end

local function setTimeoutPrompt(size, character, outChar)
        local temp = {{
                text = "time out",
                type = "TEXT",
                }}
        return temp
end

local function setVrHelp(size, character, outChar)
        local temp = {{
                text = "help",
                position = 1,
                -- image = setImage()
        }}

        return temp
end

function setChoiseSet(choiceIDValue, size)
        if (size == nil) then
                local cs = {{
                        choiceID = choiceIDValue,
                        menuName ="Choice" .. tostring(choiceIDValue),
                        vrCommands =
                        {
                                "VrChoice" .. tostring(choiceIDValue),
                        }
                }}
                return cs
        else
                local cs = {}
        for i = 1, size do
                cs[i] = {
                                choiceID = choiceIDValue+i-1,
                                menuName ="Choice" .. tostring(choiceIDValue+i-1),
                                vrCommands =
                                {
                                        "VrChoice" .. tostring(choiceIDValue+i-1),
                                }
                        }
        end
        return temp
        end
end

function createInteractionChoiceSet(self, choiceSetID, choiceID, session)
        session = session or 1
        --mobile side: sending CreateInteractionChoiceSet request
        local cid = nil
        if session == 1 then
                cid = self.mobileSession:SendRPC(
                        "CreateInteractionChoiceSet",
                        {
                                interactionChoiceSetID = choiceSetID,
                                choiceSet = setChoiseSet(choiceID),
                        })
        else
                cid = self.mobileSession1:SendRPC(
                        "CreateInteractionChoiceSet",
                        {
                                interactionChoiceSetID = choiceSetID,
                                choiceSet = setChoiseSet(choiceID),
                        })
        end

        --hmi side: expect VR.AddCommand
        EXPECT_HMICALL(
                "VR.AddCommand",
                {
                        cmdID = choiceID,
                        type = "Choice",
                        vrCommands = {"VrChoice"..tostring(choiceID) }
                })
        :Do(function(_,data)
                        --hmi side: sending VR.AddCommand response
                        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
                end)

        --mobile side: expect CreateInteractionChoiceSet response
        if session == 1 then
                EXPECT_RESPONSE(cid, { resultCode = "SUCCESS", success = true  })
        else
                self.mobileSession1:ExpectResponse(cid, { resultCode = "SUCCESS", success = true  })
        end
end

function createPerformInteraction(layout)
        layout = layout or "KEYBOARD"
        local temp = {
                                initialText = "Make a Choice!",
                                initialPrompt = setInitialPrompt(),
                                interactionMode = "MANUAL_ONLY",
                                interactionChoiceSetIDList = {100},
                                helpPrompt = setHelpPrompt(),
                                timeoutPrompt = setTimeoutPrompt(),
                                timeout = 5000,
                                -- vrHelp = setVrHelp(),
                                interactionLayout = layout
                        }
        return temp
end

local function SendOnSystemContext(self, ctx, session)
        session = session or 1
        if session == 1 then
                self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = ctx })
        else
                self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application2"], systemContext = ctx })
        end
end

local function SendPerformInteraction(self, name, keyEvent, level, layout, session)
        session = session or 1
        layout = layout or "KEYBOARD"

        testName(name .. "(" ..keyEvent ..")")
        local parametersToSend = createPerformInteraction(layout)
        local cid = nil
        if session == 1 then
                cid = self.mobileSession:SendRPC("PerformInteraction", parametersToSend)
        else
                cid = self.mobileSession1:SendRPC("PerformInteraction", parametersToSend)
        end

        EXPECT_HMICALL(
                "UI.PerformInteraction",
                {
                        timeout = parametersToSend.timeout,
                        -- choiceSet = setExChoiseSet(parametersToSend.interactionChoiceSetIDList),
                        initialText =
                        {
                                fieldName = "initialInteractionText",
                                fieldText = parametersToSend.initialText
                        }
                })
        :Do(function(_,data)
                        --hmi side: send UI.PerformInteraction response
                        SendOnSystemContext(self,"HMI_OBSCURED", session)
                        self.hmiConnection:SendNotification("UI.OnKeyboardInput",{data="abc", event=keyEvent})
                        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {manualTextEntry="abc"})

                        --Send notification to stop TTS
                        self.hmiConnection:SendNotification("TTS.Stopped")
                        SendOnSystemContext(self,"MAIN", session)
                end)

        --mobile side: OnHMIStatus notifications
        if ( (level == "FULL") and (session == 1) ) then
                userPrint(33, "expext OnHMIStatus on 1st session")
                EXPECT_NOTIFICATION(
                        "OnHMIStatus",
                        { hmiLevel = level, audioStreamingState = "AUDIBLE", systemContext = "HMI_OBSCURED"},
                        { hmiLevel = level, audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
                :Times(2)
        elseif level == "FULL" then
                userPrint(33, "expext OnHMIStatus on 2nd session")
                self.mobileSession1:ExpectNotification(
                        "OnHMIStatus",
                        { hmiLevel = level, audioStreamingState = "AUDIBLE", systemContext = "HMI_OBSCURED"},
                        { hmiLevel = level, audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
                :Times(2)
        end
        --mobile side: expect PerformInteraction response
        if session == 1 then
                EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", manualTextEntry="abc" })
        else
                self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS", manualTextEntry="abc" })
        end

        if session == 1 then
                if layout == "KEYBOARD" then
                        EXPECT_NOTIFICATION("OnKeyboardInput", {data="abc", event=keyEvent})
                        :Times(1)

                        DelayedExp(100)
                elseif level == "FULL" then
                        EXPECT_NOTIFICATION("OnKeyboardInput", {data="abc", event=keyEvent})
                        :Times(1)

                        DelayedExp(100)
                else
                        EXPECT_NOTIFICATION("OnKeyboardInput", {data="abc", event=keyEvent})
                        :Times(0)

                        DelayedExp(100)
                end
        else
                if layout == "KEYBOARD" then
                    self.mobileSession1:ExpectNotification("OnKeyboardInput", {data="abc", event=keyEvent})
                    :Times(1)

                        DelayedExp(100)
                elseif level == "FULL" then
                        self.mobileSession1:ExpectNotification("OnKeyboardInput", {data="abc", event=keyEvent})
                        :Times(1)

                        DelayedExp(100)
                else
                        self.mobileSession1:ExpectNotification("OnKeyboardInput", {data="abc", event=keyEvent})
                        :Times(0)

                        DelayedExp(100)
                end
        end
end

function Test:activateApp(applicationID, session)
        session = session or 1
        userPrint(33, "session: " .. session)
        local deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
        --hmi side: sending SDL.ActivateApp request
        local cid = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = applicationID})

        --hmi side: expect SDL.ActivateApp response
        -- TODO: next if could be dropped after fixing APPLINK-16094
        if session == 1 then
                EXPECT_HMIRESPONSE(cid)
                        :Do(function(_,data)
                                --In case when app is not allowed, it is needed to allow app
                                if data.result.isSDLAllowed ~= true then
                                        --hmi side: sending SDL.GetUserFriendlyMessage request
                                        local cid = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage",
                                                                                {language = "EN-US", messageCodes = {"DataConsent"}})

                                        --hmi side: expect SDL.GetUserFriendlyMessage response
                                        --TODO: Update after resolving APPLINK-16094 EXPECT_HMIRESPONSE(cid,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
                                        EXPECT_HMIRESPONSE(cid)
                                                :Do(function(_,data)

                                                        --hmi side: send request SDL.OnAllowSDLFunctionality
                                                        self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality",
                                                                {allowed = true, source = "GUI", device = {id = deviceMAC, name = "127.0.0.1"}})


                                                        --hmi side: expect BasicCommunication.ActivateApp request
                                                        EXPECT_HMICALL("BasicCommunication.ActivateApp")
                                                                :Do(function(_,data)

                                                                        --hmi side: sending BasicCommunication.ActivateApp response
                                                                        self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})

                                                                end)
                                                                --:Times(2) - according APPLINK-9283 we send "device" parameter, so expect "BasicCommunication.ActivateApp" one time
                                                                :Times(1)
                                                end)

                        end
                end)
        end

        --mobile side: expect notification
        if session == 1 then
            EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"})
        else
                self.mobileSession1:ExpectNotification("OnHMIStatus",{hmiLevel = "FULL", systemContext = "MAIN"})
        end
end


local HMIappID = nil

---------------------------------------------------------------------------------------------
---------------------------------------End Common function-----------------------------------
---------------------------------------------------------------------------------------------



---------------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------
	
	commonSteps:DeleteLogsFileAndPolicyTable()
	
	--Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup("Preconditions")
	
	--1. Activate application
	commonSteps:ActivationApp()

	--2. Update policy to allow request
	--TODO: Will be updated after policy flow implementation
	--policyTable:precondition_updatePolicy_AllowFunctionInHmiLeves({"BACKGROUND", "FULL", "LIMITED", "NONE"})
	policyTable:Precondition_updatePolicy_By_overwriting_preloaded_pt("files/jsons/CRQ_APPLINK-13177/sdl_preloaded_pt.json")


---------------------------------------------------------------------------------------------
-----------------------------------------I TEST BLOCK----------------------------------------
------------OnKeyboardInput: PerformInteraction(KEYBOARD) with one registered App------------
---------------------------------------------------------------------------------------------
        --Begin Test suit PositiveRequestCheck

        --Description: TC's checks that
                -- SDL must transfer OnKeyboardInput notification to the app associated with active PerfromInteraction (KEYBOARD) request
                -- SDL must transfer OnKeyboardInput notification to any app that is currently in FULL if there is no active PerformInteraction (KEYBOARD)


                --Begin Test case CommonRequestCheck.1
                --Description: This test is intended to check positive cases and when all parameters are in boundary conditions

                        --Requirement id in JAMA:
                                        -- TBD

                        --Verification criteria:

-- BEGIN TEST CASE 1.1
-- Description: SDL must transfer OnKeyboardInput notification to the associated App (FULL)

local tKeyboardEvent = {"KEYPRESS", "ENTRY_SUBMITTED", "ENTRY_VOICE", "ENTRY_CANCELLED", "ENTRY_ABORTED"}

function Test:PreconditionChoiceSet()
        testName("Create choice set", "pre")
        createInteractionChoiceSet(self, 100, 100)
end

for i,v in ipairs(tKeyboardEvent) do
        Test["PerfromInteractionFromFull" .. v] = function (self)
                SendPerformInteraction(self, "SDL transfer OnKeyboardInput to associated App in FULL", v, "FULL")
        end
end
-- END TESTCASE 1.1

-- BEGIN TEST CASE 1.2.
-- Description: SDL must transfer OnKeyboardInput notification to the associated App (LIMITED)
function Test:PreconditionSwitchToAnotherPage()
        testName("Switch to another page", "pre")
        self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", {appID = self.applications["Test Application"], reason = "GENERAL"})
        EXPECT_NOTIFICATION(
                "OnHMIStatus",
                { hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
        :Times(1)
end

for i,v in ipairs(tKeyboardEvent) do
        Test["PerfromInteractionFromLIMITED" .. v] = function (self)
                SendPerformInteraction(self, "SDL transfer OnKeyboardInput to associated App in LIMITED", v, "LIMITED")
        end
end
-- END TESTCASE 1.2

-- BEGIN TEST CASE 1.3
-- Description: SDL must transfer OnKeyboard notification to the associated App (BACKGROUND)
function Test:PreconditionDeactivateApp1()
        testName("Deactivate App", "pre")

    -- according to CRQ APPLINK-17839
    -- self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", {appID = self.applications["Test Application"], reason = "AUDIO"}

        self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged", {eventName="AUDIO_SOURCE",isActive = true})
        EXPECT_NOTIFICATION(
                "OnHMIStatus",
                { hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
        :Times(1)
end

for i,v in ipairs(tKeyboardEvent) do
        Test["PerfromInteractionFromBACKGROUND" .. v] = function (self)
                SendPerformInteraction(self, "SDL transfer OnKeyboardInput to associated App in BACKGROUND", v, "BACKGROUND")
        end
end
-- END TESTCASE 1.3

-- BEGIN TEST CASE 1.4
-- Description: SDL transfer OnKeyboardInput notification only to active App if there is no Apps associated with PerformInteraction(KEYBOARD)
local tLayouts = {"ICON_ONLY", "ICON_WITH_SEARCH", "LIST_ONLY", "LIST_WITH_SEARCH"}

--Begin Precondition.1
--Description: AudioSource - end
function Test:EndAudioSource( ... )
        -- body
        self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged", {eventName="AUDIO_SOURCE",isActive = false})
        EXPECT_NOTIFICATION("OnHMIStatus", { hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
        :Times(1)
end

--Begin Precondition.2
--Description: Activation App by sending SDL.ActivateApp
commonSteps:ActivationApp()

--End Precondition.1

for i,layoutValue in ipairs(tLayouts) do
        for i,keyboardValue in ipairs(tKeyboardEvent) do
                Test["PerformInteraction_"..layoutValue.."_"..keyboardValue] = function (self)
                        SendPerformInteraction(self, "SDL transfer OnKeyboardInput only to App in FULL", keyboardValue, "FULL", layoutValue)
                end
        end
end
-- END TESTCASE 1.4

-- BEGIN TEST CASE 1.5
-- Description: SDL doesn't transfer OnKeyboardInput notification to LIMITED App if there is no Apps associated with PerformInteraction(KEYBOARD)
function Test:PreconditionSwitchToAnotherPage()
        testName("Switch to another page", "pre")
        self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", {appID = self.applications["Test Application"], reason = "GENERAL"})
        EXPECT_NOTIFICATION(
                "OnHMIStatus",
                { hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
        :Times(1)
end

for i,layoutValue in ipairs(tLayouts) do
        for i,keyboardValue in ipairs(tKeyboardEvent) do
                Test["PerformInteraction_"..layoutValue.."_"..keyboardValue] = function (self)
                        SendPerformInteraction(self, "SDL transfer OnKeyboardInput only to App in LIMITED", keyboardValue, "LIMITED", layoutValue)
                end
        end
end
-- END TESTCASE 1.5

-- BEGIN TEST CASE 1.6
-- Description: SDL doesn't transfer OnKeyboardInput notification to BACKGROUND App if there is no Apps associated with PerformInteraction(KEYBOARD)
function Test:PreconditionDeactivateApp1()
        testName("Deactivate App", "pre")

        -- according to CRQ APPLINK-17839
    -- self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", {appID = self.applications["Test Application"], reason = "AUDIO"}

        self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged", {eventName="AUDIO_SOURCE",isActive = true})
        EXPECT_NOTIFICATION(
                "OnHMIStatus",
                { hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
        :Times(1)
end

for i,layoutValue in ipairs(tLayouts) do
        for i,keyboardValue in ipairs(tKeyboardEvent) do
                Test["PerformInteraction" .. layoutValue .. keyboardValue] = function (self)
                        SendPerformInteraction(self, "SDL transfer OnKeyboardInput only to App in BACKGROUND", keyboardValue, "BACKGROUND", layoutValue)
                end
        end
end
-- END TESTCASE 1.6

-- BEGIN TEST CASE 1.7
-- Description: One App - no PerformInteraction at all

for i,v in ipairs(tKeyboardEvent) do
        Test["NoPerformInteractionOneApp" .. v] = function (self)
                self.hmiConnection:SendNotification("UI.OnKeyboardInput",{data="abc", event=v})
                EXPECT_NOTIFICATION("OnKeyboardInput")
                :Times(0)

                DelayedExp(1000)
        end
end
-- END TESTCASE 1.7



---------------------------------------------------------------------------------------------
-------------------------------------END TEST BLOCK I----------------------------------------
------------OnKeyboardInput: PerformInteraction(KEYBOARD) with one registered App------------
---------------------------------------------------------------------------------------------



---------------------------------------------------------------------------------------------
--------------------------------------II TEST BLOCK------------------------------------------
------------OnKeyboardInput: PerformInteraction(KEYBOARD) with two registered Apps-----------
---------------------------------------------------------------------------------------------
        --Begin Test suit PositiveRequestCheck

        --Description: TC's checks that
                -- SDL must transfer OnKeyboardInput notification to the app associated with active PerfromInteraction (KEYBOARD) request
                -- SDL must transfer OnKeyboardInput notification to any app that is currently in FULL if there is no active PerformInteraction (KEYBOARD)


                --Begin Test case CommonRequestCheck.1
                --Description: This test is intended to check positive cases and when all parameters are in boundary conditions

                        --Requirement id in JAMA:
                                        -- TBD

                        --Verification criteria:


-- BEGIN TEST CASE 1.7
-- Description: SDL must transfer OnKeyboardInput notification to associated App in FULL (2 Apps are registered)

-- Start 2n session
local HMIappID2 = nil

function Test:Precondition_SecondSession()
        testName("Register second Application", "pre")
        --mobile side: start new session
        self.mobileSession1 = mobile_session.MobileSession(
        self,
        self.mobileConnection)
end

-- Register 2nd App
function Test:Precondition_AppRegistrationInSecondSession()
        --mobile side: start new
        self.mobileSession1:StartService(7)
        :Do(function()
                local cid = self.mobileSession1:SendRPC(
                        "RegisterAppInterface",
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
                                appID = "0000002"
                        })

                --hmi side: expect BasicCommunication.OnAppRegistered request
                EXPECT_HMINOTIFICATION(
                        "BasicCommunication.OnAppRegistered",
                        {
                                application =
                                {
                                appName = "Test Application2"
                                }
                        })
                :Do(function(_,data)
                                HMIappID2 = data.params.application.appID
                        end)

                --mobile side: expect response
                self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
                :Timeout(2000)

                self.mobileSession1:ExpectNotification("OnHMIStatus",{hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

        end)
end

function Test:EventChanged_Audio_not_active()
  -- HMI sends EventChanged "AUDIO_SOURCE"
  self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged", {eventName="AUDIO_SOURCE",isActive = false})

  self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  :Times(1)

  self.mobileSession1:ExpectNotification("OnHMIStatus", {})
  :Times(0)

  DelayedExp(100)
end

-- Activate App2
function Test:ActivateApp2()

        self:activateApp(HMIappID2, 2)
        DelayedExp(100)

         self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
    :Times(1)

end

-- Begin Precondition: choice set
function Test:PreconditionCreateChoiseSetSession2()
        testName("Create choice set on session 2", "pre")
        createInteractionChoiceSet(self, 100, 100, 2)
end
-- End Precondition

-- PerformInteraction from App1
for i,v in ipairs(tKeyboardEvent) do
        Test["PerfromInteractionFromFULL" .. v] = function (self)
                SendPerformInteraction(self, "SDL transfer OnKeyboardInput to associated App in FULL, 2 Apps are registered", v, "FULL", "KEYBOARD",2)
        end
end
-- END TESTCASE 1.7



-- BEGIN TEST CASE 1.5
-- Description: SDL must transfer OnKeyboardInput notification to associated App in LIMITED (2 Apps are registered)
function Test:PreconditionSwitchToAnotherPage2()
        testName("Switch to another page", "pre")
        self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", {appID = HMIappID2, reason = "GENERAL"})
        self.mobileSession1:ExpectNotification(
                "OnHMIStatus",
                {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
        :Times(1)

        EXPECT_NOTIFICATION("OnHMIStatus")
        :Times(0)

        DelayedExp(100)
end

for i,v in ipairs(tKeyboardEvent) do
        Test["PerfromInteractionFromLIMITED" .. v] = function (self)
                SendPerformInteraction(self, "SDL transfer OnKeyboardInput to associated App in LIMITED, 2 Apps are registered", v, "LIMITED", "KEYBOARD",2)
        end
end
-- END TESTCASE 1.5



-- BEGIN TEST CASE 1.6
-- Description: SDL must transfer OnKeyboardInput notification to associated App in BACKGROUND (2 Apps are registered)
function Test:PreconditionDeactivateApp2()
        testName("Deactivate App", "pre")

        -- according to CRQ APPLINK-17839
    -- self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", {appID = self.applications["Test Application"], reason = "AUDIO"}

        self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged", {eventName="AUDIO_SOURCE",isActive = true})
        self.mobileSession1:ExpectNotification(
                "OnHMIStatus",
                {hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
        :Times(1)

        EXPECT_NOTIFICATION("OnHMIStatus")
        :Times(0)

        DelayedExp(100)
end

for i,v in ipairs(tKeyboardEvent) do
        Test["PerfromInteractionFromBACKGROUND" .. v] = function (self)
                SendPerformInteraction(self, "SDL transfer OnKeyboardInput to associated App in BACKGROUND, 2 Apps are registered", v, "BACKGROUND", "KEYBOARD",2)
        end
end
-- END TESTCASE 1.6

-- BEGIN TEST CASE 2.5
-- Description: OnKeyboardInputNotification while there is no active PerfromInteraction(KEYBOARD), One App in FULL

--Begin Precondition.1
--Description: AudioSource - end
function Test:EndAudioSource( ... )
        -- body
        self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged", {eventName="AUDIO_SOURCE",isActive = false})
        EXPECT_NOTIFICATION("OnHMIStatus", {})
        :Times(0)

        self.mobileSession1:ExpectNotification("OnHMIStatus", { hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN" })
        :Times(1)
end

-- Activate App2
function Test:ActivateApp2()
        self:activateApp(HMIappID2, 2)
        EXPECT_NOTIFICATION("OnHMIStatus")
        :Times(0)

        DelayedExp(100)
end

for i,layoutValue in ipairs(tLayouts) do
        for i,keyboardValue in ipairs(tKeyboardEvent) do
                Test["PerformInteraction_"..layoutValue.."_"..keyboardValue] = function (self)
                        SendPerformInteraction(self, "SDL transfer OnKeyboardInput only to App in FULL", keyboardValue, "FULL", layoutValue, 2)
                end
        end
end

-- END TESTCASE 2.5



-- BEGIN TEST CASE 2.6
-- Description: OnKeyboardInputNotification while there is no active PerfromInteraction(KEYBOARD), App1 - BACK, App2 - LIMITED
function Test:PreconditionSwitchToAnotherPage3()
        testName("Switch to another page", "pre")
        self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", {appID = HMIappID2, reason = "GENERAL"})
        self.mobileSession1:ExpectNotification("OnHMIStatus",
                {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
        :Times(1)

        EXPECT_NOTIFICATION("OnHMIStatus")
        :Times(0)
end

for i,layoutValue in ipairs(tLayouts) do
        for i,keyboardValue in ipairs(tKeyboardEvent) do
                Test["PerformInteraction_"..layoutValue.."_"..keyboardValue] = function (self)
                        SendPerformInteraction(self, "SDL transfer OnKeyboardInput only to App in LIMITED", keyboardValue, "LIMITED", layoutValue, 2)
                end
        end
end
-- END TESTCASE 2.6



-- BEGIN TEST CASE 2.7
-- Description: OnKeyboardInputNotification while there is no active PerfromInteraction(KEYBOARD), App1 and App2 - BACKGROUND
function Test:PreconditionDeactivateApp3()
        testName("Deactivate App", "pre")

        -- according to CRQ APPLINK-17839
    -- self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", {appID = self.applications["Test Application"], reason = "AUDIO"}

        self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged", {eventName="AUDIO_SOURCE",isActive = true})
        self.mobileSession1:ExpectNotification(
                "OnHMIStatus",
                {hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
        :Times(1)

        EXPECT_NOTIFICATION("OnHMIStatus")
        :Times(0)

        DelayedExp(100)
end

for i,layoutValue in ipairs(tLayouts) do
        for i,keyboardValue in ipairs(tKeyboardEvent) do
                Test["PerformInteraction_"..layoutValue.."_"..keyboardValue] = function (self)
                        SendPerformInteraction(self, "SDL transfer OnKeyboardInput only to App in BACKGROUND", keyboardValue, "BACKGROUND", layoutValue, 2)
                end
        end
end
-- END TESTCASE 2.7



-- BEGIN TEST CASE 2.8
-- Description: No active PerformInteraction at all - two Apps are registered
for i,v in ipairs(tKeyboardEvent) do
        Test["NoPerformInteractionTwoApps" .. v] = function (self)
                self.hmiConnection:SendNotification("UI.OnKeyboardInput",{data="abc", event=v})
                EXPECT_NOTIFICATION("OnKeyboardInput")
                :Times(0)

                DelayedExp(1000)
        end
end
-- END TESTCASE 2.8



-- BEGIN TEST CASE 2.9
-- Description: OnKeyboardInput, no registered Apps at all

-- Precondition: Unregister both Apps
function Test:UnregisterApplicationApp1()
        --mobile side: UnregisterAppInterface request
        local cid1 = self.mobileSession:SendRPC("UnregisterAppInterface",{})

        --hmi side: expect OnAppUnregistered notification

    EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = HMIappID, unexpectedDisconnect = false})
    :Times(1)

        --mobile side: UnregisterAppInterface response
        EXPECT_RESPONSE(cid1, { success = true, resultCode = "SUCCESS"})
        :Timeout(2000)

end

function Test:UnregisterApplicationApp2()
        --mobile side: UnregisterAppInterface request
        local cid2 = self.mobileSession1:SendRPC("UnregisterAppInterface", {})

        --hmi side: expect OnAppUnregistered notification

    EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = HMIappID2, unexpectedDisconnect = false})
    :Times(1)

        --mobile side: UnregisterAppInterface response
        self.mobileSession1:ExpectResponse(cid2, { success = true, resultCode = "SUCCESS"})
        :Timeout(2000)

end

for i,v in ipairs(tKeyboardEvent) do
        Test["OnKeyboardInputNoApps" .. v] = function (self)
                self.hmiConnection:SendNotification("UI.OnKeyboardInput", {data="abc", event=v})

                DelayedExp(100)
        end
end
-- END TESTCASE 2.9

---------------------------------------------------------------------------------------------
------------------------------------END TEST BLOCK II----------------------------------------
--CommonRequestCheck: Check of mandatory/conditional request's parameters (mobile protocol)--
---------------------------------------------------------------------------------------------



---------------------------------------------------------------------------------------------
-------------------------------------------Postcondition-------------------------------------
---------------------------------------------------------------------------------------------

--TODO: Will be updated after policy flow implementation
-- Postcondition: restore sdl_preloaded_pt.json
policyTable:Restore_preloaded_pt()
	
return Test