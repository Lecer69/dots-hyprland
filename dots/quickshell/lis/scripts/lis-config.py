#!/usr/bin/env python3
# Moves the JSON files of ~/.config/lis in and out of a .lisc file
#   export <file>        writes them and prints the file's path
#   check <file>         prints what the file holds as JSON; exit 1 with the reason if it can't be used
#   import <file> <pid>  stops the shell with that pid, copies the old files to ~/.local/state/lis, writes the new ones, starts it again
# A .lisc is one line, lisc1:<sha256 of the base64>:<base64 of gzipped JSON>; encoded, not encrypted

import base64
import binascii
import gzip
import hashlib
import io
import json
import os
import platform
import re
import signal
import subprocess
import sys
import tempfile
import time

CONFIG = os.path.expanduser("~/.config/lis")
BACKUPS = os.path.expanduser("~/.local/state/lis")
NAME = re.compile(r"^[^./\\][^/\\]*\.json$")
# Unpacked; far above any real config
MAX_SIZE = 256 * 1024 * 1024


def read_config():
    files = {}
    for name in sorted(os.listdir(CONFIG)):
        path = os.path.join(CONFIG, name)
        if NAME.match(name) and os.path.isfile(path) and not os.path.islink(path):
            with open(path, encoding="utf-8") as f:
                files[name] = f.read()
    return files


def write_atomic(path, text):
    folder = os.path.dirname(path)
    os.makedirs(folder, exist_ok=True)
    fd, temp = tempfile.mkstemp(dir=folder, prefix=".lis-config-")
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as f:
            f.write(text)
        os.chmod(temp, 0o644)
        os.replace(temp, path)
    except BaseException:
        os.unlink(temp)
        raise


def encode(files):
    payload = {
        "created": time.strftime("%Y-%m-%d %H:%M"),
        "host": platform.node(),
        "files": files,
    }
    packed = gzip.compress(json.dumps(payload).encode(), mtime=0)
    text = base64.b64encode(packed).decode()
    return "lisc1:%s:%s\n" % (hashlib.sha256(text.encode()).hexdigest(), text)


# Everything is checked here, so a bad file changes nothing
def decode(path):
    try:
        with open(path, encoding="ascii") as f:
            parts = f.read().strip().split(":", 2)
    except (OSError, UnicodeDecodeError):
        raise ValueError("Couldn't read the file")

    if len(parts) != 3 or parts[0] != "lisc1":
        raise ValueError("Not a .lisc file")
    if hashlib.sha256(parts[2].encode()).hexdigest() != parts[1]:
        raise ValueError("The file is damaged: its hash doesn't match")

    try:
        packed = base64.b64decode(parts[2], validate=True)
        with gzip.GzipFile(fileobj=io.BytesIO(packed)) as f:
            data = f.read(MAX_SIZE + 1)
        if len(data) > MAX_SIZE:
            raise ValueError
        payload = json.loads(data)
        files = payload["files"]
        if not files or not all(NAME.match(name) for name in files):
            raise ValueError
        for text in files.values():
            json.loads(text)
    except (binascii.Error, OSError, EOFError, ValueError, KeyError, TypeError, AttributeError):
        raise ValueError("The file holds something other than a configuration")
    return payload


def stop_shell(pid):
    try:
        os.kill(pid, signal.SIGTERM)
        for _ in range(50):
            os.kill(pid, 0)
            time.sleep(0.1)
        os.kill(pid, signal.SIGKILL)
        time.sleep(0.2)
    except ProcessLookupError:
        pass


def start_shell():
    # Set on a shell Hyprland started; it would lock the screen
    env = {k: v for k, v in os.environ.items() if k != "ON_HYPRSTART"}
    subprocess.Popen(["qs", "-c", "lis"], env=env, start_new_session=True,
                     stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def notify(title, body):
    # Once the new shell takes notifications
    time.sleep(3)
    subprocess.run(["timeout", "10", "notify-send", "-a", "Settings", title, body])


def run_import(path, pid):
    payload = decode(path)
    stop_shell(pid)
    try:
        backup = os.path.join(BACKUPS, "before-import-%s.lisc" % time.strftime("%Y%m%d-%H%M%S"))
        write_atomic(backup, encode(read_config()))
        for name, text in payload["files"].items():
            write_atomic(os.path.join(CONFIG, name), text)
        title, body = "Configuration imported", "The old files are in " + backup
    except OSError as e:
        title, body = "Import failed", str(e)
    start_shell()
    notify(title, body)


def main():
    mode = sys.argv[1] if len(sys.argv) > 1 else ""
    try:
        if mode == "export" and len(sys.argv) == 3:
            path = sys.argv[2] if sys.argv[2].endswith(".lisc") else sys.argv[2] + ".lisc"
            write_atomic(os.path.abspath(path), encode(read_config()))
            print(path)
        elif mode == "check" and len(sys.argv) == 3:
            payload = decode(sys.argv[2])
            print(json.dumps({
                "created": payload.get("created", ""),
                "host": payload.get("host", ""),
                "files": sorted(payload["files"]),
            }))
        elif mode == "import" and len(sys.argv) == 4:
            run_import(sys.argv[2], int(sys.argv[3]))
        else:
            print("usage: lis-config.py export|check <file>, or import <file> <shell pid>", file=sys.stderr)
            return 2
    except (ValueError, OSError) as e:
        print(e, file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
