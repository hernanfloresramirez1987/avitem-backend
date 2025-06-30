import { Injectable } from '@nestjs/common';
import { CreateCompraDto } from './dto/create-compra.dto';
import { UpdateCompraDto } from './dto/update-compra.dto';
import { InjectRepository } from '@nestjs/typeorm';
import { Compras } from './entities/compra.entity';
import { Connection, Repository } from 'typeorm';
import { applyWhere } from '../common/applyWhere';

@Injectable()
export class ComprasService {
  constructor(
    @InjectRepository(Compras)
    private readonly comprasRepository: Repository<Compras>,
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
    const procedureStore = `CALL registro_Compra_y_Detalle_mas_Lote_update_Product(${values}, @resultado, @status, @id_compra);`; //console.log("CALL registro_Compra_y_Detalle_mas_Lote_update_Product($: \n", procedureStore, "\n\n");

    try {
      // Ejecutar la consulta en la base de datos
      const execQuery = await this.connection.query(procedureStore);

      // Recuperar los valores de los parámetros de salida
      const result = await this.connection.query('SELECT @resultado AS Mensaje, @status AS CodigoEstado, @id_compra as id;');

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
  async findAllFilter(filter: any) {
    const page = filter.page ? parseInt(filter.page) : 1;
    const rows = filter.rows ? parseInt(filter.rows) : 10;
    const skip = (page - 1) * rows;
    const whereConditions = await applyWhere(filter.filter, this.comprasRepository);
    const total_records = await this.comprasRepository.count({ // Total sin paginar
      where: whereConditions,
    });
    const queryBuilder = this.comprasRepository.createQueryBuilder('compras')
      .innerJoinAndSelect('compras.proveedor', 'proveedor')
      .innerJoinAndSelect('proveedor.persona', 'persona');
    queryBuilder.where(whereConditions);
    const data = await queryBuilder.getMany();
    const resultado = data.map((item) => ({
      ...item,
    }));
    return {
      data: resultado,
      metadata: {
        page: page,
        rows: data.length,
        total_records: total_records,
      },
    };
  }

  async findOne(id: number) {
    try {
      const compra = await this.comprasRepository.findOne({
        where: { id },
        relations: ['proveedor', 'detalle_compra'], // incluye relaciones anidadas si necesitas más detalles
      });

      if (!compra) {
        throw new Error(`Compra con ID ${id} no encontrada`);
      }
      return {
        id: compra.id,
        fechaCompra: compra.fechaCompra,
        total: compra.total,
        proveedor: compra.proveedor,
      };
    } catch (error) {
      console.error('Error al buscar la compra:', error.message);
      throw new Error('No se pudo recuperar la compra');
    }
  }

  update(id: number, updateCompraDto: UpdateCompraDto) {
    return `This action updates a #${id} compra`;
  }

  remove(id: number) {
    return `This action removes a #${id} compra`;
  }
}
