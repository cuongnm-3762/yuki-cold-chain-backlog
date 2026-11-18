Backlog break từ bộ thiết kế chi tiết Yuki Cold Chain (LAB-4). Mã học viên B123762 · đề Product B.

**Cấu trúc:** Epic → Issue → Sub-issue (quan hệ sub-issue của GitHub). Issue chỉ có một task là leaf, không có sub-issue.

**Field**
- `Status`: Todo · In Progress · In Review · Blocked · Done
- `Iteration`: Sprint 1–4, mỗi sprint 2 tuần; Sprint 1 (2026-11-30 → 2026-12-11) là sprint giả lập đã chạy
- `SWP`: story point đã review bằng skill `swp-scoring`. Ở issue và epic là tổng của các con
- `Giờ ước lượng`, `Giờ thực tế` (giờ thực tế chỉ có ở Sprint 1)
- `Phụ trách (giả định)`: tên người giả định, vì repo chỉ có một tài khoản thật
- `Cấp`, `Vai trò`, `Ràng buộc`, `Mã backlog`

**Ràng buộc đặc thù:** các item có `Ràng buộc = Giờ lái 2024` (epic EP-07, EP-08, EP-09) chịu quy định giới hạn giờ lái xe tải áp dụng từ 2024-04-01.

Nguồn dữ liệu duy nhất là `backlog/data.typ` trong repo, đồng bộ lên đây bằng `tools/gh_sync.py`.
