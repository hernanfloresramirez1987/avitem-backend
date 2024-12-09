import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, JoinColumn, BaseEntity } from 'typeorm';
import { Personas } from '../../personas/entities/persona.entity';
  
@Entity('proveedor')
export class Proveedores extends BaseEntity {
    @PrimaryGeneratedColumn('increment', { type: 'bigint', unsigned: true })
    id: number;
  
    @ManyToOne(() => Personas, { nullable: false, onDelete: 'CASCADE' })
    @JoinColumn({ name: 'id_persona' })
    persona: Personas;
  
    @Column({ type: 'varchar', length: 100, nullable: false })
    empresa: string;
  
    @Column({ type: 'varchar', length: 20, nullable: false })
    nit: string;
  
    @Column({ type: 'varchar', length: 15, nullable: true })
    telefonoEmpresa: string | null;
  
    @Column({ type: 'varchar', length: 200, nullable: true })
    direccionEmpresa: string | null;
  }