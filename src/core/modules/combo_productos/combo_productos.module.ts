import { Module } from '@nestjs/common';
import { ComboProductosService } from './combo_productos.service';
import { ComboProductosController } from './combo_productos.controller';

@Module({
  controllers: [ComboProductosController],
  providers: [ComboProductosService],
})
export class ComboProductosModule {}
