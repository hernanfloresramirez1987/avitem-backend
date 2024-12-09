import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, JoinColumn } from 'typeorm';
import { Ventas } from '../../ventas/entities/venta.entity';
import { Productos } from '../../productos/entities/producto.entity';
  
  @Entity('detalle_venta')
  export class DetalleVentas {
    @PrimaryGeneratedColumn('increment', { type: 'bigint', unsigned: true })
    id: number;
  
    @Column({ type: 'int', nullable: false })
    cantidad: number;
  
    @Column({ type: 'decimal', precision: 10, scale: 2, nullable: true })
    precioUnitario: number | null;
  
    @ManyToOne(() => Ventas, (venta) => venta.id, { nullable: true, onDelete: 'CASCADE' })
    @JoinColumn({ name: 'id_venta' })
    venta: Ventas | null;
  
    @ManyToOne(() => Productos, (producto) => producto.id, { nullable: true, onDelete: 'CASCADE' })
    @JoinColumn({ name: 'id_producto' })
    producto: Productos | null;
  }