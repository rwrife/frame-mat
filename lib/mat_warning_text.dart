import 'package:frame_mat/mat_geometry.dart';

String matWarningText(MatWarning warning) => switch (warning) {
  MatWarning.noHorizontalOverlap =>
    'Opening width leaves no horizontal artwork overlap.',
  MatWarning.noVerticalOverlap =>
    'Opening height leaves no vertical artwork overlap.',
  MatWarning.artworkExtendsBeyondBoardLeft =>
    'Artwork extends beyond left mat edge.',
  MatWarning.artworkExtendsBeyondBoardRight =>
    'Artwork extends beyond right mat edge.',
  MatWarning.artworkExtendsBeyondBoardTop =>
    'Artwork extends beyond top mat edge.',
  MatWarning.artworkExtendsBeyondBoardBottom =>
    'Artwork extends beyond bottom mat edge.',
  MatWarning.boardExceedsStock => 'Outer cut exceeds available stock.',
  MatWarning.boardExceedsFrame => 'Outer cut exceeds frame dimensions.',
  MatWarning.lowerOpeningNonPositive =>
    'Lower opening is zero or negative; reduce lower reveal.',
  MatWarning.frameApertureExceedsBoard =>
    'Frame visible aperture exceeds board; frame may not retain mat.',
  MatWarning.frameObscuresOpening =>
    'Frame visible aperture is smaller than upper opening; frame hides artwork or reveal.',
};
