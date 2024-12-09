import { PartialType } from '@nestjs/mapped-types';
import { CreateTransaccionContableDto } from './create-transaccion_contable.dto';

export class UpdateTransaccionContableDto extends PartialType(CreateTransaccionContableDto) {}
