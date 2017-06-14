// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html' hide Screen;

import '../framework.dart';
import '../ui/element.dart';

class PerformanceScreen extends Screen {
  PerformanceScreen() : super('Performance', 'performance');

  @override
  void createContent(Element mainDiv) {
    // TODO:
    mainDiv.children.add(p('Performance todo:').element);
  }
}
