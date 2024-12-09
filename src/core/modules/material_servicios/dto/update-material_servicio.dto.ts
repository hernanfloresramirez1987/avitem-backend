import { PartialType } from '@nestjs/mapped-types';
import { CreateMaterialServicioDto } from './create-material_servicio.dto';

export class UpdateMaterialServicioDto extends PartialType(CreateMaterialServicioDto) {}
