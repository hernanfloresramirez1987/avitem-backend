import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, OneToMany, JoinColumn, BaseEntity } from 'typeorm';
import { Clientes } from '../../clientes/entities/cliente.entity';
import { Empleados } from '../../empleados/entities/empleado.entity';
import { VentaCombos } from '../../venta_combos/entities/venta_combo.entity';

@Entity('venta')
export class Ventas extends BaseEntity {
    @PrimaryGeneratedColumn('increment', { type: 'bigint', unsigned: true })
    id: number;

    @Column({ type: 'date', nullable: false })
    fechaVenta: Date;

    @Column({ type: 'decimal', precision: 10, scale: 2, nullable: true })
    total: number | null;

    @Column({ type: 'varchar', length: 255, nullable: true })
    tokenSIM: string | null;

    @ManyToOne(() => Clientes, (cliente) => cliente.id, { nullable: true })
    @JoinColumn({ name: 'id_cliente' })
    cliente: Clientes | null;

    @ManyToOne(() => Empleados, (empleado) => empleado.id, { nullable: true })
    @JoinColumn({ name: 'id_empleado' })
    empleado: Empleados | null;

    @OneToMany(() => VentaCombos, (ventaCombo) => ventaCombo.venta)
    ventaCombos: VentaCombos[];

    @Column({ type: 'bool', default: false })
    confactura: boolean;
}