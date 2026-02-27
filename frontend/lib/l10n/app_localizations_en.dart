// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get login_title => 'Welcome back!';

  @override
  String get signup_title => 'Create Account';

  @override
  String get email_label => 'Email Address';

  @override
  String get password_label => 'Password';

  @override
  String get username_label => 'Username';

  @override
  String get forgot_password => 'Forgot Password?';

  @override
  String get welcome_back => 'Welcome back!';

  @override
  String get sign_in_subtitle => 'Sign in to access your advisor';

  @override
  String get create_account_btn => 'Create Account';

  @override
  String get login_btn => 'Login';

  @override
  String get or_continue_with => 'or continue with';

  @override
  String get no_account => 'Don\'t have an account? ';

  @override
  String get have_account => 'Already have an account? ';

  @override
  String get sign_up => 'Sign Up';

  @override
  String get language => 'Language';

  @override
  String get tab_signup => 'Sign Up';

  @override
  String get tab_login => 'Login';

  @override
  String get dark_mode => 'Dark Mode';

  @override
  String get app_name => 'CHARMER';

  @override
  String get app_tagline => 'Your Voice. Your Land. Your Advisor.';

  @override
  String get press_to_speak => 'Press to Speak';

  @override
  String get listening => 'Listening...';

  @override
  String get processing => 'Processing...';

  @override
  String get speaking => 'Speaking...';

  @override
  String get voice_hint =>
      'Ask me about soil health, fertilizer, weather, or upload a PDF report';

  @override
  String get upload_pdf => 'Upload PDF';

  @override
  String get pdf_analyzing => 'Analyzing document...';

  @override
  String get pdf_analyzed => 'Document analyzed successfully';

  @override
  String get soil_health => 'Soil Health';

  @override
  String get fertilizer_ratio => 'Fertilizer Ratio';

  @override
  String get weather_forecast => 'Weather Forecast';

  @override
  String get crop_advisory => 'Crop Advisory';

  @override
  String get hidden_risks => 'Hidden Risks Detected';

  @override
  String get rainfall_deviation => 'Rainfall Deviation';

  @override
  String get nutrient_drift => 'Nutrient Drift';

  @override
  String get risk_low => 'Low Risk';

  @override
  String get risk_medium => 'Medium Risk';

  @override
  String get risk_high => 'High Risk';

  @override
  String get why_this => 'Why this recommendation?';

  @override
  String get source_citation => 'Source';

  @override
  String get acreage => 'Acreage (acres)';

  @override
  String get crop_type => 'Crop Type';

  @override
  String get calculate_ratio => 'Calculate Fertilizer Ratio';

  @override
  String get nitrogen => 'Nitrogen (N)';

  @override
  String get phosphate => 'Phosphate (P)';

  @override
  String get potassium => 'Potassium (K)';

  @override
  String get kg_per_acre => 'kg/acre';

  @override
  String get district => 'District';

  @override
  String get coimbatore => 'Coimbatore';

  @override
  String get kerala => 'Kerala';

  @override
  String get micro_climate => 'Micro-Climate Data';

  @override
  String get rainfall_10yr => '10-Year Rainfall';

  @override
  String get soil_type => 'Soil Type';

  @override
  String get debug_panel => 'Technical Metrics';

  @override
  String get inference_latency => 'Inference Latency';

  @override
  String get info_density => 'Information Density';

  @override
  String get phonetic_accuracy => 'Phonetic Accuracy';

  @override
  String get pipeline_stage => 'Pipeline Stage';

  @override
  String get good_morning => 'Good Morning';

  @override
  String get good_afternoon => 'Good Afternoon';

  @override
  String get good_evening => 'Good Evening';

  @override
  String hi_user(String name) {
    return 'Hi, $name 👋';
  }

  @override
  String get recent_conversations => 'Recent Conversations';

  @override
  String get no_conversations =>
      'No conversations yet. Press the mic to begin!';

  @override
  String get conversation_history => 'Conversation History';
}
