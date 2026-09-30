#!/bin/zsh
set -euo pipefail
source "${ARVECTUM_ASC_CONFIG:-$HOME/.config/arvectum/appstore-connect.env}"
KEY_DIR="${ASC_KEY_DIR:-$HOME/.appstoreconnect/private_keys}"
ALTOOL="/Applications/Xcode-26.6.0.app/Contents/SharedFrameworks/ContentDelivery.framework/Versions/A/Resources/altool"
export API_PRIVATE_KEYS_DIR="$KEY_DIR"
tmp=$(mktemp)
"$ALTOOL" --generate-jwt --apiKey "$ASC_KEY_ID" --apiIssuer "$ASC_ISSUER_ID" >/dev/null 2>"$tmp"
token=$(grep -Eo 'eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+' "$tmp" | head -1)
rm -f "$tmp"
app_id="${1:-6816346084}"
curl -fsS -G -H "Authorization: Bearer $token" \
  --data-urlencode "filter[app]=$app_id" \
  --data-urlencode "include=preReleaseVersion" \
  --data-urlencode "limit=20" \
  "https://api.appstoreconnect.apple.com/v1/builds" > /tmp/arvectum-app-builds.json
python3 - /tmp/arvectum-app-builds.json <<'PY'
import json, sys
p=json.load(open(sys.argv[1]))
for x in p.get("data", []):
    a=x.get("attributes", {})
    print(x["id"], a.get("version"), a.get("processingState"), a.get("uploadedDate"), a.get("expired"), "encryption=", a.get("usesNonExemptEncryption"))
PY

curl -fsS -H "Authorization: Bearer $token" \
  "https://api.appstoreconnect.apple.com/v1/apps/$app_id/appStoreVersions?limit=20" \
  > /tmp/arvectum-app-versions.json
python3 - /tmp/arvectum-app-versions.json <<'PY'
import json, sys
p=json.load(open(sys.argv[1]))
for x in p.get("data", []):
    a=x.get("attributes", {})
    print("VERSION", x["id"], a.get("platform"), a.get("versionString"), a.get("appStoreState"))
PY

version_id=$(python3 -c 'import json; p=json.load(open("/tmp/arvectum-app-versions.json")); print(p["data"][0]["id"])')
curl -fsS -H "Authorization: Bearer $token" \
  "https://api.appstoreconnect.apple.com/v1/appStoreVersions/$version_id/appStoreVersionLocalizations?limit=20" \
  > /tmp/arvectum-version-localizations.json
python3 - /tmp/arvectum-version-localizations.json <<'PY'
import json, sys
p=json.load(open(sys.argv[1]))
for x in p.get("data", []):
    a=x.get("attributes", {})
    print("LOCALIZATION", x["id"], a.get("locale"), a.get("description"), a.get("keywords"))
PY

curl -fsS -H "Authorization: Bearer $token" \
  "https://api.appstoreconnect.apple.com/v1/apps/$app_id/appInfos?limit=20" \
  > /tmp/arvectum-app-infos.json
python3 - /tmp/arvectum-app-infos.json <<'PY'
import json, sys
p=json.load(open(sys.argv[1]))
for x in p.get("data", []):
    print("APPINFO", x["id"], x.get("attributes", {}))
PY

for relation in appPriceSchedule appAvailabilityV2; do
  curl -sS -H "Authorization: Bearer $token" \
    "https://api.appstoreconnect.apple.com/v1/apps/$app_id/$relation" \
    > "/tmp/arvectum-$relation.json"
  python3 - "$relation" "/tmp/arvectum-$relation.json" <<'PY'
import json, sys
name, path = sys.argv[1:]
p=json.load(open(path))
if "errors" in p:
    print(name, "ERROR", [(e.get("status"), e.get("code"), e.get("detail")) for e in p["errors"]])
else:
    d=p.get("data")
    print(name, d.get("id") if d else None, d.get("attributes") if d else None)
PY
done
