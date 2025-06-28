import { Injectable } from '@nestjs/common';
import { CreateClienteDto } from './dto/create-cliente.dto';
import { UpdateClienteDto } from './dto/update-cliente.dto';
import { InjectRepository } from '@nestjs/typeorm';
import { Clientes } from './entities/cliente.entity';
import { Connection, Repository } from 'typeorm';

@Injectable()
export class ClientesService {
  constructor(
    @InjectRepository(Clientes)
    private clienteRepository: Repository<Clientes>,
    private readonly connection: Connection
  ) {}

  create(createClienteDto: CreateClienteDto) {
    return 'This action adds a new cliente';
  }

  async saveCliente(userObject: any): Promise<any> {
    console.log('console.log(userObject); : \n', userObject);

    const values = Object.values(userObject)
      .map((value) => (typeof value === 'string' ? `'${value}'` : value))
      .join(',');

    // Procedimiento almacenado con los valores
    const procedureStore = `CALL registro_persona_cliente(${values}, @resultado, @status);`;

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

  async findOneCI(ci: number) {
    const query = await this.clienteRepository.findOne({ where: { ci } });
    console.log(ci);
    return {
      success: true,
      message: query ? 'Cliente encontrado' : 'Cliente no encontrado',
      data: query,
    };
  }

  async findAll() {
    console.log('findAll : \n');
    const clients = await this.clienteRepository.find({ relations: ['persona'] });
    
    // Formatea los datos según lo solicitado:
    const result = clients.map(cli => ({
      id: cli.id,
      ci: cli.persona.ci,
      ciExpedit: cli.persona.ciExpedit,
      nombre: cli.persona.nombre,
      app: cli.persona.app,
      apm: cli.persona.apm,
      sexo: cli.persona.sexo,
      fnaci: cli.persona.fnaci,
      direccion: cli.persona.direccion,
      telenofo: cli.persona.telefono,
      email: cli.persona.email,
    }));
  
    console.log('result : \n', result);

    return result;
  }

  findOne(id: number) {
    return `This action returns a #${id} cliente`;
  }

  update(id: number, updateClienteDto: UpdateClienteDto) {
    return `This action updates a #${id} cliente`;
  }

  remove(id: number) {
    return `This action removes a #${id} cliente`;
  }
}
