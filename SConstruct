"""
Ion vs Miseq study
"""

import os
import glob
import sqlite3
import sys

from itertools import chain
from os import path
from os.path import join

import ivmpkg.subcommands as ivsc
from ivmpkg.subcommands import module_path

# Configure a virtualenv and environment
virtualenv = 'ivm-env'
if not ('VIRTUAL_ENV' in os.environ and os.environ['VIRTUAL_ENV'].endswith(virtualenv)):
    sys.exit('--> first run \nsource {}/bin/activate'.format(virtualenv))

# note that we're using scons installed to the virtualenv
from SCons.Script import ARGUMENTS, Variables, Decider, File, Dir

# requirements installed in the virtualenv
from bioscons.fileutils import Targets, rename

# check timestamps before calculating md5 checksums
# see http://www.scons.org/doc/production/HTML/scons-user.html#AEN929
Decider('MD5-timestamp')

outdir = ARGUMENTS.get('out', 'output')


def errors(parent_env, dname, rle, rle_csv, ref_rle, ref_rle_csv):
    """Align with refs and calculate errors.
    """

    env = parent_env.Clone()
    env['out'] = Dir(path.join(parent_env['out'], dname))
    env['dname'] = dname

    ssearch, = env.Command(
        target='$out/ssearch.bz2',
        source=[rle, ref_rle],
        action=('seqmagick convert --head $stats_limit '
                '${SOURCES[0]} - | '
                'ssearch36 -m 10 -3 -n -a -d 1 -b 1 -g 3 -f 8 '
                '/dev/stdin ${SOURCES[1]} 2> /dev/null | bzip2 > $TARGET')
    )

    errors, hpe = env.Command(
        target = ['$out/errors.csv.bz2',
                  '$out/homopolymer_errors.csv'],
        source = [ssearch, rle_csv, ref_rle_csv],
        action = ('bioy ssearch2csv ${SOURCES[0]} -r ${SOURCES[1:]} '
                  '--fieldnames q_name,t_name,q_seq,t_seq,sw_zscore | '
                  'bioy errors --out ${TARGETS[0]} '
                  '--homopolymer-matrix ${TARGETS[1]} --homopolymer-max 8 '
                  '--extra-fields "data:${dname}"')
    )

    return dict(dname=dname, ssearch=ssearch, errors=errors, homopolymer_errors=hpe)


def lengthdists(parent_env, dname, seqs, refs):
    """Align untrimmed reads with refs to determine organism-specific
    length distributions. Restrict to reads > 100 bp and trim to 400.
    """

    env = parent_env.Clone()
    env['out'] = Dir(path.join(parent_env['out'], dname))
    env['dname'] = dname

    # prepare input sequences
    ssearch, = env.Command(
        target='$out/untrimmed_ssearch.bz2',
        source=[seqs, refs],
        action=('seqmagick convert '
                '--min-length 100 --cut 1:400 --head $stats_limit '
                '${SOURCES[0]} - | '
                'ssearch36 -m 10 -3 -n -a -d 1 -b 1 '
                '/dev/stdin ${SOURCES[1]} 2> /dev/null | bzip2 > $TARGET')
    )

    lengths, = env.Command(
        target = '$out/lengths.csv.bz2',
        source = ssearch,
        action = ('bioy ssearch2csv $SOURCE -o $TARGET '
                  '--fieldnames q_name,t_name,q_sq_len,t_sq_len,sw_ident,sw_zscore '
                  '--extra-fields data:${dname} ')
    )

    return dict(dname=dname, ssearch=ssearch, lengths=lengths)


mm_data = '/home/molmicro/data'
analysis = '/home/molmicro/analysis'
ion_analysis = path.join(analysis, '041_ion_mcb')
ion_db = path.join(ion_analysis, 'output', 'classification.db')

miseq_analysis = path.join(analysis, 'miseq_validation')
miseq_mcb_specimen = '1_18'
miseq_db = path.join(miseq_analysis, 'output', 'classification.db')
miseq_mcb_output = path.join(miseq_analysis, 'output', miseq_mcb_specimen)

ion_analysis = path.join(analysis, '041_ion_mcb', 'output')
ion_mcb_f = 'F1_3'
ion_mcb_r = 'R1_36'
ion_mcb_c = 'R1_36xF1_3'
ion_db = path.join(ion_analysis, 'classification.db')
ion_mcb_f = path.join(ion_analysis, ion_mcb_f)
ion_mcb_r = path.join(ion_analysis, ion_mcb_r)
ion_mcb_c = path.join(ion_analysis, ion_mcb_c)

# common hm78 refset
# on 2013-07-35:
# cp /home/molmicro/common/hm78/output/dedup.fasta data/hm78_fwd.fasta
# cp /home/molmicro/common/hm78/output/seq_info.csv data/hm78.seq_info.csv
# cp /home/molmicro/common/hm78/output/tax.csv data/hm78.taxonomy.csv
data_dir = Dir('data')
hm78_fwd = File('hm78_fwd.fasta', data_dir)
hm78_info = File('hm78.seq_info.csv', data_dir)
hm78_taxonomy = File('hm78.taxonomy.csv', data_dir)

# declare variables for the environment
nproc = ARGUMENTS.get('nproc', 8)
vars = Variables()
vars.Add('out', default='output')
vars.Add('nproc', default=nproc)
vars.Add('stats_limit', default=10000)

# explicitly define execution PATH, giving preference to local executables
PATH = ':'.join([
    'bin',
    path.join(virtualenv, 'bin'),
    '/usr/local/bin', '/usr/bin', '/bin'])

env = Environment(
    ENV = dict(os.environ, PATH=PATH,
               BLAST_THREADS=nproc),
    variables = vars
)

targets = Targets()

# run-length encode ref seqs for error analysis
hm78_rle_csv, hm78_rle = env.Command(
    target=['$out/hm78_dedup.rle.csv.bz2', '$out/hm78_dedup.rle.fasta'],
    source=hm78_fwd,
    action='bioy rlencode $SOURCE -r ${TARGETS[0]} -o ${TARGETS[1]}'
    )

# also need ref seqs in the same orientation as the reads
hm78_rev, = env.Command(
    target='$out/hm78_dedup_rev.fasta',
    source=hm78_fwd,
    action='seqmagick convert --reverse-complement $SOURCE $TARGET'
    )

# ...as well as the run-length encoded versions
hm78_rev_rle_csv, hm78_rev_rle = env.Command(
    target=['$out/hm78_rev_dedup.rle.csv.bz2',
            '$out/hm78_rev_dedup.rle.fasta'],
    source=hm78_rev,
    action='bioy rlencode $SOURCE -r ${TARGETS[0]} -o ${TARGETS[1]}'
    )

# update seq_info to contain species-level names
hm78_species_info, = env.Command(
    target='$out/hm78.species_info.csv',
    source=[hm78_info, hm78_taxonomy],
    action='ivm seq_info $SOURCES -o $TARGET'
    )

homopolymers_fwd, = env.Command(
    target='$out/homopolymers_fwd.csv',
    source=[hm78_fwd, hm78_species_info],
    action='ivm homopolymers $SOURCES -o $TARGET'
)
Depends(homopolymers_fwd, module_path('homopolymers'))

homopolymer_plots, = env.Command(
    source=homopolymers_fwd,
    target='$out/homopolymers_fwd.pdf',
    action='bin/plot_homopolymers.R $SOURCE $TARGET'
    )

# length distributions for ion reads in each direction and for
# assembled miseq reads
panda_fastq = path.join(miseq_mcb_output, 'panda.fastq')
panda_stats, = env.Command(
    target='$out/panda_stats.csv.bz2',
    source=panda_fastq,
    action=('bioy fastq_stats --limit $stats_limit '
            '-e platform:miseq '
            '-o $TARGET $SOURCE ')
)

# run-length encoded miseq reads for error analysis
e = env.Clone()
e['out'] = Dir(path.join(env['out'], 'miseq'))
miseq_rle, miseq_rle_csv = e.Command(
    target=['$out/rle.fasta.bz2', '$out/rle.csv.bz2'],
    source=panda_fastq,
    action=('seqmagick convert --head $stats_limit $SOURCE - | '
            'bioy rlencode - -o ${TARGETS[0]} -r ${TARGETS[1]} ')
)

# error analysis of primer-trimmed ion data and panda-assembled miseq data.
errordata = [errors(env, 'miseq', miseq_rle, miseq_rle_csv,
                    hm78_rle, hm78_rle_csv),
             errors(env, 'ion_f',
                    path.join(ion_mcb_f, 'primers', 'trimmed_rle.fasta'),
                    path.join(ion_mcb_f, 'primers', 'trimmed_rle.csv.bz2'),
                    hm78_rle, hm78_rle_csv),
             errors(env, 'ion_r',
                    path.join(ion_mcb_r, 'primers', 'trimmed_rle.fasta'),
                    path.join(ion_mcb_r, 'primers', 'trimmed_rle.csv.bz2'),
                    hm78_rev_rle, hm78_rev_rle_csv)]

targets.update(list(chain.from_iterable(d.values() for d in errordata)))

errors_csv, = env.Command(
    target='$out/errors.csv.bz2',
    source=[d['errors'] for d in errordata],
    action='csvstack $SOURCES | bzip2 > $TARGET'
    )

# organism-specific length distributions
lengthdata = [
    lengthdists(env, 'miseq', panda_fastq, hm78_fwd),
    lengthdists(env, 'ion_f',
                path.join(ion_mcb_f, 'left_trimmed.fasta.bz2'), hm78_fwd),
    lengthdists(env, 'ion_r',
                path.join(ion_mcb_r, 'left_trimmed.fasta.bz2'), hm78_rev)
]

targets.update(list(chain.from_iterable(d.values() for d in lengthdata)))

lengths_csv, = env.Command(
    target='$out/lengths.csv.bz2',
    source=[d['lengths'] for d in lengthdata],
    action='csvstack $SOURCES | bzip2 > $TARGET'
    )

errors_and_lengths_db, = env.Command(
    target='$out/errors_and_lengths.db',
    source=[hm78_species_info, errors_csv, lengths_csv],
    action=('rm -f $TARGET && '
            'csvsql --db sqlite:///$TARGET --table refs --insert -y 1000 ${SOURCES[0]} && '
            'csvsql --db sqlite:///$TARGET --table errors --insert -y 1000 ${SOURCES[1]} && '
            'csvsql --db sqlite:///$TARGET --table lengths --insert -y 1000 ${SOURCES[2]} && '
            'bioy -v index $TARGET q_name,t_name,tax_name')
    )

nfigs = 5
fig_base = 'report/figs/errs_and_lengths%02i.%s'
errorfigs = env.Command(
    target = [fig_base % (i, suf) for i in range(1, nfigs + 1) for suf in ['pdf', 'svg']],
    source = errors_and_lengths_db,
    action = 'bin/errors_and_lengths.R $SOURCE %s $TARGETS' % fig_base
)
Depends(errorfigs, 'bin/errors_and_lengths.R')

reportname = 'ion_vs_miseq'
css, = env.Command(
    target='report/css/bootstrap.css',
    source='data/bootstrap.css',
    action='cp $SOURCE $TARGET'
)

html, = env.Command(
    target = 'report/%s.html' % reportname,
    source = '%s.org' % reportname,
    action = ('emacs --script bin/org2html.el '
              '-package-dir .org-export '
              '-css-url css/bootstrap.css '
              '-infile $SOURCE -outfile $TARGET ')
)
Depends(html, ['bin/org2html.el'])

version = '1'
report_archive, = env.Command(
    target = '%s.%s.zip' % (reportname, version),
    source = Dir('report'),
    action = 'rm -f $TARGET && zip -q -r $TARGET $SOURCE'
    )

targets.update(locals().values())

# identify extraneous files
targets.show_extras(outdir)
targets.show_extras('report')
