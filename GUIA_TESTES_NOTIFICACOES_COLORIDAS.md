# 🎨 Guia de Testes - Notificações Push Coloridas por Tipo

## 📋 Visão Geral

Este documento contém instruções detalhadas para testar as notificações push coloridas implementadas no Conecta Saúde.

**Tipos de Notificação:**
- 🔵 **Mensagens** (azul `#005CA9`) - Chat individual, grupos e canais
- 🟡 **Alertas** (amarelo `#FFA000`) - Comunicados oficiais
- 🔴 **Emergências** (vermelho `#D32F2F`) - Alertas críticos (PCR, trauma, O₂)

---

## 🧪 Teste 1: Notificações em Foreground (App Aberto) - Android

### Pré-requisitos
- ✅ App instalado em dispositivo Android físico ou emulador
- ✅ Backend rodando (local ou Render)
- ✅ Usuário logado com FCM token registrado
- ✅ Permissões de notificação concedidas

### Passo a Passo

#### 1.1 - Compilar e Instalar o APK
```bash
cd app
flutter clean
flutter pub get
flutter build apk --release
adb install build/app/outputs/flutter-apk/app-release.apk
```

#### 1.2 - Abrir o App e Fazer Login
- Abra o aplicativo no dispositivo
- Faça login com suas credenciais
- Vá para **Perfil** e verifique se as notificações estão habilitadas

#### 1.3 - Testar Endpoint de Teste Tipado

Use uma ferramenta como **Postman**, **Insomnia** ou **curl** para enviar requisições:

**A. Teste Mensagem (Azul)**
```bash
POST https://conecta-saude-backende.onrender.com/api/auth/test-push-typed
Authorization: Bearer {seu_token_firebase}
Content-Type: application/json

{
  "type": "message"
}
```

**B. Teste Alerta (Amarelo)**
```bash
POST https://conecta-saude-backende.onrender.com/api/auth/test-push-typed
Authorization: Bearer {seu_token_firebase}
Content-Type: application/json

{
  "type": "alert"
}
```

**C. Teste Emergência (Vermelho)**
```bash
POST https://conecta-saude-backende.onrender.com/api/auth/test-push-typed
Authorization: Bearer {seu_token_firebase}
Content-Type: application/json

{
  "type": "emergency"
}
```

### ✅ Critérios de Sucesso
- [ ] Notificação de mensagem aparece com **fundo azul**
- [ ] Notificação de alerta aparece com **fundo amarelo**
- [ ] Notificação de emergência aparece com **fundo vermelho**
- [ ] Vibrações diferentes para cada tipo
- [ ] Texto do título e corpo corretos

### 📸 Evidências
Tire screenshots de cada tipo de notificação no painel de notificações do Android.

---

## 🧪 Teste 2: Notificações em Background (App Fechado) - Android

### Passo a Passo

#### 2.1 - Fechar o App Completamente
- Minimize o app
- Vá para **Configurações** → **Apps** → **Conecta Saúde**
- Toque em **Forçar Parada** OU simplesmente remova o app dos recentes

#### 2.2 - Enviar Notificação com Delay
Use o parâmetro `delaySeconds` para ter tempo de fechar o app:

```bash
POST https://conecta-saude-backende.onrender.com/api/auth/test-push-typed
Authorization: Bearer {seu_token_firebase}
Content-Type: application/json

{
  "type": "emergency",
  "delaySeconds": 10
}
```

#### 2.3 - Aguardar e Verificar
- Após enviar a requisição, feche o app completamente
- Aguarde os 10 segundos
- A notificação deve chegar via FCM background

### ✅ Critérios de Sucesso
- [ ] Notificação chega mesmo com app fechado
- [ ] Cor de fundo correta (vermelho para emergency)
- [ ] Ao tocar na notificação, o app abre
- [ ] Vibração intensa para emergência

### 📝 Notas
- Notificações em background são processadas pelo Firebase SDK nativo
- A cor é aplicada via campo `android.notification.color` no payload FCM
- O canal usado é determinado pelo campo `data.notificationType`

---

## 🧪 Teste 3: Notificações Web/PWA

### Pré-requisitos
- ✅ Navegador Chrome ou Edge
- ✅ Acesso a https://conecta-hospital.web.app
- ✅ Permissão de notificações concedida

### Passo a Passo

#### 3.1 - Instalar PWA (Opcional mas Recomendado)
1. Abra https://conecta-hospital.web.app no Chrome
2. Clique no ícone **Instalar** na barra de endereços
3. Confirme a instalação
4. O PWA abrirá como app standalone

#### 3.2 - Fazer Login e Habilitar Notificações
1. Faça login no app
2. Quando solicitado, clique em **Permitir** notificações
3. Verifique no perfil se o token FCM foi registrado

#### 3.3 - Enviar Notificações de Teste
Use os mesmos endpoints do Teste 1, mas agora para o usuário Web:

```bash
POST https://conecta-saude-backende.onrender.com/api/auth/test-push-typed
Authorization: Bearer {seu_token_firebase}
Content-Type: application/json

{
  "type": "message"
}
```

Repita para `alert` e `emergency`.

### ✅ Critérios de Sucesso
- [ ] Notificações aparecem no centro de notificações do Windows/Mac
- [ ] Badge colorido SVG aparece corretamente:
  - 🔵 Círculo azul para mensagens
  - 🟡 Círculo amarelo para alertas
  - 🔴 Círculo vermelho para emergências
- [ ] Vibração (em dispositivos compatíveis)
- [ ] `requireInteraction: true` para emergências (não desaparece automaticamente)
- [ ] Ao clicar, abre o app/PWA

### 📝 Limitações Web
- Navegadores não permitem customizar a cor de fundo do texto
- Apenas o badge/ícone pode ser colorido
- Sons de notificação são controlados pelo sistema operacional

---

## 🧪 Teste 4: Fluxo Real de Uso

### 4.1 - Teste Mensagem de Chat Real
1. Com dois usuários logados (User A e User B)
2. User A envia mensagem para User B
3. Verifique que User B recebe notificação **azul**

### 4.2 - Teste Comunicado Oficial
1. Logue como usuário **Coordenação** ou **Direção**
2. Vá para **Comunicados** → **Criar Novo**
3. Preencha título, mensagem e prioridade
4. Publique
5. Outros usuários devem receber notificação **amarela**

### 4.3 - Teste Alerta de Emergência
1. Logue como usuário **Liderança** (nível 1, 2 ou 3)
2. Vá para **Emergência** → **Criar Alerta**
3. Selecione tipo (PCR, O₂, etc.), localização
4. Publique
5. TODOS os usuários ativos devem receber notificação **vermelha**
6. Vibração deve ser mais intensa

### ✅ Critérios de Sucesso
- [ ] Mensagens de chat → azul
- [ ] Comunicados → amarelo
- [ ] Emergências → vermelho
- [ ] Cores corretas em foreground E background
- [ ] Funcionamento em Android E Web/PWA

---

## 🔧 Verificação de Canais Android

### Ver Canais Criados
1. No Android, vá para **Configurações** → **Apps** → **Conecta Saúde**
2. Toque em **Notificações**
3. Você deve ver 3 canais:
   - 📱 **Mensagens e Conversas** (Importância: Padrão)
   - 📢 **Comunicados e Alertas** (Importância: Alta)
   - 🚨 **Emergências Médicas** (Importância: Alta)

### Customizar por Canal
- Usuários podem definir som, vibração e comportamento diferentes para cada canal
- Isso permite personalização (ex: silenciar mensagens, mas manter emergências)

---

## 🐛 Troubleshooting

### Problema: Notificações não aparecem coloridas no Android
**Possíveis causas:**
- Android < 8.0 (canais não suportados)
- Tema do sistema pode afetar a visualização
- Modo de economia de energia pode desabilitar colorização

**Solução:**
- Testar em Android 9+ para melhor compatibilidade
- Verificar que `setColorized(true)` está aplicado no código Kotlin

### Problema: Notificações não chegam em background
**Possíveis causas:**
- App em "otimização de bateria"
- FCM token expirado
- Backend não está enviando campo `data.notificationType`

**Solução:**
- Desabilitar otimização de bateria para o app
- Verificar logs do backend: `[FCM Push]`
- Confirmar que payload FCM inclui `android.notification.color`

### Problema: Web não mostra badges coloridos
**Possíveis causas:**
- Navegador não suporta badges SVG
- Service Worker não registrado

**Solução:**
- Testar em Chrome/Edge mais recente
- Verificar console do navegador por erros
- Badge colorido é "best effort" - funcionalidade principal (notificação) sempre funciona

---

## 📊 Checklist Final de Validação

### Android
- [ ] Foreground: mensagem azul ✓
- [ ] Foreground: alerta amarelo ✓
- [ ] Foreground: emergência vermelho ✓
- [ ] Background: mensagem azul ✓
- [ ] Background: alerta amarelo ✓
- [ ] Background: emergência vermelho ✓
- [ ] 3 canais visíveis em Configurações ✓
- [ ] Vibrações diferentes por tipo ✓

### Web/PWA
- [ ] Notificações aparecem ✓
- [ ] Badge colorido para emergência ✓
- [ ] Badge colorido para alerta ✓
- [ ] Badge colorido para mensagem ✓
- [ ] requireInteraction para emergência ✓

### Backend
- [ ] Endpoint `/api/auth/test-push-typed` funciona ✓
- [ ] Mensagens incluem `notificationType: 'message'` ✓
- [ ] Comunicados incluem `notificationType: 'alert'` ✓
- [ ] Emergências incluem `notificationType: 'emergency'` ✓
- [ ] Cores corretas no payload FCM ✓

---

## 🎯 Resultado Esperado

Após todos os testes, o sistema deve:

✅ Diferenciar visualmente os 3 tipos de notificação através de cores
✅ Aplicar vibrações apropriadas ao nível de urgência
✅ Funcionar em foreground (app aberto) e background (app fechado)
✅ Funcionar em Android nativo e Web/PWA
✅ Permitir usuários customizarem comportamento por tipo de notificação
✅ Manter compatibilidade com fluxos reais de mensagens, comunicados e emergências

---

## 📞 Suporte

Em caso de dúvidas ou problemas nos testes:
1. Verificar logs do Flutter: `flutter logs`
2. Verificar logs do backend: seção `[FCM Push]`
3. Verificar logcat Android: `adb logcat | grep FCM`
4. Console do navegador para Web/PWA

**Data de criação:** 12/09/2026
**Versão:** 1.0
**Status:** Implementação completa ✅
