import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:handyman_provider_flutter/auth/sign_in_screen.dart';
import 'package:handyman_provider_flutter/components/app_widgets.dart';
import 'package:handyman_provider_flutter/components/back_widget.dart';
import 'package:handyman_provider_flutter/components/cached_image_widget.dart';
import 'package:handyman_provider_flutter/main.dart';
import 'package:handyman_provider_flutter/models/caregory_response.dart';
import 'package:handyman_provider_flutter/networks/rest_apis.dart';
import 'package:handyman_provider_flutter/utils/constant.dart';
import 'package:nb_utils/nb_utils.dart';

class NotificationCategoriesScreen extends StatefulWidget {
  /// When true, shown at app start (after language selection) before login; shows Continue button to go to SignIn.
  final bool isFromOnboarding;

  const NotificationCategoriesScreen({Key? key, this.isFromOnboarding = false}) : super(key: key);

  @override
  State<NotificationCategoriesScreen> createState() =>
      _NotificationCategoriesScreenState();
}

class _NotificationCategoriesScreenState
    extends State<NotificationCategoriesScreen> {
  List<CategoryData> categories = [];
  List<int> selectedCategoryIds = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadSavedSelection();
    fetchCategories();
  }

  void loadSavedSelection() {
    try {
      final saved =
          getStringAsync(NOTIFICATION_CATEGORY_IDS, defaultValue: '[]');
      final list = jsonDecode(saved) as List<dynamic>?;
      if (list != null) {
        selectedCategoryIds = list.map((e) => (e as num).toInt()).toList();
      }
    } catch (_) {
      selectedCategoryIds = [];
    }
  }

  Future<void> fetchCategories() async {
    setState(() => isLoading = true);
    try {
      final response =
          await getCategoryList(perPage: CATEGORY_TYPE_ALL);
      setState(() {
        categories = response.data ?? [];
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      toast(e.toString());
    }
  }

  Future<void> saveSelection() async {
    await setValue(NOTIFICATION_CATEGORY_IDS, jsonEncode(selectedCategoryIds));
    toast(languages.saveChanges);
    if (widget.isFromOnboarding) {
      _continueToLogin();
    } else {
      finish(context, true);
    }
  }

  Future<void> _continueToLogin() async {
    await setValue(NOTIFICATION_CATEGORY_IDS, jsonEncode(selectedCategoryIds));
    SignInScreen().launch(context, isNewTask: true, pageRouteAnimation: PageRouteAnimation.Fade);
    finish(context);
  }

  void toggleCategory(int id) {
    setState(() {
      if (selectedCategoryIds.contains(id)) {
        selectedCategoryIds.remove(id);
      } else {
        selectedCategoryIds.add(id);
      }
    });
  }

  void selectAll() {
    setState(() {
      selectedCategoryIds =
          categories.map((c) => c.id.validate()).whereType<int>().toList();
    });
  }

  void deselectAll() {
    setState(() => selectedCategoryIds = []);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarWidget(
        languages.notificationCategories,
        textColor: white,
        textSize: 15,
        color: context.primaryColor,
        backWidget: widget.isFromOnboarding ? SizedBox.shrink() : BackWidget(),
        actions: widget.isFromOnboarding
            ? null
            : [
                TextButton(
                  onPressed: saveSelection,
                  child: Text(
                    languages.saveChanges,
                    style: boldTextStyle(color: white, size: 12),
                  ),
                ),
              ],
      ),
      body: isLoading
          ? LoaderWidget()
          : Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(16),
                  child: SettingItemWidget(
                    decoration: BoxDecoration(
                      color: context.cardColor,
                      borderRadius: radius(),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    title: languages.all,
                    titleTextStyle: primaryTextStyle(),
                    trailing: Checkbox(
                      value: categories.isNotEmpty &&
                          categories
                              .map((c) => c.id)
                              .whereType<int>()
                              .every((id) => selectedCategoryIds.contains(id)),
                      tristate: false,
                      onChanged: (value) {
                        if (value == true) {
                          selectAll();
                        } else {
                          deselectAll();
                        }
                      },
                      activeColor: context.primaryColor,
                    ),
                    onTap: () {
                      final allIds = categories.map((c) => c.id).whereType<int>().toList();
                      final isAllSelected = allIds.isNotEmpty &&
                          allIds.every((id) => selectedCategoryIds.contains(id));
                      if (isAllSelected) {
                        deselectAll();
                      } else {
                        selectAll();
                      }
                    },
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final id = category.id;
                      if (id == null) return SizedBox.shrink();
                      final isSelected = selectedCategoryIds.contains(id);
                      return SettingItemWidget(
                        decoration: BoxDecoration(
                          color: context.cardColor,
                          borderRadius: radius(),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        title: category.name.validate(),
                        titleTextStyle: primaryTextStyle(),
                        leading: category.categoryImage.validate().isNotEmpty
                            ? CachedImageWidget(
                                url: category.categoryImage.validate(),
                                height: 40,
                                width: 40,
                                fit: BoxFit.cover,
                                radius: 8,
                              )
                            : Icon(
                                Icons.category_outlined,
                                color: context.primaryColor,
                                size: 24,
                              ),
                        trailing: Checkbox(
                          value: isSelected,
                          onChanged: (_) => toggleCategory(id),
                          activeColor: context.primaryColor,
                        ),
                        onTap: () => toggleCategory(id),
                      ).paddingOnly(bottom: 8);
                    },
                  ),
                ),
                if (widget.isFromOnboarding)
                  Padding(
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 16,
                      bottom: 16 + MediaQuery.of(context).padding.bottom,
                    ),
                    child: AppButton(
                      text: languages.lblNext,
                      color: context.primaryColor,
                      textStyle: boldTextStyle(color: white),
                      width: context.width(),
                      onTap: _continueToLogin,
                    ),
                  ),
              ],
            ),
    );
  }
}
