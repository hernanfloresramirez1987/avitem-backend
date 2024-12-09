import { DataSource, Repository } from 'typeorm';
import { Injectable } from '@nestjs/common';
import { Personas } from '../../modules/personas/entities/persona.entity';
import { Empleados } from '../../modules/empleados/entities/empleado.entity';

@Injectable() // here
export class EmpleadoRepository extends Repository<Empleados> {
  constructor(private dataSource: DataSource) {
    super(Personas, dataSource.createEntityManager());
  }
}