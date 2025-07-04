import { Injectable } from '@nestjs/common';
import { CreateVentaDto } from './dto/create-venta.dto';
import { UpdateVentaDto } from './dto/update-venta.dto';
import { InjectRepository } from '@nestjs/typeorm';
import { Ventas } from './entities/venta.entity';
import { Connection, Repository } from 'typeorm';

@Injectable()
export class VentasService {
  constructor(
    @InjectRepository(Ventas)
    private readonly ventasRepository: Repository<Ventas>,
    private readonly connection: Connection
  ) {}
  create(createVentaDto: CreateVentaDto) {
    console.log(createVentaDto);
    return 'This action adds a new venta';
  }

  async saveVenta(userObject: any): Promise<any> {
    console.log(userObject);

    const values = Object.values(userObject)
      .map((value) => (typeof value === 'string' ? `'${value}'` : value))
      .join(',');

    // Procedimiento almacenado con los valores
    const procedureStore = `CALL registrar_venta_y_descuento(${values}, @resultado, @status, @id_venta);`;

    console.log("CALL registrar_venta_y_descuento($: \n", procedureStore, "\n\n");

    try { // Ejecutar la consulta en la base de datos
      const execQuery = await this.connection.query(procedureStore);

      // Recuperar los valores de los parámetros de salida
      const result = await this.connection.query('SELECT @resultado AS Mensaje, @status AS CodigoEstado, @id_venta as id;');

      // Devuelvo los resultados, con el mensaje y el código de estado
      return result[0];  // Esto devuelve { Mensaje: 'Resultado', CodigoEstado: valor }
    } catch (error) {
      console.error('Error al ejecutar el procedimiento: ', error);
      throw new Error('Error al guardar el proveedor');
    }
  }

  async findAll() {
    const ventas = await this.ventasRepository.find({
      relations: ['cliente'],
    });

    const result = ventas.map(ventas => ({
      id: ventas.id,
      fechaventa: ventas.fechaVenta,
      total: ventas.total,
      cliente: ventas.cliente,
    }));

    console.log('Linea 60.- \n', result);

    return result;
  }

  findOne(id: number) {
    return `This action returns a #${id} venta`;
  }

  update(id: number, updateVentaDto: UpdateVentaDto) {
    return `This action updates a #${id} venta`;
  }

  remove(id: number) {
    return `This action removes a #${id} venta`;
  }
}
