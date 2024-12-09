import { DataSource, Repository } from 'typeorm';
import { Injectable } from '@nestjs/common';
import { VentaCombos } from 'src/core/modules/venta_combos/entities/venta_combo.entity';

@Injectable()
export class VentaComboRepository extends Repository<VentaCombos> {
  constructor(private dataSource: DataSource) {
    super(VentaCombos, dataSource.createEntityManager());
  }
}