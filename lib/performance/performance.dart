// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math';

import 'package:perf_tool/utils.dart';

import '../framework.dart';
import '../ui/elements.dart';

class PerformanceScreen extends Screen {
  PerformanceScreen() : super('Performance', 'performance');

  @override
  void createContent(CoreElement mainDiv) {
    mainDiv.layoutVertical();

    mainDiv.add([
      tableDiv(),
      div(c: 'section')..setInnerHtml('''<b>Lorem ipsum dolor sit amet</b>,
consectetur adipiscing elit. Donec faucibus dolor quis rhoncus feugiat. Ut imperdiet
libero vel vestibulum vulputate. Aliquam consequat, lectus nec euismod commodo, turpis massa volutpat ex, a
elementum tellus turpis nec arcu.'''),
      perfDataDiv()
        ..flex()
        ..element.style.overflow = 'auto',
    ]);
  }

  CoreElement tableDiv() {
    CoreElement d = div(c: 'perf-chart section');
    return d;
  }

  final Random r = new Random();

  CoreElement perfDataDiv() {
    return div(c: 'section')
      ..element.innerHtml = '''
<table>
<thead><th>Name</th><th>Count</th><th>Usage</th></thead>
  <tr><td>${getLoremFragment()}</td><td class="right">${r.nextInt(
          30)}</td><td class="right">${r.nextDouble() * 100}</td></tr>
  <tr><td>${getLoremFragment()}</td><td class="right">${r.nextInt(
          30)}</td><td class="right">${r.nextDouble() * 100}</td></tr>
  <tr><td>${getLoremFragment()}</td><td class="right">${r.nextInt(
          30)}</td><td class="right">${r.nextDouble() * 100}</td></tr>
  <tr><td>${getLoremFragment()}</td><td class="right">${r.nextInt(
          30)}</td><td class="right">${r.nextDouble() * 100}</td></tr>
  <tr><td>${getLoremFragment()}</td><td class="right">${r.nextInt(
          30)}</td><td class="right">${r.nextDouble() * 100}</td></tr>
  <tr><td>${getLoremFragment()}</td><td class="right">${r.nextInt(
          30)}</td><td class="right">${r.nextDouble() * 100}</td></tr>
  <tr><td>${getLoremFragment()}</td><td class="right">${r.nextInt(
          30)}</td><td class="right">${r.nextDouble() * 100}</td></tr>
  <tr><td>${getLoremFragment()}</td><td class="right">${r.nextInt(
          30)}</td><td class="right">${r.nextDouble() * 100}</td></tr>
  <tr><td>${getLoremFragment()}</td><td class="right">${r.nextInt(
          30)}</td><td class="right">${r.nextDouble() * 100}</td></tr>
  <tr><td>${getLoremFragment()}</td><td class="right">${r.nextInt(
          30)}</td><td class="right">${r.nextDouble() * 100}</td></tr>
  <tr><td>${getLoremFragment()}</td><td class="right">${r.nextInt(
          30)}</td><td class="right">${r.nextDouble() * 100}</td></tr>
  <tr><td>${getLoremFragment()}</td><td class="right">${r.nextInt(
          30)}</td><td class="right">${r.nextDouble() * 100}</td></tr>
  <tr><td>${getLoremFragment()}</td><td class="right">${r.nextInt(
          30)}</td><td class="right">${r.nextDouble() * 100}</td></tr>
  <tr><td>${getLoremFragment()}</td><td class="right">${r.nextInt(
          30)}</td><td class="right">${r.nextDouble() * 100}</td></tr>
</table>
''';
  }

  HelpInfo get helpInfo => new HelpInfo(
      'Docs and tips for the performance view', 'http://www.cheese.com');
}
