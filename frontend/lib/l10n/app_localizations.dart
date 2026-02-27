import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ml.dart';
import 'app_localizations_ta.dart';

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
    Locale('ml'),
    Locale('ta'),
  ];

  /// No description provided for @login_title.
  ///
  /// In en, this message translates to:
  /// **'Welcome back!'**
  String get login_title;

  /// No description provided for @signup_title.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get signup_title;

  /// No description provided for @email_label.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get email_label;

  /// No description provided for @password_label.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password_label;

  /// No description provided for @username_label.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username_label;

  /// No description provided for @forgot_password.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgot_password;

  /// No description provided for @welcome_back.
  ///
  /// In en, this message translates to:
  /// **'Welcome back!'**
  String get welcome_back;

  /// No description provided for @sign_in_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to access your advisor'**
  String get sign_in_subtitle;

  /// No description provided for @create_account_btn.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get create_account_btn;

  /// No description provided for @login_btn.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login_btn;

  /// No description provided for @or_continue_with.
  ///
  /// In en, this message translates to:
  /// **'or continue with'**
  String get or_continue_with;

  /// No description provided for @no_account.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get no_account;

  /// No description provided for @have_account.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get have_account;

  /// No description provided for @sign_up.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get sign_up;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @tab_signup.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get tab_signup;

  /// No description provided for @tab_login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get tab_login;

  /// No description provided for @dark_mode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get dark_mode;

  /// No description provided for @app_name.
  ///
  /// In en, this message translates to:
  /// **'CHARMER'**
  String get app_name;

  /// No description provided for @app_tagline.
  ///
  /// In en, this message translates to:
  /// **'Your Voice. Your Land. Your Advisor.'**
  String get app_tagline;

  /// No description provided for @press_to_speak.
  ///
  /// In en, this message translates to:
  /// **'Press to Speak'**
  String get press_to_speak;

  /// No description provided for @listening.
  ///
  /// In en, this message translates to:
  /// **'Listening...'**
  String get listening;

  /// No description provided for @processing.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get processing;

  /// No description provided for @speaking.
  ///
  /// In en, this message translates to:
  /// **'Speaking...'**
  String get speaking;

  /// No description provided for @voice_hint.
  ///
  /// In en, this message translates to:
  /// **'Ask me about soil health, fertilizer, weather, or upload a PDF report'**
  String get voice_hint;

  /// No description provided for @upload_pdf.
  ///
  /// In en, this message translates to:
  /// **'Upload PDF'**
  String get upload_pdf;

  /// No description provided for @pdf_analyzing.
  ///
  /// In en, this message translates to:
  /// **'Analyzing document...'**
  String get pdf_analyzing;

  /// No description provided for @pdf_analyzed.
  ///
  /// In en, this message translates to:
  /// **'Document analyzed successfully'**
  String get pdf_analyzed;

  /// No description provided for @soil_health.
  ///
  /// In en, this message translates to:
  /// **'Soil Health'**
  String get soil_health;

  /// No description provided for @fertilizer_ratio.
  ///
  /// In en, this message translates to:
  /// **'Fertilizer Ratio'**
  String get fertilizer_ratio;

  /// No description provided for @weather_forecast.
  ///
  /// In en, this message translates to:
  /// **'Weather Forecast'**
  String get weather_forecast;

  /// No description provided for @crop_advisory.
  ///
  /// In en, this message translates to:
  /// **'Crop Advisory'**
  String get crop_advisory;

  /// No description provided for @hidden_risks.
  ///
  /// In en, this message translates to:
  /// **'Hidden Risks Detected'**
  String get hidden_risks;

  /// No description provided for @rainfall_deviation.
  ///
  /// In en, this message translates to:
  /// **'Rainfall Deviation'**
  String get rainfall_deviation;

  /// No description provided for @nutrient_drift.
  ///
  /// In en, this message translates to:
  /// **'Nutrient Drift'**
  String get nutrient_drift;

  /// No description provided for @risk_low.
  ///
  /// In en, this message translates to:
  /// **'Low Risk'**
  String get risk_low;

  /// No description provided for @risk_medium.
  ///
  /// In en, this message translates to:
  /// **'Medium Risk'**
  String get risk_medium;

  /// No description provided for @risk_high.
  ///
  /// In en, this message translates to:
  /// **'High Risk'**
  String get risk_high;

  /// No description provided for @why_this.
  ///
  /// In en, this message translates to:
  /// **'Why this recommendation?'**
  String get why_this;

  /// No description provided for @source_citation.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get source_citation;

  /// No description provided for @acreage.
  ///
  /// In en, this message translates to:
  /// **'Acreage (acres)'**
  String get acreage;

  /// No description provided for @crop_type.
  ///
  /// In en, this message translates to:
  /// **'Crop Type'**
  String get crop_type;

  /// No description provided for @calculate_ratio.
  ///
  /// In en, this message translates to:
  /// **'Calculate Fertilizer Ratio'**
  String get calculate_ratio;

  /// No description provided for @nitrogen.
  ///
  /// In en, this message translates to:
  /// **'Nitrogen (N)'**
  String get nitrogen;

  /// No description provided for @phosphate.
  ///
  /// In en, this message translates to:
  /// **'Phosphate (P)'**
  String get phosphate;

  /// No description provided for @potassium.
  ///
  /// In en, this message translates to:
  /// **'Potassium (K)'**
  String get potassium;

  /// No description provided for @kg_per_acre.
  ///
  /// In en, this message translates to:
  /// **'kg/acre'**
  String get kg_per_acre;

  /// No description provided for @district.
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get district;

  /// No description provided for @coimbatore.
  ///
  /// In en, this message translates to:
  /// **'Coimbatore'**
  String get coimbatore;

  /// No description provided for @kerala.
  ///
  /// In en, this message translates to:
  /// **'Kerala'**
  String get kerala;

  /// No description provided for @micro_climate.
  ///
  /// In en, this message translates to:
  /// **'Micro-Climate Data'**
  String get micro_climate;

  /// No description provided for @rainfall_10yr.
  ///
  /// In en, this message translates to:
  /// **'10-Year Rainfall'**
  String get rainfall_10yr;

  /// No description provided for @soil_type.
  ///
  /// In en, this message translates to:
  /// **'Soil Type'**
  String get soil_type;

  /// No description provided for @debug_panel.
  ///
  /// In en, this message translates to:
  /// **'Technical Metrics'**
  String get debug_panel;

  /// No description provided for @inference_latency.
  ///
  /// In en, this message translates to:
  /// **'Inference Latency'**
  String get inference_latency;

  /// No description provided for @info_density.
  ///
  /// In en, this message translates to:
  /// **'Information Density'**
  String get info_density;

  /// No description provided for @phonetic_accuracy.
  ///
  /// In en, this message translates to:
  /// **'Phonetic Accuracy'**
  String get phonetic_accuracy;

  /// No description provided for @pipeline_stage.
  ///
  /// In en, this message translates to:
  /// **'Pipeline Stage'**
  String get pipeline_stage;

  /// No description provided for @good_morning.
  ///
  /// In en, this message translates to:
  /// **'Good Morning'**
  String get good_morning;

  /// No description provided for @good_afternoon.
  ///
  /// In en, this message translates to:
  /// **'Good Afternoon'**
  String get good_afternoon;

  /// No description provided for @good_evening.
  ///
  /// In en, this message translates to:
  /// **'Good Evening'**
  String get good_evening;

  /// No description provided for @hi_user.
  ///
  /// In en, this message translates to:
  /// **'Hi, {name} 👋'**
  String hi_user(String name);

  /// No description provided for @recent_conversations.
  ///
  /// In en, this message translates to:
  /// **'Recent Conversations'**
  String get recent_conversations;

  /// No description provided for @no_conversations.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet. Press the mic to begin!'**
  String get no_conversations;

  /// No description provided for @conversation_history.
  ///
  /// In en, this message translates to:
  /// **'Conversation History'**
  String get conversation_history;
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
      <String>['en', 'ml', 'ta'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ml':
      return AppLocalizationsMl();
    case 'ta':
      return AppLocalizationsTa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
