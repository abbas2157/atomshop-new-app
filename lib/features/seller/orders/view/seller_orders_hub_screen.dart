import 'package:atompro/features/seller/custom_orders/view/seller_custom_orders_screen.dart';
import 'package:atompro/features/seller/standard_orders/view/seller_standard_orders_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

abstract final class _O {
  static const bg = Color(0xFFF4F6FC);
  static const surface = Color(0xFFFFFFFF);
  static const brand = Color(0xFF3B5BDB);
  static const text = Color(0xFF101828);
  static const muted = Color(0xFF667085);
  static const border = Color(0xFFE4E8F5);
}

class SellerOrdersHubScreen extends StatelessWidget {
  const SellerOrdersHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: _O.bg,
          appBar: AppBar(
            backgroundColor: _O.bg,
            surfaceTintColor: _O.bg,
            titleSpacing: 18,
            title: const Text(
              'Orders',
              style: TextStyle(
                color: _O.text,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(58),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
                child: Container(
                  height: 46,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: _O.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _O.border),
                  ),
                  child: TabBar(
                    indicator: BoxDecoration(
                      color: _O.brand,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelColor: Colors.white,
                    unselectedLabelColor: _O.muted,
                    labelStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                    tabs: const [
                      Tab(text: 'Custom'),
                      Tab(text: 'Standard'),
                    ],
                  ),
                ),
              ),
            ),
          ),
          body: const TabBarView(
            children: [
              SellerCustomOrdersScreen(),
              SellerStandardOrdersScreen(),
            ],
          ),
        ),
      ),
    );
  }
}
