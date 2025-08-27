#!/usr/bin/env python3
import socket, time

HOST = '127.0.0.1'
IMAP_PORT = 1993
USER = 'sales@thekpsgroup.com'
PASS = 'x'

def run():
    s = socket.socket()
    s.settimeout(10)
    s.connect((HOST, IMAP_PORT))
    def recv(label):
        try:
            data = s.recv(65536)
            txt = data.decode('utf-8','ignore')
            print(f"{label}:\n{txt}")
            return txt
        except Exception as e:
            print(label, 'recv err:', e)
            return ''
    def send(cmd):
        print('>>', cmd.strip())
        s.sendall((cmd + '\r\n').encode('utf-8'))
    recv('GREETING')
    send(f'a1 LOGIN "{USER}" "{PASS}"')
    time.sleep(1)
    recv('LOGIN')
    send('a2 LIST "" "*"')
    time.sleep(2)
    recv('LIST')
    send('a3 LOGOUT')
    time.sleep(0.5)
    recv('LOGOUT')
    s.close()

if __name__ == '__main__':
    run()
