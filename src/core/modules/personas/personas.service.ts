import { Injectable } from '@nestjs/common';
import { CreatePersonaDto } from './dto/create-persona.dto';
import { UpdatePersonaDto } from './dto/update-persona.dto';
import { Personas } from './entities/persona.entity';
import { InjectRepository } from '@nestjs/typeorm';
import { PersonaRepository } from '../../shared/repositories/PersonaRep';

@Injectable()
export class PersonasService {
  constructor(
    @InjectRepository(Personas)
    private personaRepository: PersonaRepository,
  ) {}
  create(createPersonaDto: CreatePersonaDto) {
    return 'This action adds a new persona';
  }

  async getAll(): Promise<Personas[]> {
    return await this.personaRepository.find();
  }
  // findAll() {
  //   // return `This action returns all personas`;
  //   return this.find({ where: { state: true } });
  // }

  findOne(id: number) {
    return `This action returns a #${id} persona`;
  }

  update(id: number, updatePersonaDto: UpdatePersonaDto) {
    return `This action updates a #${id} persona`;
  }

  remove(id: number) {
    return `This action removes a #${id} persona`;
  }
}
