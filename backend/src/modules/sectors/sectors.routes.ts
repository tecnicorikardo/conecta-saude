import { Router } from 'express';
import { authenticate } from '../../middleware/authenticate';
import { asyncHandler } from '../../utils/asyncHandler';
import { listSectors, createSector, updateSector } from './sectors.controller';

const router = Router();
router.use(authenticate);
router.get('/', asyncHandler(listSectors));
router.post('/', asyncHandler(createSector));
router.put('/:id', asyncHandler(updateSector));
export default router;
