#!/bin/zsh
set -euo pipefail

CONFIG="${ARVECTUM_ASC_CONFIG:-$HOME/.config/arvectum/appstore-connect.env}"
[[ -r "$CONFIG" ]] || { echo "Missing App Store Connect config" >&2; exit 2; }
source "$CONFIG"
: "${ASC_KEY_ID:?ASC_KEY_ID is required}"
: "${ASC_ISSUER_ID:?ASC_ISSUER_ID is required}"

KEY_DIR="${ASC_KEY_DIR:-$HOME/.appstoreconnect/private_keys}"
KEY_FILE="$KEY_DIR/AuthKey_${ASC_KEY_ID}.p8"
[[ -r "$KEY_FILE" ]] || { echo "Missing App Store Connect private key" >&2; exit 2; }

XCODE="${ASC_XCODE:-/Applications/Xcode-26.6.0.app}"
ALTOOL="$XCODE/Contents/SharedFrameworks/ContentDelivery.framework/Versions/A/Resources/altool"
export API_PRIVATE_KEYS_DIR="$KEY_DIR"

BUNDLE_IDENTIFIER="${1:-ru.arvectum.tools.tosize}"
PROFILE_NAME="${2:-Arvectum Photo Pod Razmer App Store}"
make_token() {
  local tmp token
  tmp=$(mktemp)
  chmod 600 "$tmp"
  "$ALTOOL" --generate-jwt --apiKey "$ASC_KEY_ID" --apiIssuer "$ASC_ISSUER_ID" >/dev/null 2>"$tmp"
  token=$(python3 - "$tmp" <<'PY'
import re, sys
text = open(sys.argv[1], encoding="utf-8").read()
match = re.search(r'eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+', text)
if not match:
    raise SystemExit("JWT generation failed")
print(match.group(0), end="")
PY
)
  rm -f "$tmp"
  print -r -- "$token"
}

api() {
  local method="$1" endpoint="$2" body="${3:-}"
  local token
  token=$(make_token)
  if [[ -n "$body" ]]; then
    curl -fsS -X "$method"       -H "Authorization: Bearer $token"       -H "Content-Type: application/json"       --data-binary "$body"       "https://api.appstoreconnect.apple.com$endpoint"
  else
    curl -fsS -X "$method"       -H "Authorization: Bearer $token"       "https://api.appstoreconnect.apple.com$endpoint"
  fi
}

bundle_json=$(api GET "/v1/bundleIds?filter%5Bidentifier%5D=$BUNDLE_IDENTIFIER")
bundle_id=$(python3 -c 'import json,sys; p=json.load(sys.stdin); d=p.get("data",[]); print(d[0]["id"] if d else "")' <<<"$bundle_json")
[[ -n "$bundle_id" ]] || { echo "Bundle ID not found: $BUNDLE_IDENTIFIER" >&2; exit 3; }

cert_json=$(api GET "/v1/certificates?filter%5BcertificateType%5D=DISTRIBUTION&limit=200")
cert_id=$(python3 -c 'import json,sys; p=json.load(sys.stdin); d=[x for x in p.get("data",[]) if x.get("attributes",{}).get("activated",True)]; print(d[0]["id"] if d else "")' <<<"$cert_json")
[[ -n "$cert_id" ]] || { echo "Active Apple Distribution certificate not found" >&2; exit 4; }

profiles_json=$(api GET "/v1/bundleIds/$bundle_id/profiles?limit=200")
existing_id=$(python3 -c 'import json,sys; p=json.load(sys.stdin); d=[x for x in p.get("data",[]) if x.get("attributes",{}).get("profileType")=="IOS_APP_STORE" and x.get("attributes",{}).get("profileState")=="ACTIVE"]; print(d[0]["id"] if d else "")' <<<"$profiles_json")

if [[ -n "$existing_id" ]]; then
  profile_json=$(api GET "/v1/profiles/$existing_id")
else
  body=$(python3 - "$PROFILE_NAME" "$bundle_id" "$cert_id" <<'PY'
import json, sys
name, bundle_id, cert_id = sys.argv[1:]
print(json.dumps({
  "data": {
    "type": "profiles",
    "attributes": {"name": name, "profileType": "IOS_APP_STORE"},
    "relationships": {
      "bundleId": {"data": {"type": "bundleIds", "id": bundle_id}},
      "certificates": {"data": [{"type": "certificates", "id": cert_id}]}
    }
  }
}, separators=(",", ":")))
PY
)
  profile_json=$(api POST "/v1/profiles" "$body")
fi

mkdir -p "$HOME/Library/Developer/Xcode/UserData/Provisioning Profiles"
profile_tmp=$(mktemp)
chmod 600 "$profile_tmp"
print -r -- "$profile_json" > "$profile_tmp"
python3 - "$profile_tmp" "$HOME/Library/Developer/Xcode/UserData/Provisioning Profiles" <<'PY'
import base64, json, os, sys
payload_path, directory = sys.argv[1:]
with open(payload_path, encoding="utf-8") as f:
    payload = json.load(f)
data = payload["data"]
attrs = data["attributes"]
uuid = attrs["uuid"]
content = base64.b64decode(attrs["profileContent"])
path = os.path.join(directory, uuid + ".mobileprovision")
with open(path, "wb") as f:
    f.write(content)
print("PROFILE_ID", data["id"])
print("PROFILE_UUID", uuid)
print("PROFILE_NAME", attrs["name"])
print("PROFILE_TYPE", attrs["profileType"])
print("PROFILE_STATE", attrs["profileState"])
print("PROFILE_PATH", path)
PY
rm -f "$profile_tmp"
