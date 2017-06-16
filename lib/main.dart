// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:html' hide Screen;

import 'about.dart';
import 'framework.dart';
import 'globals.dart';
import 'memory/memory.dart';
import 'performance/performance.dart';
import 'service.dart';
import 'timeline/timeline.dart';
import 'ui/elements.dart';
import 'ui/primer.dart';

class PerfToolFramework extends Framework {
  PerfToolFramework() {
    setGlobal(ServiceInfo, new ServiceInfo());

    addScreen(_initReferences(new AboutScreen()));
    addScreen(_initReferences(new MainScreen()));
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

class MainScreen extends Screen {
  MainScreen() : super('Observatory', '/');

  CoreElement statusElement;

  @override
  void createContent(CoreElement mainDiv) {
    statusElement = p(text: ' ');

    mainDiv.add([
      statusElement,
      new CoreElement('hr'),
      // TODO: Add more descriptive text.
      p()..setInnerHtml('''
<b>Use the timeline view</b> to diagnose jank in your UI.
Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec faucibus dolor quis rhoncus feugiat. Ut imperdiet
libero vel vestibulum vulputate. Aliquam consequat, lectus nec euismod commodo, turpis massa volutpat ex, a
elementum tellus turpis nec arcu. Suspendisse erat nisl, rhoncus ut nisi in, lacinia pretium dui. Donec at erat
ultrices, tincidunt quam sit amet, cursus lectus.'''),
      p()..setInnerHtml('''
<b>Use the performance view</b> to find performance hot spots in your application code.
Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec faucibus dolor quis rhoncus feugiat. Ut imperdiet
libero vel vestibulum vulputate.'''),
      p()
        ..setInnerHtml(
            '''<b>Use the memory view</b> to view your application's memory usage and find leaks.
            Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec faucibus dolor quis rhoncus feugiat. Ut imperdiet
libero vel vestibulum vulputate. Aliquam consequat, lectus nec euismod commodo, turpis massa volutpat ex, a
elementum tellus turpis nec arcu.'''),
    ]);
  }

  StreamSubscription _stateSubscription;

  @override
  void entering() {
    _updateStatus();
    _stateSubscription = serviceInfo.onStateChange.listen(_updateStatus);
    // TODO: subscribe to isolate info
  }

  @override
  void exiting() {
    _stateSubscription.cancel();
  }

  void _updateStatus([_]) {
    // Device connected (x64); 1 isolate running.
    if (serviceInfo.service == null) {
      statusElement.text = 'No device connected';
    } else {
      String plural =
          serviceInfo.isolateRefs.length == 1 ? 'isolate' : 'isolates';
      statusElement.text = 'Device connected • '
          '${serviceInfo.hostCPU} • '
          '${serviceInfo.isolateRefs.length} $plural running';
    }
  }
}

class NotFoundScreen extends Screen {
  NotFoundScreen() : super('Not Found', 'notfound');

  void createContent(CoreElement mainDiv) {
    mainDiv.add(p(text: 'Page not found: ${window.location.pathname}'));
  }
}
