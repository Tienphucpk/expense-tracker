import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as pkg_img;

class ReceiptAIService {
  final String _fallbackApiKey = "K88606641388957";
  final String _fallbackApiUrl = "https://api.ocr.space/parse/image";

  /// Quét hóa đơn: Ưu tiên dùng Google ML Kit On-Device (Offline không cần mạng).
  /// Nếu chạy trên nền tảng không hỗ trợ ML Kit (như Windows Desktop), tự động fallback.
  Future<Map<String, dynamic>?> scanReceipt(File imageFile) async {
    // 1. Thử nhận diện bằng Google ML Kit Text Recognition (On-Device / Offline)
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      await textRecognizer.close();

      final String fullText = recognizedText.text.trim();
      if (fullText.isNotEmpty) {
        debugPrint("--- [Google ML Kit OCR (Offline)] Trích xuất thành công ---\n$fullText");
        return _parseReceiptData(fullText);
      }
    } catch (e) {
      debugPrint("Google ML Kit không khả dụng hoặc lỗi: $e. Thử chế độ phụ trợ...");
    }

    // 2. Chế độ phụ trợ (Online Fallback khi test trên Windows desktop không hỗ trợ ML Kit)
    try {
      return await _scanViaFallbackApi(imageFile);
    } catch (e) {
      debugPrint("Lỗi fallback API: $e");
      return null;
    }
  }

  /// Phân tích dữ liệu văn bản hóa đơn trực tiếp (dùng cho test hoặc khi đã có text)
  Map<String, dynamic> parseReceiptText(String fullText) => _parseReceiptData(fullText);

  /// Phân tích dữ liệu hóa đơn dựa trên quy tắc (Regex + Heuristic):
  /// - Tổng số tiền (Total Amount)
  /// - Tên đơn vị bán hàng / Cửa hàng (Merchant Name)
  /// - Ngày giao dịch (Transaction Date)
  /// - Danh mục chi tiêu (Category ID)
  Map<String, dynamic> _parseReceiptData(String fullText) {
    final double total = _extractTotalAmount(fullText);
    final String merchantName = _extractMerchantName(fullText);
    final DateTime? parsedDate = _extractTransactionDate(fullText);
    final String categoryId = _guessCategoryId(fullText, merchantName);

    return {
      "total": total.toInt(),
      "merchantName": merchantName,
      "note": merchantName.isNotEmpty ? merchantName : "Hóa đơn mua sắm",
      "date": parsedDate ?? DateTime.now(),
      "categoryId": categoryId,
      "rawText": fullText,
    };
  }

  /// ─── 1. BỘ PHÂN TÍCH TỔNG TIỀN (REGEX + HEURISTIC) ───────────────────────
  double _extractTotalAmount(String text) {
    // Chuẩn hóa khoảng trắng số tiền: VD "150 000" -> "150000"
    String normalizedText = text.replaceAllMapped(
      RegExp(r'(\d)\s+(\d{3})'),
      (match) => '${match.group(1)}${match.group(2)}',
    );

    final lines = normalizedText.split('\n');
    final primaryKeywords = [
      'tổng cộng', 'tong cong', 'tổng tiền', 'tong tien',
      'tổng thanh toán', 'tong thanh toan', 'tổng phải trả',
      'thanh toán', 'thanh toan', 'thành tiền', 'thanh tien',
      'grand total', 'total', 'amount due'
    ];

    // Ưu tiên 1: Duyệt tìm từ khóa tổng tiền và bóc số ngay sau từ khóa trên dòng đó
    for (final line in lines) {
      final lineLower = line.toLowerCase();
      for (final kw in primaryKeywords) {
        if (lineLower.contains(kw)) {
          final afterKw = line.substring(lineLower.indexOf(kw) + kw.length);
          final amount = _findFirstAmountIn(afterKw);
          if (amount >= 1000) return amount;
        }
      }
    }

    // Heuristic 2: Từ khóa ở dòng hiện tại, số tiền nằm ở dòng ngay sau nó
    for (int i = 0; i < lines.length; i++) {
      final lineLower = lines[i].toLowerCase();
      for (final kw in primaryKeywords) {
        if (lineLower.contains(kw) && i + 1 < lines.length) {
          final nextAmount = _findFirstAmountIn(lines[i + 1]);
          if (nextAmount >= 1000) return nextAmount;
        }
      }
    }

    // Heuristic 3: Từ khóa phụ (tiền mặt / tiền thanh toán)
    for (final line in lines) {
      final lineLower = line.toLowerCase();
      if (lineLower.contains('tiền mặt') || lineLower.contains('tien mat')) {
        final amount = _findFirstAmountIn(line);
        if (amount >= 1000) return amount;
      }
    }

    // Heuristic 4: Quét toàn bộ văn bản tìm số tiền lớn nhất hợp lệ
    return _findLargestAmountIn(normalizedText);
  }

  double _findFirstAmountIn(String text) {
    final RegExp regExp = RegExp(r'(\d{1,3}(?:[\.,]\d{3})+)|(\b\d{4,}\b)');
    for (final match in regExp.allMatches(text)) {
      final raw = match.group(0)!;
      if (raw.startsWith('09') || raw.startsWith('08') || raw.startsWith('03') ||
          raw.startsWith('07') || raw.startsWith('05') || raw.startsWith('01')) {
        continue;
      }
      final clean = raw.replaceAll(RegExp(r'[\.,]'), '');
      final val = double.tryParse(clean);
      if (val != null && val >= 1000 && val < 50000000) {
        return val;
      }
    }
    return 0.0;
  }

  double _findLargestAmountIn(String text) {
    final RegExp regExp = RegExp(r'(\d{1,3}(?:[\.,]\d{3})+)|(\b\d{4,}\b)');
    double maxVal = 0;

    for (final match in regExp.allMatches(text)) {
      final raw = match.group(0)!;
      // Loại trừ số điện thoại phổ biến (09, 08, 03, 07, 05...)
      if (raw.startsWith('09') || raw.startsWith('08') || raw.startsWith('03') ||
          raw.startsWith('07') || raw.startsWith('05') || raw.startsWith('01')) {
        continue;
      }
      final clean = raw.replaceAll(RegExp(r'[\.,]'), '');
      final val = double.tryParse(clean);
      if (val != null && val > maxVal && val < 50000000) {
        maxVal = val;
      }
    }
    return maxVal;
  }

  /// ─── 2. BỘ PHÂN TÍCH TÊN ĐƠN VỊ BÁN HÀNG (HEURISTIC) ─────────────────────
  String _extractMerchantName(String text) {
    final lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    if (lines.isEmpty) return "Cửa hàng";

    // Danh sách từ khóa loại trừ (header thông tin, hóa đơn, địa chỉ...)
    final ignoreKeywords = [
      'hóa đơn', 'hoa don', 'phiếu thanh toán', 'phieu thanh toan',
      'phiếu thu', 'bien lai', 'receipt', 'bill', 'order',
      'địa chỉ', 'dia chi', 'address', 'tel:', 'sđt', 'phone', 'hotline',
      'mst', 'mã số thuế', 'thu ngân', 'cashier', 'ngày', 'ngay', 'date',
      'bàn', 'khách hàng', 'nhân viên', 'wifi'
    ];

    // Danh sách từ khóa báo hiệu cửa hàng / thương hiệu
    final brandKeywords = [
      'công ty', 'siêu thị', 'cửa hàng', 'nhà hàng', 'quán',
      'coffee', 'cafe', 'mart', 'restaurant', 'store', 'shop',
      'circle k', 'winmart', 'highlands', 'phúc long', 'co.op',
      'starbucks', 'lotteria', 'kfc', 'jollibee', 'fahasa', '7-eleven'
    ];

    // Ưu tiên 1: Quét 6 dòng đầu xem có tên thương hiệu rõ ràng
    final topLimit = lines.length < 6 ? lines.length : 6;
    for (int i = 0; i < topLimit; i++) {
      final line = lines[i];
      final lineLower = line.toLowerCase();

      // Kiểm tra có chứa từ khóa thương hiệu
      for (final bk in brandKeywords) {
        if (lineLower.contains(bk)) {
          return _cleanMerchantName(line);
        }
      }
    }

    // Ưu tiên 2: Lấy dòng đầu tiên hợp lệ không chứa từ khóa loại trừ
    for (int i = 0; i < topLimit; i++) {
      final line = lines[i];
      final lineLower = line.toLowerCase();

      bool isIgnore = false;
      for (final kw in ignoreKeywords) {
        if (lineLower.contains(kw)) {
          isIgnore = true;
          break;
        }
      }

      // Đạt điều kiện: độ dài vừa phải, chứa chữ cái, không phải toàn số
      if (!isIgnore && line.length >= 3 && line.length <= 60 && RegExp(r'[a-zA-ZÀ-ỹ]').hasMatch(line)) {
        return _cleanMerchantName(line);
      }
    }

    return lines.first;
  }

  String _cleanMerchantName(String raw) {
    return raw
        .replaceAll(RegExp(r'^[^\w\sÀ-ỹ]+|[^\w\sÀ-ỹ]+$'), '')
        .trim();
  }

  /// ─── 3. BỘ PHÂN TÍCH NGÀY GIAO DỊCH (REGEX + HEURISTIC) ──────────────────
  DateTime? _extractTransactionDate(String text) {
    // Pattern 1: dd/MM/yyyy hoặc dd-MM-yyyy hoặc dd.MM.yyyy
    final dmyRegex = RegExp(r'\b(0?[1-9]|[12]\d|3[01])[\/\.\-](0?[1-9]|1[0-2])[\/\.\-](20\d{2})\b');
    // Pattern 2: yyyy/MM/dd hoặc yyyy-MM-dd
    final ymdRegex = RegExp(r'\b(20\d{2})[\/\.\-](0?[1-9]|1[0-2])[\/\.\-](0?[1-9]|[12]\d|3[01])\b');
    // Pattern 3: dd/MM/yy
    final dmyShortRegex = RegExp(r'\b(0?[1-9]|[12]\d|3[01])[\/\.\-](0?[1-9]|1[0-2])[\/\.\-](\d{2})\b');
    // Pattern 4: ngày dd tháng MM năm yyyy
    final vnTextDateRegex = RegExp(r'ngày\s+(0?[1-9]|[12]\d|3[01])\s+tháng\s+(0?[1-9]|1[0-2])\s+năm\s+(20\d{2})', caseSensitive: false);

    // Ưu tiên tìm pattern văn bản tiếng Việt "ngày .. tháng .. năm .."
    final vnMatch = vnTextDateRegex.firstMatch(text);
    if (vnMatch != null) {
      final day = int.tryParse(vnMatch.group(1)!);
      final month = int.tryParse(vnMatch.group(2)!);
      final year = int.tryParse(vnMatch.group(3)!);
      if (day != null && month != null && year != null) {
        return DateTime(year, month, day);
      }
    }

    // Heuristic: Tìm dòng chứa từ khóa "ngày", "date", "thời gian" trước
    final lines = text.split('\n');
    for (final line in lines) {
      final lower = line.toLowerCase();
      if (lower.contains('ngày') || lower.contains('ngay') || lower.contains('date') || lower.contains('time')) {
        final dmy = dmyRegex.firstMatch(line);
        if (dmy != null) {
          final day = int.parse(dmy.group(1)!);
          final month = int.parse(dmy.group(2)!);
          final year = int.parse(dmy.group(3)!);
          return DateTime(year, month, day);
        }
      }
    }

    // Quét toàn bộ: dd/MM/yyyy
    final dmyMatch = dmyRegex.firstMatch(text);
    if (dmyMatch != null) {
      final day = int.parse(dmyMatch.group(1)!);
      final month = int.parse(dmyMatch.group(2)!);
      final year = int.parse(dmyMatch.group(3)!);
      return DateTime(year, month, day);
    }

    // Quét toàn bộ: yyyy-MM-dd
    final ymdMatch = ymdRegex.firstMatch(text);
    if (ymdMatch != null) {
      final year = int.parse(ymdMatch.group(1)!);
      final month = int.parse(ymdMatch.group(2)!);
      final day = int.parse(ymdMatch.group(3)!);
      return DateTime(year, month, day);
    }

    // Quét dạng ngắn dd/MM/yy
    final shortMatch = dmyShortRegex.firstMatch(text);
    if (shortMatch != null) {
      final day = int.parse(shortMatch.group(1)!);
      final month = int.parse(shortMatch.group(2)!);
      final year = 2000 + int.parse(shortMatch.group(3)!);
      return DateTime(year, month, day);
    }

    return null;
  }

  /// ─── 4. BỘ PHÂN LOẠI DANH MỤC (HEURISTIC) ───────────────────────────────
  String _guessCategoryId(String text, [String merchant = '']) {
    final mLower = merchant.toLowerCase();
    final tLower = text.toLowerCase();

    // Ưu tiên 1: Phân loại theo thương hiệu / tên cửa hàng
    if (mLower.contains('mart') || mLower.contains('siêu thị') ||
        mLower.contains('vinmart') || mLower.contains('winmart') ||
        mLower.contains('co.op') || mLower.contains('circle k') ||
        mLower.contains('bách hóa') || mLower.contains('store')) {
      return '2'; // Siêu thị / Shopping
    }

    if (mLower.contains('coffee') || mLower.contains('cafe') ||
        mLower.contains('highlands') || mLower.contains('phúc long') ||
        mLower.contains('starbucks') || mLower.contains('kfc') ||
        mLower.contains('lotteria') || mLower.contains('jollibee') ||
        mLower.contains('nhà hàng') || mLower.contains('quán cơm')) {
      return '1'; // Ăn uống
    }

    if (mLower.contains('petrolimex') || mLower.contains('grab') || mLower.contains('be ')) {
      return '3'; // Di chuyển
    }

    // Ưu tiên 2: Phân loại theo nội dung toàn bài
    final lower = '$tLower $mLower';

    // 1. Ăn uống (ID: 1)
    if (lower.contains('cơm') || lower.contains('nước') || lower.contains('food') ||
        lower.contains('cafe') || lower.contains('coffee') || lower.contains('nướng') ||
        lower.contains('lẩu') || lower.contains('trà sữa') || lower.contains('phở') ||
        lower.contains('bánh')) {
      return '1';
    }

    // 2. Shopping / Siêu thị (ID: 2)
    if (lower.contains('mart') || lower.contains('siêu thị') || lower.contains('vinmart') ||
        lower.contains('winmart') || lower.contains('co.op') || lower.contains('circle k') ||
        lower.contains('bách hóa') || lower.contains('tiện lợi') || lower.contains('mua sắm')) {
      return '2';
    }

    // 3. Di chuyển / Xăng xe (ID: 3)
    if (lower.contains('xăng') || lower.contains('grab') || lower.contains('be ') ||
        lower.contains('vận tải') || lower.contains('petrolimex') || lower.contains('xe bus') ||
        lower.contains('taxi')) {
      return '3';
    }

    // 4. Giải Trí (ID: 5)
    if (lower.contains('bia') || lower.contains('cinema') || lower.contains('phim') ||
        lower.contains('cgv') || lower.contains('lotte') || lower.contains('karaoke') ||
        lower.contains('game') || lower.contains('snack')) {
      return '5';
    }

    // 5. Điện tử / Công nghệ (ID: 20)
    if (lower.contains('điện thoại') || lower.contains('thẻ cào') || lower.contains('phụ kiện') ||
        lower.contains('laptop') || lower.contains('fpt') || lower.contains('thế giới di động')) {
      return '20';
    }

    // 6. Hóa đơn điện nước mạng (ID: 9)
    if (lower.contains('tiền điện') || lower.contains('tiền nước') || lower.contains('internet') ||
        lower.contains('viettel') || lower.contains('vnpt') || lower.contains('fpt telecom')) {
      return '9';
    }

    return '1';
  }

  /// Phụ trợ qua OCR Space API khi môi trường không có camera/ML Kit
  Future<Map<String, dynamic>?> _scanViaFallbackApi(File imageFile) async {
    final List<int> imageBytes = await imageFile.readAsBytes();
    final pkg_img.Image? decodedImage = pkg_img.decodeImage(Uint8List.fromList(imageBytes));
    if (decodedImage == null) return null;

    final pkg_img.Image resized = pkg_img.copyResize(decodedImage, width: 600);
    final List<int> compressedBytes = pkg_img.encodeJpg(resized, quality: 70);
    final String base64Image = "data:image/jpg;base64,${base64Encode(compressedBytes)}";

    final response = await http.post(
      Uri.parse(_fallbackApiUrl),
      headers: {"Content-Type": "application/x-www-form-urlencoded"},
      body: {
        "apikey": _fallbackApiKey,
        "base64image": base64Image,
        "language": "eng",
        "OCREngine": "2",
        "scale": "true",
      },
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      if (data['ParsedResults'] != null && data['ParsedResults'].isNotEmpty) {
        final String rawText = data['ParsedResults'][0]['ParsedText'] ?? "";
        return _parseReceiptData(rawText);
      }
    }
    return null;
  }
}