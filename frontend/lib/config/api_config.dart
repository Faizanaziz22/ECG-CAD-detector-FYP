class ApiConfig {
  static const String baseUrl = 'http://192.168.100.5:3000/api';
  
  // Authentication endpoints
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String logoutEndpoint = '/auth/logout';
  
  // Patient endpoints
  static const String patientsEndpoint = '/patients';
  static const String patientProfileEndpoint = '/patients/profile';
  
  // Doctor endpoints
  static const String doctorsEndpoint = '/doctors';
  static const String doctorProfileEndpoint = '/doctors/profile';
  
  // ECG endpoints
  static const String ecgEndpoint = '/ecg';
  static const String ecgUploadEndpoint = '/ecg/upload';
  static const String ecgAnalysisEndpoint = '/ecg/analysis';
  
  // Notification endpoints
  static const String notificationsEndpoint = '/notifications';
  
  // Emergency endpoints
  static const String emergencyEndpoint = '/emergency';
  
  // Request timeout
  static const Duration requestTimeout = Duration(seconds: 30);
}