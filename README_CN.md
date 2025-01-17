# al_downloader

[![pub package](https://img.shields.io/pub/v/al_downloader.svg)](https://pub.dartlang.org/packages/al_downloader)

一个基于url的Flutter下载器，支持下载任意类型的文件，并自动管理下载相关的各种事务。

## 特性

* 通过url管理下载任务
* 简单的下载状态
* 不频繁地I/O
* 提供便利的下载句柄
* 支持批量下载
* 自动管理文件，不需要指定下载路径
* 基于[flutter_downloader](https://pub.dev/packages/flutter_downloader)

## 集成

> 原生配置：和[flutter_downloader](https://pub.dev/packages/flutter_downloader)相同

添加下面这行代码到pubspec.yaml中
```
dependencies:
  al_downloader: ^1.8.3
```

使用命令行运行下面这行代码
```
flutter packages get
```

引入下面这行代码来使用al_downloader
```
import 'package:al_downloader/al_downloader.dart';
```

## 使用

### ALDownloader

#### 初始化
```
ALDownloader.initialize();
```

#### 配置打印
```
ALDownloader.configurePrint(true, frequentEnabled: false);
```

#### 下载
```
ALDownloader.download(url,
    directoryPath: directoryPath,
    fileName: fileName,
    handlerInterface:
        ALDownloaderHandlerInterface(progressHandler: (progress) {
      debugPrint(
          'ALDownloader | 下载进度 = $progress, url = $url\n');
    }, succeededHandler: () {
      debugPrint('ALDownloader | 下载成功, url = $url\n');
    }, failedHandler: () {
      debugPrint('ALDownloader | 下载失败, url = $url\n');
    }, pausedHandler: () {
      debugPrint('ALDownloader | 下载暂停, url = $url\n');
    }));
```

#### 添加一个下载句柄池
```
ALDownloader.addHandlerInterface(
    ALDownloaderHandlerInterface(progressHandler: (progress) {
      debugPrint(
          'ALDownloader | 下载进度 = $progress, url = $url\n');
    }, succeededHandler: () {
      debugPrint('ALDownloader | 下载成功, url = $url\n');
    }, failedHandler: () {
      debugPrint('ALDownloader | 下载失败, url = $url\n');
    }, pausedHandler: () {
      debugPrint('ALDownloader | 下载暂停, url = $url\n');
    }),
    url);
```

#### 添加一个持久下载句柄池
```
ALDownloader.addForeverHandlerInterface(
    ALDownloaderHandlerInterface(progressHandler: (progress) {
      debugPrint(
          'ALDownloader | 下载进度 = $progress, url = $url\n');
    }, succeededHandler: () {
      debugPrint('ALDownloader | 下载成功, url = $url\n');
    }, failedHandler: () {
      debugPrint('ALDownloader | 下载失败, url = $url\n');
    }, pausedHandler: () {
      debugPrint('ALDownloader | 下载暂停, url = $url\n');
    }),
    url);
```

#### 移除下载句柄池
```
ALDownloader.removeHandlerInterfaceForUrl(url);
```

#### 暂停下载
```
/// 停止下载，不删除未下载完成的数据
ALDownloader.pause(url);
```

#### 取消下载
```
/// 停止下载，删除未下载完成的数据
ALDownloader.cancel(url);
```

#### 移除下载
```
/// 删除下载，删除所有数据
ALDownloader.remove(url);
```

#### 获取下载状态
```
final status = await ALDownloader.getStatusForUrl(url);
```

#### 获取下载进度
```
final progress = await ALDownloader.getProgressForUrl(url);
```

#### 获取任务
```
final task = await ALDownloader.getTaskForUrl(url);
```

#### 获取全部任务
```
final tasks = await ALDownloader.tasks;
```

### ALDownloaderBatcher

#### 批量下载
```
ALDownloaderBatcher.download(urls,
    handlerInterface:
        ALDownloaderHandlerInterface(progressHandler: (progress) {
      debugPrint('ALDownloader | 批量 | 下载进度 = $progress\n');
    }, succeededHandler: () {
      debugPrint('ALDownloader | 批量 | 下载成功\n');
    }, failedHandler: () {
      debugPrint('ALDownloader | 批量 | 下载失败\n');
    }, pausedHandler: () {
      debugPrint('ALDownloader | 批量 | 下载暂停\n');
    }));
```

#### 对批量下载添加一个下载句柄池
```
ALDownloaderBatcher.addHandlerInterface(
    ALDownloaderHandlerInterface(progressHandler: (progress) {
      debugPrint('ALDownloader | 批量 | 下载进度 = $progress\n');
    }, succeededHandler: () {
      debugPrint('ALDownloader | 批量 | 下载成功\n');
    }, failedHandler: () {
      debugPrint('ALDownloader | 批量 | 下载失败\n');
    }, pausedHandler: () {
      debugPrint('ALDownloader | 批量 | 下载暂停\n');
    }),
    urls);
```

#### 获取一组url的下载状态
```
final status = ALDownloaderBatcher.getStatusForUrls(urls);
```

#### 获取一组任务
```
final tasks = await ALDownloaderBatcher.getTasksForUrls(urls);
```

### ALDownloaderFileManager - 基于url的文件管理器

```
final physicalFilePath =
    await ALDownloaderFileManager.getPhysicalFilePathForUrl(url);
debugPrint(
    'ALDownloader | 获取[url]的物理文件路径, url = $url, path = $physicalFilePath\n');
```

## *提示*:

*1. 如果持久化文件被一些异常方式删除了，比如某些业务代码删除了缓存文件夹，调用[remove]，然后调用[download]重新下载来解决这个问题*

## Example的主要文件

### iOS

- [main.dart](https://github.com/jackleemeta/al_downloader_flutter/blob/master/example/lib/main.dart)
- [AppDelegate.swift](https://github.com/jackleemeta/al_downloader_flutter/blob/master/example/ios/Runner/AppDelegate.swift)
- [Info.plist](https://github.com/jackleemeta/al_downloader_flutter/blob/master/example/ios/Runner/Info.plist)

### Android

- [main.dart](https://github.com/jackleemeta/al_downloader_flutter/blob/master/example/lib/main.dart)
- [AndroidManifest.xml](https://github.com/jackleemeta/al_downloader_flutter/blob/master/example/android/app/src/main/AndroidManifest.xml)

## 贡献

欢迎贡献！

如果你有任何问题、建议或想法，欢迎随时提出issue或PR！

> Maintainer: jackleemeta (jackleemeta@outlook.com)