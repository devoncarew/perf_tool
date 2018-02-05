// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:intl/intl.dart';
import 'package:vm_service_lib/vm_service_lib.dart';

import '../framework/framework.dart';
import '../globals.dart';
import '../tables.dart';
import '../ui/elements.dart';
import '../utils.dart';

// TODO: inspect calls
// TODO: filtering, and enabling additional logging
// TODO: cap the number of displayed items to n
// TODO: a more efficient table

class LoggingScreen extends Screen {
  Framework framework;
  Table<LogData> memoryTable;
  StatusItem logCountStatus;

  LoggingScreen() : super('Logging', 'logging', 'octicon-clippy') {
    logCountStatus = new StatusItem();
    logCountStatus.element.text = ' - ';
    addStatusItem(logCountStatus);
  }

  @override
  void createContent(Framework framework, CoreElement mainDiv) {
    this.framework = framework;

    mainDiv.add([
      // div(c: 'section')
      //   ..add([
      //     form()
      //       ..layoutHorizontal()
      //       ..add([
      //         div()..flex(),
      //         new PButton('Add new log items')
      //           ..small()
      //           ..click(_addMoreRows),
      //       ])
      //   ]),
      _createTableView()..clazz('section'),
    ]);

    // TODO: we need an event when the vm is connected and ready
    _startLogging();
  }

  CoreElement _createTableView() {
    memoryTable = new Table<LogData>();

    memoryTable.addColumn(new LogWhenColumn());
    memoryTable.addColumn(new LogKindColumn());
    memoryTable.addColumn(new LogMessageColumn());

    memoryTable.setRows([]);

    _updateStatus();

    return memoryTable.element;
  }

  void _updateStatus() {
    int count = memoryTable.rows.length;
    logCountStatus.element.text = '${nf.format(count)} items';
  }

  HelpInfo get helpInfo =>
      new HelpInfo('logging & events docs', 'http://www.cheese.com');

  void _startLogging() {
    if (ref == null) return;

    // TODO: inspect, ...

    // Log stdout and stderr events.
    serviceInfo.service.onStdoutEvent.listen((Event e) {
      String message = decodeBase64(e.bytes);
      // TODO: Have the UI provide a way to show untruncated data.
      if (message.length > 500) {
        message = message.substring(0, 500) + '…';
      }
      _log(new LogData('stdout', message, e.timestamp));
    });
    serviceInfo.service.onStderrEvent.listen((Event e) {
      String message = decodeBase64(e.bytes);
      _log(new LogData('stderr', message, e.timestamp));
    });

    // Log GC events.
    serviceInfo.service.onGCEvent.listen((Event e) {
      dynamic json = e.json;
      String message = 'gc reason: ${json['reason']}\n'
          'new: ${json['new']}\n'
          'old: ${json['old']}\n';
      _log(new LogData('gc', message, e.timestamp));
    });

    // Log `dart:developer` `log` events.
    serviceInfo.service.onEvent('_Logging').listen((Event e) {
      dynamic logRecord = e.json['logRecord'];

      String loggerName = _valueAsString(logRecord['loggerName']);
      if (loggerName == null || loggerName.isEmpty) {
        loggerName = 'log';
      }
      // TODO: show level, with some indication of severity
      // int level = logRecord['level'];
      String message = _valueAsString(logRecord['message']);
      // TODO: The VM is not sending the error correctly.
      var error = logRecord['error'];
      var stackTrace = logRecord['stackTrace'];

      if (_isNotNull(error)) {
        message = message + '\nerror: ${_valueAsString(error)}';
      }
      if (_isNotNull(stackTrace)) {
        message = message + '\n${_valueAsString(stackTrace)}';
      }

      _log(new LogData(loggerName, message, e.timestamp));
    });

    // Log Flutter frame events.
    serviceInfo.service.onExtensionEvent.listen((Event e) {
      if (e.extensionKind == 'Flutter.Frame') {
        ExtensionData data = e.extensionData;
        print(data);
        int number = data.data['number'];
        int elapsedMicros = data.data['elapsed'];

        // TODO: Show a horizontal bar propertional to the render time.

        _log(new LogData(
          '${e.extensionKind.toLowerCase()}',
          '#$number render time ${(elapsedMicros / 1000.0)
              .toStringAsFixed(1)
              .padLeft(4)}ms',
          e.timestamp,
        ));
      } else {
        _log(new LogData('${e.extensionKind.toLowerCase()}', e.json.toString(),
            e.timestamp));
      }
    });
  }

  void _log(LogData log) {
    // TODO: make this much more efficient
    List<LogData> data = [log];
    data.addAll(memoryTable.rows);
    memoryTable.setRows(data);

    _updateStatus();
  }
}

bool _isNotNull(dynamic serviceRef) {
  return serviceRef != null && serviceRef['kind'] != 'Null';
}

String _valueAsString(dynamic serviceRef) {
  return serviceRef == null ? null : serviceRef['valueAsString'];
}

class LogData {
  final String kind;
  final String message;
  final int timestamp;

  LogData(this.kind, this.message, this.timestamp);
}

class LogKindColumn extends Column<LogData> {
  LogKindColumn() : super('Kind');

  bool get supportsSorting => false;

  bool get usesHtml => true;

  String get cssClass => 'right';

  dynamic getValue(LogData log) {
    String color = '';

    if (log.kind.startsWith('flutter')) {
      color = ' style="background-color: #0091ea"';
    } else if (log.kind == 'stdout') {
      color = ' style="background-color: #78909C"';
    } else if (log.kind == 'stderr') {
      color = ' style="background-color: #F44336"';
    } else if (log.kind == 'gc') {
      color = ' style="background-color: #424242"';
    }

    return '<span class="label"$color>${log.kind}</span>';
  }

  String render(dynamic value) => value;
}

class LogWhenColumn extends Column<LogData> {
  static DateFormat timeFormat = new DateFormat("HH:mm:ss SSS'ms'");

  LogWhenColumn() : super('When');

  String get cssClass => 'pre monospace';

  bool get supportsSorting => false;

  dynamic getValue(LogData log) => log.timestamp;

  String render(dynamic value) {
    return timeFormat.format(new DateTime.fromMillisecondsSinceEpoch(value));
  }
}

class LogMessageColumn extends Column<LogData> {
  LogMessageColumn() : super('Message', wide: true);

  String get cssClass => 'pre-wrap monospace';

  bool get supportsSorting => false;

  dynamic getValue(LogData log) => log.message;
}
