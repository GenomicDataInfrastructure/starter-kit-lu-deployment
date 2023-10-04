from authlib.jose import RSAKey
from json import dumps

public_key_file = "public-key.jwk"
private_key_file = "private-key.jwk"

if __name__ == "__main__":
    key = RSAKey.generate_key(is_private=True, options={"kid": "gdi-demo"})

    public_jwk = key.as_dict(is_private=False)
    private_jwk = dict(key)

    with open(public_key_file, "w") as f:
        f.write(dumps(public_jwk, indent=4))
        print(f"wrote {public_key_file}")
    with open(private_key_file, "w") as f:
        f.write(dumps(private_jwk, indent=4))
        print(f"wrote {private_key_file}")
