-- UNREADY---
-- Iliana second_test have status PartlyReady I need your help with sent all avaliable RPCs, I sended 22 RPCs and received DISALLOWED responce, it is OK for the test.
-- But I have 13 RPCs which come with INVALID_DATA (they commented) and 
-- 3 RPCs come with INVALID_DATA also but with error "mandatory parameter spaceAvailable not present" - they also commented for run script

-- Requirement summary:
-- [GeneralResultCode] DISALLOWED. A request comes with appID which has "null" permissions in Policy Table
-- 
-- Description:
--      In case PolicyTable has "<appID>": "null" in the Local PolicyTable for the specified application with appID, 
--      PoliciesManager must return DISALLOWED resultCode and success:"false" to any RPC requested by such <appID> app.
-- Performed steps
--       Pre_step. Add in sdl_preloaded_pt application id with NULL policy
--       1. MOB-SDL - Open new session and register application in this session
--       2. MOB-SDL - send the list of RPCs
--       3. SDL responce, success = false, resultCode = "DISALLOWED" 

 --[[ General configuration parameters ]]
config.defaultProtocolVersion = 2
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--[[ Required Shared libraries ]]
local mobile_session = require('mobile_session')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')

--[[ Local Variables ]]
local RPC = {
   {rpc = "UnregisterAppInterface", params = {}},
   {rpc = "SetGlobalProperties", params = { menuTitle = "Menu Title", timeoutPrompt = {{text = "Timeout prompt", type = "TEXT"}}, vrHelp = {{position = 1, image = {value = "action.png", imageType = "DYNAMIC"}, text = "VR help item"}}, menuIcon = {value = "action.png", imageType = "DYNAMIC"}, helpPrompt = {{text = "Help prompt", type = "TEXT"}}, vrHelpTitle = "VR help title", keyboardProperties = {keyboardLayout = "QWERTY", keypressMode = "SINGLE_KEYPRESS", limitedCharacterList = {"a"}, language = "EN-US", autoCompleteText = "Daemon, Freedom"}}},
   {rpc = "AddCommand", params = {cmdID = 14, menuParams = {parentID = 1, position = 0, menuName ="Commandpositive"}}},
   {rpc = "ResetGlobalProperties", params ={properties = {"VRHELPTITLE", "MENUNAME","MENUICON", "KEYBOARDPROPERTIES", "VRHELPITEMS", "HELPPROMPT", "TIMEOUTPROMPT"}}},
   {rpc = "DeleteCommand", params ={cmdID = 1234567890}},
   {rpc = "AddSubMenu", params = {menuID = 1000, position = 500, menuName ="SubMenupositive"}},
   {rpc = "DeleteSubMenu", params = {menuID = 1000}},
   {rpc = "CreateInteractionChoiceSet", params = {interactionChoiceSetID = 1001, choiceSet = {{choiceID = 1001, menuName ="Choice1001", vrCommands = {"Choice1001",}, image = {value ="icon.png", imageType ="DYNAMIC"}}}}},
   {rpc = "DeleteInteractionChoiceSet", params= {interactionChoiceSetID = 1}},
   {rpc = "Alert", params = {}},
   {rpc = "Show", params = {mediaClock = "00:00:01", mainField1 = "Show1", softButtons = {{ text = "", systemAction = "DEFAULT_ACTION", type = "BOTH", isHighlighted = true, image = {imageType = "DYNAMIC", value = "icon.png"},  softButtonID = 3 }}}},
   {rpc = "EndAudioPassThru", params = {}},
   {rpc = "SubscribeVehicleData", params = {gps = true}},
   {rpc = "UnsubscribeVehicleData", params = {gps = true}},
   {rpc = "GetVehicleData", params = {speed = true}},
   {rpc = "ScrollableMessage", params = {scrollableMessageBody = commonFunctions:createString(500), softButtons = {{softButtonID = 1, text = commonFunctions:createString(500),type = "TEXT", isHighlighted = false, systemAction = "DEFAULT_ACTION"}}}},
   {rpc = "Slider", params = {numTicks = 7, position = 6, sliderHeader ="sliderHeader"}},
   {rpc = "ShowConstantTBT", params = {}},
   {rpc = "AlertManeuver", params = {ttsChunks = {{text ="FirstAlert", type ="TEXT",}, {text ="SecondAlert", type ="TEXT",},}}},
   {rpc = "ChangeRegistration", params = {language ="EN-US", hmiDisplayLanguage ="EN-US", appName ="SyncProxyTester", ttsName = {{text ="SyncProxyTester",type ="TEXT",},}, ngnMediaScreenAppName ="SPT",  vrSynonyms = { "VRSyncProxyTester", }, }},
   {rpc = "SetAppIcon", params = {syncFileName = "icon.png"}},
   {rpc = "SetDisplayLayout", params = {displayLayout = "ONSCREEN_PRESETS"}},
   {rpc = "SendLocation", params = {address = {countryName = "countryName"}}},
 --{rpc = "DialNumber", params = {{number = "#3804567654*"}}},
 --{rpc = "UpdateTurnList", params = {}}
 --{rpc = "Speak", params = {}}, 
 --{rpc = "SetMediaClockTimer", params = {}}
 --{rpc = "PerformAudioPassThru", params = {}}
 --{rpc = "PerformInteraction", params = {}},
 --{rpc = "SubscribeButton", params = {}}, 
 --{rpc = "UnsubscribeButton", params = {}},    
-- {rpc = "GenericResponse", params =   {}}                   
-- {rpc = "SystemRequest", params = {}},
 --{rpc = "GetWayPoints", params = {}},
-- {rpc = "SubscribeWayPoints", params = {}},
-- {rpc = "UnsubscribeWayPoints", params = {}},
-- ATF issue - "mandatory parameter spaceAvailable not present"
-- {rpc = "ListFiles", params = {}},
 --{rpc = "PutFile", params = {syncFileName ="icon.png", fileType ="GRAPHIC_PNG", persistentFile =false, systemFile = false, offset =0, length =11600}},
 --{rpc = "DeleteFile", params = {syncFileName = "test.png"}},
}
--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()
commonFunctions:newTestCasesGroup("Preconditions")
--[[ General Settings for configuration ]]
Test = require('connecttest')

--[[ Preconditions ]]
function Test:Preconditon_CreateNewSession()
commonFunctions:userPrint(33, "Precondition")
  self.mobileSession2 = mobile_session.MobileSession(self, self.mobileConnection)
  self.mobileSession2:StartService(7)
end

function Test:TestStep_RAI_InNewSession_WithNULL_Polices()
commonFunctions:userPrint(33, "Test_Case1")
  local registerAppInterfaceParams =
  {
    syncMsgVersion =
    {
      majorVersion = 3,
      minorVersion = 0
    },
    appName = "Media Application",
    isMediaApplication = true,
    languageDesired = 'EN-US',
    hmiDisplayLanguageDesired = 'EN-US',
    appHMIType = {"NAVIGATION"},
    appID = "123abc",
    deviceInfo =
    {
      os = "Android",
      carrier = "Megafon",
      firmwareRev = "Name: Linux, Version: 3.4.0-perf",
      osVersion = "4.4.2",
    }
  }
local corId = self.mobileSession2:SendRPC("RegisterAppInterface", registerAppInterfaceParams)
  self.mobileSession2:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
end

function Test:TestStep_CheckRPCs_ForApp_withPolicyNull()
  commonFunctions:userPrint(33, "Test_Case2")
 for i = 1 , #RPC do
  local corId = self.mobileSession2:SendRPC(RPC[i].rpc, RPC[i].params) 
  self.mobileSession2:ExpectResponse(corId, {success = false, resultCode = "DISALLOWED" })
end
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
Test["StopSDL"] = function()
   commonFunctions:userPrint(33, "Postcondition")
    StopSDL()
end


