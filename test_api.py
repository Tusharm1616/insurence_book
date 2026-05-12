import urllib.request
import urllib.error
import json
import time

req = urllib.request.Request(
    'https://insurencebook-production.up.railway.app/api/auth/login', 
    data=json.dumps({'email':'kakadekiran2211@gmail.com', 'password':'password123'}).encode('utf-8'), 
    headers={'Content-Type':'application/json'}, 
    method='POST'
)

print("Polling live API...")
for i in range(15):
    try:
        urllib.request.urlopen(req)
        print('SUCCESS! Valid login.')
        break
    except urllib.error.HTTPError as e:
        res = e.read().decode('utf-8', errors='ignore')
        if 'traceback' in res or 'Invalid email or password' in res:
            print('NEW DEPLOY IS LIVE! Response:', res)
            break
        else:
            print('Waiting for deploy... Response:', res)
    time.sleep(10)
