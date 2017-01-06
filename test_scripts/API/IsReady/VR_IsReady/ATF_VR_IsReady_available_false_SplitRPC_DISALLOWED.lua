---------------------------------------------------------------------------------------------
-- CRQ: APPLINK-20918 [GENIVI] VR interface: SDL behavior in case HMI does not respond to 
--                     IsReady_request or respond with "available" = false
--
-- Requirement(s): APPLINK-25043 [VR Interface] VR.IsReady(false) -> HMI respond with 
--                                errorCode to splitted RPC 
--                 APPLINK-25042 [VR Interface] VR.IsReady(false) -> HMI respond with 
--                                successfull resultCode to splitted RPC 
--                 APPLINK-25286:[HMI_API] VR.IsReady
---------------------------------------------------------------------------------------------


TestedInterface = "VR"
Tested_resultCode = "DISALLOWED" 
Tested_wrongJSON = false


Test = require('user_modules/IsReady_Template/ATF_Interface_IsReady_available_false_SplitRPC_Template')

return Test