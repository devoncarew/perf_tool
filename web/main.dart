// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:perf_tool/main.dart';

// TODO: Do we care about the individual isolates?
//       - for the timeline view, show info for all isolates
//       - for the memory view, be able to select between isolates?
//       - for the perf view, be able to select between isolates?

void main() {
  PerfToolFramework framework = new PerfToolFramework();
  framework.performInitialLoad();
}
