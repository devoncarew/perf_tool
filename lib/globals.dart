// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'service.dart';

final Map globals = {};

ServiceConnectionManager get serviceInfo => globals[ServiceConnectionManager];

void setGlobal(dynamic clazz, dynamic instance) {
  globals[clazz] = instance;
}
