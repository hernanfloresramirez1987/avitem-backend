import { Entity, PrimaryGeneratedColumn, Column, OneToMany, BaseEntity } from 'typeorm';
import { VentaCombos } from '../../venta_combos/entities/venta_combo.entity';
import { ComboProductos } from '../../combo_productos/entities/combo_producto.entity';

@Entity('combo')
export class Combos extends BaseEntity {
  @PrimaryGeneratedColumn('increment', { type: 'bigint', unsigned: true })
  id: number;

  @Column({ type: 'varchar', length: 100, nullable: false })
  nombre: string;

  @Column({ type: 'text', nullable: true })
  descripcion: string | null;

  @Column({ type: 'decimal', precision: 5, scale: 2, nullable: true })
  descuento: number | null;

  @Column({ type: 'decimal', precision: 10, scale: 2, nullable: true })
  precioFinal: number | null;

  // Relación OneToMany con VentaCombos
  @OneToMany(() => VentaCombos, (ventaCombo) => ventaCombo.combo)
  ventaCombos: VentaCombos[];

  @OneToMany(() => ComboProductos, (comboProducto) => comboProducto.combo)
comboProductos: ComboProductos[];
}
