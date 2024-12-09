import { Injectable } from '@nestjs/common';
import { CreateVentaComboDto } from './dto/create-venta_combo.dto';
import { UpdateVentaComboDto } from './dto/update-venta_combo.dto';

@Injectable()
export class VentaCombosService {
  create(createVentaComboDto: CreateVentaComboDto) {
    return 'This action adds a new ventaCombo';
  }

  findAll() {
    return `This action returns all ventaCombos`;
  }

  findOne(id: number) {
    return `This action returns a #${id} ventaCombo`;
  }

  update(id: number, updateVentaComboDto: UpdateVentaComboDto) {
    return `This action updates a #${id} ventaCombo`;
  }

  remove(id: number) {
    return `This action removes a #${id} ventaCombo`;
  }
}
