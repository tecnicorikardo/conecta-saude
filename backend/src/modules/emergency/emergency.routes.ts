import { asyncHandler } from '../../utils/asyncHandler';
import { Router } from 'express';
import { authenticate } from '../../middleware/authenticate';
import {
  getActiveEmergency,
  createEmergencyAlert,
  resolveEmergencyAlert,
  listEmergencyHistory,
} from './emergency.controller';

const router = Router();

router.use(authenticate);

router.get('/active', asyncHandler(getActiveEmergency));
router.get('/history', asyncHandler(listEmergencyHistory));
router.post('/', asyncHandler(createEmergencyAlert));
router.patch('/:id/resolve', asyncHandler(resolveEmergencyAlert));

export { router as emergencyRouter };
