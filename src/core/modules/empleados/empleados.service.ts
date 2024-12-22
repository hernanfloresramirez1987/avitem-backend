import { Injectable } from '@nestjs/common';
import { CreateEmpleadoDto } from './dto/create-empleado.dto';
import { UpdateEmpleadoDto } from './dto/update-empleado.dto';
import { InjectRepository } from '@nestjs/typeorm';
import { Empleados } from './entities/empleado.entity';
import { Repository } from 'typeorm';
import { EmpleadoRepository } from 'src/core/shared/repositories/EmpleadoRep';

@Injectable()
export class EmpleadosService {

  constructor(
    @InjectRepository(Empleados)
    private readonly empleadosRepository: EmpleadoRepository,
  ) {}

  create(createEmpleadoDto: CreateEmpleadoDto) {
    return 'This action adds a new empleado';
  }

  findAll() {
    return this.empleadosRepository.createQueryBuilder('empleado')
      .innerJoinAndSelect('empleado.persona', 'persona') // Join con la relación persona
      .select([
        'empleado.id',
        'empleado.idtipo',
        'empleado.idcargo',
        'empleado.salario',
        'empleado.fing',
        'persona.id',
        'persona.nombre',
        'persona.app',
        'persona.apm',
        'persona.ci',
        'persona.ciExpedit',
      ])
      .getMany();
  }

  findOne(id: number) {
    return `This action returns a #${id} empleado`;
  }

  update(id: number, updateEmpleadoDto: UpdateEmpleadoDto) {
    return `This action updates a #${id} empleado`;
  }

  remove(id: number) {
    return `This action removes a #${id} empleado`;
  }
}
