import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, JoinColumn, BaseEntity, OneToMany } from 'typeorm';
import { Empleados } from '../../empleados/entities/empleado.entity';
import { OrdenServicios } from '../../orden_servicios/entities/orden_servicio.entity';
import { MaterialServicios } from '../../material_servicios/entities/material_servicio.entity';

@Entity('servicio')
export class Servicios extends BaseEntity {
  @PrimaryGeneratedColumn('increment', { type: 'bigint', unsigned: true })
  id: number;

  @Column({ type: 'varchar', length: 100, nullable: false })
  nombre: string;

  @Column({ type: 'text', nullable: true })
  descripcion: string | null;

  @Column({ type: 'decimal', precision: 10, scale: 2, nullable: true })
  precioBase: number | null;

  @Column({ type: 'varchar', length: 50, nullable: true })
  unidadCobro: string | null;

  @Column({ type: 'varchar', length: 50, nullable: true })
  duracionEstimada: string | null;

  @ManyToOne(() => Empleados, (empleado) => empleado.servicios, { nullable: true, onDelete: 'SET NULL' })
  @JoinColumn({ name: 'id_empleado' })
  empleado: Empleados | null;

  @OneToMany(() => OrdenServicios, (ordenServicio) => ordenServicio.servicio)
  ordenesServicio: OrdenServicios[];

  @OneToMany(() => MaterialServicios, (materialServicio) => materialServicio.servicio)
  materialesServicio: MaterialServicios[];
}