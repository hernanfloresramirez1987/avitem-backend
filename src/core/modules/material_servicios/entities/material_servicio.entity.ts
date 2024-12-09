import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, JoinColumn } from 'typeorm';
import { Servicios } from '../../servicios/entities/servicio.entity';
import { Productos } from '../../productos/entities/producto.entity';

@Entity('materiales_servicio')
export class MaterialServicios {
  @PrimaryGeneratedColumn('increment', { type: 'bigint', unsigned: true })
  id: number;

  @ManyToOne(() => Servicios, (servicio) => servicio.materialesServicio, { nullable: true, onDelete: 'SET NULL' })
  @JoinColumn({ name: 'id_servicio' })
  servicio: Servicios | null;

  @ManyToOne(() => Productos, (producto) => producto.materialesServicio, { nullable: true, onDelete: 'SET NULL' })
  @JoinColumn({ name: 'id_producto' })
  producto: Productos | null;

  @Column({ type: 'decimal', precision: 10, scale: 2, nullable: true })
  cantidadRequerida: number | null;

  @Column({ type: 'decimal', precision: 10, scale: 2, nullable: true })
  costoUnitario: number | null;
}