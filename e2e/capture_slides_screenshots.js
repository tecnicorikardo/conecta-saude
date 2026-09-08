const { chromium } = require('@playwright/test');
const fs = require('fs');
const path = require('path');

(async () => {
  const outputDir = path.join(__dirname, '..', 'apresentacao_assets');
  if (!fs.existsSync(outputDir)) {
    fs.mkdirSync(outputDir, { recursive: true });
  }

  console.log('[1/7] Iniciando navegador em alta resolução...');
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({
    viewport: { width: 1366, height: 768 },
    deviceScaleFactor: 1.5,
  });
  const page = await context.newPage();

  // 1. Tela de Login
  console.log('[2/7] Capturando Tela de Login...');
  await page.goto('https://conecta-hospital.web.app/login', { waitUntil: 'networkidle' });
  await page.waitForTimeout(3000);
  await page.screenshot({ path: path.join(outputDir, '01_login.png') });

  // Ativa acessibilidade
  await page.evaluate(() => {
    const el = document.querySelector('flt-semantics-placeholder');
    if (el) el.click();
  });
  await page.waitForTimeout(1000);

  // Faz Login
  console.log('[3/7] Efetuando Login Institucional...');
  const emailInput = page.locator('input[aria-label*="E-mail"]');
  const passwordInput = page.locator('input[aria-label*="Senha"]');
  const entrarBtn = page.locator('flt-semantics[role="button"]:has-text("ENTRAR")');

  await emailInput.click();
  await emailInput.fill('coord.cco@conectasaude.dev');
  await page.waitForTimeout(400);

  await passwordInput.click();
  await passwordInput.fill('ConectaSUS@2026');
  await page.waitForTimeout(600);

  await entrarBtn.click();
  await page.waitForURL('**/home', { timeout: 30000 });
  await page.waitForTimeout(3500);

  // 2. Tela Dashboard / Home
  console.log('[4/7] Capturando Dashboard Home...');
  await page.screenshot({ path: path.join(outputDir, '02_home.png') });

  // 3. Conversas / Chat
  console.log('[5/7] Capturando Lista de Conversas...');
  await page.goto('https://conecta-hospital.web.app/conversations');
  await page.waitForTimeout(3500);
  await page.screenshot({ path: path.join(outputDir, '03_conversas.png') });

  // 4. Canais Setoriais
  console.log('[6/7] Capturando Canais Setoriais...');
  await page.goto('https://conecta-hospital.web.app/channels');
  await page.waitForTimeout(3500);
  await page.screenshot({ path: path.join(outputDir, '04_canais.png') });

  // 5. Comunicados da Direção
  console.log('[7/7] Capturando Comunicados da Direção...');
  await page.goto('https://conecta-hospital.web.app/announcements');
  await page.waitForTimeout(3500);
  await page.screenshot({ path: path.join(outputDir, '05_comunicados.png') });

  console.log('✅ Todas as capturas foram salvas com sucesso em apresentacao_assets/');
  await browser.close();
})();
