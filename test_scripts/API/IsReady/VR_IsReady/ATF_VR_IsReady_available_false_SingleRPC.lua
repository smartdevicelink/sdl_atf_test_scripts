---------------------------------------------------------------------------------------------
-- CRQ: APPLINK-20918 [GENIVI] VR interface: SDL behavior in case HMI does not respond to 
--                     IsReady_request or respond with "available" = false
--
-- Requirement(s): APPLINK-20931: [VR Interface] Conditions for SDL to respond 
--                               'UNSUPPORTED_RESOURCE, success:false' to mobile app
--                 APPLINK-25286:[HMI_API] VR.IsReady
---------------------------------------------------------------------------------------------


TestedInterface = "VR"

Test = require('user_modules/IsReady_Template/ATF_Interface_IsReady_available_false_SingleRPC_Template')

return Test