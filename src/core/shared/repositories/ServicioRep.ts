import { DataSource, Repository } from 'typeorm';
import { Injectable } from '@nestjs/common';
import { Servicios } from 'src/core/modules/servicios/entities/servicio.entity';

@Injectable()
export class ServicioRepository extends Repository<Servicios> {
  constructor(private dataSource: DataSource) {
    super(Servicios, dataSource.createEntityManager());
  }
}