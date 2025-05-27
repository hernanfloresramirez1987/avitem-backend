import { Injectable } from '@nestjs/common';
import { CreateClienteDto } from './dto/create-cliente.dto';
import { UpdateClienteDto } from './dto/update-cliente.dto';
import { InjectRepository } from '@nestjs/typeorm';
import { Clientes } from './entities/cliente.entity';
import { ClienteRepository } from 'src/core/shared/repositories/ClienteRep';
import { Connection } from 'typeorm';

@Injectable()
export class ClientesService {
  constructor(
    @InjectRepository(Clientes)
    private clienteRepository: ClienteRepository,
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

  async findAll() {
    // const cliente_ = await this.clienteRepository.find(); 
    const clientes = await this.clienteRepository.find({ // where: { proveedor: { id: idProveedor } },
      relations: ['persona'] 
    });
    const result = clientes.map(t => ({
        id: t.id,
        nombre: t.persona.nombre,
        app: t.persona.app,
        apm: t.persona.apm,
        direccion: t.persona.direccion,
        nit: t.nit,
        sexo: t.persona.sexo
      })
    );
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
