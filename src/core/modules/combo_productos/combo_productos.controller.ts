import { Controller, Get, Post, Body, Patch, Param, Delete } from '@nestjs/common';
import { ComboProductosService } from './combo_productos.service';
import { CreateComboProductoDto } from './dto/create-combo_producto.dto';
import { UpdateComboProductoDto } from './dto/update-combo_producto.dto';

@Controller('combo-productos')
export class ComboProductosController {
  constructor(private readonly comboProductosService: ComboProductosService) {}

  @Post()
  create(@Body() createComboProductoDto: CreateComboProductoDto) {
    return this.comboProductosService.create(createComboProductoDto);
  }

  @Get()
  findAll() {
    return this.comboProductosService.findAll();
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.comboProductosService.findOne(+id);
  }

  @Patch(':id')
  update(@Param('id') id: string, @Body() updateComboProductoDto: UpdateComboProductoDto) {
    return this.comboProductosService.update(+id, updateComboProductoDto);
  }

  @Delete(':id')
  remove(@Param('id') id: string) {
    return this.comboProductosService.remove(+id);
  }
}
