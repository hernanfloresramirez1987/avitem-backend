import { Entity, PrimaryGeneratedColumn, Column, Unique, ManyToOne, JoinColumn, BaseEntity } from 'typeorm';
import { Empleados } from '../../empleados/entities/empleado.entity';
  
  @Entity('usuario')
  @Unique(['username'])
  export class Usuarios extends BaseEntity {
    @PrimaryGeneratedColumn('increment', { type: 'bigint' })
    id: number;
  
    @ManyToOne(() => Empleados, { nullable: false, onDelete: 'CASCADE' })
    @JoinColumn({ name: 'id_empleado' })
    empleado: Empleados;
  
    @Column({ type: 'varchar', length: 100, nullable: false })
    username: string;
  
    @Column({ type: 'varchar', length: 255, nullable: false })
    passwordHash: string;
  
    @Column({
      type: 'enum',
      enum: ['admin', 'user', 'guest'],
      default: 'user',
    })
    rol: 'admin' | 'user' | 'guest';
  
    @Column({
      type: 'enum',
      enum: ['activo', 'inactivo'],
      default: 'activo',
    })
    estado: 'activo' | 'inactivo';
  
    @Column({ type: 'timestamp', default: () => 'CURRENT_TIMESTAMP' })
    fechaCreacion: Date;
  }