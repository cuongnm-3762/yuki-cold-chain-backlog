---
name: swp-scoring
description: Chấm SWP (story point) cho từng task của backlog bằng ma trận Scope × Complexity, kiểm số giờ ước lượng có nằm trong khung của mức SWP đó không, chọn các issue mẫu cần người review, và xuất báo cáo HTML. Dùng khi vừa break xong hoặc sửa backlog trong backlog/data.typ, trước khi ghi SWP lên GitHub Project.
---

# swp-scoring

Skill này do nhóm tự viết cho bài LAB-5. Bộ skill nội bộ takumi (`sun-asterisk-internal/takumi`) không có skill chấm SWP; ở đó chỉ có `git-issues` và `git-projects` để thao tác GitHub.

## Đầu vào

- `backlog/data.typ`: nguồn duy nhất. Mỗi task có `s` (Scope 1–4), `c` (Complexity 1–4), `h` (giờ) và `swp` (giá trị đang ghi trong backlog, đã được người chốt sau review).
- `swp-report/review.json` (không bắt buộc): quyết định của người review cho các issue mẫu, theo dạng `{ "<task id>": {"final": <swp>, "hours": <giờ hoặc null>, "reason": "..."} }`.

## Thang chấm

**Scope (S)**: phạm vi chạm tới
1. một hàm hoặc một tệp
2. một tầng (DB, API hoặc UI), vài tệp
3. xuyên tầng, hoặc trọn một màn hình
4. nhiều mô-đun hoặc có hệ thống bên ngoài

**Complexity (C)**: độ khó của logic
1. hiển thị hoặc CRUD
2. quy tắc kiểm tra thông thường
3. nhiều nhánh, đồng thời hoặc giao dịch
4. thuật toán, quy định pháp lý, độ bất định cao

**Ma trận S × C → SWP** (thang Fibonacci rút gọn)

| S \ C | 1 | 2 | 3 | 4 |
|---|---|---|---|---|
| 1 | 1 | 1 | 2 | 3 |
| 2 | 1 | 2 | 3 | 5 |
| 3 | 2 | 3 | 5 | 8 |
| 4 | 3 | 5 | 8 | 13 |

**Khung giờ hợp lệ theo SWP** (để kiểm tra chéo, không dùng để quy đổi): 1 → 2–5 h · 2 → 3–8 h · 3 → 5–12 h · 5 → 8–16 h. SWP ≥ 8 nghĩa là task quá lớn và **phải tách**.

## Cờ và cách chọn issue mẫu

| Cờ | Điều kiện | Vì sao cần người xem |
|---|---|---|
| `LECH` | `swp` trong backlog ≠ ma trận | người đã ghi đè; phải có lý do |
| `NGOAI_KHUNG` | giờ nằm ngoài khung của mức SWP theo ma trận | S/C hoặc giờ có thể sai |
| `PHAI_TACH` | SWP theo ma trận ≥ 8 | task quá to |
| `C4` | Complexity = 4 | bất định cao, dễ trượt |
| `RANG_BUOC` | thuộc epic có ràng buộc đặc thù (giờ lái 2024) và C ≥ 3 | phần chịu quy định pháp lý |

Mẫu = mọi task có ít nhất một cờ, cộng thêm **một task ngẫu nhiên có seed cố định** trong mỗi epic chưa có task nào bị cờ, để kiểm tra cả phần "trông có vẻ ổn".

## Cách chạy

```bash
python -X utf8 skills/swp-scoring/scripts/score.py
```

Script ghi `swp-report/index.html` và `swp-report/result.json`, rồi in tóm tắt. Mã thoát là 1 nếu còn task `PHAI_TACH`, hoặc nếu `review.json` chốt một giá trị khác với `swp` đang ghi trong `data.typ` (nghĩa là chưa áp quyết định vào nguồn).

## Quy trình

1. Chạy script và mở `swp-report/index.html`.
2. Với mỗi issue mẫu, người review ghi quyết định vào `swp-report/review.json`. Mọi quyết định đều cần lý do, kể cả khi giữ nguyên.
3. Áp quyết định vào `backlog/data.typ`: sửa `swp`, sửa `h`, hoặc tách task.
4. Chạy lại script cho tới khi mã thoát là 0.
5. Sau đó mới ghi SWP lên Project: `python -X utf8 tools/gh_sync.py fields`. Agent đối chiếu bằng cách đọc lại field trên Project.
