import { DataSource, Repository } from 'typeorm';
import { Injectable } from '@nestjs/common';
import { Productos } from 'src/core/modules/productos/entities/producto.entity';

@Injectable() // here
export class ProductoRepository extends Repository<Productos> {
  constructor(private dataSource: DataSource) {
    super(Productos, dataSource.createEntityManager());
  }
}