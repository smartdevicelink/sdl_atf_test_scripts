---------------------------------------------------------------------------------------------
-- CRQ: APPLINK-25117: [GENIVI] TTS interface: SDL behavior in case HMI does not respond to 
--                     IsReady_request or respond with "available" = false
--
-- Requirement(s): APPLINK-25139:[TTS Interface] HMI does NOT respond to IsReady and 
--                               mobile app sends RPC that must be splitted
--                 APPLINK-25303:[HMI_API] TTS.IsReady
---------------------------------------------------------------------------------------------


TestedInterface = "TTS"
Tested_resultCode = "ABORTED" 
Tested_wrongJSON = false


Test = require('user_modules/IsReady_Template/ATF_Interface_IsReady_missing_SplitRPC_Template')

return Test