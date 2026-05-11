import 'package:flutter/material.dart';
import 'package:handyman_provider_flutter/components/notification_widget.dart';
import 'package:handyman_provider_flutter/main.dart';
import 'package:handyman_provider_flutter/models/notification_list_response.dart';
import 'package:handyman_provider_flutter/networks/rest_apis.dart';
import 'package:handyman_provider_flutter/provider/services/service_detail_screen.dart';
import 'package:handyman_provider_flutter/provider/wallet/wallet_history_screen.dart';
import 'package:handyman_provider_flutter/screens/booking_detail_screen.dart';
import 'package:handyman_provider_flutter/utils/common.dart';
import 'package:handyman_provider_flutter/utils/constant.dart';
import 'package:handyman_provider_flutter/utils/model_keys.dart';
import 'package:nb_utils/nb_utils.dart';

import '../components/app_widgets.dart';
import '../components/base_scaffold_widget.dart';
import '../components/empty_error_state_widget.dart';

class NotificationFragment extends StatefulWidget {
  @override
  NotificationScreenState createState() => NotificationScreenState();
}

class NotificationScreenState extends State<NotificationFragment> {
  Future<List<NotificationData>>? future;
  List<NotificationData> list = [];
  List<NotificationData> allNotifications = [];

  int page = 1;
  bool isLastPage = false;
  String? selectedCategory = 'all';

  List<Map<String, String>> notificationCategories = [];

  @override
  void initState() {
    super.initState();

    // Initialize localized notification categories
    notificationCategories = [
      {'key': 'all', 'label': languages.all},
      {'key': BOOKING, 'label': languages.booking},
      {'key': WALLET, 'label': languages.wallet},
      {'key': PAYOUT, 'label': languages.payout},
      {'key': SERVICE_REQUEST_APPROVE, 'label': languages.service},
      {'key': SERVICE_REQUEST_REJECT, 'label': languages.service},
      {'key': PROVIDER_SEND_BID, 'label': languages.bid},
      {'key': POSTJOB, 'label': languages.postJob},
      {'key': PAYMENT_MESSAGE_STATUS, 'label': languages.paymentStatus},
    ];
    
    // Store cached notifications in allNotifications if available
    if (cachedNotifications != null && cachedNotifications!.isNotEmpty) {
      allNotifications = List.from(cachedNotifications!);
    }

    LiveStream().on(LIVESTREAM_UPDATE_NOTIFICATIONS, (p0) {
      appStore.setLoading(true);

      init(type: MARK_AS_READ);
      setState(() {});
    });
    init();
  }

  Future<void> init({String type = ''}) async {
    future = getNotification(
      {NotificationKey.type: type},
      notificationList: list,
      lastPageCallback: (val) => isLastPage = val,
    ).then((notifications) {
      // Always store unfiltered notifications from API
      allNotifications = List.from(notifications);
      // Return all notifications - filtering will happen in onSuccess
      return allNotifications;
    });
  }

  List<NotificationData> _getFilteredNotifications() {
    if (selectedCategory == 'all' || selectedCategory == null) {
      return allNotifications;
    }
    return allNotifications.where((notification) {
      String? notificationType = notification.data?.notificationType;
      if (notificationType == null) return false;
      
      String lowerType = notificationType.toLowerCase();
      
      // Handle special cases
      if (selectedCategory == BOOKING) {
        return lowerType.contains(BOOKING) || 
               lowerType.contains(PAYMENT_MESSAGE_STATUS);
      }
      if (selectedCategory == WALLET) {
        return lowerType.contains(WALLET) || 
               lowerType.contains(PAYOUT);
      }
      if (selectedCategory == SERVICE_REQUEST_APPROVE) {
        return lowerType.contains(SERVICE_REQUEST_APPROVE) || 
               lowerType.contains(SERVICE_REQUEST_REJECT);
      }
      if (selectedCategory == PROVIDER_SEND_BID) {
        // Include all bid-related notifications
        return lowerType.contains('bid') || 
               lowerType.contains(PROVIDER_SEND_BID) ||
               lowerType.contains(USER_ACCEPT_BID) ||
               lowerType.contains('job_bid') ||
               lowerType.contains('bid_accepted') ||
               lowerType.contains('bid_accept');
      }
      
      return lowerType.contains(selectedCategory!.toLowerCase());
    }).toList();
  }

  void _applyFilter() {
    setState(() {
      // Trigger rebuild by creating a new future
      // The onSuccess callback will apply the filter based on selectedCategory
      if (allNotifications.isNotEmpty) {
        // Use Future.microtask to ensure a new Future instance each time
        future = Future<List<NotificationData>>.microtask(() => allNotifications);
      }
    });
  }

  Future<void> readNotificationGeneric({required String type, String? id}) async {
    //TODO: check for booking_id
    // Map request = {CommonKeys.bookingId: id};
    Map request = {CommonKeys.serviceId: id};

    try {
      if (type == 'booking') {
        await bookingDetail(request);
      } else if (type == 'service') {
        await getServiceDetail(request);
      }
      init();
    } catch (e) {
      log(e.toString());
    }
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  void dispose() {
    LiveStream().dispose(LIVESTREAM_UPDATE_NOTIFICATIONS);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBarTitle: Navigator.canPop(context) ? languages.notification : null,
      actions: [
        IconButton(
          icon: Icon(Icons.clear_all_rounded, color: Colors.white),
          onPressed: () async {
            showConfirmDialogCustom(
              context,
              onAccept: (_) async {
                appStore.setLoading(true);

                init(type: MARK_AS_READ);
                setState(() {});
              },
              primaryColor: context.primaryColor,
              negativeText: languages.lblNo,
              positiveText: languages.lblYes,
              title: languages.confirmationRequestTxt,
            );
          },
        ),
      ],
      body: SnapHelperWidget<List<NotificationData>>(
        key: ValueKey(selectedCategory),
        initialData: cachedNotifications,
        future: future,
        loadingWidget: LoaderWidget(),
        onSuccess: (list) {
          // Store all notifications if not already stored
          if (allNotifications.isEmpty && list.isNotEmpty) {
            allNotifications = List.from(list);
          }
          
          // Get filtered list based on current selected category
          List<NotificationData> filteredList = _getFilteredNotifications();
          
          return Column(
            children: [
              _buildCategoryFilter(),
              Expanded(
                child: AnimatedListView(
                  itemCount: filteredList.length,
                  shrinkWrap: true,
                  listAnimationType: ListAnimationType.FadeIn,
                  fadeInConfiguration: FadeInConfiguration(duration: 2.seconds),
                  emptyWidget: NoDataWidget(
                    title: languages.noNotificationTitle,
                    subTitle: languages.noNotificationSubTitle,
                    imageWidget: EmptyStateWidget(),
                  ),
                  itemBuilder: (context, index) {
                    NotificationData data = filteredList[index];
                    
                    return Container(
                      width: double.infinity,
                      child: NotificationWidget(
                        data: data,
                        onTap: () async {
                          if (isUserTypeProvider) {
                            if (data.data!.notificationType.validate().contains(WALLET) || data.data!.notificationType.validate().contains(PAYOUT)) {
                              WalletHistoryScreen().launch(context);
                            } else if (data.data!.notificationType.validate().contains(BOOKING) || data.data!.notificationType.validate().contains(PAYMENT_MESSAGE_STATUS)) {
                              readNotificationGeneric(type: 'booking', id: data.data!.id.toString());
                              BookingDetailScreen(bookingId: data.data!.id).launch(context);
                            }

                            ///handle post job detail on notification click
                            /*else if (data.data!.notificationType.validate().contains(POSTJOB)) {
                              readNotification(id: data.data!.id.toString());
                              getPostJobDetail({PostJob.postRequestId: data.data!.id}).then((response) {
                                if (response.postRequestDetail != null) {
                                  JobPostDetailScreen(postJobData: response.postRequestDetail!).launch(context);
                                } else {
                                  toast("Post job data not found.");
                                }
                              }).catchError((e) {
                                toast(e.toString());
                              });
                            }*/
                            else if (data.data!.notificationType.validate().contains(SERVICE_REQUEST_APPROVE) || data.data!.notificationType.validate().contains(SERVICE_REQUEST_REJECT)) {
                              readNotificationGeneric(type: 'service', id: data.data!.id.toString());
                              ServiceDetailScreen(serviceId: data.data!.id).launch(context);
                            } else {
                              //
                            }
                          }
                        },
                      ),
                    );
                  },
                  onSwipeRefresh: () async {
                    page = 1;
                    init();
                    setState(() {});
                    return await 2.seconds.delay;
                  },
                ),
              ),
            ],
          );
        },
        errorBuilder: (error) {
          return NoDataWidget(
            title: error,
            imageWidget: ErrorStateWidget(),
            retryText: languages.reload,
            onRetry: () {
              page = 1;
              appStore.setLoading(true);
              init();
              setState(() {});
            },
          );
        },
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 50,
      margin: EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16),
        itemCount: notificationCategories.length,
        itemBuilder: (context, index) {
          Map<String, String> category = notificationCategories[index];
          bool isSelected = selectedCategory == category['key'];
          
          return GestureDetector(
            onTap: () {
              selectedCategory = category['key'];
              _applyFilter();
            },
            child: Container(
              margin: EdgeInsets.only(right: 8),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected 
                    ? context.primaryColor 
                    : context.cardColor,
                borderRadius: radius(20),
                border: Border.all(
                  color: isSelected 
                      ? context.primaryColor 
                      : context.dividerColor,
                ),
              ),
              child: Center(
                child: Text(
                  category['label']!,
                  style: boldTextStyle(
                    size: 12,
                    color: isSelected ? white : textPrimaryColorGlobal,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
