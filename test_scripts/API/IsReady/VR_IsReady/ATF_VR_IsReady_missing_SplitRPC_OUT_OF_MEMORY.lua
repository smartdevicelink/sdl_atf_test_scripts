---------------------------------------------------------------------------------------------
-- CRQ: APPLINK-20918 [GENIVI] VR interface: SDL behavior in case HMI does not respond to 
--                     IsReady_request or respond with "available" = false
--
-- Requirement(s): APPLINK-25044:[VR Interface] HMI does NOT respond to IsReady and 
--                               mobile app sends RPC that must be splitted
--                 APPLINK-25286:[HMI_API] VR.IsReady
---------------------------------------------------------------------------------------------


TestedInterface = "VR"
Tested_resultCode = "OUT_OF_MEMORY" 
Tested_wrongJSON = false


Test = require('user_modules/IsReady_Template/ATF_Interface_IsReady_missing_SplitRPC_Template')

return Test