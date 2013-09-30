#!/bin/bash

# Create a virtualenv using local resources.

set -e

BIN=~/local/bin
venv=$(basename $(pwd))-env

# create virtualenv if necessary
if [ ! -f $venv/bin/activate ]; then
    $BIN/virtualenv -p $BIN/python --system-site-packages $venv
    $BIN/virtualenv --relocatable $venv
else
    echo "found existing virtualenv $venv"
fi

# make scons available
ln -sf $BIN/scons $venv/bin

source $venv/bin/activate

# install other requirements
$BIN/pip install -r requirements.txt

# correct any more shebang lines
$BIN/virtualenv --relocatable $venv
