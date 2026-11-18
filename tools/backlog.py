"""Đọc backlog từ nguồn Typst (backlog/data.typ qua tasks.typ) và làm phẳng thành các dòng.

Mọi tool khác (export, gh_sync, sprint_report, skill swp-scoring) dùng module này để
không ai đọc dữ liệu theo cách riêng.
"""
from __future__ import annotations

import json
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
TYP = ROOT / "backlog" / "tasks.typ"

CONSTRAINT_LABEL = {"driver-2024": "Giờ lái 2024"}


def load_raw() -> dict:
    out = subprocess.run(
        ["typst", "eval", "query(<backlog>).first().value", "--in", str(TYP), "--format", "json",
         "--root", str(ROOT)],
        check=True, capture_output=True, text=True, encoding="utf-8",
    ).stdout
    return json.loads(out)


def rows(raw: dict | None = None) -> list[dict]:
    """Một dòng cho mỗi epic, issue và sub-issue. Leaf issue (1 task) không có dòng sub."""
    raw = raw or load_raw()
    its = {i["id"]: i["title"] for i in raw["iterations"]}
    out: list[dict] = []
    for e in raw["epics"]:
        lim = CONSTRAINT_LABEL.get(e.get("lim", ""), "")
        e_swp = sum(t["swp"] for i in e["issues"] for t in i["tasks"])
        e_h = sum(t["h"] for i in e["issues"] for t in i["tasks"])
        out.append(dict(level="Epic", id=e["id"], parent="", epic=e["id"], title=e["title"], role="",
                        scope="", cx="", swp=e_swp, hours=e_h, iteration="", owner="", status="",
                        actual="", constraint=lim, kind="epic", spec=e["spec"], desc=e["goal"], ac=[]))
        for i in e["issues"]:
            tasks = i["tasks"]
            kind = i.get("kind", "story")
            if len(tasks) == 1:
                t = tasks[0]
                out.append(_task_row(t, level="Issue", id=i["id"], parent=e["id"], epic=e["id"], title=i["title"],
                                     its=its, lim=lim, kind=kind, spec=i["spec"], desc=i["desc"], ac=i["ac"],
                                     task_title=t["t"]))
                continue
            sts = [t["st"] for t in tasks]
            if all(s == "Done" for s in sts):
                roll = "Done"
            elif "Blocked" in sts:
                roll = "Blocked"
            elif any(s != "Todo" for s in sts):
                roll = "In Progress"
            else:
                roll = "Todo"
            iters = sorted({t["it"] for t in tasks})
            out.append(dict(level="Issue", id=i["id"], parent=e["id"], epic=e["id"], title=i["title"], role="",
                            scope="", cx="", swp=sum(t["swp"] for t in tasks), hours=sum(t["h"] for t in tasks),
                            iteration=its[iters[0]], owner="", status=roll,
                            actual=sum(t.get("act", 0) for t in tasks) or "", constraint=lim, kind=kind,
                            spec=i["spec"], desc=i["desc"], ac=i["ac"]))
            for n, t in enumerate(tasks, 1):
                out.append(_task_row(t, level="Sub-issue", id=f"{i['id']}-{n}", parent=i["id"], epic=e["id"],
                                     title=t["t"], its=its, lim=lim, kind="task", spec=i["spec"], desc="", ac=[],
                                     task_title=t["t"]))
    return out


def _task_row(t, *, level, id, parent, epic, title, its, lim, kind, spec, desc, ac, task_title):
    return dict(level=level, id=id, parent=parent, epic=epic, title=title, role=t["r"], scope=t["s"], cx=t["c"],
                swp=t["swp"], hours=t["h"], iteration=its[t["it"]], owner=t["who"], status=t["st"],
                actual=t.get("act", ""), constraint=lim, kind=kind, spec=spec, desc=desc, ac=ac,
                task_title=task_title, added=t.get("add", False), done_day=t.get("done"), remaining=t.get("rem"),
                leaf=True)


def leaves(rs: list[dict] | None = None) -> list[dict]:
    """Các đơn vị mang SWP/giờ thật: leaf issue và sub-issue."""
    rs = rs if rs is not None else rows()
    return [r for r in rs if r.get("leaf")]
