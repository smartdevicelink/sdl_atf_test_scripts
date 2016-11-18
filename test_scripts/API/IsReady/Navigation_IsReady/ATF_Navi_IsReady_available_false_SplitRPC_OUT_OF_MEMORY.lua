---------------------------------------------------------------------------------------------
-- CRQ: APPLINK-25169: [GENIVI] Navigation interface: SDL behavior in case HMI does not respond
-- to IsReady_request or respond with "available" = false
--
-- Requirement(s): APPLINK-25184:[Navigation Interface] Conditions for SDL to respond 
-- 'UNSUPPORTED_RESOURCE, success:false' to mobile app  
--                 APPLINK-25301:[HMI_API] Navi.IsReady
---------------------------------------------------------------------------------------------


TestedInterface = "Navigation"
Tested_resultCode = "OUT_OF_MEMORY" 
Tested_wrongJSON = false


Test = require('user_modules/IsReady_Template/ATF_Interface_IsReady_available_false_SplitRPC_Template')

return Test
