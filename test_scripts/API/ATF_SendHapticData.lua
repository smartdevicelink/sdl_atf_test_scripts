--------------------------------------------------------------------------------
-- Copyright (c) 2017 Xevo Inc.
-- All rights reserved.
--------------------------------------------------------------------------------

Test = require('connecttest')
local commonFunctions =
  require('user_modules/shared_testcases/commonFunctions')

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
    "UI.SendHapticData",
    {
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

return Test
