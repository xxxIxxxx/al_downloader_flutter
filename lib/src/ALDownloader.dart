import 'ALDownloaderHandlerInterface.dart';
import 'ALDownloaderStatus.dart';
import 'ALDownloaderTypeDefine.dart';
import 'implementation/ALDownloaderIMP.dart';

/// ALDownloader
abstract class ALDownloader {
  /// Initialize
  ///
  /// It must be called first.
  static void initialize() => ALDownloaderIMP.initialize();

  /// Configure print
  ///
  /// **parameters**
  ///
  /// [enabled] set whether enable print
  ///
  /// [frequentEnabled] set whether enable frequent print
  ///
  /// **discussion**
  ///
  /// Printing before calling this function applys the default. Default is false.
  static void configurePrint(
          {bool enabled = false, bool frequentEnabled = false}) =>
      ALDownloaderIMP.configurePrint(
          enabled: enabled, frequentEnabled: frequentEnabled);

  /// Download
  ///
  /// **parameters**
  ///
  /// [url] url
  ///
  /// [downloaderHandlerInterface] downloader handler interface
  ///
  /// It is an one-off interface which will be destroyed when the download succeeded/failed.
  ///
  /// [directoryPath], [fileName]
  ///
  /// If any one of them is `null`, both of them are invalid. At this time, [ALDownloader] will
  /// generate default.
  ///
  /// [headers] download http header
  ///
  /// [redownloadIfNeeded]
  ///
  /// If [redownloadIfNeeded] is `true` and any one of [directoryPath], [fileName], [headers] content
  /// is changed than before, [url] will re-download.
  ///
  /// **return**
  ///
  /// [ALDownloaderHandlerInterfaceId] downloader handler interface id
  ///
  /// It is used for managing downloader handler interface.
  static ALDownloaderHandlerInterfaceId? download(String url,
          {String? directoryPath,
          String? fileName,
          Map<String, String>? headers,
          bool redownloadIfNeeded = true,
          ALDownloaderHandlerInterface? downloaderHandlerInterface}) =>
      ALDownloaderIMP.download(url,
          directoryPath: directoryPath,
          fileName: fileName,
          headers: headers,
          redownloadIfNeeded: redownloadIfNeeded,
          downloaderHandlerInterface: downloaderHandlerInterface);

  /// Add a downloader handler interface
  ///
  /// **parameters**
  ///
  /// [downloaderHandlerInterface] downloader handler interface
  ///
  /// It is an one-off interface which will be destroyed when the download succeeded/failed.
  ///
  /// [url] url
  ///
  /// **return**
  ///
  /// [ALDownloaderHandlerInterfaceId] downloader handler interface id
  ///
  /// It is used for managing downloader handler interface.
  static ALDownloaderHandlerInterfaceId addDownloaderHandlerInterface(
          ALDownloaderHandlerInterface downloaderHandlerInterface,
          String url) =>
      ALDownloaderIMP.addDownloaderHandlerInterface(
          downloaderHandlerInterface, url);

  /// Add a forever downloader handler interface
  ///
  /// **parameters**
  ///
  /// [downloaderHandlerInterface] downloader handler interface
  ///
  /// It is a forever interface which never is destroyed unless the fllowing function is called.
  ///
  /// [removeDownloaderHandlerInterfaceForUrl], [removeDownloaderHandlerInterfaceForId], [removeDownloaderHandlerInterfaceForAll]
  ///
  /// [url] url
  ///
  /// **return**
  ///
  /// [ALDownloaderHandlerInterfaceId] downloader handler interface id
  ///
  /// It is used for managing downloader handler interface.
  static ALDownloaderHandlerInterfaceId addForeverDownloaderHandlerInterface(
          ALDownloaderHandlerInterface downloaderHandlerInterface,
          String url) =>
      ALDownloaderIMP.addForeverDownloaderHandlerInterface(
          downloaderHandlerInterface, url);

  /// Remove downloader handler interface
  ///
  /// **parameters**
  ///
  /// [url] url
  static void removeDownloaderHandlerInterfaceForUrl(String url) =>
      ALDownloaderIMP.removeDownloaderHandlerInterfaceForUrl(url);

  /// Remove downloader handler interface
  ///
  /// **parameters**
  ///
  /// [id] downloader handler interface id
  ///
  /// It is generated by [download], [addDownloaderHandlerInterface], [addForeverDownloaderHandlerInterface].
  static void removeDownloaderHandlerInterfaceForId(
          ALDownloaderHandlerInterfaceId id) =>
      ALDownloaderIMP.removeDownloaderHandlerInterfaceForId(id);

  /// Remove all downloader handler interfaces
  static void removeDownloaderHandlerInterfaceForAll() =>
      ALDownloaderIMP.removeDownloaderHandlerInterfaceForAll();

  /// Get download status
  ///
  /// **parameters**
  ///
  /// [url] url
  ///
  /// **return**
  ///
  /// [ALDownloaderStatus] status
  static Future<ALDownloaderStatus> getStatusForUrl(String url) =>
      ALDownloaderIMP.getStatusForUrl(url);

  /// Get download progress
  ///
  /// **parameters**
  ///
  /// [url] url
  ///
  /// **return**
  ///
  /// [double] progress
  static Future<double> getProgressForUrl(String url) =>
      ALDownloaderIMP.getProgressForUrl(url);

  /// Pause download
  ///
  /// Stop download, but the incomplete data will not be deleted.
  ///
  /// **parameters**
  ///
  /// [url] url
  static void pause(String url) => ALDownloaderIMP.pause(url);

  /// Pause all downloads
  ///
  /// This is a multiple of [pause], see [pause].
  static void pauseAll() => ALDownloaderIMP.pauseAll();

  /// Cancel download
  ///
  /// Stop download, and the incomplete data will be deleted.
  ///
  /// **parameters**
  ///
  /// [url] url
  static void cancel(String url) => ALDownloaderIMP.cancel(url);

  /// Cancel all downloads
  ///
  /// This is a multiple of [cancel], see [cancel].
  static void cancelAll() => ALDownloaderIMP.cancelAll();

  /// Remove download
  ///
  /// Remove download, and all the data will be deleted.
  ///
  /// **parameters**
  ///
  /// [url] url
  static void remove(String url) => ALDownloaderIMP.remove(url);

  /// Remove all downloads
  ///
  /// This is a multiple of [remove], see [remove].
  static void removeAll() => ALDownloaderIMP.removeAll();

  /// Privatize constructor
  ALDownloader._();
}
