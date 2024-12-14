import { Controller, Get, Post, Body, Patch, Param, Delete } from '@nestjs/common';
import { LoteProductoService } from './lote_producto.service';
import { CreateLoteProductoDto } from './dto/create-lote_producto.dto';
import { UpdateLoteProductoDto } from './dto/update-lote_producto.dto';

@Controller('lote-producto')
export class LoteProductoController {
  constructor(private readonly loteProductoService: LoteProductoService) {}

  @Post()
  create(@Body() createLoteProductoDto: CreateLoteProductoDto) {
    return this.loteProductoService.create(createLoteProductoDto);
  }

  @Get()
  findAll() {
    return this.loteProductoService.findAll();
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.loteProductoService.findOne(+id);
  }

  @Patch(':id')
  update(@Param('id') id: string, @Body() updateLoteProductoDto: UpdateLoteProductoDto) {
    return this.loteProductoService.update(+id, updateLoteProductoDto);
  }

  @Delete(':id')
  remove(@Param('id') id: string) {
    return this.loteProductoService.remove(+id);
  }
}
