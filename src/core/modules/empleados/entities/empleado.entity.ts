import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, JoinColumn, BaseEntity, OneToMany } from 'typeorm';
import { Personas } from '../../personas/entities/persona.entity';
import { Servicios } from '../../servicios/entities/servicio.entity';

@Entity('empleado')
export class Empleados extends BaseEntity {
  @PrimaryGeneratedColumn('increment', { type: 'bigint', unsigned: true })
  id: number;

  @ManyToOne(() => Personas, { nullable: false, onDelete: 'CASCADE' })
  @JoinColumn({ name: 'idper' }) // Relación con la tabla persona
  persona: Personas;

  @Column({ type: 'bigint', unsigned: true, nullable: false })
  idtipo: number;

  @Column({ type: 'bigint', unsigned: true, nullable: false })
  idcargo: number;

  @Column({ type: 'int', nullable: false })
  salario: number;

  @Column({ type: 'varchar', length: 255, nullable: false })
  fing: string;

  @OneToMany(() => Servicios, (servicio) => servicio.empleado)
  servicios: Servicios[];
}