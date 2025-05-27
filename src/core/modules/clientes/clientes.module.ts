import { Module } from '@nestjs/common';
import { ClientesService } from './clientes.service';
import { ClientesController } from './clientes.controller';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Clientes } from './entities/cliente.entity';
import { Personas } from '../personas/entities/persona.entity';
import { ClienteRepository } from 'src/core/shared/repositories/ClienteRep';

@Module({
  imports: [TypeOrmModule.forFeature([Clientes, Personas])],
  controllers: [ClientesController],
  providers: [ClientesService, ClienteRepository],
})
export class ClientesModule {}
