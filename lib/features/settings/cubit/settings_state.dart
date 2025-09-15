part of 'settings_cubit.dart';

enum SettingsStatus { initial, success, storagesSuccess, failure, loading }

extension SettingsStatusX on SettingsStatus {
  bool get isInitial => this == SettingsStatus.initial;
  bool get isLoading => this == SettingsStatus.loading;
  bool get isSuccess => this == SettingsStatus.success;
  bool get isFailure => this == SettingsStatus.failure;
  bool get isStoragesSuccess => this == SettingsStatus.storagesSuccess;
}

class SettingsState extends Equatable {
  final SettingsStatus status;

  final String printerHost;
  final String printerPort;
  final PriceType priceType;
  final List<PriceType> allPriceType;
  final String host;
  final String dbName;

  final String user;
  final String pass;
  final Storages storages;
  final Storage storage;
  final int darknees;
  final String agent;
  final String agentName;
  final String? errorMessage;

  SettingsState({
    this.status = SettingsStatus.initial,
    this.printerHost = '',
    this.printerPort = '',
    PriceType? priceType,
    this.allPriceType = const [],
    this.darknees = 1,
    Storages? storages,
    Storage? storage,
    this.user = '',
    this.dbName = '',
    this.pass = '',
    this.host = '',
    this.agent = '',
    this.agentName = '',
    this.errorMessage,
  }) : storages = storages ?? Storages.empty,
       storage = storage ?? Storage(name: '', storageId: ''),
       priceType = priceType ?? PriceType.empty;

  SettingsState copyWith({
    SettingsStatus? status,
    String? printerHost,
    String? printerPort,
    PriceType? priceType,
    List<PriceType>? allPriceType,
    Storages? storages,
    Storage? storage,
    String? user,
    int? darknees,
    String? pass,
    String? host,
    String? dbName,
    String? agent,
    String? agentName,
    String? errorMessage,
  }) {
    return SettingsState(
      status: status ?? this.status,
      printerHost: printerHost ?? this.printerHost,
      printerPort: printerPort ?? this.printerPort,
      priceType: priceType ?? this.priceType,
      allPriceType: allPriceType ?? this.allPriceType,
      storages: storages ?? this.storages,
      storage: storage ?? this.storage,
      host: host ?? this.host,
      user: user ?? this.user,
      pass: pass ?? this.pass,
      darknees: darknees ?? this.darknees,
      dbName: dbName ?? this.dbName,
      agent: agent ?? this.agent,
      agentName: agentName ?? this.agentName,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    printerHost,
    printerPort,
    priceType,
    allPriceType,
    host,
    dbName,
    pass,
    user,
    storages,
    storage,
    darknees,
    agent,
    agentName,
    errorMessage,
  ];
}
