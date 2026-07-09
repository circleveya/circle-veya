import 'package:flutter/material.dart';

enum LocationType {
  indoor,
  outdoor;

  String get label => switch (this) {
        indoor => 'Indoor',
        outdoor => 'Outdoor',
      };

  String get dbValue => name;

  IconData get icon => switch (this) {
        indoor => Icons.home_outlined,
        outdoor => Icons.park_outlined,
      };
}

enum WeatherCondition {
  cold,
  rain,
  sun;

  String get label => switch (this) {
        cold => 'Kälte',
        rain => 'Regen',
        sun => 'Sonne',
      };

  String get dbValue => name;

  IconData get icon => switch (this) {
        cold => Icons.ac_unit,
        rain => Icons.water_drop_outlined,
        sun => Icons.wb_sunny_outlined,
      };
}
