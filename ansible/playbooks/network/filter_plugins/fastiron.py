"""Filters for comparing FastIron (Brocade/Ruckus ICX) configurations."""

import re

DOCUMENTATION = """
name: fastiron_lines
short_description: Turn a FastIron config into comparable lines
description:
  - Splits a FastIron running config into one entry per line, prefixing each indented line with the block it belongs to,
    so two configs can be compared as sets regardless of block order, blank lines, '!' separators or spacing.
options:
  _input:
    description: The configuration text.
    type: str
    required: true
  ignore:
    description: Regular expressions; matching top-level lines, and the blocks they open, are left out.
    type: list
    elements: str
"""


def fastiron_lines(text, ignore=None):
    """Return a sorted list of 'block :: line' and top-level entries."""
    patterns = [re.compile(p) for p in (ignore or [])]
    entries = []
    header = None
    skipping = False
    for raw in str(text).splitlines():
        if not raw.strip() or raw.strip() == "!":
            continue
        line = " ".join(raw.split())
        if raw[0] in " \t":
            if header is not None and not skipping:
                entries.append("%s :: %s" % (header, line))
            continue
        skipping = any(p.search(line) for p in patterns)
        header = line
        if not skipping:
            entries.append(line)
    return sorted(set(entries))


class FilterModule(object):
    """FastIron config filters."""

    def filters(self):
        return {"fastiron_lines": fastiron_lines}
