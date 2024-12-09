import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, JoinColumn, BaseEntity } from 'typeorm';
import { Compras } from '../../compras/entities/compra.entity';
import { Productos } from '../../productos/entities/producto.entity';
  
  @Entity('detalle_compra')
// export class DetalleCompra {
export class DetalleCompras extends BaseEntity {
    @PrimaryGeneratedColumn('increment', { type: 'bigint', unsigned: true })
    id: number;
  
    @ManyToOne(() => Compras, (compra) => compra.id, { nullable: true })
    @JoinColumn({ name: 'id_compra' })
    compra: Compras | null;
  
    @ManyToOne(() => Productos, (producto) => producto.id, { nullable: true })
    @JoinColumn({ name: 'id_producto' })
    producto: Productos | null;
  
    @Column({ type: 'int', nullable: false })
    cantidad: number;
  
    @Column({ type: 'decimal', precision: 10, scale: 2, nullable: true })
    precioUnitario: number | null;
  }