#!/bin/bash
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

TEXT_DEFAULT="\\033[0;39m"
TEXT_INFO="\\033[1;32m"
TEXT_ERROR="\\033[1;31m"

EXIT_NORMAL=0
EXIT_WHITESPACES_ERRORS=1
EXIT_LUACHECK_NOT_FOUND=2
EXIT_LUA_SCRIPT_HAS_ISSUES=3

GIT_DIFF_CHECK_LIST="/test_scripts"

# Check for odd whitespace

echo -e $TEXT_INFO "Checking odd whitespaces" $TEXT_DEFAULT
git diff --check --cached --color -- .$GIT_DIFF_CHECK_LIST | cat
if [ "$?" -ne "0" ]; then
  echo -e $TEXT_ERROR "Your changes introduce whitespace errors"
  echo -e " Aborting commit." $TEXT_DEFAULT

  exit $EXIT_WHITESPACES_ERRORS
fi
echo -e $TEXT_INFO "PASSED" $TEXT_DEFAULT

# Get names of changed lua files

LUA_FILES=$(git diff --cached --name-only --diff-filter=ACM -- .$GIT_DIFF_CHECK_LIST | grep -e "\.lua$")

#Auto-update lua style with lua-beautifier

echo -e $TEXT_INFO "Auto-update lua style with lua-beautifier" $TEXT_DEFAULT

if [ -n "$LUA_FILES" ]; then
  for lua_file in $LUA_FILES;
  do
    ./tools/lua-beautifier/beautifier.sh $lua_file
  done
  git add $LUA_FILES
fi

echo -e $TEXT_INFO "PASSED" $TEXT_DEFAULT

# Auto-check lua code with luacheck

echo -e $TEXT_INFO "Checking lua code with luacheck" $TEXT_DEFAULT

LUA_CHECK=$(command -v luacheck)

if [ ! -x "$LUA_CHECK" ]; then
  echo -e $TEXT_ERROR "Error: luacheck executable not found." $TEXT_DEFAULT
  echo -e " Aborting commit." $TEXT_DEFAULT
  exit $EXIT_LUACHECK_NOT_FOUND
fi

if [ -n "$LUA_FILES" ]; then
  luacheck $LUA_FILES
  if [ "$?" -ne "0" ]; then
    echo -e $TEXT_ERROR "Luacheck reports about issues in lua files"
    echo -e " Aborting commit." $TEXT_DEFAULT
    exit $EXIT_LUA_SCRIPT_HAS_ISSUES
  fi
fi

echo -e $TEXT_INFO "PASSED" $TEXT_DEFAULT

exit $EXIT_NORMAL
