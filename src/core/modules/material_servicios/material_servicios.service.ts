import { Injectable } from '@nestjs/common';
import { CreateMaterialServicioDto } from './dto/create-material_servicio.dto';
import { UpdateMaterialServicioDto } from './dto/update-material_servicio.dto';

@Injectable()
export class MaterialServiciosService {
  create(createMaterialServicioDto: CreateMaterialServicioDto) {
    return 'This action adds a new materialServicio';
  }

  findAll() {
    return `This action returns all materialServicios`;
  }

  findOne(id: number) {
    return `This action returns a #${id} materialServicio`;
  }

  update(id: number, updateMaterialServicioDto: UpdateMaterialServicioDto) {
    return `This action updates a #${id} materialServicio`;
  }

  remove(id: number) {
    return `This action removes a #${id} materialServicio`;
  }
}
