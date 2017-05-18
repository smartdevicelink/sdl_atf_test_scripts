#! /usr/bin/env bash
file_name=$1
./tools/lua-beautifier/beautifier.pl $1 > $1"_b" && mv $1"_b" $1

