import { PartialType } from '@nestjs/mapped-types';
import { CreateLoteProductoDto } from './create-lote_producto.dto';

export class UpdateLoteProductoDto extends PartialType(CreateLoteProductoDto) {}
