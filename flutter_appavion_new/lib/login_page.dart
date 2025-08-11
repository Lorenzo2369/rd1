import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'Home.dart';  // IMPORTAR HOME

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController correoController = TextEditingController();
  final TextEditingController contrasenaController = TextEditingController();

  bool _isLoading = false;
  String _errorMessage = '';

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      try {
        final correo = correoController.text.trim();
        final contrasena = contrasenaController.text.trim();
        final hashedContrasena = _hashPassword(contrasena);

        final res = await DatabaseHelper.instance.queryUserByEmail(correo);

        if (res.isEmpty) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Correo no registrado.';
          });
          return;
        }

        final storedHash = res.first['password'] as String;  // Cambié 'contraseña' a 'password'

        if (storedHash == hashedContrasena) {
          setState(() {
            _isLoading = false;
          });
          // Navegar a HomePage
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Contraseña incorrecta.';
          });
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error al iniciar sesión: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo.shade50,
      appBar: AppBar(
        title: const Text("Iniciar sesión"),
        backgroundColor: Colors.indigo,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
          child: Card(
            elevation: 10,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Bienvenido",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo.shade900,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: correoController,
                      decoration: InputDecoration(
                        labelText: "Correo electrónico",
                        prefixIcon:
                            const Icon(Icons.email_outlined, color: Colors.indigo),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty ||
                            !value.contains('@')) {
                          return 'Ingresa un correo válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: contrasenaController,
                      decoration: InputDecoration(
                        labelText: "Contraseña",
                        prefixIcon:
                            const Icon(Icons.lock_outline, color: Colors.indigo),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.length < 6) {
                          return 'La contraseña debe tener al menos 6 caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),
                    _isLoading
                        ? const CircularProgressIndicator()
                        : SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                padding: const EdgeInsets.all(0),
                              ),
                              onPressed: _submit,
                              child: Ink(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Colors.indigo, Colors.blueAccent],
                                  ),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Container(
                                  alignment: Alignment.center,
                                  child: const Text(
                                    "Iniciar sesión",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                    if (_errorMessage.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(
                        _errorMessage,
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
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
    );
  }
}
