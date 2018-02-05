// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html' hide Screen;

import 'package:vm_service_lib/vm_service_lib.dart';

import 'framework/framework.dart';
import 'globals.dart';
import 'logging/logging.dart';
import 'memory/memory.dart';
import 'performance/performance.dart';
import 'service.dart';
import 'timeline/timeline.dart';
import 'ui/elements.dart';
import 'ui/primer.dart';
import 'utils.dart';

// TODO: notification when the debug process goes away

// TODO: isolate control to the status line

// TODO: page notification of isolate changes

// TODO: a sense of whether a page is active or not

class PerfToolFramework extends Framework {
  StatusItem deviceStatus;
  StatusItem isolateSelectStatus;
  PSelect isolateSelect;

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

    // TODO: isolate selector should use the rich pulldown UI
    isolateSelectStatus = new StatusItem();
    globalStatus.add(isolateSelectStatus);
    isolateSelect = select()
      ..small()
      ..change(_handleIsolateSelect);
    isolateSelectStatus.element.add(isolateSelect);
    _rebuildIsolateSelect();
    serviceInfo.isolateManager.onIsolatesChanged.listen(_rebuildIsolateSelect);
    serviceInfo.isolateManager.onSelectedIsolateChanged
        .listen(_rebuildIsolateSelect);

    // device status
    deviceStatus = new StatusItem();
    globalStatus.add(deviceStatus);
    _updateDeviceStatus(deviceStatus);
    serviceInfo.onStateChange.listen((_) {
      _updateDeviceStatus(deviceStatus);
    });
  }

  IsolateRef get currentIsolate => serviceInfo.isolateManager.selectedIsolate;

  void _handleIsolateSelect() {
    serviceInfo.isolateManager.selectIsolate(isolateSelect.value);
  }

  void _rebuildIsolateSelect([_]) {
    isolateSelect.clear();
    for (IsolateRef ref in serviceInfo.isolateManager.isolates) {
      isolateSelect.option(isolateName(ref), value: ref.id);
    }
    isolateSelect.disabled = serviceInfo.isolateManager.isolates.isEmpty;
    if (serviceInfo.isolateManager.selectedIsolate != null) {
      isolateSelect.selectedIndex = serviceInfo.isolateManager.isolates
          .indexOf(serviceInfo.isolateManager.selectedIsolate);
    }
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
      ]);
    } else {
      PTooltip.remove(deviceStatus.element);

      deviceStatus.element.add([
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
