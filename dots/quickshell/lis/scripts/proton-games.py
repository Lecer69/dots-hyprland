#!/usr/bin/env python3
# Steam games, non-Steam shortcuts and compatibility tools for the Proton panel.
#   proton-games.py                               prints JSON: { games, tools }
#   proton-games.py set-launch <id> <options>
#   proton-games.py set-tool <id> <tool>          an empty tool is Steam's default
#   proton-games.py add-game <name> <exe> <options> <tool>
#   proton-games.py remove-game <id>              non-Steam only; the game's own files stay
#   proton-games.py delete-prefix <id>
#   proton-games.py list-tools                    prints JSON: { installed, available }
#   proton-games.py releases                      prints JSON: { releases, error }
#   proton-games.py install <source> [old tool]   the old tool's games move over, then it's deleted
#   proton-games.py delete-tool <tool>
# Steam rewrites its files when it exits, so changing them needs it closed. Only the one value
# changes, the rest of the file stays byte for byte, and <file>.lis-backup keeps the last version.

import glob
import hashlib
import json
import os
import re
import shutil
import signal
import struct
import subprocess
import sys
import tempfile
import time
import zlib

ROOTS = [
    ".local/share/Steam",
    ".steam/steam",
    ".var/app/com.valvesoftware.Steam/.local/share/Steam",
    "snap/steam/common/.local/share/Steam",
]
# Tools with no toolmanifest.vdf: common redistributables, BattlEye and EasyAntiCheat runtimes
TOOLS = {"228980", "1161040", "1826330"}
STEAM_KEYS = ("Software", "Valve", "Steam")
TOKEN = re.compile(r'"((?:[^"\\]|\\.)*)"|([{}])|//[^\n]*', re.DOTALL)
# Steam's list of its Proton versions lives in this app's entry
COMPAT_APP = 891390
APPINFO_MAGIC = 0x07564429
APPINFO_ENTRY_HEADER = 68
# Newest release of each, from GitHub. `match` finds its installed versions; all ship checksums.
SOURCES = {
    "GE-Proton": {
        "repo": "GloriousEggroll/proton-ge-custom",
        "asset": r"^GE-Proton(?!.*aarch64).*\.tar\.gz$",
        "match": r"^GE-Proton",
    },
    "Proton-CachyOS": {
        "repo": "CachyOS/proton-cachyos",
        "asset": r"^proton-cachyos-.*-x86_64\.tar\.xz$",
        "match": r"^proton-cachyos",
    },
    "Proton-EM": {
        "repo": "BananaWorks07/Proton",
        "asset": r"^proton-EM-.*\.tar\.xz$",
        "match": r"^proton-EM",
    },
}
RELEASES_URL = "https://api.github.com/repos/%s/releases/latest"
RELEASES_MAX_AGE = 1800
# Direct first, then the environment's proxies and the usual ports of local proxy apps
PROXY_VARS = ("https_proxy", "HTTPS_PROXY", "all_proxy", "ALL_PROXY", "http_proxy", "HTTP_PROXY")
PROXY_PORTS = ("http://127.0.0.1:10808", "http://127.0.0.1:7890", "http://127.0.0.1:2080", "socks5h://127.0.0.1:1080")
# Roughly how much bigger a tool gets when unpacked
UNPACKED_RATIO = 4


class Refused(Exception):
    pass


def read_text(path):
    try:
        with open(path, "rb") as file:
            return file.read().decode("utf-8", "surrogateescape")
    except OSError:
        return ""


def unescape(raw):
    return re.sub(r"\\(.)", r"\1", raw, flags=re.DOTALL)


def escape(value):
    return value.replace("\\", "\\\\").replace('"', '\\"')


class Node:
    def __init__(self, key, start):
        self.key = key
        self.start = start
        self.value = None
        self.span = None
        self.close = None
        self.children = []

    def get(self, *path):
        node = self
        for key in path:
            node = next((child for child in node.children if child.key.lower() == key.lower()), None)
            if node is None:
                return None
        return node

    def string(self, *path):
        node = self.get(*path)
        return node.value if node and node.value is not None else ""

    def children_of(self, *path):
        node = self.get(*path)
        return node.children if node else []


def parse_vdf(text):
    root = Node("", 0)
    stack = [root]
    pending = None
    for match in TOKEN.finditer(text):
        string, brace = match.group(1), match.group(2)
        if string is not None:
            if pending is None:
                pending = Node(unescape(string), match.start())
                stack[-1].children.append(pending)
            else:
                pending.value = unescape(string)
                pending.span = match.span(1)
                pending = None
        elif brace == "{":
            if pending is None:
                raise ValueError("a block with no name")
            stack.append(pending)
            pending = None
        elif brace == "}":
            if pending is not None or len(stack) == 1:
                raise ValueError("unbalanced braces")
            stack.pop().close = match.start()
    if pending is not None or len(stack) != 1:
        raise ValueError("unbalanced braces")
    return root


def load_vdf(path):
    try:
        return parse_vdf(read_text(path))
    except ValueError:
        return Node("", 0)


def insert_at_end(text, block, lines):
    at = text.rfind("\n", 0, block.close) + 1
    return text[:at] + lines + text[at:]


def set_string(text, path, key, value):
    # A missing block on the way is added, then the file is read again for the new positions
    while True:
        node = parse_vdf(text)
        for depth, name in enumerate(path):
            child = node.get(name)
            if child is None:
                if depth == 0:
                    raise ValueError("not the expected file")
                tabs = "\t" * depth
                text = insert_at_end(text, node, '%s"%s"\n%s{\n%s}\n' % (tabs, name, tabs, tabs))
                break
            if child.close is None:
                raise ValueError("%s isn't a block" % name)
            node = child
        else:
            break

    child = node.get(key)
    if child is None:
        return insert_at_end(text, node, '%s"%s"\t\t"%s"\n' % ("\t" * len(path), key, escape(value)))
    if child.span is None:
        raise ValueError("%s isn't a value" % key)
    return text[:child.span[0]] + escape(value) + text[child.span[1]:]


def remove_block(text, path):
    node = parse_vdf(text).get(*path)
    if node is None:
        return text
    start = text.rfind("\n", 0, node.start) + 1
    end = text.find("\n", node.close) + 1
    return text[:start] + text[end or len(text):]


class Mapping(dict):
    def __init__(self):
        super().__init__()
        self.spans = {}
        self.blocks = {}
        self.end = 0


# shortcuts.vdf has a type byte, a key, then a value; its keys differ in case between Steam versions.
# appinfo.vdf is the same, with keys as indexes into `keys`.
def read_binary_vdf(data, pos=0, keys=None):
    def string():
        nonlocal pos
        end = data.index(b"\0", pos)
        value = data[pos:end].decode("utf-8", "replace")
        pos = end + 1
        return value

    def mapping():
        nonlocal pos
        out = Mapping()
        while True:
            start = pos
            kind = data[pos]
            pos += 1
            if kind == 8:
                out.end = start
                return out
            if keys is None:
                key = string().lower()
            else:
                key = keys[struct.unpack_from("<I", data, pos)[0]]
                pos += 4
            if kind == 0:
                out[key] = mapping()
                out.blocks[key] = (start, pos)
            elif kind == 1:
                value_start = pos
                out[key] = string()
                out.spans[key] = (value_start, pos - 1)
            elif kind in (2, 3):
                out[key] = struct.unpack_from("<I", data, pos)[0]
                pos += 4
            elif kind == 7:
                out[key] = struct.unpack_from("<Q", data, pos)[0]
                pos += 8
            else:
                raise ValueError("unknown value type %d" % kind)

    return mapping()


def read_shortcuts(path):
    with open(path, "rb") as file:
        data = file.read()
    return data, read_binary_vdf(data).get("shortcuts", {})


def official_tools(root):
    try:
        with open(os.path.join(root, "appcache/appinfo.vdf"), "rb") as file:
            data = file.read()
        magic, _, table = struct.unpack_from("<IIq", data, 0)
        if magic != APPINFO_MAGIC:
            raise ValueError("unknown appinfo version")
        count = struct.unpack_from("<I", data, table)[0]
        keys = [key.decode("utf-8", "replace") for key in data[table + 4:].split(b"\0")[:count]]
        pos = 16
        while pos + 8 < table:
            app_id, size = struct.unpack_from("<II", data, pos)
            if app_id == COMPAT_APP:
                info = read_binary_vdf(data, pos + APPINFO_ENTRY_HEADER, keys)
                tools = info["appinfo"]["extended"]["compat_tools"]
                return [(name, tool["display_name"], str(tool["appid"])) for name, tool in tools.items()
                        if tool.get("from_oslist") == "windows"]
            if app_id == 0:
                break
            pos += 8 + size
    except (OSError, ValueError, IndexError, KeyError, struct.error):
        pass
    return [("proton_experimental", "Proton Experimental", "1493710")]


def custom_tools(root):
    folders = [
        os.path.join(root, "compatibilitytools.d"),
        "/usr/share/steam/compatibilitytools.d",
        "/usr/local/share/steam/compatibilitytools.d",
    ] + [path for path in os.environ.get("STEAM_EXTRA_COMPAT_TOOLS_PATHS", "").split(":") if path]
    tools = []
    for folder in folders:
        for path in sorted(glob.glob(os.path.join(glob.escape(folder), "*/compatibilitytool.vdf"))):
            for tool in load_vdf(path).children_of("compatibilitytools", "compat_tools"):
                tools.append({
                    "name": tool.key,
                    "label": tool.string("display_name") or tool.key,
                    "path": os.path.dirname(path),
                })
    return tools


def library_paths(root):
    paths = [root]
    for library in load_vdf(os.path.join(root, "steamapps/libraryfolders.vdf")).children_of("libraryfolders"):
        path = library.string("path")
        if path and os.path.realpath(path) not in paths:
            paths.append(os.path.realpath(path))
    return paths


# The account last logged in, or the folder last changed
def config_dir(root):
    users = load_vdf(os.path.join(root, "config/loginusers.vdf")).children_of("users")
    for user in [u for u in users if u.string("MostRecent") == "1"] + users:
        if user.key.isdigit():
            path = os.path.join(root, "userdata", str(int(user.key) & 0xFFFFFFFF), "config")
            if os.path.isdir(path):
                return path
    folders = glob.glob(os.path.join(glob.escape(root), "userdata/*/config"))
    return max(folders, key=os.path.getmtime, default="")


def find_prefix(app_id, libraries):
    for library in libraries:
        path = os.path.join(library, "steamapps/compatdata", app_id)
        if os.path.isdir(os.path.join(path, "pfx")):
            return path
    return ""


# The version that last ran it: "11.0-100" for Valve's, "GE-Proton10-34" for custom ones
def proton_version(prefix):
    version = read_text(os.path.join(prefix, "version")).strip() if prefix else ""
    return "Proton " + version if version[:1].isdigit() else version


def steam_games(library, libraries):
    games = []
    for path in glob.glob(os.path.join(glob.escape(library), "steamapps/appmanifest_*.acf")):
        app_id = re.search(r"appmanifest_(\d+)\.acf$", path)
        manifest = load_vdf(path)
        folder = manifest.string("AppState", "installdir")
        if not app_id or not folder or app_id[1] in TOOLS:
            continue
        install = os.path.join(library, "steamapps/common", folder)
        if os.path.exists(os.path.join(install, "toolmanifest.vdf")):
            continue
        # The game's own library first, as an older prefix can stay behind in another
        prefix = find_prefix(app_id[1], [library] + libraries)
        found = os.path.isdir(install)
        games.append({
            "name": manifest.string("AppState", "name") or app_id[1],
            "id": app_id[1],
            "runId": app_id[1],
            "steam": True,
            "prefix": prefix,
            "install": install if found else "",
            "runnable": found,
        })
    return games


def shortcut_folder(start, exe):
    for path in (start, os.path.dirname(exe)):
        if path and os.path.isdir(path):
            return path
    return ""


def shortcuts(path, libraries):
    games = []
    try:
        entries = read_shortcuts(path)[1]
    except (OSError, ValueError, IndexError, struct.error):
        return games
    for entry in entries.values():
        app_id = str(entry.get("appid") or "")
        exe = entry.get("exe", "").strip('"')
        games.append({
            "name": re.sub(r"\.exe$", "", entry.get("appname", ""), flags=re.IGNORECASE) or app_id,
            "id": app_id,
            # 64 bits, so a string: too long for a JS number
            "runId": str((int(app_id) << 32) | 0x02000000) if app_id else "",
            "steam": False,
            "prefix": find_prefix(app_id, libraries) if app_id else "",
            "install": shortcut_folder(entry.get("startdir", "").strip('"'), exe),
            "runnable": bool(app_id) and (os.path.isfile(exe) or shutil.which(exe) is not None),
            "launch": entry.get("launchoptions", ""),
        })
    return games


def steam_roots():
    home = os.path.expanduser("~")
    roots = []
    for root in ROOTS:
        path = os.path.realpath(os.path.join(home, root))
        if os.path.isdir(path) and path not in roots:
            roots.append(path)
    return roots


def list_games():
    games = {}
    tools = {"": "Default"}
    for root in steam_roots():
        libraries = library_paths(root)
        config = config_dir(root)
        mapping = load_vdf(os.path.join(root, "config/config.vdf")).get("InstallConfigStore", *STEAM_KEYS, "CompatToolMapping")
        apps = load_vdf(os.path.join(config, "localconfig.vdf")).get("UserLocalConfigStore", *STEAM_KEYS, "Apps")
        found = shortcuts(os.path.join(config, "shortcuts.vdf"), libraries)
        for library in libraries:
            found += steam_games(library, libraries)
        for game in found:
            # A shortcut stays, however little is left of it, so it can be removed
            if game["steam"] and not (game["prefix"] or game["install"]):
                continue
            if game["steam"]:
                game["launch"] = apps.string(game["id"], "LaunchOptions") if apps else ""
            game["tool"] = mapping.string(game["id"], "name") if mapping and game["id"] else ""
            game["proton"] = proton_version(game["prefix"])
            game["root"] = root
            games[game["id"] or game["name"]] = game
        for name, label, _ in official_tools(root):
            tools.setdefault(name, label)
        for tool in custom_tools(root):
            tools.setdefault(tool["name"], tool["label"])
    return {
        "games": sorted(games.values(), key=lambda game: game["name"].casefold()),
        "tools": [{"name": name, "label": label} for name, label in tools.items()],
    }


def steam_running():
    return any(read_text(path).strip() == "steam" for path in glob.glob("/proc/[0-9]*/comm"))


def save(path, data):
    path = os.path.realpath(path)
    shutil.copy2(path, path + ".lis-backup")
    temp = path + ".lis-temp"
    with open(temp, "wb") as file:
        file.write(data)
        file.flush()
        os.fsync(file.fileno())
    shutil.copymode(path, temp)
    os.replace(temp, path)


def save_text(path, text):
    save(path, text.encode("utf-8", "surrogateescape"))


def set_launch(game, options):
    config = config_dir(game["root"])
    if game["steam"]:
        path = os.path.join(config, "localconfig.vdf")
        keys = ("UserLocalConfigStore", *STEAM_KEYS, "Apps", game["id"])
        text = set_string(read_text(path), keys, "LaunchOptions", options)
        if parse_vdf(text).string(*keys, "LaunchOptions") != options:
            raise ValueError("the change didn't read back")
        save_text(path, text)
        return
    path = os.path.join(config, "shortcuts.vdf")
    data, entries = read_shortcuts(path)
    entry = next(entry for entry in entries.values() if str(entry.get("appid")) == game["id"])
    encoded = options.encode("utf-8")
    if "launchoptions" in entry.spans:
        start, end = entry.spans["launchoptions"]
        new = data[:start] + encoded + data[end:]
    else:
        new = data[:entry.end] + b"\x01LaunchOptions\0" + encoded + b"\0" + data[entry.end:]
    entries = read_binary_vdf(new).get("shortcuts", {})
    if next(e for e in entries.values() if str(e.get("appid")) == game["id"]).get("launchoptions") != options:
        raise ValueError("the change didn't read back")
    save(path, new)


def set_tool(game, tool):
    path = os.path.join(game["root"], "config/config.vdf")
    keys = ("InstallConfigStore", *STEAM_KEYS, "CompatToolMapping", game["id"])
    text = read_text(path)
    if tool:
        text = set_string(text, keys, "name", tool)
        for key, value in (("config", ""), ("priority", "250")):
            if parse_vdf(text).get(*keys, key) is None:
                text = set_string(text, keys, key, value)
    else:
        text = remove_block(text, keys)
    if parse_vdf(text).string(*keys, "name") != tool:
        raise ValueError("the change didn't read back")
    if text != read_text(path):
        save_text(path, text)


def first_root():
    roots = steam_roots()
    if not roots:
        raise Refused("Steam isn't installed")
    return roots[0]


def find_game(app_id):
    game = next((game for game in list_games()["games"] if game["id"] == app_id), None)
    if game is None:
        raise Refused("Game not found")
    return game


def shortcut_bytes(index, app_id, name, exe, start, options):
    def text(key, value):
        return b"\x01" + key.encode() + b"\0" + value.encode("utf-8") + b"\0"

    def number(key, value):
        return b"\x02" + key.encode() + b"\0" + struct.pack("<I", value)

    return (b"\0" + str(index).encode() + b"\0" + number("appid", app_id) + text("AppName", name)
            + text("Exe", exe) + text("StartDir", start) + text("icon", "") + text("ShortcutPath", "")
            + text("LaunchOptions", options) + number("IsHidden", 0) + number("AllowDesktopConfig", 1)
            + number("AllowOverlay", 1) + number("OpenVR", 0) + number("Devkit", 0) + text("DevkitGameID", "")
            + number("DevkitOverrideAppID", 0) + number("LastPlayTime", 0) + text("FlatpakAppID", "")
            + text("sortas", "") + b"\0tags\0\x08\x08")


def add_game(name, exe, options, tool):
    exe = os.path.abspath(os.path.expanduser(exe))
    if not os.path.isfile(exe):
        raise Refused("File not found")
    name = clean(name).strip() or os.path.splitext(os.path.basename(exe))[0]
    root = first_root()
    config = config_dir(root)
    if not config:
        raise Refused("No Steam account found")
    path = os.path.join(config, "shortcuts.vdf")
    if os.path.exists(path):
        data, entries = read_shortcuts(path)
    else:
        data = b"\0shortcuts\0\x08\x08"
        entries = read_binary_vdf(data)["shortcuts"]
    if not isinstance(entries, Mapping):
        raise ValueError("no shortcuts in the file")

    quoted = '"%s"' % exe
    if any(entry.get("exe", "").strip('"') == exe and entry.get("appname") == name for entry in entries.values()):
        raise Refused("Already added")
    taken = {entry.get("appid") for entry in entries.values()}
    # The same exe and name get the same id, so adding a game back finds its prefix again
    app_id = zlib.crc32((quoted + name).encode("utf-8")) | 0x80000000
    while app_id in taken:
        app_id = ((app_id + 1) & 0xFFFFFFFF) | 0x80000000
    index = max((int(key) for key in entries if key.isdigit()), default=-1) + 1
    entry = shortcut_bytes(index, app_id, name, quoted, os.path.dirname(exe) + "/", clean(options))
    new = data[:entries.end] + entry + data[entries.end:]
    found = read_binary_vdf(new)["shortcuts"].get(str(index), {})
    if found.get("appid") != app_id or found.get("appname") != name:
        raise ValueError("the change didn't read back")
    if os.path.exists(path):
        save(path, new)
    else:
        with open(path, "wb") as file:
            file.write(new)
    if tool:
        set_tool({"root": root, "id": str(app_id)}, clean(tool))


def remove_game(app_id):
    game = find_game(app_id)
    if game["steam"]:
        raise Refused("Steam uninstalls its own games")
    path = os.path.join(config_dir(game["root"]), "shortcuts.vdf")
    data, entries = read_shortcuts(path)
    kept = [key for key, entry in entries.items() if str(entry.get("appid")) != app_id]
    if len(kept) == len(entries):
        raise Refused("Game not found")
    first = min(start for start, _ in entries.blocks.values())
    body = b""
    for index, key in enumerate(kept):
        start, end = entries.blocks[key]
        body += b"\0" + str(index).encode() + b"\0" + data[start + 2 + len(key.encode()):end]
    new = data[:first] + body + data[entries.end:]
    if len(read_binary_vdf(new)["shortcuts"]) != len(kept):
        raise ValueError("the change didn't read back")
    save(path, new)
    set_tool(game, "")


def delete_prefix(app_id):
    prefix = find_game(app_id)["prefix"]
    if not prefix or app_id == "0" or os.path.basename(prefix) != app_id:
        raise Refused("No prefix to delete")
    if os.path.basename(os.path.dirname(prefix)) != "compatdata" or os.path.islink(prefix):
        raise Refused("Not a prefix folder")
    shutil.rmtree(prefix)


def folder_size(path):
    total = 0
    for folder, _, files in os.walk(path):
        for name in files:
            try:
                total += os.lstat(os.path.join(folder, name)).st_size
            except OSError:
                pass
    return total


def source_of(name):
    return next((source for source, info in SOURCES.items() if re.search(info["match"], name)), "")


def list_tools():
    installed = {}
    available = {}
    for root in steam_roots():
        libraries = library_paths(root)
        mapping = load_vdf(os.path.join(root, "config/config.vdf")).get("InstallConfigStore", *STEAM_KEYS, "CompatToolMapping")
        users = {}
        for game in mapping.children if mapping else []:
            if game.key != "0":
                users[game.string("name")] = users.get(game.string("name"), 0) + 1

        for tool in custom_tools(root):
            writable = os.access(os.path.dirname(tool["path"]), os.W_OK)
            installed.setdefault(tool["name"], dict(
                tool, kind="custom" if writable else "system", source=source_of(os.path.basename(tool["path"])),
                appId="", size=folder_size(tool["path"]), users=users.get(tool["name"], 0)))

        for name, label, app_id in official_tools(root):
            folder = ""
            for library in libraries:
                manifest = os.path.join(library, "steamapps/appmanifest_%s.acf" % app_id)
                found = load_vdf(manifest).string("AppState", "installdir")
                if found:
                    folder = os.path.join(library, "steamapps/common", found)
            if folder and os.path.isdir(folder):
                installed.setdefault(name, dict(name=name, label=label, path=folder, kind="steam", source="",
                                                appId=app_id, size=folder_size(folder), users=users.get(name, 0)))
            else:
                available.setdefault(name, dict(name=name, label=label, kind="steam", appId=app_id))
    return {
        "installed": sorted(installed.values(), key=lambda tool: (tool["kind"] == "steam", tool["label"].casefold())),
        "available": [tool for name, tool in available.items() if name not in installed],
    }


def routes():
    found = [None]
    for proxy in [os.environ.get(name) for name in PROXY_VARS] + list(PROXY_PORTS):
        if proxy and proxy not in found:
            found.append(proxy)
    return found


def route_args(route):
    return ["--noproxy", "*"] if route is None else ["--proxy", route]


def fetch_text(url):
    for route in routes():
        result = subprocess.run(["curl", "-fsSL", "--proto", "=http,https", "--connect-timeout", "4", "--max-time", "20",
                                 *route_args(route), "--url", url], capture_output=True)
        if result.returncode == 0:
            return result.stdout.decode("utf-8", "replace")
    raise Refused("Couldn't reach GitHub")


def fetch_release(source):
    info = SOURCES[source]
    data = json.loads(fetch_text(RELEASES_URL % info["repo"]))
    assets = {asset["name"]: asset for asset in data.get("assets", [])}
    name = next((name for name in assets if re.search(info["asset"], name)), None)
    if name is None:
        raise Refused("No download found for " + source)
    stem = re.sub(r"\.tar\.\w+$", "", name)
    checksum = next((stem + end for end in (".sha512sum", ".sha256sum") if stem + end in assets), None)
    if checksum is None:
        raise Refused("No checksum found for " + source)
    return {
        "source": source,
        "label": re.sub(r"-x86_64$", "", stem),
        "asset": name,
        "url": assets[name]["browser_download_url"],
        "size": assets[name]["size"],
        "checksum": assets[checksum]["browser_download_url"],
    }


def cache_dir():
    base = os.environ.get("XDG_CACHE_HOME") or os.path.expanduser("~/.cache")
    path = os.path.join(base, "lis/proton")
    os.makedirs(path, exist_ok=True)
    return path


def list_releases():
    cache = os.path.join(cache_dir(), "releases.json")
    try:
        if time.time() - os.path.getmtime(cache) < RELEASES_MAX_AGE:
            return {"releases": json.loads(read_text(cache)), "error": False}
    except (OSError, ValueError):
        pass
    releases = []
    try:
        for source in SOURCES:
            releases.append(fetch_release(source))
    except (Refused, ValueError, KeyError):
        try:
            return {"releases": json.loads(read_text(cache)), "error": True}
        except ValueError:
            return {"releases": releases, "error": True}
    with open(cache, "w") as file:
        json.dump(releases, file)
    return {"releases": releases, "error": False}


# The running curl or tar, stopped along with this script
child = None


def on_terminate(_signal, _frame):
    if child is not None and child.poll() is None:
        child.terminate()
    sys.exit(130)


def say(*words):
    print(*words, flush=True)


# Slow or blocked: the next route carries on from what's there
def download(url, path, size):
    global child
    done = lambda: os.path.exists(path) and os.path.getsize(path) >= size
    for route in routes():
        # A server that can't carry on (curl's 33) gets a second go from the start
        for _ in range(2):
            if done():
                break
            child = subprocess.Popen(["curl", "-fsSL", "--proto", "=http,https", "--connect-timeout", "5",
                                      "--speed-time", "30", "--speed-limit", "1024", "-C", "-",
                                      *route_args(route), "-o", path, "--url", url], stderr=subprocess.DEVNULL)
            while child.poll() is None:
                time.sleep(0.5)
                if os.path.exists(path):
                    say("download", round(os.path.getsize(path) / size, 3))
            if child.returncode != 33:
                break
            os.remove(path)
    if not os.path.exists(path) or os.path.getsize(path) != size:
        raise Refused("Download failed")


def verify(path, release):
    expected = fetch_text(release["checksum"]).split()[0].lower()
    digest = hashlib.sha512() if release["checksum"].endswith(".sha512sum") else hashlib.sha256()
    with open(path, "rb") as file:
        while chunk := file.read(1 << 20):
            digest.update(chunk)
    if digest.hexdigest() != expected:
        os.remove(path)
        raise Refused("The download was damaged, try again")


def unpack(archive, compat):
    global child
    folder = tempfile.mkdtemp(prefix=".lis-extract-", dir=compat)
    try:
        child = subprocess.Popen(["tar", "-xf", archive, "-C", folder, "--no-same-owner"], stderr=subprocess.DEVNULL)
        if child.wait() != 0:
            raise Refused("Couldn't unpack the download")
        found = os.listdir(folder)
        inner = os.path.join(folder, found[0]) if len(found) == 1 else ""
        tools = load_vdf(os.path.join(inner, "compatibilitytool.vdf")).children_of("compatibilitytools", "compat_tools")
        if not tools or not os.path.isfile(os.path.join(inner, "proton")):
            raise Refused("The download isn't a compatibility tool")
        target = os.path.join(compat, found[0])
        if os.path.lexists(target):
            raise Refused("Already installed")
        os.rename(inner, target)
        return tools[0].key
    finally:
        shutil.rmtree(folder, ignore_errors=True)


def replace_tool(root, old, new):
    path = os.path.join(root, "config/config.vdf")
    keys = ("InstallConfigStore", *STEAM_KEYS, "CompatToolMapping")
    text = read_text(path)
    games = [game.key for game in parse_vdf(text).children_of(*keys) if game.string("name") == old]
    for game in games:
        text = set_string(text, keys + (game,), "name", new)
    if games:
        save_text(path, text)
    delete_tool(old)


def install(source, old=""):
    if source not in SOURCES:
        raise Refused("Unknown source")
    root = first_root()
    if old and steam_running():
        raise Refused("Close Steam first")
    signal.signal(signal.SIGTERM, on_terminate)

    release = fetch_release(source)
    tools = custom_tools(root)
    if any(release["label"] in tool["name"] or release["label"] in os.path.basename(tool["path"]) for tool in tools):
        raise Refused("Already installed")
    compat = os.path.join(root, "compatibilitytools.d")
    os.makedirs(compat, exist_ok=True)
    if shutil.disk_usage(compat).free < release["size"] * UNPACKED_RATIO:
        raise Refused("Not enough disk space")
    for leftover in glob.glob(os.path.join(glob.escape(compat), ".lis-extract-*")):
        shutil.rmtree(leftover, ignore_errors=True)

    # A cancelled download of this version is kept and carries on
    cache = cache_dir()
    archive = os.path.join(cache, release["asset"])
    for name in os.listdir(cache):
        if name not in (release["asset"], "releases.json"):
            os.remove(os.path.join(cache, name))
    say("download", 0)
    download(release["url"], archive, release["size"])
    say("verify")
    verify(archive, release)
    say("extract")
    name = unpack(archive, compat)
    os.remove(archive)

    if old:
        if steam_running():
            say("done", release["label"], "(kept %s: Steam is running)" % old)
            return
        say("switch")
        replace_tool(root, old, name)
    say("done", release["label"])


def delete_tool(name):
    for root in steam_roots():
        for tool in custom_tools(root):
            if tool["name"] == name:
                if not os.access(os.path.dirname(tool["path"]), os.W_OK):
                    raise Refused("A system package installed it")
                if os.path.islink(tool["path"]):
                    os.unlink(tool["path"])
                else:
                    shutil.rmtree(tool["path"])
                return
    raise Refused("Version not found")


def clean(value):
    return re.sub(r"[\0\r\n]", " ", value)


# Name: (function, how many arguments, whether Steam has to be closed)
COMMANDS = {
    "set-launch": (lambda app_id, options: set_launch(find_game(app_id), clean(options)), (2,), True),
    "set-tool": (lambda app_id, tool: set_tool(find_game(app_id), clean(tool)), (2,), True),
    "add-game": (add_game, (4,), True),
    "remove-game": (remove_game, (1,), True),
    "delete-prefix": (delete_prefix, (1,), True),
    "delete-tool": (delete_tool, (1,), True),
    "list-tools": (lambda: print(json.dumps(list_tools())), (0,), False),
    "releases": (lambda: print(json.dumps(list_releases())), (0,), False),
    "install": (install, (1, 2), False),
}


def fail(message):
    print(message, file=sys.stderr)
    sys.exit(1)


def main():
    args = sys.argv[1:]
    if not args:
        print(json.dumps(list_games()))
        return
    command = COMMANDS.get(args[0])
    if command is None or len(args) - 1 not in command[1]:
        fail("Usage: see the top of proton-games.py")
    if command[2] and steam_running():
        fail("Close Steam first")
    try:
        command[0](*args[1:])
    except Refused as error:
        fail(str(error))
    except (OSError, ValueError, IndexError, KeyError, StopIteration, struct.error, subprocess.SubprocessError) as error:
        fail("Couldn't save: %s" % error)


if __name__ == "__main__":
    main()
