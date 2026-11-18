# Estimate

**Báo cáo HTML của skill chấm SWP:** [`swp-report/index.html`](swp-report/index.html). Xem trên web không cần tải repo: https://htmlpreview.github.io/?https://github.com/cuongnm-3762/yuki-cold-chain-backlog/blob/main/swp-report/index.html

Các file đi kèm:
- skill: [`skills/swp-scoring/`](skills/swp-scoring/SKILL.md)
- quyết định review: [`swp-report/review.json`](swp-report/review.json)
- kết quả máy đọc: [`swp-report/result.json`](swp-report/result.json)

Chạy lại: `python -X utf8 skills/swp-scoring/scripts/score.py`. Mã thoát 0 nghĩa là không còn task phải tách và mọi quyết định review đã được áp vào `backlog/data.typ`.

## 1. Issue mẫu skill chọn để kiểm

Thang chấm và ma trận nằm ở `skills/swp-scoring/SKILL.md`. Skill chọn mẫu theo hai cách:
- **Task có cờ:** SWP lệch ma trận, giờ ngoài khung, SWP ≥ 8, Complexity 4, hoặc thuộc phần giờ lái 2024 với C ≥ 3.
- **Mẫu ngẫu nhiên:** một task trong mỗi epic không có cờ nào, seed 20261130.

Kết quả: 27 task mẫu (20 vì ràng buộc giờ lái, trong đó 1 còn bị cờ lệch; 7 ngẫu nhiên). Ngoài ra có 1 task bị buộc tách trước khi chốt.

| Issue | Skill chấm (Scope × Complexity → SWP) | Bạn chốt | Lý do |
|---|---|---|---|
| (trước khi tách) `I-0803-2` Tích hợp nhà cung cấp bản đồ thật | S4 × C3 → **8** (10 h; cờ PHAI_TACH) | **tách 3 + 2** | 8 SWP vượt trần của một task. Tách thành #123 (adapter, 3 SWP, 6 h) và #124 (kiểm thử sandbox, 2 SWP, 4 h) |
| #99 `I-0704-1` Thuật toán `drive_since_break` + nhóm BREAK đạt chuẩn | S1 × C4 → 3 (8 h; C4, RANG_BUOC) | **3 SWP, 10 h** | Giữ SWP, tăng giờ. Ví dụ 8 của `driver-hours.md` có quãng nghỉ 10 phút không đạt chuẩn, và nhóm BREAK phải hoàn tất trước mốc 4 h; cần thêm giờ cho ca biên |
| #105 `I-0706-1` Tổng tháng/năm, trần theo thỏa thuận, đếm 6 tháng và 3 tháng liên tiếp | S2 × C4 → 5 (10 h; C4, RANG_BUOC) | **5 SWP, 12 h** | Giữ SWP, tăng giờ. Phần đếm tháng liên tiếp là phần bổ sung vào spec (PREMISE B-01) |
| #102 `I-0705-1` Tổng lái theo ngày + trung bình 2 ngày (H-08) | S2 × C3 → 3 (6 h; RANG_BUOC) | **3 SWP, 8 h** | Giữ SWP, tăng giờ. 6 h nằm sát đáy khung, và task phụ thuộc quy ước ca qua nửa đêm (A-01) |
| #146 `I-0904` [Làm rõ] Ca qua nửa đêm | S1 × C3 → 2 (4 h; RANG_BUOC) | **1 SWP, 4 h** | Hạ SWP. Task chỉ soạn câu hỏi và ví dụ; độ khó của quy định thuộc #102 và #109. Giữ S/C như cũ để báo cáo vẫn hiện vết lệch (cờ LECH) |
| #127 `I-0804-2` Thuật toán gợi ý điểm nghỉ | S1 × C4 → 3 (8 h; C4, RANG_BUOC) | 3 SWP, 8 h | Giữ. Chỉ gợi ý tại điểm dừng của tuyến (A-02) nên phạm vi vẫn là S1 |
| #95 `I-0702-1` Dựng ca + H-03/H-04 | S1 × C3 → 2 (6 h) | 2 SWP, 6 h | Giữ. Dựng ca chỉ là min/max của các đoạn đã có kiểu |
| #96 `I-0702-2` Ngày > 14 h theo tuần JST (H-05) | S1 × C3 → 2 (5 h) | 2 SWP, 5 h | Giữ. Tuần JST bắt đầu thứ Hai đã chốt ở PM-10 |
| #100 `I-0704-2` Khoảng vi phạm chính xác | S1 × C3 → 2 (5 h) | 2 SWP, 5 h | Giữ. Thời điểm vượt mốc là phụ phẩm của thuật toán ở #99 |
| #103 `I-0705-2` Cửa sổ 2 tuần (H-09) | S1 × C3 → 2 (5 h) | 2 SWP, 5 h | Giữ. Logic giống H-08 nhưng cửa sổ 2 tuần |
| #109 `I-0707-2` Ca biên | S2 × C3 → 3 (8 h) | 3 SWP, 8 h | Giữ. Ca biên phải đối chiếu tay với cổng MHLW |
| #111 `I-0708-1` API-DR-01…04 | S2 × C3 → 3 (8 h) | 3 SWP, 8 h | Giữ. Vòng đời giống API-TP nên dùng lại được mẫu |
| #117 `I-0801` Schema 7 bảng tuyến + RLS | S2 × C3 → 3 (10 h) | 3 SWP, 10 h | Giữ. Cấu trúc đã có ở `table-definitions.md`; phần khó là RLS cho DRIVER |
| #120 `I-0802-2` API-RT-04, đoạn chồng lấn | S2 × C3 → 3 (8 h) | 3 SWP, 8 h | Giữ. Kiểm chồng lấn bằng exclusion constraint trong DB |
| #122 `I-0803-1` Adapter bản đồ + nhập tay + cache | S2 × C3 → 3 (8 h) | 3 SWP, 8 h | Giữ. Nhập tay là đường chính cho tới khi có Q-23 |
| #123 `I-0803-2` Adapter nhà cung cấp (phần tách) | S2 × C3 → 3 (6 h) | 3 SWP, 6 h | Giữ |
| #129 `I-0805-1` Công bố nguyên tử + `driver_duty_days` | S2 × C3 → 3 (8 h) | 3 SWP, 8 h | Giữ |
| #131 `I-0806` Sự kiện khẩn cấp | S2 × C3 → 3 (8 h) | 3 SWP, 8 h | Giữ. Phạm vi loại trừ chỉ 3 phép kiểm (`driver-hours.md` §5) |
| #134 `I-0808-1` Trình sửa đoạn có kiểu | S3 × C3 → 5 (14 h) | 5 SWP, 14 h | Giữ. Phần FE lớn nhất của dự án |
| #135 `I-0808-2` Timeline tô khoảng vi phạm | S3 × C3 → 5 (12 h) | 5 SWP, 12 h | Giữ |
| #143 `I-0902-1` Nạp CSV lịch sử giờ làm | S2 × C3 → 3 (8 h) | 3 SWP, 8 h | Giữ. Kiểm trùng IMPORT/ROUTE theo ngày là nhánh chính |
| #8 `I-0102-1` Policy RLS nhóm nhập/tồn/lô | S2 × C3 → 3 (10 h; ngẫu nhiên) | 3 SWP, 10 h | Giữ |
| #42 `I-0205-3` Test màn INBOUND_INSPECTION | S2 × C2 → 2 (6 h; ngẫu nhiên) | 2 SWP, 6 h | Giữ |
| #45 `I-0301-1` Migration sổ cái tồn kho | S2 × C3 → 3 (10 h; ngẫu nhiên) | 3 SWP, 10 h | Giữ. Có chuyển dữ liệu nên C3 là hợp lý |
| #66 `I-0402-1` API-AL-01/02/03 | S2 × C2 → 2 (6 h; ngẫu nhiên) | 2 SWP, 6 h | Giữ |
| #77 `I-0503-2` Đảo lịch sử giao | S2 × C3 → 3 (8 h; ngẫu nhiên) | 3 SWP, 8 h | Giữ |
| #85 `I-0602-1` API-TP-01…05 | S2 × C3 → 3 (10 h; ngẫu nhiên) | 3 SWP, 10 h | Giữ |
| #149 `I-1001-1` Môi trường Tokyo | S2 × C2 → 2 (6 h; ngẫu nhiên) | 2 SWP, 6 h | Giữ |

Kết quả: 1 task tách, 3 task tăng giờ (+6 h), 1 task hạ SWP. Sau review, tổng SWP theo ma trận là 238, tổng SWP đã chốt là 237; chênh 1 chính là #146.

## 2. Cách quy ra giờ

**Cách đã chọn: ước trực tiếp từng task** (bottom-up), **không** đổi từ SWP theo hệ số. SWP chỉ dùng để kiểm chéo.

**Vì sao:**
- Nhóm chưa có velocity lịch sử, nên một hệ số "1 SWP = x giờ" đặt ra lúc này là con số tự chế.
- SWP đo độ lớn và độ rủi ro tương đối; giờ đo năng lực cần để xếp sprint. Hai trục được ước độc lập thì mới kiểm chéo được nhau. Ví dụ #99: SWP giữ 3 nhưng giờ tăng.
- Sau 2–3 sprint, tỷ lệ giờ thực tế / SWP sẽ thay cho khung giờ dưới đây.

**Quy tắc cụ thể:**
1. Giờ của một task là giờ làm **tập trung** của một người, gồm code, unit test của chính phần đó và sửa theo review. Không gồm họp, scrum, chờ review: các việc này nằm trong hệ số tập trung khi tính năng lực sprint (6 giờ tập trung trên ngày 8 giờ, PREMISE A-05).
2. Mỗi task phải nằm trong **khung giờ của mức SWP theo ma trận**: 1 → 2–5 h · 2 → 3–8 h · 3 → 5–12 h · 5 → 8–16 h. Task ngoài khung bị skill gắn cờ `NGOAI_KHUNG`, và người review phải sửa S/C hoặc sửa giờ.
3. Trần 16 h cho một task (2 ngày tập trung). Task lớn hơn phải tách.
4. Mốc ước lượng (anchor) dùng chung, để các task cùng loại được ước giống nhau:
   - một màn danh sách có lọc: 4–5 h;
   - một màn form nhiều trạng thái: 10–12 h;
   - một endpoint đọc: 3 h;
   - một endpoint ghi có giao dịch: 6–10 h;
   - một nhóm policy RLS (≈ 8 bảng): 10 h;
   - bộ unit test từ bảng ví dụ của file quy tắc: 4–5 h.
5. Giờ của issue và epic là **tổng** giờ các task con. Không cộng thêm buffer ở cấp issue; rủi ro trượt được theo dõi bằng giờ thực tế (field `Giờ thực tế`) và ở `progress-report.md` §4.

**Áp dụng nhất quán:** skill kiểm quy tắc 2 và 3 trên **toàn bộ 106 task**, không chỉ trên mẫu. Sau review không còn task nào ngoài khung hoặc phải tách. Tỷ lệ chung là 3,03 h/SWP; theo epic dao động 2,8–3,3 h/SWP (bảng 4 của báo cáo HTML).

## 3. Tổng theo epic

| Epic | Số issue | Số task (leaf) | Tổng SWP | Tổng giờ | Ghi chú |
|---|---|---|---|---|---|
| #1 EP-01 Nền tảng: phân quyền, RLS, audit, mã lỗi | 8 | 21 | 39 | 127 | Đóng GAP-01/03/06/10 của prototype; 1 task phát sinh (#10) |
| #29 EP-02 Kiểm nhập | 5 | 10 | 19 | 62 | Màn và API đọc đã có trong prototype |
| #43 EP-03 Phân bổ lô và kiểm xuất | 5 | 12 | 32 | 101 | Sổ cái tồn kho và tách lô là phần mới (B-4 của LAB-4) |
| #61 EP-04 Cảnh báo đảo hạn | 2 | 4 | 9 | 28 | |
| #68 EP-05 Tồn kho, trạng thái lô và lịch sử giao | 3 | 8 | 19 | 59 | |
| #80 EP-06 Ngưỡng nhiệt 3 dải có phiên bản | 3 | 6 | 13 | 42 | |
| #90 EP-07 [Giờ lái 2024] Bộ quy tắc và engine | 9 | 17 | 37 | 105 | **Ràng buộc đặc thù**; 2 task C4; 1 issue làm rõ pháp lý |
| #116 EP-08 [Giờ lái 2024] Lập tuyến, kiểm tra, công bố | 8 | 16 | 43 | 120 | **Ràng buộc đặc thù**; 1 task C4; tích hợp bản đồ chờ Q-23 |
| #138 EP-09 [Giờ lái 2024] Dữ liệu đầu vào giờ làm | 4 | 6 | 9 | 28 | **Ràng buộc đặc thù**; epic mới sinh từ chỗ hở B-02/B-03 |
| #147 EP-10 Hạ tầng, kiểm thử xuyên suốt, phát hành | 5 | 6 | 17 | 47 | |
| **Tổng** | **52** | **106** | **237** | **719** | 3 epic giờ lái: 89 SWP / 253 h (35 % giờ) |

Theo sprint: S1 80 SWP / 262 h · S2 55 / 163 · S3 67 / 195 · S4 35 / 99. Năng lực danh nghĩa của nhóm là 370 h/sprint. S1 xếp 258 h (70 %) vì là sprint khởi động, chi tiết ở `progress-report.md`.

## 4. So với estimate lần đầu tiên

Estimate lần đầu là `proposal/06_Estimate-WBS.xlsx` (v1.0, 2026-10-22): ước từ trên xuống theo 82 feature, mỗi feature tính bằng PD (ngày công 8 giờ) gồm Thiết kế (0,22 × Build) + Build + Kiểm thử (0,32 × Build).
- Để so cùng phạm vi, mỗi epic được gắn với các feature `FT-xx` tương ứng.
- Phần **Thiết kế** của estimate cũ được bỏ ra, vì đã làm xong ở LAB-4.
- Cột "lần đầu" = (Build + Kiểm thử) PD × 8 giờ.

| Phần (epic ← feature lần đầu) | Lần đầu (giờ) | Lần này (giờ) | Chênh | Vì sao |
|---|---|---|---|---|
| EP-01 ← FT-12-01…05 | 359 | 127 | −232 (−65 %) | FT-12-01 gồm SSO/MFA và xác thực thiết bị tài xế, chưa thành issue (chờ Q-27). Vai trò, đăng nhập và audit đã có khung trong prototype |
| EP-02 ← FT-02-02, 02-04, 02-05, 09-01, 09-02 | 380 | 62 | −318 (−84 %) | Màn kiểm nhập và API đọc đã có trong prototype (AS-BUILT); lần này chỉ còn phần thay đổi |
| EP-03 ← FT-04-01/02/03/05, 05-01, 05-02, 05-05, 03-03 | 755 | 101 | −654 (−87 %) | FT-05-01 (đơn hàng, gồm nhập từ ERP) không thành issue (LAB-4 R-2). Chuỗi phân bổ đã có trong prototype, lần này chỉ thêm tách lô và sổ cái |
| EP-04 ← FT-04-04 | 132 | 28 | −104 (−79 %) | Cảnh báo đã có trong prototype; chỉ đổi mốc sang POD (B-7 của LAB-4) |
| EP-05 ← FT-03-05, 03-06, 04-06 | 306 | 59 | −247 (−81 %) | Danh sách tồn và lịch sử đã có; thêm LOT_DETAIL và đảo lịch sử |
| EP-06 ← FT-08-01, 08-02 | 121 | 42 | −79 (−65 %) | Gần như làm mới, nên chênh ít hơn các phần AS-BUILT |
| EP-07 + EP-08 + EP-09 (giờ lái 2024) ← FT-07-01…07 | 707 | 253 | −454 (−64 %) | Prototype **không có** phần này nên mức giảm thấp nhất trong các phần đã có tương ứng. EP-09 (28 h) là phần **mới**, không có trong estimate lần đầu (PREMISE B-02, B-03). Review SWP tăng 6 h (#99, #102, #105). Vẫn thấp hơn vì FT-07-08 (thiết bị tài xế) ngoài phạm vi và các ngoại lệ quy định đã tắt (PM-09) |
| EP-10 ← FT-14-01…05 | 301 | 47 | −254 (−84 %) | Giám sát/cảnh báo vận hành (FT-14-01) và phần lớn FT-14-03 chưa thành issue; NFR-AVL/RET chờ Q-20/Q-22 |
| **Tổng phần tương ứng** | **3 062** | **719** | **−2 343 (−77 %)** | Xem giải thích dưới |

Chênh lệch tổng **lớn hơn mức tự nhiên**, nên đọc như sau:
1. **Đơn vị khác nhau.** PD của lần đầu là ngày 8 giờ có cả họp, review, chờ. Giờ lần này là giờ tập trung (6/8). Quy về cùng đơn vị thì 719 h ≈ 959 h "ngày công 8 giờ".
2. **Phạm vi hẹp hơn.** Mỗi feature `FT-xx` được gắn trọn vào epic, nhưng chỉ phần có trong bộ thiết kế chi tiết mới thành issue. Phần còn lại nằm trong cột "chưa thành issue" của `task-breakdown.md` §2.
3. **Prototype đã có** 13/18 màn hình của phạm vi này (AS-BUILT, `screen-list.md`).
4. **Phần còn lại là rủi ro estimate thấp.** Sau khi trừ ba lý do trên, bottom-up vẫn chỉ bằng khoảng 30–40 % top-down. Nghĩa là các task có thể đang thiếu việc tích hợp, sửa lỗi kiểm thử hệ thống và hồi quy. Điểm này được đưa vào rủi ro R-04 ở `progress-report.md`: theo dõi tỷ lệ giờ thực tế / ước lượng qua 2 sprint; nếu > 1,15 thì ước lại phần còn lại. Sprint 1 (giả lập) cho tỷ lệ 230 h thực tế / 219 h ước lượng = 1,05 trên các task Done.
