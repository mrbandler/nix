"""Update report for a pull request: what a flake input update changes for one host."""

import argparse
import json
import os
import re
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from dataclasses import dataclass
from datetime import datetime, timezone
from typing import TypedDict, cast

HYDRA_JOBSET = "nixpkgs/trunk"
HYDRA_MAX_PACKAGES = 40
TRACKER = "https://nixpkgs-tracker.ocfox.me/?pr="
USER_AGENT = "mrbandler/nix update report (+https://github.com/mrbandler/nix)"


class Locked(TypedDict, total=False):
    type: str
    rev: str
    narHash: str
    lastModified: int
    owner: str
    repo: str
    url: str


class Original(TypedDict, total=False):
    url: str


class Node(TypedDict, total=False):
    inputs: dict[str, str | list[str]]
    locked: Locked
    original: Original


class Lock(TypedDict):
    nodes: dict[str, Node]


class HydraBuild(TypedDict, total=False):
    success: bool
    status: str
    evals: bool
    timestamp: str
    build_url: str


class RepologyPackage(TypedDict, total=False):
    version: str
    status: str


class PullRequest(TypedDict):
    number: int
    title: str
    url: str


class HostPackage(TypedDict):
    name: str
    version: str


class Host(TypedDict):
    system: str
    packages: list[HostPackage]


@dataclass
class Section:
    title: str
    summary: str
    body: list[str]

    def render(self) -> str:
        return "\n".join(["<details>", f"<summary><b>{self.title}</b>: {self.summary}</summary>", "", *self.body, "", "</details>"])


@dataclass
class Package:
    name: str
    version: str


def fetch(url: str) -> str | None:
    request = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            return str(response.read().decode())
    except (urllib.error.URLError, TimeoutError):
        return None


def fetch_json(url: str) -> object:
    body = fetch(url)
    data: object = json.loads(body) if body else None
    return data


def resolve(url: str) -> str | None:
    """The final URL after redirects."""
    request = urllib.request.Request(url, headers={"User-Agent": USER_AGENT}, method="HEAD")
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            return str(response.url)
    except (urllib.error.URLError, TimeoutError):
        return None


def run(*command: str) -> str:
    result = subprocess.run(command, capture_output=True, text=True)
    return result.stdout if result.returncode == 0 else ""


def date(timestamp: int) -> str:
    return datetime.fromtimestamp(timestamp, timezone.utc).strftime("%Y-%m-%d")


def short(rev: str) -> str:
    return rev[:7]


def plural(count: int, noun: str) -> str:
    return f"{count} {noun}{'' if count == 1 else 's'}"


def root_inputs(lock: Lock) -> dict[str, Node]:
    nodes = lock["nodes"]
    return {name: nodes[key] for name, key in nodes["root"].get("inputs", {}).items() if isinstance(key, str)}


def compare_link(locked: Locked, old_rev: str, new_rev: str) -> str | None:
    if locked.get("type") == "github" and "owner" in locked and "repo" in locked:
        repo = f"{locked['owner']}/{locked['repo']}"
    elif "releases.nixos.org/nixpkgs/" in locked.get("url", ""):
        repo = "NixOS/nixpkgs"
    else:
        return None
    return f"https://github.com/{repo}/compare/{old_rev}...{new_rev}"


def inputs_section(old_lock: Lock, new_lock: Lock) -> Section:
    old, new = root_inputs(old_lock), root_inputs(new_lock)
    rows: list[str] = []
    for name, node in sorted(new.items()):
        locked = node.get("locked", {})
        previous = old.get(name, {}).get("locked")
        if previous and (previous.get("rev"), previous.get("narHash")) == (locked.get("rev"), locked.get("narHash")):
            continue
        new_rev = locked.get("rev", "")
        new_date = date(locked.get("lastModified", 0))
        if previous:
            old_rev = previous.get("rev", "")
            link = compare_link(locked, old_rev, new_rev) if old_rev else None
            to = f"[`{short(new_rev)}`]({link})" if link else f"`{short(new_rev)}`"
            rows.append(f"| {name} | `{short(old_rev)}` | {to} | {date(previous.get('lastModified', 0))} to {new_date} |")
        else:
            rows.append(f"| {name} | new | `{short(new_rev)}` | added ({new_date}) |")
    if not rows:
        return Section("Inputs", "nothing changed", ["No flake inputs changed."])
    return Section("Inputs", f"{len(rows)} changed", ["| input | from | to | dates |", "| --- | --- | --- | --- |", *rows])


def channel_section(new_lock: Lock) -> Section:
    node = root_inputs(new_lock)["nixpkgs"]
    locked = node.get("locked", {})
    rev, modified = locked.get("rev", ""), locked.get("lastModified", 0)
    age = int((time.time() - modified) // 86400)
    pinned = f"pinned `{rev[:12]}` ({date(modified)}, {plural(age, 'day')} old)"
    lines = [f"- {pinned}"]
    match = re.search(r"channels\.nixos\.org/([^/]+)/", node.get("original", {}).get("url", ""))
    if not match:
        lines.append("- nixpkgs is not pinned to a channel tarball, skipping channel checks")
        return Section("nixpkgs channel", pinned, lines)
    channel = match.group(1)
    current = (fetch(f"https://channels.nixos.org/{channel}/git-revision") or "").strip()
    location = resolve(f"https://channels.nixos.org/{channel}")
    release = location.rstrip("/").rsplit("/", 1)[-1] if location else "current release"
    if not current:
        summary = f"{pinned}, channel state unknown"
        lines.append(f"- channel `{channel}`: could not query the current revision")
    elif current == rev:
        summary = f"{pinned}, channel is at this revision"
        lines.append(f"- channel `{channel}` is at this exact revision ({release})")
    else:
        summary = f"{pinned}, channel has moved on"
        lines.append(f"- channel `{channel}` has moved on to `{current[:12]}` ({release}); the next update will pick it up")
    lines.append(f"- [status.nixos.org](https://status.nixos.org) for channel health, gating jobset [`{HYDRA_JOBSET}`](https://hydra.nixos.org/jobset/{HYDRA_JOBSET}) on Hydra")
    return Section("nixpkgs channel", summary, lines)


NVD_LINE = re.compile(r"^\[([A-Z])[A-Z.*]*\]\s+#\d+\s+(\S+)")


def diff_section(old_closure: str, new_closure: str) -> tuple[Section, list[str]]:
    diff = run("nvd", "diff", old_closure, new_closure)
    matches = [match for match in map(NVD_LINE.match, diff.splitlines()) if match]
    if not matches:
        return Section("Closure diff", "no package changes", ["No package changes in the closure."]), []
    size = next((line.removeprefix("Closure size: ").rstrip(".") for line in diff.splitlines() if line.startswith("Closure size")), "")
    summary = f"{plural(len(matches), 'package change')}" + (f", closure {size}" if size else "")
    changed = sorted({match.group(2) for match in matches if match.group(1) in "UDCA"})
    return Section("Closure diff", summary, ["```", diff.rstrip(), "```"]), changed


def hydra_build(package: str, system: str) -> HydraBuild | None:
    output = run("hydra-check", package, "--arch", system, "--jobset", HYDRA_JOBSET, "--short", "--json")
    try:
        jobs = cast(dict[str, list[HydraBuild]], json.loads(output))
        return next(iter(jobs.values()))[0]
    except (ValueError, StopIteration, IndexError):
        return None


def hydra_section(changed: list[str], system: str) -> Section:
    title = f"Hydra build status (`{HYDRA_JOBSET}`, `{system}`)"
    if not changed:
        return Section(title, "nothing to check", ["Nothing changed, nothing to check."])
    lines: list[str] = []
    if len(changed) > HYDRA_MAX_PACKAGES:
        lines += [f"Checking the first {HYDRA_MAX_PACKAGES} of {len(changed)} changed packages.", ""]
        changed = changed[:HYDRA_MAX_PACKAGES]
    lines += ["| package | Hydra |", "| --- | --- |"]
    succeeded = failed = 0
    for package in changed:
        build = hydra_build(package, system)
        if build is None:
            status = "no data"
        elif build.get("success"):
            succeeded += 1
            status = f"✅ succeeded {build.get('timestamp', '')[:10]} ([build]({build.get('build_url', '')}))"
        elif not build.get("evals", True):
            status = "➖ no Hydra job (unfree, not built for this platform, or a different attribute name)"
        else:
            failed += 1
            link = f" ([build]({build.get('build_url')}))" if build.get("build_url") else ""
            status = f"❌ {build.get('status', 'failed')}{link}"
        lines.append(f"| `{package}` | {status} |")
    summary = f"{succeeded} succeeded, {failed} failed, {len(changed) - succeeded - failed} without a job"
    return Section(title, summary, lines)


def repology_versions(name: str) -> list[str]:
    """Newest upstream versions of a nixpkgs package according to Repology."""
    query = urllib.parse.urlencode({"repo": "nix_unstable", "name_type": "srcname", "name": name, "target_page": "api_v1_project"})
    project = cast(list[RepologyPackage] | None, fetch_json(f"https://repology.org/tools/project-by?{query}"))
    if project is None:
        project = cast(list[RepologyPackage] | None, fetch_json(f"https://repology.org/api/v1/project/{urllib.parse.quote(name)}"))
    time.sleep(1)
    return sorted({entry.get("version", "") for entry in project or [] if entry.get("status") == "newest"})


def bump_prs(name: str) -> str:
    output = run("gh", "search", "prs", "--repo", "NixOS/nixpkgs", "--state", "open", "--match", "title", "--limit", "20", "--json", "number,title,url", name)
    time.sleep(2)
    pattern = re.compile(rf"^_?{re.escape(name)}: .*(->|→)", re.IGNORECASE)
    found = cast(list[PullRequest], json.loads(output)) if output else []
    prs = [pr for pr in found if pattern.match(pr["title"])]
    return "<br>".join(f"[#{pr['number']}]({pr['url']}) {pr['title'][:60]} ([tracker]({TRACKER}{pr['number']}))" for pr in prs)


def release(version: str) -> str:
    """The leading numeric part of a version, so 0.5.1-unstable-2025-12-12 counts as 0.5.1."""
    match = re.match(r"\d+(\.\d+)*", version)
    return match.group(0) if match else version


def freshness_section(packages: list[Package]) -> Section:
    behind: list[str] = []
    current: list[str] = []
    unknown: list[str] = []
    for package in sorted(packages, key=lambda p: p.name):
        newest = repology_versions(package.name)
        if not newest:
            unknown.append(package.name)
        elif release(package.version) in map(release, newest):
            current.append(f"| `{package.name}` | ✅ {package.version} | {', '.join(newest)} | |")
        else:
            behind.append(f"| `{package.name}` | ⚠️ {package.version} | {', '.join(newest)} | {bump_prs(package.name) or 'none'} |")
    lines = ["| app | nixpkgs | upstream | open nixpkgs bump PRs |", "| --- | --- | --- | --- |", *behind, *current]
    if unknown:
        lines += ["", f"No upstream version on Repology: {', '.join(f'`{name}`' for name in sorted(unknown))}."]
    summary = f"{len(behind)} behind upstream, {len(current)} up to date, {len(unknown)} unknown"
    return Section("App freshness", summary, lines)


def load(path: str) -> object:
    with open(path) as file:
        data: object = json.load(file)
        return data


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0] if __doc__ else None)
    parser.add_argument("--host", required=True)
    parser.add_argument("--old-lock", required=True)
    parser.add_argument("--new-lock", required=True)
    parser.add_argument("--old-closure", required=True)
    parser.add_argument("--new-closure", required=True)
    args = parser.parse_args()

    hosts = cast(dict[str, Host], load(os.environ["UPDATE_REPORT_HOSTS"]))
    if args.host not in hosts:
        sys.exit(f"unknown host {args.host!r}, known: {', '.join(sorted(hosts))}")
    system = hosts[args.host]["system"]
    packages = [Package(p["name"], p["version"] or "?") for p in hosts[args.host]["packages"]]
    old_lock, new_lock = cast(Lock, load(args.old_lock)), cast(Lock, load(args.new_lock))

    diff, changed = diff_section(args.old_closure, args.new_closure)
    sections = [
        inputs_section(old_lock, new_lock),
        channel_section(new_lock),
        diff,
        hydra_section(changed, system),
        freshness_section(packages),
    ]
    print(f"## Update report for `{args.host}` (`{system}`)")
    print()
    print("CI built the new closure; this report covers what changes and how safe it looks.")
    for section in sections:
        print()
        print(section.render())


if __name__ == "__main__":
    main()
