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

Only the named programs are acted on, and only when they leave in a way
supervisor did not ask for -- a deliberate stop carries expected:1 and is
ignored, otherwise every container shutdown would look like a crash.
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

    event = headers.get("eventname")
    if event in FATAL_EVENTS:
        return True
    # A stop asked for by supervisor is reported as expected:1; only an exit it
    # did not ask for means the program died on its own.
    return event in EXIT_EVENTS and payload.get("expected") == "0"


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
                "supervisord-fail-fast: %s left unexpectedly (%s), stopping supervisord\n"
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
