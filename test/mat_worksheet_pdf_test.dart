import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frame_mat/mat_geometry.dart';
import 'package:frame_mat/mat_worksheet_pdf.dart';

MatPlan _plan({bool doubleMat = false, bool invalidLowerCut = false}) =>
    MatPlan(
      unit: LengthUnit.millimeters,
      artwork: Dimensions(200, 300),
      opening: Dimensions(190, 290),
      borders: Borders(40, 40, 50, 50),
      stock: Dimensions(invalidLowerCut ? 260 : 270, 390),
      frame: Dimensions(270, 390),
      lowerReveal: doubleMat
          ? Borders(invalidLowerCut ? 100 : 4, invalidLowerCut ? 100 : 4, 4, 4)
          : null,
      frameAperture: Dimensions(270, 390),
    );

void main() {
  test('writes a valid one-page PDF with exact dimensional rows', () {
    final bytes = createMatWorksheetPdf(_plan(doubleMat: true));
    final pdf = ascii.decode(bytes);
    expect(pdf, startsWith('%PDF-1.4\n'));
    expect(pdf, contains('/MediaBox [0 0 612.0 792.0]'));
    expect(pdf, contains('Outer board cut: 270.0 x 390.0 mm'));
    expect(pdf, contains('Frame maximum outer cut: 270.0 x 390.0 mm'));
    expect(
      pdf,
      contains('Upper borders L/R/T/B: 40.0 / 40.0 / 50.0 / 50.0 mm'),
    );
    expect(pdf, contains('Measured frame aperture: 270.0 x 390.0 mm'));
    expect(pdf, contains('Lower opening: 182.0 x 282.0 mm'));
    expect(pdf, contains('Lower reveal L/R/T/B: 4.0 / 4.0 / 4.0 / 4.0 mm'));
    expect(pdf, contains('None for the entered dimensions.'));
    expect(
      pdf,
      contains(
        'All measurements are user-entered. Verify them before cutting.',
      ),
    );
    expect(pdf, contains('diagram is illustrative, not 1:1.'));
    expect(pdf, contains('Calculated fit is not a guarantee.'));

    final startXref = int.parse(
      RegExp(r'startxref\n(\d+)').firstMatch(pdf)!.group(1)!,
    );
    expect(pdf.substring(startXref, startXref + 4), 'xref');
  });

  test('reports uncuttable cuts, fit warnings, and escaped draft names', () {
    final pdf = ascii.decode(
      createMatWorksheetPdf(
        _plan(doubleMat: true, invalidLowerCut: true),
        draftName: 'Gallery (west)\\ 1',
      ),
    );
    expect(pdf, contains(r'Draft: Gallery \(west\)\\ 1'));
    expect(pdf, contains('Lower opening: NOT CUTTABLE'));
    expect(
      pdf,
      contains('Lower opening is zero or negative; reduce lower reveal.'),
    );
    expect(pdf, contains('Outer cut exceeds available stock.'));
  });

  test('keeps measurements unrounded and uses the selected unit', () {
    final plan = MatPlan(
      unit: LengthUnit.inches,
      artwork: Dimensions(8.125, 10),
      opening: Dimensions(7.5, 9.5),
      borders: Borders(0.75, 0.75, 0.75, 0.75),
      stock: Dimensions(9, 11),
      frame: Dimensions(9, 11),
    );
    final pdf = ascii.decode(createMatWorksheetPdf(plan));
    expect(pdf, contains('Artwork: 8.125 x 10.0 in'));
    expect(pdf, contains('Outer board cut: 9.0 x 11.0 in'));
  });
}
