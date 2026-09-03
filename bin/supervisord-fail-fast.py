#!/usr/bin/python3
"""Stop supervisord when a critical program dies unexpectedly.

Programs like nginx and php-fpm run with autorestart=false: supervisor is not
meant to bring them back, the orchestrator is meant to replace the container.
Supervisor on its own only marks the program EXITED and keeps running, so the
container stays up. That matters because a master killed outside its own signal
handling leaves its workers reparented to PID 1, still holding the listen
sockets and still answering requests, while nothing supervises them any more.

Listening for the state change and shutting supervisord down turns that into a
container exit, so the orphans go away with it and the orchestrator can start a
clean replacement.

Usage: supervisord-fail-fast.py <program> [<program> ...]

Only the named programs are acted on. For those, any exit is fatal: they are
servers that are supposed to run until the container stops, so there is no exit
code that means "this was fine".

A deliberate stop does not reach here. Supervisor moves a program it stops
itself through STOPPING to STOPPED and emits no PROCESS_STATE_EXITED at all, so
a container shutdown and a `supervisorctl stop` are both invisible to this
listener without needing to be filtered out.
"""
import os
import sys

from supervisor import childutils

FATAL_EVENTS = ("PROCESS_STATE_FATAL",)
EXIT_EVENTS = ("PROCESS_STATE_EXITED",)


def write_stdout(s):
    sys.stdout.write(s)
    sys.stdout.flush()


def write_stderr(s):
    sys.stderr.write(s)
    sys.stderr.flush()


def parse(line):
    """Turn 'a:1 b:2' into {'a': '1', 'b': '2'}, ignoring anything malformed."""
    out = {}
    for token in line.split():
        key, sep, value = token.partition(":")
        if sep:
            out[key] = value
    return out


def is_fatal(headers, payload, programs):
    """True when this event means a critical program is gone for good."""
    if payload.get("processname") not in programs:
        return False

    # Any exit counts. `expected` is not the right discriminator: it says the
    # exit code was in the program's `exitcodes` list, not that supervisor asked
    # for the exit. A SIGTERM sent to the php-fpm master from outside supervisor
    # makes it exit 0, which is `expected:1`, and the container was then left
    # running without php-fpm -- exactly the state this listener exists to end.
    return headers.get("eventname") in FATAL_EVENTS + EXIT_EVENTS


def main(programs):
    if not programs:
        write_stderr("supervisord-fail-fast: no program name given\n")
        return 2

    while True:
        # transition from ACKNOWLEDGED to READY
        write_stdout("READY\n")

        line = sys.stdin.readline()
        if not line:
            return 0

        headers = parse(line)
        try:
            payload = parse(sys.stdin.read(int(headers.get("len", 0))))
        except ValueError:
            payload = {}

        fatal = is_fatal(headers, payload, programs)
        if fatal:
            write_stderr(
                "supervisord-fail-fast: %s exited (%s), stopping supervisord\n"
                % (payload.get("processname"), headers.get("eventname"))
            )

        # Acknowledge before shutting down, so supervisor is not left waiting on
        # a listener that never answers.
        write_stdout("RESULT 2\nOK")

        if fatal:
            shutdown()


def shutdown():
    """Ask supervisord to stop, over the RPC socket it hands every listener.

    supervisorctl is not usable here: it defaults to etc/supervisord.conf, which
    does not exist in this image, and hard-coding the real path would duplicate
    something supervisor already tells us. SUPERVISOR_SERVER_URL is exported
    into every event listener's environment, credentials included.
    """
    try:
        childutils.getRPCInterface(os.environ).supervisor.shutdown()
    except Exception as exc:  # noqa: BLE001 - never let the listener die on this
        write_stderr("supervisord-fail-fast: shutdown failed: %r\n" % (exc,))


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
