// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../framework/framework.dart';
import '../ui/elements.dart';

class TimelineScreen extends Screen {
  TimelineScreen() : super('Timeline', 'timeline');

  @override
  void createContent(CoreElement mainDiv) {
    mainDiv.add(p(text: 'Timeline todo:'));
  }

  HelpInfo get helpInfo =>
      new HelpInfo('timeline view docs and tips', 'http://www.cheese.com');
}
