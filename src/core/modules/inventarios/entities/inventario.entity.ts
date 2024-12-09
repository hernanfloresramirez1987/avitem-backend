import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, JoinColumn } from 'typeorm';
import { Productos } from '../../productos/entities/producto.entity';
import { Almacenes } from '../../almacenes/entities/almacene.entity';
  
  @Entity('inventario')
  export class Inventarios {
    @PrimaryGeneratedColumn('increment', { type: 'bigint', unsigned: true })
    id: number;
  
    @ManyToOne(() => Productos, (producto) => producto.id, { nullable: true })
    @JoinColumn({ name: 'id_producto' })
    producto: Productos | null;
  
    @ManyToOne(() => Almacenes, (almacen) => almacen.id, { nullable: true })
    @JoinColumn({ name: 'id_almacen' })
    almacen: Almacenes | null;
  
    @Column({ type: 'int', nullable: false })
    cantidadStock: number;
  
    @Column({ type: 'date', nullable: true })
    fechaInventario: Date | null;
  }