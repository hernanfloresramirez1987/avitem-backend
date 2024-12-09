import { DataSource, Repository } from 'typeorm';
import { Injectable } from '@nestjs/common';
import { Usuarios } from '../../modules/usuarios/entities/usuario.entity';

@Injectable() // here
export class UsuarioRepository extends Repository<Usuarios> {
  constructor(private dataSource: DataSource) {
    super(Usuarios, dataSource.createEntityManager());
  }
}