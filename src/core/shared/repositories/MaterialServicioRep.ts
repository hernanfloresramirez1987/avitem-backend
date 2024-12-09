import { DataSource, Repository } from 'typeorm';
import { Injectable } from '@nestjs/common';
import { MaterialServicios } from 'src/core/modules/material_servicios/entities/material_servicio.entity';

@Injectable() // here
export class MaterialServicioRepository extends Repository<MaterialServicios> {
  constructor(private dataSource: DataSource) {
    super(MaterialServicios, dataSource.createEntityManager());
  }
}