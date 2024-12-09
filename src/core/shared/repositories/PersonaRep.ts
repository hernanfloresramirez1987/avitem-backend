import { DataSource, Repository } from 'typeorm';
import { Injectable } from '@nestjs/common';
import { Personas } from '../../modules/personas/entities/persona.entity';

@Injectable() // here
export class PersonaRepository extends Repository<Personas> {
  constructor(private dataSource: DataSource) {
    super(Personas, dataSource.createEntityManager());
  }
}