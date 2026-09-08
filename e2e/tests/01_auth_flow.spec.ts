import { test, expect } from '@playwright/test';
import { initFlutterPage, loginAs } from '../helpers/flutter';

test.describe('01 - Fluxo de Autenticação e Login SUS (Pente Fino)', () => {
  test('deve carregar a tela de login com elementos institucionais e campos de acesso', async ({ page }) => {
    await initFlutterPage(page, '/login');

    // O título deve conter Conecta Saúde
    await expect(page).toHaveTitle(/Conecta Saúde/i);

    // Campos de e-mail e senha identificados via semântica nativa
    const emailInput = page.locator('input[aria-label*="E-mail"]');
    const passwordInput = page.locator('input[aria-label*="Senha"]');
    const entrarBtn = page.locator('flt-semantics[role="button"]:has-text("ENTRAR")');

    await expect(emailInput).toBeVisible({ timeout: 15000 });
    await expect(passwordInput).toBeVisible({ timeout: 15000 });
    await expect(entrarBtn).toBeVisible({ timeout: 15000 });
  });

  test('deve rejeitar credenciais inválidas e permanecer na tela de login', async ({ page }) => {
    await initFlutterPage(page, '/login');

    const emailInput = page.locator('input[aria-label*="E-mail"]');
    const passwordInput = page.locator('input[aria-label*="Senha"]');
    const entrarBtn = page.locator('flt-semantics[role="button"]:has-text("ENTRAR")');

    await emailInput.click();
    await emailInput.fill('usuario.invalido@conectasaude.dev');
    await page.waitForTimeout(400);

    await passwordInput.click();
    await passwordInput.fill('SenhaErrada123!');
    await page.waitForTimeout(600);

    await entrarBtn.click();

    // Aguarda tentativa de autenticação
    await page.waitForTimeout(3500);

    // Deve permanecer na tela de login
    expect(page.url()).toContain('/login');
  });

  test('deve autenticar coordenador com sucesso e redirecionar para o dashboard /home', async ({ page }) => {
    await loginAs(page, 'coord.cco@conectasaude.dev', 'ConectaSUS@2026');
    expect(page.url()).toContain('/home');
  });
});
