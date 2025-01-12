import { Module } from '@nestjs/common';
import { EmpleadosService } from './empleados.service';
import { EmpleadosController } from './empleados.controller';
import { EmpleadoRepository } from 'src/core/shared/repositories/EmpleadoRep';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Empleados } from './entities/empleado.entity';
import { Personas } from '../personas/entities/persona.entity';
import { Usuarios } from '../usuarios/entities/usuario.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Empleados, Personas, Usuarios])],
  controllers: [EmpleadosController],
  providers: [EmpleadosService, EmpleadoRepository],
})
export class EmpleadosModule {}
