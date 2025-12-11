import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:handyman_provider_flutter/components/app_widgets.dart';
import 'package:handyman_provider_flutter/main.dart';
import 'package:handyman_provider_flutter/networks/rest_apis.dart';
import 'package:handyman_provider_flutter/provider/jobRequest/shimmer/job_request_shimmer.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../components/base_scaffold_widget.dart';
import '../../components/empty_error_state_widget.dart';
import 'components/job_filter_bottom_sheet.dart';
import 'components/job_item_widget.dart';
import 'models/post_job_data.dart';

class JobListScreen extends StatefulWidget {
  final bool? showAppBar;

  const JobListScreen({Key? key, this.showAppBar}) : super(key: key);

  @override
  _JobListScreenState createState() => _JobListScreenState();
}

class _JobListScreenState extends State<JobListScreen> {
  late Future<List<PostJobData>> future;
  List<PostJobData> allJobsList = []; // All jobs from API
  List<PostJobData> filteredJobsList = []; // Filtered jobs to display

  int page = 1;
  bool isLastPage = false;

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    future = getPostJobList(
      page,
      postJobList: allJobsList,
      lastPageCallback: (val) => isLastPage = val,
    );
    
    final data = await future;
    allJobsList = data;
    
    // Apply filters after fetching
    _applyFilters();
    
    setState(() {});
  }

  void _applyFilters() {
    filteredJobsList = allJobsList.where((job) {
      // Filter by price
      if (filterStore.isPriceFilterApplied) {
        double jobPrice = job.price?.toDouble() ?? 0.0;
        if (jobPrice < filterStore.minPrice || jobPrice > filterStore.maxPrice) {
          return false;
        }
      }

      // Filter by category
      if (filterStore.categoryId.isNotEmpty) {
        bool matchesCategory = false;
        if (job.service != null && job.service!.isNotEmpty) {
          for (var service in job.service!) {
            if (service.categoryId != null && filterStore.categoryId.contains(service.categoryId)) {
              matchesCategory = true;
              break;
            }
          }
        }
        if (!matchesCategory) {
          return false;
        }
      }

      return true;
    }).toList();

    print('🔍 JobListScreen - Applied filters:');
    print('   - Total jobs: ${allJobsList.length}');
    print('   - Categories: ${filterStore.categoryId}');
    print('   - Price range: \$${filterStore.minPrice} - \$${filterStore.maxPrice}');
    print('   - Filtered results: ${filteredJobsList.length} jobs');
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => JobFilterBottomSheet(
        onApplyFilter: () {
          // Apply filters locally without API call
          _applyFilters();
          setState(() {});
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBarTitle: widget.showAppBar == true ? languages.jobRequestList : null,
      actions: widget.showAppBar == true ? [
        Observer(
          builder: (_) => IconButton(
            icon: Stack(
              children: [
                Icon(Icons.filter_list),
                if (filterStore.isAnyFilterApplied)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        filterStore.getActiveFilterCount().toString(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: _showFilterBottomSheet,
          ),
        ),
      ] : null,
      body: Stack(
        children: [
          SnapHelperWidget<List<PostJobData>>(
            future: future,
            onSuccess: (data) {
              // Use filtered list instead of raw data
              return AnimatedListView(
                physics: AlwaysScrollableScrollPhysics(),
                listAnimationType: ListAnimationType.FadeIn,
                fadeInConfiguration: FadeInConfiguration(duration: 2.seconds),
                padding: EdgeInsets.all(16),
                itemCount: filteredJobsList.length,
                shrinkWrap: true,
                emptyWidget: NoDataWidget(
                  title: languages.noDataFound,
                  imageWidget: EmptyStateWidget(),
                ),
                itemBuilder: (_, i) => JobItemWidget(data: filteredJobsList[i]),
                onNextPage: () {
                  if (!isLastPage) {
                    page++;
                    appStore.setLoading(true);

                    init();
                    setState(() {});
                  }
                },
                onSwipeRefresh: () async {
                  page = 1;

                  init();
                  setState(() {});

                  return await 2.seconds.delay;
                },
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
            loadingWidget: JobPostRequestShimmer(),
          ),
          Observer(
              builder: (context) => LoaderWidget().visible(appStore.isLoading)),
        ],
      ),
    );
  }
}
