import { Router } from 'express';
import { authenticate } from '../../middleware/authenticate';
import { asyncHandler } from '../../utils/asyncHandler';
import { listSectors, createSector, updateSector } from './sectors.controller';

const router = Router();

// Pública para listagem de unidades/setores no cadastro de novos servidores
router.get('/', asyncHandler(listSectors));
router.get('/public', asyncHandler(listSectors));

// Protegidas (Direção)
router.use(authenticate);
router.post('/', asyncHandler(createSector));
router.put('/:id', asyncHandler(updateSector));

export default router;
