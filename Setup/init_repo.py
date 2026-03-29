"""
One-time repo initialization after cloning from template.
Sets up git hooks and branch protection.

Usage: python Setup/init_repo.py
"""

import os
import subprocess
import sys

ROOT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def main():
    print("\n  Repo Initialization\n")

    # 1. Configure git hooks
    githooks_dir = os.path.join(ROOT_DIR, ".githooks")
    if os.path.isdir(githooks_dir):
        subprocess.run(["git", "config", "core.hooksPath", ".githooks"], cwd=ROOT_DIR, check=True)
        print("  Git hooks configured (.githooks/).")
    else:
        print("  Warning: .githooks/ not found. Skipping.")

    # 2. Branch protection via GitHub CLI
    try:
        subprocess.run(["gh", "--version"], capture_output=True, check=True)
        print("  Setting up branch protection on main...")
        payload = '''{
  "required_status_checks": {
    "strict": true,
    "contexts": ["lint"]
  },
  "enforce_admins": false,
  "required_pull_request_reviews": {
    "required_approving_review_count": 0
  },
  "restrictions": null
}'''
        subprocess.run(
            ["gh", "api", "-X", "PUT", "repos/{owner}/{repo}/branches/main/protection", "--input", "-"],
            input=payload, text=True, cwd=ROOT_DIR, check=True
        )
        print("  Branch protection enabled.")
    except FileNotFoundError:
        print("  Warning: gh CLI not found. Set up branch protection manually.")
    except subprocess.CalledProcessError as e:
        print(f"  Warning: Branch protection failed: {e}")

    print("\n  Done.\n")


if __name__ == "__main__":
    main()
