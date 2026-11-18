# PREMISE — Tiền đề của backlog

Backlog trong repo này được break từ bộ thiết kế chi tiết đã nộp ở LAB-4 (`specs/`: PREMISE, `system/**`, `requirements/app/**`, `adr/**`). Tài liệu này ghi lại những chỗ backlog **khác** bộ LAB-4. Mỗi dòng có mã (`B-nn`, `A-nn`, `D-nn`) để `task-breakdown.md`, `estimate.md` và nội dung issue trỏ về.

Bộ spec không được nộp lại. Chỉ có các sửa đổi nhỏ (một bước tính, một API nạp dữ liệu), không thêm màn hình nào, nên mỗi sửa đổi chỉ được mô tả ở cột "Trước → sau" mà không kèm bản spec sửa.

## 1. Spec thêm / bỏ / sửa so với LAB-4

| Mã | Spec (mã / file) | Thêm / Bỏ / Sửa | Trước → sau | Vì sao | Issue bị ảnh hưởng |
|---|---|---|---|---|---|
| B-01 | `system/rules/driver-hours.md` §3 bước 8 (H-02) | Sửa | Trước: bước 8 chỉ so tổng tháng với trần 284 h, hoặc 310 h "khi số tháng được phép chưa dùng hết". → Sau: bước 8 đếm số tháng vượt 284 h trong 12 tháng cuộn (≤ 6) **và** số tháng vượt **liên tiếp** (≤ 3). Tháng thứ 4 liên tiếp vượt 284 h thì `BLOCK` dù chưa vượt 310 h | Phát hiện khi break I-0706: bảng giá trị ở §2 dòng H-02 ghi rõ "không được liên tiếp quá 3 tháng", nhưng quy trình đánh giá ở §3 không có bước nào kiểm điều này. Không sửa thì engine bỏ sót một giới hạn cứng, mà RFP S5-03 coi việc bỏ sót ràng buộc cứng là lỗi nghiêm trọng | #104, #105, #109 |
| B-02 | `system/database/table-definitions.md` bảng `drivers`, `vehicles` · `requirements/app/common/MASTER_VIEW_SPEC.md` | Thêm | Trước: bảng có cột `labour_agreement_monthly/annual`, `overtime_ytd_h` nhưng không có API hay màn hình nào ghi vào; MASTER_VIEW chỉ xem, và sửa danh mục nằm ngoài phạm vi (PREMISE LAB-4 R-2). → Sau: thêm đường **nạp CSV** tài xế, xe và cờ thỏa thuận lao động, có kiểm tra theo dòng và audit; vẫn không thêm màn hình | Phát hiện khi break EP-07: engine cần cờ thỏa thuận để chọn trần 284/310 và 3300/3400, nhưng thiếu đường nạp thì giá trị luôn là `false` | #139, #140, #141 |
| B-03 | `table-definitions.md` bảng `driver_duty_days` (`source ROUTE\|IMPORT`) · `route-driver-hours/api-design.md` | Thêm | Trước: schema có `source = IMPORT` nhưng không có API nạp; lịch sử chỉ sinh khi công bố tuyến. → Sau: thêm API nạp CSV lịch sử giờ làm 365 ngày, báo lỗi khi dòng IMPORT trùng ngày với dòng ROUTE; ROUTE_CHECK cảnh báo khi tài xế thiếu lịch sử | Phát hiện khi break I-0705/I-0706: ngày go-live hệ thống chưa có tuyến nào, nên trong năm đầu H-01, H-02, H-08, H-09 sẽ tính sai (luôn thấp) nếu không nạp lịch sử thật | #142, #143, #144 |
| B-04 | `api-list.md` API-HIS-04 `POST /api/pod/completed` | Sửa | Trước: vai trò "hệ thống", không nói cách xác thực. → Sau: xác thực bằng chữ ký HMAC với secret riêng của mô-đun POD | Phát hiện khi break I-0503: endpoint ghi lịch sử giao, cũng là mốc của quy tắc cấm đảo hạn, mà không có cơ chế xác thực thì ai cũng gửi được | #75, #76 |

## 2. Giả định bổ sung

| Mã | Giả định | Chỗ spec / RFP để ngỏ | Ảnh hưởng tới issue / estimate |
|---|---|---|---|
| A-01 | Ca qua nửa đêm: `duty_date` là ngày JST của **giờ bắt đầu ca**, và toàn bộ ca tính vào ngày đó khi lấy trung bình 2 ngày (H-08). Giả định này dùng tạm cho tới khi Yuki xác nhận có theo cách "24 giờ tính từ giờ bắt đầu ca" của quy định hay không | `driver-hours.md` chỉ ghi "ngày của tuyến (JST)"; `ROUTE_CHECK_SPEC` có hiển thị "qua ngày thì kèm ngày" nhưng không nói thuộc ngày nào khi tính | Tạo issue làm rõ #146. I-0705-1 (#102) tăng 6 → 8 h; I-0707-2 (#109) có ca biên qua nửa đêm. Nếu Yuki chọn cách 24 giờ thì I-0705-1 và I-0702-1 phải ước lại |
| A-02 | Gợi ý điểm nghỉ (FR-SCH-03) chỉ đặt tại **các điểm dừng có sẵn của tuyến**, không đặt ở trạm nghỉ ven đường | `driver-hours.md` §4 nói "điểm dừng hoặc vị trí nghỉ", nhưng không có danh mục vị trí nghỉ nào trong spec hay RFP | #127 giữ Scope 1. Nếu cần trạm nghỉ thì phải thêm danh mục và IF-MAP-01, khoảng +1 issue |
| A-03 | `overtime_ytd_h` (H-12) do SUPERVISOR cập nhật **hằng tháng** theo số HR gửi; có audit; không kết nối hệ thống HR | SYS-DH-01 (LAB-4) để ngỏ nguồn số giờ làm thêm | #145 (3 h). Nếu muốn nạp tự động từ HR thì cần thêm một adapter |
| A-04 | IF-MAP-01: **nhập tay thời gian lái là đường chính** cho tới khi Q-23 (chọn dịch vụ bản đồ) có trả lời. Tích hợp nhà cung cấp thật xếp vào Sprint 4 | Q-23 chưa trả lời | #122 làm ở Sprint 2; #123 và #124 chờ Q-23 |
| A-05 | Nhóm giả định gồm 8 người (TL, 2 BE, 2 FE, QA, BA/BrSE, DevOps bán thời gian). Mỗi người 6 giờ tập trung một ngày, sprint 2 tuần = 10 ngày làm việc | RFP và LAB-4 không nói quy mô nhóm triển khai | Năng lực sprint ở `progress-report.md`; quy giờ ở `estimate.md` §3 |
| A-06 | Sprint 1 bắt đầu 2026-11-30, cùng ngày bắt đầu giai đoạn P2 (xây dựng) trong lịch của estimate lần đầu | Lịch P2 có trong `06_Estimate-WBS.xlsx`, nhưng chưa có ngày bắt đầu thực tế | Iteration trên Project |

## 3. Hướng đã chốt

| Vấn đề | Các phương án ở lần trước | Phương án chốt | Vì sao |
|---|---|---|---|
| Giao dịch khi phân bổ một đơn (SYS-OUT-01) | (a) một giao dịch cho cả đơn; (b) mỗi dòng một giao dịch | (b) mỗi dòng một giao dịch | Một dòng thiếu lô không được hủy giữ chỗ của các dòng đã hợp lệ. Màn OUTBOUND_ALLOCATION hiển thị kết quả theo dòng, nên giao dịch theo dòng khớp với cách hiển thị. Issue #51, #52 |
| Trạng thái phiên bản đã duyệt nhưng chưa tới ngày hiệu lực (SYS-NT-02) | (a) bật ngay khi duyệt; (b) chờ tới `effective_from` | (b): `PENDING_APPROVAL → APPROVED`, rồi job pg_cron đổi sang `ACTIVE` vào 00:00 JST của `effective_from` | PM-06 yêu cầu `effective_from` ở tương lai. Bật ngay khi duyệt sẽ áp ngưỡng mới cho các lần kiểm nhập trước ngày hiệu lực. Issue #86 |
| Mã lỗi đang mượn (SYS-ER-01) | (a) giữ mã mượn; (b) thêm mã riêng cho cả 8 chỗ | (a) giữ mã mượn cho phạm vi build hiện tại; chỉ thêm mã khi một màn hình cần thông điệp khác | Cả 8 chỗ dùng thông điệp chung mà vẫn đủ nghĩa. Thêm mã kéo theo sửa 2 bản spec và danh mục thông điệp JA/VI. Issue #28 |
| Nơi chạy `evaluateRoute` (SYS-AR-02) | (a) TypeScript; (b) hàm Postgres | (a) TypeScript, đúng như ADR-0003 | Bộ vector kiểm thử (13 ví dụ và ca biên) chạy chung trên CI. Tuyến chỉ có ≤ 15 điểm dừng nên tính trong bộ nhớ là đủ. EP-07 |
| Dịch vụ bản đồ (IF-MAP-01) | (a) chờ chọn nhà cung cấp rồi mới làm; (b) làm adapter, nhập tay trước | (b), xem A-04 | Không để ROUTE_CHECK (đường găng của EP-08) chờ một câu hỏi chưa có ngày trả lời |
| Cấp chấm SWP | (a) chấm ở issue; (b) chấm ở task (leaf), issue và epic là tổng | (b) | Task đủ nhỏ để ma trận Scope × Complexity có ý nghĩa; issue nhiều vai trò thì chấm một số chung sẽ mờ. Xem `estimate.md` §2 |
| Cách quy ra giờ | (a) đổi từ SWP theo hệ số; (b) ước trực tiếp từng task, dùng SWP để kiểm chéo | (b) | Chưa có velocity lịch sử để có hệ số đổi đáng tin. Xem `estimate.md` §3 |
