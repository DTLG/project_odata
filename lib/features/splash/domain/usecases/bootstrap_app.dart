import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/injection/injection_container.dart';
import '../../../nomenclature/ui/cubit/nomenclature_cubit.dart';
import '../../../nomenclature/ui/cubit/nomenclature_state.dart';
import '../../../kontragenty/presentation/cubit/kontragent_cubit.dart';
import '../../../customer_order/presentation/cubit/customer_order_cubit.dart';
import 'package:project_odata/objectbox.dart';
import '../../../../core/objectbox/objectbox_entities.dart';
import '../../../agents/data/datasources/local/objectbox_agents_datasource.dart';
import '../../../agents/data/datasources/remote/supabase_agents_datasource.dart';
import '../../../agents/data/repositories/agents_repository_impl.dart';
import '../../../repair_request/data/datasources/remote/supabase_types_of_repair_datasource.dart';

class BootstrapApp {
  Future<void> call(Function(String, int, int) updateProgress) async {
    const totalSteps = 100;
    int currentStep = 0;

    updateProgress('Перевірка локальних даних...', currentStep, totalSteps);

    final nomenCubit = sl<NomenclatureCubit>();
    final kontrCubit = sl<KontragentCubit>();
    final orderCubit = sl<CustomerOrderCubit>();

    currentStep += 10;
    updateProgress('Підготовка довідників...', currentStep, totalSteps);

    final store = sl<ObjectBox>().getStore();
    final agentBox = store.box<AgentObx>();
    final typesBox = store.box<TypeOfRepairObx>();
    final nomenBox = store.box<NomenclatureObx>();
    final kontrBox = store.box<KontragentObx>();

    // Перевіряємо що потрібно синхронізувати
    final needsNomenclature = nomenBox.count() == 0;
    final needsKontragenty = kontrBox.count() == 0;
    final needsAgents = agentBox.count() == 0;
    final needsTypes = typesBox.count() == 0;

    final syncSteps = [
      needsNomenclature,
      needsKontragenty,
      needsAgents,
      needsTypes,
    ].where((needs) => needs).length;

    final stepSize = syncSteps > 0 ? (70 / syncSteps).round() : 0;

    if (needsNomenclature) {
      updateProgress('Синхронізація номенклатури...', currentStep, totalSteps);

      // Підписуємося на прогрес синхронізації номенклатури
      final streamSubscription = nomenCubit.stream.listen((state) {
        if (state.status == NomenclatureStatus.loading &&
            state.total != null &&
            state.total! > 0 &&
            state.current != null &&
            state.message != null) {
          // Маштабуємо прогрес номенклатури до нашого загального прогресу
          final nomenclatureProgress =
              (state.current! / state.total! * stepSize).round();
          final totalProgress = currentStep + nomenclatureProgress;
          updateProgress(state.message!, totalProgress, totalSteps);
        }
      });

      await nomenCubit.syncNomenclature();
      await streamSubscription.cancel();

      currentStep += stepSize;
      updateProgress('Номенклатура синхронізована', currentStep, totalSteps);
    }

    if (needsKontragenty) {
      updateProgress('Синхронізація контрагентів...', currentStep, totalSteps);

      // Підписуємося на прогрес синхронізації контрагентів
      final streamSubscription = kontrCubit.stream.listen((state) {
        if (state is KontragentLoading) {
          // Для контрагентів поки що просто показуємо загальний прогрес
          final totalProgress = currentStep + (stepSize ~/ 2);
          updateProgress(
            'Синхронізація контрагентів...',
            totalProgress,
            totalSteps,
          );
        }
      });

      await kontrCubit.syncKontragenty();
      await streamSubscription.cancel();

      currentStep += stepSize;
      updateProgress('Контрагенти синхронізовані', currentStep, totalSteps);
    }

    if (needsAgents) {
      currentStep += stepSize;
      updateProgress('Синхронізація агентів...', currentStep, totalSteps);
      final repo = AgentsRepositoryImpl(
        local: ObjectBoxAgentsDatasourceImpl(),
        remote: SupabaseAgentsDatasourceImpl(Supabase.instance.client),
      );
      await repo.syncAgents();
    }

    if (needsTypes) {
      currentStep += stepSize;
      updateProgress('Синхронізація типів ремонту...', currentStep, totalSteps);
      final client = Supabase.instance.client;
      final remote = SupabaseTypesOfRepairDatasource(client);
      final list = await remote.fetchAll();
      typesBox.putMany(
        list
            .map(
              (t) => TypeOfRepairObx(
                guid: t.guid,
                name: t.name,
                createdAtMs: t.createdAt?.millisecondsSinceEpoch,
              ),
            )
            .toList(),
      );
    }

    currentStep = 90;
    updateProgress('Ініціалізація застосунку...', currentStep, totalSteps);
    orderCubit.initialize();

    currentStep = 100;
    updateProgress('Завершено!', currentStep, totalSteps);
  }
}
