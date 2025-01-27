import { DataSource, Repository } from 'typeorm';
import { Injectable } from '@nestjs/common';
import { Almacenes } from 'src/core/modules/almacenes/entities/almacene.entity';

@Injectable() // here
export class AlmacenRepository extends Repository<Almacenes> {
  constructor(private dataSource: DataSource) {
    super(Almacenes, dataSource.createEntityManager());
  }
}