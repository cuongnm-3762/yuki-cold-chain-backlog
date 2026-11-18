// Burndown Sprint 1 (giả lập) — đọc sprint-1-daily.csv do tools/sprint_report.py sinh ra.
#set page(width: 190mm, height: 112mm, margin: 6mm, fill: white)
#set text(font: ("Segoe UI", "Meiryo"), size: 8pt, lang: "vi")

#let rows = csv("sprint-1-daily.csv", row-type: dictionary)
#let n = rows.len() - 1
#let ymax = calc.max(..rows.map(r => int(r.scope_swp))) + 6
#let W = 150mm
#let H = 72mm
#let px(d) = W * d / n
#let py(v) = H - H * v / ymax
#let poly(ps, st) = curve(stroke: st, curve.move(ps.first()), ..ps.slice(1).map(q => curve.line(q)))
#let pts(key) = rows.enumerate().map(((i, r)) => (px(i), py(float(r.at(key)))))

#align(center, text(11pt, weight: "bold")[Burndown Sprint 1 · 2026-11-30 → 2026-12-11 (giả lập) · đơn vị SWP])
#v(2mm)
#box(width: W + 16mm, height: H + 14mm)[
  #place(dx: 12mm, dy: 0mm, box(width: W, height: H)[
    // lưới ngang
    #for v in range(0, ymax + 1, step: 10) {
      place(dx: 0mm, dy: py(v), line(length: W, stroke: 0.3pt + luma(220)))
      place(dx: -9mm, dy: py(v) - 1.6mm, box(width: 7mm, align(right, text(7pt, fill: luma(110), str(v)))))
    }
    // trục ngày
    #for (i, r) in rows.enumerate() {
      place(dx: px(i) - 5mm, dy: H + 1.5mm, box(width: 10mm, align(center, text(6.5pt, fill: luma(90),
        if i == 0 [KH] else [N#i \ #r.date.slice(5)]))))
    }
    #place(line(start: (0mm, H), end: (W, H), stroke: 0.6pt + luma(120)))
    #place(line(start: (0mm, 0mm), end: (0mm, H), stroke: 0.6pt + luma(120)))
    // phạm vi (scope)
    #place(poly(pts("scope_swp"), (paint: rgb("#b36b00"), thickness: 1pt, dash: "dotted")))
    // lý tưởng
    #place(poly(pts("ideal"), (paint: luma(140), thickness: 1pt, dash: "dashed")))
    // thực tế
    #place(poly(pts("remaining_swp"), (paint: rgb("#2f5bd3"), thickness: 1.6pt)))
    #for (x, y) in pts("remaining_swp") { place(dx: x - 0.9mm, dy: y - 0.9mm, circle(radius: 0.9mm, fill: rgb("#2f5bd3"))) }
    #let last = rows.last()
    #place(dx: px(n) - 30mm, dy: py(float(last.remaining_swp)) - 6mm,
      box(width: 29mm, align(right, text(7.5pt, fill: rgb("#2f5bd3"), weight: "bold")[còn #last.remaining_swp SWP])))
  ])
]
#v(-2mm)
#align(center)[
  #box(line(length: 8mm, stroke: 1.6pt + rgb("#2f5bd3"))) SWP còn lại (thực tế)
  #h(5mm) #box(line(length: 8mm, stroke: (paint: luma(140), thickness: 1pt, dash: "dashed"))) Lý tưởng theo kế hoạch
  #h(5mm) #box(line(length: 8mm, stroke: (paint: rgb("#b36b00"), thickness: 1pt, dash: "dotted"))) Phạm vi sprint (có task phát sinh)
]
