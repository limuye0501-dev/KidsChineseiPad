#!/usr/bin/env python3
"""Create this app's bundle id and App Store profile with the ASC API key.

Prints status only. Never prints the key, the profile bytes, or certificates.
The product in Products.storekit is not registered here.
"""
import base64
import hashlib
import json
import os
import plistlib
import subprocess
import time
import urllib.error
import urllib.parse
import urllib.request

API = "https://api.appstoreconnect.apple.com"
BUNDLE = os.environ.get("BUNDLE_ID", "com.limuye.littlepandachinese")
PROFILE_NAME = os.environ.get("PROFILE_NAME", "Little Panda Chinese AppStore CI")
APP_NAME = "Little Panda Chinese"


def b64url(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode()


def der_to_raw(der: bytes) -> bytes:
    if der[0] != 0x30:
        raise ValueError("signature is not a DER sequence")
    index = 2 if der[1] < 0x80 else 2 + (der[1] & 0x7F)
    if der[index] != 0x02:
        raise ValueError("missing r")
    index += 1
    length = der[index]
    index += 1
    r = der[index:index + length]
    index += length
    if der[index] != 0x02:
        raise ValueError("missing s")
    index += 1
    length = der[index]
    index += 1
    s = der[index:index + length]

    def norm(part: bytes) -> bytes:
        part = part.lstrip(b"\x00")
        if len(part) > 32:
            raise ValueError("ECDSA integer is too long")
        return part.rjust(32, b"\x00")

    return norm(r) + norm(s)


def jwt_token() -> str:
    key_path = os.environ["ASC_KEY_PATH"]
    key_id = os.environ["ASC_KEY_ID"]
    issuer = os.environ["ASC_ISSUER_ID"]
    now = int(time.time())
    header = b64url(json.dumps({"alg": "ES256", "kid": key_id, "typ": "JWT"}, separators=(",", ":")).encode())
    payload = b64url(json.dumps({
        "iss": issuer,
        "iat": now,
        "exp": now + 600,
        "aud": "appstoreconnect-v1",
    }, separators=(",", ":")).encode())
    signing_input = f"{header}.{payload}".encode()
    der = subprocess.check_output(["openssl", "dgst", "-sha256", "-sign", key_path], input=signing_input)
    return f"{header}.{payload}.{b64url(der_to_raw(der))}"


def explain(payload) -> str:
    messages = []
    for error in payload.get("errors") or []:
        messages.append(f"{error.get('status')} {error.get('code')} {error.get('title')}: {error.get('detail')}")
    return " | ".join(messages) or "no detail"


def api(token: str, method: str, path: str, body=None, params=None):
    url = API + path
    if params:
        url += "?" + urllib.parse.urlencode(params)
    data = None if body is None else json.dumps(body).encode()
    request = urllib.request.Request(url, data=data, method=method)
    request.add_header("Authorization", "Bearer " + token)
    request.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(request, timeout=60) as response:
            raw = response.read()
            return response.status, json.loads(raw) if raw else {}
    except urllib.error.HTTPError as error:
        raw = error.read()
        try:
            parsed = json.loads(raw)
        except json.JSONDecodeError:
            parsed = {"errors": [{"title": "HTTP error", "detail": raw[:180].decode("utf-8", "replace")}]}
        return error.code, parsed


def local_cert_hashes(keychain: str) -> set:
    if not keychain:
        return set()
    pem = subprocess.check_output(["security", "find-certificate", "-a", "-p", keychain])
    hashes = set()
    for block in pem.split(b"-----END CERTIFICATE-----"):
        if b"BEGIN CERTIFICATE" not in block:
            continue
        body = block.split(b"-----BEGIN CERTIFICATE-----", 1)[1]
        der = base64.b64decode(b"".join(body.split()))
        hashes.add(hashlib.sha1(der).hexdigest())
    return hashes


def ensure_bundle(token: str) -> str:
    status, payload = api(token, "GET", "/v1/bundleIds", params={"filter[identifier]": BUNDLE, "limit": "5"})
    if status != 200:
        raise SystemExit(f"bundle id lookup failed: {explain(payload)}")
    matches = [row for row in payload.get("data", []) if row["attributes"]["identifier"] == BUNDLE]
    if matches:
        print("bundle id ready")
        return matches[0]["id"]
    status, payload = api(token, "POST", "/v1/bundleIds", body={
        "data": {
            "type": "bundleIds",
            "attributes": {"identifier": BUNDLE, "name": APP_NAME, "platform": "IOS"},
        }
    })
    if status not in (201, 409):
        raise SystemExit(f"bundle id create failed: {explain(payload)}")
    if status == 409:
        status, payload = api(token, "GET", "/v1/bundleIds", params={"filter[identifier]": BUNDLE, "limit": "5"})
        matches = [row for row in payload.get("data", []) if row["attributes"]["identifier"] == BUNDLE]
        if not matches:
            raise SystemExit("bundle id conflict but lookup missed it")
        print("bundle id ready")
        return matches[0]["id"]
    print("bundle id created")
    return payload["data"]["id"]


def distribution_cert(token: str) -> str:
    status, payload = api(token, "GET", "/v1/certificates", params={"limit": "200"})
    if status != 200:
        raise SystemExit(f"certificate lookup failed: {explain(payload)}")
    rows = [
        row for row in payload.get("data", [])
        if row["attributes"].get("certificateType") in ("IOS_DISTRIBUTION", "DISTRIBUTION")
    ]
    if not rows:
        raise SystemExit("no iOS distribution certificate on the App Store Connect team")
    hashes = local_cert_hashes(os.environ.get("KEYCHAIN_PATH", ""))
    if hashes:
        for row in rows:
            content = base64.b64decode(row["attributes"]["certificateContent"])
            if hashlib.sha1(content).hexdigest() in hashes:
                print("matched distribution certificate")
                return row["id"]
        raise SystemExit("the imported distribution certificate does not match an App Store Connect distribution certificate")
    print("using distribution certificate")
    return rows[0]["id"]


def ensure_profile(token: str, bundle_id: str, cert_id: str) -> None:
    status, payload = api(token, "GET", "/v1/profiles", params={"filter[name]": PROFILE_NAME, "limit": "20"})
    if status != 200:
        raise SystemExit(f"profile lookup failed: {explain(payload)}")
    for row in payload.get("data", []):
        if row["attributes"].get("name") == PROFILE_NAME:
            delete_status, delete_payload = api(token, "DELETE", f"/v1/profiles/{row['id']}")
            if delete_status not in (204, 200, 404):
                raise SystemExit(f"profile delete failed: {explain(delete_payload)}")
    status, payload = api(token, "POST", "/v1/profiles", body={
        "data": {
            "type": "profiles",
            "attributes": {"name": PROFILE_NAME, "profileType": "IOS_APP_STORE"},
            "relationships": {
                "bundleId": {"data": {"type": "bundleIds", "id": bundle_id}},
                "certificates": {"data": [{"type": "certificates", "id": cert_id}]},
            },
        }
    })
    if status != 201:
        raise SystemExit(f"profile create failed: {explain(payload)}")
    content = base64.b64decode(payload["data"]["attributes"]["profileContent"])
    tmp = os.path.join(os.environ.get("RUNNER_TEMP", "/tmp"), "profile.mobileprovision")
    with open(tmp, "wb") as handle:
        handle.write(content)
    decoded = subprocess.check_output(["security", "cms", "-D", "-i", tmp])
    info = plistlib.loads(decoded)
    if info.get("Name") != PROFILE_NAME:
        raise SystemExit("profile name did not match")
    application = info.get("Entitlements", {}).get("application-identifier", "")
    if not str(application).endswith(BUNDLE):
        raise SystemExit("profile bundle id did not match")
    destination_dir = os.path.expanduser("~/Library/MobileDevice/Provisioning Profiles")
    os.makedirs(destination_dir, exist_ok=True)
    uuid = info["UUID"]
    with open(os.path.join(destination_dir, f"{uuid}.mobileprovision"), "wb") as handle:
        handle.write(content)
    print(f"profile installed {uuid}")


def ensure_app_record(token: str, bundle_id: str) -> None:
    """Best-effort. Upload reports a missing app record if this cannot create one."""
    status, payload = api(token, "GET", "/v1/apps", params={"filter[bundleId]": BUNDLE, "limit": "5"})
    if status == 200 and payload.get("data"):
        print("app record exists")
        return
    attempts = [
        {
            "data": {
                "type": "apps",
                "attributes": {"sku": "littlepandachinese", "primaryLocale": "en-US"},
                "relationships": {"bundleId": {"data": {"type": "bundleIds", "id": bundle_id}}},
            }
        },
        {
            "data": {
                "type": "apps",
                "attributes": {
                    "bundleId": BUNDLE,
                    "name": APP_NAME,
                    "primaryLocale": "en-US",
                    "sku": "littlepandachinese",
                },
            }
        },
    ]
    for body in attempts:
        status, payload = api(token, "POST", "/v1/apps", body=body)
        if status in (201, 200):
            print("app record created")
            return
        if status == 409:
            print("app record exists")
            return
        print(f"app record not created: {explain(payload)}")
    print("continuing to archive; upload will say if the app record is missing")


def main() -> None:
    token = jwt_token()
    bundle_id = ensure_bundle(token)
    cert_id = distribution_cert(token)
    ensure_profile(token, bundle_id, cert_id)
    ensure_app_record(token, bundle_id)


if __name__ == "__main__":
    main()
