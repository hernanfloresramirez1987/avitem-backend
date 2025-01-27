import { Injectable } from '@nestjs/common';
import { CreateAlmaceneDto } from './dto/create-almacene.dto';
import { UpdateAlmaceneDto } from './dto/update-almacene.dto';
import { InjectRepository } from '@nestjs/typeorm';
import { Almacenes } from './entities/almacene.entity';
import { AlmacenRepository } from 'src/core/shared/repositories/AlmacenRep';
import { Connection } from 'typeorm';

@Injectable()
export class AlmacenesService {
  constructor(
    @InjectRepository(Almacenes)
    private almacenRepository: AlmacenRepository,
    private readonly connection: Connection
  ) {}

  create(createAlmaceneDto: CreateAlmaceneDto) {
    
  }
    
  async findAll() {
    const almacenes = await this.almacenRepository.find(); 
    const result = almacenes.map(t => ({
        id: t.id,
        nombre: t.nombre,
        direccion: t.direccion,
        matriz: t.matriz,
        capacidad: t.capacidad
      })
    );
    return result;
  }

  findOne(id: number) {
    return `This action returns a #${id} almacene`;
  }

  update(id: number, updateAlmaceneDto: UpdateAlmaceneDto) {
    return `This action updates a #${id} almacene`;
  }

  remove(id: number) {
    return `This action removes a #${id} almacene`;
  }
}
