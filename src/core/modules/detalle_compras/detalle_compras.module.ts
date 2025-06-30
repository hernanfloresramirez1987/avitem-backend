import { Module } from '@nestjs/common';
import { DetalleComprasService } from './detalle_compras.service';
import { DetalleComprasController } from './detalle_compras.controller';
import { DetalleCompras } from './entities/detalle_compra.entity';
import { TypeOrmModule } from '@nestjs/typeorm';

@Module({
  imports: [TypeOrmModule.forFeature([DetalleCompras])],
  controllers: [DetalleComprasController],
  providers: [DetalleComprasService],
})
export class DetalleComprasModule {}
