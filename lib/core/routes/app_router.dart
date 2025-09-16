import 'package:flutter/material.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/labels/presentation/pages/lable_print_page.dart';
import '../../features/inventory/presentation/pages/inventory_documents_page.dart';
import '../../features/inventory/presentation/pages/inventory_data_page.dart';
import '../../features/orders/presentation/pages/orders_page.dart';
import '../../features/settings/ui/settings_page.dart';
import '../../features/nomenclature/ui/nomenclature_page.dart';
import '../../features/kontragenty/presentation/pages/kontragent_page.dart';
import '../../features/customer_order/presentation/pages/customer_order_page.dart';
import '../../features/customer_order/presentation/pages/customer_orders_list_page.dart';
import '../../features/splash/presentation/splash_page.dart';
import '../../features/agents/data/datasources/local/sqlite_agents_datasource.dart';
import '../../features/agents/data/datasources/remote/supabase_agents_datasource.dart';
import '../../features/agents/data/repositories/agents_repository_impl.dart';
import '../../features/agents/presentation/pages/agent_selection_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppRouter {
  static const String splash = '/';
  static const String home = '/home';
  static const String lablePrint = '/labels-print';
  static const String inventory = '/inventory';
  static const String inventoryData = '/inventory-data';
  static const String orders = '/orders';
  static const String inventoryCheck = '/inventory-check';
  static const String settingsPage = '/settings';
  static const String nomenclature = '/nomenclature';
  static const String kontragentPage = '/kontragent';
  static const String customerOrder = '/customer-order';
  static const String customerOrderLocal = '/customer-order-local';
  static const String customerOrderLocalList = '/customer-order-local-list';
  static const String customerOrdersList = '/customer-orders';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    final routeName = settings.name;

    if (routeName == splash) {
      return MaterialPageRoute(builder: (_) => const SplashPage());
    } else if (routeName == home) {
      return MaterialPageRoute(builder: (_) => const HomePage());
    } else if (routeName == lablePrint) {
      return MaterialPageRoute(builder: (_) => const LablePrintPage());
    } else if (routeName == inventory) {
      return MaterialPageRoute(builder: (_) => const InventoryDocumentsPage());
    } else if (routeName == inventoryData) {
      final args = settings.arguments as Map<String, dynamic>?;
      final document = args?['document'];
      if (document != null) {
        return MaterialPageRoute(
          builder: (_) => InventoryDataPage(document: document),
        );
      }
      return MaterialPageRoute(
        builder: (_) =>
            const Scaffold(body: Center(child: Text('Документ не знайдено'))),
      );
    } else if (routeName == orders) {
      return MaterialPageRoute(builder: (_) => const OrdersPage());
    } else if (routeName == inventoryCheck) {
      return MaterialPageRoute(builder: (_) => const InventoryDocumentsPage());
    } else if (routeName == settingsPage) {
      return MaterialPageRoute(builder: (_) => const SettingsPage());
    } else if (routeName == nomenclature) {
      return MaterialPageRoute(builder: (_) => const NomenclaturePage());
    } else if (routeName == kontragentPage) {
      return MaterialPageRoute(builder: (_) => const KontragentPage());
    } else if (routeName == customerOrder) {
      return MaterialPageRoute(builder: (_) => const CustomerOrderPage());
    } else if (routeName == customerOrdersList) {
      return MaterialPageRoute(builder: (_) => const CustomerOrdersListPage());
    } else if (routeName == customerOrderLocal) {
      return MaterialPageRoute(builder: (_) => const CustomerOrderPage());
    } else if (routeName == customerOrderLocalList) {
      return MaterialPageRoute(builder: (_) => const CustomerOrdersListPage());
    } else if (routeName == 'agentSelection') {
      final client = Supabase.instance.client;
      final repo = AgentsRepositoryImpl(
        local: SqliteAgentsDatasourceImpl(),
        remote: SupabaseAgentsDatasourceImpl(client),
      );
      return MaterialPageRoute(
        builder: (_) => AgentSelectionPage(repository: repo),
      );
    } else {
      return MaterialPageRoute(
        builder: (_) => Scaffold(
          body: Center(child: Text('Сторінка $routeName не знайдена')),
        ),
      );
    }
  }

  static void navigateTo(BuildContext context, String routeName) async {
    await Navigator.pushNamed(context, routeName);
  }

  static void navigateToAndReplace(BuildContext context, String routeName) {
    Navigator.pushReplacementNamed(context, routeName);
  }

  static void goBack(BuildContext context) {
    Navigator.pop(context);
  }
}
