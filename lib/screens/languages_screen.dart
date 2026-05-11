import 'package:flutter/material.dart';
import 'package:handyman_provider_flutter/auth/sign_in_screen.dart';
import 'package:handyman_provider_flutter/components/back_widget.dart';
import 'package:handyman_provider_flutter/main.dart';
import 'package:handyman_provider_flutter/networks/rest_apis.dart';
import 'package:handyman_provider_flutter/provider/provider_dashboard_screen.dart';
import 'package:handyman_provider_flutter/screens/notification_categories_screen.dart';
import 'package:handyman_provider_flutter/utils/common.dart';
import 'package:nb_utils/nb_utils.dart';

import '../utils/constant.dart';

class LanguagesScreen extends StatefulWidget {
  final bool isFirstTime;

  LanguagesScreen({this.isFirstTime = false});

  @override
  LanguagesScreenState createState() => LanguagesScreenState();
}

class LanguagesScreenState extends State<LanguagesScreen> {
  @override
  void initState() {
    super.initState();
  }

  Future<void> refreshList() async {
    dayListMap = {
      languages.mon: "mon",
      languages.tue: "tue",
      languages.wed: "wed",
      languages.thu: "thu",
      languages.fri: "fri",
      languages.sat: "sat",
      languages.sun: "sun",
    };
    daysList = [
      languages.mon,
      languages.tue,
      languages.wed,
      languages.thu,
      languages.fri,
      languages.sat,
      languages.sun,
    ];
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  Future<void> updateProfilePhoto() async {
    getUserDetail(appStore.userId).then((value) async {
      await appStore.setUserProfile(value.data!.profileImage.validate());
    });
  }

  Future<void> saveAndNavigate() async {
    // Language is already applied when user clicks on it
    // Just refresh the list and navigate
    await refreshList();
    setState(() {});

    // Mark first time as false if it was first time
    if (widget.isFirstTime) {
      await setValue(IS_FIRST_TIME, false);
      
      // Navigate to appropriate screen based on login status
      if (!appStore.isLoggedIn) {
        // Show notification categories first, then user continues to login
        NotificationCategoriesScreen(isFromOnboarding: true).launch(context,
            isNewTask: true, pageRouteAnimation: PageRouteAnimation.Fade);
      } else {
        await updateProfilePhoto();
        if (isUserTypeProvider) {
          setStatusBarColor(context.primaryColor);
          ProviderDashboardScreen(index: 0).launch(context,
              isNewTask: true, pageRouteAnimation: PageRouteAnimation.Fade);
        } else {
          SignInScreen().launch(context, isNewTask: true);
        }
      }
    } else {
      // Normal flow - just go back
      finish(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarWidget(
        languages.language,
        textColor: white,
        elevation: 0.0,
        color: context.primaryColor,
        backWidget: widget.isFirstTime ? SizedBox.shrink() : BackWidget(),
      ),
      body: Column(
        children: [
          LanguageListWidget(
            widgetType: WidgetType.LIST,
            onLanguageChange: (v) async {
              // Apply language immediately for visual feedback
              await appStore.setLanguage(v.languageCode!);
              await refreshList();
              setState(() {});
              // Don't navigate yet - wait for save button
            },
          ).expand(),
          // Save button at the bottom
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: 16 + MediaQuery.of(context).padding.bottom,
            ),
            decoration: boxDecorationDefault(
              color: context.scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: AppButton(
              text: languages.btnSave,
              color: context.primaryColor,
              textStyle: boldTextStyle(color: white),
              width: context.width(),
              onTap: () {
                saveAndNavigate();
              },
            ),
          ),
        ],
      ),
    );
  }
}