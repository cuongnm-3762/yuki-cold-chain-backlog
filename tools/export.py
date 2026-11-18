"""Xuất backlog (nguồn Typst) ra backlog/out/tasks.xlsx và backlog/out/tasks.csv, và PDF.

Chạy:  python -X utf8 tools/export.py
"""
from __future__ import annotations

import csv
import subprocess
import sys
from pathlib import Path

from openpyxl import Workbook
from openpyxl.styles import Alignment, Font, PatternFill
from openpyxl.utils import get_column_letter

sys.path.insert(0, str(Path(__file__).resolve().parent))
from backlog import ROOT, TYP, leaves, load_raw, rows  # noqa: E402

OUT = ROOT / "backlog" / "out"
COLS = [
    ("level", "Cấp"), ("id", "ID"), ("parent", "Cha"), ("epic", "Epic"), ("title", "Tiêu đề"),
    ("role", "Vai trò"), ("scope", "Scope (S)"), ("cx", "Complexity (C)"), ("swp", "SWP"),
    ("hours", "Giờ ước lượng"), ("iteration", "Iteration"), ("owner", "Phụ trách (giả định)"),
    ("status", "Trạng thái"), ("actual", "Giờ thực tế"), ("constraint", "Ràng buộc đặc thù"),
    ("spec", "Spec"),
]
FILL = {
    "Epic": PatternFill("solid", fgColor="1F3864"), "Issue": PatternFill("solid", fgColor="D9E2F3"),
}
ST = {"Done": "D1F0D8", "In Review": "DCE8FB", "In Progress": "FFF1C2", "Blocked": "FBD5D5"}


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    subprocess.run(["typst", "compile", str(TYP), str(OUT / "tasks.pdf"), "--root", str(ROOT)], check=True)
    raw = load_raw()
    rs = rows(raw)

    with open(OUT / "tasks.csv", "w", newline="", encoding="utf-8-sig") as f:
        w = csv.writer(f)
        w.writerow([h for _, h in COLS])
        for r in rs:
            w.writerow([r.get(k, "") if r.get(k) is not None else "" for k, _ in COLS])

    wb = Workbook()
    ws = wb.active
    ws.title = "Backlog"
    ws.append([h for _, h in COLS])
    for c in ws[1]:
        c.font = Font(bold=True, color="FFFFFF")
        c.fill = PatternFill("solid", fgColor="404040")
        c.alignment = Alignment(wrap_text=True, vertical="center")
    for r in rs:
        ws.append([r.get(k, "") if r.get(k) is not None else "" for k, _ in COLS])
        row = ws.max_row
        if r["level"] == "Epic":
            for c in ws[row]:
                c.font = Font(bold=True, color="FFFFFF")
                c.fill = FILL["Epic"]
        elif r["level"] == "Issue":
            for c in ws[row]:
                c.font = Font(bold=True)
                c.fill = FILL["Issue"]
        st = r.get("status")
        if st in ST:
            ws.cell(row=row, column=13).fill = PatternFill("solid", fgColor=ST[st])
    widths = [9, 11, 9, 7, 60, 7, 8, 10, 6, 9, 10, 12, 12, 9, 14, 50]
    for n, wdt in enumerate(widths, 1):
        ws.column_dimensions[get_column_letter(n)].width = wdt
    ws.freeze_panes = "C2"
    ws.auto_filter.ref = ws.dimensions

    # Sheet tổng theo epic
    s2 = wb.create_sheet("Tổng theo epic")
    s2.append(["Epic", "Tiêu đề", "Ràng buộc", "Số issue", "Số task (leaf)", "Tổng SWP", "Tổng giờ"])
    for c in s2[1]:
        c.font = Font(bold=True)
    lv = leaves(rs)
    for e in raw["epics"]:
        el = [x for x in lv if x["epic"] == e["id"]]
        s2.append([e["id"], e["title"], "Giờ lái 2024" if e.get("lim") else "", len(e["issues"]), len(el),
                   sum(x["swp"] for x in el), sum(x["hours"] for x in el)])
    s2.append(["Tổng", "", "", sum(len(e["issues"]) for e in raw["epics"]), len(lv),
               sum(x["swp"] for x in lv), sum(x["hours"] for x in lv)])
    for col, wdt in zip("ABCDEFG", [8, 55, 14, 9, 13, 10, 10]):
        s2.column_dimensions[col].width = wdt

    # Sheet nhóm
    s3 = wb.create_sheet("Nhóm (giả định)")
    s3.append(["Người", "Vai trò", "Năng lực mỗi sprint (giờ)"])
    for m in raw["team"]:
        s3.append([m["who"], m["role"], m["cap"]])
    wb.save(OUT / "tasks.xlsx")
    print(f"rows={len(rs)} leaves={len(lv)} swp={sum(x['swp'] for x in lv)} h={sum(x['hours'] for x in lv)}")


if __name__ == "__main__":
    main()
