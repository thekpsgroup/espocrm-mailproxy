#!/usr/bin/env python3
import socket, time, base64

def run():
    s = socket.socket()
    s.settimeout(10)
    s.connect(('127.0.0.1', 1587))
    def recv():
        try:
            data = s.recv(4096)
            print(data.decode('utf-8','ignore').strip())
        except Exception as e:
            print('recv err:', e)
    def sendln(line: str):
        print('>>', line.strip())
        s.sendall((line + '\r\n').encode('utf-8'))
    recv()
    sendln('EHLO local')
    time.sleep(1); recv()
    user = base64.b64encode(b'sales@thekpsgroup.com').decode('ascii')
    pw = base64.b64encode(b'x').decode('ascii')
    sendln('AUTH LOGIN')
    time.sleep(0.5); recv()
    sendln(user)
    time.sleep(0.5); recv()
    sendln(pw)
    time.sleep(1); recv()
    sendln('QUIT')
    time.sleep(0.3); recv()
    s.close()

if __name__ == '__main__':
    run()
