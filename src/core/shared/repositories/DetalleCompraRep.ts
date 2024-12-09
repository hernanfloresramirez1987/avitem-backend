import { DataSource, Repository } from 'typeorm';
import { Injectable } from '@nestjs/common';
import { DetalleCompras } from 'src/core/modules/detalle_compras/entities/detalle_compra.entity';

@Injectable() // here
export class DetalleCompraRepository extends Repository<DetalleCompras> {
  constructor(private dataSource: DataSource) {
    super(DetalleCompras, dataSource.createEntityManager());
  }
}