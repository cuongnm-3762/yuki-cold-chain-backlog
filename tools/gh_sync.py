"""Đồng bộ backlog (nguồn Typst) lên GitHub: issue, sub-issue, Project v2, field, iteration, trạng thái.

Mọi bước idempotent: ID nghiệp vụ (EP-01, I-0101, I-0101-1) ↔ số issue lưu ở tools/gh_map.json.
Ghi field xong luôn đọc lại để đối chiếu (theo tinh thần takumi git-projects: write → read-back).

  python -X utf8 tools/gh_sync.py labels     # nhãn
  python -X utf8 tools/gh_sync.py issues     # tạo epic/issue/sub-issue (bỏ qua cái đã có)
  python -X utf8 tools/gh_sync.py subs       # gắn quan hệ cha–con (sub-issue)
  python -X utf8 tools/gh_sync.py project    # tạo Project, field, iteration, liên kết repo, public
  python -X utf8 tools/gh_sync.py items      # thêm mọi issue vào Project
  python -X utf8 tools/gh_sync.py fields     # ghi Status/Iteration/SWP/giờ/phụ trách... rồi đọc lại
  python -X utf8 tools/gh_sync.py states     # đóng issue Done, mở lại issue chưa Done
  python -X utf8 tools/gh_sync.py verify     # chỉ đọc: so Project với nguồn, in chênh lệch
"""
from __future__ import annotations

import json
import subprocess
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from backlog import ROOT, load_raw, rows  # noqa: E402

OWNER = "cuongnm-3762"
REPO = f"{OWNER}/yuki-cold-chain-backlog"
PROJECT_TITLE = "Yuki Cold Chain — Backlog (LAB-5)"
MAP = ROOT / "tools" / "gh_map.json"
STATUS = ["Todo", "In Progress", "In Review", "Blocked", "Done"]
STATUS_COLOR = {"Todo": "GRAY", "In Progress": "YELLOW", "In Review": "BLUE", "Blocked": "RED", "Done": "GREEN"}
LEVELS = ["Epic", "Issue", "Sub-issue"]
CONSTRAINTS = ["Giờ lái 2024", "Không"]
ROLE_LABEL = {"DB": "role:db", "BE": "role:be", "FE": "role:fe", "QA": "role:qa", "TL": "role:tl", "BA": "role:ba",
              "OPS": "role:ops"}
LABELS = {
    "type:epic": ("5319E7", "Epic"), "type:story": ("1D76DB", "Issue (story)"),
    "type:devtask": ("0E8A16", "Task / sub-issue"), "type:clarification": ("FBCA04", "Cần làm rõ với khách"),
    "constraint:giờ-lái-2024": ("D93F0B", "Chịu ràng buộc giới hạn giờ lái xe tải từ 2024-04-01"),
    "phát-sinh": ("B60205", "Task phát sinh trong sprint"),
    **{v: ("C5DEF5", f"Vai trò {k}") for k, v in ROLE_LABEL.items()},
}


# ---------------------------------------------------------------- tiện ích
def gh(*args: str, input: str | None = None) -> str:
    for attempt in range(4):
        p = subprocess.run(["gh", *args], capture_output=True, text=True, encoding="utf-8", input=input)
        if p.returncode == 0:
            return p.stdout
        if "rate limit" in p.stderr.lower() or "abuse" in p.stderr.lower():
            time.sleep(30 * (attempt + 1))
            continue
        raise RuntimeError(f"gh {' '.join(args[:3])}… lỗi: {p.stderr.strip()}")
    raise RuntimeError("hết lượt thử lại do rate limit")


def gql(query: str, **variables) -> dict:
    payload = json.dumps({"query": query, "variables": variables}, ensure_ascii=False)
    out = json.loads(gh("api", "graphql", "--input", "-", input=payload))
    if out.get("errors"):
        raise RuntimeError(json.dumps(out["errors"], ensure_ascii=False))
    return out["data"]


def load_map() -> dict:
    return json.loads(MAP.read_text(encoding="utf-8")) if MAP.exists() else {"issues": {}, "project": {}}


def save_map(m: dict) -> None:
    MAP.write_text(json.dumps(m, ensure_ascii=False, indent=1), encoding="utf-8")


def title_of(r: dict) -> str:
    return f"[{r['id']}] {r['title']}".replace("`", "")


# ---------------------------------------------------------------- nội dung issue
def body_of(r: dict, by_id: dict) -> str:
    src = "> Sinh tự động từ `backlog/data.typ` bằng `tools/gh_sync.py`. Sửa nguồn rồi đồng bộ lại, không sửa tay.\n"
    if r["level"] == "Epic":
        children = [x for x in by_id.values() if x["level"] == "Issue" and x["parent"] == r["id"]]
        lines = "\n".join(f"- [{c['id']}] {c['title']}" for c in children)
        lim = f"\n**Ràng buộc đặc thù:** {r['constraint']} — tách riêng vì phần này chịu quy định giới hạn giờ lái xe tải áp dụng từ 2024-04-01 (bộ quy tắc `JP-TRUCK-2024-04`).\n" if r["constraint"] else ""
        return (f"{src}\n### Overview & Goal\n{r['desc']}\n{lim}\n### Scope & Features\n{lines}\n\n"
                f"### Acceptance Criteria\n- Mọi issue con Done\n- Test của các issue con chạy trên CI\n\n"
                f"### References & Dependencies\n- Spec (bộ thiết kế LAB-4): {r['spec']}\n"
                f"- Tổng: **{r['swp']} SWP / {r['hours']} h**\n")
    if r["level"] == "Issue":
        ac = "\n".join(f"- [ ] {a}" for a in r["ac"])
        subs = [x for x in by_id.values() if x["level"] == "Sub-issue" and x["parent"] == r["id"]]
        sub_txt = ("\n### Sub-issue\n" + "\n".join(
            f"- [{s['id']}] {s['title']} — {s['role']}, S{s['scope']}×C{s['cx']}, {s['swp']} SWP, {s['hours']} h"
            for s in subs) + "\n") if subs else (
            f"\n### Ước lượng\nLeaf issue (không tách sub-issue): {r['role']}, Scope {r['scope']} × Complexity {r['cx']}"
            f" → **{r['swp']} SWP**, **{r['hours']} h**.\n")
        lim = f"\n**Ràng buộc đặc thù:** {r['constraint']}\n" if r["constraint"] else ""
        kind = "\n**Loại:** làm rõ với khách hàng. Kết quả là một quyết định ghi vào PREMISE.md, không phải mã nguồn.\n" if r["kind"] == "clarify" else ""
        return (f"{src}\n**Epic:** {r['epic']}{lim}{kind}\n### Mô tả\n{r['desc']}\n\n### Spec\n{r['spec']}\n\n"
                f"### Acceptance Criteria\n{ac}\n{sub_txt}\n### Definition of Done\nXem `task-breakdown.md` §1.\n")
    return (f"{src}\n**Issue cha:** {r['parent']} · **Epic:** {r['epic']}"
            f"{' · **Ràng buộc:** ' + r['constraint'] if r['constraint'] else ''}\n\n"
            f"### Task Type\n{r['role']}\n\n### Specification\n{r['title']}\n\n### Impact Range\n{r['spec']}\n\n"
            f"### Ước lượng\nScope {r['scope']} × Complexity {r['cx']} → **{r['swp']} SWP** (đã review) · **{r['hours']} h**\n")


def labels_of(r: dict) -> list[str]:
    ls = []
    if r["level"] == "Epic":
        ls.append("type:epic")
    elif r["kind"] == "clarify":
        ls.append("type:clarification")
    elif r["level"] == "Issue":
        ls.append("type:story")
    else:
        ls.append("type:devtask")
    if r["constraint"]:
        ls.append("constraint:giờ-lái-2024")
    if r.get("role") in ROLE_LABEL:
        ls.append(ROLE_LABEL[r["role"]])
    if r.get("added"):
        ls.append("phát-sinh")
    return ls


# ---------------------------------------------------------------- lệnh
def cmd_labels(_rs):
    have = {x["name"] for x in json.loads(gh("label", "list", "-R", REPO, "--limit", "200", "--json", "name"))}
    for name, (color, desc) in LABELS.items():
        if name not in have:
            gh("label", "create", name, "-R", REPO, "--color", color, "--description", desc)
            print("label +", name)


def cmd_issues(rs):
    m = load_map()
    by_id = {r["id"]: r for r in rs}
    for r in rs:
        if r["id"] in m["issues"]:
            continue
        url = gh("issue", "create", "-R", REPO, "--title", title_of(r), "--body", body_of(r, by_id),
                 *sum((["--label", lb] for lb in labels_of(r)), [])).strip()
        num = int(url.rsplit("/", 1)[1])
        node = json.loads(gh("api", f"repos/{REPO}/issues/{num}"))["node_id"]
        m["issues"][r["id"]] = {"number": num, "node": node}
        save_map(m)
        print(f"{r['id']:<10} → #{num}")
        time.sleep(1.2)


def cmd_subs(rs):
    m = load_map()
    for r in rs:
        if not r["parent"]:
            continue
        child, parent = m["issues"][r["id"]], m["issues"][r["parent"]]
        if child.get("linked"):
            continue
        try:
            gql("mutation($p:ID!,$c:ID!){addSubIssue(input:{issueId:$p,subIssueId:$c}){issue{number}}}",
                p=parent["node"], c=child["node"])
        except RuntimeError as e:
            if "already" not in str(e).lower() and "duplicate" not in str(e).lower():
                raise
        child["linked"] = True
        save_map(m)
        print(f"{r['parent']} ⊃ {r['id']}")


def project_fields(pid: str) -> dict:
    d = gql("""query($p:ID!){node(id:$p){... on ProjectV2{fields(first:50){nodes{
      ... on ProjectV2FieldCommon{id name dataType}
      ... on ProjectV2SingleSelectField{options{id name}}
      ... on ProjectV2IterationField{configuration{iterations{id title startDate duration}}}}}}}}""", p=pid)
    return {f["name"]: f for f in d["node"]["fields"]["nodes"] if f}


def cmd_project(_rs):
    m = load_map()
    raw = load_raw()
    owner_id = gql("query($l:String!){user(login:$l){id}}", l=OWNER)["user"]["id"]
    if not m["project"].get("id"):
        p = gql("mutation($o:ID!,$t:String!){createProjectV2(input:{ownerId:$o,title:$t}){projectV2{id number url}}}",
                o=owner_id, t=PROJECT_TITLE)["createProjectV2"]["projectV2"]
        m["project"] = {"id": p["id"], "number": p["number"], "url": p["url"]}
        save_map(m)
        print("project", p["url"])
    pid = m["project"]["id"]
    repo_id = gql("query($o:String!,$n:String!){repository(owner:$o,name:$n){id}}",
                  o=OWNER, n=REPO.split("/")[1])["repository"]["id"]
    try:
        gql("mutation($p:ID!,$r:ID!){linkProjectV2ToRepository(input:{projectId:$p,repositoryId:$r}){repository{id}}}",
            p=pid, r=repo_id)
    except RuntimeError as e:
        print("link:", e)
    gql("""mutation($p:ID!,$d:String!,$r:String!){updateProjectV2(input:{projectId:$p,public:true,
         shortDescription:$d,readme:$r}){projectV2{public}}}""", p=pid,
        d="Backlog break từ detail design Yuki Cold Chain — B123762 — Product B",
        r=(ROOT / "tools" / "project-readme.md").read_text(encoding="utf-8"))
    f = project_fields(pid)
    st = f["Status"]
    want = [{"name": s, "color": STATUS_COLOR[s], "description": ""} for s in STATUS]
    if [o["name"] for o in st["options"]] != STATUS:
        gql("mutation($f:ID!,$o:[ProjectV2SingleSelectFieldOptionInput!]){updateProjectV2Field(input:{fieldId:$f,singleSelectOptions:$o}){projectV2Field{... on ProjectV2SingleSelectField{id}}}}",
            f=st["id"], o=want)
        print("Status options =", STATUS)
    specs = [("SWP", "NUMBER", None), ("Giờ ước lượng", "NUMBER", None), ("Giờ thực tế", "NUMBER", None),
             ("Phụ trách (giả định)", "TEXT", None), ("Mã backlog", "TEXT", None),
             ("Cấp", "SINGLE_SELECT", LEVELS), ("Ràng buộc", "SINGLE_SELECT", CONSTRAINTS),
             ("Vai trò", "SINGLE_SELECT", list(ROLE_LABEL))]
    for name, dtype, opts in specs:
        if name in f:
            continue
        v = dict(p=pid, n=name, t=dtype)
        if opts:
            v["o"] = [{"name": o, "color": "GRAY", "description": ""} for o in opts]
            gql("mutation($p:ID!,$n:String!,$t:ProjectV2CustomFieldType!,$o:[ProjectV2SingleSelectFieldOptionInput!]){createProjectV2Field(input:{projectId:$p,name:$n,dataType:$t,singleSelectOptions:$o}){projectV2Field{... on ProjectV2FieldCommon{id}}}}", **v)
        else:
            gql("mutation($p:ID!,$n:String!,$t:ProjectV2CustomFieldType!){createProjectV2Field(input:{projectId:$p,name:$n,dataType:$t}){projectV2Field{... on ProjectV2FieldCommon{id}}}}", **v)
        print("field +", name)
    if "Iteration" not in f:
        its = raw["iterations"]
        gql("""mutation($p:ID!,$c:ProjectV2IterationFieldConfigurationInput!){createProjectV2Field(input:{
              projectId:$p,name:"Iteration",dataType:ITERATION,iterationConfiguration:$c}){projectV2Field{... on ProjectV2FieldCommon{id}}}}""",
            p=pid, c={"startDate": its[0]["start"], "duration": 14,
                      "iterations": [{"title": i["title"], "startDate": i["start"], "duration": 14} for i in its]})
        print("field + Iteration")


def project_items(pid: str) -> dict:
    items, cur = {}, None
    while True:
        d = gql("""query($p:ID!,$c:String){node(id:$p){... on ProjectV2{items(first:100,after:$c){
          nodes{id content{... on Issue{number}} fieldValues(first:30){nodes{
            ... on ProjectV2ItemFieldSingleSelectValue{name field{... on ProjectV2FieldCommon{name}}}
            ... on ProjectV2ItemFieldNumberValue{number field{... on ProjectV2FieldCommon{name}}}
            ... on ProjectV2ItemFieldTextValue{text field{... on ProjectV2FieldCommon{name}}}
            ... on ProjectV2ItemFieldIterationValue{title field{... on ProjectV2FieldCommon{name}}}}}}
          pageInfo{hasNextPage endCursor}}}}}""", p=pid, c=cur)["node"]["items"]
        for n in d["nodes"]:
            if not n["content"]:
                continue
            vals = {}
            for v in n["fieldValues"]["nodes"]:
                if not v or "field" not in v:
                    continue
                vals[v["field"]["name"]] = v.get("name", v.get("number", v.get("text", v.get("title"))))
            items[n["content"]["number"]] = {"id": n["id"], "values": vals}
        if not d["pageInfo"]["hasNextPage"]:
            return items
        cur = d["pageInfo"]["endCursor"]


def cmd_items(rs):
    m = load_map()
    pid = m["project"]["id"]
    have = project_items(pid)
    for r in rs:
        it = m["issues"][r["id"]]
        if it["number"] in have:
            continue
        gql("mutation($p:ID!,$c:ID!){addProjectV2ItemById(input:{projectId:$p,contentId:$c}){item{id}}}",
            p=pid, c=it["node"])
        print("item +", r["id"])
        time.sleep(0.3)


def desired(r: dict) -> dict:
    v = {"Cấp": r["level"], "Mã backlog": r["id"], "SWP": r["swp"], "Giờ ước lượng": r["hours"],
         "Ràng buộc": r["constraint"] or "Không"}
    if r["status"]:
        v["Status"] = r["status"]
    if r["iteration"]:
        v["Iteration"] = r["iteration"]
    if r["owner"]:
        v["Phụ trách (giả định)"] = r["owner"]
    if r.get("role"):
        v["Vai trò"] = r["role"]
    if r["actual"] not in ("", None):
        v["Giờ thực tế"] = r["actual"]
    return v


def epic_status(rs: list[dict], eid: str) -> str:
    sts = [x["status"] for x in rs if x["epic"] == eid and x.get("leaf")]
    if all(s == "Done" for s in sts):
        return "Done"
    if all(s == "Todo" for s in sts):
        return "Todo"
    return "In Progress"


def with_epic_status(rs):
    for r in rs:
        if r["level"] == "Epic":
            r["status"] = epic_status(rs, r["id"])
    return rs


def cmd_fields(rs, only_check=False):
    m = load_map()
    pid = m["project"]["id"]
    f = project_fields(pid)
    have = project_items(pid)
    its = {i["title"]: i["id"] for i in f["Iteration"]["configuration"]["iterations"]}
    diffs = 0
    for r in rs:
        num = m["issues"][r["id"]]["number"]
        item = have[num]
        for name, val in desired(r).items():
            cur = item["values"].get(name)
            if isinstance(val, (int, float)) and cur is not None:
                same = float(cur) == float(val)
            else:
                same = cur == val
            if same:
                continue
            diffs += 1
            if only_check:
                print(f"KHÁC {r['id']:<10} {name}: project={cur!r} nguồn={val!r}")
                continue
            fld = f[name]
            if fld["dataType"] == "SINGLE_SELECT":
                opt = next(o["id"] for o in fld["options"] if o["name"] == val)
                value = {"singleSelectOptionId": opt}
            elif fld["dataType"] == "NUMBER":
                value = {"number": float(val)}
            elif fld["dataType"] == "ITERATION":
                value = {"iterationId": its[val]}
            else:
                value = {"text": str(val)}
            gql("""mutation($p:ID!,$i:ID!,$f:ID!,$v:ProjectV2FieldValue!){updateProjectV2ItemFieldValue(input:{
                  projectId:$p,itemId:$i,fieldId:$f,value:$v}){projectV2Item{id}}}""",
                p=pid, i=item["id"], f=fld["id"], v=value)
    if only_check:
        print(f"chênh lệch: {diffs}")
        return diffs
    print(f"đã ghi {diffs} giá trị; đọc lại để đối chiếu…")
    return cmd_fields(rs, only_check=True)


def cmd_states(rs):
    m = load_map()
    for r in rs:
        num = m["issues"][r["id"]]["number"]
        st = json.loads(gh("issue", "view", str(num), "-R", REPO, "--json", "state"))["state"]
        if r["status"] == "Done" and st == "OPEN":
            gh("issue", "close", str(num), "-R", REPO, "--reason", "completed")
            print("close", r["id"])
        elif r["status"] != "Done" and st == "CLOSED":
            gh("issue", "reopen", str(num), "-R", REPO)
            print("reopen", r["id"])


def main():
    cmd = sys.argv[1] if len(sys.argv) > 1 else "verify"
    rs = with_epic_status(rows())
    {"labels": cmd_labels, "issues": cmd_issues, "subs": cmd_subs, "project": cmd_project, "items": cmd_items,
     "fields": cmd_fields, "states": cmd_states,
     "verify": lambda r: sys.exit(1 if cmd_fields(r, only_check=True) else 0)}[cmd](rs)


if __name__ == "__main__":
    main()
