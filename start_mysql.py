import os
import shutil
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parent


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


def is_mysql_running(port: int = 3306) -> bool:
    import socket
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
        sock.settimeout(1)
        return sock.connect_ex(('127.0.0.1', port)) == 0


def start_mysql() -> bool:
    print('Ensuring MySQL is running...')

    if is_mysql_running():
        print('MySQL is already running.')
        return True

    candidates = []
    if os.name == 'nt':
        candidates.extend([
            'mysqld',
            'mysqld.exe',
            r'C:\Program Files\MySQL\MySQL Server 8.0\bin\mysqld.exe',
            r'C:\Program Files\MySQL\MySQL Server 8.0\bin\mysqld',
            r'C:\Program Files\MariaDB 11.4\bin\mysqld.exe',
            r'C:\Program Files\MariaDB 10.11\bin\mysqld.exe',
        ])

    for candidate in candidates:
        resolved = candidate if os.path.isabs(candidate) else resolve_command(candidate) if shutil.which(candidate) else None
        if resolved:
            try:
                subprocess.Popen([resolved], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, creationflags=subprocess.CREATE_NEW_PROCESS_GROUP if os.name == 'nt' else 0)
                for _ in range(30):
                    if is_mysql_running():
                        print('MySQL started successfully.')
                        return True
                    time.sleep(1)
            except Exception as exc:
                print(f'Failed to start MySQL with {resolved}: {exc}')

    print('MySQL startup command was not available. Please make sure MySQL is installed and configured.')
    return False


if __name__ == '__main__':
    start_mysql()
