import 'dart:async';
import 'package:dgis_mobile_sdk_full/dgis.dart' as sdk;
import 'package:geolocator/geolocator.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  sdk.Context? _sdkContext;
  StreamSubscription<Position>? _positionStream;
  
  final StreamController<String> _addressController = StreamController<String>.broadcast();
  Stream<String> get addressStream => _addressController.stream;
  
  String _currentAddress = 'Ош';
  String get currentAddress => _currentAddress;

  Future<void> initialize() async {
    try {
      _sdkContext = sdk.DGis.initialize();
      _addressController.add(_currentAddress);
      
      await _requestLocationPermission();
      await _startLocationTracking();
    } catch (e) {
      _currentAddress = 'Ош';
      _addressController.add(_currentAddress);
    }
  }

  Future<void> _requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _currentAddress = 'Ош';
        _addressController.add(_currentAddress);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _currentAddress = 'Ош';
      _addressController.add(_currentAddress);
      return;
    }
  }

  Future<void> _startLocationTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _currentAddress = 'Ош';
      _addressController.add(_currentAddress);
      return;
    }

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        distanceFilter: 100,
      ),
    ).listen(
      (Position position) {
        _updateAddressFromCoordinates(position.latitude, position.longitude);
      },
      onError: (error) {
        _currentAddress = 'Ош';
        _addressController.add(_currentAddress);
      },
    );
  }

  Future<void> _updateAddressFromCoordinates(double latitude, double longitude) async {
    try {
      if (_sdkContext == null) {
        _currentAddress = 'Ош';
        _addressController.add(_currentAddress);
        return;
      }

      final searchManager = sdk.SearchManager.createOnlineManager(_sdkContext!);
      
      final searchQuery = sdk.SearchQueryBuilder
          .fromGeoPoint(sdk.GeoPoint(
            latitude: sdk.Latitude(latitude),
            longitude: sdk.Longitude(longitude),
          ))
          .setPageSize(1)
          .build();

      final searchResult = await searchManager.search(searchQuery).value;
      
      if (searchResult.firstPage != null && searchResult.firstPage!.items.isNotEmpty) {
        final item = searchResult.firstPage!.items.first;
        if (item.address != null) {
          final components = <String>[];
          
          for (final component in item.address!.components) {
            component.match(
              streetAddress: (street) {
                if (street.street.isNotEmpty) {
                  components.add('${street.street}${street.number.isNotEmpty ? ', ${street.number}' : ''}');
                }
              },
              number: (s) {},
              location: (s) {}
            );
          }
          
          final adminComponents = item.address!.drillDown
              .where((admin) => admin.type == 'city' || admin.type == 'district')
              .map((admin) => admin.name)
              .toList();
          
          components.addAll(adminComponents);
          
          _currentAddress = components.isNotEmpty ? components.join(', ') : item.title;
        } else {
          _currentAddress = item.title;
        }
      } else {
        _currentAddress = 'Ош';
      }
      
      _addressController.add(_currentAddress);
    } catch (e) {
      _currentAddress = 'Ош';
      _addressController.add(_currentAddress);
    }
  }

  Future<void> getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      await _updateAddressFromCoordinates(position.latitude, position.longitude);
    } catch (e) {
      _currentAddress = 'Ош';
      _addressController.add(_currentAddress);
    }
  }

  void dispose() {
    _positionStream?.cancel();
    _addressController.close();
  }
}
