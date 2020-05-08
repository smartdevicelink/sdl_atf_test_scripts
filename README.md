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
* [Setup ATF](https://github.com/smartdevicelink/sdl_atf)
 * Later the ATF sources destination directory is referenced as `<sdl_atf>`
* Clone [sdl_atf_test_scripts](https://github.com/smartdevicelink/sdl_atf)
 * Later the atf test scripts destination directory is referenced as `<sdl_atf_test_scripts>`

``` git clone https://github.com/smartdevicelink/sdl_atf_test_scripts <sdl_atf_test_scripts>```
* Copy all files from `<sdl_atf_test_scripts>` to `<sdl_atf>` :

``` cp -r <sdl_atf_test_scripts>/* <sdl_atf>/ ```
* Include the path to your local HMI_API.xml, MOBILE_API.xml (ex. `<sdl_core>/src/components/interfaces/`) and the path to your local SDL Core binary (ex. `<sdl_build>/bin/`) in your `<sdl_atf>/modules/config.lua` :

```
--- Define path to SDL binary
-- Example: "/home/user/sdl_build/bin"
config.pathToSDL = "/home/user/sdl_build/bin"
--- Define path to SDL interfaces
-- Example: "/home/user/sdl_panasonic/src/components/interfaces"
config.pathToSDLInterfaces = "/home/user/sdl_core/src/components/interfaces"
```
* Run ATF.

 _Mandatory options:_
  * Pass path to test script as first command line parameter
```
cd <sdl_atf>/
./start.sh ./test_scripts/Smoke/API/021_Speak_PositiveCase_SUCCESS.lua
```

You can get additional help of usage ATF:
```
./start.sh --help
```

#### Known Issues
- Some test cases are failed due to known SDL issues. List of failed test cases available in KnownIssues.md
- For testing different application types (NAVI, MEDIA, etc...) you need to modify your ```<sdl_atf>/modules/config.lua``` after *prepare* step 

