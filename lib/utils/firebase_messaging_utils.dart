import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:handyman_provider_flutter/provider/jobRequest/bid_list_screen.dart';
import 'package:handyman_provider_flutter/utils/common.dart';
import 'package:http/http.dart' as http;
import 'package:nb_utils/nb_utils.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

import '../main.dart';
import '../provider/services/service_detail_screen.dart';
import '../screens/booking_detail_screen.dart';
import '../screens/chat/user_chat_list_screen.dart';
import 'constant.dart';

Future<void> initFirebaseMessaging() async {
  if (Platform.isAndroid) {
    // Android 13+ requires runtime notification permission for FCM to show notifications.
    final status = await Permission.notification.status;
    if (!status.isGranted) {
      await Permission.notification.request();
    }
    // Always register listeners on Android so FCM can deliver messages.
    await registerNotificationListeners().catchError((e) {
      log('------Notification Listener REGISTRATION ERROR-----------');
      log(e.toString());
    });
    return;
  }

  // iOS: request permission first, then register listeners only if authorized.
  await FirebaseMessaging.instance
      .requestPermission(
    alert: true,
    badge: true,
    provisional: false,
    sound: true,
  )
      .then((value) async {
    if (value.authorizationStatus == AuthorizationStatus.authorized) {
      await registerNotificationListeners().catchError((e) {
        log('------Notification Listener REGISTRATION ERROR-----------');
        log(e.toString());
      });
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
              alert: true, badge: true, sound: true)
          .catchError((e) {
        log('------setForegroundNotificationPresentationOptions ERROR-----------');
      });
    }
  });
}

Future<void> registerNotificationListeners() async {
  FirebaseMessaging.instance.setAutoInitEnabled(true).then((value) {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // Log all raw push notification data (foreground)
      log('========== PUSH NOTIFICATION RAW DATA (onMessage/foreground) ==========');
      log('message: ${message.toMap()}');
         print('message: ${message}');

      log('messageId: ${message.messageId}');
      log('sentTime: ${message.sentTime?.millisecondsSinceEpoch}');
      log('from: ${message.from}');
      log('collapseKey: ${message.collapseKey}');
      log('data (full): ${const JsonEncoder.withIndent('  ').convert(message.data)}');
      log('notification (full): ${message.notification != null ? const JsonEncoder.withIndent('  ').convert(message.notification!.toMap()) : 'null'}');
      log('categoryId from payload: ${getNotificationCategoryIdFromPayload(message)}');
      log('========================================================================');

      // Receive all; show in foreground only if category is in user's selected notification categories.
      if (message.notification != null &&
          message.notification!.title.validate().isNotEmpty &&
          message.notification!.body.validate().isNotEmpty) {
        if (shouldShowNotificationByCategory(message)) {
          showNotification(
              currentTimeStamp(),
              message.notification!.title.validate(),
              parseHtmlString(message.notification!.body.validate()),
              message);
        }
      }
    }, onError: (e) {
      log("setAutoInitEnabled error $e");
    });

    // replacement for onResume: When the app is in the background and opened directly from the push notification.
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // Log all raw push notification data (opened from background)
      log('========== PUSH NOTIFICATION RAW DATA (onMessageOpenedApp) ==========');
       print('message: ${message}');
      log('messageId: ${message.messageId}');
      log('sentTime: ${message.sentTime?.millisecondsSinceEpoch}');
      log('from: ${message.from}');
      log('collapseKey: ${message.collapseKey}');
      log('data (full): ${const JsonEncoder.withIndent('  ').convert(message.data)}');
      log('notification (full): ${message.notification != null ? const JsonEncoder.withIndent('  ').convert(message.notification!.toMap()) : 'null'}');
      log('categoryId from payload: ${getNotificationCategoryIdFromPayload(message)}');
      log('========================================================================');

      // All notifications are received; always handle tap (e.g. notification was shown by system in background).
      handleNotificationClick(message);
    }, onError: (e) {
      log("onMessageOpenedApp Error $e");
    });

    // workaround for onLaunch: When the app is completely closed (not in the background) and opened directly from the push notification
    FirebaseMessaging.instance.getInitialMessage().then(
        (RemoteMessage? message) {
      if (message != null) {
        // Log all raw push notification data (opened from terminated)
        log('========== PUSH NOTIFICATION RAW DATA (getInitialMessage) ==========');
               print('message: ${message}');

        log('messageId: ${message.messageId}');
        log('sentTime: ${message.sentTime?.millisecondsSinceEpoch}');
        log('from: ${message.from}');
        log('collapseKey: ${message.collapseKey}');
        log('data (full): ${const JsonEncoder.withIndent('  ').convert(message.data)}');
        log('notification (full): ${message.notification != null ? const JsonEncoder.withIndent('  ').convert(message.notification!.toMap()) : 'null'}');
        log('categoryId from payload: ${getNotificationCategoryIdFromPayload(message)}');
        log('========================================================================');

        // All notifications are received; always handle tap.
        handleNotificationClick(message);
      }
    }, onError: (e) {
      log("getInitialMessage error : $e");
    });
  }).onError((error, stackTrace) {
    log("onGetInitialMessage error: $error");
  });
}

Future<bool> subscribeToFirebaseTopic() async {
  bool result = appStore.isSubscribedForPushNotification;
  await initFirebaseMessaging();
  if (appStore.isLoggedIn) {
    if (Platform.isIOS) {
      String? apnsToken = await FirebaseMessaging.instance.getAPNSToken();
      if (apnsToken == null) {
        await 3.seconds.delay;
        apnsToken = await FirebaseMessaging.instance.getAPNSToken();
      }
      log('Apn Token=========${apnsToken}');
    }

    await FirebaseMessaging.instance
        .subscribeToTopic('user_${appStore.userId}')
        .then((value) {
      result = true;
      log("topic-----subscribed----> user_${appStore.userId}");
    });
    final topicTag =  PROVIDER_APP_TAG;
    await FirebaseMessaging.instance.subscribeToTopic(topicTag).then((value) {
      result = true;
      log("topic-----subscribed----> $topicTag");
    });

    // No category topic subscription: receive all notifications; filtering by category is done in the frontend only (shouldShowNotificationByCategory).
    await appStore.setPushNotificationSubscriptionStatus(result);
  }
  return result;
}

/// Returns the list of category IDs the provider selected to receive notifications for.
List<int> getNotificationCategoryIds() {
  try {
    final saved = getStringAsync(NOTIFICATION_CATEGORY_IDS, defaultValue: '[]');
    final list = jsonDecode(saved) as List<dynamic>?;
    if (list != null) {
      return list.map((e) => (e as num).toInt()).toList();
    }
  } catch (_) {}
  return [];
}

/// Extracts category_id from FCM payload (data or additional_data).
int? getNotificationCategoryIdFromPayload(RemoteMessage message) {
  // Direct in data
  final data = message.data;
  if (data['category_id'] != null) {
    final v = data['category_id'];
    if (v is int) return v;
    if (v is String) return int.tryParse(v);
  }
  if (data['category'] != null) {
    final v = data['category'];
    if (v is int) return v;
    if (v is String) return int.tryParse(v);
  }
  // Inside additional_data JSON
  if (data.containsKey('additional_data')) {
    try {
      final additionalData = jsonDecode(data['additional_data'] as String) as Map<String, dynamic>?;
      if (additionalData == null) return null;
      if (additionalData['category_id'] != null) {
        final v = additionalData['category_id'];
        if (v is int) return v;
        if (v is String) return int.tryParse(v);
      }
      if (additionalData['category'] != null) {
        final v = additionalData['category'];
        if (v is int) return v;
        if (v is String) return int.tryParse(v);
      }
    } catch (_) {}
  }
  return null;
}

/// Returns true if this notification should be shown/handled based on provider's selected notification categories.
bool shouldShowNotificationByCategory(RemoteMessage message) {
  final selectedIds = getNotificationCategoryIds();
  if (selectedIds.isEmpty) return true;
  final payloadCategoryId = getNotificationCategoryIdFromPayload(message);
  if (payloadCategoryId == null) return true;
  return selectedIds.contains(payloadCategoryId);
}

/// Updates FCM topic subscriptions when notification categories are changed.
Future<void> updateNotificationCategorySubscriptions(
    List<int> oldIds, List<int> newIds) async {
  final toUnsubscribe = oldIds.where((id) => !newIds.contains(id)).toList();
  final toSubscribe = newIds.where((id) => !oldIds.contains(id)).toList();
  for (final id in toUnsubscribe) {
    await FirebaseMessaging.instance.unsubscribeFromTopic('category_$id');
    log("topic-----unsubscribed----> category_$id");
  }
  for (final id in toSubscribe) {
    await FirebaseMessaging.instance.subscribeToTopic('category_$id');
    log("topic-----subscribed----> category_$id");
  }
}

Future<bool> unsubscribeFirebaseTopic(int userId) async {
  bool result = appStore.isSubscribedForPushNotification;
  await FirebaseMessaging.instance
      .unsubscribeFromTopic('user_$userId')
      .then((_) {
    result = false;
    log("topic-----unsubscribed----> user_$userId");
  });
  final topicTag = PROVIDER_APP_TAG;
  await FirebaseMessaging.instance.unsubscribeFromTopic(topicTag).then((_) {
    result = false;
    log('topic-----unsubscribed---->------> $topicTag');
  });

  await appStore.setPushNotificationSubscriptionStatus(result);
  return result;
}

void handleNotificationClick(RemoteMessage message) {
  if (message.data['url'] != null && message.data['url'] is String) {
    commonLaunchUrl(message.data['url'],
        launchMode: LaunchMode.externalApplication);
  }
  if (message.data.containsKey('is_chat')) {
    if (message.data.isNotEmpty) {
      navigatorKey.currentState!
          .push(MaterialPageRoute(builder: (context) => ChatListScreen()));
      // navigatorKey.currentState!.push(MaterialPageRoute(builder: (context) => UserChatScreen(receiverUser: UserData.fromJson(message.data))));
    }
  } else if (message.data.containsKey('additional_data')) {
    Map<String, dynamic> additionalData =
        jsonDecode(message.data["additional_data"]) ?? {};
    if (additionalData.containsKey('id') && additionalData['id'] != null) {
      if (additionalData.containsKey('check_booking_type') &&
          additionalData['check_booking_type'] == 'booking') {
        navigatorKey.currentState!.push(MaterialPageRoute(
            builder: (context) =>
                BookingDetailScreen(bookingId: additionalData['id'].toInt())));
      }

      if (additionalData.containsKey('notification-type') &&
          additionalData['notification-type'] == 'user_accept_bid') {
        navigatorKey.currentState!
            .push(MaterialPageRoute(builder: (context) => BidListScreen()));
      }
    }

    if (additionalData.containsKey('service_id') &&
        additionalData["service_id"] != null) {
      navigatorKey.currentState!.push(MaterialPageRoute(
          builder: (context) => ServiceDetailScreen(
              serviceId: additionalData["service_id"].toInt())));
    }
  }
}

void showNotification(
    int id, String title, String message, RemoteMessage remoteMessage) async {
  log('Notification : ${remoteMessage.notification!.toMap()}');
  log('Message Data : ${remoteMessage.data}');
  log("Provider Message Image Url : ${remoteMessage.data["image_url"]} ");
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  //code for background notification channel
  AndroidNotificationChannel channel = AndroidNotificationChannel(
    'notification',
    'Notification',
    importance: Importance.high,
    enableLights: true,
    playSound: true,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@drawable/ic_stat_ic_notification');
  var iOS = const DarwinInitializationSettings(
    requestSoundPermission: false,
    requestBadgePermission: false,
    requestAlertPermission: false,
  );
  var macOS = iOS;
  final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid, iOS: iOS, macOS: macOS);
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (details) {
      handleNotificationClick(remoteMessage);
    },
  );

  // region image logic
  Future<String> _downloadAndSaveFile(String url, String fileName) async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final String filePath = '${directory.path}/$fileName';
    final http.Response response = await http.get(Uri.parse(url));
    final File file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);
    return filePath;
  }

  BigPictureStyleInformation? bigPictureStyleInformation =
      remoteMessage.data.containsKey("image_url")
          ? BigPictureStyleInformation(
              FilePathAndroidBitmap(await _downloadAndSaveFile(
                  remoteMessage.data["image_url"], 'bigPicture')),
              largeIcon: FilePathAndroidBitmap(await _downloadAndSaveFile(
                  remoteMessage.data["image_url"], 'largeIcon')),
            )
          : null;
  // endregion

  var androidPlatformChannelSpecifics = AndroidNotificationDetails(
    'notification',
    'Notification',
    importance: Importance.high,
    visibility: NotificationVisibility.public,
    autoCancel: true,
    playSound: true,
    priority: Priority.high,
    icon: '@drawable/ic_stat_ic_notification',
    largeIcon: remoteMessage.data.containsKey("image_url")
        ? FilePathAndroidBitmap(await _downloadAndSaveFile(
            remoteMessage.data["image_url"], 'largeIcon'))
        : null,
    styleInformation: remoteMessage.data.containsKey("image_url")
        ? bigPictureStyleInformation
        : null,
  );

  var darwinPlatformChannelSpecifics = const DarwinNotificationDetails();

  var platformChannelSpecifics = NotificationDetails(
    android: androidPlatformChannelSpecifics,
    iOS: darwinPlatformChannelSpecifics,
    macOS: darwinPlatformChannelSpecifics,
  );

  flutterLocalNotificationsPlugin.show(
      id,
      remoteMessage.notification!.title.validate(),
      remoteMessage.notification!.body.validate(),
      platformChannelSpecifics);
}
