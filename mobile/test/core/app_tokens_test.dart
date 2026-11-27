import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sonlokma/core/theme/app_tokens.dart';

void main() {
  test('light palette matches tokens.json', () {
    expect(AppPalette.light.cream, const Color(0xFFF6EFE2));
    expect(AppPalette.light.brick, const Color(0xFFB4532A));
  });

  test('of() picks palette by brightness', () {
    expect(AppPalette.of(Brightness.dark), same(AppPalette.dark));
    expect(AppPalette.of(Brightness.light), same(AppPalette.light));
  });

  test('sizes follow 8px grid', () {
    expect(AppSizes.space3 % AppSizes.grid, 0);
    expect(AppSizes.buttonHeight, 52);
    expect(AppSizes.radius, 12);
  });
}
