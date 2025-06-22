import { Module } from '@nestjs/common';
import { ClientesService } from './clientes.service';
import { ClientesController } from './clientes.controller';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Clientes } from './entities/cliente.entity';
import { Personas } from '../personas/entities/persona.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Clientes, Personas])],
  controllers: [ClientesController],
  providers: [ClientesService],
})
export class ClientesModule {}
