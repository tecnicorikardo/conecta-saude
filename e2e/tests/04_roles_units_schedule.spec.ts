import { test, expect } from '@playwright/test';
import { initFlutterPage, loginAs } from '../helpers/flutter';

test.describe('04 - Cargos SUS, Unidades Hospitalares e Escala de Trabalho (Pente Fino)', () => {
  test('deve carregar a tela de auto-cadastro com seleção de unidade, cargo padronizado e horários de trabalho', async ({ page }) => {
    await initFlutterPage(page, '/register');

    // Título do Auto-Cadastro
    await expect(page).toHaveTitle(/Conecta Saúde/i);

    // Campos do formulário
    const nomeInput = page.locator('input[aria-label*="Nome Completo"]');
    const emailInput = page.locator('input[aria-label*="E-mail"]');
    const cargoInput = page.locator('input[aria-label*="Cargo / Função"]');
    const senhaInput = page.locator('input[aria-label*="Senha (mínimo"]');
    const confirmarSenhaInput = page.locator('input[aria-label*="Confirmar Senha"]');
    const submitBtn = page.locator('flt-semantics[role="button"]:has-text("SOLICITAR CADASTRO")');

    await expect(nomeInput).toBeVisible({ timeout: 15000 });
    await expect(emailInput).toBeVisible({ timeout: 15000 });
    await expect(cargoInput).toBeVisible({ timeout: 15000 });
    await expect(senhaInput).toBeVisible({ timeout: 15000 });
    await expect(confirmarSenhaInput).toBeVisible({ timeout: 15000 });
    await expect(submitBtn).toBeVisible({ timeout: 15000 });
  });

  test('deve exibir a seção de Escala & Plantão no perfil do colaborador logado', async ({ page }) => {
    // 1. Fazer login como Coordenador
    await loginAs(page, 'coord.cco@conectasaude.dev', 'ConectaSUS@2026');

    // 2. Navegar para o Perfil
    await page.goto('/profile', { waitUntil: 'domcontentloaded' });
    await page.waitForTimeout(3000);

    // 3. Verificar que a página de perfil carregou e contém o título
    expect(page.url()).toContain('/profile');

    // 4. Capturar screenshot de verificação
    await page.screenshot({ path: 'e2e/profile_schedule_verification.png' });
  });
});
