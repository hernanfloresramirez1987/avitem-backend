import { Entity, PrimaryGeneratedColumn, Column, BaseEntity } from 'typeorm';

@Entity('categoria')
export class Categorias extends BaseEntity {
  @PrimaryGeneratedColumn('increment', { type: 'bigint', unsigned: true })
  id: number;

  @Column({ type: 'varchar', length: 100, nullable: false })
  nombre: string;

  @Column({ type: 'text', nullable: true })
  descripcion: string | null;
}