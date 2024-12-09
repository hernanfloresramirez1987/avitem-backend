import { DataSource, Repository } from 'typeorm';
import { Injectable } from '@nestjs/common';
import { DetalleVentas } from 'src/core/modules/detalle_ventas/entities/detalle_venta.entity';

@Injectable() // here
export class DetalleVentaRepository extends Repository<DetalleVentas> {
  constructor(private dataSource: DataSource) {
    super(DetalleVentas, dataSource.createEntityManager());
  }
}