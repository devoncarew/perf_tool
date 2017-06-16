// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html' hide Screen;

import 'about.dart';
import 'framework.dart';
import 'globals.dart';
import 'memory/memory.dart';
import 'package:perf_tool/overview/overview.dart';
import 'performance/performance.dart';
import 'service.dart';
import 'timeline/timeline.dart';
import 'ui/elements.dart';
import 'ui/primer.dart';

class PerfToolFramework extends Framework {
  PerfToolFramework() {
    setGlobal(ServiceInfo, new ServiceInfo());

    addScreen(_initReferences(new AboutScreen()));
    addScreen(_initReferences(new OverviewScreen()));
    addScreen(_initReferences(new TimelineScreen()));
    addScreen(_initReferences(new PerformanceScreen()));
    addScreen(_initReferences(new MemoryScreen()));

    initGlobalUI();
  }

  Screen _initReferences(Screen screen) {
    for (Element element in querySelectorAll('a[href="${screen.ref}"]')) {
      element.onClick.listen((event) {
        if (element.attributes.containsKey('disabled')) return;

        event.preventDefault();
        navigateTo(screen.id);
      });
    }

    return screen;
  }

  void initGlobalUI() {
    // device status
    CoreElement deviceStatus =
        new CoreElement.from(querySelector('#deviceStatus'));
    serviceInfo.onStateChange.listen((_) {
      deviceStatus.clear();

      if (serviceInfo.service != null) {
        PTooltip.add(
          deviceStatus,
          '${serviceInfo.hostCPU} • ${serviceInfo.targetCpu}\n'
              'SDK ${serviceInfo.sdkVersion}',
        );
        deviceStatus.add([
          span(c: 'octicon octicon-device-mobile'),
          span(text: ' connected'),
        ]);
      } else {
        PTooltip.remove(deviceStatus);

        deviceStatus.add([
          span(c: 'octicon octicon-circle-slash'),
          span(text: ' no device connected'),
        ]);
      }
    });
  }
}

class NotFoundScreen extends Screen {
  NotFoundScreen() : super('Not Found', 'notfound');

  void createContent(CoreElement mainDiv) {
    mainDiv.add(p(text: 'Page not found: ${window.location.pathname}'));
  }
}
