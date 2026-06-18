import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../data/models/location_model.dart';

class LocationSearchScreen extends StatefulWidget {
  const LocationSearchScreen({super.key});

  @override
  State<LocationSearchScreen> createState() => _LocationSearchScreenState();
}

class _LocationSearchScreenState extends State<LocationSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _suggestions = [];
  bool _isLoading = false;
  Timer? _debounce;

  Future<void> _fetchSuggestions(String query) async {
    _debounce?.cancel();

    if (query.isEmpty || query.length < 3) {
      setState(() => _suggestions = []);
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 1000), () async {
      setState(() => _isLoading = true);

      try {
        final url = Uri.parse(
          'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&addressdetails=1&limit=5',
        );

        final response = await http.get(url, headers: {
          'User-Agent': 'LiquidCalendarApp/1.0 (contact@liquidcalendar.app)',
          'Accept-Language': 'ru',
        });

        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          setState(() => _suggestions = data);
        }
      } catch (e) {
        debugPrint('Ошибка поиска: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    });
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isLoading = true);

    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final result = await Geolocator.requestPermission();
        if (result == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Разрешение на геолокацию отклонено')),
            );
          }
          setState(() => _isLoading = false);
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}&zoom=18&addressdetails=1',
      );

      final response = await http.get(url, headers: {
        'User-Agent': 'LiquidCalendarApp/1.0 (contact@liquidcalendar.app)',
        'Accept-Language': 'ru',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final displayName = data['display_name'] ?? '';

        if (mounted) {
          Navigator.pop(
            context,
            LocationModel(
              name: displayName.split(',').first.trim(),
              address: displayName,
              latitude: position.latitude,
              longitude: position.longitude,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Ошибка геолокации: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        foregroundColor: textColor,
        elevation: 0,
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            hintText: 'Поиск места...',
            hintStyle: TextStyle(color: textColor.withValues(alpha: 0.5)),
            border: InputBorder.none,
          ),
          onChanged: _fetchSuggestions,
          onSubmitted: _fetchSuggestions,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _useCurrentLocation,
            tooltip: 'Моё местоположение',
          ),
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                setState(() => _suggestions = []);
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _suggestions.isEmpty
              ? Center(
                  child: Text(
                    _searchController.text.length < 3
                        ? 'Введите адрес или нажмите 📍 для определения местоположения'
                        : 'Ничего не найдено',
                    style: TextStyle(color: textColor.withValues(alpha: 0.5)),
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.separated(
                  itemCount: _suggestions.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final place = _suggestions[index];
                    final displayName = place['display_name'] ?? '';
                    final parts = displayName.split(',');
                    final title = parts.first.trim();
                    final subtitle = parts.skip(1).join(',').trim();
                    final lat = double.parse(place['lat']);
                    final lon = double.parse(place['lon']);

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                        child: Icon(Icons.location_on, color: theme.colorScheme.primary, size: 20),
                      ),
                      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
                      onTap: () {
                        Navigator.pop(
                          context,
                          LocationModel(name: title, address: displayName, latitude: lat, longitude: lon),
                        );
                      },
                    );
                  },
                ),
    );
  }
}
