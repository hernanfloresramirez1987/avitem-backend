import { Injectable } from '@nestjs/common';
import { CreateEmpleadoDto } from './dto/create-empleado.dto';
import { UpdateEmpleadoDto } from './dto/update-empleado.dto';
import { InjectRepository } from '@nestjs/typeorm';
import { Empleados } from './entities/empleado.entity';
import { EmpleadoRepository } from 'src/core/shared/repositories/EmpleadoRep';
import { hash } from 'bcrypt';
import { Connection } from 'typeorm';

@Injectable()
export class EmpleadosService {

  constructor(
    @InjectRepository(Empleados)
    private readonly empleadosRepository: EmpleadoRepository,
    private readonly connection: Connection
  ) {}

  create(createEmpleadoDto: CreateEmpleadoDto) {
    return 'This action adds a new empleado';
  }
  
  async saveEmployee(userObject: any): Promise<any> {
    console.log('console.log(userObject); : \n', userObject);
    // Encriptar la contraseña
    const { u_password } = userObject;
    const saltRounds = 10;
    const plainToHash = await hash(u_password, saltRounds);
    
    // Actualizar el objeto con la contraseña cifrada
    userObject = { ...userObject, u_password: plainToHash };

    // Extraer los valores del objeto y construir el string para el procedimiento almacenado
    const values = Object.values(userObject)
      .map((value) => (typeof value === 'string' ? `'${value}'` : value))
      .join(',');

    // Procedimiento almacenado con los valores
    const procedureStore = `CALL registro_persona_empleado(${values}, @resultado, @status);`;
    
    try {
      // Ejecutar la consulta en la base de datos
      const execQuery = await this.connection.query(procedureStore);

      // Recuperar los valores de los parámetros de salida
      const result = await this.connection.query('SELECT @resultado AS Mensaje, @status AS CodigoEstado;');

      // Devuelvo los resultados, con el mensaje y el código de estado
      return result[0];  // Esto devuelve { Mensaje: 'Resultado', CodigoEstado: valor }
    } catch (error) {
      console.error('Error al ejecutar el procedimiento: ', error);
      throw new Error('Error al guardar el empleado');
    }
  }

  // findAll() {
  //   const empleado: any = this.empleadosRepository.createQueryBuilder('empleado')
  //     .innerJoinAndSelect('empleado.persona', 'persona') // Join con la relación persona
  //     .select([
  //       'empleado.id',
  //       'empleado.idtipo',
  //       'empleado.idcargo',
  //       'empleado.salario',
  //       'empleado.fing',
  //       'persona.id',
  //       'persona.nombre',
  //       'persona.app',
  //       'persona.apm',
  //       'persona.ci',
  //       'persona.ciExpedit',
  //     ])
  //     .getMany();
  //     console.log(...empleado);

  //     return empleado;
  // }
  async findAll() {
    const empleados = await this.empleadosRepository.find({ relations: ['persona'] });
    
    // Formatea los datos según lo solicitado:
    const result = empleados.map(emp => ({
      id: emp.id,
      idtipo: emp.idtipo,
      idcargo: emp.idcargo,
      salario: emp.salario,
      fing: emp.fing,
      ci: emp.persona.ci,
      ciExpedit: emp.persona.ciExpedit,
      nombre: emp.persona.nombre,
      app: emp.persona.app,
      apm: emp.persona.apm,
      sexo: emp.persona.sexo,
      fnaci: emp.persona.fnaci,
      direccion: emp.persona.direccion,
      telenofo: emp.persona.telefono,
      email: emp.persona.email,
    }));
  
    return result;
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
