Proxmox VM Auto-Start After Backup
🚀 Automatically start Proxmox VMs after backup completion with 6:00 AM timeout

A bash script for Proxmox VE that monitors backup completion and automatically starts a specified VM. If the backup doesn't complete by 6:00 AM, the VM is started anyway to ensure availability.

✨ Features
Smart VM startup: Starts VM only after backup completion
Morning timeout: Ensures VM is running by 6:00 AM regardless of backup status
Duplicate prevention: Prevents multiple startups for the same backup
Comprehensive logging: Detailed logs with timestamps and emojis
Safety checks: Multiple status verifications to prevent errors
Race condition protection: Handles concurrent operations safely
📋 Prerequisites
Proxmox VE environment
Root access required
VM backup configured with vzdump
VM ID must be known
🛠️ Installation
Download the script:
bash
wget https://raw.githubusercontent.com/yourusername/proxmox-vm-autostart/main/start_vm_after_backup.sh
Make it executable:
bash
chmod +x start_vm_after_backup.sh
Move to appropriate location:
bash
mv start_vm_after_backup.sh /usr/local/bin/
⚙️ Configuration
Edit the script configuration section:

bash
# === Configuration ===
VMID=100                          # Your VM ID
LOGFILE="/var/log/start_vm_after_backup_${VMID}.log"
LAST_LOG_FILE="/tmp/last_backup_vm_${VMID}.txt"
VZDUMP_LOG="/var/log/vzdump/qemu-${VMID}.log"
MAX_AGE_SECONDS=3600              # Log age threshold (1 hour)
TIMEOUT_HOUR=6                    # Morning timeout (24-hour format)
Configuration Parameters
Parameter	Description	Default
VMID	Proxmox VM ID to manage	100
TIMEOUT_HOUR	Hour to force VM start (0-23)	6 (6:00 AM)
MAX_AGE_SECONDS	Maximum log age to consider	3600 (1 hour)
🚀 Usage
Manual Execution
bash
sudo /usr/local/bin/start_vm_after_backup.sh
Automated Execution (Recommended)
Add to crontab to run every 5 minutes:

bash
# Edit root crontab
sudo crontab -e

# Add this line
*/5 * * * * /usr/local/bin/start_vm_after_backup.sh >/dev/null 2>&1
Hook Integration
You can also integrate it as a post-backup hook in Proxmox:

bash
# In your backup job configuration
hookscript: local:snippets/post-backup-hook.sh
📊 How It Works
mermaid
flowchart TD
    A[Script Start] --> B{VM Already Running?}
    B -->|Yes| C[Exit - No Action Needed]
    B -->|No| D{Current Time >= 6:00 AM?}
    D -->|Yes| E[Start VM - Timeout Reached]
    D -->|No| F{Backup Log Recent?}
    F -->|No| G[Exit - Log Too Old]
    F -->|Yes| H{Backup Completed?}
    H -->|No| I[Exit - No Completion Found]
    H -->|Yes| J{Already Processed?}
    J -->|Yes| K[Exit - Already Handled]
    J -->|No| L[Start VM - Backup Complete]
    E --> M[Log Success/Failure]
    L --> M
    M --> N[End]
📁 Log Files
The script generates several log files:

Main log: /var/log/start_vm_after_backup_${VMID}.log
Processing tracker: /tmp/last_backup_vm_${VMID}.txt
Vzdump log: /var/log/vzdump/qemu-${VMID}.log
Sample Log Output
[2025-07-13 18:04:58] --------------------------------------------------
[2025-07-13 18:04:58] 🚀 Script started for VM 100
[2025-07-13 18:04:58] 📅 Ultimo backup completato: 2025-07-13 17:45:32
[2025-07-13 18:04:58] 🚀 Avvio della VM 100 in corso...
[2025-07-13 18:04:59] ✅ VM 100 avviata con successo.
[2025-07-13 18:04:59] 📌 Backup marcato come gestito: 2025-07-13 17:45:32
🔧 Troubleshooting
Common Issues
Error: "VM already running"

This is handled automatically by the script's safety checks
No action needed
Error: "Log file not found"

Check if VM ID is correct
Verify backup is configured for the VM
Ensure vzdump is running
VM not starting after backup

Check log file for errors
Verify VM configuration
Ensure sufficient resources
Debug Mode
For detailed debugging, run manually:

bash
sudo bash -x /usr/local/bin/start_vm_after_backup.sh
🔒 Security Considerations
Script requires root privileges
Log files contain system information
Consider log rotation for long-running systems
Review script before execution in production
🤝 Contributing
Fork the repository
Create a feature branch: git checkout -b feature-name
Commit changes: git commit -am 'Add feature'
Push to branch: git push origin feature-name
Submit a Pull Request
📝 License
This project is licensed under the MIT License - see the LICENSE file for details.

🆘 Support
Issues: Report bugs via GitHub Issues
Discussions: Use GitHub Discussions for questions
Wiki: Check the wiki for additional documentation
🙏 Acknowledgments
Proxmox VE community
Contributors and testers
Inspired by enterprise backup automation needs
⚠️ Note: This script includes Italian language log messages. It's designed for Italian-speaking Proxmox administrators but can be easily localized.

🔗 Related Projects:

Proxmox VE Documentation
Proxmox Backup Server
Made with ❤️ for the Proxmox community

