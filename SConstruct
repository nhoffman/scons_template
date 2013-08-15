"""

"""

import os
import glob
import sqlite3
import sys

from itertools import chain
from os import path
from os.path import join

# note that we're using scons installed to the virtualenv
from SCons.Script import ARGUMENTS, Variables, Decider, File, Dir

# Configure a virtualenv and environment
virtualenv = ARGUMENTS.get('virtualenv', path.basename(os.getcwd()) + '-env')

if not path.exists(virtualenv):
    sys.exit('--> run \bbin/setup.sh')
elif not ('VIRTUAL_ENV' in os.environ and os.environ['VIRTUAL_ENV'].endswith(virtualenv)):
    sys.exit('--> run \nsource {}/bin/activate'.format(virtualenv))

# requirements installed in the virtualenv
from bioscons.fileutils import Targets, rename

# check timestamps before calculating md5 checksums
# see http://www.scons.org/doc/production/HTML/scons-user.html#AEN929
Decider('MD5-timestamp')

# declare variables for the environment
nproc = ARGUMENTS.get('nproc', 8)
vars = Variables()

vars.Add(PathVariable('out', 'Path to output directory',
                      'output', PathVariable.PathIsDirCreate))
vars.Add('nproc', default=nproc)

# explicitly define execution PATH, giving preference to local executables
PATH = ':'.join([
    'bin',
    path.join(virtualenv, 'bin'),
    '/usr/local/bin', '/usr/bin', '/bin'])

env = Environment(
    ENV = dict(os.environ, PATH=PATH),
    variables = vars
)

targets = Targets()
# start analysis




# end analysis
targets.update(locals().values())

# identify extraneous files
targets.show_extras(env['out'])
