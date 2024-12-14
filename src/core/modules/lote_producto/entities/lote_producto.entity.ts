import { BaseEntity, Column, Entity, JoinColumn, ManyToOne, PrimaryGeneratedColumn } from "typeorm";
import { Productos } from "../../productos/entities/producto.entity";

@Entity('lote_producto')
export class LoteProductos extends BaseEntity {
    @PrimaryGeneratedColumn()
    id: number;
  
    @Column({ type: 'varchar', length: 50 })
    numLote: string;
  
    @Column({ type: 'date' })
    fechaReabastecimiento: string;
  
    @Column({ type: 'int' })
    cantidadReabastecida: number;
  
    @Column({ type: 'date', nullable: true })
    fechaVencimiento: string;
  
    @Column({ type: 'decimal', precision: 10, scale: 2, nullable: true })
    precioCompra: number;
  
    @Column({ type: 'decimal', precision: 10, scale: 2, nullable: true })
    precioVenta: number;
  
    @ManyToOne(() => Productos, (producto) => producto.loteProductos)
    @JoinColumn({ name: 'id_producto' })
    producto: Productos;
}