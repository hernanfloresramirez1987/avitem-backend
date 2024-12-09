import { Module } from '@nestjs/common';
import { VentaCombosService } from './venta_combos.service';
import { VentaCombosController } from './venta_combos.controller';

@Module({
  controllers: [VentaCombosController],
  providers: [VentaCombosService],
})
export class VentaCombosModule {}
