"""
Prepares src/ for local testing and creates symlinks to r2modman profile.
Copies icon.png, LICENSE into src/, generates manifest.json, and symlinks.

Usage: python Setup/deploy_local.py [--overwrite] [--profile NAME]
"""

import os
import sys
import re
import json
import shutil
import argparse
import platform

SETUP_DIR = os.path.dirname(os.path.abspath(__file__))
ROOT_DIR = os.path.dirname(SETUP_DIR)
DEFAULT_PROFILE = "h2-dev"


def get_profile_path(profile_name):
    if platform.system() == "Windows":
        appdata = os.environ.get("APPDATA")
        return os.path.join(appdata, "r2modmanPlus-local", "HadesII", "profiles", profile_name, "ReturnOfModding")
    else:
        return os.path.expanduser(f"~/.config/r2modmanPlus-local/HadesII/profiles/{profile_name}/ReturnOfModding")


def parse_toml(toml_path):
    with open(toml_path, "r", encoding="utf-8") as f:
        lines = f.readlines()

    namespace = name = description = version = website_url = ""
    dependencies = []
    current_section = ""

    for line in lines:
        stripped = line.strip()
        if stripped.startswith("["):
            current_section = stripped.strip("[]").strip()
            continue
        if not stripped or stripped.startswith("#"):
            continue

        match = re.match(r'^(\S+)\s*=\s*(.+)$', stripped)
        if not match:
            continue

        key = match.group(1)
        raw_value = match.group(2).strip()
        value = raw_value[1:-1] if raw_value.startswith('"') and raw_value.endswith('"') else raw_value

        if current_section == "package":
            if key == "namespace": namespace = value
            elif key == "name": name = value
            elif key == "description": description = value
            elif key == "versionNumber": version = value
            elif key == "websiteUrl": website_url = value
        elif current_section == "package.dependencies":
            dependencies.append(f"{key}-{value}")

    return {
        "namespace": namespace, "name": name, "description": description,
        "version_number": version, "dependencies": dependencies,
        "website_url": website_url, "FullName": f"{namespace}-{name}",
    }


def create_link(target, link_path, overwrite):
    abs_target = os.path.abspath(target)
    abs_link = os.path.abspath(link_path)

    if not os.path.isdir(abs_target):
        return

    if os.path.exists(abs_link) or os.path.lexists(abs_link):
        if not overwrite:
            print(f"    SKIP link (exists): {abs_link}")
            return
        if os.path.islink(abs_link):
            os.remove(abs_link)

    os.makedirs(os.path.dirname(abs_link), exist_ok=True)
    os.symlink(abs_target, abs_link, target_is_directory=True)
    print(f"    LINKED: {abs_link}")


def main():
    parser = argparse.ArgumentParser(description="Local deployment: assets, manifest, symlinks")
    parser.add_argument("--overwrite", action="store_true", help="Overwrite existing files/links (default: skip)")
    parser.add_argument("--profile", default=DEFAULT_PROFILE, help=f"r2modman profile name (default: {DEFAULT_PROFILE})")
    args = parser.parse_args()

    toml_path = os.path.join(ROOT_DIR, "thunderstore.toml")
    src_dir = os.path.join(ROOT_DIR, "src")
    data_dir = os.path.join(ROOT_DIR, "data")

    if not os.path.isfile(toml_path):
        print("ERROR: thunderstore.toml not found in project root.")
        sys.exit(1)

    info = parse_toml(toml_path)
    mod_name = f"{info['namespace']}-{info['name']}"

    print(f"\n  Local Deployment: {mod_name}")
    print(f"  Profile: {args.profile}")
    print(f"  Overwrite: {args.overwrite}\n")

    # 1. Copy assets into src/
    for asset in ["icon.png", "LICENSE"]:
        source = os.path.join(ROOT_DIR, asset)
        dest = os.path.join(src_dir, asset)
        if not os.path.exists(source):
            print(f"  WARNING: {asset} not found in project root.")
            continue
        if os.path.exists(dest) and not args.overwrite:
            print(f"  SKIP asset (exists): {asset}")
            continue
        shutil.copy2(source, dest)
        print(f"  COPIED: {asset} -> src/")

    # 2. Generate manifest.json
    manifest_path = os.path.join(src_dir, "manifest.json")
    if os.path.exists(manifest_path) and not args.overwrite:
        print(f"  SKIP manifest (exists)")
    else:
        with open(manifest_path, "w", encoding="utf-8", newline="\n") as f:
            json.dump(info, f, indent=2)
            f.write("\n")
        print(f"  GENERATED: manifest.json")

    # 3. Create symlinks
    profile_path = get_profile_path(args.profile)
    print()
    create_link(src_dir, os.path.join(profile_path, "plugins", mod_name), args.overwrite)
    create_link(data_dir, os.path.join(profile_path, "plugins_data", mod_name), args.overwrite)

    print(f"\n  Done.\n")


if __name__ == "__main__":
    main()
