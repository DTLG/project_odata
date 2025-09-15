import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../kontragenty/data/models/kontragent_model.dart';

part 'repair_request_state.dart';

class RepairRequestCubit extends Cubit<RepairRequestState> {
  RepairRequestCubit() : super(const RepairRequestState());

  void initialize({
    KontragentModel? customer,
    String? nomenclatureGuid,
    String? repairType,
    String? status,
    String? description,
    double? price,
    List<dynamic>? zapchastyny,
    List<dynamic>? diagnostyka,
    List<dynamic>? roboty,
  }) {
    emit(
      state.copyWith(
        customer: customer,
        nomenclatureGuid: nomenclatureGuid,
        repairType: repairType,
        status: status,
        description: description,
        price: price,
        zapchastyny: zapchastyny,
        diagnostyka: diagnostyka,
        roboty: roboty,
      ),
    );
  }

  void setCustomer(KontragentModel customer) =>
      emit(state.copyWith(customer: customer));
  void setNomenclatureGuid(String guid) =>
      emit(state.copyWith(nomenclatureGuid: guid));
  void setRepairType(String v) => emit(state.copyWith(repairType: v));
  void setStatus(String v) => emit(state.copyWith(status: v));
  void setDescription(String v) => emit(state.copyWith(description: v));
  void setPriceFromText(String v) {
    final parsed = double.tryParse(v.trim()) ?? 0.0;
    emit(state.copyWith(price: parsed));
  }

  void setZapchastyny(List<dynamic> items) =>
      emit(state.copyWith(zapchastyny: List<dynamic>.from(items)));
  void setDiagnostyka(List<dynamic> items) =>
      emit(state.copyWith(diagnostyka: List<dynamic>.from(items)));
  void setRoboty(List<dynamic> items) =>
      emit(state.copyWith(roboty: List<dynamic>.from(items)));
}
