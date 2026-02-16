// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '轻阅屏';

  @override
  String get appName => '轻阅屏';

  @override
  String get about => '关于';

  @override
  String get legaleseLicense => '本软件为开源软件，采用 MIT 许可证。';

  @override
  String get description => '一个轻量、离线、无广告的 PDF 阅读器。';

  @override
  String get removePdfTitle => '移除 PDF 文件';

  @override
  String get removePdfPrompt => '选择要移除的 PDF 文件';

  @override
  String get removePdfNote => '（仅在列表中移除，不会从设备中删除文件）';

  @override
  String get removePdfWarn => '请选择要移除的 PDF 文件';

  @override
  String modificationTime(String Date) {
    return '修改时间：$Date';
  }

  @override
  String filePath(String Path) {
    return '文件路径：$Path';
  }

  @override
  String get emptyPdfListText => '暂无 PDF 文档';

  @override
  String get importPDF => '导入 PDF 文件';

  @override
  String get removePDF => '移除 PDF 文件';

  @override
  String get pdfReader => 'PDF 阅读器';

  @override
  String get menuButton => '菜单';

  @override
  String get panMode => '平移模式';

  @override
  String get annotationMode => '批注模式';

  @override
  String get eraserMode => '橡皮擦模式';

  @override
  String get clearButton => '清空';

  @override
  String get fitToPageButton => '自适应';

  @override
  String get zoomInButton => '放大';

  @override
  String get zoomOutButton => '缩小';

  @override
  String get settingsButton => '设置';

  @override
  String get previousPageButton => '上一页';

  @override
  String get page => '页数';

  @override
  String get nextPageButton => '下一页';

  @override
  String buttonScale(String Scale) {
    return '按钮缩放：$Scale';
  }

  @override
  String strokeWidth(String Width) {
    return '画笔粗细：$Width';
  }

  @override
  String get brushColor => '画笔颜色';

  @override
  String get selectBrushColorTitle => '选择画笔颜色';

  @override
  String get goToPageTitle => '跳转到页码';

  @override
  String get goToPageInputTip => '输入页码';

  @override
  String get goToPageInputError => '请输入有效的页码';

  @override
  String loadPdfFailed(String Error) {
    return '加载 PDF 文件失败：$Error';
  }

  @override
  String get navigationAtLastPage => '已在最后一页，返回第一页';

  @override
  String get navigationAtFirstPage => '已在第一页，跳转到最后一页';

  @override
  String somethingWentWrong(String Error) {
    return '发生错误：$Error';
  }

  @override
  String get tip => '提示';

  @override
  String get cancel => '取消';

  @override
  String get remove => '移除';

  @override
  String get ok => '确定';

  @override
  String get error => '错误';

  @override
  String get more => '更多';
}
