import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/utils/route_names.dart';
import '../../../core/utils/navigation_service.dart';
import '../../../services/auth/auth_provider.dart';
import '../../../services/api/api_client.dart';
import '../../../core/constants/app_constants.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailOrUsernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _urlController = TextEditingController();
  bool _obscurePassword = true;
  double _dragOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _loadCurrentUrl();
    _loadLastUsername();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    // Wait for auth check to complete
    while (authProvider.isLoading) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    
    if (mounted && authProvider.isAuthenticated) {
      NavigationService.navigateToAndRemoveUntil(RouteNames.home);
    }
  }

  Future<void> _loadLastUsername() async {
    final prefs = await SharedPreferences.getInstance();
    final lastUsername = prefs.getString('last_username');
    if (lastUsername != null && mounted) {
      _emailOrUsernameController.text = lastUsername;
    }
  }

  Future<void> _saveLastUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_username', username);
  }

  Future<void> _loadCurrentUrl() async {
    final apiClient = ApiClient();
    final currentUrl = await apiClient.getCurrentBaseUrl();
    _urlController.text = currentUrl;
  }

  @override
  void dispose() {
    _emailOrUsernameController.dispose();
    _passwordController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final identifier = _emailOrUsernameController.text.trim();
    
    // Save username for next time
    await _saveLastUsername(identifier);
    
    final success = await authProvider.login(
      identifier,
      _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      NavigationService.navigateToAndRemoveUntil(RouteNames.home);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? 'Login failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showBackendUrlDialog() async {
    final apiClient = ApiClient();
    final currentUrl = await apiClient.getCurrentBaseUrl();
    _urlController.text = currentUrl;

    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.settings, color: Colors.blue),
            SizedBox(width: 8),
            Text('Backend URL Configuration'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Change the backend server URL for testing:',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _urlController,
                decoration: InputDecoration(
                  labelText: 'Backend URL',
                  hintText: 'http://zotrix.ddns.net:9000',
                  prefixIcon: const Icon(Icons.link),
                  border: const OutlineInputBorder(),
                  helperText: 'Include protocol (http:// or https://) and port',
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  _urlController.text = AppConstants.baseUrl;
                },
                child: const Text('Reset to Default'),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'Demo Mode:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const Text(
                'Bypass login and explore the app with demo data',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  Navigator.pop(context, false);
                  final authProvider = Provider.of<AuthProvider>(context, listen: false);
                  final success = await authProvider.enableDemoMode();
                  
                  if (mounted) {
                    if (success) {
                      NavigationService.navigateToAndRemoveUntil(RouteNames.home);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Demo mode enabled! Exploring app with demo data.'),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(authProvider.error ?? 'Failed to enable demo mode'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text('Enter Demo Mode'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue,
                  side: const BorderSide(color: Colors.blue),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final url = _urlController.text.trim();
              if (url.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('URL cannot be empty'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              // Validate URL format
              if (!url.startsWith('http://') && !url.startsWith('https://')) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('URL must start with http:// or https://'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              try {
                await apiClient.updateBaseUrl(url);
                if (mounted) {
                  Navigator.pop(context, true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Backend URL updated to: $url'),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error updating URL: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragStart: (details) {
        setState(() {
          _dragOffset = 0.0;
        });
      },
      onVerticalDragUpdate: (details) {
        // Only trigger on downward drag (positive delta)
        if (details.delta.dy > 0) {
          setState(() {
            _dragOffset += details.delta.dy;
          });
        }
      },
      onVerticalDragEnd: (details) {
        // If dragged down more than 100 pixels, show the dialog
        if (_dragOffset > 100) {
          _showBackendUrlDialog();
        }
        setState(() {
          _dragOffset = 0.0;
        });
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Login'),
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                  const Text(
                    'Welcome Back!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sign in to continue',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  TextFormField(
                    controller: _emailOrUsernameController,
                    keyboardType: TextInputType.text,
                    decoration: const InputDecoration(
                      labelText: 'Email or Username',
                      hintText: 'Enter your email or username',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email or username';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 8) {
                        return 'Password must be at least 8 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      return ElevatedButton(
                        onPressed: authProvider.isLoading ? null : _handleLogin,
                        child: authProvider.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Login'),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      NavigationService.navigateTo(RouteNames.register);
                    },
                    child: const Text("Don't have an account? Register"),
                  ),
                  const SizedBox(height: 24),
                  // Hidden hint for pull-down gesture
                  Center(
                    child: Text(
                      'Pull down to configure backend URL',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[400],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

