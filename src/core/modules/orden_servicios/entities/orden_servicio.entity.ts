import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, JoinColumn, BaseEntity } from 'typeorm';
import { Clientes } from '../../clientes/entities/cliente.entity';
import { Servicios } from '../../servicios/entities/servicio.entity';

@Entity('orden_servicio')
export class OrdenServicios extends BaseEntity {
  @PrimaryGeneratedColumn('increment', { type: 'bigint', unsigned: true })
  id: number;

  @ManyToOne(() => Clientes, (cliente) => cliente.ordenesServicio, { nullable: true, onDelete: 'SET NULL' })
  @JoinColumn({ name: 'id_cliente' })
  cliente: Clientes | null;

  @ManyToOne(() => Servicios, (servicio) => servicio.ordenesServicio, { nullable: true, onDelete: 'SET NULL' })
  @JoinColumn({ name: 'id_servicio' })
  servicio: Servicios | null;

  @Column({ type: 'date', nullable: true })
  fechaSolicitud: Date | null;

  @Column({ type: 'date', nullable: true })
  fechaEntrega: Date | null;

  @Column({ type: 'decimal', precision: 10, scale: 2, nullable: true })
  cantidad: number | null;

  @Column({ type: 'decimal', precision: 10, scale: 2, nullable: true })
  precioTotal: number | null;
}