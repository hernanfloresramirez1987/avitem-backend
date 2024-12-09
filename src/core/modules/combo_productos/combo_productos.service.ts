import { Injectable } from '@nestjs/common';
import { CreateComboProductoDto } from './dto/create-combo_producto.dto';
import { UpdateComboProductoDto } from './dto/update-combo_producto.dto';

@Injectable()
export class ComboProductosService {
  create(createComboProductoDto: CreateComboProductoDto) {
    return 'This action adds a new comboProducto';
  }

  findAll() {
    return `This action returns all comboProductos`;
  }

  findOne(id: number) {
    return `This action returns a #${id} comboProducto`;
  }

  update(id: number, updateComboProductoDto: UpdateComboProductoDto) {
    return `This action updates a #${id} comboProducto`;
  }

  remove(id: number) {
    return `This action removes a #${id} comboProducto`;
  }
}
