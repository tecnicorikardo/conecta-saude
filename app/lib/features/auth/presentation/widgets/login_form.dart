import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routes/app_routes.dart';
import '../providers/auth_provider.dart';

class LoginForm extends ConsumerStatefulWidget {
  final bool isLoading;

  const LoginForm({super.key, required this.isLoading});

  @override
  ConsumerState<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<LoginForm> {
  final _formKey    = GlobalKey<FormState>();
  final _emailCtrl  = TextEditingController();
  final _passCtrl   = TextEditingController();
  final _emailFocus = FocusNode();
  final _passFocus  = FocusNode();
  bool _obscure     = true;

  // ─── Cores Institucionais ──────────────────────────────────────────────────
  static const Color _primaryBlue    = Color(0xFF1565C0);
  static const Color _textPrimary    = Color(0xFF263238);
  static const Color _textSecondary  = Color(0xFF607D8B);
  static const Color _borderColor    = Color(0xFFD9E2EC);
  static const Color _inputFillColor = Color(0xFFF8FAFC);
  static const Color _errorColor     = Color(0xFFC62828);

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _emailFocus.dispose();
    _passFocus.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    ref.read(loginNotifierProvider.notifier).signIn(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ─── Título e Subtítulo do Card ──────────────────────────────────
          const Text(
            'Bem-vindo',
            style: TextStyle(
              color: _textPrimary,
              fontSize: 19,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Entre com seu e-mail institucional para continuar.',
            style: TextStyle(
              color: _textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w400,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 18),

          // ─── Campo E-mail Institucional ──────────────────────────────────
          TextFormField(
            controller: _emailCtrl,
            focusNode: _emailFocus,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autocorrect: false,
            enabled: !widget.isLoading,
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            onFieldSubmitted: (_) =>
                FocusScope.of(context).requestFocus(_passFocus),
            decoration: InputDecoration(
              labelText: 'E-mail institucional',
              hintText: 'Digite seu e-mail',
              labelStyle: const TextStyle(
                color: _textSecondary,
                fontSize: 13.5,
              ),
              hintStyle: TextStyle(
                color: _textSecondary.withValues(alpha: 0.6),
                fontSize: 13.5,
              ),
              prefixIcon: const Icon(
                Icons.mail_outline_rounded,
                size: 20,
                color: _textSecondary,
              ),
              filled: true,
              fillColor: _inputFillColor,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: _borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: _borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: _primaryBlue, width: 1.8),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: _errorColor),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: _errorColor, width: 1.8),
              ),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Informe seu e-mail.';
              }
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v.trim())) {
                return 'E-mail inválido.';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),

          // ─── Campo Senha ─────────────────────────────────────────────────
          TextFormField(
            controller: _passCtrl,
            focusNode: _passFocus,
            obscureText: _obscure,
            textInputAction: TextInputAction.done,
            enabled: !widget.isLoading,
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            onFieldSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: 'Senha',
              hintText: 'Digite sua senha',
              labelStyle: const TextStyle(
                color: _textSecondary,
                fontSize: 13.5,
              ),
              hintStyle: TextStyle(
                color: _textSecondary.withValues(alpha: 0.6),
                fontSize: 13.5,
              ),
              prefixIcon: const Icon(
                Icons.lock_outline_rounded,
                size: 20,
                color: _textSecondary,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                  color: _textSecondary,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
                tooltip: _obscure ? 'Mostrar senha' : 'Ocultar senha',
              ),
              filled: true,
              fillColor: _inputFillColor,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: _borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: _borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: _primaryBlue, width: 1.8),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: _errorColor),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: _errorColor, width: 1.8),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Informe sua senha.';
              if (v.length < 6) {
                return 'Mínimo de 6 caracteres.';
              }
              return null;
            },
          ),

          // ─── Link: Esqueci minha senha ───────────────────────────────────
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: widget.isLoading
                  ? null
                  : () => context.push(AppRoutes.forgotPassword),
              style: TextButton.styleFrom(
                foregroundColor: _primaryBlue,
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Esqueci minha senha',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // ─── Botão Principal: ENTRAR ─────────────────────────────────────
          SizedBox(
            height: 46,
            child: ElevatedButton(
              onPressed: widget.isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryBlue,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _primaryBlue.withValues(alpha: 0.65),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: widget.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'ENTRAR',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),

          // ─── Informação Institucional ────────────────────────────────────
          Column(
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 13,
                    color: _textSecondary,
                  ),
                  SizedBox(width: 5),
                  Text(
                    'Ambiente institucional • Acesso restrito',
                    style: TextStyle(
                      color: _textSecondary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Comunicações monitoradas conforme política do SUS.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _textSecondary.withValues(alpha: 0.75),
                  fontSize: 10.5,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

