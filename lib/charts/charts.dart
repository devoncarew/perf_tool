// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:html' show Element, window, Rectangle;
import 'dart:math' as math;

import '../ui/elements.dart';

abstract class LineChart<T> {
  final CoreElement parent;
  CoreElement chartElement;
  math.Point<int> dim;

  LineChart(this.parent) {
    parent.element.style.position = 'relative';

    window.onResize.listen((e) => _updateSize());
    Timer.run(_updateSize);

    chartElement = parent.add(div()..layoutVertical());

    chartElement.setInnerHtml('''
<svg viewBox="0 0 500 100" preserveAspectRatio="none">
<polyline
    fill="none"
    stroke="#0074d9"
    stroke-width="3"
    points=""/>
</svg>
''');
  }

  void _updateSize() {
    Rectangle rect = chartElement.element.getBoundingClientRect();
    Element svgChild = chartElement.element.children.first;
    svgChild.setAttribute('viewBox', '0 0 ${rect.width} ${rect.height}');
    dim = new math.Point<int>(rect.width.toInt(), rect.height.toInt());
  }

  set disabled(bool value) {
    parent.disabled = value;
  }

  void updateFrom(T data);
}
