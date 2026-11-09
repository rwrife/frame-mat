/// Pure, unit-explicit mat-cut geometry. All dimensions in one plan use the
/// same unit; no dimension is rounded for calculations or display.
library;

enum LengthUnit {
  millimeters,
  inches;

  double convert(double value, LengthUnit to) {
    _positive(value, 'length');
    if (this == to) return value;
    final converted = this == inches ? value * 25.4 : value / 25.4;
    if (!converted.isFinite || converted <= 0) {
      throw ArgumentError.value(value, 'length', 'Conversion is out of range');
    }
    return converted;
  }
}

// ponytail: doubles preserve supplied precision without display rounding, but
// are not exact decimal fractions; use decimal arithmetic if sub-ULP cuts matter.
double _positive(double value, String name) {
  if (!value.isFinite || value <= 0) {
    throw ArgumentError.value(value, name, 'Must be finite and positive');
  }
  return value;
}

class Dimensions {
  Dimensions(double width, double height)
    : width = _positive(width, 'width'),
      height = _positive(height, 'height');

  final double width;
  final double height;

  Dimensions inUnit(LengthUnit from, LengthUnit to) =>
      Dimensions(from.convert(width, to), from.convert(height, to));
}

class Borders {
  Borders(double left, double right, double top, double bottom)
    : left = _positive(left, 'left'),
      right = _positive(right, 'right'),
      top = _positive(top, 'top'),
      bottom = _positive(bottom, 'bottom');

  final double left;
  final double right;
  final double top;
  final double bottom;

  Borders inUnit(LengthUnit from, LengthUnit to) => Borders(
    from.convert(left, to),
    from.convert(right, to),
    from.convert(top, to),
    from.convert(bottom, to),
  );
}

enum MatWarning {
  noHorizontalOverlap,
  noVerticalOverlap,
  artworkExtendsBeyondBoardLeft,
  artworkExtendsBeyondBoardRight,
  artworkExtendsBeyondBoardTop,
  artworkExtendsBeyondBoardBottom,
  boardExceedsStock,
  boardExceedsFrame,
}

/// Opening centered over artwork. Borders run from opening to outer cut edges.
/// [stock] is available mat board; [frame] is maximum outer cut size.
class MatPlan {
  MatPlan({
    required this.unit,
    required this.artwork,
    required this.opening,
    required this.borders,
    required this.stock,
    required this.frame,
  });

  final LengthUnit unit;
  final Dimensions artwork;
  final Dimensions opening;
  final Borders borders;
  final Dimensions stock;
  final Dimensions frame;

  /// Outer mat cut size, not the uncut stock size.
  Dimensions get outer => Dimensions(
    _positive(borders.left + opening.width + borders.right, 'outer width'),
    _positive(borders.top + opening.height + borders.bottom, 'outer height'),
  );

  /// Signed overlap per edge; zero or negative means artwork is exposed.
  double get horizontalOverlap => (artwork.width - opening.width) / 2;
  double get verticalOverlap => (artwork.height - opening.height) / 2;

  /// Stable order for diagnostics; warnings never imply guaranteed physical fit.
  List<MatWarning> get warnings {
    final result = <MatWarning>[];
    if (horizontalOverlap <= 0) result.add(MatWarning.noHorizontalOverlap);
    if (verticalOverlap <= 0) result.add(MatWarning.noVerticalOverlap);
    if (horizontalOverlap > borders.left) {
      result.add(MatWarning.artworkExtendsBeyondBoardLeft);
    }
    if (horizontalOverlap > borders.right) {
      result.add(MatWarning.artworkExtendsBeyondBoardRight);
    }
    if (verticalOverlap > borders.top) {
      result.add(MatWarning.artworkExtendsBeyondBoardTop);
    }
    if (verticalOverlap > borders.bottom) {
      result.add(MatWarning.artworkExtendsBeyondBoardBottom);
    }
    if (outer.width > stock.width || outer.height > stock.height) {
      result.add(MatWarning.boardExceedsStock);
    }
    if (outer.width > frame.width || outer.height > frame.height) {
      result.add(MatWarning.boardExceedsFrame);
    }
    return List.unmodifiable(result);
  }

  MatPlan inUnit(LengthUnit to) => MatPlan(
    unit: to,
    artwork: artwork.inUnit(unit, to),
    opening: opening.inUnit(unit, to),
    borders: borders.inUnit(unit, to),
    stock: stock.inUnit(unit, to),
    frame: frame.inUnit(unit, to),
  );
}
