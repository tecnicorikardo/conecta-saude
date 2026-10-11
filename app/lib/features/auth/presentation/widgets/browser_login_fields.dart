// Truque de compilação do Dart: "se estiver compilando para WEB, use a
// versão com inputs HTML (browser_login_fields_web.dart); se for para outra
// plataforma (Android, iOS...), use o stub que não desenha nada".
//
// Assim o login_form fica igual para todos — na hora de compilar, cada
// plataforma ganha automaticamente o widget certo:
//   navegador → campos HTML de verdade (Chrome só autocompleta formulário
//               HTML real);
//   celular   → SizedBox vazio, porque lá o autofill nativo já funciona nos
//               campos normais do Flutter.
export 'browser_login_fields_stub.dart'
    if (dart.library.js_interop) 'browser_login_fields_web.dart';
