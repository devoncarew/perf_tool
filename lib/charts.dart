// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:html';
import 'dart:js';

class LineChart {
  static Future initChartLibrary() {
    // google.charts.load('current', {packages: ['corechart', 'line']});
    // google.charts.setOnLoadCallback(drawBasic);

    Completer completer = new Completer();

    try {
      JsObject charts = context['google']['charts'];
      charts.callMethod('load', [
        'current',
        new JsObject.jsify({
          'packages': ['corechart', 'line']
        })
      ]);
      charts.callMethod('setOnLoadCallback', [completer.complete]);
    } catch (e) {
      completer.completeError(e);
    }

    return completer.future;
  }

  final Element element;
  JsObject chart;

  LineChart(this.element) {
    // var chart = new google.visualization.LineChart(document.getElementById('chart_div'));
    JsFunction ctor = context['google']['visualization']['LineChart'];
    chart = new JsObject(ctor, [element]);
  }

  void draw(DataTable data, {Map options}) {
    // chart.draw(data, options);
    chart.callMethod('draw',
        [data.dataTable, options == null ? null : new JsObject.jsify(options)]);
  }
}

class DataTable {
  JsObject dataTable;

  DataTable() {
    // var data = new google.visualization.DataTable();
    JsFunction ctor = context['google']['visualization']['DataTable'];
    dataTable = new JsObject(ctor);
  }

  void addColumn(String type, String name) {
    // data.addColumn('number', 'Dogs');
    dataTable.callMethod('addColumn', [type, name]);
  }

  void addRows(List<List> rows) {
    // data.addRows([...])

    JsArray arr =
        new JsArray.from(rows.map((List list) => new JsArray.from(list)));
    dataTable.callMethod('addRows', [arr]);
  }
}

/*
  var options = {
    chartArea: {
      left: 35,
      right: 75,
      top: 10,
      bottom: 20
    },
    hAxis: {
      //title: 'Time',
      baseline: -10
    },
    vAxis: {
      //title: 'Popularity'
    },
    //animation: {
    //  startup: true
    //},
    //lineWidth: 3,
    //axisTitlesPosition: 'none'
  };
}
*/
