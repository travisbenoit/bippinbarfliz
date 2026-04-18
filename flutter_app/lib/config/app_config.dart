class AppConfig {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://yfucglycufjwmcuadace.supabase.co',
  );
  static const String stripePublishableKey = String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
    defaultValue: 'YOUR_STRIPE_PUBLISHABLE_KEY',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
      'SUPABASE_ANON_KEY',
      defaultValue:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlmdWNnbHljdWZqd21jdWFkYWNlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzIyNDc0MTcsImV4cCI6MjA4NzgyMzQxN30.1aC4j5kzZwAi9AJDuEoc55glGsYomOF_JVOkddiWroI');

  static const String radarPublishableKey = String.fromEnvironment(
    'RADAR_PUBLISHABLE_KEY',
    defaultValue: 'prj_test_pk_43af23e1975079f349544e8202fd785a50be9525',
  );

  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: 'AIzaSyAS0-83wH0i8jwFy-gAXM3sZmqH_hZCetM',
  );
}
