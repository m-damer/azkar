import 'package:flutter/material.dart';

import '../../design/colors.dart';

const int listColorCount = 5;

/// Background / foreground pair for a list colour index.
(Color, Color) listColors(AppColors c, int i) => switch (i % listColorCount) {
      0 => (c.tileMorning, c.onTileMorning),
      1 => (c.tileEvening, c.onTileEvening),
      2 => (c.tileSleep, c.onTileSleep),
      3 => (c.tileDone, c.onTileDone),
      _ => (c.navActive, c.onNavActive),
    };
