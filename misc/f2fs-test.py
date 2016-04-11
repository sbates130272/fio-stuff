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
##     A post-processor for the f2fs scripting stuff.
##
########################################################################

from __future__ import print_function
from __future__ import unicode_literals

import re
import subprocess as sp

def fibmap(inp_file):
    """A post-processing file for the fibmap output."""

    fibmap = []
    fFile = open(inp_file,'r')
    for line in fFile:
        if re.match("^filesystem", line.strip()):
            bs  = map(int, re.findall("[-+]?\d+[\.]?\d*", line))[0]
            lba = map(int, re.findall("[-+]?\d+[\.]?\d*", line))[2]
        if re.match("^[0-9]", line.strip()):
            fibmap.append(map(int, re.findall("[-+]?\d+[\.]?\d*", line)))

    fibmap2 = []
    for this in fibmap:
        fibmap2.append([this[0], this[1]])
        fibmap2.append([this[0]+(this[3]-1)*lba, this[2]])

    fFileOut = open(inp_file+'.out','w')
    for this in fibmap2:
        fFileOut.write("%d %d\n" % (this[0], this[1]))

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
                                     "post process f2fs_test script output")
    parser.add_argument("-f", "--fibmap", required=True,
                        help="the fibmap file")
    parser.add_argument("-b", "--blktrace", required=True,
                        help="the blktrace file")
    args = parser.parse_args()

    fibmap(args.fibmap)
    blktrace(args.blktrace)
