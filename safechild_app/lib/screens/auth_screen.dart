import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../services/localization_service.dart';
import '../models/user.dart';
import 'main_navigation_screen.dart';
import 'forgot_password_screen.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  return AuthNotifier(ref.watch(apiServiceProvider));
});

class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  final ApiService _apiService;
  AuthNotifier(this._apiService) : super(const AsyncValue.data(null)) {
    checkAuth();
  }

  Future<void> checkAuth() async {
    if (await _apiService.hasToken()) {
      try {
        final response = await _apiService.get('/me');
        state = AsyncValue.data(User.fromJson(response.data));
      } catch (e) {
        await _apiService.deleteToken();
        state = const AsyncValue.data(null);
      }
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final response = await _apiService.post('/login', data: {
        'email': email,
        'password': password,
      });
      final user = User.fromJson(response.data['user']);
      await _apiService.saveToken(response.data['access_token']);
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> register(String name, String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final response = await _apiService.post('/register', data: {
        'name': name,
        'email': email,
        'password': password,
        'role': 'parent',
      });
      final user = User.fromJson(response.data['user']);
      await _apiService.saveToken(response.data['access_token']);
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> logout() async {
    try {
      await _apiService.post('/logout');
    } catch (e) {
      // Ignore if already expired on server
    } finally {
      await _apiService.deleteToken();
      state = const AsyncValue.data(null);
    }
  }
}

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLogin = true;
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final tr = AppTranslations.of(context);

    ref.listen(authProvider, (previous, next) {
      next.whenOrNull(
        data: (user) {
          if (user != null) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
            );
          }
        },
        error: (e, _) {
          String errorMessage = e.toString();
          if (e is DioException) {
            if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
              errorMessage = tr.translate('connection_error_api');
            } else if (e.response?.data != null && e.response?.data['message'] != null) {
              errorMessage = e.response?.data['message'];
              if (e.response?.data['errors'] != null) {
                final errors = e.response?.data['errors'] as Map<String, dynamic>;
                errorMessage = errors.values.first[0];
              }
            }
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${tr.translate('error')}: $errorMessage'),
              backgroundColor: Colors.redAccent,
            ),
          );
        },
      );
    });

    return Scaffold(
      body: Stack(
        children: [
          Container(color: Colors.blue[900]),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.blue[800]!.withValues(alpha: 0.8),
                  Colors.black.withValues(alpha: 0.9),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 30.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/app_icon.png',
                      height: 100,
                      width: 100,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'Safechild',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    Text(tr.translate('welcome_back'), style: const TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 40),
                    Container(
                      padding: const EdgeInsets.all(25),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 15, spreadRadius: 5)],
                      ),
                      child: Column(
                        children: [
                          Text(
                            _isLogin ? tr.translate('login') : tr.translate('register'),
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue[900]),
                          ),
                          const SizedBox(height: 20),
                          if (!_isLogin)
                            _buildTextField(
                              controller: _nameController, 
                              label: tr.translate('name'), 
                              icon: Icons.person_outline
                            ),
                          _buildTextField(
                            controller: _emailController,
                            label: tr.translate('email'),
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          _buildTextField(
                            controller: _passwordController, 
                            label: tr.translate('password'), 
                            icon: Icons.lock_outline, 
                            obscureText: _obscurePassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                color: Colors.blue[900],
                                size: 20,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          
                          if (_isLogin)
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                                  );
                                },
                                child: Text(tr.translate('forgot_password_title'), style: const TextStyle(fontSize: 12)),
                              ),
                            ),

                          const SizedBox(height: 10),
                          if (authState.isLoading)
                            const CircularProgressIndicator()
                          else
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue[900],
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 15),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  elevation: 5,
                                ),
                                child: Text(_isLogin ? tr.translate('login') : tr.translate('register'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          const SizedBox(height: 15),
                          TextButton(
                            onPressed: () => setState(() => _isLogin = !_isLogin),
                            child: Text(
                              _isLogin ? tr.translate('no_account') : tr.translate('have_account'),
                              style: TextStyle(color: Colors.blue[900]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller, 
    required String label, 
    required IconData icon, 
    bool obscureText = false, 
    TextInputType? keyboardType,
    Widget? suffixIcon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.black87),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
          prefixIcon: Icon(icon, size: 20, color: Colors.blue[900]),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }

  void _submit() {
    final tr = AppTranslations.of(context);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr.translate('fill_fields'))),
      );
      return;
    }

    if (_isLogin) {
      debugPrint('Attempting login with: $email');
      ref.read(authProvider.notifier).login(email, password);
    } else {
      final name = _nameController.text.trim();
      if (name.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr.translate('enter_name'))),
        );
        return;
      }
      ref.read(authProvider.notifier).register(name, email, password);
    }
  }
}