import { Module } from '@nestjs/common';
import { EmpleadosService } from './empleados.service';
import { EmpleadosController } from './empleados.controller';
import { EmpleadoRepository } from 'src/core/shared/repositories/EmpleadoRep';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Empleados } from './entities/empleado.entity';
import { Personas } from '../personas/entities/persona.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([Empleados, Personas]), // Registra las entidades
  ],
  controllers: [EmpleadosController],
  providers: [EmpleadosService, EmpleadoRepository],
})
export class EmpleadosModule {}
