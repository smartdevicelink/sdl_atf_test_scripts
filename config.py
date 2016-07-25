#!/usr/bin/env python
# Copyright (c) 2016 Ford Motor Company,
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
# * Neither the name of Ford Motor Company nor the names of its
#   contributors may be used to endorse or promote products derived from
#   this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

work_dir = "~/SmartDeviceLinkCore/"

sdl_repository = "https://github.com/smartdevicelink/sdl_core/"
sdl_branch = "develop"

atf_repository = "https://github.com/smartdevicelink/sdl_atf/"
atf_branch = "BUILD_SERVER_VERSION"

scripts_repository = "https://github.com/CustomSDL/sdl_atf_test_scripts/"
scripts_branch = "GENIVI"

sdl_clone_dir = work_dir + "sdl_core/"
sdl_build_dir = sdl_clone_dir + "build/"

qt_path = "/opt/qt53/"
atf_build_dir = work_dir + "atf_build/"

scripts_clone_dir = work_dir + "sdl_atf_test_scripts/"

# test_scripts_dir is dir where atomatic tool will search test scripts for running
test_scripts_dir = scripts_clone_dir + "test_scripts/"

test_run_dir = work_dir + "test_run/"
reports_dir = test_run_dir + "reports/"


def set_custom_config(config_file_name):
    """
    Load variable from custom config file
    :param config_file_name: path to custom config file
    """
    try:
        exec(open(config_file_name).read(), globals())
        print("Use custom config : {}".format(config_file_name))
    except IOError:
        print("Unable to read local config: {}".format(config_file_name))
