# AI report — LAB-5 (break task, estimate, GitHub Project, báo cáo tiến độ)

Công cụ: Claude Code (model Claude Opus) trên Windows, dùng `gh` CLI và GraphQL API của GitHub, Typst 0.15, Python (openpyxl).

## 1. Skill và cách viết prompt cho từng việc

**Đầu vào chung.** Người dùng dán nguyên đề bài LAB-5 làm prompt, rồi trả lời ba câu hỏi chặn của AI:
1. Lấy skill chấm SWP ở đâu: "tìm trong skill của takumi, nếu có thì sử dụng, không có thì tự viết".
2. Tên và owner repo.
3. Đã cấp quyền `project` cho `gh`.

Yêu cầu riêng của người dùng: danh sách task phải viết bằng **Typst**, rồi xuất sang Excel và CSV. AI mở rộng yêu cầu này thành nguyên tắc **một nguồn duy nhất** (`backlog/data.typ`): PDF, Excel, CSV, issue và field trên GitHub, báo cáo SWP và burndown đều sinh từ file đó bằng script. Không có bản nào sửa tay.

| Việc | Skill / công cụ | Cách viết prompt / chỉ dẫn |
|---|---|---|
| Tìm skill | takumi (`sun-asterisk-internal/takumi`), catalog plugin | AI tìm cả bản cài cục bộ (`~/.takumi`) lẫn repo takumi, bằng từ khóa `swp`, `estimat`, `point`, `complex`. Không có skill chấm SWP; chỉ có `git-issues` (mẫu issue Sun*: Epic / Story / Dev Task) và `git-projects` (thao tác ProjectV2 theo kiểu ghi xong đọc lại). AI dùng mẫu body của `git-issues` cho nội dung issue, và cách ghi xong đọc lại của `git-projects` cho script đồng bộ |
| Break task | Không có skill; đọc trực tiếp bộ spec LAB-4 | Chỉ dẫn gồm: break từ `specs/` của LAB-4, không từ 82 feature của proposal; mỗi epic ứng với một slug của spec; phần giờ lái 2024 tách thành epic riêng; độ hạt 2–16 giờ, một vai trò; chỗ nào spec để ngỏ thì ghi vào PREMISE thay vì tự lấp trong task. AI đọc `driver-hours.md`, `api-list.md`, `open-questions.md`, `table-definitions.md` để tìm chỗ hở trước khi viết task |
| Chấm SWP | Skill tự viết [`skills/swp-scoring`](skills/swp-scoring/SKILL.md) | Thang Scope 1–4 × Complexity 1–4 → SWP (Fibonacci rút gọn), khung giờ theo SWP để kiểm chéo, các cờ chọn mẫu, mẫu ngẫu nhiên có seed cố định. Script trả mã thoát ≠ 0 khi còn task phải tách hoặc khi quyết định review chưa được áp vào nguồn, nên không thể "quên" bước chốt |
| Quy giờ | Như trên + quy tắc ở `estimate.md` §2 | Ước trực tiếp từng task theo các mốc (anchor) cố định; SWP chỉ để kiểm chéo. Skill kiểm toàn bộ 106 task, không chỉ mẫu |
| Dựng GitHub Project | `gh` + GraphQL, [`tools/gh_sync.py`](tools/gh_sync.py) | Mỗi lệnh idempotent; ánh xạ ID nghiệp vụ ↔ số issue lưu ở `tools/gh_map.json`; dùng quan hệ sub-issue thật (`addSubIssue`) chứ không chỉ checklist; ghi field xong đọc lại toàn bộ Project và in chênh lệch |
| Ghi SWP lên Project bằng Agent | Subagent của Claude Code | Agent chính ghi mọi field **trừ** SWP (`gh_sync.py fields-no-swp`). Một subagent riêng được giao: đọc `swp-report/result.json` và `review.json`, chạy `gh_sync.py swp` để ghi SWP đã review, rồi **tự viết truy vấn GraphQL độc lập** để đọc SWP của mọi item trên Project. Subagent kiểm ba điều: (a) SWP ở leaf bằng giá trị đã chốt; (b) SWP ở issue/epic bằng tổng các con; (c) không có item nào thiếu. Agent chỉ báo cáo chênh lệch, không tự sửa nguồn. Kết quả ở mục 2 |
| Báo cáo tiến độ | [`tools/sprint_report.py`](tools/sprint_report.py) + [`sprint/burndown.typ`](sprint/burndown.typ) | Trạng thái, giờ thực tế và ngày xong của từng task Sprint 1 khai báo trong nguồn Typst. Script tính burndown theo ngày (có đường phạm vi khi có task phát sinh) và dựng PNG bằng Typst. Không dùng biểu đồ Insights của GitHub, vì sprint là giả lập nên ngày thực trên GitHub không khớp |

## 2. Review output của AI

**Con người tham gia ở các bước sau:**
- chọn nguồn skill (takumi trước, tự viết nếu không có);
- chọn tên và chế độ public của repo;
- cấp quyền `project` cho token `gh` (bước xác nhận trên trình duyệt do người làm).

**Nội dung backlog, estimate và báo cáo chưa được người duyệt.** Người dùng sẽ review sau khi AI nộp và yêu cầu sửa tiếp. Vì vậy cột "Bạn chốt" trong `estimate.md` hiện là quyết định do AI đề xuất, kèm lý do, chờ người xác nhận.

**AI tự kiểm bằng máy**, và các lần kiểm này bắt được lỗi thật:

| Bước kiểm | Phát hiện | Xử lý |
|---|---|---|
| Skill chấm SWP, lần chạy 1 | 1 task 8 SWP (tích hợp bản đồ thật) vượt trần; 27 task mẫu, 3 task C4 | Tách task 8 SWP thành 3 + 2; tăng giờ 3 task (#99, #102, #105); hạ 1 task (#146). Chạy lại thì mã thoát 0 |
| Đếm tải theo người sau khi xếp sprint | Backend Bình 85 h trong Sprint 1, năng lực 60 h | Chuyển #32 sang Sprint 2, chuyển #117 và #30 sang Tech lead; thêm 1 màn FE (#40) vì FE còn trống |
| Đối chiếu số liệu trong báo cáo với `sprint-1-summary.json` | AI ghi EP-07 đã xong "18/37 SWP", số đúng là 13/37. Ghi mẫu "19 vì ràng buộc", số đúng là 20. Ghi "khoảng 60 % màn hình AS-BUILT", số đúng là 13/18. Ghi tỷ lệ "262/258 h" (lẫn task phát sinh và task chưa xong), số đúng là 230/219 trên task Done | Sửa trong `progress-report.md` và `estimate.md` |
| So với estimate lần đầu | Bottom-up chỉ bằng khoảng 23 % top-down cho cùng phạm vi | Không tăng số cho khớp. Giải thích chênh lệch theo từng phần, phần không giải thích được đưa thành rủi ro R-04 |
| Ghi Project | `addProjectV2ItemById` báo "Content already exists": khi liên kết repo, một số issue đã vào Project | Sửa script, coi trường hợp này là đã có |
| Ghi file | Lệnh PowerShell 5.1 (`Get-Content -Raw`) đọc UTF-8 thành ANSI và làm hỏng dấu tiếng Việt trong `tasks.typ` | Viết lại file. Từ đó chỉ sửa file bằng công cụ Edit hoặc Python có `encoding="utf-8"` |
| Quyền | Người dùng báo đã cấp quyền, nhưng `gh auth status` vẫn chưa có `project` | Mở lệnh refresh trong Terminal panel để người dùng hoàn tất, rồi kiểm lại trước khi ghi |
| Subagent đối chiếu SWP | Xem dòng cuối | |

Kết quả subagent: *(xem mục "Kết quả đối chiếu SWP" bên dưới, ghi sau khi agent chạy xong)*.

## 3. Điểm đặc biệt trong cách dùng AI

**Hiệu quả:**
- **Một nguồn Typst cho mọi đầu ra.** Thay một ước lượng thì chạy lại 3 script là PDF, Excel, CSV, báo cáo SWP và Project khớp nhau. Khi review SWP tách task bản đồ, issue mới có ngay số và field đúng mà không phải sửa ở 4 nơi.
- **Mã thoát của skill làm cổng chặn.** Không thể ghi SWP lên Project khi còn task phải tách hoặc khi quyết định review chưa được áp vào nguồn.
- **Break từ spec để tìm chỗ hở.** 4 sửa đổi spec (B-01…B-04) và cả epic EP-09 đến từ việc hỏi "dữ liệu này ai ghi vào?" khi viết từng task. Đọc spec bình thường thì bỏ sót các chỗ này.
- **Ghi xong đọc lại toàn bộ Project**, không tin vào mã thoát của mutation.

**Chưa tốt, cần cải thiện khi làm thật:**
- **Cùng một AI vừa ước lượng vừa viết skill chấm**, nên ma trận và khung giờ dễ "tự khớp" với cách AI đã ước. Bằng chứng: lần chạy đầu không có task nào lệch ma trận. Khi làm thật, S/C nên do người khác chấm (planning poker), skill chỉ so và chọn mẫu.
- **Số liệu Sprint 1 là giả lập do AI dựng** (trạng thái, giờ thực tế, ngày xong). Báo cáo đúng về hình thức, nhưng không chứng minh được estimate. Tỷ lệ 1,05 chỉ là con số minh họa.
- **Người phụ trách là tên giả định ghi ở field text**, vì repo chỉ có một tài khoản thật. Khi làm thật cần mời thành viên vào repo để dùng Assignees.
- **Chưa dùng hết cách làm của takumi `git-projects`.** Script có đọc lại nhưng không có khóa ghi và sổ ghi (ledger) cho từng item. Nếu nhiều người cùng đồng bộ, hai lần chạy có thể ghi chồng nhau.
- **Board view của Project** (layout board, nhóm theo Status, lọc Iteration) phải tạo trên giao diện web, vì API không hỗ trợ tạo view.

**Chưa có ý tưởng:** cách hiệu chỉnh khung giờ theo SWP trước khi có velocity thật, mà không quay lại đổi thẳng SWP ra giờ bằng một hệ số tự đặt.
