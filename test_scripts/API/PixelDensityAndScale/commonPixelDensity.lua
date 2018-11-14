---------------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")

--[[ Variables ]]
local m = actions

m.defaultValue = {
    diagonalScreenSize = 8,
    pixelPerInch = 117,
    scale = 1
}

--[[ Functions]]
function m.getSystemCapability(pDiagonalSize, pPixelPerInch, pScale)
    local corId = m.getMobileSession():SendRPC("GetSystemCapability", { systemCapabilityType = "VIDEO_STREAMING" })
    m.getMobileSession():ExpectResponse(corId, { success = true, resultCode = "SUCCESS",
        systemCapability = {
            videoStreamingCapability = {
                supportedFormats = {
                    {codec = "H264",
                    protocol= "RAW"}
                },
                preferredResolution = {
                    resolutionHeight = 350,
                    resolutionWidth = 800
                },
                scale = pScale,
                pixelPerInch = pPixelPerInch,
                diagonalScreenSize = pDiagonalSize,
                maxBitrate = 10000,
                hapticSpatialDataSupported = false
            },
        systemCapabilityType = "VIDEO_STREAMING"}
        })
end

return m