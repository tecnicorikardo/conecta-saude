import 'dart:async';
import 'dart:js_interop';
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;
import 'browser_login_controller.dart';

Widget browserLoginFields({
  required TextEditingController email,
  required TextEditingController password,
  required BrowserLoginController controller,
  required bool enabled,
  required VoidCallback onSubmit,
}) =>
    _BrowserLoginFields(
        email: email,
        password: password,
        controller: controller,
        enabled: enabled,
        onSubmit: onSubmit);

class _BrowserLoginFields extends StatefulWidget {
  final TextEditingController email;
  final TextEditingController password;
  final BrowserLoginController controller;
  final bool enabled;
  final VoidCallback onSubmit;
  const _BrowserLoginFields(
      {required this.email,
      required this.password,
      required this.controller,
      required this.enabled,
      required this.onSubmit});
  @override
  State<_BrowserLoginFields> createState() => _BrowserLoginFieldsState();
}

class _BrowserLoginFieldsState extends State<_BrowserLoginFields> {
  web.HTMLInputElement? _email;
  web.HTMLInputElement? _password;
  web.HTMLElement? _error;
  Timer? _autofillTimer;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    widget.controller.synchronize = _syncFromBrowser;
    widget.email.addListener(_syncToBrowser);
    widget.password.addListener(_syncToBrowser);
  }

  void _syncFromBrowser() {
    if (!mounted || _email == null || _password == null || _syncing) return;
    _syncing = true;
    try {
      if (widget.email.text != _email!.value) widget.email.text = _email!.value;
      if (widget.password.text != _password!.value) {
        widget.password.text = _password!.value;
      }
    } finally {
      _syncing = false;
    }
  }

  void _syncToBrowser() {
    if (_syncing) return;
    if (_email != null && _email!.value != widget.email.text) {
      _email!.value = widget.email.text;
    }
    if (_password != null && _password!.value != widget.password.text) {
      _password!.value = widget.password.text;
    }
  }

  void _create(Object element) {
    final root = element as web.HTMLDivElement;
    final style = web.HTMLStyleElement()
      ..textContent = '''
      .conecta-login-form {font:14px Arial,sans-serif;width:100%;margin:0;color:#263238;}
      .conecta-login-form * {box-sizing:border-box;}
      .conecta-login-form label {display:block;color:#607D8B;font-size:12px;margin:0 0 5px;}
      .conecta-login-form .field {position:relative;margin-bottom:12px;}
      .conecta-login-form input {display:block;width:100%;height:48px;border:1px solid #D9E2EC;border-radius:8px;background:#F8FAFC;color:#263238;font:14px Arial,sans-serif;padding:12px 14px;outline:none;}
      .conecta-login-form input:focus {border:2px solid #1565C0;padding:11px 13px;}
      .conecta-login-form input:disabled {opacity:.65;}
      .conecta-login-form .password {padding-right:76px;}
      .conecta-login-form .password:focus {padding-right:75px;}
      .conecta-login-form button {position:absolute;right:6px;bottom:6px;height:36px;border:0;border-radius:6px;background:transparent;color:#1565C0;cursor:pointer;font-size:12px;}
      .conecta-login-form button:focus-visible {outline:2px solid #1565C0;}
      .conecta-login-form .error {color:#C62828;font-size:12px;line-height:16px;min-height:16px;}
    ''';
    final form = web.HTMLFormElement()
      ..className = 'conecta-login-form'
      ..id = 'conecta-login-credentials'
      ..name = 'conecta-login'
      ..autocomplete = 'on'
      ..noValidate = true;
    root.appendChild(style);
    root.appendChild(form);
    web.HTMLInputElement field(
        String id, String label, String type, String autocomplete) {
      final container = web.HTMLDivElement()..className = 'field';
      final caption = web.HTMLLabelElement()
        ..htmlFor = id
        ..textContent = label;
      final input = web.HTMLInputElement()
        ..id = id
        ..name = type == 'password' ? 'password' : 'username'
        ..type = type
        ..autocomplete = autocomplete
        ..required = true
        ..disabled = !widget.enabled;
      input.setAttribute('autocapitalize', 'none');
      input.setAttribute('spellcheck', 'false');
      input.addEventListener(
          'input',
          ((web.Event _) {
            _syncFromBrowser();
          }).toJS);
      input.addEventListener(
          'change',
          ((web.Event _) {
            _syncFromBrowser();
          }).toJS);
      input.addEventListener(
          'keydown',
          ((web.KeyboardEvent event) {
            if (event.key == 'Enter') {
              event.preventDefault();
              if (type == 'email') {
                _password?.focus();
              } else if (widget.enabled) {
                _syncFromBrowser();
                widget.onSubmit();
              }
            }
          }).toJS);
      container.appendChild(caption);
      container.appendChild(input);
      form.appendChild(container);
      if (type == 'password') {
        input.className = 'password';
        final toggle = web.HTMLButtonElement()
          ..type = 'button'
          ..textContent = 'Mostrar';
        toggle.setAttribute('aria-label', 'Mostrar senha');
        toggle.addEventListener(
            'click',
            ((web.Event _) {
              final visible = input.type == 'password';
              input.type = visible ? 'text' : 'password';
              toggle.textContent = visible ? 'Ocultar' : 'Mostrar';
              toggle.setAttribute(
                  'aria-label', visible ? 'Ocultar senha' : 'Mostrar senha');
            }).toJS);
        container.appendChild(toggle);
      }
      return input;
    }

    _email = field(
        'conecta-login-username', 'E-mail institucional', 'email', 'username');
    _password = field(
        'conecta-login-password', 'Senha', 'password', 'current-password');
    _error = web.HTMLDivElement()..className = 'error';
    _error!.setAttribute('role', 'alert');
    form.appendChild(_error!);
    form.addEventListener(
        'submit',
        ((web.Event event) {
          event.preventDefault();
          if (widget.enabled) {
            _syncFromBrowser();
            widget.onSubmit();
          }
        }).toJS);
    _syncToBrowser();
    // Some password managers change values without dispatching input/change.
    // Poll only this mounted login form; submission also reads the values directly.
    _autofillTimer = Timer.periodic(
        const Duration(milliseconds: 300), (_) => _syncFromBrowser());
  }

  @override
  void didUpdateWidget(covariant _BrowserLoginFields oldWidget) {
    super.didUpdateWidget(oldWidget);
    _email?.disabled = !widget.enabled;
    _password?.disabled = !widget.enabled;
  }

  @override
  Widget build(BuildContext context) => FormField<void>(
        validator: (_) {
          _syncFromBrowser();
          final email = widget.email.text.trim();
          String? error;
          if (email.isEmpty) {
            error = 'Informe seu e-mail.';
          } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email)) {
            error = 'E-mail inválido.';
          } else if (widget.password.text.isEmpty) {
            error = 'Informe sua senha.';
          } else if (widget.password.text.length < 6) {
            error = 'Mínimo de 6 caracteres.';
          }
          _error?.textContent = error ?? '';
          return error;
        },
        builder: (_) => SizedBox(
            height: 180,
            child: HtmlElementView.fromTagName(
                tagName: 'div', onElementCreated: _create)),
      );

  @override
  void dispose() {
    _autofillTimer?.cancel();
    widget.controller.synchronize = null;
    widget.email.removeListener(_syncToBrowser);
    widget.password.removeListener(_syncToBrowser);
    _password?.value = '';
    super.dispose();
  }
}
