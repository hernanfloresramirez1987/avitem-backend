import { Entity, PrimaryGeneratedColumn, Column, BaseEntity } from 'typeorm';

@Entity('almacen')
export class Almacenes extends BaseEntity {
  @PrimaryGeneratedColumn('increment', { type: 'bigint', unsigned: true })
  id: number;

  @Column({ type: 'varchar', length: 255, nullable: false })
  direccion: string;

  @Column({ type: 'tinyint', nullable: false })
  matriz: boolean;

  @Column({ type: 'bigint', unsigned: true, nullable: true })
  capacidad: number | null;
}