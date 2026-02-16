import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In zh, this message translates to:
  /// **'轻阅屏'**
  String get appTitle;

  /// No description provided for @appName.
  ///
  /// In zh, this message translates to:
  /// **'轻阅屏'**
  String get appName;

  /// No description provided for @about.
  ///
  /// In zh, this message translates to:
  /// **'关于'**
  String get about;

  /// No description provided for @legaleseLicense.
  ///
  /// In zh, this message translates to:
  /// **'本软件为开源软件，采用 MIT 许可证。'**
  String get legaleseLicense;

  /// No description provided for @description.
  ///
  /// In zh, this message translates to:
  /// **'一个轻量、离线、无广告的 PDF 阅读器。'**
  String get description;

  /// No description provided for @removePdfTitle.
  ///
  /// In zh, this message translates to:
  /// **'移除 PDF 文件'**
  String get removePdfTitle;

  /// No description provided for @removePdfPrompt.
  ///
  /// In zh, this message translates to:
  /// **'选择要移除的 PDF 文件'**
  String get removePdfPrompt;

  /// No description provided for @removePdfNote.
  ///
  /// In zh, this message translates to:
  /// **'（仅在列表中移除，不会从设备中删除文件）'**
  String get removePdfNote;

  /// No description provided for @removePdfWarn.
  ///
  /// In zh, this message translates to:
  /// **'请选择要移除的 PDF 文件'**
  String get removePdfWarn;

  /// 修改时间
  ///
  /// In zh, this message translates to:
  /// **'修改时间：{Date}'**
  String modificationTime(String Date);

  /// 文件路径
  ///
  /// In zh, this message translates to:
  /// **'文件路径：{Path}'**
  String filePath(String Path);

  /// No description provided for @emptyPdfListText.
  ///
  /// In zh, this message translates to:
  /// **'暂无 PDF 文档'**
  String get emptyPdfListText;

  /// No description provided for @importPDF.
  ///
  /// In zh, this message translates to:
  /// **'导入 PDF 文件'**
  String get importPDF;

  /// No description provided for @removePDF.
  ///
  /// In zh, this message translates to:
  /// **'移除 PDF 文件'**
  String get removePDF;

  /// No description provided for @pdfReader.
  ///
  /// In zh, this message translates to:
  /// **'PDF 阅读器'**
  String get pdfReader;

  /// No description provided for @menuButton.
  ///
  /// In zh, this message translates to:
  /// **'菜单'**
  String get menuButton;

  /// No description provided for @panMode.
  ///
  /// In zh, this message translates to:
  /// **'平移模式'**
  String get panMode;

  /// No description provided for @annotationMode.
  ///
  /// In zh, this message translates to:
  /// **'批注模式'**
  String get annotationMode;

  /// No description provided for @eraserMode.
  ///
  /// In zh, this message translates to:
  /// **'橡皮擦模式'**
  String get eraserMode;

  /// No description provided for @clearButton.
  ///
  /// In zh, this message translates to:
  /// **'清空'**
  String get clearButton;

  /// No description provided for @fitToPageButton.
  ///
  /// In zh, this message translates to:
  /// **'自适应'**
  String get fitToPageButton;

  /// No description provided for @zoomInButton.
  ///
  /// In zh, this message translates to:
  /// **'放大'**
  String get zoomInButton;

  /// No description provided for @zoomOutButton.
  ///
  /// In zh, this message translates to:
  /// **'缩小'**
  String get zoomOutButton;

  /// No description provided for @settingsButton.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get settingsButton;

  /// No description provided for @previousPageButton.
  ///
  /// In zh, this message translates to:
  /// **'上一页'**
  String get previousPageButton;

  /// No description provided for @page.
  ///
  /// In zh, this message translates to:
  /// **'页数'**
  String get page;

  /// No description provided for @nextPageButton.
  ///
  /// In zh, this message translates to:
  /// **'下一页'**
  String get nextPageButton;

  /// 按钮缩放
  ///
  /// In zh, this message translates to:
  /// **'按钮缩放：{Scale}'**
  String buttonScale(String Scale);

  /// 画笔粗细
  ///
  /// In zh, this message translates to:
  /// **'画笔粗细：{Width}'**
  String strokeWidth(String Width);

  /// No description provided for @brushColor.
  ///
  /// In zh, this message translates to:
  /// **'画笔颜色'**
  String get brushColor;

  /// No description provided for @selectBrushColorTitle.
  ///
  /// In zh, this message translates to:
  /// **'选择画笔颜色'**
  String get selectBrushColorTitle;

  /// No description provided for @goToPageTitle.
  ///
  /// In zh, this message translates to:
  /// **'跳转到页码'**
  String get goToPageTitle;

  /// No description provided for @goToPageInputTip.
  ///
  /// In zh, this message translates to:
  /// **'输入页码'**
  String get goToPageInputTip;

  /// No description provided for @goToPageInputError.
  ///
  /// In zh, this message translates to:
  /// **'请输入有效的页码'**
  String get goToPageInputError;

  /// 加载 PDF 文件失败
  ///
  /// In zh, this message translates to:
  /// **'加载 PDF 文件失败：{Error}'**
  String loadPdfFailed(String Error);

  /// No description provided for @navigationAtLastPage.
  ///
  /// In zh, this message translates to:
  /// **'已在最后一页，返回第一页'**
  String get navigationAtLastPage;

  /// No description provided for @navigationAtFirstPage.
  ///
  /// In zh, this message translates to:
  /// **'已在第一页，跳转到最后一页'**
  String get navigationAtFirstPage;

  /// 发生错误
  ///
  /// In zh, this message translates to:
  /// **'发生错误：{Error}'**
  String somethingWentWrong(String Error);

  /// No description provided for @tip.
  ///
  /// In zh, this message translates to:
  /// **'提示'**
  String get tip;

  /// No description provided for @cancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get cancel;

  /// No description provided for @remove.
  ///
  /// In zh, this message translates to:
  /// **'移除'**
  String get remove;

  /// No description provided for @ok.
  ///
  /// In zh, this message translates to:
  /// **'确定'**
  String get ok;

  /// No description provided for @error.
  ///
  /// In zh, this message translates to:
  /// **'错误'**
  String get error;

  /// No description provided for @more.
  ///
  /// In zh, this message translates to:
  /// **'更多'**
  String get more;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
