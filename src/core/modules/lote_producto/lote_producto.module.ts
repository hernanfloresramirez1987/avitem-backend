import { Module } from '@nestjs/common';
import { LoteProductoService } from './lote_producto.service';
import { LoteProductoController } from './lote_producto.controller';

@Module({
  controllers: [LoteProductoController],
  providers: [LoteProductoService],
})
export class LoteProductoModule {}
