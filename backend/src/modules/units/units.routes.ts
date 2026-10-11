import { asyncHandler } from '../../utils/asyncHandler';
import { Router } from 'express';
import { listUnits, getUnit, createUnit, updateUnit } from './units.controller';
import { authenticate } from '../../middleware/authenticate';

export const unitsRouter = Router();

// Rota pública para seleção no cadastro
unitsRouter.get('/', asyncHandler(listUnits));
unitsRouter.get('/:id', asyncHandler(getUnit));

// Rotas protegidas (Gestão pela Direção)
unitsRouter.post('/', authenticate, asyncHandler(createUnit));
unitsRouter.put('/:id', authenticate, asyncHandler(updateUnit));
