-- AddEmServicoField
-- Adiciona campo booleano para controle manual de status "Em Serviço"
-- Substitui o cálculo automático baseado em jornada que causava inconsistências

-- Adicionar coluna em_servico (padrão true = em serviço)
ALTER TABLE "users" ADD COLUMN "em_servico" BOOLEAN NOT NULL DEFAULT true;

-- Criar índice para consultas rápidas de usuários em serviço
CREATE INDEX "users_em_servico_idx" ON "users"("em_servico");

-- Comentário explicativo
COMMENT ON COLUMN "users"."em_servico" IS 'Status manual do usuário: true=Em Serviço, false=Fora de Serviço. Controlado por toggle no app.';
