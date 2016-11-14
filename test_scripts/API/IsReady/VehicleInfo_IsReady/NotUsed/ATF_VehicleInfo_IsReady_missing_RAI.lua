print("\27[31m SDL crushes with DCHECK. Some tests are commented. After resolving uncomment tests!\27[0m")
---------------------------------------------------------------------------------------------
-- CRQ: APPLINK-25200: [GENIVI] VehicleInfo interface: SDL behavior in case HMI does not 
--                     respond to IsReady_request or respond with "available" = false
--
-- Requirement(s): APPLINK-25064:[RegisterAppInterface] SDL behavior in case HMI does NOT 
--                               respond to IsReady request
--                 APPLINK-25225: [VehicleInfo Interface] SDL behavior in case HMI does not 
--                               respond to VehicleInfo.IsReady_request 
--                               => only checked RPC: GetVehicleType
--                 APPLINK-25305: [HMI_API] VehicleInfo.IsReady
---------------------------------------------------------------------------------------------


TestedInterface = "VehicleInfo"
Test = require('user_modules/ATF_Interface_IsReady_missing_RAI_Template')

return Test