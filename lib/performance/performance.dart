// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:vm_service_lib/vm_service_lib.dart';

import '../charts/charts.dart';
import '../framework/framework.dart';
import '../globals.dart';
import '../tables/tables.dart';
import '../ui/elements.dart';
import '../ui/primer.dart';
import '../utils.dart';

class PerformanceScreen extends Screen {
  StatusItem sampleCountStatusItem;
  StatusItem sampleFreqStatusItem;

  PButton loadSnapshotButton;
  PButton resetButton;
  PSelect isolateSelect;
  Table perfTable;

  PerformanceScreen() : super('Performance', 'performance') {
    sampleCountStatusItem = new StatusItem();
    sampleCountStatusItem.element.text = '20,766 samples';
    addStatusItem(sampleCountStatusItem);

    sampleFreqStatusItem = new StatusItem();
    sampleFreqStatusItem.element.text = '32 frames per sample @ 1000Hz';
    addStatusItem(sampleFreqStatusItem);
  }

  @override
  void createContent(Framework framework, CoreElement mainDiv) {
    mainDiv.add([
      chartDiv(),
      div(c: 'section'),
      div(c: 'section')..setInnerHtml('''<b>Lorem ipsum dolor sit amet</b>,
consectetur adipiscing elit. Donec faucibus dolor quis rhoncus feugiat. Ut imperdiet
libero vel vestibulum vulputate. Aliquam consequat, lectus nec euismod commodo, turpis massa volutpat ex, a
elementum tellus turpis nec arcu.'''),
      div(c: 'section')
        ..add([
          form()
            ..layoutHorizontal()
            ..add([
              isolateSelect = select()
                ..small()
                ..change(_handleIsolateSelect),
              loadSnapshotButton = new PButton('Load snapshot')
                ..small()
                ..clazz('margin-left')
                ..click(_loadSnapshot),
              div()..flex(),
              resetButton = new PButton('Reset VM counters')
                ..small()
                ..click(_reset),
            ])
        ]),
      _createTableView()..clazz('section'),
    ]);

    _updateStatus(null);

    isolateSelect.clear();
    print(serviceInfo.isolateRefs);
    serviceInfo.isolateRefs.forEach(
        (ref) => isolateSelect.option(isolateName(ref), value: ref.id));
  }

  void _handleIsolateSelect() {
    // TODO: update buttons
  }

  String get _isolateId => isolateSelect.value;

  void _loadSnapshot() {
    loadSnapshotButton.disabled = true;

    serviceInfo.service
        .getCpuProfile(_isolateId, 'UserVM')
        .then((CpuProfile profile) async {
      // TODO:
      print(profile);

      _CalcProfile calc = new _CalcProfile(profile);
      await calc.calc();

      _updateStatus(profile);
    }).catchError((e) {
      toastError('', e);
    }).whenComplete(() {
      loadSnapshotButton.disabled = false;
    });
  }

  void _reset() {
    resetButton.disabled = true;

    serviceInfo.service.clearCpuProfile(_isolateId).then((_) {
      toast('VM counters reset.');
    }).catchError((e) {
      toastError('Error resetting counters', e);
    }).whenComplete(() {
      resetButton.disabled = false;
    });
  }

  CoreElement chartDiv() {
    CoreElement d = div(c: 'perf-chart section');

    // TODO: clean up
    LineChart.initChartLibrary().then((_) {
      DataTable data = new DataTable();
      data.addColumn('number', 'X');
      data.addColumn('number', 'CPU');
      data.addRows(new List.generate(100, (i) => [i, r.nextInt(100)]));

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
    perfTable = new Table<PerfData>();

    perfTable.addColumn(new PerfColumnInclusive());
    perfTable.addColumn(new PerfColumnSelf());
    perfTable.addColumn(new PerfColumnMethodName());

    perfTable.setSortColumn(perfTable.columns.first);

    perfTable.setRows(new List<PerfData>());

    return perfTable.element;
  }

  void _updateStatus(CpuProfile profile) {
    if (profile == null) {
      sampleCountStatusItem.element.text = 'no snapshot loaded';
      sampleFreqStatusItem.element.text = ' ';
    } else {
      Duration timeSpan = new Duration(seconds: profile.timeSpan.round());
      String s = timeSpan.toString();
      s = s.substring(0, s.length - 7);
      sampleCountStatusItem.element.text =
          '${nf.format(profile.sampleCount)} samples over $s';
      sampleFreqStatusItem.element.text =
          '${profile.stackDepth} frames per sample @ ${profile.samplePeriod}Hz';

      _process(profile);
    }
  }

  HelpInfo get helpInfo =>
      new HelpInfo('performance view docs and tips', 'http://www.cheese.com');

  void _process(CpuProfile profile) {
//    print(profile.codes.map((cr) => cr.code.name).toList());

    perfTable.setRows(
        new List<PerfData>.from(profile.functions.map((ProfileFunction f) {
      return new PerfData(
          f.kind,
          escape(funcRefName(f.function)),
          f.exclusiveTicks / profile.sampleCount,
          f.inclusiveTicks / profile.sampleCount);
    })));
  }
}

class PerfData {
  final String kind;
  final String name;
  final double self;
  final double inclusive;

  PerfData(this.kind, this.name, this.self, this.inclusive);
}

class PerfColumnInclusive extends Column<PerfData> {
  PerfColumnInclusive() : super('Total');

  bool get numeric => true;

  dynamic getValue(PerfData row) => row.inclusive;

  String render(dynamic value) => percent(value);
}

class PerfColumnSelf extends Column<PerfData> {
  PerfColumnSelf() : super('Self');

  bool get numeric => true;

  dynamic getValue(PerfData row) => row.self;

  String render(dynamic value) => percent(value);
}

class PerfColumnMethodName extends Column<PerfData> {
  PerfColumnMethodName() : super('Method', wide: true);

  bool get usesHtml => true;

  dynamic getValue(PerfData row) {
    if (row.kind == 'Dart') {
      return row.name;
    }
    return '${row.name} <span class="function-kind ${row.kind}">${row.kind}</span>';
  }
}

class _CalcProfile {
  final CpuProfile profile;

  _CalcProfile(this.profile);

  Future calc() async {
    // TODO:
    profile.exclusiveCodeTrie;

//    tries['exclusiveCodeTrie'] =
//      new Uint32List.fromList(profile['exclusiveCodeTrie']);
//    tries['inclusiveCodeTrie'] =
//      new Uint32List.fromList(profile['inclusiveCodeTrie']);
//    tries['exclusiveFunctionTrie'] =
//      new Uint32List.fromList(profile['exclusiveFunctionTrie']);
//    tries['inclusiveFunctionTrie'] =
//      new Uint32List.fromList(profile['inclusiveFunctionTrie']);
  }
}

/*
// Process code table.
for (var codeRegion in profile['codes']) {
  if (needToUpdate()) {
    await signal(count * 100.0 / length);
  }
  Code code = codeRegion['code'];
  assert(code != null);
  codes.add(new ProfileCode.fromMap(this, code, codeRegion));
}
// Process function table.
for (var profileFunction in profile['functions']) {
  if (needToUpdate()) {
    await signal(count * 100 / length);
  }
  ServiceFunction function = profileFunction['function'];
  assert(function != null);
  functions.add(
      new ProfileFunction.fromMap(this, function, profileFunction));
}

tries['exclusiveCodeTrie'] =
    new Uint32List.fromList(profile['exclusiveCodeTrie']);
tries['inclusiveCodeTrie'] =
    new Uint32List.fromList(profile['inclusiveCodeTrie']);
tries['exclusiveFunctionTrie'] =
    new Uint32List.fromList(profile['exclusiveFunctionTrie']);
tries['inclusiveFunctionTrie'] =
    new Uint32List.fromList(profile['inclusiveFunctionTrie']);

*/
