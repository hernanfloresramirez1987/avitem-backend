import { BaseEntity, Column, Entity, JoinColumn, ManyToMany, ManyToOne, PrimaryGeneratedColumn } from "typeorm";
import { Productos } from "../../productos/entities/producto.entity";

@Entity('color')
export class Colores  extends BaseEntity {
  @PrimaryGeneratedColumn('increment', { type: 'bigint', unsigned: true })
  id: number;

  @Column({ type: 'varchar', length: 10, nullable: true })
  code: string;

  @Column({ type: 'varchar', length: 50, nullable: true })
  color: string;

  @ManyToMany(() => Productos, (producto) => producto.color)
  productos: Productos[];
}
