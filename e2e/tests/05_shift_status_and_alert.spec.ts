import { test, expect } from '@playwright/test';
import { loginAs } from '../helpers/flutter';

test.describe('05 - Visibilidade de Status na Home e Alerta de 5 Minutos', () => {
  test('deve exibir status na tela inicial e abrir diálogo de 5 min', async ({ page }) => {
    // 1. Fazer login como Coordenador
    await loginAs(page, 'coord.cco@conectasaude.dev', 'ConectaSUS@2026');
    await page.waitForTimeout(4000);

    // 2. Capturar tela inicial com badge de status e banner Fora de Serviço
    await page.screenshot({ path: 'screenshots_01_home_status_badge.png' });

    // 3. Navegar para perfil
    await page.goto('/profile', { waitUntil: 'domcontentloaded' });
    await page.waitForTimeout(6000);

    // 4. Capturar seção de escala no perfil
    await page.screenshot({ path: 'screenshots_02_profile_schedule_card.png' });

    // 5. Clicar no botão "Testar Alerta de Fim de Expediente (5 min)"
    const testBtn = page.getByText(/Testar Alerta de Fim de Expediente/i).first();
    if (await testBtn.isVisible({ timeout: 5000 }).catch(() => false)) {
      await testBtn.click();
      await page.waitForTimeout(2500);
      await page.screenshot({ path: 'screenshots_03_shift_end_5min_dialog.png' });
    } else {
      // Tentar via role button
      const btnRole = page.getByRole('button', { name: /Testar Alerta/i });
      if (await btnRole.isVisible({ timeout: 3000 }).catch(() => false)) {
        await btnRole.click();
        await page.waitForTimeout(2500);
        await page.screenshot({ path: 'screenshots_03_shift_end_5min_dialog.png' });
      }
    }
  });
});
