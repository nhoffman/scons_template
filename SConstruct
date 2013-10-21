"""

"""

import os
import sys
from os import path
from os.path import join

# note that we shouold be using scons installed to the virtualenv
from SCons.Script import ARGUMENTS, Variables, Decider, File, Dir

# check timestamps before calculating md5 checksums
# see http://www.scons.org/doc/production/HTML/scons-user.html#AEN929
Decider('MD5-timestamp')

# declare variables for the environment
vars = Variables(None, ARGUMENTS)

vars.AddVariables(
    ('nproc', 'Number of processors', 8),
    PathVariable('out', 'Path to output directory', 'output', PathVariable.PathIsDirCreate),
    PathVariable('virtualenv', 'Virtualenv',  path.basename(os.getcwd()) + '-env',
                 PathVariable.PathAccept)
    )

# Provides access to options prior to instantiation of env object
# below; it's better to access variables through the env object.
varargs = dict({opt.key: opt.default for opt in vars.options}, **vars.args)

# Configure a virtualenv and environment
virtualenv = varargs['virtualenv']
if not path.exists(virtualenv):
    sys.exit('--> run \nbin/setup.sh')
elif not ('VIRTUAL_ENV' in os.environ and os.environ['VIRTUAL_ENV'].endswith(virtualenv)):
    sys.exit('--> run \nsource {}/bin/activate'.format(virtualenv))

# import requirements installed in the virtualenv after this point
from bioscons.fileutils import Targets, rename

# explicitly define execution PATH, giving preference to local executables
PATH = ':'.join([
    'bin',
    path.join(varargs['virtualenv'], 'bin'),
    '/usr/local/bin', '/usr/bin', '/bin'])

env = Environment(
    ENV = dict(os.environ, PATH=PATH),
    variables = vars
)

Help(vars.GenerateHelpText(env))

targets = Targets()
# start analysis




# end analysis
targets.update(locals().values())

# identify extraneous files
targets.show_extras(env['out'])
