# Prompt para implementação de temas — Conecta Saúde

## Objetivo

Implementar no Conecta Saúde um sistema de temas configurável, permitindo que cada usuário escolha entre o tema SUS claro padrão, o tema escuro, o tema LGBTQI+ sutil e o tema rosa. A personalização deve alterar a aparência visual sem modificar a estrutura, a hierarquia, os textos, as permissões, os fluxos clínicos ou os recursos de comunicação da aplicação.

A identidade do SUS deve permanecer reconhecível em todos os temas. O azul institucional continuará sendo a cor de referência para navegação, ações principais, seleção, links e indicadores de interação. Os temas personalizados devem complementar o padrão SUS, e não substituí-lo.

## Prompt principal para o desenvolvimento

> Implemente no Conecta Saúde um seletor de temas visuais com quatro opções: **SUS Claro**, **Escuro**, **LGBTQI+ Sutil** e **Rosa Institucional**.
>
> A implementação deve usar tokens de design ou variáveis globais de tema, evitando cores escritas diretamente em cada componente. O tema escolhido deve ser salvo localmente para permanecer após fechar e reabrir o aplicativo. Se o usuário estiver autenticado em mais de um dispositivo, a preferência pode ser sincronizada futuramente, mas a primeira versão deve funcionar com segurança usando armazenamento local.
>
> O seletor deve estar disponível em Perfil, Configurações ou Preferências. Deve apresentar nome, ícone e uma pequena prévia de cada tema. A troca deve ocorrer sem recarregar a página e sem interromper conversas, notificações, áudio, canais ou outras operações em andamento.
>
> O tema SUS Claro deve ser o padrão inicial e continuar sendo a referência visual principal do produto. O azul SUS deve permanecer presente em botões, links, navegação ativa e elementos de foco.
>
> O tema Escuro deve usar azul-marinho e grafite como base, sem transformar todos os elementos em preto puro. Os textos precisam manter alto contraste, as superfícies devem ser diferenciadas por níveis de luminosidade e o azul SUS deve continuar identificando ações e estados ativos.
>
> O tema LGBTQI+ deve ser elegante, discreto e institucional. Não usar arco-íris saturado em todos os cards, fundos inteiros ou textos. Aplicar uma faixa cromática fina, um detalhe linear, um pequeno indicador no cabeçalho ou acentos muito controlados em elementos de identidade. O azul SUS deve continuar sendo a cor funcional principal. As cores LGBTQI+ devem aparecer como identidade visual complementar, sem competir com alertas clínicos, informações de emergência ou navegação.
>
> O tema Rosa Institucional deve utilizar rosa e magenta de forma sóbria, combinados com azul SUS, azul-marinho, branco e cinza clínico. Evitar rosa neon, excesso de gradientes, fundos inteiramente rosas e texto rosa sobre fundo claro com baixo contraste. O rosa deve ser aplicado em detalhes de destaque, seleção alternativa, ilustrações simples, indicadores e elementos de personalização.
>
> Não alterar a semântica das cores de status. Vermelho deve continuar reservado para emergência, erro e perigo. Âmbar deve representar atenção ou pendência. Verde deve representar sucesso, confirmação ou estado ativo. A troca de tema não pode fazer um alerta de emergência parecer decorativo ou reduzir sua legibilidade.
>
> Os cards devem permanecer predominantemente brancos no tema claro, translúcidos ou em superfícies elevadas no tema escuro, e sem preenchimentos multicoloridos exagerados nos temas LGBTQI+ e Rosa. Preferir bordas finas, faixas laterais, ícones e indicadores discretos. Não preencher todos os cards com cores fortes.
>
> Garantir acessibilidade visual em todos os temas. Validar contraste de texto normal, texto grande, botões, links, estados selecionados, mensagens não lidas, campos de formulário e alertas. Nunca usar somente cor para comunicar estado: combinar cor com ícone, texto, peso tipográfico, borda ou padrão visual.
>
> A troca de tema deve respeitar responsividade em desktop, tablet e celular, além do modo PWA. O tema escolhido deve funcionar em telas de login, home, conversas, grupos, canais, comunicados, emergência, perfil, notificações e modais.

## Tokens sugeridos

### Tema SUS Claro

```text
background: #F6F8FA
surface: #FFFFFF
surfaceMuted: #EAF3FB
textPrimary: #0B1C2E
textSecondary: #5C6B7A
border: #D8E0E8
primary: #1565C0
primaryDark: #0B3D6E
primarySoft: #EAF3FB
critical: #C62828
warning: #D9822B
success: #218739
```

### Tema Escuro

```text
background: #081522
surface: #0F2438
surfaceMuted: #143450
textPrimary: #F5F9FC
textSecondary: #B9C7D4
border: #2A455D
primary: #42A5F5
primaryDark: #1565C0
primarySoft: #173F62
critical: #FF6B5E
warning: #F2B45B
success: #55C878
```

O tema escuro deve evitar preto absoluto como fundo dominante. O azul-marinho cria continuidade com o padrão SUS e preserva uma aparência hospitalar e tecnológica.

### Tema LGBTQI+ Sutil

```text
background: #F6F8FA
surface: #FFFFFF
surfaceMuted: #F1F5FA
textPrimary: #0B1C2E
textSecondary: #5C6B7A
border: #D8E0E8
primary: #1565C0
primaryDark: #0B3D6E
primarySoft: #EAF3FB
identityRed: #E85D75
identityOrange: #E99A45
identityYellow: #D8B52C
identityGreen: #4C9B6B
identityBlue: #3D7CC9
identityViolet: #7657A6
critical: #C62828
warning: #D9822B
success: #218739
```

Aplicar as cores de identidade preferencialmente em uma linha de 3 px a 4 px, em um pequeno elemento decorativo no cabeçalho, em uma borda superior de seção ou em um indicador discreto. Não utilizar as seis cores em todos os componentes.

### Tema Rosa Institucional

```text
background: #F8F7F9
surface: #FFFFFF
surfaceMuted: #FCEEF4
textPrimary: #241A26
textSecondary: #6D5D6B
border: #E4D6DF
primary: #1565C0
primaryDark: #0B3D6E
primarySoft: #EAF3FB
accent: #C04B78
accentSoft: #FCEEF4
critical: #C62828
warning: #D9822B
success: #218739
```

O azul SUS deve continuar nos botões principais e na navegação. O rosa deve funcionar como acento de personalização, não como substituto da cor funcional principal.

## Tratamento dos componentes

### Navegação

A barra superior deve conservar azul-marinho ou azul SUS. No tema LGBTQI+, pode receber uma linha multicolorida fina na borda superior. No tema rosa, pode receber uma linha rosa discreta, mantendo o restante azul institucional.

### Cards

Usar fundo de superfície, borda fina e indicadores laterais. O tema não deve preencher todos os cards com azul, rosa ou arco-íris. Cards selecionados podem usar fundo suave e borda de destaque.

### Botões

O botão principal continua azul SUS. O botão secundário usa superfície clara com borda. O botão de emergência continua vermelho em todos os temas. O tema rosa pode usar rosa apenas em ações não críticas de personalização ou destaque.

### Conversas

Conversas não lidas devem usar ponto, contador ou faixa lateral azul. O tema escolhido não deve alterar a compreensão de enviado, pendente, entregue, lido ou falha. O relógio de envio deve continuar visível e usar uma cor de pendência adequada.

### Grupos e canais

A lista deve usar superfícies neutras com seleção em azul claro. Um canal destacado pode receber uma faixa de identidade do tema, mas nunca deve parecer um alerta de emergência.

### Comunicados

A prioridade do comunicado deve continuar sendo expressa por texto, ícone e cor semântica. O tema não pode transformar um comunicado normal em vermelho, rosa ou arco-íris apenas por estética.

### Emergência

Emergência sempre deve manter alto contraste e predominância de vermelho ou vermelho combinado com azul-marinho. Nenhuma cor LGBTQI+ ou rosa deve substituir o vermelho de emergência.

### Perfil e configurações

Adicionar uma seção “Aparência” com as opções:

- SUS Claro — padrão institucional.
- Escuro — conforto visual em ambientes de pouca luz.
- LGBTQI+ Sutil — identidade inclusiva discreta.
- Rosa Institucional — personalização com acento rosa.
- Seguir sistema — opcional para acompanhar o modo claro/escuro do dispositivo.

Cada opção deve apresentar uma miniatura visual pequena e uma descrição curta. A seleção deve ter indicação textual e visual, não apenas uma borda colorida.

## Requisitos de acessibilidade

- Garantir contraste mínimo conforme WCAG 2.2.
- Não usar somente cor para diferenciar mensagens lidas e não lidas.
- Manter foco visível em campos, botões e menus.
- Garantir leitura correta por tecnologias assistivas.
- Usar estados `hover`, `focus`, `active`, `disabled`, `loading` e `error` consistentes.
- Testar daltonismo e baixa visão.
- Evitar texto pequeno sobre azul, rosa ou roxo saturado.
- Não usar animações rápidas ou piscantes em elementos de identidade.
- Respeitar preferência de redução de movimento do sistema operacional.

## Critérios de aceite

- [ ] O tema SUS Claro permanece como padrão.
- [ ] O usuário consegue trocar o tema sem recarregar a aplicação.
- [ ] A preferência permanece após fechar e reabrir o PWA.
- [ ] Conversas, grupos, canais e comunicados mantêm a mesma estrutura em todos os temas.
- [ ] O tema escuro não apresenta textos ilegíveis ou superfícies indistinguíveis.
- [ ] O tema LGBTQI+ é visível, inclusivo e discreto, sem excesso de arco-íris.
- [ ] O tema rosa é institucional e não usa rosa neon como cor dominante.
- [ ] O azul SUS continua identificando ações principais.
- [ ] Vermelho continua reservado para emergência e erro crítico.
- [ ] Cards não são preenchidos integralmente com cores fortes.
- [ ] O contraste é validado em login, home, conversa, grupo, modal e emergência.
- [ ] A preferência de tema não altera permissões ou dados do usuário.
- [ ] A troca não interrompe listeners de mensagens ou notificações.
- [ ] O tema funciona em desktop, celular e PWA.

## Resultado esperado

O Conecta Saúde deve oferecer personalização sem perder autoridade institucional. O SUS continua sendo a base visual do produto, enquanto os temas escuro, LGBTQI+ sutil e rosa permitem identificação e conforto individual.

A interface final deve transmitir três características: **confiança hospitalar, inclusão respeitosa e tecnologia moderna**. O impacto visual deve vir do contraste, da tipografia, da organização e dos detalhes de identidade, não do excesso de cores nos cards.
