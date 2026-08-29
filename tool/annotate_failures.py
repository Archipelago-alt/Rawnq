#!/usr/bin/env python3
"""Turn a `flutter test` log into GitHub Actions error annotations.

CI logs are not readable without repository access, but annotations are, so
failures are condensed into annotations instead. Annotations must be a single
line with no control characters, and GitHub renders only the first ten.

Usage: python3 tool/annotate_failures.py <logfile>
"""
import re
import sys

ANSI = re.compile(r"\x1b\[[0-9;]*m")
LOCATION = re.compile(r"\.dart:\d+:\d+")
# `flutter test` marks a failing test by appending [E] to its progress line,
# which is where the test name lives.
FAILED_TEST = re.compile(r"\[E\]\s*$")
SUMMARY = re.compile(r"(Some tests failed|All tests passed|\d+ tests? (passed|failed))")
MAX_ANNOTATIONS = 10
MAX_LEN = 400

INTERESTING = ("Expected:", "Actual:", "Which:", "Error:", "Exception:")


def clean(raw: str) -> str:
    return ANSI.sub("", raw).replace("\r", "").strip()


def main() -> int:
    path = sys.argv[1] if len(sys.argv) > 1 else "/tmp/test.log"
    try:
        with open(path, errors="replace") as handle:
            lines = handle.read().replace("\r", "\n").split("\n")
    except OSError as error:
        print(f"::error::could not read {path}: {error}")
        return 1

    failures, seen = [], set()
    for raw in lines:
        line = clean(raw)
        if not line:
            continue
        if line.startswith(INTERESTING) or LOCATION.search(line) \
                or FAILED_TEST.search(line):
            message = line[:MAX_LEN]
            if message not in seen:
                seen.add(message)
                failures.append(message)

    summaries = [clean(line) for line in lines if SUMMARY.search(line)]

    # Leave room for the summary line, which is the most useful single fact.
    for message in failures[: MAX_ANNOTATIONS - 1]:
        print(f"::error::{message}")
    if summaries:
        print(f"::error::{summaries[-1][:MAX_LEN]}")
    if not failures and not summaries:
        print("::error::Tests failed but no failure lines were recognised.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
