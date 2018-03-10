// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import 'package:vm_service_lib/vm_service_lib.dart';

import '../charts/charts.dart';
import '../framework/framework.dart';
import '../globals.dart';
import '../tables.dart';
import '../ui/custom.dart';
import '../ui/elements.dart';
import '../ui/primer.dart';

// TODO: expose _getAllocationProfile

class MemoryScreen extends Screen {
  PButton loadSnapshotButton;
  PButton gcButton;
  Table<ClassHeapStats> memoryTable;
  Framework framework;

  MemoryChart memoryChart;
  SetStateMixin memoryChartStateMixin = new SetStateMixin();
  MemoryTracker memoryTracker;
  ProgressElement progressElement;

  MemoryScreen() : super('Memory', 'memory', 'octicon-package');

  @override
  void createContent(Framework framework, CoreElement mainDiv) {
    this.framework = framework;

    mainDiv.add([
      createLiveChartArea(),
      div(c: 'section'),
      div(c: 'section')
        ..add([
          form()
            ..layoutHorizontal()
            ..clazz('align-items-center')
            ..add([
              loadSnapshotButton = new PButton('Load heap snapshot')
                ..small()
                ..primary()
                ..click(_loadAllocationProfile),
              progressElement = new ProgressElement()
                ..clazz('margin-left')
                ..display = 'none',
              div()..flex(),
              gcButton = new PButton('Garbage collect')
                ..small()
                ..click(_doGC),
            ])
        ]),
      _createTableView()..clazz('section'),
    ]);

    // TODO: don't rebuild until the component is active
    serviceInfo.isolateManager.onSelectedIsolateChanged.listen((_) {
      _handleIsolateChanged();
    });

    serviceInfo.onConnectionAvailable.listen(_handleConnectionStart);
    if (serviceInfo.hasConnection) {
      _handleConnectionStart(serviceInfo.service);
    }
    serviceInfo.onConnectionClosed.listen(_handleConnectionStop);
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

  void _handleIsolateChanged() {
    // TODO: update buttons
  }

  String get _isolateId => serviceInfo.isolateManager.selectedIsolate.id;

  Future _loadAllocationProfile() async {
    loadSnapshotButton.disabled = true;

    // TODO: error handling

    try {
      // 'reset': true to reset the object allocation accumulators
      Response response = await serviceInfo.service
          .callMethod('_getAllocationProfile', isolateId: _isolateId);
      List members = response.json['members'];
      List<ClassHeapStats> heapStats = members
          .map((d) => new ClassHeapStats(d))
          .where((ClassHeapStats stats) {
        return stats.instancesCurrent > 0; //|| stats.instancesAccumulated > 0;
      }).toList();

      heapStats.forEach((stats) {
        if (stats.classRef.name.isEmpty) {
          print(stats.json);
        }
      });

      memoryTable.setRows(heapStats);
    } finally {
      loadSnapshotButton.disabled = false;
    }
  }

//  void _loadHeapSnapshot() {
//    List<Event> events = [];
//    Completer<List<Event>> graphEventsCompleter = new Completer();
//    StreamSubscription sub;
//
//    int received = 0;
//    sub = serviceInfo.service.onGraphEvent.listen((Event e) {
//      int index = e.json['chunkIndex'];
//      int count = e.json['chunkCount'];
//
//      print('received $index of $count');
//
//      if (events.length != count) {
//        events.length = count;
//        progressElement.max = count;
//      }
//
//      received++;
//
//      progressElement.value = received;
//
//      events[index] = e;
//
//      if (!events.any((e) => e == null)) {
//        sub.cancel();
//        graphEventsCompleter.complete(events);
//      }
//    });
//
//    loadSnapshotButton.disabled = true;
//    progressElement.value = 0;
//    progressElement.display = 'initial';
//
//    // TODO: snapshot info comes in as multiple binary _Graph events
//    serviceInfo.service
//        .requestHeapSnapshot(_isolateId, 'VM', true)
//        .catchError((e) {
//      framework.showError('Error retrieving heap snapshot', e);
//    });
//
//    graphEventsCompleter.future.then((List<Event> events) {
//      print('received ${events.length} heap snapshot events.');
//      toast('Snapshot download complete.');
//
//      // type, kind, isolate, timestamp, chunkIndex, chunkCount, nodeCount, _data
//      for (Event e in events) {
//        int nodeCount = e.json['nodeCount'];
//        ByteData data = e.json['_data'];
//        print('  $nodeCount nodes, ${data.lengthInBytes ~/ 1024}k data');
//      }
//    }).whenComplete(() {
//      print('done');
//      loadSnapshotButton.disabled = false;
//      progressElement.display = 'none';
//    });
//  }

  CoreElement createLiveChartArea() {
    CoreElement container = div(c: 'section perf-chart table-border')
      ..layoutVertical();
    memoryChart = new MemoryChart(container);
    memoryChart.disabled = true;
    return container;
  }

  CoreElement _createTableView() {
    memoryTable = new Table<ClassHeapStats>();

    memoryTable.addColumn(new MemoryColumnSize());
    memoryTable.addColumn(new MemoryColumnInstanceCount());
    memoryTable.addColumn(new MemoryColumnClassName());

    memoryTable.setSortColumn(memoryTable.columns.first);

    // new List<MemoryRow>.generate(100, (_) => MemoryRow.random()
    memoryTable.setRows([]);

    memoryTable.onSelect.listen((ClassHeapStats row) {
      // TODO:
      print(row);
    });

    return memoryTable.element;
  }

  HelpInfo get helpInfo =>
      new HelpInfo('memory view docs', 'http://www.cheese.com');

  void _handleConnectionStart(VmService service) {
    memoryChart.disabled = false;

    memoryTracker = new MemoryTracker(service);
    memoryTracker.start();

    memoryTracker.onChange.listen((_) {
      memoryChartStateMixin.setState(() {
        memoryChart.updateFrom(memoryTracker);
      });
    });
  }

  void _handleConnectionStop(dynamic event) {
    memoryChart.disabled = true;

    memoryTracker?.stop();
  }
}

class MemoryRow {
//  static MemoryRow random() {
//    return new MemoryRow(
//        getLoremFragment(), r.nextInt(4 * 1024 * 1024), r.nextDouble());
//  }

  final String name;
  final int bytes;
  final double percentage;

  MemoryRow(this.name, this.bytes, this.percentage);

  String toString() => name;
}

class MemoryColumnClassName extends Column<ClassHeapStats> {
  MemoryColumnClassName() : super('Class', wide: true);

  dynamic getValue(ClassHeapStats row) => row.classRef.name;
}

class MemoryColumnSize extends Column<ClassHeapStats> {
  MemoryColumnSize() : super('Size');

  bool get numeric => true;

  //String get cssClass => 'monospace';

  dynamic getValue(ClassHeapStats row) => row.bytesCurrent;

  String render(dynamic value) {
    if (value < 1024) {
      return ' ${Column.fastIntl(value)}';
    } else {
      return ' ${Column.fastIntl(value ~/ 1024)}k';
    }
  }
}

class MemoryColumnInstanceCount extends Column<ClassHeapStats> {
  MemoryColumnInstanceCount() : super('Count');

  bool get numeric => true;

  //String get cssClass => 'monospace';

  dynamic getValue(ClassHeapStats row) => row.instancesCurrent;

  String render(dynamic value) => Column.fastIntl(value);
}

class MemoryChart extends LineChart<MemoryTracker> {
  CoreElement processLabel;
  CoreElement heapLabel;

  MemoryChart(CoreElement parent) : super(parent) {
    processLabel = parent.add(div(c: 'perf-label'));
    processLabel.element.style.left = '0';

    heapLabel = parent.add(div(c: 'perf-label'));
    heapLabel.element.style.right = '0';
  }

  void update(MemoryTracker tracker) {
    if (tracker.samples.isEmpty || dim == null) {
      // TODO:
      return;
    }

    // display the process usage
    String rss = '${_printMb(tracker.processRss, 0)} MB RSS';
    processLabel.text = rss;

    // display the dart heap usage
    String used = '${_printMb(tracker.currentHeap, 1)} of ${_printMb(
        tracker.heapMax, 1)} MB';
    heapLabel.text = used;

    // re-render the svg

    // Make the y height large enough for the largest sample,
    const int tenMB = 1024 * 1024 * 10;
    int top = (tracker.maxHeapData ~/ tenMB) * tenMB + tenMB;

    int width = MemoryTracker.kMaxGraphTime.inMilliseconds;
    int right = tracker.samples.last.time;

    // TODO: draw dots for GC events?

    chartElement.setInnerHtml('''
<svg viewBox="0 0 ${dim.x} ${dim.y}">
<polyline
    fill="none"
    stroke="#0074d9"
    stroke-width="3"
    points="${createPoints(tracker.samples, top, width, right)}"/>
</svg>
''');
  }

  String createPoints(List<HeapSample> samples, int top, int width, int right) {
    // 0,120 20,60 40,80 60,20
    return samples.map((HeapSample sample) {
      final int x = dim.x - ((right - sample.time) * dim.x ~/ width);
      final int y = dim.y - (sample.bytes * dim.y ~/ top);
      return '${x},${y}';
    }).join(' ');
  }
}

class MemoryTracker {
  static const Duration kMaxGraphTime = const Duration(minutes: 1);
  static const Duration kUpdateDelay = const Duration(seconds: 1);

  VmService service;
  Timer _pollingTimer;
  final StreamController _changeController = new StreamController.broadcast();

  final List<HeapSample> samples = <HeapSample>[];
  final Map<String, List<HeapSpace>> isolateHeaps = <String, List<HeapSpace>>{};
  int heapMax;
  int processRss;

  MemoryTracker(this.service);

  bool get hasConnection => service != null;

  Stream get onChange => _changeController.stream;

  int get currentHeap => samples.last.bytes;

  int get maxHeapData {
    return samples.fold<int>(heapMax,
        (int value, HeapSample sample) => math.max(value, sample.bytes));
  }

  void start() {
    _pollingTimer = new Timer(const Duration(milliseconds: 100), _pollMemory);
    service.onGCEvent.listen(_handleGCEvent);
  }

  void stop() {
    _pollingTimer?.cancel();
    service = null;
  }

  void _handleGCEvent(Event event) {
    //final bool ignore = event.json['reason'] == 'compact';

    final List<HeapSpace> heaps = <HeapSpace>[
      HeapSpace.parse(event.json['new']),
      HeapSpace.parse(event.json['old'])
    ];
    _updateGCEvent(event.isolate.id, heaps);
  }

  Future _pollMemory() async {
    if (!hasConnection) return;

    VM vm = await service.getVM();
    final List<Isolate> isolates =
        await Future.wait(vm.isolates.map((IsolateRef ref) async {
      return await service.getIsolate(ref.id);
    }));
    _update(vm, isolates);

    _pollingTimer = new Timer(kUpdateDelay, _pollMemory);
  }

  // TODO: add a way to pause polling

  void _update(VM vm, List<Isolate> isolates) {
    processRss = vm.json['_currentRSS'];

    isolateHeaps.clear();

    for (Isolate isolate in isolates) {
      List<HeapSpace> heaps = getHeaps(isolate).toList();
      isolateHeaps[isolate.id] = heaps;
    }

    _recalculate();
  }

  void _updateGCEvent(String id, List<HeapSpace> heaps) {
    isolateHeaps[id] = heaps;
    _recalculate(true);
  }

  void _recalculate([bool fromGC = false]) {
    int current = 0;
    int total = 0;

    for (List<HeapSpace> heaps in isolateHeaps.values) {
      current += heaps.fold<int>(
          0, (int i, HeapSpace heap) => i + heap.used + heap.external);
      total += heaps.fold<int>(
          0, (int i, HeapSpace heap) => i + heap.capacity + heap.external);
    }

    heapMax = total;

    int time = new DateTime.now().millisecondsSinceEpoch;
    if (samples.isNotEmpty) {
      time = math.max(time, samples.last.time);
    }

    _addSample(new HeapSample(current, time, fromGC));
  }

  void _addSample(HeapSample sample) {
    if (samples.isEmpty) {
      // Add an initial synthetic sample so the first version of the graph draws some data.
      samples.add(new HeapSample(
          sample.bytes, sample.time - kUpdateDelay.inMilliseconds ~/ 4, false));
    }

    samples.add(sample);

    // delete old samples
    // TODO: Interpolate the left-most point if we remove a sample.
    final int oldestTime =
        (new DateTime.now().subtract(kMaxGraphTime).subtract(kUpdateDelay))
            .millisecondsSinceEpoch;
    samples.retainWhere((HeapSample sample) => sample.time >= oldestTime);

    _changeController.add(null);
  }

  // TODO: fix HeapSpace.parse upstream
  static Iterable<HeapSpace> getHeaps(Isolate isolate) {
    final Map<String, dynamic> heaps = isolate.json['_heaps'];
    return heaps.values.map((dynamic json) => HeapSpace.parse(json));
  }
}

class HeapSample {
  final int bytes;
  final int time;
  final bool isGC;

  HeapSample(this.bytes, this.time, this.isGC);
}

String _printMb(num bytes, int fractionDigits) =>
    (bytes / (1024 * 1024)).toStringAsFixed(fractionDigits);

// {
//   type: ClassHeapStats,
//   class: {type: @Class, fixedId: true, id: classes/5, name: Class},
//   new: [0, 0, 0, 0, 0, 0, 0, 0],
//   old: [3892, 809536, 3892, 809536, 0, 0, 0, 0],
//   promotedInstances: 0,
//   promotedBytes: 0
// }
class ClassHeapStats {
  static const ALLOCATED_BEFORE_GC = 0;
  static const ALLOCATED_BEFORE_GC_SIZE = 1;
  static const LIVE_AFTER_GC = 2;
  static const LIVE_AFTER_GC_SIZE = 3;
  static const ALLOCATED_SINCE_GC = 4;
  static const ALLOCATED_SINCE_GC_SIZE = 5;
  static const ACCUMULATED = 6;
  static const ACCUMULATED_SIZE = 7;

  final Map json;

  int instancesCurrent = 0;
  int instancesAccumulated = 0;
  int bytesCurrent = 0;
  int bytesAccumulated = 0;

  ClassRef classRef;

  ClassHeapStats(this.json) {
    classRef = ClassRef.parse(json['class']);
    _update(json['new']);
    _update(json['old']);
  }

  String get type => json['type'];

  void _update(List stats) {
    instancesAccumulated += stats[ACCUMULATED];
    bytesAccumulated += stats[ACCUMULATED_SIZE];
    instancesCurrent += stats[LIVE_AFTER_GC] + stats[ALLOCATED_SINCE_GC];
    bytesCurrent += stats[LIVE_AFTER_GC_SIZE] + stats[ALLOCATED_SINCE_GC_SIZE];
  }

  String toString() => '[ClassHeapStats type: ${type}, class: ${classRef
      .name}, count: $instancesCurrent, bytes: $bytesCurrent]';
}
