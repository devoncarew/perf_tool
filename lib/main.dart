// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html' hide Screen;

import 'framework/framework.dart';
import 'globals.dart';
import 'logging/logging.dart';
import 'memory/memory.dart';
import 'performance/performance.dart';
import 'service.dart';
import 'timeline/timeline.dart';
import 'ui/elements.dart';
import 'ui/primer.dart';

// TODO: notification when the debug process goes away

class PerfToolFramework extends Framework {
  PerfToolFramework() {
    setGlobal(ServiceConnectionManager, new ServiceConnectionManager());

    addScreen(new MemoryScreen());
    addScreen(new PerformanceScreen());
    addScreen(new TimelineScreen());
    addScreen(new LoggingScreen());

    initGlobalUI();
  }

  void initGlobalUI() {
    CoreElement mainNav = new CoreElement.from(querySelector('#main-nav'));
    mainNav.clear();
    for (Screen screen in screens) {
      CoreElement link = new CoreElement('a')
        ..attributes['href'] = screen.ref
        ..onClick.listen((MouseEvent e) {
          e.preventDefault();
          navigateTo(screen.id);
        })
        ..add([
          span(c: 'octicon ${screen.iconClass}'),
          span(text: ' ${screen.name}')
        ]);
      mainNav.add(link);
    }

    // device status
    final StatusItem deviceStatus = new StatusItem();
    globalStatus.add(deviceStatus);

    _updateDeviceStatus(deviceStatus);

    serviceInfo.onStateChange.listen((_) {
      _updateDeviceStatus(deviceStatus);
    });

    // TODO: isolate selector
  }

  void _updateDeviceStatus(StatusItem deviceStatus) {
    deviceStatus.element.clear();

    if (serviceInfo.service != null) {
      PTooltip.add(
        deviceStatus.element,
        '${serviceInfo.hostCPU} • ${serviceInfo.targetCpu}\n'
            'SDK ${serviceInfo.sdkVersion}',
      );
      deviceStatus.element.add([
        span(c: 'octicon octicon-device-mobile'),
        span(text: ' ${serviceInfo.targetCpu}'),
      ]);
    } else {
      PTooltip.remove(deviceStatus.element);

      deviceStatus.element.add([
        span(c: 'octicon octicon-circle-slash'),
        span(text: ' no device connected'),
      ]);
    }
  }
}

class NotFoundScreen extends Screen {
  NotFoundScreen() : super('Not Found', 'notfound');

  void createContent(Framework framework, CoreElement mainDiv) {
    mainDiv.add(p(text: 'Page not found: ${window.location.pathname}'));
  }
}
