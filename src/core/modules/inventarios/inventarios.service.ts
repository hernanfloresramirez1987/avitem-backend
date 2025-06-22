import { Injectable } from '@nestjs/common';
import { CreateInventarioDto } from './dto/create-inventario.dto';
import { UpdateInventarioDto } from './dto/update-inventario.dto';
import { Repository } from 'typeorm';
import { InjectRepository } from '@nestjs/typeorm';
import { Inventarios } from './entities/inventario.entity';
import { applyWhere } from '../common/applyWhere';

@Injectable()
export class InventariosService {
  constructor(
    @InjectRepository(Inventarios)
    private inventarioRepository: Repository<Inventarios>
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

    console.log("Filter:    ", filter);
    const whereConditions = await applyWhere(filter.filter, this.inventarioRepository); // Aplica filtros

    const total_records = await this.inventarioRepository.count({ // Total sin paginar
      where: whereConditions,
    });

    const queryBuilder = this.inventarioRepository.createQueryBuilder('inventario')
      .innerJoinAndSelect('inventario.producto', 'producto')
      .innerJoinAndSelect('inventario.almacen', 'almacen')
      // .innerJoinAndSelect('producto.ventas', 'ventas')
      // .innerJoinAndSelect('producto.compras', 'compras')
      // .innerJoinAndSelect('producto.lote_producto', 'lote_producto');
    queryBuilder.where(whereConditions);

    console.log("SQL Generado:", queryBuilder.getSql()); // Muestra la SQL final

    const data = await queryBuilder.getMany();
  
    const resultado = data.map((item) => ({
      ...item,
      totalDisponible: item.cantidadStock - item.cantidadReservada,
      nombreProducto: item.producto?.nombre,
      nombreAlmacen: item.almacen?.nombre,
      cantidadStock: item.cantidadStock,
      cantidadReservada: item.cantidadReservada,
      cantidadDespachada: item.cantidadDespachada,
      fechaInventario: item.fechaInventario,  
      fechaIngreso: item.fechaIngreso,
      fechaSalida: item.fechaSalida,
      idProducto: item.producto?.id,
      idAlmacen: item.almacen?.id,
    }));
  
    console.log("Result:............................    ", resultado[0]);
  
    return {
      data: resultado,
      metadata: {
        page: page,
        rows: data.length,
        total_records: total_records,
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
