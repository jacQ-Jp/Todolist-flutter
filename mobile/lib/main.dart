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
  static const String baseUrl = "http://10.0.2.2:8000/api"; // Android Emulator
  // static const String baseUrl = "http://192.168.1.100:8000/api"; // Device Fisik
  // static const String baseUrl = "http://localhost:8000/api"; // iOS Simulator
  // static const String baseUrl = "http://127.0.0.1:8000/api"; // Web/Desktop

  static const int timeoutSeconds = 15;
  static const bool enableMockFallback = true;
}

// =====================
// MODEL
// =====================
class Task {
  final int? id;
  final String title;
  final String? description;
  final String priority;
  final String dueDate;
  final bool isDone;

  Task({
    this.id,
    required this.title,
    this.description,
    required this.priority,
    required this.dueDate,
    this.isDone = false,
  });

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'],
        title: json['title'],
        description: json['description'],
        priority: json['priority'],
        dueDate: json['due_date'],
        isDone: json['is_done'] == true ||
            json['is_done'] == 'true' ||
            json['is_done'] == 1,
      );

  Map<String, dynamic> toJson() => {
        if (id != null) "id": id,
        "title": title,
        if (description != null) "description": description,
        "priority": priority,
        "due_date": dueDate,
        "is_done": isDone,
      };

  Task copyWith({
    int? id,
    String? title,
    String? description,
    String? priority,
    String? dueDate,
    bool? isDone,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
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
    return name?.isNotEmpty == true ? name! : username;
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

  static Future<bool> isTokenValid() async {
    try {
      final token = await getToken();
      return token != null && token.isNotEmpty;
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
      print('User  data saved: $userData');
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
      return userDataString != null && userDataString.isNotEmpty
          ? json.decode(userDataString) as Map<String, dynamic>
          : null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  static Future<String> getUsername() async {
    try {
      final userData = await getUserData();
      return userData != null
          ? userData['username'] ??
              userData['name'] ??
              userData['user'] ??
              userData['email']?.toString().split('@')[0] ??
              'User '
          : 'User ';
    } catch (e) {
      print('Error getting username: $e');
      return 'User ';
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

  static Future<bool> validateTokenWithServer() async {
    try {
      final token = await getToken();
      if (token == null || token.isEmpty) {
        return false;
      }

      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/user'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      print('Error validating token with server: $e');
      return false;
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

      final response = await http
          .get(
            Uri.parse('$baseUrl/health'),
            headers: await _getHeaders(),
          )
          .timeout(Duration(seconds: 5));

      if (response.statusCode == 200 || response.statusCode == 404) {
        ConnectionStatus.setServerStatus(true);
        print('✅ Server is reachable');
        return true;
      } else {
        ConnectionStatus.setServerStatus(
            false, 'Server returned ${response.statusCode}');
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
      final response = await http
          .get(
            Uri.parse(tasksEndpoint),
            headers: headers,
          )
          .timeout(Duration(seconds: AppConfig.timeoutSeconds));

      print('📡 Response status: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        ConnectionStatus.setServerStatus(true);
        final data = json.decode(response.body);

        List<dynamic> tasksJson;
        if (data is List) {
          tasksJson = data;
        } else if (data is Map) {
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
        return await _getMockTasks();
      }

      rethrow;
    }
  }

  Future<bool> addTask(Task task) async {
    try {
      print('➕ Adding task: ${task.title}');

      final headers = await _getHeaders();
      final response = await http
          .post(
            Uri.parse(tasksEndpoint),
            headers: headers,
            body: json.encode(task.toJson()),
          )
          .timeout(Duration(seconds: AppConfig.timeoutSeconds));

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
        return await _addMockTask(task);
      }

      return false;
    }
  }

  Future<bool> updateTask(Task task) async {
    try {
      if (task.id == null) return false;

      print('✏️ Updating task: ${task.id}');

      final headers = await _getHeaders();
      final response = await http
          .put(
            Uri.parse('$tasksEndpoint/${task.id}'),
            headers: headers,
            body: json.encode(task.toJson()),
          )
          .timeout(Duration(seconds: AppConfig.timeoutSeconds));

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
        return await _updateMockTask(task);
      }

      return false;
    }
  }

  Future<bool> deleteTask(int id) async {
    try {
      print('🗑️ Deleting task: $id');

      final headers = await _getHeaders();
      final response = await http
          .delete(
            Uri.parse('$tasksEndpoint/$id'),
            headers: headers,
          )
          .timeout(Duration(seconds: AppConfig.timeoutSeconds));

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
        return await _deleteMockTask(id);
      }

      return false;
    }
  }

  // =====================
  // MOCK DATA FALLBACK
  // =====================
  static Map<String, List<Task>> _mockTasksByUser = {};

  Future<List<Task>> _getMockTasks() async {
    final userData = await AuthService.getUserData();
    final userId = userData?['id']?.toString() ?? 'default';

    if (!_mockTasksByUser.containsKey(userId)) {
      _mockTasksByUser[userId] = []; // Initialize with an empty list
    }
    return List.from(_mockTasksByUser[userId] ?? []);
  }

  Future<bool> _addMockTask(Task task) async {
    final userData = await AuthService.getUserData();
    final userId = userData?['id']?.toString() ?? 'default';

    if (!_mockTasksByUser.containsKey(userId)) {
      _mockTasksByUser[userId] = [];
    }

    final newTask =
        task.copyWith(id: (_mockTasksByUser[userId]?.length ?? 0) + 1);
    _mockTasksByUser[userId]?.add(newTask);
    return true;
  }

  Future<bool> _updateMockTask(Task task) async {
    if (task.id == null) return false;

    final userData = await AuthService.getUserData();
    final userId = userData?['id']?.toString() ?? 'default';

    if (!_mockTasksByUser.containsKey(userId)) return false;

    final index =
        _mockTasksByUser[userId]?.indexWhere((t) => t.id == task.id) ?? -1;
    if (index != -1) {
      _mockTasksByUser[userId]?[index] = task;
      return true;
    }
    return false;
  }

  Future<bool> _deleteMockTask(int id) async {
    final userData = await AuthService.getUserData();
    final userId = userData?['id']?.toString() ?? 'default';

    if (!_mockTasksByUser.containsKey(userId)) return false;

    final initialLength = _mockTasksByUser[userId]?.length ?? 0;
    _mockTasksByUser[userId]?.removeWhere((task) => task.id == id);
    return (_mockTasksByUser[userId]?.length ?? 0) < initialLength;
  }
}

// =====================
// UI
// =====================
void main() {
  runApp(ToDoApp());
}

class ToDoApp extends StatelessWidget {
  const ToDoApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ToDo List',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.pink,
        scaffoldBackgroundColor: Colors.grey[100],
        appBarTheme: AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.pink.shade700,
          foregroundColor: Colors.white,
          titleTextStyle: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 22, letterSpacing: 1.2),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.pink.shade600,
          shape: CircleBorder(),
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

    return _isLoggedIn ? ToDoHomePage() : LoginPage();
  }
}

class ToDoHomePage extends StatefulWidget {
  const ToDoHomePage({Key? key}) : super(key: key);

  @override
  State<ToDoHomePage> createState() => _ToDoHomePageState();
}

class _ToDoHomePageState extends State<ToDoHomePage> {
  final ApiService api = ApiService();
  late Future<List<Task>> futureTasks;
  String _userName = '';

  @override
  void initState() {
    super.initState();
    futureTasks = api.getTasks();
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

  void refreshTasks() {
    if (mounted) {
      setState(() {
        futureTasks = api.getTasks();
      });
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd MMM yyyy, HH:mm').format(date);
    } catch (_) {
      return dateString;
    }
  }

  Future<void> _showTaskDialog({Task? task}) async {
    final TextEditingController titleController =
        TextEditingController(text: task?.title ?? '');
    final TextEditingController descController =
        TextEditingController(text: task?.description ?? '');
    DateTime? dueDate = task != null ? DateTime.tryParse(task.dueDate) : null;

    await showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.2),
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Column(
              children: [
                Icon(task == null ? Icons.add_task : Icons.edit,
                    color: Colors.pink, size: 36),
                const SizedBox(height: 8),
                Text(task == null ? 'Tambah Tugas' : 'Edit Tugas',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.title),
                      labelText: 'Judul Tugas',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.notes),
                      labelText: 'Catatan / Deskripsi',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: dueDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2030),
                      );
                      if (pickedDate != null) {
                        final pickedTime = await showTimePicker(
                          context: context,
                          initialTime:
                              TimeOfDay.fromDateTime(dueDate ?? DateTime.now()),
                        );
                        if (pickedTime != null) {
                          setDialogState(() {
                            dueDate = DateTime(
                              pickedDate.year,
                              pickedDate.month,
                              pickedDate.day,
                              pickedTime.hour,
                              pickedTime.minute,
                            );
                          });
                        }
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Colors.pink),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              dueDate == null
                                  ? 'Pilih tanggal dan waktu'
                                  : _formatDate(dueDate!.toIso8601String()),
                              style: TextStyle(
                                  color: dueDate == null
                                      ? Colors.grey
                                      : Colors.black),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (titleController.text.isNotEmpty && dueDate != null) {
                    final newTask = Task(
                      id: task?.id,
                      title: titleController.text,
                      description: descController.text.isNotEmpty
                          ? descController.text
                          : null,
                      priority: task?.priority ??
                          'low', // tetap isi default agar backend tidak error
                      dueDate: dueDate!.toIso8601String(),
                      isDone: task?.isDone ?? false,
                    );
                    bool success = task == null
                        ? await api.addTask(newTask)
                        : await api.updateTask(newTask);
                    if (success && mounted) {
                      Navigator.pop(context);
                      refreshTasks();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(task == null
                              ? 'Tugas berhasil ditambahkan'
                              : 'Tugas berhasil diperbarui'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Gagal menyimpan tugas'),
                          backgroundColor: Colors.red));
                    }
                  } else if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Mohon lengkapi semua field'),
                        backgroundColor: Colors.orange));
                  }
                },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  backgroundColor: Colors.pink,
                ),
                child: Text(task == null ? 'Tambah' : 'Perbarui'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteTask(Task task) async {
    bool success = await api.deleteTask(task.id!);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Tugas "${task.title}" berhasil dihapus'),
          backgroundColor: Colors.green));
      refreshTasks();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Gagal menghapus tugas'), backgroundColor: Colors.red));
    }
  }

  void _confirmDelete(Task task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text("Konfirmasi Hapus"),
          ],
        ),
        content:
            Text('Apakah Anda yakin ingin menghapus tugas "${task.title}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteTask(task);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("Hapus", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 8),
            Text("Konfirmasi Logout"),
          ],
        ),
        content: const Text("Apakah Anda yakin ingin keluar?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Batal"),
          ),
          ElevatedButton(
            style: ButtonStyle(
              backgroundColor: MaterialStatePropertyAll(Colors.red),
              shape: MaterialStatePropertyAll(
                RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8))),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text("Logout", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await AuthService.logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => LoginPage()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: [
                    Icon(Icons.check_box, color: Colors.pink, size: 32),
                    SizedBox(width: 12),
                    Text('ToDo List',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 22)),
                  ],
                ),
              ),
              Divider(),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.person, color: Colors.grey[700]),
                    SizedBox(width: 8),
                    Text('Halo, $_userName', style: TextStyle(fontSize: 15)),
                  ],
                ),
              ),
              Spacer(),
              ListTile(
                leading: Icon(Icons.logout, color: Colors.red),
                title: Text('Logout'),
                onTap: _logout,
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        title: null,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.pink),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: FutureBuilder<List<Task>>(
          future: futureTasks,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(),
              );
            }
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red),
                    SizedBox(height: 16),
                    Text("Terjadi kesalahan",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text('${snapshot.error}',
                          style: TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                        onPressed: refreshTasks, child: Text('Coba Lagi')),
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
                    Text("Tidak ada tugas",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text("Tambahkan tugas pertama Anda!",
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
              );
            }
            final allTasks = snapshot.data!;
            return SingleChildScrollView(
              child: Wrap(
                spacing: 16,
                runSpacing: 16,
                children: allTasks.map((task) {
                  return Container(
                    width: 260,
                    child: Card(
                      color: Colors.pink.shade50,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.pink.shade200, width: 2),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Checkbox(
                                  value: task.isDone,
                                  activeColor: Colors.pink,
                                  onChanged: (val) async {
                                    final updatedTask =
                                        task.copyWith(isDone: val ?? false);
                                    final success =
                                        await api.updateTask(updatedTask);
                                    if (success && mounted) {
                                      setState(() {
                                        futureTasks = api.getTasks();
                                      });
                                    }
                                  },
                                ),
                                Expanded(
                                  child: Text(
                                    task.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      decoration: task.isDone
                                          ? TextDecoration.lineThrough
                                          : null,
                                      color: task.isDone
                                          ? Colors.grey
                                          : Colors.pink.shade900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 6),
                            Text(
                              task.description ?? '-',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 14, color: Colors.grey[700]),
                            ),
                            SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(Icons.schedule,
                                    size: 16, color: Colors.grey),
                                SizedBox(width: 6),
                                Text(
                                  _formatDate(task.dueDate),
                                  style: TextStyle(
                                      fontSize: 13, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit_note,
                                      color: Colors.pink.shade400, size: 26),
                                  onPressed: () => _showTaskDialog(task: task),
                                  tooltip: 'Edit tugas',
                                  splashRadius: 22,
                                ),
                                SizedBox(width: 8),
                                IconButton(
                                  icon: Icon(Icons.delete_forever,
                                      color: Colors.red.shade300, size: 26),
                                  onPressed: () => _confirmDelete(task),
                                  tooltip: 'Hapus tugas',
                                  splashRadius: 22,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTaskDialog(),
        child: Icon(Icons.add, size: 32),
        backgroundColor: Colors.pink,
      ),
    );
  }
}
