import { DataSource, Repository } from 'typeorm';
import { Injectable } from '@nestjs/common';
import { Categorias } from 'src/core/modules/categorias/entities/categoria.entity';

@Injectable() // here
export class CategoriaRepository extends Repository<Categorias> {
  constructor(private dataSource: DataSource) {
    super(Categorias, dataSource.createEntityManager());
  }
}