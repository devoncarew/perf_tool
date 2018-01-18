// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:html' hide Event;
import 'dart:typed_data';

import 'package:vm_service_lib/vm_service_lib.dart';

Future<VmService> connect(String host, int port, Completer finishedCompleter) {
  WebSocket ws = new WebSocket('ws://${host}:${port}/ws');

  Completer<VmService> connectedCompleter = new Completer();

  ws.onOpen.listen((_) {
    VmService service = new VmService(
      ws.onMessage.asyncMap((MessageEvent e) {
        if (e.data is String) return e.data as String;

        final FileReader fileReader = new FileReader();
        fileReader.readAsArrayBuffer(e.data as Blob);
        return fileReader.onLoadEnd.first.then((_) {
          return new ByteData.view((fileReader.result as Uint8List).buffer);
        });
      }),
      (String message) => ws.send(message),
    );

    ws.onClose.listen((_) {
      finishedCompleter.complete();
      service.dispose();
    });

    connectedCompleter.complete(service);
  });

  ws.onError.listen((e) {
    //_logger.fine('Unable to connect to observatory, port ${port}', e);
    if (!connectedCompleter.isCompleted) connectedCompleter.completeError(e);
  });

  return connectedCompleter.future;
}

class ServiceConnectionManager {
  final StreamController _stateController = new StreamController.broadcast();
  final IsolateManager isolateManager = new IsolateManager();

  VmService service;
  String targetCpu;
  String hostCPU;
  String sdkVersion;

  Stream get onStateChange => _stateController.stream;

  void vmServiceOpened(VmService _service, Future onClosed) {
    //_service.onSend.listen((s) => print('==> $s'));
    //_service.onReceive.listen((s) => print('<== $s'));

    _service.getVM().then((VM vm) {
      targetCpu = vm.targetCPU;
      hostCPU = vm.hostCPU;
      sdkVersion = vm.version;
      if (sdkVersion.contains(' ')) {
        sdkVersion = sdkVersion.substring(0, sdkVersion.indexOf(' '));
      }
      isolateManager.updateLiveIsolates(vm.isolates);

      //for (IsolateRef ref in vm.isolates) {
      //  _service.getIsolate(ref.id).then((Isolate isolate) {
      //    print(isolate.extensionRPCs);
      //  });
      //}

      print(vm.hostCPU);
      print(vm.version);

      // TODO: listen for isolate changes - fire events

      this.service = _service;

      _stateController.add(null);

      onClosed.then((_) => vmServiceClosed());

      service.streamListen('Stdout');
      service.streamListen('Stderr');
      service.streamListen('VM');
      service.streamListen('Isolate');
      service.streamListen('Debug');
      service.streamListen('GC');
      service.streamListen('Timeline');
      service.streamListen('Extension');
      service.streamListen('_Graph');
      service.streamListen('_Logging');

      service.onGCEvent.listen((Event event) => print(event.json));
      service.onIsolateEvent.listen(print);
      service.onEvent('Timeline').listen(print);

      service.onExtensionEvent.listen((Event e) {
        if (e.extensionKind == 'Flutter.Frame') {
          ExtensionData data = e.extensionData;

          // {number: 185, startTime: 12942276949, elapsed: 18503}
          int number = data.data['number'];
          int elapsedMicros = data.data['elapsed'];

          print('[frame $number] ${(elapsedMicros / 1000.0)
              .toStringAsFixed(1)
              .padLeft(4)}ms');
        }
      });

      //service.getIsolate(isolateRefs.last.id).then((Isolate isolate) {
      //  print(isolate);
      //});

      //service
      //    .requestHeapSnapshot(isolateRefs.last.id, 'User', true)
      //    .then(print)
      //    .catchError(print);

      //service
      //    .getCpuProfile(isolateRefs.last.id, 'VMUser')
      //    .then((CpuProfile response) {
      //  print(response);
      //});
    }).catchError((e) {
      // TODO:
      print(e);
    });
  }

  void vmServiceClosed() {
    print('service connection closed');

    service = null;
    targetCpu = null;
    hostCPU = null;
    sdkVersion = null;

    _stateController.add(null);
  }
}

class IsolateManager {
  List<IsolateRef> _isolates = [];
  IsolateRef _selectedIsolate;

  final StreamController<List<IsolateRef>> _isolatesChangedController =
      new StreamController.broadcast();
  final StreamController<IsolateRef> _selectedIsolateController =
      new StreamController.broadcast();

  // TODO: immutable
  List<IsolateRef> get isolates => new List.from(_isolates);

  IsolateRef get selectedIsolate => _selectedIsolate;

  void selectIsolate(String isolateRefId) {
    IsolateRef ref =
        _isolates.firstWhere((r) => r.id == isolateRefId, orElse: () => null);
    if (ref != _selectedIsolate) {
      _selectedIsolate = ref;
      _selectedIsolateController.add(_selectedIsolate);
    }
  }

  Stream<List<IsolateRef>> get onIsolatesChanged =>
      _isolatesChangedController.stream;

  Stream<IsolateRef> get onSelectedIsolateChanged =>
      _selectedIsolateController.stream;

  void updateLiveIsolates(List<IsolateRef> isolates) {
    // TODO: update these better
    _isolates = isolates;
    _isolatesChangedController.add(_isolates);

    if (_selectedIsolate == null && isolates.isNotEmpty) {
      _selectedIsolate = isolates
          .firstWhere((ref) => ref.name.contains('main('), orElse: () => null);
      if (_selectedIsolate == null) {
        _selectedIsolate = isolates.first;
      }
      _selectedIsolateController.add(_selectedIsolate);
    } else if (!isolates.contains(_selectedIsolateController)) {
      // TODO: select a better next isolate
      _selectedIsolate = isolates.isNotEmpty ? isolates.first : null;
      _selectedIsolateController.add(_selectedIsolate);
    }
  }
}
