// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'LiteView';

  @override
  String get appName => 'LiteView';

  @override
  String get about => 'About';

  @override
  String get legaleseLicense =>
      'This software is open source and licensed under the MIT License.';

  @override
  String get description => 'A lite, offline and ad-free PDF reader.';

  @override
  String get removePdfTitle => 'Remove PDF';

  @override
  String get removePdfPrompt => 'Select a PDF file to remove';

  @override
  String get removePdfNote =>
      '(Only removed from the list, not deleted from your device.)';

  @override
  String get removePdfWarn => 'Please select a PDF file to remove.';

  @override
  String modificationTime(String Date) {
    return 'Modified: $Date';
  }

  @override
  String filePath(String Path) {
    return 'Path: $Path';
  }

  @override
  String get emptyPdfListText => 'No PDFs yet.';

  @override
  String get importPDF => 'Import PDF';

  @override
  String get removePDF => 'Remove PDF';

  @override
  String get pdfReader => 'PDF Reader';

  @override
  String get menuButton => 'Menu';

  @override
  String get panMode => 'Pan Mode';

  @override
  String get annotationMode => 'Annotation Mode';

  @override
  String get eraserMode => 'Eraser Mode';

  @override
  String get clearButton => 'Clear';

  @override
  String get fitToPageButton => 'Fit To Page';

  @override
  String get zoomInButton => 'Zoom In';

  @override
  String get zoomOutButton => 'Zoom Out';

  @override
  String get settingsButton => 'Settings';

  @override
  String get previousPageButton => 'Previous Page';

  @override
  String get page => 'Page';

  @override
  String get nextPageButton => 'Next Page';

  @override
  String buttonScale(String Scale) {
    return 'Button Scale: $Scale';
  }

  @override
  String strokeWidth(String Width) {
    return 'Stroke Width: $Width';
  }

  @override
  String get brushColor => 'Brush Color';

  @override
  String get selectBrushColorTitle => 'Select Brush Color';

  @override
  String get goToPageTitle => 'Go to page';

  @override
  String get goToPageInputTip => 'Input page number';

  @override
  String get goToPageInputError => 'Please input valid page number';

  @override
  String loadPdfFailed(String Error) {
    return 'Load PDF failed: $Error';
  }

  @override
  String get navigationAtLastPage =>
      'Already at the last page, jumped to the first page.';

  @override
  String get navigationAtFirstPage =>
      'Already at the first page, jumped to the last page.';

  @override
  String somethingWentWrong(String Error) {
    return 'Something went wrong: $Error';
  }

  @override
  String get tip => 'Tip';

  @override
  String get cancel => 'Cancel';

  @override
  String get remove => 'Remove';

  @override
  String get ok => 'OK';

  @override
  String get error => 'Error';

  @override
  String get more => 'More';
}
