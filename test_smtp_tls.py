#!/usr/bin/env python3
import socket, ssl, time, base64

def run():
    s = socket.socket()
    s.settimeout(10)
    s.connect(('127.0.0.1', 1587))
    def recv(label=''): 
        try:
            data = s.recv(4096)
            txt = data.decode('utf-8','ignore')
            print((label+txt).strip())
            return txt
        except Exception as e:
            print('recv err:', e)
            return ''
    def sendln(line: str):
        print('>>', line.strip())
        s.sendall((line + '\r\n').encode('utf-8'))
    # Banner
    recv()
    sendln('EHLO local')
    time.sleep(1); recv()
    # STARTTLS
    sendln('STARTTLS')
    time.sleep(0.5); rsp = recv()
    # Upgrade to TLS
    ctx = ssl.create_default_context()
    s = ctx.wrap_socket(s, server_hostname='smtp.office365.com')
    # Re-EHLO after TLS
    def recv_tls():
        try:
            data = s.recv(4096)
            txt = data.decode('utf-8','ignore')
            print(txt.strip());
            return txt
        except Exception as e:
            print('recv err:', e); return ''
    def sendln_tls(line: str):
        print('>>', line.strip())
        s.sendall((line + '\r\n').encode('utf-8'))
    sendln_tls('EHLO local')
    time.sleep(1); recv_tls()
    # Build one-line AUTH LOGIN to trigger proxy
    ub = base64.b64encode(b'sales@thekpsgroup.com').decode('ascii')
    pb = base64.b64encode(b'x').decode('ascii')
    sendln_tls(f'AUTH LOGIN {ub} {pb}')
    time.sleep(1); recv_tls()
    sendln_tls('QUIT')
    time.sleep(0.2); recv_tls()

if __name__ == '__main__':
    run()
