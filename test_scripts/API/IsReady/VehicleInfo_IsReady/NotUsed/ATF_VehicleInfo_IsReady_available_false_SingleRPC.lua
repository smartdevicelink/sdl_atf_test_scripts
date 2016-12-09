
---------------------------------------------------------------------------------------------
-- CRQ: APPLINK-25200: [GENIVI] VehicleInfo interface: SDL behavior in case HMI does not 
--                     respond to IsReady_request or respond with "available" = false
--
-- Requirement(s): APPLINK-25224: [VehicleInfo Interface] Conditions for SDL to respond 
--                                 'UNSUPPORTED_RESOURCE, success:false' to mobile app
--                 APPLINK-25305: [HMI_API] VehicleInfo.IsReady
---------------------------------------------------------------------------------------------


TestedInterface = "VehicleInfo"
Test = require('user_modules/ATF_Interface_IsReady_available_false_SingleRPC_Template')

return Test