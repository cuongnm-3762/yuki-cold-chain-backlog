"""Số liệu Sprint 1 (giả lập) từ nguồn Typst → sprint/sprint-1-daily.csv, sprint/sprint-1-summary.json,
rồi dựng sprint/burndown.png bằng Typst (sprint/burndown.typ đọc CSV).

  python -X utf8 tools/sprint_report.py
"""
from __future__ import annotations

import csv
import json
import subprocess
import sys
from collections import defaultdict
from datetime import date, timedelta
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from backlog import ROOT, leaves, load_raw, rows  # noqa: E402

OUT = ROOT / "sprint"
DAYS = 10


def workdays(start: date, n: int) -> list[date]:
    out, d = [], start
    while len(out) < n:
        if d.weekday() < 5:
            out.append(d)
        d += timedelta(days=1)
    return out


def main() -> None:
    raw = load_raw()
    rs = rows(raw)
    lv = leaves(rs)
    s1 = [x for x in lv if x["iteration"] == "Sprint 1"]
    it = next(i for i in raw["iterations"] if i["id"] == "S1")
    dates = workdays(date.fromisoformat(it["start"]), DAYS)

    # add-day lấy từ nguồn (addday); task kế hoạch có add-day = 0
    added_day = {}
    for e in raw["epics"]:
        for i in e["issues"]:
            for n, t in enumerate(i["tasks"], 1):
                if t.get("addday"):
                    tid = i["id"] if len(i["tasks"]) == 1 else f"{i['id']}-{n}"
                    added_day[tid] = t["addday"]
    planned = [x for x in s1 if x["id"] not in added_day]
    plan_swp = sum(x["swp"] for x in planned)
    plan_h = sum(x["hours"] for x in planned)

    daily = []
    for d in range(0, DAYS + 1):
        scope = [x for x in s1 if added_day.get(x["id"], 0) <= d]
        done = [x for x in scope if x["status"] == "Done" and x["done_day"] and x["done_day"] <= d]
        scope_swp = sum(x["swp"] for x in scope)
        daily.append(dict(
            day=d, date=(dates[d - 1] if d else dates[0] - timedelta(days=3)).isoformat() if d else "kế hoạch",
            ideal=round(plan_swp * (1 - d / DAYS), 1), scope_swp=scope_swp,
            remaining_swp=scope_swp - sum(x["swp"] for x in done),
            done_swp=sum(x["swp"] for x in done), done_tasks=len(done),
            remaining_h=sum(x["hours"] for x in scope) - sum(x["hours"] for x in done),
        ))
    OUT.mkdir(exist_ok=True)
    with open(OUT / "sprint-1-daily.csv", "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=list(daily[0]))
        w.writeheader()
        w.writerows(daily)

    by_status = defaultdict(lambda: dict(n=0, swp=0, h=0, act=0, rem=0, ids=[]))
    for x in s1:
        b = by_status[x["status"]]
        b["n"] += 1
        b["swp"] += x["swp"]
        b["h"] += x["hours"]
        b["act"] += x["actual"] or 0
        b["rem"] += x["remaining"] or 0
        b["ids"].append(x["id"])
    owners = defaultdict(lambda: dict(plan=0, act=0))
    for x in s1:
        owners[x["owner"]]["plan"] += x["hours"]
        owners[x["owner"]]["act"] += x["actual"] or 0
    cap = {m["who"]: m["cap"] for m in raw["team"]}
    overrun = sorted(((x["id"], x["hours"], x["actual"]) for x in s1 if x["actual"] and x["actual"] > x["hours"]),
                     key=lambda t: t[2] - t[1], reverse=True)
    all_status = defaultdict(lambda: dict(n=0, swp=0, h=0))
    for x in lv:
        all_status[x["status"]]["n"] += 1
        all_status[x["status"]]["swp"] += x["swp"]
        all_status[x["status"]]["h"] += x["hours"]
    by_epic = {}
    for e in raw["epics"]:
        xs = [x for x in lv if x["epic"] == e["id"]]
        by_epic[e["id"]] = dict(title=e["title"], swp=sum(x["swp"] for x in xs),
                                done=sum(x["swp"] for x in xs if x["status"] == "Done"),
                                s1=sum(x["swp"] for x in xs if x["iteration"] == "Sprint 1"))
    summary = dict(
        iteration=it, dates=[d.isoformat() for d in dates], planned_swp=plan_swp, planned_h=plan_h,
        added=[dict(id=k, day=v, swp=next(x["swp"] for x in s1 if x["id"] == k),
                    h=next(x["hours"] for x in s1 if x["id"] == k)) for k, v in added_day.items()],
        final_scope_swp=daily[-1]["scope_swp"], done_swp=daily[-1]["done_swp"],
        velocity_swp=daily[-1]["done_swp"], by_status=by_status, owners=owners, capacity=cap, overrun=overrun,
        actual_h=sum(x["actual"] or 0 for x in s1), backlog_status=all_status, by_epic=by_epic,
        backlog_total=dict(swp=sum(x["swp"] for x in lv), h=sum(x["hours"] for x in lv), n=len(lv)),
        sprints={i["title"]: dict(swp=sum(x["swp"] for x in lv if x["iteration"] == i["title"]),
                                  h=sum(x["hours"] for x in lv if x["iteration"] == i["title"])) for i in raw["iterations"]},
    )
    (OUT / "sprint-1-summary.json").write_text(json.dumps(summary, ensure_ascii=False, indent=1), encoding="utf-8")
    subprocess.run(["typst", "compile", str(OUT / "burndown.typ"), str(OUT / "burndown.png"), "--ppi", "160",
                    "--root", str(ROOT)], check=True)
    print(json.dumps({k: summary[k] for k in ("planned_swp", "planned_h", "final_scope_swp", "done_swp", "actual_h")},
                     ensure_ascii=False))
    for d in daily:
        print(d)
    for k, v in by_status.items():
        print(k, {kk: vv for kk, vv in v.items()})
    print(dict(owners))
    print("overrun", overrun)
    print("sprints", summary["sprints"])


if __name__ == "__main__":
    main()
