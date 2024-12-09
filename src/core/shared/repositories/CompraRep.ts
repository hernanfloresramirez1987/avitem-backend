import { DataSource, Repository } from 'typeorm';
import { Injectable } from '@nestjs/common';
import { Compras } from 'src/core/modules/compras/entities/compra.entity';

@Injectable() // here
export class CompraRepository extends Repository<Compras> {
  constructor(private dataSource: DataSource) {
    super(Compras, dataSource.createEntityManager());
  }
}