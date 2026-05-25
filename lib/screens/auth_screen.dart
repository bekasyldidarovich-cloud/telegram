import 'package:flutter/material.dart';

import '../state/app_scope.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({this.startupMessage, super.key});

  final String? startupMessage;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();

  bool _isLoading = false;
  String? _verificationId;
  String? _errorText;

  bool get _isCodeStep => _verificationId != null;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);

    return Scaffold(
      backgroundColor: const Color(0xff17212b),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_isCodeStep)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          onPressed: _isLoading ? null : _editNumber,
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                          ),
                        ),
                      )
                    else
                      const SizedBox(height: 44),

                    const SizedBox(height: 12),

                    const _TelegramLogo(),

                    const SizedBox(height: 28),

                    Text(
                      _isCodeStep ? 'Enter code' : 'Your phone number',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      _isCodeStep
                          ? 'We sent an SMS code to ${_phoneController.text.trim()}.'
                          : 'Please confirm your country code and enter your phone number.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xff8eacbb),
                        fontSize: 15,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 34),

                    if (!_isCodeStep) ...[
                      _AuthTextField(
                        controller: _nameController,
                        labelText: 'Name',
                        hintText: 'Bekasyl',
                        icon: Icons.person_outline,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        validator: (value) {
                          final text = (value ?? '').trim();

                          if (text.isNotEmpty && text.length < 2) {
                            return 'Enter your name or leave it empty.';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 14),

                      _AuthTextField(
                        controller: _phoneController,
                        labelText: 'Phone number',
                        hintText: '+77001234567',
                        icon: Icons.phone_iphone_outlined,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.done,
                        autofocus: true,
                        onSubmitted: (_) => _submit(),
                        validator: (value) {
                          final phone = _normalizedPhone(value ?? '');

                          if (!RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(phone)) {
                            return 'Use international format, for example +77001234567.';
                          }

                          return null;
                        },
                      ),
                    ] else ...[
                      _AuthTextField(
                        controller: _codeController,
                        labelText: 'SMS code',
                        hintText: '123456',
                        icon: Icons.password_outlined,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        autofocus: true,
                        maxLength: 6,
                        onSubmitted: (_) => _submit(),
                        validator: (value) {
                          final code = (value ?? '').trim();

                          if (!RegExp(r'^\d{6}$').hasMatch(code)) {
                            return 'Enter the 6-digit code.';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 8),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: _isLoading ? null : _editNumber,
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Edit phone number'),
                        ),
                      ),
                    ],

                    if (_errorText != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xffffeded),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          _errorText!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xffd43c3c),
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    SizedBox(
                      height: 52,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xff2aabee),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _isLoading ? null : _submit,
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Text(
                                _isCodeStep ? 'Continue' : 'Next',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),

                    if (!scope.usesFirebase || widget.startupMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 22),
                        child: Text(
                          !scope.usesFirebase
                              ? 'Local demo mode: use any + phone number and SMS code 123456.'
                              : widget.startupMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xff8eacbb),
                            fontSize: 12,
                            height: 1.35,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_isLoading) return;

    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    if (_isCodeStep) {
      await _confirmCode();
    } else {
      await _sendCode();
    }
  }

  Future<void> _sendCode() async {
    try {
      final auth = AppScope.of(context).authService;

      await auth.startPhoneSignIn(
        phoneNumber: _normalizedPhone(_phoneController.text),
        displayName: _nameController.text.trim(),
        onCodeSent: (verificationId) {
          if (!mounted) return;

          setState(() {
            _verificationId = verificationId;
            _isLoading = false;
            _errorText = null;
          });
        },
        onVerificationCompleted: (_) {
          if (!mounted) return;

          setState(() {
            _isLoading = false;
            _errorText = null;
          });
        },
        onVerificationFailed: (message) {
          if (!mounted) return;

          setState(() {
            _isLoading = false;
            _errorText = message;
          });
        },
      );
    } on Object catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorText = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _confirmCode() async {
    try {
      await AppScope.of(context).authService.confirmPhoneSignIn(
        verificationId: _verificationId!,
        smsCode: _codeController.text.trim(),
        displayName: _nameController.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorText = null;
      });
    } on Object catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorText = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _editNumber() {
    setState(() {
      _verificationId = null;
      _codeController.clear();
      _errorText = null;
      _isLoading = false;
    });
  }

  String _normalizedPhone(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), '');
  }
}

class _AuthTextField extends StatelessWidget {
  const _AuthTextField({
    required this.controller,
    required this.labelText,
    required this.hintText,
    required this.icon,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
    this.onSubmitted,
    this.autofocus = false,
    this.maxLength,
  });

  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      autofocus: autofocus,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      validator: validator,
      onFieldSubmitted: onSubmitted,
      maxLength: maxLength,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        counterText: '',
        labelText: labelText,
        hintText: hintText,
        prefixIcon: Icon(icon),
        labelStyle: const TextStyle(
          color: Color(0xff8eacbb),
          fontWeight: FontWeight.w600,
        ),
        hintStyle: const TextStyle(
          color: Color(0xff587080),
          fontWeight: FontWeight.w500,
        ),
        prefixIconColor: const Color(0xff8eacbb),
        filled: true,
        fillColor: const Color(0xff232e3c),
        errorMaxLines: 2,
        errorStyle: const TextStyle(
          color: Color(0xffff8a8a),
          fontWeight: FontWeight.w600,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xff344457)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xff2aabee), width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xffff8a8a)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xffff8a8a), width: 1.6),
        ),
      ),
    );
  }
}

class _TelegramLogo extends StatelessWidget {
  const _TelegramLogo();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 108,
        height: 108,
        decoration: const BoxDecoration(
          color: Color(0xff2aabee),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0x552aabee),
              blurRadius: 28,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: const Icon(Icons.send_rounded, color: Colors.white, size: 58),
      ),
    );
  }
}
