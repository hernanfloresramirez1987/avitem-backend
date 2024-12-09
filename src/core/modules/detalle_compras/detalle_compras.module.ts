import { Module } from '@nestjs/common';
import { DetalleComprasService } from './detalle_compras.service';
import { DetalleComprasController } from './detalle_compras.controller';

@Module({
  controllers: [DetalleComprasController],
  providers: [DetalleComprasService],
})
export class DetalleComprasModule {}
