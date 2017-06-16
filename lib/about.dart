// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'framework.dart';
import 'ui/elements.dart';

class AboutScreen extends Screen {
  AboutScreen() : super('About', 'about');

  @override
  void createContent(CoreElement mainDiv) {
    mainDiv.add(p(text: 'About Observatory todo:'));
  }
}
