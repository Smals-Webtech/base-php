#!/usr/bin/python3
"""Run a command on every supervisor event delivered on stdin.

The event header and payload are echoed only when DEBUG is set. They carry
nothing an operator needs -- a serial, a pool name, a timestamp -- and a TICK_60
subscriber emits them once a minute forever, which buries the lines that do
matter.
"""
import os
import subprocess
import sys

DEBUG = os.environ.get("DEBUG", "false").lower() == "true"


def write_stdout(s):
    sys.stdout.write(s)
    sys.stdout.flush()


def write_stderr(s):
    sys.stderr.write(s)
    sys.stderr.flush()


def main(args):
    while 1:
        # transition from ACKNOWLEDGED to READY
        write_stdout("READY\n")

        # read header line from stdin
        line = sys.stdin.readline()

        # read event payload
        headers = dict([x.split(":") for x in line.split()])
        data = sys.stdin.read(int(headers["len"]))

        if DEBUG:
            write_stderr(line)
            write_stderr(data + "\n")

        res = subprocess.call(args, stdout=sys.stderr)  # don't mess with real stdout

        # transition from READY to ACKNOWLEDGED
        if res != 0:
            write_stdout("RESULT 4\nFAIL")
        else:
            write_stdout("RESULT 2\nOK")


if __name__ == "__main__":
    main(sys.argv[1:])
