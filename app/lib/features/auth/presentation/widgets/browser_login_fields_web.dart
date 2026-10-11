import 'dart:async';
import 'dart:js_interop';
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;
import 'browser_login_controller.dart';

/// ────────────────────────────────────────────────────────────────────────────
/// CAMPOS DE LOGIN "DE VERDADE" PARA O NAVEGADOR (usado só na web)
///
/// O problema que isto resolve: o Flutter desenha a tela num <canvas>, e o
/// Chrome (assim como Edge e Firefox) só oferece preenchimento automático de
/// login/senha em FORMULÁRIOS HTML de verdade, com os atributos certos
/// (autocomplete="username" e autocomplete="current-password"). Nos campos
/// normais do Flutter o navegador preenchia só o e-mail e esquecia a senha.
///
/// A solução: por cima da tela do Flutter, criamos um <form> HTML real com
/// dois <input> reais (e-mail e senha), pintados com a mesma cara do app.
/// A pessoa digita — ou escolhe a conta salva do navegador — nesses inputs,
/// e nós ficamos copiando o valor deles para os TextEditingController do
/// Flutter. A partir daí o login é o mesmo de sempre: mesma validação, mesmo
/// botão, mesma biometria.
///
/// No celular este arquivo NÃO entra na compilação: lá o autofill já funciona
/// nos campos normais do Flutter (ver browser_login_fields_stub.dart).
/// ────────────────────────────────────────────────────────────────────────────

/// Porta de entrada do widget. Recebe os MESMOS controllers que os campos
/// normais usariam (_emailCtrl/_passCtrl do login_form), o "telefone" entre
/// as partes (controller), se os campos estão habilitados e o que fazer
/// quando a pessoa aperta Enter.
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
  // Ponteiros para os inputs HTML criados no _create(). Ficam nulos até o
  // Flutter reservar o espaço na tela e entregar o <div> para a gente.
  web.HTMLInputElement? _email;
  web.HTMLInputElement? _password;
  // <div> vermelha onde escrevemos a mensagem de erro — faz o papel do
  // "validator" dos campos normais do Flutter, só que em cima do HTML.
  web.HTMLElement? _error;
  // Rede de segurança: alguns gerenciadores de senha preenchem o input SEM
  // disparar evento de digitação. Por isso conferimos de 300 em 300 ms se o
  // HTML tem algo que o Flutter ainda não recebeu. Só roda enquanto a tela de
  // login estiver aberta.
  Timer? _autofillTimer;
  // Cadeado contra loop infinito: quando copiamos HTML→Flutter, o Flutter
  // avisa "mudei!", e sem este cadeado a gente copiaria Flutter→HTML de
  // volta, para sempre. Quando a flag está ligada, a cópia de volta é
  // ignorada.
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    // Ligações iniciais:
    // 1) avisa o controller QUAL função sincroniza (ele chama no ENTRAR);
    // 2) escuta os controllers do Flutter — se a biometria escrever e-mail/
    //    senha direto neles, o valor precisa ir parar no input HTML também.
    widget.controller.synchronize = _syncFromBrowser;
    widget.email.addListener(_syncToBrowser);
    widget.password.addListener(_syncToBrowser);
  }

  /// Copia o que está digitado nos inputs HTML para os controllers do Flutter.
  /// Dispara quando a pessoa digita, cola, escolhe a conta salva, aperta
  /// Enter e também pelo timer de 300 ms (gerenciadores que não avisam).
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

  /// Caminho contrário: Flutter → HTML. Serve quando algo fora do teclado
  /// muda o texto no Flutter — hoje é a biometria, que escreve direto no
  /// controller. O cadeado _syncing evita o pingue-pongue com a cópia acima.
  void _syncToBrowser() {
    if (_syncing) return;
    if (_email != null && _email!.value != widget.email.text) {
      _email!.value = widget.email.text;
    }
    if (_password != null && _password!.value != widget.password.text) {
      _password!.value = widget.password.text;
    }
  }

  /// Chamado pela Flutter UMA vez, quando o "buraco" reservado na tela
  /// (HtmlElementView, lá no build) está pronto e o navegador nos entrega o
  /// <div> vazio. Aqui montamos o formulário HTML inteiro: estilos, os dois
  /// campos, botão de mostrar senha e a área de erro.
  void _create(Object element) {
    final root = element as web.HTMLDivElement;
    // CSS puro injetado na página: deixa os inputs HTML com a mesma cara dos
    // campos do app (mesmas cores, altura de 48px, borda que fica azul no
    // foco, botão "Mostrar" no canto direito da senha).
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
    // O <form> de verdade. autocomplete='on' autoriza o navegador a oferecer
    // preenchimento automático; noValidate=true porque quem valida somos nós
    // (mesmas regras do app, lá no validator do build).
    final form = web.HTMLFormElement()
      ..className = 'conecta-login-form'
      ..id = 'conecta-login-credentials'
      ..name = 'conecta-login'
      ..autocomplete = 'on'
      ..noValidate = true;
    root.appendChild(style);
    root.appendChild(form);

    // Fábrica interna de campos: cria label + input com tudo que o navegador
    // precisa para reconhecer um campo de login —
    //   name='username'/'password'  → o Chrome emparelha e-mail e senha pelo
    //                                 name e preenche os dois juntos;
    //   autocomplete='username'/'current-password'
    //                               → diz "isto é um login antigo", para ele
    //                                 sugerir as contas já salvas (e não
    //                                 inventar senha nova).
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

      // Sem capitalizar nem corretor ortográfico — é login, não redação.
      input.setAttribute('autocapitalize', 'none');
      input.setAttribute('spellcheck', 'false');

      // 'input' e 'change': disparam quando a pessoa digita, cola OU o
      // navegador autocompleta. Em todos esses casos, levamos o valor para o
      // Flutter.
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

      // Enter no e-mail → pula para a senha. Enter na senha → loga (o mesmo
      // comportamento do app no celular). preventDefault() segura o envio do
      // formulário pelo navegador, porque quem loga é o Flutter.
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

      // Só o campo de senha ganha o botão Mostrar/Ocultar — o "olhinho" do
      // app, versão HTML. Trocar input.type entre 'password' (bolinhas) e
      // 'text' (letras visíveis) é o jeito clássico de revelar a senha.
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

    // Cria os dois campos. Repare nos atributos: são ELES que fazem o Chrome
    // mostrar "escolher conta salva" e preencher e-mail + senha de uma vez.
    _email = field(
        'conecta-login-username', 'E-mail institucional', 'email', 'username');
    _password = field(
        'conecta-login-password', 'Senha', 'password', 'current-password');

    // Área de erro embaixo dos campos. role='alert' faz leitores de tela
    // anunciarem a mensagem sozinhos (acessibilidade).
    _error = web.HTMLDivElement()..className = 'error';
    _error!.setAttribute('role', 'alert');
    form.appendChild(_error!);

    // Se o navegador tentar enviar o formulário (ex.: Enter), seguramos o
    // envio dele e mandamos o Flutter logar do jeito do app.
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

    // Última rede de segurança: certos gerenciadores de senha (extensões,
    // sobretudo) trocam o valor do input SEM disparar 'input'/'change'. Este
    // timer de 300 ms confere se o HTML tem algo que o Flutter ainda não
    // recebeu. Roda só neste formulário, só enquanto a tela de login existe,
    // e o envio também lê os valores direto do HTML — tripla proteção.
    _autofillTimer = Timer.periodic(
        const Duration(milliseconds: 300), (_) => _syncFromBrowser());
  }

  @override
  void didUpdateWidget(covariant _BrowserLoginFields oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Quando o app começa a logar (isLoading=true), trava os inputs HTML
    // para ninguém editar durante o processamento — igual aos campos do
    // celular, que ficam cinza e bloqueados.
    _email?.disabled = !widget.enabled;
    _password?.disabled = !widget.enabled;
  }

  @override
  Widget build(BuildContext context) => FormField<void>(
        // Mesmas regras da versão mobile: e-mail obrigatório e no formato
        // certo, senha obrigatória com no mínimo 6 caracteres. Antes de
        // validar, sincronizamos HTML→Flutter para não julgar valor velho.
        // O texto vai tanto para a <div> de erro do formulário quanto para o
        // Form do Flutter, que mostra o snackbar de erro normal.
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
        // Reserva um espaço de 180px na tela do Flutter e pede um <div> do
        // navegador dentro dele (HtmlElementView). Quando o <div> fica
        // pronto, o _create monta o formulário lá dentro. Usamos FormField
        // para a validação plugar direto no Form que já existia na tela.
        builder: (_) => SizedBox(
            height: 180,
            child: HtmlElementView.fromTagName(
                tagName: 'div', onElementCreated: _create)),
      );

  @override
  void dispose() {
    // Faxina ao sair da tela de login: para o timer, desliga os ouvintes,
    // avisa o controller que não existe mais quem sincronizar e — importante
    // — apaga o valor da senha do input HTML, para ela não ficar pendurada
    // na página depois do login.
    _autofillTimer?.cancel();
    widget.controller.synchronize = null;
    widget.email.removeListener(_syncToBrowser);
    widget.password.removeListener(_syncToBrowser);
    _password?.value = '';
    super.dispose();
  }
}
