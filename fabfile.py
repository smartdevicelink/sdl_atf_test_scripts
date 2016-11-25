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


from fabric.decorators import task
from fabric.tasks import Task
from fabric.api import run
from fabric.api import cd
from fabric.api import execute
from fabric.contrib.files import exists
from fabric.context_managers import settings
from utils import arch, open_dir, clone
from utils import get_list_of_failed_test_cases
from utils import get_known_issues
from utils import filter_known_issues
import config as config
import os

def resolve_path(relative_path):
    """
    Function that transform relative to absolute path
    :param relative_path: relative path
    :return: absolute path
    """
    return os.path.abspath(os.path.expanduser(relative_path)) + "/"

config.work_dir = resolve_path(config.work_dir)
config.sdl_clone_dir = resolve_path(config.sdl_clone_dir)
config.sdl_build_dir = resolve_path(config.sdl_build_dir)
config.qt_path = resolve_path(config.qt_path)
config.atf_build_dir = resolve_path(config.atf_build_dir)
config.scripts_clone_dir = resolve_path(config.scripts_clone_dir)
config.test_scripts_dir = resolve_path(config.test_scripts_dir)
config.test_run_dir = resolve_path(config.test_run_dir)
config.reports_dir = resolve_path(config.reports_dir)


class TaskWithConfig(Task):
    """
        Task that support custom config
    """
    def __init__(self, func, *args, **kwargs):
        super(TaskWithConfig, self).__init__(*args, **kwargs)
        self.func = func

    def run(self, custom_config=None, *args, **kwargs):
        if custom_config is not None:
            config.set_custom_config(custom_config)
        return self.func(*args, **kwargs)


@task(task_class=TaskWithConfig)
def clone_sdl(rewrite=False):
    """
    Clone SDL to work directory
    :param rewrite: if True delete sdl folder
    """
    clone(config.sdl_repository, config.sdl_clone_dir,
          config.work_dir, branch=config.sdl_branch, rewrite=rewrite)


@task(task_class=TaskWithConfig)
def clone_atf(rewrite=False):
    """
    Clone ATF to work directory
    :param rewrite: if True delete atf folder
    """
    clone(config.atf_repository, config.atf_build_dir, config.work_dir,
          branch=config.atf_branch, submodules=True, rewrite=rewrite)


@task(task_class=TaskWithConfig)
def clone_scripts(rewrite=False):
    """
    Clone ATF scripts to work directory
    :param rewrite: if True delete atf scripts folder
    """
    clone(config.scripts_repository, config.scripts_clone_dir, config.work_dir,
          branch=config.scripts_branch, rewrite=rewrite)


@task(task_class=TaskWithConfig)
def build_sdl(rewrite=False):
    """
    Build SDL
    :param rewrite: if True delete old SDL build and build again
    """
    with open_dir(config.work_dir), open_dir(config.sdl_build_dir, rewrite):
        log_build_dir = config.sdl_build_dir + "log4cxx_build/"
        log_build_arch_dir = log_build_dir + arch()
        run('''export THIRD_PARTY_INSTALL_PREFIX={};
               export THIRD_PARTY_INSTALL_PREFIX_ARCH={};
               cmake {} && make install VERBOSE=1 '''.format(
                                                        log_build_dir,
                                                        log_build_arch_dir,
                                                        config.sdl_clone_dir))


@task(task_class=TaskWithConfig)
def build_atf(rewrite=False):
    """
    Build ATF
    :param rewrite: if True, delete all build atf files and build again
    """
    with open_dir(config.work_dir), cd(config.atf_build_dir):
        if rewrite:
            run("git reset --hard && git clean -dfx")
        qmake_path = config.qt_path + "/bin/qmake"
        qmake_lib = config.qt_path + "/lib/"
        run('''export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:{};
               export QMAKE={}; make'''.format(qmake_lib, qmake_path))


@task(task_class=TaskWithConfig)
def prepare_test_run(rewrite=False):
    """
    Copy all files, required to execute test run to special directory
    :param rewrite: it True delete old tests_run_dir and copy files again
    """
    with open_dir(config.test_run_dir, rewrite):
        run("cp -r {} {}".format(config.atf_build_dir +
                                 "bin/", config.test_run_dir))
        run("cp -r {} {}".format(config.atf_build_dir +
                                 "modules/", config.test_run_dir))
        run("cp -r {} {}".format(config.atf_build_dir +
                                 "data/", config.test_run_dir))
        run("cp -r {} {}".format(config.atf_build_dir +
                                 "tools/", config.test_run_dir))
        run("cp -r {} {}".format(config.atf_build_dir +
                                 "start.sh", config.test_run_dir))
        run("cp -r {} {}".format(config.scripts_clone_dir +
                                 "/*", config.test_run_dir))
        run("cp -r {} {}".format(config.sdl_build_dir + "bin",
                                 config.test_run_dir + "SDL_bin"))
        logger_library_path = config.sdl_build_dir + \
            "log4cxx_build/" + arch() + "/lib/"
        run("cp -r {} {}".format(logger_library_path +
                                 "/*", config.test_run_dir + "SDL_bin/"))


@task(task_class=TaskWithConfig)
def tests_run():
    """
    Run all tests from test_run_dir
    """
    if not exists(config.test_run_dir):
        print("{} does not exists".format(config.test_run_dir))
    with cd(config.test_run_dir):
        output = run('find {} -name "*.lua"'.format(config.test_scripts_dir))
        scripts = output.split()
        known_issues = run("cat KnownIssues.md")
        known_issues = get_known_issues(known_issues)
        new_failed = {}
        print(scripts)
        for script in scripts:
            print("Execute {}".format(script))
            with settings(warn_only=True):
                output = run('''./start.sh --storeFullSDLLogs \
                             --sdl-core=./SDL_bin/ {} |\
                             tee console_output'''.format(script))
                script_reports_dir = "{}/{}".format(config.reports_dir, script)
                run("mkdir -p {}".format(script_reports_dir))
                run("mv console_output {}/".format(script_reports_dir))
                run("mv TestingReports {}/".format(script_reports_dir))
                new_failed[script] = get_list_of_failed_test_cases(output)
                print("List of failed test cases in {} : ".format(script))
                for failed_case in new_failed[script]:
                    print("\t {}".format(failed_case))
                if script in known_issues:
                    new_failed[script] = filter_known_issues(
                                    new_failed[script], known_issues[script])
        print("New failed test cases:")
        for script in new_failed:
            failed_in_script = new_failed[script]
            print("* {}:".format(script))
            for case in failed_in_script:
                print("  * {}".format(case))


@task(task_class=TaskWithConfig)
def prepare():
    """
    Prepare all preconditions for tests_run
    """
    execute(clone_sdl)
    execute(clone_atf)
    execute(clone_scripts)
    execute(build_sdl)
    execute(build_atf)
    execute(prepare_test_run)


@task
def clear():
    """
    Clear working directory
    """
    run("rm -rf  {}".format(config.work_dir))


@task(task_class=TaskWithConfig)
def reset():
    """
    Clear test_run_dir
    """
    run("rm -rf  {}".format(config.test_run_dir))
    execute(prepare_test_run)
