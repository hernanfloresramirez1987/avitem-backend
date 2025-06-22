import { Module } from '@nestjs/common';
import { ProveedoresService } from './proveedores.service';
import { ProveedoresController } from './proveedores.controller';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Proveedores } from './entities/proveedore.entity';
import { Personas } from '../personas/entities/persona.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Proveedores, Personas])],
  controllers: [ProveedoresController],
  providers: [ProveedoresService],
})
export class ProveedoresModule {}
