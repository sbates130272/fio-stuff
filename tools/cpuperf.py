#!/usr/bin/env python3

import os
import sys
import subprocess as sp
import time

def get_ps_data(options):
    try:
        data = sp.check_output(["ps", "-C", options.command, "-o" "%cpu=,%mem="])
        if options.multithread:
            temp = tuple(float(x) for x in data.split())
            data = (sum(temp[::2]), sum(temp[1::2]))
        else:
            data = tuple(float(x) for x in data.split()[0:2])
    except sp.CalledProcessError:
        if (options.skip):
            data=None
        else:
            data = 0.,0.

    return data

class HostData(object):
    def __init__(self):
        self.last_total = None
        self.last_time = None

        self.clk_tck = os.sysconf(os.sysconf_names['SC_CLK_TCK'])

        self.start = self.get_total_usage()
        self.start_time = time.time()

    def get_total_usage(self):
        return sum(float(x) for x in
                    open("/proc/stat").readline().split()[:3])

    def calc_cpu(self, a, b, start_time):
        duration = time.time() - start_time
        return (a - b) / duration / self.clk_tck

    def get_cpu(self):
        usage = None
        total = self.get_total_usage()

        if self.last_total is not None:
            usage = self.calc_cpu(total, self.last_total, self.last_time)

        self.last_time = time.time()
        self.last_total = total

        return usage

    def get_mem(self):
        line = sp.check_output(["free"]).split("\n")[1]
        total, used = (int(x) for x in line.split()[1:3])

        return float(used) / float(total) * 100.

    def __call__(self, *args):
        cpu = self.get_cpu()

        if cpu is None:
            return

        return cpu, self.get_mem()

    def average(self):
        total = self.get_total_usage()
        return self.calc_cpu(total, self.start, self.start_time)

if __name__=="__main__":
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument("-C", "--command", action="store",
                         help="The command to look for in the ps log.", default=None)
    parser.add_argument("-t", "--time", action="store", type=int,
                        help="Time to run for in seconds (-1 to run forever)", default=-1)
    parser.add_argument("-w", "--wait", action="store", type=int,
                        help="Wait time in ms between calls to ps.", default=100)
    parser.add_argument("-s", "--skip", action="store_true",
                        help="Only output data when command is running.")
    parser.add_argument("-m", "--multithread", action="store_true",
                        help="Treat the process as a multi-threaded one when calling ps.")
    options = parser.parse_args()

    if not options.command:
        get_data = HostData()
    else:
        get_data = get_ps_data

    try:
        start_time = time.time()
        end_time = start_time + options.time
        print("#%7s   %3s   %3s" % ("TIME", "CPU", "MEM"))
        while options.time < 0 or time.time() < end_time:
            t = time.time()-start_time
            data = get_data(options)
            if data:
                print("%8.1f   %-3.1f   %3.1f" % ((t,) + data))
                sys.stdout.flush()
            time.sleep(options.wait / 1000.)

    except KeyboardInterrupt:
        print()
        if hasattr(get_data, "average"):
            print("%-8s   %-3.1f" % (("Average", get_data.average())))
