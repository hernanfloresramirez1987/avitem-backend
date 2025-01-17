import { MiddlewareConsumer, Module, NestModule } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { LoggerModule } from 'nestjs-pino';
import { Request } from 'express';
import { CORRELATION_ID_HEADER, CorrelationIdMiddleware } from './correlation-id/correlation-id.middleware';
import { ConfigModule } from '@nestjs/config';
import { EmpleadosModule } from './core/modules/empleados/empleados.module';
import { ClientesModule } from './core/modules/clientes/clientes.module';
import { PersonasModule } from './core/modules/personas/personas.module';
import { UsuariosModule } from './core/modules/usuarios/usuarios.module';
import { ProveedoresModule } from './core/modules/proveedores/proveedores.module';
import { DatabaseModule } from './core/config/database/database.module';
import { CategoriasModule } from './core/modules/categorias/categorias.module';
import { ProductosModule } from './core/modules/productos/productos.module';
import { AlmacenesModule } from './core/modules/almacenes/almacenes.module';
import { InventariosModule } from './core/modules/inventarios/inventarios.module';
import { ComprasModule } from './core/modules/compras/compras.module';
import { DetalleComprasModule } from './core/modules/detalle_compras/detalle_compras.module';
import { VentasModule } from './core/modules/ventas/ventas.module';
import { DetalleVentasModule } from './core/modules/detalle_ventas/detalle_ventas.module';
import { CombosModule } from './core/modules/combos/combos.module';
import { VentaCombosModule } from './core/modules/venta_combos/venta_combos.module';
import { ComboProductosModule } from './core/modules/combo_productos/combo_productos.module';
import { ServiciosModule } from './core/modules/servicios/servicios.module';
import { OrdenServiciosModule } from './core/modules/orden_servicios/orden_servicios.module';
import { MaterialServiciosModule } from './core/modules/material_servicios/material_servicios.module';
import { TransaccionContablesModule } from './core/modules/transaccion_contables/transaccion_contables.module';
import { LoteProductoModule } from './core/modules/lote_producto/lote_producto.module';
import { ColoresModule } from './core/modules/colores/colores.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      envFilePath: `.${process.env.NODE_ENV}.env`,
      isGlobal: true,
    }),
    DatabaseModule,
    LoggerModule.forRoot({
      pinoHttp: {
        transport: process.env.NODE_ENV === 'development' ? {
          target: 'pino-pretty',
          options: {
            messageKey: 'message',
          }
        } : undefined,
        messageKey: 'message',
        customProps: (req: Request) => {
          return { correlationId: req[CORRELATION_ID_HEADER] };
        },
        autoLogging: false,
        serializers: {
          req: () => { return undefined },
          res: () => { return undefined },
        }
      }
    }),
    EmpleadosModule,
    ClientesModule,
    PersonasModule,
    UsuariosModule,
    ProveedoresModule,
    CategoriasModule,
    ProductosModule,
    AlmacenesModule,
    InventariosModule,
    ComprasModule,
    DetalleComprasModule,
    VentasModule,
    DetalleVentasModule,
    CombosModule,
    VentaCombosModule,
    ComboProductosModule,
    ServiciosModule,
    OrdenServiciosModule,
    MaterialServiciosModule,
    TransaccionContablesModule,
    LoteProductoModule,
    ColoresModule
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule implements NestModule {
  configure(consumer: MiddlewareConsumer) {
    consumer.apply(CorrelationIdMiddleware).forRoutes('*');
  }
}
