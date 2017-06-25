// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import '../framework/framework.dart';
import '../globals.dart';
import '../ui/elements.dart';
import '../utils.dart';

class OverviewScreen extends Screen {
  OverviewScreen() : super('Overview', '/');

  CoreElement statusElement;

  @override
  void createContent(Framework framework, CoreElement mainDiv) {
    statusElement = p(text: ' ');

    mainDiv.add([
      div(c: 'section')
        ..add([
          statusElement,
        ]),
      div(c: 'section')
        ..add([
          h2(text: 'Views'),
          p()..setInnerHtml('''
<b>Use the timeline view</b> to diagnose jank in your UI.
Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec faucibus dolor quis rhoncus feugiat. Ut imperdiet
libero vel vestibulum vulputate.'''),
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
        ]),
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
      statusElement.setInnerHtml('<b>Device:</b> no device connected');
    } else {
      String plural =
          serviceInfo.isolateRefs.length == 1 ? 'isolate' : 'isolates';
      String text = '${serviceInfo.hostCPU} • '
          '${serviceInfo.targetCpu} • '
          '${serviceInfo.isolateRefs.length} $plural running';
      statusElement.setInnerHtml('<b>Device:</b> ${escape(text)}');
    }
  }
}
