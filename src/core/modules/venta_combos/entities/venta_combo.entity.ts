import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, JoinColumn, BaseEntity } from 'typeorm';
import { Ventas } from '../../ventas/entities/venta.entity';
import { Combos } from '../../combos/entities/combo.entity';

@Entity('venta_combo')
export class VentaCombos extends BaseEntity {
  @PrimaryGeneratedColumn('increment', { type: 'bigint', unsigned: true })
  id: number;

  @ManyToOne(() => Ventas, (venta) => venta.ventaCombos, { nullable: true, onDelete: 'CASCADE' })
  @JoinColumn({ name: 'id_venta' })
  venta: Ventas | null;

  @ManyToOne(() => Combos, (combo) => combo.ventaCombos, { nullable: true, onDelete: 'CASCADE' })
  @JoinColumn({ name: 'id_combo' })
  combo: Combos | null;

  @Column({ type: 'decimal', precision: 10, scale: 2, nullable: true })
  precioCombo: number | null;

  @Column({ type: 'int', nullable: false })
  cantidad: number;
}