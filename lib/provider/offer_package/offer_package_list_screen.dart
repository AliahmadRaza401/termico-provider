import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:handyman_provider_flutter/components/app_widgets.dart';
import 'package:handyman_provider_flutter/main.dart';
import 'package:handyman_provider_flutter/models/offer_package_model.dart';
import 'package:handyman_provider_flutter/networks/rest_apis.dart';
import 'package:handyman_provider_flutter/utils/configs.dart';
import 'package:handyman_provider_flutter/utils/extensions/num_extenstions.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../components/base_scaffold_widget.dart';
import '../../components/empty_error_state_widget.dart';
import '../../utils/colors.dart';
import '../../utils/constant.dart';
import '../../utils/common.dart';

class OfferPackageListScreen extends StatefulWidget {
  @override
  _OfferPackageListScreenState createState() => _OfferPackageListScreenState();
}

class _OfferPackageListScreenState extends State<OfferPackageListScreen> {
  Future<List<OfferPackageModel>>? future;
  List<OfferPackageModel> offerPackageList = [];
  OfferPackageStatusModel? purchasedPackageStatus;

  @override
  void initState() {
    super.initState();
    init();
    afterBuildCreated(() {
      setStatusBarColor(context.primaryColor);
    });
  }

  void init() async {
    // Load package list and status in parallel
    future = Future.wait([
      getOfferPackageList(),
      getOfferPackageStatus().catchError((e) {
        log('Error loading package status: $e');
        return OfferPackageStatusResponse();
      }),
    ]).then((results) {
      List<OfferPackageModel> packages = (results[0] as List<OfferPackageModel>);
      offerPackageList = packages.where((pkg) => pkg.status == 1).toList();
      
      OfferPackageStatusResponse statusResponse = results[1] as OfferPackageStatusResponse;
      purchasedPackageStatus = statusResponse.data;
      
      // Log the purchased package status for debugging
      if (purchasedPackageStatus != null) {
        log('📦 Purchased Package Status:');
        log('   • has_active_package: ${purchasedPackageStatus!.hasActivePackage}');
        log('   • has_package: ${purchasedPackageStatus!.hasPackage}');
        log('   • package_id: ${purchasedPackageStatus!.packageId}');
        log('   • package_name: ${purchasedPackageStatus!.packageName}');
        log('   • status: ${purchasedPackageStatus!.status}');
      }
      
      setState(() {});
      return offerPackageList;
    });
  }

  Future<void> refreshPackageStatus() async {
    try {
      OfferPackageStatusResponse response = await getOfferPackageStatus();
      purchasedPackageStatus = response.data;
      
      // Log the refreshed package status for debugging
      if (purchasedPackageStatus != null) {
        log('🔄 Refreshed Package Status:');
        log('   • package_id: ${purchasedPackageStatus!.packageId}');
        log('   • package_name: ${purchasedPackageStatus!.packageName}');
        log('   • status: ${purchasedPackageStatus!.status}');
      }
      
      setState(() {});
    } catch (e) {
      log('Error refreshing package status: $e');
    }
  }

  Future<void> buyPackage(OfferPackageModel package) async {
    // Check if this package is already purchased
    if (purchasedPackageStatus?.packageId == package.id) {
      toast('You have already purchased this package', print: true);
      return;
    }

    showConfirmDialogCustom(
      context,
      title: '${languages.lblBuy} ${package.name.validate()}?',
      primaryColor: context.primaryColor,
      positiveText: languages.lblYes,
      negativeText: languages.lblNo,
      onAccept: (context) async {
        // Show loading overlay after dialog closes
        await Future.delayed(Duration(milliseconds: 100));
        appStore.setLoading(true);
        setState(() {});

        buyOfferPackage(
          offerPackageId: package.id.validate(),
          paymentId: '',
          paymentMethodName: '',
        ).then((value) async {
          appStore.setLoading(false);
          setState(() {});

          // Store package info
          await appStore.setHasOfferPackage(true);
          await appStore.setOfferPackageName(package.name.validate());
          await appStore.setOfferPackageOffersPerMonth(package.offersPerMonth.validate());
          await appStore.setOfferPackageId(package.id.validate());

          // Refresh package status after purchase
          await refreshPackageStatus();

          // Show success toast
          toast(value.message ?? languages.lblSuccess, print: true);

          // Navigate back to profile screen after a short delay to ensure toast is visible
          await Future.delayed(Duration(milliseconds: 500));
          finish(context, true);
        }).catchError((e) {
          appStore.setLoading(false);
          setState(() {});
          // Display error message from API or fallback to generic message
          String errorMessage = e.toString();
          if (errorMessage.contains('Demo user') || errorMessage.contains('demo user') || errorMessage.contains('tester')) {
            toast(languages.lblUnAuthorized, print: true);
          } else {
            toast(errorMessage, print: true);
          }
        });
      },
    );
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBarTitle: languages.lblJobOfferPackages,
      body: Stack(
        children: [
          SnapHelperWidget<List<OfferPackageModel>>(
            future: future,
            loadingWidget: Container(
              padding: EdgeInsets.all(16),
              child: ListView.builder(
                itemCount: 3,
                itemBuilder: (context, index) {
                  return Container(
                    margin: EdgeInsets.only(bottom: 16),
                    padding: EdgeInsets.all(16),
                    decoration: boxDecorationRoundedWithShadow(defaultRadius.toInt(), backgroundColor: context.cardColor),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(height: 20, width: 150, color: Colors.grey.withAlpha(100)).cornerRadiusWithClipRRect(8),
                        8.height,
                        Container(height: 16, width: double.infinity, color: Colors.grey.withAlpha(100)).cornerRadiusWithClipRRect(8),
                        8.height,
                        Container(height: 16, width: 200, color: Colors.grey.withAlpha(100)).cornerRadiusWithClipRRect(8),
                      ],
                    ),
                  );
                },
              ),
            ),
            onSuccess: (snap) {
              return RefreshIndicator(
                onRefresh: () async {
                  await Future.wait([
                    getOfferPackageList().then((value) {
                      offerPackageList = value.where((pkg) => pkg.status == 1).toList();
                      setState(() {});
                    }),
                    refreshPackageStatus(),
                  ]);
                },
                child: CustomScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  slivers: [
                  // Purchased package section - use hasActivePackage from API response
                  if (purchasedPackageStatus != null && ((purchasedPackageStatus?.hasActivePackage == true) || (purchasedPackageStatus?.hasPackage == true)))
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: _buildPurchasedPackageCard(),
                      ),
                    ),
                  
                  // Available packages section
                  if (snap.isEmpty && (purchasedPackageStatus == null || ((purchasedPackageStatus?.hasActivePackage != true) && (purchasedPackageStatus?.hasPackage != true))))
                    SliverFillRemaining(
                      child: NoDataWidget(
                        title: languages.noDataFound,
                        imageWidget: EmptyStateWidget(),
                      ),
                    )
                  else if (snap.isNotEmpty)
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(16, purchasedPackageStatus != null && ((purchasedPackageStatus?.hasActivePackage == true) || (purchasedPackageStatus?.hasPackage == true)) ? 8 : 16, 16, 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            OfferPackageModel package = snap[index];
                            // Match purchased package by packageId from API response
                            bool isPurchased = purchasedPackageStatus != null && 
                                               purchasedPackageStatus?.packageId != null && 
                                               purchasedPackageStatus?.packageId == package.id;
                            
                            return Container(
                              margin: EdgeInsets.only(bottom: 20),
                              child: _buildPackageCard(package, isPurchased: isPurchased),
                            );
                          },
                          childCount: snap.length,
                        ),
                      ),
                    ),
                ],
                ),
              );
            },
            errorBuilder: (error) {
              return NoDataWidget(
                title: error,
                imageWidget: ErrorStateWidget(),
                retryText: languages.reload,
                onRetry: () {
                  appStore.setLoading(true);
                  init();
                  setState(() {});
                },
              );
            },
          ),
          Observer(
            builder: (context) => appStore.isLoading
                ? Container(
                    color: Colors.black.withOpacity(0.5),
                    child: Center(
                      child: Container(
                        padding: EdgeInsets.all(24),
                        decoration: boxDecorationWithRoundedCorners(
                          borderRadius: radius(16),
                          backgroundColor: context.cardColor,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            LoaderWidget(size: 50),
                            16.height,
                            Text(
                              '${languages.lblBuy}...',
                              style: primaryTextStyle(size: 14, color: primaryColor),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildPurchasedPackageCard() {
    if (purchasedPackageStatus == null) return SizedBox.shrink();

    final status = purchasedPackageStatus!;
    final isActive = status.status?.toLowerCase() == 'active';
    final statusColor = isActive ? Colors.green : Colors.orange;
    
    // Use packageName directly from API response (should be "Free" from the API)
    final packageName = (status.packageName != null && status.packageName!.isNotEmpty)
        ? status.packageName!
        : languages.lblJobOfferPackages;

    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: radius(defaultRadius.toDouble()),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 0,
          ),
        ],
        border: Border.all(
          color: statusColor.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with status badge
          Container(
            padding: EdgeInsets.all(20),
            decoration: boxDecorationWithRoundedCorners(
              borderRadius: BorderRadius.vertical(top: Radius.circular(defaultRadius)),
              backgroundColor: statusColor.withOpacity(0.1),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: statusColor, size: 24),
                12.width,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              packageName,
                              style: boldTextStyle(color: appTextPrimaryColor, size: 20),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: boxDecorationWithRoundedCorners(
                              borderRadius: radius(12),
                              backgroundColor: statusColor,
                            ),
                            child: Text(
                              status.status?.toUpperCase() ?? '',
                              style: boldTextStyle(color: whiteColor, size: 11),
                            ),
                          ),
                        ],
                      ),
                      4.height,
                      Text(
                        'Current Package',
                        style: secondaryTextStyle(color: appTextSecondaryColor, size: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Content section
          Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Offers info
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: boxDecorationWithRoundedCorners(
                    borderRadius: radius(8),
                    backgroundColor: primaryColor.withOpacity(0.1),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.stars_rounded, color: primaryColor, size: 22),
                          12.width,
                          Expanded(
                            child: Text(
                              '${languages.lblOffersPerMonth}: ${status.offersPerMonth ?? 0}',
                              style: boldTextStyle(size: 16, color: primaryColor),
                            ),
                          ),
                        ],
                      ),
                      12.height,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  '${status.offersUsed ?? 0}',
                                  style: boldTextStyle(size: 18, color: appTextPrimaryColor),
                                ),
                                4.height,
                                Text(
                                  'Used',
                                  style: secondaryTextStyle(size: 12),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 30,
                            color: borderColor,
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  '${status.offersRemaining ?? 0}',
                                  style: boldTextStyle(size: 18, color: statusColor),
                                ),
                                4.height,
                                Text(
                                  'Remaining',
                                  style: secondaryTextStyle(size: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Dates
                if (status.startAt != null || status.endAt != null) ...[
                  16.height,
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: boxDecorationWithRoundedCorners(
                      borderRadius: radius(8),
                      backgroundColor: context.scaffoldBackgroundColor,
                      border: Border.all(color: borderColor, width: 1),
                    ),
                    child: Column(
                      children: [
                        if (status.startAt != null && status.startAt!.isNotEmpty)
                          Row(
                            children: [
                              Icon(Icons.calendar_today, color: appTextSecondaryColor, size: 16),
                              8.width,
                              Expanded(
                                child: Text(
                                  'Start Date: ${formatDate(status.startAt!, format: DATE_FORMAT_1)}',
                                  style: secondaryTextStyle(size: 12),
                                ),
                              ),
                            ],
                          ),
                        if (status.startAt != null && status.startAt!.isNotEmpty && status.endAt != null && status.endAt!.isNotEmpty) 8.height,
                        if (status.endAt != null && status.endAt!.isNotEmpty)
                          Row(
                            children: [
                              Icon(Icons.event, color: appTextSecondaryColor, size: 16),
                              8.width,
                              Expanded(
                                child: Text(
                                  'End Date: ${formatDate(status.endAt!, format: DATE_FORMAT_1)}',
                                  style: secondaryTextStyle(size: 12),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageCard(OfferPackageModel package, {bool isPurchased = false}) {
    return Opacity(
      opacity: isPurchased ? 0.6 : 1.0,
      child: IgnorePointer(
        ignoring: isPurchased,
        child: Container(
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: radius(defaultRadius.toDouble()),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
                spreadRadius: 0,
              ),
            ],
            border: isPurchased ? Border.all(
              color: Colors.grey.withOpacity(0.5),
              width: 2,
            ) : null,
          ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with gradient background
          Container(
            padding: EdgeInsets.all(20),
            decoration: boxDecorationWithRoundedCorners(
              borderRadius: BorderRadius.vertical(top: Radius.circular(defaultRadius)),
              backgroundColor: isPurchased ? Colors.grey.withOpacity(0.7) : primaryColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  package.name.validate(),
                                  style: boldTextStyle(color: whiteColor, size: 22),
                                ),
                              ),
                              if (isPurchased) ...[
                                8.width,
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: boxDecorationWithRoundedCorners(
                                    borderRadius: radius(12),
                                    backgroundColor: Colors.green,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.check_circle, color: whiteColor, size: 16),
                                      4.width,
                                      Text(
                                        'PURCHASED',
                                        style: boldTextStyle(color: whiteColor, size: 10),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          4.height,
                          Text(
                            languages.lblJobOfferPackages,
                            style: secondaryTextStyle(color: whiteColor.withOpacity(0.9), size: 12),
                          ),
                        ],
                      ),
                    ),
                    12.width,
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: boxDecorationWithRoundedCorners(
                        borderRadius: radius(20),
                        backgroundColor: whiteColor.withOpacity(0.2),
                      ),
                      child: Text(
                        package.price.validate().toPriceFormat(),
                        style: boldTextStyle(color: Colors.yellow.shade300, size: 20),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Content section
          Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Features row
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: boxDecorationWithRoundedCorners(
                    borderRadius: radius(8),
                    backgroundColor: primaryColor.withOpacity(0.1),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.stars_rounded, color: primaryColor, size: 22),
                      12.width,
                      Expanded(
                        child: Text(
                          '${package.offersPerMonth.validate()} ${languages.lblOffersPerMonth}',
                          style: boldTextStyle(size: 16, color: primaryColor),
                        ),
                      ),
                    ],
                  ),
                ),
                // Description
                if (package.description.validate().isNotEmpty) ...[
                  16.height,
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: boxDecorationWithRoundedCorners(
                      borderRadius: radius(8),
                      backgroundColor: context.scaffoldBackgroundColor,
                      border: Border.all(color: borderColor, width: 1),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, color: appTextSecondaryColor, size: 18),
                        8.width,
                        Expanded(
                          child: Text(
                            package.description.validate(),
                            style: secondaryTextStyle(size: 13, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                20.height,
                // Buy button
                AppButton(
                  text: isPurchased ? 'ALREADY PURCHASED' : languages.lblBuy.toUpperCase(),
                  textColor: whiteColor,
                  color: isPurchased ? Colors.grey : primaryColor,
                  width: double.infinity,
                  height: 50,
                  textStyle: boldTextStyle(size: 15, letterSpacing: 1.2, color: whiteColor),
                  shapeBorder: RoundedRectangleBorder(borderRadius: radius(8)),
                  elevation: isPurchased ? 0 : 2,
                  onTap: isPurchased ? null : () {
                    buyPackage(package);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
        ),
      ),
    );
  }
}

