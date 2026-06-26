import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
BACKEND_DIR = ROOT / 'backend'
FLUTTER_DIR = ROOT / 'swappit_flutter'


def main():
    print('Launching Swappit full stack...')
    print('Root:', ROOT)

    if not (BACKEND_DIR / 'node_modules').exists():
        print('Installing backend dependencies...')
        subprocess.run(['npm', 'install', '--prefix', str(BACKEND_DIR)], check=True)

    if not (FLUTTER_DIR / '.dart_tool').exists():
        print('Installing Flutter dependencies...')
        subprocess.run(['flutter', 'pub', 'get'], cwd=str(FLUTTER_DIR), check=True)

    print('Starting backend...')
    subprocess.Popen(
        ['npm', 'start'],
        cwd=str(BACKEND_DIR),
        stdout=sys.stdout,
        stderr=sys.stderr,
        shell=False,
    )

    print('Starting Flutter app...')
    flutter_bin = shutil.which('flutter')
    if not flutter_bin:
        raise FileNotFoundError('Flutter executable not found on PATH')

    subprocess.Popen(
        [flutter_bin, 'run', '-d', 'chrome', '--web-port=3000'],
        cwd=str(FLUTTER_DIR),
        stdout=sys.stdout,
        stderr=sys.stderr,
        shell=False,
    )

    print('\nSwappit is starting...')
    print('Backend: http://localhost:5000/health')
    print('Frontend: http://localhost:3000')
    print('Demo login: use the buttons on the login screen or sign in as alicia@example.com / demo1234')


if __name__ == '__main__':
    main()
