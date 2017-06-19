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

class ServiceInfo {
  StreamController _stateController = new StreamController.broadcast();

  VmService service;
  String targetCpu;
  String hostCPU;
  String sdkVersion;
  List<IsolateRef> isolateRefs;

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
      isolateRefs = vm.isolates;

      print(vm.hostCPU);
      print(vm.version);

      // TODO: listen for isolate changes - fire events

      this.service = _service;

      _stateController.add(null);

      onClosed.then((_) => vmServiceClosed());

      // TODO:
      service.streamListen('VM');
      service.streamListen('Isolate');
      service.streamListen('Debug');
      service.streamListen('GC');
      service.streamListen('Timeline');
      service.streamListen('_Graph');

      service.onGCEvent.listen((Event event) => print(event.json));
      service.onIsolateEvent.listen(print);

      //service.getIsolate(isolateRefs.last.id).then((Isolate isolate) {
      //  print(isolate);
      //});

      //service.collectAllGarbage(isolateRefs.first.id).then(print);
      //service.collectAllGarbage(isolateRefs.last.id).then(print);

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
