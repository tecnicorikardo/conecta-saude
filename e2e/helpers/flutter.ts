import { Page, expect } from '@playwright/test';

/**
 * Inicializa a página Flutter Web e ativa a camada de acessibilidade semântica
 * permitindo que o Playwright interaja diretamente com inputs, botões e labels.
 */
export async function initFlutterPage(page: Page, path: string = '/') {
  await page.goto(path, { waitUntil: 'networkidle' });
  await page.waitForTimeout(2500);

  // Ativa a semântica do Flutter Web clicando no placeholder de acessibilidade
  await page.waitForFunction(() => {
    const el = document.querySelector('flt-semantics-placeholder') as HTMLElement | null;
    if (el) {
      el.click();
      return true;
    }
    return false;
  }, { timeout: 15000 }).catch(() => {});

  await page.waitForTimeout(1200);
}

/**
 * Realiza o login institucional e aguarda redirecionamento para /home
 */
export async function loginAs(
  page: Page,
  email: string = 'coord.cco@conectasaude.dev',
  password: string = 'ConectaSUS@2026'
) {
  await initFlutterPage(page, '/login');

  const emailInput = page.locator('input[aria-label*="E-mail"]');
  const passwordInput = page.locator('input[aria-label*="Senha"]');
  const entrarBtn = page.locator('flt-semantics[role="button"]:has-text("ENTRAR")');

  await emailInput.waitFor({ state: 'visible', timeout: 15000 });
  await emailInput.click();
  await emailInput.fill(email);
  await page.waitForTimeout(400);

  await passwordInput.waitFor({ state: 'visible', timeout: 15000 });
  await passwordInput.click();
  await passwordInput.fill(password);
  await page.waitForTimeout(600);

  await entrarBtn.click();

  // Aguarda transição para /home com timeout estendido para conexões lentas
  await expect.poll(() => page.url(), { timeout: 30000 }).toContain('/home');
  await page.waitForTimeout(2000);
}
