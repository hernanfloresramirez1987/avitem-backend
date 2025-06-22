import { Module } from '@nestjs/common';
import { PersonasService } from './personas.service';
import { PersonasController } from './personas.controller';
import { Personas } from './entities/persona.entity';
import { TypeOrmModule } from '@nestjs/typeorm';

@Module({
  imports: [TypeOrmModule.forFeature([Personas])],
  controllers: [PersonasController],
  providers: [PersonasService],
})
export class PersonasModule {}