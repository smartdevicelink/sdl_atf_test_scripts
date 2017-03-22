#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Install (copy) git hooks
"""

import os
import glob
import shutil


def uninstall_hooks(hooks_dir):
    print 'Deleting existing pre-commit hooks'
    files = glob.glob(os.path.join(hooks_dir, 'pre-commit*'))
    for item in files:
        os.remove(item)


def install_hooks(src_dir, dst_dir):
    print 'Installing pre-commit hooks'
    src_files = glob.glob(os.path.join(src_dir, 'pre-commit*'))
    for item in src_files:
        shutil.copy(item, dst_dir)

def main():
    ''' Main logic '''
    # change working directory to root of repository
    os.chdir(os.path.join(os.path.dirname(
        os.path.realpath(__file__)), os.pardir))
    print 'Current working dir is {}'.format(os.getcwd())
    hooks_src_dir = os.path.join(
        os.getcwd(), 'tools', 'git-hooks')
    hooks_dst_dir = os.path.join(os.getcwd(), '.git', 'hooks')
    uninstall_hooks(hooks_dst_dir)
    install_hooks(hooks_src_dir, hooks_dst_dir)
    print 'Done'


if __name__ == '__main__':
    main()
