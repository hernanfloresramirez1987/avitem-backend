import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, JoinColumn, BaseEntity, OneToMany } from 'typeorm';
import { Personas } from '../../personas/entities/persona.entity';
import { OrdenServicios } from '../../orden_servicios/entities/orden_servicio.entity';
  
  @Entity('cliente')
  export class Clientes extends BaseEntity {
    @PrimaryGeneratedColumn('increment', { type: 'bigint', unsigned: true })
    id: number;
  
    @Column({ type: 'int', nullable: false })
    ci: number;
  
    @Column({ type: 'int', nullable: true })
    nit: number | null;
  
    @Column({ type: 'tinyint', width: 1, nullable: false })
    state: boolean;
  
    @ManyToOne(() => Personas, { nullable: true, onDelete: 'SET NULL' })
    @JoinColumn({ name: 'id_persona' })
    persona: Personas | null;

    @OneToMany(() => OrdenServicios, (ordenServicio) => ordenServicio.cliente)
    ordenesServicio: OrdenServicios[];
  }