import { PartialType } from '@nestjs/mapped-types';
import { CreateOrdenServicioDto } from './create-orden_servicio.dto';

export class UpdateOrdenServicioDto extends PartialType(CreateOrdenServicioDto) {}
