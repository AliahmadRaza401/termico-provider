import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:handyman_provider_flutter/components/cached_image_widget.dart';
import 'package:handyman_provider_flutter/components/custom_map_marker.dart';
import 'package:handyman_provider_flutter/main.dart';
import 'package:handyman_provider_flutter/networks/rest_apis.dart';
import 'package:handyman_provider_flutter/provider/jobRequest/components/job_filter_bottom_sheet.dart';
import 'package:handyman_provider_flutter/provider/jobRequest/job_list_screen.dart';
import 'package:handyman_provider_flutter/provider/jobRequest/job_post_detail_screen.dart';
import 'package:handyman_provider_flutter/provider/jobRequest/models/post_job_data.dart';
import 'package:handyman_provider_flutter/utils/images.dart';
import 'package:handyman_provider_flutter/utils/map_cluster_helper.dart';
import 'package:nb_utils/nb_utils.dart';

class ServicesMapScreen extends StatefulWidget {
  const ServicesMapScreen({super.key});

  @override
  State<ServicesMapScreen> createState() => _ServicesMapScreenState();
}

class _ServicesMapScreenState extends State<ServicesMapScreen> {
  late Future<List<PostJobData>> future;
  List<PostJobData> allJobsList = []; // All jobs from API
  List<PostJobData> filteredJobsList = []; // Filtered jobs to display

  Set<Marker> _markers = {};
  GoogleMapController? _mapController;
  double _currentZoom = 13.0;
  bool _isUpdatingMarkers = false;

  int page = 1;
  bool isLastPage = false;

  @override
  void initState() {
    super.initState();
    fetchJobs();
  }

  Future<void> fetchJobs() async {
    appStore.setLoading(true);
    
    future = getPostJobList(
      page,
      postJobList: allJobsList,
      lastPageCallback: (val) => isLastPage = val,
    );

    final data = await future;
    allJobsList = data;
    
    // Apply filters after fetching
    _applyFilters();
    
    appStore.setLoading(false);

    print('📊 Total jobs fetched: ${allJobsList.length}');
    print('🔍 Filtered jobs: ${filteredJobsList.length}');

    await _setMarkers();

    if (mounted) setState(() {});
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

    print('🔍 Applied filters:');
    print('   - Categories: ${filterStore.categoryId}');
    print('   - Price range: \$${filterStore.minPrice} - \$${filterStore.maxPrice}');
    print('   - Results: ${filteredJobsList.length} jobs');
  }

  Future<void> _setMarkers() async {
    // Prevent concurrent marker updates
    if (_isUpdatingMarkers) {
      print('⏳ Already updating markers, skipping...');
      return;
    }
    
    _isUpdatingMarkers = true;
    
    print('🗺️ Setting up clustering for ${filteredJobsList.length} jobs at zoom $_currentZoom...');
    
    // Clear all existing markers first
    _markers.clear();
    
    // Filter valid jobs
    List<PostJobData> validJobs = filteredJobsList
        .where((job) => 
            job.status != null && 
            job.status != 'assigned' && 
            job.latitude != null && 
            job.longitude != null)
        .toList();
    
    if (validJobs.isEmpty) {
      _isUpdatingMarkers = false;
      if (mounted) setState(() {});
      return;
    }
    
    // Create clusters
    List<MapCluster> clusters = MapClusterHelper.clusterJobs(validJobs, _currentZoom);
    
    print('✅ Created ${clusters.length} clusters from ${validJobs.length} jobs');
    
    // Track processed job IDs to ensure no duplicates
    Set<int> processedJobIds = {};
    
    // Create markers for each cluster
    for (var cluster in clusters) {
      if (cluster.isCluster) {
        // Multiple jobs - create cluster marker
        print('🎯 Cluster: ${cluster.count} jobs, Total: \$${cluster.totalPrice.toStringAsFixed(0)}');
        
        // Mark all jobs in this cluster as processed
        for (var job in cluster.jobs) {
          processedJobIds.add(job.id!.toInt());
        }
        
        final icon = await CustomMapMarker.createEnhancedClusterMarker(
          count: cluster.count,
          avgPrice: cluster.totalPrice.toStringAsFixed(0),
          currency: '\$',
          color: context.primaryColor,
          size: 110,
        );
        
        // Use unique cluster ID based on job IDs
        String clusterJobIds = cluster.jobs.map((j) => j.id).join('_');
        
        _markers.add(Marker(
          markerId: MarkerId('cluster_$clusterJobIds'),
          position: cluster.center,
          icon: icon,
          onTap: () {
            // Zoom to next level to expand cluster
            _mapController?.animateCamera(
              CameraUpdate.newLatLngZoom(cluster.center, _currentZoom + 1),
            );
          },
        ));
      } else {
        // Single job - create individual marker
        final job = cluster.jobs.first;
        
        // Check if this job was already processed
        if (processedJobIds.contains(job.id?.toInt())) {
          print('⚠️ Job #${job.id} already processed, skipping...');
          continue;
        }
        processedJobIds.add(job.id!.toInt());
        
        String imageUrl = '';
        if (job.service?.isNotEmpty == true &&
            job.service!.first.imageAttachments?.isNotEmpty == true) {
          imageUrl = job.service!.first.imageAttachments!.first;
        } else if (job.customerProfile?.isNotEmpty == true) {
          imageUrl = job.customerProfile!;
        }
        
        print('📍 Single: Job #${job.id} - ${job.title}');
        
        final markerIcon = await CustomMapMarker.createServiceImageMarker(
          imageUrl: imageUrl,
          price: job.price.toString(),
          currency: '\$',
          size: 130,
          borderColor: Colors.white,
          priceBgColor: context.primaryColor,
        );
        
        _markers.add(Marker(
          markerId: MarkerId('job_${job.id}'),
          position: LatLng(job.latitude!, job.longitude!),
          icon: markerIcon,
          infoWindow: InfoWindow(title: job.title),
          onTap: () {
            JobPostDetailScreen(postJobData: job).launch(context);
          },
        ));
      }
    }

    print('🏁 Final marker count: ${_markers.length}');
    
    _isUpdatingMarkers = false;
    if (mounted) setState(() {});
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => JobFilterBottomSheet(
        onApplyFilter: () async {
          // Apply filters locally without API call
          _applyFilters();
          await _setMarkers();
          if (mounted) setState(() {});
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PostJobData>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No jobs found'));
            } else {
              return Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(
                        filteredJobsList.isNotEmpty 
                          ? (filteredJobsList.first.latitude ?? 0)
                          : (allJobsList.first.latitude ?? 0),
                        filteredJobsList.isNotEmpty 
                          ? (filteredJobsList.first.longitude ?? 0)
                          : (allJobsList.first.longitude ?? 0),
                      ),
                      zoom: 13,
                    ),
                    markers: _markers,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    onMapCreated: (controller) {
                      _mapController = controller;
                    },
                    onCameraMove: (position) {
                      _currentZoom = position.zoom;
                    },
                    onCameraIdle: () {
                      // Re-cluster when camera stops moving
                      _setMarkers();
                    },
                  ),
              Positioned(
                right: 0,
                child: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Filter Button
                      Observer(
                        builder: (_) => Container(
                          padding: EdgeInsets.all(10),
                          decoration: boxDecorationDefault(
                            color: context.primaryColor,
                          ),
                          child: Stack(
                            children: [
                              Icon(
                                Icons.filter_list,
                                color: Colors.white,
                                size: 26,
                              ),
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
                                    constraints: BoxConstraints(
                                      minWidth: 18,
                                      minHeight: 18,
                                    ),
                                    child: Text(
                                      filterStore.getActiveFilterCount().toString(),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ).onTap(() {
                          _showFilterBottomSheet();
                        }, borderRadius: radius()),
                      ),
                      16.height,
                      // List View Button
                      Container(
                        padding: EdgeInsets.all(10),
                        decoration:
                            boxDecorationDefault(color: context.primaryColor),
                        child: CachedImageWidget(
                          url: list,
                          height: 26,
                          width: 26,
                          color: Colors.white,
                        ),
                      ).onTap(() {
                        hideKeyboard(context);

                        JobListScreen(showAppBar: true)
                            .launch(context)
                            .then((value) {});
                      }, borderRadius: radius())
                    ],
                  ).paddingAll(16),
                ),
              ),
            ],
          );
        }
      },
    );
  }
}
