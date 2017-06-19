// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../charts/charts.dart';
import '../framework/framework.dart';
import '../overview/overview.dart';
import '../tables/tables.dart';
import '../ui/elements.dart';
import '../utils.dart';

class PerformanceScreen extends Screen {
  StatusItem sampleCountStatusItem;
  StatusItem sampleFreqStatusItem;

  PerformanceScreen() : super('Performance', 'performance') {
    // TODO:
    sampleCountStatusItem = new StatusItem();
    sampleCountStatusItem.element.text = '20,766 samples';
    addStatusItem(sampleCountStatusItem);

    sampleFreqStatusItem = new StatusItem();
    sampleFreqStatusItem.element.text = '32 frames per sample @ 1000Hz';
    addStatusItem(sampleFreqStatusItem);
  }

  @override
  void createContent(CoreElement mainDiv) {
    mainDiv.add([
      chartDiv(),
      div(c: 'section')..setInnerHtml('''<b>Lorem ipsum dolor sit amet</b>,
consectetur adipiscing elit. Donec faucibus dolor quis rhoncus feugiat. Ut imperdiet
libero vel vestibulum vulputate. Aliquam consequat, lectus nec euismod commodo, turpis massa volutpat ex, a
elementum tellus turpis nec arcu.'''),
      _createTableView()..clazz('section'),
    ]);
  }

  CoreElement chartDiv() {
    CoreElement d = div(c: 'perf-chart section');

    // TODO: clean up
    LineChart.initChartLibrary().then((_) {
      DataTable data = new DataTable();
      data.addColumn('number', 'X');
      data.addColumn('number', 'CPU');
      data.addRows([
        [0, 0],
        [1, 10],
        [2, 23],
        [3, 17],
        [4, 18],
        [5, 9],
        [6, 11],
        [7, 27],
        [8, 33],
        [9, 40],
        [10, 32],
        [11, 35],
        [12, 30],
        [13, 40],
        [14, 42],
        [15, 47],
        [16, 44],
        [17, 48],
        [18, 52],
        [19, 54],
        [20, 42],
        [21, 55],
        [22, 56],
        [23, 57],
        [24, 60],
        [25, 50],
        [26, 52],
        [27, 51],
        [28, 49],
        [29, 53],
        [30, 55],
        [31, 60],
        [32, 61],
        [33, 59],
        [34, 62],
        [35, 65],
        [36, 62],
        [37, 58],
        [38, 55],
        [39, 61],
        [40, 64],
        [41, 65],
        [42, 63],
        [43, 66],
        [44, 67],
        [45, 69],
        [46, 69],
        [47, 70],
        [48, 72],
        [49, 68],
        [50, 66],
        [51, 65],
        [52, 67],
        [53, 70],
        [54, 71],
        [55, 72],
        [56, 73],
        [57, 75],
        [58, 70],
        [59, 68],
        [60, 64],
        [61, 60],
        [62, 65],
        [63, 67],
        [64, 68],
        [65, 69],
        [66, 70],
        [67, 72],
        [68, 75],
        [69, 80]
      ]);

      LineChart chart = new LineChart(d.element);
      chart.draw(data, options: {
        'chartArea': {'left': 35, 'right': 90, 'top': 10, 'bottom': 20}
      });
    }).catchError((e) {
      print('charting library not available');
      d.toggleClass('error');
    });

    return d;
  }

  CoreElement _createTableView() {
    Table table = new Table<SampleData>();

    table.addColumn(new SampleColumnMethodName());
    table.addColumn(new SampleColumnCount());
    table.addColumn(new SampleColumnUsage());

    table.setSortColumn(table.columns.last);

    table
        .setRows(new List<SampleData>.generate(25, (_) => SampleData.random()));

    return table.element;
  }

  HelpInfo get helpInfo =>
      new HelpInfo('performance view docs and tips', 'http://www.cheese.com');
}
