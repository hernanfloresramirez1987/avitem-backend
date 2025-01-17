import { Module } from '@nestjs/common';
import { ColoresService } from './colores.service';
import { ColoresController } from './colores.controller';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Colores } from './entities/color.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Colores])],
  controllers: [ColoresController],
  providers: [ColoresService],
})
export class ColoresModule {}
