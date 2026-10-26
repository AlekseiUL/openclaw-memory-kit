"""No real data: all cases are dry-runs in a synthetic HOME."""
import datetime
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

SCRIPT = Path(__file__).resolve().parents[1] / 'scripts/archive-old-notes.sh'


class ArchiveTests(unittest.TestCase):
    def run_case(self, files, expected, flavor='native'):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp); memory = root/'workspace/memory'; memory.mkdir(parents=True)
            for name in files:
                p = memory/name; p.parent.mkdir(parents=True, exist_ok=True); p.write_text('synthetic fixture\n')
            env = dict(os.environ, HOME=str(root), OPENCLAW_WORKSPACE=str(memory.parent),
                       OPENCLAW_LOG_DIR=str(root/'logs'), OPENCLAW_TMP_LOG_DIR=str(root/'tmp-logs'),
                       OPENCLAW_SQLITE_DB=str(root/'missing.sqlite'))
            if flavor != 'native':
                binary = root/'bin'; binary.mkdir()
                # Exercise both branches without requiring GNU date on macOS or BSD date on Linux.
                mock = binary/'date'
                mock.write_text('#!/bin/sh\n' + (
                    'case "$1" in -v-1d) echo 2026;; -v-14d) echo 2026-01-17;; -v-90d) echo 2025-11-02;; -d) exit 1;; *) echo 00:00:00;; esac\n'
                    if flavor == 'bsd' else
                    'case "$1" in -v*) exit 1;; -d) case "$2" in "14 days ago") echo 2026-01-17;; "90 days ago") echo 2025-11-02;; *) exit 2;; esac;; *) echo 00:00:00;; esac\n'))
                mock.chmod(0o755); env['PATH'] = str(binary)+os.pathsep+env['PATH']
            before = {str(p.relative_to(memory)):p.read_bytes() for p in memory.rglob('*') if p.is_file()}
            result = subprocess.run(['bash', str(SCRIPT)], env=env, text=True, capture_output=True)
            self.assertEqual(result.returncode, 0, result.stdout+result.stderr)
            self.assertIn(expected, result.stdout)
            self.assertEqual(before, {str(p.relative_to(memory)):p.read_bytes() for p in memory.rglob('*') if p.is_file()})

    def test_empty(self): self.run_case([], 'archived=0 deleted=0')
    def test_archive_only(self): self.run_case(['archive/daily/2000-01-01.md'], 'archived=0 deleted=1')
    def test_fresh(self): self.run_case([datetime.date.today().isoformat()+'.md'], 'archived=0 deleted=0')
    def test_expired(self): self.run_case(['2000-01-01.md'], 'archived=0 deleted=1')
    def test_bsd_and_gnu_dates(self):
        for flavor in ('bsd', 'gnu'):
            with self.subTest(flavor=flavor):
                self.run_case(['2026-01-01.md', '2026-01-30.md', 'archive/daily/2000-01-01.md'], 'archived=1 deleted=1', flavor)


if __name__ == '__main__': unittest.main()
