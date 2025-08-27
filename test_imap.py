#!/usr/bin/env python3
import socket
import time

def test_imap_connection():
    try:
        # Connect to IMAP proxy
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.connect(('127.0.0.1', 1993))
        
        # Read initial greeting
        response = s.recv(1024).decode()
        print(f"Initial response: {response}")
        
        # Send LOGIN command
        login_cmd = b'a1 LOGIN "sales@thekpsgroup.com" "x"\r\n'
        s.send(login_cmd)
        
        # Read response
        response = s.recv(1024).decode()
        print(f"Login response: {response}")
        
        s.close()
        return response
        
    except Exception as e:
        print(f"Error: {e}")
        return None

if __name__ == "__main__":
    print("Testing IMAP connection to trigger OAuth2 flow...")
    result = test_imap_connection()
    print(f"Result: {result}")
