import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:gap/gap.dart';
import 'package:wandr/core/in_memory_store.dart';
import 'package:wandr/main.dart';
import 'package:wandr/models/trip_model.dart';

class TripMapView extends StatefulWidget {
  final TripModel trip;

  const TripMapView({super.key, required this.trip});

  @override
  State<TripMapView> createState() => _TripMapViewState();
}

class _TripMapViewState extends State<TripMapView> {
  late List<Marker> _markers;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _markers = List.from(widget.trip.markers ?? []);
  }

  void _handleTap(TapPosition tapPosition, LatLng point) {
    setState(() {
      // Check if tapping near an existing marker to "unpin"
      final existingIndex = _markers.indexWhere((m) {
        final double dist = (m.point.latitude - point.latitude).abs() + 
                           (m.point.longitude - point.longitude).abs();
        return dist < 0.005; // Tight tolerance for tapping a pin
      });

      if (existingIndex != -1) {
        _markers.removeAt(existingIndex);
      } else {
        _markers.add(
          Marker(
            point: point,
            width: 40,
            height: 40,
            child: const Icon(Icons.location_on, color: Colors.lightBlueAccent, size: 30),
          ),
        );
      }
      
      // Save changes back to store
      widget.trip.markers = _markers;
      getIt<InMemoryStore>().saveToDisk();
    });
  }

  void _zoom(double delta) {
    try {
      _mapController.move(_mapController.camera.center, _mapController.camera.zoom + delta);
    } catch (_) {
      // Controller might not be attached yet
    }
  }

  @override
  Widget build(BuildContext context) {
    // Default to Kyoto if no markers
    final LatLng initialCenter = _markers.isNotEmpty
        ? _markers.first.point
        : const LatLng(35.0116, 135.7681); 

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: initialCenter,
              initialZoom: 12.0,
              onTap: _handleTap,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                userAgentPackageName: 'com.example.wandr',
                subdomains: const ['a', 'b', 'c', 'd'],
              ),
              MarkerLayer(markers: _markers),
            ],
          ),
          Positioned(
            right: 16,
            bottom: 120, // Adjust above possible tab nav
            child: Column(
              children: [
                _buildZoomButton(Icons.add, () => _zoom(1)),
                const Gap(8),
                _buildZoomButton(Icons.remove, () => _zoom(-1)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZoomButton(IconData icon, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)],
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.lightBlueAccent),
        onPressed: onPressed,
      ),
    );
  }
}
