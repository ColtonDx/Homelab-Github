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


def fastiron_commands(entries):
    """Group fastiron_lines entries into pushes: [{'parents': [block] or [], 'lines': [...]}], top-level lines first."""
    top = [e for e in entries if " :: " not in e]
    blocks = {}
    for entry in entries:
        if " :: " in entry:
            header, line = entry.split(" :: ", 1)
            blocks.setdefault(header, []).append(line)
    # A missing block header is opened by its block's parents line instead, so it never leaves later top-level lines inside that block
    top = [line for line in top if line not in blocks]
    pushes = [{"parents": [], "lines": top}] if top else []
    for header in sorted(blocks):
        pushes.append({"parents": [header], "lines": blocks[header]})
    return pushes


class FilterModule(object):
    """FastIron config filters."""

    def filters(self):
        return {"fastiron_lines": fastiron_lines, "fastiron_commands": fastiron_commands}
