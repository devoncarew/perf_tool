// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:vm_service_lib/vm_service_lib.dart';

import '../framework/framework.dart';
import '../globals.dart';
import '../tables.dart';
import '../timeline/fps.dart';
import '../ui/elements.dart';
import '../utils.dart';

// TODO: inspect calls

// TODO: filtering, and enabling additional logging

// TODO: a more efficient table; we need to virtualize it

// TODO: don't update DOM when we're not active; update once we return

const int kMaxLogItemsLength = 40;

class LoggingScreen extends Screen {
  Framework framework;
  Table<LogData> loggingTable;
  StatusItem logCountStatus;
  SetStateMixin loggingStateMixin = new SetStateMixin();

  LoggingScreen() : super('Logs', 'logs', 'octicon-clippy') {
    logCountStatus = new StatusItem();
    logCountStatus.element.text = '';
    addStatusItem(logCountStatus);
  }

  @override
  void createContent(Framework framework, CoreElement mainDiv) {
    this.framework = framework;

    mainDiv.add([
      _createTableView()..clazz('section'),
    ]);

    serviceInfo.onConnectionAvailable.listen(_handleConnectionStart);
    if (serviceInfo.hasConnection) {
      _handleConnectionStart(serviceInfo.service);
    }
    serviceInfo.onConnectionClosed.listen(_handleConnectionStop);
  }

  CoreElement _createTableView() {
    loggingTable = new Table<LogData>();

    loggingTable.addColumn(new LogWhenColumn());
    loggingTable.addColumn(new LogKindColumn());
    loggingTable.addColumn(new LogMessageColumn());

    loggingTable.setRows([]);

    _updateStatus();

    return loggingTable.element;
  }

  void _updateStatus() {
    int count = loggingTable.rows.length;
    logCountStatus.element.text = '${nf.format(count)} events';
  }

  HelpInfo get helpInfo =>
      new HelpInfo('logs view docs', 'http://www.cheese.com');

  void _handleConnectionStart(VmService service) {
    if (ref == null) return;

    // TODO: inspect, ...

    // Log stdout and stderr events.
    service.onStdoutEvent.listen((Event e) {
      String message = decodeBase64(e.bytes);
      // TODO: Have the UI provide a way to show untruncated data.
      if (message.length > 500) {
        message = message.substring(0, 500) + '…';
      }
      _log(new LogData('stdout', message, e.timestamp));
    });
    service.onStderrEvent.listen((Event e) {
      String message = decodeBase64(e.bytes);
      _log(new LogData('stderr', message, e.timestamp, error: true));
    });

    // Log GC events.
    service.onGCEvent.listen((Event e) {
      dynamic json = e.json;
      String message = 'gc reason: ${json['reason']}\n'
          'new: ${json['new']}\n'
          'old: ${json['old']}\n';
      _log(new LogData('gc', message, e.timestamp));
    });

    // Log `dart:developer` `log` events.
    service.onEvent('_Logging').listen((Event e) {
      dynamic logRecord = e.json['logRecord'];

      String loggerName = _valueAsString(logRecord['loggerName']);
      if (loggerName == null || loggerName.isEmpty) {
        loggerName = 'log';
      }
      // TODO: show level, with some indication of severity
      int level = logRecord['level'];
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

      bool isError =
          level != null && level >= Level.SEVERE.value ? true : false;
      _log(new LogData(loggerName, message, e.timestamp, error: isError));
    });

    // Log Flutter frame events.
    service.onExtensionEvent.listen((Event e) {
      if (e.extensionKind == 'Flutter.Frame') {
        FrameInfo frame = FrameInfo.from(e.extensionData.data);

        String div = createFrameDivHtml(frame);

        _log(new LogData(
          '${e.extensionKind.toLowerCase()}',
          'frame ${frame.number} ${frame.elapsedMs
              .toStringAsFixed(1)
              .padLeft(4)}ms',
          e.timestamp,
          extraHtml: div,
        ));
      } else {
        _log(new LogData('${e.extensionKind.toLowerCase()}', e.json.toString(),
            e.timestamp));
      }
    });
  }

  void _handleConnectionStop(dynamic event) {}

  void _log(LogData log) {
    // TODO: make this much more efficient
    List<LogData> data = [log];
    data.addAll(loggingTable.rows);

    if (data.length > kMaxLogItemsLength) {
      data.removeRange(kMaxLogItemsLength, data.length);
    }

    loggingStateMixin.setState(() {
      loggingTable.setRows(data);
      _updateStatus();
    });
  }

  String createFrameDivHtml(FrameInfo frame) {
    String classes = (frame.elapsedMs >= FrameInfo.kTargetMaxFrameTimeMs)
        ? 'frame-bar over-budget'
        : 'frame-bar';

    int pixelWidth = (frame.elapsedMs * 3).round();
    return '<div class="$classes" style="width: ${pixelWidth}px"/>';
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
  final bool error;
  final String extraHtml;

  LogData(this.kind, this.message, this.timestamp,
      {this.error: false, this.extraHtml});
}

class LogKindColumn extends Column<LogData> {
  LogKindColumn() : super('Kind');

  bool get supportsSorting => false;

  bool get usesHtml => true;

  String get cssClass => 'right';

  dynamic getValue(LogData log) {
    String color = '';

    if (log.kind == 'stderr' || log.error) {
      color = 'style="background-color: #F44336"';
    } else if (log.kind == 'stdout') {
      color = 'style="background-color: #78909C"';
    } else if (log.kind.startsWith('flutter')) {
      color = 'style="background-color: #0091ea"';
    } else if (log.kind == 'gc') {
      color = 'style="background-color: #424242"';
    }

    return '<span class="label" $color>${log.kind}</span>';
  }

  String render(dynamic value) => value;
}

class LogWhenColumn extends Column<LogData> {
  static DateFormat timeFormat = new DateFormat("HH:mm:ss.SSS");

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

  bool get usesHtml => true;

  bool get supportsSorting => false;

  dynamic getValue(LogData log) => log;

  String render(dynamic value) {
    final LogData log = value;

    if (log.extraHtml != null) {
      return '${log.message} ${log.extraHtml}';
    } else {
      return log.message; // TODO: escape html
    }
  }
}
