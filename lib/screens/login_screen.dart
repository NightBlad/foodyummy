import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/user.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();

  String error = '';
  bool isLoading = false;
  bool isLoginMode = true;

  Future<void> signIn() async {
    setState(() {
      isLoading = true;
      error = '';
    });

    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      // Kiểm tra xem user đã có trong Firestore chưa
      AppUser? existingUser = await _firestoreService.getUser(
        userCredential.user!.uid,
      );
      if (existingUser == null) {
        // Tạo user mới trong Firestore
        existingUser = AppUser(
          id: userCredential.user!.uid,
          email: emailController.text.trim(),
          name: nameController.text.trim().isEmpty
              ? 'User'
              : nameController.text.trim(),
          createdAt: DateTime.now(),
        );
        await _firestoreService.addUser(existingUser);
      }
      // Navigate to menu or home
      Navigator.pushReplacementNamed(context, '/menu');
    } catch (e) {
      setState(() {
        error = 'Đăng nhập thất bại';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> signUp() async {
    setState(() {
      isLoading = true;
      error = '';
    });

    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      // Tạo user trong Firestore
      await _firestoreService.addUser(
        AppUser(
          id: userCredential.user!.uid,
          email: emailController.text.trim(),
          name: nameController.text.trim(),
          createdAt: DateTime.now(),
        ),
      );
    } catch (e) {
      setState(() {
        error = 'Đăng ký thất bại';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFF6B6B), Color(0xFFFFE66D), Color(0xFF4ECDC4)],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Card(
                  color: isDarkMode ? Colors.grey[900] : Colors.white,
                  elevation: 12,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6B6B).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.restaurant_menu,
                            size: 60,
                            color: Color(0xFFFF6B6B),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'FoodyYummy',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Khám phá thế giới ẩm thực',
                          style: TextStyle(
                            fontSize: 16,
                            color:
                            isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 40),

                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => isLoginMode = true),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isLoginMode
                                        ? const Color(0xFFFF6B6B)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  child: Text(
                                    'Đăng nhập',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: isLoginMode
                                          ? Colors.white
                                          : (isDarkMode
                                          ? Colors.grey[300]
                                          : Colors.grey[600]),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => isLoginMode = false),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: !isLoginMode
                                        ? const Color(0xFFFF6B6B)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  child: Text(
                                    'Đăng ký',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: !isLoginMode
                                          ? Colors.white
                                          : (isDarkMode
                                          ? Colors.grey[300]
                                          : Colors.grey[600]),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),

                        if (!isLoginMode) ...[
                          TextField(
                            controller: nameController,
                            style: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Họ và tên',
                              prefixIcon: const Icon(Icons.person,
                                  color: Color(0xFFFF6B6B)),
                              filled: true,
                              fillColor: isDarkMode
                                  ? Colors.grey[800]
                                  : Colors.grey[100],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        TextField(
                          controller: emailController,
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Email',
                            prefixIcon:
                            const Icon(Icons.email, color: Color(0xFFFF6B6B)),
                            filled: true,
                            fillColor:
                            isDarkMode ? Colors.grey[800] : Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        TextField(
                          controller: passwordController,
                          obscureText: true,
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Mật khẩu',
                            prefixIcon:
                            const Icon(Icons.lock, color: Color(0xFFFF6B6B)),
                            filled: true,
                            fillColor:
                            isDarkMode ? Colors.grey[800] : Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed:
                            isLoading ? null : (isLoginMode ? signIn : signUp),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF6B6B),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              elevation: 5,
                            ),
                            child: isLoading
                                ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white),
                              ),
                            )
                                : Text(
                              isLoginMode ? 'Đăng nhập' : 'Đăng ký',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        if (error.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDarkMode ? Colors.red[900] : Colors.red[50],
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isDarkMode
                                    ? Colors.red[300]!
                                    : Colors.red[200]!,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error,
                                    color: Colors.red[600], size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    error,
                                    style: TextStyle(color: Colors.red[600]),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        );
    }

}