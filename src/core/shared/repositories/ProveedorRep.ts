import { DataSource, Repository } from 'typeorm';
import { Injectable } from '@nestjs/common';
import { Proveedores } from '../../modules/proveedores/entities/proveedore.entity';

@Injectable()
export class ProveedorRepository extends Repository<Proveedores> {
  constructor(private dataSource: DataSource) {
    super(Proveedores, dataSource.createEntityManager());
  }
}