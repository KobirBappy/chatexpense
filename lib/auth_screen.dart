// import 'package:chatapp/auth_service.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';


// class AuthScreen extends StatefulWidget {
//   const AuthScreen({super.key});

//   @override
//   _AuthScreenState createState() => _AuthScreenState();
// }

// class _AuthScreenState extends State<AuthScreen> {
//   final _formKey = GlobalKey<FormState>();
//   bool _isLogin = true;
//   String _email = '';
//   String _password = '';
//   String _error = '';

//   Future<void> _submit() async {
//     if (_formKey.currentState!.validate()) {
//       _formKey.currentState!.save();
      
//       final auth = context.read<AuthService>();
//       try {
//         if (_isLogin) {
//           await auth.signIn(_email, _password);
//         } else {
//           await auth.register(_email, _password);
//         }
//       } catch (e) {
//         setState(() => _error = 'Authentication failed: ${e.toString()}');
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Padding(
//         padding: const EdgeInsets.all(20.0),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               const Icon(Icons.account_balance_wallet, size: 80, color: Colors.teal),
//               const SizedBox(height: 20),
//               Text(
//                 _isLogin ? 'Welcome Back' : 'Create Account',
//                // style: Theme.of(context).textTheme.headline5,
//               ),
//               const SizedBox(height: 20),
//               TextFormField(
//                 decoration: const InputDecoration(
//                   labelText: 'Email',
//                   prefixIcon: Icon(Icons.email),
//                 ),
//                 keyboardType: TextInputType.emailAddress,
//                 validator: (value) => 
//                   value!.isEmpty ? 'Enter your email' : null,
//                 onSaved: (value) => _email = value!,
//               ),
//               const SizedBox(height: 10),
//               TextFormField(
//                 decoration: const InputDecoration(
//                   labelText: 'Password',
//                   prefixIcon: Icon(Icons.lock),
//                 ),
//                 obscureText: true,
//                 validator: (value) => 
//                   value!.isEmpty ? 'Enter a password' : null,
//                 onSaved: (value) => _password = value!,
//               ),
//               const SizedBox(height: 20),
//               if (_error.isNotEmpty)
//                 Text(_error, style: const TextStyle(color: Colors.red)),
//               const SizedBox(height: 20),
//               ElevatedButton(
//                 onPressed: _submit,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.teal,
//                   minimumSize: const Size(double.infinity, 50),
//                 ),
//                 child: Text(_isLogin ? 'Login' : 'Register'),
//               ),
//               TextButton(
//                 onPressed: () => setState(() => _isLogin = !_isLogin),
//                 child: Text(_isLogin 
//                   ? 'Create new account' 
//                   : 'I already have an account'),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }



import 'package:chatapp/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLogin = true;
  bool _isLoading = false;
  String _email = '';
  String _password = '';
  String _confirmPassword = '';
  String _error = '';

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Check password confirmation for registration
    if (!_isLogin && _password != _confirmPassword) {
      setState(() => _error = 'Passwords do not match');
      return;
    }
    
    _formKey.currentState!.save();
    setState(() {
      _isLoading = true;
      _error = '';
    });
    
    try {
      final auth = context.read<AuthService>();
      if (_isLogin) {
        await auth.signIn(_email.trim(), _password);
      } else {
        await auth.register(_email.trim(), _password);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = _getErrorMessage(e.toString());
      });
    }
  }

  String _getErrorMessage(String error) {
    if (error.contains('user-not-found')) {
      return 'No user found with this email address.';
    } else if (error.contains('wrong-password')) {
      return 'Incorrect password. Please try again.';
    } else if (error.contains('email-already-in-use')) {
      return 'An account already exists with this email address.';
    } else if (error.contains('weak-password')) {
      return 'Password is too weak. Please choose a stronger password.';
    } else if (error.contains('invalid-email')) {
      return 'Please enter a valid email address.';
    } else if (error.contains('network-request-failed')) {
      return 'Network error. Please check your internet connection.';
    } else {
      return 'Authentication failed. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.teal.shade300,
              Colors.teal.shade600,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Logo and Title
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet, 
                      size: 60, 
                      color: Colors.teal
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  Text(
                    'ChatExpense',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.3),
                          offset: const Offset(2, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  
                  Text(
                    _isLogin ? 'Welcome Back!' : 'Create Your Account',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // Auth Form Card
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email),
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                            onSaved: (value) => _email = value!,
                          ),
                          const SizedBox(height: 15),
                          
                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Password',
                              prefixIcon: Icon(Icons.lock),
                              border: OutlineInputBorder(),
                            ),
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a password';
                              }
                              if (!_isLogin && value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                            onSaved: (value) => _password = value!,
                            onChanged: (value) => _password = value,
                          ),
                          
                          // Confirm Password field for registration
                          if (!_isLogin) ...[
                            const SizedBox(height: 15),
                            TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Confirm Password',
                                prefixIcon: Icon(Icons.lock_outline),
                                border: OutlineInputBorder(),
                              ),
                              obscureText: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please confirm your password';
                                }
                                return null;
                              },
                              onChanged: (value) => _confirmPassword = value,
                            ),
                          ],
                          
                          const SizedBox(height: 20),
                          
                          // Error Message
                          if (_error.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline, color: Colors.red.shade600, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _error,
                                      style: TextStyle(color: Colors.red.shade600),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          
                          if (_error.isNotEmpty) const SizedBox(height: 20),
                          
                          // Submit Button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 3,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      _isLogin ? 'Sign In' : 'Create Account',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                          
                          const SizedBox(height: 15),
                          
                          // Switch between login and register
                          TextButton(
                            onPressed: _isLoading ? null : () {
                              setState(() {
                                _isLogin = !_isLogin;
                                _error = '';
                                _formKey.currentState?.reset();
                              });
                            },
                            child: Text(
                              _isLogin 
                                ? 'Don\'t have an account? Create one' 
                                : 'Already have an account? Sign in',
                              style: TextStyle(
                                color: Colors.teal.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // App Features
                  Text(
                    'AI-Powered Financial Management',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildFeatureItem(Icons.receipt_long, 'Track Expenses'),
                      _buildFeatureItem(Icons.analytics, 'Get Reports'),
                      _buildFeatureItem(Icons.chat, 'AI Assistant'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}