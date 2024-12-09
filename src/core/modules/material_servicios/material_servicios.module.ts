import { Module } from '@nestjs/common';
import { MaterialServiciosService } from './material_servicios.service';
import { MaterialServiciosController } from './material_servicios.controller';

@Module({
  controllers: [MaterialServiciosController],
  providers: [MaterialServiciosService],
})
export class MaterialServiciosModule {}
