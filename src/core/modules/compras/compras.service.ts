import { Injectable } from '@nestjs/common';
import { CreateCompraDto } from './dto/create-compra.dto';
import { UpdateCompraDto } from './dto/update-compra.dto';
import { InjectRepository } from '@nestjs/typeorm';
import { Compras } from './entities/compra.entity';
import { Connection, Repository } from 'typeorm';

@Injectable()
export class ComprasService {
  constructor(
    @InjectRepository(Compras)
    private comprasRepository: Repository<Compras>,
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
    const procedureStore = `CALL registro_Compra_y_Detalle_mas_Lote_update_Product(${values}, @resultado, @status);`;

    console.log("CALL registro_Compra_y_Detalle_mas_Lote_update_Product($: \n", procedureStore, "\n\n");
    
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
    const compras = await this.comprasRepository.find({
      relations: ['proveedor']
    });
    
    const result = compras.map(compras => ({
      id: compras.id,
      fechaCompra: compras.fechaCompra,
      total: compras.total,
      proveedor: compras.proveedor.empresa
    }));

    console.log('Linea 60.- \n', result);
  
    return result;
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
