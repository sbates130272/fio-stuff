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

import re

def fibmap(options):
    """A post-processing file for the fibmap output."""

    fibmap = []
    fFile = open(options.fibmap,'r')
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

    fFileOut = open(options.fibmap+'.out','w')
    for this in fibmap2:
        fFileOut.write ("%d %d\n" % (this[0], this[1]))

if __name__=="__main__":
    import sys
    import optparse

    parser = optparse.OptionParser()
    parser.add_option("-f", "--fibmap", action="store", type=str,
                      default=None, help="the fibmap file")
    parser.add_option("-b", "--blktrace", action="store", type=str,
                      default=None, help="the blktrace file")
    options, args = parser.parse_args()

    if (not options.fibmap) or (not options.blktrace):
        raise ValueError('must specify both fibmap and blktrace files')

    fibmap(options)
