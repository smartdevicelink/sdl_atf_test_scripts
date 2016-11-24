
---------------------------------------------------------------------------------------------
-- CRQ: APPLINK-25169: [GENIVI] Navigation interface: SDL behavior in case HMI does not respond to 
--                     IsReady_request or respond with "available" = false
--
-- Requirement(s): APPLINK-25185 [Navigation Interface] SDL behavior in case HMI does not respond to Navi.IsReady_request 
--                 		   APPLINK-25301:[HMI_API] Navi.IsReady
---------------------------------------------------------------------------------------------


TestedInterface = "Navigation"
Tested_resultCode = "SUCCESS" 
Tested_wrongJSON = true


Test = require('user_modules/IsReady_Template/ATF_Interface_IsReady_missing_SingleRPC_Template')

return Test
