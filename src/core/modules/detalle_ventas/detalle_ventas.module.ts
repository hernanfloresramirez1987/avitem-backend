import { Module } from '@nestjs/common';
import { DetalleVentasService } from './detalle_ventas.service';
import { DetalleVentasController } from './detalle_ventas.controller';

@Module({
  controllers: [DetalleVentasController],
  providers: [DetalleVentasService],
})
export class DetalleVentasModule {}
