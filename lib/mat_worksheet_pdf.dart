import 'dart:convert';

import 'package:frame_mat/mat_geometry.dart';
import 'package:frame_mat/mat_warning_text.dart';

List<int> createMatWorksheetPdf(MatPlan plan, {String? draftName}) {
  const pageWidth = 612.0;
  const pageHeight = 792.0;
  const margin = 42.0;
  const diagramWidth = pageWidth - margin * 2;
  const diagramHeight = 210.0;
  const diagramBottom = 425.0;
  final content = StringBuffer();

  void text(String value, double x, double y, {double size = 9, bool bold = false}) {
    final font = bold ? 'F2' : 'F1';
    content.writeln(
      'BT /$font ${_number(size)} Tf ${_number(x)} ${_number(y)} Td '
      '(${_escapePdfText(value)}) Tj ET',
    );
  }

  final unit = plan.unit == LengthUnit.millimeters ? 'mm' : 'in';
  String dimensions(Dimensions value) =>
      '${value.width} x ${value.height} $unit';
  String edges(double left, double right, double top, double bottom) =>
      '$left / $right / $top / $bottom $unit';

  text('Frame Mat - Cutting Worksheet', margin, 750, size: 18, bold: true);
  text('All measurements are user-entered. Verify them before cutting.', margin, 728);
  text('Assumes a centered opening and square cuts; diagram is illustrative, not 1:1.', margin, 712);
  text('Draft: ${draftName == null || draftName.isEmpty ? 'Unsaved plan' : draftName}', margin, 692);
  text('MAT LAYOUT', margin, 660, size: 10, bold: true);

  final outer = plan.outer;
  final isWide = outer.width >= outer.height;
  final boardWidth = isWide
      ? diagramWidth
      : outer.width / outer.height * diagramHeight;
  final boardHeight = isWide
      ? outer.height / outer.width * diagramWidth
      : diagramHeight;
  final boardX = (pageWidth - boardWidth) / 2;
  final boardY = diagramBottom + (diagramHeight - boardHeight) / 2;
  final openingX = boardX + plan.borders.left / outer.width * boardWidth;
  final openingY = boardY + plan.borders.bottom / outer.height * boardHeight;
  final openingWidth = plan.opening.width / outer.width * boardWidth;
  final openingHeight = plan.opening.height / outer.height * boardHeight;

  content.writeln('0.20 0.35 0.47 rg');
  content.writeln(
    '${_number(boardX)} ${_number(boardY)} ${_number(boardWidth)} ${_number(boardHeight)} re f',
  );
  content.writeln('0 0 0 RG 0.8 w');
  content.writeln(
    '${_number(boardX)} ${_number(boardY)} ${_number(boardWidth)} ${_number(boardHeight)} re S',
  );
  if (plan.lowerReveal != null && plan.lowerOpening != null) {
    content.writeln('0.71 0.44 0.28 rg');
    content.writeln(
      '${_number(openingX)} ${_number(openingY)} ${_number(openingWidth)} ${_number(openingHeight)} re f',
    );
    final lowerX = boardX + plan.lowerOpeningLeft / outer.width * boardWidth;
    final lowerY =
        boardY +
        (plan.borders.bottom + plan.lowerReveal!.bottom) /
            outer.height *
            boardHeight;
    final lowerWidth = plan.lowerOpening!.width / outer.width * boardWidth;
    final lowerHeight = plan.lowerOpening!.height / outer.height * boardHeight;
    content.writeln('1 1 1 rg');
    content.writeln(
      '${_number(lowerX)} ${_number(lowerY)} ${_number(lowerWidth)} ${_number(lowerHeight)} re f',
    );
    content.writeln('0 0 0 RG 0.8 w');
    content.writeln(
      '${_number(lowerX)} ${_number(lowerY)} ${_number(lowerWidth)} ${_number(lowerHeight)} re S',
    );
  } else {
    content.writeln('1 1 1 rg');
    content.writeln(
      '${_number(openingX)} ${_number(openingY)} ${_number(openingWidth)} ${_number(openingHeight)} re f',
    );
  }
  content.writeln('0 0 0 RG 0.8 w');
  content.writeln(
    '${_number(openingX)} ${_number(openingY)} ${_number(openingWidth)} ${_number(openingHeight)} re S',
  );
  text('Outer cut: ${dimensions(outer)}', margin, 405, size: 8);
  text('Opening: ${dimensions(plan.opening)}', margin, 393, size: 8);

  final rows = <String>[
    'Artwork: ${dimensions(plan.artwork)}',
    'Upper opening: ${dimensions(plan.opening)}',
    'Upper borders L/R/T/B: ${edges(plan.borders.left, plan.borders.right, plan.borders.top, plan.borders.bottom)}',
    'Outer board cut: ${dimensions(outer)}',
    'Available stock: ${dimensions(plan.stock)}',
    'Frame maximum outer cut: ${dimensions(plan.frame)}',
    if (plan.frameAperture != null)
      'Measured frame aperture: ${dimensions(plan.frameAperture!)}',
    'Upper-opening overlap L/R/T/B: ${edges(plan.horizontalOverlap, plan.horizontalOverlap, plan.verticalOverlap, plan.verticalOverlap)}',
    if (plan.lowerReveal != null) ...[
      'Lower reveal L/R/T/B: ${edges(plan.lowerReveal!.left, plan.lowerReveal!.right, plan.lowerReveal!.top, plan.lowerReveal!.bottom)}',
      'Lower opening: ${plan.lowerOpening == null ? 'NOT CUTTABLE' : dimensions(plan.lowerOpening!)}',
      'Lower-opening overlap L/R/T/B: ${edges(plan.horizontalOverlap + plan.lowerReveal!.left, plan.horizontalOverlap + plan.lowerReveal!.right, plan.verticalOverlap + plan.lowerReveal!.top, plan.verticalOverlap + plan.lowerReveal!.bottom)}',
    ],
  ];
  text('MEASUREMENTS', margin, 374, size: 10, bold: true);
  var y = 357.0;
  for (final row in rows) {
    text(row, margin, y, size: 8);
    y -= 12;
  }

  y -= 7;
  text('CALCULATED FIT WARNINGS', margin, y, size: 10, bold: true);
  y -= 15;
  if (plan.warnings.isEmpty) {
    text('None for the entered dimensions.', margin, y, size: 8);
  } else {
    for (final warning in plan.warnings) {
      text('- ${matWarningText(warning)}', margin, y, size: 8);
      y -= 11;
    }
  }
  text('Check artwork, frame rebate, board and cutter tolerances with physical measurements.', margin, 52, size: 8);
  text('Calculated fit is not a guarantee. Never use this diagram as a 1:1 cutting template.', margin, 40, size: 8);

  final stream = content.toString();
  final streamBytes = ascii.encode(stream);
  final objects = <String>[
    '<< /Type /Catalog /Pages 2 0 R >>',
    '<< /Type /Pages /Kids [3 0 R] /Count 1 >>',
    '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 $pageWidth $pageHeight] '
        '/Resources << /Font << /F1 4 0 R /F2 5 0 R >> >> /Contents 6 0 R >>',
    '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>',
    '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold >>',
    '<< /Length ${streamBytes.length} >>\nstream\n$stream' 'endstream',
  ];
  final output = <int>[];
  void append(String value) => output.addAll(ascii.encode(value));

  append('%PDF-1.4\n');
  final offsets = <int>[];
  for (var index = 0; index < objects.length; index++) {
    offsets.add(output.length);
    append('${index + 1} 0 obj\n${objects[index]}\nendobj\n');
  }
  final crossReferenceOffset = output.length;
  append('xref\n0 ${objects.length + 1}\n0000000000 65535 f \n');
  for (final offset in offsets) {
    append('${offset.toString().padLeft(10, '0')} 00000 n \n');
  }
  append(
    'trailer\n<< /Size ${objects.length + 1} /Root 1 0 R >>\n'
    'startxref\n$crossReferenceOffset\n%%EOF\n',
  );
  return output;
}

String _number(double value) => value.toStringAsFixed(3);

String _escapePdfText(String value) => value
    .replaceAll(RegExp(r'[^\x20-\x7E]'), '?')
    .replaceAll('\\', '\\\\')
    .replaceAll('(', r'\(')
    .replaceAll(')', r'\)');
