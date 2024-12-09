import { Injectable } from '@nestjs/common';
import { CreateTransaccionContableDto } from './dto/create-transaccion_contable.dto';
import { UpdateTransaccionContableDto } from './dto/update-transaccion_contable.dto';

@Injectable()
export class TransaccionContablesService {
  create(createTransaccionContableDto: CreateTransaccionContableDto) {
    return 'This action adds a new transaccionContable';
  }

  findAll() {
    return `This action returns all transaccionContables`;
  }

  findOne(id: number) {
    return `This action returns a #${id} transaccionContable`;
  }

  update(id: number, updateTransaccionContableDto: UpdateTransaccionContableDto) {
    return `This action updates a #${id} transaccionContable`;
  }

  remove(id: number) {
    return `This action removes a #${id} transaccionContable`;
  }
}
