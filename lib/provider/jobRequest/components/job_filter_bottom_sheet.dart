import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:handyman_provider_flutter/components/app_widgets.dart';
import 'package:handyman_provider_flutter/main.dart';
import 'package:handyman_provider_flutter/models/caregory_response.dart';
import 'package:handyman_provider_flutter/networks/rest_apis.dart';
import 'package:nb_utils/nb_utils.dart';

class JobFilterBottomSheet extends StatefulWidget {
  final VoidCallback onApplyFilter;

  const JobFilterBottomSheet({Key? key, required this.onApplyFilter}) : super(key: key);

  @override
  State<JobFilterBottomSheet> createState() => _JobFilterBottomSheetState();
}

class _JobFilterBottomSheetState extends State<JobFilterBottomSheet> {
  List<CategoryData> categories = [];
  RangeValues _priceRange = RangeValues(0, 10000);
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    // Initialize from filter store
    _priceRange = RangeValues(filterStore.minPrice, filterStore.maxPrice);
    await fetchCategories();
  }

  Future<void> fetchCategories() async {
    try {
      setState(() => isLoading = true);
      var response = await getCategoryList();
      categories = response.data ?? [];
      setState(() => isLoading = false);
    } catch (e) {
      setState(() => isLoading = false);
      toast(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: context.height() * 0.75,
      decoration: boxDecorationWithRoundedCorners(
        borderRadius: radiusOnly(topLeft: 16, topRight: 16),
        backgroundColor: context.cardColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(16),
            decoration: boxDecorationWithRoundedCorners(
              borderRadius: radiusOnly(topLeft: 16, topRight: 16),
              backgroundColor: context.primaryColor.withOpacity(0.1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  languages.filter,
                  style: boldTextStyle(size: 18),
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => finish(context),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: isLoading
                ? LoaderWidget()
                : SingleChildScrollView(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Price Range Filter
                        Text(
                          'Price Range',
                          style: boldTextStyle(size: 16),
                        ),
                        8.height,
                        Observer(
                          builder: (_) => Column(
                            children: [
                              RangeSlider(
                                values: _priceRange,
                                min: 0,
                                max: 10000,
                                divisions: 100,
                                labels: RangeLabels(
                                  '\$${_priceRange.start.toInt()}',
                                  '\$${_priceRange.end.toInt()}',
                                ),
                                onChanged: (RangeValues values) {
                                  setState(() {
                                    _priceRange = values;
                                  });
                                },
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '\$${_priceRange.start.toInt()}',
                                    style: secondaryTextStyle(),
                                  ),
                                  Text(
                                    '\$${_priceRange.end.toInt()}',
                                    style: secondaryTextStyle(),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        24.height,

                        // Category Filter
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Category',
                              style: boldTextStyle(size: 16),
                            ),
                            Observer(
                              builder: (_) => Text(
                                '${filterStore.categoryId.length} Selected',
                                style: secondaryTextStyle(),
                              ),
                            ),
                          ],
                        ),
                        16.height,
                        Observer(
                          builder: (_) => Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: categories.map((category) {
                              bool isSelected = filterStore.categoryId.contains(category.id);
                              return FilterChip(
                                label: Text(category.name ?? ''),
                                selected: isSelected,
                                onSelected: (bool selected) {
                                  if (selected) {
                                    filterStore.addToCategoryList(catId: category.id!);
                                  } else {
                                    filterStore.removeFromCategoryList(catId: category.id!);
                                  }
                                  setState(() {});
                                },
                                selectedColor: context.primaryColor.withOpacity(0.2),
                                checkmarkColor: context.primaryColor,
                                labelStyle: TextStyle(
                                  color: isSelected ? context.primaryColor : null,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),

          // Bottom Actions
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: languages.reset,
                    textColor: context.primaryColor,
                    color: context.cardColor,
                    shapeBorder: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: context.primaryColor),
                    ),
                    onTap: () {
                      setState(() {
                        _priceRange = RangeValues(0, 10000);
                      });
                      filterStore.resetPriceFilter();
                      filterStore.categoryId.clear();
                      filterStore.updateFilterFlag();
                      widget.onApplyFilter();
                      finish(context);
                    },
                  ),
                ),
                16.width,
                Expanded(
                  flex: 2,
                  child: AppButton(
                    text: languages.apply,
                    color: context.primaryColor,
                    textColor: Colors.white,
                    onTap: () {
                      filterStore.setPriceRange(
                        min: _priceRange.start,
                        max: _priceRange.end,
                      );
                      widget.onApplyFilter();
                      finish(context);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

