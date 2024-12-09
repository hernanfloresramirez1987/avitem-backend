import { Module } from '@nestjs/common';
import { PersonasService } from './personas.service';
import { PersonasController } from './personas.controller';
import { Personas } from './entities/persona.entity';
import { TypeOrmModule } from '@nestjs/typeorm';
import { PersonaRepository } from '../../shared/repositories/PersonaRep';

@Module({
  imports: [
    TypeOrmModule.forFeature([Personas]), // Importa la entidad
  ],
  providers: [
    PersonasService, 
    PersonaRepository, // Registra el repositorio como proveedor
  ],
  controllers: [PersonasController],
  exports: [
    PersonasService, 
    PersonaRepository, // Exporta si es necesario en otros módulos
  ],
})
export class PersonasModule {}