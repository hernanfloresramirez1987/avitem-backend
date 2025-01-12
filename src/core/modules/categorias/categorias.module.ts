import { Module } from '@nestjs/common';
import { CategoriasService } from './categorias.service';
import { CategoriasController } from './categorias.controller';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Categorias } from './entities/categoria.entity';
import { CategoriaRepository } from 'src/core/shared/repositories/CategoriaRep';

@Module({
  imports: [TypeOrmModule.forFeature([Categorias])],
  controllers: [CategoriasController],
  providers: [CategoriasService, CategoriaRepository],
})
export class CategoriasModule {}
