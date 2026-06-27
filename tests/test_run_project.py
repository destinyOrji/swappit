import unittest
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import run_project


class ResolveCommandTests(unittest.TestCase):
    def test_resolve_command_prefers_windows_batch_files(self):
        resolved = run_project.resolve_command('npm')
        self.assertTrue(resolved)
        self.assertTrue(resolved.lower().endswith(('.cmd', '.bat', '.exe', '.com')) or Path(resolved).name.lower() == 'npm')


if __name__ == '__main__':
    unittest.main()
