#!/usr/bin/env python
########################################################################
##
## Copyright 2015 PMC-Sierra, Inc.
##
## Licensed under the Apache License, Version 2.0 (the "License"); you
## may not use this file except in compliance with the License. You may
## obtain a copy of the License at
## http://www.apache.org/licenses/LICENSE-2.0 Unless required by
## applicable law or agreed to in writing, software distributed under the
## License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
## CONDITIONS OF ANY KIND, either express or implied. See the License for
## the specific language governing permissions and limitations under the
## License.
##
########################################################################

########################################################################
##
##   Description:
##     A post-processor for the filesystem scripting stuff.
##
########################################################################

from __future__ import print_function
from __future__ import unicode_literals

import re
import subprocess as sp

class ParseException(Exception):
    pass

def filefrag(inp_file):
    """A post-processing file for the filefrag output."""

    fin = open(inp_file,'r')
    fout = open(inp_file+'.out','w')

    rhdr = re.compile(r"^File size of (?P<filename>[\w/]+) is "
                      "(?P<filesize>\d+) \((?P<blocks>\d+) blocks of "
                      "(?P<blocksize>\d+) bytes\)$")

    hdr = None
    for l in fin:
        l = l.strip()
        m = rhdr.match(l)
        if m:
            hdr = m.groupdict()
            continue
        if l.startswith("ext:"):
            break

    if not hdr:
        raise ParseException("Unable to parse filefrag file. No valid header.")

    def output_line(*args):
        fout.write("{} {} {}\n".format(*args))

    for l in fin:
        if l.startswith("/"):
            break
        tmp = \
            [int(s) for s in l.replace(":","").replace("..","").split() if s.isdigit()]
        if len(tmp)==6:
            extent, off_s, off_f, lba_s, lba_f, length = tmp
        else:
            extent, off_s, off_f, lba_s, lba_f, length, exp = tmp

        output_line(off_s*int(hdr["blocksize"]), lba_s, length)


def blktrace(inp_file):
    """A post-processing file for the blktrace output."""

    fin = open(inp_file, "r")
    fout = open(inp_file+".out", "w")
    p = sp.Popen(["blkparse", "-q", "-f", "%T.%9t %a %d %S %n\n", "-i", "-"],
                 stdin=fin, stdout=sp.PIPE)
    lines, _ = p.communicate()

    for l in lines.split("\n"):
        if not l: continue
        timestamp, cmd, rw, sector, count = l.split()

        if cmd != "C": continue

        sector = int(sector)
        count = int(count)
        last = sector + count - 1
        direction = 1 if "R" in rw else 0

        if not count: continue

        fout.write("{} {} {} {}\n".format(timestamp, sector, last, direction))

if __name__=="__main__":
    import sys
    import argparse

    parser = argparse.ArgumentParser(description=
                                     "post process fs_test script output")
    parser.add_argument("-f", "--filefrag", required=True,
                        help="the filefrag file")
    parser.add_argument("-b", "--blktrace", required=True,
                        help="the blktrace file")
    args = parser.parse_args()

    try:
        filefrag(args.filefrag)
        blktrace(args.blktrace)
    except Exception as e:
        print(e)
