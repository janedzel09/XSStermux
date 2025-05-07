# 1. Core System Packages
pkg update && pkg upgrade
pkg install python python-pip curl jq termux-tools proot util-linux coreutils

# 2. Python Requirements
pip install --user flask pyngrok requests cryptography watchdog

# 3. Database Setup
mkdir -p /data/data/com.termux/files/usr/var/xss_db
touch /data/data/com.termux/files/usr/var/xss_db/live_cookies.log

# 4. Termux-Specific Fixes
termux-setup-storage
yes | pip uninstall werkzeug
pip install --user werkzeug==2.3.0  # Downgrade for Flask compatibility

# 5. Optional Monitoring Tools
pkg install termux-api termux-exec
pip install --user pyopenssl

# 6. Verify Installation
python3 -c "import flask, pyngrok; print('Success!')"
