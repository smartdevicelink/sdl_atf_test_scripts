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

## Start in Auto mode
### Preconditions:
For test script automation workstation should be able to build SDL and ATF, also python fabric should be installed.
To install all dependencies please execute setup_env.sh. Note that it will ask sudo password to install missed software

```
./setup_env.sh
```

### Run all scripts from test_scripts automatically

```
$ fab -H localhost prepare tests_run
```

This goals will build all required stuff (SDL, ATF) and execute all scripts.
Note that this command will execute test scripts not from you local test_scripts directory but from github.

All parameters like an SDL commit, ATF commit, test scripts commit, work, build, source directories may be changed.
For this purpose you can use you own config

```
fab -H localhost prepare:custom_config=develop_config.py
```


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
* Place actual HMI_API.xml, MOBILE_API.xml from `<sdl_core>/src/components/interfaces/` to `<sdl_atf>/data/` :

```
cp <sdl_core>/src/components/interfaces/HMI_API.xml <sdl_atf>/data/
cp <sdl_core>/src/components/interfaces/MOBILE_API.xml <sdl_atf>/data/
```
* Run ATF.

 _Mandatory options:_
  * Pass path to sdl binary dir with --sdl_core command line parameter
  * Pass path to test script as first command line parameter
```
cd <sdl_atf>/
./start.sh --sdl_core=<sdl_core>/build/bin  ./test_scripts/ATF_Speak.lua
```

__Note, that path to SDL binary dir may be different__

You can get additional help of usage ATF:
```
./start.sh --help
```

#### Known Issues
- Some test cases are failed due to known SDL issues. List of failed test cases available in KnownIssues.md
- For testing different application types (NAVI, MEDIA, etc...) you need to modify your ```<sdl_atf>/modules/config.lua``` after *prepare* step 

