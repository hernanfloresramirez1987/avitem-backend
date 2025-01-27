import { Injectable } from '@nestjs/common';
import { CreateColoreDto } from './dto/create-colore.dto';
import { UpdateColoreDto } from './dto/update-colore.dto';
import { InjectRepository } from '@nestjs/typeorm';
import { Colores } from './entities/color.entity';
import { ColorRepository } from 'src/core/shared/repositories/ColorRep';
import { Connection } from 'typeorm';

@Injectable()
export class ColoresService {

  constructor(
    @InjectRepository(Colores)
    private readonly colorRepository: ColorRepository,
    private readonly connection: Connection
  ) {}
  create(createColoreDto: CreateColoreDto) {
    return 'This action adds a new colore';
  }

  async findAll(): Promise<Colores[]> {
    return await this.colorRepository.find();
  }

  findOne(id: number) {
    return `This action returns a #${id} colore`;
  }

  update(id: number, updateColoreDto: UpdateColoreDto) {
    return `This action updates a #${id} colore`;
  }

  remove(id: number) {
    return `This action removes a #${id} colore`;
  }
}
