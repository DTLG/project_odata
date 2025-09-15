import 'package:flutter/material.dart';
import '../../../../core/injection/injection_container.dart';
import '../../../../features/nomenclature/cubit/nomenclature_cubit.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../features/nomenclature/cubit/nomenclature_state.dart';
import '../../../../features/kontragenty/presentation/cubit/kontragent_cubit.dart';
import '../../../../common/shared_preferiences/sp_func.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../features/agents/data/datasources/local/sqlite_agents_datasource.dart';
import '../../../../features/agents/data/datasources/remote/supabase_agents_datasource.dart';
import '../../../../features/agents/data/repositories/agents_repository_impl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../features/repair_request/data/datasources/local/sqlite_types_of_repair_datasource.dart';
import '../../../../features/repair_request/data/datasources/remote/supabase_types_of_repair_datasource.dart';
import '../../../../features/repair_request/data/repositories/types_of_repair_repository.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  String _message = 'Підготовка...';

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      setState(() => _message = 'Перевірка локальних даних...');

      // Ensure schema is selected
      String schema = await getSchema();
      if (schema.isEmpty) {
        if (!mounted) return;
        schema = await _askSchema(context) ?? '';
        if (schema.isEmpty) {
          // stay or proceed with info, but better to stop here
          setState(() => _message = 'Не вказано схему бази даних');
          await Future.delayed(const Duration(seconds: 2));
          if (!mounted) return;
          AppRouter.navigateToAndReplace(context, AppRouter.home);
          return;
        }
        await setSchema(schema);
      }

      // Use existing cubits/usecases via DI
      final nomenCubit = sl<NomenclatureCubit>();
      final kontrCubit = sl<KontragentCubit>();

      // Check local counts (reuse existing methods)
      await nomenCubit.loadRootTree();
      await kontrCubit.loadLocalKontragenty();

      // If empty -> sync from supabase
      bool needNomenSync = false;
      if (nomenCubit.state is NomenclatureTreeLoaded) {
        final s = nomenCubit.state as NomenclatureTreeLoaded;
        needNomenSync = s.totalCount == 0;
      }

      bool needKontrSync = false;
      if (kontrCubit.state is KontragentLoaded) {
        final k = kontrCubit.state as KontragentLoaded;
        needKontrSync = k.kontragenty.isEmpty;
      }
      // Check agents count directly from local DB
      final agentsLocal = SqliteAgentsDatasourceImpl();
      final agentsCount = await agentsLocal.getAgentsCount();
      final bool needAgentsSync = agentsCount == 0;

      if (needNomenSync) {
        setState(() => _message = 'Синхронізація номенклатури...');
        await nomenCubit.syncNomenclature();
      }

      if (needKontrSync) {
        setState(() => _message = 'Синхронізація контрагентів...');
        await kontrCubit.syncKontragenty();
      }
      if (needAgentsSync) {
        setState(() => _message = 'Синхронізація агентів...');
        final client = Supabase.instance.client;
        final agentsRepo = AgentsRepositoryImpl(
          local: agentsLocal,
          remote: SupabaseAgentsDatasourceImpl(client),
        );
        await agentsRepo.syncAgents();
      }

      // Sync types_of_repair if empty
      final typesLocal = SqliteTypesOfRepairDatasource();
      final typesCount = await typesLocal.getCount();
      if (typesCount == 0) {
        setState(() => _message = 'Синхронізація типів ремонту...');
        final client = Supabase.instance.client;
        final typesRepo = TypesOfRepairRepository(
          local: typesLocal,
          remote: SupabaseTypesOfRepairDatasource(client),
        );
        await typesRepo.sync();
      }

      if (!mounted) return;

      // Ensure an agent is selected; if not, open selection screen first
      final prefs = await SharedPreferences.getInstance();
      final selectedAgentGuid = prefs.getString('agent_guid') ?? '';
      if (selectedAgentGuid.isEmpty) {
        setState(() => _message = 'Оберіть агента...');
        await Navigator.of(context).pushNamed('agentSelection');
      }

      if (!mounted) return;
      AppRouter.navigateToAndReplace(context, AppRouter.home);
    } catch (e) {
      if (!mounted) return;
      setState(() => _message = 'Помилка під час підготовки: $e');
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      AppRouter.navigateToAndReplace(context, AppRouter.home);
    }
  }

  Future<String?> _askSchema(BuildContext context) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Схема бази даних'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Введіть назву схеми (наприклад, kup)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Скасувати'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Продовжити'),
          ),
        ],
      ),
    );
    // Do not dispose here to avoid race with dialog teardown
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 72,
              height: 72,
              child: CircularProgressIndicator(),
            ),
            const SizedBox(height: 16),
            Text(_message),
          ],
        ),
      ),
    );
  }
}
