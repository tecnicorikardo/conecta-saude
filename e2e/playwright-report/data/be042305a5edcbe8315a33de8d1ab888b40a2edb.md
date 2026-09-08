# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: 02_navigation_and_console.spec.ts >> 02 - Navegação e Varredura de Erros de Console (Pente Fino) >> deve navegar pelas rotas principais sem disparar exceções de runtime, CORS ou erros 422/500
- Location: tests\02_navigation_and_console.spec.ts:5:7

# Error details

```
Error: expect(received).toContain(expected) // indexOf

Expected substring: "/home"
Received string:    "https://conecta-hospital.web.app/login"

Call Log:
- Timeout 30000ms exceeded while waiting on the predicate
```

# Page snapshot

```yaml
- generic [ref=e4] [cursor=pointer]:
  - generic:
    - generic:
      - generic:
        - generic:
          - group:
            - generic [ref=e6]: CONECTA SAÚDE
            - generic [ref=e7]: Sistema Integrado de Comunicação Institucional SUS
            - generic:
              - generic [ref=e8]: Bem-vindo
              - generic [ref=e9]: Entre com seu e-mail institucional para continuar.
              - textbox "E-mail institucional" [ref=e11]: coord.cco@conectasaude.dev
              - generic [ref=e12]:
                - textbox "Senha" [invalid] [ref=e13]
                - button "Mostrar senha" [ref=e14]
                - generic [ref=e15]: Informe sua senha.
              - group "Lembrar login e senha" [ref=e16]:
                - checkbox [checked] [ref=e17]
              - button "Esqueci minha senha" [ref=e18]
              - button "ENTRAR" [active] [ref=e19]
              - generic [ref=e20]: OU
              - button "Primeiro Acesso? Cadastre-se" [ref=e21]
              - generic [ref=e22]: Ambiente institucional • Acesso restrito
              - generic [ref=e23]: Comunicações monitoradas conforme política do SUS.
            - generic [ref=e24]: Conecta Saúde • SUS © 2026
```

# Test source

```ts
  1  | import { Page, expect } from '@playwright/test';
  2  | 
  3  | /**
  4  |  * Inicializa a página Flutter Web e ativa a camada de acessibilidade semântica
  5  |  * permitindo que o Playwright interaja diretamente com inputs, botões e labels.
  6  |  */
  7  | export async function initFlutterPage(page: Page, path: string = '/') {
  8  |   await page.goto(path, { waitUntil: 'networkidle' });
  9  |   await page.waitForTimeout(2500);
  10 | 
  11 |   // Ativa a semântica do Flutter Web clicando no placeholder de acessibilidade
  12 |   await page.waitForFunction(() => {
  13 |     const el = document.querySelector('flt-semantics-placeholder') as HTMLElement | null;
  14 |     if (el) {
  15 |       el.click();
  16 |       return true;
  17 |     }
  18 |     return false;
  19 |   }, { timeout: 15000 }).catch(() => {});
  20 | 
  21 |   await page.waitForTimeout(1200);
  22 | }
  23 | 
  24 | /**
  25 |  * Realiza o login institucional e aguarda redirecionamento para /home
  26 |  */
  27 | export async function loginAs(
  28 |   page: Page,
  29 |   email: string = 'coord.cco@conectasaude.dev',
  30 |   password: string = 'ConectaSUS@2026'
  31 | ) {
  32 |   await initFlutterPage(page, '/login');
  33 | 
  34 |   const emailInput = page.locator('input[aria-label*="E-mail"]');
  35 |   const passwordInput = page.locator('input[aria-label*="Senha"]');
  36 |   const entrarBtn = page.locator('flt-semantics[role="button"]:has-text("ENTRAR")');
  37 | 
  38 |   await emailInput.waitFor({ state: 'visible', timeout: 15000 });
  39 |   await emailInput.click();
  40 |   await emailInput.fill(email);
  41 |   await page.waitForTimeout(400);
  42 | 
  43 |   await passwordInput.waitFor({ state: 'visible', timeout: 15000 });
  44 |   await passwordInput.click();
  45 |   await passwordInput.fill(password);
  46 |   await page.waitForTimeout(600);
  47 | 
  48 |   await entrarBtn.click();
  49 | 
  50 |   // Aguarda transição para /home com timeout estendido para conexões lentas
> 51 |   await expect.poll(() => page.url(), { timeout: 30000 }).toContain('/home');
     |                                                           ^ Error: expect(received).toContain(expected) // indexOf
  52 |   await page.waitForTimeout(2000);
  53 | }
  54 | 
```