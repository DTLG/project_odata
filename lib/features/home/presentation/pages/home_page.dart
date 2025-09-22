import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/theme_service.dart';
import '../../../../core/routes/app_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../settings/cubit/settings_cubit.dart';
import '../widgets/feature_card.dart';
import '../../../repair_request/presentation/pages/repair_requests_list_page.dart';
import '../../../settings/ui/settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isDarkMode = false;
  late ThemeService _themeService;

  @override
  void initState() {
    super.initState();
    _themeService = ThemeService();
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final isDarkMode = await _themeService.getThemeMode();
    setState(() {
      _isDarkMode = isDarkMode;
    });
  }

  Future<void> _toggleTheme() async {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
    await _themeService.saveThemeMode(_isDarkMode);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SettingsCubit()..loadHomeIcons(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: _isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme,
        onGenerateRoute: AppRouter.generateRoute,
        home: Scaffold(
          body: CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                expandedHeight: 120,
                floating: false,
                pinned: true,
                backgroundColor: Theme.of(context).colorScheme.primary,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    'Virok Service',
                    // 'Project OData',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.primaryColor,
                          AppTheme.primaryDarkColor,
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  BlocBuilder<SettingsCubit, SettingsState>(
                    builder: (context, state) {
                      return IconButton(
                        icon: const Icon(Icons.settings),
                        onPressed: () async {
                          final ok = await _askSettingsPin(context);
                          if (!ok) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SettingsPage(),
                            ),
                          ).then((value) {
                            context.read<SettingsCubit>().loadHomeIcons();
                          });
                        },
                        tooltip: 'Налаштування',
                      );
                    },
                  ),
                  // IconButton(
                  //   icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
                  //   onPressed: _toggleTheme,
                  //   tooltip: 'Змінити тему',
                  // ),
                ],
              ),

              // Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BlocBuilder<SettingsCubit, SettingsState>(
                        builder: (context, s) {
                          final cards = <Widget>[
                            if (s.showLabelPrint)
                              FeatureCard(
                                icon: Icons.local_offer,
                                title: 'Друк етикеток',
                                subtitle: 'Створення та друк етикеток',
                                color: AppTheme.primaryColor,
                                onTap: () {
                                  AppRouter.navigateTo(
                                    context,
                                    AppRouter.lablePrint,
                                  );
                                },
                              ),
                            if (s.showNomenclature)
                              FeatureCard(
                                icon: Icons.inventory,
                                title: 'Перевірка номенклатури',
                                subtitle: 'Контроль цін',
                                color: AppTheme.secondaryColor,
                                onTap: () {
                                  AppRouter.navigateTo(
                                    context,
                                    AppRouter.nomenclature,
                                  );
                                },
                              ),
                            if (s.showCustomerOrders)
                              FeatureCard(
                                icon: Icons.shopping_cart,
                                title: 'Замовлення клієнта',
                                subtitle: 'Управління замовленнями',
                                color: AppTheme.accentColor,
                                onTap: () {
                                  AppRouter.navigateTo(
                                    context,
                                    AppRouter.customerOrderLocalList,
                                  );
                                },
                              ),
                            if (s.showInventoryCheck)
                              FeatureCard(
                                icon: Icons.assessment,
                                title: 'Інвентаризація',
                                subtitle: 'Проведення перевірок',
                                color: Colors.orange,
                                onTap: () {
                                  AppRouter.navigateTo(
                                    context,
                                    AppRouter.inventoryCheck,
                                  );
                                },
                              ),
                            if (s.showKontragenty)
                              FeatureCard(
                                icon: Icons.people,
                                title: 'Контрагенти',
                                subtitle: 'Управління контрагентами',
                                color: Colors.cyan,
                                onTap: () {
                                  AppRouter.navigateTo(
                                    context,
                                    AppRouter.kontragentPage,
                                  );
                                },
                              ),
                            if (s.showRepairRequests)
                              FeatureCard(
                                icon: Icons.build_circle,
                                title: 'Заявка на ремонт',
                                subtitle: 'Ремонт з вибором товару',
                                color: Colors.teal,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const RepairRequestsListPage(),
                                    ),
                                  );
                                },
                              ),
                          ];
                          return GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.85,
                            children: cards,
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _askSettingsPin(BuildContext context) async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Введіть PIN'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'PIN'),
          keyboardType: TextInputType.number,
          obscureText: true,
          autofocus: true,
          maxLength: 4,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Скасувати'),
          ),
          TextButton(
            onPressed: () {
              final isOk = controller.text.trim() == '2025';
              if (isOk) {
                Navigator.of(ctx).pop(true);
              } else {
                Navigator.of(ctx).pop(false);
                // Show error and keep dialog open
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Неправильний PIN')),
                );
              }
            },
            child: const Text('Підтвердити'),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: AppTheme.primaryColor),
            const SizedBox(height: 12),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
