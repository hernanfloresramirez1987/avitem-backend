import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Almacenes } from 'src/core/modules/almacenes/entities/almacene.entity';
import { Categorias } from 'src/core/modules/categorias/entities/categoria.entity';
import { Clientes } from 'src/core/modules/clientes/entities/cliente.entity';
import { Colores } from 'src/core/modules/colores/entities/color.entity';
import { ComboProductos } from 'src/core/modules/combo_productos/entities/combo_producto.entity';
import { Combos } from 'src/core/modules/combos/entities/combo.entity';
import { Compras } from 'src/core/modules/compras/entities/compra.entity';
import { DetalleCompras } from 'src/core/modules/detalle_compras/entities/detalle_compra.entity';
import { DetalleVentas } from 'src/core/modules/detalle_ventas/entities/detalle_venta.entity';
import { Empleados } from 'src/core/modules/empleados/entities/empleado.entity';
import { Inventarios } from 'src/core/modules/inventarios/entities/inventario.entity';
import { LoteProductos } from 'src/core/modules/lote_producto/entities/lote_producto.entity';
import { MaterialServicios } from 'src/core/modules/material_servicios/entities/material_servicio.entity';
import { OrdenServicios } from 'src/core/modules/orden_servicios/entities/orden_servicio.entity';
import { Personas } from 'src/core/modules/personas/entities/persona.entity';
import { Productos } from 'src/core/modules/productos/entities/producto.entity';
import { Proveedores } from 'src/core/modules/proveedores/entities/proveedore.entity';
import { Servicios } from 'src/core/modules/servicios/entities/servicio.entity';
import { Usuarios } from 'src/core/modules/usuarios/entities/usuario.entity';
import { VentaCombos } from 'src/core/modules/venta_combos/entities/venta_combo.entity';
import { Ventas } from 'src/core/modules/ventas/entities/venta.entity';

@Module({
    imports: [
        TypeOrmModule.forRootAsync({
          imports: [ConfigModule],
          inject: [ConfigService],
          useFactory: (configService: ConfigService) => ({
            type: 'mysql',
            host: '192.168.0.151', //configService.getOrThrow('DB_HOST'),
            port: 3306, //configService.getOrThrow('DB_PORT'),
            username: 'root', //configService.getOrThrow('DB_USERNAME'),
            password: '', //configService.getOrThrow('DB_PASSWORD'),
            database: 'avitem_prueba', //configService.getOrThrow('DB_NAME'),
            // entities: [__dirname + '/../../core/models/**/*.entity{.ts,.js}'],
            entities: [
              Personas,
              Empleados,
              Usuarios,
              Proveedores,
              Clientes,
              Categorias,
              Productos,
              LoteProductos,
              Almacenes,
              Inventarios,
              Compras,
              DetalleCompras,
              Ventas,
              DetalleVentas,
              Combos,
              VentaCombos,
              ComboProductos,
              VentaCombos,
              Servicios,
              OrdenServicios,
              MaterialServicios,
              Colores
            ],
            synchronize: true, //configService.getOrThrow('DB_SYNCRONIZE') === 'true',
          }),
          
        }),
      ],
    })
export class DatabaseModule {}
