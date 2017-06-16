import 'service.dart';

final Map globals = {};

ServiceInfo get serviceInfo => globals[ServiceInfo];

void setGlobal(dynamic clazz, dynamic instance) {
  globals[clazz] = instance;
}
