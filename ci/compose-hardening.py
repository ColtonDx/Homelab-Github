"""Warns about Docker Compose services in docker/ that are missing part of the standard hardening block (docs/docker/hardening.md).

Warnings only for now: each one becomes a GitHub annotation, and the exit code is always 0 until every stack has been rolled out.
A service can skip a check with a comment on the same line as its image, e.g. `image: ...  # hardening: no read_only (writes its own files)`.
"""

import glob
import sys

import yaml

# Each check: a short name and a test on the service's settings
CHECKS = {
    "no-new-privileges": lambda s: any("no-new-privileges" in str(o) for o in s.get("security_opt", [])),
    "cap_drop ALL": lambda s: "ALL" in [str(c).upper() for c in s.get("cap_drop", [])],
    "healthcheck": lambda s: "healthcheck" in s,
    "mem_limit": lambda s: "mem_limit" in s or "memory" in str(s.get("deploy", {})),
    "pids_limit": lambda s: "pids_limit" in s,
    "log rotation": lambda s: "max-size" in str(s.get("logging", {})),
}


def main():
    missing = 0
    for path in sorted(glob.glob("docker/*/docker-compose.y*ml")):
        with open(path, encoding="utf-8") as handle:
            text = handle.read()
        services = (yaml.safe_load(text) or {}).get("services", {}) or {}
        for name, service in services.items():
            # A recorded exception in a comment counts as handled
            skipped = [line.split("# hardening:", 1)[1] for line in text.splitlines() if "# hardening:" in line]
            gaps = [check for check, test in CHECKS.items() if not test(service or {}) and not any(check.split()[0] in s for s in skipped)]
            if gaps:
                missing += 1
                print(f"::warning file={path}::{name} is missing: {', '.join(gaps)}")
    print(f"{missing} service(s) still need hardening")
    return 0


if __name__ == "__main__":
    sys.exit(main())
