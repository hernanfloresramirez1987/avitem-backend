import { DataSource, Repository } from 'typeorm';
import { Injectable } from '@nestjs/common';
import { Inventarios } from 'src/core/modules/inventarios/entities/inventario.entity';

@Injectable()
export class InventarioRepository extends Repository<Inventarios> {
  constructor(private dataSource: DataSource) {
    super(Inventarios, dataSource.createEntityManager());
  }
}