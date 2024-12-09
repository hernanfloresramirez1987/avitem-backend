import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, JoinColumn } from 'typeorm';
import { Combos } from '../../combos/entities/combo.entity';
import { Productos } from '../../productos/entities/producto.entity';

@Entity('combo_producto')
export class ComboProductos {
  @PrimaryGeneratedColumn('increment', { type: 'bigint', unsigned: true })
  id: number;

  @ManyToOne(() => Combos, (combo) => combo.comboProductos, { nullable: true, onDelete: 'CASCADE' })
  @JoinColumn({ name: 'id_combo' })
  combo: Combos | null;

  @ManyToOne(() => Productos, (producto) => producto.comboProductos, { nullable: true, onDelete: 'CASCADE' })
  @JoinColumn({ name: 'id_producto' })
  producto: Productos | null;

  @Column({ type: 'decimal', precision: 10, scale: 2, nullable: false })
  cantidad: number;
}