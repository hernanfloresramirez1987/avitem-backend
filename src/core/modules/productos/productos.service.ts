import { Injectable } from '@nestjs/common';
import { CreateProductoDto } from './dto/create-producto.dto';
import { UpdateProductoDto } from './dto/update-producto.dto';
import { InjectRepository } from '@nestjs/typeorm';
import { Productos } from './entities/producto.entity';
import { ProductoRepository } from 'src/core/shared/repositories/ProductoRep';
import { Connection } from 'typeorm';

@Injectable()
export class ProductosService {
  constructor(
    @InjectRepository(Productos)
    private personaRepository: ProductoRepository,
    private readonly connection: Connection
  ) {}
  create(createProductoDto: CreateProductoDto) {
    return 'This action adds a new producto';
  }

  async saveProducto(userObject: any): Promise<any> {
    console.log('console.log(userObject); : \n', userObject);

    const values = Object.values(userObject)
      .map((value) => (typeof value === 'string' ? `'${value}'` : value))
      .join(',');

    // Procedimiento almacenado con los valores
    const procedureStore = `CALL registro_producto(${values}, @resultado, @status);`;
    
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


  async findAllOneProveedor(idProveedor: number) {
    const productos = await this.personaRepository.find({
      where: { proveedor: { id: idProveedor } },
      relations: ['proveedor'] 
    });
    
    const result = productos.map(producto => ({
      id: producto.id,
      nombre: producto.nombre,
      descripcion: producto.descripcion,
      cantidadStock: producto.cantidadStock,
      fechaIngreso: producto.fechaIngreso,
      unidadMedida: producto.unidadMedida,
      codigoProducto: producto.codigoProducto,
      id_proveedor: producto.proveedor.id,
      empresa: producto.proveedor.empresa,
      nit: producto.proveedor.nit
    }));
  
    return result;
  }

  async findAll() {
    const productos = await this.personaRepository.find({ 
      relations: ['proveedor'] 
    });
    
    const result = productos.map(producto => ({
      id: producto.id,
      nombre: producto.nombre,
      descripcion: producto.descripcion,
      cantidadStock: producto.cantidadStock,
      fechaIngreso: producto.fechaIngreso,
      unidadMedida: producto.unidadMedida,
      codigoProducto: producto.codigoProducto,
      id_proveedor: producto.proveedor.id,
      empresa: producto.proveedor.empresa,
      nit: producto.proveedor.nit
    }));
  
    return result;
  }

  findOne(id: number) {
    return `This action returns a #${id} producto`;
  }

  update(id: number, updateProductoDto: UpdateProductoDto) {
    return `This action updates a #${id} producto`;
  }

  remove(id: number) {
    return `This action removes a #${id} producto`;
  }
}
