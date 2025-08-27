#!/bin/bash

# Email OAuth2 Proxy Test Script
# This script provides one-liners for testing the OAuth2 flow

echo "🚀 Email OAuth2 Proxy Test Script"
echo "=================================="

# Function to restart the proxy
restart_proxy() {
    echo "🔄 Restarting mail-proxy..."
    docker compose restart mail-proxy
    echo "✅ Proxy restarted"
}

# Function to test IMAP login and trigger OAuth2 flow
test_imap_login() {
    echo "📧 Testing IMAP login to trigger OAuth2 flow..."
    echo "Command: printf 'a1 LOGIN \"sales@thekpsgroup.com\" \"x\"\r\n' | nc -w 8 -N 127.0.0.1 1993"
    printf 'a1 LOGIN "sales@thekpsgroup.com" "x"\r\n' | nc -w 8 -N 127.0.0.1 1993
    echo ""
    echo "📋 Check the proxy logs for the Microsoft sign-in URL:"
    echo "Command: docker logs espocrm-mail-proxy --tail 20"
}

# Function to check proxy logs
check_logs() {
    echo "📋 Checking proxy logs..."
    docker logs espocrm-mail-proxy --tail 20
}

# Function to extract Microsoft sign-in URL from logs
extract_auth_url() {
    echo "🔗 Extracting Microsoft sign-in URL from logs..."
    docker logs espocrm-mail-proxy 2>&1 | grep "Microsoft Sign-in URL:" | tail -1 | sed 's/.*Microsoft Sign-in URL: //'
}

# Function to test successful IMAP connection
test_successful_imap() {
    echo "✅ Testing successful IMAP connection..."
    echo "Command: printf 'a1 LIST \"\" \"*\"\r\n' | nc -w 8 -N 127.0.0.1 1993"
    printf 'a1 LIST "" "*"\r\n' | nc -w 8 -N 127.0.0.1 1993
}

# Function to test SMTP connection
test_smtp() {
    echo "📤 Testing SMTP connection..."
    echo "Command: printf 'EHLO test\r\n' | nc -w 8 -N 127.0.0.1 1587"
    printf 'EHLO test\r\n' | nc -w 8 -N 127.0.0.1 1587
}

# Function to check token status
check_tokens() {
    echo "🔑 Checking token status..."
    if docker exec espocrm-mail-proxy ls -la /config/tokens/ 2>/dev/null; then
        echo "✅ Tokens directory exists"
        docker exec espocrm-mail-proxy cat /config/tokens/sales@thekpsgroup.com.json 2>/dev/null | jq '.access_token' | head -c 20
        echo "..."
    else
        echo "❌ No tokens found"
    fi
}

# Main menu
while true; do
    echo ""
    echo "Select an option:"
    echo "1) Restart proxy"
    echo "2) Test IMAP login (trigger OAuth2)"
    echo "3) Check proxy logs"
    echo "4) Extract Microsoft sign-in URL"
    echo "5) Test successful IMAP connection"
    echo "6) Test SMTP connection"
    echo "7) Check token status"
    echo "8) Run full OAuth2 flow test"
    echo "9) Exit"
    echo ""
    read -p "Enter your choice (1-9): " choice

    case $choice in
        1)
            restart_proxy
            ;;
        2)
            test_imap_login
            ;;
        3)
            check_logs
            ;;
        4)
            extract_auth_url
            ;;
        5)
            test_successful_imap
            ;;
        6)
            test_smtp
            ;;
        7)
            check_tokens
            ;;
        8)
            echo "🔄 Running full OAuth2 flow test..."
            restart_proxy
            sleep 3
            test_imap_login
            sleep 2
            check_logs
            ;;
        9)
            echo "👋 Goodbye!"
            exit 0
            ;;
        *)
            echo "❌ Invalid option. Please try again."
            ;;
    esac
done
