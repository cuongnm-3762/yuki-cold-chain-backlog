// =====================================================================
// NGUỒN DUY NHẤT (single source of truth) của backlog Yuki Cold Chain.
// - tasks.typ đọc file này để in danh sách task (PDF).
// - tools/export.py đọc qua `typst query` để xuất Excel + CSV.
// - tools/gh_sync.py đọc qua `typst query` để tạo issue/sub-issue và ghi field trên GitHub Project.
// - skills/swp-scoring chấm SWP từ `s` (Scope) × `c` (Complexity).
// Sửa backlog = sửa file này rồi chạy lại các tool; không sửa tay Excel/CSV/Project.
//
// Khóa của task:
//   r    vai trò: DB | BE | FE | QA | TL | BA | OPS
//   t    tên task
//   s    Scope 1–4      (1: một hàm/tệp · 2: một tầng, vài tệp · 3: xuyên tầng hoặc trọn một màn · 4: nhiều mô-đun/bên ngoài)
//   c    Complexity 1–4 (1: hiển thị/CRUD · 2: quy tắc kiểm tra thường · 3: nhiều nhánh/đồng thời/giao dịch · 4: thuật toán, quy định pháp lý, bất định cao)
//   h    giờ ước lượng (ước trực tiếp, xem estimate.md §3)
//   swp  SWP đã review (skill gợi ý từ s × c; người chốt — xem estimate.md §2)
//   it   Iteration: S1…S4
//   who  người phụ trách giả định
//   st   trạng thái trên Project cuối Sprint 1: Todo | In Progress | In Review | Blocked | Done
//   act  giờ thực tế đã ghi (chỉ có ở task S1)
//   done ngày làm việc của Sprint 1 mà task chuyển Done (1–10), dùng cho burndown
//   add  true = task phát sinh trong sprint (không có lúc lập kế hoạch)
//   rem  giờ còn lại ước lượng lại cuối sprint (task chưa xong)
// =====================================================================

#let team = (
  (who: "Khoa", role: "Tech lead", cap: 30),
  (who: "An", role: "Backend", cap: 60),
  (who: "Bình", role: "Backend", cap: 60),
  (who: "Chi", role: "Frontend", cap: 60),
  (who: "Dũng", role: "Frontend", cap: 60),
  (who: "Hà", role: "QA", cap: 60),
  (who: "Lan", role: "BA / BrSE", cap: 20),
  (who: "Minh", role: "DevOps", cap: 20),
)

#let iterations = (
  (id: "S1", title: "Sprint 1", start: "2026-11-30", end: "2026-12-11"),
  (id: "S2", title: "Sprint 2", start: "2026-12-14", end: "2026-12-25"),
  (id: "S3", title: "Sprint 3", start: "2027-01-04", end: "2027-01-15"),
  (id: "S4", title: "Sprint 4", start: "2027-01-18", end: "2027-01-29"),
)

#let epics = (
  // ------------------------------------------------------------------
  (id: "EP-01", title: "Nền tảng: phân quyền, RLS, audit, mã lỗi", lim: "",
   spec: "system/security/rbac.md · system/api-contracts/error-codes.md · requirements/app/common · ADR-0005 · GAP-01/03/06/10",
   goal: "Đóng các lỗ hổng bảo mật của prototype và dựng phần dùng chung mà mọi màn hình cần: vai trò trong claim JWT, RLS theo vai trò, actor audit lấy từ phiên, danh mục mã lỗi.",
   issues: (
    (id: "I-0101", title: "Vai trò trong claim JWT, `user_roles`, API-CM-05 `/api/me`",
     spec: "rbac.md §3 · ADR-0005 · API-CM-05",
     desc: "Đưa 9 vai trò vào `app_metadata.roles[]` qua custom access token hook; bỏ đọc vai trò từ `user_metadata`.",
     ac: ("Người dùng không tự sửa được vai trò của mình", "`/api/me` trả đúng danh sách vai trò", "Menu và nút ẩn đúng ma trận rbac.md §2"),
     tasks: (
      (r: "DB", t: "Bảng `user_roles` + hook đưa vai trò vào claim JWT", s: 2, c: 3, h: 8, swp: 3, it: "S1", who: "An", st: "Done", act: 9, done: 3),
      (r: "BE", t: "`requireRole` đọc claim + API-CM-05 `/api/me`", s: 2, c: 2, h: 6, swp: 2, it: "S1", who: "An", st: "Done", act: 6, done: 4),
      (r: "FE", t: "Menu và nút lọc theo vai trò (ma trận 18 màn × 9 vai trò)", s: 2, c: 2, h: 8, swp: 2, it: "S1", who: "Chi", st: "Done", act: 8, done: 6),
      (r: "QA", t: "Test ma trận quyền 9 vai trò × 18 màn (menu ẩn, URL trả E09002)", s: 3, c: 2, h: 8, swp: 3, it: "S1", who: "Hà", st: "Done", act: 8, done: 8),
     )),
    (id: "I-0102", title: "RLS theo vai trò cho 17 bảng hiện có (thay `using (true)`)",
     spec: "rbac.md §3 lớp 1 · GAP-01 · erd.md §3 #2",
     desc: "Viết lại chính sách RLS select/insert/update theo ma trận vai trò; mọi người dùng đã đăng nhập không còn ghi được mọi bảng.",
     ac: ("Không còn policy `using (true)` nào", "Mỗi vai trò chỉ đọc/ghi đúng bảng theo ma trận", "Có test tự động bằng JWT giả cho từng vai trò"),
     tasks: (
      (r: "DB", t: "Policy RLS nhóm nhập hàng, tồn kho, lô, sai lệch", s: 2, c: 3, h: 10, swp: 3, it: "S1", who: "Bình", st: "Done", act: 12, done: 4),
      (r: "DB", t: "Policy RLS nhóm đơn hàng, cảnh báo, lịch sử, danh mục", s: 2, c: 3, h: 10, swp: 3, it: "S1", who: "Bình", st: "Done", act: 13, done: 6),
      (r: "DB", t: "Tách FK `skus.temp_band → temp_policies` trước khi bật RLS (phát sinh)", s: 1, c: 2, h: 4, swp: 1, it: "S1", who: "Bình", st: "Done", act: 4, done: 7, add: true),
      (r: "QA", t: "Bộ test RLS (pgTAP) với JWT giả cho 9 vai trò", s: 2, c: 3, h: 10, swp: 3, it: "S1", who: "Hà", st: "In Progress", act: 9, rem: 5),
     )),
    (id: "I-0103", title: "Audit: `actor` lấy từ `auth.uid()` trong trigger",
     spec: "rbac.md §3 · NFR-AUD-01 · GAP-03",
     desc: "Không còn nhận `actor` từ request; trigger ghi actor từ phiên, chặn insert trực tiếp vào `audit_events`.",
     ac: ("Insert giả mạo actor bị từ chối", "Mọi call site không còn gửi actor"),
     tasks: (
      (r: "DB", t: "Trigger gán actor từ `auth.uid()`, thu hồi quyền insert trực tiếp", s: 2, c: 2, h: 6, swp: 2, it: "S1", who: "An", st: "Done", act: 6, done: 3),
      (r: "BE", t: "Bỏ tham số actor ở mọi call site", s: 2, c: 1, h: 3, swp: 1, it: "S1", who: "An", st: "Done", act: 3, done: 4),
      (r: "QA", t: "Test lặp lại kịch bản giả mạo actor (SPOOF_TEST)", s: 1, c: 2, h: 3, swp: 1, it: "S1", who: "Hà", st: "Done", act: 2, done: 5),
     )),
    (id: "I-0104", title: "Danh mục mã lỗi và mã lý do chặn `BLK-*` / `SH-*`",
     spec: "error-codes.md · PREMISE(LAB-4) B-6 · GAP-06",
     desc: "Một mô-đun lỗi dùng chung cho 67 mã; thông điệp lấy từ danh mục; `block_reason` văn bản tự do đổi thành mã.",
     ac: ("API chỉ trả mã trong danh mục", "Màn hình chỉ hiển thị thông điệp của danh mục", "Dữ liệu cũ được chuyển sang mã"),
     tasks: (
      (r: "BE", t: "Mô-đun `errors.ts`, định dạng lỗi chuẩn, ánh xạ 67 mã", s: 2, c: 2, h: 8, swp: 2, it: "S1", who: "Bình", st: "Done", act: 9, done: 5),
      (r: "FE", t: "Danh mục thông điệp và component hiển thị lỗi", s: 2, c: 2, h: 6, swp: 2, it: "S1", who: "Dũng", st: "Done", act: 6, done: 7),
      (r: "DB", t: "Cột `block_reason_code` + chuyển dữ liệu văn bản cũ", s: 2, c: 2, h: 5, swp: 2, it: "S1", who: "Bình", st: "Done", act: 5, done: 5),
     )),
    (id: "I-0105", title: "AUTH_LOGIN và phiên làm việc",
     spec: "requirements/app/common/AUTH_LOGIN_SPEC.md · SYS-CM-01",
     desc: "Màn đăng nhập theo spec (trạng thái lỗi, đang gửi, khóa) và phiên ngắn cho thiết bị dùng chung.",
     ac: ("Đủ trạng thái wireframe của AUTH_LOGIN", "Hết phiên thì quay về đăng nhập, không mất dữ liệu đang nhập"),
     tasks: (
      (r: "FE", t: "Màn AUTH_LOGIN đủ trạng thái theo spec", s: 2, c: 1, h: 5, swp: 1, it: "S1", who: "Dũng", st: "Done", act: 5, done: 3),
      (r: "BE", t: "Phiên ngắn và tự đăng xuất", s: 1, c: 2, h: 4, swp: 1, it: "S1", who: "An", st: "Done", act: 4, done: 4),
     )),
    (id: "I-0106", title: "DASHBOARD, MASTER_VIEW, AUDIT_LOG theo spec",
     spec: "requirements/app/common/{DASHBOARD,MASTER_VIEW,AUDIT_LOG}_SPEC.md",
     desc: "Ba màn hỗ trợ đã có trong prototype, chỉnh theo spec và phân quyền.",
     ac: ("Bộ đếm DASHBOARD lọc theo vai trò", "AUDIT_LOG lọc theo thời gian, đối tượng, người làm và phân trang"),
     tasks: (
      (r: "FE", t: "DASHBOARD: bộ đếm theo vai trò", s: 2, c: 1, h: 5, swp: 1, it: "S1", who: "Chi", st: "Done", act: 5, done: 8),
      (r: "FE", t: "MASTER_VIEW chỉ xem", s: 2, c: 1, h: 4, swp: 1, it: "S1", who: "Dũng", st: "Done", act: 4, done: 9),
      (r: "FE", t: "AUDIT_LOG: lọc, tìm, phân trang", s: 2, c: 2, h: 8, swp: 2, it: "S1", who: "Chi", st: "In Review", act: 8, rem: 2),
     )),
    (id: "I-0107", title: "Loại `POST /api/demo/reset` khỏi bản build production",
     spec: "API-CM-04 · GAP-10",
     desc: "Endpoint xóa audit chỉ tồn tại ở môi trường demo.",
     ac: ("Build production trả 404 cho `/api/demo/reset`",),
     tasks: (
      (r: "OPS", t: "Cờ build loại endpoint demo + kiểm tra trên bản build", s: 1, c: 1, h: 2, swp: 1, it: "S1", who: "Minh", st: "Done", act: 2, done: 2),
     )),
    (id: "I-0108", title: "[Làm rõ] SYS-ER-01: các mã lỗi đang mượn", kind: "clarify",
     spec: "open-questions.md SYS-ER-01",
     desc: "8 chỗ trong spec mượn mã có sẵn (E09005, E09003, E01202…). Quyết định thêm mã riêng hay giữ.",
     ac: ("Mỗi chỗ mượn có quyết định ghi trong PREMISE.md", "error-codes.md cập nhật nếu thêm mã"),
     tasks: (
      (r: "TL", t: "Rà 8 chỗ mượn mã, quyết định, cập nhật danh mục", s: 2, c: 2, h: 4, swp: 2, it: "S1", who: "Khoa", st: "Done", act: 5, done: 6),
     )),
   )),
  // ------------------------------------------------------------------
  (id: "EP-02", title: "Kiểm nhập", lim: "",
   spec: "requirements/app/inbound-inspection · system/rules/temperature-bands.md",
   goal: "Kiểm nhập ba giá trị nhiệt theo phiên bản chính sách đang hiệu lực, cách ly tự động, ghi nguyên tử.",
   issues: (
    (id: "I-0201", title: "Hàm quy tắc nhiệt T-02/T-03 theo phiên bản chính sách",
     spec: "temperature-bands.md T-02, T-03 · ADR-0003",
     desc: "`tempInBand` nhận phiên bản chính sách thay vì hằng số; biên bao gồm, đúng một chữ số thập phân.",
     ac: ("10 ví dụ của temperature-bands.md là unit test và đều qua",),
     tasks: (
      (r: "BE", t: "`tempInBand(version)` + 10 ví dụ thành unit test", s: 1, c: 2, h: 5, swp: 1, it: "S1", who: "Khoa", st: "Done", act: 5, done: 8),
     )),
    (id: "I-0202", title: "API-IN-03 ghi nguyên tử và idempotent",
     spec: "inbound-inspection/api-design.md API-IN-03 · sequence-backend.md",
     desc: "Một hàm DB ghi `inbound_inspections` + `lots` + `deviations` + `audit_events` trong một giao dịch; idempotent theo `source_line_id`.",
     ac: ("Gửi lặp không tạo lô thứ hai", "Lỗi giữa chừng không để lại bản ghi dở", "Nhập sai số chữ số thập phân trả E02003"),
     tasks: (
      (r: "DB", t: "Hàm `submit_inspection` (plpgsql) nguyên tử", s: 2, c: 3, h: 10, swp: 3, it: "S2", who: "Bình", st: "Todo"),
      (r: "BE", t: "Route handler gọi RPC, kiểm đầu vào, ánh xạ mã lỗi", s: 2, c: 2, h: 6, swp: 2, it: "S2", who: "Bình", st: "Todo"),
      (r: "QA", t: "Test gửi đồng thời và gửi lặp", s: 2, c: 3, h: 6, swp: 3, it: "S2", who: "Hà", st: "Todo"),
     )),
    (id: "I-0203", title: "Làn truy xuất (gạo, bò 10 chữ số) và cách ly khi lỗi truy xuất",
     spec: "INBOUND_INSPECTION_SPEC.md · E01107/E01108",
     desc: "Trường bắt buộc theo làn; lỗi truy xuất → lô QUARANTINE.",
     ac: ("Mã cá thể bò sai định dạng trả E01108", "Lỗi truy xuất tạo lô cách ly"),
     tasks: (
      (r: "BE", t: "Kiểm tra làn truy xuất E01107/E01108", s: 1, c: 2, h: 4, swp: 1, it: "S2", who: "An", st: "Todo"),
      (r: "FE", t: "Trường động theo làn truy xuất", s: 2, c: 2, h: 5, swp: 2, it: "S2", who: "Dũng", st: "Todo"),
     )),
    (id: "I-0204", title: "Màn INBOUND_LIST",
     spec: "INBOUND_LIST_SPEC.md · API-IN-01",
     desc: "Danh sách lịch hẹn và dòng nhập theo spec.",
     ac: ("Lọc, trạng thái, phân trang đúng spec",),
     tasks: (
      (r: "FE", t: "INBOUND_LIST: lọc, trạng thái, phân trang", s: 2, c: 1, h: 5, swp: 1, it: "S1", who: "Dũng", st: "Done", act: 5, done: 9),
     )),
    (id: "I-0205", title: "Màn INBOUND_INSPECTION",
     spec: "INBOUND_INSPECTION_SPEC.md · event.md · NFR-ACC-01",
     desc: "Form ba giá trị nhiệt, đánh giá trực tiếp, trạng thái cách ly; dùng được trên máy tính bảng khi đeo găng.",
     ac: ("Đủ trạng thái wireframe", "Vùng chạm ≥ 44 px, bàn phím số cho nhiệt độ"),
     tasks: (
      (r: "FE", t: "Form kiểm nhập + đánh giá trực tiếp + trạng thái cách ly", s: 3, c: 2, h: 12, swp: 3, it: "S1", who: "Dũng", st: "Done", act: 12, done: 10),
      (r: "FE", t: "Tối ưu máy tính bảng (vùng chạm, bàn phím số)", s: 1, c: 1, h: 3, swp: 1, it: "S2", who: "Chi", st: "Todo"),
      (r: "QA", t: "Test màn hình theo event.md", s: 2, c: 2, h: 6, swp: 2, it: "S2", who: "Hà", st: "Todo"),
     )),
   )),
  // ------------------------------------------------------------------
  (id: "EP-03", title: "Phân bổ lô và kiểm xuất", lim: "",
   spec: "requirements/app/outbound-allocation-shipping · system/rules/allocation-chain.md",
   goal: "Chuỗi phân bổ cố định có bằng chứng từng lô, tách nhiều lô, sổ cái tồn kho, kiểm xuất theo dải nhiệt.",
   issues: (
    (id: "I-0301", title: "Sổ cái tồn kho: `qty_on_hand` / `qty_reserved`, `inventory_movements`, `lot_reservations`",
     spec: "PREMISE(LAB-4) B-4 · table-definitions.md · GAP-05",
     desc: "Bỏ trừ `qty_available` ngay khi phân bổ; giữ chỗ và biến động có sổ cái.",
     ac: ("Tổng biến động = tồn hiện có", "Giữ chỗ đồng thời không vượt tồn (khóa dòng)"),
     tasks: (
      (r: "DB", t: "Migration sổ cái + chuyển dữ liệu `qty_available`", s: 2, c: 3, h: 10, swp: 3, it: "S2", who: "Bình", st: "Todo"),
      (r: "DB", t: "Hàm `allocate_lot` / `release_lot` với `for update`", s: 2, c: 3, h: 10, swp: 3, it: "S2", who: "Bình", st: "Todo"),
     )),
    (id: "I-0302", title: "Chuỗi phân bổ Rule A-01…A-08 và tách lô",
     spec: "allocation-chain.md · PM-14 · SYS-AL-01",
     desc: "`evaluateLot` theo thứ tự cố định, lưu bằng chứng từng lô; tách nhiều lô theo FEFO rồi FIFO.",
     ac: ("Mọi ví dụ của allocation-chain.md là unit test và đều qua", "Bước thất bại chủ đạo theo SYS-AL-01"),
     tasks: (
      (r: "BE", t: "`evaluateLot` 7 bước + bằng chứng từng lô", s: 2, c: 3, h: 10, swp: 3, it: "S2", who: "An", st: "Todo"),
      (r: "BE", t: "Tách nhiều lô FEFO/FIFO", s: 2, c: 3, h: 8, swp: 3, it: "S2", who: "An", st: "Todo"),
      (r: "QA", t: "Ví dụ allocation-chain thành unit test", s: 1, c: 2, h: 5, swp: 1, it: "S2", who: "Hà", st: "Todo"),
     )),
    (id: "I-0303", title: "API-OUT-03/04/05/07 theo hợp đồng mới",
     spec: "outbound-allocation-shipping/api-design.md · SYS-OUT-01",
     desc: "Phân bổ mỗi dòng một giao dịch; chọn lô thủ công trả E01205 khi đảo hạn; hủy phân bổ.",
     ac: ("Một dòng lỗi không hủy các dòng đã giữ chỗ", "E01205 khi chọn tay lô đảo hạn"),
     tasks: (
      (r: "BE", t: "API-OUT-03 phân bổ mỗi dòng một giao dịch", s: 2, c: 3, h: 8, swp: 3, it: "S3", who: "An", st: "Todo"),
      (r: "BE", t: "API-OUT-05 chọn lô thủ công + API-OUT-07 hủy phân bổ", s: 2, c: 2, h: 6, swp: 2, it: "S3", who: "An", st: "Todo"),
     )),
    (id: "I-0304", title: "Màn OUTBOUND_LIST và OUTBOUND_ALLOCATION",
     spec: "OUTBOUND_LIST_SPEC.md · OUTBOUND_ALLOCATION_SPEC.md",
     desc: "Danh sách đơn; màn phân bổ hiển thị kết quả từng bước của chuỗi và các lô tách.",
     ac: ("Mỗi lô bị loại hiển thị đúng mã `BLK-*`", "Hiển thị tách lô và tổng số lượng"),
     tasks: (
      (r: "FE", t: "OUTBOUND_LIST", s: 2, c: 1, h: 4, swp: 1, it: "S3", who: "Dũng", st: "Todo"),
      (r: "FE", t: "OUTBOUND_ALLOCATION: chuỗi đánh giá, tách lô", s: 3, c: 3, h: 14, swp: 5, it: "S3", who: "Chi", st: "Todo"),
     )),
    (id: "I-0305", title: "Kiểm xuất OUTBOUND_SHIP_CHECK và API-OUT-06",
     spec: "OUTBOUND_SHIP_CHECK_SPEC.md · T-04 · SH-* · PM-15 · PREMISE(LAB-4) B-7",
     desc: "Seal, nhiệt khoang theo dải, nhiệt hàng, quét mã lô; không ghi lịch sử giao ở bước này.",
     ac: ("Chặn khi nhiệt khoang ngoài dải", "Lần kiểm thất bại được lưu", "Không ghi `shipment_history`"),
     tasks: (
      (r: "BE", t: "API-OUT-06: seal, nhiệt khoang, quét lô", s: 2, c: 3, h: 10, swp: 3, it: "S3", who: "Bình", st: "Todo"),
      (r: "FE", t: "Màn kiểm xuất + quét mã lô", s: 3, c: 2, h: 10, swp: 3, it: "S3", who: "Dũng", st: "Todo"),
      (r: "QA", t: "Test đạt / chặn / tạo deviation", s: 2, c: 2, h: 6, swp: 2, it: "S3", who: "Hà", st: "Todo"),
     )),
   )),
  // ------------------------------------------------------------------
  (id: "EP-04", title: "Cảnh báo đảo hạn", lim: "",
   spec: "requirements/app/date-reversal-alert · allocation-chain.md Rule A-06",
   goal: "Cấm đảo hạn so với lần giao được chấp nhận gần nhất theo `completed_at` của POD.",
   issues: (
    (id: "I-0401", title: "Rule A-06 theo `completed_at` của POD",
     spec: "PM-04 · B-7 · Rule A-06",
     desc: "Truy vấn lần giao chấp nhận gần nhất cùng khách–SKU (chưa bị đảo), tạo cảnh báo khi đảo hạn.",
     ac: ("Ví dụ đảo hạn trong allocation-chain.md đều qua", "Lần giao bị đảo lịch sử không được dùng làm mốc"),
     tasks: (
      (r: "BE", t: "Truy vấn lần giao gần nhất + tạo cảnh báo", s: 2, c: 3, h: 8, swp: 3, it: "S3", who: "Bình", st: "Todo"),
      (r: "QA", t: "Test ví dụ đảo hạn", s: 1, c: 2, h: 4, swp: 1, it: "S3", who: "Hà", st: "Todo"),
     )),
    (id: "I-0402", title: "REVERSAL_ALERT_LIST / DETAIL và API-AL-01…03",
     spec: "REVERSAL_ALERT_LIST_SPEC.md · REVERSAL_ALERT_DETAIL_SPEC.md",
     desc: "Danh sách, chi tiết so sánh lô đề xuất với lần giao gần nhất; xác nhận đã xử lý không giải phóng lô.",
     ac: ("Lọc theo trạng thái/nguồn/khách", "PATCH không đổi trạng thái lô"),
     tasks: (
      (r: "BE", t: "API-AL-01/02/03 với mã lỗi E014xx", s: 2, c: 2, h: 6, swp: 2, it: "S3", who: "Bình", st: "Todo"),
      (r: "FE", t: "Danh sách + chi tiết so sánh lô", s: 3, c: 2, h: 10, swp: 3, it: "S3", who: "Chi", st: "Todo"),
     )),
   )),
  // ------------------------------------------------------------------
  (id: "EP-05", title: "Tồn kho, trạng thái lô và lịch sử giao", lim: "",
   spec: "requirements/app/inventory-lot-status",
   goal: "Lịch sử trạng thái lô bất biến; lịch sử giao ghi lúc POD; đảo lịch sử có người lập ≠ người duyệt.",
   issues: (
    (id: "I-0501", title: "`lot_status_events` bất biến và API-LOT-02/03",
     spec: "LOT_DETAIL_SPEC.md · api-design.md · GAP-07 · E01505",
     desc: "Đổi trạng thái lô qua một hàm nguyên tử; chặn cách ly lô đang có giữ chỗ.",
     ac: ("Không sửa/xóa được `lot_status_events`", "Cách ly lô có giữ chỗ trả E01505"),
     tasks: (
      (r: "DB", t: "Bảng + trigger chỉ ghi thêm + hàm `change_lot_status`", s: 2, c: 3, h: 8, swp: 3, it: "S3", who: "An", st: "Todo"),
      (r: "BE", t: "API-LOT-02/03 theo ma trận vai trò", s: 2, c: 2, h: 6, swp: 2, it: "S3", who: "An", st: "Todo"),
     )),
    (id: "I-0502", title: "Màn LOT_INVENTORY và LOT_DETAIL",
     spec: "LOT_INVENTORY_SPEC.md · LOT_DETAIL_SPEC.md",
     desc: "Danh sách lô theo dải/trạng thái; chi tiết lô có dòng thời gian và hộp thoại đổi trạng thái.",
     ac: ("Đủ trạng thái wireframe", "Nút đổi trạng thái theo vai trò"),
     tasks: (
      (r: "FE", t: "LOT_INVENTORY: lọc dải nhiệt, trạng thái", s: 2, c: 2, h: 8, swp: 2, it: "S4", who: "Dũng", st: "Todo"),
      (r: "FE", t: "LOT_DETAIL: dòng thời gian + đổi trạng thái", s: 3, c: 2, h: 10, swp: 3, it: "S4", who: "Dũng", st: "Todo"),
     )),
    (id: "I-0503", title: "Lịch sử giao ghi lúc POD và đảo lịch sử (người lập ≠ người duyệt)",
     spec: "SHIPMENT_HISTORY_SPEC.md · API-HIS-02/03/04 · GAP-09 · E01902",
     desc: "Endpoint `DELIVERY_COMPLETED` ghi `shipment_history`; đề xuất và duyệt đảo lịch sử.",
     ac: ("Lịch sử chỉ ghi khi có sự kiện POD", "Người lập tự duyệt trả E01902"),
     tasks: (
      (r: "BE", t: "API-HIS-04 nhận sự kiện POD (xác thực chữ ký)", s: 2, c: 2, h: 6, swp: 2, it: "S3", who: "Bình", st: "Todo"),
      (r: "BE", t: "`shipment_history_reversals` + API-HIS-02/03", s: 2, c: 3, h: 8, swp: 3, it: "S4", who: "Bình", st: "Todo"),
      (r: "FE", t: "SHIPMENT_HISTORY + đề xuất / duyệt đảo", s: 3, c: 2, h: 10, swp: 3, it: "S4", who: "Chi", st: "Todo"),
      (r: "QA", t: "Test người lập ≠ người duyệt (E01902)", s: 1, c: 2, h: 3, swp: 1, it: "S4", who: "Hà", st: "Todo"),
     )),
   )),
  // ------------------------------------------------------------------
  (id: "EP-06", title: "Ngưỡng nhiệt 3 dải có phiên bản", lim: "",
   spec: "requirements/app/temperature-policy · temperature-bands.md · PM-05/06",
   goal: "AMBIENT 15.0–25.0, CHILLED 0.0–5.0, FROZEN ≤ −18.0 °C, biên bao gồm, có phiên bản và ngày hiệu lực, người lập ≠ người duyệt.",
   issues: (
    (id: "I-0601", title: "Schema `temp_policy_versions` + `temp_policy_band_values`",
     spec: "table-definitions.md · GAP-02 · GAP-04",
     desc: "Thay `temp_policies` một phiên bản; nạp v1 hiệu lực 2026-04-01; giá trị đánh giá = giá trị lưu.",
     ac: ("v1 nạp đúng 3 dải", "Không còn làm tròn ngầm khi lưu"),
     tasks: (
      (r: "DB", t: "Schema phiên bản + nạp v1 (PM-05)", s: 2, c: 2, h: 6, swp: 2, it: "S1", who: "An", st: "Done", act: 6, done: 2),
      (r: "DB", t: "Bắt buộc một chữ số thập phân, bỏ làm tròn `numeric(4,1)`", s: 1, c: 2, h: 3, swp: 1, it: "S1", who: "An", st: "Done", act: 3, done: 3),
     )),
    (id: "I-0602", title: "API-TP-01…05 và vòng đời phiên bản",
     spec: "temperature-policy/api-design.md · SYS-NT-02 · E01604",
     desc: "Nháp → chờ duyệt → duyệt → hiệu lực vào `effective_from`; người lập không tự duyệt.",
     ac: ("Tự duyệt trả E01604", "Job kích hoạt đúng ngày hiệu lực (JST)"),
     tasks: (
      (r: "BE", t: "API-TP-01…05 + kiểm người lập ≠ người duyệt", s: 2, c: 3, h: 10, swp: 3, it: "S1", who: "Bình", st: "Done", act: 12, done: 7),
      (r: "DB", t: "Job kích hoạt theo `effective_from` (pg_cron)", s: 2, c: 2, h: 5, swp: 2, it: "S1", who: "Bình", st: "Done", act: 5, done: 8),
     )),
    (id: "I-0603", title: "Màn TEMP_POLICY",
     spec: "TEMP_POLICY_SPEC.md",
     desc: "Danh sách phiên bản, form bản nháp, duyệt/từ chối.",
     ac: ("Đủ trạng thái wireframe", "10 ví dụ biên hiển thị đúng"),
     tasks: (
      (r: "FE", t: "TEMP_POLICY: danh sách phiên bản, form nháp, duyệt", s: 3, c: 2, h: 12, swp: 3, it: "S1", who: "Chi", st: "In Progress", act: 6, rem: 6),
      (r: "QA", t: "Test 10 ví dụ biên + phiên bản theo ngày", s: 2, c: 2, h: 6, swp: 2, it: "S2", who: "Hà", st: "Todo"),
     )),
   )),
  // ------------------------------------------------------------------
  (id: "EP-07", title: "[Giờ lái 2024] Bộ quy tắc và engine `evaluateRoute`", lim: "driver-2024",
   spec: "system/rules/driver-hours.md (JP-TRUCK-2024-04, H-01…H-12) · DRIVER_RULESET_SPEC.md · ADR-0003 · PM-07…PM-11",
   goal: "Đánh giá một tuyến theo quy định giờ làm của tài xế xe tải áp dụng từ 2024-04-01: trả vi phạm kèm khoảng thời gian chính xác; giá trị quy tắc là dữ liệu có phiên bản.",
   issues: (
    (id: "I-0701", title: "Schema bộ quy tắc + nạp `JP-TRUCK-2024-04`",
     spec: "driver-hours.md §2 · table-definitions.md §E",
     desc: "`driver_rule_sets` / `driver_rule_values` với 12 giá trị H-01…H-12; giá trị không nằm trong mã.",
     ac: ("12 giá trị khớp driver-hours.md §2", "Mỗi giá trị ghi nguồn (RFP / cổng MHLW)"),
     tasks: (
      (r: "DB", t: "Bảng bộ quy tắc + nạp 12 giá trị + CHECK", s: 2, c: 2, h: 6, swp: 2, it: "S1", who: "An", st: "Done", act: 6, done: 2),
      (r: "BA", t: "Đối chiếu 12 giá trị với cổng MHLW, ghi nguồn", s: 1, c: 2, h: 3, swp: 1, it: "S1", who: "Lan", st: "Done", act: 3, done: 2),
     )),
    (id: "I-0702", title: "Engine: dựng ca, 拘束時間 trong ngày (H-03, H-04, H-05)",
     spec: "driver-hours.md §3 bước 2–3 · PM-10",
     desc: "Dựng ca từ các đoạn có kiểu; > 13 h cảnh báo, > 15 h chặn; đếm ngày > 14 h trong tuần JST.",
     ac: ("Ví dụ 1–3 của driver-hours.md qua", "Tuần bắt đầu thứ Hai theo JST"),
     tasks: (
      (r: "BE", t: "Dựng ca từ đoạn có kiểu + H-03/H-04", s: 1, c: 3, h: 6, swp: 2, it: "S1", who: "An", st: "Done", act: 6, done: 4),
      (r: "BE", t: "Đếm ngày > 14 h theo tuần JST (H-05)", s: 1, c: 3, h: 5, swp: 2, it: "S1", who: "An", st: "Done", act: 5, done: 5),
     )),
    (id: "I-0703", title: "Engine: thời gian nghỉ giữa ca (H-06, H-07)",
     spec: "driver-hours.md §3 bước 4",
     desc: "Nghỉ trước ca < 9 h chặn, 9–11 h cảnh báo; ca đầu tiên không có nghỉ trước.",
     ac: ("Ví dụ 4–5 qua",),
     tasks: (
      (r: "BE", t: "Tính `rest_before` từ ca trước (H-06/H-07)", s: 1, c: 2, h: 4, swp: 1, it: "S1", who: "An", st: "Done", act: 4, done: 6),
     )),
    (id: "I-0704", title: "Engine: lái liên tục và gián đoạn đạt chuẩn (H-10, H-11)",
     spec: "driver-hours.md §3 bước 5 · FR-SCH-02 \"正確な違反時間範囲\"",
     desc: "Cộng dồn lái kể từ gián đoạn đạt chuẩn (tổng ≥ 30 phút, mỗi quãng ≥ 10 phút, hoàn tất trước mốc 4 h); báo đúng thời điểm vượt mốc.",
     ac: ("Ví dụ 6–8 qua, ví dụ 8 báo đúng 10:40", "Trả khoảng vi phạm chính xác đến phút"),
     tasks: (
      (r: "BE", t: "Thuật toán `drive_since_break` + nhóm BREAK đạt chuẩn", s: 1, c: 4, h: 10, swp: 3, it: "S1", who: "Bình", st: "Done", act: 11, done: 8),
      (r: "BE", t: "Trả khoảng vi phạm chính xác (mốc vượt 4 h)", s: 1, c: 3, h: 5, swp: 2, it: "S1", who: "Bình", st: "In Review", act: 5, rem: 1),
     )),
    (id: "I-0705", title: "Engine: trung bình lái 2 ngày và 2 tuần (H-08, H-09)",
     spec: "driver-hours.md §3 bước 6–7",
     desc: "Ghép thời gian lái của tuyến với lịch sử `driver_duty_days`; xét (D−1, D) và (D, D+1); cửa sổ 2 tuần dương lịch.",
     ac: ("Ví dụ 9–11 qua", "Đúng 9 h trung bình là OK (giới hạn là \"hơn 9 h\")"),
     tasks: (
      (r: "BE", t: "Tổng lái theo ngày từ lịch sử + tuyến, trung bình 2 ngày (H-08)", s: 2, c: 3, h: 8, swp: 3, it: "S2", who: "An", st: "Todo"),
      (r: "BE", t: "Cửa sổ 2 tuần dương lịch (H-09)", s: 1, c: 3, h: 5, swp: 2, it: "S2", who: "An", st: "Todo"),
     )),
    (id: "I-0706", title: "Engine: 拘束時間 tháng/năm, thỏa thuận lao động, làm thêm (H-01, H-02, H-12)",
     spec: "driver-hours.md §3 bước 8–9 · PREMISE.md B-01",
     desc: "Tổng tháng và cuộn 12 tháng; trần 284/3300 hoặc 310/3400 khi có thỏa thuận; đếm ≤ 6 tháng/năm và không quá 3 tháng liên tiếp vượt 284 h; H-12 dùng số giờ làm thêm từ HR.",
     ac: ("Ví dụ 12–13 qua", "Tháng thứ 4 liên tiếp vượt 284 h bị chặn"),
     tasks: (
      (r: "BE", t: "Tổng tháng/năm, trần theo thỏa thuận, đếm 6 tháng và 3 tháng liên tiếp", s: 2, c: 4, h: 12, swp: 5, it: "S2", who: "Bình", st: "Todo"),
      (r: "BE", t: "H-12 làm thêm 960 h từ số liệu HR", s: 1, c: 2, h: 3, swp: 1, it: "S2", who: "Bình", st: "Todo"),
     )),
    (id: "I-0707", title: "Bộ vector kiểm thử dùng chung cho giờ lái",
     spec: "NFR-TST-01 · driver-hours.md §6 · specs/tools/verify_rules.py",
     desc: "13 ví dụ thành unit test của `evaluateRoute`; thêm ca biên.",
     ac: ("13 ví dụ qua trên CI", "Có ca: đúng 4 h 00, đúng 9 h 00 nghỉ, ca qua nửa đêm, tháng vượt liên tiếp"),
     tasks: (
      (r: "QA", t: "13 ví dụ driver-hours.md thành unit test", s: 1, c: 2, h: 5, swp: 1, it: "S1", who: "Hà", st: "Done", act: 5, done: 9),
      (r: "QA", t: "Ca biên: 4 h 00, nghỉ 9 h 00, qua nửa đêm, 3 tháng liên tiếp", s: 2, c: 3, h: 8, swp: 3, it: "S2", who: "Hà", st: "Todo"),
     )),
    (id: "I-0708", title: "API-DR-01…04 và màn DRIVER_RULESET",
     spec: "DRIVER_RULESET_SPEC.md · API-DR-01…04 · E01803",
     desc: "Tạo phiên bản bộ quy tắc mới, sửa giá trị, gửi duyệt; người duyệt ≠ người lập.",
     ac: ("Tự duyệt trả E01803", "Không xóa được dòng quy tắc BLOCK"),
     tasks: (
      (r: "BE", t: "API-DR-01…04", s: 2, c: 3, h: 8, swp: 3, it: "S3", who: "An", st: "Todo"),
      (r: "FE", t: "Màn DRIVER_RULESET", s: 3, c: 2, h: 10, swp: 3, it: "S3", who: "Chi", st: "Todo"),
     )),
    (id: "I-0709", title: "[Làm rõ] Q-15: giới hạn nào chặn, giới hạn nào cảnh báo; xác nhận pháp lý", kind: "clarify",
     spec: "PM-08 (LAB-4) · Q-15 · OPS-LAW-01",
     desc: "Phân loại BLOCK/WARN hiện là giả định của chúng tôi. Cần pháp chế Yuki xác nhận trước khi chốt engine.",
     ac: ("Có trả lời bằng văn bản từ Yuki", "PM-08 và bộ quy tắc cập nhật theo trả lời"),
     tasks: (
      (r: "BA", t: "Bảng hỏi kèm ví dụ cho pháp chế Yuki", s: 1, c: 2, h: 3, swp: 1, it: "S1", who: "Lan", st: "Done", act: 3, done: 3),
      (r: "TL", t: "Họp xác nhận, cập nhật PM-08 và bộ quy tắc theo trả lời", s: 2, c: 2, h: 4, swp: 2, it: "S1", who: "Khoa", st: "Blocked", act: 1, rem: 4),
     )),
   )),
  // ------------------------------------------------------------------
  (id: "EP-08", title: "[Giờ lái 2024] Lập tuyến, kiểm tra và công bố", lim: "driver-2024",
   spec: "requirements/app/route-driver-hours (ROUTE_LIST, ROUTE_CHECK) · API-RT-01…08 · IF-MAP-01",
   goal: "Người lập kế hoạch dựng tuyến bằng các đoạn có kiểu, thấy vi phạm theo khoảng thời gian, chỉ công bố được khi không có BLOCK.",
   issues: (
    (id: "I-0801", title: "Schema tuyến, phiên bản, đoạn, kết quả tuân thủ, sự kiện khẩn cấp",
     spec: "table-definitions.md §E · erd.md §2",
     desc: "`routes`, `route_versions`, `route_stops`, `route_segments`, `route_compliance_results`, `route_violations`, `emergency_events` + RLS PLANNER / DRIVER (của mình).",
     ac: ("DRIVER chỉ đọc được tuyến đã công bố của mình",),
     tasks: (
      (r: "DB", t: "Migration 7 bảng tuyến + RLS PLANNER/DRIVER", s: 2, c: 3, h: 10, swp: 3, it: "S1", who: "Khoa", st: "Done", act: 10, done: 7),
     )),
    (id: "I-0802", title: "API-RT-01…04: tạo tuyến, lưu bản nháp đoạn có kiểu",
     spec: "route-driver-hours/api-design.md · E01705",
     desc: "Danh sách, tạo, đọc tuyến; lưu phiên bản nháp với các đoạn DRIVE/LOAD/SERVICE/WAIT/BREAK.",
     ac: ("Tài xế đã gán tuyến khác cùng ngày trả E01705", "Đoạn chồng lấn bị từ chối"),
     tasks: (
      (r: "BE", t: "API-RT-01/02/03", s: 2, c: 2, h: 8, swp: 2, it: "S2", who: "Bình", st: "Todo"),
      (r: "BE", t: "API-RT-04 lưu phiên bản nháp, kiểm đoạn chồng lấn", s: 2, c: 3, h: 8, swp: 3, it: "S2", who: "Bình", st: "Todo"),
     )),
    (id: "I-0803", title: "IF-MAP-01: adapter dịch vụ bản đồ và nhập tay khi lỗi",
     spec: "driver-hours.md §8 · ADR-0008 · Q-23 · E01706",
     desc: "Interface adapter, cache, hết thời gian chờ thì nhập tay; tích hợp nhà cung cấp thật khi Q-23 có trả lời.",
     ac: ("Bản đồ lỗi vẫn lập được tuyến bằng nhập tay", "Tổng ước tính > 24 h trả E01706"),
     tasks: (
      (r: "BE", t: "Interface adapter + bản giả lập + nhập tay + cache", s: 2, c: 3, h: 8, swp: 3, it: "S2", who: "An", st: "Todo"),
      (r: "BE", t: "Adapter nhà cung cấp bản đồ: thời gian chạy xe tải theo đoạn (chờ Q-23)", s: 2, c: 3, h: 6, swp: 3, it: "S4", who: "An", st: "Todo"),
      (r: "QA", t: "Kiểm thử adapter với sandbox nhà cung cấp: timeout, cache (chờ Q-23)", s: 2, c: 2, h: 4, swp: 2, it: "S4", who: "Hà", st: "Todo"),
     )),
    (id: "I-0804", title: "API-RT-05 kiểm tra tuyến và API-RT-06 gợi ý điểm nghỉ",
     spec: "driver-hours.md §3–§4 · FR-SCH-03",
     desc: "Chạy `evaluateRoute`, lưu kết quả và vi phạm; gợi ý điểm nghỉ 30 phút sớm nhất tại hoặc trước mốc 4 h.",
     ac: ("Vi phạm lưu kèm khoảng thời gian", "Gợi ý chỉ được lưu khi người lập chấp nhận"),
     tasks: (
      (r: "BE", t: "API-RT-05 lưu kết quả và vi phạm", s: 2, c: 2, h: 6, swp: 2, it: "S3", who: "Bình", st: "Todo"),
      (r: "BE", t: "Thuật toán gợi ý điểm nghỉ (API-RT-06)", s: 1, c: 4, h: 8, swp: 3, it: "S3", who: "An", st: "Todo"),
     )),
    (id: "I-0805", title: "API-RT-07 công bố: chặn khi có BLOCK, gắn phiên bản bộ quy tắc",
     spec: "driver-hours.md §3 bước 10 · E01702 · sequence-backend.md",
     desc: "Công bố nguyên tử: kiểm lại, gắn phiên bản bộ quy tắc, upsert `driver_duty_days` (source ROUTE).",
     ac: ("Có BLOCK thì trả E01702", "Đổi bộ quy tắc sau đó không đánh giá lại tuyến đã công bố"),
     tasks: (
      (r: "BE", t: "Hàm công bố nguyên tử + upsert `driver_duty_days`", s: 2, c: 3, h: 8, swp: 3, it: "S3", who: "Bình", st: "Todo"),
      (r: "QA", t: "Test không đánh giá lại khi đổi bộ quy tắc", s: 1, c: 2, h: 3, swp: 1, it: "S3", who: "Hà", st: "Todo"),
     )),
    (id: "I-0806", title: "API-RT-08 sự kiện khẩn cấp có bằng chứng",
     spec: "driver-hours.md §5 · FR-SCH-05 · PM-11",
     desc: "Ghi `emergency_events` kèm bằng chứng; chỉ loại khỏi H-04, H-08, H-10; báo cáo tách riêng, không ghi đè kết quả.",
     ac: ("Thiếu bằng chứng bị từ chối", "Kết quả đã tính không bị sửa"),
     tasks: (
      (r: "BE", t: "Ghi sự kiện khẩn cấp + loại trừ có phạm vi", s: 2, c: 3, h: 8, swp: 3, it: "S4", who: "Bình", st: "Todo"),
     )),
    (id: "I-0807", title: "Màn ROUTE_LIST",
     spec: "ROUTE_LIST_SPEC.md · API-RT-01",
     desc: "Danh sách tuyến theo ngày/tài xế; DRIVER chỉ thấy tuyến của mình.",
     ac: ("Lọc theo ngày, tài xế, kết quả tuân thủ",),
     tasks: (
      (r: "FE", t: "ROUTE_LIST theo ngày/tài xế", s: 2, c: 1, h: 5, swp: 1, it: "S2", who: "Dũng", st: "Todo"),
     )),
    (id: "I-0808", title: "Màn ROUTE_CHECK: sửa đoạn, timeline vi phạm, gợi ý nghỉ, công bố",
     spec: "ROUTE_CHECK_SPEC.md · sequence-ui.md",
     desc: "Trình sửa đoạn có kiểu, timeline tô khoảng vi phạm, chấp nhận gợi ý nghỉ, công bố; chế độ xem đơn giản cho DRIVER.",
     ac: ("Khoảng vi phạm tô đúng trên timeline", "DRIVER không thấy giá trị quy tắc và giờ làm thêm"),
     tasks: (
      (r: "FE", t: "Trình sửa các đoạn có kiểu", s: 3, c: 3, h: 14, swp: 5, it: "S3", who: "Chi", st: "Todo"),
      (r: "FE", t: "Timeline tô khoảng vi phạm + gợi ý nghỉ", s: 3, c: 3, h: 12, swp: 5, it: "S3", who: "Dũng", st: "Todo"),
      (r: "FE", t: "Chế độ xem đơn giản cho DRIVER", s: 2, c: 1, h: 4, swp: 1, it: "S4", who: "Dũng", st: "Todo"),
      (r: "QA", t: "E2E lập → kiểm → công bố tuyến", s: 3, c: 2, h: 8, swp: 3, it: "S4", who: "Hà", st: "Todo"),
     )),
   )),
  // ------------------------------------------------------------------
  (id: "EP-09", title: "[Giờ lái 2024] Dữ liệu đầu vào giờ làm của tài xế", lim: "driver-2024",
   spec: "table-definitions.md `drivers`, `driver_duty_days` · SYS-DH-01 · PREMISE.md B-02, B-03",
   goal: "Engine cần lịch sử 365 ngày, cờ thỏa thuận lao động và giờ làm thêm của từng tài xế; bộ spec LAB-4 có bảng nhưng không có đường nạp dữ liệu.",
   issues: (
    (id: "I-0901", title: "Nạp danh mục tài xế, xe và cờ thỏa thuận lao động (CSV)",
     spec: "PREMISE.md B-02 · table-definitions.md `drivers`, `vehicles`",
     desc: "Không có màn hình (sửa danh mục ngoài phạm vi, R-2); nạp bằng CSV có kiểm tra và audit.",
     ac: ("CSV sai định dạng bị từ chối theo dòng", "Mọi thay đổi cờ thỏa thuận có audit"),
     tasks: (
      (r: "DB", t: "Bảng `drivers` / `vehicles` + RLS", s: 1, c: 2, h: 3, swp: 1, it: "S2", who: "An", st: "Todo"),
      (r: "BE", t: "Nạp CSV tài xế/xe/cờ thỏa thuận + kiểm tra", s: 2, c: 2, h: 6, swp: 2, it: "S2", who: "An", st: "Todo"),
     )),
    (id: "I-0902", title: "Nạp lịch sử giờ làm 365 ngày (`driver_duty_days`, source IMPORT)",
     spec: "PREMISE.md B-03 · driver-hours.md §3 đầu vào",
     desc: "Khi go-live chưa có tuyến nào trong hệ thống; engine cần lịch sử thật để tính H-01/H-02/H-08/H-09.",
     ac: ("Dòng IMPORT trùng ngày với dòng ROUTE bị báo lỗi", "Thiếu lịch sử thì màn hình cảnh báo"),
     tasks: (
      (r: "BE", t: "API nạp CSV `driver_duty_days`, kiểm trùng với ROUTE", s: 2, c: 3, h: 8, swp: 3, it: "S3", who: "Bình", st: "Todo"),
      (r: "QA", t: "Test lịch sử qua ranh giới tuần/tháng", s: 1, c: 2, h: 4, swp: 1, it: "S3", who: "Hà", st: "Todo"),
     )),
    (id: "I-0903", title: "Giờ làm thêm năm từ HR (SYS-DH-01)",
     spec: "SYS-DH-01 · H-12 · PREMISE.md A-03",
     desc: "SUPERVISOR cập nhật `overtime_ytd_h` theo số HR gửi hằng tháng; có audit.",
     ac: ("Thay đổi có audit", "Số âm bị từ chối"),
     tasks: (
      (r: "BE", t: "Endpoint cập nhật `overtime_ytd_h` có audit", s: 1, c: 2, h: 3, swp: 1, it: "S3", who: "An", st: "Todo"),
     )),
    (id: "I-0904", title: "[Làm rõ] Ca qua nửa đêm: \"ngày\" tính theo lịch hay 24 h từ giờ bắt đầu ca", kind: "clarify",
     spec: "PREMISE.md A-01 · driver-hours.md H-08 · `driver_duty_days.duty_date`",
     desc: "Spec LAB-4 dùng \"ngày của tuyến (JST)\" nhưng không nói ca qua nửa đêm thuộc ngày nào khi tính trung bình 2 ngày.",
     ac: ("Yuki xác nhận quy ước", "driver-hours.md và test biên cập nhật theo"),
     tasks: (
      (r: "BA", t: "Đề xuất quy ước kèm ví dụ, gửi hỏi Yuki", s: 1, c: 3, h: 4, swp: 1, it: "S1", who: "Lan", st: "Blocked", act: 3, rem: 1),
     )),
   )),
  // ------------------------------------------------------------------
  (id: "EP-10", title: "Hạ tầng, kiểm thử xuyên suốt và phát hành", lim: "",
   spec: "system/nfr/nfr.md · system/architecture/overview.md · ADR-0009",
   goal: "Môi trường Tokyo, CI, sao lưu, hiệu năng, E2E hồi quy và giao diện JA/VI.",
   issues: (
    (id: "I-1001", title: "Môi trường Tokyo và CI",
     spec: "NFR-DAT-01 · ADR-0009 · GAP-10",
     desc: "Supabase ap-northeast-1, Vercel hnd1; GitHub Actions chạy lint, typecheck, unit, pgTAP, migration.",
     ac: ("Mọi PR chạy CI", "Không còn tài nguyên ở London"),
     tasks: (
      (r: "OPS", t: "Dựng project Tokyo, biến môi trường, secret", s: 2, c: 2, h: 6, swp: 2, it: "S1", who: "Minh", st: "Done", act: 6, done: 3),
      (r: "OPS", t: "GitHub Actions: lint, typecheck, unit, pgTAP", s: 2, c: 2, h: 6, swp: 2, it: "S1", who: "Minh", st: "Done", act: 7, done: 5),
     )),
    (id: "I-1002", title: "Sao lưu, PITR và runbook khôi phục",
     spec: "NFR-BKP-01",
     desc: "Bật PITR, diễn tập khôi phục, ghi runbook.",
     ac: ("Diễn tập khôi phục đạt RTO 4 h",),
     tasks: (
      (r: "OPS", t: "Bật PITR + diễn tập khôi phục + runbook", s: 2, c: 2, h: 5, swp: 2, it: "S3", who: "Minh", st: "Todo"),
     )),
    (id: "I-1003", title: "Kiểm thử hiệu năng NFR-PERF-01/02",
     spec: "NFR-PERF-01 · NFR-PERF-02",
     desc: "Phân bổ một đơn ≤ 30 dòng / 500 lô mỗi SKU p95 < 2 s; kiểm tra tuyến ≤ 15 điểm dừng p95 < 3 s.",
     ac: ("Báo cáo p95 cho hai kịch bản",),
     tasks: (
      (r: "QA", t: "Kịch bản k6 cho phân bổ và kiểm tra tuyến", s: 2, c: 3, h: 8, swp: 3, it: "S4", who: "Hà", st: "Todo"),
     )),
    (id: "I-1004", title: "E2E hồi quy luồng chính",
     spec: "overview.md §3",
     desc: "Playwright: nhập → phân bổ → kiểm xuất → POD → cảnh báo đảo hạn.",
     ac: ("Chạy trên CI hằng đêm",),
     tasks: (
      (r: "QA", t: "Playwright luồng nhập → xuất → POD → đảo hạn", s: 4, c: 2, h: 12, swp: 5, it: "S4", who: "Hà", st: "Todo"),
     )),
    (id: "I-1005", title: "Giao diện JA/VI",
     spec: "NFR-LOC-01 · PM-12",
     desc: "Khung i18n, tách chuỗi của 18 màn; hiển thị JST.",
     ac: ("Đổi ngôn ngữ không cần tải lại", "Không còn chuỗi cứng"),
     tasks: (
      (r: "FE", t: "Khung i18n + tách chuỗi 18 màn", s: 4, c: 1, h: 10, swp: 3, it: "S4", who: "Chi", st: "Todo"),
     )),
   )),
)
