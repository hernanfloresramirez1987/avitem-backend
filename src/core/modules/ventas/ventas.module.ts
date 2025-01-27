import { Module } from '@nestjs/common';
import { VentasService } from './ventas.service';
import { VentasController } from './ventas.controller';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Ventas } from './entities/venta.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Ventas])],
  controllers: [VentasController],
  providers: [VentasService],
})
export class VentasModule {}
