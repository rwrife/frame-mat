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
  lowerOpeningNonPositive,
  frameApertureExceedsBoard,
  frameObscuresOpening,
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
    this.lowerReveal,
    this.frameAperture,
  });

  final LengthUnit unit;
  final Dimensions artwork;

  /// Upper mat opening. Lower mat, when present, has a smaller opening.
  final Dimensions opening;
  final Borders borders;
  final Dimensions stock;

  /// Maximum outer cut accepted by frame, not its visible aperture.
  final Dimensions frame;

  /// Visible lower-mat strip at each upper opening edge, in [unit].
  final Borders? lowerReveal;

  /// Measured visible frame aperture; optional because rebate is frame-specific.
  final Dimensions? frameAperture;

  double get lowerOpeningWidth =>
      opening.width - (lowerReveal?.left ?? 0) - (lowerReveal?.right ?? 0);
  double get lowerOpeningHeight =>
      opening.height - (lowerReveal?.top ?? 0) - (lowerReveal?.bottom ?? 0);

  /// Positive only when lower opening is cuttable; never silently clamp it.
  Dimensions? get lowerOpening =>
      lowerReveal != null && lowerOpeningWidth > 0 && lowerOpeningHeight > 0
      ? Dimensions(lowerOpeningWidth, lowerOpeningHeight)
      : null;

  double get lowerOpeningLeft => borders.left + (lowerReveal?.left ?? 0);
  double get lowerOpeningTop => borders.top + (lowerReveal?.top ?? 0);

  /// Visible artwork overlap measured at the actual lower cut, when present.
  double get effectiveHorizontalOverlap =>
      (artwork.width - (lowerOpening?.width ?? opening.width)) / 2;
  double get effectiveVerticalOverlap =>
      (artwork.height - (lowerOpening?.height ?? opening.height)) / 2;

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
    if (lowerReveal != null && lowerOpening == null) {
      result.add(MatWarning.lowerOpeningNonPositive);
    }
    // Center artwork on upper opening; lower reveal shifts each lower cut edge.
    final leftOverlap = horizontalOverlap + (lowerReveal?.left ?? 0);
    final rightOverlap = horizontalOverlap + (lowerReveal?.right ?? 0);
    final topOverlap = verticalOverlap + (lowerReveal?.top ?? 0);
    final bottomOverlap = verticalOverlap + (lowerReveal?.bottom ?? 0);
    if (leftOverlap <= 0 || rightOverlap <= 0) {
      result.add(MatWarning.noHorizontalOverlap);
    }
    if (topOverlap <= 0 || bottomOverlap <= 0) {
      result.add(MatWarning.noVerticalOverlap);
    }
    if (leftOverlap > borders.left + (lowerReveal?.left ?? 0)) {
      result.add(MatWarning.artworkExtendsBeyondBoardLeft);
    }
    if (rightOverlap > borders.right + (lowerReveal?.right ?? 0)) {
      result.add(MatWarning.artworkExtendsBeyondBoardRight);
    }
    if (topOverlap > borders.top + (lowerReveal?.top ?? 0)) {
      result.add(MatWarning.artworkExtendsBeyondBoardTop);
    }
    if (bottomOverlap > borders.bottom + (lowerReveal?.bottom ?? 0)) {
      result.add(MatWarning.artworkExtendsBeyondBoardBottom);
    }
    if (outer.width > stock.width || outer.height > stock.height) {
      result.add(MatWarning.boardExceedsStock);
    }
    if (outer.width > frame.width || outer.height > frame.height) {
      result.add(MatWarning.boardExceedsFrame);
    }
    if (frameAperture != null) {
      if (frameAperture!.width > outer.width ||
          frameAperture!.height > outer.height) {
        result.add(MatWarning.frameApertureExceedsBoard);
      }
      if (frameAperture!.width < opening.width ||
          frameAperture!.height < opening.height) {
        result.add(MatWarning.frameObscuresOpening);
      }
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
    lowerReveal: lowerReveal?.inUnit(unit, to),
    frameAperture: frameAperture?.inUnit(unit, to),
  );
}
