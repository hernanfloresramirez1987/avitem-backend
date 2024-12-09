import { DataSource, Repository } from 'typeorm';
import { Injectable } from '@nestjs/common';
import { Clientes } from 'src/core/modules/clientes/entities/cliente.entity';

@Injectable() // here
export class ClienteRepository extends Repository<Clientes> {
  constructor(private dataSource: DataSource) {
    super(Clientes, dataSource.createEntityManager());
  }
}