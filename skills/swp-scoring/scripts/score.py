"""swp-scoring: chấm SWP bằng ma trận Scope × Complexity, kiểm khung giờ, chọn mẫu, xuất HTML.

Chạy từ gốc repo:  python -X utf8 skills/swp-scoring/scripts/score.py
"""
from __future__ import annotations

import html
import json
import random
import sys
from collections import Counter, defaultdict
from datetime import datetime, timezone, timedelta
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / "tools"))
from backlog import leaves, load_raw, rows  # noqa: E402

MATRIX = {1: [1, 1, 2, 3], 2: [1, 2, 3, 5], 3: [2, 3, 5, 8], 4: [3, 5, 8, 13]}
BAND = {1: (2, 5), 2: (3, 8), 3: (5, 12), 5: (8, 16)}
OUT = ROOT / "swp-report"
SEED = 20261130

FLAG_TEXT = {
    "LECH": "SWP trong backlog khác ma trận",
    "NGOAI_KHUNG": "giờ ngoài khung của mức SWP",
    "PHAI_TACH": "SWP ≥ 8, phải tách",
    "C4": "Complexity 4, bất định cao",
    "RANG_BUOC": "ràng buộc giờ lái 2024, C ≥ 3",
    "NGAU_NHIEN": "chọn ngẫu nhiên (epic không có cờ)",
}


def score(t: dict) -> dict:
    m = MATRIX[t["scope"]][t["cx"] - 1]
    flags = []
    if t["swp"] != m:
        flags.append("LECH")
    if m >= 8:
        flags.append("PHAI_TACH")
    elif not (BAND[m][0] <= t["hours"] <= BAND[m][1]):
        flags.append("NGOAI_KHUNG")
    if t["cx"] == 4:
        flags.append("C4")
    if t["constraint"] and t["cx"] >= 3:
        flags.append("RANG_BUOC")
    return dict(id=t["id"], epic=t["epic"], title=t["task_title"], role=t["role"], s=t["scope"], c=t["cx"],
                matrix=m, swp=t["swp"], hours=t["hours"], band=BAND.get(m), constraint=t["constraint"],
                flags=flags, ratio=round(t["hours"] / t["swp"], 1))


def main() -> int:
    raw = load_raw()
    rs = rows(raw)
    lv = leaves(rs)
    scored = [score(t) for t in lv]
    rng = random.Random(SEED)
    flagged_epics = {x["epic"] for x in scored if x["flags"]}
    for e in raw["epics"]:
        if e["id"] in flagged_epics:
            continue
        pool = [x for x in scored if x["epic"] == e["id"]]
        if pool:
            rng.choice(pool)["flags"].append("NGAU_NHIEN")
    sample = [x for x in scored if x["flags"]]

    review_path = OUT / "review.json"
    review = json.loads(review_path.read_text(encoding="utf-8")) if review_path.exists() else {}
    pending, unapplied = [], []
    for x in sample:
        rv = review.get(x["id"])
        x["review"] = rv
        if rv is None:
            pending.append(x["id"])
        elif rv["final"] != x["swp"] or (rv.get("hours") and rv["hours"] != x["hours"]):
            unapplied.append(x["id"])
    # quyết định cho task đã bị tách (không còn trong backlog) vẫn hiện để lưu vết
    gone = {k: v for k, v in review.items() if k not in {x["id"] for x in scored}}

    must_split = [x["id"] for x in scored if "PHAI_TACH" in x["flags"]]
    OUT.mkdir(exist_ok=True)
    result = dict(
        generated=datetime.now(timezone(timedelta(hours=9))).isoformat(timespec="seconds"),
        matrix=MATRIX, band={str(k): v for k, v in BAND.items()},
        totals=dict(leaves=len(scored), swp=sum(x["swp"] for x in scored), hours=sum(x["hours"] for x in scored),
                    matrix_swp=sum(x["matrix"] for x in scored)),
        sample=[{k: v for k, v in x.items()} for x in sample], pending=pending, unapplied=unapplied,
        must_split=must_split, split_history=gone,
        tasks=scored,
    )
    (OUT / "result.json").write_text(json.dumps(result, ensure_ascii=False, indent=1), encoding="utf-8")
    (OUT / "index.html").write_text(render(raw, scored, sample, result), encoding="utf-8")
    print(f"leaves={len(scored)} swp={result['totals']['swp']} matrix_swp={result['totals']['matrix_swp']} "
          f"hours={result['totals']['hours']} sample={len(sample)} pending={len(pending)} "
          f"unapplied={unapplied} must_split={must_split}")
    for x in sample:
        print(f"  {x['id']:<10} S{x['s']}C{x['c']} -> {x['matrix']:>2} | backlog {x['swp']:>2} | {x['hours']:>3}h | "
              f"{','.join(x['flags'])}")
    return 1 if (must_split or unapplied) else 0


def esc(s) -> str:
    return html.escape(str(s))


def render(raw, scored, sample, result) -> str:
    by_epic = defaultdict(list)
    for x in scored:
        by_epic[x["epic"]].append(x)
    dist = Counter(x["swp"] for x in scored)
    titles = {e["id"]: e["title"] for e in raw["epics"]}

    def flag_html(fs):
        return " ".join(f'<span class="flag f-{f}" title="{esc(FLAG_TEXT[f])}">{f}</span>' for f in fs)

    mat = "".join(
        f"<tr><th>S{s}</th>" + "".join(f'<td class="m{v}">{v}</td>' for v in MATRIX[s]) + "</tr>" for s in (1, 2, 3, 4))
    sample_rows = []
    for x in sample:
        rv = x["review"] or {}
        final = rv.get("final", "—")
        reason = rv.get("reason", "<em>chưa review</em>")
        changed = rv and (rv.get("final") != x["matrix"] or rv.get("hours"))
        sample_rows.append(
            f'<tr><td class="id">{esc(x["id"])}</td><td>{esc(x["title"])}<div class="sub">{esc(x["epic"])} · {esc(x["role"])}'
            f'{" · " + esc(x["constraint"]) if x["constraint"] else ""}</div></td>'
            f'<td class="c">S{x["s"]} × C{x["c"]} → <b>{x["matrix"]}</b></td><td class="c">{x["hours"]} h'
            f'<div class="sub">khung {x["band"][0]}–{x["band"][1]} h</div></td>' if x["band"] else
            f'<tr><td class="id">{esc(x["id"])}</td><td>{esc(x["title"])}<div class="sub">{esc(x["epic"])} · {esc(x["role"])}'
            f'{" · " + esc(x["constraint"]) if x["constraint"] else ""}</div></td>'
            f'<td class="c">S{x["s"]} × C{x["c"]} → <b>{x["matrix"]}</b></td><td class="c">{x["hours"]} h'
            f'<div class="sub">phải tách</div></td>')
        sample_rows[-1] += (f'<td>{flag_html(x["flags"])}</td><td class="c {"chg" if changed else ""}"><b>{esc(final)}</b>'
                            f'{"<div class=sub>" + esc(rv["hours"]) + " h</div>" if rv.get("hours") else ""}</td>'
                            f'<td>{reason if not rv else esc(reason)}</td></tr>')
    hist = "".join(
        f'<tr><td class="id">{esc(k)}</td><td colspan="2">{esc(v.get("was", ""))}</td><td class="c"><b>{esc(v["final"])}</b></td>'
        f'<td>{esc(v["reason"])}</td></tr>' for k, v in result["split_history"].items())
    epic_rows = "".join(
        f'<tr><td class="id">{esc(e)}</td><td>{esc(titles[e])}</td><td class="c">{len(xs)}</td>'
        f'<td class="c">{sum(x["swp"] for x in xs)}</td><td class="c">{sum(x["matrix"] for x in xs)}</td>'
        f'<td class="c">{sum(x["hours"] for x in xs)}</td><td class="c">{round(sum(x["hours"] for x in xs) / max(1, sum(x["swp"] for x in xs)), 2)}</td>'
        f'<td class="c">{sum(1 for x in xs if x["flags"])}</td></tr>' for e, xs in by_epic.items())
    all_rows = "".join(
        f'<tr><td class="id">{esc(x["id"])}</td><td>{esc(x["title"])}</td><td class="c">{x["role"]}</td>'
        f'<td class="c">{x["s"]}</td><td class="c">{x["c"]}</td><td class="c">{x["matrix"]}</td>'
        f'<td class="c {"chg" if x["swp"] != x["matrix"] else ""}">{x["swp"]}</td><td class="c">{x["hours"]}</td>'
        f'<td>{flag_html(x["flags"])}</td></tr>' for x in scored)
    maxd = max(dist.values())
    bars = "".join(
        f'<div class="bar"><span class="lbl">{k} SWP</span><span class="b" style="width:{v / maxd * 100:.0f}%"></span>'
        f'<span class="v">{v}</span></div>' for k, v in sorted(dist.items()))
    t = result["totals"]
    status = ("Còn task phải tách: " + ", ".join(result["must_split"])) if result["must_split"] else (
        "Còn quyết định chưa áp vào data.typ: " + ", ".join(result["unapplied"]) if result["unapplied"] else (
            f'{len(result["pending"])} issue mẫu chưa review' if result["pending"] else "Mọi issue mẫu đã review và đã áp vào nguồn"))
    ok = not (result["must_split"] or result["unapplied"] or result["pending"])
    return f"""<!doctype html><html lang="vi"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Báo cáo chấm SWP</title><style>
:root{{--bg:#fff;--fg:#1d1d1f;--mut:#6b6b70;--line:#e2e2e6;--card:#f6f6f8;--acc:#2f5bd3;--ok:#1f7a3a;--warn:#b25e00}}
@media (prefers-color-scheme:dark){{:root{{--bg:#151517;--fg:#ececf0;--mut:#a0a0a8;--line:#33333a;--card:#1e1e22;--acc:#7c9cff;--ok:#5fc27e;--warn:#f0a050}}}}
*{{box-sizing:border-box}}body{{margin:0;background:var(--bg);color:var(--fg);font:14px/1.5 system-ui,"Segoe UI",sans-serif}}
main{{max-width:1180px;margin:0 auto;padding:24px 16px 64px}}h1{{font-size:24px;margin:0 0 4px}}h2{{font-size:18px;margin:32px 0 8px}}
.mut,.sub{{color:var(--mut)}}.sub{{font-size:12px}}.cards{{display:grid;grid-template-columns:repeat(auto-fit,minmax(150px,1fr));gap:10px;margin:16px 0}}
.card{{background:var(--card);border:1px solid var(--line);border-radius:8px;padding:10px 12px}}.card b{{display:block;font-size:22px}}
.status{{padding:10px 12px;border-radius:8px;border:1px solid var(--line);margin:12px 0;font-weight:600;color:{"var(--ok)" if ok else "var(--warn)"}}}
.wrap{{overflow-x:auto}}table{{border-collapse:collapse;width:100%;font-size:13px}}th,td{{border-bottom:1px solid var(--line);padding:6px 8px;text-align:left;vertical-align:top}}
th{{font-size:12px;color:var(--mut);font-weight:600}}td.c{{text-align:center;white-space:nowrap}}td.id{{white-space:nowrap;font-family:ui-monospace,Consolas,monospace;font-size:12px}}
.chg{{color:var(--warn)}}table.mx{{width:auto}}table.mx td{{width:48px;text-align:center;font-weight:600}}
.m1,.m2{{background:rgba(47,91,211,.08)}}.m3,.m5{{background:rgba(47,91,211,.18)}}.m8,.m13{{background:rgba(200,60,40,.22)}}
.flag{{display:inline-block;font-size:11px;padding:1px 6px;border-radius:10px;border:1px solid var(--line);margin:1px;white-space:nowrap}}
.f-PHAI_TACH,.f-LECH{{border-color:#c83c28;color:#c83c28}}.f-NGOAI_KHUNG,.f-C4{{border-color:var(--warn);color:var(--warn)}}.f-RANG_BUOC{{border-color:#a35200;background:rgba(255,160,60,.15)}}
.bar{{display:flex;align-items:center;gap:8px;margin:3px 0}}.bar .lbl{{width:60px;font-size:12px}}.bar .b{{height:14px;background:var(--acc);border-radius:3px}}.bar .v{{font-size:12px}}
</style></head><body><main>
<h1>Báo cáo chấm SWP</h1>
<div class="mut">Skill <code>skills/swp-scoring</code> · nguồn <code>backlog/data.typ</code> · tạo lúc {esc(result["generated"])} (JST)</div>
<div class="status">{esc(status)}</div>
<div class="cards"><div class="card">Task (leaf)<b>{t["leaves"]}</b></div><div class="card">SWP trong backlog<b>{t["swp"]}</b></div>
<div class="card">SWP theo ma trận<b>{t["matrix_swp"]}</b></div><div class="card">Giờ ước lượng<b>{t["hours"]}</b></div>
<div class="card">Giờ / SWP<b>{t["hours"] / t["swp"]:.2f}</b></div><div class="card">Issue mẫu<b>{len(sample)}</b></div></div>

<h2>1. Ma trận Scope × Complexity → SWP</h2>
<div class="wrap"><table class="mx"><tr><th></th><th>C1</th><th>C2</th><th>C3</th><th>C4</th></tr>{mat}</table></div>
<p class="sub">Khung giờ kiểm tra chéo: 1 → 2–5 h · 2 → 3–8 h · 3 → 5–12 h · 5 → 8–16 h · ≥ 8 → phải tách.</p>

<h2>2. Issue mẫu skill chọn để kiểm</h2>
<p class="sub">Mẫu = mọi task có cờ, cộng một task ngẫu nhiên (seed {SEED}) ở mỗi epic không có cờ. Cột "Người chốt" lấy từ <code>swp-report/review.json</code>.</p>
<div class="wrap"><table><tr><th>Task</th><th>Tiêu đề</th><th>Skill chấm</th><th>Giờ</th><th>Cờ</th><th>Người chốt</th><th>Lý do</th></tr>{"".join(sample_rows)}</table></div>
{"<h3>Task đã tách sau review</h3><div class=wrap><table><tr><th>Task cũ</th><th colspan=2>Trước</th><th>Chốt</th><th>Lý do</th></tr>" + hist + "</table></div>" if hist else ""}

<h2>3. Phân bố SWP</h2>{bars}

<h2>4. Tổng theo epic</h2>
<div class="wrap"><table><tr><th>Epic</th><th>Tên</th><th>Task</th><th>SWP</th><th>SWP ma trận</th><th>Giờ</th><th>Giờ/SWP</th><th>Task có cờ</th></tr>{epic_rows}</table></div>

<h2>5. Toàn bộ task</h2>
<div class="wrap"><table><tr><th>Task</th><th>Tiêu đề</th><th>Vai trò</th><th>S</th><th>C</th><th>Ma trận</th><th>Backlog</th><th>Giờ</th><th>Cờ</th></tr>{all_rows}</table></div>
</main></body></html>"""


if __name__ == "__main__":
    sys.exit(main())
