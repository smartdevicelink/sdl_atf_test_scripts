---------------------------------------------------------------------------------------------
-- CRQ: APPLINK-25117: [GENIVI] TTS interface: SDL behavior in case HMI does not respond to 
--                     IsReady_request or respond with "available" = false
--
-- Requirement(s): APPLINK-25131 [TTS Interface] SDL behavior in case HMI does not respond 
--                 to TTS.IsReady_request 
--                 APPLINK-25303:[HMI_API] TTS.IsReady
---------------------------------------------------------------------------------------------


TestedInterface = "TTS"
Tested_resultCode = "TRUNCATED_DATA" 
Tested_wrongJSON = false


Test = require('user_modules/IsReady_Template/ATF_Interface_IsReady_missing_SingleRPC_Template')

return Test