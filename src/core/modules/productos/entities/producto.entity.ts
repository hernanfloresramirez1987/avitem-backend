import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, JoinColumn, BaseEntity, OneToMany } from 'typeorm';
import { Proveedores } from '../../proveedores/entities/proveedore.entity';
import { Categorias } from '../../categorias/entities/categoria.entity';
import { ComboProductos } from '../../combo_productos/entities/combo_producto.entity';
import { MaterialServicios } from '../../material_servicios/entities/material_servicio.entity';
  
@Entity('producto')
export class Productos extends BaseEntity {
  @PrimaryGeneratedColumn('increment', { type: 'bigint', unsigned: true })
  id: number;

  @Column({ type: 'varchar', length: 100, nullable: false })
  nombre: string;

  @Column({ type: 'text', nullable: true })
  descripcion: string | null;

  @Column({ type: 'decimal', precision: 10, scale: 2, nullable: false })
  precio: number;

  @Column({ type: 'int', nullable: false })
  cantidadStock: number;

  @Column({ type: 'date', nullable: true })
  fechaIngreso: Date | null;

  @Column({ type: 'varchar', length: 20, nullable: true })
  unidadMedida: string | null;

  @Column({ type: 'decimal', precision: 10, scale: 2, nullable: true })
  precioUnitario: number | null;

  @Column({ type: 'varchar', length: 50, nullable: true, unique: true })
  codigoProducto: string | null;

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
}