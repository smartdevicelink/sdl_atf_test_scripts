---------------------------------------------------------------------------------------------
-- CRQ: APPLINK-20918 [GENIVI] VR interface: SDL behavior in case HMI does not respond to 
--                     IsReady_request or respond with "available" = false
--
-- Requirement(s): APPLINK-20932 [VR Interface] SDL behavior in case HMI does not respond 
--                 to VR.IsReady_request 
--                 APPLINK-25286:[HMI_API] VR.IsReady
---------------------------------------------------------------------------------------------


TestedInterface = "VR"
Tested_resultCode = "TIMED_OUT" 
Tested_wrongJSON = false


Test = require('user_modules/IsReady_Template/ATF_Interface_IsReady_missing_SingleRPC_Template')

return Test