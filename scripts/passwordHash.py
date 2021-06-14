from werkzeug.security import generate_password_hash, check_password_hash

password = generate_password_hash("wGC76-x", method='sha256')

print(password)
