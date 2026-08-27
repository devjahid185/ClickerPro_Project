import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class LiveWeather {
  const LiveWeather({
    required this.temperatureC,
    required this.feelsLikeC,
    required this.humidity,
    required this.windKmh,
    required this.precipitationMm,
    required this.condition,
    required this.weatherCode,
    required this.isDay,
    required this.latitude,
    required this.longitude,
    required this.observedAt,
  });

  final double temperatureC;
  final double feelsLikeC;
  final int humidity;
  final double windKmh;
  final double precipitationMm;
  final String condition;
  final int weatherCode;
  final bool isDay;
  final double latitude;
  final double longitude;
  final DateTime observedAt;

  String get locationLabel =>
      '${latitude.toStringAsFixed(2)}, ${longitude.toStringAsFixed(2)}';
}

class WeatherUnavailable implements Exception {
  WeatherUnavailable(this.message);

  final String message;

  @override
  String toString() => message;
}

final liveWeatherProvider = FutureProvider.autoDispose<LiveWeather>((ref) async {
  final position = await _currentPosition();
  final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
    'latitude': position.latitude.toStringAsFixed(5),
    'longitude': position.longitude.toStringAsFixed(5),
    'current': [
      'temperature_2m',
      'relative_humidity_2m',
      'apparent_temperature',
      'precipitation',
      'weather_code',
      'wind_speed_10m',
      'is_day',
    ].join(','),
    'timezone': 'auto',
  });

  http.Response response;
  try {
    response = await http.get(uri).timeout(const Duration(seconds: 12));
  } on TimeoutException {
    throw WeatherUnavailable('Weather service timed out. Try again.');
  } catch (e) {
    throw WeatherUnavailable('Weather service/network failed: $e');
  }

  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw WeatherUnavailable('Weather service error ${response.statusCode}.');
  }

  final root = jsonDecode(response.body);
  if (root is! Map || root['current'] is! Map) {
    throw WeatherUnavailable('Weather data was not readable.');
  }

  final current = (root['current'] as Map).cast<String, dynamic>();
  final code = _asInt(current['weather_code']);
  final timeRaw = current['time']?.toString();

  return LiveWeather(
    temperatureC: _asDouble(current['temperature_2m']),
    feelsLikeC: _asDouble(current['apparent_temperature']),
    humidity: _asInt(current['relative_humidity_2m']),
    windKmh: _asDouble(current['wind_speed_10m']),
    precipitationMm: _asDouble(current['precipitation']),
    condition: _conditionFor(code),
    weatherCode: code,
    isDay: _asInt(current['is_day']) == 1,
    latitude: position.latitude,
    longitude: position.longitude,
    observedAt: DateTime.tryParse(timeRaw ?? '') ?? DateTime.now(),
  );
});

Future<Position> _currentPosition() async {
  try {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw WeatherUnavailable('Allow location permission to show live weather.');
    }
    if (permission == LocationPermission.deniedForever) {
      throw WeatherUnavailable('Location permission is blocked. Enable it from app settings.');
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw WeatherUnavailable('Turn on phone location/GPS to show live weather.');
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
    } on TimeoutException {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) return last;
      throw WeatherUnavailable('Could not get GPS fix. Move near a window and retry.');
    }
  } on WeatherUnavailable {
    rethrow;
  } catch (e) {
    throw WeatherUnavailable('Location failed: $e');
  }
}

double _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

int _asInt(dynamic value) {
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String _conditionFor(int code) {
  if (code == 0) return 'CLEAR';
  if (code == 1) return 'MOSTLY CLEAR';
  if (code == 2) return 'PARTLY CLOUDY';
  if (code == 3) return 'OVERCAST';
  if (code == 45 || code == 48) return 'FOG';
  if ((code >= 51 && code <= 57) || (code >= 61 && code <= 67)) {
    return 'RAIN';
  }
  if (code >= 71 && code <= 77) return 'SNOW';
  if (code >= 80 && code <= 82) return 'SHOWERS';
  if (code >= 95 && code <= 99) return 'THUNDERSTORM';
  return 'LIVE WEATHER';
}