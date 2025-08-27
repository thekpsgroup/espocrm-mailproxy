#!/usr/bin/env python3
import socket
import time

def test_imap():
    try:
        print("Testing IMAP connection from inside container...")
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.settimeout(5)
        s.connect(('127.0.0.1', 1993))
        print("Connected to IMAP proxy")
        
        greeting = s.recv(1024).decode('utf-8', errors='ignore')
        print(f"Greeting: '{greeting.strip()}'")
        
        login_cmd = b'a1 LOGIN "sales@thekpsgroup.com" "x"\r\n'
        s.send(login_cmd)
        print("Sent LOGIN command")
        
        time.sleep(2)
        response = s.recv(1024).decode('utf-8', errors='ignore')
        print(f"Response: '{response.strip()}'")
        
        s.close()
        print("Test completed")
        
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    test_imap()
