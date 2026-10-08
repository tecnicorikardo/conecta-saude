# 🏥 Conecta Saúde (SUS) — Documentação Oficial de Contas e Serviços

> **Documento Confidencial Interno**  
> Este arquivo centraliza o mapeamento de todas as contas, painéis de nuvem e formas de acesso utilizadas pela infraestrutura do sistema **Conecta Saúde**.

---

## 🗺️ Mapa Rápido de Acessos

| Serviço | Função | Conta / Login de Acesso | Painel / URL Direta |
| :--- | :--- | :--- | :--- |
| **Supabase** | Banco de Dados PostgreSQL Principal | **Mesmo login utilizado no ChatGPT (SSO / Google)** | [Dashboard do Projeto](https://supabase.com/dashboard/project/sxviipihvpkggukyfcfj) |
| **Render** | Backend API (Node.js/Express) | **`rikardomartinssantos@gmail.com`** | [Dashboard do Render](https://dashboard.render.com/) |
| **Firebase Console** | Autenticação, Web Push (FCM) e Hosting | **`tecnicorikardo@gmail.com`** (ou Google Principal) | [Console Firebase](https://console.firebase.google.com/) |
| **GitHub** | Repositório de Código-Fonte | Usuário: **`tecnicorikardo`** | [Repositório conecta-saude](https://github.com/tecnicorikardo/conecta-saude) |

---

## 🟢 1. Supabase (Banco de Dados PostgreSQL)

* **URL Direta do Projeto:** 👉 [https://supabase.com/dashboard/project/sxviipihvpkggukyfcfj](https://supabase.com/dashboard/project/sxviipihvpkggukyfcfj)
* **Método de Entrada:** Faça login com as **mesmas credenciais utilizadas para acessar o ChatGPT** (Login social Google / SSO).
* **Project Reference ID:** `sxviipihvpkggukyfcfj`
* **Região dos Servidores:** `aws-0-us-west-2` (Oregon, EUA)
* **Usuário do Banco:** `postgres.sxviipihvpkggukyfcfj`
* **Hosts do Connection Pooler:**
  * **Session Pooler (Porta 5432):** `aws-0-us-west-2.pooler.supabase.com:5432`
  * **Transaction Pooler (Porta 6543):** `aws-0-us-west-2.pooler.supabase.com:6543`
* **Onde gerenciar senhas:** No painel do projeto $\rightarrow$ **Project Settings** $\rightarrow$ **Database** $\rightarrow$ **Database Password**.

---

## 🟣 2. Render (Backend Node.js API)

* **URL do Painel:** 👉 [https://dashboard.render.com/](https://dashboard.render.com/)
* **Conta de Acesso:** **`rikardomartinssantos@gmail.com`**
* **Nome do Serviço Web:** `conecta-saude-backende`
* **URL Pública da API:** `https://conecta-saude-backende.onrender.com/api`
* **Healthcheck:** `https://conecta-saude-backende.onrender.com/health`
* **Repositório Conectado:** `tecnicorikardo/conecta-saude` (Branch `main`, subpasta `backend`)
* **Variáveis de Ambiente Críticas configuradas no Render:**
  * `DATABASE_URL` (String de conexão do Supabase)
  * `FIREBASE_PROJECT_ID` (`conecta-hospital`)
  * `FIREBASE_CLIENT_EMAIL` (`firebase-adminsdk-fbsvc@conecta-hospital.iam.gserviceaccount.com`)
  * `FIREBASE_PRIVATE_KEY` (Chave privada do Firebase Admin)
  * `NODE_ENV` (`production`)

---

## 🟡 3. Firebase Console (Auth, FCM e Hosting)

* **URL do Console:** 👉 [https://console.firebase.google.com/](https://console.firebase.google.com/)
* **Conta de Acesso:** Conta Google (`tecnicorikardo@gmail.com`)
* **ID do Projeto:** `conecta-hospital`
* **Serviços Ativos:**
  * **Firebase Hosting (App Web / PWA):** [https://conecta-hospital.web.app](https://conecta-hospital.web.app)
  * **Firebase Hosting (Slides):** [https://slide-conecta-hospital.web.app](https://slide-conecta-hospital.web.app)
  * **Firebase Authentication:** Gestão de login dos profissionais de saúde
  * **Firebase Cloud Messaging:** Web Push notifications em tempo real
* **Onde gerenciar chaves de serviço:** Configurações do Projeto $\rightarrow$ **Contas de Serviço** (*Service accounts*) $\rightarrow$ Gerar nova chave privada.

---

## 🐙 4. GitHub (Código-Fonte e Versionamento)

* **URL do Repositório:** 👉 [https://github.com/tecnicorikardo/conecta-saude](https://github.com/tecnicorikardo/conecta-saude)
* **Usuário:** `tecnicorikardo` (Ricardo Martins)
* **Branch Principal de Deploy:** `main`

---

## ⚠️ Cuidados de Segurança Operacional

1. **Nunca versionar arquivos com senhas:** Os arquivos `.env` e chaves `.json` devem permanecer exclusivamente no computador local e nos painéis oficiais do Render.
2. **Atualização de senhas:** Sempre que alterar a senha do banco no **Supabase**, lembre-se de atualizar imediatamente a variável `DATABASE_URL` no painel do **Render**.
