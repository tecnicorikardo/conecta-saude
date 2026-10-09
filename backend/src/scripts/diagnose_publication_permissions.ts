/**
 * Diagnóstico sem publicação: envia formulários vazios, rejeitados pelo Zod
 * antes de criar registros. Execute com uma sessão de Supervisão ativa.
 * Configure DIAGNOSTIC_ID_TOKEN no ambiente (nunca em arquivo versionado).
 * Uso, dentro de backend: npx tsx src/scripts/diagnose_publication_permissions.ts
 */
async function main(): Promise<void> {
  const token = process.env.DIAGNOSTIC_ID_TOKEN;
  if (!token) throw new Error('Configure DIAGNOSTIC_ID_TOKEN com uma sessão de Supervisão.');
  const base = process.env.DIAGNOSTIC_API_URL ?? 'https://conecta-saude-backende.onrender.com/api';
  const headers = { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' };
  const me = await fetch(`${base}/auth/me`, { headers, signal: AbortSignal.timeout(30_000) });
  const profile = await me.json() as { data?: { hierarquiaNivel?: number; ativo?: boolean } };
  // Não imprimir tokens, nome, e-mail ou o restante do cadastro.
  console.log({ route: '/auth/me', status: me.status, nivel: profile.data?.hierarquiaNivel });
  if (!me.ok || profile.data?.hierarquiaNivel !== 3 || !profile.data.ativo) {
    throw new Error('O diagnóstico exige uma conta ativa de Supervisão (nível 3).');
  }
  for (const route of ['/channels', '/announcements']) {
    const response = await fetch(`${base}${route}`, {
      method: 'POST', headers, body: '{}', signal: AbortSignal.timeout(30_000),
    });
    console.log({ route, status: response.status, esperado: 422 });
    // 422 é o resultado correto: autorização passou, formulário incompleto não.
    if (response.status !== 422) process.exitCode = 1;
  }
}

main().catch(() => {
  console.error('Diagnóstico interrompido. Verifique sessão, configuração e conexão.');
  process.exitCode = 1;
});
