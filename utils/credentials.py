import random
import string

def generate_user_id() -> str:
    """
    Format: 'TU' + 4 digits + 1 letter + 5 random chars
    Example: TU9714A88702
    """
    digits = "".join(random.choices(string.digits, k=4))
    letter = random.choice(string.ascii_uppercase)
    suffix = "".join(random.choices(string.ascii_uppercase + string.digits, k=5))
    return f"TU{digits}{letter}{suffix}"

def generate_temp_password() -> str:
    """
    Format: 3 letters + 1 digit + 2 letters (all uppercase)
    Example: RAD3U4
    """
    p1 = "".join(random.choices(string.ascii_uppercase, k=3))
    d = random.choice(string.digits)
    p2 = "".join(random.choices(string.ascii_uppercase, k=2))
    return f"{p1}{d}{p2}"
