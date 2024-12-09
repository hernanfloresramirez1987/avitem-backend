import { DataSource, Repository } from 'typeorm';
import { Injectable } from '@nestjs/common';
import { Ventas } from 'src/core/modules/ventas/entities/venta.entity';

@Injectable() // here
export class VentaRepository extends Repository<Ventas> {
  constructor(private dataSource: DataSource) {
    super(Ventas, dataSource.createEntityManager());
  }
}