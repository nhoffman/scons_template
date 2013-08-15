#!/bin/bash

# Create virtualenv, install scons from source, and install
# requirements in requirements.txt

set -e

if [[ -z $1 ]]; then
    venv=$(basename $(pwd))-env
else
    venv=$1
fi

if [ ! -f $venv/bin/activate ]; then
    virtualenv $venv
else
    echo "found existing virtualenv $venv"
fi

source $venv/bin/activate

mkdir -p src
if [ ! -f $venv/bin/scons ]; then
    (cd src && \
	wget http://downloads.sourceforge.net/project/scons/scons/2.3.0/scons-2.3.0.tar.gz && \
	tar -xf scons-2.3.0.tar.gz && \
	cd scons-2.3.0 && \
	python setup.py install
    )
else
    echo "scons is already installed in $(which scons)"
fi

pip install -r requirements.txt
