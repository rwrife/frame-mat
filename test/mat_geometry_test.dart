import 'package:flutter_test/flutter_test.dart';
import 'package:frame_mat/mat_geometry.dart';

MatPlan plan({
  Dimensions? artwork,
  Dimensions? opening,
  Borders? borders,
  Dimensions? stock,
  Dimensions? frame,
}) => MatPlan(
  unit: LengthUnit.millimeters,
  artwork: artwork ?? Dimensions(200, 300),
  opening: opening ?? Dimensions(190, 290),
  borders: borders ?? Borders(40, 40, 50, 50),
  stock: stock ?? Dimensions(270, 390),
  frame: frame ?? Dimensions(270, 390),
);

void main() {
  test('exact board/stock/frame fit, overlap, no rounding', () {
    final p = plan();
    expect(p.outer.width, 270);
    expect(p.outer.height, 390);
    expect(p.horizontalOverlap, 5);
    expect(p.verticalOverlap, 5);
    expect(p.warnings, isEmpty);
    final precise = plan(opening: Dimensions(190.125, 290));
    expect(precise.outer.width, 270.125);
    expect(precise.warnings, [
      MatWarning.boardExceedsStock,
      MatWarning.boardExceedsFrame,
    ]);
  });

  test('zero overlap, exposed art, stock/frame overrun have stable order', () {
    final p = plan(
      artwork: Dimensions(200, 300),
      opening: Dimensions(200, 302),
      borders: Borders(1, 1, 1, 1),
      stock: Dimensions(201, 303),
      frame: Dimensions(201, 303),
    );
    expect(p.horizontalOverlap, 0);
    expect(p.verticalOverlap, -1);
    expect(p.warnings, [
      MatWarning.noHorizontalOverlap,
      MatWarning.noVerticalOverlap,
      MatWarning.boardExceedsStock,
      MatWarning.boardExceedsFrame,
    ]);
    expect(plan(borders: Borders(4, 5, 4, 5)).warnings, [
      MatWarning.artworkExtendsBeyondBoardLeft,
      MatWarning.artworkExtendsBeyondBoardTop,
    ]);
  });

  test('all inputs reject zero, negative, NaN and infinity', () {
    for (final invalid in [
      0.0,
      -0.5,
      double.nan,
      double.infinity,
      double.negativeInfinity,
    ]) {
      expect(() => Dimensions(invalid, 1), throwsArgumentError);
      expect(() => Dimensions(1, invalid), throwsArgumentError);
      expect(() => Borders(invalid, 1, 1, 1), throwsArgumentError);
      expect(() => Borders(1, invalid, 1, 1), throwsArgumentError);
      expect(() => Borders(1, 1, invalid, 1), throwsArgumentError);
      expect(() => Borders(1, 1, 1, invalid), throwsArgumentError);
      expect(
        () => LengthUnit.inches.convert(invalid, LengthUnit.millimeters),
        throwsArgumentError,
      );
    }
    expect(
      () => plan(
        opening: Dimensions(double.maxFinite, 1),
        borders: Borders(1, double.maxFinite, 1, 1),
      ).outer,
      throwsArgumentError,
    );
    expect(
      () => LengthUnit.inches.convert(double.maxFinite, LengthUnit.millimeters),
      throwsArgumentError,
    );
  });

  test('explicit conversion keeps unit and geometry consistent', () {
    expect(LengthUnit.inches.convert(1, LengthUnit.millimeters), 25.4);
    expect(LengthUnit.millimeters.convert(25.4, LengthUnit.inches), 1);
    final p = MatPlan(
      unit: LengthUnit.inches,
      artwork: Dimensions(8, 10),
      opening: Dimensions(7, 9),
      borders: Borders(1, 1, 1, 1),
      stock: Dimensions(9, 11),
      frame: Dimensions(9, 11),
    );
    final mm = p.inUnit(LengthUnit.millimeters);
    expect(mm.unit, LengthUnit.millimeters);
    expect(mm.artwork.width, 203.2);
    expect(mm.warnings, isEmpty);
    expect(mm.outer.width, closeTo(228.6, 1e-10));
    expect(p.warnings, isEmpty);
  });
}
