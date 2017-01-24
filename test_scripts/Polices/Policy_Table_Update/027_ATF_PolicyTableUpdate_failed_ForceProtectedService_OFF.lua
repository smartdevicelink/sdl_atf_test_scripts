-- UNREADY - Securuty is not implemented in ATF

-- Requirement summary:
-- In case
-- SDL starts PolicyTableUpdate in case of no "certificate" at "module_config" section at LocalPT (please see APPLINK-27521, APPLINK-27522)
-- and PolicyTableUpdate is failed by any reason even after retry strategy (please see related req-s HTTP flow and Proprietary flow)
-- and "ForceProtectedService" is OFF at .ini file
-- and app sends StartService (<any_serviceType>, encypted=true) to SDL
-- SDL must:
-- respond StartService (ACK, encrypted=false) to this mobile app

require('atf_modules')
local policy = require('utils/policy')
require('preconditions')

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
local mobile_session = require('mobile_session')

Test["UpdateForceProtectedService_" .. tostring("prefix") ] = function(self)
	commonFunctions:SetValuesInIniFile("%p?ForceProtectedService%s?=%s-[%w%d,-]-%s-\n", "ForceProtectedService", "OFF" )
end

commonSteps:ActivationApp()

policy:UpdatePolicyWithWrongPTU()

--[[ Test ]]
function Test:Start_Secure_Service()
  print("Starting security service is not implemented")

  EXPECT_HMICALL("SDL.PolicyUpdate")
  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UPDATE_NEEDED"})
end

--[[ Postcondition ]]
--ToDo: shall be removed when issue: "SDL doesn't stop at execution ATF function StopSDL()" is fixed
function Test:Postcondition_SDLForceStop()
  commonFunctions:SDLForceStop()
end