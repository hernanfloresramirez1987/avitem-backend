import { DataSource, Repository } from 'typeorm';
import { Injectable } from '@nestjs/common';
import { Combos } from 'src/core/modules/combos/entities/combo.entity';

@Injectable() // here
export class ComboRepository extends Repository<Combos> {
  constructor(private dataSource: DataSource) {
    super(Combos, dataSource.createEntityManager());
  }
}