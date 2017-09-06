// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

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
  CoreElement progressElement;
  Table<PerfData> perfTable;
  Framework framework;

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
    this.framework = framework;

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
                ..primary()
                ..clazz('margin-left')
                ..click(_loadSnapshot),
              progressElement = span(c: 'margin-left text-gray')..flex(),
              resetButton = new PButton('Reset VM counters')
                ..small()
                ..click(_reset),
            ])
        ]),
      _createTableView()..clazz('section'),
    ]);

    _updateStatus(null);

    isolateSelect.clear();

    if (serviceInfo.isolateRefs != null) {
      serviceInfo.isolateRefs.forEach(
          (ref) => isolateSelect.option(isolateName(ref), value: ref.id));
    }
  }

  void _handleIsolateSelect() {
    // TODO: update buttons
  }

  String get _isolateId => isolateSelect.value;

  void _loadSnapshot() {
    loadSnapshotButton.disabled = true;

    progressElement.text = 'Loading snapshot…';

    serviceInfo.service
        .getCpuProfile(_isolateId, 'UserVM')
        .then((CpuProfile profile) async {
      // TODO:
      print(profile);

      _CalcProfile calc = new _CalcProfile(profile);
      await calc.calc();

      _updateStatus(profile);
    }).catchError((e) {
      framework.showError('', e);
    }).whenComplete(() {
      loadSnapshotButton.disabled = false;
      progressElement.text = '';
    });
  }

  void _reset() {
    resetButton.disabled = true;

    serviceInfo.service.clearCpuProfile(_isolateId).then((_) {
      toast('VM counters reset.');
    }).catchError((e) {
      framework.showError('Error resetting counters', e);
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
      int value = 30;
      data.addRows(new List.generate(400, (i) {
        value += (r.nextInt(7) - 3);
        value = math.max(0, math.min(100, value));
        return [i, value];
      }));

      LineChart chart = new LineChart(d.element);
      chart.draw(data, options: {
        'chartArea': {'left': 35, 'right': 90, 'top': 12, 'bottom': 20},
        'vAxis': {
          'viewWindow': {'min': 0, 'max': 100}
        }
      });
      // ticks: [0, 25, 50, 75, 100] // display labels every 25
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

    perfTable.onSelect.listen((PerfData data) {
      // TODO:
      print(data);
    });

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
    perfTable.setRows(
        new List<PerfData>.from(profile.functions.map((ProfileFunction f) {
      int count = math.max(1, profile.sampleCount);
      return new PerfData(
        f.kind,
        escape(funcRefName(f.function)),
        f.exclusiveTicks / count,
        f.inclusiveTicks / count,
      );
    })));
  }
}

class PerfData {
  final String kind;
  final String name;
  final double self;
  final double inclusive;

  PerfData(this.kind, this.name, this.self, this.inclusive);

  String toString() => '[$kind] $name';
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
    return '${row.name} <span class="function-kind ${row.kind}">${row
        .kind}</span>';
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
