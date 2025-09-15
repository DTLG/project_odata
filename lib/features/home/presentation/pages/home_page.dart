import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/theme_service.dart';
import '../../../../core/routes/app_router.dart';
import '../widgets/feature_card.dart';
import '../../../repair_request/presentation/pages/repair_requests_list_page.dart';

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
    return MaterialApp(
      theme: _isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme,
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
                  'Project OData',
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
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () {
                    AppRouter.navigateTo(context, AppRouter.settingsPage);
                  },
                  tooltip: 'Налаштування',
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
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.85,
                      children: [
                        FeatureCard(
                          icon: Icons.local_offer,
                          title: 'Друк етикеток',
                          subtitle: 'Створення та друк етикеток',
                          color: AppTheme.primaryColor,
                          onTap: () {
                            AppRouter.navigateTo(context, AppRouter.lablePrint);
                            // TODO: Навігація до друку етикеток
                            // ScaffoldMessenger.of(context).showSnackBar(
                            //   const SnackBar(
                            //     content: Text('Друк етикеток - в розробці'),
                            //   ),
                            // );
                          },
                        ),
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
                        FeatureCard(
                          icon: Icons.assessment,
                          title: 'Інвентаризація',
                          subtitle: 'Проведення перевірок',
                          color: Colors.orange,
                          onTap: () {
                            // TODO: Навігація до інвентаризації
                            AppRouter.navigateTo(
                              context,
                              AppRouter.inventoryCheck,
                            );
                          },
                        ),
                        FeatureCard(
                          icon: Icons.people,
                          title: 'Контрагенти',
                          subtitle: 'Управління контрагентами',
                          color: Colors.cyan,
                          onTap: () {
                            // TODO: Навігація до контрагентів
                            AppRouter.navigateTo(
                              context,
                              AppRouter.kontragentPage,
                            );
                          },
                        ),
                        FeatureCard(
                          icon: Icons.build_circle,
                          title: 'Заявка на ремонт',
                          subtitle: 'Ремонт з вибором товару',
                          color: Colors.teal,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const RepairRequestsListPage(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),

                    // // Theme Switcher
                    // ThemeSwitcher(
                    //   isDarkMode: _isDarkMode,
                    //   onThemeChanged: _toggleTheme,
                    // ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
