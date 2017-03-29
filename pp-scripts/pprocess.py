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
##     A simple python script that uses gnuplot to generate a SVF plot
##     file based on inputted data file(s).
##
########################################################################

import os
import subprocess
import re

suffixmap = {
    'n' : 1e-9   ,
    'u' : 1e-6   ,
    'm' : 1e-3   ,
    ' ' : 1      ,
    'k' : 1e3    ,
    'K' : 1e3    ,
    'M' : 1e6    ,
    'G' : 1e9    ,
    'T' : 1e12
}


def suffix(szVal):
    """Parse an input string looking for scientifc suffixes and if
    they exist then modify the input value accordingly. The supported
    values are given in the suffixmap dict"""

    numeric = '0123456789-.'
    for i,c in enumerate(szVal):
        if c not in numeric:
            break
    number = szVal[:i]
    unit = szVal[i:].lstrip()
    unit = unit.strip("B") or " "

    try:
        return float(number)*suffixmap[unit[0]]
    except:
        raise ValueError('pprocess.py: suffix() could not process '\
                             '%s,%s' % (number, unit))


def parse_lat(szFile):
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

def parse_thr(szFile):
    """Read in a standard FIO console log and pull out the data needed
    for thread analysis."""

    threads = []
    cpu     = []
    readbw  = []
    writebw = []
    fFile = open(szFile,'r')
    for line in fFile:
        if line[0]=="#":
            continue
        if re.match("^cpu", line.strip()):
            cpu.append(map(float, re.findall("[-+]?\d+[\.]?\d*", line)))
        if "jobs=" in line:
            threads.append(map(int, re.findall("[-+]?\d+[\.]?\d*", line))[0])
        if re.match("^READ", line.strip()):
            readbw.append(suffix(((line.split(',')[1]).split('=')[1]).strip()))
        if re.match("^WRITE", line.strip()):
            readbw.append(suffix(((line.split(',')[1]).split('=')[1]).strip()))

    cpu2 = []; i=0
    for thread in threads:
        cpu2.append((cpu[i][0]+cpu[i][1])*thread)
        i=i+1

    return threads, cpu2, readbw, writebw

def parse_iod(szFile):
    """Read in a standard FIO console log and pull out the data needed
    for IO depth analysis."""

    threads = []
    iodepth = []
    cpu     = []
    readbw  = []
    writebw = []
    fFile = open(szFile,'r')
    for line in fFile:
        if line[0]=="#":
            continue
        if re.match("^cpu", line.strip()):
            cpu.append(map(float, re.findall("[-+]?\d+[\.]?\d*", line)))
        if "jobs=" in line:
            threads.append(map(int, re.findall("[-+]?\d+[\.]?\d*", line))[2])
        if "iodepth=" in line:
            iodepth.append(map(float, re.findall("[-+]?\d+[\.]?\d*", line))[0])
        if re.match("^READ", line.strip()):
            readbw.append(suffix(((line.split(',')[0]).split('=')[1]).strip()))
        if re.match("^WRITE", line.strip()):
            readbw.append(suffix(((line.split(',')[0]).split('=')[1]).strip()))

    cpu2 = []; i=0
    for iod in iodepth:
        cpu2.append((cpu[i][0]+cpu[i][1])*threads[0])
        i=i+1

    return iodepth, cpu2, readbw, writebw

def parse_bs(szFile):
    """Read in a standard FIO console log and pull out the data needed
    for block size (bs) analysis."""

    threads = []
    bss     = []
    cpu     = []
    readbw  = []
    writebw = []
    fFile = open(szFile,'r')
    for line in fFile:
        if line[0]=="#":
            continue
        if re.match("^cpu", line.strip()):
            cpu.append(map(float, re.findall("[-+]?\d+[\.]?\d*", line)))
        if "jobs=" in line:
            threads.append(map(int, re.findall("[-+]?\d+[\.]?\d*", line))[2])
        if ", bs=" in line:
            tmp = line.split(',')[1].split('-')[0][4:].strip()
            tmp = tmp.replace("(R)", "").strip()
            try:
                bss.append(float(tmp))
            except:
                bss.append(suffix(tmp))
        if re.match("^READ", line.strip()):
            readbw.append(suffix(((line.split(',')[0]).split('=')[1]).strip()))
        if re.match("^WRITE", line.strip()):
            readbw.append(suffix(((line.split(',')[0]).split('=')[1]).strip()))

    cpu2 = []; i=0
    for iod in bss:
        cpu2.append((cpu[i][0]+cpu[i][1])*threads[0])
        i=i+1

    return bss, cpu2, readbw, writebw

def parse_cpu(szFile):
    """Read in a cpuperf file which has the three column format time,
    CPU utilization (%), memory usage (MB). Fill a 2D array with the
    latency data and return that vector"""

    data = []

    fFile = open(szFile,'r')
    for line in fFile:
        if line[0]=="#":
            continue
        data.append(map(float, re.findall("[-+]?\d+[\.]?\d*", line)))

    time = []; cpu = []; i=0
    for i in xrange(len(data)):
        time.append(data[i][0])
        cpu.append(data[i][1])

    return time, cpu

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
        for i in xrange(nBins):
            pnHist[i] = pnHist[i]/float(pnHist[-1])
    return pnBins,pnHist

def plotxdf(peX, peY, dtLabels=None, szFile='plotxdf.png', bCdf=False):
    """Use the GnuPlot program to plot the specified input data. For
    now we assume this is latency plot though we may generalize in
    time. Also, for now we dump the data to a temp file rather than
    placing it on the gnuplot command line."""

    TMP_FILE='plot.data'
    DEVNULL = open(os.devnull, 'wb')

    tmpFile = open(TMP_FILE,'w')
    for i in xrange(len(peX)):
        tmpFile.write("%f\t%f\n" % (peX[i],peY[i]))
    tmpFile.close()

    proc = subprocess.Popen(['gnuplot','-p'], shell=True,
                            stdin=subprocess.PIPE,
                            stdout=DEVNULL, stderr=DEVNULL)
    proc.stdin.write('set terminal png medium\n')
    proc.stdin.write('set output \"%s\"\n' % szFile)
    if dtLabels['title']:
        proc.stdin.write('set title \"Latency Distribution : %s\" font \",20\"\n' \
                             % dtLabels['title'])
    else:
        proc.stdin.write('set title \"Latency Distribution\" font \",20\"\n')
    proc.stdin.write('set xlabel \'time (us)\'\n')
    proc.stdin.write('set ylabel \'%s\'\n' % ("CDF" if bCdf else "PDF"))
    proc.stdin.write('set grid\n')
    proc.stdin.write('plot \"%s" with lines\n' % TMP_FILE)
    proc.stdin.write('quit\n')
    proc.wait()
    os.remove(TMP_FILE)

def plotxy(peX, peY, dtLabels=None, szFile='plotxy.png', logscale=False):
    """Use the GnuPlot program to plot the specified input data. For
    now we assume this is latency plot though we may generalize in
    time. Also, for now we dump the data to a temp file rather than
    placing it on the gnuplot command line."""

    if peX==None:
        peX = xrange(len(peY))

    TMP_FILE='plot.data'
    DEVNULL = open(os.devnull, 'wb')

    tmpFile = open(TMP_FILE,'w')
    for i in xrange(len(peX)):
        tmpFile.write("%f\t%f\n" % (peX[i],peY[i]))
    tmpFile.close()

    proc = subprocess.Popen(['gnuplot','-p'], shell=True,
                            stdin=subprocess.PIPE,
                            stdout=DEVNULL, stderr=DEVNULL)
    proc.stdin.write('set terminal png medium\n')
    proc.stdin.write('set output \"%s\"\n' % szFile)
    try:
        if dtLabels['title']:
            proc.stdin.write('set title \"%s\" font \",20\"\n' \
                                 % dtLabels['title'])
        if dtLabels['xlabel']:
            proc.stdin.write('set xlabel \'%s\'\n' % dtLabels['xlabel'])
        if dtLabels['ylabel']:
            proc.stdin.write('set ylabel \'%s\'\n' % dtLabels['ylabel'])
    except:
        pass
    if logscale:
        proc.stdin.write('set logscale x\n')
    proc.stdin.write('set grid\n')
    proc.stdin.write('plot \"%s" with lines\n' % TMP_FILE)
    proc.stdin.write('quit\n')
    proc.wait()
    os.remove(TMP_FILE)

def mean(peX):
    """Calculate the mean of a vector. No python2.x version of this
    built-in."""

    return sum(peX)/float(len(peX)) if len(peX) > 0 else float('nan')

def latency(options, args):

    data = []
    for i in range(len(args)):
        data.append(parse_lat(args[i]))

    if len(data[0])<(options.skip+options.crop):
        raise ValueError('pprocess.py skip and crop add to more than input data size')

    if options.skip:
        data[0] = data[0][options.skip:]
    if options.crop:
        data[0] = data[0][0:-options.crop]

    pnBins,pnHist = hist(data[0], options.bins, options.cdf)

    eMean = mean(data[0])
    eMin  = min(data[0])
    eMax  = max(data[0])
    dtLabels = {}
    dtLabels['title'] = "Latency : count=%d : mean=%.1fus : min=%.1fus : max=%.1fus" % \
        (len(data[0]),eMean,eMin,eMax)
    dtLabels['xlabel'] = "sample index"
    dtLabels['ylabel'] = "time (us)"
    plotxy(None, data[0], dtLabels, options.ofile+".time.png")
    plotxdf(pnBins, pnHist, dtLabels, options.ofile+".cdf.png", options.cdf)

def threads(options, args):

    x,y1,y2,y3 = parse_thr(args[0])
    dtLabels=dict()
    dtLabels['title']  = "Threads vs CPU Utilization"
    dtLabels['xlabel'] = "FIO threads"
    dtLabels['ylabel'] = "CPU Utilization (%)"
    plotxy(x, y1, dtLabels, szFile='threads.cpu.png')
    dtLabels=dict()
    dtLabels['title']  = "Threads vs Bandwidth"
    dtLabels['xlabel'] = "FIO threads"
    dtLabels['ylabel'] = "Bandwidth"
    plotxy(x, y2, dtLabels, szFile='threads.bw.png')
    try:
        dtLabels=dict()
        dtLabels['title']  = "Threads vs Bandwidth Efficiency"
        dtLabels['xlabel'] = "FIO threads"
        dtLabels['ylabel'] = "Bandwidth per HW Thread"
        plotxy(x, [100*float(a)/b for a,b in zip(y2,y1)], dtLabels, szFile='threads.cpubw.png')
    except:
        print "WARNING: Issue generating'threads.cpubw.png' skipping."
    x,y = parse_cpu('threads.cpu.log')
    dtLabels['title']  = "CPU Utilization vs time"
    dtLabels['xlabel'] = "time (sec)"
    dtLabels['ylabel'] = "CPU Utilization (%)"
    plotxy(x, y, dtLabels, szFile='threads.cpu.time.png')

def iodepth(options, args):

    x,y1,y2,y3 = parse_iod(args[0])
    dtLabels=dict()
    dtLabels['title']  = "IO Depth vs CPU Utilization"
    dtLabels['xlabel'] = "IO Depth"
    dtLabels['ylabel'] = "CPU Utilization (%)"
    plotxy(x, y1, dtLabels, szFile='iodepth.cpu.png')
    dtLabels=dict()
    dtLabels['title']  = "IO Depth vs Bandwidth"
    dtLabels['xlabel'] = "IO Depth"
    dtLabels['ylabel'] = "Bandwidth"
    plotxy(x, y2, dtLabels, szFile='iodepth.bw.png')

    dtLabels=dict()
    dtLabels['title']  = "IO Depth vs Bandwidth Efficiency"
    dtLabels['xlabel'] = "IO Depth"
    dtLabels['ylabel'] = "Bandwidth per HW Thread"
    plotxy(x, [100*float(a)/b if b != 0 else float('inf') for a,b in zip(y2,y1) ],
           dtLabels, szFile='iodepth.cpubw.png')

    x,y = parse_cpu('iodepth.cpu.log')
    dtLabels['title']  = "CPU Utilization vs time"
    dtLabels['xlabel'] = "time (sec)"
    dtLabels['ylabel'] = "CPU Utilization (%)"
    plotxy(x, y, dtLabels, szFile='iodepth.cpu.time.png')

def bs(options, args):

    x,y1,y2,y3 = parse_bs(args[0])
    dtLabels=dict()
    dtLabels['title']  = "Block Size vs CPU Utilization"
    dtLabels['xlabel'] = "Block Size"
    dtLabels['ylabel'] = "CPU Utilization (%)"
    plotxy(x, y1, dtLabels, szFile='bs.cpu.png', logscale=True)
    dtLabels=dict()
    dtLabels['title']  = "Block Size vs Bandwidth"
    dtLabels['xlabel'] = "Block Size"
    dtLabels['ylabel'] = "Bandwidth"
    plotxy(x, y2, dtLabels, szFile='bs.bw.png', logscale=True)
    try:
        dtLabels=dict()
        dtLabels['title']  = "Block Size vs Bandwidth Efficiency"
        dtLabels['xlabel'] = "Block Size"
        dtLabels['ylabel'] = "Bandwidth per HW Thread"
        plotxy(x, [100*float(a)/b for a,b in zip(y2,y1)], dtLabels, szFile='bs.cpubw.png', logscale=True)
    except:
        print "WARNING: Issue generating'bs.cpubw.png' skipping."
    x,y = parse_cpu('bs.cpu.log')
    dtLabels['title']  = "CPU Utilization vs time"
    dtLabels['xlabel'] = "time (sec)"
    dtLabels['ylabel'] = "CPU Utilization (%)"
    plotxy(x, y, dtLabels, szFile='bs.cpu.time.png')

if __name__=="__main__":
    import sys
    import optparse

    parser = optparse.OptionParser()
    parser.add_option("-m", "--mode", action="store", type=str,
                      default="latency", help="post processing mode")
    parser.add_option("-f", "--ofile", action="store", type=str,
                      default="latency", help="basename for output files")
    parser.add_option("-b", "--bins", action="store", type=int,
                      default=100, help="number of histogram bins")
    parser.add_option("-s", "--skip", action="store", type=int,
                      default=0, help="skip this number of data-points (start)")
    parser.add_option("-k", "--crop", action="store", type=int,
                      default=0, help="skip this number of data-points (end)")
    parser.add_option("-c", "--cdf", action="store_true",
                      help="generate CDF rather than PDF")
    options, args = parser.parse_args()

    if len(args)>1:
        raise ValueError('pprocess.py only accepts one input file (for now)')

    if options.mode=="latency":
        latency(options, args)
    elif options.mode=="threads":
        threads(options, args)
    elif options.mode=="iodepth":
        iodepth(options, args)
    elif options.mode=="bs":
        bs(options, args)
    else:
        raise ValueError('invalid option for mode (%s)' % options.mode)
