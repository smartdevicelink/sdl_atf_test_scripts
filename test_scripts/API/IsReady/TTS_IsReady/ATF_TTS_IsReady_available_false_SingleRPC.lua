---------------------------------------------------------------------------------------------
-- CRQ: APPLINK-25117: [GENIVI] TTS interface: SDL behavior in case HMI does not respond to 
--                     IsReady_request or respond with "available" = false
--
-- Requirement(s): APPLINK-25140:[TTS Interface] Conditions for SDL to respond 
--                               'UNSUPPORTED_RESOURCE, success:false' to mobile app
--                 APPLINK-25303:[HMI_API] TTS.IsReady
---------------------------------------------------------------------------------------------


TestedInterface = "TTS"

Test = require('user_modules/IsReady_Template/ATF_Interface_IsReady_available_false_SingleRPC_Template')

return Test