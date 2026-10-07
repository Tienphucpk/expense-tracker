import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../HomePage/screens/AddWalletScreen.dart';

class ManageWalletsScreen extends StatefulWidget {
  final String userId;
  const ManageWalletsScreen({super.key, required this.userId});

  @override
  State<ManageWalletsScreen> createState() => _ManageWalletsScreenState();
}

class _ManageWalletsScreenState extends State<ManageWalletsScreen> {
  // ── iOS Minimalist Design Tokens ────────────────────────────────
  static const _bg = Color(0xFFF2F2F7);
  static const _card = Color(0xFFFFFFFF);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF8E8E93);
  static const _border = Color(0xFFE5E5EA);

  // ── Dữ liệu mẫu hiển thị ─────────────────────────────────────────
  final List<Map<String, dynamic>> _dummyWallets = [
    {
      'name': 'Ví Tiền Mặt',
      'balance': 5250000.0,
      'color': const Color(0xFF34C759),
      'isCash': true,
    },
    {
      'name': 'Thẻ MB Bank',
      'balance': 12800000.0,
      'color': const Color(0xFF007AFF),
      'isCash': false,
      'number': '8888'
    },
    {
      'name': 'Ví Momo',
      'balance': 450000.0,
      'color': const Color(0xFFAF52DE),
      'isCash': false,
      'number': '0901'
    },
  ];

  String _fmt(double amount) {
    return amount.toInt().toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.');
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          // 1. CHỨA DANH SÁCH
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(),
              _buildTotalAsset(),
              SliverToBoxAdapter(child: SizedBox(height: 20.h)),
              _buildWalletListHeader(),
              _buildWalletList(),
              SliverToBoxAdapter(child: SizedBox(height: 120.h)), // Chừa chỗ cho nút fixed
            ],
          ),

          // 2. NÚT ADD CỐ ĐỊNH (FIXED BUTTON)
          _buildAddButtonFixed(),
        ],
      ),
    );
  }

  // --- AppBar iOS Minimalist ---
  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: _bg,
      pinned: true,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded, color: _textPrimary, size: 18.sp),
        onPressed: () => Navigator.pop(context),
      ),
      centerTitle: true,
      title: Text('Ví Của Tôi',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700, color: _textPrimary, letterSpacing: -0.3)),
    );
  }

  // --- Tổng tài sản (iOS Minimalist Style) ---
  Widget _buildTotalAsset() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
        child: Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: _border, width: 1.w),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('TỔNG TÀI SẢN HIỆN CÓ',
                  style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600, color: _textSecondary, letterSpacing: 0.8)),
              SizedBox(height: 8.h),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('18.500.000',
                      style: TextStyle(fontSize: 30.sp, fontWeight: FontWeight.w800, color: _textPrimary, letterSpacing: -0.5)),
                  Padding(
                    padding: EdgeInsets.only(bottom: 4.h, left: 6.w),
                    child: Text('₫', style: TextStyle(fontSize: 20.sp, color: _textPrimary, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Header Danh sách ---
  Widget _buildWalletListHeader() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
        child: Row(
          children: [
            Text('DANH SÁCH CHI TIẾT',
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: _textSecondary, letterSpacing: 0.6)),
            const Spacer(),
            Icon(Icons.tune_rounded, color: _textPrimary, size: 18.sp),
          ],
        ),
      ),
    );
  }

  // --- Danh sách ví ---
  Widget _buildWalletList() {
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final wallet = _dummyWallets[index];
            return _buildWalletItem(wallet);
          },
          childCount: _dummyWallets.length,
        ),
      ),
    );
  }

  // --- Item Ví (Card Design) ---
  Widget _buildWalletItem(Map<String, dynamic> wallet) {
    final Color accent = wallet['color'];
    return Container(
      height: 92.h,
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: _border, width: 1.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon ví
          Container(
            width: 46.w,
            height: 46.w,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Icon(
              wallet['isCash'] ? Icons.payments_rounded : Icons.credit_card_rounded,
              color: accent,
              size: 22.sp,
            ),
          ),
          SizedBox(width: 14.w),

          // Thông tin ví
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(wallet['name'],
                    style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600, color: _textPrimary)),
                if (!wallet['isCash'])
                  Padding(
                    padding: EdgeInsets.only(top: 2.h),
                    child: Text('**** ${wallet['number']}',
                        style: TextStyle(fontSize: 12.sp, color: _textSecondary)),
                  ),
              ],
            ),
          ),

          // Số dư
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${_fmt(wallet['balance'])}',
                  style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700, color: _textPrimary)),
              Text('₫', style: TextStyle(fontSize: 11.sp, color: _textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  // --- Nút thêm ví (Floating Bottom) ---
  Widget _buildAddButtonFixed() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 32.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_bg.withOpacity(0), _bg.withOpacity(0.95), _bg],
          ),
        ),
        child: Container(
          height: 52.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 16, offset: const Offset(0, 4))
            ],
          ),
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddWalletScreen(userId: widget.userId),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF111827),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_circle_outline_rounded, size: 20.sp, color: Colors.white),
                SizedBox(width: 8.w),
                Text('THÊM VÍ MỚI',
                    style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: Colors.white)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}