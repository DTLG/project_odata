import 'package:equatable/equatable.dart';

class DbConn extends Equatable {
  final String host;
  final String dbName;
  final String user;
  final String pass;

  const DbConn(
      {required this.host,
      required this.dbName,
      required this.user,
      required this.pass});

  static const empty = DbConn(host: '', dbName: '', user: '', pass: '');

  @override
  List<Object?> get props => [host, dbName, user, pass];
}
