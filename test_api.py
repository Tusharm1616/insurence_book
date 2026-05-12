import urllib.request
import urllib.error
import json

req = urllib.request.Request(
    'https://insurencebook-production.up.railway.app/api/auth/login', 
    data=json.dumps({'email':'kakadekiran2211@gmail.com', 'password':'password123'}).encode('utf-8'), 
    headers={'Content-Type':'application/json'}, 
    method='POST'
)

try:
    print(urllib.request.urlopen(req).read())
except urllib.error.HTTPError as e:
    print('HTTP ERROR CODE:', e.code)
    print('RESPONSE BODY:', e.read().decode('utf-8', errors='ignore'))
