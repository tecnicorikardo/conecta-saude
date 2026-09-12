/**
 * Utilitário para verificar se um usuário está em horário de serviço/plantão
 */
export function isUserCurrentlyWorking(user: {
  jornadaInicio?: string | null;
  jornadaFim?: string | null;
  jornadaDias?: string | null;
  emPlantaoExtra?: boolean | null;
  ativo?: boolean | null;
}): boolean {
  if (user.emPlantaoExtra) return true;
  if (user.ativo === false) return false;

  const now = new Date();
  const dayCodes = ['dom', 'seg', 'ter', 'qua', 'qui', 'sex', 'sab'];
  const todayCode = dayCodes[now.getDay()];
  const dias = (user.jornadaDias ?? 'seg,ter,qua,qui,sex')
    .toLowerCase()
    .split(',')
    .map(d => d.trim());

  if (!dias.includes(todayCode)) {
    return false;
  }

  const startParts = (user.jornadaInicio ?? '07:00')
    .split(':')
    .map(e => parseInt(e, 10) || 0);
  const endParts = (user.jornadaFim ?? '16:00')
    .split(':')
    .map(e => parseInt(e, 10) || 0);

  const startMinutes = (startParts[0] ?? 7) * 60 + (startParts[1] ?? 0);
  const endMinutes = (endParts[0] ?? 16) * 60 + (endParts[1] ?? 0);
  const nowMinutes = now.getHours() * 60 + now.getMinutes();

  if (endMinutes >= startMinutes) {
    return nowMinutes >= startMinutes && nowMinutes <= endMinutes;
  } else {
    // Jornada noturna que cruza a meia-noite (ex: 19:00 às 07:00)
    return nowMinutes >= startMinutes || nowMinutes <= endMinutes;
  }
}