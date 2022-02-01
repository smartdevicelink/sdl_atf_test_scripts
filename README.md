[![Build Status](https://travis-ci.org/smartdevicelink/sdl_atf_test_scripts.svg?branch=master)](https://travis-ci.org/smartdevicelink/sdl_atf_test_scripts)

# Automated Test Framework (ATF) scripts
This repository contains ATF scripts and data to run it.

## Coverage
|Functionality    |Status    |Notes    |
|:---|:---|:---|
|Smoke Test    | 100%   | Common mobile APIs check   |
|Mobile API Protocol    | 95%   |    |
|HMI API    |  5% |    |
|App Resumption    | 10%   |    |
|SDL 4.0    | 100%   |    |
|UTF-8 Check    | 100%   |    |
|Safety feature active    | 100%   |    |
|Audio/Video Streaming    | 20%   | Planned   |
|Policies    | Not Covered   | Planned   |
|Heartbeat    | Not Covered   | Needs new ATF functionality   |
|SecurityService    | Not Covered   | Needs new ATF functionality   |
|Start/End Service    |  Not Covered  | Planned   |
|Transport    | Not Covered   |    |

## Manual usage:

* [Setup SDL](https://github.com/smartdevicelink/sdl_core).
  * Later the SDL sources destination directory is referenced as `<sdl_core>`
* [Setup ATF](https://github.com/smartdevicelink/sdl_atf).
  * Later the ATF sources destination directory is referenced as `<sdl_atf>`
  * Later the ATF build destination directory is referenced as `<atf_build>`
* Clone [sdl_atf_test_scripts](https://github.com/smartdevicelink/sdl_atf)
  * Later the atf test scripts destination directory is referenced as `<sdl_atf_test_scripts>`

  ```bash
  git clone https://github.com/smartdevicelink/sdl_atf_test_scripts <sdl_atf_test_scripts>
  ```

* Create symlinks in the build `bin` directory to certain directories in `<sdl_atf_test_scripts>`:

  ```bash
  cd <atf_build>/bin
  ln -s <sdl_atf_test_scripts>/files
  ln -s <sdl_atf_test_scripts>/test_sets
  ln -s <sdl_atf_test_scripts>/test_scripts
  ln -s <sdl_atf_test_scripts>/user_modules
  ```

* In your `<sdl_atf>/modules/configuration/base_config.lua`
  * Include the path to your local SDL Core binary (ex. `<sdl_build>/bin/`):
  ```lua
  --- Define path to SDL binary
  -- Example: "/home/user/sdl_build/bin"
  config.pathToSDL = "/home/user/sdl_build/bin"
  ```

  * Include the path to your local SDL Core Source directory (ex. `<sdl_build>/bin/`):
  ```lua
  --- Define path to SDL source
  -- Example: "/home/user/sdl_core"
  config.pathToSDLSource = "<sdl_core>"
  ```
  ATF will use this path to derive the path to the MOBILE_API.xml and HMI_API.xml files in the `<sdl_core>` directory.

  * Instead of including the path to your local SDL Core Source directory, you can alternatively include the path to your local HMI_API and MOBILE_API directories:

  ```lua
  --- Define path to SDL MOBILE interface
  -- Example: "/home/user/sdl_core/tools/rpc_spec"
  config.pathToSDLMobileInterface = "/home/user/sdl_core/tools/rpc_spec"
  --- Define path to SDL HMI interface
  -- Example: "/home/user/sdl_core/src/components/interfaces"
  config.pathToSDLHMIInterface = "/home/user/sdl_core/src/components/interfaces"
  ```
  **NOTE:** If both `pathToSDLSource` and `pathToSDLMobileInterface`/`pathToSDLHMIInterface` are defined in the config file, the `pathToSDLMobileInterface`/`pathToSDLHMIInterface` will be used instead of the path derived from `pathToSDLSource`.


* Run ATF.

 _Mandatory options:_
  * Pass path to test script as first command line parameter
  ```
  cd <atf_build>/bin
  ./start.sh ./test_scripts/Smoke/API/021_Speak_PositiveCase_SUCCESS.lua
  ```

You can get additional help of usage ATF:
```
./start.sh --help
```

#### Known Issues
- Some test cases are failed due to known SDL issues. List of failed test cases available in KnownIssues.md
- For testing different application types (NAVI, MEDIA, etc...) you need to modify your ```<sdl_atf>/modules/config.lua``` after *prepare* step 

