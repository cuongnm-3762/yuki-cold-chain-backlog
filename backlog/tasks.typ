// Danh sách task & subtask — bản in từ data.typ (nguồn duy nhất).
// Build: typst compile backlog/tasks.typ backlog/out/tasks.pdf
// Xuất Excel/CSV: python tools/export.py   (đọc <backlog> qua `typst eval`)
#import "data.typ": team, iterations, epics

#metadata((team: team, iterations: iterations, epics: epics)) <backlog>

#set document(title: "Yuki Cold Chain — Backlog task & subtask")
#set page(paper: "a4", flipped: true, margin: (x: 12mm, y: 12mm),
  footer: context [#set text(7pt, fill: gray); Yuki Cold Chain backlog · nguồn `backlog/data.typ` #h(1fr) #counter(page).display("1 / 1", both: true)])
#set text(font: ("Segoe UI", "Noto Sans JP", "Meiryo"), size: 8pt, lang: "vi")
#set table(stroke: 0.4pt + luma(180), inset: (x: 4pt, y: 3pt))

// ---- tính toán (cùng quy tắc với tools/export.py) ----
#let leaf-of(i) = i.tasks.len() == 1
#let sum(xs) = xs.fold(0, (a, b) => a + b)
#let issue-swp(i) = sum(i.tasks.map(t => t.swp))
#let issue-h(i) = sum(i.tasks.map(t => t.h))
#let epic-swp(e) = sum(e.issues.map(issue-swp))
#let epic-h(e) = sum(e.issues.map(issue-h))
#let roll-status(i) = {
  let s = i.tasks.map(t => t.st)
  if s.all(x => x == "Done") { "Done" }
  else if s.any(x => x == "Blocked") { "Blocked" }
  else if s.any(x => x != "Todo") { "In Progress" }
  else { "Todo" }
}
#let st-color(s) = (
  "Done": rgb("#d1f0d8"), "In Review": rgb("#dce8fb"), "In Progress": rgb("#fff1c2"),
  "Blocked": rgb("#fbd5d5"), "Todo": white,
).at(s)
#let it-title(id) = iterations.find(x => x.id == id).title
#let all-tasks = epics.map(e => e.issues.map(i => i.tasks)).flatten()

= Yuki Cold Chain — Backlog task & subtask
#v(-4pt)
#text(9pt)[Mã học viên B123762 · Đề Product B · Break từ bộ thiết kế chi tiết LAB-4 (`specs/`) + `PREMISE.md` của repo này · trạng thái tính đến cuối Sprint 1 (2026-12-11, giả lập)]

#grid(columns: (1fr, 1fr, 1fr, 1fr), gutter: 6pt,
  ..(
    ("Epic", str(epics.len())),
    ("Issue", str(sum(epics.map(e => e.issues.len())))),
    ("Task (leaf)", str(all-tasks.len())),
    ("Tổng SWP / giờ", str(sum(all-tasks.map(t => t.swp))) + " SWP / " + str(sum(all-tasks.map(t => t.h))) + " h"),
  ).map(((k, v)) => box(width: 100%, inset: 6pt, stroke: 0.5pt + luma(160), radius: 3pt)[#text(7pt, fill: gray)[#k] \ #text(12pt, weight: "bold")[#v]])
)

#v(4pt)
*Quy ước.* Issue có một task duy nhất là *leaf* (tự mang SWP và giờ, không có sub-issue). Issue có ≥ 2 task thì mỗi task là một *sub-issue*; SWP và giờ của issue = tổng các sub-issue. Epic gắn nhãn #box(fill: rgb("#ffe0b2"), inset: 2pt)[Giờ lái 2024] là hạng mục chịu ràng buộc giới hạn giờ lái xe tải từ 2024-04-01. S = Scope, C = Complexity (thang 1–4, xem `skills/swp-scoring`).

#let head = ("ID", "Loại", "Tiêu đề", "Vai trò", "S", "C", "SWP", "Giờ", "Iteration", "Phụ trách", "Trạng thái")

#for e in epics [
  #v(6pt)
  #block(breakable: false)[
    == #e.id — #e.title #if e.lim == "driver-2024" [#box(fill: rgb("#ffe0b2"), inset: 2pt, text(8pt)[Giờ lái 2024])]
    #text(8pt)[#e.goal] \
    #text(7pt, fill: gray)[Spec: #e.spec · #e.issues.len() issue · #epic-swp(e) SWP · #epic-h(e) h]
  ]
  #table(
    columns: (auto, auto, 1fr, auto, auto, auto, auto, auto, auto, auto, auto),
    align: (x, y) => if x in (4, 5, 6, 7) { right } else { left },
    table.header(..head.map(h => text(weight: "bold", h))),
    ..e.issues.map(i => {
      let rows = ()
      if leaf-of(i) {
        let t = i.tasks.at(0)
        rows += (
          text(weight: "bold", i.id), [Issue], [#i.title], t.r, str(t.s), str(t.c), str(t.swp), str(t.h),
          it-title(t.it), t.who, table.cell(fill: st-color(t.st), t.st),
        )
      } else {
        rows += (
          text(weight: "bold", i.id), [Issue], text(weight: "bold")[#i.title], [], [], [],
          text(weight: "bold", str(issue-swp(i))), text(weight: "bold", str(issue-h(i))), [], [],
          table.cell(fill: st-color(roll-status(i)), roll-status(i)),
        )
        for (n, t) in i.tasks.enumerate() {
          rows += (
            i.id + "-" + str(n + 1), [Sub], [#h(8pt)#t.t#if t.at("add", default: false) [ _(phát sinh)_]],
            t.r, str(t.s), str(t.c), str(t.swp), str(t.h), it-title(t.it), t.who,
            table.cell(fill: st-color(t.st), t.st),
          )
        }
      }
      rows
    }).flatten()
  )
]
