--------------------------------------------------------------------------------
-- Preconditions before ATF start
--------------------------------------------------------------------------------
  -- copy initial connecttest.lua to FileName
  os.execute(  'cp ./modules/connecttest.lua  ./user_modules/connecttest_softButtonsCapabilities.lua')

  f = assert(io.open('./user_modules/connecttest_softButtonsCapabilities.lua', "r"))

  fileContent = f:read("*all")
  f:close()

  -- update function,  softButtonCapabilities struct
  local pattern1 = "function .?module%.?:.?initHMI%_onReady%(.?%)"
  local ResultPattern1 = fileContent:match(pattern1)

  if ResultPattern1 == nil then 
    print(" \27[31m initHMI_onReady function is not found in /user_modules/connecttest_softButtonsCapabilities.lua \27[0m ")
  else
    fileContent  =  string.gsub(fileContent, pattern1, "function module:initHMI_onReady(softButtonCapabilitiesValue) \n softButtonCapabilitiesValue = softButtonCapabilitiesValue or {{shortPressAvailable = true, longPressAvailable = true, upDownAvailable = true, imageSupported = true}}")
  end

  local ResultPatternTest = fileContent:match("softButtonCapabilities%s-=%s-%{%s-%{[%w%s,=%{%}]-%}%s-%}")
  local pattern
  if ResultPatternTest ~= nil then
      pattern = "softButtonCapabilities%s-=%s-%{%s-%{[%w%s,=%{%}]-%}%s-%}"
  else
    pattern = "softButtonCapabilities%s-=%s-%{[%w%s,=%{%}]-%}"
  end

  ResultPattern2 =  fileContent:match(pattern)

  if ResultPattern2 == nil then 
    print(" \27[31m softButtonCapabilities struct is not found in /user_modules/connecttest_softButtonsCapabilities.lua \27[0m ")
  else
    fileContent  =  string.gsub(fileContent, pattern, 'softButtonCapabilities = softButtonCapabilitiesValue')
  end

  f = assert(io.open('./user_modules/connecttest_softButtonsCapabilities.lua', "w+"))
  f:write(fileContent)
  f:close()
--------------------------------------------------------------------------------

Test = require('user_modules/connecttest_softButtonsCapabilities')
require('cardinalities')
local mobile_session = require("mobile_session")
require('user_modules/AppTypes')

local softButtonCapabilitiesarray = {}

--ToDo: shall be removed when APPLINK-16610 is fixed
config.defaultProtocolVersion = 2

---------------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------

-- Postcondition: removing user_modules/connecttest_softButtonsCapabilities.lua
function Test:Postcondition_remove_user_connecttest()
  os.execute( "rm -f ./user_modules/connecttest_softButtonsCapabilities.lua" )
end

-- Stop SDL

function Test:StopSDL()
  StopSDL()
end

-- Start SDL
function Test:StartSDL()
  StartSDL(config.pathToSDL, config.ExitOnCrash)
end

-- HMI initialization
function Test:InitHMI2()
  self:initHMI()
end

print("\27[32m!!!!!!!!!!!!!! SoftButtonCapabilities with one element as array checked in initHMI_onReady !!!!!!!!!!!!!!!!!!!!!!!\27[0m")

---------------------------------------------------------------------------------------------
-----------------------------------------I TEST BLOCK----------------------------------------
--------------CommonRequestCheck: Check of positive boundary parameters)---------------------
---------------------------------------------------------------------------------------------
  -- Begin Test suit PositiveRequestCheck
       -- Description: Check processing response from HMI with conditional parameters
       -- Requirement APPLINK-11829 UI.GetCapabilities: change HMI_API for SoftButtonCapabilities to be an array, HMI_API.xml

  -- Begin Test case 1.1 Check case with two elements in array

-- Test case:
function Test:SoftButtonCapabilities_2_elements()

  softButtonCapabilitiesarray = {
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          }
                                }

  self:initHMI_onReady(softButtonCapabilitiesarray)
end


-- Check that SDL resend softButtonCapabilities recieved from HMI to registered app :


function Test:ConnectMobile2()
  self:connectMobile()

  self.mobileSession= mobile_session.MobileSession(
  self,
  self.mobileConnection)
end

function Test:StartSession2()
  self.mobileSession:StartService(7)
    :Do(function()
    --mobile side: RegisterAppInterface request 
          local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)

            --mobile side: RegisterAppInterface response 
          EXPECT_RESPONSE(CorIdRAI, 
            { 
              success = true, 
              resultCode = "SUCCESS",
              softButtonCapabilities = softButtonCapabilitiesarray
            })
            :Do(function(_,data)
              EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
            end)

          EXPECT_NOTIFICATION("OnPermissionsChange")
    end)
end

-- End Test case 1.1
-- Begin Test Case 1.2 Check case with nine hundred and nine elements in array


-- Preconditions:

-- Should stop SDL
function Test:StopSDL()
  StopSDL()
end

-- Starts SDL
function Test:StartSDL()
  StartSDL(config.pathToSDL, config.ExitOnCrash)
end

-- HMI initialization
function Test:InitHMI3()
  self:initHMI()
end

-- Test case:
function Test:SoftButtonCapabilities_100_elements()

  softButtonCapabilitiesarray = {
          {
            shortPressAvailable = true,
            longPressAvailable = false,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = false
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          }
        }
  self:initHMI_onReady(softButtonCapabilitiesarray)
end

-- Check that SDL resend softButtonCapabilities recieved from HMI to registered app :


function Test:ConnectMobile3()
  self:connectMobile()

  self.mobileSession= mobile_session.MobileSession(
  self,
  self.mobileConnection)
end

function Test:StartSession3()
  self.mobileSession:StartService(7)
    :Do(function()
    --mobile side: RegisterAppInterface request 
          local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)

            --mobile side: RegisterAppInterface response 
          EXPECT_RESPONSE(CorIdRAI, 
            { 
              success = true, 
              resultCode = "SUCCESS",
              softButtonCapabilities = softButtonCapabilitiesarray
            })
            :Do(function(_,data)
              EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
            end)

          EXPECT_NOTIFICATION("OnPermissionsChange")
    end)
end

-- End Test case 1.2

-- End Test suit PositiveRequestCheck


---------------------------------------------------------------------------------------------
-----------------------------------------II TEST BLOCK----------------------------------------
--------------------CommonRequestCheck: Check of invalid parameters-------------------------
---------------------------------------------------------------------------------------------
  -- Begin Test suit NegativeRequestCheck
       -- Description: Check processing response from HMI with invalid parameters
       -- Requirement APPLINK-11829 UI.GetCapabilities: change HMI_API for SoftButtonCapabilities to be an array, HMI_API.xml

  -- Begin Test case 2.1 Check case with one hundred and one elements in array

-- Preconditions:

-- Should stop SDL
function Test:StopSDL()
  StopSDL()
end

-- Starts SDL
function Test:StartSDL()
  StartSDL(config.pathToSDL, config.ExitOnCrash)
end

function Test:InitHMI4()
  self:initHMI()
end


-- Test case:
function Test:SoftButtonCapabilities_101_elements()

  softButtonCapabilitiesarray = {
          {
            shortPressAvailable = true,
            longPressAvailable = false,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = false
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          },
          {
            shortPressAvailable = true,
            longPressAvailable = true,
            upDownAvailable = true,
            imageSupported = true
          }
        }
  self:initHMI_onReady(softButtonCapabilitiesarray)
end

-- Check that SDL apply default softButtonCapabilities as in hmi_capabilities.json


function Test:ConnectMobile4()
  self:connectMobile()

  self.mobileSession= mobile_session.MobileSession(
  self,
  self.mobileConnection)
end

function Test:StartSession4()
  self.mobileSession:StartService(7)
    :Do(function()
    --mobile side: RegisterAppInterface request 
          local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)

            --mobile side: RegisterAppInterface response 
          EXPECT_RESPONSE(CorIdRAI, 
            { 
              success = true, 
              resultCode = "SUCCESS",
              softButtonCapabilities = {{
                                         shortPressAvailable = true,
                                         longPressAvailable = true,
                                         upDownAvailable = true,
                                         imageSupported = true
                                       }}
            })
            :Do(function(_,data)
              EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
            end)
            :ValidIf(function(_,data)
              if #data.payload.softButtonCapabilities == 1 then 
                return true
              else 
                 print("\27[31m Number of elements in softbuttonscapabilities is not equal one, actual value "..tostring(#data.payload.softButtonCapabilities).."\27[0m")
                 return false 
               end
            end)  

          EXPECT_NOTIFICATION("OnPermissionsChange")
    end)
end


-- End test case 2.1.
-- Begin Test case 2.2 Check case with empty array

-- Preconditions:

-- Should stop SDL
function Test:StopSDL()
  StopSDL()
end

-- Starts SDL
function Test:StartSDL()
  StartSDL(config.pathToSDL, config.ExitOnCrash)
end

function Test:InitHMI4()
  self:initHMI()
end

--Test case:

function Test:SoftButtonCapabilities_empty_array()

  softButtonCapabilitiesarray = { }

  self:initHMI_onReady(softButtonCapabilitiesarray)
end

-- Check that SDL apply default softButtonCapabilities as in hmi_capabilities.json


function Test:ConnectMobile4()
  self:connectMobile()

  self.mobileSession= mobile_session.MobileSession(
  self,
  self.mobileConnection)
end

function Test:StartSession4()
  self.mobileSession:StartService(7)
    :Do(function()
    --mobile side: RegisterAppInterface request 
          local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)

            --mobile side: RegisterAppInterface response 
          EXPECT_RESPONSE(CorIdRAI, 
            { 
              success = true, 
              resultCode = "SUCCESS",
              softButtonCapabilities = {{
                                         shortPressAvailable = true,
                                         longPressAvailable = true,
                                         upDownAvailable = true,
                                         imageSupported = true
                                       }}
            })
            :Do(function(_,data)
              EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
            end)
            :ValidIf(function(_,data)
              if #data.payload.softButtonCapabilities == 1 then 
                return true
              else 
                 print("\27[31m Number of elements in softbuttonscapabilities is not equal one, actual value "..tostring(#data.payload.softButtonCapabilities).."\27[0m")
                 return false 
               end
            end)  

          EXPECT_NOTIFICATION("OnPermissionsChange")
    end)
end


-- End test case 2.2.
-- Begin Test case 2.3 Check case with not an array - number

-- Preconditions:

-- Should stop SDL
function Test:StopSDL()
  StopSDL()
end

-- Starts SDL
function Test:StartSDL()
  StartSDL(config.pathToSDL, config.ExitOnCrash)
end

function Test:InitHMI5()
  self:initHMI()
end

--Test case:

function Test:SoftButtonCapabilities_Not_array_Num()

  softButtonCapabilitiesarray = 8833453458340958

  self:initHMI_onReady(softButtonCapabilitiesarray)
end

-- Check that SDL apply default softButtonCapabilities as in hmi_capabilities.json


function Test:ConnectMobile5()
  self:connectMobile()

  self.mobileSession= mobile_session.MobileSession(
  self,
  self.mobileConnection)
end

function Test:StartSession5()
  self.mobileSession:StartService(7)
    :Do(function()
    --mobile side: RegisterAppInterface request 
          local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)

            --mobile side: RegisterAppInterface response 
          EXPECT_RESPONSE(CorIdRAI, 
            { 
              success = true, 
              resultCode = "SUCCESS",
              softButtonCapabilities = {{
                                         shortPressAvailable = true,
                                         longPressAvailable = true,
                                         upDownAvailable = true,
                                         imageSupported = true
                                       }}
            })
            :Do(function(_,data)
              EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
            end)
            :ValidIf(function(_,data)
              if #data.payload.softButtonCapabilities == 1 then 
                return true
              else 
                 print("\27[31m Number of elements in softbuttonscapabilities is not equal one, actual value "..tostring(#data.payload.softButtonCapabilities).."\27[0m")
                 return false 
               end
            end)  

          EXPECT_NOTIFICATION("OnPermissionsChange")
    end)
end



-- End test case 2.3.
-- Begin Test case 2.4 Check case with not an array - string

-- Preconditions:

-- Should stop SDL
function Test:StopSDL()
  StopSDL()
end

-- Starts SDL
function Test:StartSDL()
  StartSDL(config.pathToSDL, config.ExitOnCrash)
end

function Test:InitHMI5()
  self:initHMI()
end

--Test case:

function Test:SoftButtonCapabilities_Not_array_string()

  softButtonCapabilitiesarray = "ashdjshflsdhfdklshfdshf"

  self:initHMI_onReady(softButtonCapabilitiesarray)
end

-- Check that SDL apply default softButtonCapabilities as in hmi_capabilities.json


function Test:ConnectMobile5()
  self:connectMobile()

  self.mobileSession= mobile_session.MobileSession(
  self,
  self.mobileConnection)
end

function Test:StartSession5()
  self.mobileSession:StartService(7)
    :Do(function()
    --mobile side: RegisterAppInterface request 
          local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)

            --mobile side: RegisterAppInterface response 
          EXPECT_RESPONSE(CorIdRAI, 
            { 
              success = true, 
              resultCode = "SUCCESS",
              softButtonCapabilities = {{
                                         shortPressAvailable = true,
                                         longPressAvailable = true,
                                         upDownAvailable = true,
                                         imageSupported = true
                                       }}
            })
            :Do(function(_,data)
              EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
            end)
            :ValidIf(function(_,data)
              if #data.payload.softButtonCapabilities == 1 then 
                return true
              else 
                 print("\27[31m Number of elements in softbuttonscapabilities is not equal one, actual value "..tostring(#data.payload.softButtonCapabilities).."\27[0m")
                 return false 
               end
            end)  

          EXPECT_NOTIFICATION("OnPermissionsChange")
    end)
end
