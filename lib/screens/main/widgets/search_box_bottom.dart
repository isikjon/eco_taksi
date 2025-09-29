import 'package:eco_taksi/styles/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:dgis_mobile_sdk_full/dgis.dart' as sdk;

class SearchBoxBottom extends StatefulWidget {
  const SearchBoxBottom({super.key, required this.sdkContext});

  final sdk.Context sdkContext;

  @override
  State<SearchBoxBottom> createState() => _SearchBoxBottomState();
}

class _SearchBoxBottomState extends State<SearchBoxBottom> {
  late final sdk.SearchManager searchManager;
  final TextEditingController _textController = TextEditingController();
  List<sdk.DirectoryObject> _searchResults = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    searchManager = sdk.SearchManager.createOnlineManager(widget.sdkContext);

    // Проверяем инициализацию SDK
    _checkSDKInitialization();
  }

  // Функция для проверки корректности инициализации SDK
  void _checkSDKInitialization() {
    // Убираем тестовый поиск, который вызывает раздражающие логи
    // SDK инициализирован, если SearchManager создался без ошибок
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  // Функция для выполнения поиска
  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults.clear();
      });
      return;
    }

    // Минимальная длина запроса для поиска
    if (query.trim().length < 2) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      const oshCenter = sdk.GeoPoint(
        latitude: sdk.Latitude(40.5283),
        longitude: sdk.Longitude(72.7985),
      );

      const oshBounds = sdk.GeoRect(
        southWestPoint: sdk.GeoPoint(
          latitude: sdk.Latitude(40.4800),
          longitude: sdk.Longitude(72.7200),
        ),
        northEastPoint: sdk.GeoPoint(
          latitude: sdk.Latitude(40.5800), // северо-восточный угол
          longitude: sdk.Longitude(72.8800),
        ),
      );

      // Формируем запрос с указанием города
      String searchText = query.trim();
      if (!searchText.toLowerCase().contains('ош') && !searchText.toLowerCase().contains('osh')) {
        searchText = '$searchText, Ош'; // добавляем город к запросу
      }

      // Создаем поисковый запрос согласно документации
      final searchQuery = sdk.SearchQueryBuilder
          .fromQueryText(searchText)
          .setAreaOfInterest(oshBounds)
          .setGeoPoint(oshCenter)
          .setRadius(const sdk.Meter(15000))
          .setAllowedResultTypes([
        sdk.ObjectType.building,
        sdk.ObjectType.road,
      ])
          .setPageSize(15)
          .build();

      final searchResult = await searchManager.search(searchQuery).value;

      if (searchResult.firstPage != null && searchResult.firstPage!.items.isNotEmpty) {
        // Дополнительная фильтрация результатов по Ошу
        final oshResults = searchResult.firstPage!.items.where((item) {
          final address = _getAddressString(item).toLowerCase();
          final title = item.title.toLowerCase();
          return address.contains('ош') || address.contains('osh') ||
              title.contains('ош') || title.contains('osh') ||
              _isInOshBounds(item);
        }).toList();

        setState(() {
          _searchResults = oshResults;
        });
      } else {
        setState(() {
          _searchResults.clear();
        });
      }
    } catch (e) {
      // Убираем детальные логи ошибок, которые могут вызывать раздражающие сообщения

      setState(() {
        _searchResults.clear();
      });

      String errorMessage = 'Ошибка при поиске';

      // Обработка различных типов ошибок
      if (e.toString().contains('400')) {
        errorMessage = 'Неверный запрос. Проверьте настройки API ключа.';
      } else if (e.toString().contains('401')) {
        errorMessage = 'Ошибка авторизации. Проверьте API ключ.';
      } else if (e.toString().contains('403')) {
        errorMessage = 'Доступ запрещен. Проверьте права API ключа.';
      } else if (e.toString().contains('network') || e.toString().contains('connection')) {
        errorMessage = 'Ошибка сети. Проверьте подключение к интернету.';
      }

      // Показываем пользователю сообщение об ошибке
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Проверка, находится ли объект в границах Оша
  bool _isInOshBounds(sdk.DirectoryObject obj) {
    final coordinates = _getObjectCoordinates(obj);
    if (coordinates == null) return false;

    const minLat = 40.4800;
    const maxLat = 40.5800;
    const minLng = 72.7200;
    const maxLng = 72.8800;

    final lat = coordinates.latitude.value;
    final lng = coordinates.longitude.value;

    return lat >= minLat && lat <= maxLat && lng >= minLng && lng <= maxLng;
  }

  // Функция для получения адреса из объекта
  String _getAddressString(sdk.DirectoryObject obj) {
    if (obj.address != null) {
      final components = <String>[];

      // Добавляем компоненты адреса согласно документации
      for (final component in obj.address!.components) {
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

      // Добавляем административные единицы город, район
      final adminComponents = obj.address!.drillDown
          .where((admin) => admin.type == 'city' || admin.type == 'district')
          .map((admin) => admin.name)
          .toList();

      components.addAll(adminComponents);

      return components.isNotEmpty ? components.join(', ') : obj.title;
    }
    return obj.title;
  }

  // Функция для получения координат объекта
  sdk.GeoPoint? _getObjectCoordinates(sdk.DirectoryObject obj) {
    final int entranceId = obj.id?.entranceId ?? 0;

    // Если есть конкретный подъезд
    if (entranceId != 0 && obj.entrances.isNotEmpty) {
      try {
        final entrance = obj.entrances.firstWhere(
              (entrance) => entrance.id.entranceId == entranceId,
        );
        return entrance.geometry?.entrancePoints.firstOrNull;
      } catch (e) {
      }
    }

    return obj.markerPosition?.point;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Поле поиска
          TextField(
            controller: _textController,
            decoration: InputDecoration(
              hintText: 'Введите адрес...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _textController.text.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _textController.clear();
                  setState(() {
                    _searchResults.clear();
                  });
                },
              )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: (value) {
              // Выполняем поиск с задержкой
              Future.delayed(const Duration(milliseconds: 500), () {
                if (_textController.text == value) {
                  _performSearch(value);
                }
              });
            },
            onSubmitted: _performSearch,
          ),

          const SizedBox(height: 8),

          // Кнопка "Указать точку на карте"
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context, {'action': 'select_point'});
              },
              icon: const Icon(Icons.location_on, color: Colors.white),
              label: const Text(
                'Указать точку на карте',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),

          // Индикатор загрузки
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),

          // Результаты поиска
          if (!_isLoading && _searchResults.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _searchResults.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final result = _searchResults[index];
                  final coordinates = _getObjectCoordinates(result);

                  return ListTile(
                    leading: Icon(
                      _getIconForObjectType(result.types.first),
                      color: AppColors.primary,
                    ),
                    title: Text(
                      result.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_getAddressString(result)),
                        if (result.subtitle.isNotEmpty)
                          Text(
                            result.subtitle,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        if (coordinates != null)
                          Text(
                            'Координаты: ${coordinates.latitude.value.toStringAsFixed(6)}, ${coordinates.longitude.value.toStringAsFixed(6)}',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 10,
                            ),
                          ),
                      ],
                    ),
                    onTap: () {
                      // Обработка выбора результата
                      _onResultSelected(result);
                    },
                  );
                },
              ),
            ),

          // Сообщение когда ничего не найдено
          if (!_isLoading && _textController.text.isNotEmpty && _searchResults.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Ничего не найдено',
                style: TextStyle(color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }

  IconData _getIconForObjectType(sdk.ObjectType type) {
    switch (type) {
      case sdk.ObjectType.building:
        return Icons.business;
      case sdk.ObjectType.branch:
        return Icons.store;
      case sdk.ObjectType.admDivCity:
        return Icons.location_city;
      case sdk.ObjectType.road:
        return Icons.abc;
      case sdk.ObjectType.parking:
        return Icons.local_parking;
      default:
        return Icons.place;
    }
  }

  // Функция обработки выбора результата
  void _onResultSelected(sdk.DirectoryObject result) {
    final coordinates = _getObjectCoordinates(result);
    final address = _getAddressString(result);

    print('Выбран объект: ${result.title}');
    print('Адрес: $address');
    if (coordinates != null) {
      print('Координаты: ${coordinates.latitude.value}, ${coordinates.longitude.value}');
    }

    Navigator.pop(context, {
      'title': result.title,
      'address': address,
      'coordinates': coordinates,
      'directoryObject': result,
    });
  }
}