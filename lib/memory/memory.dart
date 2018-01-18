// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:vm_service_lib/vm_service_lib.dart';

import '../charts.dart';
import '../framework/framework.dart';
import '../globals.dart';
import '../tables.dart';
import '../ui/elements.dart';
import '../ui/primer.dart';
import '../utils.dart';

class MemoryScreen extends Screen {
  PButton loadSnapshotButton;
  PButton gcButton;
  Table<MemoryRow> memoryTable;
  Framework framework;

  PSelect isolateSelect;
  SetStateMixin isolateSelectSetState;
  MemoryScreen() : super('Memory', 'memory', 'octicon-package');

  @override
  void createContent(Framework framework, CoreElement mainDiv) {
    this.framework = framework;

    mainDiv.add([
      chartDiv(),
      div(c: 'section'),
      div(c: 'section')..setInnerHtml('''<b>Lorem ipsum dolor sit amet</b>,
consectetur adipiscing elit. Donec faucibus dolor quis rhoncus feugiat. Ut imperdiet
libero vel vestibulum vulputate. Aliquam consequat, lectus nec euismod commodo, turpis massa volutpat ex, a
elementum tellus turpis nec arcu; memory roots.'''),
      div(c: 'section')
        ..add([
          form()
            ..layoutHorizontal()
            ..add([
              isolateSelect = select()
                ..small()
                ..change(_handleIsolateSelect),
              loadSnapshotButton = new PButton('Load heap snapshot')
                ..small()
                ..primary()
                ..clazz('margin-left')
                ..click(_loadSnapshot),
              div()..flex(),
              gcButton = new PButton('Garbage collect')
                ..small()
                ..click(_doGC),
            ])
        ]),
      _createTableView()..clazz('section'),
    ]);

    isolateSelectSetState = new SetStateMixin();
    isolateSelectSetState.setState(_rebuildIsolatesSelect);

    // TODO: don't rebuild until the component is active
    serviceInfo.isolateManager.onIsolatesChanged.listen((_) {
      isolateSelectSetState.setState(_rebuildIsolatesSelect);
    });
    serviceInfo.isolateManager.onSelectedIsolateChanged.listen((_) {
      isolateSelectSetState.setState(_rebuildIsolatesSelect);
    });
  }

  void _rebuildIsolatesSelect() {
    isolateSelect.clear();
    serviceInfo.isolateManager.isolates.forEach(
        (ref) => isolateSelect.option(isolateName(ref), value: ref.id));
    if (serviceInfo.isolateManager.selectedIsolate != null) {
      isolateSelect.selectedIndex = serviceInfo.isolateManager.isolates
          .indexOf(serviceInfo.isolateManager.selectedIsolate);
    }
  }

  void _doGC() {
    gcButton.disabled = true;

    // TODO: collectAllGarbage only works when the VM is built for debug.
    serviceInfo.service.collectAllGarbage(_isolateId).then((_) {
      toast('Garbage collection performed.');
    }).catchError((e) {
      framework.showError('Error from GC', e);
    }).whenComplete(() {
      gcButton.disabled = false;
    });
  }

  void _handleIsolateSelect() {
    // TODO: update buttons
  }

  String get _isolateId => isolateSelect.value;

  void _loadSnapshot() {
    List<Event> events = [];
    Completer<List<Event>> graphEventsCompleter = new Completer();
    StreamSubscription sub;

    // TODO: harden this

    sub = serviceInfo.service.onGraphEvent.listen((Event e) {
      int index = e.json['chunkIndex'];
      int count = e.json['chunkCount'];

      if (events.length != count) {
        events.length = count;
      }

      events[index] = e;

      if (!events.any((e) => e == null)) {
        sub.cancel();
        graphEventsCompleter.complete(events);
      }
    });

    loadSnapshotButton.disabled = true;

    // TODO: snapshot info comes in as multiple binary _Graph events
    serviceInfo.service
        .requestHeapSnapshot(_isolateId, 'VM', true)
        .catchError((e) {
      framework.showError('Error retrieving heap snapshot', e);
    });

    graphEventsCompleter.future.then((List<Event> events) {
      print('received ${events.length} heap snapshot events.');
      toast('Snapshot download complete.');

      // type, kind, isolate, timestamp, chunkIndex, chunkCount, nodeCount, _data
      for (Event e in events) {
        int nodeCount = e.json['nodeCount'];
        ByteData data = e.json['_data'];
        print('  $nodeCount nodes, ${data.lengthInBytes ~/ 1024}k data');
      }
    }).whenComplete(() {
      print('done');
      loadSnapshotButton.disabled = false;
    });
  }

  CoreElement chartDiv() {
    CoreElement d = div(c: 'perf-chart section');

    // TODO: clean up
    LineChart.initChartLibrary().then((_) {
      DataTable data = new DataTable();
      data.addColumn('number', 'X');
      data.addColumn('number', 'MB');
      int value = 120;
      data.addRows(new List.generate(400, (i) {
        value += (r.nextInt(11) - 5);
        if (value < 0) value == 0;
        return [i, value];
      }));

      LineChart chart = new LineChart(d.element);
      chart.draw(data, options: {
        'chartArea': {'left': 35, 'right': 90, 'top': 12, 'bottom': 20},
        'vAxis': {
          'viewWindow': {'min': 0}
        }
      });
    }).catchError((e) {
      print('charting library not available');
      d.toggleClass('error');
    });

    return d;
  }

  CoreElement _createTableView() {
    memoryTable = new Table<MemoryRow>();

    memoryTable.addColumn(new MemoryColumnMB());
    memoryTable.addColumn(new MemoryColumnPercent());
    memoryTable.addColumn(new MemoryColumnName());

    memoryTable.setSortColumn(memoryTable.columns.first);

    memoryTable
        .setRows(new List<MemoryRow>.generate(100, (_) => MemoryRow.random()));

    memoryTable.onSelect.listen((MemoryRow row) {
      // TODO:
      print(row);
    });

    return memoryTable.element;
  }

  HelpInfo get helpInfo => new HelpInfo('memory view', 'http://www.cheese.com');
}

class MemoryRow {
  static MemoryRow random() {
    return new MemoryRow(
        getLoremFragment(), r.nextInt(4 * 1024 * 1024), r.nextDouble());
  }

  final String name;
  final int bytes;
  final double percentage;

  MemoryRow(this.name, this.bytes, this.percentage);

  String toString() => name;
}

class MemoryColumnName extends Column<MemoryRow> {
  MemoryColumnName() : super('Name', wide: true);

  dynamic getValue(MemoryRow row) => row.name;
}

class MemoryColumnMB extends Column<MemoryRow> {
  MemoryColumnMB() : super('Memory');

  bool get numeric => true;

  dynamic getValue(MemoryRow row) => row.bytes;

  String render(dynamic value) => '${Column.fastIntl(value ~/ 1024)}k';
}

class MemoryColumnPercent extends Column<MemoryRow> {
  MemoryColumnPercent() : super('%');

  bool get numeric => true;

  dynamic getValue(MemoryRow row) => row.percentage;

  String render(dynamic value) => percent2(value);
}
