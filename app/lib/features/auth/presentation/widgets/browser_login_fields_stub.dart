import 'package:flutter/material.dart';
import 'browser_login_controller.dart';

// Versão para CELULAR (Android/iOS): não faz nada de propósito.
//
// No celular o autofill já funciona com os campos normais do Flutter — o
// sistema operacional reconhece os hints de e-mail/senha e sugere as
// credenciais salvas — então não precisamos dos inputs HTML. Esta função
// existe só para a compilação não quebrar: ela "some" da tela.
Widget browserLoginFields({
  required TextEditingController email,
  required TextEditingController password,
  required BrowserLoginController controller,
  required bool enabled,
  required VoidCallback onSubmit,
}) =>
    // SizedBox.shrink() = uma caixinha vazia que não ocupa espaço.
    const SizedBox.shrink();
