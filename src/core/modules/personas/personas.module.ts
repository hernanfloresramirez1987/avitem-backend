import { Module } from '@nestjs/common';
import { PersonasService } from './personas.service';
import { PersonasController } from './personas.controller';
import { Personas } from './entities/persona.entity';
import { TypeOrmModule } from '@nestjs/typeorm';
import { PersonaRepository } from '../../shared/repositories/PersonaRep';

@Module({
  imports: [TypeOrmModule.forFeature([Personas])],
  controllers: [PersonasController],
  providers: [PersonasService, PersonaRepository],
})
export class PersonasModule {}