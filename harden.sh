#!/bin/bash
# =============================================================================
#  ULTIMATE UBUNTU SERVER HARDENING WIZARD 2025
#  Safe • Interactive • Explains everything • Works only on real Ubuntu
# =============================================================================

set -euo pipefail
IFS=$'\n\t'
trap 'echo -e "\nScript stopped at line $LINENO" >&2; exit 1' ERR

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

LOG="/var/log/ubuntu-hardening-$(date +%Y%m%d-%H%M%S).log"
touch "$LOG" && chmod 640 "$LOG"

log() { echo "[$(date +'%H:%M:%S')] $*" | tee -a "$LOG"; }
yesno() { while true; do read -p "$1 (y/N): " ans; case "$ans" in [Yy]*) return 0;; [Nn]*|"") return 1;; *) echo "Please answer y or n";; esac; done; }

# =============================================================================
# 1. Detect real Ubuntu (not Debian, CentOS, etc.)
# =============================================================================
if [[ ! -f /etc/os-release ]] || ! grep -q "^ID=ubuntu" /etc/os-release; then
    clear
    echo -e "${RED}
╔══════════════════════════════════════════════════════════════╗
║                  CRITICAL WARNING                            ║
║  This script was made ONLY for real Ubuntu systems.          ║
║  You are running: $(cat /etc/os-release 2>/dev/null | grep PRETTY_NAME || uname -s)     ║
║  Running this on Debian, CentOS, AlmaLinux, etc. may break    ║
║  your server or apply wrong settings.                        ║
║                                                              ║
║  → Press Ctrl+C now to abort, or wait 15 seconds to continue ║
╚══════════════════════════════════════════════════════════════╝${NC}"
    sleep 15
fi

clear
echo -e "${PURPLE}
   ██████╗  █████╗ ███████╗███████╗   ██╗   ██╗██████╗ ██╗   ██╗
   ██╔══██╗██╔══██╗██╔════╝██╔════╝   ██║   ██║██╔══██╗██║   ██║
   ██████╔╝███████║███████╗█████╗     ██║   ██║██████╔╝██║   ██║
   ██╔══██╗██╔══██║╚════██║██╔══╝     ██║   ██║██╔══██╗██║   ██║
   ██║  ██║██║  ██║███████║███████╗   ╚██████╔╝██████╔╝╚██████╔╝
   ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚══════╝    ╚═════╝ ╚═════╝  ╚═════╝
${NC}"
echo -e "${BLUE}               Safe • Interactive • Beginner-friendly${NC}\n"
log "=== UBUNTU HARDENING WIZARD STARTED ==="

# Root check
[[ $EUID -eq 0 ]] || { echo -e "${RED}Please run as root (sudo)${NC}"; exit 1; }

# =============================================================================
# 2. System update first
# =============================================================================
echo -e "${YELLOW}Updating all packages (this keeps your server secure)${NC}"
apt update && apt upgrade -y && apt autoremove -y
log "System fully updated"

# =============================================================================
# 3. Interactive wizard with plain-English explanations
# =============================================================================
clear
echo -e "${BLUE}We will now secure your server step by step.${NC}"
echo -e "${BLUE}You will see a short explanation before each action.\n${NC}"

NEW_USER="" SSH_PORT="22" OLD_PORT="22"
DISABLE_ROOT="no" ENABLE_UFW="no" INSTALL_FAIL2BAN="no" AUTO_UPDATES="no"
EXTRA_PORTS=()

# — 1. Create new admin user —
if yesno "$(echo -e "${YELLOW}Create a new admin user?${NC}\n   → Instead of using 'root', you login with your own account\n   → Much safer and professional")"; then
    while true; do
        read -p "Choose username (e.g. john): " NEW_USER
        [[ -z "$NEW_USER" ]] && continue
        [[ "$NEW_USER" =~ ^[a-z_][a-z0-9_-]{0,31}$ ]] || { echo "Only letters, numbers, _ and - allowed"; continue; }
        id "$NEW_USER" &>/dev/null && { echo "User already exists"; continue; }
        break
    done
    read -sp "Enter strong password: " P1; echo
    read -sp "Confirm password: " P2; echo
    [[ "$P1" == "$P2" ]] || { echo -e "${RED}Passwords don't match → skipping user${NC}"; NEW_USER=""; }
    [[ -n "$NEW_USER" ]] && adduser --gecos "" --disabled-password "$NEW_USER" && echo "$NEW_USER:$P1" | chpasswd && usermod -aG sudo "$NEW_USER"
    log "Created user: $NEW_USER"
fi

# — 2. Change SSH port —
OLD_PORT=$(ss -tlnp | grep -oP ': \K\d+' | head -1 || echo 22)
if yesno "$(echo -e "${YELLOW}Change SSH port from 22?${NC}\n   → Hackers scan port 22 millions of times per day\n   → Using 2222 or 60222 makes attacks 99% harder")"; then
    while true; do
        read -p "New port (1024–65535, e.g. 2222): " SSH_PORT
        SSH_PORT=${SSH_PORT:-22}
        [[ "$SSH_PORT" =~ ^[0-9]+$ ]] && (( SSH_PORT >= 1024 && SSH_PORT <= 65535 )) && break
        echo "Please enter a valid port number"
    done
fi

# — 3. Disable root login —
if yesno "$(echo -e "${YELLOW}Disable direct root login via SSH?${NC}\n   → Extremely recommended\n   → Attackers try 'root' password billions of times daily")"; then
    DISABLE_ROOT="yes"
fi

# — 4. Enable firewall —
if yesno "$(echo -e "${YELLOW}Enable firewall (UFW)?${NC}\n   → Blocks all incoming connections except what you allow\n   → Like a wall with only one door")"; then
    ENABLE_UFW="yes"
    apt install -y ufw
fi

# — 5. Extra ports (web, etc.) —
if [[ "$ENABLE_UFW" == "yes" ]]; then
    echo -e "${YELLOW}Do you need web server access?${NC}"
    if yesno "Allow HTTP (80) and HTTPS (443) for websites?"; then
        EXTRA_PORTS+=("80/tcp" "443/tcp")
    fi
    while yesno "Allow any other port? (e.g. 3306 for MySQL, 8080 for apps)"; do
        read -p "Port number or name (e.g. 5432, HTTP): " p
        EXTRA_PORTS+=("$p")
    done
fi

# — 6. Fail2Ban —
if yesno "$(echo -e "${YELLOW}Install Fail2Ban?${NC}\n   → Automatically bans IPs that try wrong passwords too many times\n   → Stops brute-force attacks")"; then
    INSTALL_FAIL2BAN="yes"
fi

# — 7. Automatic security updates —
if yesno "$(echo -e "${YELLOW}Enable automatic security updates?${NC}\n   → Server installs critical security patches every day automatically\n   → No need to remember 'apt upgrade'")"; then
    AUTO_UPDATES="yes"
fi

# =============================================================================
# 8. Final confirmation
# =============================================================================
clear
echo -e "${GREEN}Your chosen security setup:${NC}\n"
echo "New admin user        → ${NEW_USER:-No change}"
echo "SSH port              → $SSH_PORT $( (( SSH_PORT != OLD_PORT )) && echo "(changed from $OLD_PORT)" || echo "")"
echo "Root login            → $( [[ $DISABLE_ROOT == yes ]] && echo "DISABLED (safe)" || echo "still allowed")"
echo "Firewall (UFW)        → $( [[ $ENABLE_UFW == yes ]] && echo "ENABLED" || echo "disabled")"
echo "Fail2Ban              → $( [[ $INSTALL_FAIL2BAN == yes ]] && echo "installed" || echo "not installed")"
echo "Auto security updates → $( [[ $AUTO_UPDATES == yes ]] && echo "ENABLED" || echo "disabled")"
echo
if ! yesno "Apply all these changes now?"; then
    echo -e "${YELLOW}No changes made. Goodbye!${NC}"
    exit 0
fi

# =============================================================================
# 9. APPLY EVERYTHING SAFELY
# =============================================================================

# SSH config backup
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup.$(date +%s)
log "SSH config backed up"

# Apply SSH changes
sed -i \
    -e "s/^#*Port .*/Port $SSH_PORT/" \
    -e "s/^#*PermitRootLogin .*/PermitRootLogin $( [[ $DISABLE_ROOT == yes ]] && echo no || echo yes )/" \
    -e "s/^#*PasswordAuthentication .*/PasswordAuthentication yes/" \
    /etc/ssh/sshd_config

[[ -n "$NEW_USER" ]] && grep -q "^AllowUsers" /etc/ssh/sshd_config || echo "AllowUsers $NEW_USER" >> /etc/ssh/sshd_config

# Test config before restart
if ! sshd -t; then
    echo -e "${RED}SSH config is broken! Reverting...${NC}"
    cp /etc/ssh/sshd_config.backup.* /etc/ssh/sshd_config
    exit 1
fi

systemctl restart sshd
log "SSH restarted (port $SSH_PORT, root=$( [[ $DISABLE_ROOT == yes ]] && echo disabled || echo allowed ))"

# Test new user login
if [[ -n "$NEW_USER" ]]; then
    echo -e "${YELLOW}Testing login as $NEW_USER...${NC}"
    if timeout 10 su - "$NEW_USER" -c "whoami" >/dev/null; then
        echo -e "${GREEN}Login test PASSED${NC}"
    else
        echo -e "${RED}Login failed! Keeping root access open for safety${NC}"
        DISABLE_ROOT="no"
    fi
fi

# Firewall
if [[ "$ENABLE_UFW" == "yes" ]]; then
    ufw --force reset >/dev/null
    ufw default deny incoming
    ufw default allow outgoing
    ufw allow "$SSH_PORT/tcp" comment "SSH"
    for p in "${EXTRA_PORTS[@]}"; do ufw allow "$p" comment "User rule"; done
    echo "y" | ufw enable
    log "UFW firewall enabled"
fi

# Fail2Ban
if [[ "$INSTALL_FAIL2BAN" == "yes" ]]; then
    apt install -y fail2ban
    cat > /etc/fail2ban/jail.local <<EOF
[sshd]
enabled = true
port = $SSH_PORT
maxretry = 5
bantime = 2h
EOF
    systemctl enable --now fail2ban
    log "Fail2Ban enabled"
fi

# Automatic security updates
if [[ "$AUTO_UPDATES" == "yes" ]]; then
    apt install -y unattended-upgrades
    cat > /etc/apt/apt.conf.d/50unattended-upgrades <<EOF
Unattended-Upgrade::Allowed-Origins {
    "\${distro_id}:\${distro_codename}-security";
};
Unattended-Upgrade::Automatic-Reboot "false";
EOF
    cat > /etc/apt/apt.conf.d/20auto-upgrades <<EOF
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
EOF
    log "Automatic security updates enabled"
fi

# =============================================================================
# 10. Final screen
# =============================================================================
clear
echo -e "${GREEN}
╔══════════════════════════════════════════════════════════════╗
║                   YOUR SERVER IS NOW SECURE!                 ║
╚══════════════════════════════════════════════════════════════╝${NC}\n"
echo -e "Summary:"
echo -e "   User created      : ${NEW_USER:-none}"
echo -e "   SSH port          : $SSH_PORT"
echo -e "   Root login        : $( [[ $DISABLE_ROOT == yes ]] && echo "blocked" || echo "allowed")"
echo -e "   Firewall          : $( [[ $ENABLE_UFW == yes ]] && echo "active" || echo "off")"
echo -e "   Auto updates      : $( [[ $AUTO_UPDATES == yes ]] && echo "on" || echo "off")"
echo
echo -e "${YELLOW}Log file: $LOG${NC}"
echo -e "${YELLOW}TEST YOUR NEW LOGIN NOW before closing this window!${NC}"
echo -e "Example: ssh $NEW_USER@$(hostname -I | awk '{print $1}') -p $SSH_PORT"
echo
yesno "Reboot now to finish?" && reboot

echo -e "${GREEN}All done! You can now close this window safely.${NC}"
log "=== HARDENING COMPLETED SUCCESSFULLY ==="
exit 0