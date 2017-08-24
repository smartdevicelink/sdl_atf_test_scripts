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
  -- mobiel side
  local cid = self.mobileSession:SendRPC(
    "SendHapticData",
    {
      HapticSpatialData =
      { { id = 1, x = 2.0, y = 3.0, width = 4.0, height = 5.0 } }
    }
  )
  -- hmi side
  EXPECT_HMICALL(
    "UI.SendHapticData",
    {
      HapticSpatialData =
      { { id = 1, x = 2.0, y = 3.0, width = 4.0, height = 5.0, } }
    }
  )
  :Do(function(_,data)
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
  end)
  -- mobiel side
  EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
  :ValidIf (function(_,data)
    return true
  end)
end

function Test:MultiSpatialData()
  -- mobiel side
  local cid = self.mobileSession:SendRPC(
    "SendHapticData",
    {
      HapticSpatialData =
      { { id = 1, x = 2.0, y = 3.0, width = 4.0, height = 5.0     },
        { id = 2, x = 12.0, y = 13.0, width = 14.0, height = 15.0 } }
    }
  )
  -- hmi side
  EXPECT_HMICALL(
    "UI.SendHapticData",
    {
      HapticSpatialData =
      { { id = 1, x = 2.0, y = 3.0, width = 4.0, height = 5.0     },
        { id = 2, x = 12.0, y = 13.0, width = 14.0, height = 15.0 } } 
    }
  )
  :Do(function(_,data)
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
  end)
  -- mobiel side
  EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
  :ValidIf (function(_,data)
    return true
  end)
end

function Test:MaxSpatialData()

  local spatial_data = {}
  for i= 1, 1000 do
    table.insert(spatial_data,
      {id = i, x = i+2, y=i+3, width=i+4, height=i+5})
  end

  -- mobiel side
  local cid = self.mobileSession:SendRPC(
    "SendHapticData", { HapticSpatialData = spatial_data }
  )
  -- hmi side
  EXPECT_HMICALL(
    "UI.SendHapticData",
    {
      HapticSpatialData = spatial_data
    }
  )
  :Do(function(_,data)
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
  end)
  -- mobiel side
  EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
  :ValidIf (function(_,data)
    return true
  end)
end

function Test:NoSpatialData()
  -- mobiel side
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
  -- mobiel side
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
  -- mobiel side
  local cid = self.mobileSession:SendRPC(
    "SendHapticData",
    {
      HapticSpatialData =
      { { id = 1, x = 2.0, y = 3.0, width = 4.0, height = 5.0 } }
    }
  )
  -- hmi side
  EXPECT_HMICALL(
    "UI.SendHapticData",
    {
      HapticSpatialData =
      { { id = 1, x = 2.0, y = 3.0, width = 4.0, height = 5.0, } }
    }
  )
  :Do(function(_,data)
    self.hmiConnection:SendResponse(data.id, data.method, "GENERIC_ERROR", {})
  end)
  -- mobiel side
  EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR" })
  :ValidIf (function(_,data)
    return true
  end)
end

function Test:InvalidDataNonExistId()
  -- mobiel side
  local cid = self.mobileSession:SendRPC(
    "SendHapticData",
    {
      HapticSpatialData =
        { { x = 2.0, y = 3.0, width = 4.0, height = 5.0, } }
    }
  )
  -- mobiel side
  EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
  :ValidIf (function(_,data)
    return true
  end)
end

function Test:InvalidDataNonExistX()
  -- mobiel side
  local cid = self.mobileSession:SendRPC(
    "SendHapticData",
    {
      HapticSpatialData =
      { { id = 1, y = 3.0, width = 4.0, height = 5.0, } }
    }
  )
  -- mobiel side
  EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
  :ValidIf (function(_,data)
    return true
  end)
end

function Test:InvalidDataNonExistY()
  -- mobiel side
  local cid = self.mobileSession:SendRPC(
    "SendHapticData",
		{
		  HapticSpatialData =
			{ { id = 1, x = 2.0, width = 4.0, height = 5.0, } }
		}
  )
  -- mobiel side
  EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
  :ValidIf (function(_,data)
    return true
  end)
end

function Test:InvalidDataNonExistWidth()
  -- mobiel side
  local cid = self.mobileSession:SendRPC(
    "SendHapticData",
		{
		  HapticSpatialData =
			{ { id = 1, x = 2.0, y = 3.0, height = 5.0, } }
		}
  )
  -- mobiel side
  EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
  :ValidIf (function(_,data)
    return true
  end)
end

function Test:InvalidDataNonExistHeight()
  -- mobiel side
  local cid = self.mobileSession:SendRPC(
    "SendHapticData",
		{
		  HapticSpatialData =
			{ { id = 1, x = 2.0, y = 3.0, width = 4.0, } }
		}
  )
  -- mobiel side
  EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
  :ValidIf (function(_,data)
    return true
  end)
end

function Test:InvalidDataWithUnknowItem()
  -- mobiel side
  local cid = self.mobileSession:SendRPC(
    "SendHapticData",
		{
		  HapticSpatialData =
			{ { id = 1, a = 2.0, y = 3.0, width = 4.0, height = 5.0} }
		}
  )
  -- mobiel side
  EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
  :ValidIf (function(_,data)
    return true
  end)
end

function Test:InvalidDataOverMaxSpatialData()

  local spatial_data = {}
  for i= 1, 1001 do
    table.insert(spatial_data, {id = i, x = i+2, y=i+3, width=i+4, height=i+5})
  end

  -- mobiel side
  local cid = self.mobileSession:SendRPC(
    "SendHapticData", { HapticSpatialData = spatial_data }
  )
  -- mobiel side
  EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
  :ValidIf (function(_,data)
    return true
  end)
end

function Test:SingleSpatialDataWithMaxID()
  -- mobiel side
  local cid = self.mobileSession:SendRPC(
    "SendHapticData",
		{
		  HapticSpatialData =
			{ { id = 2000000000, x = 2.0, y = 3.0, width = 4.0, height = 5.0 } }
		}
  )
  -- hmi side
  EXPECT_HMICALL(
    "UI.SendHapticData",
    {
      HapticSpatialData =
			{ { id = 2000000000, x = 2.0, y = 3.0, width = 4.0, height = 5.0, } }
    }
  )
  :Do(function(_,data)
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
  end)
  -- mobiel side
  EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
  :ValidIf (function(_,data)
    return true
  end)
end

function Test:InvalidDataOverMaxID()
  -- mobiel side
  local cid = self.mobileSession:SendRPC(
    "SendHapticData",
		{
		  HapticSpatialData =
			{ { id = 2000000001, x = 2.0, y = 3.0, width = 5.0, height = 5.0, } }
		}
  )
  -- mobiel side
  EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
  :ValidIf (function(_,data)
    return true
  end)
end

function Test:SingleSpatialDataWithLargeNumber()
  -- mobiel side
  local cid = self.mobileSession:SendRPC(
    "SendHapticData",
		{
		  HapticSpatialData =
			{ { id = 2000000000, x = 2000000001, y = 2000000002,
			  width = 2000000003, height = 2000000004 } }
		}
  )
  -- hmi side
  EXPECT_HMICALL(
    "UI.SendHapticData",
    {
      HapticSpatialData =
			{ { id = 2000000000, x = 2000000001, y = 2000000002,
			  width = 2000000003, height = 2000000004, } }
    }
  )
  :Do(function(_,data)
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
  end)
  -- mobiel side
  EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
  :ValidIf (function(_,data)
    return true
  end)
end

function Test:SingleSpatialDataWithFloatNumber()
  -- mobiel side
  local cid = self.mobileSession:SendRPC(
    "SendHapticData",
		{
		  HapticSpatialData =
			{ { id = 1, x = 2.1, y = 3.3, width = 4.7, height = 5.9 } }
		}
  )
  -- hmi side
  EXPECT_HMICALL(
    "UI.SendHapticData",
    {
      HapticSpatialData =
			{ { id = 1, x = 2.1, y = 3.3, width = 4.7, height = 5.9, } }
    }
  )
  :Do(function(_,data)
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
  end)
  -- mobiel side
  EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
  :ValidIf (function(_,data)
    return true
  end)
end

return Test
