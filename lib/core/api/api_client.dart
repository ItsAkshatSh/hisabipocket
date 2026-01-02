
// core/api/api_client.dart (Simulated)
class ApiClient {
  Future<Map<String, dynamic>> get(String path) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    // Simulate successful or failed response based on path/state
    if (path == '/api/user') {
      // Return authenticated user data
      return {'id': 1, 'email': 'test@gmail.com', 'name': 'John Doe', 'pictureUrl': null}; 
    }
    // ... other mocked responses
    throw Exception('Simulated API Error');
  }

  Future<Map<String, dynamic>> post(String path, dynamic data) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (path == '/api/login') {
      // Simulate successful login/session creation
      return {'status': 'success', 'user': {'id': 1, 'email': 'test@gmail.com', 'name': 'John Doe', 'pictureUrl': null}};
    }
    if (path == '/api/save_receipt') {
      return {'status': 'success', 'id': 'rcpt_123'};
    }
    // ...
    throw Exception('Simulated API Post Error');
  }
  
  // Future<Map<String, dynamic>> uploadMultipart(String path, String field, File file) async {...}
}