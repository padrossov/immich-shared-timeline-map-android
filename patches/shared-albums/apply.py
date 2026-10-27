#!/usr/bin/env python3
"""Apply the ordered patch series to a clean Immich checkout; fail on drift."""
import argparse
import json
from pathlib import Path
import subprocess

parser = argparse.ArgumentParser()
parser.add_argument('source', type=Path)
parser.add_argument('--allow-other-base', action='store_true', help='For an explicit porting attempt only')
args = parser.parse_args()
folder = Path(__file__).resolve().parent
source = args.source.resolve()
manifest = json.loads((folder / 'upstream.json').read_text())

def git(*argv):
    return subprocess.check_output(['git', '-C', str(source), *argv], text=True).strip()

head = git('rev-parse', 'HEAD')
if head != manifest['commit'] and not args.allow_other_base:
    raise SystemExit(f'Wrong upstream: expected {manifest["commit"]}, got {head}')
if git('status', '--porcelain'):
    raise SystemExit('Source checkout must be clean before applying the patch series')
series = [line.strip() for line in (folder / 'series').read_text().splitlines()
          if line.strip() and not line.lstrip().startswith('#')]
if not series:
    raise SystemExit('No feature patches are listed in series')
patches = []
for entry in series:
    patch = (folder / entry).resolve()
    if patch.parent != folder or patch.suffix != '.patch' or not patch.is_file():
        raise SystemExit(f'Invalid patch entry: {entry}')
    patches.append(patch)
for patch in patches:
    git('apply', '--check', str(patch))
    git('apply', str(patch))
    print(f'Applied {patch.name}')
print(f'Applied {len(patches)} patch(es) on {head}')
