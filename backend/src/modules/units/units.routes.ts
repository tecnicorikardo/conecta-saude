import { Router } from 'express';
import { listUnits, getUnit, createUnit, updateUnit } from './units.controller';
import { authenticate } from '../../middleware/authenticate';

export const unitsRouter = Router();

// Rota pública para seleção no cadastro
unitsRouter.get('/', listUnits);
unitsRouter.get('/:id', getUnit);

// Rotas protegidas (Gestão pela Direção)
unitsRouter.post('/', authenticate, createUnit);
unitsRouter.put('/:id', authenticate, updateUnit);
