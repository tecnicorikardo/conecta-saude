# Prompt para implantação de filtro de linguagem — Conecta Saúde

## Objetivo

Implemente no Conecta Saúde um sistema de **detecção preventiva de linguagem potencialmente inadequada**, com foco em assédio, ameaças, ofensas, discriminação, conteúdo sexual impróprio e palavrões direcionados a profissionais.

O objetivo não é substituir a análise humana nem declarar automaticamente que uma mensagem configura assédio. O objetivo é prevenir o envio impulsivo, orientar o usuário, reduzir comportamentos inadequados e encaminhar reincidências para análise institucional restrita.

O recurso deve funcionar em conversas individuais, grupos, canais e respostas a comunicados, sem prejudicar a comunicação clínica ou emergencial.

## Princípio fundamental

> O sistema deve analisar linguagem potencialmente inadequada com contexto e proporcionalidade, alertar o usuário antes do envio quando possível e encaminhar situações graves ou reincidentes para o setor institucional autorizado, preservando privacidade, segurança e direito de resposta.

## Regras importantes

Não bloquear automaticamente qualquer mensagem apenas porque contém uma palavra isolada como:

- Amor.
- Querida.
- Meu bem.
- Amigo.
- Linda.
- Chefe.
- Doutora.
- Professor.

Essas palavras podem ter diferentes significados conforme o contexto. Por exemplo, “querida equipe” pode ser uma saudação normal, enquanto “querida, você nunca faz nada direito” pode ser uma mensagem humilhante dependendo da repetição, do destinatário e do histórico.

O sistema deve diferenciar **palavra isolada**, **expressão contextual**, **insulto direcionado**, **ameaça**, **conteúdo sexual**, **discriminação** e **reincidência**.

## Níveis de classificação

### Nível 0 — Linguagem normal

Mensagem sem indícios relevantes de abuso, ameaça, discriminação ou conteúdo sexual inadequado.

**Ação:** enviar normalmente.

### Nível 1 — Termo potencialmente inadequado

Mensagem contém expressões que podem ser inadequadas em ambiente profissional, mas não permitem concluir abuso sem contexto.

Exemplos:

- “amor”.
- “querida”.
- “meu bem”.
- Apelidos não autorizados.
- Linguagem excessivamente íntima.
- Comentários sobre aparência sem necessidade profissional.

**Ação recomendada:** exibir aviso antes do envio, sem bloquear automaticamente.

Mensagem sugerida:

> “Esta mensagem contém uma expressão que pode ser interpretada como informal ou inadequada no ambiente profissional. Deseja revisar antes de enviar?”

Botões:

- Revisar mensagem.
- Enviar mesmo assim.
- Cancelar.

O envio mesmo assim deve ser permitido, salvo se a mensagem também se enquadrar em nível mais grave.

### Nível 2 — Ofensa, palavrão direcionado ou humilhação

Mensagem contém insulto dirigido a uma pessoa, palavrão usado para atacar alguém, humilhação, desqualificação profissional ou linguagem agressiva repetida.

Exemplos genéricos:

- Ataque à capacidade profissional de uma pessoa.
- Humilhação pública em grupo.
- Palavrão direcionado nominalmente a um usuário.
- Mensagem com intenção clara de constranger ou intimidar.
- Repetição insistente após pedido para parar.

**Ação recomendada:** bloquear o envio inicialmente e exibir orientação.

Mensagem sugerida:

> “Não foi possível enviar esta mensagem porque ela pode conter ofensa ou linguagem inadequada para o ambiente profissional. Revise o texto ou utilize o canal institucional apropriado para registrar uma ocorrência.”

Botões:

- Editar mensagem.
- Cancelar.
- Relatar ocorrência.

Não exibir o conteúdo da mensagem para outros usuários. Registrar somente o necessário para análise autorizada, conforme a política de privacidade.

### Nível 3 — Ameaça, discriminação ou conteúdo sexual abusivo

Mensagem contém indício de:

- Ameaça física ou profissional.
- Chantagem.
- Intimidação grave.
- Conteúdo sexual não solicitado.
- Comentário sexual dirigido a colega.
- Discriminação por raça, cor, gênero, orientação sexual, identidade de gênero, religião, deficiência, idade ou origem.
- Incentivo à violência.
- Perseguição ou assédio reiterado.

**Ação recomendada:** bloquear o envio, preservar evidência de forma protegida e criar ocorrência restrita para o setor autorizado.

Mensagem sugerida ao usuário:

> “Esta mensagem não foi enviada porque contém linguagem potencialmente grave ou incompatível com a política de comunicação profissional. Se você precisa relatar uma situação, utilize o canal de Ouvidoria ou Denúncia Institucional.”

A ocorrência deve ser encaminhada somente para os perfis autorizados, como Ouvidoria, RH, Compliance ou Comissão responsável. O administrador comum não deve ter acesso ao conteúdo.

## Análise contextual

O mecanismo deve considerar, quando permitido pela política institucional:

- Palavras próximas.
- Destinatário individual ou grupo.
- Repetição do comportamento.
- Número de mensagens em curto intervalo.
- Pedido anterior para interromper o contato.
- Mensagens removidas ou editadas.
- Resposta do destinatário.
- Relação hierárquica entre remetente e destinatário, quando essa informação for necessária e legítima.
- Canal utilizado e finalidade do grupo.

Não presumir assédio apenas com base em uma palavra. A classificação deve gerar um nível de risco, não uma sentença definitiva.

## Configuração por instituição

Criar uma área administrativa restrita para configurar:

- Lista de palavras e expressões proibidas.
- Lista de palavras que apenas geram aviso.
- Categorias de risco.
- Ação por categoria: permitir, avisar ou bloquear.
- Idioma e variações regionais.
- Limite de reincidência.
- Setores responsáveis pelo recebimento de ocorrências.
- Prazo de retenção.
- Mensagem exibida ao usuário.

A lista de termos deve ficar protegida no backend. Não expor a lista completa no aplicativo para usuários comuns.

Toda alteração na lista deve registrar:

- Administrador responsável.
- Data e hora.
- Regra anterior.
- Regra nova.
- Justificativa.

## Reincidência

Criar um mecanismo de reincidência sem expor publicamente a pontuação do usuário.

Exemplo de fluxo:

1. Primeira ocorrência de nível 1: aviso educativo.
2. Repetição de nível 1 em curto período: novo aviso e recomendação de revisão.
3. Ocorrência de nível 2: bloqueio da mensagem e registro restrito.
4. Reincidência de nível 2: encaminhamento para análise do setor responsável.
5. Nível 3: encaminhamento imediato, independentemente do histórico.

Não suspender definitivamente um usuário apenas por uma classificação automática. Qualquer medida disciplinar deve depender da política institucional e de análise humana.

## Fluxo de denúncia

Adicionar a opção “Relatar ocorrência” na mensagem e no menu da conversa.

O formulário deve conter:

- Categoria do relato.
- Descrição opcional.
- Mensagem ou contexto relacionado.
- Possibilidade de anexar evidência, se permitido.
- Opção de solicitar contato.
- Aviso de confidencialidade.
- Número de protocolo.

Categorias sugeridas:

- Linguagem ofensiva.
- Assédio moral.
- Assédio sexual.
- Ameaça ou intimidação.
- Discriminação.
- Violação de confidencialidade.
- Outro.

A pessoa que registra deve receber confirmação de protocolo. O sistema deve deixar claro que a plataforma não substitui canais de emergência, atendimento médico, autoridade policial ou procedimentos obrigatórios da instituição.

## Privacidade e proteção de dados

Implementar o recurso com minimização de dados.

- Não armazenar mensagens analisadas por mais tempo do que o necessário.
- Proteger o conteúdo com controle de acesso por função.
- Registrar acesso a ocorrências sensíveis.
- Impedir que administradores comuns leiam denúncias.
- Informar os usuários sobre o funcionamento do filtro.
- Publicar política de retenção e finalidade.
- Permitir correção ou contestação conforme as regras institucionais aplicáveis.
- Evitar usar o filtro para vigilância geral ou monitoramento abusivo.
- Não utilizar o conteúdo para treinamento externo sem base legal e autorização adequada.
- Criptografar dados sensíveis em trânsito e em repouso.

A plataforma deve consultar o responsável por proteção de dados, jurídico, RH e Compliance do hospital antes da implantação em produção.

## Emergência e comunicação clínica

O filtro não pode atrapalhar comunicação clínica urgente.

Para mensagens em canal de emergência:

- Não bloquear termos técnicos, abreviações clínicas ou linguagem objetiva de plantão.
- Permitir envio prioritário de alertas operacionais.
- Manter registro de quem enviou e recebeu.
- Se houver linguagem abusiva junto com um alerta clínico real, preservar a comunicação crítica e sinalizar o trecho inadequado para análise posterior, conforme a política definida.
- Nunca substituir o protocolo oficial de emergência.

Criar uma opção de “Mensagem operacional urgente” para reduzir falsos positivos em situações críticas.

## Experiência do usuário

O aviso deve ser curto, respeitoso e não acusatório. Evitar textos como “você está cometendo assédio” quando o sistema ainda possui apenas uma suspeita.

Preferir:

> “Esta mensagem pode não estar adequada ao ambiente profissional. Revise o texto antes de enviar.”

Para bloqueios graves:

> “A mensagem não foi enviada porque pode violar a política de comunicação profissional. Se você precisa registrar uma situação, utilize o canal institucional de denúncia.”

Não usar cores LGBTQI+, rosa, azul ou qualquer tema visual para indicar gravidade. A severidade deve ser comunicada por texto, ícone, estado e padrão sem depender apenas de cor.

## Arquitetura sugerida

Separar o recurso em camadas:

1. **Validação local rápida:** identifica padrões óbvios antes do envio e mostra feedback imediato.
2. **Validação no backend:** repete a análise para impedir que a regra seja contornada.
3. **Classificador contextual:** avalia combinações de termos e contexto com regras auditáveis.
4. **Registro de evento:** salva somente metadados e evidência necessária, com acesso restrito.
5. **Fluxo institucional:** encaminha ocorrências para o setor autorizado.
6. **Painel de revisão:** permite classificar como procedente, improcedente, inconclusiva ou encaminhada.

O resultado da análise deve incluir categoria, nível, motivo resumido, ação aplicada e identificador da regra. Evitar salvar somente uma pontuação sem explicação.

Exemplo de estrutura:

```json
{
  "level": 2,
  "category": "offensive_language",
  "action": "block_and_report_option",
  "reasonCode": "directed_insult",
  "messageId": "internal-id",
  "createdAt": "server-timestamp",
  "reviewStatus": "pending"
}
```

Não incluir o texto completo em logs comuns. O conteúdo integral deve ficar em armazenamento protegido, somente quando a política autorizar a preservação.

## Testes obrigatórios

### Testes que devem ser permitidos

- “Bom dia, querida equipe.”
- “Amor, você pode conferir este documento?”
- “Favor enviar o relatório até as 16h.”
- “Paciente aguardando avaliação no leito 402.”
- “Equipe de emergência acionada.”
- Termos técnicos médicos e abreviações clínicas válidas.

### Testes que devem gerar aviso

- Uso de apelido íntimo em conversa profissional.
- Comentário sobre aparência sem necessidade profissional.
- Linguagem excessivamente informal sem insulto.
- Repetição de tratamento íntimo após pedido para usar o nome profissional.

### Testes que devem bloquear ou encaminhar

- Insulto direcionado a uma pessoa.
- Palavrão usado para humilhar ou ameaçar.
- Ameaça física ou profissional.
- Conteúdo sexual não solicitado.
- Discriminação.
- Perseguição repetida.
- Mensagem abusiva enviada várias vezes após aviso.

### Testes de segurança

- Tentar contornar o filtro com espaços, símbolos, números ou caracteres semelhantes.
- Editar mensagem após a classificação.
- Enviar a mesma mensagem por outro dispositivo.
- Tentar remover a ocorrência sem permissão.
- Verificar se administrador comum consegue abrir conteúdo restrito.
- Verificar se a denúncia aparece para o denunciado.
- Testar expiração e retenção dos dados.
- Testar exportação e auditoria.

## Critérios de aceite

- [ ] Palavras isoladas como “amor” e “querida” não são bloqueadas automaticamente.
- [ ] Palavrões direcionados podem ser classificados conforme contexto.
- [ ] Ameaças, discriminação e conteúdo sexual abusivo são bloqueados ou encaminhados conforme política.
- [ ] O usuário recebe explicação clara e respeitosa.
- [ ] Existe opção de editar a mensagem antes do envio.
- [ ] Existe canal de denúncia com protocolo.
- [ ] O filtro não interfere em mensagens clínicas e emergenciais válidas.
- [ ] Existe trilha de auditoria para ações administrativas.
- [ ] Ocorrências sensíveis têm acesso restrito.
- [ ] A classificação automática não gera punição definitiva sem análise humana.
- [ ] O sistema registra motivo e regra aplicada.
- [ ] Há proteção contra contorno simples do filtro.
- [ ] Todos os temas visuais da aplicação mantêm legibilidade e significado dos estados.
- [ ] O recurso funciona em desktop, celular e PWA.
- [ ] O hospital aprova a política de uso, retenção e encaminhamento antes da produção.

## Resultado esperado

O Conecta Saúde deve se tornar um ambiente de comunicação profissional mais seguro, sem criar censura indiscriminada ou vigilância abusiva.

O filtro deve atuar como uma camada de prevenção e orientação. Ele deve proteger as equipes, reduzir conflitos, preservar evidências necessárias e facilitar o encaminhamento institucional, mantendo sempre o contexto, a proporcionalidade, a privacidade e o direito de análise humana.

## Observação para implantação

Antes de ativar o bloqueio em produção, iniciar em **modo observação** por um período controlado. Nesse modo, o sistema identifica possíveis ocorrências, mas não bloqueia mensagens automaticamente. A equipe autorizada deve avaliar falsos positivos, ajustar regras e somente depois ativar avisos e bloqueios por categoria.
