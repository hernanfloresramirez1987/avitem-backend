import { Injectable } from '@nestjs/common';
import { CreateInventarioDto } from './dto/create-inventario.dto';
import { UpdateInventarioDto } from './dto/update-inventario.dto';
import { Connection, Like } from 'typeorm';
import { InjectRepository } from '@nestjs/typeorm';
import { Inventarios } from './entities/inventario.entity';
import { InventarioRepository } from 'src/core/shared/repositories/inventarioRep';
import { applyWhere } from '../common/applyWhere';

@Injectable()
export class InventariosService {
  constructor(
    @InjectRepository(Inventarios)
    private inventarioRepository: InventarioRepository,
    private readonly connection: Connection
  ) {}
  

  create(createInventarioDto: CreateInventarioDto) {
    return 'This action adds a new inventario';
  }

  findAll() {
    return `This action returns all inventarios`;
  }

  async findAllFilter(filter: any) {
    const page = filter.page ? parseInt(filter.page) : 1;
    const rows = filter.rows ? parseInt(filter.rows) : 10;
    const skip = (page - 1) * rows;

    // Aplica filtros
    const whereConditions = await applyWhere(filter, 'id', this.inventarioRepository);
    // Total sin paginar
    const total_records = await this.inventarioRepository.count({
      where: whereConditions,
    });

    const data = await this.inventarioRepository.find({ relations: ['producto', 'almacen'] });

    const resultado = data.map((item) => ({
      ...item,
      totalDisponible: item.cantidadStock - item.cantidadReservada,
      nombreProducto: item.producto?.nombre,
      nombreAlmacen: item.almacen?.nombre,
    }));
  
    console.log("Result:    ", data);
  
    return {
      data,
      metadata: {
        page: page,
        rows: data.length,
        totals: total_records,
      }
    };
  }

  findOne(id: number) {
    return `This action returns a #${id} inventario`;
  }

  update(id: number, updateInventarioDto: UpdateInventarioDto) {
    return `This action updates a #${id} inventario`;
  }

  remove(id: number) {
    return `This action removes a #${id} inventario`;
  }
}
