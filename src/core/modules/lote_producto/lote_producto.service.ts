import { Injectable } from '@nestjs/common';
import { CreateLoteProductoDto } from './dto/create-lote_producto.dto';
import { UpdateLoteProductoDto } from './dto/update-lote_producto.dto';

@Injectable()
export class LoteProductoService {
  create(createLoteProductoDto: CreateLoteProductoDto) {
    return 'This action adds a new loteProducto';
  }

  findAll() {
    return `This action returns all loteProducto`;
  }

  findOne(id: number) {
    return `This action returns a #${id} loteProducto`;
  }

  update(id: number, updateLoteProductoDto: UpdateLoteProductoDto) {
    return `This action updates a #${id} loteProducto`;
  }

  remove(id: number) {
    return `This action removes a #${id} loteProducto`;
  }
}
