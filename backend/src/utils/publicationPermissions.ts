import { AuthenticatedUser, HierarquiaNivel } from '../types';

/** Autor pode excluir mesmo após mudança de cargo; Direção pode excluir qualquer publicação. */
export function canDeletePublication(actor: AuthenticatedUser, createdBy: string): boolean {
  return actor.ativo && (actor.id === createdBy || actor.hierarquiaNivel === HierarquiaNivel.DIRECAO);
}
