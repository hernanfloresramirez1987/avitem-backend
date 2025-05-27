import { BaseEntity, Column, Entity, PrimaryGeneratedColumn, Unique } from "typeorm";

@Entity({ name: 'persona' }) // Asocia la entidad `Personas` a la tabla `persona`
@Unique(['ci']) // Define la restricción única para el campo `ci`
export class Personas extends BaseEntity {
    @PrimaryGeneratedColumn('increment', { type: 'bigint', unsigned: true })
    id: number;

    @Column({ type: 'varchar', length: 15, nullable: false })
    ci: string;

    @Column({ type: 'varchar', length: 2, nullable: false })
    ciExpedit: string;

    @Column({ type: 'varchar', length: 5, nullable: false })
    ciComplement: string;

    @Column({ type: 'varchar', length: 100, nullable: true })
    nombre: string;

    @Column({ type: 'varchar', length: 100, nullable: true })
    app: string;

    @Column({ type: 'varchar', length: 100, nullable: true })
    apm: string;

    @Column({ type: 'char', length: 1, nullable: true })
    sexo: string;

    @Column({ type: 'date', nullable: true })
    fnaci: Date;

    @Column({ type: 'varchar', length: 200, nullable: true })
    direccion: string;

    @Column({ type: 'varchar', length: 15, nullable: true })
    telefono: string;

    @Column({ type: 'varchar', length: 100, nullable: true })
    email: string;

    @Column({ type: 'tinyint', width: 1, nullable: true })
    state: boolean;
}