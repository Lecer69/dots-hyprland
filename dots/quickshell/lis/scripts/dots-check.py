#!/usr/bin/env python3
# Update check for the Dots Updater page: dots-check.py <clone> <repo url>
# Fetches dots-hyprland and prints JSON (latest, installed, behind, commits, devCheckout).
# The installed commit is the one whose files differ least from ~/.config.

import glob
import json
import os
import subprocess
import sys

# Kept by install.sh's update, so never compared
HYPR_PRESERVED = {"custom", "hyprpaper.conf", "monitors.conf", "monitors.lua", "workspaces.conf"}

MAX_CANDIDATES = 100
# Listed when the installed commit is unknown or the latest
RECENT_COMMITS = 10
MAX_COMMITS = 50

clone, url = sys.argv[1], sys.argv[2]
config = os.environ.get("XDG_CONFIG_HOME") or os.path.expanduser("~/.config")
env = dict(os.environ, GIT_TERMINAL_PROMPT="0", LC_ALL="C")


def fail(message):
    print(json.dumps({"error": message}))
    sys.exit(1)


def git(*args, timeout=30, stdin=None):
    return subprocess.run(["git", "-C", clone, "-c", "core.quotepath=off", *args],
                          input=stdin, capture_output=True, text=True, env=env,
                          timeout=timeout, check=True).stdout


def last_line(error):
    lines = (error.stderr or "").strip().splitlines()
    line = lines[-1] if lines else str(error)
    # git's message for a missing repo, and for no network
    if "could not read Username" in line:
        return "Couldn't find " + url
    if "Could not resolve host" in line:
        return "Couldn't reach github.com"
    return line.removeprefix("fatal: ")


def sync():
    try:
        if not os.path.exists(clone):
            os.makedirs(os.path.dirname(clone), exist_ok=True)
            subprocess.run(["git", "clone", "--quiet", url, clone], capture_output=True,
                           text=True, env=env, timeout=180, check=True)
            return
        if not os.path.isdir(os.path.join(clone, ".git")):
            fail(clone + " isn't a git clone; delete it and check again")
        git("remote", "set-url", "origin", url)
        git("fetch", "--quiet", "--prune", "origin", timeout=120)
    except subprocess.TimeoutExpired:
        fail("Timed out reaching " + url)
    except subprocess.CalledProcessError as e:
        fail(last_line(e))


# A repo path's place under ~/.config
def installed_path(path):
    if path.startswith("dots/quickshell/"):
        return path[len("dots/"):]
    if path.startswith("dots/hypr/"):
        if path[len("dots/hypr/"):].split("/", 1)[0] in HYPR_PRESERVED:
            return None
        return path[len("dots/"):]
    return None


# Whether an update installs this file
def in_scope(path):
    return installed_path(path) is not None or path.startswith("extra/lis")


def tree(sha):
    files = {}
    for entry in git("ls-tree", "-r", "-z", sha, "--", "dots/quickshell", "dots/hypr").split("\0"):
        if not entry:
            continue
        meta, path = entry.split("\t", 1)
        mode, kind, blob = meta.split()
        key = installed_path(path)
        if kind == "blob" and key:
            files[key] = blob
    return files


def find_installed(latest):
    candidates = git("rev-list", "--max-count=" + str(MAX_CANDIDATES), latest,
                     "--", "dots/quickshell", "dots/hypr").split()
    trees = [(sha, tree(sha)) for sha in candidates]
    known = sorted({key for _, files in trees for key in files})

    # Blob ids of the installed copies
    present = [key for key in known if "\n" not in key and os.path.isfile(os.path.join(config, key))]
    blobs = git("hash-object", "--no-filters", "--stdin-paths",
                stdin="".join(os.path.join(config, key) + "\n" for key in present)).split()
    installed = dict(zip(present, blobs))

    best = None
    for sha, files in trees:
        differs = sum(1 for key, blob in files.items() if installed.get(key) != blob)
        differs += sum(1 for key in installed if key not in files)
        if best is None or differs < best[1]:
            best = (sha, differs, len(files))

    # Over half the files differing isn't an install of that commit
    if best is None or best[1] * 2 > best[2]:
        return None, 0
    return best[0], best[1]


def commits(*revs):
    out = git("log", "--no-merges", "--no-renames", "--raw", "--numstat",
              "--format=%x1e%H%x1f%at%x1f%an%x1f%s%x1f%b%x1f", *revs)
    result = []
    for record in out.split("\x1e")[1:]:
        sha, time, author, subject, body, changes = record.split("\x1f", 5)
        status, stats = {}, {}
        for line in changes.splitlines():
            if line.startswith(":"):
                meta, path = line.split("\t", 1)
                status[path] = meta.split()[-1][0]
            elif line:
                added, removed, path = line.split("\t", 2)
                stats[path] = (int(added) if added.isdigit() else 0,
                               int(removed) if removed.isdigit() else 0)
        files = [{
            "path": path[len("dots/"):] if path.startswith("dots/") else path,
            "status": status.get(path, "M"),
            "added": stats.get(path, (0, 0))[0],
            "removed": stats.get(path, (0, 0))[1],
            "inScope": in_scope(path),
        } for path in status]
        result.append({
            "sha": sha,
            "short": sha[:7],
            "time": int(time),
            "author": author,
            "subject": subject,
            "body": body.strip(),
            "added": sum(f["added"] for f in files),
            "removed": sum(f["removed"] for f in files),
            "files": files,
        })
    return result


def summary(sha):
    subject, time = git("log", "-1", "--format=%s%x1f%at", sha).strip().split("\x1f")
    return {"sha": sha, "short": sha[:7], "subject": subject, "time": int(time)}


sync()

try:
    latest = git("rev-parse", "origin/HEAD").strip()
    installed, differs = find_installed(latest)
    if installed:
        behind = int(git("rev-list", "--count", "--no-merges", installed + ".." + latest))
    else:
        behind = int(git("rev-list", "--count", "--no-merges", latest))
    if installed and behind > 0:
        listed = commits("--max-count=" + str(MAX_COMMITS), installed + ".." + latest)
    else:
        listed = commits("--max-count=" + str(RECENT_COMMITS), latest)
except subprocess.CalledProcessError as e:
    fail(last_line(e))

dev = [path for path in [os.path.join(config, "quickshell")] + glob.glob(os.path.join(config, "quickshell", "*"))
       if os.path.exists(os.path.join(path, ".git"))]

print(json.dumps({
    "latest": summary(latest),
    "installed": dict(summary(installed), differs=differs) if installed else None,
    "behind": behind,
    "commits": listed,
    "devCheckout": dev[0].replace(os.path.expanduser("~"), "~", 1) if dev else "",
}))
