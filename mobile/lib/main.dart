import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Auth/login.dart';

// =====================
// CONFIG MANUAL
// =====================
class AppConfig {
  // PILIH SALAH SATU URL SESUAI KEBUTUHAN:
  
  // Untuk Android Emulator:
  static const String baseUrl = "http://10.0.2.2:8000/api";
  
  // Untuk Device Fisik (ganti dengan IP komputer Anda):
  // static const String baseUrl = "http://192.168.1.100:8000/api";
  
  // Untuk iOS Simulator:
  // static const String baseUrl = "http://localhost:8000/api";
  
  // Untuk Web/Desktop:
  // static const String baseUrl = "http://127.0.0.1:8000/api";
  
  static const int timeoutSeconds = 15;
  static const bool enableMockFallback = true;
}

// =====================
// MODEL
// =====================
class Task {
  final int? id;
  final String title;
  final String priority;
  final String dueDate;
  final bool isDone;

  Task({
    this.id,
    required this.title,
    required this.priority,
    required this.dueDate,
    this.isDone = false,
  });

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'],
        title: json['title'],
        priority: json['priority'],
        dueDate: json['due_date'],
        isDone: json['is_done'] == true || json['is_done'] == 'true' || json['is_done'] == 1,
      );

  Map<String, dynamic> toJson() => {
        if (id != null) "id": id,
        "title": title,
        "priority": priority,
        "due_date": dueDate,
        "is_done": isDone,
      };

  Task copyWith({
    int? id,
    String? title,
    String? priority,
    String? dueDate,
    bool? isDone,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      isDone: isDone ?? this.isDone,
    );
  }
}

// =====================
// CONNECTION STATUS
// =====================
class ConnectionStatus {
  static bool _isServerAvailable = false;
  static String _connectionError = '';
  
  static bool get isServerAvailable => _isServerAvailable;
  static String get connectionError => _connectionError;
  
  static void setServerStatus(bool available, [String error = '']) {
    _isServerAvailable = available;
    _connectionError = error;
  }
}

// =====================
// USER MODEL
// =====================
class User {
  final int? id;
  final String username;
  final String email;
  final String? name;
  final String? avatar;

  User({
    this.id,
    required this.username,
    required this.email,
    this.name,
    this.avatar,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'],
        username: json['username'] ?? json['user'] ?? '',
        email: json['email'] ?? '',
        name: json['name'] ?? json['full_name'] ?? '',
        avatar: json['avatar'] ?? json['profile_picture'],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "username": username,
        "email": email,
        "name": name,
        "avatar": avatar,
      };

  String get displayName {
    if (name != null && name!.isNotEmpty) {
      return name!;
    }
    return username;
  }
}

// =====================
// AUTH SERVICE
// =====================
class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  static Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      return token != null && token.isNotEmpty;
    } catch (e) {
      print('Error checking login status: $e');
      return false;
    }
  }

  static Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    } catch (e) {
      print('Error getting token: $e');
      return null;
    }
  }

  // Tambahkan method isTokenValid yang hilang
  static Future<bool> isTokenValid() async {
    try {
      final token = await getToken();
      if (token == null || token.isEmpty) {
        return false;
      }
      
      // Untuk saat ini, kita anggap token valid jika ada
      // Nanti bisa ditambahkan validasi dengan server
      return true;
    } catch (e) {
      print('Error validating token: $e');
      return false;
    }
  }

  static Future<bool> saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      return true;
    } catch (e) {
      print('Error saving token: $e');
      return false;
    }
  }

  static Future<bool> saveUserData(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, json.encode(userData));
      print('User data saved: $userData');
      return true;
    } catch (e) {
      print('Error saving user data: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString(_userKey);
      if (userDataString != null && userDataString.isNotEmpty) {
        return json.decode(userDataString) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  static Future<String> getUsername() async {
    try {
      final userData = await getUserData();
      if (userData != null) {
        return userData['username'] ?? 
               userData['name'] ?? 
               userData['user'] ?? 
               userData['email']?.toString().split('@')[0] ?? 
               'User';
      }
      return 'User';
    } catch (e) {
      print('Error getting username: $e');
      return 'User';
    }
  }

  static Future<bool> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_userKey);
      return true;
    } catch (e) {
      print('Error during logout: $e');
      return false;
    }
  }

  static Future<bool> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      return true;
    } catch (e) {
      print('Error clearing all data: $e');
      return false;
    }
  }

  // Method untuk validasi token dengan server (opsional)
  static Future<bool> validateTokenWithServer() async {
    try {
      final token = await getToken();
      if (token == null || token.isEmpty) {
        return false;
      }

      // Test token dengan endpoint yang memerlukan auth
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/user'), // atau endpoint auth lainnya
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      print('Error validating token with server: $e');
      return false; // Jika server tidak tersedia, anggap token valid
    }
  }
}

// =====================
// API SERVICE SEDERHANA
// =====================
class ApiService {
  static const String baseUrl = AppConfig.baseUrl;
  static const String tasksEndpoint = "$baseUrl/tasks";
  
  Future<Map<String, String>> _getHeaders() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<bool> testConnection() async {
    try {
      print('🔍 Testing connection to: $baseUrl');
      
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: await _getHeaders(),
      ).timeout(Duration(seconds: 5));

      if (response.statusCode == 200 || response.statusCode == 404) {
        ConnectionStatus.setServerStatus(true);
        print('✅ Server is reachable');
        return true;
      } else {
        ConnectionStatus.setServerStatus(false, 'Server returned ${response.statusCode}');
        return false;
      }
    } catch (e) {
      ConnectionStatus.setServerStatus(false, e.toString());
      print('❌ Connection failed: $e');
      return false;
    }
  }

  String _getConnectionErrorMessage(dynamic error) {
    if (error is SocketException) {
      return 'Tidak dapat terhubung ke server.\nPastikan:\n1. Server Laravel berjalan\n2. IP address benar ($baseUrl)\n3. Firewall tidak memblokir';
    } else if (error.toString().contains('TimeoutException')) {
      return 'Koneksi timeout. Server mungkin lambat atau tidak tersedia.';
    } else if (error.toString().contains('Connection refused')) {
      return 'Koneksi ditolak.\nPastikan server berjalan di: $baseUrl';
    } else {
      return 'Error: ${error.toString()}';
    }
  }

  Future<List<Task>> getTasks() async {
    try {
      print('🔄 Fetching tasks from: $tasksEndpoint');
      
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(tasksEndpoint),
        headers: headers,
      ).timeout(Duration(seconds: AppConfig.timeoutSeconds));

      print('📡 Response status: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        ConnectionStatus.setServerStatus(true);
        final data = json.decode(response.body);
        
        List<dynamic> tasksJson;
        if (data is List) {
          tasksJson = data;
        } else if (data is Map) {
          // Handle berbagai format response dari backend
          tasksJson = data['data'] ?? data['tasks'] ?? data['result'] ?? [];
        } else {
          tasksJson = [];
        }

        print('✅ Successfully loaded ${tasksJson.length} tasks from server');
        return tasksJson.map((json) => Task.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        await AuthService.logout();
        throw Exception('Session expired. Please login again.');
      } else {
        throw Exception('Failed to load tasks: ${response.statusCode}');
      }
    } catch (e) {
      String errorMsg = _getConnectionErrorMessage(e);
      ConnectionStatus.setServerStatus(false, errorMsg);
      print('❌ Error fetching tasks: $errorMsg');
      
      if (AppConfig.enableMockFallback) {
        print('🔄 Using mock data as fallback');
        return _getMockTasks();
      }
      
      rethrow;
    }
  }

  Future<bool> addTask(Task task) async {
    try {
      print('➕ Adding task: ${task.title}');
      
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse(tasksEndpoint),
        headers: headers,
        body: json.encode(task.toJson()),
      ).timeout(Duration(seconds: AppConfig.timeoutSeconds));

      print('📡 Add task response: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        ConnectionStatus.setServerStatus(true);
        print('✅ Task added successfully');
        return true;
      } else if (response.statusCode == 401) {
        await AuthService.logout();
        throw Exception('Session expired. Please login again.');
      } else {
        throw Exception('Failed to add task: ${response.statusCode}');
      }
    } catch (e) {
      String errorMsg = _getConnectionErrorMessage(e);
      ConnectionStatus.setServerStatus(false, errorMsg);
      print('❌ Error adding task: $errorMsg');
      
      if (AppConfig.enableMockFallback) {
        print('🔄 Adding to mock data');
        return _addMockTask(task);
      }
      
      return false;
    }
  }

  Future<bool> updateTask(Task task) async {
    try {
      if (task.id == null) return false;
      
      print('✏️ Updating task: ${task.id}');
      
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$tasksEndpoint/${task.id}'),
        headers: headers,
        body: json.encode(task.toJson()),
      ).timeout(Duration(seconds: AppConfig.timeoutSeconds));

      print('📡 Update task response: ${response.statusCode}');

      if (response.statusCode == 200) {
        ConnectionStatus.setServerStatus(true);
        print('✅ Task updated successfully');
        return true;
      } else if (response.statusCode == 401) {
        await AuthService.logout();
        throw Exception('Session expired. Please login again.');
      } else {
        throw Exception('Failed to update task: ${response.statusCode}');
      }
    } catch (e) {
      String errorMsg = _getConnectionErrorMessage(e);
      ConnectionStatus.setServerStatus(false, errorMsg);
      print('❌ Error updating task: $errorMsg');
      
      if (AppConfig.enableMockFallback) {
        print('🔄 Updating mock data');
        return _updateMockTask(task);
      }
      
      return false;
    }
  }

  Future<bool> deleteTask(int id) async {
    try {
      print('🗑️ Deleting task: $id');
      
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$tasksEndpoint/$id'),
        headers: headers,
      ).timeout(Duration(seconds: AppConfig.timeoutSeconds));

      print('📡 Delete task response: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        ConnectionStatus.setServerStatus(true);
        print('✅ Task deleted successfully');
        return true;
      } else if (response.statusCode == 401) {
        await AuthService.logout();
        throw Exception('Session expired. Please login again.');
      } else {
        throw Exception('Failed to delete task: ${response.statusCode}');
      }
    } catch (e) {
      String errorMsg = _getConnectionErrorMessage(e);
      ConnectionStatus.setServerStatus(false, errorMsg);
      print('❌ Error deleting task: $errorMsg');
      
      if (AppConfig.enableMockFallback) {
        print('🔄 Deleting from mock data');
        return _deleteMockTask(id);
      }
      
      return false;
    }
  }

  // =====================
  // MOCK DATA FALLBACK
  // =====================
  static List<Task> _mockTasks = [
    Task(
      id: 1,
      title: "Belajar Flutter Development",
      priority: "high",
      dueDate: DateTime.now().add(Duration(days: 1)).toIso8601String(),
      isDone: false,
    ),
    Task(
      id: 2,
      title: "Meeting dengan Tim Project",
      priority: "medium",
      dueDate: DateTime.now().add(Duration(hours: 3)).toIso8601String(),
      isDone: false,
    ),
    Task(
      id: 3,
      title: "Review Code Backend API",
      priority: "low",
      dueDate: DateTime.now().subtract(Duration(days: 1)).toIso8601String(),
      isDone: true,
    ),
  ];

  static int _nextMockId = 4;

  List<Task> _getMockTasks() {
    return List.from(_mockTasks);
  }

  bool _addMockTask(Task task) {
    final newTask = task.copyWith(id: _nextMockId++);
    _mockTasks.add(newTask);
    return true;
  }

  bool _updateMockTask(Task task) {
    if (task.id == null) return false;
    final index = _mockTasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _mockTasks[index] = task;
      return true;
    }
    return false;
  }

  bool _deleteMockTask(int id) {
    final initialLength = _mockTasks.length;
    _mockTasks.removeWhere((task) => task.id == id);
    return _mockTasks.length < initialLength;
  }
}

// =====================
// UI
// =====================
void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Manager Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        cardTheme: CardTheme(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        appBarTheme: AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.indigo.shade600,
          foregroundColor: Colors.white,
        ),
      ),
      home: AuthWrapper(),
    );
  }
}

// =====================
// AUTH WRAPPER
// =====================
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      // Cukup cek apakah user sudah login saja
      final isLoggedIn = await AuthService.isLoggedIn();
      
      if (mounted) {
        setState(() {
          _isLoggedIn = isLoggedIn;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error in _checkAuthStatus: $e');
      if (mounted) {
        setState(() {
          _isLoggedIn = false;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Memuat...', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return _isLoggedIn ? TaskPage() : LoginPage();
  }
}

// =====================
// TASK PAGE
// =====================
class TaskPage extends StatefulWidget {
  const TaskPage({Key? key}) : super(key: key);

  @override
  State<TaskPage> createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> with TickerProviderStateMixin {
  final ApiService api = ApiService();
  late Future<List<Task>> futureTasks;
  late AnimationController _animationController;
  String _filterPriority = 'all';
  bool _showCompleted = true;
  String _userName = '';

  @override
  void initState() {
    super.initState();
    futureTasks = api.getTasks();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _animationController.forward();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final username = await AuthService.getUsername();
    if (mounted) {
      setState(() {
        _userName = username;
      });
    }
  }

  // Widget untuk status koneksi
  Widget _buildConnectionStatus() {
    if (ConnectionStatus.isServerAvailable) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_done, color: Colors.white, size: 14),
            SizedBox(width: 4),
            Text('Online', style: TextStyle(color: Colors.white, fontSize: 11)),
          ],
        ),
      );
    } else {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, color: Colors.white, size: 14),
            SizedBox(width: 4),
            Text('Demo', style: TextStyle(color: Colors.white, fontSize: 11)),
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void refreshTasks() {
    if (mounted) {
      setState(() {
        futureTasks = api.getTasks();
      });
      _animationController.forward(from: 0);
    }
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 8),
            Text("Konfirmasi Logout"),
          ],
        ),
        content: Text("Apakah Anda yakin ingin keluar?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () async {
              await AuthService.logout();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => LoginPage()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text("Logout", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getPriorityIcon(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Icons.priority_high;
      case 'medium':
        return Icons.remove;
      case 'low':
        return Icons.keyboard_arrow_down;
      default:
        return Icons.help;
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd MMM yyyy, HH:mm').format(date);
    } catch (e) {
      return dateString;
    }
  }

  List<Task> _filterTasks(List<Task> tasks) {
    return tasks.where((task) {
      bool priorityMatch = _filterPriority == 'all' || task.priority == _filterPriority;
      bool completedMatch = _showCompleted || !task.isDone;
      return priorityMatch && completedMatch;
    }).toList();
  }

  Future<void> _showTaskDialog({Task? task}) async {
    final _titleController = TextEditingController(text: task?.title ?? '');
    String _priority = task?.priority ?? 'low';
    DateTime? _dueDate = task != null ? DateTime.tryParse(task.dueDate) : null;
    bool _isDone = task?.isDone ?? false;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(task == null ? Icons.add_task : Icons.edit_note, 
                   color: Colors.indigo),
              SizedBox(width: 8),
              Text(task == null ? 'Tambah Tugas' : 'Edit Tugas'),
            ],
          ),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Judul Tugas',
                        prefixIcon: Icon(Icons.title),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _priority,
                      onChanged: (value) => setDialogState(() {
                        _priority = value!;
                      }),
                      decoration: InputDecoration(
                        labelText: 'Prioritas',
                        prefixIcon: Icon(Icons.flag),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: ['low', 'medium', 'high'].map((priority) {
                        return DropdownMenuItem(
                          value: priority,
                          child: Row(
                            children: [
                              Icon(_getPriorityIcon(priority), 
                                   color: _getPriorityColor(priority), size: 20),
                              SizedBox(width: 8),
                              Text(priority.toUpperCase()),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _dueDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(_dueDate ?? DateTime.now()),
                          );
                          if (time != null) {
                            setDialogState(() {
                              _dueDate = DateTime(
                                picked.year,
                                picked.month,
                                picked.day,
                                time.hour,
                                time.minute,
                              );
                            });
                          }
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, color: Colors.indigo),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _dueDate == null
                                    ? 'Pilih tanggal dan waktu'
                                    : _formatDate(_dueDate!.toIso8601String()),
                                style: TextStyle(
                                  color: _dueDate == null ? Colors.grey : Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: CheckboxListTile(
                        title: Text('Tugas Selesai'),
                        subtitle: Text('Tandai jika tugas sudah diselesaikan'),
                        value: _isDone,
                        onChanged: (value) => setDialogState(() {
                          _isDone = value ?? false;
                        }),
                        secondary: Icon(
                          _isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                          color: _isDone ? Colors.green : Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_titleController.text.isNotEmpty && _dueDate != null) {
                  final taskData = Task(
                    id: task?.id,
                    title: _titleController.text,
                    priority: _priority,
                    dueDate: _dueDate!.toIso8601String(),
                    isDone: _isDone,
                  );
                  
                  bool success;
                  if (task == null) {
                    success = await api.addTask(taskData);
                  } else {
                    success = await api.updateTask(taskData);
                  }
                  
                  if (success && mounted) {
                    Navigator.pop(context);
                    refreshTasks();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(task == null ? 'Tugas berhasil ditambahkan' : 'Tugas berhasil diperbarui'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Gagal menyimpan tugas'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Mohon lengkapi semua field'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(task == null ? 'Tambah' : 'Perbarui'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteTask(Task task) async {
    final success = await api.deleteTask(task.id!);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tugas "${task.title}" berhasil dihapus'),
          backgroundColor: Colors.green,
        ),
      );
      refreshTasks();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus tugas'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _confirmDelete(Task task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text("Konfirmasi Hapus"),
          ],
        ),
        content: Text("Apakah Anda yakin ingin menghapus tugas \"${task.title}\"?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteTask(task);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text("Hapus", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleTaskStatus(Task task) async {
    final updatedTask = task.copyWith(isDone: !task.isDone);
    final success = await api.updateTask(updatedTask);
    if (success && mounted) {
      refreshTasks();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(updatedTask.isDone ? 'Tugas ditandai selesai' : 'Tugas ditandai belum selesai'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengubah status tugas'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Row(
          children: [
            Text("Task Manager Pro", style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(width: 8),
            _buildConnectionStatus(), // Gunakan widget inline
          ],
        ),
        actions: [
          // User info
          if (_userName.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(right: 8),
              child: Center(
                child: Text(
                  ConnectionStatus.isServerAvailable 
                    ? 'Halo, $_userName'
                    : 'Demo: $_userName',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          // Filter menu
          PopupMenuButton<String>(
            icon: Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _filterPriority = value;
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'all', child: Text('Semua Prioritas')),
              PopupMenuItem(value: 'high', child: Text('Prioritas Tinggi')),
              PopupMenuItem(value: 'medium', child: Text('Prioritas Sedang')),
              PopupMenuItem(value: 'low', child: Text('Prioritas Rendah')),
            ],
          ),
          // Toggle completed tasks
          IconButton(
            icon: Icon(_showCompleted ? Icons.visibility : Icons.visibility_off),
            onPressed: () {
              setState(() {
                _showCompleted = !_showCompleted;
              });
            },
            tooltip: _showCompleted ? 'Sembunyikan yang selesai' : 'Tampilkan yang selesai',
          ),
          // Logout button
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: Text('Semua'),
                    selected: _filterPriority == 'all',
                    onSelected: (selected) {
                      setState(() {
                        _filterPriority = 'all';
                      });
                    },
                  ),
                  SizedBox(width: 8),
                  FilterChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.priority_high, size: 16, color: Colors.red),
                        SizedBox(width: 4),
                        Text('Tinggi'),
                      ],
                    ),
                    selected: _filterPriority == 'high',
                    onSelected: (selected) {
                      setState(() {
                        _filterPriority = 'high';
                      });
                    },
                  ),
                  SizedBox(width: 8),
                  FilterChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.remove, size: 16, color: Colors.orange),
                        SizedBox(width: 4),
                        Text('Sedang'),
                      ],
                    ),
                    selected: _filterPriority == 'medium',
                    onSelected: (selected) {
                      setState(() {
                        _filterPriority = 'medium';
                      });
                    },
                  ),
                  SizedBox(width: 8),
                  FilterChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.green),
                        SizedBox(width: 4),
                        Text('Rendah'),
                      ],
                    ),
                    selected: _filterPriority == 'low',
                    onSelected: (selected) {
                      setState(() {
                        _filterPriority = 'low';
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          // Task List
          Expanded(
            child: FutureBuilder<List<Task>>(
              future: futureTasks,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Memuat tugas...', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }
                
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red),
                        SizedBox(height: 16),
                        Text("Terjadi kesalahan", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 32),
                          child: Text("${snapshot.error}", 
                                     style: TextStyle(color: Colors.grey),
                                     textAlign: TextAlign.center),
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: refreshTasks,
                          child: Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  );
                }
                
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.task_alt, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text("Tidak ada tugas", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        Text("Tambahkan tugas pertama Anda!", style: TextStyle(color: Colors.grey)),
                        SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _showTaskDialog(),
                          icon: Icon(Icons.add),
                          label: Text('Tambah Tugas'),
                        ),
                      ],
                    ),
                  );
                }

                final allTasks = snapshot.data!;
                final filteredTasks = _filterTasks(allTasks);
                
                if (filteredTasks.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.filter_list_off, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text("Tidak ada tugas yang sesuai filter", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        Text("Coba ubah filter atau tambah tugas baru", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    refreshTasks();
                  },
                  child: ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: filteredTasks.length,
                    itemBuilder: (context, index) {
                      final task = filteredTasks[index];
                      final isOverdue = DateTime.tryParse(task.dueDate)?.isBefore(DateTime.now()) ?? false;
                      
                      return Container(
                        margin: EdgeInsets.only(bottom: 12),
                        child: Card(
                          elevation: task.isDone ? 2 : 4,
                          child: InkWell(
                            onTap: () => _showTaskDialog(task: task),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border(
                                  left: BorderSide(
                                    width: 4,
                                    color: task.isDone 
                                        ? Colors.grey 
                                        : _getPriorityColor(task.priority),
                                  ),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          task.title,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            decoration: task.isDone 
                                                ? TextDecoration.lineThrough 
                                                : null,
                                            color: task.isDone 
                                                ? Colors.grey 
                                                : Colors.black,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _getPriorityColor(task.priority).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              _getPriorityIcon(task.priority),
                                              size: 16,
                                              color: _getPriorityColor(task.priority),
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              task.priority.toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: _getPriorityColor(task.priority),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.schedule,
                                        size: 16,
                                        color: isOverdue && !task.isDone 
                                            ? Colors.red 
                                            : Colors.grey,
                                      ),
                                      SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          _formatDate(task.dueDate),
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: isOverdue && !task.isDone 
                                                ? Colors.red 
                                                : Colors.grey.shade600,
                                            fontWeight: isOverdue && !task.isDone 
                                                ? FontWeight.bold 
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                      if (isOverdue && !task.isDone)
                                        Container(
                                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            'TERLAMBAT',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: task.isDone 
                                              ? Colors.green.withOpacity(0.1) 
                                              : Colors.orange.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              task.isDone 
                                                  ? Icons.check_circle 
                                                  : Icons.pending,
                                              size: 14,
                                              color: task.isDone 
                                                  ? Colors.green 
                                                  : Colors.orange,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              task.isDone ? "Selesai" : "Pending",
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: task.isDone 
                                                    ? Colors.green 
                                                    : Colors.orange,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Spacer(),
                                      IconButton(
                                        icon: Icon(
                                          task.isDone 
                                              ? Icons.check_circle 
                                              : Icons.radio_button_unchecked,
                                          color: task.isDone 
                                              ? Colors.green 
                                              : Colors.grey,
                                        ),
                                        onPressed: () => _toggleTaskStatus(task),
                                        tooltip: task.isDone 
                                            ? 'Tandai belum selesai' 
                                            : 'Tandai selesai',
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.edit, color: Colors.blue),
                                        onPressed: () => _showTaskDialog(task: task),
                                        tooltip: 'Edit tugas',
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _confirmDelete(task),
                                        tooltip: 'Hapus tugas',
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTaskDialog(),
        icon: Icon(Icons.add),
        label: Text('Tambah Tugas'),
        backgroundColor: Colors.indigo,
      ),
    );
  }
}
