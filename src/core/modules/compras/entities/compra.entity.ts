import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, JoinColumn, BaseEntity, OneToMany } from 'typeorm';
import { Proveedores } from '../../proveedores/entities/proveedore.entity';
import { DetalleCompras } from '../../detalle_compras/entities/detalle_compra.entity';

@Entity('compra')
export class Compras extends BaseEntity {
  @PrimaryGeneratedColumn('increment', { type: 'bigint', unsigned: true })
  id: number;

  @Column({ type: 'date', nullable: false })
  fechaCompra: Date;

  @Column({ type: 'decimal', precision: 10, scale: 2, nullable: true })
  total: number | null;

  @ManyToOne(() => Proveedores, (proveedor) => proveedor.id, { nullable: true })
  @JoinColumn({ name: 'id_proveedor' })
  proveedor: Proveedores | null;

  @OneToMany(() => DetalleCompras, detalle => detalle.compra)
  detalle_compra: DetalleCompras[];
}