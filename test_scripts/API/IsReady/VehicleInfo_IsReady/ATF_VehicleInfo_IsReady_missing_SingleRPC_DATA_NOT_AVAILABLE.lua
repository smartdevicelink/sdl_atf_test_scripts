---------------------------------------------------------------------------------------------
-- CRQ: APPLINK-25200: [GENIVI] VehicleInfo interface: SDL behavior in case HMI does not 
--                     respond to IsReady_request or respond with "available" = false
--
-- Requirement(s): APPLINK-25225: [VehicleInfo Interface] SDL behavior in case HMI 
--                                 does not respond to VehicleInfo.IsReady_request
--                 APPLINK-25305: [HMI_API] VehicleInfo.IsReady
---------------------------------------------------------------------------------------------

TestedInterface = "VehicleInfo"
Tested_resultCode = "DATA_NOT_AVAILABLE" 
Tested_wrongJSON = false


Test = require('user_modules/IsReady_Template/ATF_Interface_IsReady_missing_SingleRPC_Template')

return Test