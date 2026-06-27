import requests
import jwt
from datetime import datetime, timedelta

SECRET_KEY = "any-long-random-string-here-make-it-strong"
ALGORITHM = "HS256"

# Create token for user Kaushal (id=11)
to_encode = {"sub": "kaushalgiri8080@gmail.com", "user_id": 6} # Wait, what is Kaushal's email?
# Let's check Kaushal's email from the DB output:
# (11, 'kaushal', 'kaushalgiri9921@gmail.com')
# (6, 'Kaushal', 'kaushalgiri8080@gmail.com')
# Oh, there are TWO Kaushals! Which one is the user? The screenshot shows customer 'kaushal giri' with email 'kaushalgiri8080@gmail.com'. 
# Wait, if kaushalgiri8080@gmail.com is the CUSTOMER, the AGENT might be kaushalgiri9921@gmail.com (id=11)
# Let's generate tokens for both and try!

def get_token(user_id, email):
    expire = datetime.utcnow() + timedelta(minutes=30)
    to_encode = {"sub": email, "exp": expire}
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

for uid, email in [(11, 'kaushalgiri9921@gmail.com'), (6, 'kaushalgiri8080@gmail.com')]:
    print(f"--- Testing for {email} (id={uid}) ---")
    token = get_token(uid, email)
    headers = {"Authorization": f"Bearer {token}"}
    
    res = requests.get("https://insurence-book.onrender.com/api/reports/dashboard?year=2026&month=6", headers=headers)
    print("Dashboard:", res.json())
