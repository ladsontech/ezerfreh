import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Color primaryColor = Color(0xFF4CAF50);
const Color secondaryColor = Color(0xFFFF9800);

final ThemeData appTheme = ThemeData(
  primaryColor: primaryColor,
  colorScheme: ColorScheme.fromSeed(
    seedColor: primaryColor,
    secondary: secondaryColor,
  ),
  textTheme: GoogleFonts.latoTextTheme(),
  appBarTheme: AppBarTheme(
    backgroundColor: primaryColor,
    titleTextStyle: GoogleFonts.lato(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
  ),
);
