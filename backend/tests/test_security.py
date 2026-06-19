import base64
import hashlib

from app.security import canonical_query, canonical_string, hash_secret


def test_canonical_query_sorts_pairs() -> None:
    assert canonical_query(b"b=2&a=1") == "a=1&b=2"


def test_canonical_string_shape() -> None:
    value = canonical_string("get", "/v1/sync", "cursor=1", "dev", "10", "nonce", "hash")
    assert value == "GET\n/v1/sync\ncursor=1\ndev\n10\nnonce\nhash"


def test_hash_secret_is_sha256_hex() -> None:
    assert hash_secret("abc") == hashlib.sha256(b"abc").hexdigest()


def test_nonce_encoding_is_base64url_compatible() -> None:
    raw = base64.urlsafe_b64encode(b"1234567890123456").decode().rstrip("=")
    assert "+" not in raw
    assert "/" not in raw
