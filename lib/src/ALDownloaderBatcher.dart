import 'chore/ALDownloaderBatcherInputVO.dart';
import 'implementation/ALDownloaderBatcherIMP.dart';
import 'ALDownloader.dart';
import 'ALDownloaderHandlerInterface.dart';
import 'ALDownloaderStatus.dart';
import 'ALDownloaderTask.dart';
import 'ALDownloaderTypeDefine.dart';

/// ALDownloaderBatcher
///
/// The progress calculation method of [ALDownloaderHandlerInterface] is `progress = number of succeeded urls / number of all urls`.
abstract class ALDownloaderBatcher {
  /// Download
  ///
  /// **parameters**
  ///
  /// [urls] urls
  ///
  /// [handlerInterface] handler interface
  ///
  /// It is an one-off interface which will be destroyed when the download succeeded/failed.
  ///
  /// **return**
  ///
  /// [ALDownloaderHandlerInterfaceId] handler interface id
  ///
  /// It is used for managing batch handler interface.
  static ALDownloaderHandlerInterfaceId? download(List<String> urls,
          {ALDownloaderHandlerInterface? handlerInterface}) =>
      ALDownloaderBatcherIMP.download(urls, handlerInterface: handlerInterface);

  /// Download
  ///
  /// **parameters**
  ///
  /// [vos] the input value object list
  ///
  /// [handlerInterface] handler interface
  ///
  /// It is an one-off interface which will be destroyed when the download succeeded/failed.
  ///
  /// **return**
  ///
  /// [ALDownloaderHandlerInterfaceId] handler interface id
  ///
  /// It is used for managing handler interface.
  static ALDownloaderHandlerInterfaceId? downloadUrlsWithVOs(
          List<ALDownloaderBatcherInputVO> vos,
          {ALDownloaderHandlerInterface? handlerInterface}) =>
      ALDownloaderBatcherIMP.downloadUrlsWithVOs(vos,
          handlerInterface: handlerInterface);

  /// Add a handler interface
  ///
  /// **parameters**
  ///
  /// [handlerInterface] handler interface
  ///
  /// It is an one-off interface which will be destroyed when the download succeeded/failed.
  ///
  /// [urls] urls
  ///
  /// **return**
  ///
  /// [ALDownloaderHandlerInterfaceId] handler interface id
  ///
  /// It is used for managing handler interface.
  static ALDownloaderHandlerInterfaceId addHandlerInterface(
          ALDownloaderHandlerInterface handlerInterface, List<String> urls) =>
      ALDownloaderBatcherIMP.addHandlerInterface(handlerInterface, urls);

  /// Remove handler interface
  ///
  /// **parameters**
  ///
  /// [id] handler interface id
  ///
  /// It is generated by [download], [downloadUrlsWithVOs], [addHandlerInterface].
  static void removeHandlerInterfaceForId(ALDownloaderHandlerInterfaceId id) =>
      ALDownloaderBatcherIMP.removeHandlerInterfaceForId(id);

  /// Remove all handler interfaces
  static void removeHandlerInterfaceForAll() =>
      ALDownloaderBatcherIMP.removeHandlerInterfaceForAll();

  /// Get download status
  ///
  /// Summarize the download status for a set of urls.
  ///
  /// **parameters**
  ///
  /// [urls] urls
  ///
  /// **return**
  ///
  /// [ALDownloaderStatus] status
  static Future<ALDownloaderStatus> getStatusForUrls(List<String> urls) =>
      ALDownloaderBatcherIMP.getStatusForUrls(urls);

  /// Get download progress
  ///
  /// number of succeeded urls / number of all urls
  ///
  /// **parameters**
  ///
  /// [urls] urls
  ///
  /// **return**
  ///
  /// [double] progress
  static Future<double> getProgressForUrls(List<String> urls) =>
      ALDownloaderBatcherIMP.getProgressForUrls(urls);

  /// Get tasks
  ///
  /// **parameters**
  ///
  /// [urls] urls
  ///
  /// [byQueueOrder]
  ///
  /// If [byQueueOrder] is true, return results in the order of tasks in the download queue,
  /// otherwise, in the order of [urls]'s order.
  ///
  /// **return**
  ///
  /// [List<ALDownloaderTask>] tasks
  static Future<List<ALDownloaderTask>> getTasksForUrls(List<String> urls,
          {bool byQueueOrder = false}) =>
      ALDownloaderBatcherIMP.getTasksForUrls(urls, byQueueOrder: byQueueOrder);

  /// Pause downloads
  ///
  /// This is a multiple of [ALDownloader.pause], see [ALDownloader.pause].
  ///
  /// **parameters**
  ///
  /// [urls] urls
  static void pause(List<String> urls) => ALDownloaderBatcherIMP.pause(urls);

  /// Cancel downloads
  ///
  /// This is a multiple of [ALDownloader.cancel], see [ALDownloader.cancel].
  ///
  /// **parameters**
  ///
  /// [urls] urls
  static void cancel(List<String> urls) => ALDownloaderBatcherIMP.cancel(urls);

  /// Remove downloads
  ///
  /// This is a multiple of [ALDownloader.remove], see [ALDownloader.remove].
  ///
  /// **parameters**
  ///
  /// [urls] urls
  static void remove(List<String> urls) => ALDownloaderBatcherIMP.remove(urls);

  /// Privatize constructor
  ALDownloaderBatcher._();
}
