#!/usr/bin/env python3
import socket
import time

def trigger_oauth2_flow():
    try:
        print("🔗 Connecting to IMAP proxy on 127.0.0.1:1993...")
        
        # Create socket and connect
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.settimeout(10)
        s.connect(('127.0.0.1', 1993))
        
        print("✅ Connected to IMAP proxy")
        
        # Read initial greeting
        print("📧 Waiting for server greeting...")
        greeting = s.recv(1024).decode('utf-8', errors='ignore')
        print(f"📧 Server greeting: '{greeting.strip()}'")
        
        # Send LOGIN command to trigger OAuth2 flow
        login_cmd = b'a1 LOGIN "sales@thekpsgroup.com" "x"\r\n'
        print(f"🔐 Sending LOGIN command: '{login_cmd.decode()}'")
        s.send(login_cmd)
        
        # Wait for response
        print("📥 Waiting for server response...")
        time.sleep(3)
        
        # Read response
        response = s.recv(1024).decode('utf-8', errors='ignore')
        print(f"📥 Server response: '{response.strip()}'")
        
        s.close()
        print("✅ Connection closed")
        
        return response
        
    except Exception as e:
        print(f"❌ Error: {e}")
        return None

if __name__ == "__main__":
    print("🚀 Triggering OAuth2 flow for sales@thekpsgroup.com...")
    result = trigger_oauth2_flow()
    
    if result:
        print("\n📋 Next steps:")
        print("1. Check the email proxy logs for the Microsoft sign-in URL")
        print("2. Open the URL in your browser")
        print("3. Complete the authentication")
        print("4. Copy the redirect URL and deliver it to the container")
    else:
        print("\n❌ Failed to trigger OAuth2 flow")
