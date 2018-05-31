// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import 'package:vm_service_lib/vm_service_lib.dart';

import '../charts/charts.dart';
import '../framework/framework.dart';
import '../globals.dart';
import '../ui/elements.dart';

class TimelineScreen extends Screen {
  FramesChart framesChart;
  SetStateMixin framesChartStateMixin = new SetStateMixin();
  FramesTracker framesTracker;

  TimelineScreen() : super('Timeline', 'timeline', 'octicon-pulse');

  @override
  void createContent(Framework framework, CoreElement mainDiv) {
    mainDiv.add([
      createLiveChartArea(),
      div(c: 'section'),
      div(c: 'section')..add([p(text: 'Timeline todo:')])
    ]);

    serviceInfo.onConnectionAvailable.listen(_handleConnectionStart);
    if (serviceInfo.hasConnection) {
      _handleConnectionStart(serviceInfo.service);
    }
    serviceInfo.onConnectionClosed.listen(_handleConnectionStop);
  }

  CoreElement createLiveChartArea() {
    CoreElement container = div(c: 'section perf-chart table-border')
      ..layoutVertical();
    framesChart = new FramesChart(container);
    framesChart.disabled = true;
    return container;
  }

  void _handleConnectionStart(VmService service) {
    framesChart.disabled = false;

    framesTracker = new FramesTracker(service);
    framesTracker.start();

    framesTracker.onChange.listen((_) {
      framesChartStateMixin.setState(() {
        framesChart.updateFrom(framesTracker);
      });
    });
  }

  void _handleConnectionStop(dynamic event) {
    framesChart.disabled = true;

    framesTracker?.stop();
  }

  HelpInfo get helpInfo =>
      new HelpInfo('timeline docs', 'http://www.cheese.com');
}

class FramesChart extends LineChart<FramesTracker> {
  CoreElement fpsLabel;
  CoreElement lastFrameLabel;

  FramesChart(CoreElement parent) : super(parent) {
    fpsLabel = parent.add(div(c: 'perf-label'));
    fpsLabel.element.style.left = '0';
    fpsLabel.element.style.top = '0';
    fpsLabel.element.style.bottom = null;

    lastFrameLabel = parent.add(div(c: 'perf-label'));
    lastFrameLabel.element.style.right = '0';
    lastFrameLabel.element.style.top = '0';
    lastFrameLabel.element.style.bottom = null;
    lastFrameLabel.element.style.textAlign = '-webkit-right';
  }

  void update(FramesTracker tracker) {
    if (dim == null) {
      return;
    }

    fpsLabel.text = '${tracker.calcRecentFPS().round()} FPS';
    FrameInfo lastFrame = tracker.lastSample;
    lastFrameLabel.setInnerHtml('frame ${lastFrame.number} • '
        '${lastFrame.elapsedMs.toStringAsFixed(1)}ms');

    // re-render the svg
    const num msHeight = 2 * FrameInfo.kTargetMaxFrameTimeMs;
    const num halfFrameHeight = FrameInfo.kTargetMaxFrameTimeMs / 2;
    final num pixPerMs = dim.y / msHeight;
    // ignore: const_initialized_with_non_constant_value
    const double units = dim.x / (3 * FramesTracker.kMaxFrames);

    List<String> svgElements = [];
    List<FrameInfo> samples = tracker.samples;

    for (int i = 3; i > 0; i--) {
      num y = i * halfFrameHeight * pixPerMs;
      String dashed = i == 2 ? '' : 'stroke-dasharray="10 5" ';
      svgElements.add('<line x1="0" y1="$y" x2="${dim.x}" y2="$y" '
          'stroke-width="0.5" stroke="#ddd" $dashed/>');
    }

    double x = dim.x.toDouble();

    for (int i = samples.length - 1; i >= 0; i--) {
      FrameInfo frame = samples[i];
      num height = math.min(dim.y, frame.elapsedMs * pixPerMs);
      x -= 3 * units;

      String color = frame.elapsedMs > FrameInfo.kTargetMaxFrameTimeMs
          ? '#f97c7c'
          : '#4078c0';
      svgElements.add('<rect x="$x" y="${dim.y - height}" rx="1" ry="1" '
          'width="${2 * units}" height="$height" '
          'style="fill:$color"><title>${frame.elapsedMs}ms</title></rect>');

      if (frame.frameGroupStart) {
        double lineX = x - (units / 2);
        svgElements.add('<line x1="$lineX" y1="0" x2="$lineX" y2="${dim.y}" '
            'stroke-width="0.5" stroke-dasharray="4 4" stroke="#ddd"/>');
      }
    }

    chartElement.setInnerHtml('''
 <svg viewBox="0 0 ${dim.x} ${dim.y}">
 ${svgElements.join('\n')}
 </svg>
 ''');
  }
}

class FramesTracker {
  static const kMaxFrames = 60;

  VmService service;
  final StreamController _changeController = new StreamController.broadcast();
  List<FrameInfo> samples = [];

  FramesTracker(this.service) {
    service.onExtensionEvent.listen((Event e) {
      if (e.extensionKind == 'Flutter.Frame') {
        ExtensionData data = e.extensionData;
        addSample(FrameInfo.from(data.data));
      }
    });
  }

  bool get hasConnection => service != null;

  Stream get onChange => _changeController.stream;

  void start() {}

  void stop() {}

  void addSample(FrameInfo frame) {
    if (samples.isEmpty) {
      frame.frameGroupStart = true;
    } else {
      frame.calcFrameGroupStart(samples.last);
    }
    samples.add(frame);
    while (samples.length > kMaxFrames) {
      samples.removeAt(0);
    }
    _changeController.add(null);
  }

  FrameInfo get lastSample => samples.isEmpty ? null : samples.last;

  num calcRecentFPS() {
    int frameCount = 0;
    int usedFrames = 0;

    for (int i = samples.length - 1; i >= 0; i--) {
      FrameInfo frame = samples[i];

      frameCount++;

      num frameTime = frame.elapsedMs;
      int requiredFrames =
          (frameTime / FrameInfo.kTargetMaxFrameTimeMs).round();
      frameTime -= requiredFrames * FrameInfo.kTargetMaxFrameTimeMs;
      if (frameTime > 0) {
        requiredFrames++;
      }
      usedFrames += requiredFrames;

      if (frame.frameGroupStart) {
        break;
      }
    }

    return 1000 * frameCount / (usedFrames * FrameInfo.kTargetMaxFrameTimeMs);
  }
}

class FrameInfo {
  static const double kTargetMaxFrameTimeMs = 1000.0 / 60;

  static FrameInfo from(Map data) {
    return new FrameInfo(
        data['number'], data['elapsed'] / 1000, data['startTime'] / 1000);
  }

  final int number;
  final num elapsedMs;
  final num startTimeMs;

  bool frameGroupStart = false;

  FrameInfo(this.number, this.elapsedMs, this.startTimeMs);

  num get endTimeMs => startTimeMs + elapsedMs;

  void calcFrameGroupStart(FrameInfo previousFrame) {
    if (startTimeMs > (previousFrame.endTimeMs + kTargetMaxFrameTimeMs)) {
      frameGroupStart = true;
    }
  }

  String toString() => 'frame $number ${elapsedMs.toStringAsFixed(1)}ms';
}
