import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/price_type.dart';
import '../models/storage_model.dart';
import '../settings_client.dart';
import '../../../common/shared_preferiences/sp_func.dart';

part 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit() : super(SettingsState());

  Future<void> getApiData() async {
    try {
      final conn = await getdbConn();

      emit(
        state.copyWith(
          status: SettingsStatus.success,
          host: conn.host,
          pass: conn.pass,
          user: conn.user,
          dbName: conn.dbName,
          errorMessage: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: SettingsStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> gethost() async {
    final prefs = await SharedPreferences.getInstance();

    final host = prefs.getString('host') ?? '';
    emit(
      state.copyWith(
        status: SettingsStatus.success,
        host: host,
        errorMessage: null,
      ),
    );
  }

  Future<void> getDbName() async {
    final prefs = await SharedPreferences.getInstance();

    final dbName = prefs.getString('db_name') ?? '';
    emit(
      state.copyWith(
        status: SettingsStatus.success,
        dbName: dbName,
        errorMessage: null,
      ),
    );
  }

  Future<void> getUser() async {
    final prefs = await SharedPreferences.getInstance();

    final user = prefs.getString('user') ?? '';
    emit(
      state.copyWith(
        status: SettingsStatus.success,
        user: user,
        errorMessage: null,
      ),
    );
  }

  Future<void> getPass() async {
    final prefs = await SharedPreferences.getInstance();

    final pass = prefs.getString('pass') ?? '';
    emit(
      state.copyWith(
        status: SettingsStatus.success,
        pass: pass,
        errorMessage: null,
      ),
    );
  }

  Future<void> writeSp(String key, value) async {
    final prefs = await SharedPreferences.getInstance();
    switch (value.runtimeType) {
      case String:
        await prefs.setString(key, value);
      case int:
        await prefs.setInt(key, value);
    }
  }

  Future<void> getPrinterData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final printerHost = prefs.getString('printer_host') ?? '';
      final printerPort = prefs.getString('printer_port') ?? '9100';
      final darknees = await getPrinterDarkness();

      emit(
        state.copyWith(
          status: SettingsStatus.success,
          printerHost: printerHost,
          printerPort: printerPort,
          darknees: darknees,
          errorMessage: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: SettingsStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> getStorageList() async {
    try {
      emit(state.copyWith(status: SettingsStatus.loading));
      final storageList = await SettingsClient().getListStorage();
      emit(
        state.copyWith(
          storages: storageList,
          status: SettingsStatus.success,
          errorMessage: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: SettingsStatus.failure,
          storages: Storages.empty,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> writeStorageSettings(Storage storage) async {
    final prefs = await SharedPreferences.getInstance();

    prefs.setString(
      'storageId',
      storage.storageId ?? 'f941e56d-6cac-11ec-82da-fac6f165ea18',
    );
    prefs.setString('storageName', storage.name ?? 'Львів');
  }

  Future<void> getStorage() async {
    final prefs = await SharedPreferences.getInstance();

    final id = prefs.getString('storageId') ?? '';
    final name = prefs.getString('storageName') ?? '';
    emit(
      state.copyWith(
        status: SettingsStatus.success,
        storage: Storage(storageId: id, name: name),
        errorMessage: null,
      ),
    );
  }

  Future<int> getPrinterDarkness() async {
    final darknees = await getPrinterDarknessIndex();
    emit(state.copyWith(darknees: darknees, errorMessage: null));
    return darknees;
  }

  void getPiceType() async {
    try {
      emit(state.copyWith(status: SettingsStatus.loading));
      final prefsFuture = SharedPreferences.getInstance();
      final priceTypesFuture = SettingsClient().getPiceType();

      final prefs = await prefsFuture;
      final priceTypes = await priceTypesFuture;

      final currentPriceType = prefs.getString('priceTypeKey');

      final priceType = priceTypes.firstWhere(
        (element) => element.id == currentPriceType,
        orElse: () => PriceType.empty,
      );

      emit(
        state.copyWith(
          allPriceType: priceTypes,
          priceType: priceType,
          status: SettingsStatus.storagesSuccess,
          errorMessage: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: SettingsStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  void selectPriceType(PriceType priceType) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('priceTypeKey', priceType.id);
    emit(state.copyWith(priceType: priceType, errorMessage: null));
  }

  void clearError() {
    emit(state.copyWith(errorMessage: null, status: SettingsStatus.success));
  }
}
