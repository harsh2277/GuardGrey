import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'package:guardgrey/core/theme/app_colors.dart';
import 'package:guardgrey/core/theme/app_text_styles.dart';
import 'package:guardgrey/core/theme/app_theme.dart';
import 'package:guardgrey/features/location/services/nominatim_location_service.dart';
import '../models/location_picker_result.dart';
import '../models/location_search_result.dart';

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({
    super.key,
    this.initialAddress,
    this.initialLatitude,
    this.initialLongitude,
    this.initialLocationTitle,
    this.initialBuildingFloor,
  });

  final String? initialAddress;
  final double? initialLatitude;
  final double? initialLongitude;
  final String? initialLocationTitle;
  final String? initialBuildingFloor;

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  static const LatLng _fallbackCenter = LatLng(23.0225, 72.5714);
  static const double _defaultZoom = 16;
  static const double _headerRadius = 24;
  static const double _controlHeight = 52;
  static const double _searchDropdownSpacing = 8;
  static const double _bottomSheetMinHeight = 276;
  static const double _floatingButtonGap = 16;

  final TextEditingController _searchController = TextEditingController();
  late final TextEditingController _locationTitleController;
  late final TextEditingController _addressController;
  late final TextEditingController _buildingFloorController;
  final FocusNode _locationTitleFocusNode = FocusNode();
  final FocusNode _buildingFloorFocusNode = FocusNode();
  final MapController _mapController = MapController();
  final NominatimLocationService _locationService = NominatimLocationService();

  Timer? _searchDebounce;
  Timer? _reverseDebounce;
  StreamSubscription<Position>? _positionSubscription;

  late LatLng _selectedLatLng;
  late String _selectedAddress;
  late String _selectedLocationTitle;

  LatLng? _currentLatLng;
  List<LocationSearchResult> _searchResults = const [];
  bool _hasSelection = false;
  bool _isSearching = false;
  bool _isFetchingCurrentLocation = false;
  bool _isResolvingAddress = false;
  bool _showSearchResults = false;
  bool _followCurrentLocation = false;
  String? _searchError;
  String? _buildingFloorError;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );
    _selectedLatLng =
        widget.initialLatitude != null && widget.initialLongitude != null
        ? LatLng(widget.initialLatitude!, widget.initialLongitude!)
        : _fallbackCenter;
    _selectedAddress = widget.initialAddress?.trim() ?? '';
    _selectedLocationTitle =
        widget.initialLocationTitle?.trim().isNotEmpty == true
        ? widget.initialLocationTitle!.trim()
        : _extractLocationTitle(_selectedAddress);
    _hasSelection =
        widget.initialLatitude != null ||
        widget.initialLongitude != null ||
        _selectedAddress.isNotEmpty;
    _currentLatLng =
        widget.initialLatitude != null && widget.initialLongitude != null
        ? LatLng(widget.initialLatitude!, widget.initialLongitude!)
        : null;
    _locationTitleController = TextEditingController(
      text: _selectedLocationTitle,
    );
    _addressController = TextEditingController(text: _selectedAddress);
    _buildingFloorController = TextEditingController(
      text: widget.initialBuildingFloor?.trim() ?? '',
    );
    _locationTitleFocusNode.addListener(_handleBottomFieldFocusChanged);
    _buildingFloorFocusNode.addListener(_handleBottomFieldFocusChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeLocationLayer();
      if (_selectedAddress.isEmpty && _hasSelection) {
        unawaited(_resolveSelectedAddress(showLoader: true));
      }
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _reverseDebounce?.cancel();
    _positionSubscription?.cancel();
    _searchController.dispose();
    _locationTitleController.dispose();
    _addressController.dispose();
    _buildingFloorController.dispose();
    _locationTitleFocusNode
      ..removeListener(_handleBottomFieldFocusChanged)
      ..dispose();
    _buildingFloorFocusNode
      ..removeListener(_handleBottomFieldFocusChanged)
      ..dispose();
    _locationService.dispose();
    super.dispose();
  }

  void _handleBottomFieldFocusChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _initializeLocationLayer() async {
    final permission = await Geolocator.checkPermission();
    if (!mounted) {
      return;
    }

    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      await _bindCurrentLocationTracking(centerOnUser: !_hasSelection);
    }
  }

  Future<void> _bindCurrentLocationTracking({
    required bool centerOnUser,
  }) async {
    await _positionSubscription?.cancel();

    final locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 8,
    );

    _positionSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (position) {
            final latLng = LatLng(position.latitude, position.longitude);
            if (!mounted) {
              return;
            }

            setState(() {
              _currentLatLng = latLng;
            });

            if (_followCurrentLocation) {
              _mapController.move(latLng, _defaultZoom);
            }
          },
        );

    try {
      final position = await Geolocator.getCurrentPosition();
      if (!mounted) {
        return;
      }

      final latLng = LatLng(position.latitude, position.longitude);
      setState(() {
        _currentLatLng = latLng;
      });

      if (centerOnUser) {
        _followCurrentLocation = true;
        _selectedLatLng = latLng;
        _hasSelection = true;
        _mapController.move(latLng, _defaultZoom);
        await _resolveSelectedAddress(showLoader: true);
      }
    } catch (_) {
      // Keep fallback state if GPS fix is not available yet.
    }
  }

  void _handleSearchChanged(String value) {
    _searchDebounce?.cancel();
    final query = value.trim();

    if (query.length < 3) {
      setState(() {
        _isSearching = false;
        _searchError = null;
        _searchResults = const [];
        _showSearchResults = false;
      });
      return;
    }

    _searchDebounce = Timer(const Duration(milliseconds: 300), () async {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSearching = true;
        _searchError = null;
        _showSearchResults = true;
      });

      try {
        final results = await _locationService.searchLocations(query);
        if (!mounted) {
          return;
        }

        setState(() {
          _searchResults = results;
          _isSearching = false;
          _showSearchResults = true;
        });
      } catch (error) {
        if (!mounted) {
          return;
        }

        setState(() {
          _searchResults = const [];
          _isSearching = false;
          _searchError = error.toString().replaceFirst('Exception: ', '');
          _showSearchResults = true;
        });
      }
    });
  }

  void _hideSearchResults() {
    if (!_showSearchResults) {
      return;
    }

    setState(() {
      _showSearchResults = false;
      _searchError = null;
      _searchResults = const [];
    });
  }

  Future<void> _selectSearchResult(LocationSearchResult result) async {
    FocusScope.of(context).unfocus();
    _searchController.text = result.displayName;

    setState(() {
      _followCurrentLocation = false;
      _selectedLatLng = LatLng(result.latitude, result.longitude);
      _selectedAddress = result.displayName;
      _selectedLocationTitle = _extractLocationTitle(result.displayName);
      _locationTitleController.text = _selectedLocationTitle;
      _addressController.text = result.displayName;
      _hasSelection = true;
      _showSearchResults = false;
      _searchError = null;
      _searchResults = const [];
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
        throw Exception(
          'Location permission is required to use current location.',
        );
      }

      _followCurrentLocation = true;
      await _bindCurrentLocationTracking(centerOnUser: true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingCurrentLocation = false;
        });
      }
    }
  }

  void _handlePositionChanged(MapCamera camera, bool hasGesture) {
    _selectedLatLng = camera.center;
    if (!hasGesture) {
      return;
    }

    _followCurrentLocation = false;
    _reverseDebounce?.cancel();
    setState(() {
      _hasSelection = true;
    });
    _reverseDebounce = Timer(
      const Duration(milliseconds: 500),
      () => _resolveSelectedAddress(showLoader: true),
    );
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
      if (!mounted) {
        return;
      }

      setState(() {
        _selectedAddress = address;
        _addressController.text = address;
        if (_locationTitleController.text.trim().isEmpty ||
            _locationTitleController.text.trim() == _selectedLocationTitle) {
          _selectedLocationTitle = _extractLocationTitle(address);
          _locationTitleController.text = _selectedLocationTitle;
        }
        _isResolvingAddress = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isResolvingAddress = false;
      });
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _confirmSelection() {
    FocusScope.of(context).unfocus();

    final buildingFloor = _buildingFloorController.text.trim();
    if (buildingFloor.isEmpty) {
      setState(() {
        _buildingFloorError = 'Building / Floor is required';
      });
      return;
    }

    Navigator.of(context).pop(
      LocationPickerResult(
        latitude: _selectedLatLng.latitude,
        longitude: _selectedLatLng.longitude,
        locationTitle: _locationTitleController.text.trim(),
        address: _addressController.text.trim().isEmpty
            ? 'Lat: ${_selectedLatLng.latitude.toStringAsFixed(6)}, '
                  'Lng: ${_selectedLatLng.longitude.toStringAsFixed(6)}'
            : _addressController.text.trim(),
        buildingFloor: buildingFloor,
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.neutral900,
        content: Text(
          message,
          style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final theme = Theme.of(context);
    final safeBottom = mediaQuery.padding.bottom;
    final shouldLiftBottomSheet =
        _locationTitleFocusNode.hasFocus || _buildingFloorFocusNode.hasFocus;
    final keyboardInset = shouldLiftBottomSheet
        ? mediaQuery.viewInsets.bottom
        : 0.0;
    final floatingButtonBottom =
        safeBottom + _bottomSheetMinHeight + _floatingButtonGap;
    final noSearchResults =
        _showSearchResults &&
        !_isSearching &&
        _searchError == null &&
        _searchController.text.trim().length >= 3 &&
        _searchResults.isEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: false,
      resizeToAvoidBottomInset: false,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.white,
          statusBarBrightness: Brightness.light,
          statusBarIconBrightness: Brightness.dark,
        ),
        child: SafeArea(
          top: true,
          bottom: false,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              FocusScope.of(context).unfocus();
              _hideSearchResults();
            },
            child: Stack(
              children: [
                Positioned.fill(
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _selectedLatLng,
                      initialZoom: _defaultZoom,
                      onTap: (tapPosition, point) => _hideSearchResults(),
                      onPositionChanged: _handlePositionChanged,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.guardgrey.guardgrey',
                      ),
                      if (_currentLatLng != null)
                        CircleLayer(
                          circles: [
                            CircleMarker(
                              point: _currentLatLng!,
                              radius: 28,
                              useRadiusInMeter: true,
                              color: AppColors.primary400.withValues(
                                alpha: 0.18,
                              ),
                              borderStrokeWidth: 0,
                            ),
                          ],
                        ),
                      if (_currentLatLng != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _currentLatLng!,
                              width: 20,
                              height: 20,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.primary500,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary500.withValues(
                                        alpha: 0.28,
                                      ),
                                      blurRadius: 10,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    color: Colors.white,
                    child: _buildHeader(theme, noSearchResults),
                  ),
                ),
                const Positioned.fill(
                  child: IgnorePointer(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 48),
                        child: _CenterPin(),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: floatingButtonBottom,
                  child: _CurrentLocationButton(
                    isLoading: _isFetchingCurrentLocation,
                    onPressed: _useCurrentLocation,
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: AnimatedPadding(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    padding: EdgeInsets.only(bottom: keyboardInset),
                    child: _buildBottomSheet(
                      theme: theme,
                      safeBottom: safeBottom,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool noSearchResults) {
    return Material(
      color: Colors.white,
      elevation: 10,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(_headerRadius),
        bottomRight: Radius.circular(_headerRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.neutral50,
                    foregroundColor: AppColors.neutral900,
                    minimumSize: const Size(40, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.arrow_back_rounded, size: 20),
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: Text(
                    'Select Location',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.m),
            SizedBox(
              height: _controlHeight,
              child: TextField(
                controller: _searchController,
                onChanged: _handleSearchChanged,
                textInputAction: TextInputAction.search,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.neutral900,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'Search for an address',
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.neutral500,
                  ),
                  filled: true,
                  fillColor: AppColors.neutral50,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.l,
                    vertical: AppSpacing.m,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(
                      color: AppColors.primary500,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            if (_showSearchResults) ...[
              const SizedBox(height: _searchDropdownSpacing),
              _buildSearchResults(noSearchResults),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(bool noSearchResults) {
    if (!_showSearchResults) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      child: Material(
        elevation: 14,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.neutral200),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 220),
          child: _isSearching
              ? const Padding(
                  padding: EdgeInsets.all(AppSpacing.l),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              : _searchError != null
              ? Padding(
                  padding: const EdgeInsets.all(AppSpacing.l),
                  child: Text(
                    _searchError!,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.errorDark,
                    ),
                  ),
                )
              : noSearchResults
              ? Padding(
                  padding: const EdgeInsets.all(AppSpacing.l),
                  child: Text(
                    'No matching locations found.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.neutral600,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
                  shrinkWrap: true,
                  itemCount: _searchResults.length,
                  separatorBuilder: (context, index) => const Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.neutral100,
                  ),
                  itemBuilder: (context, index) {
                    final result = _searchResults[index];
                    final title = _extractLocationTitle(result.displayName);
                    final subtitle = _extractLocationSubtitle(
                      result.displayName,
                    );
                    return InkWell(
                      onTap: () => _selectSearchResult(result),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.m),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.primary50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.location_on_outlined,
                                size: 18,
                                color: AppColors.primary600,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.m),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.neutral900,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if (subtitle.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      subtitle,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.neutral600,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildBottomSheet({
    required ThemeData theme,
    required double safeBottom,
  }) {
    return Material(
      color: Colors.white,
      elevation: 20,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(24),
        topRight: Radius.circular(24),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: _bottomSheetMinHeight),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.l,
            AppSpacing.l,
            AppSpacing.l,
            AppSpacing.l + safeBottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFieldLabel('Location Title'),
              const SizedBox(height: AppSpacing.s),
              _buildInput(
                controller: _locationTitleController,
                focusNode: _locationTitleFocusNode,
                hintText: 'Add location title',
                textInputAction: TextInputAction.next,
                onChanged: (value) {
                  _selectedLocationTitle = value.trim();
                },
              ),
              const SizedBox(height: AppSpacing.m),
              _buildFieldLabel('Address'),
              const SizedBox(height: AppSpacing.s),
              _buildInput(
                controller: _addressController,
                hintText: _isResolvingAddress
                    ? 'Resolving address...'
                    : 'Move the map to fetch the address',
                readOnly: true,
                maxLines: 1,
              ),
              const SizedBox(height: AppSpacing.m),
              _buildFieldLabel('Building / Floor'),
              const SizedBox(height: AppSpacing.s),
              _buildInput(
                controller: _buildingFloorController,
                focusNode: _buildingFloorFocusNode,
                hintText: 'Building name / Floor number',
                textInputAction: TextInputAction.done,
                errorText: _buildingFloorError,
                onChanged: (value) {
                  if (_buildingFloorError != null && value.trim().isNotEmpty) {
                    setState(() {
                      _buildingFloorError = null;
                    });
                  }
                },
                onSubmitted: (_) => _confirmSelection(),
              ),
              const SizedBox(height: AppSpacing.l),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _hasSelection && !_isResolvingAddress
                      ? _confirmSelection
                      : null,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: Text(
                    'Confirm location',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: AppTextStyles.bodySmall.copyWith(
        color: AppColors.neutral500,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    FocusNode? focusNode,
    required String hintText,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
    TextInputAction? textInputAction,
    int maxLines = 1,
    bool readOnly = false,
    String? errorText,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      textInputAction: textInputAction,
      maxLines: maxLines,
      minLines: maxLines,
      readOnly: readOnly,
      style: AppTextStyles.bodyMedium.copyWith(
        color: AppColors.neutral900,
        fontWeight: FontWeight.w500,
        overflow: TextOverflow.ellipsis,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        errorText: errorText,
        filled: true,
        fillColor: readOnly ? AppColors.neutral100 : AppColors.neutral50,
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSpacing.l,
          vertical: maxLines > 1 ? AppSpacing.l : 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          borderSide: const BorderSide(color: AppColors.primary500, width: 1.5),
        ),
      ),
    );
  }

  String _extractLocationTitle(String address) {
    final parts = address
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
    if (parts.isEmpty) {
      return '';
    }
    return parts.first;
  }

  String _extractLocationSubtitle(String address) {
    final parts = address
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
    if (parts.length <= 1) {
      return '';
    }
    return parts.skip(1).join(', ');
  }
}

class _CenterPin extends StatelessWidget {
  const _CenterPin();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.error,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.error.withValues(alpha: 0.24),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.place_rounded, color: Colors.white, size: 24),
        ),
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.error,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
      ],
    );
  }
}

class _CurrentLocationButton extends StatelessWidget {
  const _CurrentLocationButton({
    required this.isLoading,
    required this.onPressed,
  });

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: Material(
        color: Colors.white,
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.l,
              vertical: 12,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(
                        Icons.my_location_rounded,
                        size: 18,
                        color: AppColors.primary600,
                      ),
                const SizedBox(width: AppSpacing.s),
                Text(
                  'Current Location',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.neutral900,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
