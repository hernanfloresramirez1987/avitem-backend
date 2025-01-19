import { DataSource, Repository } from 'typeorm';
import { Injectable } from '@nestjs/common';
import { Colores } from 'src/core/modules/colores/entities/color.entity';

@Injectable() // here
export class ColorRepository extends Repository<Colores> {
  constructor(private dataSource: DataSource) {
    super(Colores, dataSource.createEntityManager());
  }
}