import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../widgets/search_dropdown.dart';
import '../../../widgets/search_location_bar.dart';
import '../models/location_picker_result.dart';
import '../models/location_search_result.dart';
import '../services/nominatim_location_service.dart';

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({
    super.key,
    this.initialAddress,
    this.initialLatitude,
    this.initialLongitude,
  });

  final String? initialAddress;
  final double? initialLatitude;
  final double? initialLongitude;

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  static const LatLng _fallbackCenter = LatLng(23.0225, 72.5714);
  static const double _defaultZoom = 16;
  static const double _controlHeight = 48;
  static const double _controlRadius = 24;
  static const double _sectionRadius = 34;
  static const double _horizontalPadding = 20;
  static const double _topPadding = 16;
  static const double _rowSpacing = 8;
  static const double _dropdownSpacing = 8;

  final TextEditingController _searchController = TextEditingController();
  final MapController _mapController = MapController();
  final NominatimLocationService _locationService = NominatimLocationService();
  final LayerLink _searchRowLink = LayerLink();

  Timer? _searchDebounce;
  Timer? _reverseDebounce;

  late LatLng _selectedLatLng;
  late String _selectedAddress;

  List<LocationSearchResult> _searchResults = const [];
  bool _isSearching = false;
  bool _isFetchingCurrentLocation = false;
  bool _isResolvingAddress = false;
  bool _hasSelection = false;
  bool _showDropdown = false;
  String? _searchError;

  @override
  void initState() {
    super.initState();
    _selectedLatLng = widget.initialLatitude != null &&
            widget.initialLongitude != null
        ? LatLng(widget.initialLatitude!, widget.initialLongitude!)
        : _fallbackCenter;
    _selectedAddress = widget.initialAddress?.trim() ?? '';
    _hasSelection = _selectedAddress.isNotEmpty ||
        widget.initialLatitude != null ||
        widget.initialLongitude != null;
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _reverseDebounce?.cancel();
    _searchController.dispose();
    _locationService.dispose();
    super.dispose();
  }

  void _handleSearchChanged(String value) {
    _searchDebounce?.cancel();

    final query = value.trim();
    if (query.length < 3) {
      setState(() {
        _isSearching = false;
        _searchError = null;
        _searchResults = const [];
        _showDropdown = false;
      });
      return;
    }

    _searchDebounce = Timer(const Duration(milliseconds: 300), () async {
      setState(() {
        _isSearching = true;
        _searchError = null;
        _showDropdown = true;
      });

      try {
        final results = await _locationService.searchLocations(query);
        if (!mounted) return;
        setState(() {
          _searchResults = results;
          _isSearching = false;
          _showDropdown = true;
        });
      } catch (error) {
        if (!mounted) return;
        setState(() {
          _isSearching = false;
          _searchResults = const [];
          _searchError = error.toString().replaceFirst('Exception: ', '');
          _showDropdown = true;
        });
      }
    });
  }

  void _hideDropdown() {
    if (!_showDropdown &&
        _searchResults.isEmpty &&
        _searchError == null &&
        _searchController.text.trim().length < 3) {
      return;
    }

    setState(() {
      _showDropdown = false;
      _searchResults = const [];
      _searchError = null;
    });
  }

  Future<void> _selectSearchResult(LocationSearchResult result) async {
    FocusScope.of(context).unfocus();
    _searchController.text = result.displayName;
    setState(() {
      _selectedLatLng = LatLng(result.latitude, result.longitude);
      _selectedAddress = result.displayName;
      _hasSelection = true;
      _showDropdown = false;
    });
    _mapController.move(_selectedLatLng, _defaultZoom);
  }

  Future<void> _useCurrentLocation() async {
    setState(() {
      _isFetchingCurrentLocation = true;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are turned off.');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Location permission is required to use current location.');
      }

      final position = await Geolocator.getCurrentPosition();
      final latLng = LatLng(position.latitude, position.longitude);

      if (!mounted) return;

      setState(() {
        _selectedLatLng = latLng;
        _hasSelection = true;
        _showDropdown = false;
      });
      _mapController.move(latLng, _defaultZoom);
      await _resolveSelectedAddress(showLoader: true);
    } catch (error) {
      if (!mounted) return;
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingCurrentLocation = false;
        });
      }
    }
  }

  void _handlePositionChanged(MapCamera position, bool hasGesture) {
    final center = position.center;
    if (center == null) return;

    _selectedLatLng = center;

    if (hasGesture) {
      setState(() {
        _hasSelection = true;
      });
      _reverseDebounce?.cancel();
      _reverseDebounce = Timer(
        const Duration(milliseconds: 650),
        () => _resolveSelectedAddress(showLoader: false),
      );
    }
  }

  Future<void> _resolveSelectedAddress({required bool showLoader}) async {
    if (showLoader && mounted) {
      setState(() {
        _isResolvingAddress = true;
      });
    }

    try {
      final address = await _locationService.reverseGeocode(
        latitude: _selectedLatLng.latitude,
        longitude: _selectedLatLng.longitude,
      );
      if (!mounted) return;
      setState(() {
        _selectedAddress = address;
        _isResolvingAddress = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isResolvingAddress = false;
      });
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _confirmSelection() {
    if (!_hasSelection) return;

    Navigator.pop(
      context,
      LocationPickerResult(
        address: _selectedAddress.trim().isEmpty
            ? 'Lat: ${_selectedLatLng.latitude.toStringAsFixed(6)}, '
                'Lng: ${_selectedLatLng.longitude.toStringAsFixed(6)}'
            : _selectedAddress,
        latitude: _selectedLatLng.latitude,
        longitude: _selectedLatLng.longitude,
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.neutral900,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final showNoResults = _showDropdown &&
        !_isSearching &&
        _searchError == null &&
        _searchController.text.trim().length >= 3 &&
        _searchResults.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          FocusScope.of(context).unfocus();
          _hideDropdown();
        },
        child: Stack(
          children: [
            Positioned.fill(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _selectedLatLng,
                      initialZoom: _defaultZoom,
                      onTap: (_, __) => _hideDropdown(),
                      onPositionChanged: _handlePositionChanged,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName:
                            'com.example.guardgrey.guardgrey',
                      ),
                    ],
                  ),
                  const IgnorePointer(
                    child: Icon(
                      Icons.location_pin,
                      size: 44,
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(
                    _horizontalPadding,
                    12,
                    _horizontalPadding,
                    16,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(_sectionRadius),
                      bottomRight: Radius.circular(_sectionRadius),
                    ),
                    border: Border(
                      left: BorderSide(color: AppColors.neutral200),
                      right: BorderSide(color: AppColors.neutral200),
                      bottom: BorderSide(color: AppColors.neutral200),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 32,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: IconButton(
                                onPressed: () => Navigator.of(context).pop(),
                                icon: const Icon(
                                  Icons.arrow_back_rounded,
                                  color: AppColors.neutral900,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                                splashRadius: 20,
                              ),
                            ),
                            Text(
                              'Select Location',
                              style: AppTextStyles.title.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: _topPadding),
                      CompositedTransformTarget(
                        link: _searchRowLink,
                        child: Row(
                          children: [
                            Expanded(
                              child: SearchLocationBar(
                                controller: _searchController,
                                onChanged: _handleSearchChanged,
                                isLoading: _isSearching,
                                height: _controlHeight,
                                borderRadius: _controlRadius,
                              ),
                            ),
                            const SizedBox(width: _rowSpacing),
                            SizedBox(
                              width: _controlHeight,
                              height: _controlHeight,
                              child: Material(
                                color: Colors.white,
                                borderRadius:
                                    BorderRadius.circular(_controlRadius),
                                child: InkWell(
                                  borderRadius:
                                      BorderRadius.circular(_controlRadius),
                                  onTap: _isFetchingCurrentLocation
                                      ? null
                                      : _useCurrentLocation,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(
                                        _controlRadius,
                                      ),
                                      border: const Border.fromBorderSide(
                                        BorderSide(
                                          color: AppColors.neutral200,
                                        ),
                                      ),
                                    ),
                                    child: Center(
                                      child: _isFetchingCurrentLocation
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.my_location_rounded,
                                              size: 20,
                                              color: AppColors.primary600,
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: SafeArea(
                bottom: false,
                child: IgnorePointer(
                  ignoring: !_showDropdown,
                  child: CompositedTransformFollower(
                    link: _searchRowLink,
                    showWhenUnlinked: false,
                    offset: const Offset(0, _controlHeight + _dropdownSpacing),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SizeTransition(
                            sizeFactor: animation,
                            axisAlignment: -1,
                            child: child,
                          ),
                        );
                      },
                      child: _showDropdown
                          ? Padding(
                              padding: const EdgeInsets.fromLTRB(
                                _horizontalPadding,
                                12 + 32 + _topPadding,
                                _horizontalPadding,
                                0,
                              ),
                              child: SearchDropdown(
                                key: ValueKey<String>(
                                  '${_searchResults.length}-${_searchError ?? ''}-$showNoResults',
                                ),
                                results: _searchResults,
                                errorText: _searchError,
                                showNoResults: showNoResults,
                                onSelected: _selectSearchResult,
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: Container(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    18,
                    20,
                    bottomInset > 0 ? bottomInset + 8 : 20,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(_sectionRadius),
                      topRight: Radius.circular(_sectionRadius),
                    ),
                    border: Border(
                      left: BorderSide(color: AppColors.neutral200),
                      right: BorderSide(color: AppColors.neutral200),
                      top: BorderSide(color: AppColors.neutral200),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selected Address',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.neutral500,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _isResolvingAddress
                            ? 'Resolving address...'
                            : (_selectedAddress.trim().isEmpty
                                ? 'Move the map or search to choose a location'
                                : _selectedAddress),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.neutral800,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _hasSelection && !_isResolvingAddress
                              ? _confirmSelection
                              : null,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            disabledBackgroundColor: AppColors.neutral200,
                            disabledForegroundColor: AppColors.neutral500,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: const Text('Confirm Location'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
