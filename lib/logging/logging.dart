// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../framework/framework.dart';
import '../tables.dart';
import '../ui/elements.dart';
import '../ui/primer.dart';
import '../utils.dart';

// TODO: log() calls

// TODO: stdout

// TODO: inspect calls

// TODO: flutter frame events

// TODO: GCs

// TODO: filtering, and enabling additional logging

// TODO: cap the number of displayed items to n

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
      div(c: 'section')
        ..add([
          form()
            ..layoutHorizontal()
            ..add([
              div()..flex(),
              new PButton('Add new log items')
                ..small()
                ..click(_addMoreRows),
            ])
        ]),
      _createTableView()..clazz('section'),
    ]);
  }

  CoreElement _createTableView() {
    memoryTable = new Table<LogData>();

    // TODO: no sorting
    memoryTable.addColumn(new LogKindColumn());
    memoryTable.addColumn(new LogWhenColumn());
    memoryTable.addColumn(new LogMessageColumn());

    memoryTable
        .setRows(new List<LogData>.generate(100, (_) => LogData.random()));

    _updateStatus();

    return memoryTable.element;
  }

  void _addMoreRows() {
    // TODO: the table should support adding new items, or streaming items
    List<LogData> data =
        new List<LogData>.generate(r.nextInt(20), (_) => LogData.random());
    data.addAll(memoryTable.rows);
    memoryTable.setRows(data);

    _updateStatus();
  }

  void _updateStatus() {
    int count = memoryTable.rows.length;
    logCountStatus.element.text = '${nf.format(count)} items';
  }

  HelpInfo get helpInfo =>
      new HelpInfo('logging & events', 'http://www.cheese.com');
}

class LogData {
  final String kind;
  final String message;
  final dynamic when;

  LogData(this.kind, this.message, this.when);

  static final List<String> kindNames = ['stdout', 'stderr', 'frame', 'gc'];

  static LogData random() {
    return new LogData(kindNames[r.nextInt(kindNames.length)],
        getLoremFragment(r.nextInt(24) + 1), r.nextInt(4 * 10 * 1024));
  }
}

class LogKindColumn extends Column<LogData> {
  LogKindColumn() : super('Kind');

  bool get supportsSorting => false;

  dynamic getValue(LogData log) => log.kind;
}

class LogWhenColumn extends Column<LogData> {
  LogWhenColumn() : super('When');

  bool get numeric => true;

  bool get supportsSorting => false;

  // TODO: format
  dynamic getValue(LogData log) => log.when;
}

class LogMessageColumn extends Column<LogData> {
  LogMessageColumn() : super('Message', wide: true);

  bool get supportsSorting => false;

  dynamic getValue(LogData log) => log.message;
}
