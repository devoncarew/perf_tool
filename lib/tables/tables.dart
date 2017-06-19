// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';

import '../ui/elements.dart';
import '../utils.dart';

// TODO: selection

class Table<T> {
  final CoreElement element;

  List<Column<T>> columns = [];
  List<T> rows;

  Column<T> _sortColumn;
  SortOrder _sortDirection;

  CoreElement _table;
  CoreElement _thead;
  CoreElement _tbody;

  Map<Column, CoreElement> spanForColumn = {};

  Table() : element = div(a: 'flex', c: 'overflow-auto table-border') {
    _table = new CoreElement('table')..clazz('full-width');
    element.add(_table);
  }

  void addColumn(Column<T> column) {
    columns.add(column);
  }

  void setRows(List<T> rows) {
    this.rows = rows.toList();

    if (_thead == null) {
      _thead = new CoreElement('thead')
        ..add(tr()
          ..add(columns.map((Column column) {
            CoreElement s =
                span(text: column.title, c: 'interactable sortable');
            s.click(() => _columnClicked(column));
            spanForColumn[column] = s;
            return th(c: column.numeric ? 'right' : 'left')..add(s);
          })));

      _table.add(_thead);
    }

    if (_tbody == null) {
      _tbody = new CoreElement('tbody');
      _table.add(_tbody);
    }

    if (_sortColumn == null) {
      setSortColumn(columns.first);
    }

    _doSort();
    _rebuildTable();
  }

  void _doSort() {
    Column<T> column = _sortColumn;
    bool numeric = column.numeric;
    int direction = _sortDirection == SortOrder.ascending ? 1 : -1;

    // update the sort arrows
    for (Column c in columns) {
      CoreElement s = spanForColumn[c];
      if (c == _sortColumn) {
        s.toggleClass('up', _sortDirection == SortOrder.ascending);
        s.toggleClass('down', _sortDirection != SortOrder.ascending);
      } else {
        s.toggleClass('up', false);
        s.toggleClass('down', false);
      }
    }

    rows.sort((T a, T b) {
      if (numeric) {
        num one = column.getValue(a);
        num two = column.getValue(b);
        if (one == two) return 0;
        if (_sortDirection == SortOrder.ascending) {
          return one > two ? 1 : -1;
        } else {
          return one > two ? -1 : 1;
        }
      } else {
        String one = column.render(column.getValue(a));
        String two = column.render(column.getValue(b));
        return one.compareTo(two) * direction;
      }
    });
  }

  void _rebuildTable() {
    // Re-build the table.
    List<Element> rowElements = [];

    for (T row in rows) {
      CoreElement tableRow = tr();

      for (Column column in columns) {
        tableRow.add(td(
          text: column.render(column.getValue(row)),
          c: column.numeric ? 'right' : null,
        ));
      }

      rowElements.add(tableRow.element);
    }

    _tbody.clear();
    _tbody.element.children.addAll(rowElements);
  }

  void setSortColumn(Column<T> column) {
    _sortColumn = column;
    _sortDirection =
        column.numeric ? SortOrder.descending : SortOrder.ascending;
  }

  void _columnClicked(Column<T> column) {
    if (_sortColumn == column) {
      _sortDirection = _sortDirection == SortOrder.ascending
          ? SortOrder.descending
          : SortOrder.ascending;
    } else {
      setSortColumn(column);
    }

    _doSort();
    _rebuildTable();
  }
}

abstract class Column<T> {
  final String title;

  Column(this.title);

  bool get numeric => false;

  dynamic getValue(T row);

  String render(dynamic value) {
    if (numeric) {
      if (value is int && value < 1000) {
        return value.toString();
      } else {
        return nf.format(value);
      }
    }
    return value.toString();
  }

  String toString() => title;
}

enum SortOrder {
  ascending,
  descending,
}
