import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, JoinColumn, BaseEntity } from 'typeorm';
import { Productos } from '../../productos/entities/producto.entity';
import { Almacenes } from '../../almacenes/entities/almacene.entity';

@Entity('inventario')
export class Inventarios extends BaseEntity {
  @PrimaryGeneratedColumn('increment', { type: 'bigint', unsigned: true })
  id: number;

  @ManyToOne(() => Productos, (producto) => producto.id, { nullable: true })
  @JoinColumn({ name: 'id_producto' })
  producto: Productos;

  @ManyToOne(() => Almacenes, (almacen) => almacen.id, { nullable: true })
  @JoinColumn({ name: 'id_almacen' })
  almacen: Almacenes;

  @Column({ type: 'int', nullable: false })
  idLote: number;

  @Column({ type: 'int', nullable: false })
  cantidadStock: number;

  @Column({ type: 'int', nullable: false })
  cantidadReservada: number;

  @Column({ type: 'int', nullable: false })
  cantidadDespachada: number;

  @Column({ type: 'date', nullable: true })
  fechaInventario: Date | null;

  @Column({ type: 'date', nullable: true })
  fechaIngreso: Date | null;

  @Column({ type: 'date', nullable: true })
  fechaSalida: Date | null;
}