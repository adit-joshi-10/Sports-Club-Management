import 'package:flutter/material.dart';

import '../models/app_user.dart';
import 'arena_colors.dart';

/// Each role gets its own zone of the stadium.
extension RoleStyle on ClubRole {
  String get zone => switch (this) {
        ClubRole.admin => 'CLUB HQ',
        ClubRole.coach => 'THE SIDELINE',
        ClubRole.member => 'PLAYER LOCKER',
      };

  String get tag => switch (this) {
        ClubRole.admin => 'CLUB OFFICIAL',
        ClubRole.coach => 'COACHING STAFF',
        ClubRole.member => 'PLAYER',
      };

  Color get accent => switch (this) {
        ClubRole.admin => Arena.gold,
        ClubRole.coach => Arena.pitch,
        ClubRole.member => Arena.orange,
      };

  IconData get icon => switch (this) {
        ClubRole.admin => Icons.shield_rounded,
        ClubRole.coach => Icons.sports_rounded,
        ClubRole.member => Icons.person_rounded,
      };
}