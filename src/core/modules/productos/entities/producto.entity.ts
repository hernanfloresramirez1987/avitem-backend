import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, JoinColumn, BaseEntity, OneToMany } from 'typeorm';
import { Proveedores } from '../../proveedores/entities/proveedore.entity';
import { Categorias } from '../../categorias/entities/categoria.entity';
import { ComboProductos } from '../../combo_productos/entities/combo_producto.entity';
import { MaterialServicios } from '../../material_servicios/entities/material_servicio.entity';
import { LoteProductos } from '../../lote_producto/entities/lote_producto.entity';
  
@Entity('producto')
export class Productos extends BaseEntity {
  @PrimaryGeneratedColumn('increment')
  id: number;

  @Column({ type: 'varchar', length: 100 })
  nombre: string;

  @Column('text', { nullable: true })
  descripcion: string;

  @Column({ type: 'int' })
  cantidadStock: number;

  @Column('date', { nullable: true })
  fechaIngreso: string;

  @Column({ type: 'varchar', length: 20, nullable: true })
  unidadMedida: string;

  @Column({ type: 'varchar', length: 50, unique: true })
  codigoProducto: string;

  @Column({ type: 'int' })
  state: number;

  @ManyToOne(() => Proveedores, { nullable: true })
  @JoinColumn({ name: 'id_proveedor' })
  proveedor: Proveedores | null;

  @ManyToOne(() => Categorias, { nullable: true })
  @JoinColumn({ name: 'id_categoria' })
  categoria: Categorias | null;

  @OneToMany(() => ComboProductos, (comboProducto) => comboProducto.producto)
  comboProductos: ComboProductos[];

  @OneToMany(() => MaterialServicios, (materialServicio) => materialServicio.producto)
  materialesServicio: MaterialServicios[];

  @OneToMany(() => LoteProductos, (loteProducto) => loteProducto.producto)
  loteProductos: LoteProductos[];
}