"""Read-only structural review. Native roadmap stays the task source."""
import hashlib,json,re,subprocess
from pathlib import Path
ROOT=Path(__file__).resolve().parents[5]
PIN="f3893f6a70fafc529b70dbf23515ce8913706c35"
PRIOR="2d04cca3f9367a4d22add4e27e9fd729cebbfa60"
DIR="core/docs/specs/001-portfolio-roadmap-traceability"
SOURCES=json.loads("[{\"key\":\"CORE\",\"path\":\"core/ROADMAP.md\",\"sha256\":\"cf25520da328dcab0fbee01caf4879fe53e856a914f91af9cbb7adcb7897d129\",\"expected_count\":111},{\"key\":\"GROWTH\",\"path\":\"growth/ROADMAP.md\",\"sha256\":\"bc28d327a979d329be2a6e202603f6be01f0b3361f21542d6c524f54f492b4e3\",\"expected_count\":64},{\"key\":\"GROWTH-AGENT\",\"path\":\"growth/agent/ROADMAP.md\",\"sha256\":\"74153181285092bdb234a81e8e194b4271266074c806d39c8ad3ebc6bb508309\",\"expected_count\":86},{\"key\":\"CHICKMARK\",\"path\":\"chickmark/ROADMAP.md\",\"sha256\":\"dbf9e4be8447006d8a5b164b247d81046aa199e14ef7a40f81054fb371d71a38\",\"expected_count\":91},{\"key\":\"PHOTO-PDF\",\"path\":\"photo-pdf-to-size/ROADMAP.md\",\"sha256\":\"63a2ea9562080097fefd9298235a8dbdb00dd4b7f5aafeac374539c93bae2473\",\"expected_count\":75},{\"key\":\"PUSHKIN\",\"path\":\"pushkin/ROADMAP.md\",\"sha256\":\"19b76192a1eb5999b157684cf8a51578f123df3c1f8ba9c901b61dfee33c1bdd\",\"expected_count\":101},{\"key\":\"WHAT\",\"path\":\"what/ROADMAP.md\",\"sha256\":\"8f98e315c308f4f706a3f6fb0f181e5c64ab53fa3cdd73a327791253fa3e6f38\",\"expected_count\":118},{\"key\":\"WHERE\",\"path\":\"where/ROADMAP.md\",\"sha256\":\"9199bff154dcd22a13541ba767f0043ab98294159b0533bff6a1d8bec940ebb2\",\"expected_count\":39}]")
def expected_rows(original):
    result={}
    for s in SOURCES:
        heading=0
        count=0
        for n,line in enumerate(original[s["path"]].decode("utf-8").splitlines(),1):
            if re.match(r"^#{1,6}\s",line):heading=n
            if not re.match(r"^\s*(?:[-*+]|\d+\.)\s+|^\s*\|",line) or not re.search(r"\[[ ~!]\]",line):continue
            k=f'{s["key"]}-{n:04d}'
            result[k]=(s["path"],n,heading,"".join(re.findall(r"\[([ ~!])\]",line)))
            count+=1
        if count!=s["expected_count"]:raise ValueError("baseline count: "+s["path"])
    return result
def validate(data,original,prior,current):
    errors=[]
    for s in SOURCES:
        p=s["path"];b=original[p]
        if hashlib.sha256(b).hexdigest()!=s["sha256"]:errors.append("source hash "+p)
        if not prior[p].startswith(b) or prior[p]!=current[p]:errors.append("unreviewed source change "+p)
    if data.get("schema")!="arvectum.native-roadmap-review/1" or data.get("source_commit")!=PIN or data.get("review_baseline")!=PRIOR or data.get("sources")!=SOURCES or data.get("execution_authorized") is not False or data.get("actual_acceptance_verified") is not False:errors.append("scope or authority")
    expected=expected_rows(original);rows=data.get("rows",[]);ids=[r["id"] for r in rows]
    if len(ids)!=len(set(ids)) or set(ids)!=set(expected):errors.append("remaining source coverage")
    for r in rows:
        k=r["id"]
        if k not in expected:continue
        if (r.get("source"),r.get("line"),r.get("heading_line"),r.get("markers"))!=expected[k]:errors.append("source/task linkage "+k)
        if k.startswith(("WHERE-","GROWTH-AGENT-")) and r.get("disposition")!="paused":errors.append("paused scope "+k)
        if r.get("disposition") not in {"paused","conditional_or_deferred","reconcile_required"}:errors.append("disposition "+k)
        if r.get("review_state") not in {"unverified","verified"}:errors.append("state "+k)
        if r.get("review_state")=="verified":
            ev=r.get("evidence",[])
            if not ev or any(e.get("criterion")!=k or e.get("outcome")!="pass" or not re.fullmatch(r"[0-9a-f]{64}",e.get("artifact_sha256","")) or not re.fullmatch(r"[0-9a-f]{40}",e.get("source_commit","")) or not e.get("receipt_ref") or not e.get("review_ref") for e in ev):errors.append("missing criterion-specific reviewed evidence "+k)
    return errors
def inputs():
    def read(ref,p):return subprocess.check_output(["git","-C",str(ROOT),"show",ref+":"+p])
    original={s["path"]:read(PIN,s["path"]) for s in SOURCES}
    prior={p:read(PRIOR,p) for p in original}
    current={p:(ROOT/p).read_bytes() for p in original}
    return json.loads((ROOT/DIR/"native-roadmap-review.json").read_text()),original,prior,current
if __name__=="__main__":
    errors=validate(*inputs())
    if errors:raise SystemExit("\n".join(errors))
    print("Structural source coverage PASS; actual acceptance and execution authorization remain separate.")
