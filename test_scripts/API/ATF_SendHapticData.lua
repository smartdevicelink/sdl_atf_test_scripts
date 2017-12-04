--[[

 Copyright (c) 2017 Xevo Inc.
 All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:

 Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.

 Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following
 disclaimer in the documentation and/or other materials provided with the
 distribution.

 Neither the name of the Xevo Inc. nor the names of its contributors
 may be used to endorse or promote products derived from this software
 without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
 LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.

--]]

Test = require('connecttest')
local mobile_session = require('mobile_session')
local commonFunctions =
  require('user_modules/shared_testcases/commonFunctions')
local json = require("modules/json")

--------------------------------------------------------------------------------
-- PRECONDITIONS
--------------------------------------------------------------------------------
commonFunctions:newTestCasesGroup("Preconditions: Change policy table, " ..
  "restart SDL and activate application ")

function DelayedExp()
  local event = events.Event()
  event.matches = function(self, e) return self == e end
  EXPECT_EVENT(event, "Delayed event")
  RUN_AFTER(function() RAISE_EVENT(event, event) end, 2000)
end

function AddHapticGroupToPolicyTable(policyTable)
  policyTable.functional_groupings.HapticGroup = {}
  policyTable.functional_groupings.HapticGroup.rpcs = {}
  policyTable.functional_groupings.HapticGroup.rpcs.
    OnTouchEvent = {}
  policyTable.functional_groupings.HapticGroup.rpcs.
    OnTouchEvent.hmi_levels = {'FULL'}
  policyTable.functional_groupings.HapticGroup.rpcs.
    SendHapticData = {}
  policyTable.functional_groupings.HapticGroup.rpcs.
    SendHapticData.hmi_levels = {'FULL'}
  policyTable.app_policies.default.groups = {"Base-4", "HapticGroup"}
end

local ModifyPolicyTable = AddHapticGroupToPolicyTable

function Test:StopSDLToBackUpPreloadedPt( ... )
  self.mobileSession:Stop()
  StopSDL()
  DelayedExp(1000)
end

function Test:BackUpPreloadedPt()
  os.execute('cp ' .. config.pathToSDL .. '/sdl_preloaded_pt.json' .. ' ' ..
    config.pathToSDL .. '/backup_sdl_preloaded_pt.json')
  os.execute('rm ' .. config.pathToSDL .. '/storage/policy.sqlite')
end

function Test:ModifyPreloadedPt()
  pathToFile = config.pathToSDL .. '/sdl_preloaded_pt.json'
  local file  = io.open(pathToFile, "r")
  local json_data = file:read("*all")
  file:close()

  local data = json.decode(json_data)
  for k,v in pairs(data.policy_table.functional_groupings) do
    if (data.policy_table.functional_groupings[k].rpcs == nil) then
      data.policy_table.functional_groupings[k] = nil
    else
      local count = 0
      for _ in pairs(data.policy_table.functional_groupings[k].rpcs) do
        count = count + 1
      end
      if (count < 30) then
        data.policy_table.functional_groupings[k] = nil
      end
    end
  end
  ModifyPolicyTable(data.policy_table)
  data = json.encode(data)

  file = io.open(pathToFile, "w")
  file:write(data)
  file:close()
end

function Test:Precondition_StartSDL()
  StartSDL(config.pathToSDL, config.ExitOnCrash)
  DelayedExp(1000)
end

function Test:Precondition_InitHMI_1()
  self:initHMI()
end

function Test:Precondition_InitHMI_onReady_1()
  self:initHMI_onReady()
end

function Test:Precondition_ConnectMobile_1()
  self:connectMobile()
end

function Test:Precondition_StartSession_1()
  self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
end

function Test:RestorePreloadedPt()
  os.execute('cp ' .. config.pathToSDL .. '/backup_sdl_preloaded_pt.json' ..
    ' ' .. config.pathToSDL .. '/sdl_preloaded_pt.json')
  os.execute('rm ' .. config.pathToSDL .. '/backup_sdl_preloaded_pt.json')
end

local myAppID = 0

function Test:RegisterApp()
  self.mobileSession:StartService(7)
  :Do(function (_, data)
    -- mobile side
    local corrID = self.mobileSession:SendRPC("RegisterAppInterface",
      config.application1.registerAppInterfaceParams)

    -- hmi side
    EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
    :Do(function (_, data)
      myAppID = data.params.application.appID
    end)

    -- mobile side
    EXPECT_RESPONSE(corrID, {success = true})
  end)
end

function Test:ActivationApp()
  --hmi side
  local requestId = self.hmiConnection:SendRequest("SDL.ActivateApp",
    { appID = myAppID})
  EXPECT_HMIRESPONSE(requestId)

  --mobile side
  EXPECT_NOTIFICATION("OnHMIStatus",
    {hmiLevel = "FULL", systemContext = "MAIN"})
end

--------------------------------------------------------------------------------
-- TEST BLOCK I : Check normal cases
--------------------------------------------------------------------------------
commonFunctions:newTestCasesGroup("Test suite: Check normal cases")

function Test:SingleSpatialData()
  -- mobile side
  local cid = self.mobileSession:SendRPC(
    "SendHapticData",
    {
      hapticRectData =
      { { id = 1, rect = { x = 2.0, y = 3.0, width = 4.0, height = 5.0 } } }
    }
  )
  -- hmi side
  EXPECT_HMICALL(
    "UI.SendHapticData",
    {
      hapticRectData =
      { { id = 1, rect = { x = 2.0, y = 3.0, width = 4.0, height = 5.0 } } }
    }
  )
  :Do(function(_,data)
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
  end)
  -- mobile side
  EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
  :ValidIf (function(_,data)
    return true
  end)
end

function Test:MultiSpatialData()
  -- mobile side
  local cid = self.mobileSession:SendRPC(
    "SendHapticData",
    {
      hapticRectData =
      { { id = 1, rect = { x = 2.0,  y = 3.0,  width = 4.0,  height = 5.0  } },
        { id = 2, rect = { x = 12.0, y = 13.0, width = 14.0, height = 15.0 } } }
    }
  )
  -- hmi side
  EXPECT_HMICALL(
    "UI.SendHapticData",
    {
      hapticRectData =
      { { id = 1, rect = { x = 2.0, y = 3.0, width = 4.0, height = 5.0     } },
        { id = 2, rect = { x = 12.0, y = 13.0, width = 14.0, height = 15.0 } } } 
    }
  )
  :Do(function(_,data)
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
  end)
  -- mobile side
  EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
  :ValidIf (function(_,data)
    return true
  end)
end

function Test:MaxSpatialData()

  local spatial_data = {}
  for i= 1, 1000 do
    table.insert(spatial_data,
      {id = i, rect = { x = i+2, y=i+3, width=i+4, height=i+5 } })
  end

  -- mobile side
  local cid = self.mobileSession:SendRPC(
    "SendHapticData", { hapticRectData = spatial_data }
  )
  -- hmi side
  EXPECT_HMICALL(
    "UI.SendHapticData",
    {
      hapticRectData = spatial_data
    }
  )
  :Do(function(_,data)
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
  end)
  -- mobile side
  EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
  :ValidIf (function(_,data)
    return true
  end)
end

function Test:NoSpatialData()
  -- mobile side
  local cid = self.mobileSession:SendRPC(
    "SendHapticData", {}
  )
  -- hmi side
  EXPECT_HMICALL(
    "UI.SendHapticData"
  )
  :Do(function(_,data)
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
  end)
  -- mobile side
  EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
  :ValidIf (function(_,data)
    return true
  end)
end

--------------------------------------------------------------------------------
-- TEST BLOCK II : Check error cases
--------------------------------------------------------------------------------
commonFunctions:newTestCasesGroup("Test suite: Check error cases")

function Test:GenericError()
  -- mobile side
  local cid = self.mobileSession:SendRPC(
    "SendHapticData",
    {
      hapticRectData =
      { { id = 1, rect = { x = 2.0, y = 3.0, width = 4.0, height = 5.0 } } }
    }
  )
  -- hmi side
  EXPECT_HMICALL(
    "UI.SendHapticData",
    {
      hapticRectData =
      { { id = 1, rect = { x = 2.0, y = 3.0, width = 4.0, height = 5.0, } } }
    }
  )
  :Do(function(_,data)
    self.hmiConnection:SendResponse(data.id, data.method, "GENERIC_ERROR", {})
  end)
  -- mobile side
  EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR" })
  :ValidIf (function(_,data)
    return true
  end)
end

function Test:InvalidDataNonExistId()
  -- mobile side
  local cid = self.mobileSession:SendRPC(
    "SendHapticData",
    {
      hapticRectData =
        { { rect = { x = 2.0, y = 3.0, width = 4.0, height = 5.0, } } }
    }
  )
  -- mobile side
  EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
  :ValidIf (function(_,data)
    return true
  end)
end

function Test:InvalidDataNonExistX()
  -- mobile side
  local cid = self.mobileSession:SendRPC(
    "SendHapticData",
    {
      hapticRectData =
      { { id = 1, rect = { y = 3.0, width = 4.0, height = 5.0, } } }
    }
  )
  -- mobile side
  EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
  :ValidIf (function(_,data)
    return true
  end)
end

function Test:InvalidDataNonExistY()
  -- mobile side
  local cid = self.mobileSession:SendRPC(
    "SendHapticData",
    {
      hapticRectData =
      { { id = 1, rect = { x = 2.0, width = 4.0, height = 5.0, } } }
    }
  )
  -- mobile side
  EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
  :ValidIf (function(_,data)
    return true
  end)
end

function Test:InvalidDataNonExistWidth()
  -- mobile side
  local cid = self.mobileSession:SendRPC(
    "SendHapticData",
    {
      hapticRectData =
      { { id = 1, rect = { x = 2.0, y = 3.0, height = 5.0, } } }
    }
  )
  -- mobile side
  EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
  :ValidIf (function(_,data)
    return true
  end)
end

function Test:InvalidDataNonExistHeight()
  -- mobile side
  local cid = self.mobileSession:SendRPC(
    "SendHapticData",
    {
      hapticRectData =
      { { id = 1, rect = { x = 2.0, y = 3.0, width = 4.0, } } }
    }
  )
  -- mobile side
  EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
  :ValidIf (function(_,data)
    return true
  end)
end

function Test:InvalidDataWithUnknowItem()
  -- mobile side
  local cid = self.mobileSession:SendRPC(
    "SendHapticData",
    {
      hapticRectData =
      { { id = 1, rect = { a = 2.0, y = 3.0, width = 4.0, height = 5.0 } } }
    }
  )
  -- mobile side
  EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
  :ValidIf (function(_,data)
    return true
  end)
end

function Test:InvalidDataOverMaxSpatialData()

  local spatial_data = {}
  for i= 1, 1001 do
    table.insert(spatial_data, {id = i, rect =
      { x = i+2, y=i+3, width=i+4, height=i+5 } })
  end

  -- mobile side
  local cid = self.mobileSession:SendRPC(
    "SendHapticData", { hapticRectData = spatial_data }
  )
  -- mobile side
  EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
  :ValidIf (function(_,data)
    return true
  end)
end

function Test:SingleSpatialDataWithMaxID()
  -- mobile side
  local cid = self.mobileSession:SendRPC(
    "SendHapticData",
    {
      hapticRectData =
      { { id = 2000000000,
        rect = { x = 2.0, y = 3.0, width = 4.0, height = 5.0 } } }
    }
  )
  -- hmi side
  EXPECT_HMICALL(
    "UI.SendHapticData",
    {
      hapticRectData =
      { { id = 2000000000,
        rect = { x = 2.0, y = 3.0, width = 4.0, height = 5.0, } } }
    }
  )
  :Do(function(_,data)
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
  end)
  -- mobile side
  EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
  :ValidIf (function(_,data)
    return true
  end)
end

function Test:InvalidDataOverMaxID()
  -- mobile side
  local cid = self.mobileSession:SendRPC(
    "SendHapticData",
    {
      hapticRectData =
      { { id = 2000000001,
        rect = { x = 2.0, y = 3.0, width = 5.0, height = 5.0, } } }
    }
  )
  -- mobile side
  EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
  :ValidIf (function(_,data)
    return true
  end)
end

function Test:SingleSpatialDataWithLargeNumber()
  -- mobile side
  local cid = self.mobileSession:SendRPC(
    "SendHapticData",
    {
      hapticRectData =
      { { id = 2000000000, rect = { x = 2000000001, y = 2000000002,
        width = 2000000003, height = 2000000004 } } }
    }
  )
  -- hmi side
  EXPECT_HMICALL(
    "UI.SendHapticData",
    {
      hapticRectData =
      { { id = 2000000000, rect = { x = 2000000001, y = 2000000002,
        width = 2000000003, height = 2000000004, } } }
    }
  )
  :Do(function(_,data)
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
  end)
  -- mobile side
  EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
  :ValidIf (function(_,data)
    return true
  end)
end

function Test:SingleSpatialDataWithFloatNumber()
  -- mobile side
  local cid = self.mobileSession:SendRPC(
    "SendHapticData",
    {
      hapticRectData =
      { { id = 1, rect = { x = 2.1, y = 3.3, width = 4.7, height = 5.9 } } }
    }
  )
  -- hmi side
  EXPECT_HMICALL(
    "UI.SendHapticData",
    {
      hapticRectData =
      { { id = 1, rect = { x = 2.1, y = 3.3, width = 4.7, height = 5.9, } } }
    }
  )
  :Do(function(_,data)
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
  end)
  -- mobile side
  EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
  :ValidIf (function(_,data)
    return true
  end)
end

function Test:Postconditions()
  StopSDL()
end

return Test
