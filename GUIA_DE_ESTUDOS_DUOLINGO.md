# 🎓 Guia Definitivo de Estudos: Arquitetura & Código do Conecta Saúde
### *Trilha de Perguntas e Respostas Diárias (Estilo Duolingo: Do Iniciante ao Sênior)*

Este material foi preparado para você dominar **100% da arquitetura técnica, das decisões de engenharia e do código** do Conecta Saúde.
Ao seguir este cronograma diário de 10 perguntas por dia, você saberá explicar e defender qualquer parte do sistema diante de qualquer programador ou diretor técnico!

---

```
    ┌──────────────────────────────────────────────────────────────┐
    │              MAPA DA TRILHA DE CONHECIMENTO                  │
    ├──────────────────────────────────────────────────────────────┤
    │  Dia 1 ➔ Fundamentos & Arquitetura Geral (Flutter & Clean)   │
    │  Dia 2 ➔ Gerenciamento de Estado Reativo (Riverpod)          │
    │  Dia 3 ➔ Backend, Banco de Dados & Supabase Realtime         │
    │  Dia 4 ➔ Segurança, Auth, Permissões & Biometria             │
    │  Dia 5 ➔ Motor de Chat, Moderação & Filtro de Linguagem      │
    │  Dia 6 ➔ Design System, Temas (4 Cores) & Acessibilidade     │
    │  Dia 7 ➔ CI/CD, Build APK/Web, Firebase & Produção           │
    └──────────────────────────────────────────────────────────────┘
```

---

## 📅 DIA 1: Fundamentos & Arquitetura Geral do Projeto

### 🟢 1. Qual é o padrão de arquitetura adotado no Conecta Saúde e por que ele foi escolhido?
> **Resposta para o programador:**
> O Conecta Saúde adota os princípios de **Clean Architecture (Arquitetura Limpa)** combinada com **Feature-First** (organização por funcionalidade).
> 
> A estrutura é dividida em 3 camadas concêntricas:
> 1. **Data Layer (`data/`)**: Responsável por fontes de dados externas (Supabase, Firebase, SharedPreferences), models que serializam JSON (`UserModel`, `MessageModel`) e implementação concreta de repositórios.
> 2. **Domain Layer (`domain/`)**: O coração das regras de negócio puras, composto por Entidades imutáveis (`UserEntity`, `MessageEntity`) e contratos abstratos de repositórios.
> 3. **Presentation Layer (`presentation/`)**: Componentes visuais (Pages, Widgets) e orquestradores de estado com Riverpod (Providers, Notifiers).
>
> **Por que foi escolhido?** Porque permite desacoplar a interface das regras de negócio. Se amanhã trocarmos o backend por outra API, a camada de domínio e a camada visual quase não sofrem impacto.

---

### 🟢 2. O que é a pasta `lib/core` e o que fica guardado nela?
> **Resposta:**
> A pasta `core/` contém os utilitários, configurações globais e serviços compartilhados que não pertencem a uma única funcionalidade, incluindo:
> - `core/routes/`: Configuração do `GoRouter`, guards de autenticação e mapa de rotas (`app_routes.dart`).
> - `core/theme/`: O Design System (`app_colors.dart`, `app_theme_tokens.dart`, `app_theme_provider.dart`).
> - `core/services/`: Serviços globais como o `LanguageFilterService` (filtro de palavras), biometria (`local_auth`) e notificações web.
> - `core/auth/`: Lógica central de permissões (`permissions_provider.dart`).

---

### 🟢 3. Qual é a diferença entre um `Model` e uma `Entity` no nosso código?
> **Resposta:**
> - **Entity (Ex: `MessageEntity`)**: Representa o objeto puro de negócio na camada de domínio. É imutável, possui apenas propriedades e validações essenciais, sem métodos de banco ou JSON.
> - **Model (Ex: `MessageModel`)**: Fica na camada de dados. Herda da Entity e implementa métodos como `fromJson()`, `toJson()`, `fromSupabase()` e mapeamento para persistência.

---

### 🟢 4. Por que o projeto utiliza a estrutura `Feature-First` em vez de `Layer-First`?
> **Resposta:**
> Em *Layer-First*, teríamos pastas como `screens/`, `controllers/`, `models/` contendo arquivos de todas as telas misturados. Conforme o app cresce, fica inviável manter.
> Em *Feature-First*, agrupamos por funcionalidade (`features/chat/`, `features/emergency/`, `features/reports/`, etc.). Cada funcionalidade tem seu próprio mini ecossistema com `data`, `domain` e `presentation`, facilitando a navegação, testes isolados e manutenção.

---

### 🟢 5. O que é o arquivo `main.dart` e o que é inicializado antes do `runApp`?
> **Resposta:**
> O `main.dart` é o ponto de entrada da aplicação Flutter. Antes de chamar `runApp(ProviderScope(...))`, executamos:
> 1. `WidgetsFlutterBinding.ensureInitialized()`: Garante que o motor do Flutter esteja pronto para canais nativos.
> 2. `Firebase.initializeApp()`: Inicializa o Firebase para Push Notifications e Analytics.
> 3. `Supabase.initialize(...)`: Inicializa a conexão com o Supabase Realtime e Postgres.
> 4. Envolvemos a árvore com `ProviderScope` para habilitar a injeção de dependência reativa do **Riverpod**.

---

### 🟢 6. Como o `GoRouter` gerencia as rotas e redirecionamentos no app?
> **Resposta:**
> O arquivo `app_router.dart` configura o `GoRouter` usando `redirect: (context, state)`.
> - Se o usuário não está autenticado (`currentUser == null`) e tenta acessar `/home`, `/chat` ou `/reports`, ele é redirecionado automaticamente para `/login`.
> - Se o usuário já está autenticado e tenta acessar `/login`, é redirecionado para `/home`.
> - Rotas com parâmetros dinâmicos (como `/chat/:id`) recebem o ID da conversa pela URL ou parâmetros extras pelo objeto `state.extra`.

---

### 🟢 7. O que é o `MainShell` (`main_shell.dart`) no aplicativo?
> **Resposta:**
> É o container de navegação principal (ShellRoute) que renderiza a barra de navegação inferior (BottomNavigationBar) ou lateral permanente, mantendo o estado das abas principais (Início, Mensagens, Canais, Comunicados, Perfil) vivas e navegáveis sem recarregar a tela inteira.

---

### 🟢 8. Qual a função do `pubspec.yaml` e quais são as principais dependências do projeto?
> **Resposta:**
> O `pubspec.yaml` é o manifesto do projeto Flutter. Nossas principais dependências são:
> - `flutter_riverpod`: Gerenciamento de estado reativo e injeção de dependências.
> - `supabase_flutter`: Banco de dados Postgres e WebSockets em tempo real.
> - `go_router`: Roteamento declarativo com suporte a Deep Links e Web.
> - `local_auth`: Autenticação biométrica nativa (Android/iOS).
> - `firebase_core` & `firebase_messaging`: Infraestrutura de nuvem e notificações.
> - `flutter_secure_storage`: Armazenamento criptografado de credenciais.

---

### 🟢 9. Como o Conecta Saúde suporta tanto Web quanto Mobile (Android/iOS) no mesmo código?
> **Resposta:**
> O Flutter compila o código Dart para nativo (ARM/C++ no Android/iOS) e para JavaScript/Wasm na Web.
> No código, usamos verificações como `kIsWeb` do pacote `foundation.dart` para desabilitar ou adaptar recursos específicos (por exemplo, biometria nativa vs chave de sessão web, e tratamento de URL hash com `url_strategy_web.dart`).

---

### 🟢 10. O que é o `HierarchyBadge` e por que ele aparece em quase todas as telas?
> **Resposta:**
> É um widget reutilizável em `core/widgets/hierarchy_badge.dart` que exibe a insígnia oficial do nível de autoridade do colaborador no hospital (Direção Geral, Coordenação, Supervisão, Colaborador), aplicando as cores e ícones padronizados para rápida identificação de autoridade na equipe médica.

---

## 📅 DIA 2: Gerenciamento de Estado Reativo (Riverpod)

### 🟡 11. Por que usamos Riverpod em vez de `setState` puro ou `Provider` clássico?
> **Resposta:**
> O Riverpod resolve os principais problemas do Provider tradicional:
> - É **compile-safe**: Erros de injeção são pegos em tempo de compilação, sem lançar `ProviderNotFoundException` em tempo de execução.
> - Não depende do `BuildContext` para ler estados fora da árvore de widgets (em repositórios ou listeners).
> - Suporta fácil combinação de estados (`ref.watch`) e invalidação sob demanda (`ref.invalidate`).

---

### 🟡 12. Qual a diferença entre `ConsumerWidget`, `ConsumerStatefulWidget` e `StatelessWidget`?
> **Resposta:**
> - `StatelessWidget`: Widget imutável comum que não tem acesso direto aos Providers do Riverpod.
> - `ConsumerWidget`: Substituto do StatelessWidget que recebe um parâmetro `WidgetRef ref` no método `build()`, permitindo escutar estados (`ref.watch(provider)`).
> - `ConsumerStatefulWidget`: Substituto do StatefulWidget onde a classe State herda de `ConsumerState<T>`, dando acesso à propriedade `ref` em qualquer método do ciclo de vida (`initState`, `build`, `dispose`).

---

### 🟡 13. Qual é a diferença entre `ref.watch()`, `ref.read()` e `ref.listen()`?
> **Resposta:**
> - `ref.watch(provider)`: Escuta o provider e **reconstrói** o widget sempre que o valor mudar. Ideal para o método `build()`.
> - `ref.read(provider)`: Obtém o valor atual uma única vez **sem escutar** mudanças futuras. Ideal dentro de callbacks de clique (`onPressed`).
> - `ref.listen(provider, (prev, next) { ... })`: Executa uma função colateral (ex: abrir um SnackBar, navegar de tela ou tocar um som) quando o estado mudar, sem forçar reconstrução da tela.

---

### 🟡 14. Como funciona o `AsyncValue` (`AsyncLoading`, `AsyncData`, `AsyncError`) no Riverpod?
> **Resposta:**
> Quando usamos um `FutureProvider` ou `StreamProvider`, o Riverpod encapsula o resultado em um `AsyncValue`. Na UI, usamos o método `.when()`:
> ```dart
> conversationsAsync.when(
>   loading: () => CircularProgressIndicator(),
>   error: (err, stack) => Text('Erro: $err'),
>   data: (conversations) => ListView.builder(...),
> );
> ```
> Isso elimina a necessidade de controlar variáveis booleanas manuais de `isLoading`.

---

### 🟡 15. O que faz o comando `ref.invalidate(meuProvider)`?
> **Resposta:**
> Ele descarta o estado atual em cache do provider e força uma nova execução imediata do seu método de busca. Nós usamos isso, por exemplo, após enviar uma denúncia na Ouvidoria para recarregar a lista `allReportsProvider`.

---

### 🟡 16. O que são Family Providers (ex: `chatMessagesProvider(conversationId)`)?
> **Resposta:**
> São providers parametrizados. Permitem passar um argumento (como o `conversationId`) para instanciar e gerenciar um estado exclusivo para aquela conversa específica, evitando que mensagens de chats diferentes se misturem.

---

### 🟡 17. O que é o `AutoDispose` no Riverpod e quando o usamos?
> **Resposta:**
> O modificador `.autoDispose` faz com que o Riverpod destrua o estado e cancele streams/assinaturas quando nenhum widget estiver mais assistindo àquele provider. Usamos isso na tela de chat para encerrar a escuta de WebSockets quando o usuário sai da conversa, economizando memória e bateria.

---

### 🟡 18. Como o `currentUserProvider` mantém o usuário logado?
> **Resposta:**
> Ele observa a sessão do Supabase Auth e carrega os dados completos da tabela `usuarios` do Postgres. Ele expõe a instância `UserModel` para todo o aplicativo através de um `StateNotifier` ou `StreamProvider`.

---

### 🟡 19. O que é o `serviceStatusProvider`?
> **Resposta:**
> É um provider que monitora o status de serviço de cada profissional (Plantão Ativo, Intervalo, Em Atendimento, Desconectado). Ele atualiza o status no banco e reflete o indicador verde/amarelo nos avatares em tempo real.

---

### 🟡 20. Como evitar reconstruções desnecessárias da UI com Riverpod?
> **Resposta:**
> 1. Usar `ref.watch(meuProvider.select((user) => user.nome))` para rebuildar apenas quando o nome mudar, e não a foto ou cargo.
> 2. Quebrar a árvore em pequenos `ConsumerWidget` dedicados em vez de ter um build gigante na página principal.

---

## 📅 DIA 3: Backend, Banco de Dados & Supabase Realtime

### 🟠 21. Quais são as principais tabelas do banco de dados no Postgres/Supabase?
> **Resposta:**
> - `usuarios`: ID, email, nome, cargo, setor, nível hierárquico, foto, status de serviço e chave biométrica.
> - `conversas`: Salas de bate-papo 1 a 1 ou grupos.
> - `participantes_conversa`: Relacionamento N:N ligando usuários às conversas.
> - `mensagens`: ID, conversa_id, remetente_id, texto, tipo (texto, áudio, anexo, sistema), status de leitura e timestamps.
> - `canais`: Canais oficiais por departamento e emergência.
> - `comunicados`: Notificações institucionais da Direção com confirmação de leitura.
> - `denuncias_ouvidoria`: Registros de assédio/ocorrências com protocolo e sigilo.
> - `logs_auditoria`: Rastreabilidade de ações críticas dos administradores.

---

### 🟠 22. Como funciona o sistema em Tempo Real (Realtime WebSockets) do Supabase?
> **Resposta:**
> O Supabase escuta o WAL (*Write-Ahead Logging*) do PostgreSQL. Quando uma nova linha é inserida na tabela `mensagens`, o servidor despacha um evento WebSocket para o cliente Flutter:
> ```dart
> supabase
>   .from('mensagens')
>   .stream(primaryKey: ['id'])
>   .eq('conversa_id', conversationId)
>   .listen((data) { /* Nova mensagem recebida */ });
> ```

---

### 🟠 23. O que é RLS (Row Level Security) no Supabase e como ele protege nossos dados?
> **Resposta:**
> O RLS aplica regras de segurança direto no motor SQL do banco de dados.
> Mesmo que alguém acesse a API com token válido, ele só consegue ler ou escrever em linhas onde o `auth.uid()` dele seja participante da conversa ou pertença à Direção Geral, impedindo vazamento de conversas privadas.

---

### 🟠 24. Como é feito o upload e armazenamento de mídias/arquivos?
> **Resposta:**
> Usamos o **Supabase Storage / Object Storage**. O arquivo é enviado para um bucket protegido (ex: `chat-attachments` ou `avatars`), gerando uma URL pública ou pré-assinada que é gravada na coluna `anexo_url` da mensagem.

---

### 🟠 25. Como funciona a persistência de mensagens e o status de leitura (double-check azul)?
> **Resposta:**
> Cada mensagem tem um campo booleano `lida` ou uma tabela associativa de visualizações. Ao abrir a página do chat, o app executa um `update` definindo `lida = true` para todas as mensagens onde `remetente_id != meuId`. O remetente recebe a notificação Realtime e renderiza o ícone de confirmação duplo.

---

### 🟠 26. O que é a tabela `denuncias_ouvidoria` e como é gerado o protocolo?
> **Resposta:**
> É a tabela que armazena os relatos de desvio de conduta. O protocolo é gerado no formato `CS-YYYYMMDD-XXXX` (onde XXXX é um hash pseudo-aleatório seguro). Apenas usuários com a flag `is_direcao = true` têm permissão de RLS para visualizar todas as denúncias.

---

### 🟠 27. Como o banco de dados lida com exclusão de mensagens ou saída de grupos?
> **Resposta:**
> Não fazemos exclusão física destrutiva (Hard Delete) em registros com histórico de auditoria. Utilizamos **Soft Delete** (`deleted_at IS NOT NULL`) ou removemos o vínculo da tabela `participantes_conversa`.

---

### 🟠 28. Qual a diferença entre Neon Postgres e Supabase na nossa evolução de arquitetura?
> **Resposta:**
> O projeto utilizou inicialmente o Neon Serverless Postgres para estruturação SQL ágil e depois integrou o Supabase para ter a suíte completa de autenticação, Realtime WebSockets nativos do Flutter e Storage no mesmo ecossistema.

---

### 🟠 29. Como as chamadas de banco são tratadas contra falhas de conexão de rede?
> **Resposta:**
> Todos os repositórios envolvem operações de rede em blocos `try-catch` mapeados para exceções customizadas (`ServerException`, `NetworkException`), permitindo que a UI exiba mensagens amigáveis sem fechar o app.

---

### 🟠 30. Como funciona o sistema de auditoria (`audit_logs`)?
> **Resposta:**
> Toda ação sensível (criação de usuário, alteração de permissão hierárquica, visualização de denúncia) dispara a gravação de um registro na tabela `logs_auditoria` contendo o ID do autor, IP, ação realizada e timestamp para conformidade com a LGPD e regras do hospital.

---

## 📅 DIA 4: Segurança, Autenticação, Permissões & Biometria

### 🔵 31. Como funciona o sistema de Biometria (`local_auth`) implementado no app?
> **Resposta:**
> O pacote `local_auth` conversa diretamente com a API de impressão digital (Fingerprint) e reconhecimento facial (FaceID/BiometricPrompt) do sistema operacional:
> ```dart
> final localAuth = LocalAuthentication();
> final bool didAuthenticate = await localAuth.authenticate(
>   localizedReason: 'Toque no sensor para acessar o Conecta Saúde',
>   options: const AuthenticationOptions(biometricOnly: true),
> );
> ```
> O hash biométrico nunca sai do dispositivo (fica no hardware seguro Enclave/Keystore). O app apenas recebe a confirmação booleana de sucesso.

---

### 🔵 32. Como são gerenciadas as 4 Hierarquias de Permissão no app?
> **Resposta:**
> No arquivo `permissions_provider.dart`, criamos o modelo `UserPermissions`:
> 1. **Direção Geral (`isDirecao`)**: Acesso total, visualização de logs, gestão de ouvidoria/denúncias, broadcast institucional.
> 2. **Coordenação (`isCoordenacao`)**: Criação de canais, gestão de escalas e equipes do setor.
> 3. **Supervisão (`isSupervisao`)**: Moderação de mensagens da equipe, visualização de status de atendimento.
> 4. **Colaborador Geral (`isFuncionario`)**: Acesso ao chat operacional, canais autorizados e ouvidoria.

---

### 🔵 33. O que acontece se um usuário tentar forçar a navegação para `/administration` sem permissão?
> **Resposta:**
> O `GoRouter` executa o guard de rota:
> ```dart
> final perms = ref.read(permissionsProvider);
> if (state.matchedLocation == '/administration' && !perms.isDirecao) {
>   return '/home'; // Redireciona e barra o acesso
> }
> ```
> Além disso, o backend rejeita qualquer requisição via regras de RLS do banco de dados (dupla camada de segurança).

---

### 🔵 34. Onde e como são salvas as senhas e tokens de sessão no dispositivo?
> **Resposta:**
> Nunca salvamos senhas em texto puro. Os tokens JWT de sessão são armazenados no `flutter_secure_storage`, que utiliza **Keystore** no Android e **Keychain** no iOS (criptografia AES-256 baseada em hardware).

---

### 🔵 35. Como funciona o fluxo de recuperação de senha (`forgot_password_page.dart`)?
> **Resposta:**
> O usuário informa seu e-mail institucional. O Supabase Auth envia um e-mail com link assinado e token de uso único (OTP), permitindo que o colaborador redefina a senha com segurança.

---

### 🔵 36. Como garantimos a conformidade com a LGPD (Lei Geral de Proteção de Dados)?
> **Resposta:**
> 1. **Minimização de Dados**: Coletamos apenas dados essenciais para a operação hospitalar.
> 2. **Sigilo de Ouvidoria**: Denúncias não revelam a identidade da vítima caso ela opte pelo relato anônimo.
> 3. **Logs de Auditoria**: Rastreamento de quem acessou prontuários e registros de conduta.

---

### 🔵 37. O que é o JWT (JSON Web Token) retornado no login e o que ele contém?
> **Resposta:**
> É um token criptografado contendo o `sub` (ID do usuário), tempo de expiração (`exp`) e *claims* de autorização. Toda requisição HTTP/WebSocket inclui o cabeçalho `Authorization: Bearer <token>`.

---

### 🔵 38. Como funciona a alternância de status de plantão sem deslogar o usuário?
> **Resposta:**
> O status (`ativo`, `pausa`, `offline`) é um campo reativo. Ao alternar a chave no perfil, disparamos um update no banco sem invalidar a sessão JWT do usuário, mantendo-o apto a receber alertas de emergência se necessário.

---

### 🔵 39. Por que a biometria é ignorada na Web e ativada automaticamente no Mobile?
> **Resposta:**
> No ambiente Web desktop de navegadores comuns, a API de biometria nativa não está disponível universalmente. Por isso, usamos `kIsWeb` para apresentar login seguro por credenciais na web e biometria rápida nos celulares Android/iOS.

---

### 🔵 40. O que é e como funciona a chave de emergência do hospital?
> **Resposta:**
> Canais marcados com `is_emergency: true` têm prioridade máxima de transmissão e bypass em certas restrições cosméticas para que avisos de parada cardíaca ou código azul cheguem a todos os membros em menos de 1 segundo.

---

## 📅 DIA 5: Motor de Chat, Moderação & Filtro de Linguagem

### 🟣 41. Como foi projetado o `LanguageFilterService` e qual é a sua finalidade?
> **Resposta:**
> O `LanguageFilterService` (`core/services/language_filter_service.dart`) é um motor de análise contextual preventiva. Ele analisa a mensagem antes de sair do aparelho do usuário para evitar assédio moral, assédio sexual, discriminação e ofensas dirigidas, mantendo a harmonia e o compliance do hospital.

---

### 🟣 42. Quais são os 4 Níveis de Avaliação de Linguagem?
> **Resposta:**
> - **Nível 0 (Normal / Clínico)**: Envio direto. Inclui termos médicos e saudações comuns de equipe (*"querida equipe"*, *"bom dia time"*).
> - **Nível 1 (Aviso Educativo)**: Expressões informais ou inadequadas (*"que saco"*, *"porcaria"*, *"amor"*). Exibe modal permitindo revisar ou enviar mesmo assim.
> - **Nível 2 (Bloqueio Preventivo)**: Ofensas diretas e humilhação (*"idiota"*, *"babaca"*, *"incompetente"*, *"nojento"*). Impede o envio e oferece botão de reescrita ou denúncia.
> - **Nível 3 (Bloqueio Grave)**: Ameaças físicas, assédio sexual explícito e discriminação. Bloqueia imediatamente e direciona para a Ouvidoria.

---

### 🟣 43. Como o algoritmo evita "Falsos Positivos" em termos médicos legítimos?
> **Resposta:**
> Criamos uma lista de exceções clínicas (`_clinicalLegitimatePhrases`) com termos como *mama, reto, ânus, pênis, sangramento, próstata, genitália, vagina, sonda, sedação*. Se a mensagem contiver termos médicos ou estiver em um canal de emergência, o sistema classifica como **Nível 0 (Exceção Clínica Autorizada)** e não interfere no envio.

---

### 🟣 44. Como o motor lida com tentativas de burla (*Leetspeak* e repetição de letras)?
> **Resposta:**
> O método `normalizeText()` executa 3 etapas de limpeza:
> 1. **Substituição de Símbolos**: `@` e `4` viram `a`; `3` vira `e`; `1` e `!` viram `i`; `0` vira `o`; `5` e `$` viram `s`.
> 2. **Remoção de Acentos**: Converte `á, é, í, ó, ú, ç` para caracteres ASCII simples.
> 3. **Deduplicação de Letras**: Transforma *"buuuurrrro"* em *"burro"* e *"idiiooota"* em *"idiota"*.

---

### 🟣 45. Como o `ChatInputBar` intercepta o envio da mensagem para rodar o filtro?
> **Resposta:**
> No método `_handleSend()`, antes de chamar o repositório, executamos:
> ```dart
> final eval = _filterService.evaluateMessage(text: text);
> if (eval.level != LanguageRiskLevel.level0Normal) {
>   final action = await showDialog(
>     context: context,
>     builder: (_) => LanguageWarningDialog(result: eval),
>   );
>   if (action != WarningDialogAction.sendAnyway) return;
> }
> ```

---

### 🟣 46. Como o usuário pode denunciar uma mensagem recebida via "Toque Longo"?
> **Resposta:**
> No widget `MessageBubble`, configuramos o evento `onLongPress`. Ele abre um menu contextual contendo a opção **"Relatar ocorrência institucional"**. Ao clicar, o app navega para `/reports` passando o ID da mensagem e o nome do remetente pré-preenchidos.

---

### 🟣 47. O que acontece quando o usuário clica em "Ir para Ouvidoria" após um bloqueio?
> **Resposta:**
> O diálogo fecha e o app navega imediatamente para a tela de Ouvidoria (`/reports`), abrindo o formulário já configurado com a categoria correspondente e registrando um número de protocolo oficial.

---

### 🟣 48. Como as mensagens de áudio são gravadas e transmitidas?
> **Resposta:**
> Utilizamos o pacote `record` para capturar áudio em formato AAC/M4A e o `audioplayers` para reprodução com barra de progresso visual na bolha de mensagem. O arquivo de áudio é enviado para o bucket de mídias e a URL é anexada à mensagem com `type = 'audio'`.

---

### 🟣 49. Como funciona a paginação de mensagens em conversas longas?
> **Resposta:**
> Usamos paginação infinita com cursor (`limit(30).order('created_at', ascending: false)`). Conforme o usuário rola o chat para cima (`ScrollController`), o provider busca o próximo bloco de 30 mensagens sem recarregar tudo do início.

---

### 🟣 50. Por que os diálogos de alerta de linguagem usam cores neutras de severidade?
> **Resposta:**
> Para manter conformidade com padrões de acessibilidade e design institucional: usamos `AppColors.error` (vermelho) para bloqueios graves e `AppColors.warning` (âmbar) para avisos, independentemente de o usuário estar usando o tema Azul, Verde ou Noturno.

---

## 📅 DIA 6: Design System, Temas (4 Cores) & Acessibilidade

### 🟤 51. Quais são os 4 temas visuais disponíveis no Conecta Saúde?
> **Resposta:**
> 1. **Azul SUS (Padrão Institucional)**: Baseado na identidade visual da saúde pública brasileira.
> 2. **Verde Saúde / Esperança**: Focado em ambiente hospitalar clínico e humanizado.
> 3. **Modo Noturno (Dark Navy)**: Otimizado para plantonistas noturnos, reduzindo a fadiga visual.
> 4. **Alto Contraste**: Focado em acessibilidade e legibilidade máxima para baixa visão.

---

### 🟤 52. Como os temas são gerenciados no código com o `AppThemeTokens`?
> **Resposta:**
> Em vez de espalhar cores hardcoded nas telas, criamos a classe `AppThemeTokens` (`core/theme/app_theme_tokens.dart`). Cada tema define suas cores semânticas (`surface`, `textPrimary`, `textSecondary`, `themeAccentColor`, `cardBackground`). As telas consomem apenas `tokens.textPrimary`, adaptando-se instantaneamente quando o usuário troca de tema.

---

### 🟤 53. Como a troca de tema persiste entre as sessões do app?
> **Resposta:**
> O `AppThemeProvider` salva o enum do tema escolhido no `SharedPreferences`. Quando o app é aberto novamente, ele carrega a preferência antes de exibir a primeira tela.

---

### 🟤 54. Por que substituímos `withOpacity()` por `.withValues(alpha: ...)` no Flutter 3.27+?
> **Resposta:**
> A equipe do Flutter depreciou `withOpacity()` porque causava perda de precisão e overhead de renderização em novas engines gráficas (Impeller). A nova API `.withValues(alpha: 0.8)` manipula canais de cor com ponto flutuante de forma mais performática.

---

### 🟤 55. Como garantimos que o texto nunca fique ilegível no Modo Noturno?
> **Resposta:**
> Através do cálculo de contraste semântico. No modo noturno, `tokens.textPrimary` é branco puro (`#FFFFFF`) e `tokens.surface` é azul-marinho profundo (`#132A42`), garantindo uma taxa de contraste (WCAG) superior a 7:1.

---

### 🟤 56. O que são as fontes e ícones utilizados no projeto?
> **Resposta:**
> Utilizamos a tipografia padrão do Material Design com pesos customizados (`FontWeight.w400` a `w700`) e ícones oficiais do **Material Icons Rounded / Outlined**, que oferecem visual profissional e limpo para interfaces de saúde.

---

### 🟤 57. Como funciona a responsividade da interface (Mobile vs Desktop/Web)?
> **Resposta:**
> Usamos `LayoutBuilder` e `MediaQuery.of(context).size.width`. Em telas maiores que 800px (Desktop/Web), a navegação é exibida como uma barra lateral fixa (Navigation Rail), e em telas menores (Smartphones) como BottomNavigationBar inferior.

---

### 🟤 58. Como os cartões de status dos serviços (`service_status_card.dart`) adaptam suas cores?
> **Resposta:**
> Cada status possui uma cor semântica fixa (`Verde = Disponível`, `Laranja = Pausa/Refeição`, `Vermelho = Emergência`, `Cinza = Desconectado`), combinada com fundos translúcidos dinâmicos baseados no tema ativo.

---

### 🟤 59. O que é o `SplashScreen` customizado e como ele transiciona?
> **Resposta:**
> O `SplashScreen` exibe a logomarca oficial do Conecta Saúde, executa a checagem de sessão assíncrona do Riverpod e faz um fade suave diretamente para a `/home` ou `/login`.

---

### 🟤 60. Como garantimos acessibilidade para leitores de tela (TalkBack / VoiceOver)?
> **Resposta:**
> Envolvemos botões de ação e ícones em widgets com propriedades `Semantics` e rótulos descritivos (`tooltip: 'Enviar mensagem'`, `semanticsLabel: 'Denunciar ocorrência'`), permitindo que deficientes visuais utilizem o app com facilidade.

---

## 📅 DIA 7: CI/CD, Build APK/Web, Firebase & Produção

### ⚫ 61. Como o Web App é compilado e publicado em produção?
> **Resposta:**
> 1. Executamos `flutter build web --release` (otimizando árvores de ícones e JavaScript).
> 2. Os arquivos estáticos são gerados na pasta `app/build/web`.
> 3. O comando `firebase deploy --only hosting` envia os arquivos para a infraestrutura global do **Firebase Hosting** com CDN de alta velocidade no domínio `https://conecta-hospital.web.app`.

---

### ⚫ 62. Como o APK Android de Release é gerado e qual a diferença para o de Debug?
> **Resposta:**
> Executamos `flutter build apk --release`.
> - **Debug**: Contém o motor de *Hot Reload*, compilador JIT e código de inspeção (pesado e mais lento).
> - **Release**: É compilado em código de máquina AOT (*Ahead-Of-Time*), com *tree-shaking* de fontes não utilizadas, ofuscação de código e redução drástica de tamanho (de ~150MB para ~62MB).

---

### ⚫ 63. O que significa o aviso de "Tree-shaking" de fontes que aparece no build?
> **Resposta:**
> O Flutter analisa todo o código-fonte e descarta do arquivo de fontes do Material Icons todos os milhares de ícones que não foram usados no app, reduzindo o arquivo de ícones de 1.6MB para apenas 26KB (mais de 98% de economia).

---

### ⚫ 64. Como as notificações push são enviadas via Firebase Cloud Messaging (FCM)?
> **Resposta:**
> Quando um usuário recebe uma mensagem ou aviso de emergência:
> 1. O backend dispara uma mensagem via API do FCM com o token do dispositivo de destino.
> 2. O aplicativo recebe o payload via `firebase_messaging`.
> 3. Se o app estiver em segundo plano, o sistema operacional exibe a notificação nativa; se estiver em primeiro plano, exibimos um banner in-app.

---

### ⚫ 65. Como funciona o versionamento do projeto no Git e no `pubspec.yaml`?
> **Resposta:**
> Seguimos o **Semantic Versioning (SemVer)**: `version: 1.0.0+1` (onde `1.0.0` é o nome da versão visível ao usuário e `+1` é o `buildNumber` incremental exigido pelas lojas Google Play e Apple App Store).

---

### ⚫ 66. Por que utilizamos o comando `flutter analyze` antes de qualquer deploy?
> **Resposta:**
> O `flutter analyze` é o linter estático do Dart. Ele verifica se existem erros de tipagem, imports não utilizados, código morto ou chamadas a métodos depreciados, garantindo que nenhum bug chegue aos usuários em produção.

---

### ⚫ 67. Como resolver erros de CORS na versão Web?
> **Resposta:**
> Configuramos as origens permitidas (`https://conecta-hospital.web.app`) diretamente nas configurações de API do Supabase e do Firebase Storage, garantindo que o navegador autorize o tráfego de requisições e upload de mídias.

---

### ⚫ 68. Como seria o processo de publicação do app para iOS (iPhone)?
> **Resposta:**
> Como o Flutter é multiplataforma:
> 1. O código é o mesmo.
> 2. É necessário abrir o projeto no Xcode em ambiente macOS.
> 3. Configurar os certificados de assinatura da Apple (*Apple Developer Certificate & Provisioning Profile*).
> 4. Executar `flutter build ipa` e enviar para o TestFlight / App Store Connect.

---

### ⚫ 69. Onde ficam os arquivos finais e o APK dentro do nosso repositório?
> **Resposta:**
> - Código-fonte completo: `c:\projetos\conecta-saude\app`
> - APK Release pronto para instalação: `c:\projetos\conecta-saude\conecta-saude-v1.0.apk`
> - Repositório GitHub oficial: `https://github.com/tecnicorikardo/conecta-saude`
> - Web App em Produção: `https://conecta-hospital.web.app`

---

### ⚫ 70. Se o diretor técnico do hospital perguntar "Por que essa arquitetura é segura e escalável?", o que você responde?
> **Resposta (Resumo Executivo para a Diretoria):**
> *"O Conecta Saúde foi construído com arquitetura desacoplada e padrões modernos da indústria:*
> *1. **Segurança Multicamadas**: Autenticação biométrica no dispositivo, criptografia de tokens no hardware, proteção de banco via Row Level Security e filtro preventivo contra assédio e infrações éticas.*
> *2. **Alta Disponibilidade e Velocidade**: Mensageria em tempo real via WebSockets distribuídos e CDN global no Firebase Hosting com carregamento em milissegundos.*
> *3. **Escalabilidade e Manutenibilidade**: O código em Clean Architecture e Riverpod permite expandir o sistema para milhares de colaboradores ou adicionar novos hospitais à rede sem necessidade de reescrever a base do software."*
