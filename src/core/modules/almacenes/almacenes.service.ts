import { Injectable } from '@nestjs/common';
import { CreateAlmaceneDto } from './dto/create-almacene.dto';
import { UpdateAlmaceneDto } from './dto/update-almacene.dto';
import { InjectRepository } from '@nestjs/typeorm';
import { Almacenes } from './entities/almacene.entity';
import { Connection, Like, Repository } from 'typeorm';
import { applyWhere } from '../common/applyWhere';

@Injectable()
export class AlmacenesService {
  constructor(
    @InjectRepository(Almacenes)
    private almacenRepository: Repository<Almacenes>,
    private readonly connection: Connection
  ) {}

  create(createAlmaceneDto: CreateAlmaceneDto) {
    console.log(createAlmaceneDto);
  }

  async findAll() {
    const almacenes = await this.almacenRepository.find();
    console.log('almacenes: \n')
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

  // async findAllFilter(filter: any) {
  //   console.log("Filter:    ", filter);
  //   const almacenes = await this.almacenRepository.find({
  //     // where: {
  //     //   nombre: Like(`%${filter.nombre}%`)
  //     // }
  //   });
  //   console.log("Almacenes:    ", almacenes);
  //   const result = almacenes.map(t => ({
  //       id: t.id,
  //       nombre: t.nombre,
  //       direccion: t.direccion,
  //       matriz: t.matriz,
  //       capacidad: t.capacidad
  //     })
  //   );
  //   return result;
  // }

  async findAllFilter(filter: any) {
    const page = filter.page ? parseInt(filter.page) : 1;
    const rows = filter.rows ? parseInt(filter.rows) : 10;
    const skip = (page - 1) * rows;

    // const whereConditions: any = {}; // Objeto para almacenar las condiciones del WHERE
    const whereConditions = await applyWhere(filter.filter, this.almacenRepository);

    // Agregar condiciones basadas en los filtros proporcionados
    if (filter.nombre) {
      whereConditions.nombre = Like(`%${filter.nombre}%`);
    }
    if (filter.direccion) {
      whereConditions.direccion = Like(`%${filter.direccion}%`);
    }
    if (filter.matriz !== undefined) {
      whereConditions.matriz = filter.matriz; // Suponiendo que es booleano o un valor específico
    }
    if (filter.capacidad !== undefined) {
      whereConditions.capacidad = filter.capacidad; // Suponiendo que se busca una capacidad específica
    }
    const total_records = await this.almacenRepository.count({ // Total sin paginar
      where: whereConditions,
    });

    const almacenes = await this.almacenRepository.find({ where: whereConditions });
    
    const resultado = almacenes.map(t => ({
      id: t.id,
      nombre: t.nombre,
      direccion: t.direccion,
      matriz: t.matriz,
      capacidad: t.capacidad,
    }));
    console.log("RESULTADO  :    ", resultado);

    // return result;
    return {
      data: resultado,
      metadata: {
        page: page,
        rows: rows,
        total_records: total_records,
      },
    };
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
