// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../framework/framework.dart';
import '../globals.dart';
import '../overview/overview.dart';
import '../tables/tables.dart';
import '../ui/elements.dart';
import '../ui/primer.dart';
import '../utils.dart';

class MemoryScreen extends Screen {
  MemoryScreen() : super('Memory', 'memory');

  @override
  void createContent(CoreElement mainDiv) {
    mainDiv.add([
      chartDiv(),
      div(c: 'section')
        ..layoutHorizontal()
        ..add([
          div(c: 'margin-right')
            ..flex()
            ..setInnerHtml('''<b>Lorem ipsum dolor sit amet</b>,
consectetur adipiscing elit. Donec faucibus dolor quis rhoncus feugiat. Ut imperdiet
libero vel vestibulum vulputate. Aliquam consequat, lectus nec euismod commodo, turpis massa volutpat ex, a
elementum tellus turpis nec arcu.'''),
          div()
            ..add([
              new PButton('Load snapshot')..small(),
              span(text: ' '),
              new PButton('Garbage collect')
                ..small()
                ..click(_doGC),
            ]),
        ]),
      _createTableView()..clazz('section'),
    ]);
  }

  void _doGC() {
    // TODO:
    serviceInfo.service.collectAllGarbage(serviceInfo.isolateRefs.last.id);
  }

  CoreElement chartDiv() {
    CoreElement d = div(c: 'perf-chart section');
    d.element.style.backgroundColor = '#f0f0f0';
    return d;
  }

  CoreElement _createTableView() {
    Table table = new Table<SampleData>();

    table.addColumn(new SampleColumnMethodName());
    table.addColumn(new SampleColumnCount());
    table.addColumn(new SampleColumnUsage());

    table.setSortColumn(table.columns.last);

    table.setRows(
        new List<SampleData>.generate(100, (_) => SampleData.random()));

    return table.element;
  }

  HelpInfo get helpInfo =>
      new HelpInfo('memory view docs and tips', 'http://www.cheese.com');
}
