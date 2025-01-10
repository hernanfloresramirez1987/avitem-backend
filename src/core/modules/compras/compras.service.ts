import { Injectable } from '@nestjs/common';
import { CreateCompraDto } from './dto/create-compra.dto';
import { UpdateCompraDto } from './dto/update-compra.dto';
import { InjectRepository } from '@nestjs/typeorm';
import { Compras } from './entities/compra.entity';
import { CompraRepository } from 'src/core/shared/repositories/CompraRep';
import { Connection } from 'typeorm';

@Injectable()
export class ComprasService {
  constructor(
    @InjectRepository(Compras)
    private comprasRepository: CompraRepository,
    private readonly connection: Connection
  ) {}

  create(createCompraDto: CreateCompraDto) {
    return 'This action adds a new compra';
  }

  async saveCompra(userObject: any): Promise<any> {
    console.log(userObject);

    const values = Object.values(userObject)
      .map((value) => (typeof value === 'string' ? `'${value}'` : value))
      .join(',');

    // Procedimiento almacenado con los valores
    const procedureStore = `CALL registro_Compra_y_Detalle(${values}, @resultado, @status);`;

    console.log("CALL registro_Compra_y_Detalle($: \n", procedureStore, "\n\n");
    
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

  findAll() {
    return `This action returns all compras`;
  }

  findOne(id: number) {
    return `This action returns a #${id} compra`;
  }

  update(id: number, updateCompraDto: UpdateCompraDto) {
    return `This action updates a #${id} compra`;
  }

  remove(id: number) {
    return `This action removes a #${id} compra`;
  }
}
