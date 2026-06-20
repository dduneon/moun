import 'package:flutter/material.dart';

abstract final class AppRadius {
  static const double card = 22;
  static const double button = 14;
  static const double navbar = 999;
  static const double chip = 8;

  static BorderRadius get cardBorderRadius =>
      BorderRadius.circular(card);

  static BorderRadius get buttonBorderRadius =>
      BorderRadius.circular(button);

  static BorderRadius get navbarBorderRadius =>
      BorderRadius.circular(navbar);
}
