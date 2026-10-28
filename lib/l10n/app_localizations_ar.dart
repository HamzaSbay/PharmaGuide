// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'فارماغايد تونس';

  @override
  String get searchHint => 'ابحث عن دواء (اسم تجاري، DCI، دارجة)...';

  @override
  String get searchByCategory => 'البحث حسب الفئة';

  @override
  String get filterRadius => 'نطاق البحث';

  @override
  String get filterCnam => 'صيدليات متعاقدة مع CNAM فقط';

  @override
  String get filterGarde => 'صيدليات المداومة فقط';

  @override
  String get holdRequest => 'احجز لمدة ساعتين';

  @override
  String get holdActive => 'الحجوزات النشطة';

  @override
  String get holdExpires => 'ينتهي في';

  @override
  String get holdStatus_pending => 'قيد الانتظار';

  @override
  String get holdStatus_confirmed => 'مؤكد';

  @override
  String get holdStatus_expired => 'منتهي الصلاحية';

  @override
  String get holdStatus_declined => 'مرفوض';

  @override
  String get holdStatus_collected => 'تم الاستلام';

  @override
  String get drugInteractions => 'التداخلات الدوائية';

  @override
  String get emergencyBroadcast => 'تنبيه طوارئ';

  @override
  String get offlinePhonebook => 'دليل الهاتف بدون إنترنت';

  @override
  String get prescriptionOcr => 'مسح الوصفة الطبية';

  @override
  String get chronicReminders => 'تذكيرات الأدوية المزمنة';

  @override
  String get mapTitle => 'خريطة تونس';

  @override
  String get favorites => 'المفضلة';

  @override
  String get profile => 'الملف الشخصي';

  @override
  String get settings => 'الإعدادات';

  @override
  String get language => 'اللغة';

  @override
  String get pharmacyOpen => 'مفتوحة';

  @override
  String get pharmacyClosed => 'مغلقة';

  @override
  String get pharmacyGarde => 'مداومة';

  @override
  String get inStock => 'متوفر';

  @override
  String get outOfStock => 'غير متوفر';

  @override
  String get distance => 'المسافة';

  @override
  String get callPharmacy => 'اتصل';

  @override
  String get getDirections => 'الاتجاهات';

  @override
  String get requiresPrescription => 'تستلزم وصفة طبية';

  @override
  String get cnamReimbursable => 'قابل للاسترداد CNAM';

  @override
  String get sideEffects => 'الأعراض الجانبية';

  @override
  String get contraindications => 'موانع الاستعمال';

  @override
  String get interactions => 'التداخلات';

  @override
  String get genericAlternatives => 'البدائل الجنيسة';

  @override
  String get noResults => 'لا توجد نتائج';

  @override
  String get tryAgain => 'أعد المحاولة';

  @override
  String get cancel => 'إلغاء';

  @override
  String get confirm => 'تأكيد';

  @override
  String get close => 'إغلاق';

  @override
  String get loading => 'جاري التحميل...';

  @override
  String get errorOccurred => 'حدث خطأ';

  @override
  String get allGovernoratesLabel => 'جميع الولايات الـ 24';

  @override
  String get welcomeTitle => 'مرحبا بك في فارماغايد تونس';

  @override
  String get welcomeSubtitle => 'اعثر على أدويتك في الصيدلية، في كل أنحاء تونس';

  @override
  String get onboardingStep1Title => 'ابحث عن دوائك';

  @override
  String get onboardingStep1Desc =>
      'بالاسم التجاري، المادة الفعالة، أو حتى بالدارجة التونسية';

  @override
  String get onboardingStep2Title => 'حدد الصيدلية';

  @override
  String get onboardingStep2Desc =>
      'شوف في الوقت الحقيقي شكون عندو الدواء متاعك';

  @override
  String get onboardingStep3Title => 'احجز لمدة ساعتين';

  @override
  String get onboardingStep3Desc => 'دواءك يستناك في الصيدلية لمدة ساعتين';

  @override
  String get getStarted => 'ابدأ';

  @override
  String get skip => 'تخطي';

  @override
  String get next => 'التالي';
}
