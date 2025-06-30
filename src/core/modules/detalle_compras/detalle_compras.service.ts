import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Connection, Repository } from 'typeorm';
import { DetalleCompras } from './entities/detalle_compra.entity';
import { CreateDetalleCompraDto } from './dto/create-detalle_compra.dto';
import { UpdateDetalleCompraDto } from './dto/update-detalle_compra.dto';

@Injectable()
export class DetalleComprasService {
  constructor(
    @InjectRepository(DetalleCompras)
    private readonly detalleComprasRepository: Repository<DetalleCompras>,
    private readonly connection: Connection
  ) {}

  create(createDetalleCompraDto: CreateDetalleCompraDto) {
    return 'This action adds a new detalleCompra';
  }

  async findAllOne(id: number) {
    return this.detalleComprasRepository.find({
      where: {
        compra: { id }, // hace referencia al id de la entidad relacionada
      },
      relations: ['compra', 'producto'], // opcional: para incluir más relaciones si necesitas
    });
  }

  findAll() {
    return `This action returns all detalleCompras`;
  }

  findOne(id: number) {
    return `This action returns a #${id} detalleCompra`;
  }

  update(id: number, updateDetalleCompraDto: UpdateDetalleCompraDto) {
    return `This action updates a #${id} detalleCompra`;
  }

  remove(id: number) {
    return `This action removes a #${id} detalleCompra`;
  }
}
