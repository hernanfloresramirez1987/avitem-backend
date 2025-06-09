import { Module } from '@nestjs/common';
import { InventariosService } from './inventarios.service';
import { InventariosController } from './inventarios.controller';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Inventarios } from './entities/inventario.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Inventarios])],
  controllers: [InventariosController],
  providers: [InventariosService],
})
export class InventariosModule {}
