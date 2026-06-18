import 'package:map_launcher/map_launcher.dart';
import '../data/models/location_model.dart';

class LocationService {
  static Future<bool> openInMaps(LocationModel location) async {
    try {
      final availableMaps = await MapLauncher.installedMaps;
      if (availableMaps.isEmpty) return false;

      if (availableMaps.length == 1) {
        await availableMaps.first.showMarker(
          coords: Coords(
            location.latitude ?? 0,
            location.longitude ?? 0,
          ),
          title: location.name,
          description: location.address ?? '',
        );
        return true;
      }

      await availableMaps.first.showMarker(
        coords: Coords(
          location.latitude ?? 0,
          location.longitude ?? 0,
        ),
        title: location.name,
        description: location.address ?? '',
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<List<AvailableMap>> getInstalledMaps() async {
    return await MapLauncher.installedMaps;
  }
}
