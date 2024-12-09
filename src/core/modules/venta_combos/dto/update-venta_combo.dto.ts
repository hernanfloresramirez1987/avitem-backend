import { PartialType } from '@nestjs/mapped-types';
import { CreateVentaComboDto } from './create-venta_combo.dto';

export class UpdateVentaComboDto extends PartialType(CreateVentaComboDto) {}
