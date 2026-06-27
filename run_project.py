import os
import shutil
import socket
import subprocess
import sys
from pathlib import Path

import start_mysql

ROOT = Path(__file__).resolve().parent
BACKEND_DIR = ROOT / 'backend'
FLUTTER_DIR = ROOT / 'swappit_flutter'


def resolve_command(command: str) -> str:
    if os.name == 'nt':
        for candidate in [command, f'{command}.cmd', f'{command}.bat', f'{command}.exe', f'{command}.com']:
            resolved = shutil.which(candidate)
            if resolved:
                return resolved
    resolved = shutil.which(command)
    if resolved:
        return resolved
    raise FileNotFoundError(f"{command} executable not found on PATH")


def find_available_port(start_port: int = 3000) -> int:
    port = start_port
    while True:
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
            sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
            try:
                sock.bind(('127.0.0.1', port))
                return port
            except OSError:
                port += 1


def main():
    print('Launching Swappit full stack...')
    print('Root:', ROOT)

    npm_bin = resolve_command('npm')
    flutter_bin = resolve_command('flutter')
    backend_port = 5000
    frontend_port = find_available_port(3000)

    start_mysql.start_mysql()

    if not (BACKEND_DIR / 'node_modules').exists():
        print('Installing backend dependencies...')
        subprocess.run([npm_bin, 'install', '--prefix', str(BACKEND_DIR)], check=True)

    if not (FLUTTER_DIR / '.dart_tool').exists():
        print('Installing Flutter dependencies...')
        subprocess.run([flutter_bin, 'pub', 'get'], cwd=str(FLUTTER_DIR), check=True)

    print('Starting backend...')
    env = os.environ.copy()
    env['PORT'] = str(backend_port)
    subprocess.Popen(
        [npm_bin, 'start'],
        cwd=str(BACKEND_DIR),
        stdout=sys.stdout,
        stderr=sys.stderr,
        shell=False,
        env=env,
    )

    print('Starting Flutter app...')
    subprocess.Popen(
        [flutter_bin, 'run', '-d', 'chrome', f'--web-port={frontend_port}'],
        cwd=str(FLUTTER_DIR),
        stdout=sys.stdout,
        stderr=sys.stderr,
        shell=False,
    )

    print('\nSwappit is starting...')
    print(f'Backend: http://localhost:{backend_port}/health')
    print(f'Frontend: http://localhost:{frontend_port}')
    print('Demo login: use the buttons on the login screen or sign in as alicia@example.com / demo1234')


if __name__ == '__main__':
    main()
