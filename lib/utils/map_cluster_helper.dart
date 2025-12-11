import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:handyman_provider_flutter/provider/jobRequest/models/post_job_data.dart';

class MapCluster {
  final LatLng center;
  final List<PostJobData> jobs;
  
  MapCluster({
    required this.center,
    required this.jobs,
  });
  
  double get totalPrice => jobs.fold(0.0, (sum, job) => sum + (job.price?.toDouble() ?? 0.0));
  
  int get count => jobs.length;
  
  bool get isCluster => jobs.length > 1;
}

class MapClusterHelper {
  /// Clusters jobs based on their proximity at the given zoom level
  static List<MapCluster> clusterJobs(List<PostJobData> jobs, double zoomLevel) {
    // If zoomed in enough, don't cluster - stop at zoom 15
    if (zoomLevel >= 15) {
      return jobs.map((job) => MapCluster(
        center: LatLng(job.latitude!, job.longitude!),
        jobs: [job],
      )).toList();
    }
    
    // Calculate clustering distance based on zoom level
    // Lower zoom = larger distance = more clustering
    double clusterDistance = _getClusterDistance(zoomLevel);
    
    List<MapCluster> clusters = [];
    List<PostJobData> unclusteredJobs = List.from(jobs);
    
    while (unclusteredJobs.isNotEmpty) {
      PostJobData seedJob = unclusteredJobs.removeAt(0);
      List<PostJobData> clusterJobs = [seedJob];
      
      // Find all jobs within cluster distance
      unclusteredJobs.removeWhere((job) {
        double distance = _calculateDistance(
          seedJob.latitude!,
          seedJob.longitude!,
          job.latitude!,
          job.longitude!,
        );
        
        if (distance <= clusterDistance) {
          clusterJobs.add(job);
          return true;
        }
        return false;
      });
      
      // Calculate center of cluster
      LatLng clusterCenter = _calculateCenter(clusterJobs);
      
      clusters.add(MapCluster(
        center: clusterCenter,
        jobs: clusterJobs,
      ));
    }
    
    return clusters;
  }
  
  /// Calculate clustering distance based on zoom level
  static double _getClusterDistance(double zoom) {
    // Distance in kilometers - smaller distances = clusters break apart sooner
    if (zoom < 5) return 500.0;   // Very far out
    if (zoom < 8) return 100.0;   // Far out
    if (zoom < 10) return 50.0;   // Medium-far
    if (zoom < 11) return 15.0;   // Medium
    if (zoom < 12) return 5.0;    // Medium-close
    if (zoom < 13) return 2.0;    // Close
    if (zoom < 14) return 0.8;    // Very close
    return 0.3;                    // Minimal clustering before stopping
  }
  
  /// Calculate distance between two coordinates using Haversine formula (in km)
  static double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371.0; // Earth radius in kilometers
    
    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);
    
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }
  
  static double _toRadians(double degrees) {
    return degrees * pi / 180.0;
  }
  
  /// Calculate the center point of a cluster
  static LatLng _calculateCenter(List<PostJobData> jobs) {
    if (jobs.isEmpty) return LatLng(0, 0);
    if (jobs.length == 1) return LatLng(jobs[0].latitude!, jobs[0].longitude!);
    
    double totalLat = 0.0;
    double totalLng = 0.0;
    
    for (var job in jobs) {
      totalLat += job.latitude!;
      totalLng += job.longitude!;
    }
    
    return LatLng(totalLat / jobs.length, totalLng / jobs.length);
  }
}

