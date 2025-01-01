import { Module } from '@nestjs/common';
import { ProveedoresService } from './proveedores.service';
import { ProveedoresController } from './proveedores.controller';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Proveedores } from './entities/proveedore.entity';
import { Personas } from '../personas/entities/persona.entity';
import { ProveedorRepository } from 'src/core/shared/repositories/ProveedorRep';

@Module({
  imports: [TypeOrmModule.forFeature([Proveedores, Personas])],
  controllers: [ProveedoresController],
  providers: [ProveedoresService, ProveedorRepository],
})
export class ProveedoresModule {}
