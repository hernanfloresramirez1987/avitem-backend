import { Injectable } from '@nestjs/common';
import { CreateProveedoreDto } from './dto/create-proveedore.dto';
import { UpdateProveedoreDto } from './dto/update-proveedore.dto';
import { InjectRepository } from '@nestjs/typeorm';
import { Proveedores } from './entities/proveedore.entity';
import { hash } from 'bcrypt';
import { Connection, Repository } from 'typeorm';

@Injectable()
export class ProveedoresService {

  constructor(
    @InjectRepository(Proveedores)
    private readonly proveedoresRepository: Repository<Proveedores>,
    private readonly connection: Connection
  ) {}

  create(createProveedoreDto: CreateProveedoreDto) {
    return 'This action adds a new proveedore';
  }

  async saveProveedor(userObject: any): Promise<any> {
    console.log('console.log(userObject); : \n', userObject);

    const values = Object.values(userObject)
      .map((value) => (typeof value === 'string' ? `'${value}'` : value))
      .join(',');

    // Procedimiento almacenado con los valores
    const procedureStore = `CALL registro_persona_proveedor(${values}, @resultado, @status);`;
    
    try {
      // Ejecutar la consulta en la base de datos
      const execQuery = await this.connection.query(procedureStore);

      // Recuperar los valores de los parámetros de salida
      const result = await this.connection.query('SELECT @resultado AS Mensaje, @status AS CodigoEstado;');

      // Devuelvo los resultados, con el mensaje y el código de estado
      return result[0];  // Esto devuelve { Mensaje: 'Resultado', CodigoEstado: valor }
    } catch (error) {
      console.error('Error al ejecutar el procedimiento: ', error);
      throw new Error('Error al guardar el proveedor');
    }
  }

  async findAll() {
    const empleados = await this.proveedoresRepository.find({ relations: ['persona'] });
    
    // Formatea los datos según lo solicitado:
    const result = empleados.map(proveedor => ({
      id: proveedor.id,
      empresa: proveedor.empresa,
      nit: proveedor.nit,
      telefonoEmpresa: proveedor.telefonoEmpresa,
      direccionEmpresa: proveedor.direccionEmpresa,
      ci: proveedor.persona.ci,
      ciExpedit: proveedor.persona.ciExpedit,
      nombre: proveedor.persona.nombre,
      app: proveedor.persona.app,
      apm: proveedor.persona.apm,
      sexo: proveedor.persona.sexo,
      fnaci: proveedor.persona.fnaci,
      direccion: proveedor.persona.direccion,
      telenofo: proveedor.persona.telefono,
      email: proveedor.persona.email,
    }));
  
    return result;
  }

  findOne(id: number) {
    return `This action returns a #${id} proveedore`;
  }

  update(id: number, updateProveedoreDto: UpdateProveedoreDto) {
    return `This action updates a #${id} proveedore`;
  }

  remove(id: number) {
    return `This action removes a #${id} proveedore`;
  }
}
