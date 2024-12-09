import { Module } from '@nestjs/common';
import { OrdenServiciosService } from './orden_servicios.service';
import { OrdenServiciosController } from './orden_servicios.controller';

@Module({
  controllers: [OrdenServiciosController],
  providers: [OrdenServiciosService],
})
export class OrdenServiciosModule {}
