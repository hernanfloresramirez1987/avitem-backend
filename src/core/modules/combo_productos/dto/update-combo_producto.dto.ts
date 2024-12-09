import { PartialType } from '@nestjs/mapped-types';
import { CreateComboProductoDto } from './create-combo_producto.dto';

export class UpdateComboProductoDto extends PartialType(CreateComboProductoDto) {}
