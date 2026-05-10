import urllib.request

try:
    req = urllib.request.Request("https://insurencebook-production.up.railway.app/terms/")
    with urllib.request.urlopen(req, timeout=10) as response:
        print("Status:", response.status)
        print("Body:", response.read().decode())
except urllib.error.HTTPError as e:
    print("HTTPError:", e.code, e.read().decode())
except Exception as e:
    print("Error:", e)
