// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:perf_tool/main.dart';

// TODO: Do we care about the individual isolates?
//       - for the timeline view, show info for all isolates
//       - for the memory view, be able to select between isolates?
//       - for the perf view, be able to select between isolates?

// localhost:9222/?port=234234

// localhost:9222/ - landing page; brief info about the VM and the three available pages
// localhost:9222/timeline
// localhost:9222/memory - redirect to the best isolate
// localhost:9222/memory/isolate-342342 (just used for inter-app nav)
//   show a combo list of the available isolates
// localhost:9222/performance - redirect to the best isolate
// localhost:9222/performance/isolate-342342
//   show a combo list of the available isolates

void main() {
  PerfToolFramework framework = new PerfToolFramework();
  framework.performInitialLoad();
}
