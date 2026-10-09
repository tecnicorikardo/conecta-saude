# Guia de leitura para iniciantes

## Caminho de uma criação

1. A página Flutter recolhe os campos digitados. `TextEditingController` lê textos; `trim()` remove espaços nas extremidades.
2. O provider guarda o estado da tela. `ref.read` consulta uma dependência; `ref.watch` acompanha suas mudanças. `copyWith` produz um novo estado preservando os campos não alterados.
3. O repositório envia JSON para a API através do serviço HTTP. `Future` é um resultado futuro e `await` aguarda sua conclusão. `try/catch` trata sucesso e falha.
4. A rota Express escolhe a função correspondente ao endereço. `authenticate` verifica a identidade no Firebase e carrega o cadastro do servidor em `req.user`.
5. `requireHierarquia(SUPERVISAO)` aceita níveis 1, 2 e 3. Quanto menor o número, maior a autoridade. O nível 4 não pode publicar.
6. O controller valida os campos com Zod e grava com Prisma. `req.body` contém o formulário; `req.user` contém o autor autenticado. Nunca confundir essas duas fontes.
7. A resposta HTTP 201 informa que o conteúdo foi criado. O aplicativo atualiza a lista. Notificações são uma etapa separada.

## Por onde começar

- Autenticação no aplicativo: `app/lib/features/auth/data/repositories/auth_repository_impl.dart`, depois `presentation/providers/auth_provider.dart` e `current_user_provider.dart` na mesma funcionalidade.
- Permissões dos botões: `app/lib/core/auth/permissions_provider.dart`.
- Autenticação e autorização no servidor: `backend/src/middleware/authenticate.ts` e `backend/src/modules/auth/auth.routes.ts`.
- Canais: `app/lib/features/channels/` reúne páginas, providers, repositório e entidades. No servidor, ler `backend/src/modules/channels/channels.routes.ts` antes de `channels.controller.ts`.
- Comunicados: `app/lib/features/announcements/` segue a mesma separação. No servidor, rotas e funções estão em `backend/src/modules/announcements/announcements.routes.ts`.
- Testes das rotas reais: `backend/src/__tests__/publication_routes.test.ts`. Os serviços externos são simulados para não escrever em produção.

## Símbolos frequentes

| Símbolo | Significado no contexto |
| --- | --- |
| `?` em um tipo Dart | O valor pode ser nulo. |
| `?.` | Acessa o membro somente se o objeto existir. |
| `??` | Usa o valor alternativo quando o primeiro é nulo (ou undefined em TypeScript). |
| `!` depois de um valor | Afirma que ele não é nulo; não substitui validação. |
| `=>` | Define uma função curta ou uma função de retorno imediato. |
| `...lista` | Insere os elementos de uma lista em outra. |
| `map` | Transforma cada elemento. |
| `where` no Dart | Filtra elementos. |
| `where` no Prisma | Define condições da consulta. |

## Como interpretar erros

- **401:** sessão ausente, inválida ou expirada.
- **403:** identidade conhecida, mas ação negada; verificar conta ativa, hierarquia e setor.
- **422:** permissão passou, mas algum campo do formulário é inválido.
- **500:** falha inesperada no servidor; consultar seus registros.
- **Timeout FCM:** falha para obter token de notificações; não é o token de login Firebase.

O perfil em cache permite abrir o aplicativo com instabilidade de rede. Ele pode mostrar botões incompatíveis com o cadastro atual. A API sempre deve decidir a autorização. Se os testes locais passam e a produção recusa o mesmo nível, confira a versão efetivamente publicada antes de alterar permissões.

Os comentários acrescentados explicam as decisões e os trechos centrais destes três fluxos. Este guia complementa a leitura; não representa documentação linha a linha de todo o projeto.
