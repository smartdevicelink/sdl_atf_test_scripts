---------------------------------------------------------------------------------------------
-- CRQ: APPLINK-25117: [GENIVI] TTS interface: SDL behavior in case HMI does not respond to 
--                     IsReady_request or respond with "available" = false
--
-- Requirement(s): APPLINK-25134 [TTS Interface] TTS.IsReady(false) -> HMI respond with 
--                                errorCode to splitted RPC 
--                 APPLINK-25133 [TTS Interface] TTS.IsReady(false) -> HMI respond with 
--                                successfull resultCode to splitted RPC 
--                 APPLINK-25303:[HMI_API] TTS.IsReady
---------------------------------------------------------------------------------------------


TestedInterface = "TTS"
Tested_resultCode = "IN_USE" 
Tested_wrongJSON = false


Test = require('user_modules/IsReady_Template/ATF_Interface_IsReady_available_false_SplitRPC_Template')

return Test