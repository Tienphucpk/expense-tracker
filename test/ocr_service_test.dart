import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/data/repositories/services/OCRService.dart';

void main() {
  late ReceiptAIService service;

  setUp(() {
    service = ReceiptAIService();
  });

  group('ReceiptAIService OCR Rule-Based Parser Tests', () {
    test('Trích xuất hóa đơn Highlands Coffee', () {
      const receiptText = '''
HIGHLANDS COFFEE
Địa chỉ: 123 Nguyễn Huệ, Q.1, TP.HCM
SĐT: 028 1234 5678
Ngày: 24/05/2026 14:30
HÓA ĐƠN BÁN HÀNG
1. Phin Sữa Đá L    39.000
2. Trà Sen Vàng L   49.000
---------------------------
Tổng tiền:          88.000
Thanh toán:         88.000
Cảm ơn quý khách!
''';

      final result = service.parseReceiptText(receiptText);
      expect(result['merchantName'], contains('HIGHLANDS COFFEE'));
      expect(result['total'], equals(88000));
      expect(result['date'], equals(DateTime(2026, 5, 24)));
      expect(result['categoryId'], equals('1')); // Ăn uống
    });

    test('Trích xuất hóa đơn Siêu thị WinMart', () {
      const receiptText = '''
SIÊU THỊ WINMART+
Đ/C: Tòa nhà Green, Cầu Giấy, Hà Nội
Hotline: 1900 1234
Ngày: 15-08-2026
Thu ngân: NV01
1. Sữa tươi Vinamilk   32.000
2. Bánh mì sandwich    18.000
3. Nước khoáng Lavie   10.000
------------------------------
Tổng cộng:             60.000
Tiền mặt:             100.000
Tiền thừa:             40.000
''';

      final result = service.parseReceiptText(receiptText);
      expect(result['merchantName'], contains('SIÊU THỊ WINMART'));
      expect(result['total'], equals(60000));
      expect(result['date'], equals(DateTime(2026, 8, 15)));
      expect(result['categoryId'], equals('2')); // Siêu thị / Shopping
    });

    test('Trích xuất hóa đơn có định dạng tiếng Việt ngày tháng năm', () {
      const receiptText = '''
Nhà Sách Fahasa
Ngày 10 tháng 09 năm 2026
Sách Lập Trình Flutter    120.000
Vở kẻ ngang                15.000
---------------------------------
Tổng thanh toán:          135.000
''';

      final result = service.parseReceiptText(receiptText);
      expect(result['merchantName'], contains('Nhà Sách Fahasa'));
      expect(result['total'], equals(135000));
      expect(result['date'], equals(DateTime(2026, 9, 10)));
    });
  });
}
