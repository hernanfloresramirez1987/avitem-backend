import { Module } from '@nestjs/common';
import { UsuariosService } from './usuarios.service';
import { UsuariosController } from './usuarios.controller';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Proveedores } from '../proveedores/entities/proveedore.entity';
import { Personas } from '../personas/entities/persona.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([Proveedores, Personas]), // Registra las entidades
  ],
  controllers: [UsuariosController],
  providers: [UsuariosService],
})
export class UsuariosModule {}
