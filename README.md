# Yuki Cold Chain — Backlog & tiến độ (LAB-5)

**Dự án:** Hệ thống hỗ trợ nghiệp vụ chuỗi lạnh thực phẩm cho Yuki Cold Logistics (RFP YCL-RFP-2026-01) · **Mã học viên:** B123762 · **Đề:** Product B

## Tổng quan

- **Nguồn break:** bộ thiết kế chi tiết đã nộp ở LAB-4 (`specs/`: 14 màn lõi + 4 màn hỗ trợ, `system/rules/*`, API, CSDL, ADR). [`PREMISE.md`](PREMISE.md) **có thay đổi** so với LAB-4:
  - 4 sửa đổi spec phát hiện khi break (B-01…B-04, đều thuộc phần giờ lái 2024 hoặc lịch sử giao);
  - 6 giả định bổ sung (A-01…A-06);
  - 7 hướng đã chốt.
- **Quy mô:** **10 epic** · 52 issue (14 leaf + 38 có sub-issue) · 92 sub-issue · 106 task (leaf) · **237 SWP · 719 giờ**. Ba epic chịu ràng buộc giới hạn giờ lái xe tải từ 2024 được tách riêng: EP-07, EP-08, EP-09, tổng 89 SWP / 253 h.
- **Sprint giả lập đã chạy:** **Sprint 1** (2026-11-30 → 2026-12-11). Kế hoạch 79 SWP, có 1 SWP phát sinh, hoàn thành 67 SWP (84 %). Báo cáo ở [`progress-report.md`](progress-report.md). Sprint 2–4 đã xếp lịch trên Project nhưng chưa chạy.

## Link

| | |
|---|---|
| Repo | https://github.com/cuongnm-3762/yuki-cold-chain-backlog |
| GitHub Project | https://github.com/users/cuongnm-3762/projects/2 |
| Báo cáo HTML của skill chấm SWP (trong repo) | [`swp-report/index.html`](swp-report/index.html). Xem trực tiếp: https://htmlpreview.github.io/?https://github.com/cuongnm-3762/yuki-cold-chain-backlog/blob/main/swp-report/index.html |

Project có hai view (tạo trên giao diện web, vì API của GitHub không tạo được view):
- **Backlog**: bảng phân cấp epic → issue → sub-issue.
- **Board Sprint 1**: cột theo `Status`, tổng SWP ở đầu mỗi cột. Lọc `iteration:"Sprint 1" -Cấp:Epic no:sub-issues-progress`, tức chỉ lấy task leaf để SWP không bị cộng hai lần ở issue cha. Tổng các cột là 80 SWP; cột Done là 67, khớp [`progress-report.md`](progress-report.md).

Đã mở thử cả ba link bằng trình duyệt **chưa đăng nhập GitHub**: cửa sổ trình duyệt riêng của Claude Code, tương đương cửa sổ ẩn danh. Repo, Project (public) và báo cáo HTML đều xem được.

## Cấu trúc repo

| File / thư mục | Nội dung |
|---|---|
| `README.md` | File này |
| [`PREMISE.md`](PREMISE.md) | Tiền đề: backlog khác bộ spec LAB-4 ở đâu (sửa spec, giả định, hướng đã chốt) |
| [`task-breakdown.md`](task-breakdown.md) | Nguyên tắc chia task, spec → issue, hạng mục chịu ràng buộc giờ lái 2024, chỗ hở của spec |
| [`estimate.md`](estimate.md) | Issue mẫu skill chọn, cách quy ra giờ, tổng theo epic, so với estimate lần đầu |
| [`progress-report.md`](progress-report.md) | Báo cáo Sprint 1: trạng thái, burndown, rủi ro trễ |
| [`AI-report.md`](AI-report.md) | Skill và prompt đã dùng, cách review output của AI, điểm đặc biệt |
| `backlog/data.typ` | **Nguồn duy nhất** của backlog (epic → issue → task, S/C, SWP, giờ, iteration, người phụ trách, trạng thái) |
| `backlog/tasks.typ` | Bản in danh sách task và subtask; xuất ra `backlog/out/tasks.pdf` |
| `backlog/out/` | `tasks.pdf`, `tasks.xlsx`, `tasks.csv`, sinh từ nguồn Typst |
| `swp-report/` | Báo cáo HTML của skill chấm SWP (`index.html`), `result.json`, quyết định review `review.json` |
| `skills/swp-scoring/` | Skill chấm SWP tự viết (`SKILL.md` + `scripts/score.py`), vì bộ skill takumi không có skill này |
| `sprint/` | Số liệu Sprint 1 theo ngày (`sprint-1-daily.csv`), tổng hợp (`sprint-1-summary.json`), burndown (`burndown.typ` → `burndown.png`) |
| `tools/` | `backlog.py` (đọc nguồn Typst), `export.py` (PDF/Excel/CSV), `gh_sync.py` (issue, sub-issue, Project, field), `sprint_report.py` (burndown), `gh_map.json` (ID ↔ số issue), `project-readme.md` (README của Project) |
| `.gitignore` | Bỏ cache Python |

Chạy lại toàn bộ, theo thứ tự:
1. `python -X utf8 skills/swp-scoring/scripts/score.py`
2. `python -X utf8 tools/export.py`
3. `python -X utf8 tools/sprint_report.py`
4. `python -X utf8 tools/gh_sync.py issues|subs|items|fields|states`

## Spec → epic

| Spec (mã / file hoặc dòng PREMISE) | Epic trên Project (#số — tên) | Ghi chú |
|---|---|---|
| `system/security/rbac.md`, `system/api-contracts/error-codes.md`, `requirements/app/common/*`, ADR-0005, GAP-01/03/06/10 | #1 — EP-01 Nền tảng: phân quyền, RLS, audit, mã lỗi | |
| `requirements/app/inbound-inspection/*`, `system/rules/temperature-bands.md` T-02/T-03 | #29 — EP-02 Kiểm nhập | |
| `requirements/app/outbound-allocation-shipping/*`, `system/rules/allocation-chain.md` | #43 — EP-03 Phân bổ lô và kiểm xuất | |
| `requirements/app/date-reversal-alert/*`, Rule A-06 | #61 — EP-04 Cảnh báo đảo hạn | |
| `requirements/app/inventory-lot-status/*`, PREMISE B-04 | #68 — EP-05 Tồn kho, trạng thái lô và lịch sử giao | |
| `requirements/app/temperature-policy/*`, PM-05/PM-06 (LAB-4) | #80 — EP-06 Ngưỡng nhiệt 3 dải có phiên bản | |
| `system/rules/driver-hours.md` (H-01…H-12), `route-driver-hours/DRIVER_RULESET_SPEC.md`, ADR-0003, PREMISE B-01 | #90 — EP-07 [Giờ lái 2024] Bộ quy tắc và engine `evaluateRoute` | **Ràng buộc giờ lái 2024**; làm rõ pháp lý Q-15 (#113) |
| `route-driver-hours/ROUTE_LIST_SPEC.md`, `ROUTE_CHECK_SPEC.md`, API-RT-01…08, IF-MAP-01, PREMISE A-02/A-04 | #116 — EP-08 [Giờ lái 2024] Lập tuyến, kiểm tra và công bố | **Ràng buộc giờ lái 2024**; chặn công bố khi có BLOCK |
| `table-definitions.md` `drivers`, `driver_duty_days`, SYS-DH-01, PREMISE B-02/B-03/A-01/A-03 | #138 — EP-09 [Giờ lái 2024] Dữ liệu đầu vào giờ làm của tài xế | **Ràng buộc giờ lái 2024**; epic mới, sinh từ chỗ hở phát hiện khi break |
| `system/nfr/nfr.md`, `system/architecture/overview.md`, ADR-0009 | #147 — EP-10 Hạ tầng, kiểm thử xuyên suốt và phát hành | |
