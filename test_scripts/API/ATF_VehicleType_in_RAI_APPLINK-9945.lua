--------------------------------------------------------------------------------
-- Preconditions before ATF start
--------------------------------------------------------------------------------
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
--------------------------------------------------------------------------------
--Precondition: preparation connecttest_VehicleTypeIn_RAI_Response.lua
commonPreconditions:Connecttest_without_ExitBySDLDisconnect_WithoutOpenConnectionRegisterApp("connecttest_VehicleTypeIn_RAI_Response.lua", true)

f = assert(io.open('./user_modules/connecttest_VehicleTypeIn_RAI_Response.lua', "r"))

  fileContent = f:read("*all")
  f:close()

  local pattern1 = "function .?module%:InitHMI_onReady.-initHMI_onReady.-end"
  local pattern1Result = fileContent:match(pattern1)

  if pattern1Result == nil then 
    print(" \27[31m InitHMI_onReady functions is not found in /user_modules/connecttest_VehicleTypeIn_RAI_Response.lua \27[0m ")
  else
    fileContent  =  string.gsub(fileContent, pattern1, "")
  end

    -- update initHMI_onReady
  local pattern2 = "function .?module%.?:.?initHMI%_onReady%(.?%)"
  local ResultPattern2 = fileContent:match(pattern2)

  if ResultPattern2 == nil then 
    print(" \27[31m initHMI_onReady function is not found in /user_modules/connecttest_VehicleTypeIn_RAI_Response.lua \27[0m ")
  else
    fileContent  =  string.gsub(fileContent, pattern2, 'function module:initHMI_onReady(MYmake, MYmodel, MYmodelYear, MYtrim) \n MYmake = MYmake or "make" \n if MYmake == "absent" then MYmake = nil end \n  MYmodel = MYmodel or "model" \n if MYmodel == "absent" then MYmodel = nil end \n MYmodelYear = MYmodelYear or "modelYear" \n if MYmodelYear == "absent" then MYmodelYear = nil end \n  MYtrim = MYtrim or "trim" \n if MYtrim == "absent" then MYtrim = nil end \n   if MYmake ~= nil then print("In connecttest make: "..MYmake) else print("In connecttest: make is absent") end \n if MYmodel ~= nil then print("In connecttest model: "..MYmodel) else  print("In connecttest: model is absent") end \n if MYmodelYear ~= nil then  print("In connecttest modelYear: "..MYmodelYear) else  print("In connecttest: modelYear is absent") end \n if MYtrim ~= nil then  print("In connecttest trim: "..MYtrim) else  print("In connecttest: trim is absent") end')
  end

    -- update hmiCapabilities in UI.GetCapabilities
  local pattern3 = 'ExpectRequest%s-%(%s-"%s-VehicleInfo.GetVehicleType-".-%{.-%}%s-%)'
  local ResultPattern3 = fileContent:match(pattern3)

  if ResultPattern2 == nil then 
    print(" \27[31m ExpectRequest VehicleInfo.GetVehicleType call is not found in /user_modules/connecttest_VehicleTypeIn_RAI_Response.lua \27[0m ")
  else
    fileContent  =  string.gsub(fileContent, pattern3,'ExpectRequest("VehicleInfo.GetVehicleType", true, {vehicleType = { make = MYmake, model = MYmodel, modelYear = MYmodelYear, trim = MYtrim}})')
  end

f = assert(io.open('./user_modules/connecttest_VehicleTypeIn_RAI_Response.lua', "w"))
f:write(fileContent)
f:close()

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
Test = require('user_modules/connecttest_VehicleTypeIn_RAI_Response')
require('cardinalities')
local mobile_session = require('mobile_session')
require('user_modules/AppTypes')

--------------------------------------------------------------------------------------------------------------------------------
------------- Tesst script for testing CRQ APPLINK-9945 - VehicleType from PolicyTable for RegisterAppInterfaceResponse---------
--------------------------------------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------Functions----------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------


local function CreateSession( self)
  self.mobileSession = mobile_session.MobileSession(
        self,
        self.mobileConnection)
end

local function userPrint( color, message)
  print ("\27[" .. tostring(color) .. "m " .. tostring(message) .. " \27[0m")
end

local function RegisterApp(self, RAImake, RAImodel, RAImodelYear, RAItrim)  

  local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)

    EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")

  -- self.mobileSession:ExpectResponse(correlationId, { success = true })
    EXPECT_RESPONSE(correlationId, { success = true })
    :Do(function(_,data)
      if data.payload.vehicleType then
        if data.payload.vehicleType.make ~= nil then 
        print ("in RAI response make: "..data.payload.vehicleType.make)
        end

        if data.payload.vehicleType.model ~= nil then 
        print ("in RAI response model: "..data.payload.vehicleType.model)
        end

        if data.payload.vehicleType.modelYear ~= nil then 
        print ("in RAI response modelYear: "..data.payload.vehicleType.modelYear)
        end

        if data.payload.vehicleType.trim ~= nil then 
        print ("in RAI response trim: "..data.payload.vehicleType.trim)
        end
      end

     end)

  -- validation of make, model, modelYear and trim parameters which send in GetVehicleType response from HMI and in RAI response
  :ValidIf(function (_,data)
    if data.payload.vehicleType then
      if (data.payload.vehicleType.make ~= nil and (data.payload.vehicleType.make == "make_from_Policy" or RAImake))
        and (data.payload.vehicleType.make ~= nil and (data.payload.vehicleType.model == "model_from_Policy" or RAImodel))
        and (data.payload.vehicleType.modelYear == nil or RAImodelYear)
        and (data.payload.vehicleType.trim == nil or RAItrim) 
      then
        return true

      else
        return false
      end
    else 
      userPrint( 31, "vehicleType is not present in RAI response")
      return false
    end

  end)
end

function RestartSDL(self, suffix, MYmake, MYmodel, MYmodelYear, MYtrim)
  -- body
  
  Test["StopSDL "..tostring(suffix - 1)] = function (self)
    StopSDL()
  end

  Test["StartSDL " .. tostring(suffix)] = function (self)
    StartSDL(config.pathToSDL, config.ExitOnCrash)
  end

  Test["TestInitHMI " .. tostring(suffix)] = function (self)
    self:initHMI()
  end

  Test["TestInitHMIOnReady " .. tostring(suffix)] = function (self)
    self:initHMI_onReady(MYmake, MYmodel, MYmodelYear, MYtrim)
  end

end
  

-- Precondition: removing user_modules/connecttest_VehicleTypeIn_RAI_Response.lua
function Test:Precondition_remove_user_connecttest()
  os.execute( "rm -f ./user_modules/connecttest_VehicleTypeIn_RAI_Response.lua" )
end

---------------------------------------------------------------------------------------------
-----------------------              Test 1                 ---------------------------------
---------------------------------------------------------------------------------------------

--Check that SDL respond to mobile in RAI response with Upper and Lower bound value of parameters of VehicleType
local indexOfTests = 1

for i=indexOfTests, indexOfTests + 1 do

local UpperBound = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
local LowerBound = "a"
local testname = ""
local params = ""


if indexOfTests == 1 then testname = "all UpperBound" 
elseif indexOfTests == 2 then testname = "all LowerBound" end

if indexOfTests == 1 then params = UpperBound 
elseif indexOfTests == 2 then params = LowerBound end

Test["Test parameters ".. testname] = function ()
  userPrint(33, "=== Positive test suit start ===")
  return true
end

RestartSDL(self, i, params, params, params, params)

function Test:ConnectMobile()
  self:connectMobile()
end

function Test:StartSession()
   CreateSession(self)
end

function Test:RegisterApp()
  self.mobileSession:StartService(7)
  :Do(function (_,data)
    RegisterApp(self, params, params, params, params)
  end)
end

Test["Test parameters  ".. testname] = function ()
  userPrint(33, "=== Positive test suit end ===")
  return true
end

indexOfTests = indexOfTests + 1

end

---------------------------------------------------------------------------------------------
-----------------------              Test 2                 ---------------------------------
---------------------------------------------------------------------------------------------

-- Check that SDL send VehicleType without one of parameter. If make and model absent in GetVehicleType response fron HMI SDL select this parameters from policy table
local indexOfTests = 1

for i=indexOfTests, indexOfTests + 3 do

local absent = "absent"

local testname = ""
local params = ""

if indexOfTests == 1 then testname = "without make parameter" 
elseif indexOfTests == 2 then testname = "without model parameter"
elseif indexOfTests == 3 then testname = "without modelYear parameter"
elseif indexOfTests == 4 then testname = "without trim parameter" end

if indexOfTests == 1 then make = absent 
elseif indexOfTests == 2 then 
    make = "make__"
    model = absent
    
elseif indexOfTests == 3 then 
    model = "model__"
    make = "make__"
    modelYear = absent
    
elseif indexOfTests == 4 then 
    modelYear = "modelYear__"
    model = "model__"
    make = "make__" 
    trim = absent
end

Test["Test parameters ".. testname] = function ()
  -- body
  userPrint(33, "=== Positive test suit start ===")
  return true
end

RestartSDL(self, i, make, model, modelYear, trim)

function Test:ConnectMobile()
  self:connectMobile()  
end

function Test:StartSession()
   CreateSession(self)
end

if indexOfTests == 1 then function Test:RegisterApp()
  self.mobileSession:StartService(7)
  :Do(function (_,data)
    RegisterApp(self, _, model, modelYear, trim)
  end)
end

elseif indexOfTests == 2 then function Test:RegisterApp()
  self.mobileSession:StartService(7)
  :Do(function (_,data)
    RegisterApp(self, make, _, modelYear, trim)
  end)
end

elseif indexOfTests == 3 then function Test:RegisterApp()
  self.mobileSession:StartService(7)
  :Do(function (_,data)
    RegisterApp(self, make, model, _, trim)
  end)
end

elseif indexOfTests == 4 then function Test:RegisterApp()
  self.mobileSession:StartService(7)
  :Do(function (_,data)
    RegisterApp(self, make, model, modelYear, _)
  end)
end
 end

Test["Test parameters  ".. testname] = function ()
  -- body
  userPrint(33, "=== Positive test suit end ===")
  return true
end

indexOfTests = indexOfTests + 1

end

---------------------------------------------------------------------------------------------
-----------------------              Test 3                 ---------------------------------
---------------------------------------------------------------------------------------------


-- If HMI respond only with one parameter the SDL resend this parameter and "make", "model" (if they absent SDL select them from PT) 
local indexOfTests = 1

for i=indexOfTests, indexOfTests + 3 do

local testname = ""
local params = ""

if indexOfTests == 1 then testname = "only make parameter" 
elseif indexOfTests == 2 then testname = "only model parameter"
elseif indexOfTests == 3 then testname = "only modelYear parameter"
elseif indexOfTests == 4 then testname = "only trim parameter" end

if indexOfTests == 1 then 
    make = "make_|_"
    model  = absent
    modelYear  = absent 
    trim = absent
elseif indexOfTests == 2 then 
    model = "model_|_"
    make  = absent
    modelYear  = absent
    trim = absent
    
elseif indexOfTests == 3 then 
    modelYear = "modelYear_|_"
    make  = absent 
    model  = absent
    trim = absent
    
elseif indexOfTests == 4 then 
    trim = "trim_|_"
    make = absent  
    modelYear  = "BECOUSE BUG"
    model  = absent 
    --modelYear  = absent -- uncomment this line and comment the line under after fix APPLINK-19540 - SDL does not send vehicleType in RAI response to mobile if HMI respond only with "trim" parameter in GetVehicleType response
end

Test["Test parameters ".. testname] = function ()
  -- body
  userPrint(33, "=== Positive test suit start ===")
  return true
end

RestartSDL(self, i, make, model, modelYear, trim)

function Test:ConnectMobile()
  self:connectMobile()  
end

function Test:StartSession()
   CreateSession(self)
end

if indexOfTests == 1 then function Test:RegisterApp()
  self.mobileSession:StartService(7)
  :Do(function (_,data)
    RegisterApp(self, make, _, _, _)
  end)
end

elseif indexOfTests == 2 then function Test:RegisterApp()
  self.mobileSession:StartService(7)
  :Do(function (_,data)
    RegisterApp(self, _, model, _, _)
  end)
end

elseif indexOfTests == 3 then function Test:RegisterApp()
  self.mobileSession:StartService(7)
  :Do(function (_,data)
    RegisterApp(self, _, _, modelYear, _)
  end)
end

elseif indexOfTests == 4 then function Test:RegisterApp()
  self.mobileSession:StartService(7)
  :Do(function (_,data)
    RegisterApp(self, _, _, _, trim)
  end)
end
end

Test["Test parameters  ".. testname] = function ()
  -- body
  userPrint(33, "=== Positive test suit end ===")
  return true
end

indexOfTests = indexOfTests + 1

end

---------------------------------------------------------------------------------------------
-----------------------              Test 4                ---------------------------------
---------------------------------------------------------------------------------------------

-- HMI respond with OutUpperBound of parameters. SDL Does not send modelYear and trim in RAI response and send model and make which selected from PT
local indexOfTests = 1

for i=indexOfTests, indexOfTests + 3 do

local absent = "absent"

local OutUpperBound = "Aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"

local testname = ""
local params = ""

if indexOfTests == 1 then testname = "make parameter OutUpperBound" 
elseif indexOfTests == 2 then testname = "model parameter OutUpperBound"
elseif indexOfTests == 3 then testname = "modelYear parameter OutUpperBound"
elseif indexOfTests == 4 then testname = "trim parameter OutUpperBound" end


if indexOfTests == 1 then 
    make = OutUpperBound
    trim = "trim"
    model = "model"
    modelYear = "modelYear"

elseif indexOfTests == 2 then 
    model = OutUpperBound
    make = "make=="
    
elseif indexOfTests == 3 then 
    modelYear = OutUpperBound
    make = "make=="
    model = "model=="
    
elseif indexOfTests == 4 then 
    trim = OutUpperBound
    make = "make=="
    model = "model=="
    modelYear = "modelYear=="
    
end

Test["Test parameters ".. testname] = function ()
  -- body
  userPrint(33, "=== Positive test suit start ===")
  return true
end


RestartSDL(self, i, make, model, modelYear, trim)

function Test:ConnectMobile()
  self:connectMobile()  
end

function Test:StartSession()
   CreateSession(self)
end

function Test:RegisterApp()
  self.mobileSession:StartService(7)
  :Do(function (_,data)
    RegisterApp(self, _, _, modelYear, trim)
  end)
end

Test["Test parameters  ".. testname] = function ()
  userPrint(33, "=== Positive test suit end ===")
  return true
end

indexOfTests = indexOfTests + 1

end

---------------------------------------------------------------------------------------------
-----------------------              Test 5                ---------------------------------
---------------------------------------------------------------------------------------------

-- HMI respond with OutLowerBound of parameters. SDL does not send modelYear and trim in RAI response and send model and make which selected from PT
local indexOfTests = 1


for i=indexOfTests, indexOfTests + 3 do

local absent = "absent"

local OutLowerBound = ""

local testname = ""
local params = ""


if indexOfTests == 1 then testname = "make parameter OutLowerBound" 
elseif indexOfTests == 2 then testname = "model parameter OutLowerBound"
elseif indexOfTests == 3 then testname = "modelYear parameter OutLowerBound"
elseif indexOfTests == 4 then testname = "trim parameter OutLowerBound" end

if indexOfTests == 1 then 
    make = OutLowerBound
    trim = "trim"
    model = "model"
    modelYear = "modelYear"

elseif indexOfTests == 2 then 
    model = OutLowerBound
    make = "make=*="
    
elseif indexOfTests == 3 then 
    modelYear = OutLowerBound
    make = "make=*="
    model = "model=*="
    
elseif indexOfTests == 4 then 
    trim = OutLowerBound
    make = "make=*="
    model = "model=*="
    modelYear = "modelYear=*="
    
end

Test["Test parameters ".. testname] = function ()
  userPrint(33, "=== Positive test suit start ===")
  return true
end

RestartSDL(self, i, make, model, modelYear, trim)

function Test:ConnectMobile()
  self:connectMobile()  
end

function Test:StartSession()
   CreateSession(self)
end

function Test:RegisterApp()
  self.mobileSession:StartService(7)
  :Do(function (_,data)
    RegisterApp(self, _, _, modelYear, trim)
  end)
end

Test["Test parameters  ".. testname] = function ()
  userPrint(33, "=== Positive test suit end ===")
  return true
end

indexOfTests = indexOfTests + 1

end

---------------------------------------------------------------------------------------------
-----------------------              Test 6                ---------------------------------
---------------------------------------------------------------------------------------------

--Without all parameters
function Test:GetVehicleType_without_all_parameters()

RestartSDL(self, 7, "absent", "absent", "absent", "absent")
  function Test:ConnectMobile()
    self:connectMobile()  
  end


  function Test:StartSession()
     CreateSession(self)
  end

   function Test:RegisterApp()
    self.mobileSession:StartService(7)
    :Do(function (_,data)
      RegisterApp(self, _, _, _, _)
    end)
  end

end
 
----------------------------------------------------------------------------------------
------- TODO: After fix APPLINK-19188 add Precondition in beginning of script with Updating PT with  vehicle_make = "make_from_Policy"  vehicle_model = "model_from_Policy" in module_config table
------- TODO: Add case where PT will be updated with empty vehicle_make and vehicle_model and HMI respond without all parameters for GetVehicleType. SDL should not send VehicleType to mobile in RAI response




