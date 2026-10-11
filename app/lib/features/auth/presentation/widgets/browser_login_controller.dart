/// "Telefone" entre a tela de login do Flutter e os campos HTML do navegador.
///
/// Por que existe: na web a pessoa digita nos <input> HTML (aqueles que o
/// Chrome reconhece e autocomplete). Quando ela toca em ENTRAR, o login_form
/// chama `sync()` ANTES de validar — assim o Flutter recebe na hora o que
/// está nos inputs HTML, sem depender de evento de digitação.
///
/// O widget web registra a função de sincronização em `synchronize`; no
/// celular (stub) ela fica nula e o `?.` simplesmente não faz nada.
class BrowserLoginController {
  /// Função instalada pelo widget web. Fica nula no celular e depois que a
  /// tela de login fecha.
  void Function()? synchronize;

  /// Pede a sincronização imediata HTML→Flutter (se houver quem sincronize).
  void sync() => synchronize?.call();
}
