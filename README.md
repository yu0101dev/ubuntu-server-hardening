# Ubuntu Server Hardening Wizard

**Turns a fresh Ubuntu server into a **secure, production-ready machine** in minutes , even if you're not a Linux expert.**

[![Ubuntu](https://img.shields.io/badge/Ubuntu-20.04%20%7C%2022.04%20%7C%2024.04%2B-E95420?logo=ubuntu&logoColor=white)](https://ubuntu.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Safe](https://img.shields.io/badge/Safety-No%20Lockouts%20Guaranteed-success)](https://github.com/yourusername/ubuntu-server-hardening)

> Zero risk of SSH lockout • Full backups • Interactive explanations • Works on 1 or 1000 servers



This script is designed to be the `First layer` in securing a new server. While it provides a solid foundation, additional hardening steps (e.g., disabling SSH password authentication and adding SSH keys) should be implemented to further strengthen the server's security.



---
## 🛡️ Features

| Feature | Description |
|---------|-------------|
| **Ubuntu-only detection** | Stops with warning on Debian, CentOS, etc. |
| **Full system update first** | Runs `apt upgrade` before any changes |
| **Interactive wizard** | Explains every step in plain English |
| **Safe user creation** | Optional sudo user with password confirmation |
| **SSH hardening** | Change port, disable root login, password auth kept safe |
| **Zero lockout protection** | Tests new user login before applying changes |
| **Full backups** | `sshd_config`, UFW rules, and more — timestamped |
| **UFW firewall setup** | Blocks everything except SSH + your allowed ports |
| **Fail2Ban installation** | Auto-bans brute-force attackers |
| **Automatic security updates** | `unattended-upgrades` enabled — patches applied daily without reboot |
| **Detailed logging** | Full audit trail in `/var/log/ubuntu-hardening-*.log` |
| **Reboot optional** | You decide when (or if) to reboot |

---
## 🚀 Quick Start

### One-Command Installation

```
curl -fsSL https://raw.githubusercontent.com/yu0101dev/ubuntu-server-hardening/main/harden.sh -o harden.sh && \
chmod +x harden.sh && \
sudo ./harden.sh
```

---
## ❓ What the Script Asks You

| Question | Why It's Important |
|----------|-------------------|
| **Create a new admin user?** | Instead of using 'root', login with your own secure account |
| **Change SSH port from 22?** | Hackers attack port 22 millions of times daily |
| **Disable direct root login via SSH?** | EXTREMELY recommended — stops 99% of automated attacks |
| **Enable firewall (UFW)?** | Blocks all incoming traffic except what you allow |
| **Allow web ports (80/443)?** | Only if you're hosting a website |
| **Install Fail2Ban?** | Automatically bans IPs that try wrong passwords |
| **Enable automatic security updates?** | Critical patches installed daily — no manual work needed |

---
## 🔒 Safety First — No Lockouts Ever

- **SSH config is tested** with `sshd -t` before restart
- **If invalid → automatically restores backup**
- **New user login tested** with `su - user`
- **If user can't log in → root access is re-enabled automatically**
- **All backups saved:** `/etc/ssh/sshd_config.backup.*`

---
## 📋 Example Final Summary

```
========================================
     SERVER HARDENING COMPLETE!
========================================

✓ New admin user        : john
✓ SSH port              : 2222
✓ Root login            : disabled
✓ Firewall (UFW)        : active
✓ Fail2Ban              : installed
✓ Auto security updates : enabled

📁 Log file: /var/log/ubuntu-hardening-20251204-142305.log
📋 Backup folder: /root/backup-hardening-20251204-142305/

⚠️ IMPORTANT: Test your new SSH access NOW:
  ssh john@your-server-ip -p 2222

If connection fails, use server console to restore:
  sudo cp /etc/ssh/sshd_config.backup.* /etc/ssh/sshd_config
  sudo systemctl restart sshd
```

---
## 🛠️ Troubleshooting

| Problem | Solution |
|---------|----------|
| **Can't SSH after running** | Use console → restore backup: `sudo cp /etc/ssh/sshd_config.backup.* /etc/ssh/sshd_config && sudo systemctl restart sshd` |
| **Firewall blocked a port** | `sudo ufw status` → `sudo ufw allow 80` etc. |
| **New user has no sudo** | `sudo usermod -aG sudo username` |
| **Script stops on non-Ubuntu** | This script only works on Ubuntu 20.04/22.04/24.04+ |
| **Fail2Ban not working** | Check logs: `sudo fail2ban-client status sshd` |



---
## 🤝 Contributing

1. Fork the repo
2. Create your feature branch: `git checkout -b feature/amazing`
3. Commit your changes: `git commit -am 'Add amazing feature'`
4. Push to the branch: `git push origin feature/amazing`
5. Open a Pull Request

**Guidelines:**
- Keep it Ubuntu-only
- Never risk SSH lockouts
- Always create backups
- Explain changes in plain English


---
**Remember:** Always test in a staging environment first. While this script is designed to be safe, every server setup is unique.

---
## 📥 Download Complete Package

### **Option 1: Download via Git**
```
git clone https://github.com/yu0101dev/ubuntu-server-hardening.git
cd ubuntu-server-hardening
```

### **Option 2: Download ZIP**
1. Click the green **"Code"** button
2. Select **"Download ZIP"**
3. Extract and run: `sudo bash harden.sh`

### **Option 3: Just the script**
```
# Download only the hardening script
curl -fsSL https://raw.githubusercontent.com/yu0101dev/ubuntu-server-hardening/main/harden.sh -o harden.sh
chmod +x harden.sh
sudo ./harden.sh
```
