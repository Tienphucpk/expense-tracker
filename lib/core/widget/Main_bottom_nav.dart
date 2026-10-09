import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../data/model/UserModel.dart';
import '../../features/page/AIPage/AIPage.dart';
import '../../features/page/AnalyticsPage/AnalyticsPage.dart';
import '../../features/page/HomePage/HomePage.dart';
import '../../features/page/HomePage/bloc/transaction_bloc/transaction_bloc.dart';
import '../../features/page/HomePage/bloc/transaction_bloc/transaction_event.dart';
import '../../features/page/HomePage/bloc/wallet_bloc/wallet_bloc.dart';
import '../../features/page/HomePage/bloc/wallet_bloc/wallet_event.dart';
import '../../features/page/SettingsPage/SettingsPage.dart';
import '../../features/page/add_transaction/AddPage.dart';
import '../../features/page/add_transaction/models/sample_data.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;
  final UserModel user;

  const MainNavigationScreen({super.key,required this.user,  this.initialIndex = 0});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  List<Widget> _pages = [];
  late WalletBloc _walletBloc;
  late TransactionBloc _transactionBloc;

  // ── Design tokens (khớp Login / Register) ─────────────────────
  static const _bg      = Color(0xFFF2F2F7);
  static const _surface = Color(0xFFFFFFFF);
  static const _gold    = Color(0xFF111827);
  static const _border  = Color(0xFFE5E5EA);

  // ── Nav items ──────────────────────────────────────────────────
  static const _navItems = [
    _NavMeta(
      activeIcon: Icons.home_rounded,
      inactiveIcon: Icons.home_outlined,
      label: 'Trang chủ',
    ),
    _NavMeta(
      activeIcon: Icons.bar_chart_rounded,
      inactiveIcon: Icons.bar_chart_outlined,
      label: 'Thống kê',
    ),
    _NavMeta(
      activeIcon: Icons.add_rounded,
      inactiveIcon: Icons.add_rounded,
      label: 'Thêm',
    ),
    _NavMeta(
      activeIcon: Icons.auto_awesome_rounded,
      inactiveIcon: Icons.auto_awesome_outlined,
      label: 'AI',
    ),
    _NavMeta(
      activeIcon: Icons.settings_rounded,
      inactiveIcon: Icons.settings_outlined,
      label: 'Cài đặt',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _walletBloc = WalletBloc()..add(LoadWallets(widget.user.id));
    _transactionBloc = TransactionBloc()..add(LoadRecentTransactions(widget.user.id));
    _loadPages();
  }

  void _loadPages() {
    setState(() {
      _pages = [
        MultiBlocProvider(
          providers: [
            BlocProvider.value(value: _walletBloc),
            BlocProvider.value(value: _transactionBloc),
          ],
          child: HomePage(
            user: widget.user,
            categories: SampleData.categories,
          ),
        ),
        BlocProvider.value(
          value: _transactionBloc,
          child: AnalyticsPage(
            categories: SampleData.categories,
          ),
        ),
        MultiBlocProvider(
          providers: [
            BlocProvider.value(value: _walletBloc),
            BlocProvider.value(value: _transactionBloc),
          ],
          child: AddPage(
            userId: widget.user.id,
            categories: SampleData.categories,
          ),
        ),
        MultiBlocProvider(providers: [
          BlocProvider.value(value: _walletBloc),
          BlocProvider.value(value: _transactionBloc),
        ], child: AIPage(user: widget.user,),),
        MultiBlocProvider(providers: [
          BlocProvider.value(value: _walletBloc),
          BlocProvider.value(value: _transactionBloc),
        ], child: SettingsPage(user: widget.user,),),
      ];
    });
  }
  @override
  void dispose() {
    _walletBloc.close();
    _transactionBloc.close();
    super.dispose();
  }

  void _onTap(int index) {
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    if (_pages.isEmpty) {
      return const Scaffold(
        backgroundColor: _bg,
        body: Center(
          child: CircularProgressIndicator(color: _gold),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _bg,
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── Bottom nav bar ─────────────────────────────────────────────
  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        border: Border(
          top: BorderSide(color: _border, width: 1.h),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64.h,
          child: Row(
            children: List.generate(
              _navItems.length,
                  (i) => Expanded(child: _NavItem(
                meta: _navItems[i],
                isSelected: _selectedIndex == i,
                onTap: () => _onTap(i),
                // Tab "Thêm" (index 2) có kiểu đặc biệt
                isSpecial: i == 2,
              )),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Single nav item ────────────────────────────────────────────────
class _NavItem extends StatelessWidget {
  final _NavMeta meta;
  final bool isSelected;
  final bool isSpecial;
  final VoidCallback onTap;

  static const _inactive = Color(0xFF8E8E93);

  const _NavItem({
    required this.meta,
    required this.isSelected,
    required this.onTap,
    this.isSpecial = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isSpecial) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              width: 44.w,
              height: 44.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF111827),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  meta.activeIcon,
                  size: 24.sp,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Tab thường
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon với subtle pill background khi active
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFE5E5EA) : Colors.transparent,
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: AnimatedScale(
              scale: isSelected ? 1.05 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isSelected ? meta.activeIcon : meta.inactiveIcon,
                size: 22.sp,
                color: isSelected ? const Color(0xFF111827) : _inactive,
              ),
            ),
          ),
          SizedBox(height: 3.h),
          // Label
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? const Color(0xFF111827) : _inactive,
              letterSpacing: -0.2,
            ),
            child: Text(meta.label),
          ),
        ],
      ),
    );
  }
}

// ── Data model ─────────────────────────────────────────────────────
class _NavMeta {
  final IconData activeIcon;
  final IconData inactiveIcon;
  final String label;
  const _NavMeta({
    required this.activeIcon,
    required this.inactiveIcon,
    required this.label,
  });
}