import { Injectable } from '@nestjs/common';
import { CreatePersonaDto } from './dto/create-persona.dto';
import { UpdatePersonaDto } from './dto/update-persona.dto';
import { Personas } from './entities/persona.entity';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';

@Injectable()
export class PersonasService {
  constructor(
    @InjectRepository(Personas)
    private personaRepository: Repository<Personas>,
  ) {}
  create(createPersonaDto: CreatePersonaDto) {
    return 'This action adds a new persona';
  }

  async getAll(): Promise<Personas[]> {
    return await this.personaRepository.find();
  }
  
  async findOneCI(cidto: number) {
    return await this.personaRepository.find({ where: { ci: cidto.toString() } });
  }

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
