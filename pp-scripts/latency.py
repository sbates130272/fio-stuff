#!/usr/bin/env python
########################################################################
##
## Copyright 2015 PMC-Sierra, Inc.
##
## Licensed under the Apache License, Version 2.0 (the "License"); you
## may not use this file except in compliance with the License. You may
## obtain a copy of the License at
## http://www.apache.org#licenses/LICENSE-2.0 Unless required by
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
##     A simple python script that uses gnuplot to generate a SVF plot
##     file based on inputted latency data file(s).
##
########################################################################

import os
import subprocess

def parse(szFile):
    """Read in a latency FIO file which has the four column format time,
    latency (us), direction (0=read), size (B). Fill a 2D array with
    the latency data and return that vector"""

    ret = []

    fFile = open(szFile,'r')
    for line in fFile:
        if line[0]=="#":
            continue
        ret.append(map(int, line.strip().split(','))[1])

    return ret

def hist(pnData, nBins=100, bCdf=False):
    """A simple histogram binning function. We could use something
    from a 3rd party library (like numpy or matplotlib) but we avoid
    that to remove external dependencies. We use nBin equally spaced
    bins between min(pnData) and max(pnData) and return two vectors,
    one with the bin start points and one with the bin volumnes."""

    start = min(pnData)
    end   = max(pnData)
    step  = (end-start)/float(nBins)

    pnBins = [start+(x*step) for x in range(nBins)]
    
    pnHist =nBins*[0]
    for x in pnData:
        for i in xrange(nBins-1):
            if x>pnBins[i] and x<=pnBins[i+1]:
                pnHist[i] = pnHist[i]+1

    if bCdf:
        for i in xrange(1,nBins):
            pnHist[i] = pnHist[i]+pnHist[i-1]
    return pnBins,pnHist

def plot(peX, peY, szFile='latency.png', bCdf=False):
    """Use the GnuPlot program to plot the specified input data. For
    now we assume this is latency plot though we may generalize in
    time. Also, for now we dump the data to a temp file rather than
    placing it on the gnuplot command line."""

    TMP_FILE='plot.data'

    tmpFile = open(TMP_FILE,'w')
    for i in xrange(len(peX)):
        tmpFile.write("%f\t%d\n" % (peX[i],peY[i]))
    tmpFile.close()

    proc = subprocess.Popen(['gnuplot','-p'], 
                            shell=True,
                            stdin=subprocess.PIPE)
    proc.stdin.write('set terminal png medium\n')
    proc.stdin.write('set output \"%s\"\n' % szFile)
    proc.stdin.write('set title \"Latency Distribution\" font \",20\"\n')
    proc.stdin.write('set xlabel \'time (us)\'\n')
    proc.stdin.write('set ylabel \'%s\'\n' % ("CDF" if bCdf else "PDF"))
    proc.stdin.write('set grid\n')
    proc.stdin.write('plot \"%s" with lines\n' % TMP_FILE)
    proc.stdin.write('quit\n')
    proc.wait()
    os.remove(TMP_FILE)

if __name__=="__main__":
    import sys
    import optparse

    parser = optparse.OptionParser()
    parser.add_option("-f", "--ofile", action="store", type=str,
                      default="latency.png", help="name of output file")
    parser.add_option("-b", "--bins", action="store", type=int,
                      default=100, help="number of histogram bins")
    parser.add_option("-c", "--cdf", action="store_true",
                      help="generate CDF rather than PDF")
    options, args = parser.parse_args()
    
    if len(args)>1:
        raise ValueError('latency.py only accepts one input file (for now)')

    data = []
    for i in range(len(args)):
        data.append(parse(args[i]))

    pnBins,pnHist = hist(data[0], options.bins, options.cdf)
    plot(pnBins, pnHist, options.ofile, options.cdf)
