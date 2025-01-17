import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:queue/queue.dart';
import '../ALDownloaderHandlerInterface.dart';
import '../ALDownloaderStatus.dart';
import '../ALDownloaderTask.dart';
import '../ALDownloaderTypeDefine.dart';
import '../chore/ALDownloaderFile.dart';
import '../internal/ALDownloaderConstant.dart';
import '../internal/ALDownloaderFileManagerDefault.dart';
import '../internal/ALDownloaderHeader.dart';
import '../internal/ALDownloaderInnerStatus.dart';
import '../internal/ALDownloaderInnerTask.dart';
import '../internal/ALDownloaderIsolateLauncher.dart';
import '../internal/ALDownloaderMapExtension.dart';
import '../internal/ALDownloaderMessage.dart';
import '../internal/ALDownloaderPrint.dart';
import '../internal/ALDownloaderPrintConfig.dart';
import '../internal/ALDownloaderStringExtension.dart';
import '../internal/ALDownloaderTaskWaitingPhase.dart';
import 'ALDownloaderFileManagerIMP.dart';

abstract class ALDownloaderIMP {
  static void initialize() {
    if (!_isInitialized) {
      _isInitialized = true;
      _launchALIsolate();
    }
  }

  static void configurePrint(bool enabled, {bool frequentEnabled = false}) {
    ALDownloaderPrintConfig.enabled = enabled;
    ALDownloaderPrintConfig.frequentEnabled = frequentEnabled;

    final message = ALDownloaderMessage();
    message.scope = ALDownloaderConstant.kALDownloaderIMP;
    message.action = ALDownloaderConstant.kConfigurePrint;
    message.content = <String, dynamic>{
      ALDownloaderConstant.kEnabled: enabled,
      ALDownloaderConstant.kFrequentEnabled: frequentEnabled
    };

    ALDownloaderHeader.sendMessageFromRootToALReliably(message);
  }

  static ALDownloaderHandlerInterfaceId? download(String url,
      {String? directoryPath,
      String? fileName,
      Map<String, String>? headers,
      bool redownloadIfNeeded = false,
      ALDownloaderHandlerInterface? handlerInterface}) {
    final message = ALDownloaderMessage();
    message.scope = ALDownloaderConstant.kALDownloaderIMP;
    message.action = ALDownloaderConstant.kDownload;
    message.content = <String, dynamic>{
      ALDownloaderConstant.kUrl: url,
      ALDownloaderConstant.kDirectoryPath: directoryPath,
      ALDownloaderConstant.kFileName: fileName,
      ALDownloaderConstant.kHeaders: headers,
      ALDownloaderConstant.kRedownloadIfNeeded: redownloadIfNeeded,
    };

    ALDownloaderHandlerInterfaceId? id;
    if (handlerInterface != null) {
      id = ALDownloaderHeader.uuid.v1();
      _idDynamicKVs[id] = handlerInterface;
      message.content[ALDownloaderConstant.kHandlerInterfaceId] = id;
    }

    ALDownloaderHeader.sendMessageFromRootToALReliably(message);

    return id;
  }

  static ALDownloaderHandlerInterfaceId addHandlerInterface(
      ALDownloaderHandlerInterface handlerInterface, String url) {
    final message = ALDownloaderMessage();
    message.scope = ALDownloaderConstant.kALDownloaderIMP;
    message.action = ALDownloaderConstant.kAddHandlerInterface;
    message.content = <String, dynamic>{ALDownloaderConstant.kUrl: url};

    final id = ALDownloaderHeader.uuid.v1();
    _idDynamicKVs[id] = handlerInterface;
    message.content[ALDownloaderConstant.kHandlerInterfaceId] = id;

    ALDownloaderHeader.sendMessageFromRootToALReliably(message);

    return id;
  }

  static ALDownloaderHandlerInterfaceId addForeverHandlerInterface(
      ALDownloaderHandlerInterface handlerInterface, String url) {
    final message = ALDownloaderMessage();
    message.scope = ALDownloaderConstant.kALDownloaderIMP;
    message.action = ALDownloaderConstant.kAddForeverHandlerInterface;
    message.content = <String, dynamic>{ALDownloaderConstant.kUrl: url};

    final id = ALDownloaderHeader.uuid.v1();
    _idDynamicKVs[id] = handlerInterface;
    message.content[ALDownloaderConstant.kHandlerInterfaceId] = id;

    ALDownloaderHeader.sendMessageFromRootToALReliably(message);

    return id;
  }

  static void removeHandlerInterfaceForUrl(String url) {
    final message = ALDownloaderMessage();
    message.scope = ALDownloaderConstant.kALDownloaderIMP;
    message.action = ALDownloaderConstant.kRemoveHandlerInterfaceForUrl;
    message.content = {ALDownloaderConstant.kUrl: url};

    ALDownloaderHeader.sendMessageFromRootToALReliably(message);
  }

  static void removeHandlerInterfaceForId(ALDownloaderHandlerInterfaceId id) {
    final message = ALDownloaderMessage();
    message.scope = ALDownloaderConstant.kALDownloaderIMP;
    message.action = ALDownloaderConstant.kRemoveHandlerInterfaceForId;
    message.content = {ALDownloaderConstant.kHandlerInterfaceId: id};

    ALDownloaderHeader.sendMessageFromRootToALReliably(message);
  }

  static void removeHandlerInterfaceForAll() {
    final message = ALDownloaderMessage();
    message.scope = ALDownloaderConstant.kALDownloaderIMP;
    message.action = ALDownloaderConstant.kRemoveHandlerInterfaceForAll;

    ALDownloaderHeader.sendMessageFromRootToALReliably(message);
  }

  static void pause(String url) {
    final message = ALDownloaderMessage();
    message.scope = ALDownloaderConstant.kALDownloaderIMP;
    message.action = ALDownloaderConstant.kPause;
    message.content = {ALDownloaderConstant.kUrl: url};

    ALDownloaderHeader.sendMessageFromRootToALReliably(message);
  }

  static void pauseAll() {
    final message = ALDownloaderMessage();
    message.scope = ALDownloaderConstant.kALDownloaderIMP;
    message.action = ALDownloaderConstant.kPauseAll;

    ALDownloaderHeader.sendMessageFromRootToALReliably(message);
  }

  static void cancel(String url) {
    final message = ALDownloaderMessage();
    message.scope = ALDownloaderConstant.kALDownloaderIMP;
    message.action = ALDownloaderConstant.kCancel;
    message.content = {ALDownloaderConstant.kUrl: url};

    ALDownloaderHeader.sendMessageFromRootToALReliably(message);
  }

  static void cancelAll() {
    final message = ALDownloaderMessage();
    message.scope = ALDownloaderConstant.kALDownloaderIMP;
    message.action = ALDownloaderConstant.kCancelAll;

    ALDownloaderHeader.sendMessageFromRootToALReliably(message);
  }

  static void remove(String url) {
    final message = ALDownloaderMessage();
    message.scope = ALDownloaderConstant.kALDownloaderIMP;
    message.action = ALDownloaderConstant.kRemove;
    message.content = {ALDownloaderConstant.kUrl: url};

    ALDownloaderHeader.sendMessageFromRootToALReliably(message);
  }

  static void removeAll() {
    final message = ALDownloaderMessage();
    message.scope = ALDownloaderConstant.kALDownloaderIMP;
    message.action = ALDownloaderConstant.kRemoveAll;

    ALDownloaderHeader.sendMessageFromRootToALReliably(message);
  }

  static Future<ALDownloaderStatus> getStatusForUrl(String url) async {
    final message = ALDownloaderMessage();
    message.scope = ALDownloaderConstant.kALDownloaderIMP;
    message.action = ALDownloaderConstant.kGetStatusForUrl;
    message.content = <String, dynamic>{ALDownloaderConstant.kUrl: url};

    final id = ALDownloaderHeader.uuid.v1();

    final aCompleter = Completer<ALDownloaderStatus>();
    _idDynamicKVs[id] =
        (ALDownloaderStatus status) => aCompleter.complete(status);

    message.content[ALDownloaderConstant.kHandlerId] = id;

    ALDownloaderHeader.sendMessageFromRootToALReliably(message);

    return aCompleter.future;
  }

  static Future<double> getProgressForUrl(String url) async {
    final message = ALDownloaderMessage();
    message.scope = ALDownloaderConstant.kALDownloaderIMP;
    message.action = ALDownloaderConstant.kGetProgressForUrl;
    message.content = <String, dynamic>{ALDownloaderConstant.kUrl: url};

    final id = ALDownloaderHeader.uuid.v1();

    final aCompleter = Completer<double>();
    _idDynamicKVs[id] = (double progress) => aCompleter.complete(progress);

    message.content[ALDownloaderConstant.kHandlerId] = id;

    ALDownloaderHeader.sendMessageFromRootToALReliably(message);

    return aCompleter.future;
  }

  static Future<ALDownloaderTask?> getTaskForUrl(String url) async {
    final message = ALDownloaderMessage();
    message.scope = ALDownloaderConstant.kALDownloaderIMP;
    message.action = ALDownloaderConstant.kGetTask;
    message.content = <String, dynamic>{ALDownloaderConstant.kUrl: url};

    final id = ALDownloaderHeader.uuid.v1();

    final aCompleter = Completer<ALDownloaderTask?>();
    _idDynamicKVs[id] = (ALDownloaderTask? task) => aCompleter.complete(task);

    message.content[ALDownloaderConstant.kHandlerId] = id;

    ALDownloaderHeader.sendMessageFromRootToALReliably(message);

    return aCompleter.future;
  }

  static Future<List<ALDownloaderTask>> get tasks async {
    final message = ALDownloaderMessage();
    message.scope = ALDownloaderConstant.kALDownloaderIMP;
    message.action = ALDownloaderConstant.kGetTasks;
    message.content = <String, dynamic>{};

    final id = ALDownloaderHeader.uuid.v1();

    final aCompleter = Completer<List<ALDownloaderTask>>();
    _idDynamicKVs[id] =
        (List<ALDownloaderTask> tasks) => aCompleter.complete(tasks);

    message.content[ALDownloaderConstant.kHandlerId] = id;

    ALDownloaderHeader.sendMessageFromRootToALReliably(message);

    return aCompleter.future;
  }

  static void cDownload(String url,
      {String? directoryPath,
      String? fileName,
      Map<String, String>? headers,
      bool redownloadIfNeeded = false,
      ALDownloaderHandlerInterface? handlerInterface}) {
    String? id;
    if (handlerInterface != null) {
      id = ALDownloaderHeader.uuid.v1();
      _idDynamicKVs[id] = handlerInterface;
    }

    _qDownload(url,
        directoryPath: directoryPath,
        fileName: fileName,
        headers: headers,
        redownloadIfNeeded: redownloadIfNeeded,
        handlerInterfaceId: id);
  }

  static ALDownloaderHandlerInterfaceId cAddHandlerInterface(
      ALDownloaderHandlerInterface handlerInterface, String url) {
    final id = ALDownloaderHeader.uuid.v1();
    _idDynamicKVs[id] = handlerInterface;

    _qAddHandlerInterface(id, url, isInner: false);

    return id;
  }

  static void caddForeverHandlerInterface(
      ALDownloaderHandlerInterface handlerInterface, String url) {
    final id = ALDownloaderHeader.uuid.v1();
    _idDynamicKVs[id] = handlerInterface;
    _qaddForeverHandlerInterface(id, url);
  }

  static void cremoveHandlerInterfaceForUrl(String url) =>
      _qremoveHandlerInterfaceForUrl(url);

  static void cRemoveHandlerInterfaceForId(ALDownloaderHandlerInterfaceId id) =>
      _qRemoveHandlerInterfaceForId(id);

  static void cPause(String url) => _qPause(url);

  static void cPauseAll() => _qPauseAll();

  static void cPauseUrls(List<String> urls) => _qPauseUrls(urls);

  static void cCancel(String url) => _qCancel(url);

  static void cCancelUrls(List<String> urls) => _qCancelUrls(urls);

  static void cCancelAll() => _qCancelAll();

  static void cRemove(String url) => _qRemove(url);

  static void cRemoveUrls(List<String> urls) => _qRemoveUrls(urls);

  static void cRemoveAll() => _qRemoveAll();

  static Future<ALDownloaderStatus> cGetStatusForUrl(String url) =>
      _qGetStatusPurelyForUrl(url);

  static Future<double> cGetProgressForUrl(String url) =>
      _qGetProgressPurelyForUrl(url);

  static Future<ALDownloaderTask?> cGetTaskForUrl(String url) =>
      _qGetTaskPurelyForUrl(url);

  static Future<List<ALDownloaderTask>> cGetTasks() => _qGetTasksPurely();

  static void _launchALIsolate() =>
      ALDownloaderIsolateLauncher.launchALIsolate();

  static void _qInitialize() {
    _queue.add(() async {
      await _initialize();
      ALDownloaderHeader.initializedCompleter.complete();
    });
  }

  static void _qDownload(String url,
      {String? directoryPath,
      String? fileName,
      Map<String, String>? headers,
      bool redownloadIfNeeded = false,
      String? handlerInterfaceId,
      bool isNeedUpdateInputs = true}) {
    _queue.add(() => _download(url,
        directoryPath: directoryPath,
        fileName: fileName,
        headers: headers,
        redownloadIfNeeded: redownloadIfNeeded,
        handlerInterfaceId: handlerInterfaceId,
        isNeedUpdateInputs: isNeedUpdateInputs));
  }

  static void _qAddHandlerInterface(String handlerInterfaceId, String url,
      {bool isInner = true}) {
    _queue.add(() async {
      final aBinder = _ALDownloaderBinder(url, handlerInterfaceId, false);
      aBinder.isInner = isInner;

      _addBinder(url, aBinder);
    });
  }

  static void _qaddForeverHandlerInterface(
      String handlerInterfaceId, String url) {
    _queue.add(() async {
      final aBinder = _ALDownloaderBinder(url, handlerInterfaceId, true);

      _addBinder(url, aBinder);
    });
  }

  static void _qremoveHandlerInterfaceForUrl(String url) {
    _queue.add(() async {
      final binders = _urlBinderKVs[url];
      if (binders == null) return;

      final aList = <_ALDownloaderBinder>[];
      aList.addAll(binders);
      for (final element in aList) {
        if (element.isInner && element.url == url) {
          _callInterface(
              element.handlerInterfaceId, false, false, false, false, 0,
              isNeedRemoveInterface: true);
          binders.remove(element);
        }
      }

      if (binders.length == 0) _urlBinderKVs.remove(url);
    });
  }

  static void _qRemoveHandlerInterfaceForId(ALDownloaderHandlerInterfaceId id) {
    _queue.add(() async {
      final aMap = <String, List<_ALDownloaderBinder>>{};
      aMap.addAll(_urlBinderKVs);
      for (final entry in aMap.entries) {
        final key = entry.key;
        final element = entry.value;

        final aList = <_ALDownloaderBinder>[];
        aList.addAll(element);

        for (final element1 in aList) {
          if (element1.handlerInterfaceId == id) {
            _callInterface(
                element1.handlerInterfaceId, false, false, false, false, 0,
                isNeedRemoveInterface: true);
            element.remove(element1);
            if (element.length == 0) _urlBinderKVs.remove(key);
            return;
          }
        }
      }
    });
  }

  static void _qRemoveHandlerInterfaceForAll() {
    _queue.add(() async {
      final aMap = <String, List<_ALDownloaderBinder>>{};
      aMap.addAll(_urlBinderKVs);
      for (final entry in aMap.entries) {
        final key = entry.key;
        final element = entry.value;

        final aList = <_ALDownloaderBinder>[];
        aList.addAll(element);

        for (final element1 in aList) {
          if (element1.isInner) {
            _callInterface(
                element1.handlerInterfaceId, false, false, false, false, 0,
                isNeedRemoveInterface: true);
            element.remove(element1);
            if (element.length == 0) _urlBinderKVs.remove(key);
          }
        }
      }
    });
  }

  static void _qPause(String url) => _queue.add(() => _pause(url));

  static void _qPauseUrls(List<String> urls) =>
      _queue.add(() => _pauseUrls(urls));

  static void _qPauseAll() => _queue.add(() => _pauseAll());

  static void _qCancel(String url) => _queue.add(() => _cancel(url));

  static void _qCancelUrls(List<String> urls) =>
      _queue.add(() => _cancelUrls(urls));

  static void _qCancelAll() => _queue.add(() => _cancelAll());

  static void _qRemove(String url) => _queue.add(() => _remove(url));

  static void _qRemoveUrls(List<String> urls) =>
      _queue.add(() => _removeUrls(urls));

  static void _qRemoveAll() => _queue.add(() => _removeAll());

  static Future<void> _qGetStatusForUrl(String handlerId, String url) async {
    final status = await _qGetStatusPurelyForUrl(url);
    _processStatusHandlerOnComingRootIsolate(handlerId, status);
  }

  static Future<void> _qGetProgressForUrl(String handlerId, String url) async {
    final progress = await _qGetProgressPurelyForUrl(url);
    _processProgressHandlerOnComingRootIsolate(handlerId, progress);
  }

  static Future<void> _qGetTaskForUrl(String handlerId, String url) async {
    final task = await _qGetTaskPurelyForUrl(url);
    _processTaskHandlerOnComingRootIsolate(handlerId, task);
  }

  static Future<void> _qGetTasks(String handlerId) async {
    final tasks = await _qGetTasksPurely();
    _processTasksHandlerOnComingRootIsolate(handlerId, tasks);
  }

  static Future<void> _initialize() async {
    // Initialize FlutterDownloader.
    await FlutterDownloader.initialize(
      debug: false,
      ignoreSsl: true,
    );

    _registerServiceForCommunicationBetweenFAndAL();

    // Register FlutterDownloader callback.
    await FlutterDownloader.registerCallback(_downloadCallback, step: 1);

    await _loadTasks();
  }

  static Future<void> _download(String url,
      {String? directoryPath,
      String? fileName,
      Map<String, String>? headers,
      bool redownloadIfNeeded = false,
      String? handlerInterfaceId,
      bool isNeedUpdateInputs = true}) async {
    if (handlerInterfaceId != null) {
      final aBinder = _ALDownloaderBinder(url, handlerInterfaceId, false);
      _addBinder(url, aBinder);
    }

    ALDownloaderInnerTask? task = _getTaskFromUrl(url);

    if (task == null)
      task = _addOrUpdateTaskForUrl(url, '', ALDownloaderInnerStatus.prepared,
          0, null, null, ALDownloaderTaskWaitingPhase.unwaiting);

    if (isNeedUpdateInputs &&
        (task.innerStatus == ALDownloaderInnerStatus.prepared ||
            redownloadIfNeeded)) {
      task.willParameters = {
        'headers': headers,
        'directoryPath': directoryPath,
        'fileName': fileName,
        'redownloadIfNeeded': redownloadIfNeeded
      };
    }

    if (_isLimitedForGoingTasks) {
      if (task.innerStatus == ALDownloaderInnerStatus.prepared ||
          task.innerStatus == ALDownloaderInnerStatus.pretendedPaused ||
          task.innerStatus == ALDownloaderInnerStatus.deprecated ||
          task.innerStatus == ALDownloaderInnerStatus.canceled ||
          task.innerStatus == ALDownloaderInnerStatus.failed ||
          task.innerStatus == ALDownloaderInnerStatus.paused) {
        final aBool = _isWaitingTask(task);
        if (!aBool) {
          _waitTask(task);
          _processProgressEventForTask(task);
        }

        aldDebugPrint(
            'ALDownloader | try to download url, going tasks are limited, those will download later, url = $url, taskId = ${task.taskId}, status= ${task.innerStatus}');
        return;
      }
    }

    final willParameters = task.willParameters;
    String? willDirectoryPath = willParameters?['directoryPath'];
    String? willFileName = willParameters?['fileName'];
    final Map<String, String>? willHeaders = willParameters?['headers'];
    final bool redownloadIfNeededInConsumable =
        willParameters?['redownloadIfNeeded'] ?? false;

    if (willDirectoryPath == null || willFileName == null) {
      willDirectoryPath =
          await ALDownloaderFileManagerDefault.getVirtualDirectoryPathForUrl(
              url);
      willFileName = ALDownloaderFileManagerDefault.getFileNameForUrl(url);
    } else {
      if (!willDirectoryPath.endsWith('/'))
        willDirectoryPath = willDirectoryPath + '/';
    }

    if (await _isShouldRemoveData(task, willHeaders, willDirectoryPath,
        willFileName, redownloadIfNeededInConsumable)) {
      await _removeTask(task);
    }

    if (task.innerStatus == ALDownloaderInnerStatus.prepared ||
        task.innerStatus == ALDownloaderInnerStatus.pretendedPaused ||
        task.innerStatus == ALDownloaderInnerStatus.deprecated) {
      aldDebugPrint(
          'ALDownloader | try to download url, url status is ${task.innerStatus.alDescription}, url = $url, taskId = ${task.taskId}');

      final alist = await _generateDownloadConfig(task, willDirectoryPath,
          willFileName, willHeaders, redownloadIfNeeded);

      final fSavedDir = alist[0];
      final fFileName = alist[1];
      final fHeaders = alist[2];

      // Enqueue a task.
      final taskId = await FlutterDownloader.enqueue(
          url: url,
          savedDir: fSavedDir,
          fileName: fFileName,
          headers: fHeaders ?? const {},
          showNotification: false,
          openFileFromNotification: false);

      if (taskId != null) {
        aldDebugPrint(
            'ALDownloader | try to download url, a download task of url generates succeeded, url = $url, taskId = $taskId, innerStatus = enqueued');

        _addOrUpdateTaskForUrl(url, taskId, ALDownloaderInnerStatus.enqueued, 0,
            fSavedDir, fFileName, task.waitingPhase);
        task.headers = fHeaders;
        task.redownloadIfNeeded = redownloadIfNeededInConsumable;

        _callProgressHandler(url, 0);
      } else {
        aldDebugPrint(
            'ALDownloader | try to download url, but a download task of url generates failed, url = $url, taskId = null');
      }
    } else if (task.innerStatus == ALDownloaderInnerStatus.complete) {
      aldDebugPrint(
          'ALDownloader | try to download url, but url status is succeeded, url = $url, taskId = ${task.taskId}');

      _callSucceededHandler(task.url, task.double_progress);
    } else if (task.innerStatus == ALDownloaderInnerStatus.canceled ||
        task.innerStatus == ALDownloaderInnerStatus.failed) {
      final previousTaskId = task.taskId;
      final previousStatusDescription = task.innerStatus.alDescription;

      final taskIdForRetry = await FlutterDownloader.retry(taskId: task.taskId);

      if (taskIdForRetry != null) {
        final progress = task.progress;

        _addOrUpdateTaskForUrl(
            url,
            taskIdForRetry,
            ALDownloaderInnerStatus.enqueued,
            progress,
            task.savedDir,
            task.fileName,
            task.waitingPhase);

        _processProgressEventForTask(task);

        aldDebugPrint(
            'ALDownloader | try to download url, url status is $previousStatusDescription previously and retries succeeded, url = $url, previous taskId = $previousTaskId, taskId = $taskIdForRetry, innerStatus = enqueued');
      } else {
        aldDebugPrint(
            'ALDownloader | try to download url, url status is $previousStatusDescription previously but retries failed, url = $url, previous taskId = $previousTaskId, taskId = null');
      }
    } else if (task.innerStatus == ALDownloaderInnerStatus.paused) {
      final previousTaskId = task.taskId;

      final taskIdForResumption =
          await FlutterDownloader.resume(taskId: task.taskId);
      if (taskIdForResumption != null) {
        aldDebugPrint(
            'ALDownloader | try to download url, url status is paused previously and resumes succeeded, url = $url, previous taskId = $previousTaskId, taskId = $taskIdForResumption');

        _addOrUpdateTaskForUrl(
            url,
            taskIdForResumption,
            Platform.isAndroid
                ? ALDownloaderInnerStatus.paused
                : ALDownloaderInnerStatus.running,
            task.progress,
            task.savedDir,
            task.fileName,
            task.waitingPhase);
      } else {
        aldDebugPrint(
            'ALDownloader | try to download url, url status is paused previously but resumes failed, url = $url, previous taskId = $previousTaskId, taskId = null');
      }
    } else if (task.innerStatus == ALDownloaderInnerStatus.running) {
      aldDebugPrint(
          'ALDownloader | try to download url, but url status is running, url may re-download after being paused, url = $url, taskId = ${task.taskId}');

      task.isMayRedownloadAboutPause = true;
    } else {
      aldDebugPrint(
          'ALDownloader | try to download url, but url status is ${task.innerStatus.alDescription}, url = $url, taskId = ${task.taskId}');
    }
  }

  static Future<void> _pause(String url) async {
    try {
      ALDownloaderInnerTask? task = _getTaskFromUrl(url);

      aldDebugPrint(
          'ALDownloader | _pause, url = $url, url status is ${task?.innerStatus.alDescription}');

      if (task == null) return;

      final taskId = task.taskId;

      if (task.innerStatus == ALDownloaderInnerStatus.enqueued) {
        await _pauseTaskPretendedlyWithCallHandler(task);
      } else if (task.innerStatus == ALDownloaderInnerStatus.running) {
        if (Platform.isAndroid) {
          if (ALDownloaderFileManagerIMP.cIsExistPhysicalFilePath(
              task.filePath)) {
            await FlutterDownloader.pause(taskId: taskId);
            task.isMayRedownloadAboutPause = false;
          } else {
            await _pauseTaskPretendedlyWithCallHandler(task);
          }
        } else {
          await FlutterDownloader.pause(taskId: taskId);
          task.isMayRedownloadAboutPause = false;
        }
      } else if (task.waitingPhase == ALDownloaderTaskWaitingPhase.transiting ||
          task.waitingPhase == ALDownloaderTaskWaitingPhase.waiting) {
        if (task.innerStatus == ALDownloaderInnerStatus.paused ||
            task.innerStatus == ALDownloaderInnerStatus.pretendedPaused) {
          _processPausedEventForTask(task);
          task.isMayRedownloadAboutPause = false;
        } else {
          await _pauseTaskPretendedlyWithCallHandler(task);
        }
      } else if (task.innerStatus == ALDownloaderInnerStatus.paused ||
          task.innerStatus == ALDownloaderInnerStatus.pretendedPaused) {
        _callPausedHandler(task.url, task.double_progress);
        task.isMayRedownloadAboutPause = false;
      }
    } catch (error) {
      aldDebugPrint('ALDownloader | _pause, url = $url, error: $error');
    }
  }

  static Future<void> _pauseUrls(List<String> urls) async {
    for (final url in urls) _transitUrl(url);
    for (final url in urls) await _pause(url);
  }

  static Future<void> _pauseAll() async {
    for (final task in _tasks) _transitTask(task);
    for (final task in _tasks) await _pause(task.url);
  }

  static Future<void> _cancel(String url) async {
    try {
      final task = _getTaskFromUrl(url);

      aldDebugPrint(
          'ALDownloader | _cancel, url = $url, url status is ${task?.innerStatus.alDescription}');

      if (task == null) return;

      if (task.waitingPhase == ALDownloaderTaskWaitingPhase.transiting ||
          task.waitingPhase == ALDownloaderTaskWaitingPhase.waiting ||
          task.innerStatus == ALDownloaderInnerStatus.enqueued ||
          task.innerStatus == ALDownloaderInnerStatus.running) {
        await _removeTaskWithCallHandler(task);
      }
    } catch (error) {
      aldDebugPrint('ALDownloader | _cancel, url = $url, error: $error');
    }
  }

  static Future<void> _cancelUrls(List<String> urls) async {
    for (final url in urls) _transitUrl(url);
    for (final url in urls) await _cancel(url);
  }

  static Future<void> _cancelAll() async {
    for (final task in _tasks) _transitTask(task);
    for (final task in _tasks) await _cancel(task.url);
  }

  static Future<void> _remove(String url) async {
    try {
      final task = _getTaskFromUrl(url);

      aldDebugPrint(
          'ALDownloader | _remove, url = $url, url status is ${task?.innerStatus.alDescription}');

      if (task == null) return;

      await _removeTaskWithCallHandler(task);
    } catch (error) {
      aldDebugPrint('ALDownloader | _remove, url = $url, error: $error');
    }
  }

  static Future<void> _removeUrls(List<String> urls) async {
    for (final url in urls) _transitUrl(url);
    for (final url in urls) await _remove(url);
  }

  static Future<void> _removeAll() async {
    for (final task in _tasks) _transitTask(task);
    for (final task in _tasks) await _remove(task.url);
  }

  static Future<ALDownloaderStatus> _qGetStatusPurelyForUrl(String url) async {
    final r = await _queue.add<ALDownloaderStatus>(() async {
      final task = _getTaskFromUrl(url);

      final status = _getStatusForTask(task);
      return status;
    });

    return r;
  }

  static Future<double> _qGetProgressPurelyForUrl(String url) async {
    final r = await _queue.add<double>(() async {
      final task = _getTaskFromUrl(url);

      // ignore: non_constant_identifier_names
      double double_progress = task == null ? 0 : task.double_progress;
      return double_progress;
    });

    return r;
  }

  static Future<ALDownloaderTask?> _qGetTaskPurelyForUrl(String url) async {
    final r = await _queue.add<ALDownloaderTask?>(() async {
      final task = _getTaskFromUrl(url);
      if (task == null) return null;

      final r = _generateExportTaskForTask(task);
      return r;
    });

    return r;
  }

  static Future<List<ALDownloaderTask>> _qGetTasksPurely() async {
    final r = await _queue.add<List<ALDownloaderTask>>(() async {
      final r = _tasks.map((task) => _generateExportTaskForTask(task)).toList();

      return r;
    });

    return r;
  }

  static ALDownloaderTask _generateExportTaskForTask(
      ALDownloaderInnerTask task) {
    final status = _getStatusForTask(task);
    final file = ALDownloaderFile(task.savedDir ?? '', task.fileName ?? '');
    final r = ALDownloaderTask(task.url, status, task.double_progress, file);
    return r;
  }

  static ALDownloaderStatus _getStatusForTask(ALDownloaderInnerTask? task) {
    ALDownloaderStatus status;

    if (task == null) {
      status = ALDownloaderStatus.unstarted;
    } else {
      final innerStatus = task.innerStatus;
      if (task.waitingPhase == ALDownloaderTaskWaitingPhase.transiting ||
          task.waitingPhase == ALDownloaderTaskWaitingPhase.waiting) {
        // ALDownloaderTaskWaitingPhase.transiting and ALDownloaderTaskWaitingPhase.waiting as downloading
        status = ALDownloaderStatus.downloading;
      } else if (innerStatus == ALDownloaderInnerStatus.prepared ||
          innerStatus == ALDownloaderInnerStatus.undefined ||
          innerStatus == ALDownloaderInnerStatus.deprecated) {
        status = ALDownloaderStatus.unstarted;
      } else if (innerStatus == ALDownloaderInnerStatus.enqueued ||
          innerStatus == ALDownloaderInnerStatus.running) {
        status = ALDownloaderStatus.downloading;
      } else if (innerStatus == ALDownloaderInnerStatus.canceled ||
          innerStatus == ALDownloaderInnerStatus.failed) {
        status = ALDownloaderStatus.failed;
      } else if (innerStatus == ALDownloaderInnerStatus.pretendedPaused ||
          innerStatus == ALDownloaderInnerStatus.paused) {
        status = ALDownloaderStatus.paused;
      } else {
        status = ALDownloaderStatus.succeeded;
      }
    }

    return status;
  }

  static Future<List<dynamic>> _generateDownloadConfig(
      ALDownloaderInnerTask task,
      String willDirectoryPath,
      String willFileName,
      Map<String, String>? willHeaders,
      bool redownloadIfNeeded) async {
    String fSavedDir;
    String fFileName;
    Map<String, String>? fHeaders;

    final cSavedDir = task.savedDir;
    final cFileName = task.fileName;
    final cHeaders = task.headers;

    if (cSavedDir != null && cFileName != null) {
      fSavedDir = cSavedDir;
      fFileName = cFileName;
      fHeaders = cHeaders;
    } else {
      final file = await ALDownloaderFileManagerIMP.cLazyGetFile(
          willDirectoryPath, willFileName);

      fSavedDir = file.directoryPath;
      fFileName = file.fileName;
      fHeaders = willHeaders;
    }

    return [fSavedDir, fFileName, fHeaders];
  }

  /// Manager custom download tasks
  ///
  /// **purpose**
  ///
  /// avoid frequent I/O
  ///
  /// **discussion**
  ///
  /// Add or update the task for [url].
  static ALDownloaderInnerTask _addOrUpdateTaskForUrl(
      String? url,
      String taskId,
      ALDownloaderInnerStatus innerStatus,
      int progress,
      String? savedDir,
      String? fileName,
      ALDownloaderTaskWaitingPhase waitingPhase) {
    if (url == null)
      throw 'ALDownloader | _addOrUpdateTaskForUrl, error: url is null';

    ALDownloaderInnerTask? task;

    try {
      task = _tasks.firstWhere((element) => element.url == url);
      task.savedDir = savedDir;
      task.fileName = fileName;
      task.taskId = taskId;
      task.innerStatus = innerStatus;
      task.progress = progress;
      task.waitingPhase = waitingPhase;
    } catch (error) {
      aldDebugPrint('ALDownloader | _addOrUpdateTaskForUrl, error: $error');
    }

    if (task == null) {
      task = ALDownloaderInnerTask(url);
      task.savedDir = savedDir;
      task.fileName = fileName;
      task.taskId = taskId;
      task.innerStatus = innerStatus;
      task.progress = progress;
      task.waitingPhase = waitingPhase;
      task.pIndex = _tasks.length;

      _tasks.add(task);
    }

    if (task.innerStatus == ALDownloaderInnerStatus.enqueued ||
        task.innerStatus == ALDownloaderInnerStatus.running) {
      if (!_goingTasks.contains(task)) _goingTasks.add(task);
    } else {
      if (_goingTasks.contains(task)) _goingTasks.remove(task);
    }

    return task;
  }

  /// Do work on root isolate
  static void doWorkOnRootIsolate(ALDownloaderMessage message) {
    final action = message.action;
    final content = message.content;
    if (action == ALDownloaderConstant.kCallInterface) {
      final id = content[ALDownloaderConstant.kHandlerInterfaceId];
      final isNeedCallProgressHandler =
          content[ALDownloaderConstant.kIsNeedCallProgressHandler];
      final isNeedCallSucceededHandler =
          content[ALDownloaderConstant.kIsNeedCallSucceededHandler];
      final isNeedCallFailedHandler =
          content[ALDownloaderConstant.kIsNeedCallFailedHandler];
      final isNeedCallPausedHandler =
          content[ALDownloaderConstant.kIsNeedCallPausedHandler];
      final progress = content[ALDownloaderConstant.kProgress];
      final isNeedRemoveInterface =
          content[ALDownloaderConstant.kIsNeedRemoveInterface];
      final inteface = _idDynamicKVs[id];

      ALDownloaderHeader.callDownloaderHandlerInterface(
          inteface,
          isNeedCallProgressHandler,
          isNeedCallSucceededHandler,
          isNeedCallFailedHandler,
          isNeedCallPausedHandler,
          progress);

      if (isNeedRemoveInterface) _idDynamicKVs.remove(id);
    } else if (action == ALDownloaderConstant.kCallStatusHandler) {
      final id = content[ALDownloaderConstant.kHandlerId];
      final status = content[ALDownloaderConstant.kStatus];
      final handler = _idDynamicKVs[id];

      if (handler != null) handler(status);

      _idDynamicKVs.remove(id);
    } else if (action == ALDownloaderConstant.kCallProgressHandler) {
      final id = content[ALDownloaderConstant.kHandlerId];
      final progress = content[ALDownloaderConstant.kProgress];
      final handler = _idDynamicKVs[id];

      if (handler != null) handler(progress);

      _idDynamicKVs.remove(id);
    } else if (action == ALDownloaderConstant.kCallTaskHandler) {
      final id = content[ALDownloaderConstant.kHandlerId];
      final task = content[ALDownloaderConstant.kTask];
      final handler = _idDynamicKVs[id];

      if (handler != null) handler(task);

      _idDynamicKVs.remove(id);
    } else if (action == ALDownloaderConstant.kCallTasksHandler) {
      final id = content[ALDownloaderConstant.kHandlerId];
      final tasks = content[ALDownloaderConstant.kTasks];
      final handler = _idDynamicKVs[id];

      if (handler != null) handler(tasks);

      _idDynamicKVs.remove(id);
    }
  }

  /// Do work on ALDownloader isolate
  static void doWorkOnALIsolate(ALDownloaderMessage message) {
    final action = message.action;
    final content = message.content;

    if (action == ALDownloaderConstant.kInitiallize) {
      _qInitialize();
    } else if (action == ALDownloaderConstant.kConfigurePrint) {
      final enabled = content[ALDownloaderConstant.kEnabled];
      final frequentEnabled = content[ALDownloaderConstant.kFrequentEnabled];
      ALDownloaderPrintConfig.enabled = enabled;
      ALDownloaderPrintConfig.frequentEnabled = frequentEnabled;
    } else if (action == ALDownloaderConstant.kAddHandlerInterface) {
      final url = content[ALDownloaderConstant.kUrl];
      final id = content[ALDownloaderConstant.kHandlerInterfaceId];
      _qAddHandlerInterface(id, url);
    } else if (action == ALDownloaderConstant.kAddForeverHandlerInterface) {
      final url = content[ALDownloaderConstant.kUrl];
      final id = content[ALDownloaderConstant.kHandlerInterfaceId];
      _qaddForeverHandlerInterface(id, url);
    } else if (action == ALDownloaderConstant.kRemoveHandlerInterfaceForUrl) {
      final url = content[ALDownloaderConstant.kUrl];
      _qremoveHandlerInterfaceForUrl(url);
    } else if (action == ALDownloaderConstant.kRemoveHandlerInterfaceForId) {
      final id = content[ALDownloaderConstant.kHandlerInterfaceId];
      _qRemoveHandlerInterfaceForId(id);
    } else if (action == ALDownloaderConstant.kRemoveHandlerInterfaceForAll) {
      _qRemoveHandlerInterfaceForAll();
    } else {
      if (ALDownloaderHeader.initializedCompleter.isCompleted) {
        _doWorkWhichMustBeAfterInitializedOnALIsolate(message);
      } else {
        ALDownloaderHeader.initializedCompleter.future.then(
            (_) => _doWorkWhichMustBeAfterInitializedOnALIsolate(message));
      }
    }
  }

  static void _doWorkWhichMustBeAfterInitializedOnALIsolate(
      ALDownloaderMessage message) {
    final action = message.action;
    final content = message.content;

    if (action == ALDownloaderConstant.kDownload) {
      final url = content[ALDownloaderConstant.kUrl];
      final handlerInterfaceId =
          content[ALDownloaderConstant.kHandlerInterfaceId];
      final directoryPath = content[ALDownloaderConstant.kDirectoryPath];
      final fileName = content[ALDownloaderConstant.kFileName];
      final headers = content[ALDownloaderConstant.kHeaders];
      final redownloadIfNeeded =
          content[ALDownloaderConstant.kRedownloadIfNeeded];
      _qDownload(url,
          directoryPath: directoryPath,
          fileName: fileName,
          headers: headers,
          redownloadIfNeeded: redownloadIfNeeded,
          handlerInterfaceId: handlerInterfaceId);
    } else if (action == ALDownloaderConstant.kPause) {
      final url = content[ALDownloaderConstant.kUrl];
      _qPause(url);
    } else if (action == ALDownloaderConstant.kPauseAll) {
      _qPauseAll();
    } else if (action == ALDownloaderConstant.kCancel) {
      final url = content[ALDownloaderConstant.kUrl];
      _qCancel(url);
    } else if (action == ALDownloaderConstant.kCancelAll) {
      _qCancelAll();
    } else if (action == ALDownloaderConstant.kRemove) {
      final url = content[ALDownloaderConstant.kUrl];
      _qRemove(url);
    } else if (action == ALDownloaderConstant.kRemoveAll) {
      _qRemoveAll();
    } else if (action == ALDownloaderConstant.kGetStatusForUrl) {
      final id = content[ALDownloaderConstant.kHandlerId];
      final url = content[ALDownloaderConstant.kUrl];
      _qGetStatusForUrl(id, url);
    } else if (action == ALDownloaderConstant.kGetProgressForUrl) {
      final id = content[ALDownloaderConstant.kHandlerId];
      final url = content[ALDownloaderConstant.kUrl];
      _qGetProgressForUrl(id, url);
    } else if (action == ALDownloaderConstant.kGetTask) {
      final id = content[ALDownloaderConstant.kHandlerId];
      final url = content[ALDownloaderConstant.kUrl];
      _qGetTaskForUrl(id, url);
    } else if (action == ALDownloaderConstant.kGetTasks) {
      final id = content[ALDownloaderConstant.kHandlerId];
      _qGetTasks(id);
    }
  }

  /// Register service which is used for that communication between [FlutterDownloader] isolate and ALDownloader isolate by [IsolateNameServer]
  static void _registerServiceForCommunicationBetweenFAndAL() {
    IsolateNameServer.removePortNameMapping(_kPortForFToAL);

    final receivePort = ReceivePort();

    IsolateNameServer.registerPortWithName(
        receivePort.sendPort, _kPortForFToAL);
    receivePort.listen((dynamic data) {
      try {
        final taskId = data[0];

        final originalStatusValue = data[1];
        final originalStatus = DownloadTaskStatus.fromInt(originalStatusValue);

        final progress = data[2];

        _processDataFromFPort(taskId, originalStatus, progress);
      } catch (error) {
        aldDebugPrint(
            'ALDownloader | _registerServiceForCommunicationBetweenFAndAL | listen | error: $error',
            isFrequentPrint: true);
      }
    });
  }

  /// The callback binded by [FlutterDownloader]
  @pragma('vm:entry-point')
  static void _downloadCallback(
      String taskId, int originalStatusValue, int progress) {
    final send = IsolateNameServer.lookupPortByName(_kPortForFToAL);
    send?.send([taskId, originalStatusValue, progress]);
  }

  /// Process the [FlutterDownloader]'s callback
  static void _processDataFromFPort(
      String taskId, DownloadTaskStatus originalStatus, int progress) {
    aldDebugPrint(
        'ALDownloader | _processDataFromFPort | original, taskId = $taskId, original status = $originalStatus, original progress = $progress',
        isFrequentPrint: true);

    ALDownloaderInnerStatus innerStatus = _transferStatus(originalStatus);

    final task = _getTaskFromTaskId(taskId);

    if (task == null) {
      aldDebugPrint(
          'ALDownloader | _processDataFromFPort, the function return, because task is not found, taskId = $taskId');
      return;
    }

    if (task.innerStatus == ALDownloaderInnerStatus.prepared ||
        task.innerStatus == ALDownloaderInnerStatus.pretendedPaused ||
        task.innerStatus == ALDownloaderInnerStatus.deprecated) {
      aldDebugPrint(
          'ALDownloader | _processDataFromFPort, the function return, because task is ${task.innerStatus.alDescription}, taskId = $taskId');
      return;
    }

    final url = task.url;

    _addOrUpdateTaskForUrl(url, taskId, innerStatus, progress, task.savedDir,
        task.fileName, task.waitingPhase);

    _callHandlerForBusiness1(task);

    if (task.isMayRedownloadAboutPause &&
        task.innerStatus == ALDownloaderInnerStatus.paused) {
      task.isMayRedownloadAboutPause = false;
      _qDownload(url, isNeedUpdateInputs: false);
    }

    aldDebugPrint(
        'ALDownloader | _processDataFromFPort | processed, taskId = $taskId, url = $url, innerStatus = $innerStatus, progress = $progress, double_progress = ${task.double_progress}',
        isFrequentPrint: true);
  }

  /// Load [FlutterDownloader]'s database task to the memory cache
  static Future<void> _loadTasks() async {
    final originalTasks = await FlutterDownloader.loadTasks();

    if (originalTasks != null) {
      aldDebugPrint(
          'ALDownloader | _loadTasks, original tasks length = ${originalTasks.length}');

      for (final element in originalTasks) {
        final originalTaskId = element.taskId;
        final originalUrl = element.url;
        final originalSavedDir = element.savedDir;
        final originalFileName = element.filename ?? '';
        final originalStatus = element.status;
        final originalProgress = element.progress;

        aldDebugPrint(
            'ALDownloader | _loadTasks, original url = $originalUrl, original taskId = $originalTaskId, original status = $originalStatus');

        final task = ALDownloaderInnerTask(originalUrl);
        task.taskId = originalTaskId;

        if (originalSavedDir.endsWith('/')) {
          task.savedDir = originalSavedDir;
        } else {
          task.savedDir = originalSavedDir + '/';
        }
        task.fileName = originalFileName;
        task.innerStatus = _transferStatus(originalStatus);
        task.progress = originalProgress;
        _tasks.add(task);

        final isShouldRemoveDataForSavedDir =
            await _isShouldRemoveDataForInitialization(task);
        if (isShouldRemoveDataForSavedDir) {
          await _removeTask(task);
        }

        aldDebugPrint(
            'ALDownloader | _loadTasks, url = ${task.url}, taskId = ${task.taskId}, innerStatus = ${task.innerStatus}, isShouldRemoveDataForSavedDir = $isShouldRemoveDataForSavedDir');
      }

      aldDebugPrint(
          'ALDownloader | _loadTasks, tasks length = ${_tasks.length}');

      for (final task in _tasks) {
        if (task.innerStatus == ALDownloaderInnerStatus.deprecated) {
          _processFailedEventForUrlProgress(task.url, 0);
        } else {
          // If the task is normal, call handler directly.
          _callHandlerForBusiness1(task);
        }
      }
    }
  }

  /// Call handler for business 1
  static void _callHandlerForBusiness1(ALDownloaderInnerTask task) {
    final innerStatus = task.innerStatus;
    if (innerStatus == ALDownloaderInnerStatus.enqueued ||
        innerStatus == ALDownloaderInnerStatus.running) {
      _processProgressEventForTask(task);
    } else if (innerStatus == ALDownloaderInnerStatus.complete) {
      _processSucceededEventForTask(task);
    } else if (innerStatus == ALDownloaderInnerStatus.canceled ||
        innerStatus == ALDownloaderInnerStatus.failed) {
      _processFailedEventForUrlProgress(task.url, -0.01);
    } else if (innerStatus == ALDownloaderInnerStatus.paused) {
      _processPausedEventForTask(task);
    }
  }

  /// Verify data and then determine whether to delete data from disk
  ///
  /// for initialization
  static Future<bool> _isShouldRemoveDataForInitialization(
      ALDownloaderInnerTask task) async {
    final url = task.url;
    final innerStatus = task.innerStatus;
    final filePath = task.filePath;

    if (innerStatus == ALDownloaderInnerStatus.prepared) return false;

    if (filePath != null && filePath.contains('/al_flutter/')) {
      if (!(await ALDownloaderFileManagerDefault.isInRootPathForPath(filePath)))
        return true;

      final shouldFilePath =
          await ALDownloaderFileManagerDefault.getVirtualFilePathForUrl(url);
      if (filePath != shouldFilePath) return true;
    }

    bool aBool = innerStatus == ALDownloaderInnerStatus.enqueued ||
        innerStatus == ALDownloaderInnerStatus.running;

    if (!aBool) {
      if (innerStatus == ALDownloaderInnerStatus.complete ||
          innerStatus == ALDownloaderInnerStatus.paused) {
        aBool =
            !(ALDownloaderFileManagerIMP.cIsExistPhysicalFilePath(filePath));
      } else {
        aBool = false;
      }
    }

    return aBool;
  }

  /// Verify data and then determine whether to delete data from disk
  static Future<bool> _isShouldRemoveData(
      ALDownloaderInnerTask task,
      Map? willHeaders,
      String willSavedDir,
      String willFileName,
      bool redownloadIfNeeded) async {
    final savedDir = task.savedDir;
    final finaName = task.fileName;
    final innerStatus = task.innerStatus;
    final filePath = task.filePath;
    final headers = task.headers;

    if (innerStatus == ALDownloaderInnerStatus.prepared) return false;

    if (redownloadIfNeeded) {
      final isSameSavedDir =
          ALDownloaderStringExtension.isEqualTwoString(savedDir, willSavedDir);

      final isSameFileName =
          ALDownloaderStringExtension.isEqualTwoString(finaName, willFileName);

      final isSameHeaders =
          ALDownloaderMapExtension.isEqualTwoMap(headers, willHeaders);

      if (!isSameSavedDir || !isSameFileName || !isSameHeaders) return true;
    }

    if (innerStatus == ALDownloaderInnerStatus.pretendedPaused) return false;

    if (filePath != null && filePath.contains('/al_flutter/')) {
      if (!(await ALDownloaderFileManagerDefault.isInRootPathForPath(filePath)))
        return true;
    }

    bool aBool;
    if (innerStatus == ALDownloaderInnerStatus.complete ||
        innerStatus == ALDownloaderInnerStatus.paused) {
      aBool = !ALDownloaderFileManagerIMP.cIsExistPhysicalFilePath(filePath);
    } else {
      aBool = false;
    }

    return aBool;
  }

  /// Get task from custom download tasks by [url]
  static ALDownloaderInnerTask? _getTaskFromUrl(String url) {
    ALDownloaderInnerTask? task;
    try {
      task = _tasks.firstWhere((element) => url == element.url);
    } catch (error) {
      aldDebugPrint('ALDownloader | _getTaskFromUrl, error: $error');
    }

    return task;
  }

  /// Get task id from custom download tasks by [url]
  // ignore: unused_element
  static String? _getTaskIdFromUrl(String url) {
    String? taskId;
    try {
      taskId = _tasks.firstWhere((element) => url == element.url).taskId;
    } catch (error) {
      aldDebugPrint('ALDownloader | _getTaskIdWith, error: $error');
    }
    return taskId;
  }

  /// Get task from custom download tasks by [taskId]
  // ignore: unused_element
  static ALDownloaderInnerTask? _getTaskFromTaskId(String taskId) {
    ALDownloaderInnerTask? task;
    try {
      task = _tasks.firstWhere((element) => taskId == element.taskId);
    } catch (error) {
      aldDebugPrint('ALDownloader | _getTaskFromTaskId, error: $error');
    }
    return task;
  }

  /// Get url from custom download tasks by [taskId]
  // ignore: unused_element
  static String? _getUrlFromTaskId(String taskId) {
    String? url;
    try {
      url = _tasks.firstWhere((element) => taskId == element.taskId).url;
    } catch (error) {
      aldDebugPrint('ALDownloader | _getUrlWithTaskId, error: $error');
    }
    return url;
  }

  static bool get _isLimitedForGoingTasks {
    final isLimited = _goingTasks.length >= _kMaxConcurrentTaskCount;
    return isLimited;
  }

  static Future<void> _pauseTaskPretendedlyWithCallHandler(
      ALDownloaderInnerTask task) async {
    await _pauseTaskPretendedly(task);

    _processPausedEventForTask(task);
  }

  static Future<void> _pauseTaskPretendedly(ALDownloaderInnerTask task) async {
    final taskId = task.taskId;

    _addOrUpdateTaskForUrl(
        task.url,
        taskId,
        ALDownloaderInnerStatus.pretendedPaused,
        0,
        task.savedDir,
        task.fileName,
        task.waitingPhase);

    task.isMayRedownloadAboutPause = false;

    if (taskId.length > 0)
      await FlutterDownloader.remove(taskId: taskId, shouldDeleteContent: true);
  }

  static Future<void> _removeTaskWithCallHandler(
      ALDownloaderInnerTask task) async {
    final url = task.url;

    await _removeTask(task);

    _processFailedEventForUrlProgress(url, 0);
  }

  static Future<void> _removeTask(ALDownloaderInnerTask task) async {
    final taskId = task.taskId;

    _addOrUpdateTaskForUrl(task.url, taskId, ALDownloaderInnerStatus.deprecated,
        0, null, null, task.waitingPhase);

    task.willParameters = null;
    task.headers = null;
    task.redownloadIfNeeded = false;
    task.isMayRedownloadAboutPause = false;

    if (taskId.length > 0)
      await FlutterDownloader.remove(taskId: taskId, shouldDeleteContent: true);
  }

  static void _processProgressEventForTask(ALDownloaderInnerTask task) {
    _callProgressHandler(task.url, task.double_progress);
  }

  static void _processSucceededEventForTask(ALDownloaderInnerTask task) {
    _unwaitTask(task);
    _callSucceededHandler(task.url, task.double_progress);
    _downloadWaitingTasks();
  }

  // ignore: unused_element
  static void _processFailedEventForTask(ALDownloaderInnerTask task) {
    _unwaitTask(task);
    _callFailedHandler(task.url, task.double_progress);
    _downloadWaitingTasks();
  }

  static void _processPausedEventForTask(ALDownloaderInnerTask task) {
    _unwaitTask(task);
    _callPausedHandler(task.url, task.double_progress);
    _downloadWaitingTasks();
  }

  static void _processFailedEventForUrlProgress(String url, double progress) {
    _unwaitUrl(url);
    _callFailedHandler(url, progress);
    _downloadWaitingTasks();
  }

  static void _callProgressHandler(String url, double progress) {
    final binders = _urlBinderKVs[url];
    if (binders == null) return;

    for (final element in binders) {
      final handlerInterfaceId = element.handlerInterfaceId;
      _callInterface(handlerInterfaceId, true, false, false, false, progress);
    }
  }

  static void _callSucceededHandler(String url, double progress) {
    final binders = _urlBinderKVs[url];
    if (binders == null) return;

    final aList = <_ALDownloaderBinder>[];
    aList.addAll(binders);

    for (final element in aList) {
      final handlerInterfaceId = element.handlerInterfaceId;
      _callInterface(handlerInterfaceId, true, true, false, false, progress,
          isNeedRemoveInterface: !element.isForever);
      if (!element.isForever) binders.remove(element);
    }

    if (binders.length == 0) _urlBinderKVs.remove(url);
  }

  static void _callFailedHandler(String url, double progress) {
    final binders = _urlBinderKVs[url];
    if (binders == null) return;

    final aList = <_ALDownloaderBinder>[];
    aList.addAll(binders);

    for (final element in aList) {
      final handlerInterfaceId = element.handlerInterfaceId;
      _callInterface(handlerInterfaceId, true, false, true, false, progress,
          isNeedRemoveInterface: !element.isForever);
      if (!element.isForever) binders.remove(element);
    }

    if (binders.length == 0) _urlBinderKVs.remove(url);
  }

  static void _callPausedHandler(String url, double progress) {
    final binders = _urlBinderKVs[url];
    if (binders == null) return;

    for (final element in binders) {
      final handlerInterfaceId = element.handlerInterfaceId;
      bool isNeedCallProgressHandler = progress > -0.01;

      _callInterface(handlerInterfaceId, isNeedCallProgressHandler, false,
          false, true, progress);
    }
  }

  /// Call interface for all isolates
  static void _callInterface(
      String handlerInterfaceId,
      bool isNeedCallProgressHandler,
      bool isNeedCallSucceededHandler,
      bool isNeedCallFailedHandler,
      bool isNeedCallPausedHandler,
      double progress,
      {bool isNeedRemoveInterface = false}) {
    // Call interface for root isolate
    ALDownloaderHeader.processDownloaderHandlerInterfaceOnComingRootIsolate(
        ALDownloaderConstant.kALDownloaderIMP,
        handlerInterfaceId,
        isNeedCallProgressHandler,
        isNeedCallSucceededHandler,
        isNeedCallFailedHandler,
        isNeedCallPausedHandler,
        progress,
        isNeedRemoveInterface: isNeedRemoveInterface);

    // Call interface for current isolate
    _processDownloaderHandlerInterfaceOnCurrentIsolate(
        handlerInterfaceId,
        isNeedCallProgressHandler,
        isNeedCallSucceededHandler,
        isNeedCallFailedHandler,
        isNeedCallPausedHandler,
        progress);
  }

  static void _processStatusHandlerOnComingRootIsolate(
      String handlerId, ALDownloaderStatus status) {
    ALDownloaderHeader.processStatusHandlerOnComingRootIsolate(
        ALDownloaderConstant.kALDownloaderIMP, handlerId, status);
  }

  static void _processProgressHandlerOnComingRootIsolate(
      String handlerId, double progress) {
    ALDownloaderHeader.processProgressHandlerOnComingRootIsolate(
        ALDownloaderConstant.kALDownloaderIMP, handlerId, progress);
  }

  static void _processTaskHandlerOnComingRootIsolate(
      String handlerId, ALDownloaderTask? task) {
    ALDownloaderHeader.processTaskHandlerOnComingRootIsolate(handlerId, task);
  }

  static void _processTasksHandlerOnComingRootIsolate(
      String handlerId, List<ALDownloaderTask> tasks) {
    ALDownloaderHeader.processTasksHandlerOnComingRootIsolate(
        ALDownloaderConstant.kALDownloaderIMP, handlerId, tasks);
  }

  static void _processDownloaderHandlerInterfaceOnCurrentIsolate(
      String handlerInterfaceId,
      bool isNeedCallProgressHandler,
      bool isNeedCallSucceededHandler,
      bool isNeedCallFailedHandler,
      bool isNeedCallPausedHandler,
      double progress) {
    final handlerInterface = _idDynamicKVs[handlerInterfaceId];
    ALDownloaderHeader.callDownloaderHandlerInterface(
        handlerInterface,
        isNeedCallProgressHandler,
        isNeedCallSucceededHandler,
        isNeedCallFailedHandler,
        isNeedCallPausedHandler,
        progress);
  }

  // ignore: unused_element
  static bool _isWaitingUrl(String url) {
    final task = _getTaskFromUrl(url);
    return _isWaitingTask(task);
  }

  static bool _isWaitingTask(ALDownloaderInnerTask? task) {
    return task?.waitingPhase == ALDownloaderTaskWaitingPhase.waiting;
  }

  // ignore: unused_element
  static void _waitUrl(String url) {
    final task = _getTaskFromUrl(url);
    _waitTask(task);
  }

  static void _waitTask(ALDownloaderInnerTask? task) {
    _assignTaskWaitingPhase(task, ALDownloaderTaskWaitingPhase.waiting);
  }

  static void _transitUrl(String url) {
    final task = _getTaskFromUrl(url);
    _transitTask(task);
  }

  static void _transitTask(ALDownloaderInnerTask? task) {
    if (!_isWaitingTask(task)) return;

    _assignTaskWaitingPhase(task, ALDownloaderTaskWaitingPhase.transiting);
  }

  static void _unwaitUrl(String url) {
    final task = _getTaskFromUrl(url);
    _unwaitTask(task);
  }

  static void _unwaitTask(ALDownloaderInnerTask? task) {
    _assignTaskWaitingPhase(task, ALDownloaderTaskWaitingPhase.unwaiting);
  }

  static void _assignTaskWaitingPhase(
      ALDownloaderInnerTask? task, ALDownloaderTaskWaitingPhase waitingPhase) {
    if (task == null) return;

    _addOrUpdateTaskForUrl(task.url, task.taskId, task.innerStatus,
        task.progress, task.savedDir, task.fileName, waitingPhase);

    switch (waitingPhase) {
      case ALDownloaderTaskWaitingPhase.waiting:
        {
          if (!_waitingTasks.contains(task)) {
            _waitingTasks.add(task);
            _waitingTasks.sort((a, b) => a.pIndex.compareTo(b.pIndex));
          }
        }
        break;

      default:
        {
          _waitingTasks.remove(task);
        }
        break;
    }
  }

  static void _downloadWaitingTasks() {
    final expectedExecuteTasksCount =
        _kMaxConcurrentTaskCount - _goingTasks.length;

    for (int i = 0; i < expectedExecuteTasksCount; i++) {
      if (_waitingTasks.length > i) {
        final task = _waitingTasks[i];
        _qDownload(task.url, isNeedUpdateInputs: false);
      }
    }
  }

  static ALDownloaderInnerStatus _transferStatus(DownloadTaskStatus status) {
    if (status == DownloadTaskStatus.enqueued) {
      return ALDownloaderInnerStatus.enqueued;
    } else if (status == DownloadTaskStatus.running) {
      return ALDownloaderInnerStatus.running;
    } else if (status == DownloadTaskStatus.complete) {
      return ALDownloaderInnerStatus.complete;
    } else if (status == DownloadTaskStatus.failed) {
      return ALDownloaderInnerStatus.failed;
    } else if (status == DownloadTaskStatus.canceled) {
      return ALDownloaderInnerStatus.canceled;
    } else if (status == DownloadTaskStatus.paused) {
      return ALDownloaderInnerStatus.paused;
    }

    return ALDownloaderInnerStatus.undefined;
  }

  static void _addBinder(String url, _ALDownloaderBinder binder) {
    List<_ALDownloaderBinder>? binders = _urlBinderKVs[url];
    if (binders == null) {
      binders = <_ALDownloaderBinder>[];
      _urlBinderKVs[url] = binders;
    }
    binders.add(binder);
  }

  /// A dirty flag that [initialize] executed
  static bool _isInitialized = false;

  /// A map that key is id and value may be the fllowing type
  ///
  /// [ALDownloaderHandlerInterface], [ALDownloaderProgressHandler] and mores
  ///
  /// Key is generated by [ALDownloaderHeader.uuid].
  static final _idDynamicKVs = <String, dynamic>{};

  /// Send port for communication from [FlutterDownloader] isolate to ALDownloader isolate
  static final _kPortForFToAL = '_kPortForFToAL';

  /// ALDownloader event queue
  static final _queue = Queue();

  /// Custom download tasks
  static List<ALDownloaderInnerTask> get _tasks => ALDownloaderHeader.tasks;

  /// Going download tasks
  static final _goingTasks = <ALDownloaderInnerTask>[];

  /// Waiting download tasks
  static final _waitingTasks = <ALDownloaderInnerTask>[];

  /// A map that key is url and value is binder list.
  static final _urlBinderKVs = <String, List<_ALDownloaderBinder>>{};

  /// Max concurrent task count
  static final _kMaxConcurrentTaskCount = 7;

  /// Privatize constructor
  ALDownloaderIMP._();
}

/// A binder for binding some elements such as [url], [handlerInterfaceId] and more
class _ALDownloaderBinder {
  final String url;

  final ALDownloaderHandlerInterfaceId handlerInterfaceId;

  final bool isForever;

  /// Whether [_ALDownloaderBinder] generates by ALDownloader inner
  bool isInner = true;

  _ALDownloaderBinder(this.url, this.handlerInterfaceId, this.isForever);
}
