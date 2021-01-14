local SDL = require('SDL')
local utils = require('user_modules/utils')
local module = { }

--[[ Functions for Values' Creation ]]
--[[ @createButtonCapability: the function creates a value for Buttons.GetCapabilities
--! @parameters:
--! for shortPressAvailable, longPressAvailable and upDownAvailable params "true" is
-- default value, so if they are not specified or equal to different values
-- than "false" they are set to "true" ]]
function module.createButtonCapability(name, shortPressAvailable, longPressAvailable, upDownAvailable, moduleInfo)
  return {
    name = name,
    moduleInfo = moduleInfo,
    shortPressAvailable = shortPressAvailable ~= false or false,
    longPressAvailable = longPressAvailable ~= false or false,
    upDownAvailable = upDownAvailable ~= false or false
  }
end

function module.createRCModuleCapability(moduleType, moduleInformation)
  local moduleCapabilities = {
    CLIMATE = {
      currentTemperatureAvailable = true,
      fanSpeedAvailable = true,
      desiredTemperatureAvailable = true,
      acEnableAvailable = true,
      acMaxEnableAvailable = true,
      circulateAirEnableAvailable = true,
      autoModeEnableAvailable = true,
      dualModeEnableAvailable = true,
      defrostZoneAvailable = true,
      defrostZone = {
        "FRONT", "REAR", "ALL", "NONE"
      },
      ventilationModeAvailable = true,
      ventilationMode = {
        "UPPER", "LOWER", "BOTH", "NONE"
      },
      heatedSteeringWheelAvailable = true,
      heatedWindshieldAvailable = true,
      heatedRearWindowAvailable = true,
      heatedMirrorsAvailable = true,
      climateEnableAvailable = true
    },
    RADIO = {
      radioEnableAvailable = true,
      radioBandAvailable = true,
      radioFrequencyAvailable = true,
      hdChannelAvailable = true,
      rdsDataAvailable = true,
      availableHdChannelsAvailable = true,
      stateAvailable = true,
      signalStrengthAvailable = true,
      signalChangeThresholdAvailable = true,
      sisDataAvailable = true,
      hdRadioEnableAvailable = true,
      siriusxmRadioAvailable = true
    },
    SEAT = {
      heatingEnabledAvailable = true,
      coolingEnabledAvailable = true,
      heatingLevelAvailable = true,
      coolingLevelAvailable = true,
      horizontalPositionAvailable = true,
      verticalPositionAvailable = true,
      frontVerticalPositionAvailable = true,
      backVerticalPositionAvailable = true,
      backTiltAngleAvailable = true,
      headSupportHorizontalPositionAvailable = true,
      headSupportVerticalPositionAvailable = true,
      massageEnabledAvailable = true,
      massageModeAvailable = true,
      massageCushionFirmnessAvailable = true,
      memoryAvailable = true
    },
    AUDIO = {
      sourceAvailable = true,
      keepContextAvailable = true,
      volumeAvailable = true,
      equalizerAvailable = true,
      equalizerMaxChannelId = 100
    },
    LIGHT = {
      supportedLights = (function()
        local lights = { "FRONT_LEFT_HIGH_BEAM", "FRONT_RIGHT_HIGH_BEAM", "FRONT_LEFT_LOW_BEAM",
          "FRONT_RIGHT_LOW_BEAM", "FRONT_LEFT_PARKING_LIGHT", "FRONT_RIGHT_PARKING_LIGHT",
          "FRONT_LEFT_FOG_LIGHT", "FRONT_RIGHT_FOG_LIGHT", "FRONT_LEFT_DAYTIME_RUNNING_LIGHT",
          "FRONT_RIGHT_DAYTIME_RUNNING_LIGHT", "FRONT_LEFT_TURN_LIGHT", "FRONT_RIGHT_TURN_LIGHT",
          "REAR_LEFT_FOG_LIGHT", "REAR_RIGHT_FOG_LIGHT", "REAR_LEFT_TAIL_LIGHT", "REAR_RIGHT_TAIL_LIGHT",
          "REAR_LEFT_BRAKE_LIGHT", "REAR_RIGHT_BRAKE_LIGHT", "REAR_LEFT_TURN_LIGHT", "REAR_RIGHT_TURN_LIGHT",
          "REAR_REGISTRATION_PLATE_LIGHT", "HIGH_BEAMS", "LOW_BEAMS", "FOG_LIGHTS", "RUNNING_LIGHTS",
          "PARKING_LIGHTS", "BRAKE_LIGHTS", "REAR_REVERSING_LIGHTS", "SIDE_MARKER_LIGHTS", "LEFT_TURN_LIGHTS",
          "RIGHT_TURN_LIGHTS", "HAZARD_LIGHTS", "AMBIENT_LIGHTS", "OVERHEAD_LIGHTS", "READING_LIGHTS",
          "TRUNK_LIGHTS", "EXTERIOR_FRONT_LIGHTS", "EXTERIOR_REAR_LIGHTS", "EXTERIOR_LEFT_LIGHTS",
          "EXTERIOR_RIGHT_LIGHTS", "REAR_CARGO_LIGHTS", "REAR_TRUCK_BED_LIGHTS", "REAR_TRAILER_LIGHTS",
          "LEFT_SPOT_LIGHTS", "RIGHT_SPOT_LIGHTS", "LEFT_PUDDLE_LIGHTS", "RIGHT_PUDDLE_LIGHTS",
          "EXTERIOR_ALL_LIGHTS" }
      local out = { }
      for _, name in pairs(lights) do
        local item = {
          name = name,
          densityAvailable = true,
          statusAvailable = true,
          rgbColorSpaceAvailable = true
        }
        table.insert(out, item)
      end
      return out
      end)()
    },
    HMI_SETTINGS = {
      distanceUnitAvailable = true,
      temperatureUnitAvailable = true,
      displayModeUnitAvailable = true
    }
  }

  local result = utils.cloneTable(moduleInformation)
  for key, value in pairs(moduleCapabilities[moduleType]) do
    if type(value) == "table" then
      result[key] = utils.cloneTable(value)
    else
      result[key] = value
    end
  end

  return result
end

--[[ @createTextField: the function creates a value for UI.GetCapabilities.displayCapabilities.textFields ]]
function module.createTextField(name, characterSet, width, rows)
  return {
    name = name,
    characterSet = characterSet or "UTF_8",
    width = width or 500,
    rows = rows or 1
  }
end

--[[ @createImageField: the function creates a value for UI.GetCapabilities.displayCapabilities.imageFields ]]
function module.createImageField(name, width, height)
  return {
    name = name,
    imageTypeSupported = {
      "GRAPHIC_BMP",
      "GRAPHIC_JPEG",
      "GRAPHIC_PNG"
    },
    imageResolution = {
      resolutionWidth = width or 64,
      resolutionHeight = height or 64
    }
  }
end

--[[ @getDefaultHMITable: the function returns the default value for HMI Table containing all default values
-- used in dummy_connecttest->initHMI_onReady() ]]
function module.getDefaultHMITable()
  local default_language = "EN-US"
  local default_languages = {
    "EN-US","ES-MX","FR-CA","DE-DE","ES-ES","EN-GB","RU-RU",
    "TR-TR","PL-PL","FR-FR","IT-IT","SV-SE","PT-PT","NL-NL",
    "ZH-TW","JA-JP","AR-SA","KO-KR","PT-BR","CS-CZ","DA-DK",
    "NO-NO","NL-BE","EL-GR","HU-HU","FI-FI","SK-SK"
  }
  local hmi_table = {
    BasicCommunication = { },
    UI = { },
    VR = { },
    TTS = { },
    VehicleInfo = { },
    Buttons = { },
    Navigation = { }
  }
  -- "params" subtables contain values to be passed for creating expectations in
  -- initHMI_onReady() function of "connecttest"/"dummy_connecttest" file.

  -- "mandatory" and "pinned" fields defined here to control execution flow
  -- in initHMI_onReady() function

  -- "mandatory" field with a "true" value means that this expectation must happen one time
  -- "true" value is default for "mandatory" field

  -- "pinned" field with a "false" value means that this expectation will be pinned, so that
  -- it will be expected even after initHMI_onReady() finishes it's execution
  -- "false" value is default for "pinned" field

  hmi_table.BasicCommunication.MixingAudioSupported = {
    params = {
      attenuatedSupported = true
    },
    mandatory = true,
    pinned = false
  }

  hmi_table.BasicCommunication.GetSystemInfo = {
    params = {
      ccpu_version = "ccpu_version",
      language = "EN-US",
      wersCountryCode = "wersCountryCode",
      systemHardwareVersion = "systemHardwareVersion"
    },
    mandatory = false,
    pinned = false
  }

  hmi_table.UI.GetLanguage = {
    params = {
      language = default_language
    },
    mandatory = true,
    pinned = false
  }

  hmi_table.VR.GetLanguage = {
    params = {
      language = default_language
    },
    mandatory = true,
    pinned = false
  }

  hmi_table.TTS.GetLanguage = {
    params = {
      language = default_language
    },
    mandatory = true,
    pinned = false
  }

  hmi_table.BasicCommunication.UpdateDeviceList = {
    params = { },
    mandatory = false,
    pinned = true
  }

  hmi_table.UI.ChangeRegistration = {
    params = { },
    mandatory = false,
    pinned = true
  }

  hmi_table.VR.ChangeRegistration = {
    params = { },
    mandatory = false,
    pinned = true
  }

  hmi_table.TTS.ChangeRegistration = {
    params = { },
    mandatory = false,
    pinned = true
  }

  hmi_table.TTS.SetGlobalProperties = {
    params = { },
    mandatory = false,
    pinned = true
  }

  hmi_table.UI.SetGlobalProperties = {
    params = { },
    mandatory = false,
    pinned = true
  }

  hmi_table.UI.GetSupportedLanguages = {
    params = {
      languages = default_languages
    },
    mandatory = true,
    pinned = false
  }

  hmi_table.VR.GetSupportedLanguages = {
    params = {
      languages = default_languages
    },
    mandatory = true,
    pinned = false
  }

  hmi_table.TTS.GetSupportedLanguages = {
    params = {
      languages = default_languages
    },
    mandatory = true,
    pinned = false
  }

  hmi_table.VehicleInfo.GetVehicleType = {
    params = {
      vehicleType = {
        make = "Ford",
        model = "Fiesta",
        modelYear = "2013",
        trim = "SE"
      }
    },
    mandatory = true,
    pinned = false
  }

  hmi_table.VehicleInfo.GetVehicleData = {
    params = {
      vin = "52-452-52-752"
    },
    mandatory = true,
    pinned = false
  }

  hmi_table.UI.GetCapabilities = {
    params = {
      displayCapabilities = {
        displayType = "GEN2_8_DMA",
        displayName = "GENERIC_DISPLAY",
        textFields = (function()
          local fields = {
            "mainField1", "mainField2", "mainField3", "mainField4", "statusBar", "mediaClock", "mediaTrack",
            "alertText1", "alertText2", "alertText3", "scrollableMessageBody", "initialInteractionText",
            "navigationText1", "navigationText2", "ETA", "totalDistance", "navigationText", "audioPassThruDisplayText1",
            "audioPassThruDisplayText2", "sliderHeader", "sliderFooter", "notificationText", "menuName",
            "secondaryText", "tertiaryText", "timeToDestination", "menuTitle", "locationName",
            "locationDescription", "addressLines", "phoneNumber", "subtleAlertText1", "subtleAlertText2",
            "subtleAlertSoftButtonText"
          }
          local out = { }
          for _, field in pairs(fields) do
            table.insert(out, module.createTextField(field))
          end
          return out
        end)(),
        imageFields = (function()
          local fields = {
            "softButtonImage", "choiceImage", "choiceSecondaryImage", "vrHelpItem", "turnIcon", "menuIcon", "cmdIcon",
            "showConstantTBTIcon", "locationImage", "subtleAlertIcon"
          }
          local out = { }
          for _, field in pairs(fields) do
            table.insert(out, module.createImageField(field))
          end
          return out
        end)(),
        mediaClockFormats = { "CLOCK1", "CLOCK2", "CLOCK3", "CLOCKTEXT1", "CLOCKTEXT2", "CLOCKTEXT3", "CLOCKTEXT4" },
        graphicSupported = true,
        imageCapabilities = { "DYNAMIC", "STATIC" },
        templatesAvailable = { "TEMPLATE" },
        screenParams = {
          resolution = { resolutionWidth = 800, resolutionHeight = 480 },
          touchEventAvailable = {
            pressAvailable = true,
            multiTouchAvailable = true,
            doublePressAvailable = false
          }
        },
        numCustomPresetsAvailable = 10
      },
      audioPassThruCapabilities = {
        samplingRate = "44KHZ",
        bitsPerSample = "8_BIT",
        audioType = "PCM"
      },
      audioPassThruCapabilitiesList = {
        {
          samplingRate = "44KHZ",
          bitsPerSample = "8_BIT",
          audioType = "PCM"
        }
      },
      pcmStreamCapabilities = {
        samplingRate = "44KHZ",
        bitsPerSample = "8_BIT",
        audioType = "PCM"
      },
      hmiZoneCapabilities = "FRONT",
      softButtonCapabilities = {
        {
          shortPressAvailable = true,
          longPressAvailable = true,
          upDownAvailable = true,
          imageSupported = true
        }
      },
      hmiCapabilities = { navigation = true, phoneCall = true },
      systemCapabilities = {
        navigationCapability = {
          sendLocationEnabled = true,
          getWayPointsEnabled = true
        },
        phoneCapability = {
          dialNumberEnabled = true
        },
        videoStreamingCapability = {
          preferredResolution = {
            resolutionWidth = 800,
            resolutionHeight = 350
          },
          maxBitrate = 10000,
          supportedFormats = {
            {
              protocol = "RAW",
              codec = "H264"
            }
          },
          hapticSpatialDataSupported = false,
          diagonalScreenSize = 10,
          pixelPerInch = 150,
          scale = 2.5
        },
        driverDistractionCapability = {
            subMenuDepth = 3,
            menuLength = 10
        }
      }
    },
    mandatory = true,
    pinned = false
  }

  hmi_table.VR.GetCapabilities = {
    params = {
      vrCapabilities = { "TEXT" }
    },
    mandatory = true,
    pinned = false
  }

  hmi_table.TTS.GetCapabilities = {
    params = {
      speechCapabilities = { "TEXT", "PRE_RECORDED" },
      prerecordedSpeechCapabilities = {
        "HELP_JINGLE", "INITIAL_JINGLE", "LISTEN_JINGLE", "POSITIVE_JINGLE","NEGATIVE_JINGLE"
      }
    },
    mandatory = true,
    pinned = false
  }

  hmi_table.Buttons.GetCapabilities = {
    params = {
      capabilities = {
        module.createButtonCapability("PRESET_0"),
        module.createButtonCapability("PRESET_1"),
        module.createButtonCapability("PRESET_2"),
        module.createButtonCapability("PRESET_3"),
        module.createButtonCapability("PRESET_4"),
        module.createButtonCapability("PRESET_5"),
        module.createButtonCapability("PRESET_6"),
        module.createButtonCapability("PRESET_7"),
        module.createButtonCapability("PRESET_8"),
        module.createButtonCapability("PRESET_9"),
        module.createButtonCapability("OK", true, false, true),
        module.createButtonCapability("PLAY_PAUSE", true, false, true),
        module.createButtonCapability("SEEKLEFT"),
        module.createButtonCapability("SEEKRIGHT"),
        module.createButtonCapability("TUNEUP"),
        module.createButtonCapability("TUNEDOWN"),
        module.createButtonCapability("NAV_CENTER_LOCATION"),
        module.createButtonCapability("NAV_ZOOM_IN"),
        module.createButtonCapability("NAV_ZOOM_OUT"),
        module.createButtonCapability("NAV_PAN_UP"),
        module.createButtonCapability("NAV_PAN_UP_RIGHT"),
        module.createButtonCapability("NAV_PAN_RIGHT"),
        module.createButtonCapability("NAV_PAN_DOWN_RIGHT"),
        module.createButtonCapability("NAV_PAN_DOWN"),
        module.createButtonCapability("NAV_PAN_DOWN_LEFT"),
        module.createButtonCapability("NAV_PAN_LEFT"),
        module.createButtonCapability("NAV_PAN_UP_LEFT"),
        module.createButtonCapability("NAV_TILT_TOGGLE"),
        module.createButtonCapability("NAV_ROTATE_CLOCKWISE"),
        module.createButtonCapability("NAV_ROTATE_COUNTERCLOCKWISE"),
        module.createButtonCapability("NAV_HEADING_TOGGLE")

      },
      presetBankCapabilities = { onScreenPresetsAvailable = true },
    },
    mandatory = true,
    pinned = false
  }

  if SDL.buildOptions.remoteControl == "ON" then
    local modules = {
      CLIMATE = {
        {
          moduleName = "Climate Driver Seat",
          moduleInfo = {
            moduleId = "2df6518c-ca8a-4e7c-840a-0eba5c028351",
            location = { col = 0, row = 0, level = 0, colspan = 1, rowspan = 1, levelspan = 1 },
            serviceArea = { col = 0, row = 0, level = 0, colspan = 1, rowspan = 1, levelspan = 1 },
            allowMultipleAccess = true
          }
        },
        {
          moduleName = "Climate Front Passenger Seat",
          moduleInfo = {
            moduleId = "4c133291-3cc2-4174-b722-6284953af345",
            location = { col = 2, row = 0, level = 0, colspan = 1, rowspan = 1, levelspan = 1 },
            serviceArea = { col = 2, row = 0, level = 0, colspan = 1, rowspan = 1, levelspan = 1 },
            allowMultipleAccess = true
          }
        },
        {
          moduleName = "Climate Second Row Seats",
          moduleInfo = {
            moduleId = "b468c01c-9346-4331-bd4f-927ca97f0103",
            location = { col = 0, row = 1, level = 0, colspan = 1, rowspan = 1, levelspan = 1 },
            serviceArea = { col = 0, row = 1, level = 0, colspan = 3, rowspan = 1, levelspan = 1 },
            allowMultipleAccess = true
          }
        }
      },
      RADIO = {
        {
          moduleName = "Radio Driver Seat",
          moduleInfo = {
            moduleId = "00bd6d93-e093-4bf0-9784-281febe41bed",
            location = { col = 0, row = 0, level = 0, colspan = 1, rowspan = 1, levelspan = 1 },
            serviceArea = { col = 0, row = 0, level = 0, colspan = 3, rowspan = 2, levelspan = 1 },
            allowMultipleAccess = true
          }
        }
      },
      SEAT = {
        {
          moduleName = "Seat of Driver",
          moduleInfo = {
            moduleId = "a42bf1e0-e02e-4462-912a-7d4230815f73",
            location = { col = 0, row = 0, level = 0, colspan = 1, rowspan = 1, levelspan = 1
            },
            serviceArea = { col = 0, row = 0, level = 0, colspan = 1, rowspan = 1, levelspan = 1
            },
            allowMultipleAccess = true
          }
        },
        {
          moduleName = "Seat of Front Passenger",
          moduleInfo = {
            moduleId = "650765bb-2f89-4d68-a665-6267c80e6c62",
            location = { col = 2, row = 0, level = 0, colspan = 1, rowspan = 1, levelspan = 1
            },
            serviceArea = { col = 2, row = 0, level = 0, colspan = 1, rowspan = 1, levelspan = 1
            },
            allowMultipleAccess = true
          }
        },
        {
          moduleName = "Seat of 2nd Row Left Passenger",
          moduleInfo = {
            moduleId = "664975ce-689f-4448-bc9d-802615166947",
            location = { col = 0, row = 1, level = 0, colspan = 1, rowspan = 1, levelspan = 1
            },
            serviceArea = { col = 0, row = 1, level = 0, colspan = 1, rowspan = 1, levelspan = 1
            },
            allowMultipleAccess = true
          }
        },
        {
          moduleName = "Seat of 2nd Row Middle Passenger",
          moduleInfo = {
            moduleId = "89a08b45-f76a-4a37-9979-6acb50cefcf8",
            location = { col = 1, row = 1, level = 0, colspan = 1, rowspan = 1, levelspan = 1
            },
            serviceArea = { col = 1, row = 1, level = 0, colspan = 1, rowspan = 1, levelspan = 1
            },
            allowMultipleAccess = true
          }
        },
        {
          moduleName = "Seat of 2nd Row Right Passenger",
          moduleInfo = {
            moduleId = "7b12e79b-26f1-46d4-a1b8-18886ebd7266",
            location = { col = 2, row = 1, level = 0, colspan = 1, rowspan = 1, levelspan = 1
            },
            serviceArea = { col = 2, row = 1, level = 0, colspan = 1, rowspan = 1, levelspan = 1
            },
            allowMultipleAccess = true
          }
        }
      },
      AUDIO = {
        {
          moduleName = "Audio Driver Seat",
          moduleInfo = {
            moduleId = "0876b4be-f1ce-4f5c-86e9-5ca821683a1b",
            location = { col = 0, row = 0, level = 0, colspan = 1, rowspan = 1, levelspan = 1
            },
            serviceArea = { col = 0, row = 0, level = 0, colspan = 1, rowspan = 1, levelspan = 1
            },
            allowMultipleAccess = true
          },
        },
        {
          moduleName = "Audio Front Passenger Seat",
          moduleInfo = {
            moduleId = "d77a4bd2-5bd2-4c5a-991a-7ec5f14911ca",
            location = { col = 2, row = 0, level = 0, colspan = 1, rowspan = 1, levelspan = 1
            },
            serviceArea = { col = 2, row = 0, level = 0, colspan = 1, rowspan = 1, levelspan = 1
            },
            allowMultipleAccess = true
          },
        },
        {
          moduleName = "Audio 2nd Row Left Seat",
          moduleInfo = {
            moduleId = "c64f6c90-6fcb-4543-ae65-c401b3ca08b2",
            location = { col = 0, row = 1, level = 0, colspan = 1, rowspan = 1, levelspan = 1
            },
            serviceArea = { col = 0, row = 1, level = 0, colspan = 1, rowspan = 1, levelspan = 1
            },
            allowMultipleAccess = true
          },
        },
        {
          moduleName = "Audio 2nd Row Middle Seat",
          moduleInfo = {
            moduleId = "bd0452a1-34a2-4432-af60-6e0e9c3902e2",
            location = { col = 1, row = 1, level = 0, colspan = 1, rowspan = 1, levelspan = 1
            },
            serviceArea = { col = 1, row = 1, level = 0, colspan = 1, rowspan = 1, levelspan = 1
            },
            allowMultipleAccess = true
          },
        },
        {
          moduleName = "Audio 2nd Row Right Seat",
          moduleInfo = {
            moduleId = "3b41cd63-d6b0-4e5e-b831-70e937326074",
            location = { col = 2, row = 1, level = 0, colspan = 1, rowspan = 1, levelspan = 1
            },
            serviceArea = { col = 2, row = 1, level = 0, colspan = 1, rowspan = 1, levelspan = 1
            },
            allowMultipleAccess = true
          },
        },
        {
          moduleName = "Audio Upper Level Vehicle Interior",
          moduleInfo = {
            moduleId = "726827ed-d6be-47d7-a8cc-4723f333b009",        -- a position (NOT a SEAT) on the upper level
            location = { col = 0, row = 0, level = 1, colspan = 1, rowspan = 1, levelspan = 1
            },
            serviceArea = { col = 0, row = 0, level = 1, colspan = 3, rowspan = 2, levelspan = 1
            },
            allowMultipleAccess = true
          },
        }
      },
      LIGHT = {
        {
          moduleName = "Light Driver Seat",
          moduleInfo = {
            moduleId = "f31ef579-743d-41be-a75e-80630d16f4e6",
            location = { col = 0, row = 0, level = 0, colspan = 1, rowspan = 1, levelspan = 1
            },
            serviceArea = { col = 0, row = 0, level = 0, colspan = 3, rowspan = 2, levelspan = 1
            },
            allowMultipleAccess = true
          }
        }
      },
      HMI_SETTINGS = {
        {
          moduleName = "HmiSettings Driver Seat",
          moduleInfo = {
            moduleId = "fd68f1ef-95ce-4468-a304-4c864a0e34a1",
            location = { col = 0, row = 0, level = 0, colspan = 1, rowspan = 1, levelspan = 1 },
            serviceArea = { col = 0, row = 0, level = 0, colspan = 3, rowspan = 2, levelspan = 1 },
            allowMultipleAccess = true
          }
        }
      }
    }

    local function buildCapabilitiesForModuleType(moduleType)
      local capabilities = {}
      for _, moduleInformation in pairs(modules[moduleType]) do
        table.insert(capabilities, module.createRCModuleCapability(moduleType, moduleInformation))
      end
      if moduleType == "LIGHT" or moduleType == "HMI_SETTINGS" then
        return capabilities[1]
      end
      return capabilities
    end

    hmi_table.RC = { }
    hmi_table.RC.GetCapabilities = {
      params = {
        remoteControlCapability = {
          climateControlCapabilities = buildCapabilitiesForModuleType("CLIMATE"),
          radioControlCapabilities = buildCapabilitiesForModuleType("RADIO"),
          audioControlCapabilities = buildCapabilitiesForModuleType("AUDIO"),
          seatControlCapabilities = buildCapabilitiesForModuleType("SEAT"),
          hmiSettingsControlCapabilities = buildCapabilitiesForModuleType("HMI_SETTINGS"),
          lightControlCapabilities = buildCapabilitiesForModuleType("LIGHT"),
          buttonCapabilities = (function()
            local buttons = {
              CLIMATE = {
                buttons = {
                  "AC_MAX", "AC", "RECIRCULATE", "FAN_UP", "FAN_DOWN", "TEMP_UP", "TEMP_DOWN", "DEFROST_MAX", "DEFROST",
                  "DEFROST_REAR", "UPPER_VENT", "LOWER_VENT"
                },
                moduleIds = {
                  "2df6518c-ca8a-4e7c-840a-0eba5c028351",
                  "4c133291-3cc2-4174-b722-6284953af345",
                  "b468c01c-9346-4331-bd4f-927ca97f0103"
                }
              },
              RADIO = {
                buttons = {
                  "VOLUME_UP", "VOLUME_DOWN", "EJECT", "SOURCE", "SHUFFLE", "REPEAT"
                },
                moduleIds = {
                  "00bd6d93-e093-4bf0-9784-281febe41bed"
                }
              }
            }
            local out = { }
            for _, moduleStruct in pairs(buttons) do
              for _, button in pairs(moduleStruct.buttons) do
                for _, moduleId in pairs(moduleStruct.moduleIds) do
                  local moduleInfo = { moduleId = moduleId }
                  table.insert(out, module.createButtonCapability(button, true, true, true, moduleInfo))
                end
              end
            end
            return out
          end)()
        },
        seatLocationCapability = {
          rows = 2,
          columns = 3,
          levels = 2,
          seats = {
            { grid = { col = 0, row = 0, level = 0, colspan = 1, rowspan = 1, levelspan = 1 }},
            { grid = { col = 2, row = 0, level = 0, colspan = 1, rowspan = 1, levelspan = 1 }},
            { grid = { col = 0, row = 1, level = 0, colspan = 1, rowspan = 1, levelspan = 1 }},
            { grid = { col = 1, row = 1, level = 0, colspan = 1, rowspan = 1, levelspan = 1 }},
            { grid = { col = 2, row = 1, level = 0, colspan = 1, rowspan = 1, levelspan = 1 }}
          }
        }
      },
      mandatory = true,
      pinned = false
    }
    hmi_table.RC.IsReady = {
      params = {
        available = true
      },
      mandatory = true,
      pinned = false
    }
  end

  hmi_table.UI.IsReady = {
    params = {
      available = true
    },
    mandatory = true,
    pinned = false
  }

  hmi_table.VR.IsReady = {
    params = {
      available = true
    },
    mandatory = true,
    pinned = false
  }

  hmi_table.TTS.IsReady = {
    params = {
      available = true
    },
    mandatory = true,
    pinned = false
  }

  hmi_table.VehicleInfo.IsReady = {
    params = {
      available = true
    },
    mandatory = true,
    pinned = false
  }

  hmi_table.Navigation.IsReady = {
    params = {
      available = true
    },
    mandatory = true,
    pinned = false
  }

  hmi_table.BasicCommunication.UpdateAppList = {
    params = { },
    mandatory = false,
    pinned = true
  }

  return hmi_table
end

return module
