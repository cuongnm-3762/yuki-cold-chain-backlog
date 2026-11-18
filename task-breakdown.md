# Task breakdown

Nguồn duy nhất của backlog là [`backlog/data.typ`](backlog/data.typ). Bản in và bản xuất của nó:
- [`backlog/out/tasks.pdf`](backlog/out/tasks.pdf): danh sách task và subtask, in từ Typst
- [`backlog/out/tasks.xlsx`](backlog/out/tasks.xlsx), [`backlog/out/tasks.csv`](backlog/out/tasks.csv): bản xuất bằng `python -X utf8 tools/export.py`

Các issue trên GitHub cũng sinh từ cùng nguồn này qua `tools/gh_sync.py`.

Quy mô: **10 epic · 52 issue · 92 sub-issue · 106 task (leaf) · 237 SWP · 719 giờ**.

## 1. Nguyên tắc chia task

**Độ hạt: chia tới đâu thì dừng.** Một task (leaf) phải thỏa đủ bốn điều:
- một người, một vai trò (DB / BE / FE / QA / TL / BA / OPS) làm;
- **2–16 giờ**;
- **≤ 5 SWP**; task chấm ra ≥ 8 SWP thì bắt buộc tách (skill gắn cờ `PHAI_TACH`);
- có một kết quả kiểm được: một migration, một endpoint, một màn hình, một bộ test hoặc một quyết định ghi vào PREMISE.

Thêm hai quy tắc dừng:
- Không tách nhỏ hơn mức một PR có thể review độc lập.
- Không tách riêng code review, viết unit test cho chính code của mình, hay sửa lỗi phát sinh khi review. Các việc này nằm trong giờ của task và trong định nghĩa xong.

**Khi nào tách sub-issue.** Một issue tương ứng với một hạng mục trong spec (một API nhóm, một màn hình, một quy tắc, một lần làm rõ). Issue được tách thành sub-issue khi có **từ hai vai trò trở lên**, hoặc tổng **> 16 giờ**. Issue chỉ cần một task thì là *leaf issue* (tự mang SWP và giờ, không có sub-issue). Ví dụ: #27 (gỡ endpoint demo) và #117 (schema tuyến).

**Định nghĩa xong (DoD)** cho task code:
1. Code đã merge qua PR có ít nhất một người review.
2. Unit test của phần đó chạy trên CI. Nếu thuộc `system/rules/*.md` thì mọi ví dụ trong file quy tắc là test và đều qua.
3. Chỉ dùng mã lỗi có trong danh mục (`error-codes.md`), không có chuỗi lỗi tự do.
4. Policy RLS và kiểm vai trò ở API khớp ma trận `rbac.md` nếu task chạm dữ liệu.
5. Màn hình đủ các trạng thái của wireframe.
6. Field `Status` trên Project là `Done` và issue đóng ở trạng thái *completed*.

Task làm rõ (`type:clarification`) xong khi có trả lời bằng văn bản và quyết định đã ghi vào `PREMISE.md`. Issue cha xong khi mọi sub-issue xong và các tiêu chí nghiệm thu (AC) trong body issue được đánh dấu.

**Dùng epic → issue → sub-issue trên Project.**
- Epic `[EP-nn]` (nhãn `type:epic`) có các issue `[I-nnnn]` là **sub-issue** (quan hệ sub-issue thật của GitHub, xem thanh tiến độ ở epic). Issue `[I-nnnn]` lại có các task `[I-nnnn-k]` làm sub-issue.
- Mọi cấp đều nằm trong Project. Field `Cấp` (Epic / Issue / Sub-issue) dùng để lọc view.
- `SWP` và `Giờ ước lượng` ghi ở cả ba cấp: ở leaf là số đã review; ở issue và epic là tổng các con, để board cộng đúng khi lọc theo cấp.
- `Iteration`, `Phụ trách (giả định)`, `Status` dùng để chạy sprint, đặt ở leaf. Issue cha lấy Iteration của sub-issue sớm nhất; Status của issue cha là trạng thái gộp (Blocked nếu có con Blocked).
- Epic không có Iteration vì epic kéo dài nhiều sprint.

## 2. Spec → issue

| Spec (LAB-4) | Epic | Issue / sub-issue | Phần spec chưa thành issue và vì sao |
|---|---|---|---|
| `system/security/rbac.md`, ADR-0005, API-CM-05 | #1 EP-01 | #2 (#3–#6), #7 (#8–#11) | Tầng IdP OIDC (IF-IDP-01): chờ Q-27; hiện dùng Supabase Auth |
| `rbac.md` §3 audit, NFR-AUD-01, GAP-03 | #1 EP-01 | #12 (#13–#15) | — |
| `system/api-contracts/error-codes.md`, GAP-06 | #1 EP-01 | #16 (#17–#19), làm rõ #28 | — |
| `common/AUTH_LOGIN_SPEC.md` | #1 EP-01 | #20 (#21, #22) | Mã lỗi khóa tài khoản (SYS-CM-01): tạm dùng E09001 |
| `common/DASHBOARD_SPEC`, `MASTER_VIEW_SPEC`, `AUDIT_LOG_SPEC` | #1 EP-01 | #23 (#24–#26) | SYS-CM-02 (lỗi ngày tìm kiếm): chỉ kiểm ở client, nằm trong #26 |
| API-CM-04, GAP-10 | #1 EP-01 | #27 | — |
| `inbound-inspection/*`, `rules/temperature-bands.md` T-02/T-03 | #29 EP-02 | #30, #31 (#32–#34), #35 (#36, #37), #38, #39 (#40–#42) | API-IN-01/02 đã có trong prototype, không đổi hợp đồng nên không có task riêng. Phần chỉnh cho lớp phân quyền nằm trong #7 |
| `outbound-allocation-shipping/*`, `rules/allocation-chain.md` | #43 EP-03 | #44 (#45, #46), #47 (#48–#50), #51 (#52, #53), #54 (#55, #56), #57 (#58–#60) | API-OUT-01/02 đã có trong prototype, như trên |
| `date-reversal-alert/*`, Rule A-06 | #61 EP-04 | #62 (#63, #64), #65 (#66, #67) | — |
| `inventory-lot-status/*` | #68 EP-05 | #69 (#70, #71), #72 (#73, #74), #75 (#76–#79) | API-LOT-01, API-HIS-01 đã có trong prototype |
| `temperature-policy/*`, PM-05/06 | #80 EP-06 | #81 (#82, #83), #84 (#85, #86), #87 (#88, #89) | SYS-NT-03 (chữ trên hộp thoại hủy) nằm trong #88 |
| `rules/driver-hours.md`, `route-driver-hours/DRIVER_RULESET_SPEC.md`, ADR-0003 | #90 EP-07 | #91 (#92, #93), #94 (#95, #96), #97, #98 (#99, #100), #101 (#102, #103), #104 (#105, #106), #107 (#108, #109), #110 (#111, #112), làm rõ #113 (#114, #115) | Các ngoại lệ của quy định (đường dài, lái 2 người, phà…): **tắt** theo PM-09, không làm |
| `route-driver-hours/ROUTE_LIST_SPEC`, `ROUTE_CHECK_SPEC`, API-RT-01…08, IF-MAP-01 | #116 EP-08 | #117, #118 (#119, #120), #121 (#122–#124), #125 (#126, #127), #128 (#129, #130), #131, #132, #133 (#134–#137) | Hiển thị trên thiết bị của tài xế ngoài chế độ xem trong ROUTE_CHECK: ngoài phạm vi (LAB-4 R-4, ứng dụng native) |
| `table-definitions.md` `drivers`, `driver_duty_days`, SYS-DH-01 + PREMISE B-02/B-03/A-03 | #138 EP-09 | #139 (#140, #141), #142 (#143, #144), #145, làm rõ #146 | — |
| `nfr/nfr.md`, `architecture/overview.md`, ADR-0009 | #147 EP-10 | #148 (#149, #150), #151, #152, #153, #154 | NFR-AVL-01 (99,5 %) và NFR-RET-01 (lưu ≥ 3 năm): chờ Q-20/Q-22 và phụ thuộc gói hosting nên chưa có việc build cụ thể |
| IF-ERP-01, IF-LOG-01 (chỉ có hợp đồng) | — | — | Chưa thành issue: LAB-4 không thiết kế màn hình hay adapter chi tiết (R-2, R-3), định dạng chờ Q-02/Q-04. Hiện dữ liệu đơn và logger lấy từ seed của prototype |
| POD, khiếu nại, truy xuất/thu hồi, báo cáo, HACCP | — | — | Ngoài bộ thiết kế chi tiết (LAB-4 R-1, R-3). Chỉ có điểm nối API-HIS-04 (#76) |

## 3. Hạng mục chịu ràng buộc đặc thù của đề

Ràng buộc: **giới hạn giờ làm của tài xế xe tải áp dụng từ 2024-04-01** (改善基準告示 sửa đổi; bộ quy tắc `JP-TRUCK-2024-04`, H-01…H-12). Mọi item thuộc phần này có nhãn `constraint:giờ-lái-2024` và field `Ràng buộc = Giờ lái 2024` để lọc riêng trên board.

| Ràng buộc | Issue | Vì sao tách riêng |
|---|---|---|
| Giá trị quy định là dữ liệu có phiên bản, không hard-code; tuyến đã công bố gắn với phiên bản bộ quy tắc | #91, #110, #128 | Quy định có thể sửa tiếp. Đổi giá trị phải ra phiên bản mới có người duyệt, và không được đánh giá lại tuyến cũ. Phần này có vòng đời riêng, khác CRUD danh mục thường |
| 拘束時間 trong ngày, tuần (H-03/04/05) | #94 | Mỗi giới hạn có cách đo và cửa sổ thời gian riêng. Tách theo nhóm giới hạn để mỗi task có bộ ví dụ kiểm thử riêng trong `driver-hours.md` §6 |
| Thời gian nghỉ giữa ca (H-06/07) | #97 | như trên |
| Lái liên tục 4 h và gián đoạn ≥ 30 phút / mỗi lần ≥ 10 phút (H-10/11), báo khoảng vi phạm chính xác | #98 | Là phần khó nhất về thuật toán (C4). Tách riêng để review SWP thấy được (#99 tăng 8 → 10 h sau review) |
| Trung bình lái 2 ngày / 2 tuần (H-08/09) | #101 | Cần dữ liệu ngày lân cận và lịch sử, và phụ thuộc quy ước ca qua nửa đêm (A-01) |
| Tháng/năm, thỏa thuận lao động, làm thêm (H-01/02/12) | #104 | Có chỗ hở spec B-01 (≤ 3 tháng liên tiếp). Phụ thuộc dữ liệu đầu vào ở EP-09 |
| Vector kiểm thử dùng chung (13 ví dụ + ca biên) | #107 | Sai một giới hạn cứng là lỗi nghiêm trọng (RFP S5-03). Bộ test là cổng chặn trên CI, không gộp vào task code |
| Làm rõ pháp lý: giới hạn nào BLOCK, giới hạn nào WARN (Q-15) | #113 | Phân loại hiện là giả định PM-08 của LAB-4. Trả lời của Yuki có thể đổi hành vi công bố |
| Làm rõ ca qua nửa đêm | #146 | Chỗ hở phát hiện khi break (A-01) |
| Lập tuyến bằng đoạn có kiểu, kiểm tra, gợi ý nghỉ, công bố, sự kiện khẩn cấp | #116 EP-08 (#117–#137) | Màn ROUTE_CHECK và API-RT-* là nơi người dùng chạm vào ràng buộc. Chặn công bố khi có BLOCK là yêu cầu cứng |
| Dữ liệu đầu vào: tài xế, cờ thỏa thuận, lịch sử 365 ngày, giờ làm thêm | #138 EP-09 (#139–#146) | Không có dữ liệu này thì engine tính sai, dù code đúng. Phần này mới phát hiện khi break (B-02, B-03) nên tách epic riêng để thấy rõ khối việc phát sinh |

Ảnh hưởng tới effort: ba epic giờ lái chiếm **253 h / 719 h (35 %)** và **89 / 237 SWP**, gồm 3 task C4 trong tổng số 3 task C4 của cả backlog, và 2 trong 3 issue làm rõ. Chi tiết ở `estimate.md` §4.

## 4. Chỗ hở hoặc mâu thuẫn của spec lần trước phát hiện khi break

| Spec | Chỗ hở / mâu thuẫn | Xử lý |
|---|---|---|
| `driver-hours.md` §2 H-02 và §3 bước 8 | Bảng giá trị có giới hạn "≤ 3 tháng liên tiếp vượt 284 h", nhưng quy trình đánh giá không kiểm | đã sửa thiết kế — [PREMISE.md B-01](PREMISE.md#1-spec-thêm--bỏ--sửa-so-với-lab-4) |
| `table-definitions.md` `drivers` · `MASTER_VIEW_SPEC` · PREMISE LAB-4 R-2 | Có cột cờ thỏa thuận lao động nhưng không có đường ghi; R-2 loại sửa danh mục | đã sửa thiết kế — PREMISE.md B-02 |
| `table-definitions.md` `driver_duty_days.source = IMPORT` | Có giá trị IMPORT nhưng không có API nạp; ngày go-live không có lịch sử | đã sửa thiết kế — PREMISE.md B-03 |
| `api-list.md` API-HIS-04 | Endpoint ghi lịch sử giao (mốc của quy tắc cấm đảo hạn) không có cơ chế xác thực | đã sửa thiết kế — PREMISE.md B-04 |
| `driver-hours.md` "ngày của tuyến (JST)" · `ROUTE_CHECK_SPEC` "qua ngày thì kèm ngày" | Không nói ca qua nửa đêm thuộc ngày nào khi tính H-08 | giả định — PREMISE.md A-01; tạo issue làm rõ #146 |
| `driver-hours.md` §4 "điểm dừng hoặc vị trí nghỉ" | Không có danh mục vị trí nghỉ | giả định — PREMISE.md A-02 |
| `open-questions.md` SYS-DH-01 | Nguồn số giờ làm thêm (H-12) để ngỏ | giả định — PREMISE.md A-03 |
| `driver-hours.md` §8, Q-23 | Chưa chọn dịch vụ bản đồ, ROUTE_CHECK phụ thuộc | giả định — PREMISE.md A-04 |
| `PREMISE.md` (LAB-4) PM-08 | Phân loại BLOCK/WARN là giả định của chúng tôi, chưa có xác nhận pháp lý (OPS-LAW-01) | tạo issue làm rõ #113 |
| `open-questions.md` SYS-ER-01 | 8 chỗ mượn mã lỗi | tạo issue làm rõ #28; đã chốt ở PREMISE.md §3 |
| `open-questions.md` SYS-OUT-01, SYS-NT-02 | Còn hai phương án | đã sửa thiết kế (chốt phương án) — PREMISE.md §3 |
| `open-questions.md` SYS-CM-01 | Chưa có mã lỗi riêng cho đăng nhập sai / khóa tài khoản | để mở: tạm dùng E09001 vì thông điệp chung không lộ thông tin tài khoản; quyết định khi chốt IdP (Q-27) |
